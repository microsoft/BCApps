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
            field("Subc. Source Type"; Rec."Subc. Source Type")
            {
                ApplicationArea = Subcontracting;
                Editable = false;
                ToolTip = 'Specifies for which source type the transfer order is related to.';
                Visible = false;
            }
            field(SourceSubtype; Rec."Source Subtype")
            {
                ApplicationArea = Subcontracting;
                Editable = false;
                ToolTip = 'Specifies which source subtype the transfer order is related to.';
                Visible = false;
            }
            field(SourceID; Rec."Source ID")
            {
                ApplicationArea = Subcontracting;
                Editable = false;
                ToolTip = 'Specifies which source ID the transfer order is related to.';
                Visible = false;
            }
            field(SourceRefNo; Rec."Source Ref. No.")
            {
                ApplicationArea = Subcontracting;
                Editable = false;
                ToolTip = 'Specifies a reference number for the line, which the transfer order is related to.';
                Visible = false;
            }
            field("Subc. Return Order"; Rec."Subc. Return Order")
            {
                ApplicationArea = Subcontracting;
                Editable = false;
                ToolTip = 'Specifies whether the existing transfer order is a return of the subcontractor.';
                Visible = false;
            }
            field("Subcontr. Purch. Order No."; Rec."Subcontr. Purch. Order No.")
            {
                ApplicationArea = Subcontracting;
                ToolTip = 'Specifies the number of the related purchase order.';
                Visible = false;
            }
            field("Subcontr. PO Line No."; Rec."Subcontr. PO Line No.")
            {
                ApplicationArea = Subcontracting;
                ToolTip = 'Specifies the number of the related purchase order line.';
                Visible = false;
            }
        }
        addbefore(Control1900383207)
        {
            part("Subc. Transfer Line Factbox"; "Subc. Transfer Line Factbox")
            {
                ApplicationArea = Subcontracting;
                Provider = TransferLines;
                SubPageLink = "Document No." = field("Document No."), "Line No." = field("Line No.");
                Visible = ShowSubcontractingFactBox;
            }
        }
    }
    protected var
        EsEnableTransferFields: Boolean;

    var
        SubcTransferManagement: Codeunit "Subc. Transfer Management";
#if not CLEAN29
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
        SubcontractingEnabled: Boolean;
#endif
        ShowSubcontractingFactBox: Boolean;

    trigger OnOpenPage()
    begin
#if not CLEAN29
#pragma warning disable AL0432
        SubcontractingEnabled := SubcFeatureFlagHandler.IsSubcontractingEnabled();
#pragma warning restore AL0432
        if not SubcontractingEnabled then
            exit;
#endif
        ShowSubcontractingFactBox := SubcTransferManagement.IsSubcontractingTransferDocument(Rec);
        CurrPage.TransferLines.Page.SetIsSubcontracting(ShowSubcontractingFactBox);
        EsEnableTransferFields := not IsPartiallyShipped();
    end;

    trigger OnAfterGetCurrRecord()
    begin
#if not CLEAN29
        if not SubcontractingEnabled then
            exit;

#endif
        ShowSubcontractingFactBox := SubcTransferManagement.IsSubcontractingTransferDocument(Rec);
        CurrPage.TransferLines.Page.SetIsSubcontracting(ShowSubcontractingFactBox);
    end;

    trigger OnAfterGetRecord()
    begin
#if not CLEAN29
        if not SubcontractingEnabled then
            exit;

#endif
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