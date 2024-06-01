// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;

codeunit 149034 "BCCT Header"
{
    Access = Internal;

    procedure DecreaseNoOfTestsRunningNow(var BCCTHeader: Record "BCCT Header")
    begin
        if BCCTHeader.Code = '' then
            exit;
        BCCTHeader.LockTable();
        if not BCCTHeader.Find() then
            exit;
        BCCTHeader.Validate("No. of tests running", BCCTHeader."No. of tests running" - 1);
        BCCTHeader.Modify();
        Commit();
    end;

    procedure ResetStatus(var BCCTHeader: Record "BCCT Header")
    var
        BCCTLine: Record "BCCT Line";
        ConfirmResetStatusQst: Label 'This action will mark the run as Completed. Are you sure you want to continue ?';
    begin
        if Confirm(ConfirmResetStatusQst) then begin
            BCCTLine.SetRange("BCCT Code", BCCTHeader."Code");
            BCCTLine.ModifyAll(Status, BCCTLine.Status::Completed);
            BCCTHeader.Status := BCCTHeader.Status::Completed;
            BCCTHeader."No. of tests running" := 0;
            BCCTHeader."Ended at" := CurrentDateTime();
            BCCTHeader.Duration := BCCTHeader."Ended at" - BCCTHeader."Started at";
            BCCTHeader.Modify(true);
        end;
    end;

    procedure ValidateDatasets(var BCCTHeader: Record "BCCT Header")
    var
        BCCTLine: Record "BCCT Line";
        EmptyDatasetSuiteErr: Label 'Please provide a dataset for the BCCT Suite %1.', Comment = '%1 is the BCCT Suite code';
        NoDatasetInSuiteErr: Label 'The dataset %1 specified for BCCT Suite %2 does not exist.', Comment = '%1 is the Dataset name, %2 is the BCCT Suite code';
        NoInputsInSuiteErr: Label 'The dataset %1 specified for BCCT Suite %2 has no input lines.', Comment = '%1 is the Dataset name, %2 is the BCCT Suite code.';
        NoDatasetInLineErr: Label 'The dataset %1 specified for BCCT Line %2 does not exist.', Comment = '%1 is the Dataset name, %2 is BCCT Line No.';
        NoInputsInLineErr: Label 'The dataset %1 specified for BCCT line %2 has no input lines.', Comment = '%1 is the Dataset name, %2 is the BCCT Line No.';
        DatasetsToValidate: List of [Code[100]];
        DatasetName: Code[100];
    begin
        // Validate header
        if BCCTHeader."Input Dataset" = '' then
            Error(EmptyDatasetSuiteErr, BCCTHeader."Code");

        if not this.DatasetExists(BCCTHeader."Input Dataset") then
            Error(NoDatasetInSuiteErr, BCCTHeader."Input Dataset", BCCTHeader."Code");

        if not this.InputDataLinesExists(BCCTHeader."Input Dataset") then
            Error(NoInputsInSuiteErr, BCCTHeader."Input Dataset", BCCTHeader."Code");

        // Validate lines
        BCCTLine.SetRange("BCCT Code", BCCTHeader."Code");
        BCCTLine.SetFilter("Input Dataset", '<>%1', '');
        BCCTLine.SetLoadFields("Input Dataset");
        if BCCTLine.FindSet() then
            repeat
                if BCCTLine."Input Dataset" <> BCCTHeader."Input Dataset" then
                    if not DatasetsToValidate.Contains(BCCTLine."Input Dataset") then
                        DatasetsToValidate.Add(BCCTLine."Input Dataset");
            until BCCTLine.Next() = 0;

        foreach DatasetName in DatasetsToValidate do begin
            if not this.DatasetExists(DatasetName) then
                Error(NoDatasetInLineErr, DatasetName, BCCTLine."Line No.");
            if not this.InputDataLinesExists(DatasetName) then
                Error(NoInputsInLineErr, DatasetName, BCCTLine."Line No.");
        end;
    end;

    local procedure DatasetExists(DatasetName: Code[100]): Boolean
    var
        TestInputGroup: Record "Test Input Group";
    begin
        exit(TestInputGroup.Get(DatasetName));
    end;

    local procedure InputDataLinesExists(DatasetName: Code[100]): Boolean
    var
        TestInput: Record "Test Input";
    begin
        TestInput.Reset();
        TestInput.SetRange("Test Input Group Code", DatasetName);
        exit(not TestInput.IsEmpty());
    end;

    [EventSubscriber(ObjectType::Table, Database::"BCCT Header", OnBeforeDeleteEvent, '', false, false)]
    local procedure DeleteLinesOnDeleteBCCTHeader(var Rec: Record "BCCT Header"; RunTrigger: Boolean)
    var
        BCCTLine: Record "BCCT Line";
        BCCTLogEntry: Record "BCCT Log Entry";
    begin
        if Rec.IsTemporary() then
            exit;

        BCCTLine.SetRange("BCCT Code", Rec."Code");
        BCCTLine.DeleteAll(true);

        BCCTLogEntry.SetRange("BCCT Code", Rec."Code");
        BCCTLogEntry.DeleteAll(true);
    end;

    procedure SetRunStatus(var BCCTHeader: Record "BCCT Header"; BCCTHeaderStatus: Enum "BCCT Header Status")
    var
        TelemetryCustomDimensions: Dictionary of [Text, Text];
        PerformanceRunStartedLbl: Label 'Performance Toolkit run started.', Locked = true;
        PerformanceRunFinishedLbl: Label 'Performance Toolkit run finished.', Locked = true;
        PerformanceRunCancelledLbl: Label 'Performance Toolkit run cancelled.', Locked = true;
    begin
        TelemetryCustomDimensions.Add('RunID', Format(BCCTHeader.RunID));
        TelemetryCustomDimensions.Add('Code', BCCTHeader.Code);
        if BCCTHeaderStatus <> BCCTHeaderStatus::Running then begin
            BCCTHeader."Ended at" := CurrentDateTime();
            BCCTHeader.Duration := BCCTHeader."Ended at" - BCCTHeader."Started at";
            TelemetryCustomDimensions.Add('DurationInMiliseconds', Format(BCCTHeader.Duration));
        end;
        TelemetryCustomDimensions.Add('Version', Format(BCCTHeader.Version));

        BCCTHeader.Status := BCCTHeaderStatus;
        BCCTHeader.CalcFields("No. of Tests Executed", "Total Duration (ms)"); //TODO: add this to custom dimensions or remove it

        case BCCTHeaderStatus of
            BCCTHeaderStatus::Running:
                Session.LogMessage('0000DHR', PerformanceRunStartedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryCustomDimensions);
            BCCTHeaderStatus::Completed:
                Session.LogMessage('0000DHS', PerformanceRunFinishedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryCustomDimensions);
            BCCTHeaderStatus::Cancelled:
                Session.LogMessage('0000DHT', PerformanceRunCancelledLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryCustomDimensions);
        end;
        BCCTHeader.Modify();
        Commit();

    end;

}