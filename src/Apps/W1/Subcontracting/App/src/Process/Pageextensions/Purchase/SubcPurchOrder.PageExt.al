// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Document;

pageextension 99001523 "Subc. Purch. Order" extends "Purchase Order"
{
    layout
    {
        addafter(Status)
        {
            field("Subcontracting Order"; Rec."Subcontracting Order")
            {
                ApplicationArea = Manufacturing;
            }
            field("Subc. Location Code"; Rec."Subc. Location Code")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
            }
        }
        addafter(WorkflowStatus)
        {
            part(" Sub Purchase Line Factbox"; "Subc. Purchase Line Factbox")
            {
                ApplicationArea = Manufacturing;
                Provider = PurchLines;
                SubPageLink = "Document Type" = field("Document Type"), "Document No." = field("Document No."), "Line No." = field("Line No.");
                Visible = ShowSubcontractingFactBox;
            }
        }
    }
    actions
    {
        addafter(IncomingDocument)
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
    var
        ShowSubcontractingFactBox: Boolean;

    trigger OnOpenPage()
    begin
        ShowSubcontractingFactBox := SubcontractingInLines();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ShowSubcontractingFactBox := SubcontractingInLines();
    end;

    local procedure SubcontractingInLines(): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", Rec."Document Type");
        PurchaseLine.SetRange("Document No.", Rec."No.");
        PurchaseLine.SetFilter("Work Center No.", '<>%1', '');
        exit(not PurchaseLine.IsEmpty());
    end;
}