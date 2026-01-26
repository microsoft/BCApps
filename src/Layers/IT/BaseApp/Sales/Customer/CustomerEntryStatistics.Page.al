// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Foundation.Period;
using Microsoft.Sales.Receivables;

page 302 "Customer Entry Statistics"
{
    Caption = 'Customer Entry Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = Customer;

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
                        field("CustLedgEntry[1].""Posting Date"""; CustLedgEntry[1]."Posting Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Payment';
                            ToolTip = 'Specifies the amount that relates to payments.';
                        }
#pragma warning disable AA0100
                        field("CustLedgEntry[2].""Posting Date"""; CustLedgEntry[2]."Posting Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Invoice';
                            ToolTip = 'Specifies the amount that relates to invoices.';
                        }
#pragma warning disable AA0100
                        field("CustLedgEntry[3].""Posting Date"""; CustLedgEntry[3]."Posting Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Credit Memo';
                            ToolTip = 'Specifies the amount that relates to credit memos.';
                        }
#pragma warning disable AA0100
                        field("CustLedgEntry[5].""Posting Date"""; CustLedgEntry[5]."Posting Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Suite;
                            Caption = 'Reminder';
                            ToolTip = 'Specifies the amount that relates to reminders.';
                        }
#pragma warning disable AA0100
                        field("CustLedgEntry[4].""Posting Date"""; CustLedgEntry[4]."Posting Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Suite;
                            Caption = 'Finance Charge Memo';
                            ToolTip = 'Specifies the amount that relates to finance charge memos.';
                        }
#pragma warning disable AA0100
                        field("CustLedgEntry[6].""Posting Date"""; CustLedgEntry[6]."Posting Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Refund';
                            ToolTip = 'Specifies the amount that relates to refunds.';
                        }
                        field("CustLedgEntry[10].""Posting Date"""; CustLedgEntry[10]."Posting Date")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Dishonored';
                            ToolTip = 'Specifies if the customer is marked as dishonored.';
                        }
                    }
                    group("Document No.")
                    {
                        Caption = 'Document No.';
#pragma warning disable AA0100
                        field("CustLedgEntry[1].""Document No."""; CustLedgEntry[1]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that the statistic is based on.';
                        }
#pragma warning disable AA0100
                        field("CustLedgEntry[2].""Document No."""; CustLedgEntry[2]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that the statistic is based on.';
                        }
#pragma warning disable AA0100
                        field("CustLedgEntry[3].""Document No."""; CustLedgEntry[3]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that the statistic is based on.';
                        }
#pragma warning disable AA0100
                        field("CustLedgEntry[5].""Document No."""; CustLedgEntry[5]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that the statistic is based on.';
                        }
#pragma warning disable AA0100
                        field("CustLedgEntry[4].""Document No."""; CustLedgEntry[4]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that the statistic is based on.';
                        }
#pragma warning disable AA0100
                        field("CustLedgEntry[6].""Document No."""; CustLedgEntry[6]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that the statistic is based on.';
                        }
                        field("CustLedgEntry[10].""Document No."""; CustLedgEntry[10]."Document No.")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the source document for the entry.';
                        }
                    }
                    group("Currency Code")
                    {
                        Caption = 'Currency Code';
#pragma warning disable AA0100
                        field("CustLedgEntry[1].""Currency Code"""; CustLedgEntry[1]."Currency Code")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Suite;
                            Caption = 'Currency Code';
                            ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                        }
#pragma warning disable AA0100
                        field("CustLedgEntry[2].""Currency Code"""; CustLedgEntry[2]."Currency Code")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Suite;
                            Caption = 'Currency Code';
                            ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                        }
#pragma warning disable AA0100
                        field("CustLedgEntry[3].""Currency Code"""; CustLedgEntry[3]."Currency Code")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Suite;
                            Caption = 'Currency Code';
                            ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                        }
#pragma warning disable AA0100
                        field("CustLedgEntry[5].""Currency Code"""; CustLedgEntry[5]."Currency Code")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Suite;
                            Caption = 'Currency Code';
                            ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                        }
#pragma warning disable AA0100
                        field("CustLedgEntry[4].""Currency Code"""; CustLedgEntry[4]."Currency Code")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Suite;
                            Caption = 'Currency Code';
                            ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                        }
#pragma warning disable AA0100
                        field("CustLedgEntry[6].""Currency Code"""; CustLedgEntry[6]."Currency Code")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Suite;
                            Caption = 'Currency Code';
                            ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                        }
                        field("CustLedgEntry[10].""Currency Code"""; CustLedgEntry[10]."Currency Code")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Currency Code';
                            ToolTip = 'Specifies the currency for the amount.';
                        }
                    }
                    group(Amount)
                    {
                        Caption = 'Amount';
                        field("-CustLedgEntry[1].Amount"; -CustLedgEntry[1].Amount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = CustLedgEntry[1]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the customer entry.';
                        }
                        field("CustLedgEntry[2].Amount"; CustLedgEntry[2].Amount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = CustLedgEntry[2]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the customer entry.';
                        }
                        field("-CustLedgEntry[3].Amount"; -CustLedgEntry[3].Amount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = CustLedgEntry[3]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the customer entry.';
                        }
                        field("CustLedgEntry[5].Amount"; CustLedgEntry[5].Amount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = CustLedgEntry[5]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the customer entry.';
                        }
                        field("CustLedgEntry[4].Amount"; CustLedgEntry[4].Amount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = CustLedgEntry[4]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the customer entry.';
                        }
                        field("CustLedgEntry[6].Amount"; CustLedgEntry[6].Amount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = CustLedgEntry[6]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the customer entry.';
                        }
                        field("CustLedgEntry[10].Amount"; CustLedgEntry[10].Amount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = CustLedgEntry[10]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the amount of the entry.';
                        }
                    }
                    group("Remaining Amount")
                    {
                        Caption = 'Remaining Amount';
#pragma warning disable AA0100
                        field("-CustLedgEntry[1].""Remaining Amount"""; -CustLedgEntry[1]."Remaining Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = CustLedgEntry[1]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Remaining Amount';
                            ToolTip = 'Specifies the net remaining amount of all the lines in the customer entry.';
                        }
                        field(RemainingAmount; CustLedgEntry[2]."Remaining Amount")
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = CustLedgEntry[2]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Remaining Amount';
                            ToolTip = 'Specifies the net remaining amount of all the lines in the customer entry.';
                        }
#pragma warning disable AA0100
                        field("-CustLedgEntry[3].""Remaining Amount"""; -CustLedgEntry[3]."Remaining Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = CustLedgEntry[3]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Remaining Amount';
                            ToolTip = 'Specifies the net remaining amount of all the lines in the customer entry.';
                        }
#pragma warning disable AA0100
                        field("CustLedgEntry[5].""Remaining Amount"""; CustLedgEntry[5]."Remaining Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = CustLedgEntry[5]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Remaining Amount';
                            ToolTip = 'Specifies the net remaining amount of all the lines in the customer entry.';
                        }
#pragma warning disable AA0100
                        field("CustLedgEntry[4].""Remaining Amount"""; CustLedgEntry[4]."Remaining Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = CustLedgEntry[4]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Remaining Amount';
                            ToolTip = 'Specifies the net remaining amount of all the lines in the customer entry.';
                        }
#pragma warning disable AA0100
                        field("CustLedgEntry[6].""Remaining Amount"""; CustLedgEntry[6]."Remaining Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = CustLedgEntry[6]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Remaining Amount';
                            ToolTip = 'Specifies the net remaining amount of all the lines in the customer entry.';
                        }
                        field("CustLedgEntry[10].""Remaining Amount"""; CustLedgEntry[10]."Remaining Amount")
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = CustLedgEntry[10]."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Remaining Amount';
                            ToolTip = 'Specifies the outstanding amount that the customer owes.';
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
                        field("CustDateName[1]"; CustDateName[1])
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
                        field(AvgCollectionPeriodDays_ThisPeriod; AvgDaysToPay[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Avg. Collection Period (Days)';
                            DecimalPlaces = 0 : 0;
                            ToolTip = 'Specifies the time it usually takes to collect payment from the customer. The value is determined by subtracting the posting dates from the corresponding payment dates and dividing the total by the number of invoices.';
                        }
                        field("HighestBalanceLCY[1]"; HighestBalanceLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Largest Balance (LCY)';
                            ToolTip = 'Specifies the largest balance that the customer has had.';
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
                        field(AvgCollectionPeriodDays_ThisYear; AvgDaysToPay[2])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Avg. Collection Period (Days)';
                            DecimalPlaces = 0 : 0;
                            ToolTip = 'Specifies the time it usually takes to collect payment from the customer. The value is determined by subtracting the posting dates from the corresponding payment dates and dividing the total by the number of invoices.';
                        }
                        field("HighestBalanceLCY[2]"; HighestBalanceLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Largest Balance';
                            ToolTip = 'Specifies the largest balance that the customer has had.';
                        }
                    }
                    group("Last Year")
                    {
                        Caption = 'Last Year';
                        field(Placeholder2; Text000)
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
                        field(AvgCollectionPeriodDays_LastYear; AvgDaysToPay[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Avg. Collection Period (Days)';
                            DecimalPlaces = 0 : 0;
                            ToolTip = 'Specifies the time it usually takes to collect payment from the customer. The value is determined by subtracting the posting dates from the corresponding payment dates and dividing the total by the number of invoices.';
                        }
                        field("HighestBalanceLCY[3]"; HighestBalanceLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Largest Balance';
                            ToolTip = 'Specifies the largest balance that the customer has had.';
                        }
                    }
                    group("Remaining Amt. (LCY)")
                    {
                        Caption = 'Remaining Amt. (LCY)';
                        field(Placeholder3; Text000)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field("-TotalRemainAmountLCY[1]"; -TotalRemainAmountLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Remaining Amt. (LCY)';
                            ToolTip = 'Specifies the amount that remains to be paid.';
                        }
                        field("TotalRemainAmountLCY[2]"; TotalRemainAmountLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Remaining Amt. (LCY)';
                            ToolTip = 'Specifies the amount that remains to be paid.';
                        }
                        field("-TotalRemainAmountLCY[3]"; -TotalRemainAmountLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Remaining Amt. (LCY)';
                            ToolTip = 'Specifies the amount that remains to be paid.';
                        }
                        field("TotalRemainAmountLCY[5]"; TotalRemainAmountLCY[5])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Remaining Amt. (LCY)';
                            ToolTip = 'Specifies the amount that remains to be paid.';
                        }
                        field("TotalRemainAmountLCY[4]"; TotalRemainAmountLCY[4])
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
                        field(Placeholder4; Text000)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field(Placeholder5; Text000)
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

        for j := 1 to 10 do begin
            CustLedgEntry[j].SetCurrentKey("Document Type", "Customer No.", "Posting Date");
            CustLedgEntry[j].SetRange("Document Type", j); // Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund
            CustLedgEntry[j].SetRange("Customer No.", Rec."No.");
            OnAfterGetRecordOnAfterCustLedgEntrySetFiltersCalcAmount(CustLedgEntry[j]);
            if CustLedgEntry[j].FindLast() then
                CustLedgEntry[j].CalcFields(Amount, "Remaining Amount");
        end;

        CustLedgEntry2.SetCurrentKey("Customer No.", Open);
        CustLedgEntry2.SetRange("Customer No.", Rec."No.");
        CustLedgEntry2.SetRange(Open, true);
        OnAfterGetRecordOnAfterCustLedgEntrySetFiltersCalcRemainingAmountLCY(CustLedgEntry2);
        if CustLedgEntry2.Find('+') then
            repeat
                j := CustLedgEntry2."Document Type".AsInteger();
                if j > 0 then begin
                    CustLedgEntry2.CalcFields("Remaining Amt. (LCY)");
                    TotalRemainAmountLCY[j] := TotalRemainAmountLCY[j] + CustLedgEntry2."Remaining Amt. (LCY)";
                end;
            until CustLedgEntry2.Next(-1) = 0;

        DateFilterCalc.CreateAccountingPeriodFilter(CustDateFilter[1], CustDateName[1], WorkDate(), 0);
        DateFilterCalc.CreateFiscalYearFilter(CustDateFilter[2], CustDateName[2], WorkDate(), 0);
        DateFilterCalc.CreateFiscalYearFilter(CustDateFilter[3], CustDateName[3], WorkDate(), -1);

        for i := 1 to 3 do begin
            CustLedgEntry2.Reset();
            CustLedgEntry2.SetCurrentKey("Customer No.", "Posting Date");
            CustLedgEntry2.SetRange("Customer No.", Rec."No.");

            CustLedgEntry2.SetFilter("Posting Date", CustDateFilter[i]);
            CustLedgEntry2.SetRange("Posting Date", 0D, CustLedgEntry2.GetRangeMax("Posting Date"));
            DtldCustLedgEntry2.SetCurrentKey("Customer No.", "Posting Date");
            CustLedgEntry2.CopyFilter("Customer No.", DtldCustLedgEntry2."Customer No.");
            CustLedgEntry2.CopyFilter("Posting Date", DtldCustLedgEntry2."Posting Date");
            DtldCustLedgEntry2.CalcSums("Amount (LCY)");
            CustBalanceLCY := DtldCustLedgEntry2."Amount (LCY)";
            HighestBalanceLCY[i] := CustBalanceLCY;
            DaysToPay := 0;
            NoOfInv := 0;

            CustLedgEntry2.SetFilter("Posting Date", CustDateFilter[i]);
            OnAfterGetRecordOnAfterCustLedgEntrySetFiltersCalcDaysToPay(CustLedgEntry2);
            if CustLedgEntry2.Find('+') then
                repeat
                    j := CustLedgEntry2."Document Type".AsInteger();
                    if j > 0 then
                        NoOfDoc[i] [j] := NoOfDoc[i] [j] + 1;

                    CustLedgEntry2.CalcFields("Amount (LCY)");
                    CustBalanceLCY := CustBalanceLCY - CustLedgEntry2."Amount (LCY)";
                    if CustBalanceLCY > HighestBalanceLCY[i] then
                        HighestBalanceLCY[i] := CustBalanceLCY;

                    // Optimized Approximation
                    if (CustLedgEntry2."Document Type" = CustLedgEntry2."Document Type"::Invoice) and
                       not CustLedgEntry2.Open
                    then
                        if CustLedgEntry2."Closed at Date" > CustLedgEntry2."Posting Date" then
                            UpdateDaysToPay(CustLedgEntry2."Closed at Date" - CustLedgEntry2."Posting Date")
                        else
                            if CustLedgEntry2."Closed by Entry No." <> 0 then begin
                                if CustLedgEntry3.Get(CustLedgEntry2."Closed by Entry No.") then
                                    UpdateDaysToPay(CustLedgEntry3."Posting Date" - CustLedgEntry2."Posting Date");
                            end else begin
                                CustLedgEntry3.SetCurrentKey("Closed by Entry No.");
                                CustLedgEntry3.SetRange("Closed by Entry No.", CustLedgEntry2."Entry No.");
                                if CustLedgEntry3.FindLast() then
                                    if CustLedgEntry3."Bank Receipt" then
                                        UpdateDaysToPay(CustLedgEntry3."Closed at Date" - CustLedgEntry2."Posting Date")
                                    else
                                        UpdateDaysToPay(CustLedgEntry3."Posting Date" - CustLedgEntry2."Posting Date");
                            end;
                until CustLedgEntry2.Next(-1) = 0;
            if NoOfInv <> 0 then
                AvgDaysToPay[i] := DaysToPay / NoOfInv;
        end;
    end;

    var
        CustLedgEntry: array[10] of Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        CustLedgEntry3: Record "Cust. Ledger Entry";
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        DateFilterCalc: Codeunit "DateFilter-Calc";
        CustDateFilter: array[3] of Text[30];
        CustDateName: array[3] of Text[30];
        TotalRemainAmountLCY: array[10] of Decimal;
        NoOfDoc: array[3, 10] of Integer;
        AvgDaysToPay: array[3] of Decimal;
        DaysToPay: Decimal;
        NoOfInv: Integer;
        HighestBalanceLCY: array[3] of Decimal;
        CustBalanceLCY: Decimal;
        i: Integer;
        j: Integer;
#pragma warning disable AA0074
        Text000: Label 'Placeholder';
#pragma warning restore AA0074

    local procedure UpdateDaysToPay(NoOfDays: Integer)
    begin
        DaysToPay := DaysToPay + NoOfDays;
        NoOfInv := NoOfInv + 1;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterCustLedgEntrySetFiltersCalcAmount(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterCustLedgEntrySetFiltersCalcRemainingAmountLCY(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterCustLedgEntrySetFiltersCalcDaysToPay(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;
}
