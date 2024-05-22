// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.TestTools.TestRunner;

codeunit 149042 "BCCT Role Wrapper"
{
    TableNo = "BCCT Line";
    SingleInstance = true;
    Access = Internal;

    var
        GlobalBCCTLine: Record "BCCT Line";
        GlobalBCCTHeader: Record "BCCT Header";
        ActiveBCCTHeader: Record "BCCT Header";
        GlobalBCCTDatasetLine: Record "BCCT Dataset Line";
        NoOfInsertedLogEntries: Integer;
        AccumulatedWaitTimeMs: Integer;
        ExecuteProcedureOperationLbl: Label 'Execute Procedure', Locked = true;

    trigger OnRun();
    begin
        if Rec."Codeunit ID" = 0 then
            exit;
        SetBCCTLine(Rec);

        NoOfInsertedLogEntries := 0;
        AccumulatedWaitTimeMs := 0;

        InitializeBCCTLineForRun(Rec, ActiveBCCTHeader);
        SetBCCTHeader(ActiveBCCTHeader);

        ExecuteBCCTLine(Rec, ActiveBCCTHeader);
    end;

    local procedure InitializeBCCTLineForRun(var BCCTLine: Record "BCCT Line"; var BCCTHeader: Record "BCCT Header")
    begin
        BCCTHeader.Get(BCCTLine."BCCT Code");
        if BCCTHeader."Started at" < CurrentDateTime() then
            BCCTHeader."Started at" := CurrentDateTime();

        if BCCTLine.Dataset = '' then
            BCCTLine.Dataset := (BCCTHeader.Dataset);

        if BCCTLine."Delay (ms btwn. iter.)" < 1 then
            BCCTLine."Delay (ms btwn. iter.)" := BCCTHeader."Default Delay (ms)";
    end;

    local procedure ExecuteBCCTLine(var BCCTLine: Record "BCCT Line"; var BCCTHeader: Record "BCCT Header")
    var
        BCCTDatasetLine: Record "BCCT Dataset Line";
        BCCTHeaderCU: Codeunit "BCCT Header";
        ExecuteNextIteration: Boolean;
    begin
        ExecuteNextIteration := true;
        Randomize();

        SetDatasetFilter(BCCTDatasetLine, BCCTLine, BCCTHeader);
        if not BCCTDatasetLine.FindSet() then
            exit;

        repeat
            GetAndClearAccumulatedWaitTimeMs();

            SetBCCTDatasetLine(BCCTDatasetLine);
            OnBeforeExecuteIteration(BCCTHeader, BCCTLine, BCCTDatasetLine);
            ExecuteIteration(BCCTLine, BCCTDatasetLine);
            Commit();

            BCCTHeader.Find();
            if BCCTHeader.Status = BCCTHeader.Status::Cancelled then
                ExecuteNextIteration := false;


            if ExecuteNextIteration then
                if BCCTDatasetLine.Next() = 0 then begin
                    if BCCTLine.Next() = 0 then
                        ExecuteNextIteration := false
                    else begin
                        BCCTDatasetLine.Reset();
                        SetDatasetFilter(BCCTDatasetLine, BCCTLine, BCCTHeader);
                        if BCCTDatasetLine.FindSet() then;
                    end;
                    Sleep(BCCTLine."Delay (ms btwn. iter.)");
                end;

        //TODO override delay from line / default delay

        until (ExecuteNextIteration = false);
        BCCTHeaderCU.DecreaseNoOfTestsRunningNow(BCCTHeader);
    end;

    local procedure SetDatasetFilter(var BCCTDatasetLine: Record "BCCT Dataset Line"; BCCTLine: Record "BCCT Line"; BCCTHeader: Record "BCCT Header")
    begin
        // Select the correct dataset
        if BCCTLine.Dataset = '' then
            BCCTDatasetLine.SetRange(BCCTDatasetLine."Dataset Name", BCCTHeader.Dataset)
        else
            BCCTDatasetLine.SetRange(BCCTDatasetLine."Dataset Name", BCCTLine.Dataset);
    end;

    local procedure ExecuteIteration(var BCCTLine: Record "BCCT Line"; BCCTDatasetLine: Record "BCCT Dataset Line")
    var
        TestMethodLine: Record "Test Method Line";
        TestRunnerIsolDisabled: Codeunit "Test Runner - Isol. Disabled";
    begin
        SetBCCTLine(BCCTLine);
        TestMethodLine."Line Type" := TestMethodLine."Line Type"::Codeunit;
        TestMethodLine."Skip Logging Results" := true;
        TestMethodLine."Test Codeunit" := BCCTLine."Codeunit ID";
        if BCCTDatasetLine.GetInputBlobAsText() <> '' then; //TODO: remove this if we figure out that we need test method line.
        // TODO: remove BCCTDatasetLine if not needed
        //TestMethodLine."Data Input" := BCCTDatasetLine."Input Data";
        TestRunnerIsolDisabled.Run(TestMethodLine);
    end;

    // local procedure CompleteBCCTLine(var BCCTLine: Record "BCCT Line")
    // begin
    //     BCCTLine.Status := BCCTLine.Status::Completed;
    //     BCCTLine.Modify();
    //     Commit();
    // end;

    internal procedure GetBCCTHeaderTag(): Text[20]
    begin
        exit(ActiveBCCTHeader.Tag);
    end;

    /// <summary>
    /// Sets the BCCT Line so that the test codeunits can retrieve.
    /// </summary>
    local procedure SetBCCTLine(var BCCTLine: Record "BCCT Line")
    begin
        GlobalBCCTLine := BCCTLine;
    end;

    /// <summary>
    /// Gets the BCCT Line stored through the SetBCCTLine method.
    /// </summary>
    internal procedure GetBCCTLine(var BCCTLine: Record "BCCT Line")
    begin
        BCCTLine := GlobalBCCTLine;
    end;

    local procedure SetBCCTDatasetLine(var BCCTDatasetLine: Record "BCCT Dataset Line")
    begin
        GlobalBCCTDatasetLine := BCCTDatasetLine;
    end;

    internal procedure GetBCCTDatasetLine(var BCCTDatasetLine: Record "BCCT Dataset Line")
    begin
        BCCTDatasetLine := GlobalBCCTDatasetLine;
    end;

    local procedure SetBCCTHeader(var CurrBCCTHeader: Record "BCCT Header")
    begin
        GlobalBCCTHeader := CurrBCCTHeader;
    end;

    internal procedure GetBCCTHeader(var CurrBCCTHeader: Record "BCCT Header")
    begin
        CurrBCCTHeader := GlobalBCCTHeader;
    end;

    internal procedure AddToNoOfLogEntriesInserted()
    begin
        NoOfInsertedLogEntries += 1;
    end;

    internal procedure GetNoOfLogEntriesInserted(): Integer
    var
        ReturnValue: Integer;
    begin
        ReturnValue := NoOfInsertedLogEntries;
        exit(ReturnValue);
    end;

    internal procedure AddToAccumulatedWaitTimeMs(ms: Integer)
    begin
        AccumulatedWaitTimeMs += ms;
    end;

    internal procedure GetAndClearAccumulatedWaitTimeMs(): Integer
    var
        ReturnValue: Integer;
    begin
        ReturnValue := AccumulatedWaitTimeMs;
        AccumulatedWaitTimeMs := 0;
        exit(ReturnValue);
    end;

    internal procedure GetDefaultExecuteProcedureOperationLbl(): Text
    begin
        exit(ExecuteProcedureOperationLbl);
    end;

    [InternalEvent(false)]
    procedure OnBeforeExecuteIteration(var BCCTHeader: Record "BCCT Header"; var BCCTLine: Record "BCCT Line"; var BCCTDatasetLine: Record "BCCT Dataset Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", OnBeforeTestMethodRun, '', false, false)]
    local procedure OnBeforeTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions)
    var
        BCCTContextCU: Codeunit "BCCT Test Context";
    begin
        if ActiveBCCTHeader.Code = '' then // exit the code if not triggered by BCCT 
            exit;
        if FunctionName = '' then
            exit;
        BCCTContextCU.StartScenario(GetDefaultExecuteProcedureOperationLbl());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", OnAfterTestMethodRun, '', false, false)]
    local procedure OnAfterTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    var
        BCCTContextCU: Codeunit "BCCT Test Context";
    begin
        if ActiveBCCTHeader.Code = '' then // exit the code if not triggered by BCCT 
            exit;
        Commit(); //TODO: Do we need these commits?
        if FunctionName = '' then
            exit;
        BCCTContextCU.EndScenario(GetDefaultExecuteProcedureOperationLbl(), FunctionName, IsSuccess);
        Commit();
    end;
}