// LoginView.swift
import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Welcome to Taro Health")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button {
                viewModel.signInWithGoogle()
            } label: {
                HStack {
                    Image(systemName: "globe")
                    Text("Sign in with Google")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Button {
                viewModel.skipSignIn()
            } label: {
                Text("Skip for now")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
        .fullScreenCover(isPresented: .init(
            get: { viewModel.skipToProfile },
            set: { _ in }
        )) {
            MultiStepUserProfileView { _ in
                // Handle profile completion
                viewModel.skipToProfile = false
            }
        }
    }
}
