// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

pageextension 99001531 "Subc. Pstd. Direct Trans." extends "Posted Direct Transfer"
{
    layout
    {
        addlast(General)
        {
            field(SourceType; Rec."Source Type")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies for which source type the transfer order is related to.';
                Visible = false;
            }
            field(SourceSubtype; Rec."Source Subtype")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies which source subtype the transfer order is related to.';
                Visible = false;
            }
            field(SourceID; Rec."Source ID")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies which source ID the transfer order is related to.';
                Visible = false;
            }
            field(SourceRefNo; Rec."Source Ref. No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies a reference number for the line, which the transfer order is related to.';
                Visible = false;
            }
            field("Return Order"; Rec."Return Order")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies whether the existing transfer order is a return of the subcontractor.';
                Visible = false;
            }
            field("Subcontr. Purch. Order No."; Rec."Subcontr. Purch. Order No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                ToolTip = 'Specifies the number of the related purchase order.';
                Visible = false;
            }
            field("Subcontr. PO Line No."; Rec."Subcontr. PO Line No.")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                ToolTip = 'Specifies the number of the related purchase order line.';
                Visible = false;
            }
        }
    }
}