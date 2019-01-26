import Foundation
import RxSwift

class HTTPTimetableService: TimetableService {

    init(apiRoute: String = "http://peaceful-fortress-94735.herokuapp.com/api/v1",
         urlSession: URLSession = .shared) {
        self.apiRoute = apiRoute
        self.urlSession = urlSession
    }

    // MARK: - TimetableService

    var timetableEntries: Observable<[TimetableEntry]> {
        guard let url = URL(string: timetablesRoute) else {
            fatalError("Could not build URL: \(timetablesRoute)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestObservable: Observable<[TimetableEntry]> = urlSession.rx.response(request: request)
            .flatMap { (response, data) -> Observable<[TimetableEntry]> in
                guard let decoded = JSONDecoder.timetable(from: data), response.statusCode == 200 else {
                    return Observable.error(TimetableServiceError.unknown)
                }
                return Observable.just(decoded.results)
            }
            .catchError { error in
                Observable.error(error)
            }

        return requestObservable
            .observeOn(MainScheduler.instance)
    }

    // MARK: - Private

    private let apiRoute: String
    private let urlSession: URLSession

    private var timetablesRoute: String {
        return "\(apiRoute)/timetables/"
    }

}
