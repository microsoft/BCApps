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

                action(Qlty_InspectionTestCreate)
                {
                    ApplicationArea = QualityManagement;
                    Image = TaskQualityMeasure;
                    Caption = 'Create Quality Inspection Test';
                    ToolTip = 'Specifies to create a new quality inspection test.';
                    Enabled = QltyShowCreateTest;

                    trigger OnAction()
                    var
                        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
                    begin
                        QltyInspectionTestCreate.CreateTestWithVariant(Rec, true);
                    end;
                }
                action(Qlty_InspectionShowTestsForItem)
                {
                    ApplicationArea = QualityManagement;
                    Image = TaskQualityMeasure;
                    Caption = 'Show Quality Inspection Tests';
                    ToolTip = 'Shows existing Quality Inspection Tests.';
                    Enabled = QltyReadTestResults;

                    trigger OnAction()
                    var
                        QltyInspectionTestList: Page "Qlty. Inspection Test List";
                    begin
                        QltyInspectionTestList.RunModalSourceDocumentFilterWithRecord(Rec);
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
        CheckLicensePermissionQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        if not CheckLicensePermissionQltyInspectionTestHeader.WritePermission() then
            exit;

        QltyShowCreateTest := QltyPermissionMgmt.CanCreateManualTest();
        QltyReadTestResults := QltyPermissionMgmt.CanReadTestResults();
    end;
}
