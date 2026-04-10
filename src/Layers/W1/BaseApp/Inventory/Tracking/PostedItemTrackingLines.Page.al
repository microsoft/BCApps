// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Ledger;

page 6511 "Posted Item Tracking Lines"
{
    Caption = 'Posted Item Tracking Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Item Ledger Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = ItemTracking;
                }
                field("Shipped Qty. Not Returned"; Rec."Shipped Qty. Not Returned")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;
                }
                field("Warranty Date"; Rec."Warranty Date")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        CaptionText1: Text[100];
        CaptionText2: Text[100];
    begin
        CaptionText1 := Rec."Item No.";
        if CaptionText1 <> '' then begin
            CaptionText2 := CurrPage.Caption;
            CurrPage.Caption := StrSubstNo(Text001, CaptionText1, CaptionText2);
        end;
    end;

    var
#pragma warning disable AA0074
        Text001: Label '%1 - %2', Locked = true;
#pragma warning restore AA0074
}

