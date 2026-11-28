// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location.AddressPrototype;

using Microsoft.Sales.History;

pageextension 17702 "Posted Sales Address Preview" extends "Posted Sales Invoice"
{
    layout
    {
        addfirst("Sell-to")
        {
            group(SellToAddressPreviewGroup)
            {
                ShowCaption = false;
                Visible = UseAddressPreview;
                field(SellToAddressPreview; SellToFormattedAddress)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Address Preview';
                    ToolTip = 'Specifies the posted sell-to address formatted for its country or region.';
                    MultiLine = true;
                    Editable = false;
                }
            }
            group(SellToOriginalAddressFields)
            {
                ShowCaption = false;
                Visible = ShowAddressFields;
            }
        }
        movefirst(SellToOriginalAddressFields; "Sell-to Address", "Sell-to Address 2", "Sell-to City", Control88, "Sell-to Post Code", "Sell-to Country/Region Code")
        addbefore("Ship-to Address")
        {
            group(ShipToAddressPreviewGroup)
            {
                ShowCaption = false;
                Visible = UseAddressPreview;
                field(ShipToAddressPreview; ShipToFormattedAddress)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Address Preview';
                    ToolTip = 'Specifies the posted ship-to address formatted for its country or region.';
                    MultiLine = true;
                    Editable = false;
                }
            }
            group(ShipToOriginalAddressFields)
            {
                ShowCaption = false;
                Visible = ShowAddressFields;
            }
        }
        movefirst(ShipToOriginalAddressFields; "Ship-to Address", "Ship-to Address 2", "Ship-to City", Control93, "Ship-to County", "Ship-to Post Code", "Ship-to Country/Region Code")
        addbefore("Bill-to Address")
        {
            group(BillToAddressPreviewGroup)
            {
                ShowCaption = false;
                Visible = UseAddressPreview;
                field(BillToAddressPreview; BillToFormattedAddress)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Address Preview';
                    ToolTip = 'Specifies the posted bill-to address formatted for its country or region.';
                    MultiLine = true;
                    Editable = false;
                }
            }
            group(BillToOriginalAddressFields)
            {
                ShowCaption = false;
                Visible = ShowAddressFields;
            }
        }
        movefirst(BillToOriginalAddressFields; "Bill-to Address", "Bill-to Address 2", "Bill-to City", Control95, "Bill-to Post Code", "Bill-to Country/Region Code")
    }

    actions
    {
        addlast(Processing)
        {
            action(SwitchAddressView)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Switch Address View';
                ToolTip = 'Switches between the original address fields and country-formatted sell-to, bill-to, and ship-to previews.';
                Image = Edit;

                trigger OnAction()
                begin
                    UseAddressPreview := not UseAddressPreview;
                    UpdateAddressView();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        UpdateAddressView();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateAddressView();
    end;

    var
        SalesAddressMgt: Codeunit "Sales Address Mgt.";
        UseAddressPreview: Boolean;
        ShowAddressFields: Boolean;
        SellToFormattedAddress: Text;
        BillToFormattedAddress: Text;
        ShipToFormattedAddress: Text;

    local procedure UpdateAddressView()
    begin
        ShowAddressFields := not UseAddressPreview;
        if UseAddressPreview then begin
            SellToFormattedAddress := SalesAddressMgt.FormatAddress(Rec, "Sales Address Role"::SellTo);
            BillToFormattedAddress := SalesAddressMgt.FormatAddress(Rec, "Sales Address Role"::BillTo);
            ShipToFormattedAddress := SalesAddressMgt.FormatAddress(Rec, "Sales Address Role"::ShipTo);
        end;
    end;
}
