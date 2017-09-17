//
//  AppDelegate.swift
//  MusicPlayerDemo
//
//  Created by Michael Row on 2017/9/9.
//

import Cocoa
import MusicPlayer

// This simple demo is to show how to use the MusicPlayerManager, so it's really rough.

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, MusicPlayerManagerDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var iTunesCheck: NSButton!
    @IBOutlet weak var spotifyCheck: NSButton!
    @IBOutlet weak var voxCheck: NSButton!
    @IBOutlet weak var textView: NSTextView!
    
    var manager = MusicPlayerManager()
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        manager.delegate = self
    }
    
    /// A place to add/remove music players for the manager.
    @IBAction func checkBoxValueChange(_ sender: NSButton) {
        guard let playerName = playerName(from: sender) else { return }
        if sender.state == 1 {
            // log it
            append(log: "Add Player: \(playerName.rawValue)")
            manager.add(musicPlayer: playerName)
        } else if sender.state == 0 {
            // log it
            append(log: "Remove Player: \(playerName.rawValue)")
            manager.remove(musicPlayer: playerName)
        }
    }
    
    func manager(_ manager: MusicPlayerManager, trackingPlayer player: MusicPlayer, didChangeTrack track: MusicTrack, atPosition position: TimeInterval) {
        // do nothing, simply log it
        append(log: "\(player.name.rawValue)'s track Changed to \(track.title)")
    }
    
    func manager(_ manager: MusicPlayerManager, trackingPlayer player: MusicPlayer, playbackStateChanged playbackState: MusicPlaybackState, atPosition position: TimeInterval) {
        // we'd like to see the current playback state.
        append(log: "\(player.name.rawValue)'s playback state Changed to \(playbackState)")
    }
    
    func manager(_ manager: MusicPlayerManager, trackingPlayerDidQuit player: MusicPlayer) {
        // Let's see who quited.
        append(log: "\(player.name.rawValue) quited")
    }
    
    func manager(_ manager: MusicPlayerManager, trackingPlayerDidChange player: MusicPlayer) {
        // And rarely, our user use more than one player at the same (or near) time.
        append(log: "Tracking player change to \(player.name.rawValue)")
    }
    
    //MARK: - Private
    
    private func playerName(from sender: NSButton) -> MusicPlayerName? {
        if sender === iTunesCheck {
            return .iTunes
        } else if sender === voxCheck {
            return .vox
        } else if sender === spotifyCheck {
            return .spotify
        }
        return nil
    }
    
    private func append(log: String) {
        guard var str = textView.string else { return }
        str.append(log+"\n")
        textView.string = str
        textView.scrollRangeToVisible(NSRange(location: str.characters.count - 1, length: 1))
    }
}

