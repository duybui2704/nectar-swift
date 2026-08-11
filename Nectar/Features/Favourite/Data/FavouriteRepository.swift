//
//  FavouriteRepository.swift
//  Nectar
//
//  Created by admin on 11/8/26.
//
import Foundation

@MainActor
final class FavouriteRepository: FavouriteProviding {
    static let shared = FavouriteRepository()

    func fetchFavourites(
        country: String,
        pageId: Int,
        pageSize: Int
    ) async throws -> [Favourite] {

        let data = try await PrintervalAPI.fetchWishlist(
            country: country,
            pageId: pageId,
            pageSize: pageSize
        )

        let dataResult = FavouriteDTOMapper.map(from: data)

        return dataResult
    }
}
