//
//  MajorItemCell.swift
//  StepikTV
//
//  Created by Александр Пономарев on 11.12.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import UIKit

class MajorItemCell: FocusableCustomCollectionViewCell {
    static var nibName: String { return "MajorItemCell" }
    static var reuseIdentifier: String { return "MajorItemCell" }
    static var size: CGSize { return CGSize(width: 860.0, height: 390.0) }

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!

    var pressAction: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = imageView.bounds;
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.3).cgColor, UIColor.black.cgColor];
        imageView.layer.addSublayer(gradientLayer);
    }

    func setup(with item: ItemViewData) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        pressAction = item.action

        imageView.setImageWithURL(url: item.backgroundImageURL, placeholder: item.placeholder, completion: {
            let data = UIImageJPEGRepresentation(self.imageView.image!, 1)
            self.imageView.image = UIImage(data: data!)
        })
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)
        guard presses.first!.type != UIPressType.menu else { return }
        
        pressAction?()
    }
}