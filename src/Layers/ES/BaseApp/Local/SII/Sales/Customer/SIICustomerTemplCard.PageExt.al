// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Sales.Customer;

#pragma warning disable AS0088
pageextension 7000133 "SII Customer Template Card" extends "Customer Templ. Card"
{
    layout
    {
        addafter("Statistics Group")
        {
            field("Not in AEAT"; Rec."Not in AEAT")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies that the customer is not registered in Spanish tax agency.';
            }
        }
    }
}
