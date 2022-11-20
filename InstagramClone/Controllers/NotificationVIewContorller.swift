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

extension NotificationViewContorller {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! NotificationCell
        return cell
    }
}
