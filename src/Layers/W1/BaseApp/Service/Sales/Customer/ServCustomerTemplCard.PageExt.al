// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

pageextension 6492 "Serv. Customer Templ. Card" extends "Customer Templ. Card"
{
    layout
    {
        addafter("Responsibility Center")
        {
            field("Service Zone Code"; Rec."Service Zone Code")
            {
                ApplicationArea = Service;
                Importance = Additional;
                ToolTip = 'Specifies the code for the service zone that is assigned to the customer.';
                Visible = false;
            }
        }
        addafter("Combine Shipments")
        {
            field("Combine Service Shipments"; Rec."Combine Service Shipments")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies if several orders delivered to the customer can appear on the same service invoice.';
                Visible = false;
            }
        }
    }
}
