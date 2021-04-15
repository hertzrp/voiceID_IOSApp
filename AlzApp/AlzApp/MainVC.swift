//
//  ViewController.swift
//  AlzApp
//
//  Created by Wang on 2020/10/24.
//

import UIKit

class MainVC: UIViewController{
    var main_speakers:[(id: Int, name: String)] = [(0,"New Speaker")]
    @IBOutlet weak var collectButton: UIButton!
    

    func fetchData(){
        DispatchQueue.main.async {
            self.collectButton.isEnabled = false
        }
        
        DispatchQueue.main.async {
            self.getSpeakers()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        fetchData()
        NotificationCenter.default.addObserver(self, selector: #selector(fetchAfterSubmit(_:)), name: Notification.Name(rawValue: "fetchAfterSubmit"), object: nil)
    }

    @objc func fetchAfterSubmit(_ notification: Notification) {
        DispatchQueue.main.async {
            self.collectButton.isEnabled = false
        }
        let delayTime = DispatchTime.now() + 1.5
        DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
            self.getSpeakers()
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "CollectSegue"{
            let navVC = segue.destination as? UINavigationController
            let collectVC = navVC?.viewControllers.first as! CollectVC
            collectVC.speakers = main_speakers
        }

    }
    func getSpeakers() {
        let requestURL = "https://161.35.116.242/getSpeakers/"
        var request = URLRequest(url: URL(string: requestURL)!)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            do {
                self.main_speakers = [(0,"New Speaker")]
                let json = try JSONSerialization.jsonObject(with: data!) as! [String:Any]
                for speakerEntry in json["speakers"] as? [[Any]] ?? []{
                    print(speakerEntry)
                    self.main_speakers.append((speakerEntry[0] as! Int,speakerEntry[1] as! String))
                }

            } catch let error as NSError {
                print(error)
            }
            DispatchQueue.main.async {
                self.collectButton.isEnabled = true
            }
            
        }
        task.resume()
    }
}
protocol ReturnDelegate: UIViewController {
    func didReturn(_ input_speakers: [(id: Int, name: String)])
}
