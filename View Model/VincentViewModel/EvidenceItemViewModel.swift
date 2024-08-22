//
//  EvidenceItemViewModel.swift
//  MiniChallenge3
//
//  Created by Vincent Saranang on 18/08/24.
//

import SwiftUI
import AVFoundation
import MapKit

class EvidenceItemViewModel: ObservableObject {
    @Published var isExpanded: Bool = false
    var id = UUID()
    var timestamp: String
    var streetName: String
    var streetDetail: String
    var recordingTime: String
    var audioPlayer: Player
    var recording: URL
    var notes: String
    
    init(timestamp: String ,streetName: String, streetDetail: String, recordingTime: String, audioPlayer: Player, recording: URL, notes: String) {
        self.timestamp = timestamp
        self.streetName = streetName
        self.streetDetail = streetDetail
        self.recordingTime = recordingTime
        self.audioPlayer = audioPlayer
        self.recording = recording
        self.notes = notes
    }
    
    func toggleExpand() {
        isExpanded = true
    }
}

class EvidenceListViewModel: ObservableObject {
    @Published var navigateToValidation = false
    @Published var navigateToPinValidation = false
    @Published var evidenceItems: [EvidenceItemViewModel] = []
    @Published var selectedDate: String = ""
    @Published var selectedStreetName: String = ""
    @Published var selectedStreetDetail: String = ""
    @Published var selectedRecordingTime: String = ""
    @Published var selectedIndex: Int = 0
    @Published var storeNotes: String = ""
    var storeNotesBinding: Binding<String> {
        Binding(
            get: { self.storeNotes },
            set: { self.storeNotes = $0 }
        )
    }
    
    @Published var LocationDetailVM = LoadLocationManager(
        region: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ),
        pins: [PinLocation(coordinate: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), timestamp: Date())],
        routeCoordinates: [(coordinate: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), timestamp: Date())],
        sliderValue: 0.5,
        showSlider: true,
        audioPlayer: nil, // Optional, can be nil or AVPlayer instance
        maxSliderValue: 10.0,
        lastGeocodedAddressName: "Some Street",
        lastGeocodedAddressDetail: "Near Some Place"
    )
    
    @Published var recordings: [URL] = []
    @Published var formattedDate: String = ""
    @Published var audioTime: String = ""
    @Published var audioPlayer: Player?
    
    func collapseAllExcept(selectedItem: EvidenceItemViewModel) {
        for item in evidenceItems {
            if item !== selectedItem {
                item.isExpanded = false
            }
        }
    }
    
    @ViewBuilder
    func getCurrentCaseView(for currentCase: Int, _ locationVM: LocationManager, _ iOSVM: iOSManager) -> some View {
        switch currentCase {
        case 1:
            VStack(spacing: 24) {
                ForEach(Array(evidenceItems.enumerated()), id: \.element.id) { index, item in
                    EvidenceItemView(viewModel: item, player: item.audioPlayer) { streetName, recordingTime in
                        self.collapseAllExcept(selectedItem: item)
                        self.selectedIndex = index
                        self.selectedDate = item.timestamp
                        self.selectedStreetName = streetName
                        self.selectedStreetDetail = item.streetDetail
                        self.selectedRecordingTime = recordingTime
                        self.storeNotes = item.notes
                        self.LocationDetailVM = LoadLocationManager(
                            region:
                                locationVM.storeLocation[index].region,
                            pins:
                                locationVM.storeLocation[index].pins,
                            routeCoordinates:
                                locationVM.storeLocation[index].routeCoordinates,
                            sliderValue:
                                locationVM.storeLocation[index].sliderValue,
                            showSlider:
                                locationVM.storeLocation[index].showSlider,
                            maxSliderValue:
                                locationVM.storeLocation[index].maxSliderValue,
                            lastGeocodedAddressName:
                                locationVM.storeLocation[index].streetName,
                            lastGeocodedAddressDetail:
                                locationVM.storeLocation[index].streetDetail
                        )
                        
                        
                    }
                }
                Spacer()
            }
            
            .onAppear {
                self.recordings = iOSVM.fetchRecordings()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                    self.evidenceItems = []
                    for (index, recording) in self.recordings.enumerated() {
                        if let lastCoordinate = locationVM.storeLocation[index].routeCoordinates.last {
                            let timestamp = lastCoordinate.timestamp
                            
                            // Create a DateFormatter to format the date
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateStyle = .long
                            dateFormatter.timeStyle = .none
                            
                            // Format the timestamp to a string
                            self.formattedDate = dateFormatter.string(from: timestamp)
                            
                        } else {
                            print("No coordinates available.")
                        }
                        
                        self.audioTime = self.formatDuration(recording)
                        self.audioPlayer = Player(avPlayer: AVPlayer(url: recording))
                        
                        let evidenceItem = EvidenceItemViewModel(
                            timestamp: self.formattedDate,
                            streetName: locationVM.loadLocManager.lastGeocodedAddressName,
                            streetDetail: locationVM.loadLocManager.lastGeocodedAddressDetail,
                            recordingTime: self.audioTime,
                            audioPlayer: self.audioPlayer!,
                            recording: recording,
                            notes: ""
                        )
                        
                        self.evidenceItems.append(evidenceItem)
                    }
                }
            }
            
        case 2:
            VStack(spacing: 24) {
                RoutePolyline(routeCoordinates: LocationDetailVM.routeUpToSliderValue(), startEndPins: LocationDetailVM.startEndPinLocations())
                    .foregroundColor(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(height: UIScreen.main.bounds.height * 2 / 5)
                    .shadow(radius: 2, y: 4)
                
                RoundedRectangle(cornerRadius: 10)
                    .frame(height: 73)
                    .foregroundColor(.containerColor2)
                    .shadow(radius: 2, y: 4)
                    .overlay {
                        HStack(spacing: 12) {
                            Circle()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.iconColor2)
                                .overlay {
                                    Image(.icon1)
                                }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(selectedStreetName)
                                    .foregroundColor(.fontColor4)
                                    .font(.lt(size: 16, weight: .semibold))
                                Text(selectedStreetDetail)
                                    .foregroundColor(.fontColor6)
                                    .font(.lt(size: 15))
                            }
                            Spacer()
                        }
                        .padding()
                    }
                Spacer()
            }
            .onAppear {
                self.LocationDetailVM = LoadLocationManager(
                    region:
                        locationVM.storeLocation[self.selectedIndex].region,
                    pins:
                        locationVM.storeLocation[self.selectedIndex].pins,
                    routeCoordinates:
                        locationVM.storeLocation[self.selectedIndex].routeCoordinates,
                    sliderValue:
                        locationVM.storeLocation[self.selectedIndex].sliderValue,
                    showSlider:
                        locationVM.storeLocation[self.selectedIndex].showSlider,
                    maxSliderValue:
                        locationVM.storeLocation[self.selectedIndex].maxSliderValue,
                    lastGeocodedAddressName:
                        locationVM.storeLocation[self.selectedIndex].streetName,
                    lastGeocodedAddressDetail:
                        locationVM.storeLocation[self.selectedIndex].streetDetail
                )
            }
            
        case 3:
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Evidence")
                        .foregroundColor(.fontColor4)
                        .font(.lt(size: 20, weight: .bold))
                    RoundedRectangle(cornerRadius: 10)
                        .frame(height: 73)
                        .foregroundColor(.containerColor2)
                        .shadow(radius: 2, y: 4)
                        .overlay {
                            VStack(alignment:.leading, spacing:4) {
                                Text(selectedDate)
                                    .foregroundColor(.fontColor4)
                                    .font(.lt(size: 16, weight: .semibold))
                                HStack {
                                    Text(selectedStreetName)
                                    Spacer()
                                    Text(selectedRecordingTime)
                                }
                                .foregroundColor(.fontColor5)
                                .font(.lt(size: 16))
                            }
                            .padding()
                        }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Location")
                        .foregroundColor(.fontColor4)
                        .font(.lt(size: 20, weight: .bold))
                    RoundedRectangle(cornerRadius: 10)
                        .frame(height: 73)
                        .foregroundColor(.containerColor2)
                        .shadow(radius: 2, y: 4)
                        .overlay {
                            HStack(spacing: 12) {
                                Circle()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.iconColor2)
                                    .overlay {
                                        Image(.icon1)
                                    }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(selectedStreetName)
                                        .foregroundColor(.fontColor4)
                                        .font(.lt(size: 16, weight: .semibold))
                                    Text(selectedStreetDetail)
                                        .foregroundColor(.fontColor6)
                                        .font(.lt(size: 15))
                                }
                                Spacer()
                            }
                            .padding()
                        }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Other details")
                        .foregroundColor(.fontColor4)
                        .font(.lt(size: 20, weight: .bold))
                    RoundedRectangle(cornerRadius: 10)
                        .frame(height: 73)
                        .foregroundColor(.containerColor2)
                        .shadow(radius: 2, y: 4)
                        .overlay {
                            TextField("Enter your notes here...", text: storeNotesBinding)
                                .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                                .disableAutocorrection(true)
                                .foregroundColor(.fontColor4)
                                .font(.lt(size: 16, weight: .semibold))
                                .onSubmit {
                                    self.evidenceItems[self.selectedIndex].notes = self.storeNotes
                                }
                        }
                }
                Spacer()
            }
            
        default:
            EmptyView()
        }
    }
    
    func getCaseButton(for currentCase: Int) -> String {
        switch currentCase {
        case 1:
            return "Select Evidence"
        case 2:
            return "Confirm Location"
        case 3:
            return "Submit"
        default:
            return ""
        }
    }
    
    func getCaseTitle(for currentCase: Int) -> String {
        switch currentCase {
        case 1:
            return "Select the voice evidence!"
        case 2:
            return "Where did it happen?"
        case 3:
            return "Are you sure?"
        default:
            return ""
        }
    }
    
    func formatDuration(_ recording: URL) -> String {
        let asset = AVURLAsset(url: recording)
        
        guard let assetReader = try? AVAssetReader(asset: asset) else {
            return ""
        }
        
        let duration = Double(assetReader.asset.duration.value)
        let timescale = Double(assetReader.asset.duration.timescale)
        let totalDuration = duration / timescale
        
        let minutes = Int(totalDuration) / 60
        let seconds = Int(totalDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
}
