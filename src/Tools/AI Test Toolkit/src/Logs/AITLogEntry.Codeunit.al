// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.TestTools.TestRunner;

codeunit 149032 "AIT Log Entry"
{
    Access = Internal;

    var
        LineNoFilterLbl: Label 'Codeunit %1 "%2" (Input: %3)', Locked = true;

    procedure DrillDownFailedAITLogEntries(AITSuiteCode: Code[100]; LineNo: Integer; VersionNo: Integer)
    var
        AITLogEntries: Record "AIT Log Entry";
    begin
        AITLogEntries.SetRange(Version, VersionNo);
        DrillDownFailedAITLogEntries(AITLogEntries, AITSuiteCode, LineNo);
    end;

    procedure DrillDownFailedAITLogEntries(AITSuiteCode: Code[100]; LineNo: Integer; Tag: Text[20])
    var
        AITLogEntries: Record "AIT Log Entry";
    begin
        AITLogEntries.SetRange(Tag, Tag);
        DrillDownFailedAITLogEntries(AITLogEntries, AITSuiteCode, LineNo);
    end;

    local procedure DrillDownFailedAITLogEntries(var AITLogEntries: Record "AIT Log Entry"; AITSuiteCode: Code[100]; LineNo: Integer)
    var
        AITLogEntry: Page "AIT Log Entries";
    begin
        AITLogEntries.SetFilterForFailedTestProcedures();
        AITLogEntries.SetRange("Test Suite Code", AITSuiteCode);
        if LineNo <> 0 then
            AITLogEntries.SetRange("Test Method Line No.", LineNo);
        AITLogEntry.SetTableView(AITLogEntries);
        AITLogEntry.Run();
    end;

    procedure GetRunHistory(Code: Code[100]; LineNo: Integer; AITViewBy: Enum "AIT Run History - View By"; var TempAITRunHistory: Record "AIT Run History" temporary)
    var
        AITRunHistory: Record "AIT Run History";
        SeenTags: List of [Text[20]];
    begin
        TempAITRunHistory.DeleteAll();
        AITRunHistory.SetRange("Test Suite Code", Code);

        if AITViewBy = AITViewBy::Version then
            if AITRunHistory.FindSet() then
                repeat
                    TempAITRunHistory.TransferFields(AITRunHistory);
                    TempAITRunHistory.Insert();
                until AITRunHistory.Next() = 0;

        if AITViewBy = AITViewBy::Tag then
            if AITRunHistory.FindSet() then
                repeat
                    if not SeenTags.Contains(AITRunHistory.Tag) then begin
                        TempAITRunHistory.TransferFields(AITRunHistory);
                        TempAITRunHistory.Insert();
                    end;
                    SeenTags.Add(AITRunHistory.Tag);
                until AITRunHistory.Next() = 0;

        if (LineNo <> 0) then
            TempAITRunHistory.SetRange("Line No. Filter", LineNo)
    end;

    procedure LookupTestMethodLine(TestSuiteCode: Code[100]; var LineNoFilter: Text; var LineNo: Integer)
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        AITTestMethodLines: Page "AIT Test Method Lines Lookup";
    begin
        AITTestMethodLine.SetRange("Test Suite Code", TestSuiteCode);

        AITTestMethodLines.SetTableView(AITTestMethodLine);
        AITTestMethodLines.LookupMode(true);

        if AITTestMethodLines.RunModal() <> Action::LookupOK then
            exit;

        AITTestMethodLines.GetRecord(AITTestMethodLine);

        AITTestMethodLine.CalcFields("Codeunit Name");
        LineNoFilter := StrSubstNo(LineNoFilterLbl, AITTestMethodLine."Codeunit ID", AITTestMethodLine."Codeunit Name", AITTestMethodLine."Input Dataset");
        LineNo := AITTestMethodLine."Line No.";
    end;

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