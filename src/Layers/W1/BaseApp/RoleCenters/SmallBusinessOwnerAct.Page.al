// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Navigate;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;

page 9073 "Small Business Owner Act."
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "SB Owner Cue";

    layout
    {
        area(content)
        {
            cuegroup(Sales)
            {
                Caption = 'Sales';
                field("Released Sales Quotes"; Rec."Released Sales Quotes")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Sales Quotes";
                    ToolTip = 'Specifies the number of released sales quotes that are displayed in the Small Business Owner Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Open Sales Orders"; Rec."Open Sales Orders")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Sales Order List";
                    ToolTip = 'Specifies the number of open sales orders that are displayed in the Small Business Owner Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Released Sales Orders"; Rec."Released Sales Orders")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Sales Order List";
                    ToolTip = 'Specifies the number of released sales orders that are displayed in the Small Business Owner Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("New Customer")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Customer';
                        RunObject = Page "Customer Card";
                        RunPageMode = Create;
                        ToolTip = 'Register a new customer.';
                    }
                    action("New Sales Order")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Sales Order';
                        RunObject = Page "Sales Order";
                        RunPageMode = Create;
                        ToolTip = 'Sell goods or services to a customer.';
                    }
                }
            }
            cuegroup(Purchase)
            {
                Caption = 'Purchase';
                field("Released Purchase Orders"; Rec."Released Purchase Orders")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies the number of released purchase orders that are displayed in the Small Business Owner Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("New Purchase Order")
                    {
                        ApplicationArea = Suite;
                        Caption = 'New Purchase Order';
                        RunObject = Page "Purchase Order";
                        RunPageMode = Create;
                        ToolTip = 'Purchase goods or services from a vendor.';
                    }
                }
            }
            cuegroup(Receivables)
            {
                Caption = 'Receivables';
                field("Overdue Sales Documents"; Rec."Overdue Sales Documents")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Customer Ledger Entries";
                    ToolTip = 'Specifies the number of overdue sales invoices that are displayed in the Small Business Owner Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field(SOShippedNotInvoiced; SOShippedNotInvoicedCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SOs Shipped Not Invoiced';
                    DrillDownPageID = "Sales Order List";
                    ToolTip = 'Specifies the number of shipped and not invoiced sales orders that are displayed in the Small Business Owner Cue on the Role Center. The documents are filtered by today''s date.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowSalesOrdersShippedNotInvoiced();
                    end;
                }
                field("Customers - Blocked"; Rec."Customers - Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Customer List";
                    ToolTip = 'Specifies the number of blocked customers that are displayed in the Small Business Owner Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("Edit Cash Receipt Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Edit Cash Receipt Journal';
                        RunObject = Page "Cash Receipt Journal";
                        ToolTip = 'Register received payments in a cash receipt journal that may already contain journal lines.';
                    }
                    action(Navigate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Find entries...';
                        RunObject = Page Navigate;
                        ShortCutKey = 'Ctrl+Alt+Q';
                        ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                    }
                }
            }
            cuegroup(Payables)
            {
                Caption = 'Payables';
                field("Purchase Documents Due Today"; Rec."Purchase Documents Due Today")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Vendor Ledger Entries";
                    ToolTip = 'Specifies the number of purchase invoices that are displayed in the Order Cue in the Business Manager Role Center. The documents are filtered by today''s date.';
                }
                field("Vendors - Payment on Hold"; Rec."Vendors - Payment on Hold")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Vendor List";
                    ToolTip = 'Specifies the number of vendors with payments on hold that are displayed in the Small Business Owner Cue on the Role Center. The documents are filtered by today''s date.';
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
                    action("Edit Bank Acc. Reconciliation")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Edit Bank Acc. Reconciliation';
                        RunObject = Page "Bank Acc. Reconciliation List";
                        ToolTip = 'Reconcile bank transactions with bank account ledger entries to ensure that your bank account in Dynamics 365 reflects your actual liquidity.';
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
        Rec.SetFilter("Overdue Date Filter", '<%1', WorkDate());
        Rec.SetRange("User ID Filter", UserId());

        CalculateCueFieldValues();
    end;

    var
        SOShippedNotInvoicedCount: Integer;

    local procedure CalculateCueFieldValues()
    begin
        SOShippedNotInvoicedCount := Rec.CountSalesOrdersShippedNotInvoiced();
    end;
}

