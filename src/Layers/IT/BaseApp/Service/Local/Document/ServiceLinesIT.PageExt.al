// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

pageextension 12449 "Service Lines IT" extends "Service Lines"
{
    layout
    {
        addafter("Service Item Serial No.")
        {
            field("Include in VAT Transac. Rep."; Rec."Include in VAT Transac. Rep.")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies if the entry must be included in the VAT transaction report.';
            }
        }
        addafter("Item Reference No.")
        {
            field("Service Tariff No."; Rec."Service Tariff No.")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the ID of the service tariff that is associated with the service order.';
            }
        }
    }
}
