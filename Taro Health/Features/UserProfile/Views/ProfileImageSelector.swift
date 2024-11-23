import SwiftUI
import PhotosUI

struct ProfileImageSelector: View {
    @Binding var profileImage: UIImage?  // Changed to @Binding
    @State private var photoPickerItem: PhotosPickerItem?
    
    var body: some View {
        VStack {
            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    )
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }
            
            PhotosPicker(selection: $photoPickerItem,
                        matching: .images) {
                HStack {
                    Image(systemName: "camera")
                    Text(profileImage == nil ? "Add Photo" : "Change Photo")
                }
                .foregroundColor(.primaryBlack)
            }
            .onChange(of: photoPickerItem) { newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            profileImage = uiImage
                        }
                    }
                }
            }
            
            if profileImage != nil {
                Button(role: .destructive) {
                    withAnimation {
                        profileImage = nil
                    }
                } label: {
                    Text("Remove Photo")
                        .foregroundColor(.red)
                }
            }
        }
    }
}

#Preview {
    // For preview purposes only
    struct PreviewWrapper: View {
        @State var previewImage: UIImage?
        
        var body: some View {
            ProfileImageSelector(profileImage: $previewImage)
        }
    }
    
    return PreviewWrapper()
}
