// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory;

using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.AccessControl;
using Microsoft.QualityManagement.Document;

pageextension 20433 "Qlty. Item Variant Card" extends "Item Variant Card"
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
                ToolTip = 'View quality inspections filtered by the selected item and variant.';
                Visible = QltyReadQualityInspections;
                RunObject = Page "Qlty. Inspection List";
                RunPageLink = "Source Item No." = field("Item No."),
                              "Source Variant Code" = field("Code");
                RunPageView = sorting("Source Item No.", "Source Variant Code");
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
