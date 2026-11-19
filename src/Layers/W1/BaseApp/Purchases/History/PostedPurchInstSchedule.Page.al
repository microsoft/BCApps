// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Purchases.Payables;

page 8844 "Posted Purch. Inst. Schedule"
{
    Caption = 'Posted Purchase Installment Schedule';
    PageType = List;
    SourceTable = "Purchase Installment Plan Line";
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
                    ToolTip = 'Specifies the posted purchase invoice that owns this schedule.';
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
                field(RemainingAmount; VendorLedgerEntry."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    Caption = 'Remaining Amount';
                    ToolTip = 'Specifies the current unpaid amount from the linked vendor ledger entry.';
                }
                field(RemainingAmountLCY; VendorLedgerEntry."Remaining Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remaining Amount (LCY)';
                    ToolTip = 'Specifies the current unpaid local currency amount, including exchange rate adjustments.';
                }
                field(Open; VendorLedgerEntry.Open)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open';
                    ToolTip = 'Specifies whether the linked installment payable is open.';
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
                field("Vendor Ledger Entry No."; Rec."Vendor Ledger Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the exact vendor ledger entry for this installment.';

                    trigger OnDrillDown()
                    begin
                        ShowVendorEntry();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(VendorEntry)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor Ledger Entry';
                Image = VendorLedger;
                ToolTip = 'Open the vendor ledger entry for the selected installment.';

                trigger OnAction()
                begin
                    ShowVendorEntry();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Plan: Record "Purchase Installment Plan";
    begin
        Rec.FilterGroup(2);
        Plan.Get(Rec.GetRangeMin("Plan ID"));
        Plan.TestField(Status, Plan.Status::Posted);
        InvoiceNo := Plan."Posted Invoice No.";
        CurrencyCode := Plan."Currency Code";
        Rec.SetRange("Plan ID", Plan.ID);
        Rec.FilterGroup(0);
    end;

    trigger OnAfterGetRecord()
    begin
        VendorLedgerEntry.Get(Rec."Vendor Ledger Entry No.");
        VendorLedgerEntry.TestField("Installment Plan ID", Rec."Plan ID");
        VendorLedgerEntry.TestField("Installment No.", Rec."Installment No.");
        VendorLedgerEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
    end;

    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvoiceNo: Code[20];
        CurrencyCode: Code[10];

    local procedure ShowVendorEntry()
    var
        Entry: Record "Vendor Ledger Entry";
    begin
        Entry.SetRange("Entry No.", Rec."Vendor Ledger Entry No.");
        Page.Run(Page::"Vendor Ledger Entries", Entry);
    end;
}
