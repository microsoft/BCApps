// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.Finance.Currency;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 34 "Change Payment Tolerance"
{
    Caption = 'Change Payment Tolerance';
    Permissions = TableData Currency = rm,
                  TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "General Ledger Setup" = rm;
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AllCurrencies; AllCurrencies)
                    {
                        ApplicationArea = Suite;
                        Caption = 'All Currencies';
                        ToolTip = 'Specifies if you want to change the tolerance setup for both local and all foreign currencies.';

                        trigger OnValidate()
                        begin
                            if AllCurrencies then begin
                                CurrencyCode := '';
                                PaymentTolerancePct := 0;
                                MaxPmtToleranceAmount := 0;
                                CurrencyCodeEnable := false;
                            end else begin
                                CurrencyCodeEnable := true;
                                CurrencyCode := '';
                                PaymentTolerancePct := GLSetup."Payment Tolerance %";
                                MaxPmtToleranceAmount := GLSetup."Max. Payment Tolerance Amount";
                                DecimalPlaces := CheckApplnRounding(GLSetup."Amount Decimal Places");
                            end;
                        end;
                    }
                    field("Currency Code"; CurrencyCode)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Currency Code';
                        Enabled = CurrencyCodeEnable;
                        TableRelation = Currency;
                        ToolTip = 'Specifies the code for the currency that amounts are shown in.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            Currencies.LookupMode := true;
                            if Currencies.RunModal() = ACTION::LookupOK then
                                Currencies.GetCurrency(CurrencyCode);
                            Clear(Currencies);
                            if CurrencyCode = '' then begin
                                GLSetup.Get();
                                PaymentTolerancePct := GLSetup."Payment Tolerance %";
                                MaxPmtToleranceAmount := GLSetup."Max. Payment Tolerance Amount";
                            end else begin
                                Currency.Get(CurrencyCode);
                                PaymentTolerancePct := Currency."Payment Tolerance %";
                                MaxPmtToleranceAmount := Currency."Max. Payment Tolerance Amount";
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            if not AllCurrencies then
                                if CurrencyCode = '' then begin
                                    GLSetup.Get();
                                    PaymentTolerancePct := GLSetup."Payment Tolerance %";
                                    MaxPmtToleranceAmount := GLSetup."Max. Payment Tolerance Amount";
                                    DecimalPlaces := CheckApplnRounding(GLSetup."Amount Decimal Places");
                                end else begin
                                    Currency.Get(CurrencyCode);
                                    PaymentTolerancePct := Currency."Payment Tolerance %";
                                    MaxPmtToleranceAmount := Currency."Max. Payment Tolerance Amount";
                                    DecimalPlaces := CheckApplnRounding(Currency."Amount Decimal Places");
                                end;
                        end;
                    }
                    field(PaymentTolerancePct; PaymentTolerancePct)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Tolerance %';
                        DecimalPlaces = 0 : 5;
                        Enabled = true;
                        ToolTip = 'Specifies the percentage by which the payment or refund is allowed to be less than the amount on the invoice or credit memo.';
                    }
                    field("Max. Pmt. Tolerance Amount"; MaxPmtToleranceAmount)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Max. Pmt. Tolerance Amount';
                        DecimalPlaces = 0 : 5;
                        Enabled = true;
                        ToolTip = 'Specifies the maximum allowed amount by which the payment or refund can differ from the amount on the invoice or credit memo.';

                        trigger OnValidate()
                        begin
                            if AllCurrencies then begin
                                DecimalPlaces := 5;
                                FormatString := Text002 + '0:5' + Text003;
                            end else
                                if Currency.Code <> '' then begin
                                    Currency.Get(Currency.Code);
                                    DecimalPlaces := CheckApplnRounding(Currency."Amount Decimal Places");
                                    FormatString := Text002 + Currency."Amount Decimal Places" + Text003;
                                end else begin
                                    GLSetup.Get();
                                    DecimalPlaces := CheckApplnRounding(GLSetup."Amount Decimal Places");
                                    FormatString := Text002 + GLSetup."Amount Decimal Places" + Text003;
                                end;
                            TextFormat := Format(MaxPmtToleranceAmount, 0, FormatString);
                            TextInput := Format(MaxPmtToleranceAmount);
                            if StrLen(TextFormat) < StrLen(TextInput) then
                                Error(Text004, DecimalPlaces);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            CurrencyCodeEnable := true;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if AllCurrencies then begin
            if Currency.Find('-') then
                repeat
                    if Currency."Payment Tolerance %" <> PaymentTolerancePct then
                        Currency."Payment Tolerance %" := PaymentTolerancePct;
                    if Currency."Max. Payment Tolerance Amount" <> MaxPmtToleranceAmount then
                        Currency."Max. Payment Tolerance Amount" := MaxPmtToleranceAmount;
                    Currency."Max. Payment Tolerance Amount" := Round(
                        Currency."Max. Payment Tolerance Amount", Currency."Amount Rounding Precision");
                    Currency.Modify();
                until Currency.Next() = 0;
            GLSetup.Get();
            if GLSetup."Payment Tolerance %" <> PaymentTolerancePct then
                GLSetup."Payment Tolerance %" := PaymentTolerancePct;
            if GLSetup."Max. Payment Tolerance Amount" <> MaxPmtToleranceAmount then
                GLSetup."Max. Payment Tolerance Amount" := MaxPmtToleranceAmount;
            GLSetup."Max. Payment Tolerance Amount" := Round(
                GLSetup."Max. Payment Tolerance Amount", GLSetup."Amount Rounding Precision");
            GLSetup.Modify();
        end else
            if CurrencyCode = '' then begin
                GLSetup.Get();
                AmountRoundingPrecision := GLSetup."Amount Rounding Precision";
                if GLSetup."Payment Tolerance %" <> PaymentTolerancePct then
                    GLSetup."Payment Tolerance %" := PaymentTolerancePct;
                if GLSetup."Max. Payment Tolerance Amount" <> MaxPmtToleranceAmount then
                    GLSetup."Max. Payment Tolerance Amount" := MaxPmtToleranceAmount;
                GLSetup."Max. Payment Tolerance Amount" := Round(
                    GLSetup."Max. Payment Tolerance Amount", GLSetup."Amount Rounding Precision");
                GLSetup.Modify();
            end else
                if CurrencyCode <> '' then begin
                    Currency.Get(CurrencyCode);
                    AmountRoundingPrecision := Currency."Amount Rounding Precision";
                    if Currency."Payment Tolerance %" <> PaymentTolerancePct then
                        Currency."Payment Tolerance %" := PaymentTolerancePct;
                    if Currency."Max. Payment Tolerance Amount" <> MaxPmtToleranceAmount then
                        Currency."Max. Payment Tolerance Amount" := MaxPmtToleranceAmount;
                    Currency."Max. Payment Tolerance Amount" := Round(
                        Currency."Max. Payment Tolerance Amount", Currency."Amount Rounding Precision");
                    Currency.Modify();
                end;

        if AllCurrencies then begin
            if ConfirmManagement.GetResponseOrDefault(Text001, true) then begin
                if Currency.Find('-') then
                    repeat
                        AmountRoundingPrecision := Currency."Amount Rounding Precision";
                        CurrencyCode := Currency.Code;
                        ChangeCustLedgEntries();
                        ChangeVendLedgEntries();
                    until Currency.Next() = 0;
                CurrencyCode := '';
                GLSetup.Get();
                AmountRoundingPrecision := GLSetup."Amount Rounding Precision";
                ChangeCustLedgEntries();
                ChangeVendLedgEntries();
            end;
        end else
            if ConfirmManagement.GetResponseOrDefault(Text001, true) then begin
                ChangeCustLedgEntries();
                ChangeVendLedgEntries();
            end;
    end;

    var
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        Currencies: Page Currencies;
        CurrencyCode: Code[10];
        PaymentTolerancePct: Decimal;
        MaxPmtToleranceAmount: Decimal;
#pragma warning disable AA0074
        Text001: Label 'Do you want to change all open entries for every customer and vendor that are not blocked?';
#pragma warning restore AA0074
        AmountRoundingPrecision: Decimal;
        DecimalPlaces: Integer;
        AllCurrencies: Boolean;
        FormatString: Text[80];
        TextFormat: Text[250];
        TextInput: Text[250];
#pragma warning disable AA0074
        Text002: Label '<Precision,', Locked = true;
        Text003: Label '><Standard Format,0>', Locked = true;
#pragma warning disable AA0470
        Text004: Label 'The field can have a maximum of %1 decimal places.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CurrencyCodeEnable: Boolean;

    local procedure CheckApplnRounding(AmountDecimalPlaces: Text[5]): Integer
    var
        ColonPlace: Integer;
        ReturnNumber: Integer;
        OK: Boolean;
        TempAmountDecimalPlaces: Text[5];
    begin
        ColonPlace := StrPos(AmountDecimalPlaces, ':');

        if ColonPlace = 0 then begin
            OK := Evaluate(ReturnNumber, AmountDecimalPlaces);
            if OK then
                exit(ReturnNumber);
        end else begin
            TempAmountDecimalPlaces := CopyStr(AmountDecimalPlaces, ColonPlace + 1, ColonPlace + 1);
            OK := Evaluate(ReturnNumber, TempAmountDecimalPlaces);
            if OK then
                exit(ReturnNumber);
        end;
    end;

    local procedure ChangeCustLedgEntries()
    var
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        NewPaymentTolerancePct: Decimal;
        NewMaxPmtToleranceAmount: Decimal;
    begin
        Customer.SetCurrentKey("No.");
        Customer.LockTable();
        if not Customer.Find('-') then
            exit;

        repeat
            if not Customer."Block Payment Tolerance" then begin
                CustLedgEntry.SetCurrentKey("Customer No.", Open);
                CustLedgEntry.SetRange("Customer No.", Customer."No.");
                CustLedgEntry.SetRange(Open, true);

                CustLedgEntry.SetFilter("Document Type", '%1|%2',
                  CustLedgEntry."Document Type"::Invoice,
                  CustLedgEntry."Document Type"::"Credit Memo");

                CustLedgEntry.SetRange("Currency Code", CurrencyCode);
                NewPaymentTolerancePct := PaymentTolerancePct;
                NewMaxPmtToleranceAmount := MaxPmtToleranceAmount;

                CustLedgEntry.LockTable();
                if CustLedgEntry.Find('-') then
                    repeat
                        CustLedgEntry.CalcFields("Remaining Amount");
                        CustLedgEntry."Max. Payment Tolerance" :=
                          Round(NewPaymentTolerancePct * CustLedgEntry."Remaining Amount" / 100, AmountRoundingPrecision);
                        if (CustLedgEntry."Max. Payment Tolerance" = 0) and
                           (NewMaxPmtToleranceAmount <> 0) or
                           ((Abs(CustLedgEntry."Max. Payment Tolerance") > NewMaxPmtToleranceAmount) and
                            (CustLedgEntry."Max. Payment Tolerance" <> 0) and
                            (NewMaxPmtToleranceAmount <> 0))
                        then
                            if CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Invoice then
                                CustLedgEntry."Max. Payment Tolerance" :=
                                  Round(NewMaxPmtToleranceAmount, AmountRoundingPrecision)
                            else
                                CustLedgEntry."Max. Payment Tolerance" :=
                                  Round(-NewMaxPmtToleranceAmount, AmountRoundingPrecision);
                        if Abs(CustLedgEntry."Remaining Amount") < Abs(CustLedgEntry."Max. Payment Tolerance") then
                            CustLedgEntry."Max. Payment Tolerance" := CustLedgEntry."Remaining Amount";
                        OnChangeCustLedgEntriesOnBeforeModifyCustLedgEntry(CustLedgEntry);
                        CustLedgEntry.Modify();
                    until CustLedgEntry.Next() = 0;
            end;
        until Customer.Next() = 0;
    end;

    local procedure ChangeVendLedgEntries()
    var
        Vendor: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        NewPaymentTolerancePct: Decimal;
        NewMaxPmtToleranceAmount: Decimal;
    begin
        Vendor.SetCurrentKey("No.");
        Vendor.LockTable();
        if not Vendor.Find('-') then
            exit;
        repeat
            if not Vendor."Block Payment Tolerance" then begin
                VendLedgEntry.SetCurrentKey("Vendor No.", Open);
                VendLedgEntry.SetRange("Vendor No.", Vendor."No.");

                VendLedgEntry.SetRange(Open, true);

                VendLedgEntry.SetFilter("Document Type", '%1|%2',
                  VendLedgEntry."Document Type"::Invoice,
                  VendLedgEntry."Document Type"::"Credit Memo");

                VendLedgEntry.SetRange("Currency Code", CurrencyCode);
                NewPaymentTolerancePct := PaymentTolerancePct;
                NewMaxPmtToleranceAmount := MaxPmtToleranceAmount;

                VendLedgEntry.LockTable();
                if VendLedgEntry.Find('-') then
                    repeat
                        VendLedgEntry.CalcFields("Remaining Amount");
                        VendLedgEntry."Max. Payment Tolerance" :=
                          Round(NewPaymentTolerancePct * VendLedgEntry."Remaining Amount" / 100, AmountRoundingPrecision);
                        if (VendLedgEntry."Max. Payment Tolerance" = 0) and
                           (NewMaxPmtToleranceAmount <> 0) or
                           ((Abs(VendLedgEntry."Max. Payment Tolerance") > NewMaxPmtToleranceAmount) and
                            (VendLedgEntry."Max. Payment Tolerance" <> 0) and
                            (NewMaxPmtToleranceAmount <> 0))
                        then
                            if VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Invoice then
                                VendLedgEntry."Max. Payment Tolerance" :=
                                  Round(-NewMaxPmtToleranceAmount, AmountRoundingPrecision)
                            else
                                VendLedgEntry."Max. Payment Tolerance" :=
                                  Round(NewMaxPmtToleranceAmount, AmountRoundingPrecision);
                        if Abs(VendLedgEntry."Remaining Amount") < Abs(VendLedgEntry."Max. Payment Tolerance") then
                            VendLedgEntry."Max. Payment Tolerance" := VendLedgEntry."Remaining Amount";
                        OnChangeVendLedgEntryOnBeforeModifyVendLedgEntry(VendLedgEntry);
                        VendLedgEntry.Modify();
                    until VendLedgEntry.Next() = 0;
            end;
        until Vendor.Next() = 0;
    end;

    procedure SetCurrency(NewCurrency: Record Currency)
    begin
        PageSetCurrency(NewCurrency);
        exit;
    end;

    local procedure PageSetCurrency(NewCurrency: Record Currency)
    begin
        Currency := NewCurrency;

        if Currency.Code <> '' then begin
            Currency.Get(Currency.Code);
            CurrencyCode := Currency.Code;
            PaymentTolerancePct := Currency."Payment Tolerance %";
            MaxPmtToleranceAmount := Currency."Max. Payment Tolerance Amount";
            DecimalPlaces := CheckApplnRounding(Currency."Amount Decimal Places");
        end else begin
            GLSetup.Get();
            PaymentTolerancePct := GLSetup."Payment Tolerance %";
            MaxPmtToleranceAmount := GLSetup."Max. Payment Tolerance Amount";
            DecimalPlaces := CheckApplnRounding(GLSetup."Amount Decimal Places");
        end;
    end;

    procedure InitializeRequest(AllCurrenciesFrom: Boolean; CurrencyCodeFrom: Code[10]; PaymentTolerancePctFrom: Decimal; MaxPmtToleranceAmountFrom: Decimal)
    begin
        AllCurrencies := AllCurrenciesFrom;
        CurrencyCode := CurrencyCodeFrom;
        PaymentTolerancePct := PaymentTolerancePctFrom;
        MaxPmtToleranceAmount := MaxPmtToleranceAmountFrom;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeCustLedgEntriesOnBeforeModifyCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeVendLedgEntryOnBeforeModifyVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;
}

