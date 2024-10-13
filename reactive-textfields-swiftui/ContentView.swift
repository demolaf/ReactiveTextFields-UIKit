//
//  ContentView.swift
//  reactive-textfields-swiftui
//
//  Created by Ademola Fadumo on 10/10/2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section {
                        TextField("Email", text: .constant(""))
                        ZStack(alignment: .trailing) {
                            SecureField("Password", text: .constant(""))
                                .padding(.trailing, 48)
                            Image(systemName: "eye")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                Button {
                    
                } label: {
                    Text("Log In")
                        .foregroundStyle(.white)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Login")
        }
    }
}

#Preview {
    ContentView()
}
