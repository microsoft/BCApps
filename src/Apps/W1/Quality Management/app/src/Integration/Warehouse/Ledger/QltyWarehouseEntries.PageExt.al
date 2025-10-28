// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Warehouse.Ledger;

using Microsoft.QualityManagement.AccessControl;
using Microsoft.QualityManagement.Document;
using Microsoft.Warehouse.Ledger;

pageextension 20427 "Qlty. Warehouse Entries" extends "Warehouse Entries"
{
    actions
    {
        addafter("&Item Tracking")
        {
            group(Qlty_Management)
            {
                Caption = 'Quality Management';

                action(Qlty_InspectionTestCreate)
                {
                    ApplicationArea = QualityManagement;
                    Image = CreateForm;
                    Caption = 'Create Quality Inspection Test';
                    ToolTip = 'Creates a quality inspection test for this warehouse entry.';
                    AboutTitle = 'Create Quality Inspection Test';
                    AboutText = 'Create a quality inspection test for this warehouse entry.';
                    Enabled = QltyShowCreateTest;
                    Visible = QltyShowCreateTest;

                    trigger OnAction()
                    var
                        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
                    begin
                        QltyInspectionTestCreate.CreateTestWithVariant(Rec, true);
                    end;
                }
                action(Qlty_InspectionShowTestsForItemAndDocument)
                {
                    ApplicationArea = QualityManagement;
                    Image = TaskQualityMeasure;
                    Caption = 'Show Quality Inspection Tests for Item and Document';
                    ToolTip = 'Shows quality inspection tests for this item and document.';
                    AboutTitle = 'Show Quality Inspection Tests';
                    AboutText = 'Shows quality inspection tests for this item and document.';
                    Enabled = QltyReadTestResults;
                    Visible = QltyReadTestResults;

                    trigger OnAction()
                    var
                        QltyInspectionTestList: Page "Qlty. Inspection Test List";
                    begin
                        QltyInspectionTestList.RunModalSourceItemAndSourceDocumentFilterWithRecord(Rec);
                    end;
                }
                action(Qlty_InspectionShowTestsForItem)
                {
                    ApplicationArea = QualityManagement;
                    Image = TaskQualityMeasure;
                    Caption = 'Show Quality Inspection Tests for Item';
                    ToolTip = 'Shows Quality Inspection Tests for Item';
                    AboutTitle = 'Show Quality Inspection Tests';
                    AboutText = 'Shows quality inspection tests for this item.';
                    Enabled = QltyReadTestResults;
                    Visible = QltyReadTestResults;

                    trigger OnAction()
                    var
                        QltyInspectionTestList: Page "Qlty. Inspection Test List";
                    begin
                        QltyInspectionTestList.RunModalSourceItemFilterWithRecord(Rec);
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
