// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

pageextension 12448 "Service Item Wksh. Subform IT" extends "Service Item Worksheet Subform"
{
    layout
    {
        addafter("Description 2")
        {
            field("Include in VAT Transac. Rep."; Rec."Include in VAT Transac. Rep.")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies if the entry must be included in the VAT transaction report.';
            }
        }        
    }
}
