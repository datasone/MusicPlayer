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
    
    var vox: VoxApplication
    
    weak var delegate: MusicPlayerDelegate?
    
    fileprivate(set) var currentTrack: MusicTrack?
    
    fileprivate var timer: Timer?
    
    fileprivate var _trackStartTime: TimeInterval = 0
    
    fileprivate var currentPlaybackState: MusicPlaybackState = .stopped
    
    required init?() {
        guard let player = SBApplication(bundleIdentifier: MusicPlayerName.vox.bundleID) else { return nil }
        vox = player
    }
    
    deinit {
        stopPlayerTracking()
    }
    
    func startPlayerTracking() {
        // Initialize Tracking state.
        musicTrackCheckEvent()
        currentPlaybackState = playbackState
        delegate?.player(self, playbackStateChanged: currentPlaybackState, atPosition: playerPosition)
        
        // start tracking.
        startPlaybackObserving()
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(playerInfoChanged(_:)), name: NSNotification.Name.voxTrackChanged, object: nil)
    }
    
    func stopPlayerTracking() {
        DistributedNotificationCenter.default().removeObserver(self)
        timer?.invalidate()
    }
    
    // MARK: - Player Event Handle
    
    @objc fileprivate func playbackStateCheckEvent(_ timer: Timer) {
        switch playbackState {
        case .stopped:
            stoppedEvent()
        case .paused:
            pauseEvent()
        case .playing:
            playingEvent()
        default:
            break
        }
    }
    
    fileprivate func pauseEvent() {
        guard currentPlaybackState != .paused else { return }
        currentPlaybackState = .paused
        delegate?.player(self, playbackStateChanged: .paused, atPosition: playerPosition)
    }
    
    fileprivate func stoppedEvent() {
        timer?.invalidate()
        guard currentPlaybackState != .stopped else { return }
        currentPlaybackState = .stopped
        delegate?.playerDidQuit(self)
    }
    
    fileprivate func playingEvent() {
        let voxPosition = playerPosition
        
        if currentPlaybackState != .playing {
            currentPlaybackState = .playing
            delegate?.player(self, playbackStateChanged: .playing, atPosition: voxPosition)
        }
        
        repositionCheckEvent(voxPosition)
    }
    
    fileprivate func musicTrackCheckEvent() {
        guard isRunning,
              let newTrack = vox.musicTrack,
              currentTrack == nil || currentTrack != newTrack
        else { return }
        currentTrack = newTrack
        delegate?.player(self, didChangeTrack: newTrack, atPosition: playerPosition)
    }
    
    fileprivate func repositionCheckEvent(_ position: TimeInterval) {
        // check position
        let accurateStartTime = trackStartTime
        let deltaPosition = accurateStartTime - _trackStartTime

        if deltaPosition <= -MusicPlayerConfig.Precision || deltaPosition >= MusicPlayerConfig.Precision {
            delegate?.player(self, playbackStateChanged: .reposition, atPosition: position)
        }
        _trackStartTime = accurateStartTime
    }
    
    // MARK: - Notification Events
    
    @objc fileprivate func playerInfoChanged(_ notification: Notification) {
        musicTrackCheckEvent()
        startPlaybackObserving()
    }
    
    // MARK: - Timer Events
    
    fileprivate func startPlaybackObserving() {
        // start timer
        timer?.invalidate()
        timer = Timer(timeInterval: MusicPlayerConfig.TimerInterval, target: self, selector: #selector(playbackStateCheckEvent(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .commonModes)
        // write down the track start time
        _trackStartTime = trackStartTime
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
