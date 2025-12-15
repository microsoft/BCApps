// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Tracking;

using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.AccessControl;
using Microsoft.QualityManagement.Document;

pageextension 20418 "Qlty. Item Tracking Lines" extends "Item Tracking Lines"
{
    actions
    {
        addafter(ButtonLineReclass)
        {
            group(Qlty_Management)
            {
                Caption = 'Quality Management';

                action(Qlty_InspectionCreate)
                {
                    ApplicationArea = QualityManagement;
                    Image = CreateForm;
                    Caption = 'Create Quality Inspections';
                    ToolTip = 'Creates multiple quality inspections for the selected item tracking lines.';
                    AboutTitle = 'Create Quality Inspections for selected lines';
                    AboutText = 'Select multiple records, and then use this action to create multiple quality inspections for the selected item tracking lines.';
                    Enabled = QltyShowCreateInspection;
                    Visible = QltyShowCreateInspection;

                    trigger OnAction()
                    var
                        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
                    begin
                        CurrPage.SetSelectionFilter(Rec);
                        QltyInspectionCreate.CreateMultipleTestsForMarkedTrackingSpecification(Rec);
                        Rec.Reset();
                    end;
                }
                action(Qlty_InspectionShowTestsForItem)
                {
                    ApplicationArea = QualityManagement;
                    Image = TaskQualityMeasure;
                    Caption = 'Show Quality Inspections for Item with tracking specification';
                    ToolTip = 'Shows Quality Inspections for Item with tracking specification';
                    AboutTitle = 'Show Quality Inspections';
                    AboutText = 'Shows quality inspections for this item with tracking specification.';
                    Enabled = QltyReadTestResults;
                    Visible = QltyReadTestResults;

                    trigger OnAction()
                    var
                        QltyInspectionList: Page "Qlty. Inspection List";
                    begin
                        QltyInspectionList.RunModalSourceItemTrackingFilterWithRecord(Rec);
                    end;
                }
            }
        }
    }

    var
        QltyReadTestResults: Boolean;
        QltyShowCreateInspection: Boolean;

    trigger OnOpenPage()
    var
        CheckLicensePermissionQltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        if not CheckLicensePermissionQltyInspectionHeader.WritePermission() then
            exit;

        QltyShowCreateInspection := QltyPermissionMgmt.CanCreateManualInspection();
        QltyReadTestResults := QltyPermissionMgmt.CanReadInspectionResults();
    end;
}
