//
//  Vox+MusicPlayer.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/9/17.
//

import Foundation
import ScriptingBridge
import VoxBridge

extension Vox: MusicPlayer {
    
    var name: MusicPlayerName { return .vox }
    
    var playbackState: MusicPlaybackState {
        guard isRunning,
            let playerState = vox.playerState
            else { return .stopped }
        return MusicPlaybackState(playerState)
    }
    
    var repeatMode: MusicRepeatMode? {
        get {
            guard isRunning,
                let repeateState = vox.repeatState
                else { return nil }
            return MusicRepeatMode(repeateState)
        }
        set {
            guard isRunning,
                let repeateState = newValue?.intValue
                else { return }
            vox.setRepeatState?(repeateState)
        }
    }
    
    var shuffleMode: MusicShuffleMode? {
        get { return nil }
        set {}
    }
    
    var playerPosition: TimeInterval {
        get {
            guard isRunning,
                let currentTime = vox.currentTime
                else { return 0 }
            return currentTime
        }
        set {
            guard isRunning,
                newValue >= 0
                else { return }
            vox.setCurrentTime?(newValue)
        }
    }
    
    func play() {
        guard isRunning else { return }
        vox.play?()
    }
    
    func pause() {
        guard isRunning else { return }
        vox.pause?()
    }
    
    func stop() {
        guard isRunning else { return }
        vox.pause?()
    }
    
    func playNext() {
        guard isRunning else { return }
        vox.next?()
    }
    
    func playPrevious() {
        guard isRunning else { return }
        vox.previous?()
    }
    
    var originalPlayer: SBApplication {
        return vox as! SBApplication
    }
}

// MARK: - Enum Extension

fileprivate extension MusicPlaybackState {
    
    init(_ playbackState: Int) {
        switch playbackState {
        case 0:
            self = .paused
        case 1:
            self = .playing
        default:
            self = .stopped
        }
    }
}

fileprivate extension MusicRepeatMode {
    
    init?(_ repeatMode: Int) {
        switch repeatMode {
        case 0:
            self = .none
        case 1:
            self = .one
        case 2:
            self = .all
        default:
            return nil
        }
    }
    
    var intValue: Int {
        switch self {
        case .none:
            return 0
        case .one:
            return 1
        case .all:
            return 2
        }
    }
    
}
