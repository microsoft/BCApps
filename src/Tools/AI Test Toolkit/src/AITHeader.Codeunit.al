// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.TestTools.TestRunner;

codeunit 149034 "AIT Header"
{
    Access = Internal;

    var
        AITTRunStartedLbl: Label 'AITT Suite run started.', Locked = true;
        AITTRunFinishedLbl: Label 'AITT Suite run finished.', Locked = true;
        AITTRunCancelledLbl: Label 'AITT Suite run cancelled.', Locked = true;
        EmptyDatasetSuiteErr: Label 'Please provide a dataset for the AIT Suite %1.', Comment = '%1 is the AIT Suite code';
        NoDatasetInSuiteErr: Label 'The dataset %1 specified for AIT Suite %2 does not exist.', Comment = '%1 is the Dataset name, %2 is the AIT Suite code';
        NoInputsInSuiteErr: Label 'The dataset %1 specified for AIT Suite %2 has no input lines.', Comment = '%1 is the Dataset name, %2 is the AIT Suite code.';
        NoDatasetInLineErr: Label 'The dataset %1 specified for AIT Line %2 does not exist.', Comment = '%1 is the Dataset name, %2 is AIT Line No.';
        NoInputsInLineErr: Label 'The dataset %1 specified for AIT line %2 has no input lines.', Comment = '%1 is the Dataset name, %2 is the AIT Line No.';

    procedure DecreaseNoOfTestsRunningNow(var AITHeader: Record "AIT Header")
    begin
        if AITHeader.Code = '' then
            exit;
        AITHeader.ReadIsolation(IsolationLevel::UpdLock);
        if not AITHeader.Find() then
            exit;
        AITHeader.Validate("No. of tests running", AITHeader."No. of tests running" - 1);
        AITHeader.Modify();
        Commit();
    end;

    procedure ResetStatus(var AITHeader: Record "AIT Header")
    var
        AITLine: Record "AIT Line";
        ConfirmResetStatusQst: Label 'This action will mark the run as Completed. Are you sure you want to continue ?';
    begin
        if Confirm(ConfirmResetStatusQst) then begin
            AITLine.SetRange("AIT Code", AITHeader."Code");
            AITLine.ModifyAll(Status, AITLine.Status::Completed);
            AITHeader.Status := AITHeader.Status::Completed;
            AITHeader."No. of tests running" := 0;
            AITHeader."Ended at" := CurrentDateTime();
            AITHeader.Duration := AITHeader."Ended at" - AITHeader."Started at";
            AITHeader.Modify(true);
        end;
    end;

    procedure ValidateDatasets(var AITHeader: Record "AIT Header")
    var
        AITLine: Record "AIT Line";
        DatasetsToValidate: List of [Code[100]];
        DatasetName: Code[100];
    begin
        // Validate header
        if AITHeader."Input Dataset" = '' then
            Error(EmptyDatasetSuiteErr, AITHeader."Code");

        if not this.DatasetExists(AITHeader."Input Dataset") then
            Error(NoDatasetInSuiteErr, AITHeader."Input Dataset", AITHeader."Code");

        if not this.InputDataLinesExists(AITHeader."Input Dataset") then
            Error(NoInputsInSuiteErr, AITHeader."Input Dataset", AITHeader."Code");

        // Validate lines
        AITLine.SetRange("AIT Code", AITHeader."Code");
        AITLine.SetFilter("Input Dataset", '<>%1', '');
        AITLine.SetLoadFields("Input Dataset");
        if AITLine.FindSet() then
            repeat
                if AITLine."Input Dataset" <> AITHeader."Input Dataset" then
                    if not DatasetsToValidate.Contains(AITLine."Input Dataset") then
                        DatasetsToValidate.Add(AITLine."Input Dataset");
            until AITLine.Next() = 0;

        foreach DatasetName in DatasetsToValidate do begin
            if not this.DatasetExists(DatasetName) then
                Error(NoDatasetInLineErr, DatasetName, AITLine."Line No.");
            if not this.InputDataLinesExists(DatasetName) then
                Error(NoInputsInLineErr, DatasetName, AITLine."Line No.");
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

    [EventSubscriber(ObjectType::Table, Database::"AIT Header", OnBeforeDeleteEvent, '', false, false)]
    local procedure DeleteLinesOnDeleteAITHeader(var Rec: Record "AIT Header"; RunTrigger: Boolean)
    var
        AITLine: Record "AIT Line";
        AITLogEntry: Record "AIT Log Entry";
    begin
        if Rec.IsTemporary() then
            exit;

        AITLine.SetRange("AIT Code", Rec."Code");
        AITLine.DeleteAll(true);

        AITLogEntry.SetRange("AIT Code", Rec."Code");
        AITLogEntry.DeleteAll(true);
    end;

    procedure SetRunStatus(var AITHeader: Record "AIT Header"; AITHeaderStatus: Enum "AIT Header Status")
    var
        TelemetryCustomDimensions: Dictionary of [Text, Text];
    begin
        TelemetryCustomDimensions.Add('RunID', Format(AITHeader.RunID));
        TelemetryCustomDimensions.Add('Code', AITHeader.Code);
        if AITHeaderStatus <> AITHeaderStatus::Running then begin
            AITHeader."Ended at" := CurrentDateTime();
            AITHeader.Duration := AITHeader."Ended at" - AITHeader."Started at";
            TelemetryCustomDimensions.Add('DurationInMiliseconds', Format(AITHeader.Duration));
        end;
        TelemetryCustomDimensions.Add('Version', Format(AITHeader.Version));

        AITHeader.Status := AITHeaderStatus;
        AITHeader.CalcFields("No. of Tests Executed", "Total Duration (ms)"); //TODO: add this to custom dimensions or remove it

        case AITHeaderStatus of
            AITHeaderStatus::Running:
                Session.LogMessage('0000DHR', AITTRunStartedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryCustomDimensions);
            AITHeaderStatus::Completed:
                Session.LogMessage('0000DHS', AITTRunFinishedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryCustomDimensions);
            AITHeaderStatus::Cancelled:
                Session.LogMessage('0000DHT', AITTRunCancelledLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryCustomDimensions);
        end;
        AITHeader.Modify();
        Commit();
    end;
}