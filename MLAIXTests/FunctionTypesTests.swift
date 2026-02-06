//
//  FunctionTypesTests.swift
//  MLAITests
//
//  Tests for FunctionCallResult, FunctionParameter, FunctionCallRecord,
//  FunctionCategory, OpenAIFunction, and related types.
//

import Foundation
import Testing

@testable import MLAIX

// MARK: - WebSearchError Tests

struct WebSearchErrorTests {

    @Test func testWebSearchErrorDescriptions() {
        #expect(WebFunctions.WebSearchError.notConfigured.errorDescription?.contains("configured") == true)
        #expect(WebFunctions.WebSearchError.invalidDateFormat.errorDescription?.contains("date") == true)
        #expect(WebFunctions.WebSearchError.encodingFailed.errorDescription?.contains("encode") == true)
    }
}

// MARK: - FunctionCallResult Tests

struct FunctionCallResultTests {

    @Test func testSuccessFactory() {
        let result = FunctionCallResult.success(call: "search(q: \"test\")", result: "found it")
        #expect(result.call == "search(q: \"test\")")
        #expect(result.result == "found it")
        #expect(result.type == .result)
    }

    @Test func testFailureFactory() {
        let result = FunctionCallResult.failure(call: "search(q: \"test\")", error: "not found")
        #expect(result.call == "search(q: \"test\")")
        #expect(result.result == "not found")
        #expect(result.type == .error)
    }

    @Test func testSuccessWithNilResult() {
        let result = FunctionCallResult.success(call: "doSomething()", result: nil)
        #expect(result.result == nil)
        #expect(result.type == .result)
    }

    @Test func testDescriptionForSuccess() {
        let result = FunctionCallResult.success(call: "add(1,2)", result: "3")
        let desc = result.description
        #expect(desc.contains("tool_call_result"))
        #expect(desc.contains("add(1,2)"))
        #expect(desc.contains("3"))
    }

    @Test func testDescriptionForError() {
        let result = FunctionCallResult.failure(call: "divide(1,0)", error: "division by zero")
        let desc = result.description
        #expect(desc.contains("tool_call_error"))
        #expect(desc.contains("divide(1,0)"))
        #expect(desc.contains("division by zero"))
    }

    @Test func testDescriptionWithNilResultShowsNull() {
        let result = FunctionCallResult(call: "noop()", result: nil, type: .result)
        #expect(result.description.contains("null"))
    }

    @Test func testResultTypeAllCases() {
        let allCases = FunctionCallResult.ResultType.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.result))
        #expect(allCases.contains(.error))
    }

    @Test func testCodableRoundtrip() throws {
        let original = FunctionCallResult.success(call: "test()", result: "ok")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FunctionCallResult.self, from: data)
        #expect(decoded.call == original.call)
        #expect(decoded.result == original.result)
        #expect(decoded.type == original.type)
    }

    @Test func testHashable() {
        let a = FunctionCallResult(call: "f()", result: "1", type: .result)
        let b = FunctionCallResult(call: "f()", result: "1", type: .result)
        // Same properties -> same hash
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test func testInequalityByType() {
        let a = FunctionCallResult(call: "f()", result: "x", type: .result)
        let b = FunctionCallResult(call: "f()", result: "x", type: .error)
        #expect(a != b)
    }
}

// MARK: - FunctionParameter Tests

struct FunctionParameterTests {

    @Test func testBasicInit() {
        let param = FunctionParameter(
            label: "query",
            description: "Search query",
            datatype: .string
        )
        #expect(param.label == "query")
        #expect(param.description == "Search query")
        #expect(param.datatype == .string)
        #expect(param.isRequired == true) // default
    }

    @Test func testOptionalParameter() {
        let param = FunctionParameter(
            label: "limit",
            description: "Max results",
            datatype: .integer,
            isRequired: false
        )
        #expect(param.isRequired == false)
    }

    @Test func testDatatypeIsArrayForScalars() {
        #expect(FunctionParameter.Datatype.string.isArray == false)
        #expect(FunctionParameter.Datatype.integer.isArray == false)
        #expect(FunctionParameter.Datatype.float.isArray == false)
        #expect(FunctionParameter.Datatype.boolean.isArray == false)
    }

    @Test func testDatatypeIsArrayForArrayTypes() {
        #expect(FunctionParameter.Datatype.stringArray.isArray == true)
        #expect(FunctionParameter.Datatype.integerArray.isArray == true)
        #expect(FunctionParameter.Datatype.floatArray.isArray == true)
    }

    @Test func testCodableRoundtrip() throws {
        let param = FunctionParameter(
            label: "tags",
            description: "List of tags",
            datatype: .stringArray,
            isRequired: false
        )
        let data = try JSONEncoder().encode(param)
        let decoded = try JSONDecoder().decode(FunctionParameter.self, from: data)
        #expect(decoded.label == param.label)
        #expect(decoded.datatype == param.datatype)
        #expect(decoded.isRequired == param.isRequired)
    }
}

// MARK: - PropertyDetail Type Mapping Tests

struct PropertyDetailTypeMappingTests {

    // PropertyDetail.Type init maps FunctionParameter.Datatype -> OpenAI type names.
    // We test via PropertyDetail init and check the resulting .type field.

    @Test func testStringMapsToStringType() {
        let param = FunctionParameter(label: "a", description: "d", datatype: .string)
        let detail = PropertyDetail(functionParameter: param)
        #expect(detail.type == .string)
    }

    @Test func testIntegerMapsToNumberType() {
        let param = FunctionParameter(label: "a", description: "d", datatype: .integer)
        let detail = PropertyDetail(functionParameter: param)
        #expect(detail.type == .number)
    }

    @Test func testFloatMapsToNumberType() {
        let param = FunctionParameter(label: "a", description: "d", datatype: .float)
        let detail = PropertyDetail(functionParameter: param)
        #expect(detail.type == .number)
    }

    @Test func testBooleanMapsToBooleanType() {
        let param = FunctionParameter(label: "a", description: "d", datatype: .boolean)
        let detail = PropertyDetail(functionParameter: param)
        #expect(detail.type == .boolean)
    }

    @Test func testStringArrayMapsToArrayType() {
        let param = FunctionParameter(label: "a", description: "d", datatype: .stringArray)
        let detail = PropertyDetail(functionParameter: param)
        #expect(detail.type == .array)
    }

    @Test func testIntegerArrayMapsToArrayType() {
        let param = FunctionParameter(label: "a", description: "d", datatype: .integerArray)
        let detail = PropertyDetail(functionParameter: param)
        #expect(detail.type == .array)
    }

    @Test func testFloatArrayMapsToArrayType() {
        let param = FunctionParameter(label: "a", description: "d", datatype: .floatArray)
        let detail = PropertyDetail(functionParameter: param)
        #expect(detail.type == .array)
    }
}

// MARK: - PropertyDetail Init Tests

struct PropertyDetailInitTests {

    @Test func testScalarParameterHasNoItems() {
        let param = FunctionParameter(
            label: "name", description: "A name", datatype: .string
        )
        let detail = PropertyDetail(functionParameter: param)
        #expect(detail.items == nil)
        #expect(detail.type == .string)
        #expect(detail.description == "A name")
    }

    @Test func testStringArrayParameterHasStringItems() {
        let param = FunctionParameter(
            label: "tags", description: "Tags", datatype: .stringArray
        )
        let detail = PropertyDetail(functionParameter: param)
        #expect(detail.items != nil)
        #expect(detail.items?.type == .string)
        #expect(detail.type == .array)
    }

    @Test func testIntegerArrayParameterHasNumberItems() {
        let param = FunctionParameter(
            label: "ids", description: "IDs", datatype: .integerArray
        )
        let detail = PropertyDetail(functionParameter: param)
        #expect(detail.items != nil)
        #expect(detail.items?.type == .number)
    }

    @Test func testFloatArrayParameterHasNumberItems() {
        let param = FunctionParameter(
            label: "scores", description: "Scores", datatype: .floatArray
        )
        let detail = PropertyDetail(functionParameter: param)
        #expect(detail.items != nil)
        #expect(detail.items?.type == .number)
    }

    @Test func testBooleanParameterHasNoItems() {
        let param = FunctionParameter(
            label: "flag", description: "A flag", datatype: .boolean
        )
        let detail = PropertyDetail(functionParameter: param)
        #expect(detail.items == nil)
        #expect(detail.type == .boolean)
    }
}

// MARK: - FunctionCategory Tests

struct FunctionCategoryTests {

    @Test func testAllCasesCount() {
        #expect(FunctionCategory.allCases.count == 11)
    }

    @Test func testIdEqualsRawValue() {
        for category in FunctionCategory.allCases {
            #expect(category.id == category.rawValue)
        }
    }

    @Test func testDescriptionIsNonEmpty() {
        for category in FunctionCategory.allCases {
            #expect(!category.description.isEmpty)
        }
    }

    @Test func testCodableRoundtrip() throws {
        let original = FunctionCategory.web
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FunctionCategory.self, from: data)
        #expect(decoded == original)
    }

    @Test func testRawValues() {
        #expect(FunctionCategory.arithmetic.rawValue == "Arithmetic")
        #expect(FunctionCategory.web.rawValue == "Web")
        #expect(FunctionCategory.code.rawValue == "Code")
    }
}

// MARK: - OpenAIFunction Codable Tests

struct OpenAIFunctionCodableTests {

    @Test func testCodableRoundtrip() throws {
        let func1 = OpenAIFunction(
            type: "function",
            function: FunctionDetail(
                name: "search",
                description: "Search the web",
                parameters: ParameterSchema(
                    type: "object",
                    properties: [
                        "query": PropertyDetail(
                            functionParameter: FunctionParameter(
                                label: "query",
                                description: "The search query",
                                datatype: .string
                            )
                        )
                    ],
                    required: ["query"],
                    additionalProperties: false
                ),
                strict: false
            )
        )
        let data = try JSONEncoder().encode(func1)
        let decoded = try JSONDecoder().decode(OpenAIFunction.self, from: data)
        #expect(decoded.type == "function")
        #expect(decoded.function.name == "search")
        #expect(decoded.function.description == "Search the web")
        #expect(decoded.function.strict == false)
        #expect(decoded.function.parameters.required == ["query"])
    }
}

// MARK: - ParameterParsingError Tests

struct ParameterParsingErrorTests {

    @Test func testErrorCasesExist() {
        let invalidArray = ParameterParsingError.invalidArrayFormat("bad")
        let incompatible = ParameterParsingError.incompatibleType("wrong")
        let invalidValue = ParameterParsingError.invalidValue("oops")

        // Verify they can be pattern-matched
        if case .invalidArrayFormat(let msg) = invalidArray {
            #expect(msg == "bad")
        }
        if case .incompatibleType(let msg) = incompatible {
            #expect(msg == "wrong")
        }
        if case .invalidValue(let msg) = invalidValue {
            #expect(msg == "oops")
        }
    }
}
