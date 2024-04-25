// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

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

    [EventSubscriber(ObjectType::Table, Database::"BCCT Header", 'OnBeforeDeleteEvent', '', false, false)]
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
        BCCTHeader.CalcFields("No. of tests in the last run", "Total Duration (ms)");

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