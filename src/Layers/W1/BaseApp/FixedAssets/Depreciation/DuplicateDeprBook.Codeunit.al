// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Setup;

codeunit 5640 "Duplicate Depr. Book"
{

    trigger OnRun()
    begin
    end;

    var
        FA: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        FAJnlSetup: Record "FA Journal Setup";
        GenJnlLine2: Record "Gen. Journal Line";
        FAJnlLine2: Record "FA Journal Line";
        DeprBook: Record "Depreciation Book";
        FAGetJnl: Codeunit "FA Get Journal";
        InsuranceJnlPostLine: Codeunit "Insurance Jnl.-Post Line";
        FAAmount: Decimal;
        DuplicateInGenJnl: Boolean;
        TemplateName: Code[10];
        BatchName: Code[10];
        ExchangeRate: Decimal;
        NextLineNo: Integer;

    procedure DuplicateGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; FAAmount2: Decimal)
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        OnBeforeGenJnlLineDuplicate(GenJnlLine, FAAmount2);

        FAAmount := FAAmount2;
        DeprBook.Get(GenJnlLine."Depreciation Book Code");
        if GenJnlLine."Insurance No." <> '' then
            InsertInsurance(true, GenJnlLine, FAJnlLine2);
        if (GenJnlLine."Duplicate in Depreciation Book" = '') and
            (not GenJnlLine."Use Duplication List")
        then
            exit;
        ExchangeRate := GetExchangeRate(GenJnlLine."Account No.", DeprBook);
        if GenJnlLine."Duplicate in Depreciation Book" <> '' then begin
            DeprBook.Get(GenJnlLine."Duplicate in Depreciation Book");
            CreateLine(true, GenJnlLine, FAJnlLine2);
            OnDuplicateGenJnlLineOnAfterCreateLine(GenJnlLine);
            exit;
        end;
        if GenJnlLine."Use Duplication List" then
            if DeprBook.Find('-') then
                repeat
                    if DeprBook."Part of Duplication List" and (DeprBook.Code <> GenJnlLine."Depreciation Book Code") then
                        if FADeprBook.Get(GenJnlLine."Account No.", DeprBook.Code) then
                            CreateLine(true, GenJnlLine, FAJnlLine2);
                until DeprBook.Next() = 0;
    end;

    procedure DuplicateFAJnlLine(var FAJnlLine: Record "FA Journal Line")
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        DeprBook.Get(FAJnlLine."Depreciation Book Code");
        if FAJnlLine."Insurance No." <> '' then
            InsertInsurance(false, GenJnlLine2, FAJnlLine);
        if (FAJnlLine."Duplicate in Depreciation Book" = '') and
            (not FAJnlLine."Use Duplication List")
        then
            exit;
        FA.Get(FAJnlLine."FA No.");
        ExchangeRate := GetExchangeRate(FAJnlLine."FA No.", DeprBook);
        if FAJnlLine."Duplicate in Depreciation Book" <> '' then begin
            DeprBook.Get(FAJnlLine."Duplicate in Depreciation Book");
            CreateLine(false, GenJnlLine2, FAJnlLine);
            exit;
        end;
        if FAJnlLine."Use Duplication List" then
            if DeprBook.Find('-') then
                repeat
                    if DeprBook."Part of Duplication List" and (DeprBook.Code <> FAJnlLine."Depreciation Book Code") then
                        if FADeprBook.Get(FA."No.", DeprBook.Code) then
                            CreateLine(false, GenJnlLine2, FAJnlLine);
                until DeprBook.Next() = 0;
    end;

    local procedure InsertInsurance(GenJnlPosting: Boolean; GenJnlLine: Record "Gen. Journal Line"; FAJnlLine: Record "FA Journal Line")
    var
        InsuranceJnlLine: Record "Insurance Journal Line";
    begin
        FASetup.Get();
        FASetup.TestField("Insurance Depr. Book", DeprBook.Code);
        InsuranceJnlLine.Init();
        InsuranceJnlLine."Line No." := 0;
        if not FASetup."Automatic Insurance Posting" then
            InitInsuranceJnlLine(InsuranceJnlLine);

        if GenJnlPosting then begin
            if FASetup."Automatic Insurance Posting" then begin
                InsuranceJnlLine."Journal Batch Name" := GenJnlLine."Journal Batch Name";
                InsuranceJnlLine."Source Code" := GenJnlLine."Source Code";
                InsuranceJnlLine."Reason Code" := GenJnlLine."Reason Code"
            end;
            InsuranceJnlLine.Validate("Insurance No.", GenJnlLine."Insurance No.");
            InsuranceJnlLine.Validate("FA No.", GenJnlLine."Account No.");
            InsuranceJnlLine."Posting Date" := GenJnlLine."FA Posting Date";
            if InsuranceJnlLine."Posting Date" = 0D then
                InsuranceJnlLine."Posting Date" := GenJnlLine."Posting Date";
            InsuranceJnlLine.Validate(Amount, FAAmount);
            InsuranceJnlLine."Document Type" := GenJnlLine."Document Type";
            InsuranceJnlLine."Document Date" := GenJnlLine."Document Date";
            if InsuranceJnlLine."Document Date" = 0D then
                InsuranceJnlLine."Document Date" := InsuranceJnlLine."Posting Date";
            InsuranceJnlLine."Document No." := GenJnlLine."Document No.";
            InsuranceJnlLine."External Document No." := GenJnlLine."External Document No.";
            if not DeprBook."Use Default Dimension" then begin
                InsuranceJnlLine."Shortcut Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
                InsuranceJnlLine."Shortcut Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
                InsuranceJnlLine."Dimension Set ID" := GenJnlLine."Dimension Set ID";
            end;
        end;
        if not GenJnlPosting then begin
            if FASetup."Automatic Insurance Posting" then begin
                InsuranceJnlLine."Journal Batch Name" := FAJnlLine."Journal Batch Name";
                InsuranceJnlLine."Source Code" := FAJnlLine."Source Code";
                InsuranceJnlLine."Reason Code" := FAJnlLine."Reason Code"
            end;
            InsuranceJnlLine.Validate("Insurance No.", FAJnlLine."Insurance No.");
            InsuranceJnlLine.Validate("FA No.", FAJnlLine."FA No.");
            InsuranceJnlLine."Posting Date" := FAJnlLine."FA Posting Date";
            InsuranceJnlLine.Validate(Amount, FAJnlLine.Amount);
            InsuranceJnlLine."Document Type" := FAJnlLine."Document Type";
            InsuranceJnlLine."Document Date" := FAJnlLine."Document Date";
            if InsuranceJnlLine."Document Date" = 0D then
                InsuranceJnlLine."Document Date" := InsuranceJnlLine."Posting Date";
            InsuranceJnlLine."Document No." := FAJnlLine."Document No.";
            InsuranceJnlLine."External Document No." := FAJnlLine."External Document No.";
            if not DeprBook."Use Default Dimension" then begin
                InsuranceJnlLine."Shortcut Dimension 1 Code" := FAJnlLine."Shortcut Dimension 1 Code";
                InsuranceJnlLine."Shortcut Dimension 2 Code" := FAJnlLine."Shortcut Dimension 2 Code";
                InsuranceJnlLine."Dimension Set ID" := FAJnlLine."Dimension Set ID";
            end;
        end;
        if FASetup."Automatic Insurance Posting" then
            InsuranceJnlPostLine.RunWithCheck(InsuranceJnlLine)
        else begin
            InsuranceJnlLine."Line No." := NextLineNo;
            if DeprBook."Use Default Dimension" then
                InsuranceJnlLine.CreateDimFromDefaultDim();
            InsuranceJnlLine.Insert(true);
        end;
    end;

    procedure InitInsuranceJnlLine(var InsuranceJnlLine: Record "Insurance Journal Line")
    var
        InsuranceJnlLine2: Record "Insurance Journal Line";
    begin
        FAGetJnl.InsuranceJnlName(DeprBook.Code, TemplateName, BatchName);
        InsuranceJnlLine."Journal Template Name" := TemplateName;
        InsuranceJnlLine."Journal Batch Name" := BatchName;
        InsuranceJnlLine.LockTable();
        FAGetJnl.SetInsuranceJnlRange(InsuranceJnlLine2, TemplateName, BatchName);
        NextLineNo := InsuranceJnlLine2."Line No." + 10000;
        InsuranceJnlLine."Posting No. Series" := FAJnlSetup.GetInsuranceNoSeries(InsuranceJnlLine);
    end;

    local procedure CreateLine(GenJnlPosting: Boolean; var GenJnlLine: Record "Gen. Journal Line"; var FAJnlLine: Record "FA Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateLine(GenJnlPosting, GenJnlLine, FAJnlLine, DuplicateInGenJnl, TemplateName, BatchName, FAGetJnl, DeprBook, IsHandled);
        if IsHandled then
            exit;

        if GenJnlPosting then begin
            DuplicateInGenJnl := true;
            TemplateName := GenJnlLine."Journal Template Name";
            BatchName := GenJnlLine."Journal Batch Name";
            FAGetJnl.JnlName(
                DeprBook.Code, false, Enum::"FA Journal Line FA Posting Type".FromInteger(GenJnlLine."FA Posting Type".AsInteger() - 1),
                DuplicateInGenJnl, TemplateName, BatchName);
        end;
        if not GenJnlPosting then begin
            FA.Get(FAJnlLine."FA No.");
            DuplicateInGenJnl := false;
            TemplateName := FAJnlLine."Journal Template Name";
            BatchName := FAJnlLine."Journal Batch Name";
            FAGetJnl.JnlName(
              DeprBook.Code, FA."Budgeted Asset", FAJnlLine."FA Posting Type",
              DuplicateInGenJnl, TemplateName, BatchName);
        end;
        InsertLine(GenJnlPosting, DuplicateInGenJnl, GenJnlLine, FAJnlLine);
    end;

    local procedure MakeGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var FAJnlLine: Record "FA Journal Line")
    begin
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
        GenJnlLine."Account No." := FAJnlLine."FA No.";
        GenJnlLine."Depreciation Book Code" := FAJnlLine."Depreciation Book Code";
        GenJnlLine."FA Posting Type" := Enum::"Gen. Journal Line FA Posting Type".FromInteger(FAJnlLine."FA Posting Type".AsInteger() + 1);
        GenJnlLine."FA Posting Date" := FAJnlLine."FA Posting Date";
        GenJnlLine."Posting Date" := FAJnlLine."Posting Date";
        if GenJnlLine."Posting Date" = GenJnlLine."FA Posting Date" then
            GenJnlLine."FA Posting Date" := 0D;
        GenJnlLine."Document Type" := FAJnlLine."Document Type";
        GenJnlLine."Document Date" := FAJnlLine."Document Date";
        GenJnlLine."Document No." := FAJnlLine."Document No.";
        GenJnlLine."External Document No." := FAJnlLine."External Document No.";
        GenJnlLine.Description := FAJnlLine.Description;
        GenJnlLine.Validate(Amount, FAJnlLine.Amount);
        GenJnlLine."Salvage Value" := FAJnlLine."Salvage Value";
        GenJnlLine.Quantity := FAJnlLine.Quantity;
        GenJnlLine.Validate(Correction, FAJnlLine.Correction);
        GenJnlLine."No. of Depreciation Days" := FAJnlLine."No. of Depreciation Days";
        GenJnlLine."Depr. until FA Posting Date" := FAJnlLine."Depr. until FA Posting Date";
        GenJnlLine."Depr. Acquisition Cost" := FAJnlLine."Depr. Acquisition Cost";
        GenJnlLine."Posting Group" := FAJnlLine."FA Posting Group";
        GenJnlLine."Maintenance Code" := FAJnlLine."Maintenance Code";
        GenJnlLine."Shortcut Dimension 1 Code" := FAJnlLine."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := FAJnlLine."Shortcut Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := FAJnlLine."Dimension Set ID";
        GenJnlLine."Budgeted FA No." := FAJnlLine."Budgeted FA No.";
        GenJnlLine."FA Reclassification Entry" := FAJnlLine."FA Reclassification Entry";
        GenJnlLine."Index Entry" := FAJnlLine."Index Entry";

        OnAfterMakeGenJnlLine(GenJnlLine, FAJnlLine);
    end;

    local procedure MakeFAJnlLine(var FAJnlLine: Record "FA Journal Line"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        FAJnlLine."Depreciation Book Code" := GenJnlLine."Depreciation Book Code";
        FAJnlLine."FA Posting Type" := Enum::"FA Journal Line FA Posting Type".FromInteger(GenJnlLine."FA Posting Type".AsInteger() - 1);
        FAJnlLine."FA No." := GenJnlLine."Account No.";
        FAJnlLine."FA Posting Date" := GenJnlLine."FA Posting Date";
        FAJnlLine."Posting Date" := GenJnlLine."Posting Date";
        if FAJnlLine."Posting Date" = FAJnlLine."FA Posting Date" then
            FAJnlLine."Posting Date" := 0D;
        FAJnlLine."Document Type" := GenJnlLine."Document Type";
        FAJnlLine."Document Date" := GenJnlLine."Document Date";
        FAJnlLine."Document No." := GenJnlLine."Document No.";
        FAJnlLine."External Document No." := GenJnlLine."External Document No.";
        FAJnlLine.Description := GenJnlLine.Description;
        FAJnlLine.Validate(Amount, FAAmount);
        FAJnlLine."Salvage Value" := GenJnlLine."Salvage Value";
        FAJnlLine.Quantity := GenJnlLine.Quantity;
        FAJnlLine.Validate(Correction, GenJnlLine.Correction);
        FAJnlLine."No. of Depreciation Days" := GenJnlLine."No. of Depreciation Days";
        FAJnlLine."Depr. until FA Posting Date" := GenJnlLine."Depr. until FA Posting Date";
        FAJnlLine."Depr. Acquisition Cost" := GenJnlLine."Depr. Acquisition Cost";
        FAJnlLine."FA Posting Group" := GenJnlLine."Posting Group";
        FAJnlLine."Maintenance Code" := GenJnlLine."Maintenance Code";
        FAJnlLine."Shortcut Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
        FAJnlLine."Shortcut Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
        FAJnlLine."Dimension Set ID" := GenJnlLine."Dimension Set ID";
        FAJnlLine."Budgeted FA No." := GenJnlLine."Budgeted FA No.";
        FAJnlLine."FA Reclassification Entry" := GenJnlLine."FA Reclassification Entry";
        FAJnlLine."Index Entry" := GenJnlLine."Index Entry";

        OnAfterMakeFAJnlLine(FAJnlLine, GenJnlLine);
    end;

    local procedure AdjustGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        GenJnlLine2 := GenJnlLine;

        GenJnlLine.Init();
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
        GenJnlLine."Depreciation Book Code" := GenJnlLine2."Depreciation Book Code";
        GenJnlLine."FA Posting Type" := GenJnlLine2."FA Posting Type";
        GenJnlLine."Account No." := GenJnlLine2."Account No.";
        GenJnlLine."FA Posting Date" := GenJnlLine2."FA Posting Date";
        GenJnlLine."Posting Date" := GenJnlLine2."Posting Date";
        if GenJnlLine."Posting Date" = GenJnlLine."FA Posting Date" then
            GenJnlLine."FA Posting Date" := 0D;
        GenJnlLine."Document Type" := GenJnlLine2."Document Type";
        GenJnlLine."Document Date" := GenJnlLine2."Document Date";
        GenJnlLine."Document No." := GenJnlLine2."Document No.";
        GenJnlLine."External Document No." := GenJnlLine2."External Document No.";
        GenJnlLine.Description := GenJnlLine2.Description;
        GenJnlLine.Validate(Amount, FAAmount);
        GenJnlLine."Salvage Value" := GenJnlLine2."Salvage Value";
        GenJnlLine.Quantity := GenJnlLine2.Quantity;
        GenJnlLine.Validate(Correction, GenJnlLine2.Correction);
        GenJnlLine."No. of Depreciation Days" := GenJnlLine2."No. of Depreciation Days";
        GenJnlLine."Depr. until FA Posting Date" := GenJnlLine2."Depr. until FA Posting Date";
        GenJnlLine."Depr. Acquisition Cost" := GenJnlLine2."Depr. Acquisition Cost";
        GenJnlLine."Posting Group" := GenJnlLine2."Posting Group";
        GenJnlLine."Maintenance Code" := GenJnlLine2."Maintenance Code";
        GenJnlLine."Shortcut Dimension 1 Code" := GenJnlLine2."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := GenJnlLine2."Shortcut Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := GenJnlLine2."Dimension Set ID";
        GenJnlLine."Budgeted FA No." := GenJnlLine2."Budgeted FA No.";
        GenJnlLine."FA Reclassification Entry" := GenJnlLine2."FA Reclassification Entry";
        GenJnlLine."Index Entry" := GenJnlLine2."Index Entry";

        OnAfterAdjustGenJnlLine(GenJnlLine, GenJnlLine2);
    end;

    local procedure AdjustFAJnlLine(var FAJnlLine: Record "FA Journal Line")
    var
        FAJnlLine2: Record "FA Journal Line";
    begin
        FAJnlLine2 := FAJnlLine;

        FAJnlLine.Init();
        FAJnlLine."FA No." := FAJnlLine2."FA No.";
        FAJnlLine."Depreciation Book Code" := FAJnlLine2."Depreciation Book Code";
        FAJnlLine."FA Posting Type" := FAJnlLine2."FA Posting Type";
        FAJnlLine."FA Posting Date" := FAJnlLine2."FA Posting Date";
        FAJnlLine."Posting Date" := FAJnlLine2."Posting Date";
        if FAJnlLine."Posting Date" = FAJnlLine."FA Posting Date" then
            FAJnlLine."Posting Date" := 0D;
        FAJnlLine."Document Type" := FAJnlLine2."Document Type";
        FAJnlLine."Document Date" := FAJnlLine2."Document Date";
        FAJnlLine."Document No." := FAJnlLine2."Document No.";
        FAJnlLine."External Document No." := FAJnlLine2."External Document No.";
        FAJnlLine.Description := FAJnlLine2.Description;
        FAJnlLine.Validate(Amount, FAJnlLine2.Amount);
        FAJnlLine."Salvage Value" := FAJnlLine2."Salvage Value";
        FAJnlLine.Quantity := FAJnlLine2.Quantity;
        FAJnlLine.Validate(Correction, FAJnlLine2.Correction);
        FAJnlLine."No. of Depreciation Days" := FAJnlLine2."No. of Depreciation Days";
        FAJnlLine."Depr. until FA Posting Date" := FAJnlLine2."Depr. until FA Posting Date";
        FAJnlLine."Depr. Acquisition Cost" := FAJnlLine2."Depr. Acquisition Cost";
        FAJnlLine."FA Posting Group" := FAJnlLine2."FA Posting Group";
        FAJnlLine."Maintenance Code" := FAJnlLine2."Maintenance Code";
        FAJnlLine."Shortcut Dimension 1 Code" := FAJnlLine2."Shortcut Dimension 1 Code";
        FAJnlLine."Shortcut Dimension 2 Code" := FAJnlLine2."Shortcut Dimension 2 Code";
        FAJnlLine."Dimension Set ID" := FAJnlLine2."Dimension Set ID";
        FAJnlLine."Budgeted FA No." := FAJnlLine2."Budgeted FA No.";
        FAJnlLine."FA Reclassification Entry" := FAJnlLine2."FA Reclassification Entry";
        FAJnlLine."Index Entry" := FAJnlLine2."Index Entry";

        OnAfterAdjustFAJnlLine(FAJnlLine, FAJnlLine2);
    end;

    local procedure CalcExchangeRateAmount(DuplicateInGenJnl: Boolean; FANo: Code[20]; var GenJnlLine: Record "Gen. Journal Line"; var FAJnlLine: Record "FA Journal Line")
    var
        ExchangeRate2: Decimal;
    begin
        if not DeprBook."Use FA Exch. Rate in Duplic." then
            exit;
        ExchangeRate2 := ExchangeRate / GetExchangeRate(FANo, DeprBook);
        if DuplicateInGenJnl then begin
            GenJnlLine.Validate(Amount, Round(GenJnlLine.Amount * ExchangeRate2));
            GenJnlLine.Validate("Salvage Value", Round(GenJnlLine."Salvage Value" * ExchangeRate2));
        end;
        if not DuplicateInGenJnl then begin
            FAJnlLine.Validate(Amount, Round(FAJnlLine.Amount * ExchangeRate2));
            FAJnlLine.Validate("Salvage Value", Round(FAJnlLine."Salvage Value" * ExchangeRate2));
        end;
    end;

    local procedure GetExchangeRate(FANo: Code[20]; var DeprBook: Record "Depreciation Book"): Decimal
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        if not DeprBook."Use FA Exch. Rate in Duplic." then
            exit(100);
        FADeprBook.Get(FANo, DeprBook.Code);
        if FADeprBook."FA Exchange Rate" > 0 then
            exit(FADeprBook."FA Exchange Rate");
        if DeprBook."Default Exchange Rate" > 0 then
            exit(DeprBook."Default Exchange Rate");
        exit(100);
    end;

    local procedure InsertLine(GenJnlPosting: Boolean; DuplicateInGenJnl: Boolean; GenJnlLine: Record "Gen. Journal Line"; FAJnlLine: Record "FA Journal Line")
    begin
        if GenJnlPosting and DuplicateInGenJnl then begin
            AdjustGenJnlLine(GenJnlLine);
            GenJnlLine."Journal Template Name" := TemplateName;
            GenJnlLine."Journal Batch Name" := BatchName;
            GenJnlLine.LockTable();
            FAGetJnl.SetGenJnlRange(GenJnlLine2, TemplateName, BatchName);
            GenJnlLine.Validate("Depreciation Book Code", DeprBook.Code);
            CalcExchangeRateAmount(DuplicateInGenJnl, GenJnlLine."Account No.", GenJnlLine, FAJnlLine);
            GenJnlLine."Posting No. Series" := FAJnlSetup.GetGenNoSeries(GenJnlLine);
            FAJnlSetup.SetGenJnlTrailCodes(GenJnlLine);
            if DeprBook."Use Default Dimension" then
                GenJnlLine.CreateDimFromDefaultDim(0);
            GenJnlLine."Line No." := GenJnlLine2."Line No." + 10000;
            OnBeforeGenJnlLineInsert(GenJnlLine, FAJnlLine, GenJnlPosting, DuplicateInGenJnl);
            GenJnlLine.Insert(true);
        end;

        if GenJnlPosting and not DuplicateInGenJnl then begin
            MakeFAJnlLine(FAJnlLine, GenJnlLine);
            FAJnlLine."Journal Template Name" := TemplateName;
            FAJnlLine."Journal Batch Name" := BatchName;
            FAJnlLine.LockTable();
            FAGetJnl.SetFAJnlRange(FAJnlLine2, TemplateName, BatchName);
            FAJnlLine.Validate("Depreciation Book Code", DeprBook.Code);
            CalcExchangeRateAmount(DuplicateInGenJnl, FAJnlLine."FA No.", GenJnlLine, FAJnlLine);
            FAJnlLine."Posting No. Series" := FAJnlSetup.GetFANoSeries(FAJnlLine);
            FAJnlSetup.SetFAJnlTrailCodes(FAJnlLine);
            if DeprBook."Use Default Dimension" then
                FAJnlLine.CreateDimFromDefaultDim();
            FAJnlLine."Line No." := FAJnlLine2."Line No." + 10000;
            OnBeforeFAJnlLineInsert(GenJnlLine, FAJnlLine, GenJnlPosting, DuplicateInGenJnl, DeprBook);
            FAJnlLine.Insert(true);
        end;

        if not GenJnlPosting and DuplicateInGenJnl then begin
            MakeGenJnlLine(GenJnlLine, FAJnlLine);
            GenJnlLine."Journal Template Name" := TemplateName;
            GenJnlLine."Journal Batch Name" := BatchName;
            GenJnlLine.LockTable();
            FAGetJnl.SetGenJnlRange(GenJnlLine2, TemplateName, BatchName);
            GenJnlLine.Validate("Depreciation Book Code", DeprBook.Code);
            CalcExchangeRateAmount(DuplicateInGenJnl, GenJnlLine."Account No.", GenJnlLine, FAJnlLine);
            GenJnlLine."Posting No. Series" := FAJnlSetup.GetGenNoSeries(GenJnlLine);
            FAJnlSetup.SetGenJnlTrailCodes(GenJnlLine);
            if DeprBook."Use Default Dimension" then
                GenJnlLine.CreateDimFromDefaultDim(0);
            GenJnlLine."Line No." := GenJnlLine2."Line No." + 10000;
            OnBeforeGenJnlLineInsert(GenJnlLine, FAJnlLine, GenJnlPosting, DuplicateInGenJnl);
            GenJnlLine.Insert(true);
        end;

        if not GenJnlPosting and not DuplicateInGenJnl then begin
            AdjustFAJnlLine(FAJnlLine);
            FAJnlLine."Journal Template Name" := TemplateName;
            FAJnlLine."Journal Batch Name" := BatchName;
            FAJnlLine.LockTable();
            FAGetJnl.SetFAJnlRange(FAJnlLine2, TemplateName, BatchName);
            FAJnlLine.Validate("Depreciation Book Code", DeprBook.Code);
            CalcExchangeRateAmount(DuplicateInGenJnl, FAJnlLine."FA No.", GenJnlLine, FAJnlLine);
            FAJnlLine."Posting No. Series" := FAJnlSetup.GetFANoSeries(FAJnlLine);
            FAJnlSetup.SetFAJnlTrailCodes(FAJnlLine);
            if DeprBook."Use Default Dimension" then
                FAJnlLine.CreateDimFromDefaultDim();
            FAJnlLine."Line No." := FAJnlLine2."Line No." + 10000;
            OnBeforeFAJnlLineInsert(GenJnlLine, FAJnlLine, GenJnlPosting, DuplicateInGenJnl, DeprBook);
            FAJnlLine.Insert(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAdjustGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalLine2: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAdjustFAJnlLine(var FAJournalLine: Record "FA Journal Line"; var FAJournalLine2: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMakeGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var FAJnlLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMakeFAJnlLine(var FAJnlLine: Record "FA Journal Line"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateLine(GenJnlPosting: Boolean; var GenJournalLine: Record "Gen. Journal Line"; var FAJournalLine: Record "FA Journal Line"; var DuplicateInGenJnl: Boolean; var TemplateName: Code[10]; var BatchName: Code[10]; var FAGetJournal: Codeunit "FA Get Journal"; DepreciationBook: Record "Depreciation Book"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; var FAJournalLine: Record "FA Journal Line"; GenJnlPosting: Boolean; DuplicateInGenJnl: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFAJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; var FAJournalLine: Record "FA Journal Line"; GenJnlPosting: Boolean; DuplicateInGenJnl: Boolean; DepreciationBook: Record "Depreciation Book")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineDuplicate(var GenJournalLine: Record "Gen. Journal Line"; var FAAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDuplicateGenJnlLineOnAfterCreateLine(GenJnlLine: Record "Gen. Journal Line")
    begin
    end;
}

