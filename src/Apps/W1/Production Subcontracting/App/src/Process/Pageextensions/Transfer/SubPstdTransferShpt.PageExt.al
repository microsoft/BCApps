// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

pageextension 99001527 "Sub. Pstd. Transfer Shpt" extends "Posted Transfer Shipment"
{
    layout
    {
        addlast(General)
        {
            field(SourceType; Rec."Source Type")
            {
                ApplicationArea = All;
                Editable = false;
                Visible = false;
            }
            field(SourceSubtype; Rec."Source Subtype")
            {
                ApplicationArea = All;
                Editable = false;
                Visible = false;
            }
            field(SourceID; Rec."Source ID")
            {
                ApplicationArea = All;
                Editable = false;
                Visible = false;
            }
            field(SourceRefNo; Rec."Source Ref. No.")
            {
                ApplicationArea = All;
                Editable = false;
                Visible = false;
            }
            field("Return Order"; Rec."Return Order")
            {
                ApplicationArea = All;
                Editable = false;
                Visible = false;
            }
            field("Subcontr. Purch. Order No."; Rec."Subcontr. Purch. Order No.")
            {
                ApplicationArea = All;
                Editable = false;
                Visible = false;
            }
            field("Subcontr. PO Line No."; Rec."Subcontr. PO Line No.")
            {
                ApplicationArea = All;
                Editable = false;
                Visible = false;
            }
        }
    }
}