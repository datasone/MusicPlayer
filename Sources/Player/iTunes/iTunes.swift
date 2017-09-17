//
//  iTunes.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/8/31.
//

import Foundation
import ScriptingBridge
import iTunesBridge

class iTunes {
    
    var iTunesPlayer: iTunesApplication
    
    weak var delegate: MusicPlayerDelegate?
    
    fileprivate(set) var currentTrack: MusicTrack?
    
    fileprivate var timer: Timer?
    
    fileprivate var _trackStartTime: TimeInterval = 0
    
    required init?() {
        guard let player = SBApplication(bundleIdentifier: MusicPlayerName.iTunes.bundleID) else { return nil }
        iTunesPlayer = player
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
        timer?.invalidate()
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
    
    @objc fileprivate func repositionCheckEvent(_ timer: Timer) {
        // check playback state
        guard playbackState.isActiveState
        else {
            timer.invalidate()
            return
        }
        
        // check position
        let iTunesPosition = playerPosition
        let accurateStartTime = trackStartTime
        
        let deltaPosition = accurateStartTime - _trackStartTime
        if deltaPosition < -MusicPlayerConfig.Precision {
            delegate?.player(self, playbackStateChanged: .fastForwarding, atPosition: iTunesPosition)
        } else if deltaPosition > MusicPlayerConfig.Precision {
            delegate?.player(self, playbackStateChanged: .rewinding, atPosition: iTunesPosition)
        }
        _trackStartTime = accurateStartTime
    }
    
    @objc fileprivate func runningCheckEvent(_ timer: Timer) {
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
        timer?.invalidate()
        timer = Timer(timeInterval: MusicPlayerConfig.TimerInterval, target: self, selector: #selector(repositionCheckEvent(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .commonModes)
        // write down the track start time
        _trackStartTime = trackStartTime
    }
    
    fileprivate func startRunningObserving() {
        timer?.invalidate()
        timer = Timer(timeInterval: 1.5, target: self, selector: #selector(runningCheckEvent(_:)), userInfo: nil, repeats: false)
        RunLoop.current.add(timer!, forMode: .commonModes)
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
