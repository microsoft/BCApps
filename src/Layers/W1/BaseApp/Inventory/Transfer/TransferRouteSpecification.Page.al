// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Inventory.Setup;

page 5748 "Transfer Route Specification"
{
    Caption = 'Trans. Route Spec.';
    PageType = Card;
    SourceTable = "Transfer Route";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("In-Transit Code"; Rec."In-Transit Code")
                {
                    ApplicationArea = Location;
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Location;
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Location;
                }
                field("Direct Transfer"; Rec."Direct Transfer")
                {
                    ApplicationArea = Location;
                }
                field("Direct Transfer Posting"; Rec."Direct Transfer Posting")
                {
                    ApplicationArea = Location;
                    Enabled = Rec."Direct Transfer";
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

    trigger OnClosePage()
    var
        CanBeDeleted: Boolean;
    begin
        CanBeDeleted := true;
        OnBeforeClosePage(Rec, CanBeDeleted);
        if CanBeDeleted then
            if Rec.Get(Rec."Transfer-from Code", Rec."Transfer-to Code") then
                if (Rec."Shipping Agent Code" = '') and
                   (Rec."Shipping Agent Service Code" = '') and
                   (Rec."In-Transit Code" = '') and (not Rec."Direct Transfer")
                then
                    Rec.Delete();
    end;

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if not Rec."Direct Transfer" then
            Rec."Direct Transfer Posting" := Rec."Direct Transfer Posting"::" "
        else
            if not (Rec."Direct Transfer Posting" in [Rec."Direct Transfer Posting"::"Direct Transfer", Rec."Direct Transfer Posting"::"Shipment and Receipt"]) then begin
                InventorySetup.GetRecordOnce();
                Rec."Direct Transfer Posting" := InventorySetup."Direct Transfer Posting Type";
                Rec.Modify();
            end;
    end;

    var
        InventorySetup: Record "Inventory Setup";

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClosePage(TransferRoute: Record "Transfer Route"; var CanBeDeleted: Boolean)
    begin
    end;
}

