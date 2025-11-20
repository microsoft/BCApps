// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Period;
using System.Security.User;

codeunit 5631 "FA Jnl.-Check Line"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        CheckJobNo(Rec);
        Rec.TestField("FA Posting Type");
        Rec.TestField("Depreciation Book Code");
        if Rec."Duplicate in Depreciation Book" = Rec."Depreciation Book Code" then
            Rec.FieldError(
              Rec."Duplicate in Depreciation Book",
              StrSubstNo(Text000, Rec.FieldCaption("Depreciation Book Code")));
        if Rec."Account Type" = Rec."Bal. Account Type" then
            Error(
              Text001,
              Rec.FieldCaption("Account Type"), Rec.FieldCaption("Bal. Account Type"), Rec."Account Type");
        if Rec."Account No." <> '' then
            CheckAccountNo(Rec);

        if Rec."Bal. Account No." <> '' then
            CheckBalAccountNo(Rec);

        if Rec."Recurring Method".AsInteger() > Rec."Recurring Method"::"V  Variable".AsInteger() then begin
            GenJnlline2."Account Type" := GenJnlline2."Account Type"::"Fixed Asset";
            Rec.FieldError(
              Rec."Recurring Method",
              StrSubstNo(Text002,
                Rec."Recurring Method",
                Rec.FieldCaption("Account Type"),
                Rec.FieldCaption("Bal. Account Type"),
                GenJnlline2."Account Type"));
        end;
        DeprBookCode := Rec."Depreciation Book Code";
        if Rec."FA Posting Date" = 0D then
            Rec."FA Posting Date" := Rec."Posting Date";
        FAPostingDate := Rec."FA Posting Date";
        PostingDate := Rec."Posting Date";
        FAPostingType := "FA Journal Line FA Posting Type".FromInteger(Rec."FA Posting Type".AsInteger() - 1);
        GenJnlPosting := true;
        GenJnlLine := Rec;
        CheckJnlLine();
        CheckFADepAcrossFiscalYear();

        OnAfterCheckGenJnlLine(Rec);
    end;

    var
        UserSetup: Record "User Setup";
        FASetup: Record "FA Setup";
        FA: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        DeprBook: Record "Depreciation Book";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlline2: Record "Gen. Journal Line";
        FAJnlLine: Record "FA Journal Line";
        DimMgt: Codeunit DimensionManagement;
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
        GenJnlPosting: Boolean;
        FANo: Code[20];
        DeprBookCode: Code[10];
        PostingDate: Date;
        FAPostingDate: Date;
        FAPostingType: Enum "FA Journal Line FA Posting Type";
        FieldErrorText: Text[250];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'is not different than %1';
        Text001: Label '%1 and %2 must not both be %3.';
        Text002: Label 'must not be %1 when %2 or %3 are %4';
#pragma warning restore AA0470
        Text003: Label 'can only be a closing date for G/L entries';
        Text004: Label 'is not within your range of allowed posting dates';
#pragma warning disable AA0470
        Text005: Label 'must be identical to %1';
        Text006: Label 'must not be a %1';
        Text007: Label '%1 must be posted in the general journal';
        Text008: Label '%1 must be posted in the FA journal';
        Text009: Label 'must not be specified when %1 = %2 in %3';
        Text010: Label 'must not be specified when %1 is specified';
        Text011: Label 'must not be specified together with %1 = %2';
        Text012: Label 'must not be specified when %1 is a %2';
        Text013: Label 'is a %1';
        Text014: Label 'The combination of dimensions used in %1 %2, %3, %4 is blocked. %5';
        Text015: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5';
        Text016: Label '%1 + %2 must be %3.';
        Text017: Label '%1 + %2 must be -%3.';
        Text018: Label 'You cannot dispose Main Asset %1 until Components are disposed.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Text019Err: Label 'You cannot post depreciation, because the calculation is across different fiscal year periods, which is not supported.';

    procedure CheckFAJnlLine(var FAJournalLine: Record "FA Journal Line")
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        if FAJournalLine."FA No." = '' then
            exit;
        OnBeforeCheckFAJnlLine(FAJournalLine);
        FAJournalLine.TestField("FA Posting Date");
        FAJournalLine.TestField("Depreciation Book Code");
        FAJournalLine.TestField("Document No.");
        if FAJournalLine."Duplicate in Depreciation Book" = FAJournalLine."Depreciation Book Code" then
            FAJournalLine.FieldError("Duplicate in Depreciation Book",
              StrSubstNo(Text000, FAJournalLine.FieldCaption("Depreciation Book Code")));
        FANo := FAJournalLine."FA No.";
        PostingDate := FAJournalLine."Posting Date";
        FAPostingDate := FAJournalLine."FA Posting Date";
        if PostingDate = 0D then
            PostingDate := FAPostingDate;
        DeprBookCode := FAJournalLine."Depreciation Book Code";
        FAPostingType := FAJournalLine."FA Posting Type";
        if not DimMgt.CheckDimIDComb(FAJournalLine."Dimension Set ID") then
            Error(
              Text014,
              FAJournalLine.TableCaption, FAJournalLine."Journal Template Name", FAJournalLine."Journal Batch Name", FAJournalLine."Line No.",
              DimMgt.GetDimCombErr());

        TableID[1] := DATABASE::"Fixed Asset";
        No[1] := FAJournalLine."FA No.";
        if not DimMgt.CheckDimValuePosting(TableID, No, FAJournalLine."Dimension Set ID") then
            if FAJournalLine."Line No." <> 0 then
                Error(
                  Text015,
                  FAJournalLine.TableCaption, FAJournalLine."Journal Template Name", FAJournalLine."Journal Batch Name", FAJournalLine."Line No.",
                  DimMgt.GetDimValuePostingErr())
            else
                Error(DimMgt.GetDimValuePostingErr());
        GenJnlPosting := false;
        OnCheckFAJnlLineOnBeforeCheckJnlLine(FAJournalLine);
        FAJnlLine := FAJournalLine;
        CheckJnlLine();

        OnAfterCheckFAJnlLine(FAJournalLine);
    end;

    local procedure CheckAccountNo(var GenJournalLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAccountNo(GenJournalLine, FANo, IsHandled);
        if IsHandled then
            exit;

        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"Fixed Asset" then begin
            if GenJournalLine."FA Posting Type" in
               [GenJournalLine."FA Posting Type"::"Acquisition Cost",
                GenJournalLine."FA Posting Type"::Appreciation,
                GenJournalLine."FA Posting Type"::Disposal,
                GenJournalLine."FA Posting Type"::Maintenance]
            then begin
                if (GenJournalLine."Gen. Bus. Posting Group" <> '') or (GenJournalLine."Gen. Prod. Posting Group" <> '') or
                   (GenJournalLine."VAT Bus. Posting Group" <> '') or (GenJournalLine."VAT Prod. Posting Group" <> '')
                then
                    GenJournalLine.TestField("Gen. Posting Type");
                if (GenJournalLine."Gen. Posting Type" <> GenJournalLine."Gen. Posting Type"::" ") and
                   (GenJournalLine."VAT Posting" = GenJournalLine."VAT Posting"::"Automatic VAT Entry")
                then begin
                    if GenJournalLine."VAT Amount" + GenJournalLine."VAT Base Amount" <> GenJournalLine.Amount then
                        Error(
                          Text016, GenJournalLine.FieldCaption("VAT Amount"), GenJournalLine.FieldCaption("VAT Base Amount"),
                          GenJournalLine.FieldCaption(Amount));
                    if GenJournalLine."Currency Code" <> '' then
                        if GenJournalLine."VAT Amount (LCY)" + GenJournalLine."VAT Base Amount (LCY)" <> GenJournalLine."Amount (LCY)" then
                            Error(
                              Text016, GenJournalLine.FieldCaption("VAT Amount (LCY)"),
                              GenJournalLine.FieldCaption("VAT Base Amount (LCY)"), GenJournalLine.FieldCaption("Amount (LCY)"));
                end;
            end else begin
                GenJournalLine.TestField("Gen. Posting Type", 0);
                GenJournalLine.TestField("Gen. Bus. Posting Group", '');
                GenJournalLine.TestField("Gen. Prod. Posting Group", '');
                GenJournalLine.TestField("VAT Bus. Posting Group", '');
                GenJournalLine.TestField("VAT Prod. Posting Group", '');
            end;
            FANo := GenJournalLine."Account No.";
        end;
    end;

    local procedure CheckBalAccountNo(var GenJournalLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBalAccountNo(GenJournalLine, FANo, IsHandled);
        if IsHandled then
            exit;

        if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"Fixed Asset" then begin
            if GenJournalLine."FA Posting Type" in
               [GenJournalLine."FA Posting Type"::"Acquisition Cost",
                GenJournalLine."FA Posting Type"::Disposal,
                GenJournalLine."FA Posting Type"::Maintenance]
            then begin
                if (GenJournalLine."Bal. Gen. Bus. Posting Group" <> '') or (GenJournalLine."Bal. Gen. Prod. Posting Group" <> '') or
                   (GenJournalLine."Bal. VAT Bus. Posting Group" <> '') or (GenJournalLine."Bal. VAT Prod. Posting Group" <> '')
                then
                    GenJournalLine.TestField("Bal. Gen. Posting Type");
                if (GenJournalLine."Bal. Gen. Posting Type" <> GenJournalLine."Bal. Gen. Posting Type"::" ") and
                   (GenJournalLine."VAT Posting" = GenJournalLine."VAT Posting"::"Automatic VAT Entry")
                then begin
                    if GenJournalLine."Bal. VAT Amount" + GenJournalLine."Bal. VAT Base Amount" <> -GenJournalLine.Amount then
                        Error(
                          Text017, GenJournalLine.FieldCaption("Bal. VAT Amount"), GenJournalLine.FieldCaption("Bal. VAT Base Amount"),
                          GenJournalLine.FieldCaption(Amount));
                    if GenJournalLine."Currency Code" <> '' then
                        if GenJournalLine."Bal. VAT Amount (LCY)" + GenJournalLine."Bal. VAT Base Amount (LCY)" <> -GenJournalLine."Amount (LCY)" then
                            Error(
                              Text017, GenJournalLine.FieldCaption("Bal. VAT Amount (LCY)"),
                              GenJournalLine.FieldCaption("Bal. VAT Base Amount (LCY)"), GenJournalLine.FieldCaption("Amount (LCY)"));
                end;
            end else begin
                GenJournalLine.TestField("Bal. Gen. Posting Type", 0);
                GenJournalLine.TestField("Bal. Gen. Bus. Posting Group", '');
                GenJournalLine.TestField("Bal. Gen. Prod. Posting Group", '');
                GenJournalLine.TestField("Bal. VAT Bus. Posting Group", '');
                GenJournalLine.TestField("Bal. VAT Prod. Posting Group", '');
            end;
            FANo := GenJournalLine."Bal. Account No.";
        end;
    end;

    local procedure CheckJnlLine()
    begin
        FA.Get(FANo);
        FASetup.Get();
        DeprBook.Get(DeprBookCode);
        FADeprBook.Get(FANo, DeprBookCode);
        OnCheckJnlLineOnAfterGetGlobals(FA, FASetup, DeprBook, FADeprBook);
        CheckFAPostingDate();
        CheckFAIntegration();
        CheckConsistency();
        CheckErrorNo();
        CheckMainAsset();
    end;

    local procedure CheckJobNo(var GenJournalLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckJobNo(GenJournalLine, IsHandled);
        if IsHandled then
            exit;

        GenJournalLine.TestField("Job No.", '');
    end;

    local procedure CheckFAPostingDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckFAPostingDate(GenJnlLine, FAJnlLine, DeprBook, IsHandled, FADeprBook, GenJnlPosting, FAPostingDate);
        if IsHandled then
            exit;

        if FAPostingDate <> NormalDate(FAPostingDate) then
            if GenJnlPosting then
                GenJnlLine.FieldError("FA Posting Date", Text003)
            else
                FAJnlLine.FieldError("FA Posting Date", Text003);

        if (FAPostingDate < DMY2Date(1, 1, 2)) or
           (FAPostingDate > DMY2Date(31, 12, 9998))
        then
            if GenJnlPosting then
                GenJnlLine.FieldError("FA Posting Date", Text004)
            else
                FAJnlLine.FieldError("FA Posting Date", Text004);

        if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
            if UserId <> '' then
                if UserSetup.Get(UserId) then begin
                    AllowPostingFrom := UserSetup."Allow FA Posting From";
                    AllowPostingTo := UserSetup."Allow FA Posting To";
                end;
            if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
                FASetup.Get();
                AllowPostingFrom := FASetup."Allow FA Posting From";
                AllowPostingTo := FASetup."Allow FA Posting To";
            end;
            if AllowPostingTo = 0D then
                AllowPostingTo := DMY2Date(31, 12, 9998);
        end;
        if (FAPostingDate < AllowPostingFrom) or
           (FAPostingDate > AllowPostingTo)
        then
            if GenJnlPosting then
                GenJnlLine.FieldError("FA Posting Date", Text004)
            else
                FAJnlLine.FieldError("FA Posting Date", Text004);

        if DeprBook."Use Same FA+G/L Posting Dates" and (PostingDate <> FAPostingDate) then begin
            if GenJnlPosting then
                GenJnlLine.FieldError(
                  "FA Posting Date", StrSubstNo(Text005,
                    GenJnlLine.FieldCaption("Posting Date")));

            FAJnlLine.FieldError(
              "Posting Date", StrSubstNo(Text005,
                FAJnlLine.FieldCaption("FA Posting Date")))
        end;
    end;

    local procedure CheckFAIntegration()
    var
        GLIntegration: Boolean;
        IsHandled: Boolean;
    begin
        if GenJnlPosting and FA."Budgeted Asset" then
            GenJnlLine.FieldError("Account No.", StrSubstNo(Text006, FA.FieldCaption("Budgeted Asset")));
        if FA."Budgeted Asset" then
            exit;
        case FAPostingType of
            FAPostingType::"Acquisition Cost":
                GLIntegration := DeprBook."G/L Integration - Acq. Cost";
            FAPostingType::Depreciation:
                GLIntegration := DeprBook."G/L Integration - Depreciation";
            FAPostingType::"Write-Down":
                GLIntegration := DeprBook."G/L Integration - Write-Down";
            FAPostingType::Appreciation:
                GLIntegration := DeprBook."G/L Integration - Appreciation";
            FAPostingType::"Custom 1":
                GLIntegration := DeprBook."G/L Integration - Custom 1";
            FAPostingType::"Custom 2":
                GLIntegration := DeprBook."G/L Integration - Custom 2";
            FAPostingType::Disposal:
                GLIntegration := DeprBook."G/L Integration - Disposal";
            FAPostingType::Maintenance:
                GLIntegration := DeprBook."G/L Integration - Maintenance";
            FAPostingType::"Salvage Value":
                GLIntegration := false;
        end;

        IsHandled := false;
        OnAfterSetGLIntegration(FAPostingType, GLIntegration, GenJnlPosting, DeprBook, IsHandled);
        if IsHandled then
            exit;

        if GLIntegration and not GenJnlPosting then
            FAJnlLine.FieldError(
              "FA Posting Type",
              StrSubstNo(Text007, FAJnlLine."FA Posting Type"));
        if not GLIntegration and GenJnlPosting then
            GenJnlLine.FieldError(
              "FA Posting Type",
              StrSubstNo(Text008, GenJnlLine."FA Posting Type"));

        GLIntegration := DeprBook."G/L Integration - Depreciation";
        if GenJnlPosting then begin
            if GenJnlLine."Depr. until FA Posting Date" and not GLIntegration then
                GenJnlLine.FieldError(
                  "Depr. until FA Posting Date", StrSubstNo(Text009,
                    DeprBook.FieldCaption("G/L Integration - Depreciation"), false, DeprBook.TableCaption()));
            if GenJnlLine."Depr. Acquisition Cost" and not GLIntegration then
                GenJnlLine.FieldError(
                  "Depr. Acquisition Cost", StrSubstNo(Text009,
                    DeprBook.FieldCaption("G/L Integration - Depreciation"), false, DeprBook.TableCaption()));
        end;
        if not GenJnlPosting then begin
            if FAJnlLine."Depr. until FA Posting Date" and GLIntegration then
                FAJnlLine.FieldError(
                  "Depr. until FA Posting Date", StrSubstNo(Text009,
                    DeprBook.FieldCaption("G/L Integration - Depreciation"), true, DeprBook.TableCaption()));
            if FAJnlLine."Depr. Acquisition Cost" and GLIntegration then
                FAJnlLine.FieldError(
                  "Depr. Acquisition Cost", StrSubstNo(Text009,
                    DeprBook.FieldCaption("G/L Integration - Depreciation"), true, DeprBook.TableCaption()));
        end;
        OnAfterCheckFAIntegration(FAPostingType, GenJnlPosting, FAJnlLine, GenJnlLine);
    end;

    local procedure CheckErrorNo()
    begin
        if GenJnlPosting and (GenJnlLine."FA Error Entry No." > 0) then begin
            FieldErrorText :=
              StrSubstNo(Text010,
                GenJnlLine.FieldCaption("FA Error Entry No."));
            case true of
                GenJnlLine."Depr. until FA Posting Date":
                    GenJnlLine.FieldError("Depr. until FA Posting Date", FieldErrorText);
                GenJnlLine."Depr. Acquisition Cost":
                    GenJnlLine.FieldError("Depr. Acquisition Cost", FieldErrorText);
                GenJnlLine."Duplicate in Depreciation Book" <> '':
                    GenJnlLine.FieldError("Duplicate in Depreciation Book", FieldErrorText);
                GenJnlLine."Use Duplication List":
                    GenJnlLine.FieldError("Use Duplication List", FieldErrorText);
                GenJnlLine."Salvage Value" <> 0:
                    GenJnlLine.FieldError("Salvage Value", FieldErrorText);
                GenJnlLine."Insurance No." <> '':
                    GenJnlLine.FieldError("Insurance No.", FieldErrorText);
                GenJnlLine."Budgeted FA No." <> '':
                    GenJnlLine.FieldError("Budgeted FA No.", FieldErrorText);
                GenJnlLine."Recurring Method" <> GenJnlLine."Recurring Method"::" ":
                    GenJnlLine.FieldError("Recurring Method", FieldErrorText);
            end;
        end;
        if not GenJnlPosting and (FAJnlLine."FA Error Entry No." > 0) then begin
            FieldErrorText :=
              StrSubstNo(Text010,
                FAJnlLine.FieldCaption("FA Error Entry No."));
            case true of
                FAJnlLine."Depr. until FA Posting Date":
                    FAJnlLine.FieldError("Depr. until FA Posting Date", FieldErrorText);
                FAJnlLine."Depr. Acquisition Cost":
                    FAJnlLine.FieldError("Depr. Acquisition Cost", FieldErrorText);
                FAJnlLine."Duplicate in Depreciation Book" <> '':
                    FAJnlLine.FieldError("Duplicate in Depreciation Book", FieldErrorText);
                FAJnlLine."Use Duplication List":
                    FAJnlLine.FieldError("Use Duplication List", FieldErrorText);
                FAJnlLine."Salvage Value" <> 0:
                    FAJnlLine.FieldError("Salvage Value", FieldErrorText);
                FAJnlLine."Insurance No." <> '':
                    FAJnlLine.FieldError("Insurance No.", FieldErrorText);
                FAJnlLine."Budgeted FA No." <> '':
                    FAJnlLine.FieldError("Budgeted FA No.", FieldErrorText);
                FAJnlLine."Recurring Method" > 0:
                    FAJnlLine.FieldError("Recurring Method", FieldErrorText);
            end;
        end;
    end;

    local procedure SetGenJournalLineValuesBeforeConsistencyCheck(var GenJournalLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeSetGenJournalLineValuesBeforeConsistencyCheck(IsHandled, GenJnlPosting, GenJournalLine);
        if IsHandled then
            exit;
        if GenJournalLine."Journal Template Name" = '' then
            GenJournalLine.Quantity := 0;
    end;

    local procedure CheckConsistency()
    var
        IsHandled: Boolean;
        ShouldCheckNoOfDepreciationDays: Boolean;
    begin
        if GenJnlPosting then begin
            SetGenJournalLineValuesBeforeConsistencyCheck(GenJnlLine);
            FieldErrorText :=
              StrSubstNo(Text011,
                GenJnlLine.FieldCaption("FA Posting Type"), GenJnlLine."FA Posting Type");
            if (GenJnlLine."FA Error Entry No." > 0) and (GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::Maintenance) then
                GenJnlLine.FieldError("FA Error Entry No.", FieldErrorText);
            if not GenJnlLine.IsAcquisitionCost() then
                case true of
                    GenJnlLine."Depr. Acquisition Cost":
                        GenJnlLine.FieldError("Depr. Acquisition Cost", FieldErrorText);
                    GenJnlLine."Salvage Value" <> 0:
                        GenJnlLine.FieldError("Salvage Value", FieldErrorText);
                    GenJnlLine."Insurance No." <> '':
                        GenJnlLine.FieldError("Insurance No.", FieldErrorText);
                    GenJnlLine.Quantity <> 0:
                        begin
                            IsHandled := false;
                            OnCheckConsistencyOnBeforeCheckQuantity(GenJnlLine, IsHandled, FAJnlLine);
                            if not IsHandled then
                                if GenJnlLine."FA Posting Type" <> GenJnlLine."FA Posting Type"::Maintenance then
                                    GenJnlLine.FieldError(Quantity, FieldErrorText);
                        end;
                end;
            if (GenJnlLine."FA Posting Type" <> GenJnlLine."FA Posting Type"::Maintenance) and
               (GenJnlLine."Maintenance Code" <> '')
            then
                GenJnlLine.FieldError("Maintenance Code", FieldErrorText);
            if GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::Maintenance then
                if GenJnlLine."Depr. until FA Posting Date" then
                    GenJnlLine.FieldError("Depr. until FA Posting Date", FieldErrorText);

            ShouldCheckNoOfDepreciationDays := (GenJnlLine."FA Posting Type" <> GenJnlLine."FA Posting Type"::Depreciation) and (GenJnlLine."FA Posting Type" <> GenJnlLine."FA Posting Type"::"Custom 1") and (GenJnlLine."No. of Depreciation Days" <> 0);
            OnCheckConsistencyOnAfterCalcShouldCheckNoOfDepreciationDays(GenJnlLine, FieldErrorText, ShouldCheckNoOfDepreciationDays, FAJnlLine);
            if ShouldCheckNoOfDepreciationDays then
                GenJnlLine.FieldError("No. of Depreciation Days", FieldErrorText);

            if GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::Disposal then begin
                if GenJnlLine."FA Reclassification Entry" then
                    GenJnlLine.FieldError("FA Reclassification Entry", FieldErrorText);
                if GenJnlLine."Budgeted FA No." <> '' then
                    GenJnlLine.FieldError("Budgeted FA No.", FieldErrorText);
            end;

            FieldErrorText := StrSubstNo(Text012,
                GenJnlLine.FieldCaption("Account No."), FA.FieldCaption("Budgeted Asset"));

            if FA."Budgeted Asset" and (GenJnlLine."Budgeted FA No." <> '') then
                GenJnlLine.FieldError("Budgeted FA No.", FieldErrorText);

            if GenJnlLine.IsAcquisitionCost() and
               (GenJnlLine."Insurance No." <> '') and
               (DeprBook.Code <> FASetup."Insurance Depr. Book")
            then
                GenJnlLine.TestField("Insurance No.", '');

            if FA."Budgeted Asset" then
                GenJnlLine.FieldError("Account No.", StrSubstNo(Text013, FA.FieldCaption("Budgeted Asset")));
        end;

        if not GenJnlPosting then begin
            FieldErrorText :=
              StrSubstNo(Text011,
                FAJnlLine.FieldCaption("FA Posting Type"), FAJnlLine."FA Posting Type");

            if (FAJnlLine."FA Error Entry No." > 0) and (FAJnlLine."FA Posting Type" = FAJnlLine."FA Posting Type"::Maintenance) then
                FAJnlLine.FieldError("FA Error Entry No.", FieldErrorText);

            if not FAJnlLine.IsAcquisitionCost() then
                case true of
                    FAJnlLine."Depr. Acquisition Cost":
                        FAJnlLine.FieldError("Depr. Acquisition Cost", FieldErrorText);
                    FAJnlLine."Salvage Value" <> 0:
                        FAJnlLine.FieldError("Salvage Value", FieldErrorText);
                    FAJnlLine.Quantity <> 0:
                        begin
                            IsHandled := false;
                            OnCheckConsistencyOnBeforeCheckQuantity(GenJnlLine, IsHandled, FAJnlLine);
                            if not IsHandled then
                                if FAJnlLine."FA Posting Type" <> FAJnlLine."FA Posting Type"::Maintenance then
                                    FAJnlLine.FieldError(Quantity, FieldErrorText);
                        end;
                    FAJnlLine."Insurance No." <> '':
                        FAJnlLine.FieldError("Insurance No.", FieldErrorText);
                end;
            if (FAJnlLine."FA Posting Type" = FAJnlLine."FA Posting Type"::Maintenance) and
               FAJnlLine."Depr. until FA Posting Date"
            then
                FAJnlLine.FieldError("Depr. until FA Posting Date", FieldErrorText);
            if (FAJnlLine."FA Posting Type" <> FAJnlLine."FA Posting Type"::Maintenance) and
               (FAJnlLine."Maintenance Code" <> '')
            then
                FAJnlLine.FieldError("Maintenance Code", FieldErrorText);

            ShouldCheckNoOfDepreciationDays := (FAJnlLine."FA Posting Type" <> FAJnlLine."FA Posting Type"::Depreciation) and (FAJnlLine."FA Posting Type" <> FAJnlLine."FA Posting Type"::"Custom 1") and (FAJnlLine."No. of Depreciation Days" <> 0);
            OnCheckConsistencyOnAfterCalcShouldCheckNoOfDepreciationDays(GenJnlLine, FieldErrorText, ShouldCheckNoOfDepreciationDays, FAJnlLine);
            if ShouldCheckNoOfDepreciationDays then
                FAJnlLine.FieldError("No. of Depreciation Days", FieldErrorText);

            if FAJnlLine."FA Posting Type" = FAJnlLine."FA Posting Type"::Disposal then begin
                if FAJnlLine."FA Reclassification Entry" then
                    FAJnlLine.FieldError("FA Reclassification Entry", FieldErrorText);
                if FAJnlLine."Budgeted FA No." <> '' then
                    FAJnlLine.FieldError("Budgeted FA No.", FieldErrorText);
            end;

            FieldErrorText := StrSubstNo(Text012,
                FAJnlLine.FieldCaption("FA No."), FA.FieldCaption("Budgeted Asset"));

            if FA."Budgeted Asset" and (FAJnlLine."Budgeted FA No." <> '') then
                FAJnlLine.FieldError("Budgeted FA No.", FieldErrorText);

            if FAJnlLine.IsAcquisitionCost() and
               (FAJnlLine."Insurance No." <> '') and
               (DeprBook.Code <> FASetup."Insurance Depr. Book")
            then
                FAJnlLine.TestField("Insurance No.", '');

            OnAfterCheckConsistencyFAJnlPosting(FAJnlLine);
        end;
    end;

    local procedure CheckMainAsset()
    var
        MainAssetComponent: Record "Main Asset Component";
        ComponentFADeprBook: Record "FA Depreciation Book";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckMainAsset(GenJnlLine, FAJnlLine, DeprBook, FA, IsHandled);
        if IsHandled then
            exit;

        if GenJnlLine."FA Posting Type" <> GenJnlLine."FA Posting Type"::Disposal then
            exit;
        if FA."Main Asset/Component" <> FA."Main Asset/Component"::"Main Asset" then
            exit;

        MainAssetComponent.Reset();
        MainAssetComponent.SetRange("Main Asset No.", FA."No.");
        if MainAssetComponent.FindSet() then
            repeat
                if ComponentFADeprBook.Get(MainAssetComponent."FA No.", DeprBookCode) then
                    if ComponentFADeprBook."Disposal Date" = 0D then
                        Error(Text018, FA."No.");
            until MainAssetComponent.Next() = 0;
    end;

    local procedure CheckFADepAcrossFiscalYear()
    var
        AccPeriod: Record "Accounting Period";
        DepreciationCalculation: Codeunit "Depreciation Calculation";
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        EndingDate: Date;
        StartingDate: Date;
        IsHandled: Boolean;
    begin
        if (GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::Depreciation) and
           (GenJnlLine."No. of Depreciation Days" <> 0) and
           (FADeprBook."Depreciation Method" = FADeprBook."Depreciation Method"::"Declining-Balance 1")
        then begin
            EndingDate :=
               DepreciationCalculation.ToMorrow(
                 GenJnlLine."FA Posting Date",
                 DeprBook."Fiscal Year 365 Days",
                 DeprBook."Use Accounting Period");
            if DeprBook."Fiscal Year 365 Days" then
                StartingDate := CalcDate(StrSubstNo('<-%1D>', GenJnlLine."No. of Depreciation Days"), EndingDate)
            else begin
                StartingDate := CalcDate(StrSubstNo('<-%1M>', GenJnlLine."No. of Depreciation Days" div 30), EndingDate);
                StartingDate := CalcDate(StrSubstNo('<-%1D>', GenJnlLine."No. of Depreciation Days" mod 30), StartingDate);
            end;

            IsHandled := false;
            OnCheckFADepAcrossFiscalYearOnBeforeCheckAccPeriod(StartingDate, GenJnlLine, IsHandled);
            if IsHandled then
                exit;

            AccPeriod.SetFilter("Starting Date", '>%1&<=%2', AccountingPeriodMgt.FindFiscalYear(StartingDate), GenJnlLine."FA Posting Date");
            AccPeriod.SetRange("New Fiscal Year", true);
            if not AccPeriod.IsEmpty() then
                Error(Text019Err);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFAJnlLine(var FAJnlLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetGLIntegration(FAPostingType: Enum "FA Journal Line FA Posting Type"; var GLIntegration: Boolean; var GnlJnlPosting: Boolean; DeprBook: Record "Depreciation Book"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFAPostingDate(GenJournalLine: Record "Gen. Journal Line"; FAJournalLine: Record "FA Journal Line"; DepreciationBook: Record "Depreciation Book"; var IsHandled: Boolean; FADepreciationBook: Record "FA Depreciation Book"; GenJnlPosting: Boolean; var FAPostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckJobNo(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAccountNo(var GenJournalLine: Record "Gen. Journal Line"; var FANo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBalAccountNo(var GenJournalLine: Record "Gen. Journal Line"; var FANo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckConsistencyOnAfterCalcShouldCheckNoOfDepreciationDays(GenJournalLine: Record "Gen. Journal Line"; FieldErrorText: Text[250]; var ShouldCheckNoOfDepreciationDays: Boolean; FAJournalLine: Record "FA Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckConsistencyOnBeforeCheckQuantity(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean; var FAJournalLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckFAJnlLineOnBeforeCheckJnlLine(var FAJournalLine2: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckConsistencyFAJnlPosting(var FAJnlLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckMainAsset(GenJournalLine: Record "Gen. Journal Line"; FAJournalLine: Record "FA Journal Line"; DepreciationBook: Record "Depreciation Book"; FixedAsset: Record "Fixed Asset"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFAJnlLine(FAJournalLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFAIntegration(FAJournalLineFAPostingType: Enum "FA Journal Line FA Posting Type"; var GnlJnlPosting: Boolean; var FAJournalLine: Record "FA Journal Line"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckJnlLineOnAfterGetGlobals(var FixedAsset: Record "Fixed Asset"; var FASetup: Record "FA Setup"; var DepreciationBook: Record "Depreciation Book"; var FADepreciationBook: Record "FA Depreciation Book")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetGenJournalLineValuesBeforeConsistencyCheck(var IsHandled: Boolean; GenJnlPosting: Boolean; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckFADepAcrossFiscalYearOnBeforeCheckAccPeriod(var StartingDate: Date; var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

}

