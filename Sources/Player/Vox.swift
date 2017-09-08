//
//  Vox.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/8/31.
//

import Foundation
import BridgeHeader.Vox

class Vox {
    
    weak var delegate: MusicPlayerDelegate?
    
    fileprivate(set) var currentTrack: MusicTrack?
    
    fileprivate var vox: VoxApplication
    
    fileprivate var timer: Timer?
    
    fileprivate var timerPosition: TimeInterval = 0
    
    fileprivate var currentPlaybackState: MusicPlaybackState = .stopped
    
    required init?() {
        guard let player = VoxApplication(bundleIdentifier: MusicPlayerName.vox.bundleID) else { return nil }
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
        timerPosition = vox.currentTime
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
            let voxPosition = vox.currentTime
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
    
    var originalPlayer: SBApplication { return vox }
    
    var playbackState: MusicPlaybackState {
        if vox.isRunning {
            return MusicPlaybackState(vox.playerState)
        } else {
            return .stopped
        }
    }
    
    var repeatMode: MusicRepeatMode? {
        get {
            guard vox.isRunning else { return nil }
            return MusicRepeatMode(vox.repeatState)
        }
        set {
            guard vox.isRunning,
                  newValue != nil
            else {
                return
            }
            vox.repeatState = newValue!.intValue
        }
    }
    
    var shuffleMode: MusicShuffleMode? {
        get { return nil }
        set {}
    }
    
    var playerPosition: TimeInterval {
        get {
            guard vox.isRunning else { return 0 }
            return vox.currentTime
        }
        set {
            guard vox.isRunning,
                  newValue >= 0
            else {
                return
            }
            vox.currentTime = newValue
        }
    }
    
    func play() {
        guard vox.isRunning else { return }
        vox.play()
    }
    
    func pause() {
        guard vox.isRunning else { return }
        vox.pause()
    }
    
    func stop() {
        guard vox.isRunning else { return }
        vox.pause()
    }
    
    func playNext() {
        guard vox.isRunning else { return }
        vox.next()
    }
    
    func playPrevious() {
        guard vox.isRunning else { return }
        vox.previous()
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
        guard isRunning,
              let id = uniqueID,
              let title = track
        else {
            return nil
        }
        var url: URL? = nil
        if let trackURL = trackUrl {
            url = URL(fileURLWithPath: trackURL)
        }
        return MusicTrack(id: id, title: title, album: album, artist: artist, duration: totalTime, artwork: artworkImage, lyrics: nil, url: url, originalTrack: self)
    }
    
}
