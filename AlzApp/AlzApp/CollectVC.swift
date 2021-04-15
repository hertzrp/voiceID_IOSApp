//
//  CollectVC.swift
//  AlzApp
//
//  Created by Wang on 2020/10/25.
//

import UIKit
import AVFoundation

class CollectVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, AVAudioRecorderDelegate, AVAudioPlayerDelegate{
    // Audio-related variables
    

    private var audioString = ""
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
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var ffwdButton: UIButton!
    @IBOutlet weak var rwndButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    // User selection-related variables
    private let recIcon = UIImage(systemName: "largecircle.fill.circle")!
    private let recstopIcon = UIImage(systemName: "stop.circle")!
    private let playIcon = UIImage(systemName: "play")!
    private let pauseIcon = UIImage(systemName: "pause")!
    private let exitIcon = UIImage(systemName: "xmark.square")
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var relationshipLabel: UILabel!
    @IBOutlet weak var nameInput: UITextField!
    @IBOutlet weak var relationshipInput: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    private var idSelected = 0
    var speakers:[(id: Int, name: String)] = [(0,"New Speaker")]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        

        picker.delegate = self
        picker.dataSource = self
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
            recButton.isHidden = true
            disablePlayUI(exceptPlay: true)
            preparePlayer()
            playTapped(playButton!)  // auto play
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
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return speakers.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return speakers[row].name
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        idSelected = speakers[row].id as Int
        if (idSelected == 0){
            nameLabel.isHidden = false
            relationshipLabel.isHidden = false
            nameInput.isHidden = false
            relationshipInput.isHidden = false
        }else{
            nameLabel.isHidden = true
            relationshipLabel.isHidden = true
            nameInput.isHidden = true
            relationshipInput.isHidden = true
        }
    }
    
    // Audio related functions
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

    @IBAction func recTapped(_ sender: Any) {
        if (currState == StateMachine.recording) {
            finishRecording(success: true)
        } else {
            startRecording()
        }
    }
    
    @IBAction func nameDone(_ sender: UITextField) {
        sender.resignFirstResponder()
    }
    @IBAction func relationshipDone(_ sender: UITextField) {
        sender.resignFirstResponder()
    }
    
    @IBAction func doneTapped(_ sender: Any) {
        
        if (idSelected == 0 && (!nameInput.hasText || !relationshipInput.hasText)){
            let alert = UIAlertController(title: "Alert", message: "Please enter both your name and relationship before submitting.", preferredStyle: UIAlertController.Style.alert)

            // add an action (button)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

            // show the alert
            self.present(alert, animated: true, completion: nil)
            return
        }
        if (didRecord == true) {
            do {
                audioString = try Data(contentsOf: audioFile).base64EncodedString(options: .lineLength64Characters)
            }
            catch let error as NSError {
                print(error.localizedDescription)
            }
            audioRecorder.deleteRecording()  // clean up
        }
        
//        let json: [String: Any] = ["id":idSelected,
//                                   "name": nameInput.text ?? "Anonymous",
//                                   "relationship": relationshipInput.text ?? "Unknown",
//                                   "audio": audioString]
//        let jsonData = try? JSONSerialization.data(withJSONObject: json)
//
//        var request = URLRequest(url: URL(string: "https://161.35.116.242/addVoice/")!)
//        request.httpMethod = "POST"
//        request.httpBody = jsonData
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let _ = data, error == nil else {
//                print("NETWORKING ERROR")
//                return
//            }
//            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
//                print("HTTP STATUS: \(httpStatus.statusCode)")
//                return
//            }
//        }
//        task.resume()
        
        let json: [String: Any] = ["name": nameInput.text ?? "Anonymous",
                                   "audio": audioString]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        var request = URLRequest(url: URL(string: "http://ec2-3-138-155-246.us-east-2.compute.amazonaws.com/api/addVoice")!)
        request.httpMethod = "POST"
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let _ = data, error == nil else {
                print("NETWORKING ERROR")
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("HTTP STATUS: \(httpStatus.statusCode)")
                return
            }
        }
        task.resume()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchAfterSubmit"), object: nil)
        self.speakers = []
        dismiss(animated: true, completion: nil)
    }
    @IBAction func collectHelpTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Help", message: "Welcome to Voice Collection. Submit your voice clips to help us identify you. If you are a new speaker, please submit your name and relationship to the user along with the voice clip.", preferredStyle: UIAlertController.Style.alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
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
        prepareRecorder()
        recButton.isEnabled = true
        disablePlayUI(exceptPlay: false)
        doneButton.isEnabled = false
        deleteButton.isEnabled = false
    }
    
    // MARK: Toggle play UI
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


    
}

