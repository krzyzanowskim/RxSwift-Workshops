import RxCocoa
import RxSwift
import UIKit
import RxSwiftUtilities

class TimetableViewController: UIViewController {

    init(timetableService: TimetableService = HTTPTimetableService(),
         presenter: TimeTableCellPresenter = TimeTableCellPresenter(),
         filter: TimetableFiltering = TimetableFilter()) {
        self.timetableService = timetableService
        self.presenter = presenter
        self.timetableFilter = filter

        super.init(nibName: nil, bundle: nil)
    }

    private let activityIndicator = ActivityIndicator()

    var timetableView: TimetableView! {
        return view as? TimetableView
    }

    let refreshControl = UIRefreshControl(frame: .zero)

    // MARK: - Lifecycle

    override func loadView() {
        view = TimetableView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Timetable"
        setUpActivityIndicator()
        setUpSegments()
        selectFirstSegment()
        setUpTableViewDataSource()
        setUpRefreshControl()
    }

    var selectedFilter: Observable<Filter> {
        return timetableView.filterView.segmentedControl.rx.selectedSegmentIndex
            .filter { $0 >= 0 }
            .map { Filter.allCases[$0] }
    }

    // MARK: - Private

    private let timetableService: TimetableService
    private let presenter: TimeTableCellPresenter
    private let timetableFilter: TimetableFiltering

    private func setUpActivityIndicator() {
        activityIndicator.asDriver().drive(UIApplication.shared.rx.progress).disposed(by: disposeBag)
    }

    private func setUpTableViewDataSource() {
        let initial = Observable.just(())
        let refresh = refreshControl.rx.controlEvent(.valueChanged).asObservable()
        let entries = Observable.merge(initial, refresh).flatMap { [unowned self] in
            self.timetableService.timetableEntries
            .do(onNext: { _ in
                self.refreshControl.endRefreshing()
            })
            .trackActivity(self.activityIndicator)
        }
        Observable.combineLatest(entries, selectedFilter) { [timetableFilter] entries, selectedFilter -> [TimetableEntry] in
                let sortedEntries = entries.sorted { $0.departureTime < $1.departureTime }
                return timetableFilter.apply(filter: selectedFilter, for: sortedEntries)
            }
            .asDriver(onErrorDriveWith: .just([]))
            .drive(timetableView.tableView.rx.items(cellIdentifier: "TimetableCell")) { [weak self] (_, entry, cell: TimetableEntryCell) in
                self?.configure(cell: cell, with: entry)
            }
            .disposed(by: disposeBag)
    }

    private func configure(cell: TimetableEntryCell, with entry: TimetableEntry) {
        presenter.present(model: entry, in: cell)

        cell.checkInButton.rx.tap.asObservable()
            .map { entry.id }
            .subscribe(onNext: { [weak self] timetableID in
                self?.pushCheckInViewController(timetableID: timetableID)
            })
            .disposed(by: cell.disposeBag)
    }

    private func pushCheckInViewController(timetableID: Int) {
        let checkInController = CheckInViewController(timetableID: timetableID)
        pushController?(checkInController, true)
    }

    // MARK: Filter view

    private func setUpSegments() {
        Filter.allCases.enumerated().forEach { index, filter in
            let segmentedControl = timetableView.filterView.segmentedControl
            segmentedControl.insertSegment(withTitle: filter.rawValue, at: index, animated: false)
        }
    }

    private let disposeBag = DisposeBag()

    private func selectFirstSegment() {
        timetableView.filterView.segmentedControl.selectedSegmentIndex = 0
    }

    private func setUpRefreshControl() {
        timetableView.tableView.refreshControl = refreshControl
    }

    // MARK: Helpers

    lazy var pushController: ((UIViewController, Bool) -> Void)? = navigationController?.pushViewController(_:animated:)

    // MARK: Required initializer

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

}
