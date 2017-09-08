//
//  Spotify.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/8/31.
//

import Foundation
import BridgeHeader.Spotify

class Spotify {
    
    weak var delegate: MusicPlayerDelegate?
    
    fileprivate(set) var currentTrack: MusicTrack?
    
    fileprivate var spotify: SpotifyApplication
    
    fileprivate var timer: Timer?
    
    fileprivate var timerPosition: TimeInterval = 0
    
    required init?() {
        guard let player = SpotifyApplication(bundleIdentifier: MusicPlayerName.spotify.bundleID) else { return nil }
        spotify = player
    }
    
    func startPlayerTracking() {
        generatePlayingEvent()
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(playerInfoChanged(_:)), name: NSNotification.Name.spotifyPlayerInfo, object: nil)
    }
    
    func stopPlayerTracking() {
        timer?.invalidate()
        DistributedNotificationCenter.default().removeObserver(self)
    }
    
    @objc fileprivate func playerInfoChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let playerState = userInfo["Player State"] as? String
        else {
            return
        }
        
        switch playerState {
            
        case "Paused":
            delegate?.player(self, playbackStateChanged: .paused, atPosition: playerPosition)
            timer?.invalidate()
            
        case "Stopped":
            delegate?.playerDidQuit(self)
            timer?.invalidate()
            
        case "Playing":
            let currentPosition = playerPosition
            // Check whether track changed.
            if let newTrack = spotify.currentTrack.musicTrack,
               currentTrack == nil || currentTrack! != newTrack
            {
                currentTrack = newTrack
                delegate?.player(self, didChangeTrack: newTrack, atPosition: currentPosition)
            }
            delegate?.player(self, playbackStateChanged: .playing, atPosition: currentPosition)
            generatePlayingEvent()
            
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
        if deltaPosition < -MusicPlayerConfig.ComparisonPrecision {
            delegate?.player(self, playbackStateChanged: .fastForwarding, atPosition: spotifyPosition)
        } else if deltaPosition > MusicPlayerConfig.ComparisonPrecision {
            delegate?.player(self, playbackStateChanged: .rewinding, atPosition: spotifyPosition)
        }
        timerPosition = spotifyPosition
    }
}

// MARK: - Music Player

extension Spotify: MusicPlayer {
    
    var name: MusicPlayerName { return .spotify }
    
    var playbackState: MusicPlaybackState {
        if spotify.isRunning {
            return MusicPlaybackState(spotify.playerState)
        } else {
            return .stopped
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
            guard spotify.isRunning,
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
    
    var originalPlayer: SBApplication {
        return spotify
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
            self = .stopped
        }
    }
}

// MARK: - Spotify Track

fileprivate extension SpotifyTrack {
    
    var musicTrack: MusicTrack? {
        
        guard let id = id(),
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
