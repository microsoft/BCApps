// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.RoleCenters;

page 9048 "Acc. Payable Activities"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Activities';
    PageType = CardPart;
    SourceTable = "Account Payable Cue";

    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            cuegroup(WideCues)
            {
                CueGroupLayout = Wide;
                ShowCaption = false;

                field("Purchase This Month"; Rec."Purchase This Month")
                {
                }
                field("A/P Accounts Balance"; this.ActivitiesMgt.CalcAPAccountsBalance())
                {
                    Caption = 'A/P Accounts Balance';
                    ToolTip = 'The total balance of all A/P accounts.';

                    trigger OnDrillDown()
                    begin
                        this.ActivitiesMgt.DrillDownCalcAPAccountsBalances();
                    end;
                }
                field("Payments On Hold Amount"; this.PaymentsOnHoldAmountCue)
                {
                    Caption = 'Payments On Hold';
                    ToolTip = 'The total amount of payments that are currently on hold.';

                    trigger OnDrillDown()
                    var
                        VendorLedgerEntry: Record "Vendor Ledger Entry";
                    begin
                        VendorLedgerEntry.SetRange("Document Type", Enum::"Gen. Journal Document Type"::Payment);
                        VendorLedgerEntry.SetFilter("On Hold", '<>%1', '');
                        VendorLedgerEntry.SetFilter("Due Date", Format(Rec."Overdue Date Filter"));
                        Page.Run(Page::"Vendor Ledger Entries", VendorLedgerEntry);
                    end;
                }
                field("Overdue Purchase Documents"; Rec."Overdue Purchase Documents")
                {
                }
            }
            cuegroup(OngoingPurchase)
            {
                Caption = 'Ongoing Purchase';

                field("Purchase Quotes"; Rec."Purchase Quotes")
                {
                    DrillDownPageID = "Purchase Quotes";
                }
                field("Purchase Orders"; Rec."Purchase Orders")
                {
                    DrillDownPageID = "Purchase Order List";
                }
                field("Ongoing Purchase Invoices"; Rec."Ongoing Purchase Invoices")
                {
                    DrillDownPageID = "Purchase Invoices";
                }
                field("Purch. Invoices Due Next Week"; Rec."Purch. Invoices Due Next Week")
                {
                }
                field("Posted Purch. Inv. This Month"; Rec."Posted Purch. Inv. This Month")
                {
                    DrillDownPageId = "Posted Purchase Invoices";
                }
                field("Posted Purch. Cr. Memo TM"; Rec."Posted Purch. Cr. Memo TM")
                {
                    DrillDownPageId = "Posted Purchase Credit Memos";
                }
            }
            cuegroup(Payments)
            {
                Caption = 'Payments';

                field("Purchase Documents Due Today"; Rec."Purchase Documents Due Today")
                {
                }
                field("Purch. Documents Due Next Week"; Rec."Purch. Documents Due Next Week")
                {
                }
                field("Purchase Discounts Next Week"; Rec."Purchase Discounts Next Week")
                {
                }
                field("Unprocessed Payments"; Rec."Unprocessed Payments")
                {
                    trigger OnDrillDown()
                    begin
                        Codeunit.Run(Codeunit::"Pmt. Rec. Journals Launcher");
                    end;
                }
                field("Payments On Hold Count"; this.PaymentsOnHoldCountCue)
                {
                    Caption = 'Payments On Hold';
                    ToolTip = 'The number of payments that are currently on hold.';

                    trigger OnDrillDown()
                    var
                        VendorLedgerEntry: Record "Vendor Ledger Entry";
                    begin
                        VendorLedgerEntry.SetRange("Document Type", Enum::"Gen. Journal Document Type"::Payment);
                        VendorLedgerEntry.SetFilter("On Hold", '<>%1', '');
                        VendorLedgerEntry.SetFilter("Due Date", Format(Rec."Overdue Date Filter"));
                        Page.Run(Page::"Vendor Ledger Entries", VendorLedgerEntry);
                    end;
                }
                field("Outstanding Vendor Invoices"; Rec."Outstanding Vendor Invoices")
                {
                }
            }
            cuegroup(DocumentApprovals)
            {
                Caption = 'Document Approvals';

                field("POs Pending Approval"; Rec."POs Pending Approval")
                {
                    DrillDownPageId = "Purchase Order List";
                }
                field("Approved Purchase Orders"; Rec."Approved Purchase Orders")
                {
                    DrillDownPageId = "Purchase Order List";
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert(false);
        end;

        Rec.SetFilter("Overdue Date Filter", '<=%1', Rec.GetDefaultWorkDate());
        Rec.SetRange("Posting Date Filter", CalcDate('<-CM>', Rec.GetDefaultWorkDate()), Rec.GetDefaultWorkDate());
        Rec.SetFilter("Due Next Week Filter", '%1..%2', CalcDate('<1D>', Rec.GetDefaultWorkDate()), CalcDate('<1W>', Rec.GetDefaultWorkDate()));

        this.GetPaymentsOnHoldAmountCue();
        this.GetPaymentsOnHoldCountCue();
    end;

    var
        ActivitiesMgt: Codeunit "Activities Mgt.";
        PaymentsOnHoldAmountCue: Decimal;
        PaymentsOnHoldCountCue: Integer;

    local procedure GetPaymentsOnHoldAmountCue()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        this.PaymentsOnHoldAmountCue := 0;
        VendorLedgerEntry.SetAutoCalcFields("Remaining Amount");
        VendorLedgerEntry.SetRange("Document Type", Enum::"Gen. Journal Document Type"::Payment);
        VendorLedgerEntry.SetFilter("On Hold", '<>%1', '');
        VendorLedgerEntry.SetFilter("Due Date", Format(Rec."Overdue Date Filter"));
        if VendorLedgerEntry.FindSet() then
            repeat
                this.PaymentsOnHoldAmountCue += VendorLedgerEntry."Remaining Amount";
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure GetPaymentsOnHoldCountCue()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document Type", Enum::"Gen. Journal Document Type"::Payment);
        VendorLedgerEntry.SetFilter("On Hold", '<>%1', '');
        VendorLedgerEntry.SetFilter("Due Date", Format(Rec."Overdue Date Filter"));
        PaymentsOnHoldCountCue := VendorLedgerEntry.Count();
    end;
}