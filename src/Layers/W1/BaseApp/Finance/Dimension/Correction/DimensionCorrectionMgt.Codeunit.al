// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.CostAccounting.Setup;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using System.Environment.Configuration;
using System.Text;
using System.Threading;
using System.Utilities;

codeunit 2580 "Dimension Correction Mgt"
{
    trigger OnRun()
    begin

    end;

    procedure ValidateNoBlockedDimensionsUsed(var DimensionCorrection: Record "Dimension Correction")
    var
        DimCorrectionChange: Record "Dim Correction Change";
    begin
        DimCorrectionChange.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        DimCorrectionChange.SetFilter("Change Type", '<>%1', DimCorrectionChange."Change Type"::"No Change");
        if not DimCorrectionChange.FindSet() then
            exit;

        repeat
            VerifyIfDimensionCanBeChanged(DimCorrectionChange);
        until DimCorrectionChange.Next() = 0;
    end;

    procedure GenerateSupportingTables(var DimensionCorrection: Record "Dimension Correction"; var TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary)
    var
        DimensionCorrectionEntryLog: Record "Dim Correction Entry Log";
        DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
    begin
        DimCorrectSelectionCriteria.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        if DimCorrectSelectionCriteria.IsEmpty() then
            Error(NoSelectionCriteriaFoundErr);

        if not DimensionCorrection."Generated Set IDs" then begin
            Session.LogMessage('0000EHF', StrSubstNo(StartingGenerateDimensionSetIdsLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
            GenerateTargetDimensionSetIds(DimensionCorrection);
            Session.LogMessage('0000EHG', StrSubstNo(CompletedGenerateDimensionSetIdsLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
        end;

        if not LoadTempDimCorrectionSetBuffer(DimensionCorrection."Entry No.", TempDimCorrectionSetBuffer) then
            Error(NoChangesFoundErr);

        if not DimensionCorrection."Generated Selected Entries" then begin
            Session.LogMessage('0000EKA', StrSubstNo(StartingGenerateSelectedEntriesLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
            GenerateSelectedEntries(DimensionCorrection, TempDimCorrectionSetBuffer);
            Session.LogMessage('0000EKB', StrSubstNo(CompletedGenerateSelectedEntriesLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
        end;

        DimensionCorrectionEntryLog.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        if DimensionCorrectionEntryLog.IsEmpty() then
            Error(NoLedgerEntriesFoundErr);
    end;

    procedure VerifyCanValidateDimensionCorrection(var DimensionCorrection: Record "Dimension Correction")
    begin
        if not (DimensionCorrection.Status in [DimensionCorrection.Status::Completed, DimensionCorrection.Status::Draft, DimensionCorrection.Status::Failed, DimensionCorrection.Status::"Validaton in Process"]) then
            Error(CannotValidateDimensionCorrectionErr, DimensionCorrection.Status);
    end;

    procedure ValidateBlockedNotUsed(var DimensionCorrection: Record "Dimension Correction")
    begin
        Session.LogMessage('0000EHD', StrSubstNo(StartingValidateDimensionCorrectionChangesTelemetryLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
        ValidateNoBlockedDimensionsUsed(DimensionCorrection);
        Session.LogMessage('0000EHE', StrSubstNo(CompletedValidateDimensionCorrectionChangesTelemetryLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
    end;

    procedure ValidateDimensionSets(var DimensionCorrection: Record "Dimension Correction"; var TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary; var ErrorCount: Integer)
    var
        DimensionManagement: Codeunit DimensionManagement;
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorMessage: Text[250];
    begin
        if DimensionCorrection.Status = DimensionCorrection.Status::"Validaton in Process" then
            DimensionManagement.SetCollectErrorsMode();

        TempDimCorrectionSetBuffer.FindSet();
        repeat
            if not DimensionManagement.CheckDimIDComb(TempDimCorrectionSetBuffer."Target Set ID") then
                if DimensionCorrection.Status <> DimensionCorrection.Status::"Validaton in Process" then begin
                    Commit();
                    ErrorMessageManagement.GetLastError(ErrorMessage);
                    Error(ErrorMessage);
                end else begin
                    ErrorCount += 1;
                    if ErrorCount > GetMaximumNumberOfValidationErrors() then
                        UpdateValidationStatusAndThrowErrorIfFailed(DimensionCorrection, ErrorCount);
                end;
        until TempDimCorrectionSetBuffer.Next() = 0;
    end;

    procedure ValidateDimensionChanges(var DimensionCorrection: Record "Dimension Correction"; var TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary; var ErrorCount: Integer)
    var
        LastDimCorrectionEntryLog: Record "Dim Correction Entry Log";
        DimCorrectionEntryLog: Record "Dim Correction Entry Log";
        UpdateCounter: Integer;
    begin
        Session.LogMessage('0000EK5', StrSubstNo(StartingValidateDimensionChangesForEntriesLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
        ErrorCount := 0;
        UpdateCounter := 0;

        if DimensionCorrection."Last Validated Entry No." > 0 then begin
            LastDimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
            LastDimCorrectionEntryLog.SetFilter("Start Entry No.", '<=%1', DimensionCorrection."Last Validated Entry No.");
            LastDimCorrectionEntryLog.SetFilter("End Entry No.", '>%1', DimensionCorrection."Last Validated Entry No.");
            if LastDimCorrectionEntryLog.FindFirst() then
                ValidateDimensionChanges(DimensionCorrection."Last Validated Entry No." + 1, LastDimCorrectionEntryLog."End Entry No.", UpdateCounter, TempDimCorrectionSetBuffer, DimensionCorrection, ErrorCount);
        end;

        DimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        DimCorrectionEntryLog.SetFilter("Start Entry No.", '>=%1', DimensionCorrection."Last Validated Entry No.");
        DimCorrectionEntryLog.SetCurrentKey("Start Entry No.");
        DimCorrectionEntryLog.Ascending(true);

        if DimCorrectionEntryLog.FindSet() then
            repeat
                ValidateDimensionChanges(DimCorrectionEntryLog."Start Entry No.", DimCorrectionEntryLog."End Entry No.", UpdateCounter, TempDimCorrectionSetBuffer, DimensionCorrection, ErrorCount);
            until DimCorrectionEntryLog.Next() = 0;

        DimensionCorrection."Validated Selected Entries" := true;
        DimensionCorrection.Modify();
        Commit();
        Session.LogMessage('0000EK6', StrSubstNo(CompletedValidateDimensionChangesForEntriesLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
    end;

    local procedure ValidateDimensionChanges(StartEntryNo: Integer; EndEntryNo: Integer; var UpdateCounter: Integer; var TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary; var DimensionCorrection: Record "Dimension Correction"; var ErrorCount: Integer)
    var
        GLEntry: Record "G/L Entry";
        DimensionManagement: Codeunit DimensionManagement;
        StartDateTime: DateTime;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        StartDateTime := CurrentDateTime();
        GLEntry.SetFilter("Entry No.", '>=%1&<=%2', StartEntryNo, EndEntryNo);

        GLEntry.SetLoadFields("Entry No.", "Dimension Set ID", "G/L Account No.");
        if GLEntry.IsEmpty() then
            exit;
        if DimensionCorrection.Status = DimensionCorrection.Status::"Validaton in Process" then
            DimensionManagement.SetCollectErrorsMode();

        GLEntry.FindSet();
        repeat
            UpdateCounter += 1;

            No[1] := GLEntry."G/L Account No.";
            TableID[1] := Database::"G/L Account";
            TempDimCorrectionSetBuffer.Get(DimensionCorrection."Entry No.", GLEntry."Dimension Set ID");
            if not DimensionManagement.CheckDimValuePosting(TableID, No, TempDimCorrectionSetBuffer."Target Set ID") then
                if DimensionCorrection.Status <> DimensionCorrection.Status::"Validaton in Process" then begin
                    DimensionCorrection."Last Validated Entry No." := GLEntry."Entry No.";
                    DimensionCorrection.Modify();
                    Commit();
                    Error(InvalidDimensionCorrectionErr, GLEntry."Entry No.", DimensionManagement.GetDimValuePostingErr());
                end else begin
                    ErrorCount += 1;
                    if ErrorCount > GetMaximumNumberOfValidationErrors() then
                        UpdateValidationStatusAndThrowErrorIfFailed(DimensionCorrection, ErrorCount);
                end;

            if UpdateCounter >= GetCommitCount() then begin
                UpdateCounter := 0;
                DimensionCorrection."Last Validated Entry No." := GLEntry."Entry No.";
                DimensionCorrection.Modify();
                Commit();
                Session.LogMessage('0000EK7', StrSubstNo(CommitedValidateGLEntriesLbl, DimensionCorrection."Entry No.", Format(CurrentDateTime() - StartDateTime), GetCommitCount()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
                StartDateTime := CurrentDateTime();
            end;
        until GLEntry.Next() = 0;

        if UpdateCounter > 0 then begin
            DimensionCorrection."Last Validated Entry No." := GLEntry."Entry No.";
            DimensionCorrection.Modify();
            Commit();
        end;
    end;

    procedure VerifyIfDimensionCanBeChanged(var DimCorrectionChange: Record "Dim Correction Change")
    var
        DimCorrecitonBlocked: Record "Dim Correction Blocked Setup";
    begin
        if DimCorrecitonBlocked.Get(DimCorrectionChange."Dimension Code") then
            Error(CannotChangeDimensionCodeBlockedErr, DimCorrectionChange."Dimension Code");

        OnAfterVerifyIfDimensionCanBeChanged(DimCorrectionChange);
    end;

    procedure DeleteValidationErrors(var DimensionCorrection: Record "Dimension Correction")
    var
        ErrorMessage: Record "Error Message";
    begin
        if not IsNullGuid(DimensionCorrection."Validation Errors Register ID") then begin
            ErrorMessage.SetRange("Register ID", DimensionCorrection."Validation Errors Register ID");
            ErrorMessage.DeleteAll();
        end;
        Clear(DimensionCorrection."Validation Errors Register ID");
    end;

    procedure UpdateValidationStatusAndThrowErrorIfFailed(var DimensionCorrection: Record "Dimension Correction"; ErrorCount: Integer)
    begin
        DimensionCorrection."Validated At" := CurrentDateTime();
        DimensionCorrection."Validated Selected Entries" := ErrorCount = 0;
        DimensionCorrection.Modify();

        if ErrorCount > 0 then begin
            DimensionCorrection.SetValidateDimensionChangesText(GetValidationStatusText(DimensionCorrection, StrSubstNo(ValidationFailedErr, ErrorCount)));
            DimensionCorrection.Modify();
            Commit();
            Error(ValidationFailedErr, ErrorCount);
        end else begin
            DimensionCorrection.SetValidateDimensionChangesText(GetValidationStatusText(DimensionCorrection, ''));
            DimensionCorrection.Modify();
            Commit();
        end;
    end;

    procedure GenerateSelectedEntries(var DimensionCorrection: Record "Dimension Correction"; var TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary)
    var
        DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
        TempExcludedEntriesInteger: Record Integer temporary;
    begin
        if not GetSelectionCriteria(DimensionCorrection."Entry No.", DimCorrectSelectionCriteria) then
            exit;

        LoadExcludedEntries(DimensionCorrection, TempExcludedEntriesInteger);

        repeat
            GenerateSelectedEntries(DimCorrectSelectionCriteria, DimensionCorrection, TempDimCorrectionSetBuffer, TempExcludedEntriesInteger);
        until DimCorrectSelectionCriteria.Next() = 0;

        DimensionCorrection."Generated Selected Entries" := true;
        DimensionCorrection.Modify();
        Commit();
    end;

    local procedure LoadExcludedEntries(DimensionCorrection: Record "Dimension Correction"; var TempExcludedEntriesInteger: Record Integer temporary)
    var
        ExlcudedDimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
        GLEntry: Record "G/L Entry";
        ExcludedEntriesView: Text;
    begin
        ExlcudedDimCorrectSelectionCriteria.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        ExlcudedDimCorrectSelectionCriteria.SetRange("Filter Type", ExlcudedDimCorrectSelectionCriteria."Filter Type"::Excluded);
        if ExlcudedDimCorrectSelectionCriteria.IsEmpty() then
            exit;

        ExlcudedDimCorrectSelectionCriteria.FindSet();
        GLEntry.SetLoadFields("Entry No.");

        repeat
            ExlcudedDimCorrectSelectionCriteria.GetSelectionFilter(ExcludedEntriesView);
            GLEntry.SetView(ExcludedEntriesView);
            if not GLEntry.IsEmpty() then
                if GLEntry.FindSet() then
                    repeat
                        TempExcludedEntriesInteger.Number := GLEntry."Entry No.";
                        if TempExcludedEntriesInteger.Insert() then;
                    until GLEntry.Next() = 0;
        until ExlcudedDimCorrectSelectionCriteria.Next() = 0;
    end;

    local procedure GenerateSelectedEntries(var DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria"; var DimensionCorrection: Record "Dimension Correction"; var TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary; var TempExcludedEntriesInteger: Record Integer temporary)
    var
        TempInteger: Record Integer temporary;
        GLEntry: Record "G/L Entry";
        SelectionFilter: Text;
        CommitCounter: Integer;
    begin
        DimCorrectSelectionCriteria.GetSelectionFilter(SelectionFilter);
        if DimCorrectSelectionCriteria."Last Entry No." <> 0 then begin
            GLEntry.FilterGroup(4);
            GLEntry.SetFilter("Entry No.", '>%1', DimCorrectSelectionCriteria."Last Entry No.");
            GLEntry.FilterGroup(0);
        end;

        GLEntry.SetView(SelectionFilter);

        GLEntry.SetLoadFields("Entry No.");
        if GLEntry.IsEmpty() then
            exit;

        GLEntry.FindSet();

        TempInteger.SetCurrentKey(Number);
        TempInteger.Ascending(true);

        repeat
            if IsGLEntryForUpdate(GLEntry, TempDimCorrectionSetBuffer, DimensionCorrection."Entry No.", TempExcludedEntriesInteger) then begin
                if not TempInteger.Get(GLEntry."Entry No.") then begin
                    TempInteger.Number := GLEntry."Entry No.";
                    TempInteger.Insert();
                end;

                CommitCounter += 1;
                if (CommitCounter > GetDictionarySizeLimit()) then begin
                    WriteSelectedEntriesCriteriaToTables(TempInteger, DimensionCorrection);
                    DimCorrectSelectionCriteria."Last Entry No." := GLEntry."Entry No.";
                    TempInteger.DeleteAll();
                    CommitCounter := 0;
                end;
            end;
        until GLEntry.Next() = 0;

        if (CommitCounter > 0) then begin
            WriteSelectedEntriesCriteriaToTables(TempInteger, DimensionCorrection);
            DimCorrectSelectionCriteria."Last Entry No." := GLEntry."Entry No.";
            Commit();
        end;
    end;

    procedure IsGLEntryForUpdate(var GLEntry: Record "G/L Entry"; var TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary; DimensionCorrectionEntryNo: Integer; var TempExcludedEntriesInteger: Record Integer temporary): boolean
    begin
        if not TempDimCorrectionSetBuffer.Get(DimensionCorrectionEntryNo, GLEntry."Dimension Set ID") then
            exit(false);

        if GLEntry."Dimension Set ID" = TempDimCorrectionSetBuffer."Target Set ID" then
            exit(false);

        if TempExcludedEntriesInteger.Get(GLEntry."Entry No.") then
            exit(false);

        exit(true);
    end;

    local procedure WriteSelectedEntriesCriteriaToTables(var TempInteger: Record Integer temporary; var DimensionCorrection: Record "Dimension Correction")
    var
        StartEntryNo: Integer;
        LastEntryNo: Integer;
        AddedEntries: Integer;
    begin
        TempInteger.FindSet();
        StartEntryNo := TempInteger.Number;
        LastEntryNo := TempInteger.Number;

        repeat
            if LastEntryNo + 1 < TempInteger.Number then begin
                AddedEntries += UpdateDimCorrectionEntryLog(StartEntryNo, LastEntryNo, DimensionCorrection."Entry No.");
                StartEntryNo := TempInteger.Number;
            end;

            LastEntryNo := TempInteger.Number;
        until TempInteger.Next() = 0;

        // Add last entry
        AddedEntries += UpdateDimCorrectionEntryLog(StartEntryNo, LastEntryNo, DimensionCorrection."Entry No.");

        DimensionCorrection."Total Selected Ledger Entries" += AddedEntries;
        DimensionCorrection.Modify();
    end;

    local procedure UpdateDimCorrectionEntryLog(StartEntryNo: Integer; LastEntryNo: Integer; DimensionCorrectionEntryNo: Integer): Integer
    var
        PrevoiusDimCorrectionEntryLog: Record "Dim Correction Entry Log";
        NextDimCorrectionEntryLog: Record "Dim Correction Entry Log";
        DimCorrectionEntryLog: Record "Dim Correction Entry Log";
        PreviousExists: Boolean;
        NextExists: Boolean;
        AddedEntries: Integer;
    begin
        AddedEntries := 0;
        PrevoiusDimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", DimensionCorrectionEntryNo);
        PrevoiusDimCorrectionEntryLog.SetFilter("Start Entry No.", '<=%1', StartEntryNo);
        PrevoiusDimCorrectionEntryLog.SetFilter("End Entry No.", '>=%1', StartEntryNo - 1);
        PreviousExists := PrevoiusDimCorrectionEntryLog.FindFirst();

        NextDimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", DimensionCorrectionEntryNo);
        NextDimCorrectionEntryLog.SetFilter("Start Entry No.", '<=%1', LastEntryNo + 1);
        NextDimCorrectionEntryLog.SetFilter("End Entry No.", '>=%1', LastEntryNo);
        NextExists := NextDimCorrectionEntryLog.FindFirst();

        if PreviousExists then begin
            if NextExists then begin
                if (NextDimCorrectionEntryLog."Start Entry No." = PrevoiusDimCorrectionEntryLog."Start Entry No.") and (NextDimCorrectionEntryLog."End Entry No." = PrevoiusDimCorrectionEntryLog."End Entry No.") then
                    exit(AddedEntries);

                AddedEntries := NextDimCorrectionEntryLog."Start Entry No." - PrevoiusDimCorrectionEntryLog."End Entry No." - 1;
                PrevoiusDimCorrectionEntryLog.Rename(PrevoiusDimCorrectionEntryLog."Dimension Correction Entry No.", PrevoiusDimCorrectionEntryLog."Start Entry No.", NextDimCorrectionEntryLog."End Entry No.");
                NextDimCorrectionEntryLog.Delete();
                exit(AddedEntries);
            end;
            if PrevoiusDimCorrectionEntryLog."End Entry No." >= LastEntryNo then
                exit(AddedEntries);

            AddedEntries := LastEntryNo - PrevoiusDimCorrectionEntryLog."End Entry No.";
            PrevoiusDimCorrectionEntryLog.Rename(PrevoiusDimCorrectionEntryLog."Dimension Correction Entry No.", PrevoiusDimCorrectionEntryLog."Start Entry No.", LastEntryNo);
            exit(AddedEntries);
        end;

        if NextExists then begin
            AddedEntries := NextDimCorrectionEntryLog."Start Entry No." - StartEntryNo;
            NextDimCorrectionEntryLog.Rename(NextDimCorrectionEntryLog."Dimension Correction Entry No.", StartEntryNo, NextDimCorrectionEntryLog."End Entry No.");
            exit(AddedEntries)
        end;

        AddedEntries := LastEntryNo - StartEntryNo + 1;
        DimCorrectionEntryLog."Dimension Correction Entry No." := DimensionCorrectionEntryNo;
        DimCorrectionEntryLog."Start Entry No." := StartEntryNo;
        DimCorrectionEntryLog."End Entry No." := LastEntryNo;
        DimCorrectionEntryLog.Insert(true);
        exit(AddedEntries)
    end;

    procedure GetTargetDimCorrectionSetBuffer(var TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary; var DimensionCorrection: Record "Dimension Correction"; var GLEntry: Record "G/L Entry"): Boolean
    begin
        TempDimCorrectionSetBuffer.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        TempDimCorrectionSetBuffer.SetRange("Target Set ID", GLEntry."Dimension Set ID");
        if not TempDimCorrectionSetBuffer.FindFirst() then
            exit(false);

        if not TempDimCorrectionSetBuffer."Multiple Target Set ID" then
            exit(true);

        repeat
            if TempDimCorrectionSetBuffer.ContainsLedgerEntry(GLEntry."Entry No.") then
                exit(true);
        until TempDimCorrectionSetBuffer.Next() = 0;
        exit(false);
    end;

    procedure GenerateTargetDimensionSetIds(var DimensionCorrection: Record "Dimension Correction")
    var
        DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
        DimCorrectionSetBuffer: Record "Dim Correction Set Buffer";
        SameTargetDimCorrectionSetBuffer: Record "Dim Correction Set Buffer";
        TempDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimensionSetIDs: List of [Integer];
        DimensionSetID: Integer;
        NewDimensionSetID: Integer;
        CommitCounter: Integer;
    begin
        if DimensionCorrection."Generated Set IDs" then
            exit;

        if not GetSelectionCriteria(DimensionCorrection."Entry No.", DimCorrectSelectionCriteria) then
            exit;

        if not GetDimCorrectionChanges(DimensionCorrection."Entry No.", TempDimCorrectionChange) then
            exit;

        DimensionCorrection."Started Correction" := true;
        DimensionCorrection.Modify();

        CommitCounter := 0;
        repeat
            DimCorrectSelectionCriteria.GetDimensionSetIds(DimensionSetIDs);
            foreach DimensionSetID in DimensionSetIDs do
                if not DimCorrectionSetBuffer.Get(DimensionCorrection."Entry No.", DimensionSetID) then
                    if TransformDimensionSet(DimensionSetID, TempDimCorrectionChange, NewDimensionSetID) then
                        if (NewDimensionSetID <> DimensionSetID) then begin
                            DimCorrectionSetBuffer."Dimension Correction Entry No." := DimensionCorrection."Entry No.";
                            DimCorrectionSetBuffer."Dimension Set ID" := DimensionSetID;
                            DimCorrectionSetBuffer."Target Set ID" := NewDimensionSetID;
                            SameTargetDimCorrectionSetBuffer.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
                            SameTargetDimCorrectionSetBuffer.SetRange("Target Set ID", DimCorrectionSetBuffer."Target Set ID");
                            if SameTargetDimCorrectionSetBuffer.FindFirst() then begin
                                DimCorrectionSetBuffer."Multiple Target Set ID" := true;
                                if SameTargetDimCorrectionSetBuffer."Multiple Target Set ID" = false then begin
                                    SameTargetDimCorrectionSetBuffer."Multiple Target Set ID" := true;
                                    SameTargetDimCorrectionSetBuffer.Modify();
                                end;
                            end;

                            DimCorrectionSetBuffer.Insert();
                            IncrementAndCommitIfNeeded(CommitCounter);
                        end;
        until DimCorrectSelectionCriteria.Next() = 0;

        DimensionCorrection.GetBySystemId(DimensionCorrection.SystemId);
        DimensionCorrection."Generated Set IDs" := true;
        DimensionCorrection.Modify();
    end;

    procedure CreateCorrectionFromGLRegister(var GLRegister: Record "G/L Register"; var DimensionCorrection: Record "Dimension Correction")
    var
        LastDimensionCorrection: Record "Dimension Correction";
        DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
        GLEntry: Record "G/L Entry";
        GLEntryRecordRef: RecordRef;
        NewEntryNo: Integer;
    begin
        GLRegister.FindSet();

        NewEntryNo := 1;
        if LastDimensionCorrection.FindLast() then
            NewEntryNo := LastDimensionCorrection."Entry No." + 1;

        DimensionCorrection."Entry No." := NewEntryNo;
        DimensionCorrection.Insert(true);

        repeat
            GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
            TransferSelectionFilterToRecordRef(GLEntry, GLEntryRecordRef);
            InsertNewDimCorrectSelectionCriteria(GLEntryRecordRef, DimCorrectSelectionCriteria."Filter Type"::Manual, DimCorrectSelectionCriteria, NewEntryNo);
            Clear(DimCorrectSelectionCriteria);
        until GLRegister.Next() = 0;

        ReloadDimensionChangesTable(NewEntryNo);
    end;

    procedure CreateCorrectionFromSelection(var GLEntry: Record "G/L Entry"; var DimensionCorrection: Record "Dimension Correction")
    var
        LastDimensionCorrection: Record "Dimension Correction";
        DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
        GLEntryRecordRef: RecordRef;
        NewEntryNo: Integer;
    begin
        NewEntryNo := 1;
        if LastDimensionCorrection.FindLast() then
            NewEntryNo := LastDimensionCorrection."Entry No." + 1;

        DimensionCorrection."Entry No." := NewEntryNo;
        DimensionCorrection.Insert(true);

        TransferSelectionFilterToRecordRef(GLEntry, GLEntryRecordRef);
        InsertNewDimCorrectSelectionCriteria(GLEntryRecordRef, DimCorrectSelectionCriteria."Filter Type"::Manual, DimCorrectSelectionCriteria, NewEntryNo);
        ReloadDimensionChangesTable(NewEntryNo);
    end;

    procedure CreateCorrectionFromFilter(var GLEntry: Record "G/L Entry"; var DimensionCorrection: Record "Dimension Correction")
    var
        LastDimensionCorrection: Record "Dimension Correction";
        DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
        GLEntryRecordRef: RecordRef;
        NewEntryNo: Integer;
    begin
        NewEntryNo := 1;
        if LastDimensionCorrection.FindLast() then
            NewEntryNo := LastDimensionCorrection."Entry No." + 1;

        DimensionCorrection."Entry No." := NewEntryNo;
        DimensionCorrection.Insert(true);

        GLEntryRecordRef.GetTable(GLEntry);
        InsertNewDimCorrectSelectionCriteria(GLEntryRecordRef, DimCorrectSelectionCriteria."Filter Type"::"Custom Filter", DimCorrectSelectionCriteria, NewEntryNo);
        ReloadDimensionChangesTable(NewEntryNo);
    end;

    procedure InsertNewDimCorrectSelectionCriteria(var MainRecordRef: RecordRef; DimCorrectSelectionCriteriaFilterType: Option; var DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria"; DimensionCorrectionEntryNo: Integer)
    var
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
        DimensionSetIds: List of [Integer];
    begin
        DimCorrectSelectionCriteria."Dimension Correction Entry No." := DimensionCorrectionEntryNo;
        DimCorrectSelectionCriteria."Filter Type" := DimCorrectSelectionCriteriaFilterType;
        DimCorrectSelectionCriteria.SetSelectionFilter(MainRecordRef);
        DimCorrectSelectionCriteria.Insert(true);
        DimensionCorrectionMgt.CalculateDimensionSetIds(DimensionSetIds, DimCorrectSelectionCriteria);
        DimCorrectSelectionCriteria.SetDimensionSetIds(DimensionSetIds);
        DimCorrectSelectionCriteria.Modify(true);
    end;

    procedure GetSelectedDimensionSetIDsFilter(var TempDimensionSetEntry: Record "Dimension Set Entry" temporary): Text
    var
        TempFoundDimensionSetIDInteger: Record "Integer" temporary;
        SelectedDimensionSetFilter: Text;
        LastAddedNumber: Integer;
        CurrentNumber: Integer;
    begin
        GetSelectedDimensionSetIDs(TempDimensionSetEntry, TempFoundDimensionSetIDInteger);
        TempFoundDimensionSetIDInteger.SetCurrentKey(Number);
        TempFoundDimensionSetIDInteger.Ascending(true);
        if not TempFoundDimensionSetIDInteger.FindSet() then
            exit('');

        LastAddedNumber := TempFoundDimensionSetIDInteger.Number;
        SelectedDimensionSetFilter += Format(LastAddedNumber);
        CurrentNumber := LastAddedNumber;

        repeat
            if TempFoundDimensionSetIDInteger.Number > CurrentNumber + 1 then begin
                if LastAddedNumber <> CurrentNumber then
                    SelectedDimensionSetFilter += '..' + Format(CurrentNumber) + '|' + Format(TempFoundDimensionSetIDInteger.Number)
                else
                    SelectedDimensionSetFilter += '|' + Format(TempFoundDimensionSetIDInteger.Number);

                LastAddedNumber := TempFoundDimensionSetIDInteger.Number;
            end;
            CurrentNumber := TempFoundDimensionSetIDInteger.Number;
        until TempFoundDimensionSetIDInteger.Next() = 0;

        if LastAddedNumber <> CurrentNumber then
            SelectedDimensionSetFilter += '..' + Format(CurrentNumber);

        exit(SelectedDimensionSetFilter);
    end;

    procedure GetSelectedDimensionSetIDs(var TempDimensionSetEntry: Record "Dimension Set Entry" temporary; var TempFoundDimensionSetIDInteger: Record "Integer" temporary)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        if not TempDimensionSetEntry.FindFirst() then
            exit;

        TempFoundDimensionSetIDInteger.SetCurrentKey(Number);
        TempFoundDimensionSetIDInteger.Ascending(true);

        DimensionSetEntry.SetCurrentKey("Dimension Set ID");
        DimensionSetEntry.Ascending(true);

        repeat
            DimensionSetEntry.SetRange("Dimension Code", TempDimensionSetEntry."Dimension Code");
            if TempDimensionSetEntry."Dimension Value Code" <> '' then
                DimensionSetEntry.SetFilter("Dimension Value Code", TempDimensionSetEntry."Dimension Value Code");
            if DimensionSetEntry.FindFirst() then begin
                TempFoundDimensionSetIDInteger.Number := DimensionSetEntry."Dimension Set ID";
                TempFoundDimensionSetIDInteger.Insert();
                TempFoundDimensionSetIDInteger.Mark(true);
            end;
            DimensionSetEntry.SetFilter("Dimension Set ID", '>%1', DimensionSetEntry."Dimension Set ID");
        until DimensionSetEntry.Next() = 0;

        TempFoundDimensionSetIDInteger.MarkedOnly(true);

        if not TempFoundDimensionSetIDInteger.FindFirst() then
            exit;

        if TempDimensionSetEntry.Next() = 0 then
            exit;

        repeat
            repeat
                DimensionSetEntry.SetRange("Dimension Set ID", TempFoundDimensionSetIDInteger.Number);
                DimensionSetEntry.SetRange("Dimension Code", TempDimensionSetEntry."Dimension Code");
                if TempDimensionSetEntry."Dimension Value Code" <> '' then
                    DimensionSetEntry.SetRange("Dimension Value Code", TempDimensionSetEntry."Dimension Value Code");
                if DimensionSetEntry.IsEmpty() then
                    TempFoundDimensionSetIDInteger.Mark(false);
            until TempFoundDimensionSetIDInteger.Next() = 0;

            if not TempFoundDimensionSetIDInteger.FindFirst() then
                exit;
        until TempDimensionSetEntry.Next() = 0;
    end;

    local procedure TransformDimensionSet(DimensionSetID: Integer; var TempDimCorrectionChange: Record "Dim Correction Change" temporary; var NewDimensionSetID: Integer): Boolean
    var
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        TempNewDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimensionManagement: Codeunit "DimensionManagement";
        Changed: Boolean;
        EntryExist: Boolean;
    begin
        DimensionManagement.GetDimensionSet(TempDimensionSetEntry, DimensionSetId);

        TempDimCorrectionChange.Reset();
        if not TempDimCorrectionChange.FindFirst() then
            exit(false);

        repeat
            case TempDimCorrectionChange."Change Type" of
                TempDimCorrectionChange."Change Type"::Add,
                TempDimCorrectionChange."Change Type"::Change:
                    begin
                        EntryExist := TempDimensionSetEntry.Get(DimensionSetID, TempDimCorrectionChange."Dimension Code");
                        TempDimensionSetEntry."Dimension Code" := TempDimCorrectionChange."Dimension Code";
                        TempDimensionSetEntry."Dimension Value ID" := TempDimCorrectionChange."New Value ID";
                        TempDimensionSetEntry."Dimension Value Code" := CopyStr(TempDimCorrectionChange."New Value", 1, MaxStrLen(TempDimensionSetEntry."Dimension Value Code"));
                        if EntryExist then
                            TempDimensionSetEntry.Modify()
                        else
                            TempDimensionSetEntry.Insert();

                        Changed := true;
                    end;
                TempDimCorrectionChange."Change Type"::Remove:
                    if TempDimensionSetEntry.Get(DimensionSetID, TempDimCorrectionChange."Dimension Code") then begin
                        TempDimensionSetEntry.Delete();
                        Changed := true;
                    end;
            end;
        until TempDimCorrectionChange.Next() = 0;

        if Changed then
            if TempDimensionSetEntry.FindFirst() then begin
                repeat
                    TempNewDimensionSetEntry.TransferFields(TempDimensionSetEntry, true);
                    TempNewDimensionSetEntry."Dimension Set ID" := 0;
                    OnTransformDimensionSetOnBeforeInsertTempNewDimensionSetEntry(TempNewDimensionSetEntry);
                    TempNewDimensionSetEntry.Insert(true);
                until TempDimensionSetEntry.Next() = 0;

                NewDimensionSetID := DimensionManagement.GetDimensionSetID(TempNewDimensionSetEntry);
            end;

        exit(Changed);
    end;

    procedure TransferSelectionFilterToRecordRef(var GLEntry: Record "G/L Entry"; var GLEntryRecordRef: RecordRef)
    var
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        EntryNoFieldRef: FieldRef;
        FilteredText: Text;
    begin
        GLEntryRecordRef.GetTable(GLEntry);
        FilteredText := SelectionFilterManagement.GetSelectionFilter(GLEntryRecordRef, GLEntry.FieldNo("Entry No."));
        GLEntryRecordRef.ClearMarks();
        EntryNoFieldRef := GLEntryRecordRef.Field(GLEntry.FieldNo("Entry No."));
        EntryNoFieldRef.SetFilter(FilteredText);
    end;

    procedure GetDimCorrectionChanges(DimensionCorrectionEntryNo: Integer; var TempDimCorrectionChange: Record "Dim Correction Change" temporary): Boolean
    var
        DimCorrectionChange: Record "Dim Correction Change";
    begin
        DimCorrectionChange.SetRange("Dimension Correction Entry No.", DimensionCorrectionEntryNo);
        DimCorrectionChange.SetFilter("Change Type", '<>%1', DimCorrectionChange."Change Type"::"No Change");
        if not DimCorrectionChange.FindSet() then
            exit(false);

        repeat
            TempDimCorrectionChange.TransferFields(DimCorrectionChange, true);
            TempDimCorrectionChange.Insert();
        until DimCorrectionChange.Next() = 0;

        exit(true);
    end;

    procedure GetSelectionCriteria(DimensionCorrectionEntryNo: Integer; var DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria"): Boolean
    begin
        DimCorrectSelectionCriteria.SetRange("Dimension Correction Entry No.", DimensionCorrectionEntryNo);
        DimCorrectSelectionCriteria.SetFilter("Filter Type", '<>%1', DimCorrectSelectionCriteria."Filter Type"::Excluded);
        exit(DimCorrectSelectionCriteria.FindSet());
    end;

    procedure CalculateDimensionSetIds(var DimensionSetIds: List of [Integer]; var DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria")
    var
        GLEntry: Record "G/L Entry";
        SelectionFilter: Text;
    begin
        Clear(DimensionSetIds);
        DimCorrectSelectionCriteria.GetSelectionFilter(SelectionFilter);
        GLEntry.FilterGroup(2);
        GLEntry.SetView(SelectionFilter);
        GLEntry.FilterGroup(0);
        GLEntry.SetCurrentKey("Dimension Set ID", "Entry No.");
        GLEntry.Ascending(true);
        if not GLEntry.FindFirst() then
            exit;

        repeat
            if not IsEntryExclued(GLEntry, DimCorrectSelectionCriteria."Dimension Correction Entry No.") then begin
                DimensionSetIds.Add(GLEntry."Dimension Set ID");
                GLEntry.SetFilter("Dimension Set ID", '>%1', GLEntry."Dimension Set ID");
            end;
        until GLEntry.Next() = 0;
    end;

    procedure ReloadDimensionChangesTable(DimCorrectionEntryNo: Integer)
    var
        DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
        DimCorrectionChange: Record "Dim Correction Change";
        DimensionCodeValue: Dictionary of [Code[20], List of [Integer]];
    begin
        DimCorrectionChange.SetRange("Dimension Correction Entry No.", DimCorrectionEntryNo);
        DimCorrectionChange.SetFilter("Change Type", '<>%1', DimCorrectionChange."Change Type"::"No Change");
        if not DimCorrectionChange.IsEmpty() then
            Message(ChangesWereResetMsg);

        DimCorrectionChange.SetRange("Change Type");
        DimCorrectionChange.DeleteAll(true);

        DimCorrectSelectionCriteria.SetRange("Dimension Correction Entry No.", DimCorrectionEntryNo);
        if not DimCorrectSelectionCriteria.FindSet() then
            exit;

        GetDimensionCodeValues(DimensionCodeValue, DimCorrectSelectionCriteria);
        UpdateDimCorrectionChanges(DimensionCodeValue, DimCorrectionEntryNo);
    end;

    procedure LoadTempDimCorrectionSetBuffer(DimensionCorrectionEntryNo: Integer; var TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary): Boolean
    var
        DimCorrectionSetBuffer: Record "Dim Correction Set Buffer";
    begin
        DimCorrectionSetBuffer.SetRange("Dimension Correction Entry No.", DimensionCorrectionEntryNo);
        if not DimCorrectionSetBuffer.FindSet() then
            exit(false);

        repeat
            TempDimCorrectionSetBuffer.TransferFields(DimCorrectionSetBuffer, true);
            TempDimCorrectionSetBuffer.Insert();
            if DimCorrectionSetBuffer."Multiple Target Set ID" then begin
                TempDimCorrectionSetBuffer.SetLedgerEntries(DimCorrectionSetBuffer.GetSetLedgerEntries());
                TempDimCorrectionSetBuffer.Modify();
            end;
        until DimCorrectionSetBuffer.Next() = 0;

        exit(true);
    end;

    procedure ScheduleRunJob(var DimensionCorrection: Record "Dimension Correction"): Boolean

    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CreateUniqueJobQueue(Codeunit::"Dim Correction Run", DimensionCorrection, JobQueueEntry);
        Commit();

        if ScheduleJobViaUI(JobQueueEntry, '') then begin
            SetStatusInProgress(DimensionCorrection);
            DimensionCorrection."Last Job Queue Entry ID" := JobQueueEntry.ID;
            DimensionCorrection.Modify();
            exit(true);
        end;

        exit(false);
    end;

    procedure ScheduleUndoJob(var DimensionCorrection: Record "Dimension Correction"): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CreateUniqueJobQueue(Codeunit::"Dimension Correction Undo", DimensionCorrection, JobQueueEntry);
        Commit();
        if ScheduleJobViaUI(JobQueueEntry, UndoDimensionCorrectionLbl) then begin
            SetUndoStatusInProgress(DimensionCorrection);
            DimensionCorrection."Last Job Queue Entry ID" := JobQueueEntry.ID;
            DimensionCorrection.Modify();
            exit(true);
        end;
        exit(false);
    end;

    procedure ScheduleValidationJob(var DimensionCorrection: Record "Dimension Correction"): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CreateUniqueJobQueue(Codeunit::"Dim Correction Validate", DimensionCorrection, JobQueueEntry);
        Commit();
        if ScheduleJobViaUI(JobQueueEntry, ValidateDimensionCorrectionLbl) then begin
            DeleteValidationErrors(DimensionCorrection);
            ClearValidationFields(DimensionCorrection);
            SetValidatingStatusInProgress(DimensionCorrection);
            DimensionCorrection."Last Job Queue Entry ID" := JobQueueEntry.ID;
            DimensionCorrection.Modify();
            exit(true);
        end else
            exit(false);
    end;

    procedure ScheduleUpdateAnalysisViews(var DimensionCorrection: Record "Dimension Correction"): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CreateUniqueJobQueue(Codeunit::"Dim Corr Analysis View", DimensionCorrection, JobQueueEntry);
        Commit();
        if GuiAllowed then
            exit(ScheduleJobViaUI(JobQueueEntry, UpdateAnalysisViewsLbl));

        JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
        exit(true);
    end;

    local procedure ScheduleJobViaUI(var JobQueueEntry: Record "Job Queue Entry"; NewCaption: Text): Boolean
    var
        DimCorrectionSchedule: Page "Dim Correction Schedule";
    begin
        if NewCaption <> '' then
            DimCorrectionSchedule.SetNewCaption(NewCaption);

        DimCorrectionSchedule.SetRecord(JobQueueEntry);
        if DimCorrectionSchedule.RunModal() in [Action::Cancel, Action::LookupCancel] then
            exit(false);

        exit(true);
    end;

    procedure UpdateStatus(var DimensionCorrection: Record "Dimension Correction")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not (DimensionCorrection.Status in [DimensionCorrection.Status::"In Process", DimensionCorrection.Status::"Undo in Process", DimensionCorrection.Status::"Validaton in Process"]) then
            exit;

        if not JobQueueEntry.Get(DimensionCorrection."Last Job Queue Entry ID") then begin
            DimensionCorrection.Status := DimensionCorrection.Status::Failed;
            DimensionCorrection.Modify();
            exit;
        end;

        if JobQueueEntry.Status = JobQueueEntry.Status::Error then begin
            DimensionCorrection.Status := DimensionCorrection.Status::Failed;
            DimensionCorrection."Error Message" := JobQueueEntry."Error Message";
            DimensionCorrection.Modify();
            exit;
        end;

        if JobQueueEntry.Status = JobQueueEntry.Status::Finished then begin
            DimensionCorrection.Status := DimensionCorrection.Status::Completed;
            Clear(DimensionCorrection."Error Message");
            DimensionCorrection.Modify();
            exit;
        end;
    end;


    procedure UpdateAnalysisViewStatus(var DimensionCorrection: Record "Dimension Correction")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not (DimensionCorrection."Update Analysis Views Status" = DimensionCorrection."Update Analysis Views Status"::"In Process") then
            exit;

        if not JobQueueEntry.Get(DimensionCorrection."Update Analysis View Job ID") then begin
            DimensionCorrection."Update Analysis Views Status" := DimensionCorrection."Update Analysis Views Status"::Failed;
            DimensionCorrection.Modify();
            exit;
        end;

        if JobQueueEntry.Status = JobQueueEntry.Status::Error then begin
            DimensionCorrection."Update Analysis Views Status" := DimensionCorrection."Update Analysis Views Status"::Failed;
            DimensionCorrection.SetUpdateAnalysisViewErrorMessage(JobQueueEntry."Error Message");
            DimensionCorrection.Modify();
            exit;
        end;

        if JobQueueEntry.Status = JobQueueEntry.Status::Finished then begin
            DimensionCorrection."Update Analysis Views Status" := DimensionCorrection."Update Analysis Views Status"::Completed;
            Clear(DimensionCorrection."Update Analysis Views Error");
            DimensionCorrection.Modify();
            exit;
        end;
    end;

    local procedure CreateUniqueJobQueue(CodeunitID: Integer; var DimensionCorrection: Record "Dimension Correction"; var JobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueExist: Boolean;
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CodeunitID);

        JobQueueExist := JobQueueEntry.FindFirst();
        if JobQueueExist then begin
            if JobQueueEntry.Status = JobQueueEntry.Status::"In Process" then
                Error(JobQueueIsRunningErr);

            JobQueueEntry.Delete(true);
            Clear(JobQueueEntry);
        end;

        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CodeunitID;
        JobQueueEntry."Maximum No. of Attempts to Run" := 1;
        JobQueueEntry."Recurring Job" := false;
        JobQueueEntry."Record ID to Process" := DimensionCorrection.RecordId;
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry."Job Queue Category Code" := JobQueueCategoryCodeTxt;
        Clear(JobQueueEntry."Error Message");
        Clear(JobQueueEntry."Error Message Register Id");
        JobQueueEntry.Description := CopyStr(StrSubstNo(JobQueueEntryDescTxt, DimensionCorrection."Entry No."), 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry.Insert(true);
    end;

    procedure VerifyCanStartJob(DimensionCorrection: Record "Dimension Correction")
    var
        InProgressDimensionCorrection: Record "Dimension Correction";
    begin
        if not DimensionCorrection.Completed then
            if DimensionCorrection.Status = DimensionCorrection.Status::"In Process" then
                Error(JobAlreadyInProgressErr);

        if DimensionCorrection.Completed then
            if DimensionCorrection.Status = DimensionCorrection.Status::"Undo In Process" then
                Error(JobAlreadyInProgressErr);

        InProgressDimensionCorrection.SetFilter(Status, '%1|%2|%3', DimensionCorrection.Status::"In Process", DimensionCorrection.Status::"Undo in Process", DimensionCorrection.Status::"Validaton in Process");
        InProgressDimensionCorrection.SetLoadFields("Entry No.", Status);
        if InProgressDimensionCorrection.FindFirst() then
            UpdateStatus(InProgressDimensionCorrection);

        if InProgressDimensionCorrection.FindFirst() then
            Error(AnotherJobAlreadyInProgressErr, InProgressDimensionCorrection."Entry No.");
    end;

    procedure SetStatusInProgress(var DimensionCorrection: Record "Dimension Correction")
    begin
        DimensionCorrection.Status := DimensionCorrection.Status::"In Process";
        Clear(DimensionCorrection."Error Message");
        DeleteValidationErrors(DimensionCorrection);

        if DimensionCorrection."Validated At" <> 0DT then
            ClearValidationFields(DimensionCorrection);

        DimensionCorrection.Modify();
        Commit();
    end;

    procedure SetUndoStatusInProgress(var DimensionCorrection: Record "Dimension Correction")
    begin
        DimensionCorrection.Status := DimensionCorrection.Status::"Undo in Process";
        Clear(DimensionCorrection."Error Message");
        DeleteValidationErrors(DimensionCorrection);
        if DimensionCorrection."Validated At" <> 0DT then
            ClearValidationFields(DimensionCorrection);

        DimensionCorrection.Modify();
        Commit();
    end;

    procedure SetValidatingStatusInProgress(var DimensionCorrection: Record "Dimension Correction")
    begin
        DimensionCorrection.Status := DimensionCorrection.Status::"Validaton in Process";
        Clear(DimensionCorrection."Error Message");
        Clear(DimensionCorrection."Last Validated Entry No.");
        DeleteValidationErrors(DimensionCorrection);
        DimensionCorrection.Modify();
        Commit();
    end;

    procedure GetValidationStatusText(var DimensionCorrection: Record "Dimension Correction"; ErrorMessage: Text): Text
    begin
        if DimensionCorrection."Validated At" = 0DT then
            exit('');

        if DimensionCorrection."Validated Selected Entries" then begin
            if DimensionCorrection.Completed then
                exit(StrSubstNo(ValidationUndoPassedLbl, DimensionCorrection."Validated At"));

            exit(StrSubstNo(ValidationDraftPassedLbl, DimensionCorrection."Validated At"));
        end;

        exit(StrSubstNo(ValidationFailedLbl, DimensionCorrection."Validated At", ErrorMessage));
    end;

    procedure CopyToDraft(var DimensionCorrection: Record "Dimension Correction"; var NewDimensionCorrection: Record "Dimension Correction")
    var
        DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
        NewDimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
        SelectionFilter: Text;
        DimensionSetIds: List of [Integer];
    begin
        NewDimensionCorrection.Description := DimensionCorrection.Description;
        NewDimensionCorrection.Insert(true);

        DimCorrectSelectionCriteria.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        if not DimCorrectSelectionCriteria.FindSet() then
            exit;

        repeat
            Clear(NewDimCorrectSelectionCriteria);
            NewDimCorrectSelectionCriteria.TransferFields(DimCorrectSelectionCriteria);
            NewDimCorrectSelectionCriteria."Dimension Correction Entry No." := NewDimensionCorrection."Entry No.";
            DimCorrectSelectionCriteria.GetSelectionFilter(SelectionFilter);
            NewDimCorrectSelectionCriteria.SetSelectionFilter(SelectionFilter);
            NewDimCorrectSelectionCriteria."Entry No." := 0;
            NewDimCorrectSelectionCriteria."Last Entry No." := 0;
            NewDimCorrectSelectionCriteria.Insert(true);

            CalculateDimensionSetIds(DimensionSetIds, NewDimCorrectSelectionCriteria);
            NewDimCorrectSelectionCriteria.SetDimensionSetIds(DimensionSetIds);
            NewDimCorrectSelectionCriteria.Modify(true);
        until DimCorrectSelectionCriteria.Next() = 0;

        ReloadDimensionChangesTable(NewDimensionCorrection."Entry No.");
    end;

    local procedure ClearValidationFields(var DimensionCorrection: Record "Dimension Correction")
    begin
        Clear(DimensionCorrection."Validated At");
        Clear(DimensionCorrection."Validated Selected Entries");
        Clear(DimensionCorrection."Validation Errors Register ID");
        Clear(DimensionCorrection."Last Validated Entry No.");
        Clear(DimensionCorrection."Error Message");
        Clear(DimensionCorrection."Validation Message");
    end;

    local procedure GetDimensionCodeValues(var DimensionCodeValue: Dictionary of [Code[20], List of [Integer]]; var DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria")
    var
        DimensionSetIdList: List of [Integer];
        DimensionSetId: Integer;
        ProcessedDimensionSetIds: List of [Integer];
    begin
        if not DimCorrectSelectionCriteria.FindSet() then
            exit;

        repeat
            DimCorrectSelectionCriteria.GetDimensionSetIds(DimensionSetIdList);

            foreach DimensionSetId in DimensionSetIdList do
                if not ProcessedDimensionSetIds.Contains(DimensionSetId) then begin
                    AddDimensionSetIDToDictionary(DimensionSetId, DimensionCodeValue);
                    ProcessedDimensionSetIds.Add(DimensionSetId);
                end;
        until DimCorrectSelectionCriteria.Next() = 0;
    end;

    local procedure AddDimensionSetIDToDictionary(DimensionsetId: Integer; var DimensionCodeValue: Dictionary of [Code[20], List of [Integer]])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionValues: List of [Integer];
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetId);
        if DimensionSetEntry.FindSet() then
            repeat
                Clear(DimensionValues);
                if not DimensionCodeValue.ContainsKey(DimensionSetEntry."Dimension Code") then
                    DimensionCodeValue.Add(DimensionSetEntry."Dimension Code", DimensionValues)
                else
                    DimensionCodeValue.Get(DimensionSetEntry."Dimension Code", DimensionValues);

                if not DimensionValues.Contains(DimensionSetEntry."Dimension Value ID") then
                    DimensionValues.Add(DimensionSetEntry."Dimension Value ID");
            until DimensionSetEntry.Next() = 0;
    end;

    local procedure UpdateDimCorrectionChanges(var DimensionCodeValue: Dictionary of [Code[20], List of [Integer]]; DimensionCorrectionEntryNo: Integer): Boolean
    var
        DimCorrectionChange: Record "Dim Correction Change";
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionCode: Code[20];
        DimensionValues: List of [Integer];
        EntryExists: Boolean;
    begin
        if DimensionCodeValue.Keys().Count() = 0 then
            exit;

        foreach DimensionCode in DimensionCodeValue.Keys() do begin
            DimensionValues := DimensionCodeValue.Get(DimensionCode);

            Clear(DimCorrectionChange);
            EntryExists := DimCorrectionChange.Get(DimensionCorrectionEntryNo, DimensionCode);
            DimCorrectionChange."Dimension Correction Entry No." := DimensionCorrectionEntryNo;
            DimCorrectionChange."Dimension Code" := DimensionCode;
            DimCorrectionChange."Dimension Value Count" := DimensionValues.Count();
            DimCorrectionChange.SetDimensionValues(DimensionValues);
            if DimCorrectionChange."Dimension Value Count" = 1 then begin
                DimensionSetEntry.SetRange("Dimension Value ID", DimensionValues.Get(1));
                if DimensionSetEntry.FindFirst() then
                    DimCorrectionChange."Dimension Value" := DimensionSetEntry."Dimension Value Code"
                else
                    DimCorrectionChange."Dimension Value" := Format(DimensionValues.Get(1));
            end;

            if EntryExists then
                DimCorrectionChange.Modify(true)
            else
                DimCorrectionChange.Insert(true);
        end;
    end;

    procedure IsEntryExclued(var GLEntry: Record "G/L Entry"; DimensionCorrectionEntryNo: Integer): Boolean
    var
        ExcludedDimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
    begin
        ExcludedDimCorrectSelectionCriteria.SetRange("Dimension Correction Entry No.", DimensionCorrectionEntryNo);
        ExcludedDimCorrectSelectionCriteria.SetRange("Filter Type", ExcludedDimCorrectSelectionCriteria."Filter Type"::Excluded);
        exit(IsEntryExclued(GLEntry, ExcludedDimCorrectSelectionCriteria));
    end;

    procedure IsEntryExclued(var GLEntry: Record "G/L Entry"; var ExcludedDimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria"): Boolean
    var
        TempGLEntry: Record "G/L Entry" temporary;
        SelectionFilter: Text;
    begin
        if not ExcludedDimCorrectSelectionCriteria.FindSet() then
            exit;

        TempGLEntry.Copy(GLEntry);
        TempGLEntry.Insert();
        repeat
            ExcludedDimCorrectSelectionCriteria.GetSelectionFilter(SelectionFilter);
            TempGLEntry.SetView(SelectionFilter);
            if not TempGLEntry.IsEmpty() then
                exit(true);
        until ExcludedDimCorrectSelectionCriteria.Next() = 0;

        exit(false);
    end;

    procedure IncrementAndCommitIfNeeded(var Counter: Integer)
    begin
        Counter += 1;
        if Counter >= GetCommitCount() then begin
            Commit();
            Session.LogMessage('0000EHT', StrSubstNo(CommitingTelemetryLbl, GetCommitCount()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
            Counter := 0;
        end;
    end;

    local procedure GetDictionarySizeLimit(): Integer
    begin
        exit(100000);
    end;

    procedure GetMaximumNumberOfValidationErrors(): Integer
    begin
        exit(50000);
    end;

    procedure GetCommitCount(): Integer;
    var
        Handled: Boolean;
        CommitCount: Integer;
    begin
        OnGetCommitCount(Handled, CommitCount);
        if Handled then
            exit(CommitCount);

        exit(1000);
    end;

    procedure GetPreviewGLEntriesLimit(): Integer
    var
        Handled: Boolean;
        PreviewCount: Integer;
    begin
        OnGetPreviewGLEntriesLimit(Handled, PreviewCount);
        if Handled then
            exit(PreviewCount);

        exit(20000);
    end;

    procedure GetFilterConditionsLimit(): Integer;
    var
        Handled: Boolean;
        FilterCount: Integer;
    begin
        OnGetFilterCount(Handled, FilterCount);
        if Handled then
            exit(FilterCount);

        exit(2000);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterFinalizeRun', '', false, false)]
    local procedure HandleJobQueueFailures(JobQueueEntry: Record "Job Queue Entry")
    var
        DimensionCorrection: Record "Dimension Correction";
        ErrorMessage: Record "Error Message";
        LastErrorMessage: Text[2048];
    begin
        if JobQueueEntry."Error Message" = '' then
            exit;

        if not DimensionCorrection.Get(JobQueueEntry."Record ID to Process") then
            exit;

        DimensionCorrection."Validation Errors Register ID" := JobQueueEntry."Error Message Register Id";

        if not IsNullGuid(JobQueueEntry."Error Message Register Id") then begin
            ErrorMessage.SetRange("Register ID", DimensionCorrection."Validation Errors Register ID");
            if ErrorMessage.FindLast() then
                LastErrorMessage := ErrorMessage."Message"
            else
                LastErrorMessage := JobQueueEntry."Error Message";
        end;

        if (JobQueueEntry."Object Type to Run" <> JobQueueEntry."Object Type to Run"::Codeunit) then
            exit;

        if not (JobQueueEntry."Object ID to Run" in [Codeunit::"Dim Correction Run", Codeunit::"Dimension Correction Undo", Codeunit::"Dim Corr Analysis View", Codeunit::"Dim Correction Validate"]) then
            exit;

        if JobQueueEntry."Object ID to Run" in [Codeunit::"Dim Correction Run", Codeunit::"Dimension Correction Undo"] then begin
            DimensionCorrection.Status := DimensionCorrection.Status::Failed;
            DimensionCorrection."Error Message" := LastErrorMessage;
            DimensionCorrection.Modify(true);
            exit;
        end;

        if JobQueueEntry."Object Type to Run" = Codeunit::"Dim Corr Analysis View" then begin
            DimensionCorrection."Update Analysis Views Status" := DimensionCorrection."Update Analysis Views Status"::Failed;
            DimensionCorrection.SetUpdateAnalysisViewErrorMessage(LastErrorMessage);
            DimensionCorrection.Modify();
            exit;
        end;

        if JobQueueEntry."Object ID to Run" = Codeunit::"Dim Correction Validate" then begin
            if DimensionCorrection.Status = DimensionCorrection.Status::"Validaton in Process" then
                if DimensionCorrection.Completed then
                    DimensionCorrection.Status := DimensionCorrection.Status::Completed
                else
                    DimensionCorrection.Status := DimensionCorrection.Status::Draft;

            DimensionCorrection."Validated Selected Entries" := false;
            DimensionCorrection."Validated At" := CurrentDateTime();
            DimensionCorrection.SetValidateDimensionChangesText(GetValidationStatusText(DimensionCorrection, LastErrorMessage));
            DimensionCorrection.Modify();
        end;
    end;

    procedure SetUpdateAnalysisViewsCompleted(var DimensionCorrection: Record "Dimension Correction")
    begin
        DimensionCorrection."Update Analysis Views Status" := DimensionCorrection."Update Analysis Views Status"::Completed;
        Clear(DimensionCorrection."Update Analysis Views Error");
        DimensionCorrection.Modify();
    end;

    procedure ShowNotificationUpdateCashFlowAccounting()
    var
        MyNotifications: Record "My Notifications";
        CostAccountingSetup: Record "Cost Accounting Setup";
        ShowUpdateCostAccountingManually: Notification;
    begin
        if not CostAccountingSetup.Get() then
            exit;

        if not CostAccountingSetup."Auto Transfer from G/L" then
            exit;

        if MyNotifications.Get(UserId, GetUpdateCostAccountingNotificationID()) then
            if not MyNotifications.Enabled then
                exit;

        ShowUpdateCostAccountingManually.Id := GetUpdateCostAccountingNotificationID();
        if ShowUpdateCostAccountingManually.Recall() then;
        ShowUpdateCostAccountingManually.Message := UpdateCostAccountingManuallyMsg;
        ShowUpdateCostAccountingManually.Scope := NOTIFICATIONSCOPE::LocalScope;
        ShowUpdateCostAccountingManually.AddAction(DontShowAgainTxt, CODEUNIT::"Dimension Correction Mgt", 'DontShowAgainUpdateCostAccounting');
        ShowUpdateCostAccountingManually.Send();
    end;

    procedure DontShowAgainUpdateCostAccounting(UpdateCostAcountingNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetUpdateCostAccountingNotificationID()) then
            MyNotifications.InsertDefault(
              GetUpdateCostAccountingNotificationID(), DimensionCorrectionCostAccountingNotificationNameTxt, DimensionCorrectionCostAccountingNotificationDescriptionTxt, false);
    end;

    local procedure GetUpdateCostAccountingNotificationID(): Guid
    begin
        exit('0bf7a209-d730-485b-9ad8-14dc1e756eaf');
    end;

    procedure VerifyCanUndoDimensionCorrection(var DimensionCorrection: Record "Dimension Correction")
    begin
        DimensionCorrection.CalcFields(Invalidated);
        if DimensionCorrection.Invalidated then
            Error(DimensionSetIsInvalidErr);
    end;

    procedure VerifyCanModifyDraftEntry(DimensionCorrectionEntryNo: Integer)
    var
        DimensionCorrection: Record "Dimension Correction";
    begin
        if DimensionCorrectionEntryNo = 0 then
            Error(InsertDimensionCorrectionFirstErr);

        DimensionCorrection.Get(DimensionCorrectionEntryNo);
        if not (DimensionCorrection.Status in [DimensionCorrection.Status::Failed, DimensionCorrection.Status::Draft]) then
            Error(ModifyingDraftDimensionCorrectionNotAllowedErr, DimensionCorrection.Status);

        if DimensionCorrection."Started Correction" then
            Error(ModifyingDraftDimensionCorrectionNotAllowedReopenErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPreviewGLEntriesLimit(var Handled: Boolean; var Limit: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCommitCount(var Handled: Boolean; var CommitCount: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetFilterCount(var Handled: Boolean; var FilterCount: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVerifyIfDimensionCanBeChanged(var DimCorrectionChange: Record "Dim Correction Change")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransformDimensionSetOnBeforeInsertTempNewDimensionSetEntry(var TempNewDimensionSetEntry: Record "Dimension Set Entry" temporary)
    begin
    end;

    var
        CannotValidateDimensionCorrectionErr: Label 'You cannot validate dimension corrections that have the %1 status.', Comment = '%1 Status of dimension correction';
        ValidateDimensionCorrectionLbl: Label 'Validate Dimension Correction';
        UpdateCostAccountingManuallyMsg: Label 'A dimension correction may have affected reports for cost accounting. To help ensure the reports are accurate, recreate the cost accounting allocations.';
        DimensionCorrectionCostAccountingNotificationNameTxt: Label 'Warn Update Cost Accounting After Dimension Correction';
        DimensionCorrectionCostAccountingNotificationDescriptionTxt: Label 'Notifies users that a dimension correction may have affected reports for cost accounting, and that they may need to recreate allocations.';
        DontShowAgainTxt: Label 'Do not show again';
        ValidationFailedLbl: Label 'The validation of the dimension corrections that ran on %1 found the following errors: %2.', Comment = '%1 - Date time of last validation, %2 - Error message';
        ValidationUndoPassedLbl: Label 'Validation was successful on %1. You can undo the dimension correction.', Comment = '%1 - Date time of last validation';
        ValidationDraftPassedLbl: Label 'The dimension correction was validated on %1.', Comment = '%1 - Date time of last validation';
        ValidationFailedErr: Label '%1 entries have validation errors on dimension changes. To review the errors, choose the Show Errors action.', Comment = '%1 count of validation errors';
        JobQueueIsRunningErr: Label 'The job queue entry is already running. Stop the existing job queue entry to schedule a new one.';
        JobQueueEntryDescTxt: Label 'Dimension Correction - %1.', Comment = '%1 - Unique number of the correction';
        JobAlreadyInProgressErr: Label 'There is a job already in progress.';
        AnotherJobAlreadyInProgressErr: Label 'Dimension correction %1 is in progress and must complete before you can start another correction.', Comment = '%1 - Entry No of another dimension correction';
        ChangesWereResetMsg: Label 'Changes to the dimensions were reset because ledger entries were updated. We recommend that you change dimensions after selecting all ledger entries.';
        CannotChangeDimensionCodeBlockedErr: Label 'Dimension %1 cannot be used because it is blocked for the correction.', Comment = '%1 code of the dimension';
        JobQueueCategoryCodeTxt: Label 'DIMCORRECT', Locked = true;
        DimensionSetIsInvalidErr: Label 'Cannot undo the dimension correction because other corrections were made more recently.';
        ModifyingDraftDimensionCorrectionNotAllowedErr: Label 'You cannot change a dimension correction while it is in %1 state.', Comment = '%1 Name of the state';
        ModifyingDraftDimensionCorrectionNotAllowedReopenErr: Label 'You need to reopen the dimension correction to do changes. Alternatevelly you can schedule a new run.';
        InsertDimensionCorrectionFirstErr: Label 'You must create Dimension Correction first, for example by entering description';
        CommitingTelemetryLbl: Label 'Commiting after %1 entries processed.', Locked = true, Comment = '%1 Number of entries procesed';
        UndoDimensionCorrectionLbl: Label 'Undo Dimension Correction';
        UpdateAnalysisViewsLbl: Label 'Update Analysis Views';
        StartingValidateDimensionChangesForEntriesLbl: Label 'Starting Validate Dimension Changes for Entries, Dimension Correction - %1', Locked = true, Comment = '%1 - Number of Dimension Correction';
        CompletedValidateDimensionChangesForEntriesLbl: Label 'Completed Validate Dimension Changes for Entries, Dimension Correction - %1', Locked = true, Comment = '%1 - Number of Dimension Correction';
        InvalidDimensionCorrectionErr: Label 'The dimension correction for Entry %1 is invalid. Error message: %2', Comment = '%1 - Ledger entry number, %2 Error message.';
        CommitedValidateGLEntriesLbl: Label 'Commited G/L Entries validation. Dimension Correction Entry No.: %1, Time from last commit: %2. Number of entries iterated: %3.', Locked = true, Comment = '%1 Dimension Correction Entry No., %2 - Time passed between commits, %3 Number, %4 Time validating dimensions';
        StartingGenerateDimensionSetIdsLbl: Label 'Starting Generate Dimension Correction Set IDs, Dimension Correction Entry No.: %1.', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        CompletedGenerateDimensionSetIdsLbl: Label 'Completed Generate Dimension Correction Set IDs, Dimension Correction Entry No.: %1.', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        NoLedgerEntriesFoundErr: Label 'No ledger entries were found for this dimension correction';
        NoSelectionCriteriaFoundErr: Label 'No selection criteria was found for this dimension correction.';
        NoChangesFoundErr: Label 'No dimension values need to be updated.';
        StartingGenerateSelectedEntriesLbl: Label 'Starting Generate Selected Entries, Dimension Correction Entry No.: %1.', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        CompletedGenerateSelectedEntriesLbl: Label 'Completed Generate Selected Entries, Dimension Correction Entry No.: %1.', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        StartingValidateDimensionCorrectionChangesTelemetryLbl: Label 'Starting Validate Dimension Correction Changes, Dimension Correction Entry No.: %1', Locked = true, Comment = '%1 Dimension Correction Entry No.';
        CompletedValidateDimensionCorrectionChangesTelemetryLbl: Label 'Completed Validate Dimension Correction Changes, Dimension Correction Entry No.: %1.', Locked = true, Comment = '%1 Dimension Correction Entry No., %2 number of updated entries';
        DimensionCorrectionTok: Label 'DimensionCorrection', Locked = true;
}
