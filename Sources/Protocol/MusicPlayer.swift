//
//  MusicPlayer.swift
//
//  This file is part of LyricsX
//  Copyright (C) 2017  Xander Deng
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Cocoa
import ScriptingBridge

public enum MusicPlaybackState {
    case stopped
    case playing
    case paused
    case fastForwarding
    case rewinding
    
    var isActiveState: Bool {
        switch self {
        case .playing, .fastForwarding, .rewinding:
            return true
        default:
            return false
        }
    }
}

public enum MusicRepeatMode {
    case none
    case one
    case all
}

public enum MusicShuffleMode {
    case songs
    case albums
    case groupings
}

public enum MusicPlayerName: String {
    case iTunes = "iTunes"
    case vox = "Vox"
    case spotify = "Spotify"
    
    var bundleID: String {
        switch self {
        case .iTunes:
            return "com.apple.iTunes"
        case .vox:
            return "com.coppertino.Vox"
        case .spotify:
            return "com.spotify.client"
        }
    }
}

struct MusicPlayerConfig {
    static let TimerInterval = 0.5
    static let Precision = 0.25
}

public struct MusicTrack {
    
    public private(set) var id: String
    public private(set) var title: String
    public private(set) var album: String?
    public private(set) var artist: String?
    public private(set) var duration: TimeInterval
    public var artwork: NSImage?
    public var lyrics: String?
    public var url: URL?
    
    public private(set) var originalTrack: SBObject?
}

extension MusicTrack: Equatable {
    public static func ==(lhs: MusicTrack, rhs: MusicTrack) -> Bool {
        return lhs.id == rhs.id
    }
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

extension MusicPlayer {
    
    public var isRunning: Bool {
        return originalPlayer.isRunning
    }
    
    public func activate() {
        originalPlayer.activate()
    }
}


