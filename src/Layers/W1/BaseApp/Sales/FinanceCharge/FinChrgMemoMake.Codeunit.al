// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;

using Microsoft.Sales.Receivables;

/// <summary>
/// Creates and suggests finance charge memo lines from customer ledger entries based on finance charge terms.
/// </summary>
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

    /// <summary>
    /// Executes the finance charge memo creation process for the specified customer and ledger entries.
    /// </summary>
    /// <returns>True if the process completes successfully; otherwise, false if the customer is blocked.</returns>
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

    /// <summary>
    /// Sets the customer, customer ledger entries, and finance charge memo header parameters for the memo creation process.
    /// </summary>
    /// <param name="Cust2">Specifies the customer record for whom to create the finance charge memo.</param>
    /// <param name="CustLedgEntry2">Specifies the customer ledger entries to include in the finance charge memo.</param>
    /// <param name="FinChrgMemoHeaderReq2">Specifies the finance charge memo header with request parameters such as document date and posting date.</param>
    procedure Set(Cust2: Record Customer; var CustLedgEntry2: Record "Cust. Ledger Entry"; FinChrgMemoHeaderReq2: Record "Finance Charge Memo Header")
    begin
        Cust := Cust2;
        CustLedgEntry.Copy(CustLedgEntry2);
        FinChrgMemoHeaderReq := FinChrgMemoHeaderReq2;
        OnAfterSet(CustLedgEntry);
    end;

    /// <summary>
    /// Sets the finance charge memo header and customer ledger entries for suggesting lines on an existing memo.
    /// </summary>
    /// <param name="FinChrgMemoHeader2">Specifies the existing finance charge memo header to suggest lines for.</param>
    /// <param name="CustLedgEntry2">Specifies the customer ledger entries to use when suggesting lines.</param>
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

    /// <summary>
    /// Raised after a finance charge memo line is created from a customer ledger entry.
    /// </summary>
    /// <param name="FinanceChargeMemoLine">Specifies the finance charge memo line that was created.</param>
    /// <param name="Checking">Specifies whether the process is in checking mode.</param>
    /// <param name="CurrencyCode">Specifies the currency code for the memo line.</param>
    /// <param name="TempCurrency">Specifies the temporary currency record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFinChrgMemoLineCreated(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; Checking: Boolean; CurrencyCode: Code[10]; var TempCurrency: Record Currency temporary)
    begin
    end;

    /// <summary>
    /// Raised after the Set procedure assigns parameters for finance charge memo creation.
    /// </summary>
    /// <param name="CustLedgEntry">Specifies the customer ledger entry record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSet(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised after the finance charge memo header is created.
    /// </summary>
    /// <param name="FinanceChargeMemoHeader">Specifies the created finance charge memo header.</param>
    /// <param name="FinanceChargeMemoHeaderReq">Specifies the request parameters for the memo header.</param>
    /// <param name="CurrencyCode">Specifies the currency code.</param>
    /// <param name="Checking">Specifies whether the process is in checking mode.</param>
    /// <param name="Result">Specifies the result that can be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterMakeHeader(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; FinanceChargeMemoHeaderReq: Record "Finance Charge Memo Header"; CurrencyCode: Code[10]; Checking: Boolean; var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before the finance charge memo header is created.
    /// </summary>
    /// <param name="FinanceChargeMemoHeaderReq">Specifies the request parameters for the memo header.</param>
    /// <param name="CurrencyCode">Specifies the currency code that can be modified.</param>
    /// <param name="Checking">Specifies whether the process is in checking mode.</param>
    /// <param name="Result">Specifies the result that can be set.</param>
    /// <param name="IsHandled">Set to true to skip the default header creation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeHeader(var FinanceChargeMemoHeaderReq: Record "Finance Charge Memo Header"; var CurrencyCode: Code[10]; var Checking: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after filters are set on customer ledger entries during the Code procedure.
    /// </summary>
    /// <param name="CustLedgEntry">Specifies the customer ledger entry record with filters applied.</param>
    /// <param name="FinanceChargeMemoHeaderReq">Specifies the request parameters for the memo header.</param>
    /// <param name="Customer">Specifies the customer record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCustLedgEntrySetFilters(var CustLedgEntry: Record "Cust. Ledger Entry"; FinanceChargeMemoHeaderReq: Record "Finance Charge Memo Header"; Customer: Record Customer)
    begin
    end;

    /// <summary>
    /// Raised after determining whether the customer is blocked.
    /// </summary>
    /// <param name="Customer">Specifies the customer record.</param>
    /// <param name="CustIsBlocked">Specifies whether the customer is blocked that can be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCalcCustIsBlocked(Customer: Record Customer; var CustIsBlocked: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after filters are set on the finance charge memo header during header creation.
    /// </summary>
    /// <param name="FinanceChargeMemoHeader">Specifies the finance charge memo header record.</param>
    /// <param name="FinanceChargeMemoHeaderReq">Specifies the request parameters for the memo header.</param>
    /// <param name="FinanceChargeTerms">Specifies the finance charge terms record.</param>
    /// <param name="Customer">Specifies the customer record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnMakeHeaderOnAfterSetFilters(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; FinanceChargeMemoHeaderReq: Record "Finance Charge Memo Header"; FinanceChargeTerms: Record "Finance Charge Terms"; Customer: Record Customer)
    begin
    end;

    /// <summary>
    /// Raised before the finance charge memo header is inserted.
    /// </summary>
    /// <param name="FinanceChargeMemoHeader">Specifies the finance charge memo header to be inserted.</param>
    /// <param name="FinanceChargeMemoHeaderReq">Specifies the request parameters for the memo header.</param>
    /// <param name="FinanceChargeTerms">Specifies the finance charge terms record.</param>
    /// <param name="Customer">Specifies the customer record.</param>
    /// <param name="Checking">Specifies whether the process is in checking mode.</param>
    [IntegrationEvent(false, false)]
    local procedure OnMakeHeaderOnBeforeInsert(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; FinanceChargeMemoHeaderReq: Record "Finance Charge Memo Header"; FinanceChargeTerms: Record "Finance Charge Terms"; Customer: Record Customer; Checking: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before creating lines from closed customer ledger entries.
    /// </summary>
    /// <param name="CustLedgEntry">Specifies the customer ledger entry record with filters applied.</param>
    /// <param name="CurrencyCode">Specifies the currency code.</param>
    /// <param name="Checking">Specifies whether the process is in checking mode.</param>
    [IntegrationEvent(false, false)]
    local procedure OnMakeLinesOnBeforeMakeLinesClosedEntries(var CustLedgEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]; Checking: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before creating lines from open customer ledger entries.
    /// </summary>
    /// <param name="CustLedgEntry">Specifies the customer ledger entry record with filters applied.</param>
    /// <param name="CurrencyCode">Specifies the currency code.</param>
    /// <param name="Checking">Specifies whether the process is in checking mode.</param>
    [IntegrationEvent(false, false)]
    local procedure OnMakeLinesOnBeforeMakeLinesOpenEntries(var CustLedgEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]; Checking: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before checking whether to insert a finance charge memo line.
    /// </summary>
    /// <param name="FinanceChargeMemoLine">Specifies the finance charge memo line to be checked.</param>
    /// <param name="Checking">Specifies whether the process is in checking mode.</param>
    [IntegrationEvent(false, false)]
    local procedure OnMakeLines2OnBeforeCheckInsertFinChrgMemoLine(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; Checking: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before creating lines during the finance charge memo check.
    /// </summary>
    /// <param name="FinanceChargeMemoHeader">Specifies the finance charge memo header record.</param>
    /// <param name="FinanceChargeTerms">Specifies the finance charge terms record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnFinChrgMemoCheckOnBeforeMakeLines(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var FinanceChargeTerms: Record "Finance Charge Terms")
    begin
    end;

    /// <summary>
    /// Raised before the Code procedure executes the main finance charge memo creation logic.
    /// </summary>
    /// <param name="Customer">Specifies the customer record.</param>
    /// <param name="CustLedgerEntry">Specifies the customer ledger entry record.</param>
    /// <param name="FinanceChargeMemoHeaderReq">Specifies the request parameters for the memo header.</param>
    /// <param name="FinanceChargeMemoHeader">Specifies the finance charge memo header record.</param>
    /// <param name="IsHandled">Set to true to skip the default Code procedure logic.</param>
    /// <param name="Result">Specifies the result to return.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(Customer: Record Customer; var CustLedgerEntry: Record "Cust. Ledger Entry"; FinanceChargeMemoHeaderReq: Record "Finance Charge Memo Header"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after the Code procedure completes the finance charge memo creation.
    /// </summary>
    /// <param name="FinChrgMemoLine">Specifies the finance charge memo line record.</param>
    /// <param name="FinChrgMemoHeader">Specifies the finance charge memo header record.</param>
    /// <param name="CustLedgEntry">Specifies the customer ledger entry record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var FinChrgMemoLine: Record "Finance Charge Memo Line"; var FinChrgMemoHeader: Record "Finance Charge Memo Header"; var CustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;
}

