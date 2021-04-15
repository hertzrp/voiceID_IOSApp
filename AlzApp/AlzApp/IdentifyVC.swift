//
//  IdentifyVC.swift
//  AlzApp
//
//  Created by Wang on 2020/10/26.
//

import Foundation
//
//  CollectVC.swift
//  AlzApp
//
//  Created by Wang on 2020/10/25.
//

import UIKit
import AVFoundation

class IdentifyVC: UIViewController,AVAudioRecorderDelegate, AVAudioPlayerDelegate{
    // Audio-related variables
    var audioString = ""
    private var audioSession: AVAudioSession!
    private var audioRecorder: AVAudioRecorder!
    private var audioPlayer: AVAudioPlayer!
    private let audioFile = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("chatteraudio.m4a")
    private var didRecord = false
    enum StateMachine {
        case start, playing, recording, paused
    }
    private var currState : StateMachine!
    @IBOutlet weak var recButton: UIButton!
    @IBOutlet weak var detailLabel: UILabel!
    private let recIcon = UIImage(systemName: "mic.circle")!
    private let recstopIcon = UIImage(systemName: "mic.circle.fill")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        audioString = ""
        prepareRecorder()
        recButton.isEnabled = true

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
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // Audio related functions


    func startRecording() {
        currState = StateMachine.recording
        recButton.setImage(recstopIcon, for: .normal)
        
        audioRecorder.record()
    }
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        
        currState = StateMachine.start
        recButton.setImage(recIcon, for: .normal)

        if success != true {
            print("finishRecording: failed to record")
        } else {
            didRecord = true
            detailLabel.text = "Waiting for results"
            recButton.isHidden = true
            let json: [String: Any] = ["audio": audioString]
            let jsonData = try? JSONSerialization.data(withJSONObject: json)

            var request = URLRequest(url: URL(string: "https://161.35.116.242/identify/")!)
            request.httpMethod = "POST"
            request.httpBody = jsonData

            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                do {
                    let json = try JSONSerialization.jsonObject(with: data!) as! [String:String]
                    let name = json["name"]!
                    let relationship = json["relationship"]!
                    
                    if !name.isEmpty{
                        DispatchQueue.main.async {
                            self.detailLabel.text = "Name: " + name + "\n\nRelationship: " + relationship
                            self.detailLabel.numberOfLines = 3
                        }
                        
                    }else{
                        DispatchQueue.main.async {
                            self.detailLabel.text = "Oops! We couldn't identify speaker. Please navigate to Voice Collection to help us fine tune our algorithm."
                            self.detailLabel.numberOfLines = 3
                        }
                    }

                    
                } catch let error as NSError {
                    print(error)
                }
                self.reset()
            }
            task.resume()

        }
    }
    @IBAction func identifyHelpTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Help", message: "Welcome to Speaker Identification. Press the record button to record your voice. Press it again to send the voice clip to our identification algorithm. If we didn't correctly identify you, head to the voice collection scene to help us fine-tune our algorithm.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    @IBAction func recTapped(_ sender: Any) {
        if (currState == StateMachine.recording) {
            finishRecording(success: true)
        } else {
            startRecording()
        }
    }
    func reset(){
        audioString = ""
        currState = StateMachine.start
        prepareRecorder()
        DispatchQueue.main.async {
            self.recButton.setImage(self.recIcon, for: .normal)
            self.recButton.isHidden = false
        }


    }
    
}
