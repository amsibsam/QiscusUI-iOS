//
//  ChatViewController.swift
//  QiscusUI
//
//  Created by Qiscus on 31/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import UIKit
import QiscusUI
import QiscusCore
import ContactsUI

class ChatViewController: UIChatViewController {
    var roomID : String?
    let picker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        registerCell()
        // alternative load ui then set room data, but you need to handle loading
        guard let roomid = roomID else { return }
        QiscusCore.shared.getRoom(withID: roomid) { (roomData, error) in
            if let data = roomData {
                self.room = data
            }else {
                // show error
                print("error load room \(String(describing: error?.message))")
            }
        }
    }
    
    // MARK: How to implement custom view cell by comment type
    func registerCell() {
        self.registerClass(nib: UINib(nibName: "ImageViewCell", bundle: nil), forMessageCellWithReuseIdentifier: "image")
    }
    
    override func indentifierFor(message: CommentModel, atUIChatViewController : UIChatViewController) -> String {
        if message.type == "file_attachment" {
            return "image"
        }else {
            return super.indentifierFor(message: message, atUIChatViewController: atUIChatViewController)
        }
    }
    
    // MARK: How to implement custom input chat
    // register custom input
    override func chatInputBar() -> UIChatInput? {
        let inputBar = CustomChatInput()
        inputBar.delegate = self
        return inputBar
    }
}

extension ChatViewController : CustomChatInputDelegate {
    func sendAttachment() {
        let optionMenu = UIAlertController()
        let deleteAction = UIAlertAction(title: "Camera", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("File Deleted")
        })
        let saveAction = UIAlertAction(title: "Photo & Video Library", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("File Saved")
        })
        let docAction = UIAlertAction(title: "Document", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("File Saved")
        })
        let contactAction = UIAlertAction(title: "Contact", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.getContact()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(saveAction)
        optionMenu.addAction(docAction)
        optionMenu.addAction(contactAction)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    private func getContact() {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        contactPicker.displayedPropertyKeys =
            [CNContactGivenNameKey
                , CNContactPhoneNumbersKey]
        self.present(contactPicker, animated: true, completion: nil)
    }
}

// Contact Picker
extension ChatViewController : CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let userName:String = contact.givenName
        let surName:String = contact.familyName
        let fullName:String = userName + " " + surName
        print("Select contact \(fullName)")
        //  user phone number
        let userPhoneNumbers:[CNLabeledValue<CNPhoneNumber>] = contact.phoneNumbers
        let firstPhoneNumber:CNPhoneNumber = userPhoneNumbers[0].value
        let primaryPhoneNumberStr:String = firstPhoneNumber.stringValue
        print(primaryPhoneNumberStr)
        
        // send contact, with qiscus comment type "contact_person" payload must valit
        let message = CommentModel()
        message.type = "contact_person"
        message.payload = [
            "name"  : fullName,
            "value" : primaryPhoneNumberStr,
            "type"  : "phone"
        ]
        message.message = "Send Contact"
        self.send(message: message)
    }
}

// Image Picker
extension ChatViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        //
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        //
    }
}
