// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

page 9032 "Acc. Payables Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Finance Cue";

    layout
    {
        area(content)
        {
            cuegroup(Payments)
            {
                Caption = 'Payments';
                field("Purchase Documents Due Today"; Rec."Purchase Documents Due Today")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Vendor Ledger Entries";
                    ToolTip = 'Specifies the number of purchase invoices that must be paid today.';
                }
                field("Vendors - Payment on Hold"; Rec."Vendors - Payment on Hold")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Vendor List";
                }
                field("Purchase Return Orders"; Rec."Purchase Return Orders")
                {
                    ApplicationArea = PurchReturnOrder;
                    DrillDownPageID = "Purchase Return Order List";
                }
                field("Outstanding Vendor Invoices"; Rec."Outstanding Vendor Invoices")
                {
                    ApplicationArea = Basic, Suite;
                }

                actions
                {
                    action("Edit Payment Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Edit Payment Journal';
                        RunObject = Page "Payment Journal";
                        ToolTip = 'Pay your vendors by filling the payment journal automatically according to payments due, and potentially export all payment to your bank for automatic processing.';
                    }
                    action("New Purchase Credit Memo")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Purchase Credit Memo';
                        RunObject = Page "Purchase Credit Memo";
                        RunPageMode = Create;
                        ToolTip = 'Specifies a new purchase credit memo so you can manage returned items to a vendor.';
                    }
                    action("Edit Purchase Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Edit Purchase Journal';
                        RunObject = Page "Purchase Journal";
                        ToolTip = 'Post purchase invoices in a purchase journal that may already contain journal lines.';
                    }
                }
            }
            cuegroup("Document Approvals")
            {
                Caption = 'Document Approvals';
                field("POs Pending Approval"; Rec."POs Pending Approval")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Purchase Order List";
                }
                field("Approved Purchase Orders"; Rec."Approved Purchase Orders")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Purchase Order List";
                }
            }
            cuegroup(Cartera)
            {
                Caption = 'Cartera';
                field("Payable Documents"; Rec."Payable Documents")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Payables Cartera Docs";
                    ToolTip = 'Specifies the payables document that is associated with the bill group.';
                }
                field("Posted Payable Documents"; Rec."Posted Payable Documents")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Posted Cartera Documents";
                    ToolTip = 'Specifies the payables documents that have been posted.';
                }

                actions
                {
                    action("New Payment Order")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Payment Order';
                        RunObject = Page "Payment Orders";
                        RunPageMode = Create;
                        ToolTip = 'Create a new order for payables documents for submission to the bank for electronic payment.';
                    }
                    action("Posted Payment Orders List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Payment Orders List';
                        RunObject = Page "Posted Payment Orders List";
                        ToolTip = 'View posted payment orders that represent payables to submit to the bank as a file for electronic payment.';
                    }
                    action("Posted Payment Orders Select.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Payment Orders Select.';
                        RunObject = Page "Posted Payment Orders Select.";
                        ToolTip = 'View or edit where ledger entries are posted when you post a payment order.';
                    }
                }
            }
            cuegroup(MissingSIIEntries)
            {
                Caption = 'Missing SII Entries';
                field("Missing SII Entries"; Rec."Missing SII Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Missing SII Entries';
                    DrillDownPageID = "Recreate Missing SII Entries";
                    ToolTip = 'Specifies that some posted documents were not transferred to SII.';

                    trigger OnDrillDown()
                    var
                        SIIRecreateMissingEntries: Codeunit "SII Recreate Missing Entries";
                    begin
                        SIIRecreateMissingEntries.ShowRecreateMissingEntriesPage();
                    end;
                }
                field("Days Since Last SII Check"; Rec."Days Since Last SII Check")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Recreate Missing SII Entries";
                    Image = Calendar;
                    ToolTip = 'Specifies the number of days since the last check for missing SII entries.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CalculateCueFieldValues();
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        Rec.SetFilter("Due Date Filter", '<=%1', WorkDate());
    end;

    local procedure CalculateCueFieldValues()
    var
        SIIRecreateMissingEntries: Codeunit "SII Recreate Missing Entries";
    begin
        if Rec.FieldActive("Missing SII Entries") then
            Rec."Missing SII Entries" := SIIRecreateMissingEntries.GetMissingEntriesCount();
        if Rec.FieldActive("Days Since Last SII Check") then
            Rec."Days Since Last SII Check" := SIIRecreateMissingEntries.GetDaysSinceLastCheck();
    end;
}

