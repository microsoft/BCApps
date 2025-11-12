// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using System.Utilities;

codeunit 225 "Gen. Jnl.-Apply"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        GenJnlLine.Copy(Rec);

        IsHandled := false;
        OnBeforeRun(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GetCurrency();
        if GenJnlLine."Bal. Account Type" in
           [GenJnlLine."Bal. Account Type"::Customer, GenJnlLine."Bal. Account Type"::Vendor, GenJnlLine."Bal. Account Type"::Employee]
        then begin
            AccType := GenJnlLine."Bal. Account Type";
            AccNo := GenJnlLine."Bal. Account No.";
        end else begin
            AccType := GenJnlLine."Account Type";
            AccNo := GenJnlLine."Account No.";
        end;
        case AccType of
            AccType::Customer:
                ApplyCustomerLedgerEntry(GenJnlLine);
            AccType::Vendor:
                ApplyVendorLedgerEntry(GenJnlLine);
            AccType::Employee:
                ApplyEmployeeLedgerEntry(GenJnlLine);
            else
                Error(
                  Text005,
                  GenJnlLine.FieldCaption("Account Type"), GenJnlLine.FieldCaption("Bal. Account Type"));
        end;
        OnAfterRun(GenJnlLine);

        Rec := GenJnlLine;
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        AccNo: Code[20];
        CurrencyCode2: Code[10];
        EntrySelected: Boolean;
        AccType: Enum "Gen. Journal Account Type";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You must specify %1 or %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ConfirmChangeQst: Label 'CurrencyCode in the %1 will be changed from %2 to %3.\Do you wish to continue?', Comment = '%1 = Table Name, %2 and %3 = Currency Code';
        UpdateInterruptedErr: Label 'The update has been interrupted to respect the warning.';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label 'The %1 or %2 must be Customer or Vendor.';
#pragma warning restore AA0470
        Text006: Label 'All entries in one application must be in the same currency.';
        Text007: Label 'All entries in one application must be in the same currency or one or more of the EMU currencies. ';
#pragma warning restore AA0074
        EarlierPostingDateErr: Label 'You cannot apply and post an entry to an entry with an earlier posting date. Instead, post the document of type %1 with the number %2 and then apply it to the document of type %3 with the number %4.', Comment = '%1 = Applying document type, %2 = Applying document number, %3 = Entry document type, %4 = Entry document number';

    local procedure SelectCustLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var CustomAppliesToId: Code[50]) Selected: Boolean
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        ApplyCustEntries: Page "Apply Customer Entries";
        PreviousAppliesToID: Code[50];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectCustLedgEntry(GenJnlLine, AccNo, Selected, IsHandled, CustomAppliesToId);
        if IsHandled then
            exit(Selected);

        CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
        CustLedgEntry.SetRange("Customer No.", AccNo);
        CustLedgEntry.SetRange(Open, true);
        OnSelectCustLedgEntryOnAfterSetFilters(CustLedgEntry, GenJnlLine);
        PreviousAppliesToID := GenJnlLine."Applies-to ID";
        if GenJnlLine."Applies-to ID" = '' then
            GenJnlLine."Applies-to ID" := GenJnlLine."Document No.";
        if GenJnlLine."Applies-to ID" = '' then
            Error(
              Text000,
              GenJnlLine.FieldCaption("Document No."), GenJnlLine.FieldCaption("Applies-to ID"));
        ApplyCustEntries.SetGenJnlLine(GenJnlLine, GenJnlLine.FieldNo("Applies-to ID"));
        ApplyCustEntries.SetRecord(CustLedgEntry);
        ApplyCustEntries.SetTableView(CustLedgEntry);
        ApplyCustEntries.LookupMode(true);
        Selected := ApplyCustEntries.RunModal() = ACTION::LookupOK;
        if not Selected then
            GenJnlLine."Applies-to ID" := PreviousAppliesToID;
        CustomAppliesToId := ApplyCustEntries.GetCustomAppliesToID();
        Clear(ApplyCustEntries);

        OnAfterSelectCustLedgEntry(GenJnlLine, AccNo, Selected);
    end;

    local procedure SelectVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var CustomAppliesToId: Code[50]) Selected: Boolean
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        ApplyVendEntries: Page "Apply Vendor Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectVendLedgEntry(GenJnlLine, AccNo, Selected, IsHandled, CustomAppliesToId);
        if IsHandled then
            exit(Selected);

        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
        VendLedgEntry.SetRange("Vendor No.", AccNo);
        VendLedgEntry.SetRange(Open, true);
        OnSelectVendLedgEntryOnAfterSetFilters(VendLedgEntry, GenJnlLine);
        if GenJnlLine."Applies-to ID" = '' then
            GenJnlLine."Applies-to ID" := GenJnlLine."Document No.";
        if GenJnlLine."Applies-to ID" = '' then
            Error(
              Text000,
              GenJnlLine.FieldCaption("Document No."), GenJnlLine.FieldCaption("Applies-to ID"));
        ApplyVendEntries.SetGenJnlLine(GenJnlLine, GenJnlLine.FieldNo("Applies-to ID"));
        ApplyVendEntries.SetRecord(VendLedgEntry);
        ApplyVendEntries.SetTableView(VendLedgEntry);
        ApplyVendEntries.LookupMode(true);
        Selected := ApplyVendEntries.RunModal() = ACTION::LookupOK;
        CustomAppliesToId := ApplyVendEntries.GetCustomAppliesToID();
        Clear(ApplyVendEntries);

        OnAfterSelectVendLedgEntry(GenJnlLine, AccNo, Selected);
    end;

    local procedure SelectEmplLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var CustomAppliesToId: Code[50]) Selected: Boolean
    var
        EmplLedgEntry: Record "Employee Ledger Entry";
        ApplyEmplEntries: Page "Apply Employee Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectEmplLedgEntry(GenJnlLine, AccNo, Selected, IsHandled);
        if IsHandled then
            exit(Selected);

        EmplLedgEntry.SetCurrentKey("Employee No.", Open, Positive);
        EmplLedgEntry.SetRange("Employee No.", AccNo);
        EmplLedgEntry.SetRange(Open, true);
        OnSelectEmplLedgEntryOnAfterSetFilters(EmplLedgEntry, GenJnlLine);
        if GenJnlLine."Applies-to ID" = '' then
            GenJnlLine."Applies-to ID" := GenJnlLine."Document No.";
        if GenJnlLine."Applies-to ID" = '' then
            Error(
              Text000,
              GenJnlLine.FieldCaption("Document No."), GenJnlLine.FieldCaption("Applies-to ID"));
        ApplyEmplEntries.SetGenJnlLine(GenJnlLine, GenJnlLine.FieldNo("Applies-to ID"));
        ApplyEmplEntries.SetRecord(EmplLedgEntry);
        ApplyEmplEntries.SetTableView(EmplLedgEntry);
        ApplyEmplEntries.LookupMode(true);
        Selected := ApplyEmplEntries.RunModal() = ACTION::LookupOK;
        CustomAppliesToId := ApplyEmplEntries.GetCustomAppliesToID();
        Clear(ApplyEmplEntries);

        OnAfterSelectEmplLedgEntry(GenJnlLine, AccNo, Selected);
    end;

    local procedure UpdateCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCustLedgEntry(CustLedgEntry, GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        CustLedgEntry.CalcFields("Remaining Amount");
        CustLedgEntry."Remaining Amount" :=
          CurrExchRate.ExchangeAmount(
            CustLedgEntry."Remaining Amount", CustLedgEntry."Currency Code", GenJnlLine."Currency Code", GenJnlLine."Posting Date");
        CustLedgEntry."Remaining Amount" :=
          Round(CustLedgEntry."Remaining Amount", Currency."Amount Rounding Precision");
        CustLedgEntry."Remaining Pmt. Disc. Possible" :=
          CurrExchRate.ExchangeAmount(
            CustLedgEntry."Remaining Pmt. Disc. Possible", CustLedgEntry."Currency Code", GenJnlLine."Currency Code", GenJnlLine."Posting Date");
        CustLedgEntry."Remaining Pmt. Disc. Possible" :=
          Round(CustLedgEntry."Remaining Pmt. Disc. Possible", Currency."Amount Rounding Precision");
        CustLedgEntry."Amount to Apply" :=
          CurrExchRate.ExchangeAmount(
            CustLedgEntry."Amount to Apply", CustLedgEntry."Currency Code", GenJnlLine."Currency Code", GenJnlLine."Posting Date");
        CustLedgEntry."Amount to Apply" :=
          Round(CustLedgEntry."Amount to Apply", Currency."Amount Rounding Precision");
    end;

    local procedure UpdateVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateVendLedgEntry(VendLedgEntry, GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        VendLedgEntry.CalcFields("Remaining Amount");
        VendLedgEntry."Remaining Amount" :=
          CurrExchRate.ExchangeAmount(
            VendLedgEntry."Remaining Amount", VendLedgEntry."Currency Code", GenJnlLine."Currency Code", GenJnlLine."Posting Date");
        VendLedgEntry."Remaining Amount" :=
          Round(VendLedgEntry."Remaining Amount", Currency."Amount Rounding Precision");
        VendLedgEntry."Remaining Pmt. Disc. Possible" :=
          CurrExchRate.ExchangeAmount(
            VendLedgEntry."Remaining Pmt. Disc. Possible", VendLedgEntry."Currency Code", GenJnlLine."Currency Code", GenJnlLine."Posting Date");
        VendLedgEntry."Remaining Pmt. Disc. Possible" :=
          Round(VendLedgEntry."Remaining Pmt. Disc. Possible", Currency."Amount Rounding Precision");
        VendLedgEntry."Amount to Apply" :=
          CurrExchRate.ExchangeAmount(
            VendLedgEntry."Amount to Apply", VendLedgEntry."Currency Code", GenJnlLine."Currency Code", GenJnlLine."Posting Date");
        VendLedgEntry."Amount to Apply" :=
          Round(VendLedgEntry."Amount to Apply", Currency."Amount Rounding Precision");

        OnAfterUpdateVendLedgEntry(GenJnlLine, VendLedgEntry);
    end;

    local procedure UpdateEmployeeLedgEntry(var EmplLedgEntry: Record "Employee Ledger Entry")
    begin
        EmplLedgEntry.CalcFields("Remaining Amount");

        EmplLedgEntry."Remaining Amount" :=
          CurrExchRate.ExchangeAmount(
            EmplLedgEntry."Remaining Amount", EmplLedgEntry."Currency Code", GenJnlLine."Currency Code", GenJnlLine."Posting Date");

        EmplLedgEntry."Remaining Amount" :=
          Round(EmplLedgEntry."Remaining Amount", Currency."Amount Rounding Precision");

        EmplLedgEntry."Amount to Apply" :=
          CurrExchRate.ExchangeAmount(
            EmplLedgEntry."Amount to Apply", EmplLedgEntry."Currency Code", GenJnlLine."Currency Code", GenJnlLine."Posting Date");

        EmplLedgEntry."Amount to Apply" :=
          Round(EmplLedgEntry."Amount to Apply", Currency."Amount Rounding Precision");
    end;

    procedure CheckAgainstApplnCurrency(ApplnCurrencyCode: Code[10]; CompareCurrencyCode: Code[10]; AccType: Enum "Gen. Journal Account Type"; Message: Boolean): Boolean
    var
        Currency: Record Currency;
        Currency2: Record Currency;
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        CurrencyAppln: Option No,EMU,All;
    begin
        OnBeforeCheckAgainstApplnCurrency(ApplnCurrencyCode, CompareCurrencyCode);
        if ApplnCurrencyCode = CompareCurrencyCode then
            exit(true);

        case AccType of
            AccType::Customer:
                begin
                    SalesSetup.Get();
                    CurrencyAppln := SalesSetup."Appln. between Currencies";
                    case CurrencyAppln of
                        CurrencyAppln::No:
                            if ApplnCurrencyCode <> CompareCurrencyCode then
                                if Message then
                                    Error(Text006)
                                else
                                    exit(false);
                        CurrencyAppln::EMU:
                            begin
                                GLSetup.Get();
                                if not Currency.Get(ApplnCurrencyCode) then
                                    Currency."EMU Currency" := GLSetup."EMU Currency";
                                if not Currency2.Get(CompareCurrencyCode) then
                                    Currency2."EMU Currency" := GLSetup."EMU Currency";
                                if not Currency."EMU Currency" or not Currency2."EMU Currency" then
                                    if Message then
                                        Error(Text007)
                                    else
                                        exit(false);
                            end;
                    end;
                end;
            AccType::Vendor:
                begin
                    PurchSetup.Get();
                    CurrencyAppln := PurchSetup."Appln. between Currencies";
                    case CurrencyAppln of
                        CurrencyAppln::No:
                            if ApplnCurrencyCode <> CompareCurrencyCode then
                                if Message then
                                    Error(Text006)
                                else
                                    exit(false);
                        CurrencyAppln::EMU:
                            begin
                                GLSetup.Get();
                                if not Currency.Get(ApplnCurrencyCode) then
                                    Currency."EMU Currency" := GLSetup."EMU Currency";
                                if not Currency2.Get(CompareCurrencyCode) then
                                    Currency2."EMU Currency" := GLSetup."EMU Currency";
                                if not Currency."EMU Currency" or not Currency2."EMU Currency" then
                                    if Message then
                                        Error(Text007)
                                    else
                                        exit(false);
                            end;
                    end;
                end;
        end;

        exit(true);
    end;

    local procedure GetCurrency()
    begin
        if GenJnlLine."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else begin
            Currency.Get(GenJnlLine."Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    local procedure ApplyCustomerLedgerEntry(var GenJnlLine: Record "Gen. Journal Line")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        AppliedAmount: Decimal;
        CustomAppliesToId: Code[50];
        IsHandled: Boolean;
    begin
        GetAppliedCustomerEntries(TempCustLedgEntry, GenJnlLine);
        EntrySelected := SelectCustLedgEntry(GenJnlLine, CustomAppliesToId);
        if not EntrySelected then
            exit;

        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
        CustLedgEntry.SetRange("Customer No.", AccNo);
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");

        IsHandled := false;
        OnAfterCustLedgEntrySetFilters(CustLedgEntry, GenJnlLine, AccNo, CustomAppliesToId, IsHandled);
        if IsHandled then
            exit;

        if CustLedgEntry.Find('-') then begin
            CurrencyCode2 := CustLedgEntry."Currency Code";
            if GenJnlLine.Amount = 0 then begin
                repeat
                    if not TempCustLedgEntry.Get(CustLedgEntry."Entry No.") then begin
                        PaymentToleranceMgt.DelPmtTolApllnDocNo(GenJnlLine, CustLedgEntry."Document No.");
                        OnApplyCustomerLedgerEntryOnBeforeCheckAgainstApplnCurrency(GenJnlLine, CustLedgEntry);
                        CheckAgainstApplnCurrency(CurrencyCode2, CustLedgEntry."Currency Code", AccType::Customer, true);
                        UpdateCustLedgEntry(CustLedgEntry);
                        IsHandled := false;
                        OnBeforeFindCustApply(GenJnlLine, CustLedgEntry, GenJnlLine.Amount, IsHandled);
                        if not IsHandled then
                            if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlCust(GenJnlLine, CustLedgEntry, 0, false) and
                               (Abs(CustLedgEntry."Amount to Apply") >=
                                Abs(CustLedgEntry."Remaining Amount" - CustLedgEntry.GetRemainingPmtDiscPossible(GenJnlLine."Posting Date")))
                            then
                                GenJnlLine.Amount := GenJnlLine.Amount - (CustLedgEntry."Amount to Apply" - CustLedgEntry.GetRemainingPmtDiscPossible(GenJnlLine."Posting Date"))
                            else
                                GenJnlLine.Amount := GenJnlLine.Amount - CustLedgEntry."Amount to Apply";
                    end else
                        GetAppliedAmountOnCustLedgerEntry(TempCustLedgEntry, AppliedAmount);
                until CustLedgEntry.Next() = 0;
                TempCustLedgEntry.DeleteAll();

                if AppliedAmount <> 0 then
                    GenJnlLine.Amount += AppliedAmount;

                if (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Customer) or (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor) then
                    GenJnlLine.Amount := -GenJnlLine.Amount;
                GenJnlLine.Validate(Amount);
                OnApplyCustomerLedgerEntryOnAfterValidateAmount(GenJnlLine, CustLedgEntry);
            end else
                repeat
                    OnApplyCustomerLedgerEntryOnBeforeCheckAgainstApplnCurrencyCustomerAmountNotZero(GenJnlLine, CustLedgEntry);
                    CheckAgainstApplnCurrency(CurrencyCode2, CustLedgEntry."Currency Code", AccType::Customer, true);
                until CustLedgEntry.Next() = 0;
            if GenJnlLine."Currency Code" <> CurrencyCode2 then
                if GenJnlLine.Amount = 0 then begin
                    IsHandled := false;
                    OnApplyCustomerLedgerEntryOnBeforeConfirmUpdateCurrency(GenJnlLine, CustLedgEntry."Currency Code", IsHandled);
                    if not IsHandled then begin
                        ConfirmCurrencyUpdate(GenJnlLine, CustLedgEntry."Currency Code");
                        GenJnlLine."Currency Code" := CustLedgEntry."Currency Code";
                    end;
                end else begin
                    OnApplyCustomerLedgerEntryOnBeforeCheckAgainstApplnCurrencyCustomer(GenJnlLine, CustLedgEntry);
                    CheckAgainstApplnCurrency(GenJnlLine."Currency Code", CustLedgEntry."Currency Code", AccType::Customer, true);
                end;
            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::" ";
            GenJnlLine."Applies-to Doc. No." := '';
            OnApplyCustomerLedgerEntryOnAfterSetCustomerAppliesToDocNo(GenJnlLine, CustLedgEntry);
        end else
            GenJnlLine."Applies-to ID" := '';

        if (GenJnlLine."Applies-to ID" = '') and (CustomAppliesToId <> '') then
            GenJnlLine."Applies-to ID" := CustomAppliesToId;

        GenJnlLine.SetJournalLineFieldsFromApplication();

        OnApplyCustomerLedgerEntryOnBeforeModify(GenJnlLine, CustLedgEntry);

        if GenJnlLine.Modify() then;
        if GenJnlLine.Amount <> 0 then
            if not PaymentToleranceMgt.PmtTolGenJnl(GenJnlLine) then
                exit;
    end;

    procedure SetVendApplIdAPI(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        TempApplyingVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        Vendor: Record Vendor;
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        VendEntrySetApplID: Codeunit "Vend. Entry-SetAppl.ID";
        ApplnCurrencyCode: Code[10];
    begin
        if GenJournalLine."Applies-to ID" = '' then
            GenJournalLine."Applies-to ID" := GenJournalLine."Document No.";
        if GenJournalLine."Applies-to ID" = '' then
            Error(
              Text000,
              GenJournalLine.FieldCaption("Document No."), GenJournalLine.FieldCaption("Applies-to ID"));

        ApplnCurrencyCode := GenJournalLine."Currency Code";
        TempApplyingVendorLedgerEntry."Posting Date" := GenJournalLine."Posting Date";
        TempApplyingVendorLedgerEntry."Document Type" := GenJournalLine."Document Type";
        TempApplyingVendorLedgerEntry."Document No." := GenJournalLine."Document No.";
        if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::Vendor then begin
            TempApplyingVendorLedgerEntry."Vendor No." := GenJournalLine."Bal. Account No.";
            Vendor.Get(TempApplyingVendorLedgerEntry."Vendor No.");
            TempApplyingVendorLedgerEntry.Description := Vendor.Name;
        end else begin
            TempApplyingVendorLedgerEntry."Vendor No." := GenJournalLine."Account No.";
            TempApplyingVendorLedgerEntry.Description := GenJournalLine.Description;
        end;
        TempApplyingVendorLedgerEntry."Currency Code" := GenJournalLine."Currency Code";
        TempApplyingVendorLedgerEntry.Amount := GenJournalLine.Amount;
        TempApplyingVendorLedgerEntry."Remaining Amount" := GenJournalLine.Amount;
        OnSetVendApplIdAPIOnBeforeCheckPostingDate(TempApplyingVendorLedgerEntry, GenJournalLine, VendorLedgerEntry);
        if TempApplyingVendorLedgerEntry."Posting Date" < VendorLedgerEntry."Posting Date" then
            Error(
                EarlierPostingDateErr, TempApplyingVendorLedgerEntry."Document Type", TempApplyingVendorLedgerEntry."Document No.",
                VendorLedgerEntry."Document Type", VendorLedgerEntry."Document No.");

        if TempApplyingVendorLedgerEntry."Entry No." <> 0 then begin
            OnSetVendApplIdAPIOnBeforeCheckAgainstApplnCurrency(GenJournalLine, VendorLedgerEntry);
            GenJnlApply.CheckAgainstApplnCurrency(
                ApplnCurrencyCode, VendorLedgerEntry."Currency Code", GenJournalLine."Account Type"::Vendor, true);
        end;

        VendorLedgerEntry.SetRange("Entry No.", VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");
        VendEntrySetApplID.SetApplId(VendorLedgerEntry, TempApplyingVendorLedgerEntry, GenJournalLine."Applies-to ID");
    end;

    procedure ApplyVendorLedgerEntryAPI(var GenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
    begin
        GenJnlLine.Copy(GenJournalLine);
        GetCurrency();
        GenJnlLine.GetAccTypeAndNo(GenJnlLine, AccType, AccNo);

        GetAppliedVendorEntries(TempVendorLedgerEntry, GenJnlLine);
        GenJnlLine."Applies-to ID" := GenJnlLine."Document No.";
        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetCurrentKey("Vendor No.", Open, Positive);
        VendorLedgerEntry.SetRange("Vendor No.", AccNo);
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetRange("Applies-to ID", GenJnlLine."Document No.");

        if VendorLedgerEntry.Find('-') then begin
            CurrencyCode2 := VendorLedgerEntry."Currency Code";
            if GenJnlLine.Amount = 0 then begin
                repeat
                    if not TempVendorLedgerEntry.Get(VendorLedgerEntry."Entry No.") then begin
                        PaymentToleranceMgt.DelPmtTolApllnDocNo(GenJnlLine, VendorLedgerEntry."Document No.");
                        OnApplyVendorLedgerEntryAPIOnBeforeCheckAgainstApplnCurrencyAmountZero(GenJnlLine, VendorLedgerEntry);
                        CheckAgainstApplnCurrency(CurrencyCode2, VendorLedgerEntry."Currency Code", AccType::Vendor, true);
                        UpdateVendLedgEntry(VendorLedgerEntry);
                        if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlVend(GenJnlLine, VendorLedgerEntry, 0, false) and
                           (Abs(VendorLedgerEntry."Amount to Apply") >=
                            Abs(VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry.GetRemainingPmtDiscPossible(GenJnlLine."Posting Date")))
                        then
                            GenJnlLine.Amount := GenJnlLine.Amount - (VendorLedgerEntry."Amount to Apply" - VendorLedgerEntry."Remaining Pmt. Disc. Possible")
                        else
                            GenJnlLine.Amount := GenJnlLine.Amount - VendorLedgerEntry."Amount to Apply";
                    end;
                until VendorLedgerEntry.Next() = 0;
                TempVendorLedgerEntry.DeleteAll();
                if (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Customer) or (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor) then
                    GenJnlLine.Amount := -GenJnlLine.Amount;
                OnApplyVendorLedgerEntryAPIOnBeforeValidateAmount(GenJnlLine);
                GenJnlLine.Validate(Amount);
            end else
                repeat
                    OnApplyVendorLedgerEntryAPIOnBeforeCheckAgainstApplnCurrencyAmountNonZero(GenJnlLine, VendorLedgerEntry);
                    CheckAgainstApplnCurrency(CurrencyCode2, VendorLedgerEntry."Currency Code", AccType::Vendor, true);
                until VendorLedgerEntry.Next() = 0;
            if GenJnlLine."Currency Code" <> CurrencyCode2 then
                if GenJnlLine.Amount = 0 then
                    GenJnlLine."Currency Code" := VendorLedgerEntry."Currency Code"
                else begin
                    OnApplyVendorLedgerEntryAPIOnBeforeCheckAgainstApplnCurrencyDifferentCurrenciesAmountNonZero(GenJnlLine, VendorLedgerEntry);
                    CheckAgainstApplnCurrency(GenJnlLine."Currency Code", VendorLedgerEntry."Currency Code", AccType::Vendor, true);
                end;
            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::" ";
            GenJnlLine."Applies-to Doc. No." := '';
            OnApplyVendorLedgerEntryOnAfterSetVendorAppliesToDocNo(GenJnlLine, VendorLedgerEntry);
        end else
            GenJnlLine."Applies-to ID" := '';

        GenJnlLine.SetJournalLineFieldsFromApplication();

        if GenJnlLine.Modify() then;
        if GenJnlLine.Amount <> 0 then
            if not PaymentToleranceMgt.PmtTolGenJnl(GenJnlLine) then
                exit;
    end;

    local procedure ApplyVendorLedgerEntry(var GenJnlLine: Record "Gen. Journal Line")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        CustomAppliesToId: Code[50];
        IsHandled: Boolean;
    begin
        GetAppliedVendorEntries(TempVendorLedgerEntry, GenJnlLine);
        EntrySelected := SelectVendLedgEntry(GenJnlLine, CustomAppliesToId);
        if not EntrySelected then
            exit;

        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
        VendLedgEntry.SetRange("Vendor No.", AccNo);
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
        OnAfterVendLedgEntrySetFilters(VendLedgEntry, GenJnlLine, AccNo);
        if VendLedgEntry.Find('-') then begin
            CurrencyCode2 := VendLedgEntry."Currency Code";
            if GenJnlLine.Amount = 0 then begin
                repeat
                    if not TempVendorLedgerEntry.Get(VendLedgEntry."Entry No.") then begin
                        PaymentToleranceMgt.DelPmtTolApllnDocNo(GenJnlLine, VendLedgEntry."Document No.");
                        OnApplyVendorLedgerEntryOnBeforeCheckAgainstApplnCurrency(GenJnlLine, VendLedgEntry);
                        CheckAgainstApplnCurrency(CurrencyCode2, VendLedgEntry."Currency Code", AccType::Vendor, true);
                        UpdateVendLedgEntry(VendLedgEntry);
                        IsHandled := false;
                        OnBeforeFindVendApply(GenJnlLine, VendLedgEntry, GenJnlLine.Amount, IsHandled);
                        if not IsHandled then
                            if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlVend(GenJnlLine, VendLedgEntry, 0, false) and
                               (Abs(VendLedgEntry."Amount to Apply") >=
                                Abs(VendLedgEntry."Remaining Amount" - VendLedgEntry.GetRemainingPmtDiscPossible(GenJnlLine."Posting Date")))
                            then
                                GenJnlLine.Amount := GenJnlLine.Amount - (VendLedgEntry."Amount to Apply" - VendLedgEntry.GetRemainingPmtDiscPossible(GenJnlLine."Posting Date"))
                            else
                                GenJnlLine.Amount := GenJnlLine.Amount - VendLedgEntry."Amount to Apply";
                        GenJnlLine."Remit-to Code" := VendLedgEntry."Remit-to Code";
                    end;
                until VendLedgEntry.Next() = 0;
                TempVendorLedgerEntry.DeleteAll();
                if (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Customer) or (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor) then
                    GenJnlLine.Amount := -GenJnlLine.Amount;
                OnApplyVendorLedgerEntryOnBeforeValidateAmount(GenJnlLine, VendLedgEntry);
                GenJnlLine.Validate(Amount);
            end else
                repeat
                    OnApplyVendorLedgerEntryOnBeforeCheckAgainstApplnCurrencyAmountNotZero(GenJnlLine, VendLedgEntry);
                    CheckAgainstApplnCurrency(CurrencyCode2, VendLedgEntry."Currency Code", AccType::Vendor, true);
                until VendLedgEntry.Next() = 0;
            if GenJnlLine."Currency Code" <> CurrencyCode2 then
                if GenJnlLine.Amount = 0 then begin
                    IsHandled := false;
                    OnApplyVendorLedgerEntryOnBeforeConfirmUpdateCurrency(GenJnlLine, VendLedgEntry."Currency Code", IsHandled);
                    if not IsHandled then begin
                        ConfirmCurrencyUpdate(GenJnlLine, VendLedgEntry."Currency Code");
                        GenJnlLine."Currency Code" := VendLedgEntry."Currency Code";
                    end;
                end else begin
                    OnApplyVendorLedgerEntryOnBeforeCheckAgainstApplnCurrencyDifferentCurrenciesAmountNotZero(GenJnlLine, VendLedgEntry);
                    CheckAgainstApplnCurrency(GenJnlLine."Currency Code", VendLedgEntry."Currency Code", AccType::Vendor, true);
                end;
            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::" ";
            GenJnlLine."Applies-to Doc. No." := '';
            OnApplyVendorLedgerEntryOnAfterSetGenJnlLineAppliesToDocNo(GenJnlLine, VendLedgEntry);
        end else
            GenJnlLine."Applies-to ID" := '';

        if (GenJnlLine."Applies-to ID" = '') and (CustomAppliesToId <> '') then
            GenJnlLine."Applies-to ID" := CustomAppliesToId;

        GenJnlLine.SetJournalLineFieldsFromApplication();

        OnApplyVendorLedgerEntryOnBeforeModify(GenJnlLine, TempVendorLedgerEntry, VendLedgEntry);
        if GenJnlLine.Modify() then;
        if GenJnlLine.Amount <> 0 then
            if not PaymentToleranceMgt.PmtTolGenJnl(GenJnlLine) then
                exit;
    end;

    local procedure ApplyEmployeeLedgerEntry(var GenJnlLine: Record "Gen. Journal Line")
    var
        EmplLedgEntry: Record "Employee Ledger Entry";
        CustomAppliesToId: Code[50];
    begin
        EntrySelected := SelectEmplLedgEntry(GenJnlLine, CustomAppliesToId);
        if not EntrySelected then
            exit;

        EmplLedgEntry.Reset();
        EmplLedgEntry.SetCurrentKey("Employee No.", Open, Positive);
        EmplLedgEntry.SetRange("Employee No.", AccNo);
        EmplLedgEntry.SetRange(Open, true);
        EmplLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
        if EmplLedgEntry.Find('-') then begin
            CurrencyCode2 := EmplLedgEntry."Currency Code";
            if GenJnlLine.Amount = 0 then begin
                repeat
                    UpdateEmployeeLedgEntry(EmplLedgEntry);
                    OnApplyEmployeeLedgerEntryOnBeforeUpdateAmount(GenJnlLine, EmplLedgEntry);
                    GenJnlLine.Amount := GenJnlLine.Amount - EmplLedgEntry."Amount to Apply";
                until EmplLedgEntry.Next() = 0;
                if (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Customer) or
                   (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor) or
                   (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Employee)
                then
                    GenJnlLine.Amount := -GenJnlLine.Amount;
                GenJnlLine.Validate(Amount);
            end;
            if GenJnlLine."Currency Code" <> CurrencyCode2 then
                if GenJnlLine.Amount = 0 then begin
                    ConfirmCurrencyUpdate(GenJnlLine, EmplLedgEntry."Currency Code");
                    GenJnlLine."Currency Code" := EmplLedgEntry."Currency Code"
                end;
            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::" ";
            GenJnlLine."Applies-to Doc. No." := '';
        end else
            GenJnlLine."Applies-to ID" := '';

        if (GenJnlLine."Applies-to ID" = '') and (CustomAppliesToId <> '') then
            GenJnlLine."Applies-to ID" := CustomAppliesToId;

        GenJnlLine.SetJournalLineFieldsFromApplication();

        if GenJnlLine.Modify() then;

        OnAfterApplyEmployeeLedgerEntry(GenJnlLine, EmplLedgEntry);
    end;

    local procedure GetAppliedCustomerEntries(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; GenJournalLineSource: Record "Gen. Journal Line")
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if GenJournalLineSource.Amount <> 0 then
            exit;
        GenJournalLine.SetRange("Journal Template Name", GenJournalLineSource."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLineSource."Journal Batch Name");
        GenJournalLine.SetFilter("Line No.", '<>%1', GenJournalLineSource."Line No.");
        GenJournalLine.SetRange("Document No.", GenJournalLineSource."Document No.");
        if not GenJournalLine.IsEmpty() then begin
            CustLedgerEntry.SetCurrentKey("Customer No.", Open, Positive);
            CustLedgerEntry.SetRange("Customer No.", AccNo);
            CustLedgerEntry.SetRange(Open, true);
            CustLedgerEntry.SetRange("Applies-to ID", GenJournalLineSource."Document No.");
            if CustLedgerEntry.FindSet() then
                repeat
                    TempCustLedgerEntry := CustLedgerEntry;
                    TempCustLedgerEntry.Insert();
                until CustLedgerEntry.Next() = 0;
        end;
    end;

    local procedure GetAppliedVendorEntries(var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; GenJournalLineSource: Record "Gen. Journal Line")
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if GenJournalLineSource.Amount <> 0 then
            exit;
        GenJournalLine.SetRange("Journal Template Name", GenJournalLineSource."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLineSource."Journal Batch Name");
        GenJournalLine.SetFilter("Line No.", '<>%1', GenJournalLineSource."Line No.");
        GenJournalLine.SetRange("Document No.", GenJournalLineSource."Document No.");
        if not GenJournalLine.IsEmpty() then begin
            VendorLedgerEntry.SetCurrentKey("Vendor No.", Open, Positive);
            VendorLedgerEntry.SetRange("Vendor No.", AccNo);
            VendorLedgerEntry.SetRange(Open, true);
            VendorLedgerEntry.SetRange("Applies-to ID", GenJournalLineSource."Document No.");
            if VendorLedgerEntry.FindSet() then
                repeat
                    TempVendorLedgerEntry := VendorLedgerEntry;
                    TempVendorLedgerEntry.Insert();
                until VendorLedgerEntry.Next() = 0;
        end;
    end;

    local procedure ConfirmCurrencyUpdate(GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10])
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(
             StrSubstNo(
               ConfirmChangeQst, GenJournalLine.TableCaption(), GenJournalLine."Currency Code",
               CurrencyCode), true)
        then
            Error(UpdateInterruptedErr);
    end;

    local procedure GetAppliedAmountOnCustLedgerEntry(CustLedgEntry: Record "Cust. Ledger Entry"; var AppliedAmount: Decimal)
    var
        CustLedgEntry2: Record "Cust. Ledger Entry";
    begin
        if CustLedgEntry."Amount to Apply" = 0 then
            exit;

        CustLedgEntry2.Get(CustLedgEntry."Entry No.");
        if CustLedgEntry2."Amount to Apply" = CustLedgEntry."Amount to Apply" then
            CalcAppliedAmountOnCustLedgerEntry(CustLedgEntry, AppliedAmount)
        else
            CalcAppliedAmountOnCustLedgerEntry(CustLedgEntry2, AppliedAmount);
    end;

    local procedure CalcAppliedAmountOnCustLedgerEntry(CustLedgEntry: Record "Cust. Ledger Entry"; var AppliedAmount: Decimal)
    begin
        CustLedgEntry.CalcFields("Remaining Amount");
        OnCalcAppliedAmountOnCustLedgerEntryOnAfterCalcRemainingAmount(CustLedgEntry);
        if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlCust(GenJnlLine, CustLedgEntry, 0, false) and
            (Abs(CustLedgEntry."Amount to Apply") >=
            Abs(CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible"))
        then
            AppliedAmount := AppliedAmount - (CustLedgEntry."Amount to Apply" - CustLedgEntry."Remaining Pmt. Disc. Possible")
        else
            AppliedAmount := AppliedAmount - CustLedgEntry."Amount to Apply";
    end;

    [Scope('OnPrem')]
    procedure GetEntrySelected(): Boolean
    begin
        exit(EntrySelected);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCustLedgEntrySetFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var CustomAppliesToId: Code[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVendLedgEntrySetFilters(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyEmployeeLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSelectCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var AccNo: Code[20]; var Selected: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSelectEmplLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var AccNo: Code[20]; var Selected: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSelectVendLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var AccNo: Code[20]; var Selected: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustomerLedgerEntryOnBeforeCheckAgainstApplnCurrency(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustomerLedgerEntryOnBeforeModify(var GenJnlLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendorLedgerEntryOnBeforeCheckAgainstApplnCurrency(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendorLedgerEntryOnBeforeModify(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorLedgerEntryLocal: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyEmployeeLedgerEntryOnBeforeUpdateAmount(var GenJournalLine: Record "Gen. Journal Line"; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAgainstApplnCurrency(var ApplnCurrencyCode: Code[10]; var CompareCurrencyCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindCustApply(GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; var Amount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindVendApply(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; var Amount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var AccNo: Code[20]; var Selected: Boolean; var IsHandled: Boolean; var CustomAppliesToId: Code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectEmplLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var AccNo: Code[20]; var Selected: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectVendLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var AccNo: Code[20]; var Selected: Boolean; var IsHandled: Boolean; var CustomAppliesToId: Code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectCustLedgEntryOnAfterSetFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectEmplLedgEntryOnAfterSetFilters(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectVendLedgEntryOnAfterSetFilters(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendorLedgerEntryOnBeforeConfirmUpdateCurrency(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustomerLedgerEntryOnBeforeConfirmUpdateCurrency(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustomerLedgerEntryOnBeforeCheckAgainstApplnCurrencyCustomerAmountNotZero(GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustomerLedgerEntryOnBeforeCheckAgainstApplnCurrencyCustomer(GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnApplyCustomerLedgerEntryOnAfterValidateAmount(var GenJnlLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetVendApplIdAPIOnBeforeCheckAgainstApplnCurrency(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendorLedgerEntryAPIOnBeforeCheckAgainstApplnCurrencyAmountZero(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendorLedgerEntryAPIOnBeforeCheckAgainstApplnCurrencyAmountNonZero(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendorLedgerEntryAPIOnBeforeCheckAgainstApplnCurrencyDifferentCurrenciesAmountNonZero(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendorLedgerEntryOnAfterSetGenJnlLineAppliesToDocNo(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendorLedgerEntryOnBeforeCheckAgainstApplnCurrencyAmountNotZero(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendorLedgerEntryOnBeforeCheckAgainstApplnCurrencyDifferentCurrenciesAmountNotZero(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyCustomerLedgerEntryOnAfterSetCustomerAppliesToDocNo(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendorLedgerEntryOnAfterSetVendorAppliesToDocNo(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVendLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendorLedgerEntryAPIOnBeforeValidateAmount(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendorLedgerEntryOnBeforeValidateAmount(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetVendApplIdAPIOnBeforeCheckPostingDate(var TempApplyingVendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAppliedAmountOnCustLedgerEntryOnAfterCalcRemainingAmount(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;
}

