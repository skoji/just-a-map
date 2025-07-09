import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("settings.default_settings".localized) {
                    // ズームレベル
                    VStack(alignment: .leading, spacing: 8) {
                        Text("settings.default_zoom_level".localized)
                            .font(.headline)
                        HStack {
                            Button {
                                viewModel.defaultZoomIndex -= 1
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(viewModel.defaultZoomIndex > SettingsViewModel.minZoomIndex ? .blue : .gray)
                            }
                            .disabled(viewModel.defaultZoomIndex <= SettingsViewModel.minZoomIndex)
                            .buttonStyle(.borderless)
                            
                            Spacer()
                            
                            Text(viewModel.zoomLevelDisplayText)
                                .font(.title3)
                                .frame(minWidth: 100)
                            
                            Spacer()
                            
                            Button {
                                viewModel.defaultZoomIndex += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(viewModel.defaultZoomIndex < SettingsViewModel.maxZoomIndex ? .blue : .gray)
                            }
                            .disabled(viewModel.defaultZoomIndex >= SettingsViewModel.maxZoomIndex)
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // 地図の種類
                    Picker("settings.map_type".localized, selection: $viewModel.defaultMapStyle) {
                        ForEach(MapStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    
                    // 地図の向き
                    Toggle("settings.default_north_up".localized, isOn: $viewModel.defaultIsNorthUp)
                }
                
                Section("settings.display_settings".localized) {
                    // 住所表示フォーマット
                    VStack(alignment: .leading, spacing: 8) {
                        Text("settings.address_format".localized)
                            .font(.headline)
                        
                        ForEach(AddressFormat.allCases, id: \.self) { format in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(format.displayName)
                                        .font(.body)
                                    Text(format.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if viewModel.addressFormat == format {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.addressFormat = format
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section("settings.app_info".localized) {
                    HStack {
                        Text("settings.app_version".localized)
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("settings.build_number".localized)
                        Spacer()
                        Text(viewModel.buildNumber)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("settings.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("settings.close".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}