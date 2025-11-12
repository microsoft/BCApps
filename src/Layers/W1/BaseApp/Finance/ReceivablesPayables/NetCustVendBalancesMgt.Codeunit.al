// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

codeunit 108 "Net Cust/Vend Balances Mgt."
{
    var
        NetBalancesParameters: Record "Net Balances Parameters";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlTemplate: Record "Gen. Journal Template";
        VendorGenJnlLine: Record "Gen. Journal Line";
        CustomerGenJnlLine: Record "Gen. Journal Line";
        GlobalCustLedgEntry: Record "Cust. Ledger Entry";
        GlobalVendLedgEntry: Record "Vendor Ledger Entry";
        Window: Dialog;
        NetAmount: Decimal;
        FirstLineNo: Integer;
        LastLineNo: Integer;
        IncreaseDocNo: Boolean;
        ProcessingMsg: Label 'Processing vendors #1########## @2@@@@@@@@@@@@@', Comment = '#1 - vendor code, @2 - processing bar';
        DuplicateLineExistsErr: Label 'There is the duplicate journal line in journal template name %2, journal batch name %3, document number %1 applied to %4 %5.',
            Comment = '%1 - document no., %2 - template name, %3 - batch name, %4 - document type, %5 - document no.';
        CustomerBlockedErr: Label 'Customer %1 is blocked', Comment = '%1 - customer no.';

    procedure NetCustVendBalances(var Vendor: Record Vendor; NewNetBalancesParameters: Record "Net Balances Parameters")
    var
        Customer: Record Customer;
        VendorCount: Integer;
    begin
        NetBalancesParameters := NewNetBalancesParameters;
        NetBalancesParameters.Verify();
        Initialize();

        Window.Open(ProcessingMsg);

        Vendor.SetLoadFields(Blocked);
        if Vendor.FindSet() then
            repeat
                Window.Update(1, Vendor."No.");
                VendorCount := VendorCount + 1;
                Window.Update(2, ROUND(VendorCount / Vendor.Count() * 10000, 1));

                if FindLinkedCustomer(Vendor, Customer) then
                    HandleVendor(Vendor."No.", Customer."No.");
            until Vendor.Next() = 0;

        Window.Close();
    end;

    local procedure FindLinkedCustomer(Vendor: Record Vendor; var Customer: Record Customer): Boolean;
    var
        CustomerNo: Code[20];
    begin
        CustomerNo := Vendor.GetLinkedCustomer();
        if CustomerNo <> '' then begin
            Customer.Reset();
            Customer.SetLoadFields(Blocked);
            Customer.Get(CustomerNo);
            if Customer.Blocked = Customer.Blocked::" " then
                exit(true)
            else
                Message(CustomerBlockedErr, Customer."No.");
        end;
    end;

    local procedure Initialize()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.LockTable();
        NetBalancesParameters.TestField("Journal Template Name");
        NetBalancesParameters.TestField("Journal Batch Name");
        GenJnlTemplate.Get(NetBalancesParameters."Journal Template Name");
        GenJnlBatch.Get(NetBalancesParameters."Journal Template Name", NetBalancesParameters."Journal Batch Name");
        GenJournalLine.Validate("Journal Template Name", NetBalancesParameters."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", NetBalancesParameters."Journal Batch Name");
        SetGenJnlLine(GenJournalLine);
        GenJournalLine.SetRange("Journal Template Name", NetBalancesParameters."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", NetBalancesParameters."Journal Batch Name");
        if GenJournalLine.FindLast() then begin
            FirstLineNo := GenJournalLine."Line No.";
            LastLineNo := GenJournalLine."Line No.";
        end;

        IncreaseDocNo := false;
    end;

    local procedure HandleVendor(VendorNo: Code[20]; CustomerNo: Code[20])
    var
        Customer: Record Customer;
        VendLedgEntry: Record "Vendor Ledger Entry";
        CurrencyCode: Code[10];
    begin
        if CustomerNo <> '' then begin
            Customer.Get(CustomerNo);
            if FindVendLedgEntries(VendorNo, VendLedgEntry) then begin
                CurrencyCode := VendLedgEntry."Currency Code";
                repeat
                    if CurrencyCode <> VendLedgEntry."Currency Code" then
                        NetCustVendBalances(VendorNo, CustomerNo, CurrencyCode);
                    CurrencyCode := VendLedgEntry."Currency Code";
                until VendLedgEntry.Next() = 0;
                NetCustVendBalances(VendorNo, CustomerNo, CurrencyCode);

                if IncreaseDocNo then begin
                    NetBalancesParameters."Document No." := INCSTR(NetBalancesParameters."Document No.");
                    IncreaseDocNo := false;
                end;
            end;
        end;
    end;

    local procedure SetNetAmount(VendorNo: Code[20]; CustomerNo: Code[20]; CurrencyCode: Code[10]);
    var
        VendorRemainingAmount: Decimal;
        CustomerRemainingAmount: Decimal;
    begin
        NetAmount := 0;
        VendorRemainingAmount := SumVendorRemainingAmount(VendorNo, CurrencyCode);
        if VendorRemainingAmount < 0 then begin
            CustomerRemainingAmount := SumCustomerRemainingAmount(CustomerNo, CurrencyCode);
            if CustomerRemainingAmount > 0 then
                NetAmount := MinDec(CustomerRemainingAmount, -VendorRemainingAmount);
        end;
    end;

    local procedure NetCustVendBalances(VendorNo: Code[20]; CustomerNo: Code[20]; CurrencyCode: Code[10]);
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendDocNetAmount: Decimal;
        CustDocNetAmount: Decimal;
        VendNetAmount: Decimal;
        CustNetAmount: Decimal;
        SmallerNetAmount: Decimal;
        VendorRemainingAmount: Decimal;
        CustomerRemainingAmount: Decimal;
    begin
        SetNetAmount(VendorNo, CustomerNo, CurrencyCode);
        if NetAmount > 0 then begin
            if not IncreaseDocNo then
                IncreaseDocNo := true;
            GlobalVendLedgEntry.SetRange(Positive, false);
            GlobalCustLedgEntry.SetRange(Positive, true);
            VendLedgEntry.Copy(GlobalVendLedgEntry);
            CustLedgEntry.Copy(GlobalCustLedgEntry);

            case NetBalancesParameters."Order of Suggestion" of
                "Net Cust/Vend Balances Order"::"Fin. Ch. Memo First":
                    CalcPartNetAmount(VendLedgEntry, CustLedgEntry, VendDocNetAmount, CustDocNetAmount, "Gen. Journal Document Type"::"Finance Charge Memo");
                "Net Cust/Vend Balances Order"::"Invoices First":
                    CalcPartNetAmount(VendLedgEntry, CustLedgEntry, VendDocNetAmount, CustDocNetAmount, "Gen. Journal Document Type"::Invoice);
                else begin
                    GlobalVendLedgEntry.SetCurrentKey("Entry No.");
                    GlobalCustLedgEntry.SetCurrentKey("Entry No.");
                end;
            end;

            if NetAmount < VendDocNetAmount then
                VendDocNetAmount := NetAmount;
            if NetAmount < CustDocNetAmount then
                CustDocNetAmount := NetAmount;
            VendNetAmount := NetAmount - VendDocNetAmount;
            CustNetAmount := NetAmount - CustDocNetAmount;

            case true of
                (VendDocNetAmount = 0) and (CustDocNetAmount = 0):
                    begin
                        SmallerNetAmount := MinDec(VendNetAmount, CustNetAmount);
                        NetBalances(GlobalVendLedgEntry, GlobalCustLedgEntry, VendorRemainingAmount, CustomerRemainingAmount, SmallerNetAmount);
                    end;
                (VendDocNetAmount > 0) and (CustDocNetAmount = 0):
                    begin
                        SmallerNetAmount := MinDec(VendDocNetAmount, CustNetAmount);
                        NetBalances(VendLedgEntry, GlobalCustLedgEntry, VendorRemainingAmount, CustomerRemainingAmount, SmallerNetAmount);
                        CustNetAmount := CustNetAmount - VendDocNetAmount;
                        SmallerNetAmount := MinDec(VendNetAmount, CustNetAmount);
                        if SmallerNetAmount > 0 then begin
                            VendorRemainingAmount := 0;
                            NetBalances(GlobalVendLedgEntry, GlobalCustLedgEntry, VendorRemainingAmount, CustomerRemainingAmount, SmallerNetAmount);
                        end;
                    end;
                (VendDocNetAmount = 0) and (CustDocNetAmount > 0):
                    begin
                        SmallerNetAmount := MinDec(VendNetAmount, CustDocNetAmount);
                        NetBalances(GlobalVendLedgEntry, CustLedgEntry, VendorRemainingAmount, CustomerRemainingAmount, SmallerNetAmount);
                        VendNetAmount := VendNetAmount - CustDocNetAmount;
                        SmallerNetAmount := MinDec(VendNetAmount, CustNetAmount);
                        if SmallerNetAmount > 0 then begin
                            CustomerRemainingAmount := 0;
                            NetBalances(GlobalVendLedgEntry, GlobalCustLedgEntry, VendorRemainingAmount, CustomerRemainingAmount, SmallerNetAmount);
                        end;
                    end;
                else
                    case true of
                        VendDocNetAmount > CustDocNetAmount:
                            begin
                                SmallerNetAmount := CustDocNetAmount;
                                NetBalances(VendLedgEntry, CustLedgEntry, VendorRemainingAmount, CustomerRemainingAmount, SmallerNetAmount);
                                VendDocNetAmount := VendDocNetAmount - CustDocNetAmount;
                                SmallerNetAmount := MinDec(VendDocNetAmount, CustNetAmount);
                                if SmallerNetAmount > 0 then begin
                                    CustomerRemainingAmount := 0;
                                    NetBalances(VendLedgEntry, GlobalCustLedgEntry, VendorRemainingAmount, CustomerRemainingAmount, SmallerNetAmount);
                                    CustNetAmount := CustNetAmount - VendDocNetAmount;
                                    SmallerNetAmount := MinDec(VendNetAmount, CustNetAmount);
                                    if SmallerNetAmount > 0 then begin
                                        VendorRemainingAmount := 0;
                                        NetBalances(GlobalVendLedgEntry, GlobalCustLedgEntry, VendorRemainingAmount, CustomerRemainingAmount, SmallerNetAmount);
                                    end;
                                end;
                            end;
                        VendDocNetAmount < CustDocNetAmount:
                            begin
                                SmallerNetAmount := VendDocNetAmount;
                                NetBalances(VendLedgEntry, CustLedgEntry, VendorRemainingAmount, CustomerRemainingAmount, SmallerNetAmount);
                                CustDocNetAmount := CustDocNetAmount - VendDocNetAmount;
                                SmallerNetAmount := MinDec(VendNetAmount, CustDocNetAmount);
                                if SmallerNetAmount > 0 then begin
                                    VendorRemainingAmount := 0;
                                    NetBalances(GlobalVendLedgEntry, CustLedgEntry, VendorRemainingAmount, CustomerRemainingAmount, SmallerNetAmount);
                                    VendNetAmount := VendNetAmount - CustDocNetAmount;
                                    SmallerNetAmount := MinDec(VendNetAmount, CustNetAmount);
                                    if SmallerNetAmount > 0 then begin
                                        CustomerRemainingAmount := 0;
                                        NetBalances(GlobalVendLedgEntry, GlobalCustLedgEntry, VendorRemainingAmount, CustomerRemainingAmount, SmallerNetAmount);
                                    end;
                                end;
                            end;
                        else begin
                            SmallerNetAmount := VendDocNetAmount;
                            NetBalances(VendLedgEntry, CustLedgEntry, VendorRemainingAmount, CustomerRemainingAmount, SmallerNetAmount);
                            SmallerNetAmount := MinDec(VendNetAmount, CustNetAmount);
                            if SmallerNetAmount > 0 then
                                NetBalances(GlobalVendLedgEntry, GlobalCustLedgEntry, VendorRemainingAmount, CustomerRemainingAmount, SmallerNetAmount);
                        end;
                    end;
            end;
        end;
    end;

    local procedure InsertGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry"; CustLedgEntry: Record "Cust. Ledger Entry"; ForVLE: Boolean);
    begin
        InitGenJnlLine(GenJnlLine, VendLedgEntry);
        if ForVLE then
            FillGenJnlLineFromVendLedgEntry(GenJnlLine, VendLedgEntry)
        else
            FillGenJnlLineFromCustledgEntry(GenJnlLine, CustLedgEntry);
        FailIfDuplicateLineExists(GenJnlLine);
        GenJnlLine.Insert();
    end;

    local procedure FailIfDuplicateLineExists(GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetLoadFields("Document No.");
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type");
        GenJournalLine.SetRange("Account No.", GenJournalLine."Account No.");
        GenJournalLine.SetRange("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type");
        GenJournalLine.SetRange("Applies-to Doc. No.", GenJournalLine."Applies-to Doc. No.");
        if GenJournalLine.FindFirst() then
            Error(
                DuplicateLineExistsErr,
                GenJournalLine."Document No.",
                GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
                GenJournalLine."Applies-to Doc. Type", GenJournalLine."Applies-to Doc. No.");
    end;

    local procedure NetBalances(var VendLedgEntry: Record "Vendor Ledger Entry"; var CustLedgEntry: Record "Cust. Ledger Entry"; var VendorRemainingAmount: Decimal; var CustomerRemainingAmount: Decimal; var TempNetAmount: Decimal);
    var
        MinNetAmount: Decimal;
    begin
        NetAmount := NetAmount - TempNetAmount;
        if VendorRemainingAmount = 0 then
            VendLedgEntry.FindFirst();
        if CustomerRemainingAmount = 0 then
            CustLedgEntry.FindFirst();
        repeat
            if VendorRemainingAmount <= 0 then begin
                SetOnHold(VendLedgEntry);
                VendLedgEntry.CalcFields("Remaining Amount");
                OnNetBalancesBeforeSetVendorRemainingAmount(VendLedgEntry);
                VendorRemainingAmount := -VendLedgEntry."Remaining Amount";
                InsertGenJnlLine(VendorGenJnlLine, VendLedgEntry, CustLedgEntry, true);
            end;
            repeat
                if CustomerRemainingAmount <= 0 then begin
                    SetOnHold(CustLedgEntry);
                    CustLedgEntry.CalcFields("Remaining Amount");
                    OnNetBalancesBeforeSetCustomerRemainingAmount(CustLedgEntry);
                    CustomerRemainingAmount := CustLedgEntry."Remaining Amount";
                end;

                MinNetAmount := MinDec(VendorRemainingAmount, CustomerRemainingAmount);
                if MinNetAmount > TempNetAmount then
                    MinNetAmount := TempNetAmount;

                TempNetAmount -= MinNetAmount;
                VendorRemainingAmount -= MinNetAmount;
                CustomerRemainingAmount -= MinNetAmount;

                if CustomerRemainingAmount <= 0 then begin
                    InsertGenJnlLine(CustomerGenJnlLine, VendLedgEntry, CustLedgEntry, false);
                    CustLedgEntry.Next();
                end;
                if VendorRemainingAmount <= 0 then
                    VendLedgEntry.Next();
            until (VendorRemainingAmount <= 0) or (TempNetAmount <= 0);
        until (TempNetAmount <= 0);

        if (TempNetAmount <= 0) and (NetAmount <= 0) then begin
            if VendorRemainingAmount > 0 then begin
                VendorGenJnlLine.Validate(Amount, VendorGenJnlLine.Amount - VendorRemainingAmount);
                VendorGenJnlLine.Modify();
            end;
            if CustomerRemainingAmount > 0 then begin
                InsertGenJnlLine(CustomerGenJnlLine, VendLedgEntry, CustLedgEntry, false);
                CustomerGenJnlLine.Validate(Amount, CustomerGenJnlLine.Amount + CustomerRemainingAmount);
                CustomerGenJnlLine.Modify();
            end;
        end;
    end;

    procedure SetGenJnlLine(NewGenJnlLine: Record "Gen. Journal Line");
    begin
        VendorGenJnlLine := NewGenJnlLine;
        CustomerGenJnlLine := NewGenJnlLine;
    end;

    local procedure CalcPartNetAmount(var VendLedgEntry: Record "Vendor Ledger Entry"; var CustLedgEntry: Record "Cust. Ledger Entry"; var VendNetAmount: Decimal; var CustNetAmount: Decimal; DocType: Enum "Gen. Journal Document Type");
    var
        IsHandled: Boolean;
    begin
        GlobalVendLedgEntry.SetFilter("Document Type", '<>%1', DocType);
        GlobalCustLedgEntry.SetFilter("Document Type", '<>%1', DocType);

        IsHandled := false;
        OnCalcPartNetAmountAfterSetDocumentType(VendLedgEntry, CustLedgEntry, VendNetAmount, CustNetAmount, DocType, IsHandled);
        if IsHandled then
            exit;

        VendLedgEntry.SetRange("Document Type", DocType);
        VendLedgEntry.SetAutoCalcFields("Remaining Amount");
        if VendLedgEntry.FindSet() then
            repeat
                VendNetAmount -= VendLedgEntry."Remaining Amount";
            until VendLedgEntry.Next() = 0;

        CustLedgEntry.SetRange("Document Type", DocType);
        CustLedgEntry.SetAutoCalcFields("Remaining Amount");
        if CustLedgEntry.FindSet() then
            repeat
                CustNetAmount += CustLedgEntry."Remaining Amount";
            until CustLedgEntry.Next() = 0;
    end;

    local procedure FillGenJnlLineFromVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        GenJnlLine."External Document No." := VendLedgEntry."External Document No.";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine.Validate("Account No.", VendLedgEntry."Vendor No.");
        GenJnlLine.Description :=
            STRSUBSTNO(
                NetBalancesParameters.Description,
                NetBalancesParameters."Document No.",
                NetBalancesParameters."Posting Date");
        GenJnlLine.Validate("Bal. Account No.");
        GenJnlLine.Validate("Currency Code", VendLedgEntry."Currency Code");
        VendLedgEntry.CalcFields("Remaining Amount");
        OnFillGenJnlLineFromVendLedgEntryBeforeValidateAmount(VendLedgEntry);
        GenJnlLine.Validate(Amount, -VendLedgEntry."Remaining Amount");
        GenJnlLine."Posting Group" := VendLedgEntry."Vendor Posting Group";
        GenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
        GenJnlLine."Applies-to Doc. No." := VendLedgEntry."Document No.";
        GenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID";

        OnAfterFillGenJnlLineFromVendLedgEntry(GenJnlLine, VendLedgEntry);
    end;

    local procedure FillGenJnlLineFromCustledgEntry(var GenJnlLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        GenJnlLine."External Document No." := CustLedgEntry."Document No.";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
        GenJnlLine.Validate("Account No.", CustLedgEntry."Customer No.");
        GenJnlLine.Description :=
            STRSUBSTNO(
                NetBalancesParameters.Description,
                NetBalancesParameters."Document No.",
                NetBalancesParameters."Posting Date");
        GenJnlLine.Validate("Bal. Account No.");
        GenJnlLine.Validate("Currency Code", CustLedgEntry."Currency Code");
        CustLedgEntry.CalcFields("Remaining Amount");
        OnFillGenJnlLineFromCustledgEntryBeforeValidateAmount(CustLedgEntry);
        GenJnlLine.Validate(Amount, -CustLedgEntry."Remaining Amount");
        GenJnlLine."Posting Group" := CustLedgEntry."Customer Posting Group";
        GenJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type";
        GenJnlLine."Applies-to Doc. No." := CustLedgEntry."Document No.";
        GenJnlLine."Dimension Set ID" := CustLedgEntry."Dimension Set ID";

        OnAfterFillGenJnlLineFromCustLedgEntry(GenJnlLine, CustLedgEntry);
    end;

    local procedure InitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        GenJnlLine.Init();
        LastLineNo := LastLineNo + 10000;
        GenJnlLine."Line No." := LastLineNo;
        GenJnlLine.Validate("Posting Date", NetBalancesParameters."Posting Date");
        GenJnlLine."Document Type" := "Gen. Journal Document Type"::" ";
        GenJnlLine."Posting No. Series" := GenJnlBatch."Posting No. Series";
        GenJnlLine."Document No." := NetBalancesParameters."Document No.";
        GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
        GenJnlLine."Gen. Bus. Posting Group" := '';
        GenJnlLine."Gen. Prod. Posting Group" := '';
        GenJnlLine."VAT Bus. Posting Group" := '';
        GenJnlLine."VAT Prod. Posting Group" := '';
        GenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
        GenJnlLine."Source Code" := GenJnlTemplate."Source Code";
        GenJnlLine."Reason Code" := GenJnlBatch."Reason Code";
        GenJnlLine."On Hold" := NetBalancesParameters."On Hold";

        OnAfterInitGenJnlLine(GenJnlLine, VendLedgEntry);
    end;

    local procedure SetOnHold(var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        CustEntryEdit: Codeunit "Cust. Entry-Edit";
    begin
        CustEntryEdit.SetOnHold(CustLedgEntry, NetBalancesParameters."On Hold");
    end;

    local procedure SetOnHold(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        VendEntryEdit: Codeunit "Vend. Entry-Edit";
    begin
        VendEntryEdit.SetOnHold(VendorLedgerEntry, NetBalancesParameters."On Hold");
    end;

    local procedure MinDec(Decimal1: Decimal; Decimal2: Decimal): Decimal
    begin
        if Decimal1 < Decimal2 then
            exit(Decimal1);
        exit(Decimal2);
    end;

    local procedure SumCustomerRemainingAmount(CustomerNo: Code[20]; CurrencyCode: Code[10]) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        GlobalCustLedgEntry.Reset();
        GlobalCustLedgEntry.SetLoadFields("Remaining Amount", "On Hold");
        GlobalCustLedgEntry.SetRange("Customer No.", CustomerNo);
        GlobalCustLedgEntry.SetRange(Open, true);
        GlobalCustLedgEntry.SetRange("Currency Code", CurrencyCode);
        GlobalCustLedgEntry.SetRange("Posting Date", 0D, NetBalancesParameters."Posting Date");
        GlobalCustLedgEntry.SetFilter("On Hold", '%1|%2', '', NetBalancesParameters."On Hold");

        IsHandled := false;
        OnSumCustomerRemainingAmountBeforeCalcResult(GlobalCustLedgEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GlobalCustLedgEntry.SetAutoCalcFields("Remaining Amount");
        if GlobalCustLedgEntry.FindSet() then
            repeat
                Result += GlobalCustLedgEntry."Remaining Amount";
            until GlobalCustLedgEntry.Next() = 0;
    end;

    local procedure SumVendorRemainingAmount(VendorNo: Code[20]; CurrencyCode: Code[10]) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        GlobalVendLedgEntry.Reset();
        GlobalVendLedgEntry.SetLoadFields("Remaining Amount", "On Hold");
        GlobalVendLedgEntry.SetRange("Vendor No.", VendorNo);
        GlobalVendLedgEntry.SetRange(Open, true);
        GlobalVendLedgEntry.SetRange("Currency Code", CurrencyCode);
        GlobalVendLedgEntry.SetRange("Posting Date", 0D, NetBalancesParameters."Posting Date");
        GlobalVendLedgEntry.SetFilter("On Hold", '%1|%2', '', NetBalancesParameters."On Hold");

        IsHandled := false;
        OnSumVendorRemainingAmountBeforeCalcResult(GlobalVendLedgEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GlobalVendLedgEntry.SetAutoCalcFields("Remaining Amount");
        if GlobalVendLedgEntry.FindSet() then
            repeat
                Result += GlobalVendLedgEntry."Remaining Amount";
            until GlobalVendLedgEntry.Next() = 0;
    end;

    local procedure FindVendLedgEntries(VendorNo: code[20]; var VendLedgEntry: Record "Vendor Ledger Entry"): Boolean
    begin
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Vendor No.", "Currency Code", "Posting Date");
        VendLedgEntry.SetRange("Vendor No.", VendorNo);
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetRange(Positive, false);
        VendLedgEntry.SetRange("Posting Date", 0D, NetBalancesParameters."Posting Date");
        VendLedgEntry.SetFilter("On Hold", '%1|%2', '', NetBalancesParameters."On Hold");
        exit(VendLedgEntry.FindSet());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillGenJnlLineFromCustLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillGenJnlLineFromVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPartNetAmountAfterSetDocumentType(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var VendNetAmount: Decimal; var CustNetAmount: Decimal; DocType: Enum "Gen. Journal Document Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillGenJnlLineFromCustledgEntryBeforeValidateAmount(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillGenJnlLineFromVendLedgEntryBeforeValidateAmount(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNetBalancesBeforeSetCustomerRemainingAmount(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNetBalancesBeforeSetVendorRemainingAmount(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumCustomerRemainingAmountBeforeCalcResult(var CustLedgerEntry: Record "Cust. Ledger Entry"; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumVendorRemainingAmountBeforeCalcResult(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;
}
