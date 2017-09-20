//
//  Spotify.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/8/31.
//

import Foundation
import ScriptingBridge
import SpotifyBridge

class Spotify: HashClass {
    
    var spotifyPlayer: SpotifyApplication
    
    weak var delegate: MusicPlayerDelegate?
    
    fileprivate(set) var currentTrack: MusicTrack?
    
    fileprivate var _trackStartTime: TimeInterval = 0
    
    override required init?() {
        guard let player = SBApplication(bundleIdentifier: MusicPlayerName.spotify.bundleID) else { return nil }
        spotifyPlayer = player
        super.init()
    }
    
    deinit {
        stopPlayerTracking()
    }
    
    func startPlayerTracking() {
        // Initialize Tracking state.
        musicTrackCheckEvent()
        delegate?.player(self, playbackStateChanged: playbackState, atPosition: playerPosition)
        
        // start tracking.
        startRepositionObserving()
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(playerInfoChanged(_:)), name: NSNotification.Name.spotifyPlayerInfo, object: nil)
    }
    
    func stopPlayerTracking() {
        TimerDispatcher.shared.unregister(player: self)
        DistributedNotificationCenter.default().removeObserver(self)
    }
    
    // MARK: - Player Event Handle
    
    fileprivate func pauseEvent() {
        TimerDispatcher.shared.unregister(player: self)
        delegate?.player(self, playbackStateChanged: .paused, atPosition: playerPosition)
    }
    
    fileprivate func stoppedEvent() {
        TimerDispatcher.shared.unregister(player: self)
        delegate?.playerDidQuit(self)
    }
    
    fileprivate func playingEvent() {
        musicTrackCheckEvent()
        delegate?.player(self, playbackStateChanged: .playing, atPosition: playerPosition)
        startRepositionObserving()
    }
    
    fileprivate func musicTrackCheckEvent() {
        guard isRunning,
              let newTrack = spotifyPlayer.currentTrack?.musicTrack,
              currentTrack == nil || currentTrack! != newTrack
        else { return }
        currentTrack = newTrack
        delegate?.player(self, didChangeTrack: newTrack, atPosition: playerPosition)
    }
    
    fileprivate func repositionCheckEvent() {
        // check playback state
        guard playbackState.isActiveState else {
            TimerDispatcher.shared.unregister(player: self)
            return
        }
        
        // check position
        let spotifyPosition = playerPosition
        let accurateStartTime = trackStartTime
        let deltaPosition = accurateStartTime - _trackStartTime
        
        if deltaPosition <= -MusicPlayerConfig.Precision || deltaPosition >= MusicPlayerConfig.Precision {
            delegate?.player(self, playbackStateChanged: .reposition, atPosition: spotifyPosition)
        }
        _trackStartTime = accurateStartTime
    }
    
    // MARK: - Notification Events
    
    @objc fileprivate func playerInfoChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let playerState = userInfo["Player State"] as? String
        else { return }
        
        switch playerState {
        case "Paused":
            pauseEvent()
        case "Stopped":
            stoppedEvent()
        case "Playing":
            playingEvent()
        default:
            break
        }
    }
    
    // MARK: - Timer Events
    
    fileprivate func startRepositionObserving() {
        // start timer
        TimerDispatcher.shared.register(player: self, timerPrecision: MusicPlayerConfig.TimerInterval) { timeInterval in
            self.repositionCheckEvent()
        }
        // write down the track start time
        _trackStartTime = trackStartTime
    }
}

// MARK: - Spotify Track

fileprivate extension SpotifyTrack {
    
    var musicTrack: MusicTrack? {
        
        guard let id = id?(),
              let title = name,
              let duration = duration
        else { return nil }
        
        var url: URL? = nil
        if let spotifyUrl = spotifyUrl {
            url = URL(fileURLWithPath: spotifyUrl)
        }
        return MusicTrack(id: id, title: title, album: album, artist: artist, duration: TimeInterval(duration), artwork: artwork, lyrics: nil, url: url, originalTrack: self as? SBObject)
    }
}
