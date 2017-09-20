//
//  iTunes.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/8/31.
//

import Foundation
import ScriptingBridge
import iTunesBridge

class iTunes: HashClass {
    
    var iTunesPlayer: iTunesApplication
    
    weak var delegate: MusicPlayerDelegate?
    
    fileprivate(set) var currentTrack: MusicTrack?
    
    fileprivate var _trackStartTime: TimeInterval = 0
    
    override required init?() {
        guard let player = SBApplication(bundleIdentifier: MusicPlayerName.iTunes.bundleID) else { return nil }
        iTunesPlayer = player
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
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(playerInfoChanged(_:)), name: NSNotification.Name.iTunesPlayerInfo, object: nil)
    }
    
    func stopPlayerTracking() {
        currentTrack = nil
        TimerDispatcher.shared.unregister(player: self)
        DistributedNotificationCenter.default().removeObserver(self)
    }
    
    // MARK: - Player Event Handle
    
    fileprivate func pauseEvent() {
        // Rewind and fast forward would send pause notification.
        guard playbackState == .paused else { return }
        delegate?.player(self, playbackStateChanged: .paused, atPosition: playerPosition)
        startRunningObserving()
    }
    
    fileprivate func stoppedEvent() {
        delegate?.player(self, playbackStateChanged: .stopped, atPosition: playerPosition)
        startRunningObserving()
    }
    
    fileprivate func playingEvent() {
        musicTrackCheckEvent()
        delegate?.player(self, playbackStateChanged: .playing, atPosition: playerPosition)
        startRepositionObserving()
    }
    
    fileprivate func musicTrackCheckEvent() {
        guard isRunning,
              let newTrack = iTunesPlayer.currentTrack?.musicTrack,
              currentTrack == nil || currentTrack! != newTrack
        else { return }
        currentTrack = newTrack
        delegate?.player(self, didChangeTrack: newTrack, atPosition: playerPosition)
    }
    
    fileprivate func repositionCheckEvent() {
        // check playback state
        guard playbackState.isActiveState
        else {
            TimerDispatcher.shared.unregister(player: self)
            return
        }
        
        // check position
        let iTunesPosition = playerPosition
        let accurateStartTime = trackStartTime
        let deltaPosition = accurateStartTime - _trackStartTime
        
        if deltaPosition > -MusicPlayerConfig.Precision && deltaPosition < MusicPlayerConfig.Precision {
            _trackStartTime = accurateStartTime
            return
        }
        
        let currentState = playbackState
        if currentState == .fastForwarding || currentState == .rewinding {
            delegate?.player(self, playbackStateChanged: currentState, atPosition: iTunesPosition)
        } else {
            delegate?.player(self, playbackStateChanged: .reposition, atPosition: iTunesPosition)
        }
        _trackStartTime = accurateStartTime
    }
    
    fileprivate func runningCheckEvent() {
        guard !isRunning else { return }
        delegate?.playerDidQuit(self)
    }
    
    // MARK: - Notification Event
    
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
        
        if let location = userInfo["Location"] as? String {
            currentTrack?.url = URL(fileURLWithPath: location)
        }
    }
    
    // MARK: - Timer Actions
    
    fileprivate func startRepositionObserving() {
        // start timer
        TimerDispatcher.shared.register(player: self, timerPrecision: MusicPlayerConfig.TimerInterval) { timeInterval in
            // It's useless to weak self for player is strong referenced by the dispatcher's dictionary key.
            self.repositionCheckEvent()
        }
        // write down the track start time
        _trackStartTime = trackStartTime
    }
    
    fileprivate func startRunningObserving() {
        TimerDispatcher.shared.register(player: self, timerPrecision: 1.5) { timeInterval in
            self.runningCheckEvent()
        }
    }
}

// MARK: - Track

fileprivate extension iTunesTrack {
    
    var musicTrack: MusicTrack? {
        guard mediaKind == .music,
              let id = id?(),
              let name = name,
              let duration = duration
        else { return nil }
        
        var artwork: NSImage? = nil
        if let artworks = artworks?(),
           artworks.count > 0,
           let iTunesArtwork = artworks[0] as? iTunesArtwork
        {
            artwork = iTunesArtwork.data
        }
        
        return MusicTrack(id: String(id), title: name, album: album, artist: artist, duration: duration, artwork: artwork, lyrics: lyrics, url: nil, originalTrack: self as? SBObject)
    }
    
}
