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
        addlast(navigation)
        {
            group(Qlty_QualityManagement)
            {
                Caption = 'Quality Management';

                action(Qlty_CreateQualityInspections)
                {
                    ApplicationArea = QualityManagement;
                    Image = CreateForm;
                    Caption = 'Create Quality Inspections';
                    ToolTip = 'Creates multiple quality inspections for the selected item tracking lines.';
                    AboutTitle = 'Create Quality Inspections for selected lines';
                    AboutText = 'Select multiple records, and then use this action to create multiple quality inspections for the selected item tracking lines.';
                    Enabled = QltyCreateQualityInspections;
                    Visible = QltyCreateQualityInspections;

                    trigger OnAction()
                    var
                        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
                    begin
                        CurrPage.SetSelectionFilter(Rec);
                        QltyInspectionCreate.CreateMultipleInspectionsForMarkedTrackingSpecification(Rec, true);
                        Rec.Reset();
                    end;
                }
                action(Qlty_ShowQualityInspectionsForItem)
                {
                    ApplicationArea = QualityManagement;
                    Image = TaskQualityMeasure;
                    Caption = 'Show Quality Inspections for Item with tracking specification';
                    ToolTip = 'Shows Quality Inspections for Item with tracking specification';
                    AboutTitle = 'Show Quality Inspections';
                    AboutText = 'Shows quality inspections for this item with tracking specification.';
                    Enabled = QltyReadQualityInspections;
                    Visible = QltyReadQualityInspections;

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
        QltyReadQualityInspections, QltyCreateQualityInspections : Boolean;

    trigger OnOpenPage()
    var
        CheckLicensePermissionQltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        QltyReadQualityInspections := QltyPermissionMgmt.CanReadInspectionResults();

        if not CheckLicensePermissionQltyInspectionHeader.WritePermission() then
            exit;

        QltyCreateQualityInspections := QltyPermissionMgmt.CanCreateManualInspection();
    end;
}
