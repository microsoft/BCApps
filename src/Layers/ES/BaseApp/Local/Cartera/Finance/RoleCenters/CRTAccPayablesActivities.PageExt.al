// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;

pageextension 7000003 "CRT Acc. Payables Activities" extends "Acc. Payables Activities"
{
    layout
    {
        addafter("Document Approvals")
        {
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
        }
    }
}