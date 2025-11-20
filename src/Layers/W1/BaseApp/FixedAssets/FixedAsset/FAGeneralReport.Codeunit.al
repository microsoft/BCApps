// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.FixedAsset;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Ledger;

codeunit 5626 "FA General Report"
{
    Permissions = TableData "Fixed Asset" = rm;

    trigger OnRun()
    begin
    end;

    var
        FADeprBook: Record "FA Depreciation Book";
        FALedgEntry: Record "FA Ledger Entry";
        DepreciationCalc: Codeunit "Depreciation Calculation";

#pragma warning disable AA0074
        Text000: Label 'Posting Date Filter';
        Text001: Label 'You must specify the Starting Date and the Ending Date.';
        Text002: Label 'The Starting Date is later than the Ending Date.';
        Text003: Label 'You must not specify closing dates.';
        Text004: Label 'You must specify the First Depreciation Date and the Last Depreciation Date.';
        Text005: Label 'The First Depreciation Date is later than the Last Depreciation Date.';
        Text006: Label 'Sorting fixed assets';
#pragma warning restore AA0074

    procedure GetLastDate(FANo: Code[20]; PostingType: Integer; EndingDate: Date; DeprBookCode: Code[10]; GLEntry: Boolean): Date
    var
        FirstLast: Text[1];
    begin
        ClearAll();
        if PostingType = 0 then
            exit(0D);
        if EndingDate = 0D then
            EndingDate := DMY2Date(31, 12, 9999);
        FALedgEntry.Reset();
        if GLEntry then begin
            FALedgEntry.SetCurrentKey(
              "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Posting Date");
            FALedgEntry.SetRange("Depreciation Book Code", DeprBookCode);
            FALedgEntry.SetRange("FA No.", FANo);
            FALedgEntry.SetRange("FA Posting Category", FALedgEntry."FA Posting Category"::" ");
            FALedgEntry.SetRange("Posting Date", 0D, EndingDate);
        end else begin
            DepreciationCalc.SetFAFilter(FALedgEntry, FANo, DeprBookCode, true);
            FALedgEntry.SetRange("FA Posting Date", 0D, EndingDate);
        end;
        FirstLast := '+';
        case PostingType of
            FADeprBook.FieldNo("Last Acquisition Cost Date"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Acquisition Cost");
            FADeprBook.FieldNo("Last Depreciation Date"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::Depreciation);
            FADeprBook.FieldNo("Last Write-Down Date"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Write-Down");
            FADeprBook.FieldNo("Last Appreciation Date"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::Appreciation);
            FADeprBook.FieldNo("Last Custom 1 Date"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Custom 1");
            FADeprBook.FieldNo("Last Custom 2 Date"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Custom 2");
            FADeprBook.FieldNo("Last Salvage Value Date"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Salvage Value");
            FADeprBook.FieldNo("Acquisition Date"),
            FADeprBook.FieldNo("G/L Acquisition Date"):
                begin
                    FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Acquisition Cost");
                    FirstLast := '-';
                end;
            FADeprBook.FieldNo("Disposal Date"):
                begin
                    FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Proceeds on Disposal");
                    FirstLast := '-';
                end;
        end;

        OnGetLastDateOnAfterFALedgEntrySetFilters(FALedgEntry, FADeprBook, PostingType, FirstLast);
        if FALedgEntry.Find(FirstLast) then begin
            if GLEntry then
                exit(FALedgEntry."Posting Date");

            exit(FALedgEntry."FA Posting Date");
        end;
        exit(0D);
    end;

    procedure CalcFAPostedAmount(FANo: Code[20]; PostingType: Integer; Period: Option "Before Starting Date","Net Change","at Ending Date"; StartingDate: Date; EndingDate: Date; DeprBookCode: Code[10]; BeforeAmount: Decimal; UntilAmount: Decimal; OnlyReclassified: Boolean; OnlyBookValue: Boolean) Result: Decimal
    begin
        ClearAll();
        if PostingType = 0 then
            exit(0);
        if EndingDate = 0D then
            EndingDate := DMY2Date(31, 12, 9999);
        case PostingType of
            FADeprBook.FieldNo("Book Value"):
                FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "Part of Book Value");
            FADeprBook.FieldNo("Depreciable Basis"):
                FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "Part of Depreciable Basis");
            else begin
                FALedgEntry.SetCurrentKey(
                  "FA No.", "Depreciation Book Code",
                  "FA Posting Category", "FA Posting Type", "FA Posting Date");
                FALedgEntry.SetRange("FA Posting Category", FALedgEntry."FA Posting Category"::" ");
            end;
        end;
        FALedgEntry.SetRange("FA No.", FANo);
        FALedgEntry.SetRange("Depreciation Book Code", DeprBookCode);
        if OnlyReclassified then
            FALedgEntry.SetRange("Reclassification Entry", true);
        if OnlyBookValue then
            FALedgEntry.SetRange("Part of Book Value", true);
        case PostingType of
            FADeprBook.FieldNo("Acquisition Cost"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Acquisition Cost");
            FADeprBook.FieldNo(Depreciation):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::Depreciation);
            FADeprBook.FieldNo("Write-Down"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Write-Down");
            FADeprBook.FieldNo(Appreciation):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::Appreciation);
            FADeprBook.FieldNo("Custom 1"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Custom 1");
            FADeprBook.FieldNo("Custom 2"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Custom 2");
            FADeprBook.FieldNo("Proceeds on Disposal"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Proceeds on Disposal");
            FADeprBook.FieldNo("Gain/Loss"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Gain/Loss");
            FADeprBook.FieldNo("Salvage Value"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Salvage Value");
            FADeprBook.FieldNo("Book Value"):
                FALedgEntry.SetRange("Part of Book Value", true);
            FADeprBook.FieldNo("Depreciable Basis"):
                FALedgEntry.SetRange("Part of Depreciable Basis", true);
        end;
        OnBeforeCalcFAPostedAmount(FALedgEntry, PostingType);
        case Period of
            Period::"Before Starting Date":
                FALedgEntry.SetRange("FA Posting Date", 0D, StartingDate - 1);
            Period::"Net Change":
                FALedgEntry.SetRange("FA Posting Date", StartingDate, EndingDate);
            Period::"at Ending Date":
                FALedgEntry.SetRange("FA Posting Date", 0D, EndingDate);
        end;
        FALedgEntry.CalcSums(Amount);

        if (PostingType = FADeprBook.FieldNo("Book Value")) or
           (PostingType = FADeprBook.FieldNo(Depreciation))
        then
            case Period of
                Period::"Before Starting Date":
                    FALedgEntry.Amount := FALedgEntry.Amount + BeforeAmount;
                Period::"Net Change":
                    FALedgEntry.Amount := FALedgEntry.Amount - BeforeAmount + UntilAmount;
                Period::"at Ending Date":
                    FALedgEntry.Amount := FALedgEntry.Amount + UntilAmount;
            end;
        Result := FALedgEntry.Amount;

        OnAfterCalcFAPostedAmount(FALedgEntry, PostingType, Period, BeforeAmount, UntilAmount, Result);
    end;

    procedure CalcGLPostedAmount(FANo: Code[20]; PostingType: Integer; Period: Option " ",Disposal,"Bal. Disposal"; StartingDate: Date; EndingDate: Date; DeprBookCode: Code[10]): Decimal
    begin
        ClearAll();
        if PostingType = 0 then
            exit(0);
        if EndingDate = 0D then
            EndingDate := DMY2Date(31, 12, 9999);
        FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Posting Date");
        FALedgEntry.SetRange("FA No.", FANo);
        FALedgEntry.SetRange("Depreciation Book Code", DeprBookCode);
        FALedgEntry.SetRange("FA Posting Category", Period);
        FALedgEntry.SetRange("Posting Date", StartingDate, EndingDate);
        case PostingType of
            FADeprBook.FieldNo("Acquisition Cost"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Acquisition Cost");
            FADeprBook.FieldNo(Depreciation):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::Depreciation);
            FADeprBook.FieldNo("Write-Down"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Write-Down");
            FADeprBook.FieldNo(Appreciation):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::Appreciation);
            FADeprBook.FieldNo("Custom 1"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Custom 1");
            FADeprBook.FieldNo("Custom 2"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Custom 2");
            FADeprBook.FieldNo("Proceeds on Disposal"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Proceeds on Disposal");
            FADeprBook.FieldNo("Gain/Loss"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Gain/Loss");
            FADeprBook.FieldNo("Book Value on Disposal"):
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Book Value on Disposal");
        end;
        OnCalcGLPostedAmountOnBeforeCalcAmount(FALedgEntry, PostingType);
        FALedgEntry.CalcSums(Amount);

        OnCalcGLPostedAmountOnAfterCalcAmount(FALedgEntry, PostingType, FALedgEntry.Amount);

        exit(FALedgEntry.Amount);
    end;

    procedure AppendFAPostingFilter(var FA: Record "Fixed Asset"; StartingDate: Date; EndingDate: Date)
    begin
        if (StartingDate = 0D) and (EndingDate = 0D) then
            exit;
        if StartingDate = 0D then
            FA.SetFilter("FA Posting Date Filter", '..%1', EndingDate)
        else
            if EndingDate = 0D then
                FA.SetFilter("FA Posting Date Filter", '%1..', StartingDate)
            else
                FA.SetFilter("FA Posting Date Filter", '%1..%2', StartingDate, EndingDate);
    end;

    procedure AppendPostingDateFilter(var FAFilter: Text; StartingDate: Date; EndingDate: Date)
    var
        PostingDateFilter: Text[50];
    begin
        PostingDateFilter := StrSubstNo('%1: %2..%3', Text000, StartingDate, EndingDate);
        if FAFilter = '' then
            FAFilter := PostingDateFilter
        else
            FAFilter := FAFilter + StrSubstNo('%1 %2', ',', PostingDateFilter);
    end;

    procedure ValidateDates(StartingDate: Date; EndingDate: Date)
    begin
        if (EndingDate = 0D) or (StartingDate <= 00000101D) then
            Error(Text001);

        if StartingDate > EndingDate then
            Error(Text002);

        if (NormalDate(StartingDate) <> StartingDate) or (NormalDate(EndingDate) <> EndingDate) then
            Error(Text003);
    end;

    procedure ValidateDeprDates(StartingDate: Date; EndingDate: Date)
    begin
        if (EndingDate = 0D) or (StartingDate <= 00000101D) then
            Error(Text004);

        if StartingDate > EndingDate then
            Error(Text005);

        if (NormalDate(StartingDate) <> StartingDate) or (NormalDate(EndingDate) <> EndingDate) then
            Error(Text003);
    end;

    procedure SetFAPostingGroup(var FA2: Record "Fixed Asset"; DeprBookCode: Code[10])
    var
        FA: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        Window: Dialog;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetFAPostingGroup(FA2, DeprBookCode, IsHandled);
        if IsHandled then
            exit;

        Window.Open(Text006);
        FA.LockTable();
        FA.Copy(FA2);
        FA.SetRange("FA Posting Group");
        if FA.Find('-') then
            repeat
                if FADeprBook.Get(FA."No.", DeprBookCode) then
                    if FA."FA Posting Group" <> FADeprBook."FA Posting Group" then begin
                        FA."FA Posting Group" := FADeprBook."FA Posting Group";
                        FA.Modify();
                    end;
            until FA.Next() = 0;
        Commit();
        Window.Close();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcFAPostedAmount(var FALedgerEntry: Record "FA Ledger Entry"; PostingType: Integer; Period: Option "Before Starting Date","Net Change","at Ending Date"; BeforeAmount: Decimal; UntilAmount: Decimal; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcFAPostedAmount(var FALedgerEntry: Record "FA Ledger Entry"; PostingType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcGLPostedAmountOnBeforeCalcAmount(var FALedgerEntry: Record "FA Ledger Entry"; PostingType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetLastDateOnAfterFALedgEntrySetFilters(var FALedgerEntry: Record "FA Ledger Entry"; var FADeprBook: Record "FA Depreciation Book"; PostingType: Integer; FirstLast: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetFAPostingGroup(var FixedAsset: Record "Fixed Asset"; DeprBookCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcGLPostedAmountOnAfterCalcAmount(var FALedgerEntry: Record "FA Ledger Entry"; PostingType: Integer; var Amount: Decimal)
    begin
    end;
}

