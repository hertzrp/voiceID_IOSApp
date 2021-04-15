//
//  SpeakerTableCell.swift
//  AlzAppV2
//
//  Created by Wang on 2020/11/27.
//

import Foundation
import UIKit

class SpeakerTableCell: UITableViewCell{
    
    @IBOutlet weak var cellPhoto: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
