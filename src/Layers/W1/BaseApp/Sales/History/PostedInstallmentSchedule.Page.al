// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Sales.Receivables;
using System.Environment.Configuration;

page 8842 "Posted Installment Schedule"
{
    Caption = 'Posted Installment Schedule';
    PageType = List;
    SourceTable = "Sales Installment Plan Line";
    SourceTableView = sorting("Plan ID", "Installment No.");
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;

    layout
    {
        area(Content)
        {
            group(Invoice)
            {
                Caption = 'Posted Invoice';
                field(InvoiceNo; InvoiceNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoice No.';
                    ToolTip = 'Specifies the posted sales invoice that owns this schedule.';
                }
                field(CurrencyCode; CurrencyCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Currency Code';
                    ToolTip = 'Specifies the document currency. A blank value represents local currency.';
                }
            }
            repeater(Installments)
            {
                field("Installment No."; Rec."Installment No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the installment sequence in the posted invoice.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original installment due date.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the original posted installment amount in document currency.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original posted installment amount in local currency.';
                }
                field(RemainingAmount; RemainingAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    Caption = 'Remaining Amount';
                    ToolTip = 'Specifies the current unpaid amount from the linked customer ledger entry.';
                }
                field(RemainingAmountLCY; RemainingAmountLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = '';
                    AutoFormatType = 1;
                    Caption = 'Remaining Amount (LCY)';
                    ToolTip = 'Specifies the current unpaid local currency amount, including exchange rate adjustments.';
                }
                field(Open; TempCustLedgerEntry.Open)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open';
                    ToolTip = 'Specifies whether the linked installment receivable is open.';
                }
                field("Pmt. Discount Date"; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original installment payment discount date.';
                }
                field("Discount %"; Rec."Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posted installment payment discount percentage.';
                }
                field("Original Pmt. Disc. Possible"; Rec."Original Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original posted installment payment discount eligibility.';
                }
                field("Cust. Ledger Entry No."; Rec."Cust. Ledger Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the exact customer ledger entry for this installment.';

                    trigger OnDrillDown()
                    begin
                        ShowCustomerEntry();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(CustomerEntry)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer Ledger Entry';
                Image = CustomerLedger;
                ToolTip = 'Open the customer ledger entry for the selected installment.';

                trigger OnAction()
                begin
                    ShowCustomerEntry();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Plan: Record "Sales Installment Plan";
    begin
        FeatureKeyManagement.CheckPaymentInstallmentsEnabled();
        Rec.FilterGroup(2);
        Plan.Get(Rec.GetRangeMin("Plan ID"));
        Plan.TestField(Status, Plan.Status::Posted);
        InvoiceNo := Plan."Posted Invoice No.";
        CurrencyCode := Plan."Currency Code";
        PlanID := Plan.ID;
        Rec.SetRange("Plan ID", Plan.ID);
        Rec.FilterGroup(0);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        LoadLedgerEntries();
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    begin
        TempCustLedgerEntry.Get(Rec."Cust. Ledger Entry No.");
        TempCustLedgerEntry.TestField("Installment Plan ID", Rec."Plan ID");
        TempCustLedgerEntry.TestField("Installment No.", Rec."Installment No.");
        RemainingAmount := RemainingAmounts.Get(Rec."Cust. Ledger Entry No.");
        RemainingAmountLCY := RemainingAmountsLCY.Get(Rec."Cust. Ledger Entry No.");
    end;

    var
        TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        FeatureKeyManagement: Codeunit "Feature Key Management";
        InvoiceNo: Code[20];
        CurrencyCode: Code[10];
        PlanID: Guid;
        RemainingAmount: Decimal;
        RemainingAmountLCY: Decimal;
        RemainingAmounts: Dictionary of [BigInteger, Decimal];
        RemainingAmountsLCY: Dictionary of [BigInteger, Decimal];

    local procedure LoadLedgerEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        TempCustLedgerEntry.Reset();
        TempCustLedgerEntry.DeleteAll();
        Clear(RemainingAmounts);
        Clear(RemainingAmountsLCY);
        CustLedgerEntry.SetCurrentKey("Installment Plan ID", "Installment No.");
        CustLedgerEntry.SetRange("Installment Plan ID", PlanID);
        CustLedgerEntry.SetAutoCalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        if CustLedgerEntry.FindSet() then
            repeat
                TempCustLedgerEntry := CustLedgerEntry;
                TempCustLedgerEntry.Insert();
                // FlowField values are not persisted in temporary records.
                RemainingAmounts.Add(CustLedgerEntry."Entry No.", CustLedgerEntry."Remaining Amount");
                RemainingAmountsLCY.Add(CustLedgerEntry."Entry No.", CustLedgerEntry."Remaining Amt. (LCY)");
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure ShowCustomerEntry()
    var
        Entry: Record "Cust. Ledger Entry";
    begin
        Entry.SetRange("Entry No.", Rec."Cust. Ledger Entry No.");
        Page.Run(Page::"Customer Ledger Entries", Entry);
    end;
}
