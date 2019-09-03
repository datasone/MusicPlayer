//
//  OAScript.swift
//
//  This file is part of LyricsX
//  Copyright (C) 2019  datasone
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

import AppKit
import ScriptingBridge

public final class AppleScriptPlayer {
    
    public weak var delegate: MusicPlayerDelegate?
    
    private var _currentTrack: MusicTrack?
    private var _playbackState: MusicPlaybackState = .stopped
    private var _startTime: Date?
    private var _pausePosition: Double?
    
    private var startTime: Date? {
        return Date().addingTimeInterval(-playerPosition)
    }
    
    private var pausePosition: TimeInterval?
    
    public init?() {}

    func updatePlayerPosition() {
        if _playbackState.isPlaying {
            if let _startTime = self._startTime,
                let startTime = self.startTime,
                abs(startTime.timeIntervalSince(_startTime)) > positionMutateThreshold {
                self._startTime = startTime
                delegate?.playerPositionMutated(position: playerPosition, from: self)
            }
        } else {
            if let _pausePosition = self._pausePosition,
                let pausePosition = self.pausePosition,
                abs(_pausePosition - pausePosition) > positionMutateThreshold {
                self._pausePosition = pausePosition
                self.playerPosition = pausePosition
                delegate?.playerPositionMutated(position: playerPosition, from: self)
            }
        }
    }
    
}

extension AppleScriptPlayer: MusicPlayer {
    
    public static var name: MusicPlayerName = .asplayer
    
    public static var needsUpdateIfNotSelected = false
    
    public var playbackState: MusicPlaybackState {
        return _playbackState
    }
    
    public var currentTrack: MusicTrack? {
        return _currentTrack
    }
    
    public var playerPosition: TimeInterval {
        get {
            guard _playbackState.isPlaying else { return _pausePosition ?? 0 }
            guard let _startTime = self._startTime else { return 0 }
            return -_startTime.timeIntervalSinceNow
        }
        set {
            // originalPlayer.setValue(newValue, forKey: "playerPosition")
            self._startTime = Date().addingTimeInterval(-newValue)
        }
    }
    
    public func updatePlayerState() {
        updatePlayerPosition()
    }
    
    public func updatePlayerState(state: MusicPlaybackState, position: TimeInterval) {
        _playbackState = state
        playerPosition = position
        if (!_playbackState.isPlaying) {
            pausePosition = position
        }
        updatePlayerPosition()
    }
    
    public func updateCurrentTrack(title: String, album: String, artist: String, duration: TimeInterval, url: URL?) {
        let id = "AppleScriptPlayer-" + title  + album + artist + String(duration)
        _currentTrack = MusicTrack(id: id, title: title, album: album, artist: artist, duration: duration, url: url, artwork: nil, originalTrack: nil)
        delegate?.currentTrackChanged(track: currentTrack, from: self)
        updatePlayerState(state: MusicPlaybackState.playing, position: 0)
    }
    
    public func resume() {}
    
    public func pause() {}
    
    public func playPause() {}
    
    public func skipToNextItem() {}
    
    public func skipToPreviousItem() {}
    
    public var originalPlayer: SBApplication {
        return SBApplication(bundleIdentifier: iTunes.name.bundleID)!
    }
}
