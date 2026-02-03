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
        addlast(Navigation)
        {
            group(Qlty_QualityManagement)
            {
                Caption = 'Quality Management';

                action(Qlty_CreateQualityInspection)
                {
                    ApplicationArea = QualityManagement;
                    Image = CreateForm;
                    Caption = 'Create Quality Inspection';
                    ToolTip = 'Creates a quality inspection for this warehouse entry.';
                    AboutTitle = 'Create Quality Inspection';
                    AboutText = 'Create a quality inspection for this warehouse entry.';
                    Enabled = QltyCreateQualityInspection;
                    Visible = QltyCreateQualityInspection;

                    trigger OnAction()
                    var
                        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
                    begin
                        QltyInspectionCreate.CreateInspectionWithVariant(Rec, true);
                    end;
                }
                action(Qlty_ShowQualityInspectionsForItemAndDocument)
                {
                    ApplicationArea = QualityManagement;
                    Image = TaskQualityMeasure;
                    Caption = 'Show Quality Inspections for Item and Document';
                    ToolTip = 'Shows quality inspections for this item and document.';
                    AboutTitle = 'Show Quality Inspections';
                    AboutText = 'Shows quality inspections for this item and document.';
                    Enabled = QltyReadQualityInspections;
                    Visible = QltyReadQualityInspections;

                    trigger OnAction()
                    var
                        QltyInspectionList: Page "Qlty. Inspection List";
                    begin
                        QltyInspectionList.RunModalSourceItemAndSourceDocumentFilterWithRecord(Rec);
                    end;
                }
                action(Qlty_ShowQualityInspectionsForItem)
                {
                    ApplicationArea = QualityManagement;
                    Image = TaskQualityMeasure;
                    Caption = 'Show Quality Inspections for Item';
                    ToolTip = 'Shows Quality Inspections for Item';
                    AboutTitle = 'Show Quality Inspections';
                    AboutText = 'Shows quality inspections for this item.';
                    Enabled = QltyReadQualityInspections;
                    Visible = QltyReadQualityInspections;

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
        QltyReadQualityInspections, QltyCreateQualityInspection : Boolean;

    trigger OnOpenPage()
    var
        CheckLicensePermissionQltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        QltyReadQualityInspections := QltyPermissionMgmt.CanReadInspectionResults();

        if not CheckLicensePermissionQltyInspectionHeader.WritePermission() then
            exit;

        QltyCreateQualityInspection := QltyPermissionMgmt.CanCreateManualInspection();
    end;
}
