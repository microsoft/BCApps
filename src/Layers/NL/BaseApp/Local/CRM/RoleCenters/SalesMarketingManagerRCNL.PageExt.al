// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.RoleCenters;

using Microsoft.Sales.History;

pageextension 11364 "Sales Marketing Manager RC NL" extends "Sales & Marketing Manager RC"
{
    actions
    {
        addafter("Credit Memos")
        {
            action("CMR - Sales Shipment")
            {
                ApplicationArea = Warehouse;
                Caption = 'CMR - Sales Shipment';
                RunObject = report "CMR - Sales Shipment";
                Tooltip = 'Use this report to print a CMR document for a sales shipment. The CMR document is a standard consignment note used in international road transport. It contains information about the sender, recipient, and goods being transported, and serves as a contract of carriage between the parties involved.';
            }
        }
    }
}