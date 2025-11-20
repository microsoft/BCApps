// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

using Microsoft.Utilities;

page 9140 "Postcode Select Address"
{
    Caption = 'Address Selection';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Value; Rec.Value)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the postal code.';
                }
            }
        }
    }

    actions
    {
    }

    procedure SetAddressList(var TempAddressListNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        if TempAddressListNameValueBuffer.FindSet() then
            repeat
                Rec := TempAddressListNameValueBuffer;
                Rec.Insert();
            until TempAddressListNameValueBuffer.Next() = 0;

        Rec.FindFirst(); // Move selection to the first one
    end;

    procedure GetSelectedAddress(var TempSelectedAddressNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        CurrPage.SetSelectionFilter(TempSelectedAddressNameValueBuffer);
        Rec.SetFilter(ID, TempSelectedAddressNameValueBuffer.GetFilter(ID));
        Rec.FindFirst();
        TempSelectedAddressNameValueBuffer := Rec;
    end;
}

