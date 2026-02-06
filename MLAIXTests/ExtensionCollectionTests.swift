//
//  ExtensionCollectionTests.swift
//  MLAIXTests
//
//  Tests for Extension+Collection (transpose) and Array+Double (standardDeviation, variance).
//

import Foundation
import Testing
@testable import MLAIX

struct ExtensionCollectionTransposeTests {

    @Test func testTransposeEmptyReturnsEmpty() {
        let empty: [[Int]] = []
        #expect(empty.transpose == [])
    }

    @Test func testTransposeSingleRow() {
        let input = [[1, 2, 3]]
        let result = input.transpose
        #expect(result == [[1], [2], [3]])
    }

    @Test func testTransposeSingleColumn() {
        let input = [[1], [2], [3]]
        let result = input.transpose
        #expect(result == [[1, 2, 3]])
    }

    @Test func testTransposeMatrix() {
        let input = [[1, 2], [3, 4], [5, 6]]
        let result = input.transpose
        #expect(result == [[1, 3, 5], [2, 4, 6]])
    }

    @Test func testTransposeSquareMatrix() {
        let input = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
        let result = input.transpose
        #expect(result == [[1, 4, 7], [2, 5, 8], [3, 6, 9]])
    }

    @Test func testTransposeWithStrings() {
        let input = [["a", "b"], ["c", "d"]]
        let result = input.transpose
        #expect(result == [["a", "c"], ["b", "d"]])
    }
}

struct ExtensionArrayDoubleTests {

    @Test func testStandardDeviationEmptyReturnsNil() {
        let empty: [Double] = []
        #expect(empty.standardDeviation() == nil)
    }

    @Test func testStandardDeviationSingleElementReturnsZero() {
        let result = [1.0].standardDeviation()
        #expect(result != nil)
        #expect(result! == 0.0)
    }

    @Test func testStandardDeviationConstantReturnsZero() {
        let result = [5.0, 5.0, 5.0].standardDeviation()
        #expect(result != nil)
        #expect(result! == 0.0)
    }

    @Test func testStandardDeviationNonConstant() {
        let values = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]
        let result = values.standardDeviation()
        #expect(result != nil)
        #expect(result! > 0)
    }

    @Test func testVarianceEmptyReturnsNil() {
        let empty: [Double] = []
        #expect(empty.variance() == nil)
    }

    @Test func testVarianceConstantReturnsZero() {
        let result = [3.0, 3.0, 3.0].variance()
        #expect(result != nil)
        #expect(result! == 0.0)
    }

    @Test func testVarianceNonConstant() {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        let result = values.variance()
        #expect(result != nil)
        #expect(result! == 2.0, "Variance of 1..5 is 2.0")
    }
}
