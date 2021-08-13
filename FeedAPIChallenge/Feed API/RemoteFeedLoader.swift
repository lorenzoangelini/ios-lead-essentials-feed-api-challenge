//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { [weak self] result in
			guard self != nil else {
				return
			}
			switch result {
			case let .success((data, response)):
				completion(FeedLoaderMapper.map(data, from: response))

			case .failure:
				completion(.failure(Error.connectivity))
			}
		}
	}
}

private class FeedLoaderMapper {
	private struct Root: Codable {
		let items: [Image]
		var images: [FeedImage] {
			return items.map {
				$0.item
			}
		}
	}

	private struct Image: Codable {
		let image_id: UUID
		let image_desc: String?
		let image_loc: String?
		let image_url: URL

		var item: FeedImage {
			FeedImage(id: image_id, description: image_desc, location: image_loc, url: image_url)
		}
	}

	private static let STATUS_200 = 200

	static func map(_ data: Data, from response: HTTPURLResponse) -> RemoteFeedLoader.Result {
		guard response.statusCode == 200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
			return .failure(RemoteFeedLoader.Error.invalidData)
		}
		return .success(root.images)
	}
}
