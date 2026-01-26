// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

pageextension 10622 "Service Order NO" extends "Service Order"
{
    layout
    {
        addafter("Max. Labor Unit Price")
        {
            field(GLN; Rec.GLN)
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the global location number of the customer.';
            }
            field("Account Code"; Rec."Account Code")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the account code of the customer.';
            }
            field("E-Invoice"; Rec."E-Invoice")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies whether the customer is part of the EHF system and requires an electronic service order.';
            }
        }
        addafter("Shipping Time")
        {
            field("Delivery Date"; Rec."Delivery Date")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the date that the item was requested for delivery in the service order.';
            }
        }
    }
}

