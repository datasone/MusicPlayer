//
//  iTunes.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/8/31.
//

import Cocoa
import ScriptingBridge
import iTunesBridge

class iTunes {
    
    weak var delegate: MusicPlayerDelegate?
    
    fileprivate(set) var currentTrack: MusicTrack?
    
    fileprivate var iTunes: iTunesApplication
    
    fileprivate var timer: Timer?
    
    fileprivate var timerPosition: TimeInterval = 0
    
    required init?() {
        guard let player = SBApplication(bundleIdentifier: MusicPlayerName.iTunes.bundleID) else { return nil }
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
            if let newTrack = iTunes.currentTrack?.musicTrack,
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
        timerPosition = playerPosition
        timer = Timer(timeInterval: MusicPlayerConfig.TimerCheckingInterval, target: self, selector: #selector(playingEvent(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .commonModes)
    }
    
    @objc fileprivate func playingEvent(_ timer: Timer) {
        guard playbackState == .playing,
              let iTunesPosition = iTunes.playerPosition
        else {
            timer.invalidate()
            return
        }
        
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
        guard !isRunning else { return }
        delegate?.playerDidQuit(self)
    }
}

// MARK: - Music Player

extension iTunes: MusicPlayer {
    
    var name: MusicPlayerName { return .iTunes }
    
    var playbackState: MusicPlaybackState {
        guard isRunning,
              let playerState = iTunes.playerState
        else { return .stopped }
        return MusicPlaybackState(playerState)
    }
    
    var repeatMode: MusicRepeatMode? {
        get {
            guard isRunning,
                  let songRepeat = iTunes.songRepeat
            else { return nil }
            return MusicRepeatMode(songRepeat)
        }
        set {
            guard isRunning,
                  let songRepeat = newValue?.iTunesERptValue
            else { return }
            iTunes.setSongRepeat?(songRepeat)
        }
    }
    
    var shuffleMode: MusicShuffleMode? {
        get {
            guard isRunning,
                  let shuffleMode = iTunes.shuffleMode
            else { return nil }
            return MusicShuffleMode(shuffleMode)
        }
        set {
            guard isRunning,
                  let shuffleMode = newValue?.iTunesEShMValue
            else { return }
            iTunes.setShuffleMode?(shuffleMode)
        }
    }
    
    var playerPosition: TimeInterval {
        get {
            guard isRunning,
                  let playerPosition = iTunes.playerPosition
            else { return 0 }
            return max(playerPosition, 0)
        }
        set {
            guard isRunning,
                  newValue >= 0
            else { return }
            iTunes.setPlayerPosition?(newValue)
        }
    }
    
    var originalPlayer: SBApplication {
        return iTunes as! SBApplication
    }
    
    func play() {
        guard isRunning,
              playbackState != .playing
        else { return }
        iTunes.playpause?()
    }
    
    func pause() {
        guard isRunning else { return }
        iTunes.pause?()
    }
    
    func stop() {
        guard isRunning else { return }
        iTunes.stop?()
    }
    
    func playNext() {
        guard isRunning else { return }
        iTunes.nextTrack?()
    }
    
    func playPrevious() {
        guard isRunning else { return }
        iTunes.previousTrack?()
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

// MARK: - Enum Extension

fileprivate extension MusicPlaybackState {
    
    init(_ playbackState: iTunesEPlS) {
        switch playbackState {
        case .stopped:
            self = .stopped
        case .playing:
            self = .playing
        case .paused:
            self = .paused
        case .fastForwarding:
            self = .fastForwarding
        case .rewinding:
            self = .rewinding
        }
    }
}

fileprivate extension MusicRepeatMode {
    
    init(_ repeateMode: iTunesERpt) {
        switch repeateMode {
        case .off:
            self = .none
        case .one:
            self = .one
        case .all:
            self = .all
        }
    }
    
    var iTunesERptValue: iTunesERpt {
        switch self {
        case .none:
            return .off
        case .one:
            return .one
        case .all:
            return .all
        }
    }
}

fileprivate extension MusicShuffleMode {
    
    init(_ shuffleMode: iTunesEShM) {
        switch shuffleMode {
        case .songs:
            self = .songs
        case .albums:
            self = .albums
        case .groupings:
            self = .groupings
        }
    }
    
    var iTunesEShMValue: iTunesEShM {
        switch self {
        case .songs:
            return .songs
        case .albums:
            return .albums
        case .groupings:
            return .groupings
        }
    }
}
