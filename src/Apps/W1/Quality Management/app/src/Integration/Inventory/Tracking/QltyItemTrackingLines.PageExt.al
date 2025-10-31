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

                action(Qlty_InspectionTestCreate)
                {
                    ApplicationArea = QualityManagement;
                    Image = CreateForm;
                    Caption = 'Create Quality Inspection Tests';
                    ToolTip = 'Creates multiple quality inspection tests for the selected item tracking lines.';
                    AboutTitle = 'Create Quality Inspection Tests for selected lines';
                    AboutText = 'Select multiple records, and then use this action to create multiple quality inspection tests for the selected item tracking lines.';
                    Enabled = QltyShowCreateTest;
                    Visible = QltyShowCreateTest;

                    trigger OnAction()
                    var
                        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
                    begin
                        CurrPage.SetSelectionFilter(Rec);
                        QltyInspectionTestCreate.CreateMultipleTestsForMarkedTrackingSpecification(Rec);
                        Rec.Reset();
                    end;
                }
                action(Qlty_InspectionShowTestsForItem)
                {
                    ApplicationArea = QualityManagement;
                    Image = TaskQualityMeasure;
                    Caption = 'Show Quality Inspection Tests for Item with tracking specification';
                    ToolTip = 'Shows Quality Inspection Tests for Item with tracking specification';
                    AboutTitle = 'Show Quality Inspection Tests';
                    AboutText = 'Shows quality inspection tests for this item with tracking specification.';
                    Enabled = QltyReadTestResults;
                    Visible = QltyReadTestResults;

                    trigger OnAction()
                    var
                        QltyInspectionTestList: Page "Qlty. Inspection Test List";
                    begin
                        QltyInspectionTestList.RunModalSourceItemTrackingFilterWithRecord(Rec);
                    end;
                }
            }
        }
    }

    var
        QltyReadTestResults: Boolean;
        QltyShowCreateTest: Boolean;

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
