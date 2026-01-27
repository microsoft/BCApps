// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Document;

pageextension 99001525 "Subc. PurchOrderList" extends "Purchase Order List"
{
    layout
    {
        addafter("Location Code")
        {
            field("Subc. Location Code"; Rec."Subc. Location Code")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
            }
        }
    }
    actions
    {
        addafter("Create Inventor&y Put-away/Pick")
        {
            action(CreateTransfOrdToSubcontractor)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Create Transf. Ord. to Subcontractor';
                Image = NewDocument;
                ToolTip = 'Create a transfer order to send to the subcontractor.';

                trigger OnAction()
                var
                    PurchaseHeader: Record "Purchase Header";
                begin
                    PurchaseHeader := Rec;
                    PurchaseHeader.SetRecFilter();
                    Report.Run(Report::"Subc. Create Transf. Order", false, false, PurchaseHeader);
                end;
            }
            action(CreateReturnFromSubcontractor)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Create Return from Subcontractor';
                Image = ReturnRelated;
                ToolTip = 'Create a return document from the subcontractor.';

                trigger OnAction()
                var
                    PurchaseHeader: Record "Purchase Header";
                begin
                    PurchaseHeader := Rec;
                    PurchaseHeader.SetRecFilter();
                    Report.Run(Report::"Subc. Create SubCReturnOrder", false, false, PurchaseHeader);
                end;
            }
            action(PrintSubcDispatchingList)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Print Subcontractor Dispatching List';
                Image = Print;
                ToolTip = 'Prints the Dispatching List for the subcontractor.';

                trigger OnAction()
                var
                    PurchaseHeader: Record "Purchase Header";
                begin
                    PurchaseHeader := Rec;
                    PurchaseHeader.SetRecFilter();
                    Report.Run(Report::"Subc. Dispatching List", true, false, PurchaseHeader);
                end;
            }
        }
    }
}