//
//  ListChatViewController.swift
//  example
//
//  Created by Qiscus on 30/07/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

import UIKit
import QiscusUI
import QiscusCore

class ListChatViewController: UIChatListViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Chat List"
        // Do any additional setup after loading the view.
        let add = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addChat))
        let play = UIBarButtonItem(title: "Group", style: .plain, target: self, action: #selector(addGroup))
        
        navigationItem.rightBarButtonItems = [add, play]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func addChat() {
        QiscusCore.shared.getRoom(withUser: "amsibsam") { (room, error) in
            guard let room = room else {return}
            self.chat(withRoom: room)
        }
    }
    
    @objc func addGroup() {
        let names = ["Semarang", "jogja", "jakarta", "bogor", "palembang"]
        let randomName = names[Int(arc4random_uniform(UInt32(names.count)))]
        QiscusCore.shared.createGroup(withName: randomName, participants: ["amsibsam", "amsibsan"], avatarUrl: nil) { (room, error) in
            guard let room = room else {return}
            self.chat(withRoom: room)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let room = self.rooms[indexPath.row]
        self.chat(withRoom: room)
    }

    private func chat(withRoom room: QRoom) {
        let target = ChatViewController()
        target.room = room
        self.navigationController?.pushViewController(target, animated: true)
    }
}
