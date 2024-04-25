// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

codeunit 149046 "BCCT Test Suite"
{
    var
        TestSuiteAlreadyExistsErr: Label 'Test suite with %1 %2 already exists.', Comment = '%1 - field caption, %2 - field value';
        TestSuiteNotFoundErr: Label 'Test suite with %1 %2 does not exist.', Comment = '%1 - field caption, %2 - field value';
        TestSuiteLineNotFoundErr: Label 'Test suite line with %1 %2 and %3 %4 does not exist.', Comment = '%1 - field caption, %2 - field value, %3 - field caption, %4 - field value';

    procedure CreateTestSuiteHeader(SuiteCode: Code[10]; SuiteDescription: Text[50]; DurationInMinutes: Integer;
                              DefaultMinUserDelayInMs: Integer; DefaultMaxUserDelayInMs: Integer;
                              OneDayCorrespondsToMinutes: Integer; Tag: Text[20])
    var
        BCCTHeader: Record "BCCT Header";
    begin
        if BCCTHeader.Get(SuiteCode) then
            Error(TestSuiteAlreadyExistsErr, BCCTHeader.FieldCaption(Code), SuiteCode);

        Clear(BCCTHeader);
        BCCTHeader.Code := SuiteCode;
        BCCTHeader.Description := SuiteDescription;

        // if DurationInMinutes <> 0 then
        //     BCCTHeader."Duration (minutes)" := DurationInMinutes;

        // if DefaultMinUserDelayInMs <> 0 then
        //     BCCTHeader."Default Min. User Delay (ms)" := DefaultMinUserDelayInMs;

        // if DefaultMaxUserDelayInMs <> 0 then
        //     BCCTHeader."Default Max. User Delay (ms)" := DefaultMaxUserDelayInMs;

        // if OneDayCorrespondsToMinutes <> 0 then
        //     BCCTHeader."1 Day Corresponds to (minutes)" := OneDayCorrespondsToMinutes;

        BCCTHeader.Tag := Tag;
        BCCTHeader.Insert(true);
    end;

    procedure CreateTestSuiteHeader(SuiteCode: Code[10]; SuiteDescription: Text[50])
    var
        BCCTHeader: Record "BCCT Header";
    begin
        if BCCTHeader.Get(SuiteCode) then
            Error(TestSuiteAlreadyExistsErr, BCCTHeader.FieldCaption(Code), SuiteCode);

        Clear(BCCTHeader);
        BCCTHeader.Code := SuiteCode;
        BCCTHeader.Description := SuiteDescription;
        BCCTHeader.Insert(true);
    end;

    procedure CreateUpdateTestSuiteHeader(SuiteCode: Code[10]; SuiteDescription: Text[50]; DurationInMinutes: Integer;
                              DefaultMinUserDelayInMs: Integer; DefaultMaxUserDelayInMs: Integer;
                              OneDayCorrespondsToMinutes: Integer; Tag: Text[20])
    var
        BCCTHeader: Record "BCCT Header";
        SuiteExists: Boolean;
    begin
        if BCCTHeader.Get(SuiteCode) then
            SuiteExists := true;

        if not SuiteExists then begin
            Clear(BCCTHeader);
            BCCTHeader.Code := SuiteCode;
        end;

        BCCTHeader.Description := SuiteDescription;

        // if DurationInMinutes <> 0 then
        //     BCCTHeader."Duration (minutes)" := DurationInMinutes;

        // if DefaultMinUserDelayInMs <> 0 then
        //     BCCTHeader."Default Min. User Delay (ms)" := DefaultMinUserDelayInMs;

        // if DefaultMaxUserDelayInMs <> 0 then
        //     BCCTHeader."Default Max. User Delay (ms)" := DefaultMaxUserDelayInMs;

        // if OneDayCorrespondsToMinutes <> 0 then
        //     BCCTHeader."1 Day Corresponds to (minutes)" := OneDayCorrespondsToMinutes;

        BCCTHeader.Tag := Tag;

        if SuiteExists then
            BCCTHeader.Modify(true)
        else
            BCCTHeader.Insert(true);
    end;

    procedure TestSuiteExists(SuiteCode: Code[10]): Boolean
    var
        BCCTHeader: Record "BCCT Header";
    begin
        exit(BCCTHeader.Get(SuiteCode));
    end;

    procedure TestSuiteLineExists(SuiteCode: Code[10]; CodeunitID: Integer): Boolean
    var
        BCCTLine: Record "BCCT Line";
    begin
        SetBCCTLineCodeunitFilter(SuiteCode, CodeunitID, BCCTLine);
        exit(not BCCTLine.IsEmpty());
    end;

    procedure TestSuiteLineExists(SuiteCode: Code[10]; CodeunitID: Integer; var LineNo: Integer): Boolean
    var
        BCCTLine: Record "BCCT Line";
    begin
        SetBCCTLineCodeunitFilter(SuiteCode, CodeunitID, BCCTLine);
        if not BCCTLine.FindFirst() then
            exit(false);
        LineNo := BCCTLine."Line No.";
        exit(true);
    end;

    procedure TestSuiteLineExists(SuiteCode: Code[10]; CodeunitID: Integer; ParameterFilterStr: Text; var LineNo: Integer): Boolean
    var
        BCCTLine: Record "BCCT Line";
    begin
        SetBCCTLineCodeunitFilter(SuiteCode, CodeunitID, BCCTLine);
        BCCTLine.SetFilter(Parameters, ParameterFilterStr);
        if not BCCTLine.FindFirst() then
            exit(false);
        LineNo := BCCTLine."Line No.";
        exit(true);
    end;

    // procedure SetTestSuiteDuration(SuiteCode: Code[10]; DurationInMinutes: Integer)
    // var
    //     BCCTHeader: Record "BCCT Header";
    // begin
    //     if not BCCTHeader.Get(SuiteCode) then
    //         Error(TestSuiteNotFoundErr, BCCTHeader.FieldCaption(Code), SuiteCode);

    //     //BCCTHeader."Duration (minutes)" := DurationInMinutes;
    //     BCCTHeader.Modify(true);
    // end;

    // procedure GetTestSuiteDuration(SuiteCode: Code[10]): Integer
    // var
    //     BCCTHeader: Record "BCCT Header";
    // begin
    //     if not BCCTHeader.Get(SuiteCode) then
    //         Error(TestSuiteNotFoundErr, BCCTHeader.FieldCaption(Code), SuiteCode);

    //     exit(BCCTHeader."Duration (minutes)");
    // end;

    // procedure SetTestSuiteDefaultMinUserDelay(SuiteCode: Code[10]; DelayInMs: Integer)
    // var
    //     BCCTHeader: Record "BCCT Header";
    // begin
    //     if not BCCTHeader.Get(SuiteCode) then
    //         Error(TestSuiteNotFoundErr, BCCTHeader.FieldCaption(Code), SuiteCode);

    //     BCCTHeader."Default Min. User Delay (ms)" := DelayInMs;
    //     BCCTHeader.Modify(true);
    // end;

    // procedure GetTestSuiteDefaultMinUserDelay(SuiteCode: Code[10]): Integer
    // var
    //     BCCTHeader: Record "BCCT Header";
    // begin
    //     if not BCCTHeader.Get(SuiteCode) then
    //         Error(TestSuiteNotFoundErr, BCCTHeader.FieldCaption(Code), SuiteCode);

    //     exit(BCCTHeader."Default Min. User Delay (ms)");
    // end;

    // procedure SetTestSuiteDefaultMaxUserDelay(SuiteCode: Code[10]; DelayInMs: Integer)
    // var
    //     BCCTHeader: Record "BCCT Header";
    // begin
    //     if not BCCTHeader.Get(SuiteCode) then
    //         Error(TestSuiteNotFoundErr, BCCTHeader.FieldCaption(Code), SuiteCode);

    //     BCCTHeader."Default Max. User Delay (ms)" := DelayInMs;
    //     BCCTHeader.Modify(true);
    // end;

    // procedure GetTestSuiteDefaultMaxUserDelay(SuiteCode: Code[10]): Integer
    // var
    //     BCCTHeader: Record "BCCT Header";
    // begin
    //     if not BCCTHeader.Get(SuiteCode) then
    //         Error(TestSuiteNotFoundErr, BCCTHeader.FieldCaption(Code), SuiteCode);

    //     exit(BCCTHeader."Default Max. User Delay (ms)");
    // end;

    // procedure SetTestSuite1DayCorresponds(SuiteCode: Code[10]; DurationInMinutes: Integer)
    // var
    //     BCCTHeader: Record "BCCT Header";
    // begin
    //     if not BCCTHeader.Get(SuiteCode) then
    //         Error(TestSuiteNotFoundErr, BCCTHeader.FieldCaption(Code), SuiteCode);

    //     BCCTHeader."1 Day Corresponds to (minutes)" := DurationInMinutes;
    //     BCCTHeader.Modify(true);
    // end;

    // procedure GetTestSuite1DayCorresponds(SuiteCode: Code[10]): Integer
    // var
    //     BCCTHeader: Record "BCCT Header";
    // begin
    //     if not BCCTHeader.Get(SuiteCode) then
    //         Error(TestSuiteNotFoundErr, BCCTHeader.FieldCaption(Code), SuiteCode);

    //     exit(BCCTHeader."1 Day Corresponds to (minutes)");
    // end;

    procedure SetTestSuiteTag(SuiteCode: Code[10]; Tag: Text[20])
    var
        BCCTHeader: Record "BCCT Header";
    begin
        if not BCCTHeader.Get(SuiteCode) then
            Error(TestSuiteNotFoundErr, BCCTHeader.FieldCaption(Code), SuiteCode);

        BCCTHeader.Tag := Tag;
        BCCTHeader.Modify(true);
    end;

    procedure GetTestSuiteTag(SuiteCode: Code[10]): Text[20]
    var
        BCCTHeader: Record "BCCT Header";
    begin
        if not BCCTHeader.Get(SuiteCode) then
            Error(TestSuiteNotFoundErr, BCCTHeader.FieldCaption(Code), SuiteCode);

        exit(BCCTHeader.Tag);
    end;

    procedure AddLineToTestSuiteHeader(SuiteCode: Code[10]; CodeunitId: Integer): Integer
    var
        BCCTHeader: Record "BCCT Header";
        BCCTLine: Record "BCCT Line";
        LastBCCTLine: Record "BCCT Line";

    begin
        if not BCCTHeader.Get(SuiteCode) then
            Error(TestSuiteNotFoundErr, BCCTHeader.FieldCaption(Code), SuiteCode);

        LastBCCTLine.SetRange("BCCT Code", SuiteCode);
        if LastBCCTLine.FindLast() then;
        Clear(BCCTLine);
        BCCTLine."BCCT Code" := SuiteCode;
        BCCTLine."Line No." := LastBCCTLine."Line No." + 1000;
        BCCTLine.validate("Codeunit ID", CodeunitId);
        BCCTLine.Insert(true);

        exit(BCCTLine."Line No.");
    end;

    procedure AddLineToTestSuiteHeader(SuiteCode: Code[10]; CodeunitId: Integer; NoOfSessions: Integer; Description: Text[50];
                               MinUserDelayInMs: Integer; MaxUserDelayInMs: Integer; DelayBtwnIterInSecs: Integer; RunInForeground: Boolean;
                               Parameters: Text[1000]): Integer
    var
        BCCTHeader: Record "BCCT Header";
        BCCTLine: Record "BCCT Line";
        LastBCCTLine: Record "BCCT Line";
    begin
        if not BCCTHeader.Get(SuiteCode) then
            Error(TestSuiteNotFoundErr, BCCTHeader.FieldCaption(Code), SuiteCode);


        LastBCCTLine.SetRange("BCCT Code", SuiteCode);
        if LastBCCTLine.FindLast() then;
        Clear(BCCTLine);
        BCCTLine."BCCT Code" := SuiteCode;
        BCCTLine."Line No." := LastBCCTLine."Line No." + 1000;
        BCCTLine."Codeunit ID" := CodeunitId;

        // if NoOfSessions <> 0 then
        //     BCCTLine."No. of Sessions" := NoOfSessions;

        // BCCTLine.Description := Description;

        // if MinUserDelayInMs <> 0 then
        //     BCCTLine."Min. User Delay (ms)" := MinUserDelayInMs
        // else
        //     BCCTLine."Min. User Delay (ms)" := BCCTHeader."Default Min. User Delay (ms)";

        // if MaxUserDelayInMs <> 0 then
        //     BCCTLine."Max. User Delay (ms)" := MaxUserDelayInMs
        // else
        //     BCCTLine."Max. User Delay (ms)" := BCCTHeader."Default Max. User Delay (ms)";

        // if DelayBtwnIterInSecs <> 0 then
        //     BCCTLine."Delay (sec. btwn. iter.)" := DelayBtwnIterInSecs;

        BCCTLine."Run in Foreground" := RunInForeground;

        BCCTLine.Parameters := Parameters;

        // BCCTLine."Delay Type" := DelayType;

        BCCTLine.Insert(true);

        exit(BCCTLine."Line No.");
    end;

    // procedure SetTestSuiteLineNoOfSessions(SuiteCode: Code[10]; LineNo: Integer; NoOfSessions: Integer)
    // var
    //     BCCTLine: Record "BCCT Line";
    // begin
    //     if not BCCTLine.Get(SuiteCode, LineNo) then
    //         Error(TestSuiteLineNotFoundErr, BCCTLine.FieldCaption("BCCT Code"), SuiteCode, BCCTLine.FieldCaption("Line No."), LineNo);

    //     BCCTLine."No. of Sessions" := NoOfSessions;
    //     BCCTLine.Modify(true);
    // end;

    procedure SetTestSuiteLineDescription(SuiteCode: Code[10]; LineNo: Integer; Description: Text[50])
    var
        BCCTLine: Record "BCCT Line";
    begin
        if not BCCTLine.Get(SuiteCode, LineNo) then
            Error(TestSuiteLineNotFoundErr, BCCTLine.FieldCaption("BCCT Code"), SuiteCode, BCCTLine.FieldCaption("Line No."), LineNo);

        BCCTLine.Description := Description;
        BCCTLine.Modify(true);
    end;

    // procedure SetTestSuiteLineMinUserDelay(SuiteCode: Code[10]; LineNo: Integer; DelayInMs: Integer)
    // var
    //     BCCTLine: Record "BCCT Line";
    // begin
    //     if not BCCTLine.Get(SuiteCode, LineNo) then
    //         Error(TestSuiteLineNotFoundErr, BCCTLine.FieldCaption("BCCT Code"), SuiteCode, BCCTLine.FieldCaption("Line No."), LineNo);

    //     BCCTLine."Min. User Delay (ms)" := DelayInMs;
    //     BCCTLine.Modify(true);
    // end;

    // procedure SetTestSuiteLineMaxUserDelay(SuiteCode: Code[10]; LineNo: Integer; DelayInMs: Integer)
    // var
    //     BCCTLine: Record "BCCT Line";
    // begin
    //     if not BCCTLine.Get(SuiteCode, LineNo) then
    //         Error(TestSuiteLineNotFoundErr, BCCTLine.FieldCaption("BCCT Code"), SuiteCode, BCCTLine.FieldCaption("Line No."), LineNo);

    //     BCCTLine."Max. User Delay (ms)" := DelayInMs;
    //     BCCTLine.Modify(true);
    // end;

    procedure SetTestSuiteLineDelayBtwnIter(SuiteCode: Code[10]; LineNo: Integer; DelayInSecs: Integer)
    var
        BCCTLine: Record "BCCT Line";
    begin
        if not BCCTLine.Get(SuiteCode, LineNo) then
            Error(TestSuiteLineNotFoundErr, BCCTLine.FieldCaption("BCCT Code"), SuiteCode, BCCTLine.FieldCaption("Line No."), LineNo);

        BCCTLine."Delay (ms btwn. iter.)" := DelayInSecs;
        BCCTLine.Modify(true);
    end;

    procedure SetTestSuiteLineRunInForeground(SuiteCode: Code[10]; LineNo: Integer; RunInForeground: Boolean)
    var
        BCCTLine: Record "BCCT Line";
    begin
        if not BCCTLine.Get(SuiteCode, LineNo) then
            Error(TestSuiteLineNotFoundErr, BCCTLine.FieldCaption("BCCT Code"), SuiteCode, BCCTLine.FieldCaption("Line No."), LineNo);

        BCCTLine."Run in Foreground" := RunInForeground;
        BCCTLine.Modify(true);
    end;

    procedure SetTestSuiteLineParameters(SuiteCode: Code[10]; LineNo: Integer; Parameters: Text[1000])
    var
        BCCTLine: Record "BCCT Line";
    begin
        if not BCCTLine.Get(SuiteCode, LineNo) then
            Error(TestSuiteLineNotFoundErr, BCCTLine.FieldCaption("BCCT Code"), SuiteCode, BCCTLine.FieldCaption("Line No."), LineNo);

        BCCTLine.Parameters := Parameters;
        BCCTLine.Modify(true);
    end;

    procedure IsAnyTestRunInProgress(): Boolean
    var
        BCCTHeader2: Record "BCCT Header";
    begin
        BCCTHeader2.SetRange(Status, BCCTHeader2.Status::Running);
        exit(not BCCTHeader2.IsEmpty());
    end;

    procedure IsTestRunInProgress(SuiteCode: Code[10]): Boolean
    var
        BCCTHeader2: Record "BCCT Header";
    begin
        BCCTHeader2.SetRange(Code, SuiteCode);
        BCCTHeader2.SetRange(Status, BCCTHeader2.Status::Running);
        exit(not BCCTHeader2.IsEmpty());
    end;

    local procedure SetBCCTLineCodeunitFilter(SuiteCode: Code[10]; CodeunitID: Integer; var BCCTLine: Record "BCCT Line")
    begin
        BCCTLine.SetRange("BCCT Code", SuiteCode);
        BCCTLine.SetRange("Codeunit ID", CodeunitID);
    end;

    /// <summary>
    /// This event is raised before a log entry is added to the BCCT Line table.
    /// It can be used to skip errors which are not relevant for the test suite. Like unused handler functions.
    /// </summary>
    /// <param name="SuiteCode">The test suite code</param>
    /// <param name="CodeunitId">The id of the test codunit that is being run</param>
    /// <param name="Description">Description of the test on the "BCCT Line"</param>
    /// <param name="Orig. Operation">Original operation that is currently executed</param>
    /// <param name="Orig. ExecutionSuccess">The original ExecutionSuccess</param>
    /// <param name="Orig. Message">The original message</param>
    /// <param name="Operation">Replacement operation that is currently executed</param>
    /// <param name="ExecutionSuccess">Replacement ExcecutionSuccess</param>
    /// <param name="Message">Replacement Message</param>
    [IntegrationEvent(false, false)]
    procedure OnBeforeBCCTLineAddLogEntry(SuiteCode: Code[10]; CodeunitId: Integer; Description: Text; "Orig. Operation": Text; "Orig. ExecutionSuccess": Boolean; "Orig. Message": Text; var Operation: Text; var ExecutionSuccess: Boolean; var Message: Text)
    begin
    end;
}