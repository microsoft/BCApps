// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.RoleCenters;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;
using System.Automation;

page 36623 "Credit Manager Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    SourceTable = "Credit Manager Cue";

    layout
    {
        area(content)
        {
            cuegroup("My Approvals")
            {
                Caption = 'My Approvals';
                field("Approvals - Sales Orders"; Rec."Approvals - Sales Orders")
                {
                    Caption = 'Sales Orders';
                    DrillDownPageID = "Approval Entries";
                    ToolTip = 'Specifies the number of sales orders awaiting approval.';
                }
                field("Approvals - Sales Invoices"; Rec."Approvals - Sales Invoices")
                {
                    Caption = 'Sales Invoices';
                    DrillDownPageID = "Approval Entries";
                    ToolTip = 'Specifies the number of sales invoices awaiting approval.';
                }
            }
            cuegroup(Customers)
            {
                Caption = 'Customers';
                field("Customers - Overdue"; Rec."Customers - Overdue")
                {
                    Caption = 'Overdue';
                    DrillDownPageID = "Customer List - Collections";
                    ToolTip = 'Specifies the number of overdue customers.';
                }
                field("Customers - Blocked"; Rec."Customers - Blocked")
                {
                    Caption = 'Blocked';
                    DrillDownPageID = "Customer List - Collections";
                    ToolTip = 'Specifies the number of blocked customers.';
                }
                field("Overdue Sales Invoices"; Rec."Overdue Sales Invoices")
                {
                    DrillDownPageID = "Customer Ledger Entries";
                    ToolTip = 'Specifies the number of overdue sales invoices.';
                }
            }
            cuegroup("Sales Orders")
            {
                Caption = 'Sales Orders';
                field("Sales Orders On Hold"; Rec."Sales Orders On Hold")
                {
                    Caption = 'On Hold';
                    DrillDownPageID = "Customer Order Header Status";
                    ToolTip = 'Specifies the number of sales orders that are on hold.';
                }
                field("SOs Pending Approval"; Rec."SOs Pending Approval")
                {
                    Caption = 'Pending Approval';
                    DrillDownPageID = "Customer Order Header Status";
                    ToolTip = 'Specifies the number of sales orders that are pending approval.';
                }
                field("Approved Sales Orders"; Rec."Approved Sales Orders")
                {
                    Caption = 'Approved';
                    DrillDownPageID = "Customer Order Header Status";
                    ToolTip = 'Specifies the number of approved sales orders.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        Rec.SetRange("Overdue Date Filter", 0D, WorkDate() - 1);
        Rec.SetRange("User Filter", UserId);
    end;
}

