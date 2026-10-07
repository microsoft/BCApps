// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

query 9151 "My Vendors"
{
    Caption = 'My Vendors';

    elements
    {
        dataitem(My_Vendor; "My Vendor")
        {
            filter(User_ID; "User ID")
            {
            }
            column(Vendor_No; "Vendor No.")
            {
            }
            dataitem(Vendor; Vendor)
            {
                DataItemLink = "No." = My_Vendor."Vendor No.";
                filter(Date_Filter; "Date Filter")
                {
                }
                column(Sum_Balance; Balance)
                {
                    Method = Sum;
                }
                column(Sum_Invoice_Amounts; "Invoice Amounts")
                {
                    Method = Sum;
                }
            }
        }
    }

    trigger OnBeforeOpen()
    begin
        SetRange(User_ID, UserId);
    end;
}

