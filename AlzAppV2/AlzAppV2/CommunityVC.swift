//
//  CommunityVC.swift
//  AlzAppV2
//
//  Created by Wang on 2020/11/26.
//

import Foundation
import UIKit
class CommunityVC:UITableViewController{
    
    var speakers:[(id: Int, name: String, relationship:String, photo:String)] = [(0,"New Speaker","Unknown","")]

    override func viewDidLoad() {
        super.viewDidLoad()
        speakers = speakers.filter { $0.id != -1}
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        // how many sections are in table
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // how many rows per section
        return speakers.count
    }
    
    var currentIndexPath: IndexPath!
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // event handler when a cell is tapped
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        currentIndexPath = indexPath
        self.performSegue(withIdentifier: "CommunityResultSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CommunityResultSegue" {
            let resultVC = segue.destination as! ResultVC
            resultVC.nameString = speakers[currentIndexPath!.row].name
            resultVC.relationshipString = speakers[currentIndexPath!.row].relationship
            resultVC.photoString = speakers[currentIndexPath!.row].photo
        }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // populate a single cell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SpeakerTableCell", for: indexPath) as? SpeakerTableCell else {
            fatalError("No reusable cell!")
        }
        
        let speaker = speakers[indexPath.row]
        let loadedImage = base64toImage(img: speaker.photo)!.resizeImage(targetSize: CGSize(width: 191, height: 156))
        cell.cellPhoto.image = loadedImage

        return cell
    }
    func base64toImage(img: String) -> UIImage? {
        if (img == "") {
          return nil
        }
        let dataDecoded : Data = Data(base64Encoded: img, options: .ignoreUnknownCharacters)!
        let decodedimage = UIImage(data: dataDecoded)
        return decodedimage!
    }
}


