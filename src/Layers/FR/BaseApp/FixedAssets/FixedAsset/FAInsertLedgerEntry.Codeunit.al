// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Ledger;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.AuditCodes;
using System.Telemetry;
using System.Utilities;

codeunit 5600 "FA Insert Ledger Entry"
{
    Permissions = TableData "FA Ledger Entry" = rim,
                  TableData "FA Depreciation Book" = rim,
                  TableData "FA Register" = rim,
                  TableData "Maintenance Ledger Entry" = rim;
    TableNo = "FA Ledger Entry";

    trigger OnRun()
    begin
    end;

    var
        FASetup: Record "FA Setup";
        FAPostingTypeSetup: Record "FA Posting Type Setup";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FADeprBook2: Record "FA Depreciation Book";
        FA: Record "Fixed Asset";
        FA2: Record "Fixed Asset";
        FALedgEntry: Record "FA Ledger Entry";
        FALedgEntry2: Record "FA Ledger Entry";
        TempFALedgEntry: Record "FA Ledger Entry" temporary;
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        TempMaintenanceLedgEntry: Record "Maintenance Ledger Entry" temporary;
        FAReg: Record "FA Register";
        FAJnlLine: Record "FA Journal Line";
        FAInsertGLAcc: Codeunit "FA Insert G/L Account";
        FAAutomaticEntry: Codeunit "FA Automatic Entry";
#if not CLEAN30
        AcceleratedDeprFeature: Codeunit "Accelerated Depr. Feature";
#endif
        DeprBookCode: Code[10];
        ErrorEntryNo: Integer;
        NextEntryNo: Integer;
        NextMaintenanceEntryNo: Integer;
        RegisterInserted: Boolean;
        LastEntryNo: Integer;
        GLRegisterNo: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%2 = %3 does not exist for %1.';
        Text001: Label '%2 = %3 does not match the journal line for %1.';
        Text002: Label '%1 is a %2. %3 must be %4 in %5.';
        Text003: Label '%1 must not be %2 in %3 %4.';
        Text004: Label 'Reversal found a %1 without a matching %2.';
#pragma warning restore AA0470
        Text005: Label 'You cannot reverse the transaction, because it has already been reversed.';
#pragma warning disable AA0470
        Text006: Label 'The combination of dimensions used in %1 %2 is blocked. %3';
        Text007: Label '%1 = %2 already exists for %5 (%3 = %4).';
#pragma warning restore AA0470
#pragma warning restore AA0074
        NotEligibleForBonusDepreciationErr: Label 'Fixed asset %1 in depreciation book %2 is not eligible for bonus depreciation, but has a line with bonus depreciation posting type.', Comment = '%1 - fixed asset code; %2 - depreciation book code';
        DepreciationAlreadyAppliedErr: Label 'Depreciation ledger entries have already been posted for fixed asset %1 in depreciation book %2. You must first reverse them in order to post bonus depreciation.', Comment = '%1 - fixed asset code; %2 - depreciation book code';
        FASetupBonusDepreciationErr: Label 'Fixed Asset Setup is not correctly configured for bonus depreciation. You must make sure that bonus depreciation percentage and effective date are set up correctly.';
        BonusDepreciationExceedsAllowedValueErr: Label 'The amount of bonus depreciation must not exceed the allowed value calculated based on acquisition cost and bonus depreciation percentage set up in Fixed Asset Setup.';
        MissingDerogatoryCounterpartErr: Label 'The derogatory counterpart for source entry %1 in depreciation book %2 is missing.', Comment = '%1 - source entry number, %2 - depreciation book code';
        MultipleDerogatoryCounterpartsErr: Label 'More than one derogatory counterpart references source entry %1.', Comment = '%1 - source entry number';

    procedure InsertFA(var FALedgEntry3: Record "FA Ledger Entry")
    var
        InsertedFALedgerEntry: Record "FA Ledger Entry";
    begin
        InsertFA(FALedgEntry3, InsertedFALedgerEntry);
    end;

    procedure InsertFA(var FALedgEntry3: Record "FA Ledger Entry"; var InsertedFALedgerEntry: Record "FA Ledger Entry")
    var
        DerogatoryPostingMgt: Codeunit "Derogatory Posting Mgt.";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        IsHandled: Boolean;
    begin
        FeatureTelemetry.LogUptake('0000GY8', 'Fixed Asset', Enum::"Feature Uptake Status"::Used);
        if NextEntryNo = 0 then begin
            FALedgEntry.LockTable();
            NextEntryNo := FALedgEntry.GetLastEntryNo();
            InitRegister(
              "FA Register Called From"::"Fixed Asset", FALedgEntry3."G/L Entry No.", FALedgEntry3."Source Code",
              FALedgEntry3."Journal Batch Name");
        end;
        NextEntryNo := NextEntryNo + 1;

        FALedgEntry := FALedgEntry3;
        OnBeforeInsertFA(FALedgEntry);

        DeprBook.Get(FALedgEntry."Depreciation Book Code");
        FA.Get(FALedgEntry."FA No.");
        DeprBookCode := FALedgEntry."Depreciation Book Code";
        CheckMainAsset();
        CheckBonusDepreciation();
        ErrorEntryNo := FALedgEntry."Entry No.";
        FALedgEntry."Entry No." := NextEntryNo;
        SetFAPostingType(FALedgEntry);
        if FALedgEntry."Automatic Entry" then
            FAAutomaticEntry.AdjustFALedgEntry(FALedgEntry);
        FALedgEntry."Amount (LCY)" :=
          Round(FALedgEntry.Amount * GetExchangeRate(FALedgEntry."FA Exchange Rate"));
        if not CalcGLIntegration(FALedgEntry) then
            FALedgEntry."G/L Entry No." := 0
        else
            FAInsertGLAcc.Run(FALedgEntry);
        if not DeprBook."Allow Identical Document No." and
           (FALedgEntry."Journal Batch Name" <> '') and
           (FALedgEntry."FA Posting Category" = FALedgEntry."FA Posting Category"::" ") and
           (ErrorEntryNo = 0) and
           (LastEntryNo > 0)
        then
            CheckFADocNo(FALedgEntry);
#if not CLEAN30
        // Both exclusion fields exist until CLEAN30, and the "Book Value" FlowField can only filter one of them,
        // so keep them aligned while the legacy field is still part of the schema.
        FALedgEntry."Derogatory Excluded" := CalcExcludeDerogatory(FALedgEntry);
        FALedgEntry."Exclude Derogatory" := FALedgEntry."Derogatory Excluded";
#else
        FALedgEntry."Derogatory Excluded" := CalcExcludeDerogatory(FALedgEntry);      
#endif
        DerogatoryPostingMgt.ValidateDerogatoryLink(FALedgEntry);
        FALedgEntry.Insert(true);
        FeatureTelemetry.LogUsage('0000H4F', 'Fixed Asset', 'Insert FA Ledger Entry');
        OnInsertFAOnAfterInsertFALedgEntry(FALedgEntry, FALedgEntry3);
        if ErrorEntryNo > 0 then begin
            if not FALedgEntry2.Get(ErrorEntryNo) then
                Error(
                  Text000,
                  FAName(DeprBookCode), FALedgEntry2.FieldCaption("Entry No."), ErrorEntryNo);
            IsHandled := false;
            OnInsertFAOnBeforeCheckFALedgEntry(FALedgEntry, FALedgEntry2, IsHandled);
            if not IsHandled then
                if (FALedgEntry2."Depreciation Book Code" <> FALedgEntry."Depreciation Book Code") or
                   (FALedgEntry2."FA No." <> FALedgEntry."FA No.") or
                   (FALedgEntry2."FA Posting Category" <> FALedgEntry."FA Posting Category") or
                   (FALedgEntry2."FA Posting Type" <> FALedgEntry."FA Posting Type") or
                   (FALedgEntry2.Amount <> -FALedgEntry.Amount) or
                   (FALedgEntry2."FA Posting Date" <> FALedgEntry."FA Posting Date")
                then
                    Error(
                      Text001,
                      FAName(DeprBookCode), FAJnlLine.FieldCaption("FA Error Entry No."), ErrorEntryNo);
            FALedgEntry."Canceled from FA No." := FALedgEntry."FA No.";
            FALedgEntry2."Canceled from FA No." := FALedgEntry2."FA No.";
            FALedgEntry2."FA No." := '';
            FALedgEntry."FA No." := '';
            if FALedgEntry.Amount = 0 then begin
                FALedgEntry2."Transaction No." := 0;
                FALedgEntry."Transaction No." := 0;
            end;
            FALedgEntry2.Modify();
            FALedgEntry.Modify();
            FALedgEntry."FA No." := FALedgEntry3."FA No.";
            OnInsertFAOnAfterSetFALedgEntryFANo(FALedgEntry3, FALedgEntry2, FALedgEntry, NextEntryNo);
        end;

        OnInsertFAOnBeforeFACheckConsistency(FALedgEntry, FALedgEntry3);

        if FALedgEntry3."FA Posting Category" = FALedgEntry3."FA Posting Category"::" " then
            if (FALedgEntry3."FA Posting Type".AsInteger() <= FALedgEntry3."FA Posting Type"::"Salvage Value".AsInteger()) or
               (FALedgEntry3."FA Posting Type" = FALedgEntry3."FA Posting Type"::Derogatory)
            then
                CODEUNIT.Run(CODEUNIT::"FA Check Consistency", FALedgEntry);

        OnBeforeInsertRegister(FALedgEntry, FALedgEntry2, NextEntryNo);

        InsertRegister("FA Register Called From"::"Fixed Asset", NextEntryNo);
        InsertedFALedgerEntry.Get(NextEntryNo);
    end;

    procedure InsertMaintenance(var MaintenanceLedgEntry2: Record "Maintenance Ledger Entry")
    var
        InsertedMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        InsertMaintenance(MaintenanceLedgEntry2, InsertedMaintenanceLedgerEntry);
    end;

    procedure InsertMaintenance(var MaintenanceLedgEntry2: Record "Maintenance Ledger Entry"; var InsertedMaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    var
        DerogatoryPostingMgt: Codeunit "Derogatory Posting Mgt.";
    begin
        if NextMaintenanceEntryNo = 0 then begin
            MaintenanceLedgEntry.LockTable();
            NextMaintenanceEntryNo := MaintenanceLedgEntry.GetLastEntryNo();
            InitRegister(
              "FA Register Called From"::Maintenance, MaintenanceLedgEntry2."G/L Entry No.", MaintenanceLedgEntry2."Source Code",
              MaintenanceLedgEntry2."Journal Batch Name");
        end;
        NextMaintenanceEntryNo := NextMaintenanceEntryNo + 1;
        MaintenanceLedgEntry := MaintenanceLedgEntry2;
        DeprBook.Get(MaintenanceLedgEntry."Depreciation Book Code");
        OnInsertMaintenanceOnAfterDeprBookGet(DeprBook);
        FA.Get(MaintenanceLedgEntry."FA No.");
        CheckMainAsset();
        MaintenanceLedgEntry."Entry No." := NextMaintenanceEntryNo;
        if MaintenanceLedgEntry."Automatic Entry" then
            FAAutomaticEntry.AdjustMaintenanceLedgEntry(MaintenanceLedgEntry);
        MaintenanceLedgEntry."Amount (LCY)" := Round(MaintenanceLedgEntry.Amount * GetExchangeRate(MaintenanceLedgEntry."FA Exchange Rate"));
        if (MaintenanceLedgEntry.Amount > 0) and not MaintenanceLedgEntry.Correction or
           (MaintenanceLedgEntry.Amount < 0) and MaintenanceLedgEntry.Correction
        then begin
            MaintenanceLedgEntry."Debit Amount" := MaintenanceLedgEntry.Amount;
            MaintenanceLedgEntry."Credit Amount" := 0
        end else begin
            MaintenanceLedgEntry."Debit Amount" := 0;
            MaintenanceLedgEntry."Credit Amount" := -MaintenanceLedgEntry.Amount;
        end;
        if MaintenanceLedgEntry."G/L Entry No." > 0 then
            FAInsertGLAcc.InsertMaintenanceAccNo(MaintenanceLedgEntry);
        DerogatoryPostingMgt.ValidateDerogatoryLink(MaintenanceLedgEntry);
        MaintenanceLedgEntry.Insert(true);
        SetMaintenanceLastDate(MaintenanceLedgEntry);
        InsertRegister("FA Register Called From"::Maintenance, NextMaintenanceEntryNo);
        InsertedMaintenanceLedgerEntry.Get(NextMaintenanceEntryNo);
    end;

    procedure SetMaintenanceLastDate(MaintenanceLedgEntry: Record "Maintenance Ledger Entry")
    begin
        MaintenanceLedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
        MaintenanceLedgEntry.SetRange("FA No.", MaintenanceLedgEntry."FA No.");
        MaintenanceLedgEntry.SetRange("Depreciation Book Code", MaintenanceLedgEntry."Depreciation Book Code");
        FADeprBook.Get(MaintenanceLedgEntry."FA No.", MaintenanceLedgEntry."Depreciation Book Code");
        if MaintenanceLedgEntry.FindLast() then
            FADeprBook."Last Maintenance Date" := MaintenanceLedgEntry."FA Posting Date"
        else
            FADeprBook."Last Maintenance Date" := 0D;
        FADeprBook.Modify();
    end;

    local procedure SetFAPostingType(var FALedgerEntry: Record "FA Ledger Entry")
    begin
        UpdateDebitCredit(FALedgEntry);
        FALedgerEntry."Part of Book Value" := false;
        FALedgerEntry."Part of Depreciable Basis" := false;
        if FALedgerEntry."FA Posting Category" = FALedgerEntry."FA Posting Category"::" " then begin
            case FALedgerEntry."FA Posting Type" of
                "FA Ledger Entry FA Posting Type"::"Write-Down":
                    FAPostingTypeSetup.Get(DeprBookCode, FAPostingTypeSetup."FA Posting Type"::"Write-Down");
                "FA Ledger Entry FA Posting Type"::Appreciation:
                    FAPostingTypeSetup.Get(DeprBookCode, FAPostingTypeSetup."FA Posting Type"::Appreciation);
                "FA Ledger Entry FA Posting Type"::"Custom 1":
                    FAPostingTypeSetup.Get(DeprBookCode, FAPostingTypeSetup."FA Posting Type"::"Custom 1");
                "FA Ledger Entry FA Posting Type"::"Custom 2":
                    FAPostingTypeSetup.Get(DeprBookCode, FAPostingTypeSetup."FA Posting Type"::"Custom 2");
            end;
            case FALedgerEntry."FA Posting Type" of
                "FA Ledger Entry FA Posting Type"::"Acquisition Cost",
                "FA Ledger Entry FA Posting Type"::"Salvage Value":
                    FALedgerEntry."Part of Depreciable Basis" := true;
                "FA Ledger Entry FA Posting Type"::"Write-Down",
                "FA Ledger Entry FA Posting Type"::Appreciation,
                "FA Ledger Entry FA Posting Type"::"Custom 1",
                "FA Ledger Entry FA Posting Type"::"Custom 2":
                    FALedgerEntry."Part of Depreciable Basis" := FAPostingTypeSetup."Part of Depreciable Basis";
                "FA Ledger Entry FA Posting Type"::"Bonus Depreciation":
                    FALedgerEntry."Part of Depreciable Basis" := false;
            end;
            case FALedgerEntry."FA Posting Type" of
                "FA Ledger Entry FA Posting Type"::"Acquisition Cost",
                "FA Ledger Entry FA Posting Type"::Derogatory,
                "FA Ledger Entry FA Posting Type"::Depreciation,
                "FA Ledger Entry FA Posting Type"::"Bonus Depreciation":
                    FALedgerEntry."Part of Book Value" := true;
                "FA Ledger Entry FA Posting Type"::"Write-Down",
                "FA Ledger Entry FA Posting Type"::Appreciation,
                "FA Ledger Entry FA Posting Type"::"Custom 1",
                "FA Ledger Entry FA Posting Type"::"Custom 2":
                    FALedgerEntry."Part of Book Value" := FAPostingTypeSetup."Part of Book Value";
            end;
        end;

        OnAfterSetFAPostingType(FALedgerEntry, FAPostingTypeSetup);
    end;

    local procedure GetExchangeRate(ExchangeRate: Decimal): Decimal
    begin
        if ExchangeRate <= 0 then
            exit(1);
        exit(ExchangeRate / 100);
    end;

    local procedure CalcGLIntegration(var FALedgEntry: Record "FA Ledger Entry"): Boolean
    var
        IsHandled, Result : Boolean;
    begin
        IsHandled := false;
        Result := false;
        OnBeforeCalcGLIntegration(FALedgEntry, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if FALedgEntry."G/L Entry No." = 0 then
            exit(false);
        case DeprBook."Disposal Calculation Method" of
            DeprBook."Disposal Calculation Method"::Net:
                if FALedgEntry."FA Posting Type" = FALedgEntry."FA Posting Type"::"Proceeds on Disposal" then
                    exit(false);
            DeprBook."Disposal Calculation Method"::Gross:
                if FALedgEntry."FA Posting Type" = FALedgEntry."FA Posting Type"::"Gain/Loss" then
                    exit(false);
        end;
        if FALedgEntry."FA Posting Type" = FALedgEntry."FA Posting Type"::"Salvage Value" then
            exit(false);

        exit(true);
    end;

    local procedure CheckBonusDepreciation()
    var
        ExistingFALedgerEntry: Record "FA Ledger Entry";
    begin
        if FALedgEntry."FA Posting Type" <> FALedgEntry."FA Posting Type"::"Bonus Depreciation" then
            exit;

        if not FASetup.BonusDepreciationCorrectlySetup() then
            Error(FASetupBonusDepreciationErr);

        FADeprBook.Get(FALedgEntry."FA No.", FALedgEntry."Depreciation Book Code");
        if not FADeprBook.EligibleForBonusDepreciation(FASetup) then
            Error(NotEligibleForBonusDepreciationErr, FADeprBook."FA No.", FADeprBook."Depreciation Book Code");

        if Abs(FALedgEntry.Amount) > Abs(FADeprBook.BonusDepreciationAmount()) then
            Error(BonusDepreciationExceedsAllowedValueErr);

        ExistingFALedgerEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type");
        ExistingFALedgerEntry.SetRange("FA No.", FALedgEntry."FA No.");
        ExistingFALedgerEntry.SetRange("Depreciation Book Code", FALedgEntry."Depreciation Book Code");
        ExistingFALedgerEntry.SetRange("FA Posting Category", FALedgEntry."FA Posting Category"::" ");
        ExistingFALedgerEntry.SetFilter("FA Posting Type", '%1|%2', FALedgEntry."FA Posting Type"::"Depreciation", FALedgEntry."FA Posting Type"::"Bonus Depreciation");

        if not ExistingFALedgerEntry.IsEmpty() then
            Error(DepreciationAlreadyAppliedErr, FADeprBook."FA No.", FADeprBook."Depreciation Book Code");
    end;

    procedure InsertBalAcc(var FALedgEntry: Record "FA Ledger Entry")
    begin
        FAInsertGLAcc.InsertBalAcc(FALedgEntry);
    end;

    procedure InsertBalDisposalAcc(FALedgEntry: Record "FA Ledger Entry")
    begin
        FAInsertGLAcc.Run(FALedgEntry);
    end;

    procedure FindFirstGLAcc(var FAGLPostBuf: Record "FA G/L Posting Buffer"): Boolean
    begin
        exit(FAInsertGLAcc.FindFirstGLAcc(FAGLPostBuf));
    end;

    procedure GetNextGLAcc(var FAGLPostBuf: Record "FA G/L Posting Buffer"): Integer
    begin
        exit(FAInsertGLAcc.GetNextGLAcc(FAGLPostBuf));
    end;

    procedure DeleteAllGLAcc()
    begin
        FAInsertGLAcc.DeleteAllGLAcc();
    end;

    local procedure CheckMainAsset()
    begin
        if FA."Main Asset/Component" = FA."Main Asset/Component"::Component then
            FADeprBook2.Get(FA."Component of Main Asset", DeprBook.Code);

        FASetup.Get();
        if FASetup."Allow Posting to Main Assets" then
            exit;
        FA2."Main Asset/Component" := FA2."Main Asset/Component"::"Main Asset";
        if FA."Main Asset/Component" = FA."Main Asset/Component"::"Main Asset" then
            Error(
              Text002,
              FAName(''), FA2."Main Asset/Component", FASetup.FieldCaption("Allow Posting to Main Assets"),
              true, FASetup.TableCaption);
    end;

    procedure CopyRecordLinksToFALedgEntry(GenJnlLine: Record "Gen. Journal Line")
    var
        RecordLinkMgt: Codeunit "Record Link Management";
    begin
        RecordLinkMgt.CopyLinks(GenJnlLine, FALedgEntry);
    end;

    local procedure InitRegister(CalledFrom: Enum "FA Register Called From"; GLEntryNo: Integer; SourceCode: Code[10]; BatchName: Code[10])
    begin
        if (CalledFrom = "FA Register Called From"::"Fixed Asset") and (NextMaintenanceEntryNo <> 0) then
            exit;
        if (CalledFrom = "FA Register Called From"::Maintenance) and (NextEntryNo <> 0) then
            exit;

        FAReg.LockTable();
        if FAReg.FindLast() and (GLRegisterNo <> 0) and (GLRegisterNo = FAReg.GetLastGLRegisterNo()) then
            exit;
        FAReg."No." := FAReg.GetLastEntryNo() + 1;

        FAReg.Init();
        if GLEntryNo = 0 then
            FAReg."Journal Type" := FAReg."Journal Type"::"Fixed Asset";
        FAReg."Source Code" := SourceCode;
        FAReg."Journal Batch Name" := BatchName;
        FAReg."User ID" := CopyStr(UserId(), 1, MaxStrLen(FAReg."User ID"));
        FAReg.Insert(true);
    end;

    procedure InsertRegister(CalledFrom: Enum "FA Register Called From"; NextEntryNo: Integer)
    begin
        case CalledFrom of
            "FA Register Called From"::"Fixed Asset":
                begin
                    if FAReg."From Entry No." = 0 then
                        FAReg."From Entry No." := NextEntryNo;
                    FAReg."To Entry No." := NextEntryNo;
                end;
            "FA Register Called From"::Maintenance:
                begin
                    if FAReg."From Maintenance Entry No." = 0 then
                        FAReg."From Maintenance Entry No." := NextEntryNo;
                    FAReg."To Maintenance Entry No." := NextEntryNo;
                end;
        end;
        FAReg.Modify();
    end;

    procedure FAName(DeprBookCode: Code[10]): Text[200]
    var
        DepreciationCalc: Codeunit "Depreciation Calculation";
    begin
        exit(DepreciationCalc.FAName(FA, DeprBookCode));
    end;

    local procedure CheckFADocNo(FALedgEntry: Record "FA Ledger Entry")
    var
        OldFALedgEntry: Record "FA Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckFADocNo(FALedgEntry, IsHandled);
        if IsHandled then
            exit;

        OldFALedgEntry.SetCurrentKey(
          "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Document No.");
        OldFALedgEntry.SetRange("FA No.", FALedgEntry."FA No.");
        OldFALedgEntry.SetRange("Depreciation Book Code", FALedgEntry."Depreciation Book Code");
        OldFALedgEntry.SetRange("FA Posting Category", FALedgEntry."FA Posting Category");
        OldFALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type");
        OldFALedgEntry.SetRange("Document No.", FALedgEntry."Document No.");
        OldFALedgEntry.SetRange("Entry No.", 0, LastEntryNo);
        OnCheckFADocNoOnAfterOldFALedgEntrySetFilters(OldFALedgEntry, FALedgEntry);
        if OldFALedgEntry.FindFirst() then
            Error(
              Text007,
              OldFALedgEntry.FieldCaption("Document No."),
              OldFALedgEntry."Document No.",
              OldFALedgEntry.FieldCaption("FA Posting Type"),
              OldFALedgEntry."FA Posting Type",
              FAName(DeprBookCode));
    end;

    procedure SetOrgGenJnlLine(OrgGenJnlLine2: Boolean)
    begin
        FAInsertGLAcc.SetOrgGenJnlLine(OrgGenJnlLine2)
    end;

    procedure CorrectEntries()
    begin
        FAInsertGLAcc.CorrectEntries();
    end;

    procedure InsertReverseEntry(NewGLEntryNo: Integer; FAEntryType: Option " ","Fixed Asset",Maintenance; FAEntryNo: Integer; var NewFAEntryNo: Integer; TransactionNo: Integer)
    var
        OriginalFALedgerEntry: Record "FA Ledger Entry";
        OriginalMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        DerogatorySourceEntryNo: Integer;
    begin
        case FAEntryType of
            FAEntryType::"Fixed Asset":
                begin
                    OriginalFALedgerEntry.Get(FAEntryNo);
                    DerogatorySourceEntryNo := OriginalFALedgerEntry."Derogatory Source Entry No.";
                end;
            FAEntryType::Maintenance:
                begin
                    OriginalMaintenanceLedgerEntry.Get(FAEntryNo);
                    DerogatorySourceEntryNo := OriginalMaintenanceLedgerEntry."Derogatory Source Entry No.";
                end;
        end;
        InsertReverseEntryWithLink(
            NewGLEntryNo, FAEntryType, FAEntryNo, NewFAEntryNo, TransactionNo, DerogatorySourceEntryNo, true);
    end;

    local procedure InsertReverseEntryWithLink(NewGLEntryNo: Integer; FAEntryType: Option " ","Fixed Asset",Maintenance; FAEntryNo: Integer; var NewFAEntryNo: Integer; TransactionNo: Integer; DerogatorySourceEntryNo: Integer; ReverseAutomaticSalvage: Boolean)
    var
        SourceCodeSetup: Record "Source Code Setup";
        FALedgEntry3: Record "FA Ledger Entry";
        OriginalFALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgEntry3: Record "Maintenance Ledger Entry";
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        AccNo: array[10] of Code[20];
        IsHandled, SkipInsertOfMaintenanceLedgerEntry : Boolean;
    begin
        SourceCodeSetup.Get();
        if FAEntryType = FAEntryType::"Fixed Asset" then begin
            FALedgEntry3.Get(FAEntryNo);
            OriginalFALedgerEntry := FALedgEntry3;
            FALedgEntry3.TestField("Reversed by Entry No.", 0);
            IsHandled := false;
            OnInsertReverseEntryOnBeforeCheckIfDisposalIsAllowed(FALedgEntry3, IsHandled);
            if not IsHandled then begin
                FALedgEntry3.TestField("FA Posting Category", FALedgEntry3."FA Posting Category"::" ");
                if FALedgEntry3."FA Posting Type" = FALedgEntry3."FA Posting Type"::"Proceeds on Disposal" then
                    Error(
                      Text003,
                      FALedgEntry3.FieldCaption("FA Posting Type"),
                      FALedgEntry3."FA Posting Type",
                      FALedgEntry.TableCaption(), FALedgEntry3."Entry No.");
            end;
            if ReverseAutomaticSalvage then begin
                ReverseAutomaticSalvageEntries(FAEntryType, OriginalFALedgerEntry, TransactionNo);
                FALedgEntry3.Get(FAEntryNo);
            end;
            if FALedgEntry3."FA Posting Type" = FALedgEntry3."FA Posting Type"::"Salvage Value" then begin
                InsertSalvageReverseEntryWithLink(
                    FALedgEntry3, FAEntryType, NewGLEntryNo, NewFAEntryNo, TransactionNo, DerogatorySourceEntryNo);
                exit;
            end;
            if FALedgEntry3."FA Posting Type" <> FALedgEntry3."FA Posting Type"::"Salvage Value" then begin
                if not DimMgt.CheckDimIDComb(FALedgEntry3."Dimension Set ID") then
                    Error(Text006, FALedgEntry3.TableCaption(), FALedgEntry3."Entry No.", DimMgt.GetDimCombErr());
                Clear(TableID);
                Clear(AccNo);
                TableID[1] := DATABASE::"Fixed Asset";
                AccNo[1] := FALedgEntry3."FA No.";
                OnInsertReverseEntryOnNonSalvageValueFAPostingTypeOnBeforeCheckDimValuePosting(TableID, AccNo, FALedgEntry3);
                if not DimMgt.CheckDimValuePosting(TableID, AccNo, FALedgEntry3."Dimension Set ID") then
                    Error(DimMgt.GetDimValuePostingErr());
                if NextEntryNo = 0 then begin
                    FALedgEntry.LockTable();
                    NextEntryNo := FALedgEntry.GetLastEntryNo();
                    InitRegister("FA Register Called From"::"Fixed Asset", 1, SourceCodeSetup.Reversal, '');
                    RegisterInserted := true;
                end;
                NextEntryNo := NextEntryNo + 1;
                NewFAEntryNo := NextEntryNo;
                IsHandled := false;
                OnInsertReverseEntryOnBeforeInsertTempFALedgEntry(FALedgEntry3, IsHandled);
#if not CLEAN30
                if not IsHandled then begin
                    DeprBook.Get(FALedgEntry3."Depreciation Book Code");
                    if AcceleratedDeprFeature.IsEnabled() then begin
                        if DeprBook."Derogatory Calc." = '' then begin
                            TempFALedgEntry := FALedgEntry3;
                            TempFALedgEntry.Insert();
                        end;
                    end else
                        if DeprBook."Derogatory Calculation" = '' then begin
                            TempFALedgEntry := FALedgEntry3;
                            TempFALedgEntry.Insert();
                        end;
                end;
#else
                if not IsHandled then begin
                    DeprBook.Get(FALedgEntry3."Depreciation Book Code");
                    if DeprBook."Derogatory Calc." = '' then begin
                        TempFALedgEntry := FALedgEntry3;
                        TempFALedgEntry.Insert();
                    end;
                end;
#endif
                SetFAReversalMark(FALedgEntry3, NextEntryNo);
                FALedgEntry3."Entry No." := NextEntryNo;
                FALedgEntry3."G/L Entry No." := NewGLEntryNo;
                FALedgEntry3.Amount := -FALedgEntry3.Amount;
                FALedgEntry3."Debit Amount" := -FALedgEntry3."Debit Amount";
                FALedgEntry3."Credit Amount" := -FALedgEntry3."Credit Amount";
                FALedgEntry3.Quantity := 0;
                FALedgEntry3."User ID" := CopyStr(UserId(), 1, MaxStrLen(FALedgEntry3."User ID"));
                FALedgEntry3."Source Code" := SourceCodeSetup.Reversal;
                FALedgEntry3."Transaction No." := TransactionNo;
                FALedgEntry3."VAT Amount" := -FALedgEntry3."VAT Amount";
                FALedgEntry3."Amount (LCY)" := -FALedgEntry3."Amount (LCY)";
                FALedgEntry3.Correction := not FALedgEntry3.Correction;
                FALedgEntry3."No. Series" := '';
                FALedgEntry3."Journal Batch Name" := '';
                FALedgEntry3."FA No./Budgeted FA No." := '';
                FALedgEntry3."Derogatory Source Entry No." := DerogatorySourceEntryNo;
                OnInsertReverseEntryOnBeforeInsertFALedgEntry(FALedgEntry3);
                FALedgEntry3.Insert(true);
                OnInsertReverseEntryOnBeforeFACheckConsistency(FALedgEntry3);
                CODEUNIT.Run(CODEUNIT::"FA Check Consistency", FALedgEntry3);
                OnInsertReverseEntryOnBeforeInsertRegister(FALedgEntry3);
                InsertRegister("FA Register Called From"::"Fixed Asset", NextEntryNo);
                InsertFARevEntryForDerog(FAEntryType, FALedgEntry3);
            end;
        end;
        if FAEntryType = FAEntryType::Maintenance then begin
            if NextMaintenanceEntryNo = 0 then begin
                MaintenanceLedgEntry.LockTable();
                NextMaintenanceEntryNo := MaintenanceLedgEntry.GetLastEntryNo();
                InitRegister("FA Register Called From"::Maintenance, 1, SourceCodeSetup.Reversal, '');
                RegisterInserted := true;
            end;
            NextMaintenanceEntryNo := NextMaintenanceEntryNo + 1;
            NewFAEntryNo := NextMaintenanceEntryNo;
            MaintenanceLedgEntry3.Get(FAEntryNo);

            if not DimMgt.CheckDimIDComb(MaintenanceLedgEntry3."Dimension Set ID") then
                Error(Text006, MaintenanceLedgEntry3.TableCaption(), MaintenanceLedgEntry3."Entry No.", DimMgt.GetDimCombErr());
            Clear(TableID);
            Clear(AccNo);
            TableID[1] := DATABASE::"Fixed Asset";
            AccNo[1] := MaintenanceLedgEntry3."FA No.";
            if not DimMgt.CheckDimValuePosting(TableID, AccNo, MaintenanceLedgEntry3."Dimension Set ID") then
                Error(DimMgt.GetDimValuePostingErr());

            OnInsertReverseEntryOnBeforeInsertMaintenanceLedgerEntryBuffer(MaintenanceLedgEntry3, SkipInsertOfMaintenanceLedgerEntry);
            DeprBook.Get(MaintenanceLedgEntry3."Depreciation Book Code");
#if not CLEAN30
            if AcceleratedDeprFeature.IsEnabled() then
                SkipInsertOfMaintenanceLedgerEntry := SkipInsertOfMaintenanceLedgerEntry or (DeprBook."Derogatory Calc." <> '')
            else
                SkipInsertOfMaintenanceLedgerEntry := SkipInsertOfMaintenanceLedgerEntry or (DeprBook."Derogatory Calculation" <> '');
#else
            SkipInsertOfMaintenanceLedgerEntry := SkipInsertOfMaintenanceLedgerEntry or (DeprBook."Derogatory Calc." <> '');
#endif
            if not SkipInsertOfMaintenanceLedgerEntry then begin
                TempMaintenanceLedgEntry := MaintenanceLedgEntry3;
                TempMaintenanceLedgEntry.Insert();
            end;
            SetMaintReversalMark(MaintenanceLedgEntry3, NextMaintenanceEntryNo);
            MaintenanceLedgEntry3."Entry No." := NextMaintenanceEntryNo;
            MaintenanceLedgEntry3."G/L Entry No." := NewGLEntryNo;
            MaintenanceLedgEntry3.Amount := -MaintenanceLedgEntry3.Amount;
            MaintenanceLedgEntry3."Debit Amount" := -MaintenanceLedgEntry3."Debit Amount";
            MaintenanceLedgEntry3."Credit Amount" := -MaintenanceLedgEntry3."Credit Amount";
            MaintenanceLedgEntry3.Quantity := 0;
            MaintenanceLedgEntry3."User ID" := CopyStr(UserId(), 1, MaxStrLen(MaintenanceLedgEntry3."User ID"));
            MaintenanceLedgEntry3."Source Code" := SourceCodeSetup.Reversal;
            MaintenanceLedgEntry3."Transaction No." := TransactionNo;
            MaintenanceLedgEntry3."VAT Amount" := -MaintenanceLedgEntry3."VAT Amount";
            MaintenanceLedgEntry3."Amount (LCY)" := -MaintenanceLedgEntry3."Amount (LCY)";
            MaintenanceLedgEntry3.Correction := not FALedgEntry3.Correction;
            MaintenanceLedgEntry3."No. Series" := '';
            MaintenanceLedgEntry3."Journal Batch Name" := '';
            MaintenanceLedgEntry3."FA No./Budgeted FA No." := '';
            MaintenanceLedgEntry3."Derogatory Source Entry No." := DerogatorySourceEntryNo;
            OnInsertReverseEntryOnBeforeInsertMaintenanceLedgerEntry(MaintenanceLedgEntry3);
            MaintenanceLedgEntry3.Insert();
            InsertRegister("FA Register Called From"::Maintenance, NextMaintenanceEntryNo);
            InsertMaintRevEntryForDerog(FAEntryType, MaintenanceLedgEntry3);
        end;
    end;

    local procedure InsertSalvageReverseEntryWithLink(var FALedgerEntry: Record "FA Ledger Entry"; FAEntryType: Option " ","Fixed Asset",Maintenance; NewGLEntryNo: Integer; var NewFAEntryNo: Integer; TransactionNo: Integer; DerogatorySourceEntryNo: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        if NextEntryNo = 0 then begin
            FALedgEntry.LockTable();
            NextEntryNo := FALedgEntry.GetLastEntryNo();
            InitRegister("FA Register Called From"::"Fixed Asset", 1, SourceCodeSetup.Reversal, '');
            RegisterInserted := true;
        end;
        NextEntryNo += 1;
        NewFAEntryNo := NextEntryNo;
        SetFAReversalMark(FALedgerEntry, NextEntryNo);
        FALedgerEntry."Entry No." := NextEntryNo;
        FALedgerEntry."G/L Entry No." := NewGLEntryNo;
        FALedgerEntry.Amount := -FALedgerEntry.Amount;
        FALedgerEntry."Debit Amount" := -FALedgerEntry."Debit Amount";
        FALedgerEntry."Credit Amount" := -FALedgerEntry."Credit Amount";
        FALedgerEntry.Quantity := 0;
        FALedgerEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(FALedgerEntry."User ID"));
        FALedgerEntry."Source Code" := SourceCodeSetup.Reversal;
        FALedgerEntry."Transaction No." := TransactionNo;
        FALedgerEntry."VAT Amount" := -FALedgerEntry."VAT Amount";
        FALedgerEntry."Amount (LCY)" := -FALedgerEntry."Amount (LCY)";
        FALedgerEntry.Correction := not FALedgerEntry.Correction;
        FALedgerEntry."No. Series" := '';
        FALedgerEntry."Journal Batch Name" := '';
        FALedgerEntry."FA No./Budgeted FA No." := '';
        FALedgerEntry."Derogatory Source Entry No." := DerogatorySourceEntryNo;
        FALedgerEntry.Insert(true);
        OnInsertReverseEntryOnBeforeInsertRegister(FALedgerEntry);
        InsertRegister("FA Register Called From"::"Fixed Asset", NextEntryNo);
        InsertFARevEntryForDerog(FAEntryType, FALedgerEntry);
    end;

    local procedure ReverseAutomaticSalvageEntries(FAEntryType: Option " ","Fixed Asset",Maintenance; OriginalFALedgerEntry: Record "FA Ledger Entry"; TransactionNo: Integer)
    var
        AutomaticSalvageFALedgerEntry: Record "FA Ledger Entry";
        OriginalAcquisitionFALedgerEntry: Record "FA Ledger Entry";
        OriginalSalvageFALedgerEntry: Record "FA Ledger Entry";
        NewAutomaticSalvageEntryNo: Integer;
    begin
        if OriginalFALedgerEntry."FA Posting Type" <> OriginalFALedgerEntry."FA Posting Type"::"Acquisition Cost" then
            exit;

        if OriginalFALedgerEntry."Reversed Entry No." = 0 then begin
            if not AutomaticSalvageFALedgerEntry.Get(OriginalFALedgerEntry."Entry No." + 1) then
                exit;
            if not IsAutomaticSalvageCompanion(AutomaticSalvageFALedgerEntry, OriginalFALedgerEntry) then
                exit;
        end else begin
            OriginalAcquisitionFALedgerEntry.Get(OriginalFALedgerEntry."Reversed Entry No.");
            if not OriginalSalvageFALedgerEntry.Get(OriginalAcquisitionFALedgerEntry."Entry No." + 1) then
                exit;
            if not IsAutomaticSalvageCompanion(OriginalSalvageFALedgerEntry, OriginalAcquisitionFALedgerEntry) then
                exit;
            AutomaticSalvageFALedgerEntry.SetRange("Reversed Entry No.", OriginalSalvageFALedgerEntry."Entry No.");
            if not AutomaticSalvageFALedgerEntry.FindFirst() then
                exit;
        end;

        InsertReverseEntryWithLink(
            0, FAEntryType, AutomaticSalvageFALedgerEntry."Entry No.", NewAutomaticSalvageEntryNo, TransactionNo,
            AutomaticSalvageFALedgerEntry."Derogatory Source Entry No.", false);
    end;

    local procedure IsAutomaticSalvageCompanion(AutomaticSalvageFALedgerEntry: Record "FA Ledger Entry"; AcquisitionFALedgerEntry: Record "FA Ledger Entry"): Boolean
    begin
        exit(
            (AutomaticSalvageFALedgerEntry."FA No." = AcquisitionFALedgerEntry."FA No.") and
            (AutomaticSalvageFALedgerEntry."Depreciation Book Code" = AcquisitionFALedgerEntry."Depreciation Book Code") and
            (AutomaticSalvageFALedgerEntry."FA Posting Category" = AcquisitionFALedgerEntry."FA Posting Category") and
            (AutomaticSalvageFALedgerEntry."FA Posting Type" = AutomaticSalvageFALedgerEntry."FA Posting Type"::"Salvage Value") and
            AutomaticSalvageFALedgerEntry."Automatic Entry" and
            (AutomaticSalvageFALedgerEntry."Transaction No." = AcquisitionFALedgerEntry."Transaction No.") and
            (AutomaticSalvageFALedgerEntry."Document Type" = AcquisitionFALedgerEntry."Document Type") and
            (AutomaticSalvageFALedgerEntry."Document No." = AcquisitionFALedgerEntry."Document No.") and
            (AutomaticSalvageFALedgerEntry."Posting Date" = AcquisitionFALedgerEntry."Posting Date") and
            (AutomaticSalvageFALedgerEntry."FA Posting Date" = AcquisitionFALedgerEntry."FA Posting Date") and
            ((AutomaticSalvageFALedgerEntry."Derogatory Source Entry No." = 0) =
             (AcquisitionFALedgerEntry."Derogatory Source Entry No." = 0)));
    end;

    procedure CheckFAReverseEntry(FALedgEntry3: Record "FA Ledger Entry")
    var
        GLEntry: Record "G/L Entry";
    begin
        TempFALedgEntry := FALedgEntry3;
        if FALedgEntry3."FA Posting Type" <> FALedgEntry3."FA Posting Type"::"Salvage Value" then
            if not TempFALedgEntry.Delete() then
                Error(Text004, FALedgEntry.TableCaption(), GLEntry.TableCaption());
    end;

    procedure CheckMaintReverseEntry(MaintenanceLedgEntry3: Record "Maintenance Ledger Entry")
    var
        GLEntry: Record "G/L Entry";
    begin
        TempMaintenanceLedgEntry := MaintenanceLedgEntry3;
        if not TempMaintenanceLedgEntry.Delete() then
            Error(Text004, MaintenanceLedgEntry.TableCaption(), GLEntry.TableCaption());
    end;

    procedure FinishFAReverseEntry(GLReg: Record "G/L Register")
    var
        GLEntry: Record "G/L Entry";
    begin
        if TempFALedgEntry.FindFirst() then
            Error(Text004, FALedgEntry.TableCaption(), GLEntry.TableCaption());
        if TempMaintenanceLedgEntry.FindFirst() then
            Error(Text004, MaintenanceLedgEntry.TableCaption(), GLEntry.TableCaption());
        if RegisterInserted then begin
            FAReg."G/L Register No." := GLReg."No.";
            FAReg.Modify();
        end;
    end;

    local procedure SetFAReversalMark(var FALedgEntry: Record "FA Ledger Entry"; NextEntryNo: Integer)
    var
        FALedgEntry2: Record "FA Ledger Entry";
        GenJnlPostReverse: Codeunit "Gen. Jnl.-Post Reverse";
        CloseReversal: Boolean;
    begin
        if FALedgEntry."Reversed Entry No." <> 0 then begin
            FALedgEntry2.Get(FALedgEntry."Reversed Entry No.");
            if FALedgEntry2."Reversed Entry No." <> 0 then
                Error(Text005);
            CloseReversal := true;
            FALedgEntry2."Reversed by Entry No." := 0;
            FALedgEntry2.Reversed := false;
            FALedgEntry2.Modify();
        end;
        FALedgEntry."Reversed by Entry No." := NextEntryNo;
        if CloseReversal then
            FALedgEntry."Reversed Entry No." := NextEntryNo;
        FALedgEntry.Reversed := true;
        FALedgEntry.Modify();
        FALedgEntry."Reversed by Entry No." := 0;
        FALedgEntry."Reversed Entry No." := FALedgEntry."Entry No.";
        if CloseReversal then
            FALedgEntry."Reversed by Entry No." := FALedgEntry."Entry No.";

        GenJnlPostReverse.SetReversalDescription(FALedgEntry, FALedgEntry.Description);
    end;

    local procedure SetMaintReversalMark(var MaintenanceLedgEntry: Record "Maintenance Ledger Entry"; NextEntryNo: Integer)
    var
        MaintenanceLedgEntry2: Record "Maintenance Ledger Entry";
        GenJnlPostReverse: Codeunit "Gen. Jnl.-Post Reverse";
        CloseReversal: Boolean;
    begin
        if MaintenanceLedgEntry."Reversed Entry No." <> 0 then begin
            MaintenanceLedgEntry2.Get(MaintenanceLedgEntry."Reversed Entry No.");
            if MaintenanceLedgEntry2."Reversed Entry No." <> 0 then
                Error(Text005);
            CloseReversal := true;
            MaintenanceLedgEntry2."Reversed by Entry No." := 0;
            MaintenanceLedgEntry2.Reversed := false;
            MaintenanceLedgEntry2.Modify();
        end;
        MaintenanceLedgEntry."Reversed by Entry No." := NextEntryNo;
        if CloseReversal then
            MaintenanceLedgEntry."Reversed Entry No." := NextEntryNo;
        MaintenanceLedgEntry.Reversed := true;
        MaintenanceLedgEntry.Modify();
        MaintenanceLedgEntry."Reversed by Entry No." := 0;
        MaintenanceLedgEntry."Reversed Entry No." := MaintenanceLedgEntry."Entry No.";
        if CloseReversal then
            MaintenanceLedgEntry."Reversed by Entry No." := MaintenanceLedgEntry."Entry No.";

        GenJnlPostReverse.SetReversalDescription(MaintenanceLedgEntry, MaintenanceLedgEntry.Description);
    end;

    procedure SetNetdisposal(NetDisp2: Boolean)
    begin
        FAInsertGLAcc.SetNetDisposal(NetDisp2);
    end;

    procedure SetLastEntryNo(FindLastEntry: Boolean)
    var
        FALedgEntry: Record "FA Ledger Entry";
    begin
        LastEntryNo := 0;
        if FindLastEntry then
            LastEntryNo := FALedgEntry.GetLastEntryNo();
    end;

    [Scope('OnPrem')]
    procedure InsertFARevEntryForDerog(FAEntryType: Option " ","Fixed Asset",Maintenance; ReversingFALedgerEntry: Record "FA Ledger Entry")
    var
        NewDerogatoryEntryNo: Integer;
    begin
        InsertFARevEntryForDerogWithResult(FAEntryType, NewDerogatoryEntryNo, ReversingFALedgerEntry);
    end;

    [Scope('OnPrem')]
    procedure InsertFARevEntryForDerog(FAEntryType: Option " ","Fixed Asset",Maintenance; var NewFAEntryNo: Integer; FALedgEntry: Record "FA Ledger Entry")
    begin
        InsertFARevEntryForDerogWithResult(FAEntryType, NewFAEntryNo, FALedgEntry);
    end;

    local procedure InsertFARevEntryForDerogWithResult(FAEntryType: Option " ","Fixed Asset",Maintenance; var NewDerogatoryEntryNo: Integer; ReversingFALedgerEntry: Record "FA Ledger Entry")
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgEntryForDerog: Record "FA Ledger Entry";
        OriginalFALedgerEntry: Record "FA Ledger Entry";
        DerogatoryPostingMgt: Codeunit "Derogatory Posting Mgt.";
        DerogatoryDepreciationBookCode: Code[10];
    begin
#if not CLEAN30
        if not AcceleratedDeprFeature.IsEnabled() then begin
            // Retained legacy heuristic for companies still using the pre-move "Derogatory Calculation" setup field.
            DeprBook.SetRange("Derogatory Calculation", ReversingFALedgerEntry."Depreciation Book Code");
            if not DeprBook.FindFirst() then
                exit;
            FALedgEntryForDerog.Reset();
            FALedgEntryForDerog.SetRange("Depreciation Book Code", DeprBook.Code);
            FALedgEntryForDerog.SetRange("FA No.", ReversingFALedgerEntry."FA No.");
            FALedgEntryForDerog.SetRange("FA Posting Type", ReversingFALedgerEntry."FA Posting Type");
            FALedgEntryForDerog.SetRange(Amount, -ReversingFALedgerEntry.Amount);
            FALedgEntryForDerog.SetRange("Document Type", ReversingFALedgerEntry."Document Type");
            FALedgEntryForDerog.SetRange("Document No.", ReversingFALedgerEntry."Document No.");
            if FALedgEntryForDerog.FindFirst() then
                InsertReverseEntry(0, FAEntryType, FALedgEntryForDerog."Entry No.", NewDerogatoryEntryNo, 0);
            exit;
        end;
#endif
        if ReversingFALedgerEntry."Derogatory Source Entry No." <> 0 then
            exit;

        FALedgEntryForDerog.SetRange("Derogatory Source Entry No.", ReversingFALedgerEntry."Reversed Entry No.");
        OriginalFALedgerEntry.Get(ReversingFALedgerEntry."Reversed Entry No.");
        if OriginalFALedgerEntry."Reversed Entry No." = 0 then
            FALedgEntryForDerog.SetRange("Reversed Entry No.", 0);
        case FALedgEntryForDerog.Count() of
            0:
                begin
                    if ReversingFALedgerEntry."Automatic Entry" and
                       (ReversingFALedgerEntry."FA Posting Type" <> ReversingFALedgerEntry."FA Posting Type"::Derogatory)
                    then
                        exit;
                    if ReversingFALedgerEntry."Legacy Derogatory Ambiguous" then begin
                        FindLegacyFADerogatoryEntry(FALedgEntryForDerog, ReversingFALedgerEntry);
                        if FALedgEntryForDerog.IsEmpty() then
                            exit;
                    end else begin
                        if not DerogatoryPostingMgt.GetDerogatoryBookCode(
                             ReversingFALedgerEntry."Depreciation Book Code", DerogatoryDepreciationBookCode)
                        then
                            exit;
                        if not FADepreciationBook.Get(
                             ReversingFALedgerEntry."FA No.", DerogatoryDepreciationBookCode)
                        then
                            exit;
                        Error(
                            MissingDerogatoryCounterpartErr,
                            ReversingFALedgerEntry."Reversed Entry No.", DerogatoryDepreciationBookCode);
                    end;
                end;
            1:
                FALedgEntryForDerog.FindFirst();
            else
                Error(MultipleDerogatoryCounterpartsErr, ReversingFALedgerEntry."Reversed Entry No.");
        end;

        DerogatoryDepreciationBookCode := FALedgEntryForDerog."Depreciation Book Code";
        FALedgEntryForDerog.TestField("Depreciation Book Code", DerogatoryDepreciationBookCode);
        FALedgEntryForDerog.TestField("FA No.", ReversingFALedgerEntry."FA No.");
        FALedgEntryForDerog.TestField("Reversed by Entry No.", 0);
        InsertReverseEntryWithLink(
            0, FAEntryType, FALedgEntryForDerog."Entry No.", NewDerogatoryEntryNo, 0,
            ReversingFALedgerEntry."Entry No.", false);
    end;

    [Scope('OnPrem')]
    procedure InsertMaintRevEntryForDerog(FAEntryType: Option; ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    var
        NewDerogatoryEntryNo: Integer;
    begin
        InsertMaintRevEntryForDerogWithResult(FAEntryType, NewDerogatoryEntryNo, ReversingMaintenanceLedgerEntry);
    end;

    [Scope('OnPrem')]
    procedure InsertMaintRevEntryForDerog(FAEntryType: Option; var NewFAEntryNo: Integer; MaintenanceLedgEntry: Record "Maintenance Ledger Entry")
    begin
        InsertMaintRevEntryForDerogWithResult(FAEntryType, NewFAEntryNo, MaintenanceLedgEntry);
    end;

    local procedure InsertMaintRevEntryForDerogWithResult(FAEntryType: Option; var NewDerogatoryEntryNo: Integer; ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    var
        FADepreciationBook: Record "FA Depreciation Book";
        MaintLedgEntryForDerog: Record "Maintenance Ledger Entry";
        OriginalMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        DerogatoryPostingMgt: Codeunit "Derogatory Posting Mgt.";
        DerogatoryDepreciationBookCode: Code[10];
    begin
#if not CLEAN30
        if not AcceleratedDeprFeature.IsEnabled() then begin
            // Retained legacy heuristic for companies still using the pre-move "Derogatory Calculation" setup field.
            DeprBook.SetRange("Derogatory Calculation", ReversingMaintenanceLedgerEntry."Depreciation Book Code");
            if not DeprBook.FindFirst() then
                exit;
            MaintLedgEntryForDerog.Reset();
            MaintLedgEntryForDerog.SetRange("Depreciation Book Code", DeprBook.Code);
            MaintLedgEntryForDerog.SetRange("FA No.", ReversingMaintenanceLedgerEntry."FA No.");
            MaintLedgEntryForDerog.SetRange("Document Type", ReversingMaintenanceLedgerEntry."Document Type");
            MaintLedgEntryForDerog.SetRange("Document No.", ReversingMaintenanceLedgerEntry."Document No.");
            if MaintLedgEntryForDerog.FindFirst() then
                InsertReverseEntry(0, FAEntryType, MaintLedgEntryForDerog."Entry No.", NewDerogatoryEntryNo, 0);
            exit;
        end;
#endif
        if ReversingMaintenanceLedgerEntry."Derogatory Source Entry No." <> 0 then
            exit;

        MaintLedgEntryForDerog.SetRange("Derogatory Source Entry No.", ReversingMaintenanceLedgerEntry."Reversed Entry No.");
        OriginalMaintenanceLedgerEntry.Get(ReversingMaintenanceLedgerEntry."Reversed Entry No.");
        if OriginalMaintenanceLedgerEntry."Reversed Entry No." = 0 then
            MaintLedgEntryForDerog.SetRange("Reversed Entry No.", 0);
        case MaintLedgEntryForDerog.Count() of
            0:
                if ReversingMaintenanceLedgerEntry."Legacy Derogatory Ambiguous" then begin
                    FindLegacyMaintenanceDerogatoryEntry(
                        MaintLedgEntryForDerog, ReversingMaintenanceLedgerEntry);
                    if MaintLedgEntryForDerog.IsEmpty() then
                        exit;
                end else begin
                    if not DerogatoryPostingMgt.GetDerogatoryBookCode(
                         ReversingMaintenanceLedgerEntry."Depreciation Book Code", DerogatoryDepreciationBookCode)
                    then
                        exit;
                    if not FADepreciationBook.Get(
                         ReversingMaintenanceLedgerEntry."FA No.", DerogatoryDepreciationBookCode)
                    then
                        exit;
                    Error(
                        MissingDerogatoryCounterpartErr,
                        ReversingMaintenanceLedgerEntry."Reversed Entry No.", DerogatoryDepreciationBookCode);
                end;
            1:
                MaintLedgEntryForDerog.FindFirst();
            else
                Error(MultipleDerogatoryCounterpartsErr, ReversingMaintenanceLedgerEntry."Reversed Entry No.");
        end;

        DerogatoryDepreciationBookCode := MaintLedgEntryForDerog."Depreciation Book Code";
        MaintLedgEntryForDerog.TestField("Depreciation Book Code", DerogatoryDepreciationBookCode);
        MaintLedgEntryForDerog.TestField("FA No.", ReversingMaintenanceLedgerEntry."FA No.");
        MaintLedgEntryForDerog.TestField("Reversed by Entry No.", 0);
        InsertReverseEntryWithLink(
            0, FAEntryType, MaintLedgEntryForDerog."Entry No.", NewDerogatoryEntryNo, 0,
            ReversingMaintenanceLedgerEntry."Entry No.", false);
    end;

    local procedure FindLegacyFADerogatoryEntry(var DerogatoryFALedgerEntry: Record "FA Ledger Entry"; ReversingFALedgerEntry: Record "FA Ledger Entry")
    begin
        DerogatoryFALedgerEntry.Reset();
        DerogatoryFALedgerEntry.SetFilter("Depreciation Book Code", '<>%1', ReversingFALedgerEntry."Depreciation Book Code");
        DerogatoryFALedgerEntry.SetRange("FA No.", ReversingFALedgerEntry."FA No.");
        DerogatoryFALedgerEntry.SetRange("FA Posting Type", ReversingFALedgerEntry."FA Posting Type");
        DerogatoryFALedgerEntry.SetRange(Amount, -ReversingFALedgerEntry.Amount);
        DerogatoryFALedgerEntry.SetRange("Document Type", ReversingFALedgerEntry."Document Type");
        DerogatoryFALedgerEntry.SetRange("Document No.", ReversingFALedgerEntry."Document No.");
        DerogatoryFALedgerEntry.FindFirst();
    end;

    local procedure FindLegacyMaintenanceDerogatoryEntry(var DerogatoryMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; ReversingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    begin
        DerogatoryMaintenanceLedgerEntry.Reset();
        DerogatoryMaintenanceLedgerEntry.SetFilter("Depreciation Book Code", '<>%1', ReversingMaintenanceLedgerEntry."Depreciation Book Code");
        DerogatoryMaintenanceLedgerEntry.SetRange("FA No.", ReversingMaintenanceLedgerEntry."FA No.");
        DerogatoryMaintenanceLedgerEntry.SetRange("Document Type", ReversingMaintenanceLedgerEntry."Document Type");
        DerogatoryMaintenanceLedgerEntry.SetRange("Document No.", ReversingMaintenanceLedgerEntry."Document No.");
        DerogatoryMaintenanceLedgerEntry.FindFirst();
    end;

    local procedure CalcExcludeDerogatory(FALedgEntry: Record "FA Ledger Entry"): Boolean
    var
        DeprBook: Record "Depreciation Book";
    begin
        DeprBook.Get(FALedgEntry."Depreciation Book Code");
        exit((FALedgEntry."FA Posting Type" = FALedgEntry."FA Posting Type"::Derogatory) and not DeprBook.IsDerogatoryBook());
    end;

    procedure SetGLRegisterNo(NewGLRegisterNo: Integer)
    begin
        GLRegisterNo := NewGLRegisterNo;
    end;

    local procedure UpdateDebitCredit(var FALedgerEntry: Record "FA Ledger Entry")
    begin
        if (FALedgerEntry.Amount > 0) and not FALedgerEntry.Correction or
           (FALedgerEntry.Amount < 0) and FALedgerEntry.Correction
        then begin
            FALedgerEntry."Debit Amount" := FALedgerEntry.Amount;
            FALedgerEntry."Credit Amount" := 0
        end else begin
            FALedgerEntry."Debit Amount" := 0;
            FALedgerEntry."Credit Amount" := -FALedgerEntry.Amount;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFAPostingType(var FALedgEntry: Record "FA Ledger Entry"; FAPostingTypeSetup: Record "FA Posting Type Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertFA(var FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertRegister(var FALedgerEntry: Record "FA Ledger Entry"; var FALedgerEntry2: Record "FA Ledger Entry"; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckFADocNoOnAfterOldFALedgEntrySetFilters(var OldFALedgEntry: Record "FA Ledger Entry"; FALedgEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReverseEntryOnBeforeInsertRegister(var FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReverseEntryOnBeforeFACheckConsistency(var FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReverseEntryOnNonSalvageValueFAPostingTypeOnBeforeCheckDimValuePosting(var TableID: array[10] of Integer; var AccNo: array[10] of Code[20]; var FALedgEntry3: Record "FA Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFADocNo(FALedgEntry: Record "FA Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertFAOnAfterSetFALedgEntryFANo(FALedgEntry3: Record "FA Ledger Entry"; FALedgEntry2: Record "FA Ledger Entry"; FALedgEntry: Record "FA Ledger Entry"; var NextEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFAOnBeforeFACheckConsistency(var FALedgerEntry: Record "FA Ledger Entry"; FALedgerEntry3: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFAOnBeforeCheckFALedgEntry(var FALedgEntry: Record "FA Ledger Entry"; FALedgEntry2: Record "FA Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertMaintenanceOnAfterDeprBookGet(var DeprBook: Record "Depreciation Book")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcGLIntegration(var FALedgerEntry: Record "FA Ledger Entry"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFAOnAfterInsertFALedgEntry(var FALedgerEntry: Record "FA Ledger Entry"; FALedgerEntry3: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReverseEntryOnBeforeInsertTempFALedgEntry(var FALedgerEntry3: Record "FA Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReverseEntryOnBeforeInsertFALedgEntry(var FALedgerEntry3: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReverseEntryOnBeforeCheckIfDisposalIsAllowed(var FALedgerEntry3: Record "FA Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReverseEntryOnBeforeInsertMaintenanceLedgerEntryBuffer(var MaintenanceKedgerEntry: Record "Maintenance Ledger Entry"; var SkipInsertOfMaintenanceLedgerEntry: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReverseEntryOnBeforeInsertMaintenanceLedgerEntry(var MaintenanceKedgerEntry: Record "Maintenance Ledger Entry")
    begin
    end;

}
