import Foundation

class GitHubClient {

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        return session
    }()

    func send<Request : GitHubRequest>(request: Request, completion: @escaping (Result<Request.Response, GitHubClientError>) -> Void) {
        // request仕様からHTTPリクエスト（urlRequest）を生成
        let urlRequest = request.buildURLRequest()
        // リクエストごとの通信タスクを管理し、HTTPサーバと通信してHTTPレスポンスとバイナリデータを受け取る
        let task = session.dataTask(with: urlRequest) { data, response, error in
            switch (data, response, error) {
            // errorがnilでない
            case (_, _, let error?):
                completion(Result(error: .connectionError(error)))
            // dataとresponse両方ともnilでない
            case (let data?, let response?, _):
                do {
                    // HTTPレスポンスとバイナリデータをレスポンスの仕様を表す型に変換
                    let response = try request.response(from: data, urlResponse: response)
                    completion(Result(value: response))
                } catch let error as GitHubAPIError {
                    completion(Result(error: .apiError(error)))
                } catch {
                    completion(Result(error: .responseParseError(error)))
                }
            default:
                fatalError("invalid response combination \(data), \(response), \(error).")
            }
        }

        task.resume()
    }
}
