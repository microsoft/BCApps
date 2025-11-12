// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

pageextension 6466 "Serv. Ship-to Address" extends "Ship-to Address"
{
    layout
    {
        addafter("Shipping Agent Service Code")
        {
            field("Service Zone Code"; Rec."Service Zone Code")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the code for the service zone in which the ship-to address is located.';
            }
        }
    }
}
