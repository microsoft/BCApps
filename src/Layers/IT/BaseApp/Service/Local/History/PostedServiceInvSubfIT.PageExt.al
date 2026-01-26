// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

pageextension 12458 "Posted Service Inv. Subf. IT" extends "Posted Service Invoice Subform"
{
    layout
    {
        addafter("Item Reference No.")
        {
            field("Service Tariff No."; Rec."Service Tariff No.")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the ID of the service tariff that is associated with the posted service invoice.';
            }
        }
        addafter("Description 2")
        {
            field("Include in VAT Transac. Rep."; Rec."Include in VAT Transac. Rep.")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies if you want to include the entry in the VAT transaction report.';
            }
        }
    }
}