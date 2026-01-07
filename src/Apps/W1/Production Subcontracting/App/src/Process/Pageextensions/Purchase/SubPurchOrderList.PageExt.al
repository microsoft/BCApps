// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Document;

pageextension 99001525 "Sub. PurchOrderList" extends "Purchase Order List"
{
    layout
    {
        addafter("Location Code")
        {
            field("Subc. Location Code"; Rec."Subc. Location Code")
            {
                ApplicationArea = All;
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
                ApplicationArea = All;
                Caption = 'Create Transf. Ord. to Subcontractor';
                Image = NewDocument;
                ToolTip = 'Create a transfer order to send to the subcontractor.';

                trigger OnAction()
                var
                    PurchHeader: Record "Purchase Header";
                begin
                    PurchHeader := Rec;
                    PurchHeader.SetRecFilter();
                    Report.Run(Report::"Sub. Create SubC.Transf. Order", false, false, PurchHeader);
                end;
            }
            action(CreateReturnFromSubcontractor)
            {
                ApplicationArea = All;
                Caption = 'Create Return from Subcontractor';
                Image = ReturnRelated;
                ToolTip = 'Create a return document from the subcontractor.';

                trigger OnAction()
                var
                    PurchHeader: Record "Purchase Header";
                begin
                    PurchHeader := Rec;
                    PurchHeader.SetRecFilter();
                    Report.Run(Report::"Sub. Create SubCReturnOrder", false, false, PurchHeader);
                end;
            }
            action(PrintSubcDispatchingList)
            {
                ApplicationArea = All;
                Caption = 'Print Subcontractor Dispatching List';
                Image = Print;
                ToolTip = 'Prints the Dispatching List for the subcontractor.';

                trigger OnAction()
                var
                    PurchHeader: Record "Purchase Header";
                begin
                    PurchHeader := Rec;
                    PurchHeader.SetRecFilter();
                    Report.Run(Report::"Sub. Dispatching List", true, false, PurchHeader);
                end;
            }
        }
    }
}