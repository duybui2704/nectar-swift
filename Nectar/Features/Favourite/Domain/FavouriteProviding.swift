//
//  FavouriteProviding.swift
//  Nectar
//
//  Created by admin on 11/8/26.
//

import Foundation

@MainActor
protocol FavouriteProviding {
    func fetchFavourites(country: String, pageId: Int, pageSize: Int) async throws -> [Favourite]
}
