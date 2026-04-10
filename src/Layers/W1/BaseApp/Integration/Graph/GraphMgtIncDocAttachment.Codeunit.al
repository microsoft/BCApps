// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;
using System.Reflection;

codeunit 5509 "Graph Mgt - Inc Doc Attachment"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm,
                  TableData "Purch. Inv. Header" = rm,
                  TableData "Purch. Cr. Memo Hdr." = rm,
                  TableData "G/L Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        AttachmentCategoryLbl: Label 'AL Attachment', Locked = true;
        NoPermissionErr: Label 'No permission to update a related document (table %1).', Comment = '%1=table number that caused the error', Locked = true;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document Attachment", 'OnAfterInsertEvent', '', false, false)]
    local procedure HandleOnAfterInsert(var Rec: Record "Incoming Document Attachment"; RunTrigger: Boolean)
    begin
        UpdateRelatedDocument(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document Attachment", 'OnAfterModifyEvent', '', false, false)]
    local procedure HandleOnAfterUpdate(var Rec: Record "Incoming Document Attachment"; var xRec: Record "Incoming Document Attachment"; RunTrigger: Boolean)
    begin
        UpdateRelatedDocument(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document Attachment", 'OnAfterRenameEvent', '', false, false)]
    local procedure HandleOnAfterRename(var Rec: Record "Incoming Document Attachment"; var xRec: Record "Incoming Document Attachment"; RunTrigger: Boolean)
    begin
        UpdateRelatedDocument(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document Attachment", 'OnAfterDeleteEvent', '', false, false)]
    local procedure HandleOnAfterDelete(var Rec: Record "Incoming Document Attachment"; RunTrigger: Boolean)
    begin
        UpdateRelatedDocument(Rec);
    end;

    local procedure UpdateRelatedDocument(var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    var
        IncomingDocument: Record "Incoming Document";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        DataTypeManagement: Codeunit "Data Type Management";
        RelatedRecRef: RecordRef;
        RelatedDocument: Variant;
    begin
        if IncomingDocumentAttachment.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled()) then
            exit;

        if not IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.") then
            exit;

        if not IncomingDocument.GetRecord(RelatedDocument) then
            exit;

        if not DataTypeManagement.GetRecordRef(RelatedDocument, RelatedRecRef) then
            exit;

        if not RelatedRecRef.WritePermission then begin
            Session.LogMessage('00006WH', StrSubstNo(NoPermissionErr, RelatedRecRef.Number), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AttachmentCategoryLbl);
            exit;
        end;

        RelatedRecRef.Modify();
    end;
}

