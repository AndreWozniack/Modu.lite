//
//  HomeViewController.swift
//  Modulite
//
//  Created by Gustavo Munhoz Correa on 09/08/24.
//

import UIKit

protocol HomeViewControllerDelegate: AnyObject {
    func homeViewControllerDidStartWidgetCreationFlow(
        _ viewController: HomeViewController
    )
}

class HomeViewController: UIViewController {

    // MARK: - Properties
    private let homeView = HomeView()
    private let viewModel = HomeViewModel()
    
    weak var delegate: HomeViewControllerDelegate?
    
    // MARK: - Lifecycle
    override func loadView() {
        self.view = homeView
        homeView.setCollectionViewDelegates(to: self)
        homeView.setCollectionViewDataSources(to: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
    }
    
    // MARK: - Setup methods
    private func setupNavigationBar() {
        // FIXME: Make image be on bottom-left of navbar with large title
            
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.whiteTurnip
                
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        if let image = UIImage(named: "navbar-app-name") {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            
            navigationItem.titleView = imageView
            
        } else {
            print("Image not found")
        }
    }
    
    // MARK: - Actions
    func getCurrentMainWidgetCount() -> Int {
        viewModel.mainWidgets.count
    }
    
    func registerNewWidget(_ widget: ModuliteWidgetConfiguration) {
        viewModel.addMainWidget(widget)
        homeView.mainWidgetsCollectionView.reloadData()
    }
}

extension HomeViewController {
    class func instantiate(delegate: HomeViewControllerDelegate) -> HomeViewController {
        let homeVC = HomeViewController()
        homeVC.delegate = delegate
        return homeVC
    }
}

// MARK: - UICollectionViewDataSource
extension HomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch collectionView {
        case homeView.mainWidgetsCollectionView: return viewModel.mainWidgets.count
        case homeView.auxiliaryWidgetsCollectionView: return viewModel.auxiliaryWidgets.count
        case homeView.tipsCollectionView: return viewModel.tips.count
        default: return 0
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
        switch collectionView {
        case homeView.mainWidgetsCollectionView:
            guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: MainWidgetCollectionViewCell.reuseId,
                    for: indexPath
                  ) as? MainWidgetCollectionViewCell else {
                fatalError("Could not dequeue MainWidgetCollectionViewCell.")
            }
            
            let widget = viewModel.mainWidgets[indexPath.row]
            cell.configure(image: widget.previewImage, name: widget.name)
            cell.delegate = self
            
            return cell
            
        case homeView.auxiliaryWidgetsCollectionView:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: AuxiliaryWidgetCollectionViewCell.reuseId,
                for: indexPath
            ) as? AuxiliaryWidgetCollectionViewCell else {
                fatalError("Could not dequeue AuxiliaryWidgetCollectionViewCell.")
            }
            
            cell.configure(with: viewModel.auxiliaryWidgets[indexPath.row])
            
            return cell
            
        case homeView.tipsCollectionView:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TipCollectionViewCell.reuseId,
                for: indexPath
            ) as? TipCollectionViewCell else {
                fatalError("Could not dequeue TipCollectionViewCell.")
            }
            
            return cell
            
        default:
            fatalError("Unsupported collection view.")
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
            withReuseIdentifier: HomeHeaderReusableCell.reuseId,
            for: indexPath
        ) as? HomeHeaderReusableCell else {
            fatalError("Error dequeueing Header cell.")
        }
        
        switch collectionView {
        case homeView.mainWidgetsCollectionView:
            header.setup(
                title: .localized(for: .homeViewMainSectionHeaderTitle),
                buttonImage: UIImage(systemName: "plus.circle")!,
                buttonAction: { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.homeViewControllerDidStartWidgetCreationFlow(self)
                }
            )
            
        case homeView.auxiliaryWidgetsCollectionView:
            header.setup(
                title: .localized(for: .homeViewAuxiliarySectionHeaderTitle),
                buttonImage: UIImage(systemName: "plus.circle")!,
                buttonAction: { [weak self] in
                    guard let self = self else { return }
                    let id = self.viewModel.mainWidgets[indexPath.row]
                    self.delegate?.homeViewControllerDidStartWidgetCreationFlow(self)
                }
            )
            
        case homeView.tipsCollectionView:
            header.setup(
                title: .localized(for: .homeViewTipsSectionHeaderTitle),
                buttonImage: UIImage(systemName: "ellipsis")!,
                buttonColor: .systemGray,
                buttonAction: {
                    // TODO: Implement this
                }
            )
            
        default: fatalError("Unsupported collection view.")
        }
        
        return header
    }
}

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {
    // TODO: Implement cell selection
    
//    func collectionView(
//        _ collectionView: UICollectionView,
//        contextMenuConfigurationForItemsAt indexPaths: [IndexPath],
//        point: CGPoint
//    ) -> UIContextMenuConfiguration? {
//        switch collectionView {
//        case homeView.mainWidgetsCollectionView:
//            let widgets = indexPaths.map { viewModel.mainWidgets[$0.row] }
//                        
//            return UIContextMenuConfiguration(
//                identifier: nil,
//                previewProvider: nil,
//                actionProvider: { suggestedActions in
//                    return self.makeContextMenu(for: widgets, at: indexPaths)
//                }
//            )
//            
//        default: return nil
//        }
//    }
}

//  extension HomeViewController {
//      func makeContextMenu(for widgets: [ModuliteWidgetConfiguration], at indexPaths: [IndexPath]) ->     UIMenu {
//          if widgets.count == 1 {
//              return makeContextMenu(for: widgets.first!, at: indexPaths.first!)
//
//          } else {
//              let deleteAction = UIAction(
//                  title: "Excluir \(widgets.count) Widgets",
//                  image: UIImage(systemName: "trash"),
//                  attributes: .destructive
//              ) { [weak self] action in
//                  self?.deleteWidgets(widgets, at: indexPaths)
//              }
//
//              return UIMenu(title: "", children: [deleteAction])
//          }
//      }
//
//      func makeContextMenu(for widget: ModuliteWidgetConfiguration, at indexPath: IndexPath) -> UIMenu {
//          let editAction = UIAction(
//              title: .localized(for: .homeViewWidgetContextMenuEditTitle),
//              image: UIImage(systemName: "pencil")
//          ) { [weak self] action in
//              self?.editWidget(widget, at: indexPath)
//          }
//
//          let deleteAction = UIAction(
//              title: .localized(for: .homeViewWidgetContextMenuDeleteTitle),
//              image: UIImage(systemName: "trash"),
//              attributes: .destructive
//          ) { [weak self] action in
//              self?.deleteWidget(widget, at: indexPath)
//          }
//
//          return UIMenu(title: "", children: [editAction, deleteAction])
//      }
//  }

extension HomeViewController: MainWidgetCollectionViewCellDelegate {
    func mainWidgetCellDidRequestEdit(_ cell: MainWidgetCollectionViewCell) {
        
    }
    
    func mainWidgetCellDidRequestDelete(_ cell: MainWidgetCollectionViewCell) {
        
    }
}
