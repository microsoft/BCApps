// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory;

using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.Document;

pageextension 20430 "Qlty. Item Card" extends "Item Card"
{
    actions
    {
        addlast(navigation)
        {
            action(Qlty_QualityInspections)
            {
                ApplicationArea = QualityManagement;
                AccessByPermission = tabledata "Qlty. Inspection Header" = R;
                Caption = 'Quality Inspections';
                Image = TaskQualityMeasure;
                ToolTip = 'View quality inspections filtered by the selected item.';
                RunObject = Page "Qlty. Inspection List";
                RunPageLink = "Source Item No." = field("No.");
                RunPageView = sorting("Source Item No.");
            }
        }
    }
}
