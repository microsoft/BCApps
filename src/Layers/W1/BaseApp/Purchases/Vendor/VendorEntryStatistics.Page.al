// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Foundation.Period;
using Microsoft.Purchases.Payables;

page 303 "Vendor Entry Statistics"
{
    Caption = 'Vendor Entry Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = Vendor;

    layout
    {
        area(content)
        {
            group("Last Documents")
            {
                Caption = 'Last Documents';
                fixed(Control1903895301)
                {
                    ShowCaption = false;
                    group(Date)
                    {
                        Caption = 'Date';
#pragma warning disable AA0100
                        field("VendLedgEntry[1].""Posting Date"""; VendLedgEntry[1]."Posting Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Payment';
                            ToolTip = 'Specifies the amount that relates to payments.';
                        }
#pragma warning disable AA0100
                        field("VendLedgEntry[2].""Posting Date"""; VendLedgEntry[2]."Posting Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Invoice';
                            ToolTip = 'Specifies the amount that relates to invoices.';
                        }
#pragma warning disable AA0100
                        field("VendLedgEntry[3].""Posting Date"""; VendLedgEntry[3]."Posting Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Credit Memo';
                            ToolTip = 'Specifies the amount that relates to credit memos.';
                        }
#pragma warning disable AA0100
                        field("VendLedgEntry[5].""Posting Date"""; VendLedgEntry[5]."Posting Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Suite;
                            Caption = 'Reminder';
                            ToolTip = 'Specifies the amount that relates to reminders.';
                        }
#pragma warning disable AA0100
                        field("VendLedgEntry[4].""Posting Date"""; VendLedgEntry[4]."Posting Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Suite;
                            Caption = 'Finance Charge Memo';
                            ToolTip = 'Specifies the amount that relates to finance charge memos.';
                        }
#pragma warning disable AA0100
                        field("VendLedgEntry[6].""Posting Date"""; VendLedgEntry[6]."Posting Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Refund';
                            ToolTip = 'Specifies the amount that relates to refunds.';
                        }
                    }
                    group("Document No.")
                    {
                        Caption = 'Document No.';
#pragma warning disable AA0100
                        field("VendLedgEntry[1].""Document No."""; VendLedgEntry[1]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that the statistic is based on.';
                        }
#pragma warning disable AA0100
                        field("VendLedgEntry[2].""Document No."""; VendLedgEntry[2]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that the statistic is based on.';
                        }
#pragma warning disable AA0100
                        field("VendLedgEntry[3].""Document No."""; VendLedgEntry[3]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that the statistic is based on.';
                        }
#pragma warning disable AA0100
                        field("VendLedgEntry[5].""Document No."""; VendLedgEntry[5]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that the statistic is based on.';
                        }
#pragma warning disable AA0100
                        field("VendLedgEntry[4].""Document No."""; VendLedgEntry[4]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that the statistic is based on.';
                        }
#pragma warning disable AA0100
                        field("VendLedgEntry[6].""Document No."""; VendLedgEntry[6]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that the statistic is based on.';
                        }
                    }
                    group("Currency Code")
                    {
                        Caption = 'Currency Code';
#pragma warning disable AA0100
                        field("VendLedgEntry[1].""Currency Code"""; VendLedgEntry[1]."Currency Code")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Suite;
                            Caption = 'Currency Code';
                            ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                        }
#pragma warning disable AA0100
                        field("VendLedgEntry[2].""Currency Code"""; VendLedgEntry[2]."Currency Code")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Suite;
                            Caption = 'Currency Code';
                            ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                        }
#pragma warning disable AA0100
                        field("VendLedgEntry[3].""Currency Code"""; VendLedgEntry[3]."Currency Code")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Suite;
                            Caption = 'Currency Code';
                            ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                        }
#pragma warning disable AA0100
                        field("VendLedgEntry[5].""Currency Code"""; VendLedgEntry[5]."Currency Code")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Suite;
                            Caption = 'Currency Code';
                            ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                        }
#pragma warning disable AA0100
                        field("VendLedgEntry[4].""Currency Code"""; VendLedgEntry[4]."Currency Code")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Suite;
                            Caption = 'Currency Code';
                            ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                        }
#pragma warning disable AA0100
                        field("VendLedgEntry[6].""Currency Code"""; VendLedgEntry[6]."Currency Code")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Suite;
                            Caption = 'Currency Code';
                            ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                        }
                    }
                    group(Control1900724301)
                    {
                        Caption = 'Amount';
                        field("VendLedgEntry[1].Amount"; VendLedgEntry[1].Amount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = VendLedgEntry[1]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the vendor entry.';
                        }
                        field(Amount; -VendLedgEntry[2].Amount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = VendLedgEntry[2]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the vendor entry.';
                        }
                        field("VendLedgEntry[3].Amount"; VendLedgEntry[3].Amount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = VendLedgEntry[3]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the vendor entry.';
                        }
                        field("-VendLedgEntry[5].Amount"; -VendLedgEntry[5].Amount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = VendLedgEntry[5]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the vendor entry.';
                        }
                        field("-VendLedgEntry[4].Amount"; -VendLedgEntry[4].Amount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = VendLedgEntry[4]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the vendor entry.';
                        }
                        field("VendLedgEntry[6].Amount"; VendLedgEntry[6].Amount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = VendLedgEntry[6]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the vendor entry.';
                        }
                    }
                    group("Remaining Amount")
                    {
                        Caption = 'Remaining Amount';
#pragma warning disable AA0100
                        field("VendLedgEntry[1].""Remaining Amount"""; VendLedgEntry[1]."Remaining Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = VendLedgEntry[1]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Remaining Amount';
                            ToolTip = 'Specifies the net remaining amount of all the lines in the vendor entry.';
                        }
#pragma warning disable AA0100
                        field("-VendLedgEntry[2].""Remaining Amount"""; -VendLedgEntry[2]."Remaining Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = VendLedgEntry[2]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Remaining Amount';
                            ToolTip = 'Specifies the net remaining amount of all the lines in the vendor entry.';
                        }
#pragma warning disable AA0100
                        field("VendLedgEntry[3].""Remaining Amount"""; VendLedgEntry[3]."Remaining Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = VendLedgEntry[3]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Remaining Amount';
                            ToolTip = 'Specifies the net remaining amount of all the lines in the vendor entry.';
                        }
#pragma warning disable AA0100
                        field("-VendLedgEntry[5].""Remaining Amount"""; -VendLedgEntry[5]."Remaining Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = VendLedgEntry[5]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Remaining Amount';
                            ToolTip = 'Specifies the net remaining amount of all the lines in the vendor entry.';
                        }
#pragma warning disable AA0100
                        field("-VendLedgEntry[4].""Remaining Amount"""; -VendLedgEntry[4]."Remaining Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = VendLedgEntry[4]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Remaining Amount';
                            ToolTip = 'Specifies the net remaining amount of all the lines in the vendor entry.';
                        }
#pragma warning disable AA0100
                        field("VendLedgEntry[6].""Remaining Amount"""; VendLedgEntry[6]."Remaining Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = VendLedgEntry[6]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Remaining Amount';
                            ToolTip = 'Specifies the net remaining amount of all the lines in the vendor entry.';
                        }
                    }
                }
            }
            group("No. of Documents")
            {
                Caption = 'No. of Documents';
                fixed(Control1904230801)
                {
                    ShowCaption = false;
                    group("This Period")
                    {
                        Caption = 'This Period';
                        field("VendDateName[1]"; VendDateName[1])
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field("NoOfDoc[1][1]"; NoOfDoc[1] [1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Payments';
                            ToolTip = 'Specifies the amount that relates to payments.';
                        }
                        field("NoOfDoc[1][2]"; NoOfDoc[1] [2])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Invoices';
                            ToolTip = 'Specifies the amount that relates to invoices.';
                        }
                        field("NoOfDoc[1][3]"; NoOfDoc[1] [3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Credit Memos';
                            ToolTip = 'Specifies the amount that relates to credit memos.';
                        }
                        field("NoOfDoc[1][5]"; NoOfDoc[1] [5])
                        {
                            ApplicationArea = Suite;
                            Caption = 'Reminder';
                            ToolTip = 'Specifies the amount that relates to reminders.';
                        }
                        field("NoOfDoc[1][4]"; NoOfDoc[1] [4])
                        {
                            ApplicationArea = Suite;
                            Caption = 'Finance Charge Memos';
                            ToolTip = 'Specifies the amount that relates to finance charge memos.';
                        }
                        field("NoOfDoc[1][6]"; NoOfDoc[1] [6])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Refund';
                            ToolTip = 'Specifies the amount that relates to refunds.';
                        }
                        field("-TotalPaymentDiscLCY[1]"; -TotalPaymentDiscLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Disc. Received (LCY)';
                            ToolTip = 'Specifies the total amount that the vendor has granted as payment discount.';
                        }
                        field("-PaymentDiscMissedLCY[1]"; -PaymentDiscMissedLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Disc. Missed (LCY)';
                            ToolTip = 'Specifies the total amount that the vendor granted as payment discount but you missed.';
                        }
                    }
                    group("This Year")
                    {
                        Caption = 'This Year';
                        field(Text000; Text000)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field("NoOfDoc[2][1]"; NoOfDoc[2] [1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Payments';
                            ToolTip = 'Specifies the amount that relates to payments.';
                        }
                        field("NoOfDoc[2][2]"; NoOfDoc[2] [2])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Invoices';
                            ToolTip = 'Specifies the amount that relates to invoices.';
                        }
                        field("NoOfDoc[2][3]"; NoOfDoc[2] [3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Credit Memos';
                            ToolTip = 'Specifies the amount that relates to credit memos.';
                        }
                        field("NoOfDoc[2][5]"; NoOfDoc[2] [5])
                        {
                            ApplicationArea = Suite;
                            Caption = 'Reminder';
                            ToolTip = 'Specifies the amount that relates to reminders.';
                        }
                        field("NoOfDoc[2][4]"; NoOfDoc[2] [4])
                        {
                            ApplicationArea = Suite;
                            Caption = 'Finance Charge Memos';
                            ToolTip = 'Specifies the amount that relates to finance charge memos.';
                        }
                        field("NoOfDoc[2][6]"; NoOfDoc[2] [6])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Refund';
                            ToolTip = 'Specifies the amount that relates to refunds.';
                        }
                        field("-TotalPaymentDiscLCY[2]"; -TotalPaymentDiscLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Disc. Received (LCY)';
                            ToolTip = 'Specifies the total amount that the vendor has granted as payment discount.';
                        }
                        field("-PaymentDiscMissedLCY[2]"; -PaymentDiscMissedLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Disc. Missed (LCY)';
                            ToolTip = 'Specifies the total amount that the vendor granted as payment discount but you missed.';
                        }
                    }
                    group("Last Year")
                    {
                        Caption = 'Last Year';
                        field(Control87; Text000)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field("NoOfDoc[3][1]"; NoOfDoc[3] [1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Payments';
                            ToolTip = 'Specifies the amount that relates to payments.';
                        }
                        field("NoOfDoc[3][2]"; NoOfDoc[3] [2])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Invoices';
                            ToolTip = 'Specifies the amount that relates to invoices.';
                        }
                        field("NoOfDoc[3][3]"; NoOfDoc[3] [3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Credit Memos';
                            ToolTip = 'Specifies the amount that relates to credit memos.';
                        }
                        field("NoOfDoc[3][5]"; NoOfDoc[3] [5])
                        {
                            ApplicationArea = Suite;
                            Caption = 'Reminder';
                            ToolTip = 'Specifies the amount that relates to reminders.';
                        }
                        field("NoOfDoc[3][4]"; NoOfDoc[3] [4])
                        {
                            ApplicationArea = Suite;
                            Caption = 'Finance Charge Memos';
                            ToolTip = 'Specifies the amount that relates to finance charge memos.';
                        }
                        field("NoOfDoc[3][6]"; NoOfDoc[3] [6])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Refund';
                            ToolTip = 'Specifies the amount that relates to refunds.';
                        }
                        field("-TotalPaymentDiscLCY[3]"; -TotalPaymentDiscLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Disc. Received (LCY)';
                            ToolTip = 'Specifies the total amount that the vendor has granted as payment discount.';
                        }
                        field("-PaymentDiscMissedLCY[3]"; -PaymentDiscMissedLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Disc. Missed (LCY)';
                            ToolTip = 'Specifies the total amount that the vendor granted as payment discount but you missed.';
                        }
                    }
                    group("Remaining Amt. (LCY)")
                    {
                        Caption = 'Remaining Amt. (LCY)';
                        field(Control88; Text000)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field("TotalRemainAmountLCY[1]"; TotalRemainAmountLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Remaining Amt. (LCY)';
                            ToolTip = 'Specifies the amount that remains to be paid.';
                        }
                        field("-TotalRemainAmountLCY[2]"; -TotalRemainAmountLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Remaining Amt. (LCY)';
                            ToolTip = 'Specifies the amount that remains to be paid.';
                        }
                        field("TotalRemainAmountLCY[3]"; TotalRemainAmountLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Remaining Amt. (LCY)';
                            ToolTip = 'Specifies the amount that remains to be paid.';
                        }
                        field("-TotalRemainAmountLCY[5]"; -TotalRemainAmountLCY[5])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Remaining Amt. (LCY)';
                            ToolTip = 'Specifies the amount that remains to be paid.';
                        }
                        field("-TotalRemainAmountLCY[4]"; -TotalRemainAmountLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Remaining Amt. (LCY)';
                            ToolTip = 'Specifies the amount that remains to be paid.';
                        }
                        field("TotalRemainAmountLCY[6]"; TotalRemainAmountLCY[6])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Remaining Amt. (LCY)';
                            ToolTip = 'Specifies the amount that remains to be paid.';
                        }
                        field(Control89; Text000)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field(Control90; Text000)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ClearAll();

        for j := 1 to 6 do begin
            VendLedgEntry[j].SetCurrentKey("Document Type", "Vendor No.", "Posting Date");
            VendLedgEntry[j].SetRange("Document Type", j); // Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund
            VendLedgEntry[j].SetRange("Vendor No.", Rec."No.");
            OnAfterGetRecordOnAfterVendLedgEntrySetFiltersCalcAmount(VendLedgEntry[j]);
            if VendLedgEntry[j].FindLast() then
                VendLedgEntry[j].CalcFields(Amount, "Remaining Amount");
        end;

        VendLedgEntry2.SetCurrentKey("Vendor No.", Open);
        VendLedgEntry2.SetRange("Vendor No.", Rec."No.");
        VendLedgEntry2.SetRange(Open, true);
        OnAfterGetRecordOnAfterVendLedgEntrySetFiltersCalcRemainingAmountLCY(VendLedgEntry2);
        if VendLedgEntry2.Find('+') then
            repeat
                j := VendLedgEntry2."Document Type".AsInteger();
                if j > 0 then begin
                    VendLedgEntry2.CalcFields("Remaining Amt. (LCY)");
                    TotalRemainAmountLCY[j] := TotalRemainAmountLCY[j] + VendLedgEntry2."Remaining Amt. (LCY)";
                end;
            until VendLedgEntry2.Next(-1) = 0;
        VendLedgEntry2.Reset();

        DateFilterCalc.CreateAccountingPeriodFilter(VendDateFilter[1], VendDateName[1], WorkDate(), 0);
        DateFilterCalc.CreateFiscalYearFilter(VendDateFilter[2], VendDateName[2], WorkDate(), 0);
        DateFilterCalc.CreateFiscalYearFilter(VendDateFilter[3], VendDateName[3], WorkDate(), -1);

        for i := 1 to 3 do begin // Period,This Year,Last Year
            VendLedgEntry2.SetCurrentKey("Vendor No.", "Posting Date");
            VendLedgEntry2.SetRange("Vendor No.", Rec."No.");
            VendLedgEntry2.SetFilter("Posting Date", VendDateFilter[i]);
            OnAfterGetRecordOnAfterVendLedgEntrySetFiltersCalcPaymentDiscMissedLCY(VendLedgEntry2);
            if VendLedgEntry2.Find('+') then
                repeat
                    j := VendLedgEntry2."Document Type".AsInteger();
                    if j > 0 then
                        NoOfDoc[i] [j] := NoOfDoc[i] [j] + 1;

                    VendLedgEntry2.CalcFields(Amount);
                    TotalPaymentDiscLCY[i] := TotalPaymentDiscLCY[i] + VendLedgEntry2."Pmt. Disc. Rcd.(LCY)";
                    if (VendLedgEntry2."Document Type" = VendLedgEntry2."Document Type"::Invoice) and
                       (not VendLedgEntry2.Open) and
                       (VendLedgEntry2.Amount <> 0)
                    then begin
                        VendLedgEntry2.CalcFields("Amount (LCY)");
                        PaymentDiscMissedLCY[i] :=
                          PaymentDiscMissedLCY[i] +
                          (VendLedgEntry2."Original Pmt. Disc. Possible" * (VendLedgEntry2."Amount (LCY)" / VendLedgEntry2.Amount)) -
                          VendLedgEntry2."Pmt. Disc. Rcd.(LCY)";
                    end;
                until VendLedgEntry2.Next(-1) = 0;
        end;
    end;

    var
        VendLedgEntry: array[6] of Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        DateFilterCalc: Codeunit "DateFilter-Calc";
        VendDateFilter: array[3] of Text[30];
        VendDateName: array[3] of Text[30];
        TotalRemainAmountLCY: array[6] of Decimal;
        NoOfDoc: array[3, 6] of Integer;
        TotalPaymentDiscLCY: array[3] of Decimal;
        PaymentDiscMissedLCY: array[3] of Decimal;
        i: Integer;
        j: Integer;
#pragma warning disable AA0074
        Text000: Label 'Placeholder';
#pragma warning restore AA0074

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterVendLedgEntrySetFiltersCalcAmount(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterVendLedgEntrySetFiltersCalcRemainingAmountLCY(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterVendLedgEntrySetFiltersCalcPaymentDiscMissedLCY(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;
}

