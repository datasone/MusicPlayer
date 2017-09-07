//
//  Spotify.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/8/31.
//

import Foundation
import BridgeHeader.Spotify

class Spotify {
    
    weak var _delegate: MusicPlayerDelegate?
    
    fileprivate var _currentTrack: MusicTrack?
    
    fileprivate var spotify: SpotifyApplication
    
    fileprivate var timer: Timer?
    
    fileprivate var timerPosition: TimeInterval = 0
    
    required init?() {
        guard let player = SpotifyApplication(bundleIdentifier: MusicPlayerName.Spotify.bundleID) else { return nil }
        spotify = player
    }
    
    fileprivate func _startPlayerTracking() {
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(playerInfoChanged(_:)), name: NSNotification.Name(rawValue: "com.spotify.client.PlaybackStateChanged"), object: nil)
        generatePlayingEvent()
    }
    
    fileprivate func _stopPlayerTracking() {
        DistributedNotificationCenter.default().removeObserver(self)
        timer?.invalidate()
    }
    
    @objc fileprivate func playerInfoChanged(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let playerState = userInfo["Player State"] as? String
            else {
                return
        }
        
        switch playerState {
            
        case "Paused":
            delegate?.playerDidPaused(self)
            timer?.invalidate()
            break
            
        case "Stopped":
            delegate?.playerDidQuit(self)
            timer?.invalidate()
            break
            
        case "Playing":
            // Reset timer.
            generatePlayingEvent()
            
            // Check whether track changed.
            guard let newTrack = spotify.currentTrack.musicTrack else { return }
            if _currentTrack == nil || _currentTrack! != newTrack {
                _currentTrack = newTrack
                delegate?.player(self, didChangeTrack: newTrack, atPosition: playerPosition)
            }
            break
            
        default:
            break
        }
    }
    
    // MARK: - Timer Events
    
    fileprivate func generatePlayingEvent() {
        timer?.invalidate()
        timerPosition = spotify.playerPosition
        timer = Timer(timeInterval: MusicPlayerConfig.TimerCheckingInterval, target: self, selector: #selector(playingEvent(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .commonModes)
    }
    
    @objc fileprivate func playingEvent(_ timer: Timer) {
        guard playbackState == .playing else {
            timer.invalidate()
            return
        }
        
        let spotifyPosition = spotify.playerPosition
        let deltaPosition = timerPosition + MusicPlayerConfig.TimerCheckingInterval - spotifyPosition
        if abs(deltaPosition) <= MusicPlayerConfig.ComparisonPrecision {
            delegate?.playerPlaying(self, atPosition: spotifyPosition)
        } else if deltaPosition < -MusicPlayerConfig.ComparisonPrecision {
            delegate?.player(self, didFastForwardAtPosition: spotifyPosition)
        } else {
            delegate?.player(self, didRewindAtPosition: spotifyPosition)
        }
        timerPosition = spotifyPosition
    }
}

// MARK: - Playback Control

extension Spotify: PlaybackControl {
    
    var playbackState: MusicPlaybackState {
        if spotify.isRunning {
            return MusicPlaybackState(spotify.playerState)
        } else {
            return .notRunning
        }
    }
    
    var repeatMode: MusicRepeatMode? {
        get { return nil }
        set {}
    }
    
    var shuffleMode: MusicShuffleMode? {
        get { return nil }
        set {}
    }
    
    var playerPosition: TimeInterval {
        get {
            guard spotify.isRunning else { return 0 }
            return spotify.playerPosition
        }
        set {
            guard
                spotify.isRunning,
                newValue >= 0
                else {
                    return
            }
            spotify.playerPosition = newValue
        }
    }
    
    func play() {
        guard spotify.isRunning else { return }
        spotify.play()
    }
    
    func pause() {
        guard spotify.isRunning else { return }
        spotify.pause()
    }
    
    func stop() {
        guard spotify.isRunning else { return }
        spotify.pause()
    }
    
    func playNext() {
        guard spotify.isRunning else { return }
        spotify.nextTrack()
    }
    
    func playPrevious() {
        guard spotify.isRunning else { return }
        spotify.previousTrack()
    }
}

extension Spotify: MusicPlayer {

    weak var delegate: MusicPlayerDelegate? {
        get { return _delegate }
        set { _delegate = newValue }
    }
    
    var originalPlayer: SBApplication {
        return spotify
    }
    
    var currentTrack: MusicTrack? {
        guard spotify.isRunning else { return nil }
        return _currentTrack
    }
    
    var name: MusicPlayerName { return .Spotify }
    
    func startPlayerTracking() {
        _startPlayerTracking()
    }
    
    func stopPlayerTracking() {
        _stopPlayerTracking()
    }
}

// MARK: - Enum Extension

fileprivate extension MusicPlaybackState {
    
    init(_ playbackState: SpotifyEPlS) {
        switch playbackState {
        case SpotifyEPlSStopped:
            self = .stopped
        case SpotifyEPlSPlaying:
            self = .playing
        case SpotifyEPlSPaused:
            self = .paused
        default:
            self = .notRunning
        }
    }
}

// MARK: - Spotify Track

fileprivate extension SpotifyTrack {
    
    var musicTrack: MusicTrack? {
        
        guard
            let id = id(),
            let title = name
            else {
                return nil
        }
        
        var url: URL? = nil
        if let spotifyUrl = spotifyUrl {
            url = URL(fileURLWithPath: spotifyUrl)
        }
        return MusicTrack(id: id, title: title, album: album, artist: artist, duration: TimeInterval(duration), artwork: artwork, lyrics: nil, url: url, originalTrack: self)
    }
    
}


