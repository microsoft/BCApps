// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 2000019 "Suggest Vendor Payments EB"
{
    Caption = 'Suggest Vendor Payments EB';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Vend; Vendor)
        {
            DataItemTableView = sorting("No.") where("Suggest Payments" = const(true));
            RequestFilterFields = "No.", "Payment Method Code", "Currency Filter", "Country/Region Code";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");
                AmountPerVendor := 0;
                SuggestPayments();
            end;

            trigger OnPostDataItem()
            begin
                // process priority 0
                if UsePriority then begin
                    Reset();
                    CopyFilters(Vend2);
                    SetCurrentKey(Priority);
                    SetRange(Priority, 0);
                    if FindSet() then
                        repeat
                            Window.Update(1, "No.");
                            AmountPerVendor := 0;
                            SuggestPayments();
                        until Next() = 0
                end;
                if OpenPayments then
                    Message(Text005,
                      PaymJnlLine4."Journal Template Name",
                      PaymJnlLine4."Journal Batch Name")
            end;

            trigger OnPreDataItem()
            begin
                if DueDate = 0D then
                    Error(Text000);
                if IncPmtDiscount and (PmtDiscDueDate < Today) then
                    if not Confirm(StrSubstNo(Text001, Today), false) then
                        Error(Text003);

                OpenPayments := false;

                Vend2.CopyFilters(Vend);

                PaymJnlLine.LockTable();
                PaymJnlLine.SetRange("Journal Template Name", PaymJnlBatch."Journal Template Name");
                PaymJnlLine.SetRange("Journal Batch Name", PaymJnlBatch.Name);
                if PaymJnlLine.FindLast() then;

                if MaximumAmount > 0 then begin
                    SetCurrentKey(Priority);
                    SetRange(Priority, 1, 9999);
                    UsePriority := true;
                end;
                Window.Open(Text004);
            end;
        }
        dataitem(Counter; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                PaymJnlLine2.Reset();
                PaymJnlLine2.SetRange("Journal Template Name", PaymJnlTemplate.Name);
                PaymJnlLine2.SetRange("Journal Batch Name", PaymJnlBatch.Name);
                PaymJnlLine2.SetRange("Account No.", '');
                PaymJnlLine2.DeleteAll();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DueDate; DueDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Last Due Date';
                        ToolTip = 'Specifies the last due date that can appear on the vendor ledger entries to be included in the batch job.';
                    }
                    field(IncCreditMemos; IncCreditMemos)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Take Credit Memos';
                        ToolTip = 'Specifies if you want the batch job to include outstanding credit memos for vendors. The credit memos will then be subtracted from the amount due. When selecting credit memos, the due date is not considered.';
                    }
                    field(IncPmtDiscount; IncPmtDiscount)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Take Payment Discounts';
                        ToolTip = 'Specifies if you want the batch job to include vendor ledger entries for which you can receive a payment discount.';
                    }
                    field(PmtDiscDueDate; PmtDiscDueDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Discount Date';
                        ToolTip = 'Specifies the date that will be used to calculate the payment discount.';
                    }
                    field(MaximumAmount; MaximumAmount)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Available Amount';
                        ToolTip = 'Specifies a maximum amount (in LCY) that is available for payments. The batch job will then create a payment suggestion on the basis of this amount and the Use Vendor Priority check box. It will only include vendor entries that can be paid fully.';
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that will appear as the posting date on the lines that the batch job inserts in the payment journal.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if DueDate = 0D then
                DueDate := WorkDate();
            if PmtDiscDueDate = 0D then
                PmtDiscDueDate := WorkDate();
            if PostingDate = 0D then
                PostingDate := WorkDate();
            IncCreditMemos := true;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        ClearAll();
    end;

    trigger OnPreReport()
    begin
        PaymJnlTemplate.Get(PaymJnlLine."Journal Template Name");
        PaymJnlBatch.Get(PaymJnlLine."Journal Template Name", PaymJnlLine."Journal Batch Name");
    end;

    var
        Text000: Label 'Please enter the Last Due Date.';
        Text001: Label 'The Payment Discount Date is earlier then %1. Do you want to continue?';
        Text003: Label 'The batch job was interrupted.';
        Text004: Label 'Processing Vendors               #1########';
        Text005: Label 'Some payments were not suggested because there are still open payments \in journal template name %1 journal batch name %2.', Comment = 'Parameter 1 - journal template name (code), 2 - journal batch name (code)';
        Vend2: Record Vendor;
        PaymJnlTemplate: Record "Payment Journal Template";
        PaymJnlBatch: Record "Paym. Journal Batch";
        PaymJnlLine: Record "Payment Journal Line";
        PaymJnlLine2: Record "Payment Journal Line";
        PaymJnlLine3: Record "Payment Journal Line";
        PaymJnlLine4: Record "Payment Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        Window: Dialog;
        IncCreditMemos: Boolean;
        IncPmtDiscount: Boolean;
        PostingDate: Date;
        DueDate: Date;
        PmtDiscDueDate: Date;
        AmountPerVendor: Decimal;
        MaximumAmount: Decimal;
        UsePriority: Boolean;
        OpenPayments: Boolean;

    [Scope('OnPrem')]
    procedure SuggestPayments()
    begin
        OnBeforeSuggestPayments(Vend, PaymJnlLine, VendLedgEntry);

        Vend.CheckBlockedVendOnJnls(Vend, VendLedgEntry."Document Type"::Payment, false);
        // select vendor ledger entries
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
        VendLedgEntry.SetRange("Vendor No.", Vend."No.");
        VendLedgEntry.SetRange(Open, true);
        if Vend.GetFilter("Currency Filter") <> '' then
            VendLedgEntry.SetFilter("Currency Code", Vend.GetFilter("Currency Filter"));
        VendLedgEntry.SetFilter("Global Dimension 1 Code", Vend.GetFilter("Global Dimension 1 Filter"));
        VendLedgEntry.SetFilter("Global Dimension 2 Code", Vend.GetFilter("Global Dimension 2 Filter"));
        OnSuggestPaymentsOnAfterApplyVendLedgEntryFilters(VendLedgEntry);
        // first take credit memo's into account
        if IncCreditMemos then begin
            // no filtering on "due date" here
            VendLedgEntry.SetRange(Positive, true);
            VendLedgEntry.SetRange("On Hold", '');
            VendLedgEntry.SetRange("Applies-to ID", '');
            if VendLedgEntry.FindSet() then
                repeat
                    SetPaymJnlLine();
                until VendLedgEntry.Next() = 0;
        end;
        // select open and due entries
        VendLedgEntry.SetRange(Positive, false);
        VendLedgEntry.SetRange("Due Date", 0D, DueDate);
        VendLedgEntry.SetRange("On Hold", '');
        VendLedgEntry.SetRange("Applies-to ID", '');
        if VendLedgEntry.FindSet() then
            repeat
                SetPaymJnlLine();
            until VendLedgEntry.Next() = 0;
        // select open with payment discount
        if IncPmtDiscount then begin
            VendLedgEntry.SetRange(Positive, false);
            VendLedgEntry.SetRange("Due Date", CalcDate('<+1D>', DueDate), 99991231D);
            VendLedgEntry.SetRange("Pmt. Discount Date", PmtDiscDueDate, DueDate);
            VendLedgEntry.SetFilter("Remaining Pmt. Disc. Possible", '<0');
            VendLedgEntry.SetRange("On Hold", '');
            VendLedgEntry.SetRange("Applies-to ID", '');
            if VendLedgEntry.FindSet() then
                repeat
                    SetPaymJnlLine();
                until VendLedgEntry.Next() = 0;
        end;
        // cleanup if nothing to pay for this vendor (e.g. Credit memo's > Invoices)
        if AmountPerVendor <= 0 then begin
            PaymJnlLine3.Reset();
            PaymJnlLine3.SetCurrentKey("Account Type", "Account No.");
            PaymJnlLine3.SetRange("Journal Template Name", PaymJnlTemplate.Name);
            PaymJnlLine3.SetRange("Journal Batch Name", PaymJnlBatch.Name);
            PaymJnlLine3.SetRange("Account Type", PaymJnlLine3."Account Type"::Vendor);
            PaymJnlLine3.SetRange("Account No.", Vend."No.");
            PaymJnlLine3.SetRange(Status, PaymJnlLine3.Status::Created);
            PaymJnlLine3.DeleteAll(true);
            // reset maximum amount
            MaximumAmount := MaximumAmount + AmountPerVendor;
            OpenPayments := false;
        end;
    end;

    procedure SetPaymJnlLine()
    var
        DimMgt: Codeunit DimensionManagement;
        DimSetIDArr: array[10] of Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetPaymJnlLine(VendLedgEntry, IsHandled);
        if IsHandled then
            exit;
        // if the invoice already is attached to an unposted Payment Line, we skip it
        PaymJnlLine2.Reset();
        PaymJnlLine2.SetCurrentKey("Account Type", "Account No.");
        PaymJnlLine2.SetRange("Account Type", PaymJnlLine2."Account Type"::Vendor);
        PaymJnlLine2.SetRange("Account No.", VendLedgEntry."Vendor No.");
        PaymJnlLine2.SetRange("Applies-to Doc. Type", VendLedgEntry."Document Type");
        PaymJnlLine2.SetRange("Applies-to Doc. No.", VendLedgEntry."Document No.");
        PaymJnlLine2.SetFilter(Status, '<>%1', PaymJnlLine2.Status::Posted);
        if not PaymJnlLine2.FindFirst() then begin
            PaymJnlLine.Init();
            PaymJnlLine."Journal Template Name" := PaymJnlTemplate.Name;
            PaymJnlLine."Journal Batch Name" := PaymJnlBatch.Name;
            PaymJnlLine."Line No." := PaymJnlLine."Line No." + 10000;
            // bank account: we could add our preferred bank account to a vendor
            PaymJnlLine.Validate("Bank Account", PaymJnlTemplate."Bank Account");
            PaymJnlLine."Posting Date" := PostingDate;
            PaymJnlLine.Validate("Account No.", VendLedgEntry."Vendor No.");
            PaymJnlLine.Validate("Pmt. Discount Date", PmtDiscDueDate);
            PaymJnlLine.Processing := true;
            PaymJnlLine."Account Type" := PaymJnlLine."Account Type"::Vendor;
            PaymJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
            PaymJnlLine."Payment Method Code" := Vend."Payment Method Code";
            PaymJnlLine.Validate("Applies-to Doc. No.", VendLedgEntry."Document No.");
            PaymJnlLine."Source Code" := PaymJnlTemplate."Source Code";
            PaymJnlLine."Reason Code" := PaymJnlBatch."Reason Code";
            // adjust maximum amount
            if UsePriority then
                if MaximumAmount >= PaymJnlLine."Amount (LCY)" then
                    MaximumAmount := MaximumAmount - PaymJnlLine."Amount (LCY)"
                else
                    exit;
            // adjust amount per vendor
            AmountPerVendor := AmountPerVendor + PaymJnlLine."Amount (LCY)";
            if PaymJnlLine."Amount (LCY)" <> 0 then begin
                PaymJnlLine.CreateDim(
                  PaymJnlLine.TypeToTableID2000001(PaymJnlLine."Account Type"), PaymJnlLine."Account No.",
                  DATABASE::"Bank Account", PaymJnlLine."Bank Account",
                  DATABASE::"Salesperson/Purchaser", PaymJnlLine."Salespers./Purch. Code");
                if PaymJnlLine."Dimension Set ID" <> VendLedgEntry."Dimension Set ID" then begin
                    DimSetIDArr[1] := PaymJnlLine."Dimension Set ID";
                    DimSetIDArr[2] := VendLedgEntry."Dimension Set ID";
                    PaymJnlLine."Dimension Set ID" :=
                        DimMgt.GetCombinedDimensionSetID(DimSetIDArr, PaymJnlLine."Shortcut Dimension 1 Code", PaymJnlLine."Shortcut Dimension 2 Code");
                end;
                OnSetPaymJnlLineOnBeforePaymJnlLineInsert(PaymJnlLine, VendLedgEntry);
                PaymJnlLine.Insert();
            end;
        end else begin
            if OpenPayments = false then
                PaymJnlLine4 := PaymJnlLine2;
            OpenPayments := true;

            AmountPerVendor := AmountPerVendor + PaymJnlLine2."Amount (LCY)";
        end;
    end;

    [Scope('OnPrem')]
    procedure SetJournal(PaymentJnlLine: Record "Payment Journal Line")
    begin
        PaymJnlLine := PaymentJnlLine;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPaymJnlLine(VendLedgEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSuggestPayments(var Vendor: Record Vendor; var PaymentJournalLine: Record "Payment Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetPaymJnlLineOnBeforePaymJnlLineInsert(var PaymJnlLine: Record "Payment Journal Line"; VendorLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSuggestPaymentsOnAfterApplyVendLedgEntryFilters(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;
}

