//
//  WidgetSetupViewController.swift
//  Modulite
//
//  Created by Gustavo Munhoz Correa on 14/08/24.
//

import UIKit
import TipKit

class WidgetSetupViewController: UIViewController {
    static let didSelectWidgetStyle = Tips.Event(id: "didSelectWidgetStyle")
    static let didSelectApps = Tips.Event(id: "didSelectApps")
    
    // MARK: - Properties
    let setupView = WidgetSetupView()
    var viewModel = WidgetSetupViewModel()
    
    weak var delegate: WidgetSetupViewControllerDelegate?
    
    private var isEditingWidget: Bool = false
    
    var didMakeChanges: Bool = false
    
    var isOnboarding: Bool = false
    
    private var selectWidgetStyleTip = SelectWidgetStyleTip()
    private var selectAppsTip = SelectAppsTip()
    private var proceedToEditorTip = ProceedToEditorTip()
    private var styleTipObservationTask: Task<Void, Never>?
    private var selectAppsTipObservationTask: Task<Void, Never>?
    private var proceedTipObservationTask: Task<Void, Never>?
    private weak var tipPopoverController: TipUIPopoverViewController?
    
    // MARK: - Lifecycle
    override func loadView() {
        view = setupView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
//        viewModel.updatePurchaseStatus()
//        
//        PurchasedSkinsManager.shared.onPurchaseCompleted = { [weak self] productId in
//            self?.handlePurchaseCompleted(for: productId)
//        }
        
        configureViewDependencies()
        setupNavigationBar()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        setupView.updateSelectedAppsCollectionViewHeight()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard isOnboarding else { return }
        
        setupTipObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        breakdownTipObservers()
    }
    
    // MARK: - Setup methods
    private func setupTipObservers() {
        styleTipObservationTask = styleTipObservationTask ?? createObservationTask(
            for: selectWidgetStyleTip,
            sourceItem: setupView.stylesCollectionView
        )
        
        selectAppsTipObservationTask = selectAppsTipObservationTask ?? createObservationTask(
            for: selectAppsTip,
            sourceItem: setupView.searchAppsButton
        )
        
        proceedTipObservationTask = proceedTipObservationTask ?? createObservationTask(
            for: proceedToEditorTip,
            sourceItem: setupView.nextViewButton
        )
    }
    
    private func breakdownTipObservers() {
        styleTipObservationTask?.cancel()
        styleTipObservationTask = nil
        
        selectAppsTipObservationTask?.cancel()
        selectAppsTipObservationTask = nil
        
        proceedTipObservationTask?.cancel()
        proceedTipObservationTask = nil
    }
    
    func setupNavigationBar() {
        guard isEditingWidget else { return }
        
        navigationItem.backAction = UIAction { [weak self] _ in
            self?.handleBackButtonPress()
        }
    }
    
    func setToWidgetEditingMode() {
        isEditingWidget = true
    }
    
    private func configureViewDependencies() {
        setupView.setCollectionViewDelegates(to: self)
        setupView.setCollectionViewDataSources(to: self)
        setupView.setWidgetNameTextFieldDelegate(to: self)
        
        setupView.onNextButtonPressed = proceedToWidgetEditor
        setupView.onSearchButtonPressed = presentSearchModal
    }
    
    private func setPlaceholderName(to name: String) {
        setupView.widgetNameTextField.placeholder = name
    }
    
    // MARK: - Actions
    @objc func handleBackButtonPress() {
        delegate?.widgetSetupViewControllerDidPressBack(
            self,
            didMakeChanges: didMakeChanges
        )
    }
    
    func didFinishSelectingApps(apps: [AppInfo]) {
        setSetupViewHasAppsSelected(to: !apps.isEmpty)
        viewModel.setSelectedApps(to: apps)
        
        setupView.selectedAppsCollectionView.reloadData()
        
        if !apps.isEmpty, isOnboarding {
            Self.didSelectApps.sendDonation()
        }
    }
    
    func proceedToWidgetEditor() {
        if isOnboarding { dismissCurrentTip() }
        
        delegate?.widgetSetupViewControllerDidPressNext(
            widgetName: setupView.getWidgetName()
        )
    }
    
    func presentSearchModal() {
        if isOnboarding && tipPopoverController != nil {
            dismissCurrentTip()
        }
        
        delegate?.widgetSetupViewControllerDidTapSearchApps(self)
    }
    
    func setSetupViewStyleSelected(to value: Bool) {
        setupView.isStyleSelected = value
        setupView.updateButtonConfig()
    }
    
    func setSetupViewHasAppsSelected(to value: Bool) {
        setupView.hasAppsSelected = value
        setupView.updateButtonConfig()
    }
    
    // MARK: - Onboarding
    
    private func createObservationTask(
        for tip: any Tip,
        sourceItem: UIPopoverPresentationControllerSourceItem
    ) -> Task<Void, Never>? {
        Task { @MainActor in
            for await shouldDisplay in tip.shouldDisplayUpdates where shouldDisplay {
                presentTip(tip, sourceItem: sourceItem)
            }
        }
    }
    
    private func presentTip(
        _ tip: any Tip,
        sourceItem: any UIPopoverPresentationControllerSourceItem
    ) {
        dismissCurrentTip()
        
        let popoverController = TipUIPopoverViewController(
            tip,
            sourceItem: sourceItem
        )
        
        popoverController.popoverPresentationController?.passthroughViews = [setupView]
        
        present(popoverController, animated: true)
        tipPopoverController = popoverController
    }
    
    private func dismissCurrentTip(_ animated: Bool = true) {
        if presentedViewController is TipUIPopoverViewController {
            dismiss(animated: animated)
            tipPopoverController = nil
        }
    }
    
    private func handlePurchaseCompleted(for productId: String) {
        if let index = viewModel.widgetStyles.firstIndex(where: { $0.key.rawValue == productId }) {
            viewModel.widgetStyles[index].isPurchased = true
            setupView.stylesCollectionView.reloadData()
        }
    }
}

extension WidgetSetupViewController {
    class func instantiate(delegate: WidgetSetupViewControllerDelegate) -> WidgetSetupViewController {
        let vc = WidgetSetupViewController()
        vc.delegate = delegate
        vc.setPlaceholderName(to: delegate.getPlaceholderName())
        
        return vc
    }
    
    func loadDataFromContent(_ content: WidgetContent) {
        setupView.widgetNameTextField.text = content.name
        viewModel.setWidgetStyle(to: content.style)
        guard let apps = content.apps.filter({ $0 != nil }) as? [AppInfo] else { return }
        
        viewModel.setSelectedApps(to: apps)
        
        setSetupViewStyleSelected(to: true)
        setSetupViewHasAppsSelected(to: true)
    }
}

// MARK: - SelectedAppCollectionViewCellDelegate
extension WidgetSetupViewController: SelectedAppCollectionViewCellDelegate {
    func selectedAppCollectionViewCellDidPressDelete(_ cell: SelectedAppCollectionViewCell) {
        guard let indexPath = setupView.selectedAppsCollectionView.indexPath(for: cell) else {
            print("Could not get IndexPath for app cell")
            return
        }
        
        didMakeChanges = true
        
        let app = viewModel.selectedApps[indexPath.row]
        viewModel.removeSelectedApp(app)
        delegate?.widgetSetupViewControllerDidDeselectApp(self, app: app)
        setupView.selectedAppsCollectionView.performBatchUpdates({ [weak self] in
            self?.setupView.selectedAppsCollectionView.deleteItems(at: [indexPath])
            
        }, completion: { _ in
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.setupView.setNeedsLayout()
                self?.setupView.layoutIfNeeded()
            }
        })
    }
}

// MARK: - UICollectionViewDataSource
extension WidgetSetupViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section != 0 else { return 0 }
        
        switch collectionView {
        case setupView.stylesCollectionView: return viewModel.widgetStyles.count
        case setupView.selectedAppsCollectionView: return viewModel.selectedApps.count
        default: return 0
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
        switch collectionView {
        case setupView.stylesCollectionView:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: StyleCollectionViewCell.reuseId,
                for: indexPath
            ) as? StyleCollectionViewCell else {
                fatalError("Could not dequeue StyleCollectionViewCell")
            }
            
            let style = viewModel.widgetStyles[indexPath.row]
            
            cell.setup(
                image: style.previewImage,
                title: style.name,
                delegate: self,
                isPurchased: style.isPurchased
            )
            
            cell.hasSelectionBeenMade = viewModel.isStyleSelected()
            
            if style == viewModel.selectedStyle {
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
            }
            
            return cell
            
        case setupView.selectedAppsCollectionView:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: SelectedAppCollectionViewCell.reuseId,
                for: indexPath
            ) as? SelectedAppCollectionViewCell else {
                fatalError("Could not dequeue StyleCollectionViewCell")
            }
            
            cell.setup(with: viewModel.selectedApps[indexPath.row].name)
            cell.delegate = self
            
            return cell
        
        default: fatalError("Unsupported View Controller.")
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        
        guard let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: SetupHeaderReusableCell.reuseId,
            for: indexPath
        ) as? SetupHeaderReusableCell else {
            fatalError("Could not dequeue SetupHeader cell.")
        }
        
        if collectionView === setupView.stylesCollectionView {
            header.setup(title: .localized(for: .widgetSetupViewStyleHeaderTitle))
            
        } else {
            header.setup(title: .localized(for: .widgetSetupViewAppsHeaderTitle))
        }
        return header
    }
}

// MARK: - UICollectionViewDelegate
extension WidgetSetupViewController: UICollectionViewDelegate {
    func selectStyle(_ style: WidgetStyle) {
        guard let index = viewModel.widgetStyles.firstIndex(of: style) else { return }
        let indexPath = IndexPath(item: index, section: 1)
        
        viewModel.selectStyle(at: index)
        viewModel.setWidgetStyle(to: style)
        
        setupView.stylesCollectionView.selectItem(
            at: indexPath,
            animated: true,
            scrollPosition: .centeredHorizontally
        )
        
        setupView.stylesCollectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case setupView.stylesCollectionView:
            let widgetStyle = viewModel.widgetStyles[indexPath.row]
            
            if widgetStyle.isPurchased {
                guard let style = viewModel.selectStyle(at: indexPath.row) else { return }
                
                didMakeChanges = true
                setSetupViewStyleSelected(to: true)
                delegate?.widgetSetupViewControllerDidSelectWidgetStyle(self, style: style)
            } else {
                delegate?.widgetSetupViewControllerShouldPresentPurchasePreview(self, for: widgetStyle)
            }

            collectionView.reloadData()
            
            if isOnboarding { Self.didSelectWidgetStyle.sendDonation() }
            
        default: return
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension WidgetSetupViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let text = viewModel.selectedApps[indexPath.row].name
        let font = UIFont(textStyle: .title3, weight: .semibold)
        let size = (text as NSString).size(withAttributes: [NSAttributedString.Key.font: font])
        
        return CGSize(width: size.width + 45, height: size.height + 24)
    }
}
