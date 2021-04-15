//
//  MainVC.swift
//  AlzAppV2
//
//  Created by Wang on 2020/11/16.
//
import Foundation
import AVFoundation
import UIKit
import FDSoundActivatedRecorder

struct IdResponse: Decodable {
    var name: String
    var relationship: String
    var photo:String
    var label:String
    var score:String
}

class MainVC: UIViewController,AVAudioRecorderDelegate, AVAudioPlayerDelegate, FDSoundActivatedRecorderDelegate, ResultReturnDelegate{
    func soundActivatedRecorderDidStartRecording(_ recorder: FDSoundActivatedRecorder) {
        DispatchQueue.main.async {
            self.currState = StateMachine.recording
            self.recButton.setImage(self.recstopIcon, for: .normal)
            self.detailLabel.text = "Stop speaking when ready"
        }
        
    }
    
    func soundActivatedRecorderDidTimeOut(_ recorder: FDSoundActivatedRecorder) {
    }
    
    func soundActivatedRecorderDidAbort(_ recorder: FDSoundActivatedRecorder) {
    }
    
    func soundActivatedRecorderDidFinishRecording(_ recorder: FDSoundActivatedRecorder, andSaved file: URL) {
        audioFile = file
        didRecord = true
        finishRecording(success: true)
    }
    
    var main_speakers:[(id: Int, name: String, relationship:String, photo:String)] = [(-1,"New Speaker","Unknown","")]

    var audioString = ""
    var nameString = ""
    var relationshipString = ""
    var photoString = ""
    private var audioSession: AVAudioSession!
    //private var audioRecorder: AVAudioRecorder!
    //private var audioPlayer: AVAudioPlayer!
    //private let audioFile = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("chatteraudio.m4a")
    private var didRecord = false
    private var audioFile: URL!
    private var recorder: FDSoundActivatedRecorder!
    private var returnToMain = false
    enum StateMachine {
        case start, playing, recording, paused
    }
    private let recIcon = UIImage(systemName: "mic.circle")!
    private let recstopIcon = UIImage(systemName: "mic.circle.fill")!
    private var currState : StateMachine!
    
    @IBOutlet weak var collectButton: UIButton!
    @IBOutlet weak var communityButton: UIButton!
    
    @IBOutlet weak var recButton: UIButton!
    
    
    @IBOutlet weak var detailLabel: UILabel!
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

        recorder.startListening()

        returnToMain = false
        
        fetchData()
        NotificationCenter.default.addObserver(self, selector: #selector(fetchAfterSubmit(_:)), name: Notification.Name(rawValue: "fetchAfterSubmit"), object: nil)

    }
    
    @objc func fetchAfterSubmit(_ notification: Notification) {
        DispatchQueue.main.async {
            self.collectButton.isEnabled = false
            self.communityButton.isEnabled = false
        }
        let delayTime = DispatchTime.now() + 1.5
        DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
            self.getSpeakers()
        })
    }
    
    func getSpeakers() {
        //let requestURL = "https://161.35.116.242/getSpeakersV2/"
        let requestURL = "https://18.217.201.244/getspeakers/"
        var request = URLRequest(url: URL(string: requestURL)!)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            do {
                self.main_speakers = [(-1,"New Speaker","Unknown","")]
                let json = try JSONSerialization.jsonObject(with: data!) as! [String:Any]
//                for speakerEntry in json["speakers"] as? [[Any]] ?? []{
//                    print(speakerEntry)
//                    self.main_speakers.append((speakerEntry[0] as! Int,speakerEntry[1] as! String, speakerEntry[2] as! String, speakerEntry[3] as! String))
//                    //self.main_speakers.append((speakerEntry["id"] as! Int,speakerEntry["name"] as! String, speakerEntry["relationship"] as! String, speakerEntry["photo"] as! String))
//                }
                for speakerEntry in json["speakers"] as! [[String : Any]]{
                    print(speakerEntry)
                    //self.main_speakers.append((speakerEntry[0] as! Int,speakerEntry[1] as! String, speakerEntry[2] as! String, speakerEntry[3] as! String))
                    self.main_speakers.append((speakerEntry["speakerID"] as! Int,speakerEntry["fullname"] as! String, speakerEntry["relationship"] as! String, speakerEntry["photo"] as! String))
                }

            } catch let error as NSError {
                print(error)
            }
            DispatchQueue.main.async {
                self.collectButton.isEnabled = true
                self.communityButton.isEnabled = true
            }
            
        }
        task.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // turn off automatic voice detection
        self.recorder.abort()
        self.recButton.isEnabled = false
        
        if segue.identifier == "CollectSegue"{
            let collectVC = segue.destination as! CollectVC
            collectVC.speakers = main_speakers
        }
        if segue.identifier == "CommunitySegue"{
            let communityVC = segue.destination as! CommunityVC
            communityVC.speakers = main_speakers
        }
        if segue.identifier == "ResultSegue"{
            let resultVC = segue.destination as! ResultVC
            resultVC.nameString = nameString
            resultVC.relationshipString = relationshipString
            resultVC.photoString = photoString
            resultVC.resultReturnDelegate = self
            resultVC.showIncorrect = true
        }
        returnToMain = true

    }
    
    // turn on automatic voice detection when returning to main menu
    // from other scenes
    
    func enableRecording(){
        DispatchQueue.main.async {
            if self.returnToMain {
                self.audioString = ""
                self.currState = StateMachine.start
                if self.recButton.isEnabled == false{
                    self.detailLabel.text = "Loading recorder"
                }
                self.recButton.setImage(self.recIcon, for: .normal)
                self.didRecord = false
                self.prepareRecorder()
                
                // delay automatic voice detection
                let delayTime = DispatchTime.now() + 1.5
                DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
                    self.detailLabel.text = "Start identifying voice"
                    self.recButton.isEnabled = true
                    self.recorder.startListening()

                })
            }
        }
        
    }
    override func viewDidAppear(_ animated: Bool) {
        enableRecording()
    }
    func resultDidReturn() {
        enableRecording()
    }
    
    @IBAction func recTapped(_ sender: Any) {
        if (currState == StateMachine.recording) {
            recorder.stopAndSaveRecording()
        } else {
            recorder.startRecording()
        }
    }
    
    
    func fetchData(){
        DispatchQueue.main.async {
            self.collectButton.isEnabled = false
            self.communityButton.isEnabled = false
            
        }
        DispatchQueue.main.async {
            self.getSpeakers()
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
//        let settings = [
//            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
//            //AVFormatIDKey: Int(kAudioFormatMPEGLayer3),
//            AVSampleRateKey: 12000,
//            AVNumberOfChannelsKey: 1,
//            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
//        ]
//        do {
//            audioRecorder = try AVAudioRecorder(url: audioFile, settings: settings)
//            audioRecorder.delegate = self
//        } catch {
//            print("prepareRecorder: failed")
//            dismiss(animated: true, completion: nil)
//        }
        self.recorder = FDSoundActivatedRecorder()
        self.recorder.delegate = self
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // Audio related functions
    func writeAudioString(){
        if (didRecord == true) {
            do {
                audioString = try Data(contentsOf: audioFile).base64EncodedString(options: .lineLength64Characters)
            }
            catch let error as NSError {
                print(error.localizedDescription)
            }
            recorder.abort()
            //audioRecorder.deleteRecording()  // clean up
        }
    }
    func finishRecording(success: Bool) {
        //audioRecorder.stop()
        currState = StateMachine.start
        recButton.setImage(recIcon, for: .normal)

        if success != true {
            print("finishRecording: failed to record")
        } else {
            didRecord = true
            writeAudioString()
            detailLabel.text = "Waiting for results ..."
            recButton.setImage(recIcon, for: .normal)
            recButton.isEnabled = false
            let json: [String: Any] = ["audio": audioString]
            let jsonData = try? JSONSerialization.data(withJSONObject: json)

            //var identify_request = URLRequest(url: URL(string: "https://161.35.116.242/identifyV2/")!)
            var identify_request = URLRequest(url: URL(string: "https://18.217.201.244/api/ios/identify/")!)
            identify_request.httpMethod = "POST"
            identify_request.httpBody = jsonData
            
            identify_request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")  // the request is JSON
            identify_request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")        // the expected response is also JSON

            let task = URLSession.shared.dataTask(with: identify_request) { (data, response, error) in
                do {
                    //let res = try JSONDecoder().decode(IdResponse.self, from: data!)
                    //print(res)
                    //var mdata = String(data: data!, encoding: .utf8)
                    let json = try JSONSerialization.jsonObject(with: data!) as! [String:String]
                    self.nameString = json["name"]!
                    //self.nameString = json["name"]!
                    self.relationshipString = json["relationship"]!
                    self.photoString = json["photo"]!
                    //let relationship = json["relationship"]!
                    if !self.nameString.isEmpty{
                        DispatchQueue.main.async {
                            //self.detailLabel.text = "I know who you are"
                            //self.detailLabel.numberOfLines = 1
                            self.detailLabel.text = "Successfully identified"
                            self.performSegue(withIdentifier: "ResultSegue", sender: nil)
                        }
                        
                    }else{
                        DispatchQueue.main.async {
                            self.detailLabel.text = "Cannot identify voice"
                            let alert = UIAlertController(title: "Failed Identification", message: "Looks like our model doesn't recognize you. Please head to 'Add Voice' and submit more of your voice clips.", preferredStyle: UIAlertController.Style.alert)
                            // add an action (button)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                            // show the alert
                            self.present(alert, animated: true, completion: nil)

                        }
                    }
                    

                    
                } catch let error as NSError {
                    print(error)
                }

//                DispatchQueue.main.async {
//                    self.performSegue(withIdentifier: "resultSegue", sender: nil)
//                }
            
                
            }
            task.resume()

        }
    }

}

protocol ResultReturnDelegate: UIViewController {
    func resultDidReturn()
}
