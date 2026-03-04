// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Purchases.Document;

using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Document;

pageextension 20407 "Qlty. Purch. Ret. Order Subf." extends "Purchase Return Order Subform"
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
                    AccessByPermission = tabledata "Qlty. Inspection Header" = I;
                    Image = CreateForm;
                    Caption = 'Create Quality Inspection';
                    ToolTip = 'Creates a quality inspection for this purchase return order line.';
                    AboutTitle = 'Create Quality Inspection';
                    AboutText = 'Create a quality inspection for this purchase return order line.';

                    trigger OnAction()
                    var
                        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
                    begin
                        if CanBeProcessed() then
                            QltyInspectionCreate.CreateInspectionWithVariant(Rec, true);
                    end;
                }
                action(Qlty_ShowQualityInspectionsForItemAndDocument)
                {
                    ApplicationArea = QualityManagement;
                    AccessByPermission = tabledata "Qlty. Inspection Header" = R;
                    Image = TaskQualityMeasure;
                    Caption = 'Show Quality Inspections for Item and Document';
                    ToolTip = 'Shows quality inspections for this item and document.';
                    AboutTitle = 'Show Quality Inspections';
                    AboutText = 'Shows quality inspections for this item and document.';

                    trigger OnAction()
                    var
                        QltyInspectionList: Page "Qlty. Inspection List";
                    begin
                        if CanBeProcessed() then
                            QltyInspectionList.RunModalSourceItemAndSourceDocumentFilterWithRecord(Rec);
                    end;
                }
                action(Qlty_ShowQualityInspectionsForItem)
                {
                    ApplicationArea = QualityManagement;
                    AccessByPermission = tabledata "Qlty. Inspection Header" = R;
                    Image = TaskQualityMeasure;
                    Caption = 'Show Quality Inspections for Item';
                    ToolTip = 'Shows Quality Inspections for Item';
                    AboutTitle = 'Show Quality Inspections';
                    AboutText = 'Shows quality inspections for this item.';

                    trigger OnAction()
                    var
                        QltyInspectionList: Page "Qlty. Inspection List";
                    begin
                        if CanBeProcessed() then
                            QltyInspectionList.RunModalSourceItemFilterWithRecord(Rec);
                    end;
                }
            }
        }
    }

    local procedure CanBeProcessed(): Boolean
    begin
        if IsNullGuid(Rec.SystemId) then
            exit(false);

        exit((Rec.Type = Rec.Type::Item) and (Rec."No." <> ''));
    end;
}
