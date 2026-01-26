// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

pageextension 12453 "Posted Serv. Cr.Memo Subf. IT" extends "Posted Serv. Cr. Memo Subform"
{
    layout
    {
        addafter("Item Reference No.")
        {
            field("Service Tariff No."; Rec."Service Tariff No.")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the ID of the service tariff that is associated with the service credit memo.';
            }
        }
        addafter("VAT Prod. Posting Group")
        {
            field("Include in VAT Transac. Rep."; Rec."Include in VAT Transac. Rep.")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies if you want to include the entry in the VAT transaction report.';
            }
            field("Refers to Period"; Rec."Refers to Period")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the time period that is used to process and filter the transactions.';
            }
        }
    }
}