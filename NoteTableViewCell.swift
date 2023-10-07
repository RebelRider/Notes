//
//  NoteTableViewCell.swift
//  Notes
//
//  Created by Kirill Smirnov on 26.09.2023.
//

import UIKit

class NoteTableViewCell: UITableViewCell {
    static let identifier = "NoteCell"
    
    let noteTextLabel: UILabel = {
        let noteText = UILabel()
        noteText.font = .italicSystemFont(ofSize: 17)
        return noteText
    }()
    
    let dateCreatedLabel: UILabel = {
        let dateCreated = UILabel()
        dateCreated.font = .monospacedSystemFont(ofSize: 8, weight: .light)
        return dateCreated
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.layer.borderWidth = 0.1
        contentView.layer.borderColor = .init(gray: 0.2, alpha: 0.1)
        
        contentView.addSubview(noteTextLabel)
        contentView.addSubview(dateCreatedLabel)
            noteTextLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
            noteTextLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
            noteTextLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11).isActive = true
            noteTextLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -11).isActive = true
            noteTextLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(note:Note) {
        noteTextLabel.text = note.text
                let df = DateFormatter()
                df.dateFormat = "dd-MM-yyyy HH:mm"
        dateCreatedLabel.text = df.string(from: note.dateCreated ?? Date())
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dateCreatedLabel.frame = CGRect(x: contentView.frame.width - 82,
                                        y: -6,
                                        width: 82,
                                        height: 22)
        noteTextLabel.adjustsFontSizeToFitWidth = true
        noteTextLabel.adjustsFontForContentSizeCategory = true
        noteTextLabel.numberOfLines = 0
        noteTextLabel.minimumScaleFactor = 0.5
        noteTextLabel.sizeToFit()
        noteTextLabel.layoutIfNeeded()
    }
}
