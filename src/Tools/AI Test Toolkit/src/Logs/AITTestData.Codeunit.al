// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.TestTools.TestRunner;

codeunit 149035 "AIT Test Data"
{
    Access = Internal;

    procedure UpdateTestInput(TestInput: Text; TestInputView: Enum "AIT Test Input - View"): Text
    var
        TestData: Codeunit "Test Input Json";
    begin
        InitTestData(TestInput, TestData);

        case TestInputView of
            TestInputView::"Full Input":
                exit(TestInput);
            TestInputView::Question:
                exit(GetTestDataElement('question', TestData));
            TestInputView::Context:
                exit(GetTestDataElement('context', TestData));
            TestInputView::"Test Setup":
                exit(GetTestDataElement('test_setup', TestData));
            TestInputView::"Ground Truth":
                exit(GetTestDataElement('ground_truth', TestData));
            TestInputView::"Expected Data":
                exit(GetTestDataElement('expected_data', TestData));
            else
                exit('');
        end;
    end;

    procedure UpdateTestOutput(TestOutput: Text; TestOutputView: Enum "AIT Test Output - View"): Text
    var
        TestData: Codeunit "Test Input Json";
    begin
        InitTestData(TestOutput, TestData);

        case TestOutputView of
            TestOutputView::"Full Output":
                exit(TestOutput);
            TestOutputView::Answer:
                exit(GetTestDataElement('answer', TestData));
            TestOutputView::Question:
                exit(GetTestDataElement('question', TestData));
            TestOutputView::Context:
                exit(GetTestDataElement('context', TestData));
            TestOutputView::"Ground Truth":
                exit(GetTestDataElement('ground_truth', TestData));
            else
                exit('');
        end;
    end;

    local procedure InitTestData(TestDataText: Text; var TestData: Codeunit "Test Input Json")
    begin
        if TestDataText = '' then
            TestData.Initialize()
        else
            TestData.Initialize(TestDataText);
    end;

    local procedure GetTestDataElement(ElementName: Text; TestData: Codeunit "Test Input Json"): Text
    var
        ElementTestDataJson: Codeunit "Test Input Json";
        ElementExists: Boolean;
    begin
        ElementTestDataJson := TestData.ElementExists('turns', ElementExists);

        if ElementExists then
            TestData := ElementTestDataJson;

        ElementTestDataJson := TestData.ElementExists(ElementName, ElementExists);

        if ElementExists and (ElementTestDataJson.ToText() <> '{}') then
            exit(ElementTestDataJson.ToText())
        else
            exit('');
    end;
}