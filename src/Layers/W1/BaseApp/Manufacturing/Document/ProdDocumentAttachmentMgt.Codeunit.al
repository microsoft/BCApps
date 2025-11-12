// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Foundation.Attachment;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using System.Telemetry;

codeunit 99000783 "Prod. Document Attachment Mgt."
{
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        ProductionDocumentAttachmentFeatureTelemetryNameLbl: Label 'Production Document Attachment', Locked = true;
        CopyAttachmentLbl: Label 'Copy Attachment From %1 to %2.', Comment = '%1 = From Table Caption, %2 = To Table Caption ';
        DeleteAttachmentLbl: Label 'Delete Attachment From %1.', Comment = '%1 = From Table Caption';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterIsProductionDocumentFlow', '', false, false)]
    local procedure OnAfterIsProductionDocumentFlow(TableNo: Integer; var IsDocumentFlow: Boolean)
    begin
        if IsProductionDocumentFlow(TableNo) then
            IsDocumentFlow := true;
    end;

    internal procedure IsProductionDocumentFlow(TableNo: Integer) IsDocumentFlow: Boolean
    begin
        exit(TableNo in
            [Database::Item,
            Database::"Production BOM Header",
            Database::"Routing Header",
            Database::"Production Order",
            Database::"Prod. Order Line"]);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableIsDocument', '', false, false)]
    local procedure OnAfterIsTableDocument(TableNo: Integer; var IsDocument: Boolean)
    begin
        if IsDocument then
            exit;

        IsDocument := TableNo in [Database::"Production Order", Database::"Prod. Order Line"];
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterGetRefTable', '', false, false)]
    local procedure OnAfterGetRefTable(var RecRef: RecordRef; DocumentAttachment: Record "Document Attachment")
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
    begin
        if DocumentAttachment."Table ID" <> 0 then
            case DocumentAttachment."Table ID" of
                Database::"Production BOM Header":
                    begin
                        RecRef.Open(Database::"Production BOM Header");
                        if ProdBOMHeader.Get(DocumentAttachment."No.") then
                            RecRef.GetTable(ProdBOMHeader);
                    end;
                Database::"Routing Header":
                    begin
                        RecRef.Open(Database::"Routing Header");
                        if RoutingHeader.Get(DocumentAttachment."No.") then
                            RecRef.GetTable(RoutingHeader);
                    end;
                Database::"Production Order":
                    begin
                        RecRef.Open(Database::"Production Order");
                        case DocumentAttachment."Document Type" of
                            DocumentAttachment."Document Type"::"Simulated Production Order":
                                ProdOrder.Status := ProdOrder.Status::Simulated;
                            DocumentAttachment."Document Type"::"Planned Production Order":
                                ProdOrder.Status := ProdOrder.Status::Planned;
                            DocumentAttachment."Document Type"::"Firm Planned Production Order":
                                ProdOrder.Status := ProdOrder.Status::"Firm Planned";
                            DocumentAttachment."Document Type"::"Released Production Order":
                                ProdOrder.Status := ProdOrder.Status::Released;
                            DocumentAttachment."Document Type"::"Finished Production Order":
                                ProdOrder.Status := ProdOrder.Status::Finished;
                        end;
                        if ProdOrder.Get(ProdOrder.Status, DocumentAttachment."No.") then
                            RecRef.GetTable(ProdOrder);
                    end;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableHasNumberFieldPrimaryKey', '', false, false)]
    local procedure OnAfterTableHasNumberFieldPrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    begin
        if TableNo <> 0 then
            case TableNo of
                Database::"Production Order",
                Database::"Prod. Order Line":
                    begin
                        // Field "Prod. Order No.".
                        FieldNo := 2;
                        Result := true;
                    end;
                Database::"Production BOM Header",
                Database::"Routing Header":
                    begin
                        // Field "No.".
                        FieldNo := 1;
                        Result := true;
                    end;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableHasDocTypePrimaryKey', '', false, false)]
    local procedure OnAfterTableHasDocTypePrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    begin
        if TableNo <> 0 then
            case TableNo of
                Database::"Production Order",
                Database::"Prod. Order Line":
                    begin
                        // Field Status.
                        FieldNo := 1;
                        Result := true;
                    end;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableHasLineNumberPrimaryKey', '', false, false)]
    local procedure OnAfterTableHasLineNumberPrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    begin
        if TableNo <> 0 then
            case TableNo of
                Database::"Prod. Order Line":
                    begin
                        // Field "Line No.".
                        FieldNo := 3;
                        Result := true;
                    end;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnCopyAttachmentsOnAfterSetFromParameters', '', false, false)]
    local procedure OnCopyAttachmentsOnAfterSetFromParameters(FromRecRef: RecordRef; var FromDocumentAttachment: Record "Document Attachment"; var FromAttachmentDocumentType: Enum "Attachment Document Type")
    var
        FromFieldRef: FieldRef;
        FromNo: Code[20];
        FromLineNo: Integer;
    begin
        if FromRecRef.Number() <> 0 then
            case FromRecRef.Number() of
                Database::"Routing Header":
                    begin
                        // Field "No.".
                        FromFieldRef := FromRecRef.Field(1);
                        FromNo := FromFieldRef.Value();
                        FromDocumentAttachment.SetRange("No.", FromNo);
                    end;
                Database::"Production BOM Header":
                    begin
                        // Field "No.".
                        FromFieldRef := FromRecRef.Field(1);
                        FromNo := FromFieldRef.Value();
                        FromDocumentAttachment.SetRange("No.", FromNo);
                    end;
                Database::"Production Order":
                    begin
                        // Field Status.
                        FromFieldRef := FromRecRef.Field(1);
                        FromAttachmentDocumentType := FromFieldRef.Value();
                        TransformAttachmentDocumentTypeValue(FromRecRef.Number(), FromAttachmentDocumentType);
                        FromDocumentAttachment.SetRange("Document Type", FromAttachmentDocumentType);

                        // Field "Prod. Order No.".
                        FromFieldRef := FromRecRef.Field(2);
                        FromNo := FromFieldRef.Value();
                        FromDocumentAttachment.SetRange("No.", FromNo);
                    end;
                Database::"Prod. Order Line":
                    begin
                        // Field Status.
                        FromFieldRef := FromRecRef.Field(1);
                        FromAttachmentDocumentType := FromFieldRef.Value();
                        TransformAttachmentDocumentTypeValue(FromRecRef.Number(), FromAttachmentDocumentType);
                        FromDocumentAttachment.SetRange("Document Type", FromAttachmentDocumentType);

                        // Field "Prod. Order No.".
                        FromFieldRef := FromRecRef.Field(2);
                        FromNo := FromFieldRef.Value();
                        FromDocumentAttachment.SetRange("No.", FromNo);

                        // Field "Line No.".
                        FromFieldRef := FromRecRef.Field(3);
                        FromLineNo := FromFieldRef.Value();
                        FromDocumentAttachment.SetRange("Line No.", FromLineNo);
                    end;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnCopyAttachmentsOnAfterSetDocumentFlowFilter', '', false, false)]
    local procedure OnCopyAttachmentsOnAfterSetDocumentFlowFilter(var FromDocumentAttachment: Record "Document Attachment"; FromRecRef: RecordRef; ToRecRef: RecordRef);
    begin
        if ToRecRef.Number() <> 0 then
            case ToRecRef.Number() of
                Database::"Production Order":
                    if FromRecRef.Number() <> Database::"Production Order" then
                        FromDocumentAttachment.SetRange("Document Flow Production", true);
                Database::"Prod. Order Line":
                    if FromRecRef.Number() <> Database::"Prod. Order Line" then
                        FromDocumentAttachment.SetRange("Document Flow Production", true);
                Database::"Production BOM Header":
                    if FromRecRef.Number() <> Database::"Production BOM Header" then
                        FromDocumentAttachment.SetRange("Document Flow Production", true);
                Database::"Routing Header":
                    if FromRecRef.Number() <> Database::"Routing Header" then
                        FromDocumentAttachment.SetRange("Document Flow Production", true);
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnCopyAttachmentsOnAfterSetToParameters', '', false, false)]
    local procedure OnCopyAttachmentsOnAfterSetToParameters(var ToDocumentAttachment: Record "Document Attachment"; ToRecRef: RecordRef; var ToFieldRef: FieldRef; var ToNo: Code[20]; var ToLineNo: Integer; var ToAttachmentDocumentType: Enum "Attachment Document Type");
    begin
        if ToRecRef.Number() <> 0 then
            case ToRecRef.Number() of
                Database::"Production Order":
                    begin
                        // Field Status.
                        ToFieldRef := ToRecRef.Field(1);
                        ToAttachmentDocumentType := ToFieldRef.Value();
                        TransformAttachmentDocumentTypeValue(ToRecRef.Number(), ToAttachmentDocumentType);

                        // Field "Prod. Order No.".
                        ToFieldRef := ToRecRef.Field(2);
                        ToNo := ToFieldRef.Value();
                    end;
                Database::"Prod. Order Line":
                    begin
                        // Field Status.
                        ToFieldRef := ToRecRef.Field(1);
                        ToAttachmentDocumentType := ToFieldRef.Value();
                        TransformAttachmentDocumentTypeValue(ToRecRef.Number(), ToAttachmentDocumentType);

                        // Field "Prod. Order No.".
                        ToFieldRef := ToRecRef.Field(2);
                        ToNo := ToFieldRef.Value();

                        // Field "Line No.".
                        ToFieldRef := ToRecRef.Field(3);
                        ToLineNo := ToFieldRef.Value();
                    end;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnCopyAttachmentsOnAfterSetToDocumentFilters', '', false, false)]
    local procedure OnCopyAttachmentsOnAfterSetToDocumentFilters(var ToDocumentAttachment: Record "Document Attachment"; ToRecRef: RecordRef; ToAttachmentDocumentType: Enum "Attachment Document Type"; ToNo: Code[20]; ToLineNo: Integer)
    begin
        if ToRecRef.Number() <> 0 then
            case ToRecRef.Number() of
                Database::"Production Order":
                    ToDocumentAttachment.Validate("Document Type", ToAttachmentDocumentType);
                Database::"Prod. Order Line":
                    begin
                        ToDocumentAttachment.Validate("Document Type", ToAttachmentDocumentType);
                        ToDocumentAttachment.Validate("Line No.", ToLineNo);
                    end;
            end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure DocumentAttachmentFlow_ForProdOrderLineInsert(var Rec: Record "Prod. Order Line"; RunTrigger: Boolean)
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if (Rec."Line No." = 0) or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if Rec."Item No." = '' then
            exit;

        if not Item.Get(Rec."Item No.") then
            exit;

        DocumentAttachmentMgmt.CopyAttachments(Item, Rec);
        FeatureTelemetry.LogUptake('0000OC5', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000OCF', GetFeatureTelemetryName(), StrSubstNo(CopyAttachmentLbl, Item.TableCaption(), Rec.TableCaption()));

        if Rec."Routing No." <> '' then
            if RoutingHeader.Get(Rec."Routing No.") then begin
                DocumentAttachmentMgmt.CopyAttachments(RoutingHeader, Rec);
                FeatureTelemetry.LogUsage('0000OF7', GetFeatureTelemetryName(), StrSubstNo(CopyAttachmentLbl, RoutingHeader.TableCaption(), Rec.TableCaption()));
            end;

        if Rec."Production BOM No." <> '' then
            if ProductionBOMHeader.Get(Rec."Production BOM No.") then begin
                DocumentAttachmentMgmt.CopyAttachments(ProductionBOMHeader, Rec);
                FeatureTelemetry.LogUsage('0000OF8', GetFeatureTelemetryName(), StrSubstNo(CopyAttachmentLbl, ProductionBOMHeader.TableCaption(), Rec.TableCaption()));
            end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Line", OnAfterValidateEvent, "Item No.", false, false)]
    local procedure DocumentAttachmentFlow_ForProdOrderLineNoChange(var Rec: Record "Prod. Order Line"; var xRec: Record "Prod. Order Line")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if (Rec."Line No." = 0) or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."Item No." = xRec."Item No.") then
            exit;

        DocumentAttachmentMgmt.DeleteAttachedDocuments(xRec, false);
        FeatureTelemetry.LogUptake('0000OC6', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000OCH', GetFeatureTelemetryName(), StrSubstNo(DeleteAttachmentLbl, xRec.TableCaption()));

        DocumentAttachmentFlow_ForProdOrderLineInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Line", OnAfterValidateEvent, "Production BOM No.", false, false)]
    local procedure DocumentAttachmentFlow_ForProdOrderBomInsert(var Rec: Record "Prod. Order Line"; var xRec: Record "Prod. Order Line")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if (Rec."Line No." = 0) or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."Production BOM No." = xRec."Production BOM No.") then
            exit;

        DocumentAttachmentMgmt.DeleteAttachedDocuments(xRec, false);
        FeatureTelemetry.LogUptake('0000OC7', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000OCI', GetFeatureTelemetryName(), StrSubstNo(DeleteAttachmentLbl, xRec.TableCaption()));

        DocumentAttachmentFlow_ForProdOrderLineInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Line", OnAfterValidateEvent, "Routing No.", false, false)]
    local procedure DocumentAttachmentFlow_ForRoutingNoInsert(var Rec: Record "Prod. Order Line"; var xRec: Record "Prod. Order Line")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if (Rec."Line No." = 0) or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."Routing No." = xRec."Routing No.") then
            exit;

        DocumentAttachmentMgmt.DeleteAttachedDocuments(xRec, false);
        FeatureTelemetry.LogUptake('0000OC9', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000OCK', GetFeatureTelemetryName(), StrSubstNo(DeleteAttachmentLbl, xRec.TableCaption()));

        DocumentAttachmentFlow_ForProdOrderLineInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", OnAfterTransProdOrder, '', false, false)]
    local procedure DocumentAttachmentFlow_FromProdOrderToProdOrder(var FromProdOrder: Record "Production Order"; var ToProdOrder: Record "Production Order")
    begin
        if (ToProdOrder."No." = '') or IsNullGuid(ToProdOrder.SystemId) then
            exit;

        if ToProdOrder.IsTemporary() then
            exit;

        DocumentAttachmentMgmt.CopyAttachments(FromProdOrder, ToProdOrder);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTransformAttachmentDocumentTypeValue', '', false, false)]
    local procedure OnAfterTransformAttachmentDocumentTypeValue(TableNo: Integer; var AttachmentDocumentType: Enum "Attachment Document Type")
    begin
        TransformAttachmentDocumentTypeValue(TableNo, AttachmentDocumentType);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Prod. Order Status Management", 'OnAfterToProdOrderLineModify', '', false, false)]
    local procedure DocumentAttachmentFlow_FromProdOrderLineToProdOrderLine(var FromProdOrderLine: Record "Prod. Order Line"; var ToProdOrderLine: Record "Prod. Order Line")
    begin
        if ToProdOrderLine.IsTemporary() then
            exit;

        DocumentAttachmentMgmt.DeleteAttachedDocuments(ToProdOrderLine, false);
        DocumentAttachmentMgmt.CopyAttachments(FromProdOrderLine, ToProdOrderLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Order", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteProductionOrder(var Rec: Record "Production Order"; RunTrigger: Boolean)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, false);
        FeatureTelemetry.LogUptake('0000OCB', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000OCM', GetFeatureTelemetryName(), StrSubstNo(DeleteAttachmentLbl, Rec.TableCaption()));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Prod. Order Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteProdOrderLine(var Rec: Record "Prod. Order Line"; RunTrigger: Boolean)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, false);
        FeatureTelemetry.LogUptake('0000OCC', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000OCN', GetFeatureTelemetryName(), StrSubstNo(DeleteAttachmentLbl, Rec.TableCaption()));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Routing Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteRoutingHeader(var Rec: Record "Routing Header"; RunTrigger: Boolean)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, false);
        FeatureTelemetry.LogUptake('0000OCD', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000OCO', GetFeatureTelemetryName(), StrSubstNo(DeleteAttachmentLbl, Rec.TableCaption()));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production BOM Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteProductionBOM(var Rec: Record "Production BOM Header"; RunTrigger: Boolean)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, false);
        FeatureTelemetry.LogUptake('0000OCE', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000OCP', GetFeatureTelemetryName(), StrSubstNo(DeleteAttachmentLbl, Rec.TableCaption()));
    end;

    local procedure TransformAttachmentDocumentTypeValue(TableNo: Integer; var AttachmentDocumentType: Enum "Attachment Document Type")
    begin
        if TableNo <> 0 then
            case TableNo of
                Database::"Production Order", Database::"Prod. Order Line":
                    case AttachmentDocumentType.AsInteger() of
                        0:
                            AttachmentDocumentType := AttachmentDocumentType::"Simulated Production Order";
                        1:
                            AttachmentDocumentType := AttachmentDocumentType::"Planned Production Order";
                        2:
                            AttachmentDocumentType := AttachmentDocumentType::"Firm Planned Production Order";
                        3:
                            AttachmentDocumentType := AttachmentDocumentType::"Released Production Order";
                        4:
                            AttachmentDocumentType := AttachmentDocumentType::"Finished Production Order";
                    end;
            end;
    end;

    local procedure GetFeatureTelemetryName(): Text
    begin
        exit(ProductionDocumentAttachmentFeatureTelemetryNameLbl);
    end;
}
