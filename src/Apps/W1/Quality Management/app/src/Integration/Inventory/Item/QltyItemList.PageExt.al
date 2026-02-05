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
        addlast(Action126)
        {
            action(Qlty_QualityInspections)
            {
                ApplicationArea = QualityManagement;
                Caption = 'Quality Inspections';
                Image = TaskQualityMeasure;
                ToolTip = 'View quality inspections filtered by the selected item.';
                Visible = QltyReadTestResults;

                trigger OnAction()
                begin
                    ShowQualityInspections();
                end;
            }
        }
    }

    var
        QltyReadTestResults: Boolean;

    trigger OnOpenPage()
    var
        CheckLicensePermissionQltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        if not CheckLicensePermissionQltyInspectionHeader.ReadPermission() then
            exit;

        QltyReadTestResults := QltyPermissionMgmt.CanReadInspectionResults();
    end;

    local procedure ShowQualityInspections()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        QltyInspectionHeader.SetRange("Source Item No.", Rec."No.");
        Page.Run(Page::"Qlty. Inspection List", QltyInspectionHeader);
    end;
}
