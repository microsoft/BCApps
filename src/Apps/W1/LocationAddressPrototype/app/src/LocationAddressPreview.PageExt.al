// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location.AddressPrototype;

using Microsoft.Inventory.Location;

pageextension 17700 "Location Address Preview" extends "Location Card"
{
    layout
    {
        addfirst(AddressDetails)
        {
            group(AddressPreviewGroup)
            {
                ShowCaption = false;
                Visible = UseAddressPreview;
                field(AddressSummary; FormattedAddress)
                {
                    ApplicationArea = Location;
                    Caption = 'Address Preview';
                    ToolTip = 'Specifies the address formatted for its country or region. Choose AssistEdit to edit the individual address fields.';
                    MultiLine = true;
                    Editable = false;
                    AssistEdit = true;
                    Enabled = CanEditAddress;

                    trigger OnAssistEdit()
                    begin
                        if not CurrPage.Editable() then
                            exit;

                        if LocationAddressMgt.EditAddress(Rec) then begin
                            UpdateAddressView();
                            CurrPage.Update(false);
                        end;
                    end;
                }
            }
            group(OriginalAddressFields)
            {
                ShowCaption = false;
                Visible = ShowAddressFields;
            }
        }
        movefirst(OriginalAddressFields; Address, "Address 2", "Post Code", City, "Country/Region Code", CountyGroup)
        modify("Country/Region Code")
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
                ApplicationArea = Location;
                Caption = 'Switch Address View';
                ToolTip = 'Switches between the original address fields and the prototype country-formatted preview with an address editor.';
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
        LocationAddressMgt: Codeunit "Location Address Mgt.";
        UseAddressPreview: Boolean;
        ShowAddressFields: Boolean;
        CanEditAddress: Boolean;
        FormattedAddress: Text;

    local procedure UpdateAddressView()
    begin
        ShowAddressFields := not UseAddressPreview;
        CanEditAddress := CurrPage.Editable();
        if UseAddressPreview then
            FormattedAddress := LocationAddressMgt.FormatAddress(Rec);
    end;
}
