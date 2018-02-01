//
//  TVFocusableText.swift
//  StepikTV
//
//  Created by Александр Пономарев on 24.12.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import UIKit

class TVFocusableText: UILabel, FocusAnimatable {

    var pressAction: ((TVFocusableText) -> Void)?
    var isAnimatable: Bool = true

    private let substrateView: UIView = UIView()
    private var lastText: String = ""

    override var canBecomeFocused: Bool {
        return true
    }

    override func drawText(in rect: CGRect) {

        guard lastText != text || text != "" else {
            super.drawText(in: rect)
            return
        }

        substrateView.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        substrateView.frame = rect.insetBy(dx: -20, dy: -20)
        substrateView.center = center
        substrateView.layer.cornerRadius = 10
        substrateView.clipsToBounds = true
        superview?.insertSubview(substrateView, belowSubview: self)

        lastText = text ?? ""
        super.drawText(in: rect)
    }

    func changeToDefault() {
        self.transform = CGAffineTransform.identity
        self.substrateView.transform = CGAffineTransform.identity
        self.substrateView.alpha = 0
    }

    func changeToFocused() {
        self.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
        self.substrateView.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
        self.substrateView.alpha = 1
    }

    func changeToHighlighted() {
        self.transform = CGAffineTransform.identity
        self.substrateView.transform = CGAffineTransform.identity
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        changeToDefault()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        changeToDefault()
    }

    // Events to look for a Highlighted state

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)
        guard presses.first!.type != UIPressType.menu else { return }

        pressAction?(self)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {

        guard isAnimatable else { return }
        self.updateFocus(in: context, with: coordinator)
    }

}

class TVTextPresentationAlertController: BlurredViewController {

    private var contentLabel: UILabel!
    private var scrollView: UIScrollView!

    private var scrollViewTopInset: NSLayoutConstraint!
    private var scrollViewBottomInset: NSLayoutConstraint!

    private let scrollViewDefaultInsetsValue: CGFloat = 30.0

    private var text: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        scrollView.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouchType.indirect.rawValue)]

        contentLabel = UILabel(frame: CGRect.zero)

        contentLabel.text = text
        contentLabel.textAlignment = .center
        contentLabel.textColor = UIColor.white
        contentLabel.numberOfLines = 0
        contentLabel.font = UIFont.systemFont(ofSize: 38, weight: UIFontWeightRegular)

        arrangeViews()
        view.layoutIfNeeded()
    }

    func setText(_ text: String) {
        self.text = text

        view?.layoutIfNeeded()
    }

    private func arrangeViews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentLabel)

        scrollView.align(to: view, top: 60.0, leading: 210.0, bottom: -60.0, trailing: -210.0)

        contentLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        contentLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true

        scrollViewTopInset = contentLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 60.0)
        scrollViewBottomInset = contentLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -60.0)

        scrollViewTopInset.isActive = true
        scrollViewBottomInset.isActive = true

        contentLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
    }

    override func viewDidLayoutSubviews() {

        print("\(contentLabel.bounds.height) \(scrollView.bounds.height)")

        if contentLabel.bounds.height <= scrollView.bounds.height {
            let insetValue = (scrollView.bounds.height - contentLabel.bounds.height) / 2
            scrollViewTopInset.constant = insetValue
            scrollViewBottomInset.constant = -insetValue

            //contentView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
        } else {
            scrollViewTopInset.constant = scrollViewDefaultInsetsValue
            scrollViewBottomInset.constant = -scrollViewDefaultInsetsValue
        }
    }
}