//
//  iTunes.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/8/31.
//

import Foundation
import BridgeHeader.iTunes


class iTunes {
    
    weak var _delegate: MusicPlayerDelegate?
    
    fileprivate var _currentTrack: MusicTrack?
    
    fileprivate var iTunes: iTunesApplication
    
    fileprivate var timer: Timer?
    
    fileprivate var timerPosition: TimeInterval = 0
    
    required init?() {
        guard let player = iTunesApplication(bundleIdentifier: MusicPlayerName.iTunes.bundleID) else { return nil }
        iTunes = player
    }
    
    deinit {
        _stopPlayerTracking()
    }
    
    fileprivate func _startPlayerTracking() {

        DistributedNotificationCenter.default().addObserver(self, selector: #selector(playerInfoChanged(_:)), name: NSNotification.Name(rawValue: "com.apple.iTunes.playerInfo"), object: nil)
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
            // Rewind and fast forward would send pause notification.
            guard playbackState == .paused else { return }
            delegate?.playerDidPaused(self)
            checkRunningState()
            break
            
        case "Stopped":
            delegate?.playerDidStopped(self)
            checkRunningState()
            break
            
        case "Playing":
            // Reset timer.
            generatePlayingEvent()
            
            // Check whether track changed.
            guard let newTrack = iTunes.currentTrack.musicTrack else { return }
            if _currentTrack == nil || _currentTrack! != newTrack {
                _currentTrack = newTrack
                delegate?.player(self, didChangeTrack: newTrack, atPosition: playerPosition)
            }
            break
            
        default:
            break
        }
        
        if let location = userInfo["Location"] as? String {
            _currentTrack?.url = URL(fileURLWithPath: location)
        }
    }
    
    // MARK: Timer Events
    
    fileprivate func generatePlayingEvent() {
        timer?.invalidate()
        timerPosition = iTunes.playerPosition
        timer = Timer(timeInterval: MusicPlayerConfig.TimerCheckingInterval, target: self, selector: #selector(playingEvent(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .commonModes)
    }
    
    @objc fileprivate func playingEvent(_ timer: Timer) {
        guard playbackState == .playing else {
            timer.invalidate()
            return
        }
        
        let iTunesPosition = iTunes.playerPosition
        let deltaPosition = timerPosition + MusicPlayerConfig.TimerCheckingInterval - iTunesPosition
        if abs(deltaPosition) <= MusicPlayerConfig.ComparisonPrecision {
            delegate?.playerPlaying(self, atPosition: iTunesPosition)
        } else if deltaPosition < -MusicPlayerConfig.ComparisonPrecision {
            delegate?.player(self, didFastForwardAtPosition: iTunesPosition)
        } else {
            delegate?.player(self, didRewindAtPosition: iTunesPosition)
        }
        timerPosition = iTunesPosition
    }
    
    fileprivate func checkRunningState() {
        timer?.invalidate()
        timer = Timer(timeInterval: 1.5, target: self, selector: #selector(runningState(_:)), userInfo: nil, repeats: false)
        RunLoop.current.add(timer!, forMode: .commonModes)
    }
    
    @objc fileprivate func runningState(_ timer: Timer) {
        guard !iTunes.isRunning else { return }
        delegate?.playerDidQuit(self)
    }
}

// MARK: - Playback Control

extension iTunes: PlaybackControl {
    
    var playbackState: MusicPlaybackState {
        if iTunes.isRunning {
            return MusicPlaybackState(iTunes.playerState)
        } else {
            return .notRunning
        }
    }
    
    var repeatMode: MusicRepeatMode? {
        get {
            guard iTunes.isRunning else { return nil }
            return MusicRepeatMode(iTunes.songRepeat)
        }
        set {
            guard
                iTunes.isRunning,
                newValue != nil
                else {
                    return
            }
            iTunes.songRepeat = newValue!.iTunesERptValue
        }
    }
    
    var shuffleMode: MusicShuffleMode? {
        get {
            guard iTunes.isRunning else { return nil }
            return MusicShuffleMode(iTunes.shuffleMode)
        }
        set {
            guard
                iTunes.isRunning,
                newValue != nil
                else {
                    return
            }
            iTunes.shuffleMode = newValue!.iTunesEShMValue
        }
    }
    
    var playerPosition: TimeInterval {
        get {
            guard iTunes.isRunning else { return 0 }
            return iTunes.playerPosition
        }
        set {
            guard
                iTunes.isRunning,
                newValue >= 0
                else {
                    return
            }
            iTunes.playerPosition = newValue
        }
    }
    
    func play() {
        guard iTunes.isRunning else { return }
        if playbackState != .playing {
            iTunes.playpause()
        }
    }
    
    func pause() {
        guard iTunes.isRunning else { return }
        iTunes.pause()
    }
    
    func stop() {
        guard iTunes.isRunning else { return }
        iTunes.stop()
    }
    
    func playNext() {
        guard iTunes.isRunning else { return }
        iTunes.nextTrack()
    }
    
    func playPrevious() {
        guard iTunes.isRunning else { return }
        iTunes.previousTrack()
    }
}

// MARK: - MusicPlayer

extension iTunes: MusicPlayer {
    
    weak var delegate: MusicPlayerDelegate? {
        get { return _delegate }
        set { _delegate = newValue }
    }
    
    var originalPlayer: SBApplication {
        return iTunes
    }
    
    var currentTrack: MusicTrack? {
        return _currentTrack
    }
    
    var name: MusicPlayerName { return .iTunes }
    
    func startPlayerTracking() {
        _startPlayerTracking()
    }
    
    func stopPlayerTracking() {
        _stopPlayerTracking()
    }
}

// MARK: - Track

fileprivate extension iTunesTrack {
    
    var musicTrack: MusicTrack? {
        guard
            mediaKind == iTunesEMdKSong,
            let name = name
            else {
                return nil
        }
        
        var artwork: NSImage? = nil
        if
            let artworks = artworks(),
            artworks.count > 0,
            let iTunesArtwork = artworks[0] as? iTunesArtwork
        {
            artwork = iTunesArtwork.data
        }

        return MusicTrack(id: String(id()), title: name, album: album, artist: artist, duration: duration, artwork: artwork, lyrics: lyrics, url: nil, originalTrack: self)
    }
    
}

// MARK: - Enum Extension

fileprivate extension MusicPlaybackState {
    
    init(_ playbackState: iTunesEPlS) {
        switch playbackState {
        case iTunesEPlSStopped:
            self = .stopped
        case iTunesEPlSPlaying:
            self = .playing
        case iTunesEPlSPaused:
            self = .paused
        case iTunesEPlSFastForwarding:
            self = .fastForwarding
        case iTunesEPlSRewinding:
            self = .rewinding
        default:
            self = .notRunning
        }
    }
}

fileprivate extension MusicRepeatMode {
    
    init?(_ repeateMode: iTunesERpt) {
        switch repeateMode {
        case iTunesERptOff:
            self = .none
        case iTunesERptOne:
            self = .one
        case iTunesERptAll:
            self = .all
        default:
            return nil
        }
    }
    
    var iTunesERptValue: iTunesERpt {
        switch self {
        case .none:
            return iTunesERptOff
        case .one:
            return iTunesERptOne
        case .all:
            return iTunesERptAll
        }
    }
}

fileprivate extension MusicShuffleMode {
    
    init?(_ shuffleMode: iTunesEShM) {
        switch shuffleMode {
        case iTunesEShMSongs:
            self = .songs
        case iTunesEShMAlbums:
            self = .albums
        case iTunesEShMGroupings:
            self = .groupings
        default:
            return nil
        }
    }
    
    var iTunesEShMValue: iTunesEShM {
        switch self {
        case .songs:
            return iTunesEShMSongs
        case .albums:
            return iTunesEShMAlbums
        case .groupings:
            return iTunesEShMGroupings
        }
    }
}
