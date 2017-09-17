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
    
    fileprivate var trackStartTime: TimeInterval = 0
    
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
        // check position
        let spotifyPosition = playerPosition
        let accurateStartTime = trackStartDate(with: spotifyPosition)
        
        let deltaPosition = accurateStartTime - trackStartTime
        if deltaPosition < -MusicPlayerConfig.Precision {
            delegate?.player(self, playbackStateChanged: .fastForwarding, atPosition: spotifyPosition)
        } else if deltaPosition > MusicPlayerConfig.Precision {
            delegate?.player(self, playbackStateChanged: .rewinding, atPosition: spotifyPosition)
        }
        trackStartTime = accurateStartTime
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
        trackStartTime = trackStartDate(with: playerPosition)
    }
    
    // MARK: - Private
    
    fileprivate func trackStartDate(with playerPosition: TimeInterval) -> TimeInterval {
        let currentTime = NSDate().timeIntervalSince1970
        return currentTime - playerPosition
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
