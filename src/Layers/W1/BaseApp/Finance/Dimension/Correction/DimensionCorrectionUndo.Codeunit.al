// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using System.Threading;

codeunit 2582 "Dimension Correction Undo"
{
    TableNo = "Job Queue Entry";
    Permissions = tabledata "G/L Entry" = rimd;

    trigger OnRun()
    var
        DimensionCorrection: Record "Dimension Correction";
    begin
        DimensionCorrection.Get(Rec."Record ID to Process");
        RunUndoDimensionCorrection(DimensionCorrection);
    end;

    procedure RunUndoDimensionCorrection(var DimensionCorrection: Record "Dimension Correction")
    var
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
    begin
        Session.LogMessage('0000EHM', StrSubstNo(StartingDimensionCorrectionUndoLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
        Session.LogMessage('0000EHN', StrSubstNo(StartingVerifyingCanUndoDimensionCorrectionLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
        DimensionCorrectionMgt.VerifyCanUndoDimensionCorrection(DimensionCorrection);
        Session.LogMessage('0000EHO', StrSubstNo(CompletedVerifyingCanUndoDimensionCorrectionLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);

        DimensionCorrectionMgt.SetUndoStatusInProgress(DimensionCorrection);
        UndoDimensionCorrection(DimensionCorrection);

        DimensionCorrection.Status := DimensionCorrection.Status::"Undo Completed";
        DimensionCorrection.Modify();
        Commit();

        if DimensionCorrection."Update Analysis Views" then
            DimensionCorrectionMgt.ScheduleUpdateAnalysisViews(DimensionCorrection);

        Session.LogMessage('0000EHP', StrSubstNo(CompletedDimensionCorrectionUndoLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
    end;

    local procedure UndoDimensionCorrection(var DimensionCorrection: Record "Dimension Correction")
    var
        DimCorrectionEntryLog: Record "Dim Correction Entry Log";
        TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        InvalidatedDimCorrection: Record "Invalidated Dim Correction";
        GLEntry: Record "G/L Entry";
        TempInvalidatedDimCorrection: Record "Invalidated Dim Correction" temporary;
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
        StartDateTime: DateTime;
    begin
        Session.LogMessage('0000EHQ', StrSubstNo(StartingUndoDimensionCorrectionEntriesLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
        StartDateTime := CurrentDateTime();

        if not DimensionCorrectionManagement.LoadTempDimCorrectionSetBuffer(DimensionCorrection."Entry No.", TempDimCorrectionSetBuffer) then
            Error(CannotFindChangesToUndoErr);

        DimCorrectionEntryLog.SetCurrentKey("Start Entry No.");
        DimCorrectionEntryLog.Ascending(true);
        DimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        DimCorrectionEntryLog.SetFilter("End Entry No.", '>=%1', DimensionCorrection."Undo Last Ledger Entry No.");
        if not DimCorrectionEntryLog.FindSet() then
            Error(CannotFindEntriesToUndoErr);

        if DimCorrectionEntryLog."Start Entry No." < DimensionCorrection."Undo Last Ledger Entry No." then
            DimCorrectionEntryLog."Start Entry No." := DimensionCorrection."Undo Last Ledger Entry No.";

        repeat
            GLEntry.SetRange("Entry No.", DimCorrectionEntryLog."Start Entry No.", DimCorrectionEntryLog."End Entry No.");
            if GLEntry.FindSet() then
                repeat
                    if DimensionCorrectionMgt.GetTargetDimCorrectionSetBuffer(TempDimCorrectionSetBuffer, DimensionCorrection, GLEntry) then begin
                        UndoGLEntry(GLEntry, TempDimCorrectionSetBuffer, TempInvalidatedDimCorrection);
                        CommitCounter += 1;
                        if CommitCounter >= DimensionCorrectionMgt.GetCommitCount() then begin
                            DimensionCorrection."Undo Last Ledger Entry No." := GLEntry."Entry No.";
                            Commit();
                            Session.LogMessage('0000EHR', StrSubstNo(CommitedUndoLedgerEntriesUpdateTelemetryLbl, Format(CurrentDateTime() - StartDateTime), DimensionCorrectionMgt.GetCommitCount()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
                            StartDateTime := CurrentDateTime();
                            CommitCounter := 0;
                        end;
                    end;
                until GLEntry.Next() = 0;
        until DimCorrectionEntryLog.Next() = 0;

        if CommitCounter > 0 then
            Commit();

        InvalidatedDimCorrection.SetRange("Invalidated By Entry No.", DimensionCorrection."Entry No.");
        InvalidatedDimCorrection.DeleteAll();
        Commit();
        Session.LogMessage('0000EHS', StrSubstNo(CompletedUndoDimensionCorrectionEntriesLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
    end;

    local procedure UndoGLEntry(var GLEntry: Record "G/L Entry"; var TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary; var TempInvalidatedDimCorrection: Record "Invalidated Dim Correction" temporary): Boolean
    var
        InvalidatedDimCorrection: Record "Invalidated Dim Correction";
        DimensionManagement: Codeunit "DimensionManagement";
        Result: Boolean;
    begin
        if GLEntry."Dimension Set ID" = TempDimCorrectionSetBuffer."Dimension Set ID" then
            exit(false);

        GLEntry."Dimension Set ID" := TempDimCorrectionSetBuffer."Dimension Set ID";
        DimensionManagement.UpdateGlobalDimFromDimSetID(
            GLEntry."Dimension Set ID", GLEntry."Global Dimension 1 Code", GLEntry."Global Dimension 2 Code");
        OnUndoGLEntryOnAfterUpdateGlobalDimFromDimSetID(GLEntry);

        GLEntry."Dimension Changes Count" += 1;

        if not TempInvalidatedDimCorrection.Get(GLEntry."Last Dim. Correction Node") then begin
            InvalidatedDimCorrection.Get(GLEntry."Last Dim. Correction Node");
            TempInvalidatedDimCorrection.TransferFields(InvalidatedDimCorrection, true);
            TempInvalidatedDimCorrection.Insert();
        end;

        GLEntry."Last Dim. Correction Node" := TempInvalidatedDimCorrection."Parent Node Id";
        GLEntry."Last Dim. Correction Entry No." := TempInvalidatedDimCorrection."Invalidated Entry No.";
        GLEntry.Modify(true);

        Result := true;
        OnAfterUndoGLEntry(GLEntry, TempDimCorrectionSetBuffer, Result, TempInvalidatedDimCorrection);
        exit(Result);
    end;

    var
        DimensionCorrectionManagement: Codeunit "Dimension Correction Mgt";
        CommitCounter: Integer;
        CannotFindChangesToUndoErr: Label 'Cannot find the changed dimension set IDs to undo.';
        CannotFindEntriesToUndoErr: Label 'Cannot find changed entries to undo.';
        DimensionCorrectionTok: Label 'DimensionCorrection', Locked = true;
        StartingDimensionCorrectionUndoLbl: Label 'Starting Undo of Dimension Correction - %1', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        CompletedDimensionCorrectionUndoLbl: Label 'Completed Undo of Dimension Correction - %1', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        StartingVerifyingCanUndoDimensionCorrectionLbl: Label 'Starting Verify if Undo is possible of Dimension Correction - %1', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        CompletedVerifyingCanUndoDimensionCorrectionLbl: Label 'Completed Verify if Undo is possible of Dimension Correction - %1', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        StartingUndoDimensionCorrectionEntriesLbl: Label 'Starting undo of Ledger entries of Dimension Correction %1.', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        CompletedUndoDimensionCorrectionEntriesLbl: Label 'Starting undo of Ledger entries of Dimension Correction %1.', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        CommitedUndoLedgerEntriesUpdateTelemetryLbl: Label 'Commited Undo G/L Entries Dimensions. Time from last commit: %1. Number of entries iterated: %2', Locked = true, Comment = '%1 - Time passed between commits, %2 Number';

    [IntegrationEvent(false, false)]
    local procedure OnUndoGLEntryOnAfterUpdateGlobalDimFromDimSetID(var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUndoGLEntry(var GLEntry: Record "G/L Entry"; var TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer"; var Result: Boolean; var TempInvalidatedDimCorrection: Record "Invalidated Dim Correction" temporary)
    begin
    end;
}
