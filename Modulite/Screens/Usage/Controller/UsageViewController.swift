import UIKit
import DeviceActivity
import FamilyControls
import Combine

class UsageViewController: UIViewController {
    
    private var usageView = UsageView() // Custom view
    private var usageViewModel = UsageViewModel() // ViewModel que contém a lógica de negócios
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Lifecycle
    
    override func loadView() {
        view = usageView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBindings()
        
        let authCenter = AuthorizationCenter.shared

        Task {
            do {
                // Solicita autorização para uso do Screen Time
                try await authCenter.requestAuthorization(for: .individual)
                
            } catch {
                print("Authorization Error")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }
    
    // MARK: - Setup methods
    private func setupNavigationBar() {
        navigationItem.title = .localized(for: .usageViewControllerNavigationTitle)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func setupBindings() {
        // Observa mudanças no totalScreenTime do ViewModel e atualiza a timeSpentLabel
        usageViewModel.$totalScreenTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] totalScreenTime in
                let formattedTime = self?.formatTime(totalScreenTime)
                self?.usageView.timeSpentLabel.text = formattedTime
            }
            .store(in: &cancellables)
        
        // Observa mudanças na média diária de ontem e atualiza a dailyAvarageYesterdayLabel
        usageViewModel.$dailyAverageYesterday
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dailyAverageYesterday in
                self?.usageView.dailyAvarageYesterdayLabel.timeLabel.text = self?.formatTime(dailyAverageYesterday)
            }
            .store(in: &cancellables)
        
        // Observa mudanças na média diária da semana passada e atualiza a dailyAvarageLastWeek
        usageViewModel.$dailyAverageLastWeek
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dailyAverageLastWeek in
                self?.usageView.dailyAvarageLastWeek.timeLabel.text = self?.formatTime(dailyAverageLastWeek)
            }
            .store(in: &cancellables)
    }
    
    // Função utilitária para formatar o tempo
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}
