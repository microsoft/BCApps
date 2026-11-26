// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Purchases.Payables;
using System.Environment.Configuration;

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
                field(RemainingAmount; RemainingAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    Caption = 'Remaining Amount';
                    ToolTip = 'Specifies the current unpaid amount from the linked vendor ledger entry.';
                }
                field(RemainingAmountLCY; RemainingAmountLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = '';
                    AutoFormatType = 1;
                    Caption = 'Remaining Amount (LCY)';
                    ToolTip = 'Specifies the current unpaid local currency amount, including exchange rate adjustments.';
                }
                field(Open; TempVendorLedgerEntry.Open)
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
        TempVendorLedgerEntry.Get(Rec."Vendor Ledger Entry No.");
        TempVendorLedgerEntry.TestField("Installment Plan ID", Rec."Plan ID");
        TempVendorLedgerEntry.TestField("Installment No.", Rec."Installment No.");
        RemainingAmount := RemainingAmounts.Get(Rec."Vendor Ledger Entry No.");
        RemainingAmountLCY := RemainingAmountsLCY.Get(Rec."Vendor Ledger Entry No.");
    end;

    var
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
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
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        TempVendorLedgerEntry.Reset();
        TempVendorLedgerEntry.DeleteAll();
        Clear(RemainingAmounts);
        Clear(RemainingAmountsLCY);
        VendorLedgerEntry.SetCurrentKey("Installment Plan ID", "Installment No.");
        VendorLedgerEntry.SetRange("Installment Plan ID", PlanID);
        VendorLedgerEntry.SetAutoCalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        if VendorLedgerEntry.FindSet() then
            repeat
                TempVendorLedgerEntry := VendorLedgerEntry;
                TempVendorLedgerEntry.Insert();
                // FlowField values are not persisted in temporary records.
                RemainingAmounts.Add(VendorLedgerEntry."Entry No.", VendorLedgerEntry."Remaining Amount");
                RemainingAmountsLCY.Add(VendorLedgerEntry."Entry No.", VendorLedgerEntry."Remaining Amt. (LCY)");
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure ShowVendorEntry()
    var
        Entry: Record "Vendor Ledger Entry";
    begin
        Entry.SetRange("Entry No.", Rec."Vendor Ledger Entry No.");
        Page.Run(Page::"Vendor Ledger Entries", Entry);
    end;
}
