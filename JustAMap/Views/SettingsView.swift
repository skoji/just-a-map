import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("デフォルト設定") {
                    // ズームレベル
                    VStack(alignment: .leading, spacing: 8) {
                        Text("デフォルトズームレベル")
                            .font(.headline)
                        HStack {
                            Button {
                                if viewModel.defaultZoomIndex > 0 {
                                    viewModel.defaultZoomIndex -= 1
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(viewModel.defaultZoomIndex > 0 ? .blue : .gray)
                            }
                            .disabled(viewModel.defaultZoomIndex <= 0)
                            
                            Spacer()
                            
                            Text(viewModel.zoomLevelDisplayText)
                                .font(.title3)
                                .frame(minWidth: 100)
                            
                            Spacer()
                            
                            Button {
                                if viewModel.defaultZoomIndex < 11 {
                                    viewModel.defaultZoomIndex += 1
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(viewModel.defaultZoomIndex < 11 ? .blue : .gray)
                            }
                            .disabled(viewModel.defaultZoomIndex >= 11)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // 地図の種類
                    Picker("地図の種類", selection: $viewModel.defaultMapStyle) {
                        ForEach([MapStyle.standard, .hybrid, .imagery], id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    
                    // 地図の向き
                    Toggle("デフォルトでNorth Up", isOn: $viewModel.defaultIsNorthUp)
                }
                
                Section("表示設定") {
                    // 住所表示フォーマット
                    VStack(alignment: .leading, spacing: 8) {
                        Text("住所表示フォーマット")
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
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
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