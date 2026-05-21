//
//  ViewController.swift
//  LsdSandbox
//
//  Single-button UI for acquiring lsd sandbox permissions.
//  Ported from LockIPCC's acquireLsdSandboxTapped: logic.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "lsd 沙箱权限"
        label.font = UIFont.boldSystemFont(ofSize: 28)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "获取 /var/mobile 读写权限"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(white: 0.7, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let acquireButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("获取 lsd 沙箱权限", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let logTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        textView.textColor = UIColor(red: 0.3, green: 1.0, blue: 0.3, alpha: 1.0)
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.isEditable = false
        textView.text = ""
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.darkGray.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return textView
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "就绪"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor(white: 0.5, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.08, alpha: 1.0)
        
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(acquireButton)
        view.addSubview(logTextView)
        view.addSubview(statusLabel)
        view.addSubview(activityIndicator)
        
        acquireButton.addTarget(self, action: #selector(acquireButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Button
            acquireButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            acquireButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            acquireButton.widthAnchor.constraint(equalToConstant: 260),
            acquireButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Activity indicator (next to button)
            activityIndicator.centerYAnchor.constraint(equalTo: acquireButton.centerYAnchor),
            activityIndicator.leadingAnchor.constraint(equalTo: acquireButton.trailingAnchor, constant: 12),
            
            // Log text view
            logTextView.topAnchor.constraint(equalTo: acquireButton.bottomAnchor, constant: 30),
            logTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            logTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            logTextView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -10),
            
            // Status label
            statusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Actions
    
    @objc private func acquireButtonTapped() {
        acquireButton.isEnabled = false
        activityIndicator.startAnimating()
        statusLabel.text = "正在获取 lsd 沙箱权限..."
        statusLabel.textColor = .systemYellow
        
        logTextView.text = "[日志] 开始获取 lsd 沙箱权限...\n"
        
        LsdHelper.acquirePermission { [weak self] success, log in
            guard let self = self else { return }
            
            self.acquireButton.isEnabled = true
            self.activityIndicator.stopAnimating()
            
            self.logTextView.text = log
            
            if success {
                self.statusLabel.text = "成功 - lsd 沙箱权限已获取"
                self.statusLabel.textColor = UIColor(red: 0.3, green: 1.0, blue: 0.3, alpha: 1.0)
                self.acquireButton.backgroundColor = UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
                self.acquireButton.setTitle("已获取 lsd 沙箱权限", for: .normal)
                
                // Flash green animation
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.backgroundColor = UIColor(red: 0.0, green: 0.2, blue: 0.05, alpha: 1.0)
                }) { _ in
                    UIView.animate(withDuration: 0.5) {
                        self.view.backgroundColor = UIColor(white: 0.08, alpha: 1.0)
                    }
                }
            } else {
                self.statusLabel.text = "失败 - 请查看日志"
                self.statusLabel.textColor = .systemRed
            }
        }
    }
}