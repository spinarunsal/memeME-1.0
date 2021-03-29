//
//  ViewController.swift
//  ImagePickerExperiment
//
//  Created by Pinar Unsal on 2021-03-13.
//

import Foundation
import UIKit

class MemeEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    /***************************************************************************************************************/
    // MARK: Outlets
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var imagePickerView: UIImageView!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var camButton: UIBarButtonItem!
    /***************************************************************************************************************/
    // MARK: Properties
    let memeTextAttributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key.strokeColor:  UIColor.black,
        NSAttributedString.Key.foregroundColor: UIColor.white,
        NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
        NSAttributedString.Key.strokeWidth: NSNumber(value: -3.0)
    ]
    
    var activeTextField = UITextField()
    /***************************************************************************************************************/
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        organiseTextField(textfield: topTextField)
        organiseTextField(textfield: bottomTextField)
        
        shareButton.isEnabled = false
    }
    @IBAction func cancelButtonAction(_ sender: Any) {
        organiseTextField(textfield: topTextField)
        organiseTextField(textfield: bottomTextField)
        imagePickerView.image = .none
    }
    /***************************************************************************************************************/
    // MARK: Textfields
    //Organize textfields
    func organiseTextField (textfield: UITextField) {
        topTextField.text = "TOP"
        bottomTextField.text = "BOTTOM"
        textfield.defaultTextAttributes = memeTextAttributes
        textfield.textAlignment = .center
        textfield.borderStyle = .none
        textfield.delegate = self
    }
    
    //When a user taps inside a textfield, the default text should clear
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == "TOP" || textField.text == "BOTTOM" {
            textField.text = ""
        }
        self.activeTextField = textField
    }
    //When a user presses return, the keyboard should be dismissed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
    /***************************************************************************************************************/
    // MARK: Subscription of Keyboard
    override func viewWillAppear(_ animated: Bool) {
        camButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    // Shift the keyboard
    @objc func keyboardWillShow(_ notification:Notification) {
        if (self.activeTextField == topTextField) {
            view.frame.origin.y -= 0
        } else {
            view.frame.origin.y = -getKeyboardHeight(notification)
        }
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        super.view.frame.origin.y = 0
    }
    
    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: self)
        
    }
    /***************************************************************************************************************/
    // MARK: Image Picker Controllers
    @IBAction func pickAnImageFromAlbum(_ sender: Any) {
        pickAnImage(from: .photoLibrary)
    }
    
    @IBAction func pickAnImageFromCamera(_ sender: Any) {
        pickAnImage(from: .camera)
    }
    
    func pickAnImage(from source: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = source
        present(imagePicker, animated: true, completion: nil)
        shareButton.isEnabled = true
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.originalImage] as? UIImage {
            imagePickerView.image = image
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Meme Object Initializer
    func save() {
        // Create the meme
        _ = Meme(topText: topTextField.text!, bottomText: bottomTextField.text!, originalImage: imagePickerView.image!, memedImage: generateMemedImage())
    }
    
    // Combining image and text
    func generateMemedImage() -> UIImage {
        // Hide toolbar and navbar
        self.toolBar.isHidden = true
        self.navBar.isHidden = true
        
        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        //Show toolbar and navbar
        self.toolBar.isHidden = false
        self.navBar.isHidden = false
        
        return memedImage
    }
    
    // MARK: Share Action Method
    @IBAction func share(_ sender: Any) {
        // generate a meme image
        let aMemedImage = generateMemedImage()
        // define an instance of the ActivityViewController, pass the activityViewController a memedImage as an activity item
        let activityViewController = UIActivityViewController(activityItems: [aMemedImage], applicationActivities: nil)
        // present the ActivityViewController
        self.present(activityViewController, animated: true, completion: nil)
        
        //save the memedImage
        activityViewController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed:Bool, arrayReturnedItems: [Any]?, error: Error?) in
            if completed {
                self.save()
                print("saved")
                return
            } else {
                print("cancel")
            }
            if let shareError = error {
                print("error while sharing: \(shareError.localizedDescription)")
            }
        }
    }
}
/***************************************************************************************************************/
