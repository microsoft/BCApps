// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

codeunit 149046 "AIT Test Suite"
{
    var
        TestSuiteAlreadyExistsErr: Label 'Test suite with %1 %2 already exists.', Comment = '%1 - field caption, %2 - field value';
        TestSuiteNotFoundErr: Label 'Test suite with %1 %2 does not exist.', Comment = '%1 - field caption, %2 - field value';
        TestSuiteLineNotFoundErr: Label 'Test suite line with %1 %2 and %3 %4 does not exist.', Comment = '%1 - field caption, %2 - field value, %3 - field caption, %4 - field value';
    // DatasetNotFoundErr: Label 'Dataset %1 does not exist.', Comment = '%1 - field value';

    // TODO: DO we need this at all? Maybe for tests.
    // procedure CreateTestSuiteHeader(SuiteCode: Code[10]; SuiteDescription: Text[250]; Dataset: Text[100];
    //                           DefaultMinUserDelayInMs: Integer; DefaultMaxUserDelayInMs: Integer;
    //                           Tag: Text[20])
    // var
    //     AITHeader: Record "AIT Header";
    //     AITDataset: Record "AIT Dataset";
    // begin
    //     if AITHeader.Get(SuiteCode) then
    //         Error(this.TestSuiteAlreadyExistsErr, AITHeader.FieldCaption(Code), SuiteCode);

    //     Clear(AITHeader);
    //     AITHeader.Code := SuiteCode;
    //     AITHeader.Description := SuiteDescription;

    //     if AITDataset.Get(Dataset) then
    //         AITHeader."Input Dataset" := Dataset; //TODO: Should not finding a dataset error?

    //     if DefaultMinUserDelayInMs <> 0 then
    //         AITHeader."Default Min. User Delay (ms)" := DefaultMinUserDelayInMs;

    //     if DefaultMaxUserDelayInMs <> 0 then
    //         AITHeader."Default Max. User Delay (ms)" := DefaultMaxUserDelayInMs;

    //     AITHeader.Tag := Tag;
    //     AITHeader.Insert(true);
    // end;

    procedure CreateTestSuiteHeader(SuiteCode: Code[10]; SuiteDescription: Text[250])
    var
        AITHeader: Record "AIT Header";
    begin
        if AITHeader.Get(SuiteCode) then
            Error(this.TestSuiteAlreadyExistsErr, AITHeader.FieldCaption(Code), SuiteCode);

        Clear(AITHeader);
        AITHeader.Code := SuiteCode;
        AITHeader.Description := SuiteDescription;
        AITHeader.Insert(true);
    end;

    // procedure CreateUpdateTestSuiteHeader(SuiteCode: Code[10]; SuiteDescription: Text[250]; Dataset: Text[100];
    //                           DefaultMinUserDelayInMs: Integer; DefaultMaxUserDelayInMs: Integer;
    //                           Tag: Text[20])
    // var
    //     AITHeader: Record "AIT Header";
    //     AITDataset: Record "AIT Dataset";
    //     SuiteExists: Boolean;
    // begin
    //     if AITHeader.Get(SuiteCode) then
    //         SuiteExists := true;

    //     if not SuiteExists then begin
    //         Clear(AITHeader);
    //         AITHeader.Code := SuiteCode;
    //     end;

    //     if AITDataset.Get(Dataset) then
    //         AITheader."Input Dataset" := Dataset; //TODO: Should not finding a dataset error?

    //     AITHeader.Description := SuiteDescription;

    //     if DefaultMinUserDelayInMs <> 0 then
    //         AITHeader."Default Min. User Delay (ms)" := DefaultMinUserDelayInMs;

    //     if DefaultMaxUserDelayInMs <> 0 then
    //         AITHeader."Default Max. User Delay (ms)" := DefaultMaxUserDelayInMs;

    //     AITHeader.Tag := Tag;

    //     if SuiteExists then
    //         AITHeader.Modify(true)
    //     else
    //         AITHeader.Insert(true);
    // end;

    procedure TestSuiteExists(SuiteCode: Code[100]): Boolean
    var
        AITHeader: Record "AIT Header";
    begin
        exit(AITHeader.Get(SuiteCode));
    end;

    procedure TestSuiteLineExists(SuiteCode: Code[100]; CodeunitID: Integer): Boolean
    var
        AITLine: Record "AIT Line";
    begin
        this.SetAITLineCodeunitFilter(SuiteCode, CodeunitID, AITLine);
        exit(not AITLine.IsEmpty());
    end;

    procedure TestSuiteLineExists(SuiteCode: Code[100]; CodeunitID: Integer; var LineNo: Integer): Boolean
    var
        AITLine: Record "AIT Line";
    begin
        this.SetAITLineCodeunitFilter(SuiteCode, CodeunitID, AITLine);
        if not AITLine.FindFirst() then
            exit(false);
        LineNo := AITLine."Line No.";
        exit(true);
    end;

    procedure SetTestSuiteDefaultMinUserDelay(SuiteCode: Code[100]; DelayInMs: Integer)
    var
        AITHeader: Record "AIT Header";
    begin
        if not AITHeader.Get(SuiteCode) then
            Error(this.TestSuiteNotFoundErr, AITHeader.FieldCaption(Code), SuiteCode);

        AITHeader."Default Min. User Delay (ms)" := DelayInMs;
        AITHeader.Modify(true);
    end;

    procedure GetTestSuiteDefaultMinUserDelay(SuiteCode: Code[100]): Integer
    var
        AITHeader: Record "AIT Header";
    begin
        if not AITHeader.Get(SuiteCode) then
            Error(this.TestSuiteNotFoundErr, AITHeader.FieldCaption(Code), SuiteCode);

        exit(AITHeader."Default Min. User Delay (ms)");
    end;

    procedure SetTestSuiteDefaultMaxUserDelay(SuiteCode: Code[100]; DelayInMs: Integer)
    var
        AITHeader: Record "AIT Header";
    begin
        if not AITHeader.Get(SuiteCode) then
            Error(this.TestSuiteNotFoundErr, AITHeader.FieldCaption(Code), SuiteCode);

        AITHeader."Default Max. User Delay (ms)" := DelayInMs;
        AITHeader.Modify(true);
    end;

    procedure GetTestSuiteDefaultMaxUserDelay(SuiteCode: Code[100]): Integer
    var
        AITHeader: Record "AIT Header";
    begin
        if not AITHeader.Get(SuiteCode) then
            Error(this.TestSuiteNotFoundErr, AITHeader.FieldCaption(Code), SuiteCode);

        exit(AITHeader."Default Max. User Delay (ms)");
    end;

    // TODO: DO we need this at all? Maybe for tests.
    // procedure SetTestSuiteDataset(SuiteCode: Code[100]; Dataset: Text[100])
    // var
    //     AITHeader: Record "AIT Header";
    //     AITDataset: Record "AIT Dataset";
    // begin
    //     if not AITHeader.Get(SuiteCode) then
    //         Error(this.TestSuiteNotFoundErr, AITHeader.FieldCaption(Code), SuiteCode);

    //     if not AITDataset.Get(Dataset) then
    //         Error(this.DatasetNotFoundErr, Dataset);

    //     AITHeader."Input Dataset" := Dataset;
    //     AITHeader.Modify(true);
    // end;

    procedure GetTestSuiteDataset(SuiteCode: Code[100]): Text[100]
    var
        AITHeader: Record "AIT Header";
    begin
        if not AITHeader.Get(SuiteCode) then
            Error(this.TestSuiteNotFoundErr, AITHeader.FieldCaption(Code), SuiteCode);

        exit(AITHeader."Input Dataset");
    end;

    procedure SetTestSuiteTag(SuiteCode: Code[100]; Tag: Text[20])
    var
        AITHeader: Record "AIT Header";
    begin
        if not AITHeader.Get(SuiteCode) then
            Error(this.TestSuiteNotFoundErr, AITHeader.FieldCaption(Code), SuiteCode);

        AITHeader.Tag := Tag;
        AITHeader.Modify(true);
    end;

    procedure GetTestSuiteTag(SuiteCode: Code[100]): Text[20]
    var
        AITHeader: Record "AIT Header";
    begin
        if not AITHeader.Get(SuiteCode) then
            Error(this.TestSuiteNotFoundErr, AITHeader.FieldCaption(Code), SuiteCode);

        exit(AITHeader.Tag);
    end;

    procedure AddLineToTestSuiteHeader(SuiteCode: Code[100]; CodeunitId: Integer): Integer
    var
        AITHeader: Record "AIT Header";
        AITLine: Record "AIT Line";
        LastAITLine: Record "AIT Line";

    begin
        if not AITHeader.Get(SuiteCode) then
            Error(this.TestSuiteNotFoundErr, AITHeader.FieldCaption(Code), SuiteCode);

        LastAITLine.SetRange("AIT Code", SuiteCode);
        if LastAITLine.FindLast() then;
        Clear(AITLine);
        AITLine."AIT Code" := SuiteCode;
        AITLine."Line No." := LastAITLine."Line No." + 1000;
        AITLine.validate("Codeunit ID", CodeunitId);
        AITLine.Insert(true);

        exit(AITLine."Line No.");
    end;

    procedure AddLineToTestSuiteHeader(SuiteCode: Code[100]; CodeunitId: Integer; Description: Text[250];
                               MinUserDelayInMs: Integer; MaxUserDelayInMs: Integer; DelayBtwnIterInMs: Integer): Integer
    var
        AITHeader: Record "AIT Header";
        AITLine: Record "AIT Line";
        LastAITLine: Record "AIT Line";
    begin
        if not AITHeader.Get(SuiteCode) then
            Error(this.TestSuiteNotFoundErr, AITHeader.FieldCaption(Code), SuiteCode);


        LastAITLine.SetRange("AIT Code", SuiteCode);
        if LastAITLine.FindLast() then;
        Clear(AITLine);
        AITLine."AIT Code" := SuiteCode;
        AITLine."Line No." := LastAITLine."Line No." + 1000;
        AITLine."Codeunit ID" := CodeunitId;

        AITLine.Description := Description;

        if MinUserDelayInMs <> 0 then
            AITLine."Min. User Delay (ms)" := MinUserDelayInMs
        else
            AITLine."Min. User Delay (ms)" := AITHeader."Default Min. User Delay (ms)";

        if MaxUserDelayInMs <> 0 then
            AITLine."Max. User Delay (ms)" := MaxUserDelayInMs
        else
            AITLine."Max. User Delay (ms)" := AITHeader."Default Max. User Delay (ms)";

        if DelayBtwnIterInMs <> 0 then
            AITLine."Delay (ms btwn. iter.)" := DelayBtwnIterInMs;

        AITLine.Insert(true);

        exit(AITLine."Line No.");
    end;

    procedure SetTestSuiteLineDescription(SuiteCode: Code[100]; LineNo: Integer; Description: Text[250])
    var
        AITLine: Record "AIT Line";
    begin
        if not AITLine.Get(SuiteCode, LineNo) then
            Error(this.TestSuiteLineNotFoundErr, AITLine.FieldCaption("AIT Code"), SuiteCode, AITLine.FieldCaption("Line No."), LineNo);

        AITLine.Description := Description;
        AITLine.Modify(true);
    end;

    procedure SetTestSuiteLineMinUserDelay(SuiteCode: Code[100]; LineNo: Integer; DelayInMs: Integer)
    var
        AITLine: Record "AIT Line";
    begin
        if not AITLine.Get(SuiteCode, LineNo) then
            Error(this.TestSuiteLineNotFoundErr, AITLine.FieldCaption("AIT Code"), SuiteCode, AITLine.FieldCaption("Line No."), LineNo);

        AITLine."Min. User Delay (ms)" := DelayInMs;
        AITLine.Modify(true);
    end;

    procedure SetTestSuiteLineMaxUserDelay(SuiteCode: Code[100]; LineNo: Integer; DelayInMs: Integer)
    var
        AITLine: Record "AIT Line";
    begin
        if not AITLine.Get(SuiteCode, LineNo) then
            Error(this.TestSuiteLineNotFoundErr, AITLine.FieldCaption("AIT Code"), SuiteCode, AITLine.FieldCaption("Line No."), LineNo);

        AITLine."Max. User Delay (ms)" := DelayInMs;
        AITLine.Modify(true);
    end;

    procedure SetTestSuiteLineDelayBtwnIter(SuiteCode: Code[100]; LineNo: Integer; DelayInSecs: Integer)
    var
        AITLine: Record "AIT Line";
    begin
        if not AITLine.Get(SuiteCode, LineNo) then
            Error(this.TestSuiteLineNotFoundErr, AITLine.FieldCaption("AIT Code"), SuiteCode, AITLine.FieldCaption("Line No."), LineNo);

        AITLine."Delay (ms btwn. iter.)" := DelayInSecs;
        AITLine.Modify(true);
    end;

    procedure IsAnyTestRunInProgress(): Boolean
    var
        AITHeader2: Record "AIT Header";
    begin
        AITHeader2.SetRange(Status, AITHeader2.Status::Running);
        exit(not AITHeader2.IsEmpty());
    end;

    procedure IsTestRunInProgress(SuiteCode: Code[100]): Boolean
    var
        AITHeader2: Record "AIT Header";
    begin
        AITHeader2.SetRange(Code, SuiteCode);
        AITHeader2.SetRange(Status, AITHeader2.Status::Running);
        exit(not AITHeader2.IsEmpty());
    end;

    local procedure SetAITLineCodeunitFilter(SuiteCode: Code[100]; CodeunitID: Integer; var AITLine: Record "AIT Line")
    begin
        AITLine.SetRange("AIT Code", SuiteCode);
        AITLine.SetRange("Codeunit ID", CodeunitID);
    end;

    /// <summary>
    /// This event is raised before a log entry is added to the AIT Line table.
    /// It can be used to skip errors which are not relevant for the test suite. Like unused handler functions.
    /// </summary>
    /// <param name="SuiteCode">The test suite code</param>
    /// <param name="CodeunitId">The id of the test codunit that is being run</param>
    /// <param name="Description">Description of the test on the "AIT Line"</param>
    /// <param name="Orig. Operation">Original operation that is currently executed</param>
    /// <param name="Orig. ExecutionSuccess">The original ExecutionSuccess</param>
    /// <param name="Orig. Message">The original message</param>
    /// <param name="Operation">Replacement operation that is currently executed</param>
    /// <param name="ExecutionSuccess">Replacement ExecutionSuccess</param>
    /// <param name="Message">Replacement Message</param>
    [IntegrationEvent(false, false)]
    procedure OnBeforeAITLineAddLogEntry(SuiteCode: Code[100]; CodeunitId: Integer; Description: Text[250]; "Orig. Operation": Text; "Orig. ExecutionSuccess": Boolean; "Orig. Message": Text; var Operation: Text; var ExecutionSuccess: Boolean; var Message: Text)
    begin
    end;
}