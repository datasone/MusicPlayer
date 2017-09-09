//
//  MusicPlayerManagerDelegate.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/9/4.
//

import Foundation

public protocol MusicPlayerManagerDelegate: class {
    
    /// Tells the delegate the manager's tracking player has changed track.
    ///
    /// - Parameters:
    ///   - manager: The manager to handle all players.
    ///   - name: Name of the music player.
    ///   - track: The track the player change to.
    ///   - position: The player's current playing position.
    func manager(_ manager: MusicPlayerManager, trackingPlayer name: MusicPlayerName, didChangeTrack track: MusicTrack, atPosition position: TimeInterval)
    
    
    /// Tells the delegate the playback state of the tracking player has been changed.
    ///
    /// - Parameters:
    ///   - manager: The manager to handle all players.
    ///   - name: Name of the music player.
    ///   - playbackState: The player's playback state.
    ///   - position: The player's current playing position.
    func manager(_ manager: MusicPlayerManager, trackingPlayer name: MusicPlayerName, playbackStateChanged playbackState: MusicPlaybackState, atPosition position: TimeInterval)
    
    
    /// Tells the delegate the manager's tracking player has quitted.
    ///
    /// - Parameters:
    ///   - manager: The manager to handle all players.
    ///   - name: Name of the music player.
    func manager(_ manager: MusicPlayerManager, trackingPlayerDidQuit name: MusicPlayerName)
    
    
    /// Tells the delegate the manager has changed its tracking player.
    ///
    /// - Parameters:
    ///   - manager: The manager to handle all players.
    ///   - name: Name of the new music player.
    func manager(_ manager: MusicPlayerManager, trackingPlayerDidChange name: MusicPlayerName)
    
}
