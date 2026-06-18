// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;

pageextension 99001543 "Subc. Finished Prod. Orders" extends "Finished Production Orders"
{
    actions
    {
        addafter("&Warehouse Entries")
        {
            action("Subc. Transfer Orders")
            {
                ApplicationArea = Subcontracting;
                Caption = 'Subcontracting Transfer Orders';
                Image = TransferOrder;
                ToolTip = 'View the subcontracting transfer orders related to this production order.';

                trigger OnAction()
                var
                    SubcPurchFactboxMgmt: Codeunit "Subc. Purch. Factbox Mgmt.";
                begin
                    SubcPurchFactboxMgmt.ShowTransferOrdersFromProductionOrder(Rec);
                end;
            }
            action("WIP Ledger Entries")
            {
                ApplicationArea = Subcontracting;
                Caption = 'Subcontracting WIP Entries';
                Image = LedgerEntries;
                RunObject = page "Subc. WIP Ledger Entries";
                RunPageLink = "Prod. Order Status" = field(Status), "Prod. Order No." = field("No.");
                ToolTip = 'View the Subcontracting WIP Entries for this production order.';
            }
        }
    }
}