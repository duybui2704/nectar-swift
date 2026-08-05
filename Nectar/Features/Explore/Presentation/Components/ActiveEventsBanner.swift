//
//  ActiveEventsBanner 2.swift
//  Nectar
//
//  Created by admin on 5/8/26.
//


//
//  ActiveEventsBanner.swift
//  Nectar
//
//  Created by admin on 5/8/26.
//


import SwiftUI

/// Banner active event — Explore (dưới search) + Home (cuối trang).
struct ActiveEventsBanner: View {
    let events: [ActiveEvent]
    @HotReloadObserver private var _hr

    var body: some View {
        if events.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                         LazyHStack(spacing: 32) {
                             ForEach(events) { event in
                                 bannerCard(event)
                             }
                         }
                         .frame(maxWidth: .infinity, alignment: .leading)
           }
        }
            
    }

    private func bannerCard(_ event: ActiveEvent) -> some View {
        VStack(alignment: .leading) {

                 RemoteImageView(
                     url: event.bannerURL,
                     contentMode: .fill,
                     showsLoadingIndicator: false
                 )
                 .frame(
                     width: UIScreen.main.bounds.width - 50,
                     height: 180
                 )
                 .scaledToFill()
                 .clipped()
                 .clipShape(RoundedRectangle(cornerRadius: 12))
               

                 Text(event.name)
                     .font(NectarFonts.elmsSans(size: 18.scaled, weight: .bold))
                     .foregroundStyle(NectarColors.textPrimary)
                     .lineLimit(2)
             }
        .frame(
            width: UIScreen.main.bounds.width - 36,
            alignment: .leading
        )
     
    }
}
