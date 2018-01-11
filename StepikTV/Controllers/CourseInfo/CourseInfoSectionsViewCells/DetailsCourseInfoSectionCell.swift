//
//  DetailsCourseInfoCell.swift
//  StepikTV
//
//  Created by Александр Пономарев on 29.10.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import UIKit

class DetailsCourseInfoSectionCell: UICollectionViewCell, CourseInfoSectionViewProtocol {
    static var nibName: String { return "DetailsCourseInfoSectionCell" }
    static var reuseIdentifier: String { return "DetailsCourseInfoSectionCell" }
    static var size: CGSize { return CGSize(width: UIScreen.main.bounds.width, height: 150.0) }

    @IBOutlet var title: UILabel!
    @IBOutlet var content: TVFocusableText!
    @IBOutlet var widthConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        widthConstraint.constant = DetailsCourseInfoSectionCell.size.width
    }

    func setup(with section: CourseInfoSection) {
        title.text = section.title

        switch section.contentType {
        case let .text(content: content, selectionAction: selectionAction):
            self.content.text = content
            self.content.pressAction = selectionAction
        default:
            fatalError("Sections data and view dependencies fails")
        }
    }
}
