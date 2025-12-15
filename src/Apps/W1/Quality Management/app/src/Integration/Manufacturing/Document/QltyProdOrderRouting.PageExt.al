// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Manufacturing.Document;

using Microsoft.Manufacturing.Document;
using Microsoft.QualityManagement.AccessControl;
using Microsoft.QualityManagement.Document;

pageextension 20400 "Qlty. Prod. Order Routing" extends "Prod. Order Routing"
{
    actions
    {
        addbefore("&Line")
        {
            group(Qlty_Management)
            {
                Caption = 'Quality Management';

                action(Qlty_InspectionCreate)
                {
                    ApplicationArea = QualityManagement;
                    Image = TaskQualityMeasure;
                    Caption = 'Create Quality Inspection';
                    ToolTip = 'Specifies to create a new quality inspection.';
                    Enabled = QltyShowCreateTest;

                    trigger OnAction()
                    var
                        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
                    begin
                        QltyInspectionCreate.CreateTestWithVariant(Rec, true);
                    end;
                }
                action(Qlty_InspectionShowTestsForItem)
                {
                    ApplicationArea = QualityManagement;
                    Image = TaskQualityMeasure;
                    Caption = 'Show Quality Inspections';
                    ToolTip = 'Shows existing Quality Inspections.';
                    Enabled = QltyReadTestResults;

                    trigger OnAction()
                    var
                        QltyInspectionList: Page "Qlty. Inspection List";
                    begin
                        QltyInspectionList.RunModalSourceDocumentFilterWithRecord(Rec);
                    end;
                }
            }
        }
    }

    var
        QltyShowCreateTest: Boolean;
        QltyReadTestResults: Boolean;

    trigger OnOpenPage()
    var
        CheckLicensePermissionQltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        if not CheckLicensePermissionQltyInspectionHeader.WritePermission() then
            exit;

        QltyShowCreateTest := QltyPermissionMgmt.CanCreateManualTest();
        QltyReadTestResults := QltyPermissionMgmt.CanReadTestResults();
    end;
}
