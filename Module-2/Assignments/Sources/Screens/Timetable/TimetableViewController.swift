// DONE_0: Zaimportuj RxCocoa & RxSwift
import UIKit
import RxCocoa
import RxSwift

class TimetableViewController: UIViewController/*, UITableViewDataSource*/ { // TODO_2_DELETE: Usuń `UITableViewDataSource`
    private(set) var disposeBag: DisposeBag = DisposeBag()

    init(timetableService: TimetableService = LocalFileTimetableService(),
         presenter: TimeTableCellPresenter = TimeTableCellPresenter(),
         filter: TimetableFiltering = TimetableFilter()) {
        self.timetableService = timetableService
        self.presenter = presenter
        self.timetableFilter = filter

        super.init(nibName: nil, bundle: nil)
    }

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
        setUpSegments()
        selectFirstSegment()
        setUpTableViewDataSource()
        setUpRefreshControl()
    }

    // MARK: - Private

    private let timetableService: TimetableService
    private let presenter: TimeTableCellPresenter
    private let timetableFilter: TimetableFiltering

    private func setUpTableViewDataSource() { // TODO_2_REPLACE: Zastąp implementację funkcji
        Observable.combineLatest(timetableService.timetableEntries,
                                 timetableView.filterView.segmentedControl.rx.selectedSegmentIndex.asObservable())
            .filter { $1 != UISegmentedControl.noSegment }
            .map { (entries: [TimetableEntry], index: Int) -> [TimetableEntry] in
                let filter = Filter.allCases[index]
                return self.timetableFilter.apply(filter: filter, for: entries)
            }
            .map { $0.sorted(by: { $0.departureTime < $1.departureTime }) }
            .asDriver(onErrorJustReturn: []) // subscribe -> driver
            .drive(timetableView.tableView.rx.items(cellIdentifier: "TimetableCell", cellType: TimetableEntryCell.self)) { (row, element, cell) in
                self.configure(cell: cell, with: element)
            }
            .disposed(by: disposeBag)
    }

    private func configure(cell: TimetableEntryCell, with entry: TimetableEntry) {
        presenter.present(model: entry, in: cell)

        // DONE_3:
        // 1. Usuń fragment kodu oznaczony komentarzem `TODO_3_DELETE`.
        // 2. Zastąp wywołanie closure'a rx'owym obsłużeniem tapnięcia na przycisk:
        //   a. zastanów się co stanie się jeśli subskrypcja zostanie przypięta do dispose baga wewnątrz controllera
        //   b. rozwiąż problem zdiagnozowany w punkcie a. - do tego celu przenalizuj implementację funkcji
        //      prepareForReuse() wewnątrz klasy TimetableEntryCell
        // 3. Zweryfikuj poprawność refactoringu uruchamiając testy jednostkowe

        cell.checkInButton.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.pushCheckInViewController(timetableID: entry.id)
        }).disposed(by: cell.disposeBag)
    }

    private func pushCheckInViewController(timetableID: Int) {
        let checkInController = CheckInViewController(timetableID: timetableID)
        pushController?(checkInController, true)
    }

    // MARK: Filter view

    // DONE_1:
    // 1. Usuń wszystkie fragmenty kodu oznaczone komentarzem: `TODO_1_DELETE`
    // 2. Zrefactoruj kod tak, aby użyć właściwości rx.selectedSegmentIndex na UISegmentedControl:
    //   a. zamień wyliczenia filtru na przekształcenia funkcyjne
    //   b. zawołaj prywatną metodę update(filter:entries:) w subskrypcji
    // 3. Zweryfikuj poprawność refactoringu uruchamiając testy jednostkowe

    private func setUpSegments() {
        Filter.allCases.enumerated().forEach { index, filter in
            let segmentedControl = timetableView.filterView.segmentedControl
            segmentedControl.insertSegment(withTitle: filter.rawValue, at: index, animated: false)
        }
    }

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
