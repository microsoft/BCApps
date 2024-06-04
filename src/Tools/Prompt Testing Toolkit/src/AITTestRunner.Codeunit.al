// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.TestTools.TestRunner;

codeunit 149042 "AIT Test Runner"
{
    TableNo = "BCCT Line";
    SingleInstance = true;
    Access = Internal;

    var
        GlobalBCCTLine: Record "BCCT Line";
        GlobalBCCTHeader: Record "BCCT Header";
        ActiveBCCTHeader: Record "BCCT Header";
        GlobalTestMethodLine: Record "Test Method Line";
        NoOfInsertedLogEntries: Integer;
        AccumulatedWaitTimeMs: Integer;

    trigger OnRun();
    begin
        if Rec."Codeunit ID" = 0 then
            exit;
        this.SetBCCTLine(Rec);

        this.NoOfInsertedLogEntries := 0;
        this.AccumulatedWaitTimeMs := 0;

        this.InitializeBCCTLineForRun(Rec, this.ActiveBCCTHeader);
        this.SetBCCTHeader(this.ActiveBCCTHeader);

        this.RunBCCTLine(Rec, this.ActiveBCCTHeader);
    end;

    local procedure InitializeBCCTLineForRun(var BCCTLine: Record "BCCT Line"; var BCCTHeader: Record "BCCT Header")
    begin
        BCCTHeader.Get(BCCTLine."BCCT Code");
        if BCCTHeader."Started at" < CurrentDateTime() then
            BCCTHeader."Started at" := CurrentDateTime();

        if BCCTLine."Input Dataset" = '' then
            BCCTLine."Input Dataset" := (BCCTHeader."Input Dataset");

        if BCCTLine."Delay (ms btwn. iter.)" < 1 then
            BCCTLine."Delay (ms btwn. iter.)" := BCCTHeader."Default Delay (ms)";
    end;

    local procedure RunBCCTLine(var BCCTLine: Record "BCCT Line"; var BCCTHeader: Record "BCCT Header")
    var
        BCCTHeaderCU: Codeunit "BCCT Header";
    begin
        this.GetAndClearAccumulatedWaitTimeMs();

        this.OnBeforeRunIteration(BCCTHeader, BCCTLine);
        this.RunIteration(BCCTLine);
        Commit();

        //TODO override delay from line / default delay
        Sleep(BCCTLine."Delay (ms btwn. iter.)");

        BCCTHeaderCU.DecreaseNoOfTestsRunningNow(BCCTHeader);
    end;

    local procedure RunIteration(var BCCTLine: Record "BCCT Line")
    var
        TestMethodLine: Record "Test Method Line";
        AITTALTestSuiteMgt: Codeunit "AITT AL Test Suite Mgt";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
    begin
        BCCTLine.Find();
        AITTALTestSuiteMgt.UpdateALTestSuite(BCCTLine);
        this.SetBCCTLine(BCCTLine);

        TestMethodLine.SetRange("Test Codeunit", BCCTLine."Codeunit ID");
        TestMethodLine.SetRange("Test Suite", BCCTLine."AL Test Suite");
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Codeunit);
        TestMethodLine.FindFirst();
        TestSuiteMgt.RunAllTests(TestMethodLine);
    end;

    // local procedure CompleteBCCTLine(var BCCTLine: Record "BCCT Line")
    // begin
    //     BCCTLine.Status := BCCTLine.Status::Completed;
    //     BCCTLine.Modify();
    //     Commit();
    // end;

    internal procedure GetBCCTHeaderTag(): Text[20]
    begin
        exit(this.ActiveBCCTHeader.Tag);
    end;

    /// <summary>
    /// Sets the BCCT Line so that the test codeunits can retrieve.
    /// </summary>
    local procedure SetBCCTLine(var BCCTLine: Record "BCCT Line")
    begin
        this.GlobalBCCTLine := BCCTLine;
    end;

    /// <summary>
    /// Gets the BCCT Line stored through the SetBCCTLine method.
    /// </summary>
    internal procedure GetBCCTLine(var BCCTLine: Record "BCCT Line")
    begin
        BCCTLine := this.GlobalBCCTLine;
    end;

    local procedure SetBCCTHeader(var CurrBCCTHeader: Record "BCCT Header")
    begin
        this.GlobalBCCTHeader := CurrBCCTHeader;
    end;

    internal procedure GetBCCTHeader(var CurrBCCTHeader: Record "BCCT Header")
    begin
        CurrBCCTHeader := this.GlobalBCCTHeader;
    end;

    internal procedure AddToNoOfLogEntriesInserted()
    begin
        this.NoOfInsertedLogEntries += 1;
    end;

    internal procedure GetNoOfLogEntriesInserted(): Integer
    var
        ReturnValue: Integer;
    begin
        ReturnValue := this.NoOfInsertedLogEntries;
        exit(ReturnValue);
    end;

    internal procedure AddToAccumulatedWaitTimeMs(ms: Integer)
    begin
        this.AccumulatedWaitTimeMs += ms;
    end;

    internal procedure GetAndClearAccumulatedWaitTimeMs(): Integer
    var
        ReturnValue: Integer;
    begin
        ReturnValue := this.AccumulatedWaitTimeMs;
        this.AccumulatedWaitTimeMs := 0;
        exit(ReturnValue);
    end;

    internal procedure GetCurrTestMethodLine(): Record "Test Method Line"
    begin
        exit(this.GlobalTestMethodLine);
    end;

    [InternalEvent(false)]
    procedure OnBeforeRunIteration(var BCCTHeader: Record "BCCT Header"; var BCCTLine: Record "BCCT Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", OnBeforeTestMethodRun, '', false, false)]
    local procedure OnBeforeTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions)
    var
        BCCTContextCU: Codeunit "BCCT Test Context";
    begin
        if this.ActiveBCCTHeader.Code = '' then // exit the code if not triggered by BCCT 
            exit;
        if FunctionName = '' then
            exit;

        GlobalTestMethodLine := CurrentTestMethodLine;

        BCCTContextCU.StartRunProcedureScenario();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", OnAfterTestMethodRun, '', false, false)]
    local procedure OnAfterTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    var
        BCCTContextCU: Codeunit "BCCT Test Context";
    begin
        if this.ActiveBCCTHeader.Code = '' then // exit the code if not triggered by BCCT 
            exit;
        if FunctionName = '' then
            exit;

        GlobalTestMethodLine := CurrentTestMethodLine;
        BCCTContextCU.EndRunProcedureScenario(CurrentTestMethodLine, IsSuccess);
        Commit();
    end;
}