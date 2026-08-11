//
//  FavouriteDTOMapper.swift
//  Nectar
//
//  Created by admin on 11/8/26.
//

import Foundation

enum FavouriteDTOMapper {

    static func map(from data: Data) -> [Favourite] {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = root["result"] as? [[String: Any]] else {
            return []
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: result) else {
            return []
        }

        return (try? JSONDecoder().decode(
            [Favourite].self,
            from: jsonData
        )) ?? []
    }
}
