// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;

using Microsoft.Sales.Receivables;

codeunit 394 "FinChrgMemo-Make"
{

    trigger OnRun()
    begin
    end;

    var
        Cust: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        FinChrgTerms: Record "Finance Charge Terms";
        FinChrgMemoHeaderReq: Record "Finance Charge Memo Header";
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
        FinChrgMemoLine: Record "Finance Charge Memo Line";
        TempCurrency: Record Currency temporary;
        TempCurrency2: Record Currency temporary;
        CurrExchRate: Record "Currency Exchange Rate";
        NextLineNo: Integer;
        CustAmountLCY: Decimal;
        HeaderExists: Boolean;
        OverDue: Boolean;

    procedure "Code"() Result: Boolean
    var
        CustIsBlocked: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCode(Cust, CustLedgEntry, FinChrgMemoHeaderReq, FinChrgMemoHeader, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if FinChrgMemoHeader."No." <> '' then begin
            HeaderExists := true;
            FinChrgMemoHeader.TestField("Customer No.");
            Cust.Get(FinChrgMemoHeader."Customer No.");
            FinChrgMemoHeader.TestField("Document Date");
            FinChrgMemoHeader.TestField("Fin. Charge Terms Code");
            FinChrgMemoHeaderReq := FinChrgMemoHeader;
            FinChrgMemoLine.SetRange("Finance Charge Memo No.", FinChrgMemoHeader."No.");
            FinChrgMemoLine.DeleteAll();
        end;

        OverDue := false;

        Cust.TestField("Fin. Charge Terms Code");
        if HeaderExists then
            FinChrgMemoCheck(FinChrgMemoHeader."Currency Code")
        else begin
            CustIsBlocked := Cust.Blocked = Cust.Blocked::All;
            OnCodeOnAfterCalcCustIsBlocked(Cust, CustIsBlocked);
            if CustIsBlocked then
                exit(false);
            TempCurrency.DeleteAll();
            TempCurrency2.DeleteAll();
            CustLedgEntry2.CopyFilters(CustLedgEntry);
            CustLedgEntry.SetCurrentKey("Customer No.");
            CustLedgEntry.SetRange("Customer No.", Cust."No.");
            OnCodeOnAfterCustLedgEntrySetFilters(CustLedgEntry, FinChrgMemoHeaderReq, Cust);
            if CustLedgEntry.Find('-') then
                repeat
                    if CustLedgEntry."On Hold" = '' then begin
                        TempCurrency.Code := CustLedgEntry."Currency Code";
                        if TempCurrency.Insert() then;
                    end;
                until CustLedgEntry.Next() = 0;
            CustLedgEntry.CopyFilters(CustLedgEntry2);
            if TempCurrency.Find('-') then
                repeat
                    FinChrgMemoCheck(TempCurrency.Code);
                until TempCurrency.Next() = 0;
        end;

        if ((CustAmountLCY = 0) or (CustAmountLCY < FinChrgTerms."Minimum Amount (LCY)")) and
           ((FinChrgTerms."Additional Fee (LCY)" = 0) or (not OverDue))
        then
            exit(true);
        FinChrgMemoLine.LockTable();
        FinChrgMemoHeader.LockTable();

        if HeaderExists then
            MakeFinChrgMemo(FinChrgMemoHeader."Currency Code")
        else
            if TempCurrency.Find('-') then
                repeat
                    if TempCurrency2.Get(tempCurrency.Code) then
                        MakeFinChrgMemo(TempCurrency.Code);
                until TempCurrency.Next() = 0;
        OnAfterCode(FinChrgMemoLine, FinChrgMemoHeader, CustLedgEntry);
        exit(true);
    end;

    procedure Set(Cust2: Record Customer; var CustLedgEntry2: Record "Cust. Ledger Entry"; FinChrgMemoHeaderReq2: Record "Finance Charge Memo Header")
    begin
        Cust := Cust2;
        CustLedgEntry.Copy(CustLedgEntry2);
        FinChrgMemoHeaderReq := FinChrgMemoHeaderReq2;
        OnAfterSet(CustLedgEntry);
    end;

    procedure SuggestLines(FinChrgMemoHeader2: Record "Finance Charge Memo Header"; var CustLedgEntry2: Record "Cust. Ledger Entry")
    begin
        FinChrgMemoHeader := FinChrgMemoHeader2;
        CustLedgEntry.Copy(CustLedgEntry2);
    end;

    local procedure MakeFinChrgMemo(CurrencyCode: Code[10])
    begin
        if not HeaderExists then
            if not MakeHeader(CurrencyCode, false) then
                exit;
        NextLineNo := 0;
        MakeLines(CurrencyCode, false);
        FinChrgMemoHeader.InsertLines();
        FinChrgMemoHeader.Modify();
    end;

    local procedure FinChrgMemoCheck(CurrencyCode: Code[10])
    begin
        if not HeaderExists then
            MakeHeader(CurrencyCode, true);
        FinChrgTerms.Get(FinChrgMemoHeader."Fin. Charge Terms Code");
        OnFinChrgMemoCheckOnBeforeMakeLines(FinChrgMemoHeader, FinChrgTerms);
        MakeLines(CurrencyCode, true);
    end;

    local procedure MakeHeader(CurrencyCode: Code[10]; Checking: Boolean) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeHeader(FinChrgMemoHeaderReq, CurrencyCode, Checking, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not Checking then begin
            FinChrgMemoHeader.SetCurrentKey("Customer No.", "Currency Code");
            FinChrgMemoHeader.SetRange("Customer No.", Cust."No.");
            FinChrgMemoHeader.SetRange("Currency Code", CurrencyCode);
            OnMakeHeaderOnAfterSetFilters(FinChrgMemoHeader, FinChrgMemoHeaderReq, FinChrgTerms, Cust);
            if FinChrgMemoHeader.FindFirst() then
                exit(false);
        end;
        FinChrgMemoHeader.Init();
        FinChrgMemoHeader."No." := '';
        FinChrgMemoHeader."Posting Date" := FinChrgMemoHeaderReq."Posting Date";
        OnMakeHeaderOnBeforeInsert(FinChrgMemoHeader, FinChrgMemoHeaderReq, FinChrgTerms, Cust, Checking);
        if not Checking then
            FinChrgMemoHeader.Insert(true);
        FinChrgMemoHeader.Validate("Customer No.", Cust."No.");
        FinChrgMemoHeader.Validate("Document Date", FinChrgMemoHeaderReq."Document Date");
        FinChrgMemoHeader.Validate("Currency Code", CurrencyCode);
        if not Checking then
            FinChrgMemoHeader.Modify();
        Result := true;

        OnAfterMakeHeader(FinChrgMemoHeader, FinChrgMemoHeaderReq, CurrencyCode, Checking, Result);
    end;

    local procedure MakeLines(CurrencyCode: Code[10]; Checking: Boolean)
    begin
        if FinChrgTerms."Interest Calculation" in
           [FinChrgTerms."Interest Calculation"::"Open Entries",
            FinChrgTerms."Interest Calculation"::"All Entries"]
        then begin
            CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date", "Currency Code");
            CustLedgEntry.SetRange("Customer No.", Cust."No.");
            CustLedgEntry.SetRange(Open, true);
            CustLedgEntry.SetRange("On Hold", '');
            CustLedgEntry.SetRange(Positive, true);
            CustLedgEntry.SetRange("Currency Code", CurrencyCode);
            OnMakeLinesOnBeforeMakeLinesOpenEntries(CustLedgEntry, CurrencyCode, Checking);
            MakeLines2(CurrencyCode, Checking);
        end;
        if FinChrgTerms."Interest Calculation" in
           [FinChrgTerms."Interest Calculation"::"Closed Entries",
            FinChrgTerms."Interest Calculation"::"All Entries"]
        then begin
            if not CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Calculate Interest") then
                CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date", "Currency Code");
            CustLedgEntry.SetRange("Customer No.", Cust."No.");
            CustLedgEntry.SetRange(Open, false);
            CustLedgEntry.SetRange("On Hold", '');
            CustLedgEntry.SetRange(Positive, true);
            CustLedgEntry.SetRange("Currency Code", CurrencyCode);
            CustLedgEntry.SetRange("Calculate Interest", true);
            OnMakeLinesOnBeforeMakeLinesClosedEntries(CustLedgEntry, CurrencyCode, Checking);
            MakeLines2(CurrencyCode, Checking);
            CustLedgEntry.SetRange("Calculate Interest");
        end;
    end;

    local procedure MakeLines2(CurrencyCode: Code[10]; Checking: Boolean)
    begin
        if CustLedgEntry.Find('-') then
            repeat
                Clear(FinChrgMemoLine);
                NextLineNo := GetLastLineNo(FinChrgMemoHeader."No.") + 10000;
                FinChrgMemoLine.Init();
                FinChrgMemoLine."Finance Charge Memo No." := FinChrgMemoHeader."No.";
                FinChrgMemoLine."Line No." := NextLineNo;
                FinChrgMemoLine.SetFinChrgMemoHeader(FinChrgMemoHeader);
                FinChrgMemoLine.Type := FinChrgMemoLine.Type::"Customer Ledger Entry";
                FinChrgMemoLine.SetCheckingMode(Checking);
                FinChrgMemoLine.Validate("Entry No.", CustLedgEntry."Entry No.");
                if CurrencyCode <> '' then
                    CustAmountLCY :=
                      CustAmountLCY +
                      CurrExchRate.ExchangeAmtFCYToLCY(
                        FinChrgMemoHeader."Posting Date", CurrencyCode, FinChrgMemoLine.Amount,
                        CurrExchRate.ExchangeRate(
                          FinChrgMemoHeader."Posting Date", CurrencyCode))
                else
                    CustAmountLCY := CustAmountLCY + FinChrgMemoLine.Amount;
                if (CustAmountLCY >= FinChrgTerms."Minimum Amount (LCY)") and
                   (FinChrgMemoHeader."Document Date" > CalcDate(FinChrgTerms."Grace Period", FinChrgMemoLine."Due Date"))
                then
                    OverDue := true;

                OnMakeLines2OnBeforeCheckInsertFinChrgMemoLine(FinChrgMemoLine, Checking);
                if FinChrgMemoLine.Amount <> 0 then
                    if not Checking then
                        FinChrgMemoLine.Insert()
                    else begin
                        TempCurrency2.Code := CurrencyCode;
                        if TempCurrency2.Insert() then;
                    end;
                OnAfterFinChrgMemoLineCreated(FinChrgMemoLine, Checking, CurrencyCode, TempCurrency2);
            until CustLedgEntry.Next() = 0;
    end;

    local procedure GetLastLineNo(MemoNo: Code[20]): Integer
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
    begin
        FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", MemoNo);
        if FinanceChargeMemoLine.FindLast() then;
        exit(FinanceChargeMemoLine."Line No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinChrgMemoLineCreated(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; Checking: Boolean; CurrencyCode: Code[10]; var TempCurrency: Record Currency temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSet(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMakeHeader(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; FinanceChargeMemoHeaderReq: Record "Finance Charge Memo Header"; CurrencyCode: Code[10]; Checking: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeHeader(var FinanceChargeMemoHeaderReq: Record "Finance Charge Memo Header"; var CurrencyCode: Code[10]; var Checking: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCustLedgEntrySetFilters(var CustLedgEntry: Record "Cust. Ledger Entry"; FinanceChargeMemoHeaderReq: Record "Finance Charge Memo Header"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCalcCustIsBlocked(Customer: Record Customer; var CustIsBlocked: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeHeaderOnAfterSetFilters(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; FinanceChargeMemoHeaderReq: Record "Finance Charge Memo Header"; FinanceChargeTerms: Record "Finance Charge Terms"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeHeaderOnBeforeInsert(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; FinanceChargeMemoHeaderReq: Record "Finance Charge Memo Header"; FinanceChargeTerms: Record "Finance Charge Terms"; Customer: Record Customer; Checking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeLinesOnBeforeMakeLinesClosedEntries(var CustLedgEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]; Checking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeLinesOnBeforeMakeLinesOpenEntries(var CustLedgEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]; Checking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeLines2OnBeforeCheckInsertFinChrgMemoLine(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; Checking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinChrgMemoCheckOnBeforeMakeLines(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var FinanceChargeTerms: Record "Finance Charge Terms")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(Customer: Record Customer; var CustLedgerEntry: Record "Cust. Ledger Entry"; FinanceChargeMemoHeaderReq: Record "Finance Charge Memo Header"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var FinChrgMemoLine: Record "Finance Charge Memo Line"; var FinChrgMemoHeader: Record "Finance Charge Memo Header"; var CustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;
}

