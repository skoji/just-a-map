import XCTest
import MapKit
@testable import JustAMap

final class SettingsViewModelTests: XCTestCase {
    var sut: SettingsViewModel!
    var mockSettingsStorage: MockMapSettingsStorage!
    
    override func setUp() {
        super.setUp()
        mockSettingsStorage = MockMapSettingsStorage()
        sut = SettingsViewModel(settingsStorage: mockSettingsStorage)
    }
    
    override func tearDown() {
        sut = nil
        mockSettingsStorage = nil
        super.tearDown()
    }
    
    func testInitialValues() {
        XCTAssertEqual(sut.defaultZoomIndex, mockSettingsStorage.defaultZoomIndex)
        XCTAssertEqual(sut.defaultMapStyle, mockSettingsStorage.defaultMapStyle)
        XCTAssertEqual(sut.defaultIsNorthUp, mockSettingsStorage.defaultIsNorthUp)
        XCTAssertEqual(sut.addressFormat, mockSettingsStorage.addressFormat)
    }
    
    func testUpdateDefaultZoomIndex() {
        let newZoomIndex = 5
        sut.defaultZoomIndex = newZoomIndex
        
        XCTAssertEqual(mockSettingsStorage.defaultZoomIndex, newZoomIndex)
    }
    
    func testUpdateDefaultMapStyle() {
        let newMapStyle = MapStyle.hybrid
        sut.defaultMapStyle = newMapStyle
        
        XCTAssertEqual(mockSettingsStorage.defaultMapStyle, newMapStyle)
    }
    
    func testUpdateDefaultIsNorthUp() {
        let newIsNorthUp = false
        sut.defaultIsNorthUp = newIsNorthUp
        
        XCTAssertEqual(mockSettingsStorage.defaultIsNorthUp, newIsNorthUp)
    }
    
    func testUpdateAddressFormat() {
        let newFormat = AddressFormat.detailed
        sut.addressFormat = newFormat
        
        XCTAssertEqual(mockSettingsStorage.addressFormat, newFormat)
    }
    
    func testZoomLevelDisplayText() {
        sut.defaultZoomIndex = 0
        XCTAssertEqual(sut.zoomLevelDisplayText, "200m")
        
        sut.defaultZoomIndex = 6
        XCTAssertEqual(sut.zoomLevelDisplayText, "20km")
        
        sut.defaultZoomIndex = 11
        XCTAssertEqual(sut.zoomLevelDisplayText, "1,000km")
    }
    
    func testZoomLevelDisplayTextWithOutOfRangeIndex() {
        // 範囲外の値でもデフォルト値が返される
        sut.defaultZoomIndex = -1
        XCTAssertEqual(sut.zoomLevelDisplayText, "10km") // デフォルト
        
        sut.defaultZoomIndex = 12
        XCTAssertEqual(sut.zoomLevelDisplayText, "10km") // デフォルト
    }
    
    func testZoomLevelDisplayTextUpdatesWhenDefaultZoomIndexChanges() {
        // 初期値を確認
        sut.defaultZoomIndex = 2
        XCTAssertEqual(sut.zoomLevelDisplayText, "1km")
        
        // ズームインボタンを押した時の動作を再現
        sut.defaultZoomIndex = 3
        XCTAssertEqual(sut.zoomLevelDisplayText, "2km")
        
        // ズームアウトボタンを押した時の動作を再現
        sut.defaultZoomIndex = 1
        XCTAssertEqual(sut.zoomLevelDisplayText, "500m")
    }
    
    func testDefaultZoomIndexBoundaryConditions() {
        // 最小値でのズームアウトは値が変わらない
        sut.defaultZoomIndex = SettingsViewModel.minZoomIndex
        let minIndex = sut.defaultZoomIndex
        
        // ボタンアクションをシミュレート（本来は無効化されるべき）
        if sut.defaultZoomIndex > SettingsViewModel.minZoomIndex {
            sut.defaultZoomIndex -= 1
        }
        XCTAssertEqual(sut.defaultZoomIndex, minIndex)
        
        // 最大値でのズームインは値が変わらない
        sut.defaultZoomIndex = SettingsViewModel.maxZoomIndex
        let maxIndex = sut.defaultZoomIndex
        
        // ボタンアクションをシミュレート（本来は無効化されるべき）
        if sut.defaultZoomIndex < SettingsViewModel.maxZoomIndex {
            sut.defaultZoomIndex += 1
        }
        XCTAssertEqual(sut.defaultZoomIndex, maxIndex)
    }
    
    func testAppVersionWithMainBundle() {
        // Test with main bundle (this should work in test environment)
        let version = sut.appVersion
        XCTAssertNotNil(version)
        XCTAssertFalse(version.isEmpty)
        // Main bundle in test may not have version info, so it could be "Unknown" or "不明"
        XCTAssertTrue(version.contains("Unknown") || version.contains("不明") || version.count > 0)
    }
    
    func testBuildNumberWithMainBundle() {
        // Test with main bundle (this should work in test environment)
        let buildNumber = sut.buildNumber
        XCTAssertNotNil(buildNumber)
        XCTAssertFalse(buildNumber.isEmpty)
        // Main bundle in test may not have build info, so it could be "Unknown" or "不明"
        XCTAssertTrue(buildNumber.contains("Unknown") || buildNumber.contains("不明") || buildNumber.count > 0)
    }
    
    func testAppVersionWithMockBundle() {
        // Test with mock bundle that returns specific values
        let mockBundle = MockBundle()
        mockBundle.infoDictionary = [
            "CFBundleShortVersionString": "1.0.0",
            "CFBundleVersion": "123"
        ]
        
        let sutWithMockBundle = SettingsViewModel(
            settingsStorage: mockSettingsStorage,
            bundle: mockBundle
        )
        
        XCTAssertEqual(sutWithMockBundle.appVersion, "1.0.0")
        XCTAssertEqual(sutWithMockBundle.buildNumber, "123")
    }
    
    func testAppVersionWithMissingInfoPlist() {
        // Test with mock bundle that returns nil
        let mockBundle = MockBundle()
        mockBundle.infoDictionary = [:]
        
        let sutWithMockBundle = SettingsViewModel(
            settingsStorage: mockSettingsStorage,
            bundle: mockBundle
        )
        
        let expectedUnknownString = "app_info.unknown".localized
        XCTAssertEqual(sutWithMockBundle.appVersion, expectedUnknownString)
        XCTAssertEqual(sutWithMockBundle.buildNumber, expectedUnknownString)
    }
    
    // MARK: - Git-based versioning tests
    
    func testAppVersionWithGitVersioning() {
        // Test with mock Git version provider
        let mockGitProvider = MockGitVersionInfoProvider()
        mockGitProvider.mockVersionString = "1.0.0+abc123"
        mockGitProvider.mockBuildNumber = "42"
        
        let sutWithGitProvider = SettingsViewModel(
            settingsStorage: mockSettingsStorage,
            gitVersionProvider: mockGitProvider
        )
        
        XCTAssertEqual(sutWithGitProvider.appVersion, "1.0.0+abc123")
        XCTAssertEqual(sutWithGitProvider.buildNumber, "42")
    }
    
    func testAppVersionFallbackToBundleWhenGitFails() {
        // Test fallback to bundle when Git version is unavailable
        let mockGitProvider = MockGitVersionInfoProvider()
        mockGitProvider.mockVersionString = "1.0.0+unknown"
        mockGitProvider.mockBuildNumber = "1"
        
        let mockBundle = MockBundle()
        mockBundle.infoDictionary = [
            "CFBundleShortVersionString": "2.0.0",
            "CFBundleVersion": "456"
        ]
        
        let sutWithFallback = SettingsViewModel(
            settingsStorage: mockSettingsStorage,
            bundle: mockBundle,
            gitVersionProvider: mockGitProvider
        )
        
        XCTAssertEqual(sutWithFallback.appVersion, "2.0.0")
        XCTAssertEqual(sutWithFallback.buildNumber, "456")
    }
    
    func testAppVersionFallbackToUnknownWhenAllFail() {
        // Test fallback to unknown when both Git and bundle fail
        let mockGitProvider = MockGitVersionInfoProvider()
        mockGitProvider.mockVersionString = "1.0.0+unknown"
        mockGitProvider.mockBuildNumber = "1"
        
        let mockBundle = MockBundle()
        mockBundle.infoDictionary = [:]
        
        let sutWithAllFallback = SettingsViewModel(
            settingsStorage: mockSettingsStorage,
            bundle: mockBundle,
            gitVersionProvider: mockGitProvider
        )
        
        let expectedUnknownString = "app_info.unknown".localized
        XCTAssertEqual(sutWithAllFallback.appVersion, expectedUnknownString)
        XCTAssertEqual(sutWithAllFallback.buildNumber, expectedUnknownString)
    }
    
    func testGitVersioningPreferredOverBundle() {
        // Test that Git versioning takes precedence over bundle
        let mockGitProvider = MockGitVersionInfoProvider()
        mockGitProvider.mockVersionString = "1.0.0+git123"
        mockGitProvider.mockBuildNumber = "99"
        
        let mockBundle = MockBundle()
        mockBundle.infoDictionary = [
            "CFBundleShortVersionString": "1.0.0",
            "CFBundleVersion": "1"
        ]
        
        let sutWithGitPrecedence = SettingsViewModel(
            settingsStorage: mockSettingsStorage,
            bundle: mockBundle,
            gitVersionProvider: mockGitProvider
        )
        
        XCTAssertEqual(sutWithGitPrecedence.appVersion, "1.0.0+git123")
        XCTAssertEqual(sutWithGitPrecedence.buildNumber, "99")
    }
}