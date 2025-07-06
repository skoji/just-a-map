import XCTest
import MapKit
@testable import JustAMap

@MainActor
final class MapControlsViewModelTests: XCTestCase {
    var sut: MapControlsViewModel!
    
    override func setUp() {
        super.setUp()
        sut = MapControlsViewModel()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Zoom Tests
    
    func testZoomIn() {
        // Given
        let initialSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        
        // When
        let newSpan = sut.calculateZoomIn(from: initialSpan)
        
        // Then
        XCTAssertLessThan(newSpan.latitudeDelta, initialSpan.latitudeDelta)
        XCTAssertLessThan(newSpan.longitudeDelta, initialSpan.longitudeDelta)
        XCTAssertEqual(newSpan.latitudeDelta, initialSpan.latitudeDelta * 0.5, accuracy: 0.0001)
    }
    
    func testZoomOut() {
        // Given
        let initialSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        
        // When
        let newSpan = sut.calculateZoomOut(from: initialSpan)
        
        // Then
        XCTAssertGreaterThan(newSpan.latitudeDelta, initialSpan.latitudeDelta)
        XCTAssertGreaterThan(newSpan.longitudeDelta, initialSpan.longitudeDelta)
        XCTAssertEqual(newSpan.latitudeDelta, initialSpan.latitudeDelta * 2.0, accuracy: 0.0001)
    }
    
    func testZoomInLimit() {
        // Given - 最小ズーム値に近い値
        let initialSpan = MKCoordinateSpan(latitudeDelta: 0.0001, longitudeDelta: 0.0001)
        
        // When
        let newSpan = sut.calculateZoomIn(from: initialSpan)
        
        // Then - それ以上ズームインしない
        XCTAssertEqual(newSpan.latitudeDelta, sut.minimumZoomSpan.latitudeDelta, accuracy: 0.00001)
    }
    
    func testZoomOutLimit() {
        // Given - 最大ズーム値に近い値
        let initialSpan = MKCoordinateSpan(latitudeDelta: 100.0, longitudeDelta: 100.0)
        
        // When
        let newSpan = sut.calculateZoomOut(from: initialSpan)
        
        // Then - それ以上ズームアウトしない
        XCTAssertEqual(newSpan.latitudeDelta, sut.maximumZoomSpan.latitudeDelta, accuracy: 0.1)
    }
    
    func testZoomLevelCalculation() {
        // Given
        let span1 = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let span2 = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        
        // When
        let level1 = sut.calculateZoomLevel(from: span1)
        let level2 = sut.calculateZoomLevel(from: span2)
        
        // Then
        XCTAssertGreaterThan(level1, level2) // より小さいspanはより高いズームレベル
        XCTAssertGreaterThan(level1, 0)
        XCTAssertLessThanOrEqual(level1, 20)
    }
    
    func testConsistentZoomSteps() {
        // Given - 異なる開始点からのズーム（ピンチ操作後を想定）
        let span1 = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let span2 = MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008) // ピンチで少し変更された値
        
        // When - 両方からズームインする
        let newSpan1 = sut.calculateZoomIn(from: span1)
        let newSpan2 = sut.calculateZoomIn(from: span2)
        
        // Then - 結果が大きく異ならないこと
        let ratio = newSpan1.latitudeDelta / newSpan2.latitudeDelta
        XCTAssertGreaterThan(ratio, 0.8) // 20%以上の差がないこと
        XCTAssertLessThan(ratio, 1.25)
    }
    
    func testZoomInOutReversibility() {
        // Given
        let initialSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        
        // When - ズームイン後にズームアウト
        let zoomedIn = sut.calculateZoomIn(from: initialSpan)
        let zoomedOut = sut.calculateZoomOut(from: zoomedIn)
        
        // Then - 元の値に戻ること
        XCTAssertEqual(zoomedOut.latitudeDelta, initialSpan.latitudeDelta, accuracy: 0.0001)
        XCTAssertEqual(zoomedOut.longitudeDelta, initialSpan.longitudeDelta, accuracy: 0.0001)
    }
    
    func testMultipleZoomStepsConsistency() {
        // Given - ピンチ操作で微妙に変わった値
        let pinchModifiedSpan = MKCoordinateSpan(latitudeDelta: 0.0073, longitudeDelta: 0.0073)
        
        // When - 複数回ズーム操作
        let step1 = sut.calculateZoomIn(from: pinchModifiedSpan)
        let step2 = sut.calculateZoomOut(from: step1)
        let step3 = sut.calculateZoomIn(from: step2)
        
        // Then - 最初のズームインと3回目のズームインが同じ結果になること
        XCTAssertEqual(step1.latitudeDelta, step3.latitudeDelta, accuracy: 0.0001)
    }
    
    func testDiscreteZoomLevels() {
        // Given - 連続的な値（0.0073は0.005と0.01の間）
        let continuousSpan = MKCoordinateSpan(latitudeDelta: 0.0073, longitudeDelta: 0.0073)
        
        // When - ズームインする
        let zoomedIn = sut.calculateZoomIn(from: continuousSpan)
        
        // Then - 次の小さいレベル（0.005）にスナップされるべき
        XCTAssertEqual(zoomedIn.latitudeDelta, 0.005, accuracy: 0.0001,
                      "0.0073からのズームインは0.005になるべき")
        
        // When - ズームアウトする
        let zoomedOut = sut.calculateZoomOut(from: continuousSpan)
        
        // Then - 次の大きいレベル（0.01）にスナップされるべき
        XCTAssertEqual(zoomedOut.latitudeDelta, 0.01, accuracy: 0.0001,
                      "0.0073からのズームアウトは0.01になるべき")
    }
    
    func testPredefinedZoomLevels() {
        // Given - 予め定義されたズームレベル
        let zoomLevels = [0.0005, 0.001, 0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0, 180.0]
        
        // When/Then - 各レベルからのズームが次の適切なレベルに移動すること
        for i in 1..<zoomLevels.count - 1 {
            let currentSpan = MKCoordinateSpan(latitudeDelta: zoomLevels[i], longitudeDelta: zoomLevels[i])
            let zoomedIn = sut.calculateZoomIn(from: currentSpan)
            let zoomedOut = sut.calculateZoomOut(from: currentSpan)
            
            // ズームインは前のレベルへ
            XCTAssertEqual(zoomedIn.latitudeDelta, zoomLevels[i-1], accuracy: 0.0001,
                          "レベル\(zoomLevels[i])からのズームインは\(zoomLevels[i-1])になるべき")
            
            // ズームアウトは次のレベルへ
            XCTAssertEqual(zoomedOut.latitudeDelta, zoomLevels[i+1], accuracy: 0.0001,
                          "レベル\(zoomLevels[i])からのズームアウトは\(zoomLevels[i+1])になるべき")
        }
    }
    
    func testZoomButtonsIgnoreSimilarValues() {
        // Given - ボタンを押した後の値（0.005）に非常に近い値
        let almostSameSpan = MKCoordinateSpan(latitudeDelta: 0.00501, longitudeDelta: 0.00501)
        
        // When - ズームインしようとする
        let newSpan = sut.calculateZoomIn(from: almostSameSpan)
        
        // Then - 同じレベルに留まるべき（次のレベルには行かない）
        XCTAssertEqual(newSpan.latitudeDelta, 0.002, accuracy: 0.0001,
                      "0.00501からのズームインは0.002になるべき（0.005には留まらない）")
    }
    
    func testZoomStability() {
        // Given - アニメーション中の微小な変化
        let spans = [0.005, 0.00502, 0.00498, 0.00501, 0.005]
        
        // When - 連続してズーム計算
        var results: [Double] = []
        for span in spans {
            let s = MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
            let zoomedIn = sut.calculateZoomIn(from: s)
            results.append(zoomedIn.latitudeDelta)
        }
        
        // Then - すべて同じ結果になるべき
        let uniqueResults = Set(results)
        XCTAssertEqual(uniqueResults.count, 1, "微小な変化では同じズームレベルを維持すべき")
    }
    
    func testZoomInFromIntermediateValues() {
        // Given - 1.0より大きい中間値
        let testCases: [(input: Double, expected: Double)] = [
            (1.7231532046885647, 0.5),  // 1.0より大きい値から0.5へ
            (1.7237187676566208, 0.5),
            (1.0, 0.5),                  // 1.0から0.5へ
            (0.8614408496052519, 0.5),  // 1.0より小さい値から0.5へ
        ]
        
        // When/Then
        for testCase in testCases {
            let span = MKCoordinateSpan(latitudeDelta: testCase.input, longitudeDelta: testCase.input)
            let result = sut.calculateZoomIn(from: span)
            print("Input: \(testCase.input), Expected: \(testCase.expected), Got: \(result.latitudeDelta)")
            XCTAssertEqual(result.latitudeDelta, testCase.expected, accuracy: 0.0001,
                          "\(testCase.input)からのズームインは\(testCase.expected)になるべき、実際は\(result.latitudeDelta)")
        }
    }
    
    func testZoomShouldHandleMapKitConvertedValues() {
        // Given - MapKitが変換した値（実際のログから）
        let mapKitValues: [(actual: Double, shouldBeFrom: Double)] = [
            (0.01723765370820729, 0.01),     // 0.01に設定したがMapKitが報告する値
            (0.03447514724412315, 0.02),     // 0.02に設定したがMapKitが報告する値
            (0.08618684050986758, 0.05),     // 0.05に設定したがMapKitが報告する値
            (0.17237128803817825, 0.1),      // 0.1に設定したがMapKitが報告する値
            (0.34472916623524696, 0.2),      // 0.2に設定したがMapKitが報告する値
            (0.8618068330600863, 0.5),       // 0.5に設定したがMapKitが報告する値
            (1.722302264434937, 1.0),        // 1.0に設定したがMapKitが報告する値
        ]
        
        // When/Then - ズームインは前のレベルに戻るべき
        for (i, value) in mapKitValues.enumerated() where i > 0 {
            let span = MKCoordinateSpan(latitudeDelta: value.actual, longitudeDelta: value.actual)
            let result = sut.calculateZoomIn(from: span)
            let expectedLevel = mapKitValues[i-1].shouldBeFrom
            
            XCTAssertEqual(result.latitudeDelta, expectedLevel, accuracy: 0.0001,
                          "MapKit値\(value.actual)（本来\(value.shouldBeFrom)）からのズームインは\(expectedLevel)になるべき")
        }
    }
    
    func testZoomShouldMaintainTargetLevel() {
        // Given - 目標レベルに設定後、MapKitが異なる値を報告
        let targetLevel = 0.02
        let mapKitReportedValue = 0.03447514724412315
        
        // When - MapKitの値からズームインを試みる
        let span = MKCoordinateSpan(latitudeDelta: mapKitReportedValue, longitudeDelta: mapKitReportedValue)
        let zoomInResult = sut.calculateZoomIn(from: span)
        
        // Then - 元の目標レベル（0.02）より小さい値（0.01）になるべき
        XCTAssertEqual(zoomInResult.latitudeDelta, 0.01, accuracy: 0.0001,
                      "0.02に設定後のMapKit値からズームインすると0.01になるべき")
        
        // When - ズームアウトを試みる
        let zoomOutResult = sut.calculateZoomOut(from: span)
        
        // Then - 次のレベル（0.05）になるべき
        XCTAssertEqual(zoomOutResult.latitudeDelta, 0.05, accuracy: 0.0001,
                      "0.02に設定後のMapKit値からズームアウトすると0.05になるべき")
    }
    
    // MARK: - Map Style Tests
    
    func testDefaultMapStyle() {
        // Then
        XCTAssertEqual(sut.currentMapStyle, .standard)
    }
    
    func testMapStyleToggle() {
        // Given
        let initialStyle = sut.currentMapStyle
        
        // When
        sut.toggleMapStyle()
        
        // Then
        XCTAssertNotEqual(sut.currentMapStyle, initialStyle)
        XCTAssertEqual(sut.currentMapStyle, .hybrid)
    }
    
    func testMapStyleCycle() {
        // Given
        let styles: [MapStyle] = [.standard, .hybrid, .imagery]
        
        // When & Then
        for expectedStyle in styles {
            XCTAssertEqual(sut.currentMapStyle, expectedStyle)
            sut.toggleMapStyle()
        }
        
        // 一周して元に戻る
        XCTAssertEqual(sut.currentMapStyle, .standard)
    }
    
    func testMapStyleProperties() {
        // Given & When & Then
        XCTAssertEqual(MapStyle.standard.rawValue, "標準")
        XCTAssertEqual(MapStyle.hybrid.rawValue, "航空写真+地図")
        XCTAssertEqual(MapStyle.imagery.rawValue, "航空写真")
    }
    
    // MARK: - Map Orientation Tests
    
    func testDefaultMapOrientation() {
        // Then
        XCTAssertTrue(sut.isNorthUp)
        XCTAssertFalse(sut.isHeadingUp)
    }
    
    func testToggleMapOrientation() {
        // Given
        let initialNorthUp = sut.isNorthUp
        
        // When
        sut.toggleMapOrientation()
        
        // Then
        XCTAssertEqual(sut.isNorthUp, !initialNorthUp)
        XCTAssertEqual(sut.isHeadingUp, initialNorthUp)
    }
    
    func testMapOrientationToggleBackAndForth() {
        // When & Then
        sut.toggleMapOrientation()
        XCTAssertFalse(sut.isNorthUp)
        XCTAssertTrue(sut.isHeadingUp)
        
        sut.toggleMapOrientation()
        XCTAssertTrue(sut.isNorthUp)
        XCTAssertFalse(sut.isHeadingUp)
    }
    
    func testCalculateHeadingRotation() {
        // Given
        let heading1: Double = 90  // 東向き
        let heading2: Double = 180 // 南向き
        let heading3: Double = 270 // 西向き
        let heading4: Double = 0   // 北向き
        
        // When & Then
        XCTAssertEqual(sut.calculateHeadingRotation(heading1), -90, accuracy: 0.1)
        XCTAssertEqual(sut.calculateHeadingRotation(heading2), -180, accuracy: 0.1)
        XCTAssertEqual(sut.calculateHeadingRotation(heading3), -270, accuracy: 0.1)
        XCTAssertEqual(sut.calculateHeadingRotation(heading4), 0, accuracy: 0.1)
    }
}