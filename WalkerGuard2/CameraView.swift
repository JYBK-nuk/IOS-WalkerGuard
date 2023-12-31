//  NQ Detect
//
//  Created by NULL on 10/9/22.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var model = DataModel()
    
    private static let barHeightFactor = 0.10
    
    @State private var isImageTaken = false
    
    @State private var speed = 50.0
    @State private var isEditing = false
    
    
    var body: some View {
        
        NavigationView {
            GeometryReader { geometry in
                ViewfinderView(image:  $model.viewfinderImage )
                    .overlay(alignment: .bottom) {
                        buttonsView()
                            .frame(height: geometry.size.height * (Self.barHeightFactor+0.1))
                            .background(.black.opacity(0.7))
                        
                        
                        
                    }
                    .overlay(alignment: .center)  {
                        Color.clear
                            .frame(height: geometry.size.height * (1 - (Self.barHeightFactor * 2)))
                            .accessibilityElement()
                            .accessibilityLabel("View Finder")
                            .accessibilityAddTraits([.isImage])
                    }
                    .background(.black)
            }
            .task {
                await model.camera.start()
            }
            .navigationTitle("Camera")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .ignoresSafeArea()
            .statusBar(hidden: true)
            .sheet(isPresented: self.$isImageTaken) {
                PhotoView(image: $model.thumbnailImage).onAppear(){
                    model.camera.isPreviewPaused = true
                }.onDisappear(){
                    model.camera.isPreviewPaused = false
                    model.thumbnailImage = nil
                    
                }
            }.onAppear(){
                UIApplication.shared.isIdleTimerDisabled = true
            }.onDisappear(){
                UIApplication.shared.isIdleTimerDisabled = false
            }
            
        }
    }
    
    private func buttonsView() -> some View {
        VStack(){
            HStack {
                Slider(value: $speed, in: 15...10000,onEditingChanged: {_ in
                    model.camera.setShutterSpeed_( shutterSpeed: (Int64(1),Int32(speed)))
                }) // 調整快門的滑條
                .accentColor(.pink)
            }.padding(20)
            HStack() {
                VStack{
                    HStack{
                        Text("快門速度")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                    }
                    HStack{
                        Text(String(format: "1/%d", Int(speed)))
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                    }
                }
                Button {
                    model.camera.takePhoto()
                    self.isImageTaken.toggle()
                } label: {
                    Label {
                        Text("Take Photo")
                    } icon: {
                        ZStack {
                            Circle()
                                .strokeBorder(.white, lineWidth: 3)
                                .frame(width: 62, height: 62)
                            Circle()
                                .fill(.white)
                                .frame(width: 50, height: 50)
                        }
                    }
                }
                Button {
                    model.camera.switchCaptureDevice()
                } label: {
                    Label("Switch Camera", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                
                
            }
            .buttonStyle(.plain)
            .labelStyle(.iconOnly)
            .padding()
            
        }
        
    }
    
}
