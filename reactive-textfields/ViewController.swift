//
//  ViewController.swift
//  reactive-textfields
//
//  Created by Ademola Fadumo on 22/06/2024.
//

import UIKit
import RxSwift
import RxCocoa

struct FormSection: Hashable {
    let title: String
}

struct TextFieldComponent: Hashable {
    let title: String
    let hint: String
    let islabelHidden: Bool = true
    var enabled: Bool = true
    var obscured: Bool = false
    let validations: [FieldValidation]
}

struct FieldValidation: Equatable, Hashable {
    let message: String
    var valid: Bool = false

    static func ==(lhs: FieldValidation, rhs: FieldValidation) -> Bool {
        lhs.message == rhs.message &&
        lhs.valid == rhs.valid
    }
}

enum ListItem: Hashable {
    case header(FormSection)
    case item(TextFieldComponent)
}

class ViewController: UIViewController {
    private let rootView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewCompositionalLayout { section, environment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            configuration.headerMode = .firstItemInSection
            configuration.backgroundColor = .systemBackground
            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        }
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isScrollEnabled = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .tintColor
        button.layer.cornerRadius = 12
        button.addAction(
            UIAction { _ in },
            for: .primaryActionTriggered
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var diffableDataSource: UICollectionViewDiffableDataSource<FormSection, ListItem>!
    
    private let bag = DisposeBag()
    
    let formSection: [FormSection] = [
        .init(title: "Login")
    ]
    
    let textFieldComponents: [TextFieldComponent] = [
        .init(
            title: "Email",
            hint: "Username",
            validations: [
                FieldValidation(message: "Please enter a valid email", valid: true)
            ]
        ),
        .init(
            title: "Password",
            hint: "Password",
            obscured: true,
            validations: [
                FieldValidation(message: "Password must be at least 8 characters", valid: true),
                FieldValidation(message: "Password must contain at least one uppercase letter", valid: true),
                FieldValidation(message: "Password must contain at least one lowercase letter", valid: true),
                FieldValidation(message: "Password must contain at least one special character", valid: true)
            ]
        ),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeSubviews()
        initializeViewAppearance()
        initializeDiffableDataSource()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyConstraints()
    }
    
    private func initializeSubviews() {
        view.addSubview(rootView)
        rootView.addSubview(collectionView)
        rootView.addSubview(loginButton)
    }
    
    private func initializeViewAppearance() {
        title = "Login"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground
    }
    
    private func initializeDiffableDataSource() {
        let headerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, FormSection> {
            (cell, indexPath, headerItem) in }
        
        let itemCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, TextFieldComponent> {
            (cell, indexPath, item) in
            cell.backgroundConfiguration?.backgroundColor = .tertiarySystemFill
            
            let textfield = CustomTextField(textFieldComponent: item)
            textfield.label.text = item.title.uppercased()
            textfield.field.placeholder = item.hint
            textfield.textEditingValue
                .asDriver()
                .drive(onNext: { value in
                    debugPrint("Text Editing Value: \(value)")
                })
                .disposed(by: self.bag)
            textfield.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.translatesAutoresizingMaskIntoConstraints = false
            
            cell.contentView.addSubview(textfield)
            
            NSLayoutConstraint.activate([
                textfield.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                textfield.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                textfield.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
                textfield.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12),
            ])

            NSLayoutConstraint.activate([
                cell.contentView.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
                cell.contentView.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
                cell.contentView.topAnchor.constraint(equalTo: cell.topAnchor),
                cell.contentView.bottomAnchor.constraint(equalTo: cell.bottomAnchor),
                cell.contentView.heightAnchor.constraint(equalToConstant: 72)
            ])
        }
        
        diffableDataSource = UICollectionViewDiffableDataSource<FormSection, ListItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case .header(let headerItem):
                // Dequeue header cell
                let cell = collectionView.dequeueConfiguredReusableCell(
                    using: headerCellRegistration,
                    for: indexPath,
                    item: headerItem
                )
                return cell
                
            case .item(let symbolItem):
                
                // Dequeue item cell
                let cell = collectionView.dequeueConfiguredReusableCell(
                    using: itemCellRegistration,
                    for: indexPath,
                    item: symbolItem
                )
                return cell
            }
        }
        
        var dataSourceSnapshot = NSDiffableDataSourceSnapshot<FormSection, ListItem>()
        dataSourceSnapshot.appendSections(formSection)
        self.diffableDataSource.apply(dataSourceSnapshot, animatingDifferences: true)
        
        debugPrint("Sections in: \(self.diffableDataSource.numberOfSections(in: collectionView))")
        
        for section in formSection {
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ListItem>()
            
            let headerListItem = ListItem.header(section)
            sectionSnapshot.append([headerListItem])
            
            let listItems = textFieldComponents.map { ListItem.item($0) }
            sectionSnapshot.append(listItems, to: headerListItem)
            
            // Expand this section by default
            sectionSnapshot.expand([headerListItem])
            
            // Apply section snapshot to main section
            self.diffableDataSource.apply(sectionSnapshot, to: section, animatingDifferences: true)
        }
    }
    
    private func applyConstraints() {
        NSLayoutConstraint.activate([
            rootView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            rootView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rootView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rootView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: rootView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            
            // TODO(demolaf): fix collection view size to fit cell size to avoid the below
            collectionView.heightAnchor.constraint(equalToConstant: 200),
        ])
        
        NSLayoutConstraint.activate([
            loginButton.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 16),
            loginButton.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -16),
            loginButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 24),
            loginButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
}

class CustomTextField: UIView {
    override init(frame: CGRect) {
        self.textFieldComponent = .init(title: "", hint: "", validations: [])
        super.init(frame: .zero)
    }
    
    convenience init(textFieldComponent: TextFieldComponent) {
        self.init(frame: .zero)
        self.textFieldComponent = textFieldComponent
        initialize()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private(set) var label: UILabel = {
        let label = UILabel()
        label.text = "Placeholder"
        label.font = .preferredFont(forTextStyle: .caption2)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private(set) var field: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var obscureButton: UIButton = {
        let button = UIButton(type: .custom)
        button.configuration = .plain()
        button.setImage(UIImage(systemName: "eye"), for: .normal)
        button.addAction(
            UIAction(
                handler: { _ in
                    debugPrint("Obscure button tapped")
                    self.toggleObscure()
                }),
            for: .primaryActionTriggered
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var textFieldComponent: TextFieldComponent
    
    let textEditingValue = BehaviorRelay<String>(value: .init())
    
    let bag = DisposeBag()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        applyConstraints()
    }
    
    private func initialize() {
        initializeSubviews()
        subscribeToTextField()
        initializeTextField()
        initializeObscureButton()
    }
    
    private func initializeSubviews() {
        self.addSubview(label)
        self.addSubview(field)
        self.addSubview(obscureButton)
    }
    
    private func applyConstraints() {
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
        ])
        
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            field.topAnchor.constraint(equalTo: label.bottomAnchor),
            field.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            obscureButton.leadingAnchor.constraint(equalTo: field.trailingAnchor),
            obscureButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            obscureButton.topAnchor.constraint(equalTo: topAnchor),
            obscureButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            obscureButton.widthAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    func subscribeToTextField() {
        field.rx.text.orEmpty
            .bind(to: textEditingValue)
            .disposed(by: bag)
    }

    func initializeTextField() {
        field.isSecureTextEntry = textFieldComponent.obscured
    }

    func initializeObscureButton() {
        obscureButton.isHidden = !textFieldComponent.obscured
    }

    func toggleObscure() {
        textFieldComponent.obscured.toggle()
        obscureButton.setImage(textFieldComponent.obscured ? UIImage(systemName: "eye.slash") : UIImage(systemName: "eye"), for: .normal)
        field.isSecureTextEntry = textFieldComponent.obscured
    }
}
