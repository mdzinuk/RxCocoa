//
//  RxCocoaViewController.swift
//  RxCocoa-Tuts-Final
//
//  Created by Mohammad Arafat Hossain on 6/27/19.
//  Copyright © 2019 M. Arafat. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RxCocoaViewController: UIViewController {
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var age: UITextField!
    @IBOutlet weak var submit: UIButton!
    @IBOutlet weak var label: UILabel!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Observe keyboard frame
        Keyboard.instance
            .keyboardFrame?
            .subscribe { [unowned self] in
                guard let point = $0.element else { return }
                self.view.frame.origin.y = UIScreen.main.bounds.origin.y
                self.view.frame.origin.y -= point/2
            }
            .disposed(by: disposeBag)
        
        // Create fieldsObserver with combine latest
        let fieldsObserver = Observable
            .combineLatest(name.rx.text.orEmpty.distinctUntilChanged(),
                           email.rx.text.orEmpty.distinctUntilChanged(),
                           age.rx.text.orEmpty.distinctUntilChanged())
            .filter ({ [unowned self] (result: (String, String, String)) in
                let isValid = User.validate(result.0,User.ValidationType.name) &&
                    User.validate(result.1, User.ValidationType.email) &&
                    User.validate(result.2, User.ValidationType.age)
                // Disable button if textfields are validate to fail
                self.submit.isEnabled = isValid
                // return once after validated
                return isValid
            })
        
        // Subscribe submit button event to get proper name
        submit.rx.tap.withLatestFrom(fieldsObserver
            .map { "Name: \($0.0)\n Email: \($0.1) \n Age: \($0.2)" })
            .map { [unowned self] text in // Remove keyboard after tap on
                self.isEditing = !text.isEmpty
                return text
            }
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        coordinator.animate(alongsideTransition: { [unowned self] context in
            // Hide navigation bar at landscape orientation othwerwise our actual content will hide during the editing mode
            self.navigationController?.navigationBar.isHidden = (newCollection.verticalSizeClass == .compact)
        })
    }
}

fileprivate extension RxCocoaViewController {
    struct User {
        enum ValidationType: Int {
            case name, email, age
            var pattern: String {
                switch self {
                case .name:
                    return "[A-Za-z]"
                case .email:
                    return "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
                default:
                    return "[0-9]{1,3}"
                }
            }
        }
        
        var name: String?
        var email: String?
        var age: String?
        init() { name = nil; email = nil; age = nil }
        
        static func validate(_ content: String, _ type: ValidationType) -> Bool {
            let regex = try! NSRegularExpression(pattern: type.pattern, options: .caseInsensitive)
            return regex.firstMatch(in: content, options: [], range: NSRange(location: 0, length: content.count)) != nil
        }
    }
}
