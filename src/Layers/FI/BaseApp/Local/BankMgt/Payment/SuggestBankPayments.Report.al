// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

report 32000003 "Suggest Bank Payments"
{
    Caption = 'Suggest Bank Payments';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.") where(Blocked = filter(= " "));
            RequestFilterFields = "No.", "Payment Method Code";

            trigger OnAfterGetRecord()
            begin
                if StopPayments then
                    CurrReport.Break();
                Window.Update(1, "No.");
                GetVendLedgEntries(true, false);
                GetVendLedgEntries(false, false);
                CheckAmounts(false);
            end;

            trigger OnPostDataItem()
            begin
                if UsePriority and not StopPayments then begin
                    Reset();
                    CopyFilters(Vend2);
                    SetCurrentKey(Priority);
                    SetRange(Priority, 0);
                    if FindSet() then
                        repeat
                            Window.Update(1, "No.");
                            GetVendLedgEntries(true, false);
                            GetVendLedgEntries(false, false);
                            CheckAmounts(false);
                        until (Next() = 0) or StopPayments;
                end;
                Window.Close();

                if UsePaymentDisc and not StopPayments then begin
                    Reset();
                    CopyFilters(Vend2);
                    if FindSet() then begin
                        Window.Open(Text1090005);
                        repeat
                            Window.Update(1, "No.");
                            PayableVendLedgEntry.SetRange("Vendor No.", "No.");
                            GetVendLedgEntries(true, true);
                            GetVendLedgEntries(false, true);
                            CheckAmounts(true);
                        until (Next() = 0) or StopPayments;
                        Window.Close();
                    end;
                end;

                RefPmtLines.LockTable();

                Window.Open(Text1090006);

                PayableVendLedgEntry.Reset();
                PayableVendLedgEntry.SetFilter(Priority, '>0');
                MakeRefPmtLines();
                PayableVendLedgEntry.Reset();
                PayableVendLedgEntry.SetRange(Priority, 0);
                MakeRefPmtLines();
                PayableVendLedgEntry.Reset();
                PayableVendLedgEntry.DeleteAll();

                Window.Close();
            end;

            trigger OnPreDataItem()
            begin
                if LastDueDateToPayReq = 0D then
                    Error(Text1090000);

                if UsePaymentDisc and (LastDueDateToPayReq < WorkDate()) then
                    if not
                       Confirm(
                         Text1090001 +
                         Text1090002, false,
                         WorkDate())
                    then
                        Error(Text1090003);

                Vend2.CopyFilters(Vendor);

                OriginalAmtAvailable := AmountAvailable;
                if AmountAvailable > 0 then begin
                    SetCurrentKey(Priority);
                    SetFilter(Priority, '>0');
                    UsePriority := true;
                end;
                Window.Open(Text1090004);
            end;
        }
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
                    field(LastPaymentDate; LastDueDateToPayReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Last Payment Date';
                        ToolTip = 'Specifies the latest payment date that can appear on the vendor ledger entries to be included in the batch job. Only entries that have a due date or a payment discount date before or on this date will be included.';
                    }
                    field("Find Payment Discounts"; UsePaymentDisc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Find Payment Discounts';
                        MultiLine = true;
                        ToolTip = 'Specifies whether the batch job includes vendor ledger entries for which you can receive a payment discount.';
                    }
                    field(UsePmtDiscTolerance; UsePmtDiscTolerance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Find Payment Discount Tolerance';
                        ToolTip = 'Specifies if the batch job includes vendor ledger entries for which you can receive a payment discount tolerance.';
                    }
                    field(UsePriority; UsePriority)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Vendor Priority';
                        ToolTip = 'Specifies if the Priority field on the vendor cards will determine in which order vendor entries are suggested for payment by the batch job. The batch job always prioritizes vendors for payment suggestions if you specify an available amount in the Available Amount (LCY) field.';

                        trigger OnValidate()
                        begin
                            if not UsePriority and (AmountAvailable <> 0) then
                                Error(Text1090008);
                        end;
                    }
                    field(AmountAvailable; AmountAvailable)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Available Amount (LCY)';
                        ToolTip = 'Specifies a maximum amount available in local currency for payments. ';

                        trigger OnValidate()
                        begin
                            AmountAvailableOnAfterValidate();
                        end;
                    }
                    field("Payment Account"; SelectedAccount)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Account';
                        TableRelation = "Bank Account"."No." where("Country/Region Code" = filter('' | 'FI'));
                        ToolTip = 'Specifies the bank account that will be used for payments in the batch job. All payments in the batch job must use the same currency code as the selected payment account.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        RefPmtLines: Record "Ref. Payment - Exported";
        Vend2: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        PayableVendLedgEntry: Record "Payable Vendor Ledger Entry" temporary;
        PurchRefLines: Record "Ref. Payment - Exported";
        Window: Dialog;
        UsePaymentDisc: Boolean;
        UsePmtDiscTolerance: Boolean;
        LastDueDateToPayReq: Date;
        AmountAvailable: Decimal;
        OriginalAmtAvailable: Decimal;
        UsePriority: Boolean;
        StopPayments: Boolean;
        SelectedAccount: Code[20];
        NextEntryNo: Integer;
        Text1090000: Label 'Please enter the last payment date';
        Text1090001: Label 'Payment date is earlier than %1.\\';
        Text1090002: Label 'Do you wish to continue?';
        Text1090003: Label 'Export job canceled';
        Text1090004: Label 'Processing vendors     #1##########';
        Text1090005: Label 'Processing vendors payment discounts #1##########';
        Text1090006: Label 'Inserting lines into Ref Payment table #1##########';
        Text1090008: Label 'Use vendor priority function has to be in use when the value of Amount available field is not 0.';

    [Scope('OnPrem')]
    procedure SetRefkPmtLine(NewRefPmtLine: Record "Ref. Payment - Exported")
    begin
        RefPmtLines := NewRefPmtLine;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(LastPmtDate: Date; FindPmtDisc: Boolean; NewAvailableAmount: Decimal)
    begin
        LastDueDateToPayReq := LastPmtDate;
        UsePaymentDisc := FindPmtDisc;
        AmountAvailable := NewAvailableAmount;
    end;

    [Scope('OnPrem')]
    procedure GetVendLedgEntries(Positive: Boolean; Future: Boolean)
    begin
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetFilter("Document Type", '%1|%2',
          VendLedgEntry."Document Type"::Invoice,
          VendLedgEntry."Document Type"::"Credit Memo");
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetRange(Positive, Positive);
        VendLedgEntry.SetRange("On Hold", '<>''');

        if Future then begin
            VendLedgEntry.SetRange("Due Date", LastDueDateToPayReq + 1, 99991231D);
            VendLedgEntry.SetRange("Pmt. Discount Date", WorkDate(), LastDueDateToPayReq);
            VendLedgEntry.SetFilter("Original Pmt. Disc. Possible", '<0');
        end else
            VendLedgEntry.SetRange("Due Date", 0D, LastDueDateToPayReq);
        VendLedgEntry.SetRange("On Hold", '');
        VendLedgEntry.SetFilter("Currency Code", Vendor.GetFilter("Currency Filter"));
        if VendLedgEntry.FindSet() then
            repeat
                SaveAmount();
            until VendLedgEntry.Next() = 0;
    end;

    local procedure SaveAmount()
    begin
        VendLedgEntry.CalcFields("Amount (LCY)");
        if UsePriority then
            PayableVendLedgEntry.Priority := Vendor.Priority
        else
            PayableVendLedgEntry.Priority := 0;
        PayableVendLedgEntry."Vendor No." := VendLedgEntry."Vendor No.";
        PayableVendLedgEntry."Entry No." := NextEntryNo;
        PayableVendLedgEntry."Vendor Ledg. Entry No." := VendLedgEntry."Entry No.";
        PayableVendLedgEntry.Amount := -VendLedgEntry.Amount;
        PayableVendLedgEntry."Amount (LCY)" := -VendLedgEntry."Amount (LCY)";
        PayableVendLedgEntry.Positive := (PayableVendLedgEntry.Amount > 0);
        PayableVendLedgEntry.Future := (VendLedgEntry."Due Date" > LastDueDateToPayReq);
        PayableVendLedgEntry."Currency Code" := VendLedgEntry."Currency Code";
        PayableVendLedgEntry.Insert();
        NextEntryNo := NextEntryNo + 1;
    end;

    [Scope('OnPrem')]
    procedure CheckAmounts(Future: Boolean)
    var
        CurrencyBalance: Decimal;
        PrevCurrency: Code[10];
    begin
        PayableVendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        PayableVendLedgEntry.SetRange(Future, Future);
        if PayableVendLedgEntry.FindSet() then begin
            PrevCurrency := PayableVendLedgEntry."Currency Code";
            repeat
                if PayableVendLedgEntry."Currency Code" <> PrevCurrency then begin
                    if CurrencyBalance < 0 then begin
                        PayableVendLedgEntry.SetRange("Currency Code", PrevCurrency);
                        PayableVendLedgEntry.DeleteAll();
                        PayableVendLedgEntry.SetRange("Currency Code");
                    end else
                        AmountAvailable := AmountAvailable - CurrencyBalance;
                    CurrencyBalance := 0;
                    PrevCurrency := PayableVendLedgEntry."Currency Code";
                end;
                if (OriginalAmtAvailable = 0) or
                   (AmountAvailable >= CurrencyBalance + PayableVendLedgEntry."Amount (LCY)")
                then
                    CurrencyBalance := CurrencyBalance + PayableVendLedgEntry."Amount (LCY)"
                else
                    PayableVendLedgEntry.Delete();
            until PayableVendLedgEntry.Next() = 0;
            if CurrencyBalance < 0 then begin
                PayableVendLedgEntry.SetRange("Currency Code", PrevCurrency);
                PayableVendLedgEntry.DeleteAll();
                PayableVendLedgEntry.SetRange("Currency Code");
            end else
                if OriginalAmtAvailable > 0 then
                    AmountAvailable := AmountAvailable - CurrencyBalance;
            if (OriginalAmtAvailable > 0) and (AmountAvailable <= 0) then
                StopPayments := true;
        end;
        PayableVendLedgEntry.Reset();
    end;

    local procedure MakeRefPmtLines()
    begin
        PurchRefLines.Reset();
        NextEntryNo := PurchRefLines.GetLastEntryNo() + 1;

        if PayableVendLedgEntry.FindSet() then
            repeat
                RefPmtLines."No." := NextEntryNo;
                RefPmtLines.SetUsePaymentDisc(UsePaymentDisc);
                RefPmtLines.SetUsePaymentDiscTolerance(UsePmtDiscTolerance);
                RefPmtLines."Payment Account" := SelectedAccount;
                RefPmtLines."Vendor No." := PayableVendLedgEntry."Vendor No.";
                RefPmtLines."Entry No." := PayableVendLedgEntry."Vendor Ledg. Entry No.";
                if not RefPmtLines.ExistsNotTransferred() then begin
                    RefPmtLines.Validate("Entry No.", PayableVendLedgEntry."Vendor Ledg. Entry No.");
                    if RefPmtLines."Entry No." <> 0 then begin
                        RefPmtLines.Insert();
                        NextEntryNo := NextEntryNo + 1;
                    end;
                end;
            until PayableVendLedgEntry.Next() = 0;
    end;

    local procedure AmountAvailableOnAfterValidate()
    begin
        if AmountAvailable <> 0 then
            UsePriority := true;
    end;
}

