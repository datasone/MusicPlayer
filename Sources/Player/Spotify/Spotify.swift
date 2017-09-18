//
//  Spotify.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/8/31.
//

import Foundation
import ScriptingBridge
import SpotifyBridge

class Spotify {
    
    var spotifyPlayer: SpotifyApplication
    
    weak var delegate: MusicPlayerDelegate?
    
    fileprivate(set) var currentTrack: MusicTrack?
    
    fileprivate var timer: Timer?
    
    fileprivate var _trackStartTime: TimeInterval = 0
    
    required init?() {
        guard let player = SBApplication(bundleIdentifier: MusicPlayerName.spotify.bundleID) else { return nil }
        spotifyPlayer = player
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
        timer?.invalidate()
        DistributedNotificationCenter.default().removeObserver(self)
    }
    
    // MARK: - Player Event Handle
    
    fileprivate func pauseEvent() {
        delegate?.player(self, playbackStateChanged: .paused, atPosition: playerPosition)
        timer?.invalidate()
    }
    
    fileprivate func stoppedEvent() {
        delegate?.playerDidQuit(self)
        timer?.invalidate()
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
    
    @objc fileprivate func repositionCheckEvent(_ timer: Timer) {
        // check playback state
        guard playbackState.isActiveState
            else {
                timer.invalidate()
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
        timer?.invalidate()
        timer = Timer(timeInterval: MusicPlayerConfig.TimerInterval, target: self, selector: #selector(repositionCheckEvent(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .commonModes)
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
