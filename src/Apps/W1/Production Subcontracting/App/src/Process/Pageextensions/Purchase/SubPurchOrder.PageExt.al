// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Document;

pageextension 99001523 "Sub. Purch. Order" extends "Purchase Order"
{
    layout
    {
        addafter(Status)
        {
            field("Subcontracting Order"; Rec."Subcontracting Order")
            {
                ApplicationArea = All;
            }
            field("Subc. Location Code"; Rec."Subc. Location Code")
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
        addafter(WorkflowStatus)
        {
            part(" Sub Purchase Line Factbox"; "Sub. Purchase Line Factbox")
            {
                ApplicationArea = All;
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
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", Rec."Document Type");
        PurchLine.SetRange("Document No.", Rec."No.");
        PurchLine.SetFilter("Work Center No.", '<>%1', '');
        exit(not PurchLine.IsEmpty());
    end;
}