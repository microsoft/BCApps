// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Receiving.Document;

using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Warehouse;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Document;

pageextension 20434 "Qlty. Whse. Receipt Subform" extends "Whse. Receipt Subform"
{
    actions
    {
        addlast("&Line")
        {
            group(Qlty_QualityManagement)
            {
                Caption = 'Quality Management';

                action(Qlty_CreateQualityInspection)
                {
                    ApplicationArea = QualityManagement;
                    AccessByPermission = tabledata "Qlty. Inspection Header" = I;
                    Image = BulletList;
                    Caption = 'Create Quality Inspection';
                    ToolTip = 'Creates a quality inspection for this warehouse receipt line.';
                    AboutTitle = 'Create Quality Inspection';
                    AboutText = 'Create a quality inspection for this warehouse receipt line.';

                    trigger OnAction()
                    begin
                        if CanBeProcessed() then
                            CreateInspectionWithSourceTracking();
                    end;
                }
                action(Qlty_ShowQualityInspectionsForItemAndDocument)
                {
                    ApplicationArea = QualityManagement;
                    AccessByPermission = tabledata "Qlty. Inspection Header" = R;
                    Image = CheckList;
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
                    Image = CheckList;
                    Caption = 'Show Quality Inspections for Item';
                    ToolTip = 'Shows quality inspections for this item.';
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

        exit(Rec."Item No." <> '');
    end;

    local procedure CreateInspectionWithSourceTracking()
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyWarehouseIntegration: Codeunit "Qlty. Warehouse Integration";
        OptionalSourceLineVariant: Variant;
        DummyVariant: Variant;
        HasSourceLine: Boolean;
    begin
        if WarehouseReceiptHeader.Get(Rec."No.") then;

        HasSourceLine := TryGetSourceLineVariant(OptionalSourceLineVariant);
        if HasSourceLine then
            QltyWarehouseIntegration.CollectSourceItemTracking(OptionalSourceLineVariant, TempTrackingSpecification);

        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.FindSet() then
            repeat
                QltyInspectionCreate.CreateInspectionWithMultiVariants(Rec, OptionalSourceLineVariant, WarehouseReceiptHeader, TempTrackingSpecification, true, TempQltyInspectionGenRule);
            until TempTrackingSpecification.Next() = 0
        else
            if HasSourceLine then
                QltyInspectionCreate.CreateInspectionWithMultiVariants(Rec, OptionalSourceLineVariant, WarehouseReceiptHeader, DummyVariant, true, TempQltyInspectionGenRule)
            else
                QltyInspectionCreate.CreateInspectionWithVariant(Rec, true);
    end;

    local procedure TryGetSourceLineVariant(var OptionalSourceLineVariant: Variant): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
    begin
        case Rec."Source Type" of
            Database::"Purchase Line":
                if PurchaseLine.Get(Rec."Source Subtype", Rec."Source No.", Rec."Source Line No.") then begin
                    OptionalSourceLineVariant := PurchaseLine;
                    exit(true);
                end;
            Database::"Sales Line":
                if SalesLine.Get(Rec."Source Subtype", Rec."Source No.", Rec."Source Line No.") then begin
                    OptionalSourceLineVariant := SalesLine;
                    exit(true);
                end;
            Database::"Transfer Line":
                if TransferLine.Get(Rec."Source No.", Rec."Source Line No.") then begin
                    OptionalSourceLineVariant := TransferLine;
                    exit(true);
                end;
        end;
    end;
}
