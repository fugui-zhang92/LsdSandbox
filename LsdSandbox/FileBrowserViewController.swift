import UIKit

// MARK: - 文件浏览器（支持编辑）
final class FileBrowserViewController: UIViewController {

    private let rootPath = "/var/mobile/Library/CarrierBundles"
    private var currentPath: String = ""
    private var entries: [Entry] = []

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let pathLabel = UILabel()

    private enum Entry {
        case dir(String, String)   // name, fullPath
        case file(String, String)  // name, fullPath
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "文件管理"
        view.backgroundColor = UIColor.systemGroupedBackground
        setupPathLabel()
        setupTableView()
        currentPath = rootPath
        pathLabel.text = rootPath
        // Defer directory enumeration to avoid crash on launch
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if entries.isEmpty && currentPath == rootPath {
            navigateTo(rootPath)
        }
    }

    // MARK: - UI

    private func setupPathLabel() {
        pathLabel.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        pathLabel.textColor = .secondaryLabel
        pathLabel.numberOfLines = 2
        pathLabel.lineBreakMode = .byCharWrapping
        pathLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pathLabel)

        NSLayoutConstraint.activate([
            pathLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            pathLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            pathLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: pathLabel.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Navigation

    private func navigateTo(_ path: String) {
        currentPath = path
        pathLabel.text = path
        entries.removeAll()

        let fm = FileManager.default
        var contents: [String] = []
        do {
            contents = try fm.contentsOfDirectory(atPath: path)
        } catch {
            showAlert("无法读取目录", message: error.localizedDescription)
        }

        // Dirs first, then files (sorted)
        for name in contents.sorted() {
            let full = (path as NSString).appendingPathComponent(name)
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: full, isDirectory: &isDir), isDir.boolValue {
                entries.append(.dir(name, full))
            }
        }
        for name in contents.sorted() {
            let full = (path as NSString).appendingPathComponent(name)
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: full, isDirectory: &isDir), !isDir.boolValue {
                entries.append(.file(name, full))
            }
        }
        tableView.reloadData()
    }

    // MARK: - Helpers

    private func openFileEditor(_ path: String) {
        let editor = FileEditorViewController(filePath: path)
        navigationController?.pushViewController(editor, animated: true)
    }

    private func showAlert(_ title: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.view.window != nil else { return }
            let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "好", style: .default))
            self.present(ac, animated: true)
        }
    }
}

// MARK: - UITableViewDelegate/DataSource

extension FileBrowserViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        switch entries[indexPath.row] {
        case .dir(let name, _):
            cell.textLabel?.text = "📁 \(name)"
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.font = .boldSystemFont(ofSize: 15)
        case .file(let name, _):
            cell.textLabel?.text = "📄 \(name)"
            cell.accessoryType = .detailButton
            cell.textLabel?.font = .systemFont(ofSize: 15)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch entries[indexPath.row] {
        case .dir(_, let path):
            navigateTo(path)
        case .file(_, let path):
            openFileEditor(path)
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if case .file = entries[indexPath.row] { return true }
        return false
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        if case .file(_, let path) = entries[indexPath.row] {
            do {
                try FileManager.default.removeItem(atPath: path)
                entries.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            } catch {
                showAlert("删除失败", message: error.localizedDescription)
            }
        }
    }
}

// MARK: - 文件编辑器

final class FileEditorViewController: UIViewController {

    private let filePath: String
    private let textView = UITextView()
    private var originalContent: String = ""

    init(filePath: String) {
        self.filePath = filePath
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = (filePath as NSString).lastPathComponent
        view.backgroundColor = .systemBackground
        setupTextView()
        setupToolbar()
        loadFile()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 提示未保存
        if textView.text != originalContent {
            // just let it go; user can re-open
        }
    }

    // MARK: - UI

    private func setupTextView() {
        textView.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -48),
        ])
    }

    private func setupToolbar() {
        let saveBtn = UIBarButtonItem(title: "保存", style: .done, target: self, action: #selector(saveTapped))
        let revertBtn = UIBarButtonItem(title: "还原", style: .plain, target: self, action: #selector(revertTapped))
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [flex, revertBtn, flex, saveBtn]
        navigationController?.isToolbarHidden = false

        // Undo/Redo support
        textView.undoManager?.levelsOfUndo = 100
    }

    // MARK: - File I/O

    private func loadFile() {
        guard let data = FileManager.default.contents(atPath: filePath) else {
            textView.text = "【无法读取文件】\n路径: \(filePath)"
            textView.isEditable = false
            return
        }

        // Try UTF-8 first
        if let content = String(data: data, encoding: .utf8) {
            textView.text = content
            originalContent = content
            return
        }
        // Try other encodings
        for enc: String.Encoding in [.ascii, .isoLatin1, .windowsCP1252, .utf16LittleEndian] {
            if let content = String(data: data, encoding: enc) {
                textView.text = content
                originalContent = content
                return
            }
        }
        // Fallback: show hex
        textView.text = data.hexDump(header: "Binary data (\(data.count) bytes):\n")
        textView.isEditable = false
        originalContent = textView.text
    }

    @objc private func saveTapped() {
        guard textView.isEditable else {
            showAlert("二进制文件不支持编辑")
            return
        }

        guard let data = textView.text.data(using: .utf8) else {
            showAlert("编码失败", message: "无法将文本转为 UTF-8")
            return
        }

        do {
            // Set write permission first (remote chmod before write)
            LsdHelper.remoteChmodPath(filePath, mode: 0o777)
            try data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
            originalContent = textView.text
            showAlert("保存成功", message: "文件已写入:\n\(filePath)")
        } catch {
            showAlert("保存失败", message: error.localizedDescription)
        }
    }

    @objc private func revertTapped() {
        textView.text = originalContent
    }

    private func showAlert(_ title: String, message: String = "") {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.view.window != nil else { return }
            let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "好", style: .default))
            self.present(ac, animated: true)
        }
    }
}

// MARK: - Data hex dump helper

private extension Data {
    func hexDump(header: String) -> String {
        var out = header
        for (i, byte) in enumerated() {
            if i > 0 && i % 16 == 0 { out += "\n" }
            out += String(format: "%02X ", byte)
        }
        return out
    }
}