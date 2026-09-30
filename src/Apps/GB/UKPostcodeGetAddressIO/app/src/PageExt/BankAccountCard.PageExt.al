// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if CLEAN27
namespace app.app;

using Microsoft.Bank.BankAccount;

pageextension 50000 "Bank Account Card" extends "Bank Account Card"
{
    layout
    {
        addfirst(Communication)
        {
            group(Control1040007_GB)
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
        moveafter("Address 2"; City, CountyGroup)
    }

    var
        IsAddressLookupTextEnabled: Boolean;
        LookupAddressLbl: Label 'Lookup address from postcode';
}
#endif
