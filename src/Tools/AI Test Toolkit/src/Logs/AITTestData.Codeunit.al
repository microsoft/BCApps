// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.TestTools.TestRunner;

codeunit 149035 "AIT Test Data"
{
    Access = Internal;

    var
        TurnsLbl: Label '<b>%1:</b> %2 <br>', Comment = '%1 = The turn number as an integer, %2 = The data from that turn', Locked = true;

    procedure UpdateTestInput(TestInput: Text; TestInputView: Enum "AIT Test Input - View"): Text
    var
        TestData: Codeunit "Test Input Json";
    begin
        InitTestData(TestInput, TestData);

        case TestInputView of
            TestInputView::"Full Input":
                exit(TestInput);
            TestInputView::Question:
                exit(FilterToElement('question', TestData));
            TestInputView::Context:
                exit(FilterToElement('context', TestData));
            TestInputView::"Test Setup":
                exit(FilterToElement('test_setup', TestData));
            TestInputView::"Ground Truth":
                exit(FilterToElement('ground_truth', TestData));
            TestInputView::"Expected Data":
                exit(FilterToElement('expected_data', TestData));
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
                exit(FilterToElement('answer', TestData));
            TestOutputView::Question:
                exit(FilterToElement('question', TestData));
            TestOutputView::Context:
                exit(FilterToElement('context', TestData));
            TestOutputView::"Ground Truth":
                exit(FilterToElement('ground_truth', TestData));
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

    local procedure FilterToElement(ElementName: Text; TestData: Codeunit "Test Input Json"): Text
    var
        TurnsDataJson: Codeunit "Test Input Json";
        ElementJson: Codeunit "Test Input Json";
        TextBuilder: TextBuilder;
        IsMultiTurn: Boolean;
        NumberOfTurns: Integer;
        I: Integer;
    begin
        TurnsDataJson := TestData.ElementExists('turns', IsMultiTurn);

        if not IsMultiTurn then
            exit(GetTestDataElement(ElementName, TestData));

        NumberOfTurns := TurnsDataJson.GetElementCount();
        for I := 0 to NumberOfTurns - 1 do begin
            ElementJson := TurnsDataJson.ElementAt(I);
            TextBuilder.AppendLine(StrSubstNo(TurnsLbl, I, GetTestDataElement(ElementName, ElementJson)));
        end;

        exit(TextBuilder.ToText());
    end;

    local procedure GetTestDataElement(ElementName: Text; var TestData: Codeunit "Test Input Json"): Text
    var
        ElementJson: Codeunit "Test Input Json";
        ElementExists: Boolean;
    begin
        ElementJson := TestData.ElementExists(ElementName, ElementExists);

        if ElementExists and (ElementJson.ToText() <> '{}') then
            exit(ElementJson.ToText())
        else
            exit('');
    end;
}