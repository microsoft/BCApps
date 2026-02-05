// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory;

using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.AccessControl;
using Microsoft.QualityManagement.Document;

pageextension 20431 "Qlty. Item List" extends "Item List"
{
    actions
    {
        addlast(navigation)
        {
            action(Qlty_QualityInspections)
            {
                ApplicationArea = QualityManagement;
                Caption = 'Quality Inspections';
                Image = TaskQualityMeasure;
                ToolTip = 'View quality inspections filtered by the selected item.';
                Visible = QltyReadQualityInspections;
                RunObject = Page "Qlty. Inspection List";
                RunPageLink = "Source Item No." = field("No.");
                RunPageView = sorting("Source Item No.");
            }
        }
    }

    var
        QltyReadQualityInspections: Boolean;

    trigger OnOpenPage()
    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        QltyReadQualityInspections := QltyPermissionMgmt.CanReadInspectionResults();
    end;
}
