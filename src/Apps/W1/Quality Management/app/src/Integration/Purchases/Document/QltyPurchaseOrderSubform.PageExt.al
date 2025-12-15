// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Purchases.Document;

using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.AccessControl;
using Microsoft.QualityManagement.Document;

pageextension 20402 "Qlty. Purchase Order Subform" extends "Purchase Order Subform"
{
    actions
    {
        addafter("O&rder")
        {
            group(Qlty_Management)
            {
                Caption = 'Quality Management';

                action(Qlty_InspectionCreate)
                {
                    ApplicationArea = QualityManagement;
                    Image = CreateForm;
                    Caption = 'Create Quality Inspection';
                    ToolTip = 'Creates a quality inspection for this purchase order line.';
                    AboutTitle = 'Create Quality Inspection';
                    AboutText = 'Create a quality inspection for this purchase order line.';
                    Enabled = QltyShowCreateInspection;
                    Visible = QltyShowCreateInspection;

                    trigger OnAction()
                    var
                        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
                    begin
                        QltyInspectionCreate.CreateInspectionWithVariant(Rec, true);
                    end;
                }
                action(Qlty_InspectionShowTestsForItemAndDocument)
                {
                    ApplicationArea = QualityManagement;
                    Image = TaskQualityMeasure;
                    Caption = 'Show Quality Inspections for Item and Document';
                    ToolTip = 'Shows quality inspections for this item and document.';
                    AboutTitle = 'Show Quality Inspections';
                    AboutText = 'Shows quality inspections for this item and document.';
                    Enabled = QltyReadTestResults;
                    Visible = QltyReadTestResults;

                    trigger OnAction()
                    var
                        QltyInspectionList: Page "Qlty. Inspection List";
                    begin
                        QltyInspectionList.RunModalSourceItemAndSourceDocumentFilterWithRecord(Rec);
                    end;
                }
                action(Qlty_ShowTests)
                {
                    ApplicationArea = QualityManagement;
                    Image = TaskQualityMeasure;
                    Caption = 'Show Quality Inspections for Item';
                    ToolTip = 'Shows Quality Inspections for Item';
                    AboutTitle = 'Show Quality Inspections';
                    AboutText = 'Shows quality inspections for this item.';
                    Enabled = QltyReadTestResults;
                    Visible = QltyReadTestResults;

                    trigger OnAction()
                    var
                        QltyInspectionList: Page "Qlty. Inspection List";
                    begin
                        QltyInspectionList.RunModalSourceItemFilterWithRecord(Rec);
                    end;
                }
            }
        }
    }

    var
        QltyShowCreateInspection: Boolean;
        QltyReadTestResults: Boolean;

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
