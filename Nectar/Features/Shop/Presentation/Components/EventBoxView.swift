//
//  EventBox.swift
//  Nectar
//
//  Created by admin on 3/8/26.
//

import SwiftUI
import Combine

struct EventBoxView: View {
    @Binding var event: EventBox
    var body: some View {
       ZStack(){
           Image(event.bannerUrl ?? "https://assets.printerval.com/2026/07/09/en-1-dffea7764bcd1338eadf0f0b3240c2e8.jpg").resizable().frame(width: .infinity, height: 200)
           VStack(alignment: .leading, spacing: 10){
               Text(event.name).font(.title).bold()
               Text(event.description).font(.body)
           
           }
        }
    }
}

