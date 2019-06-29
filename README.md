# Learning RxCocoa

RxCocoa provides everything we need, wraps most UIKit compononent under Observables by providing two extraordinary protocol capabilities are ControlEvent andControlproperties. The RxCocoa Observable has some specifications:
* The stream never fails.
* Complete sequence will call when control deallocates.
* Stream delivery events happen on main thread(MainScheduler).



## System requirements
For this tutorial we'll use Xcode 10.2.1, Swift 5.*,  [cocoapods 1.7.2](https://cocoapods.org) and [RxSwift 5.0 & RxCocoa 5.0](https://github.com/ReactiveX/RxSwift.git). Since, RxSwift, RxCocoa and RxRelay come on same package we don't need to worry about individual pods.

If you're new to Rx thing then please allow few times to visit my  [RxSwift tutorial](https://github.com/mdzinuk/RxSwift) page first then come here again :).

## Getting Started with [RxCocoa-Tuts](https://github.com/mdzinuk/RxCocoa)
To get started, download [RxCocoa-Tuts](https://github.com/mdzinuk/RxCocoa/tree/master/RxCocoa-Tuts) first then open the **RxCocoa-Tuts.xcworkspace**  project in Xcode to build, build the project by selecting **RxCocoa-Tuts** target if it is not selected.

Firstly, create a class Named it Keyboard, add two properties 
```swift
static let instance = Keyboard()
var keyboardFrame: Observable<CGFloat>?
```

at init method create an Observable.from([]) put two keyboard NotificationCenter observable, merge and observe them by main thread.

```swift
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
```
We'll subscribe it to get keyboard frame while it appeares/disappear.

Come into RxCocoaViewController class, inside its viewDidLoad method subscribe it and change view origin.y point while keyboard animate.

```swift
Keyboard.instance
            .keyboardFrame?
            .subscribe { [unowned self] in
                guard let point = $0.element else { return }
                self.view.frame.origin.y = UIScreen.main.bounds.origin.y
                self.view.frame.origin.y -= point/2
            }.disposed(by: disposeBag)
```

Next, create a new observable with textfileds. We added ```.orEmpty ``` property after .text, which simply emits an empty string if nil is emitted. We also added ```.distinctUntilChanged()``` to prevent duplicate string.

After that ```.filter``` operator will return valid stream with disabling/enablbling submit button.

```swift
// Create fieldsObserver with combine latest
let fieldsObserver = Observable
    .combineLatest(name.rx.text.orEmpty.distinctUntilChanged(),
                   email.rx.text.orEmpty.distinctUntilChanged(),
                   age.rx.text.orEmpty.distinctUntilChanged())
    .filter ({ [weak self] (result: (String, String, String)) in
        let isValid = User.validate(result.0,User.ValidationType.name) &&
            User.validate(result.1, User.ValidationType.email) &&
            User.validate(result.2, User.ValidationType.age)
        // Disable button if textfields are validate to fail
        self?.submit.isEnabled = isValid
        // return once after validated
        return isValid
    })
```

Finally we'll subscribe submit button tap events with withLatestFrom operator, which will combine three strings from fieldsObserver into a single string streaming to bind into single label output.

```swift
// Subscribe submit button event to get proper name
submit.rx.tap.withLatestFrom(fieldsObserver
    .map { "Name: \($0.0)\n Email: \($0.1) \n Age: \($0.2)" })
    .map { [unowned self] text in // Remove keyboard after tap on
        self.isEditing = !text.isEmpty
        return text
    }
    .bind(to: label.rx.text)
    .disposed(by: disposeBag)
```

<em>**Note: binding here is a uni-directional stream of string.**</em>

Here is [Final project](https://github.com/mdzinuk/RxCocoa/tree/master/RxCocoa-Tuts-Final) has been done for you. 
## Demo!!!
![RxCocoa Demo](https://github.com/mdzinuk/RxCocoa/blob/master/Resources/demo.gif)

