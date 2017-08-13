//
//  MusicPlayer.swift
//  LD39
//
//  Created by Steve Johnson on 8/13/17.
//  Copyright © 2017 Steve Johnson. All rights reserved.
//

import Foundation
import AVFoundation

class MusicPlayer {
  var currentTrack: String? = nil
  var players = [String: AVAudioPlayer]()
  var isPlaying: Bool {
    guard let currentTrack = currentTrack, let player = players[currentTrack] else { return false }
    return player.isPlaying
  }
  var player: AVAudioPlayer? {
    guard let currentTrack = currentTrack else { return nil }
    return players[currentTrack]
  }

  static var shared: MusicPlayer = MusicPlayer(track: "1")

  init(track: String) {
    self.prepare(track: track)
  }

  func prepare(track: String?) {
    currentTrack = track
  }

  func getPlayer(forTrack track: String) -> AVAudioPlayer? {
    if let player = players[track] { return player }
    if UserDefaults.pwr_isMusicEnabled, let musicURL = Bundle.main.url(forResource: track, withExtension: "mp3"), let player = try? AVAudioPlayer(contentsOf: musicURL) {
      player.volume = 0.5
      player.numberOfLoops = -1
      player.enableRate = true
      player.rate = 1
      players[track] = player
      return player
    } else {
      return nil
    }
  }

  func play() {
    guard let currentTrack = currentTrack, UserDefaults.pwr_isMusicEnabled else { return }
    getPlayer(forTrack: currentTrack)?.play()
  }

  func pause() {
    player?.pause()
  }

  func toggleMusicSetting() {
    if self.isPlaying {
      UserDefaults.pwr_isMusicEnabled = false
      self.pause()
    } else {
      UserDefaults.pwr_isMusicEnabled = true
      self.play()
    }
  }
}
