//
//  Keyboard.swift
//  RxCocoa-Tuts-Final
//
//  Created by Mohammad Arafat Hossain on 29/06/19.
//  Copyright © 2019 M. Arafat. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

class Keyboard: NSObject {
    static let instance = Keyboard()
    
    var keyboardFrame: Observable<CGFloat>?
    
    override init() {
        super.init()
        
        keyboardFrame = Observable.from([
            NotificationCenter
                .default
                .rx
                .notification(UIResponder.keyboardWillShowNotification)
                .map { notification -> CGFloat in
                    (notification
                        .userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?
                        .cgRectValue
                        .height ?? 0
            },
            NotificationCenter
                .default
                .rx
                .notification(UIResponder.keyboardWillHideNotification)
                .map { _ -> CGFloat in 0 }
            ])
            .merge()
            .observeOn(MainScheduler.instance)
    }
}
