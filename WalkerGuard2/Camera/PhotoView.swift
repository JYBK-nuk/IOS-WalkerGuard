//  NQ Detect
//
//  Created by NULL on 10/9/22.
//

import SwiftUI
import Photos

struct PhotoView: View {
    @Binding  var image: Image?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Group {
            if let image = image {
                VStack{
                    image
                        .resizable()
                        .scaledToFit()
                    
                    Text("已儲存到相簿")
                        .font(.title2)
                    
                    Button(action:{dismiss()} , label: {
                        Image(systemName: "arrow.backward")
                    }).padding(25)
                        .background(Color.pink)
                        .cornerRadius(20).frame(width: 350)
                        .foregroundColor(.white)
                }
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .navigationTitle("Photo")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
}
