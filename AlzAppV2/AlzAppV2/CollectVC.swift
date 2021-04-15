//
//  CollectVC.swift
//  AlzAppV2
//
//  Created by Wang on 2020/11/22.
//

import Foundation

import UIKit
class CollectVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, AudioReturnDelegate, PhotoReturnDelegate{
    private var audioString = ""
    private var photoString = ""
    private let emptyAudioIcon = UIImage(systemName: "mic")!
    private let filledAudioIcon = UIImage(systemName: "mic.fill")!
    private let emptyPhotoIcon = UIImage(systemName: "camera")!
    private let filledPhotoIcon = UIImage(systemName: "camera.fill")!
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var relationshipLabel: UILabel!
    @IBOutlet weak var photoLabel: UILabel!
    @IBOutlet weak var nameInput: UITextField!
    @IBOutlet weak var relationshipInput: UITextField!
    @IBOutlet weak var audioButton: UIButton!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    
    private var idSelected = -1
    var speakers:[(id: Int, name: String, relationship:String, photo:String)] = [(-1,"New Speaker","Unknown","")]

    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        picker.dataSource = self
        submitButton.isEnabled = false
        nameInput.sizeToFit()
        relationshipInput.sizeToFit()


    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AudioSegue"{
            let audioVC = segue.destination as! AudioVC
            audioVC.audioString = self.audioString
            audioVC.audioReturnDelegate = self
        }
        if segue.identifier == "PhotoSegue"{
            let photoVC = segue.destination as! PhotoVC
            photoVC.photoString = self.photoString
            photoVC.photoReturnDelegate = self
        }

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
        if (idSelected == -1){
            nameLabel.isHidden = false
            relationshipLabel.isHidden = false
            nameInput.isHidden = false
            relationshipInput.isHidden = false
            photoLabel.isHidden = false
            photoButton.isHidden = false
        }else{
            nameLabel.isHidden = true
            relationshipLabel.isHidden = true
            nameInput.isHidden = true
            relationshipInput.isHidden = true
            photoLabel.isHidden = true
            photoButton.isHidden = true
        }
        enableSubmit()
    }
    func enableSubmit(){
        if (idSelected == 0 && audioString != "" && photoString != "" && nameInput.hasText && relationshipInput.hasText){
            submitButton.isEnabled = true
        }else if (idSelected != 0 && audioString != ""){
            submitButton.isEnabled = true
        }else{
            submitButton.isEnabled = false
        }
    }
    func photoDidReturn(_ result:String){
        self.photoString = result
        if result == ""{
            photoButton.setImage(emptyPhotoIcon, for: .normal)
        }
        else{
            photoButton.setImage(filledPhotoIcon, for: .normal)
        }
        enableSubmit()

    }
    func audioDidReturn(_ result:String){
        self.audioString = result
        if result == ""{
            audioButton.setImage(emptyAudioIcon, for: .normal)
        }
        else{
            audioButton.setImage(filledAudioIcon, for: .normal)
        }
        enableSubmit()
        
    }

    @IBAction func nameDone(_ sender: UITextField) {
        sender.resignFirstResponder()
        enableSubmit()
    }
    
    @IBAction func relationshipDone(_ sender: UITextField) {
        sender.resignFirstResponder()
        enableSubmit()
    }
    
    @IBAction func submitTapped(_ sender: Any) {
        let json: [String: Any] = ["id":idSelected,
                                   "name": nameInput.text ?? "Anonymous",
                                   "relationship": relationshipInput.text ?? "Unknown",
                                   "audio": audioString,
                                   "photo": photoString]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        //var request = URLRequest(url: URL(string: "https://161.35.116.242/addVoiceV2/")!)
        var request = URLRequest(url: URL(string: "https://18.217.201.244/api/ios/addvoice/")!)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")  // the request is JSON
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")        // the expected response is also JSON
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
        navigationController?.popViewController(animated: true)
        //self.dismiss(animated: true, completion: nil)
    }
    
    
}
protocol PhotoReturnDelegate: UIViewController {
    func photoDidReturn(_ result: String)
}

protocol AudioReturnDelegate: UIViewController {
    func audioDidReturn(_ result: String)
}
