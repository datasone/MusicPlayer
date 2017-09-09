//
//  Vox.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/8/31.
//

import Foundation
import ScriptingBridge
import VoxBridge

class Vox {
    
    weak var delegate: MusicPlayerDelegate?
    
    fileprivate(set) var currentTrack: MusicTrack?
    
    fileprivate var vox: VoxApplication
    
    fileprivate var timer: Timer?
    
    fileprivate var timerPosition: TimeInterval = 0
    
    fileprivate var currentPlaybackState: MusicPlaybackState = .stopped
    
    required init?() {
        guard let player = SBApplication(bundleIdentifier: MusicPlayerName.vox.bundleID) else { return nil }
        vox = player
    }
    
    deinit {
        stopPlayerTracking()
    }
    
    func startPlayerTracking() {
        currentPlaybackState = .stopped
        generatePlayingEvent()
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(playerInfoChanged(_:)), name: NSNotification.Name.voxTrackChanged, object: nil)
    }
    
    func stopPlayerTracking() {
        DistributedNotificationCenter.default().removeObserver(self)
        timer?.invalidate()
    }
    
    @objc fileprivate func playerInfoChanged(_ notification: Notification) {
        guard let newTrack = vox.musicTrack,
              currentTrack == nil || currentTrack != newTrack
        else {
            return
        }
        currentTrack = newTrack
        delegate?.player(self, didChangeTrack: newTrack, atPosition: playerPosition)
        generatePlayingEvent()
    }
    
    // MARK: - Timer Events
    
    fileprivate func generatePlayingEvent() {
        timer?.invalidate()
        timerPosition = playerPosition
        timer = Timer(timeInterval: MusicPlayerConfig.TimerCheckingInterval, target: self, selector: #selector(playingEvent(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .commonModes)
    }
    
    @objc fileprivate func playingEvent(_ timer: Timer) {
        let state = playbackState
        switch state {
        case .stopped:
            timer.invalidate()
            guard currentPlaybackState != state else { return }
            currentPlaybackState = state
            delegate?.playerDidQuit(self)
            
        case .paused:
            guard currentPlaybackState != state else { return }
            currentPlaybackState = state
            delegate?.player(self, playbackStateChanged: .paused, atPosition: playerPosition)
            
        case .playing:
            let voxPosition = playerPosition
            let deltaPosition = timerPosition + MusicPlayerConfig.TimerCheckingInterval - voxPosition
            
            if currentPlaybackState != state {
                currentPlaybackState = state
                delegate?.player(self, playbackStateChanged: .playing, atPosition: voxPosition)
            }
            
            if deltaPosition < -MusicPlayerConfig.ComparisonPrecision {
                delegate?.player(self, playbackStateChanged: .fastForwarding, atPosition: voxPosition)
            } else if deltaPosition > MusicPlayerConfig.ComparisonPrecision {
                delegate?.player(self, playbackStateChanged: .rewinding, atPosition: voxPosition)
            }
            
            timerPosition = voxPosition
        default:
            break
        }
    }
}

// MARK: - Music Player

extension Vox: MusicPlayer {
    
    var name: MusicPlayerName { return .vox }
    
    var playbackState: MusicPlaybackState {
        guard isRunning,
              let playerState = vox.playerState
        else { return .stopped }
        return MusicPlaybackState(playerState)
    }
    
    var repeatMode: MusicRepeatMode? {
        get {
            guard isRunning,
                  let repeateState = vox.repeatState
            else { return nil }
            return MusicRepeatMode(repeateState)
        }
        set {
            guard isRunning,
                  let repeateState = newValue?.intValue
            else { return }
            vox.setRepeatState?(repeateState)
        }
    }
    
    var shuffleMode: MusicShuffleMode? {
        get { return nil }
        set {}
    }
    
    var playerPosition: TimeInterval {
        get {
            guard isRunning,
                  let currentTime = vox.currentTime
            else { return 0 }
            return currentTime
        }
        set {
            guard isRunning,
                  newValue >= 0
            else { return }
            vox.setCurrentTime?(newValue)
        }
    }
    
    func play() {
        guard isRunning else { return }
        vox.play?()
    }
    
    func pause() {
        guard isRunning else { return }
        vox.pause?()
    }
    
    func stop() {
        guard isRunning else { return }
        vox.pause?()
    }
    
    func playNext() {
        guard isRunning else { return }
        vox.next?()
    }
    
    func playPrevious() {
        guard isRunning else { return }
        vox.previous?()
    }
    
    var originalPlayer: SBApplication {
        return vox as! SBApplication
    }
}

// MARK: - Enum Extension

fileprivate extension MusicPlaybackState {
    
    init(_ playbackState: Int) {
        switch playbackState {
        case 0:
            self = .paused
        case 1:
            self = .playing
        default:
            self = .stopped
        }
    }
}

fileprivate extension MusicRepeatMode {
    
    init?(_ repeatMode: Int) {
        switch repeatMode {
        case 0:
            self = .none
        case 1:
            self = .one
        case 2:
            self = .all
        default:
            return nil
        }
    }
    
    var intValue: Int {
        switch self {
        case .none:
            return 0
        case .one:
            return 1
        case .all:
            return 2
        }
    }

}

// MARK: - VoxApplication

fileprivate extension VoxApplication {
    
    var musicTrack: MusicTrack? {
        guard (self as! SBApplication).isRunning,
              let id = uniqueID,
              let title = track,
              let totalTime = totalTime
        else { return nil }
        var url: URL? = nil
        if let trackURL = trackUrl {
            url = URL(fileURLWithPath: trackURL)
        }
        return MusicTrack(id: id, title: title, album: album, artist: artist, duration: totalTime, artwork: artworkImage, lyrics: nil, url: url, originalTrack: nil)
    }
    
}
