import RxSwift
import XCTest

// Zadanie 4 (5min)
// Dany jest skończony strumień słów (String):

private let input: Observable<String> = Observable.of("ala", "ma", "kota")

// Ze strumienia stringów utwórz jedno zdanie.
// - pamiętaj że zdania rozpoczynamy z dużej litery
// - pamiętaj o spacjach pomiedzy słowami
// - zdanie zakończ kropką (bezpośrednio po ostatnim słowie)
// Edytuj tylko strumień przypisany do zmiennej `solution`.

private let solution: Observable<String> = input
    .toArray()
    .map {
        $0.joined(separator: " ")
    }
    .map { $0.capitalizingFirstLetter() }
    .map { $0 + "." }

//    .reduce("") {
//        $0.appending($1).appending(" ")
//    }
//    .map { $0.dropLast() + "." }
//    .map { $0.capitalizingFirstLetter() }

class Exercise4: XCTestCase {

    var resultObserver: TestObserver<String>!

    override func setUp() {
        resultObserver = TestObserver()
    }

    override func tearDown() {
        resultObserver = nil
    }

    func testSolution() {
        _ = solution.test(using: resultObserver).subscribe()

        resultObserver.assert(valuesEqualTo: ["Ala ma kota."])
    }

}
