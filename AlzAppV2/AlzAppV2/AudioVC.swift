//
//  AudioVC.swift
//  AlzAppV2
//
//  Created by Wang on 2020/11/22.
//

import Foundation
import AVFoundation
import UIKit

class AudioVC: UIViewController,AVAudioRecorderDelegate, AVAudioPlayerDelegate{
    weak var audioReturnDelegate : AudioReturnDelegate?
    var audioString = ""
    var photoString = ""
    private var audioSession: AVAudioSession!
    private var audioRecorder: AVAudioRecorder!
    private var audioPlayer: AVAudioPlayer!
    private let audioFile = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("chatteraudio.m4a")
    private var didRecord = false
    
    enum StateMachine {
        case start, playing, recording, paused
    }
    private var currState : StateMachine!
    
    private let recIcon = UIImage(systemName: "largecircle.fill.circle")!
    private let recstopIcon = UIImage(systemName: "stop.circle")!
    private let playIcon = UIImage(systemName: "play")!
    private let pauseIcon = UIImage(systemName: "pause")!
    private let exitIcon = UIImage(systemName: "xmark.square")!

    @IBOutlet weak var recButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var ffwdButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var rwndButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            // failed to record handler
            print("viewDidLoad: failed to setup session")
            dismiss(animated: true, completion: nil)
        }
        func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
            print("Error encoding audio: \(error!.localizedDescription)")
            finishRecording(success: false)
            // don't dismiss in case user wants to record again
        }
        
        currState = StateMachine.start

        if (audioString == "") {
            prepareRecorder()
            recButton.isEnabled = true
            disablePlayUI(exceptPlay: false)
            doneButton.isEnabled = false
            deleteButton.isEnabled = false
        } else {
            recButton.isEnabled = true
            doneButton.isEnabled = true
            deleteButton.isEnabled = true
            ffwdButton.isEnabled = false
            rwndButton.isEnabled = false
            prepareRecorder()
            preparePlayer()
            //playTapped(playButton!)  // auto play
        }

    }

    func prepareRecorder() {
        // check permission first
        audioSession.requestRecordPermission() { allowed in
            if !allowed {
                print("prepareRecorder: no permission to record")
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            //AVFormatIDKey: Int(kAudioFormatMPEGLayer3),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: audioFile, settings: settings)
            audioRecorder.delegate = self
        } catch {
            print("prepareRecorder: failed")
            dismiss(animated: true, completion: nil)
        }
    }
    func preparePlayer() {
        do {
            if audioString == "" {
                audioPlayer = try AVAudioPlayer(contentsOf: audioFile)
            } else {
                audioPlayer = try AVAudioPlayer(data: Data(base64Encoded: audioString, options: .ignoreUnknownCharacters)!)
            }
        } catch let err as NSError {
            print("AVAudioPlayer error: \(err.localizedDescription)")
            dismiss(animated: true, completion: nil)
        }
        audioPlayer.volume = 10.0
        audioPlayer.delegate = self
        audioPlayer.prepareToPlay()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        finishPlaying()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Error while playing audio \(error!.localizedDescription)")
        // don't dismiss, in case user wants to record
        finishPlaying()
    }
    func disablePlayUI(exceptPlay: Bool) {
        // when disabled, always reset playButton to playIcon
        playButton.setImage(playIcon, for: .normal)
        playButton.isEnabled = exceptPlay
        rwndButton.isEnabled = false
        ffwdButton.isEnabled = false
        deleteButton.isEnabled = true
        doneButton.isEnabled = true

    }
    
    func enablePlayUI() {
        rwndButton.isEnabled = true
        ffwdButton.isEnabled = true
        deleteButton.isEnabled = false
        doneButton.isEnabled = false

    }
    func finishPlaying() {
        currState = StateMachine.start
        disablePlayUI(exceptPlay:true)
        recButton.isEnabled = true
    }
    
    func startRecording() {
        currState = StateMachine.recording
        disablePlayUI(exceptPlay: false)
        doneButton.isEnabled = false
        deleteButton.isEnabled = false
        recButton.setImage(recstopIcon, for: .normal)
        
        audioRecorder.record()
    }
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        
        currState = StateMachine.start
        recButton.setImage(recIcon, for: .normal)
        doneButton.isEnabled = true
        deleteButton.isEnabled = true

        if success != true {
            print("finishRecording: failed to record")
        } else {
            didRecord = true
            playButton.isEnabled = true
            preparePlayer()
        }
    }
    
    @IBAction func playTapped(_ sender: Any) {
        if (currState == StateMachine.playing) {
            currState = StateMachine.paused
            playButton.setImage(playIcon, for: .normal)
            recButton.isEnabled = true
            audioPlayer.pause()
        } else {
            currState = StateMachine.playing
            playButton.setImage(pauseIcon, for: .normal)
            enablePlayUI()
            recButton.isEnabled = false
            audioPlayer.play()
        }
    }
    
    @IBAction func rwndTapped(_ sender: Any) {
        audioPlayer.currentTime -= 10.0 // seconds
        if (audioPlayer.currentTime < 0) {
            audioPlayer.currentTime = 0
        }
    }
    
    @IBAction func ffwdTapped(_ sender: Any) {
        audioPlayer.currentTime += 10.0 // seconds
        if (audioPlayer.currentTime > audioPlayer.duration) {
            audioPlayer.currentTime = audioPlayer.duration
        }
    }
    @IBAction func deleteTapped(_ sender: Any) {
        audioString = ""
        currState = StateMachine.start
        audioRecorder.deleteRecording()
        prepareRecorder()
        recButton.isEnabled = true
        disablePlayUI(exceptPlay: false)
        doneButton.isEnabled = false
        deleteButton.isEnabled = false
    }
    @IBAction func recTapped(_ sender: Any) {
        if (currState == StateMachine.recording) {
            finishRecording(success: true)
        } else {
            startRecording()
        }
    }
    func writeAudioString(){
        if (didRecord == true) {
            do {
                audioString = try Data(contentsOf: audioFile).base64EncodedString(options: .lineLength64Characters)
            }
            catch let error as NSError {
                print(error.localizedDescription)
            }
            audioRecorder.deleteRecording()  // clean up
        }
    }
    @IBAction func doneTapped(_ sender: Any) {
        writeAudioString()
        audioReturnDelegate?.audioDidReturn(audioString)
        dismiss(animated: true, completion: nil)
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if (currState == StateMachine.recording) {
            finishRecording(success: true)
        }
        writeAudioString()
        audioReturnDelegate?.audioDidReturn(audioString)
        dismiss(animated: true, completion: nil)
        
    }

    
}
