//
//  MusicPlayer.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/9/17.
//

import Cocoa
import ScriptingBridge

struct MusicPlayerConfig {
    static let TimerInterval = 0.5
    static let Precision = 0.25
}

public protocol MusicPlayer: class {
    
    init?()
    weak var delegate: MusicPlayerDelegate? { get set }
    var name: MusicPlayerName { get }
    var currentTrack: MusicTrack? { get }
    var playbackState: MusicPlaybackState { get }
    var repeatMode: MusicRepeatMode? { get set }
    var shuffleMode: MusicShuffleMode? { get set }
    var playerPosition: TimeInterval { get set }
    var trackStartTime: TimeInterval { get }
    var originalPlayer: SBApplication { get }
    
    func play()
    func pause()
    func stop()
    func playNext()
    func playPrevious()
    
    /// Make the player start Tracking the external player.
    func startPlayerTracking()
    
    /// Make the player stop Tracking the external player.
    func stopPlayerTracking()
}

public extension MusicPlayer {
    
    public var isRunning: Bool {
        return originalPlayer.isRunning
    }
    
    public func activate() {
        originalPlayer.activate()
    }
}

// MARK: - Check Event

extension MusicPlayer {
    
    var trackStartTime: TimeInterval {
        let currentTime = NSDate().timeIntervalSince1970
        return currentTime - playerPosition
    }
}
