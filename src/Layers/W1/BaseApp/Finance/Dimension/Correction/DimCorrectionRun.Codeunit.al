// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using System.Threading;

codeunit 2581 "Dim Correction Run"
{
    TableNo = "Job Queue Entry";
    Permissions = tabledata "G/L Entry" = rimd;

    trigger OnRun()
    var
        DimensionCorrection: Record "Dimension Correction";
    begin
        DimensionCorrection.Get(Rec."Record ID to Process");
        RunDimensionCorrection(DimensionCorrection);
    end;

    procedure RunDimensionCorrection(var DimensionCorrection: Record "Dimension Correction")
    var
        TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        ErrorCount: Integer;
    begin
        Session.LogMessage('0000EHC', StrSubstNo(StartingDimensionCorrectionTelemetryLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
        DimensionCorrectionMgt.ValidateBlockedNotUsed(DimensionCorrection);
        DimensionCorrectionMgt.SetStatusInProgress(DimensionCorrection);

        DimensionCorrectionMgt.GenerateSupportingTables(DimensionCorrection, TempDimCorrectionSetBuffer);

        if not DimensionCorrection."Validated Selected Entries" then begin
            DimensionCorrectionMgt.ValidateDimensionSets(DimensionCorrection, TempDimCorrectionSetBuffer, ErrorCount);
            DimensionCorrectionMgt.ValidateDimensionChanges(DimensionCorrection, TempDimCorrectionSetBuffer, ErrorCount);
        end;

        ChangeLedgerEntries(DimensionCorrection, TempDimCorrectionSetBuffer);

        DimensionCorrection.GetBySystemId(DimensionCorrection.SystemId);
        DimensionCorrection.Status := DimensionCorrection.Status::Completed;
        DimensionCorrection.Completed := true;
        DimensionCorrection.Modify();
        Commit();
        if DimensionCorrection."Update Analysis Views" then
            DimensionCorrectionMgt.ScheduleUpdateAnalysisViews(DimensionCorrection);

        Session.LogMessage('0000EHH', StrSubstNo(CompletedDimensionCorrectionTelemetryLbl, DimensionCorrection."Entry No.", DimensionCorrection."Total Updated Ledger Entries"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
    end;

    local procedure ChangeLedgerEntries(var DimensionCorrection: Record "Dimension Correction"; var TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary)
    var
        LastDimCorrectionEntryLog: Record "Dim Correction Entry Log";
        DimCorrectionEntryLog: Record "Dim Correction Entry Log";
        TempInvalidatedDimCorrection: Record "Invalidated Dim Correction" temporary;
        UpdateCounter: Integer;
    begin
        Session.LogMessage('0000EHI', StrSubstNo(StartingChangeLedgerEntriesLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
        UpdateCounter := 0;

        if DimensionCorrection."Last Updated Entry No." > 0 then begin
            LastDimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
            LastDimCorrectionEntryLog.SetFilter("Start Entry No.", '<=%1', DimensionCorrection."Last Updated Entry No.");
            LastDimCorrectionEntryLog.SetFilter("End Entry No.", '>%1', DimensionCorrection."Last Updated Entry No.");
            if LastDimCorrectionEntryLog.FindFirst() then
                ChangeLedgerEntries(DimensionCorrection."Last Updated Entry No." + 1, LastDimCorrectionEntryLog."End Entry No.", UpdateCounter, TempInvalidatedDimCorrection, TempDimCorrectionSetBuffer, DimensionCorrection);
        end;

        DimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        DimCorrectionEntryLog.SetFilter("Start Entry No.", '>=%1', DimensionCorrection."Last Updated Entry No.");
        DimCorrectionEntryLog.SetCurrentKey("Start Entry No.");
        DimCorrectionEntryLog.Ascending(true);

        if DimCorrectionEntryLog.FindSet() then
            repeat
                ChangeLedgerEntries(DimCorrectionEntryLog."Start Entry No.", DimCorrectionEntryLog."End Entry No.", UpdateCounter, TempInvalidatedDimCorrection, TempDimCorrectionSetBuffer, DimensionCorrection);
            until DimCorrectionEntryLog.Next() = 0;

        if UpdateCounter > 0 then begin
            DimensionCorrection.Modify();
            commit();
        end;

        Session.LogMessage('0000EHK', StrSubstNo(CompletedChangeLedgerEntriesLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
    end;

    local procedure ChangeLedgerEntries(StartEntryNo: Integer; EndEntryNo: Integer; var UpdateCounter: Integer; var TempInvalidatedDimCorrection: Record "Invalidated Dim Correction" temporary; var TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary; var DimensionCorrection: Record "Dimension Correction")
    var
        GLEntry: Record "G/L Entry";
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime();

        GLEntry.SetFilter("Entry No.", '>=%1&<=%2', StartEntryNo, EndEntryNo);
        if GLEntry.FindSet() then
            repeat
                TempDimCorrectionSetBuffer.Get(DimensionCorrection."Entry No.", GLEntry."Dimension Set ID");
                if UpdateGLEntry(GLEntry, DimensionCorrection."Entry No.", TempDimCorrectionSetBuffer, TempInvalidatedDimCorrection) then
                    DimensionCorrection."Total Updated Ledger Entries" += 1;

                DimensionCorrection."Last Updated Entry No." := GLEntry."Entry No.";

                UpdateCounter += 1;
                if UpdateCounter >= DimensionCorrectionMgt.GetCommitCount() then begin
                    UpdateCounter := 0;
                    DimensionCorrection.Modify();
                    Commit();
                    Session.LogMessage('0000EHJ', StrSubstNo(CommitedLedgerEntriesUpdateTelemetryLbl, DimensionCorrection."Entry No.", Format(CurrentDateTime() - StartDateTime), DimensionCorrectionMgt.GetCommitCount()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
                    StartDateTime := CurrentDateTime();
                end;
            until GLEntry.Next() = 0;

        if UpdateCounter > 0 then begin
            DimensionCorrection.Modify();
            Commit();
        end;
    end;

    local procedure UpdateGLEntry(var GLEntry: Record "G/L Entry"; DimensionCorrectionEntryNo: Integer; var TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary; var TempInvalidatedDimCorrection: Record "Invalidated Dim Correction" temporary) Result: Boolean
    var
        InvalidatedDimCorrection: Record "Invalidated Dim Correction";
        DimCorrectionSetBuffer: Record "Dim Correction Set Buffer";
        DimensionManagement: Codeunit "DimensionManagement";
    begin
        GLEntry."Dimension Set ID" := TempDimCorrectionSetBuffer."Target Set ID";
        DimensionManagement.UpdateGlobalDimFromDimSetID(
            GLEntry."Dimension Set ID", GLEntry."Global Dimension 1 Code", GLEntry."Global Dimension 2 Code");
        OnUpdateGLEntryOnAfterUpdateGlobalDimFromDimSetID(GLEntry);

        if TempDimCorrectionSetBuffer."Multiple Target Set ID" then begin
            DimCorrectionSetBuffer.Get(TempDimCorrectionSetBuffer.RecordId);
            DimCorrectionSetBuffer.AddLedgerEntry(GLEntry."Entry No.");
            DimCorrectionSetBuffer.Modify();
        end;

        GLEntry."Dimension Changes Count" += 1;
        TempInvalidatedDimCorrection.SetRange("Parent Node Id", GLEntry."Last Dim. Correction Node");
        TempInvalidatedDimCorrection.SetRange("Invalidated Entry No.", GLEntry."Last Dim. Correction Entry No.");
        TempInvalidatedDimCorrection.SetRange("Invalidated By Entry No.", DimensionCorrectionEntryNo);
        if not TempInvalidatedDimCorrection.FindFirst() then begin
            InvalidatedDimCorrection.SetRange("Parent Node Id", GLEntry."Last Dim. Correction Node");
            InvalidatedDimCorrection.SetRange("Invalidated Entry No.", GLEntry."Last Dim. Correction Entry No.");
            InvalidatedDimCorrection.SetRange("Invalidated By Entry No.", DimensionCorrectionEntryNo);

            if not InvalidatedDimCorrection.FindFirst() then begin
                InvalidatedDimCorrection."Parent Node Id" := GLEntry."Last Dim. Correction Node";
                InvalidatedDimCorrection."Invalidated Entry No." := GLEntry."Last Dim. Correction Entry No.";
                InvalidatedDimCorrection."Invalidated By Entry No." := DimensionCorrectionEntryNo;
                InvalidatedDimCorrection.Insert(true);
            end;

            TempInvalidatedDimCorrection.TransferFields(InvalidatedDimCorrection, true);
            TempInvalidatedDimCorrection.Insert(true);
        end;

        GLEntry."Last Dim. Correction Entry No." := DimensionCorrectionEntryNo;
        GLEntry."Last Dim. Correction Node" := TempInvalidatedDimCorrection."Node Id";
        GLEntry.Modify(true);

        Result := true;
        OnAfterUpdateGLEntry(GLEntry, TempDimCorrectionSetBuffer, Result, DimensionCorrectionEntryNo, TempInvalidatedDimCorrection);
    end;

    var
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
        StartingDimensionCorrectionTelemetryLbl: Label 'Starting Dimension Correction, Dimension Correction Entry No.: %1.', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        CompletedDimensionCorrectionTelemetryLbl: Label 'Completed Dimension Correction, Dimension Correction Entry No.: %1. Total number of updated entries %2.', Locked = true, Comment = '%1 Dimension Correction Entry No., %2 number of updated entries';
        StartingChangeLedgerEntriesLbl: Label 'Starting Change Ledger Entries, Dimension Correction Entry No.: %1.', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        CompletedChangeLedgerEntriesLbl: Label 'Completed Change Ledger Entries, Dimension Correction Entry No.: %1.', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        CommitedLedgerEntriesUpdateTelemetryLbl: Label 'Commited G/L Entries update. Dimension Correction Entry No.: %1, Time from last commit: %2. Number of entries iterated: %3.', Locked = true, Comment = '%1 Dimension Correction Entry No., %2 - Time passed between commits, %3 Number';
        DimensionCorrectionTok: Label 'DimensionCorrection', Locked = true;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateGLEntry(var GLEntry: Record "G/L Entry"; var TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer"; var Result: Boolean; DimensionCorrectionEntryNo: Integer; var TempInvalidatedDimCorrection: Record "Invalidated Dim Correction" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateGLEntryOnAfterUpdateGlobalDimFromDimSetID(var GLEntry: Record "G/L Entry")
    begin
    end;
}
