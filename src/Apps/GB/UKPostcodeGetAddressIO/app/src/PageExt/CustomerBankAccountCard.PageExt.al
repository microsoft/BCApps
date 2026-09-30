// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if CLEAN27
namespace app.app;

using Microsoft.Sales.Customer;

pageextension 50007 "Customer Bank Account Card" extends "Customer Bank Account Card"
{
    layout
    {
        addafter(Name)
        {
            group(Control1040004_GB)
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
        moveafter(Contact; "Post Code")
        moveafter(City; CountyGroup)
    }

    var
        IsAddressLookupTextEnabled: Boolean;
        LookupAddressLbl: Label 'Lookup address from postcode';
}
#endif
