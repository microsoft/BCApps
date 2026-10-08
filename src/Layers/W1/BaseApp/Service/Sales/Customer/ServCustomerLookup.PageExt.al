// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Customer;

using Microsoft.Sales.Customer;

pageextension 6497 "Serv. Customer Lookup" extends "Customer Lookup"
{
    layout
    {
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
