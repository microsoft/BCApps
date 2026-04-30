// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

pageextension 99001526 "Subc. Transfer Order" extends "Transfer Order"
{
    layout
    {
        modify("Direct Transfer")
        {
            Enabled = EsEnableTransferFields;
        }
        addlast(General)
        {
            field(SourceType; Rec."Source Type")
            {
                ApplicationArea = Location;
                Editable = false;
                ToolTip = 'Specifies for which source type the transfer order is related to.';
                Visible = false;
            }
            field(SourceSubtype; Rec."Source Subtype")
            {
                ApplicationArea = Location;
                Editable = false;
                ToolTip = 'Specifies which source subtype the transfer order is related to.';
                Visible = false;
            }
            field(SourceID; Rec."Source ID")
            {
                ApplicationArea = Location;
                Editable = false;
                ToolTip = 'Specifies which source ID the transfer order is related to.';
                Visible = false;
            }
            field(SourceRefNo; Rec."Source Ref. No.")
            {
                ApplicationArea = Location;
                Editable = false;
                ToolTip = 'Specifies a reference number for the line, which the transfer order is related to.';
                Visible = false;
            }
            field("Return Order"; Rec."Return Order")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                ToolTip = 'Specifies whether the existing transfer order is a return of the subcontractor.';
                Visible = false;
            }
            field("Subcontr. Purch. Order No."; Rec."Subcontr. Purch. Order No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the number of the related purchase order.';
                Visible = false;
            }
            field("Subcontr. PO Line No."; Rec."Subcontr. PO Line No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the number of the related purchase order line.';
                Visible = false;
            }
        }
        addbefore(Control1900383207)
        {
            part("Subc. Transfer Line Factbox"; "Subc. Transfer Line Factbox")
            {
                ApplicationArea = Manufacturing;
                Provider = TransferLines;
                SubPageLink = "Document No." = field("Document No."), "Line No." = field("Line No.");
                Visible = ShowSubcontractingFactBox;
            }
        }
    }
    protected var
        EsEnableTransferFields: Boolean;

    var
        ShowSubcontractingFactBox: Boolean;

    trigger OnOpenPage()
    begin
        ShowSubcontractingFactBox := Rec."Source Type" = Rec."Source Type"::Subcontracting;
        EsEnableTransferFields := not IsPartiallyShipped();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ShowSubcontractingFactBox := Rec."Source Type" = Rec."Source Type"::Subcontracting;
    end;

    trigger OnAfterGetRecord()
    begin
        EsEnableTransferFields := not IsPartiallyShipped();
    end;

    local procedure IsPartiallyShipped(): Boolean
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Document No.", Rec."No.");
        TransferLine.SetFilter("Quantity Shipped", '> 0');
        exit(not TransferLine.IsEmpty());
    end;
}