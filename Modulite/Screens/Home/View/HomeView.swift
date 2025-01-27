//
//  HomeView.swift
//  Modulite
//
//  Created by Gustavo Munhoz Correa on 09/08/24.
//

import UIKit
import SnapKit

/// `HomeView` is a scrollable container view that includes three different sections, 
/// each represented by a `UICollectionView`.
/// These collections are used for displaying main widgets, auxiliary widgets, and tips respectively.
class HomeView: UIScrollView {
    
    // MARK: - Properties
    
    /// Container view that holds all subviews to enable vertical scrolling.
    private let contentView = UIView()
    
    private(set) lazy var moduliteAppLogo: UIImageView = {
        let view = UIImageView(image: .moduliteAppName)
        view.contentMode = .scaleAspectFit
                
        return view
    }()
    
    /// Collection view for displaying main widgets.
    private(set) lazy var mainWidgetsCollectionView = createCollectionView(for: .mainWidgets)
    
    private let mainWidgetsPlaceholderView = MainWidgetsPlaceholderView()
    
    /// Collection view for displaying auxiliary widgets.
    private(set) lazy var auxiliaryWidgetsCollectionView = createCollectionView(for: .auxiliaryWidgets)
    
    private(set) var auxWidgetsPlaceholderView: UIView = AuxiliaryWidgetsPlaceholderView()
    
    /// Collection view for displaying tips.
    private(set) lazy var tipsCollectionView: UICollectionView = createCollectionView(for: .tips)
    
    /// Enumeration to define sections within the HomeView for better management.
    fileprivate enum ViewSection: Equatable {
        case mainWidgets
        case auxiliaryWidgets
        case tips
    }
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .whiteTurnip
        showsVerticalScrollIndicator = false
        
        addSubviews()
        setupConstraints()
        setupCollectionViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup methods
        
    func setCollectionViewDelegates(to delegate: UICollectionViewDelegate) {
        mainWidgetsCollectionView.delegate = delegate
        auxiliaryWidgetsCollectionView.delegate = delegate
        tipsCollectionView.delegate = delegate
    }
        
    func setCollectionViewDataSources(to dataSource: UICollectionViewDataSource) {
        mainWidgetsCollectionView.dataSource = dataSource
        auxiliaryWidgetsCollectionView.dataSource = dataSource
        tipsCollectionView.dataSource = dataSource
    }
        
    private func setupCollectionViews() {
        mainWidgetsCollectionView.register(
            HomeWidgetCollectionViewCell.self,
            forCellWithReuseIdentifier: HomeWidgetCollectionViewCell.reuseId
        )
        
        mainWidgetsCollectionView.register(
            HomeHeaderReusableCell.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: HomeHeaderReusableCell.reuseId
        )
        
        auxiliaryWidgetsCollectionView.register(
            HomeWidgetCollectionViewCell.self,
            forCellWithReuseIdentifier: HomeWidgetCollectionViewCell.reuseId
        )
        auxiliaryWidgetsCollectionView.register(
            HomeHeaderReusableCell.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: HomeHeaderReusableCell.reuseId
        )
        
        tipsCollectionView.register(
            TipCollectionViewCell.self,
            forCellWithReuseIdentifier: TipCollectionViewCell.reuseId
        )
        tipsCollectionView.register(
            HomeHeaderReusableCell.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: HomeHeaderReusableCell.reuseId
        )
    }
    
    @discardableResult
    func addSeparatorBelow(view: UIView) -> SeparatorView {
        let separator = SeparatorView()
        
        contentView.addSubview(separator)
        
        separator.snp.makeConstraints { make in
            make.top.equalTo(view.snp.bottom).offset(12)
            make.left.right.equalToSuperview()
        }
        
        return separator
    }
    
    /// Adds all subviews to the contentView, which is then added to the UIScrollView.
    private func addSubviews() {
        addSubview(contentView)
        
        contentView.addSubview(moduliteAppLogo)
        
        contentView.addSubview(mainWidgetsPlaceholderView)
        contentView.addSubview(mainWidgetsCollectionView)
        contentView.addSubview(auxWidgetsPlaceholderView)
        contentView.addSubview(auxiliaryWidgetsCollectionView)
//        contentView.addSubview(tipsCollectionView)
    }
        
    private func setupConstraints() {
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(top: 0, left: 20, bottom: 0, right: -20)
            )
            make.width.equalToSuperview().offset(-40)
        }
        
        moduliteAppLogo.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.height.equalTo(32)
            make.width.equalTo(226)
        }
        
        let firstSeparator = addSeparatorBelow(view: moduliteAppLogo)
        
        mainWidgetsCollectionView.snp.makeConstraints { make in
            make.top.equalTo(firstSeparator.snp.bottom).offset(16)
            make.left.right.equalToSuperview()
            make.height.equalTo(300)
        }
        
        mainWidgetsPlaceholderView.snp.makeConstraints { make in
            make.edges.equalTo(mainWidgetsCollectionView)
        }
        
        let secondSeparator = addSeparatorBelow(view: mainWidgetsCollectionView)
        
        auxiliaryWidgetsCollectionView.snp.makeConstraints { make in
            make.top.equalTo(secondSeparator.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(190)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        auxWidgetsPlaceholderView.snp.makeConstraints { make in
            make.edges.equalTo(auxiliaryWidgetsCollectionView)
        }
        
        // TODO: Add TipsView
        
//        let thirdSeparator = addSeparatorBelow(view: auxWidgetsPlaceholderView)
//        
//        tipsCollectionView.snp.makeConstraints { make in
//            make.top.equalTo(thirdSeparator.snp.bottom)
//            make.left.right.equalToSuperview()
//            make.height.equalTo(210)
//            make.bottom.equalToSuperview().offset(-20)
//        }
    }
    
    func setMainWidgetPlaceholderVisibility(to shouldShow: Bool) {
        mainWidgetsPlaceholderView.isHidden = !shouldShow
    }
    
    func setAuxWidgetPlaceholderVisibility(to shouldShow: Bool) {
        auxWidgetsPlaceholderView.isHidden = !shouldShow
    }
    
    func setAuxWidgetPlaceholderToPlusVersion() {
        auxWidgetsPlaceholderView.removeFromSuperview()
        auxWidgetsPlaceholderView = MainWidgetsPlaceholderView()
        
        contentView.insertSubview(
            auxWidgetsPlaceholderView,
            belowSubview: auxiliaryWidgetsCollectionView
        )
        
        auxWidgetsPlaceholderView.snp.makeConstraints { make in
            make.edges.equalTo(auxiliaryWidgetsCollectionView)
        }
    }
    
    // MARK: - Helper methods
    
    /// Calculates and returns the appropriate size for a given collection view layout section.
    private func getGroupSizeForCollectionViewLayout(for section: ViewSection) -> CGSize {
        switch section {
        case .mainWidgets: return CGSize(width: 187, height: 234)
        case .auxiliaryWidgets: return CGSize(width: 187, height: 130)
        case .tips: return CGSize(width: 200, height: 150)
        }
    }
    
    /// Creates and returns a collection view configured with a compositional layout based on the section type.
    private func createCollectionView(for section: ViewSection) -> UICollectionView {
        let layout = UICollectionViewCompositionalLayout { [weak self] _, _ -> NSCollectionLayoutSection? in
            guard let self = self else { return nil }
            
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
 
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let size = self.getGroupSizeForCollectionViewLayout(for: section)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(size.width),
                heightDimension: .absolute(size.height)
            )
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            
            section.interGroupSpacing = 16
            
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(60)
            )
            
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            
            section.boundarySupplementaryItems = [header]
            return section
        }
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.clipsToBounds = false
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        
        return collectionView
    }
}
