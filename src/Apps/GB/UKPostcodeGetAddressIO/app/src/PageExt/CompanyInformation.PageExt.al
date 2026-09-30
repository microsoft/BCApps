// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if CLEAN27
namespace app.app;

using Microsoft.Foundation.Company;

pageextension 50003 "Company Information" extends "Company Information"
{
    layout
    {
        addfirst(Shipping)
        {
            group(Control1040016_GB)
            {
                ShowCaption = false;
                Visible = IsShipToAddressLookupTextEnabled;
                field(ShipToLookupAddress_GB; LookupAddressLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
        }
        addfirst(General)
        {
            group(Control1040003_GB)
            {
                ShowCaption = false;
                Visible = IsAddressLookupTextEnabled;
                field(LookupAddress_GB; LookupAddressLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
        }
    }

    var
        IsAddressLookupTextEnabled: Boolean;
        IsShipToAddressLookupTextEnabled: Boolean;
        LookupAddressLbl: Label 'Lookup address from postocde';
}
#endif
