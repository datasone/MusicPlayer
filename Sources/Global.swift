//
//  Global.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/9/2.
//

import Foundation

// MARK: - Global Var

extension Notification.Name {
    static let iTunesPlayerInfo = Notification.Name("com.apple.iTunes.playerInfo")
    static let SpotifyPlayerInfo = Notification.Name("com.spotify.client.PlaybackStateChanged")
    static let VoxTrackChanged = Notification.Name("com.coppertino.Vox.trackChanged")
}

// MARK: - Global Method Replacement

#if !DEBUG
    func NSLog(_ format: String, _ args: CVarArg...) {}
    func print(_ item: Any) {}
#endif
