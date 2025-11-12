// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Foundation.Period;

codeunit 5642 "FA Reclass. Transfer Line"
{

    trigger OnRun()
    begin
    end;

    var
        FAJnlSetup: Record "FA Journal Setup";
        OldFA: Record "Fixed Asset";
        NewFA: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        FADeprBook2: Record "FA Depreciation Book";
        GenJnlLine: Record "Gen. Journal Line";
        FAJnlLine: Record "FA Journal Line";
        DepreciationCalc: Codeunit "Depreciation Calculation";
        FAGetJnl: Codeunit "FA Get Journal";
        FAPostingType: Enum "FA Journal Line FA Posting Type";
        TransferToGenJnl: Boolean;
        TemplateName: Code[10];
        BatchName: Code[10];
        FANo: Code[20];
        TransferType: array[9] of Boolean;
        Amounts: array[9] of Decimal;
        FAJnlNextLineNo: Integer;
        GenJnlNextLineNo: Integer;
        i: Integer;
        j: Integer;
        OldNewFA: Integer;
        Sign: Integer;
        GenJnlUsedOnce: Boolean;
        FAJnlUsedOnce: Boolean;
        FAJnlDocumentNo: Code[20];
        GenJnlDocumentNo: Code[20];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'is a %1 and %2 is not a %1.';
        Text001: Label 'is not different than %1.';
        Text002: Label '%1 is disposed.';
        Text003: Label '%2 = 0 for %1.';
        Text004: Label '%2 is greater than %3 for %1.';
        Text005: Label 'It was not possible to find a %1 in %2.';
        Text006: Label '%1 must be %2 or %3 for %4.';
        Text007: Label '%1 must be %2 for %3.';
        Text008: Label 'must not be used together with %1 in %2 %3.';
        Text009: Label '%1 cannot be calculated for %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure FAReclassLine(var FAReclassJnlLine: Record "FA Reclass. Journal Line"; var Done: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFAReclassLine(FAReclassJnlLine, Done, IsHandled);
        if IsHandled then
            exit;

        if (FAReclassJnlLine."FA No." = '') and (FAReclassJnlLine."New FA No." = '') then
            exit;
        OldFA.Get(FAReclassJnlLine."FA No.");
        NewFA.Get(FAReclassJnlLine."New FA No.");
        FADeprBook.Get(FAReclassJnlLine."FA No.", FAReclassJnlLine."Depreciation Book Code");
        FADeprBook2.Get(FAReclassJnlLine."New FA No.", FAReclassJnlLine."Depreciation Book Code");
        OldFA.TestField(Blocked, false);
        NewFA.TestField(Blocked, false);
        OldFA.TestField(Inactive, false);
        NewFA.TestField(Inactive, false);

        if OldFA."Budgeted Asset" and not NewFA."Budgeted Asset" then
            FAReclassJnlLine.FieldError(
              "FA No.", StrSubstNo(Text000,
                OldFA.FieldCaption("Budgeted Asset"), FAReclassJnlLine.FieldCaption("New FA No.")));

        if NewFA."Budgeted Asset" and not OldFA."Budgeted Asset" then
            FAReclassJnlLine.FieldError(
              "New FA No.", StrSubstNo(Text000,
                NewFA.FieldCaption("Budgeted Asset"), FAReclassJnlLine.FieldCaption("FA No.")));

        if FAReclassJnlLine."FA No." = FAReclassJnlLine."New FA No." then
            FAReclassJnlLine.FieldError(
              "FA No.", StrSubstNo(Text001, FAReclassJnlLine.FieldCaption("New FA No.")));

        if FADeprBook."Disposal Date" > 0D then
            Error(Text002, FAName(OldFA, FAReclassJnlLine."Depreciation Book Code"));

        if FADeprBook2."Disposal Date" > 0D then
            Error(Text002, FAName(NewFA, FAReclassJnlLine."Depreciation Book Code"));

        SetFAReclassType(FAReclassJnlLine);
        CalcAmounts(FAReclassJnlLine);
        CalcDB1DeprAmount(FAReclassJnlLine);

        for OldNewFA := 0 to 1 do begin
            j := 0;
            while j < 9 do begin
                j := j + 1;
                if j = 7 then
                    j := 9;
                Convert(OldNewFA, j, FAPostingType, Sign, FANo);
                i := FAPostingType.AsInteger() + 1;
                TemplateName := '';
                BatchName := '';
                if TransferType[i] and (Amounts[i] <> 0) then begin
                    FAGetJnl.JnlName(
                      FAReclassJnlLine."Depreciation Book Code", OldFA."Budgeted Asset", FAPostingType,
                      TransferToGenJnl, TemplateName, BatchName);
                    SetJnlRange();
                    if TransferToGenJnl then
                        InsertGenJnlLine(FAReclassJnlLine, FANo, Sign * Amounts[i], FAReclassJnlLine."Insert Bal. Account")
                    else
                        InsertFAJnlLine(FAReclassJnlLine, FANo, Sign * Amounts[i]);
                    Done := true;
                end;
            end;
        end;
    end;

    local procedure CalcAmounts(var FAReclassJnlLine: Record "FA Reclass. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAmounts(FAReclassJnlLine, Amounts, IsHandled);
        if IsHandled then
            exit;

        FADeprBook.CalcFields("Acquisition Cost");
        if TransferType[2] then
            FADeprBook.CalcFields(Depreciation);
        if TransferType[3] then
            FADeprBook.CalcFields("Write-Down");
        if TransferType[4] then
            FADeprBook.CalcFields(Appreciation);
        if TransferType[5] then
            FADeprBook.CalcFields("Custom 1");
        if TransferType[6] then
            FADeprBook.CalcFields("Custom 2");
        if TransferType[9] then
            FADeprBook.CalcFields("Salvage Value");
        Amounts[1] := FADeprBook."Acquisition Cost";
        Amounts[2] := FADeprBook.Depreciation;
        Amounts[3] := FADeprBook."Write-Down";
        Amounts[4] := FADeprBook.Appreciation;
        Amounts[5] := FADeprBook."Custom 1";
        Amounts[6] := FADeprBook."Custom 2";
        Amounts[9] := FADeprBook."Salvage Value";
        OnCalcAmountsOnAfterSetAmounts(FADeprBook, Amounts, TransferType);
        if Amounts[1] = 0 then
            Error(Text003,
              FAName(OldFA, FADeprBook."Depreciation Book Code"), FADeprBook.FieldCaption("Acquisition Cost"));

        if FAReclassJnlLine."Reclassify Acq. Cost Amount" <> 0 then begin
            if FAReclassJnlLine."Reclassify Acq. Cost Amount" > Amounts[1] then
                Error(Text004,
                  FAName(OldFA, FAReclassJnlLine."Depreciation Book Code"),
                  FAReclassJnlLine.FieldCaption("Reclassify Acq. Cost Amount"),
                  FADeprBook.FieldCaption("Acquisition Cost"));
            FAReclassJnlLine."Reclassify Acq. Cost %" := FAReclassJnlLine."Reclassify Acq. Cost Amount" / Amounts[1] * 100;
        end;
        if FAReclassJnlLine."Reclassify Acq. Cost Amount" <> 0 then
            Amounts[1] := FAReclassJnlLine."Reclassify Acq. Cost Amount"
        else
            Amounts[1] := Round(Amounts[1] * FAReclassJnlLine."Reclassify Acq. Cost %" / 100);
        for i := 2 to 9 do
            Amounts[i] := Round(Amounts[i] * FAReclassJnlLine."Reclassify Acq. Cost %" / 100);
    end;

    local procedure SetFAReclassType(var FAReclassJnlLine: Record "FA Reclass. Journal Line")
    begin
        TransferType[1] := FAReclassJnlLine."Reclassify Acquisition Cost";
        TransferType[2] := FAReclassJnlLine."Reclassify Depreciation";
        TransferType[3] := FAReclassJnlLine."Reclassify Write-Down";
        TransferType[4] := FAReclassJnlLine."Reclassify Appreciation";
        TransferType[5] := FAReclassJnlLine."Reclassify Custom 1";
        TransferType[6] := FAReclassJnlLine."Reclassify Custom 2";
        TransferType[9] := FAReclassJnlLine."Reclassify Salvage Value";
    end;

    local procedure SetJnlRange()
    begin
        if (FAJnlNextLineNo = 0) and not TransferToGenJnl then begin
            FAJnlLine.LockTable();
            FAGetJnl.SetFAJnlRange(FAJnlLine, TemplateName, BatchName);
            FAJnlNextLineNo := FAJnlLine."Line No.";
        end;
        if (GenJnlNextLineNo = 0) and TransferToGenJnl then begin
            GenJnlLine.LockTable();
            FAGetJnl.SetGenJnlRange(GenJnlLine, TemplateName, BatchName);
            GenJnlNextLineNo := GenJnlLine."Line No.";
        end;
    end;

    local procedure Convert(OldNewFA: Option OldFA,NewFA; J: Integer; var FAPostingType: Enum "FA Journal Line FA Posting Type"; var Sign: Integer; var FANo: Code[20])
    begin
        if OldNewFA = OldNewFA::OldFA then begin
            Sign := -1;
            FANo := OldFA."No.";
        end else begin
            Sign := 1;
            FANo := NewFA."No.";
        end;
        if OldNewFA = OldNewFA::OldFA then
            case J of
                1:
                    FAPostingType := FAPostingType::"Salvage Value";
                2:
                    FAPostingType := FAPostingType::Depreciation;
                3:
                    FAPostingType := FAPostingType::"Write-Down";
                4:
                    FAPostingType := FAPostingType::"Custom 1";
                5:
                    FAPostingType := FAPostingType::"Custom 2";
                6:
                    FAPostingType := FAPostingType::Appreciation;
                9:
                    FAPostingType := FAPostingType::"Acquisition Cost";
            end;
        if OldNewFA = OldNewFA::NewFA then
            case J of
                1:
                    FAPostingType := FAPostingType::"Acquisition Cost";
                2:
                    FAPostingType := FAPostingType::"Salvage Value";
                3:
                    FAPostingType := FAPostingType::Appreciation;
                4:
                    FAPostingType := FAPostingType::"Write-Down";
                5:
                    FAPostingType := FAPostingType::"Custom 1";
                6:
                    FAPostingType := FAPostingType::"Custom 2";
                9:
                    FAPostingType := FAPostingType::Depreciation;
            end;
    end;

    local procedure InsertFAJnlLine(var FAReclassJnlLine: Record "FA Reclass. Journal Line"; FANo: Code[20]; EntryAmount: Decimal)
    begin
        if not FAJnlUsedOnce then begin
            ;
            FAJnlUsedOnce := true;
            FAJnlDocumentNo :=
              FAJnlSetup.GetFAJnlDocumentNo(FAJnlLine, FAReclassJnlLine."FA Posting Date", false);
        end;

        FAJnlLine.Init();
        FAJnlLine."Line No." := 0;
        FAJnlSetup.SetFAJnlTrailCodes(FAJnlLine);
        FAJnlLine."FA Posting Type" := FAPostingType;
        FAJnlLine.Validate("FA No.", FANo);
        FAJnlLine."FA Posting Date" := FAReclassJnlLine."FA Posting Date";
        FAJnlLine."Posting Date" := FAReclassJnlLine."Posting Date";
        if FAJnlLine."Posting Date" = FAJnlLine."FA Posting Date" then
            FAJnlLine."Posting Date" := 0D;

        FAJnlLine."Document No." := FAReclassJnlLine."Document No.";
        if FAJnlLine."Document No." = '' then
            FAJnlLine."Document No." := FAJnlDocumentNo;
        if FAJnlLine."Document No." = '' then
            FAReclassJnlLine.TestField("Document No.");

        FAJnlLine."Posting No. Series" := FAJnlSetup.GetFANoSeries(FAJnlLine);
        FAJnlLine.Validate("Depreciation Book Code", FAReclassJnlLine."Depreciation Book Code");
        FAJnlLine.Validate(Amount, EntryAmount);
        FAJnlLine.Description := FAReclassJnlLine.Description;
        FAJnlLine."FA Reclassification Entry" := true;
        FAJnlNextLineNo := FAJnlNextLineNo + 10000;
        FAJnlLine."Line No." := FAJnlNextLineNo;
        OnBeforeFAJnlLineInsert(FAJnlLine, FAReclassJnlLine, Sign);
        FAJnlLine.Insert(true);
    end;

    local procedure InsertGenJnlLine(var FAReclassJnlLine: Record "FA Reclass. Journal Line"; FANo: Code[20]; EntryAmount: Decimal; BalAccount: Boolean)
    var
        FAInsertGLAcc: Codeunit "FA Insert G/L Account";
    begin
        if not GenJnlUsedOnce then begin
            ;
            GenJnlUsedOnce := true;
            GenJnlDocumentNo :=
              FAJnlSetup.GetGenJnlDocumentNo(GenJnlLine, FAReclassJnlLine."FA Posting Date", false);
        end;

        GenJnlLine.Init();
        GenJnlLine."Line No." := 0;
        FAJnlSetup.SetGenJnlTrailCodes(GenJnlLine);
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
        GenJnlLine."FA Posting Type" := Enum::"Gen. Journal Line FA Posting Type".FromInteger(FAPostingType.AsInteger() + 1);
        GenJnlLine.Validate("Account No.", FANo);
        GenJnlLine.Validate("Depreciation Book Code", FAReclassJnlLine."Depreciation Book Code");
        GenJnlLine."FA Posting Date" := FAReclassJnlLine."FA Posting Date";
        GenJnlLine."Posting Date" := FAReclassJnlLine."Posting Date";
        if GenJnlLine."Posting Date" = 0D then
            GenJnlLine."Posting Date" := FAReclassJnlLine."FA Posting Date";
        if GenJnlLine."Posting Date" = GenJnlLine."FA Posting Date" then
            GenJnlLine."FA Posting Date" := 0D;

        GenJnlLine."Document No." := FAReclassJnlLine."Document No.";
        if GenJnlLine."Document No." = '' then
            GenJnlLine."Document No." := GenJnlDocumentNo;
        if GenJnlLine."Document No." = '' then
            FAReclassJnlLine.TestField("Document No.");

        GenJnlLine."Posting No. Series" := FAJnlSetup.GetGenNoSeries(GenJnlLine);
        GenJnlLine.Validate(Amount, EntryAmount);
        GenJnlLine.Description := FAReclassJnlLine.Description;
        GenJnlLine."FA Reclassification Entry" := true;
        GenJnlNextLineNo := GenJnlNextLineNo + 10000;
        GenJnlLine."Line No." := GenJnlNextLineNo;
        OnBeforeGenJnlLineInsert(GenJnlLine, FAReclassJnlLine, Sign);
        GenJnlLine.Insert(true);
        if BalAccount then begin
            FAInsertGLAcc.GetBalAcc(GenJnlLine);
            if GenJnlLine.Find('+') then;
            GenJnlNextLineNo := GenJnlLine."Line No.";
        end;
    end;

    local procedure FAName(var FA: Record "Fixed Asset"; DeprBookCode: Code[10]): Text[200]
    begin
        exit(DepreciationCalc.FAName(FA, DeprBookCode));
    end;

    local procedure CalcDB1DeprAmount(FAReclassJnlLine: Record "FA Reclass. Journal Line")
    var
        AccountingPeriod: Record "Accounting Period";
        DeprBook: Record "Depreciation Book";
        CalculateDepr: Codeunit "Calculate Depreciation";
        DeprAmount: Decimal;
        DeprAmount2: Decimal;
        Custom1Amount: Decimal;
        NumberOfDays: Integer;
        NumberOfDays2: Integer;
        Custom1NumberOfDays: Integer;
        DeprUntilDate: Date;
        DummyEntryAmounts: array[4] of Decimal;
        FixedAmount: Decimal;
        FixedAmount2: Decimal;
        DaysInFiscalYear: Integer;
        IsHandled: Boolean;
    begin
        if not FAReclassJnlLine."Calc. DB1 Depr. Amount" then
            exit;
        DeprBook.Get(FAReclassJnlLine."Depreciation Book Code");
        DeprBook.TestField("Use Custom 1 Depreciation", false); // better
        if (FADeprBook."Depreciation Method" <> FADeprBook."Depreciation Method"::"DB1/SL") and
           (FADeprBook."Depreciation Method" <> FADeprBook."Depreciation Method"::"Declining-Balance 1")
        then begin
            FADeprBook."Depreciation Method" := FADeprBook."Depreciation Method"::"Declining-Balance 1";
            FADeprBook2."Depreciation Method" := FADeprBook."Depreciation Method"::"DB1/SL";
            Error(Text006,
              FADeprBook.FieldCaption("Depreciation Method"),
              FADeprBook."Depreciation Method",
              FADeprBook2."Depreciation Method",
              FAName(OldFA, FAReclassJnlLine."Depreciation Book Code"));
        end;
        if FADeprBook."Depreciation Method" <> FADeprBook2."Depreciation Method" then
            Error(Text007,
              FADeprBook.FieldCaption("Depreciation Method"),
              FADeprBook."Depreciation Method",
              FAName(NewFA, FAReclassJnlLine."Depreciation Book Code"));

        if DeprBook."Use Custom 1 Depreciation" then
            FAReclassJnlLine.FieldError("Calc. DB1 Depr. Amount",
              StrSubstNo(
                Text008,
                DeprBook.FieldCaption("Use Custom 1 Depreciation"),
                DeprBook.TableCaption(),
                DeprBook.Code));

        FADeprBook.TestField("Temp. Ending Date", 0D);
        FADeprBook2.TestField("Temp. Ending Date", 0D);

        IsHandled := false;
        OnCalcDB1DeprAmountOnBeforeGetAccountingPeriod(FAReclassJnlLine, DeprUntilDate, IsHandled);

        if not IsHandled then
            if AccountingPeriod.IsEmpty() then
                DeprUntilDate := CalcDate('<-CY>', FAReclassJnlLine."FA Posting Date") - 1
            else begin
                AccountingPeriod.SetRange("New Fiscal Year", true);
                AccountingPeriod.SetRange("Starting Date", FAReclassJnlLine."FA Posting Date", DMY2Date(31, 12, 9999));
                if AccountingPeriod.FindFirst() then begin
                    if AccountingPeriod."Starting Date" <= 00000101D then
                        Error(Text005, AccountingPeriod.FieldCaption("Starting Date"), AccountingPeriod.TableCaption);
                    DeprUntilDate := AccountingPeriod."Starting Date" - 1
                end else
                    Error(Text005, AccountingPeriod.FieldCaption("Starting Date"), AccountingPeriod.TableCaption);
            end;

        CalculateDepr.Calculate(
          DeprAmount, Custom1Amount, NumberOfDays, Custom1NumberOfDays,
          FAReclassJnlLine."FA No.", FAReclassJnlLine."Depreciation Book Code",
          DeprUntilDate, DummyEntryAmounts, 0D, 0);
        if (DeprAmount >= 0) or (NumberOfDays <= 0) then
            Error(Text009,
              FADeprBook.FieldCaption("Temp. Fixed Depr. Amount"),
              FAName(OldFA, FAReclassJnlLine."Depreciation Book Code"));
        CalculateDepr.Calculate(
          DeprAmount2, Custom1Amount, NumberOfDays2, Custom1NumberOfDays,
          FAReclassJnlLine."New FA No.", FAReclassJnlLine."Depreciation Book Code",
          DeprUntilDate, DummyEntryAmounts, 0D, 0);

        DaysInFiscalYear := DeprBook."No. of Days in Fiscal Year";
        if DaysInFiscalYear = 0 then
            DaysInFiscalYear := 360;

        if DeprBook."Fiscal Year 365 Days" then
            DaysInFiscalYear := 365;

        FixedAmount := Round(-DeprAmount / NumberOfDays * DaysInFiscalYear);
        if NumberOfDays2 > 0 then
            FixedAmount2 := Round(-DeprAmount2 / NumberOfDays2 * DaysInFiscalYear);

        FADeprBook."Temp. Fixed Depr. Amount" :=
          Round(FixedAmount * (100 - FAReclassJnlLine."Reclassify Acq. Cost %") / 100);
        FADeprBook."Temp. Ending Date" := DeprUntilDate;
        FADeprBook.Modify();

        FADeprBook2."Temp. Fixed Depr. Amount" :=
          Round(FixedAmount2 + FixedAmount - FADeprBook."Temp. Fixed Depr. Amount");
        FADeprBook2."Temp. Ending Date" := FADeprBook."Temp. Ending Date";
        FADeprBook2.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; var FAReclassJournalLine: Record "FA Reclass. Journal Line"; Sign: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFAJnlLineInsert(var FAJournalLine: Record "FA Journal Line"; var FAReclassJournalLine: Record "FA Reclass. Journal Line"; Sign: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAmounts(FAReclassJnlLine: Record "FA Reclass. Journal Line"; var Amounts: array[9] of Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFAReclassLine(var FAReclassJnlLine: Record "FA Reclass. Journal Line"; var Done: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAmountsOnAfterSetAmounts(FADepreciationBook: Record "FA Depreciation Book"; var Amounts: array[9] of Decimal; TransferType: array[9] of Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcDB1DeprAmountOnBeforeGetAccountingPeriod(FAReclassJnlLine: Record "FA Reclass. Journal Line"; var DeprUntilDate: Date; var IsHandled: Boolean)
    begin
    end;
}

