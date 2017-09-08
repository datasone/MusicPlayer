//
//  iTunes.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/8/31.
//

import Foundation
import BridgeHeader.iTunes


class iTunes {
    
    weak var delegate: MusicPlayerDelegate?
    
    fileprivate(set) var currentTrack: MusicTrack?
    
    fileprivate var iTunes: iTunesApplication
    
    fileprivate var timer: Timer?
    
    fileprivate var timerPosition: TimeInterval = 0
    
    required init?() {
        guard let player = iTunesApplication(bundleIdentifier: MusicPlayerName.iTunes.bundleID) else { return nil }
        iTunes = player
    }
    
    deinit {
        stopPlayerTracking()
    }
    
    func startPlayerTracking() {
        generatePlayingEvent()
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(playerInfoChanged(_:)), name: NSNotification.Name.iTunesPlayerInfo, object: nil)
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
            // Rewind and fast forward would send pause notification.
            guard playbackState == .paused else { return }
            delegate?.player(self, playbackStateChanged: .paused, atPosition: playerPosition)
            checkRunningState()
            
        case "Stopped":
            delegate?.player(self, playbackStateChanged: .stopped, atPosition: playerPosition)
            checkRunningState()
            
        case "Playing":
            let currentPosition = playerPosition
            // Check whether track changed.
            if let newTrack = iTunes.currentTrack.musicTrack,
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
        
        if let location = userInfo["Location"] as? String {
            currentTrack?.url = URL(fileURLWithPath: location)
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
        if deltaPosition < -MusicPlayerConfig.ComparisonPrecision {
            delegate?.player(self, playbackStateChanged: .fastForwarding, atPosition: iTunesPosition)
        } else if deltaPosition > MusicPlayerConfig.ComparisonPrecision {
            delegate?.player(self, playbackStateChanged: .rewinding, atPosition: iTunesPosition)
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

// MARK: - Music Player

extension iTunes: MusicPlayer {
    
    var name: MusicPlayerName { return .iTunes }
    
    var playbackState: MusicPlaybackState {
        if iTunes.isRunning {
            return MusicPlaybackState(iTunes.playerState)
        } else {
            return .stopped
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
            else { return }
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
    
    var originalPlayer: SBApplication {
        return iTunes
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

// MARK: - Track

fileprivate extension iTunesTrack {
    
    var musicTrack: MusicTrack? {
        guard mediaKind == iTunesEMdKSong,
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
            self = .stopped
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
