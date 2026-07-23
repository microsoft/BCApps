// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.Sales.Customer;

pageextension 10806 "Customer Card" extends "Customer Card"
{
    layout
    {
        addafter("Registration Number")
        {
            field("SIREN No. FR"; Rec."SIREN No. FR")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the SIREN No. for the customer.';
            }
        }
    }
}
