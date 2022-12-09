//
//  NotificationVIewContorller.swift
//  InstagramClone
//
//  Created by 이상준 on 2022/11/10.
//

import UIKit

private let reuseIdentifier = "NotificationCell"

class NotificationViewContorller: UITableViewController {
    
    private var notifications = [Notification]() {
        didSet { tableView.reloadData() }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        fetchNotifications()
    }
    
    func fetchNotifications() {
        NotificationService.fetchNotifications { notifications in
            self.notifications = notifications
            self.checkIfUserIsFollowed()
        }
    }
    
    func checkIfUserIsFollowed() {
        notifications.forEach { notification in
            guard notification.type == .follow else { return }
            
            UserService.checkIfUserIsFollowed(uid: notification.uid) { isFollowed in
                if let index = self.notifications.firstIndex(where: { $0.id == notification.id }) {
                    self.notifications[index].userIsFollwed = isFollowed
                }
            }
        }
    }
    
    func configureTableView() {
        view.backgroundColor = .white
        navigationItem.title = "알림"
        
        tableView.register(NotificationCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 80
        tableView.separatorStyle = .none
    }
}

// MARK: UITableViewDataSource
extension NotificationViewContorller {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! NotificationCell
        cell.viewModel = NotificationViewModel(notification: notifications[indexPath.row])
        cell.delegate = self
        return cell
    }
}

extension NotificationViewContorller {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

extension NotificationViewContorller: NotificationCellDelegate {
    func cell(_ cell: NotificationCell, wantsToFollow uid: String) {
        
    }
    
    func cell(_ cell: NotificationCell, wantsToUnfollow uid: String) {
        
    }
    
    func cell(_ cell: NotificationCell, wantsToViewPost postId: String) {
        
    }
}
