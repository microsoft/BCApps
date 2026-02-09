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
        addlast("F&unctions")
        {
            group(Qlty_QualityManagement)
            {
                Caption = 'Quality Management';

                action(Qlty_CreateQualityInspection)
                {
                    ApplicationArea = QualityManagement;
                    Image = TaskQualityMeasure;
                    Caption = 'Create Quality Inspection';
                    ToolTip = 'Specifies to create a new quality inspection.';
                    Enabled = QltyCreateQualityInspection;

                    trigger OnAction()
                    var
                        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
                    begin
                        QltyInspectionCreate.CreateInspectionWithVariant(Rec, true);
                    end;
                }
                action(Qlty_ShowQualityInspectionsForItem)
                {
                    ApplicationArea = QualityManagement;
                    Image = TaskQualityMeasure;
                    Caption = 'Show Quality Inspections';
                    ToolTip = 'Shows existing Quality Inspections.';
                    Enabled = QltyReadQualityInspections;

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
