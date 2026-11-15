// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location.AddressPrototype;

using Microsoft.Foundation.Address;
using Microsoft.Sales.Document;

pageextension 17701 "Sales Invoice Address Preview" extends "Sales Invoice"
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
                    ToolTip = 'Specifies the country-formatted sell-to address. Choose AssistEdit to edit its address fields.';
                    MultiLine = true;
                    Editable = false;
                    AssistEdit = true;
                    Enabled = CanEditSellToAddress;

                    trigger OnAssistEdit()
                    begin
                        if CanEditSellToAddress then
                            EditAddress("Sales Address Role"::SellTo);
                    end;
                }
            }
            group(SellToOriginalAddressFields)
            {
                ShowCaption = false;
                Visible = ShowAddressFields;
            }
        }
        movefirst(SellToOriginalAddressFields; "Sell-to Address", "Sell-to Address 2", "Sell-to City", Control60, "Sell-to Post Code", "Sell-to Country/Region Code")
        addafter(ShippingOptions)
        {
            group(ShipToAddressPreviewGroup)
            {
                ShowCaption = false;
                Visible = UseAddressPreview;
                field(ShipToAddressPreview; ShipToFormattedAddress)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Address Preview';
                    ToolTip = 'Specifies the country-formatted ship-to address. Choose Custom Address in the Ship-to field to enable AssistEdit.';
                    MultiLine = true;
                    Editable = false;
                    AssistEdit = true;
                    Enabled = CanEditShipToAddress;

                    trigger OnAssistEdit()
                    begin
                        if CanEditShipToAddress then
                            EditAddress("Sales Address Role"::ShipTo);
                    end;
                }
            }
        }
        addbefore("Ship-to Address")
        {
            group(ShipToOriginalAddressFields)
            {
                ShowCaption = false;
                Visible = ShowAddressFields;
            }
        }
        movefirst(ShipToOriginalAddressFields; "Ship-to Address", "Ship-to Address 2", "Ship-to City", Control82, "Ship-to Post Code", "Ship-to Country/Region Code")
        addafter(BillToOptions)
        {
            group(BillToAddressPreviewGroup)
            {
                ShowCaption = false;
                Visible = UseAddressPreview;
                field(BillToAddressPreview; BillToFormattedAddress)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Address Preview';
                    ToolTip = 'Specifies the country-formatted bill-to address. AssistEdit is available for a custom address or another bill-to customer.';
                    MultiLine = true;
                    Editable = false;
                    AssistEdit = true;
                    Enabled = CanEditBillToAddress;

                    trigger OnAssistEdit()
                    begin
                        if CanEditBillToAddress then
                            EditAddress("Sales Address Role"::BillTo);
                    end;
                }
            }
        }
        addbefore("Bill-to Address")
        {
            group(BillToOriginalAddressFields)
            {
                ShowCaption = false;
                Visible = ShowAddressFields;
            }
        }
        movefirst(BillToOriginalAddressFields; "Bill-to Address", "Bill-to Address 2", "Bill-to City", Control85, "Bill-to Post Code", "Bill-to Country/Region Code")
        modify(ShippingOptions)
        {
            trigger OnAfterValidate()
            begin
                UpdateAddressView();
            end;
        }
        modify(BillToOptions)
        {
            trigger OnAfterValidate()
            begin
                UpdateAddressView();
            end;
        }
        modify(Control60)
        {
            Visible = ShowSellToCounty;
        }
        modify(Control82)
        {
            Visible = ShowShipToCounty;
        }
        modify(Control85)
        {
            Visible = ShowBillToCounty;
        }
        modify("Sell-to Country/Region Code")
        {
            trigger OnAfterValidate()
            begin
                UpdateAddressView();
            end;
        }
        modify("Ship-to Country/Region Code")
        {
            trigger OnAfterValidate()
            begin
                UpdateAddressView();
            end;
        }
        modify("Bill-to Country/Region Code")
        {
            trigger OnAfterValidate()
            begin
                UpdateAddressView();
            end;
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(SwitchAddressView)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Switch Address View';
                ToolTip = 'Switches between the original address fields and country-formatted sell-to, bill-to, and ship-to previews with address editors.';
                Image = Edit;

                trigger OnAction()
                begin
                    UseAddressPreview := not UseAddressPreview;
                    RefreshAddressView();
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
        CanEditSellToAddress: Boolean;
        CanEditBillToAddress: Boolean;
        CanEditShipToAddress: Boolean;
        ShowSellToCounty: Boolean;
        ShowBillToCounty: Boolean;
        ShowShipToCounty: Boolean;
        SellToFormattedAddress: Text;
        BillToFormattedAddress: Text;
        ShipToFormattedAddress: Text;

    local procedure EditAddress(AddressRole: Enum "Sales Address Role")
    begin
        if not CurrPage.Editable() then
            exit;

        if SalesAddressMgt.EditAddress(Rec, AddressRole) then
            RefreshAddressView();
    end;

    local procedure RefreshAddressView()
    begin
        UpdateAddressView();
        CurrPage.Update(false);
    end;

    local procedure UpdateAddressView()
    var
        AddressFormatter: Codeunit "Format Address";
    begin
        ShowAddressFields := not UseAddressPreview;
        ShowSellToCounty := AddressFormatter.UseCounty(Rec."Sell-to Country/Region Code");
        ShowBillToCounty := AddressFormatter.UseCounty(Rec."Bill-to Country/Region Code");
        ShowShipToCounty := AddressFormatter.UseCounty(Rec."Ship-to Country/Region Code");
        CanEditSellToAddress := CurrPage.Editable() and (Rec."Sell-to Customer No." <> '');
        CanEditBillToAddress := CanEditSellToAddress and
            ((BillToOptions = BillToOptions::"Custom Address") or (Rec."Bill-to Customer No." <> Rec."Sell-to Customer No."));
        CanEditShipToAddress := CanEditSellToAddress and (ShipToOptions = ShipToOptions::"Custom Address");
        if UseAddressPreview then begin
            SellToFormattedAddress := SalesAddressMgt.FormatAddress(Rec, "Sales Address Role"::SellTo);
            BillToFormattedAddress := SalesAddressMgt.FormatAddress(Rec, "Sales Address Role"::BillTo);
            ShipToFormattedAddress := SalesAddressMgt.FormatAddress(Rec, "Sales Address Role"::ShipTo);
        end;
    end;
}
