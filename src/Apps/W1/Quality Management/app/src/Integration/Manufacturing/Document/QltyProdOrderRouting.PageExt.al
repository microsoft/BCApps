// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Manufacturing.Document;

using Microsoft.Manufacturing.Document;
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
                    Image = CreateForm;
                    Caption = 'Create Quality Inspection';
                    ToolTip = 'Specifies to create a new quality inspection.';

                    trigger OnAction()
                    var
                        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
                    begin
                        if CanBeProcessed() then
                            QltyInspectionCreate.CreateInspectionWithVariant(Rec, true);
                    end;
                }
                action(Qlty_ShowQualityInspectionsForItem)
                {
                    ApplicationArea = QualityManagement;
                    AccessByPermission = tabledata "Qlty. Inspection Header" = R;
                    Image = TaskQualityMeasure;
                    Caption = 'Show Quality Inspections';
                    ToolTip = 'Shows existing Quality Inspections.';

                    trigger OnAction()
                    var
                        QltyInspectionList: Page "Qlty. Inspection List";
                    begin
                        if CanBeProcessed() then
                            QltyInspectionList.RunModalSourceDocumentFilterWithRecord(Rec);
                    end;
                }
            }
        }
    }

    local procedure CanBeProcessed(): Boolean
    begin
        exit(not IsNullGuid(Rec.SystemId));
    end;
}
