//
//  File.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 07/05/18.
//

import Foundation
import QiscusCore

protocol UIChatUserInteraction {
    func sendMessage(withText text: String)
    func loadRoom(withId roomId: String)
    func loadComments(withID roomId: String)
    func loadMore()
    func getAvatarImage(section: Int, imageView: UIImageView)
    func getMessage(atIndexPath: IndexPath) -> CommentModel
}

protocol UIChatViewDelegate {
    func onLoadRoomFinished(roomName: String, roomAvatarURL: URL?)
    func onLoadMessageFinished()
    func onLoadMessageFailed(message: String)
    func onLoadMoreMesageFinished()
    func onSendingComment(comment: CommentModel, newSection: Bool)
    func onSendMessageFinished(comment: CommentModel)
    func onGotNewComment(newSection: Bool, isMyComment: Bool)
    func onGotComment(comment: CommentModel, isUpdate: CommentModel)
    func onUser(name: String, typing: Bool)
    func onUser(name: String, isOnline: Bool, message: String)
}

class UIChatPresenter: UIChatUserInteraction {
    private var viewPresenter: UIChatViewDelegate?
    var comments: [[CommentModel]] = []
    var room: RoomModel? 
    var loadMoreAvailable: Bool = true
    var participants : [MemberModel] = [MemberModel]()
    
    init() {
        self.comments = [[CommentModel]]()
    }
    
    func attachView(view : UIChatViewDelegate){
        viewPresenter = view
        if let room = self.room {
            room.delegate = self
            self.loadComments(withID: room.id)
            viewPresenter?.onLoadRoomFinished(roomName: room.name, roomAvatarURL: room.avatarUrl)
            if let p = room.participants {
                self.participants = p
            }
        }
    }
    
    func detachView() {
        viewPresenter = nil
        if let room = self.room {
            room.delegate = nil
        }
    }
    
    func getMessage(atIndexPath: IndexPath) -> CommentModel {
        let comment = comments[atIndexPath.section][atIndexPath.row]
        return comment
    }
    
    func getComments() -> [[CommentModel]] {
        return self.comments
    }
    
    func loadRoom(withId roomId: String) {
        
    }
    
    func loadComments(withID roomId: String) {
        // load local
        if let _comments = QiscusCore.database.comment.find(roomId: roomId) {
            self.comments.removeAll()
            self.comments = self.groupingComments(comments: _comments)
            debugPrint(self.comments)
            self.viewPresenter?.onLoadMessageFinished()
        }
        QiscusCore.shared.loadComments(roomID: roomId) { (dataResponse, error) in
            guard let response = dataResponse else {
                guard let _error = error else { return }
                self.viewPresenter?.onLoadMessageFailed(message: _error.message)
                return
            }
            self.comments.removeAll()
            // convert model
            var tempComments = [CommentModel]()
            for i in response {
                tempComments.append(i)
            }
            // MARK: TODO improve and grouping
            self.comments.removeAll()
            self.comments = self.groupingComments(comments: tempComments)
            debugPrint(self.comments)
            self.viewPresenter?.onLoadMessageFinished()
        }
    }
    
    func loadMore() {
        if loadMoreAvailable {
            if let lastGroup = self.comments.last, let lastComment = lastGroup.last {
                if lastComment.id.isEmpty {
                    return
                }
                
                QiscusCore.shared.loadMore(roomID: (self.room?.id)!, lastCommentID: Int(lastComment.id)!, completion: { (commentsRsponse, error) in
                    if let comments = commentsRsponse {
                        if comments.count == 0 {
                            self.loadMoreAvailable = false
                        }
                        let tempComments = comments.map({ (qComment) -> CommentModel in
                            return qComment 
                        })
                        
                        self.comments.append(contentsOf: self.groupingComments(comments: tempComments))
                        self.viewPresenter?.onLoadMoreMesageFinished()
                    } else {
                        
                    }
                })
            }
        }
    }
    
    func isTyping(_ value: Bool) {
        if let r = self.room {
            QiscusCore.shared.isTyping(value, roomID: r.id)
        }
    }
    
    func sendMessage(withComment comment: CommentModel) {
        
        addNewCommentUI(comment)
        QiscusCore.shared.sendMessage(roomID: (self.room?.id)!,comment: comment) { (_comment, error) in
            guard let c = _comment else { return }
            self.viewPresenter?.onGotComment(comment: comment, isUpdate: c)
            
        }
    }
    
    func sendMessage(withText text: String) {
        // create object comment
        // MARK: TODO improve object generator
        let message = CommentModel()
        message.message = text
        message.type    = "text"
        addNewCommentUI(message)
        QiscusCore.shared.sendMessage(roomID: (self.room?.id)!,comment: message) { (comment, error) in
            guard let c = comment else { return }
            self.viewPresenter?.onGotComment(comment: message, isUpdate: c)
        }
    }
    
    func sendMessageLoc() {
        // create object comment
        // MARK: TODO improve object generator
        let message = CommentModel()
        message.message = "location"
        message.type    = "custom"
        message.payload = [
            "type" : "data",
            "content" : "",
        ]
        addNewCommentUI(message)
        QiscusCore.shared.sendMessage(roomID: (self.room?.id)!,comment: message) { (comment, error) in
            print("failed \(String(describing: error?.message))")
        }
    }
    
    private func addNewCommentUI(_ message: CommentModel) {
            // add new comment to ui
            if self.comments.count > 0 {
                if self.comments[0].count > 0 {
                    let lastComment = self.comments[0][0]
                    if lastComment.userEmail == message.userEmail && lastComment.timestamp == message.timestamp {
                        self.comments[0].insert(message, at: 0)
                        self.viewPresenter?.onSendingComment(comment: message, newSection: false)
                    } else {
                        self.comments.insert([message], at: 0)
                        self.viewPresenter?.onSendingComment(comment: message, newSection: true)
                    }
                } else {
                    self.comments.insert([message], at: 0)
                    self.viewPresenter?.onSendingComment(comment: message, newSection: true)
                }
            } else {
                self.comments.insert([message], at: 0)
                self.viewPresenter?.onSendingComment(comment: message, newSection: true)
            }
    }
    
    func getAvatarImage(section: Int, imageView: UIImageView) {
        if self.comments.count > 0 {
            if self.comments[0].count > 0 {
                if let url = self.comments[0][0].userAvatarUrl {
                    imageView.loadAsync(url: "\(url)")
                }
            }
        }
        
    }
    
    /// Grouping by useremail and date(same day), example [[you,you],[me,me],[me]]
    private func groupingComments(comments: [CommentModel]) -> [[CommentModel]]{
        var retVal = [[CommentModel]]()
        var group = [CommentModel]()
        for comment in comments {
            if !group.contains(where: { $0.uniqId == comment.uniqId}) {
                // check last comment in group
                if let last = group.last {
                    // compare email with last group
                    if last.userEmail == comment.userEmail {
                        group.append(comment)
                    }else {
                        retVal.append(group)
                        group.removeAll()
                    }
                }else {
                    group.append(comment)
                }
            }
        }
        return retVal
//        var uidList = [CommentModel]()
//        var prevComment:CommentModel?
//        var group = [CommentModel]()
//        var count = 0
//
//        for comment in comments {
//
//            if !uidList.contains(where: { $0.uniqId == comment.uniqId}) {
//                // check last comment
//                if let prev = prevComment {
//                    // check difference time(in same day) and user group
//                    if prev.timestamp == comment.timestamp && prev.userEmail == comment.userEmail {
//                        uidList.append(comment)
//                        group.append(comment)
//                    }else{
//                        retVal.append(group)
//                        //                        checkPosition(ids: group)
//                        group = [CommentModel]()
//                        group.append(comment)
//                        uidList.append(comment)
//                    }
//                }else{
//                    // add new group
//                    group.append(comment)
//                    uidList.append(comment)
//                }
//                if count == comments.count - 1  {
//                    retVal.append(group)
//                    //                    checkPosition(ids: group)
//                }else{
//                    prevComment = comment
//                }
//            }
//            count += 1
//        }
//        return retVal
    }
    
    func getIndexPath(comment : CommentModel) -> IndexPath? {
        let data = self.comments
        print("data \(data.count)")
        for (group,c) in data.enumerated() {
            print("data \(group), count \(c.count)")
            for (index,i) in c.enumerated() {
                print("i.uniqueid \(i.uniqId), \(comment.uniqId)")
                if i.uniqId == comment.uniqId {
                    print("found data \(index), count \(group)")
                    return IndexPath.init(row: index, section: group)
                }
            }
//            if let index = c.index(where: { $0.uniqId == comment.uniqId }) {
//                print("found data \(index), count \(c.count)")
//                return IndexPath.init(row: index, section: group)
//            }
        }
        return nil
    }
}


extension UIChatPresenter : QiscusCoreRoomDelegate {
    func gotNewComment(comment: CommentModel) {
        guard let room = self.room else { return }
        let message = comment
        self.comments.insert([message], at: 0)
        self.viewPresenter?.onGotNewComment(newSection: true, isMyComment: false)
        // MARK: TODO unread new comment, need trotle
        QiscusCore.shared.updateCommentRead(roomId: room.id, lastCommentReadId: comment.id)
    }
    
    func didComment(comment: CommentModel, changeStatus status: CommentStatus) {
        print("comment \(comment.message), status update \(status.rawValue)")
        // check comment already exist in view
        for (group,c) in comments.enumerated() {
            if let index = c.index(where: { $0.uniqId == comment.uniqId }) {
                // then update comment value and notice onChange()
                print("comment change last \(comments.count), \(c.count)")
                comments[group][index] = comment
//                comments[group][index].onChange(comment)
                self.viewPresenter?.onGotComment(comment: comments[group][index], isUpdate: comment)
            }
        }
        
    }
    
    func onRoom(thisParticipant user: MemberModel, isTyping typing: Bool) {
        self.viewPresenter?.onUser(name: user.username, typing: typing)
    }
    
    func onChangeUser(_ user: MemberModel, onlineStatus status: Bool, whenTime time: Date) {
        if let room = self.room {
            if room.type != .group {
                var message = ""
                //let lessMinute = time.timeIntervalSinceNow.second
                //if lessMinute <= 59 {
                    message = "online"
               // }else {
                    //if lessMinute
                   // message = "Last seen .. ago"
                //}
                self.viewPresenter?.onUser(name: user.username, isOnline: status, message: message)
            }
        }
    }
}
