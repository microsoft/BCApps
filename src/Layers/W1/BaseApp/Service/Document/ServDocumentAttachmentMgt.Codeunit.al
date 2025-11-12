// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Foundation.Attachment;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Service.Contract;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Posting;

codeunit 6459 "Serv. Document Attachment Mgt."
{
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnAfterIsPostedDocument', '', false, false)]
    local procedure OnInsertOrderTrackingEntry(TableID: Integer; var Posted: Boolean)
    begin
        if TableID in [Database::"Service Invoice Header", Database::"Service Cr.Memo Header"] then
            Posted := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterIsServiceDocumentFlow', '', false, false)]
    local procedure OnAfterIsServiceDocumentFlow(TableNo: Integer; var IsDocumentFlow: Boolean)
    begin
        if IsServiceDocumentFlow(TableNo) then
            IsDocumentFlow := true;
    end;

    internal procedure IsServiceDocumentFlow(TableNo: Integer): Boolean
    begin
        exit(TableNo in
            [Database::Customer,
             Database::"Service Header",
             Database::"Service Line",
             Database::"Service Invoice Header",
             Database::"Service Invoice Line",
             Database::"Service Cr.Memo Header",
             Database::"Service Cr.Memo Line",
             Database::"Service Contract Header",
             Database::"Service Contract Line",
             Database::Item,
             Database::"Service Item"]);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterGetRefTable', '', false, false)]
    local procedure OnAfterGetRefTable(var RecRef: RecordRef; DocumentAttachment: Record "Document Attachment")
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        case DocumentAttachment."Table ID" of
            Database::"Service Item":
                begin
                    RecRef.Open(Database::"Service Item");
                    if ServiceItem.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(ServiceItem);
                end;
            Database::"Service Header":
                begin
                    RecRef.Open(Database::"Service Header");
                    if ServiceHeader.Get(DocumentAttachment."Document Type", DocumentAttachment."No.") then
                        RecRef.GetTable(ServiceHeader);
                end;
            Database::"Service Line":
                begin
                    RecRef.Open(Database::"Service Line");
                    if ServiceLine.Get(DocumentAttachment."Document Type", DocumentAttachment."No.", DocumentAttachment."Line No.") then
                        RecRef.GetTable(ServiceLine);
                end;
            Database::"Service Invoice Header":
                begin
                    RecRef.Open(Database::"Service Invoice Header");
                    if ServiceInvoiceHeader.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(ServiceInvoiceHeader);
                end;
            Database::"Service Cr.Memo Header":
                begin
                    RecRef.Open(Database::"Service Cr.Memo Header");
                    if ServiceCrMemoHeader.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(ServiceCrMemoHeader);
                end;
            Database::"Service Contract Header":
                begin
                    RecRef.Open(Database::"Service Contract Header");
                    case DocumentAttachment."Document Type" of
                        DocumentAttachment."Document Type"::"Service Contract":
                            ServiceContractHeader."Contract Type" := ServiceContractHeader."Contract Type"::Contract;
                        DocumentAttachment."Document Type"::"Service Contract Quote":
                            ServiceContractHeader."Contract Type" := ServiceContractHeader."Contract Type"::Quote;
                    end;
                    if ServiceContractHeader.Get(ServiceContractHeader."Contract Type", DocumentAttachment."No.") then
                        RecRef.GetTable(ServiceContractHeader);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnSetRelatedAttachmentsFilterOnBeforeSetTableIdFilter', '', false, false)]
    local procedure OnSetRelatedAttachmentsFilterOnBeforeSetTableIdFilter(TableNo: Integer; var RelatedTable: Integer);
    begin
        case TableNo of
            Database::"Service Header":
                RelatedTable := Database::"Service Line";
            Database::"Service Invoice Header":
                RelatedTable := Database::"Service Invoice Line";
            Database::"Service Cr.Memo Header":
                RelatedTable := Database::"Service Cr.Memo Line";
            Database::"Service Contract Header":
                RelatedTable := Database::"Service Contract Line";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableIsDocument', '', false, false)]
    local procedure OnAfterIsTableDocument(TableNo: Integer; var IsDocument: Boolean)
    begin
        if IsDocument then
            exit;

        IsDocument := TableNo in [
                                    Database::"Service Header",
                                    Database::"Service Line",
                                    Database::"Service Invoice Header",
                                    Database::"Service Invoice Line",
                                    Database::"Service Cr.Memo Header",
                                    Database::"Service Cr.Memo Line",
                                    Database::"Service Contract Header",
                                    Database::"Service Contract Line"];
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableHasNumberFieldPrimaryKey', '', false, false)]
    local procedure OnAfterTableHasNumberFieldPrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    begin
        case TableNo of
            Database::"Service Item",
            Database::"Service Contract Header":
                begin
                    FieldNo := 1;
                    Result := true;
                end;
            Database::"Service Header",
            Database::"Service Line",
            Database::"Service Invoice Header",
            Database::"Service Invoice Line",
            Database::"Service Cr.Memo Header",
            Database::"Service Cr.Memo Line":
                begin
                    FieldNo := 3;
                    Result := true;
                end;
            Database::"Service Contract Line":
                begin
                    FieldNo := 2;
                    Result := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableHasDocTypePrimaryKey', '', false, false)]
    local procedure OnAfterTableHasDocTypePrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    begin
        case TableNo of
            Database::"Service Header",
            Database::"Service Line",
            Database::"Service Contract Line":
                begin
                    FieldNo := 1;
                    Result := true;
                end;
            Database::"Service Contract Header":
                begin
                    FieldNo := 2;
                    Result := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableHasLineNumberPrimaryKey', '', false, false)]
    local procedure OnAfterTableHasLineNumberPrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    begin
        case TableNo of
            Database::"Service Line",
            Database::"Service Invoice Line",
            Database::"Service Cr.Memo Line":
                begin
                    FieldNo := 4;
                    Result := true;
                end;
            Database::"Service Contract Line":
                begin
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
        case FromRecRef.Number() of
            Database::"Service Item":
                begin
                    FromFieldRef := FromRecRef.Field(1);
                    FromNo := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("No.", FromNo);
                end;
            Database::"Service Header":
                begin
                    FromFieldRef := FromRecRef.Field(1);
                    FromAttachmentDocumentType := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("Document Type", FromAttachmentDocumentType);
                    FromFieldRef := FromRecRef.Field(3);
                    FromNo := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("No.", FromNo);
                end;
            Database::"Service Line":
                begin
                    FromFieldRef := FromRecRef.Field(1);
                    FromAttachmentDocumentType := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("Document Type", FromAttachmentDocumentType);
                    FromFieldRef := FromRecRef.Field(3);
                    FromNo := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("No.", FromNo);
                    FromFieldRef := FromRecRef.Field(4);
                    FromLineNo := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("Line No.", FromLineNo);
                end;
            Database::"Service Contract Header":
                begin
                    FromFieldRef := FromRecRef.Field(2);
                    FromAttachmentDocumentType := FromFieldRef.Value();
                    TransformAttachmentDocumentTypeValue(FromRecRef.Number(), FromAttachmentDocumentType);
                    FromDocumentAttachment.SetRange("Document Type", FromAttachmentDocumentType);
                    FromFieldRef := FromRecRef.Field(1);
                    FromNo := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("No.", FromNo);
                end;
            Database::"Service Contract Line":
                begin
                    FromFieldRef := FromRecRef.Field(1);
                    FromAttachmentDocumentType := FromFieldRef.Value();
                    TransformAttachmentDocumentTypeValue(FromRecRef.Number(), FromAttachmentDocumentType);
                    FromDocumentAttachment.SetRange("Document Type", FromAttachmentDocumentType);
                    FromFieldRef := FromRecRef.Field(2);
                    FromNo := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("No.", FromNo);
                    FromFieldRef := FromRecRef.Field(3);
                    FromLineNo := FromFieldRef.Value();
                    FromDocumentAttachment.SetRange("Line No.", FromLineNo);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTransformAttachmentDocumentTypeValue', '', false, false)]
    local procedure OnAfterTransformAttachmentDocumentTypeValue(TableNo: Integer; var AttachmentDocumentType: Enum "Attachment Document Type")
    begin
        TransformAttachmentDocumentTypeValue(TableNo, AttachmentDocumentType);
    end;

    local procedure TransformAttachmentDocumentTypeValue(TableNo: Integer; var AttachmentDocumentType: Enum "Attachment Document Type")
    begin
        case TableNo of
            Database::"Service Contract Header", Database::"Service Contract Line":
                case AttachmentDocumentType of
                    AttachmentDocumentType::Quote:
                        AttachmentDocumentType := AttachmentDocumentType::"Service Contract Quote";
                    AttachmentDocumentType::Order:
                        AttachmentDocumentType := AttachmentDocumentType::"Service Contract";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnCopyAttachmentsOnAfterSetDocumentFlowFilter', '', false, false)]
    local procedure OnCopyAttachmentsOnAfterSetDocumentFlowFilter(var FromDocumentAttachment: Record "Document Attachment"; FromRecRef: RecordRef; ToRecRef: RecordRef);
    begin
        case ToRecRef.Number() of
            Database::"Service Line":
                if FromRecRef.Number() <> Database::"Service Line" then
                    FromDocumentAttachment.SetRange("Document Flow Service", true);
            Database::"Service Header":
                if FromRecRef.Number() <> Database::"Service Header" then
                    FromDocumentAttachment.SetRange("Document Flow Service", true);
            Database::"Service Contract Line":
                if FromRecRef.Number() <> Database::"Service Contract Line" then
                    FromDocumentAttachment.SetRange("Document Flow Service", true);
            Database::"Service Contract Header":
                if FromRecRef.Number() <> Database::"Service Contract Header" then
                    FromDocumentAttachment.SetRange("Document Flow Service", true);
            Database::"Service Item":
                if FromRecRef.Number() <> Database::"Service Item" then
                    FromDocumentAttachment.SetRange("Document Flow Service", true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnCopyAttachmentsOnAfterSetToParameters', '', false, false)]
    local procedure OnCopyAttachmentsOnAfterSetToParameters(var ToDocumentAttachment: Record "Document Attachment"; ToRecRef: RecordRef; var ToFieldRef: FieldRef; var ToNo: Code[20]; var ToLineNo: Integer; var ToAttachmentDocumentType: Enum "Attachment Document Type");
    begin
        case ToRecRef.Number() of
            Database::"Service Header":
                begin
                    ToFieldRef := ToRecRef.Field(1);
                    ToAttachmentDocumentType := ToFieldRef.Value();

                    ToFieldRef := ToRecRef.Field(3);
                    ToNo := ToFieldRef.Value();
                end;
            Database::"Service Line":
                begin
                    ToFieldRef := ToRecRef.Field(1);
                    ToAttachmentDocumentType := ToFieldRef.Value();

                    ToFieldRef := ToRecRef.Field(3);
                    ToNo := ToFieldRef.Value();

                    ToFieldRef := ToRecRef.Field(4);
                    ToLineNo := ToFieldRef.Value();
                end;
            Database::"Service Contract Header":
                begin
                    ToFieldRef := ToRecRef.Field(2);
                    ToAttachmentDocumentType := ToFieldRef.Value();
                    TransformAttachmentDocumentTypeValue(ToRecRef.Number(), ToAttachmentDocumentType);

                    ToFieldRef := ToRecRef.Field(1);
                    ToNo := ToFieldRef.Value();
                end;
            Database::"Service Contract Line":
                begin
                    ToFieldRef := ToRecRef.Field(1);
                    ToAttachmentDocumentType := ToFieldRef.Value();
                    TransformAttachmentDocumentTypeValue(ToRecRef.Number(), ToAttachmentDocumentType);

                    ToFieldRef := ToRecRef.Field(2);
                    ToNo := ToFieldRef.Value();

                    ToFieldRef := ToRecRef.Field(3);
                    ToLineNo := ToFieldRef.Value();
                end;
            Database::"Service Item":
                begin
                    ToFieldRef := ToRecRef.Field(1);
                    ToNo := ToFieldRef.Value();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnCopyAttachmentsOnAfterSetToDocumentFilters', '', false, false)]
    local procedure OnCopyAttachmentsOnAfterSetToDocumentFilters(var ToDocumentAttachment: Record "Document Attachment"; ToRecRef: RecordRef; ToAttachmentDocumentType: Enum "Attachment Document Type"; ToNo: Code[20]; ToLineNo: Integer)
    begin
        case ToRecRef.Number() of
            Database::"Service Header",
            Database::"Service Contract Header":
                ToDocumentAttachment.Validate("Document Type", ToAttachmentDocumentType);
            Database::"Service Line",
            Database::"Service Contract Line":
                begin
                    ToDocumentAttachment.Validate("Document Type", ToAttachmentDocumentType);
                    ToDocumentAttachment.Validate("Line No.", ToLineNo);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableIsDocumentHeader', '', false, false)]
    local procedure OnAfterTableIsDocumentHeader(TableNo: Integer; var IsHeader: Boolean)
    begin
        if TableNo = Database::"Service Header" then
            IsHeader := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableIsDocumentLine', '', false, false)]
    local procedure OnAfterTableIsDocumentLine(TableNo: Integer; var IsLine: Boolean)
    begin
        if TableNo = Database::"Service Line" then
            IsLine := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableIsEntity', '', false, false)]
    local procedure OnAfterTableIsEntity(TableNo: Integer; var IsEntity: Boolean)
    begin
        if TableNo = Database::"Service Item" then
            IsEntity := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnCopyAttachmentsForPostedDocsLinesOnAfterSetFromFilters', '', false, false)]
    local procedure OnCopyAttachmentsForPostedDocsLinesOnAfterSetFromFilters(FromRecRef: RecordRef; var FromDocumentAttachmentLine: Record "Document Attachment")
    begin
        case FromRecRef.Number() of
            Database::"Service Header":
                FromDocumentAttachmentLine.SetRange("Table ID", Database::"Service Line");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnCopyAttachmentsForPostedDocsLinesOnAfterSetToTableID', '', false, false)]
    local procedure OnCopyAttachmentsForPostedDocsLinesOnAfterSetToTableID(ToRecRef: RecordRef; var ToDocumentAttachmentLine: Record "Document Attachment")
    begin
        case ToRecRef.Number of
            Database::"Service Invoice Header":
                ToDocumentAttachmentLine.Validate("Table ID", Database::"Service Invoice Line");
            Database::"Service Cr.Memo Header":
                ToDocumentAttachmentLine.Validate("Table ID", Database::"Service Cr.Memo Line");
        end;
    end;

    #region [Service Management event subscribers]
    [EventSubscriber(ObjectType::Table, Database::"Service Item", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteServiceItem(var Rec: Record "Service Item"; RunTrigger: Boolean)
    begin
        DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item", 'OnAfterRenameEvent', '', false, false)]
    local procedure MoveAttachedDocumentsOnAfterRenameServiceItem(var Rec: Record "Service Item"; var xRec: Record "Service Item"; RunTrigger: Boolean)
    var
        MoveFromRecordRef: RecordRef;
        MoveToRecordRef: RecordRef;
    begin
        // Moves attached docs when an Service Item record is renamed [When service item no. is changed] from old to new rec
        MoveFromRecordRef.GetTable(xRec);
        MoveToRecordRef.GetTable(Rec);

        DocumentAttachmentMgmt.MoveAttachmentsWithinSameRecordType(MoveFromRecordRef, MoveToRecordRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteServiceHeader(var Rec: Record "Service Header"; RunTrigger: Boolean)
    begin
        DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteServiceLine(var Rec: Record "Service Line"; RunTrigger: Boolean)
    begin
        DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteServiceInvoiceHeader(var Rec: Record "Service Invoice Header"; RunTrigger: Boolean)
    begin
        DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteServiceInvoiceLine(var Rec: Record "Service Invoice Line"; RunTrigger: Boolean)
    begin
        DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteServiceCreditMemoHeader(var Rec: Record "Service Cr.Memo Header"; RunTrigger: Boolean)
    begin
        DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteServiceCreditMemoLine(var Rec: Record "Service Cr.Memo Line"; RunTrigger: Boolean)
    begin
        DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteServiceContractHeader(var Rec: Record "Service Contract Header"; RunTrigger: Boolean)
    begin
        DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteAttachedDocumentsOnAfterDeleteServiceContractLine(var Rec: Record "Service Contract Line"; RunTrigger: Boolean)
    begin
        DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item", 'OnAfterInsertEvent', '', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceItemInsert(var Rec: Record "Service Item"; RunTrigger: Boolean)
    var
        Item: Record Item;
    begin
        if (Rec."No." = '') or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if Rec."Item No." = '' then
            exit;
        if not Item.Get(Rec."Item No.") then
            exit;

        DocumentAttachmentMgmt.CopyAttachments(Item, Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item", 'OnAfterValidateEvent', 'Item No.', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceItemItemNoChange(var Rec: Record "Service Item"; var xRec: Record "Service Item"; CurrFieldNo: Integer)
    begin
        if (Rec."No." = '') or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."Item No." <> xRec."Item No.") and (xRec."Item No." <> '') then
            DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, false);

        DocumentAttachmentFlow_ForServiceItemInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceHeaderInsert(var Rec: Record "Service Header"; RunTrigger: Boolean)
    var
        Customer: Record Customer;
    begin
        if (Rec."No." = '') or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if Rec."Customer No." = '' then
            exit;
        if not Customer.Get(Rec."Customer No.") then
            exit;

        DocumentAttachmentMgmt.CopyAttachments(Customer, Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterValidateEvent', 'Customer No.', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceHeaderCustomerNoChange(var Rec: Record "Service Header"; var xRec: Record "Service Header"; CurrFieldNo: Integer)
    begin
        if (Rec."No." = '') or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."Customer No." <> xRec."Customer No.") and (xRec."Customer No." <> '') then
            DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, true);

        DocumentAttachmentFlow_ForServiceHeaderInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ServContractManagement, 'OnCreateServHeaderOnAfterCopyFromCustomer', '', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceHeaderCustomerChange_OnCreateServHeaderOnAfterCopyFromCustomer(var ServiceHeader: Record "Service Header"; ServiceContract: Record "Service Contract Header"; Customer: Record Customer)
    begin
        if (ServiceHeader."No." = '') or IsNullGuid(ServiceHeader.SystemId) then
            exit;

        if ServiceHeader."Customer No." = '' then
            exit;

        if ServiceHeader.IsTemporary() then
            exit;

        DocumentAttachmentMgmt.DeleteAttachedDocuments(ServiceHeader, false);

        DocumentAttachmentFlow_ForServiceHeaderInsert(ServiceHeader, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ServContractManagement, 'OnCreateOrGetCreditHeaderOnAfterCopyFromCustomer', '', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceHeaderCustomerChange_OnCreateOrGetCreditHeaderOnAfterCopyFromCustomer(var ServiceHeader: Record "Service Header"; ServiceContract: Record "Service Contract Header"; Customer: Record Customer)
    begin
        DocumentAttachmentFlow_ForServiceHeaderCustomerChange_OnCreateServHeaderOnAfterCopyFromCustomer(ServiceHeader, ServiceContract, Customer);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceLineInsert(var Rec: Record "Service Line"; RunTrigger: Boolean)
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
    begin
        if (Rec."Line No." = 0) or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if Rec."Service Item No." <> '' then
            if ServiceItem.Get(Rec."Service Item No.") then
                DocumentAttachmentMgmt.CopyAttachments(ServiceItem, Rec);

        if (Rec.Type = Rec.Type::Item) and (Rec."No." <> '') then
            if Item.Get(Rec."No.") then
                DocumentAttachmentMgmt.CopyAttachments(Item, Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterValidateEvent', 'Service Item No.', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceLineServiceItemNoChange(var Rec: Record "Service Line"; var xRec: Record "Service Line"; CurrFieldNo: Integer)
    begin
        if (Rec."Line No." = 0) or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."Service Item No." <> xRec."Service Item No.") and (xRec."Service Item No." <> '') then
            DocumentAttachmentMgmt.DeleteAttachedDocuments(xRec, false);

        DocumentAttachmentFlow_ForServiceLineInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterValidateEvent', 'Service Item Line No.', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceLineServiceItemLineNoChange(var Rec: Record "Service Line"; var xRec: Record "Service Line"; CurrFieldNo: Integer)
    begin
        if (Rec."Line No." = 0) or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."Service Item Line No." <> xRec."Service Item Line No.") and (xRec."Service Item Line No." <> 0) then
            DocumentAttachmentMgmt.DeleteAttachedDocuments(xRec, false);

        if Rec."Service Item No." <> '' then
            DocumentAttachmentFlow_ForServiceLineInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Line", 'OnAfterValidateEvent', 'No.', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceLineNoChange(var Rec: Record "Service Line"; var xRec: Record "Service Line"; CurrFieldNo: Integer)
    begin
        if (Rec."Line No." = 0) or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."No." <> xRec."No.") and (xRec."No." <> '') then
            DocumentAttachmentMgmt.DeleteAttachedDocuments(xRec, false);

        DocumentAttachmentFlow_ForServiceLineInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Quote to Order", 'OnBeforeServiceHeaderOrderModify', '', false, false)]
    local procedure DocumentAttachmentFlow_FromServiceQuoteHeaderToServiceOrderHeader(var ServiceOrderHeader: Record "Service Header"; ServiceQuoteHeader: Record "Service Header")
    begin
        if (ServiceQuoteHeader."No." = '') or IsNullGuid(ServiceQuoteHeader.SystemId) then
            exit;

        if ServiceQuoteHeader.IsTemporary() then
            exit;

        if (ServiceOrderHeader."No." = '') or IsNullGuid(ServiceOrderHeader.SystemId) then
            exit;

        if ServiceOrderHeader.IsTemporary() then
            exit;

        DocumentAttachmentMgmt.DeleteAttachedDocuments(ServiceOrderHeader, false);

        DocumentAttachmentMgmt.CopyAttachments(ServiceQuoteHeader, ServiceOrderHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Quote to Order", 'OnAfterServOrderLineInsert', '', false, false)]
    local procedure DocumentAttachmentFlow_FromServiceQuoteLineToServiceOrderLine(var ServiceOrderLine2: Record "Service Line"; ServiceOrderLine: Record "Service Line")
    begin
        // ServiceOrderLine - quote line
        // ServiceOrderLine2 - order line
        if (ServiceOrderLine2."No." = '') or IsNullGuid(ServiceOrderLine2.SystemId) then
            exit;

        if ServiceOrderLine2.IsTemporary() then
            exit;

        DocumentAttachmentMgmt.DeleteAttachedDocuments(ServiceOrderLine2, false);

        DocumentAttachmentMgmt.CopyAttachments(ServiceOrderLine, ServiceOrderLine2);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnFinalizeOnBeforeDeleteHeaderAndLines', '', false, false)]
    local procedure CopyDocumentAttachmentsToPostedServiceDocument(var ServiceHeader: Record "Service Header")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        FromRecordRef: RecordRef;
        ToRecordRef: RecordRef;
    begin
        // Triggered when a last posted service invoice / cr. memo is created
        if ServiceHeader.IsTemporary() then
            exit;

        if (ServiceHeader."Last Posting No." = '') and (ServiceHeader."No." = '') then
            exit;

        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::"Order", ServiceHeader."Document Type"::"Invoice":
                begin
                    if ServiceHeader."Last Posting No." = '' then begin
                        if not ServiceInvoiceHeader.Get(ServiceHeader."No.") then
                            exit;
                    end else
                        if not ServiceInvoiceHeader.Get(ServiceHeader."Last Posting No.") then
                            exit;
                    FromRecordRef.GetTable(ServiceHeader);
                    ToRecordRef.GetTable(ServiceInvoiceHeader);
                    DocumentAttachmentMgmt.CopyAttachmentsForPostedDocs(FromRecordRef, ToRecordRef);
                end;
            ServiceHeader."Document Type"::"Credit Memo":
                begin
                    if ServiceHeader."Last Posting No." = '' then begin
                        if not ServiceCrMemoHeader.Get(ServiceHeader."No.") then
                            exit;
                    end else
                        if not ServiceCrMemoHeader.Get(ServiceHeader."Last Posting No.") then
                            exit;
                    FromRecordRef.GetTable(ServiceHeader);
                    ToRecordRef.GetTable(ServiceCrMemoHeader);
                    DocumentAttachmentMgmt.CopyAttachmentsForPostedDocs(FromRecordRef, ToRecordRef);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceContractHeaderInsert(var Rec: Record "Service Contract Header"; RunTrigger: Boolean)
    var
        Customer: Record Customer;
    begin
        if (Rec."Contract No." = '') or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if Rec."Customer No." = '' then
            exit;
        if not Customer.Get(Rec."Customer No.") then
            exit;

        DocumentAttachmentMgmt.CopyAttachments(Customer, Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Header", 'OnAfterValidateEvent', 'Customer No.', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceContractHeaderCustomerNoChange(var Rec: Record "Service Contract Header"; var xRec: Record "Service Contract Header"; CurrFieldNo: Integer)
    begin
        if (Rec."Contract No." = '') or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."Customer No." <> xRec."Customer No.") and (xRec."Customer No." <> '') then
            DocumentAttachmentMgmt.DeleteAttachedDocuments(Rec, true);

        DocumentAttachmentFlow_ForServiceContractHeaderInsert(Rec, true);
    end;

#if not CLEAN25
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ServContractManagement, 'OnChangeCustNoOnServContractOnAfterGetCust', '', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceContractHeaderCustomerChange_OnChangeCustNoOnServContractOnAfterGetCust(Customer: Record Customer; var ServiceContractHeader: Record "Service Contract Header"; var CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit"; var IsHandled: Boolean)
    begin
        if (ServiceContractHeader."Contract No." = '') or IsNullGuid(ServiceContractHeader.SystemId) then
            exit;

        if ServiceContractHeader.IsTemporary() then
            exit;

        DocumentAttachmentMgmt.DeleteAttachedDocuments(ServiceContractHeader, true);

        if ServiceContractHeader."Customer No." = '' then
            exit;

        DocumentAttachmentFlow_ForServiceContractHeaderInsert(ServiceContractHeader, true);
    end;
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ServContractManagement, 'OnChangeCustNoOnServContractOnAfterGetCustomer', '', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceContractHeaderCustomerChange_OnChangeCustNoOnServContractOnAfterGetCustomer(Customer: Record Customer; var ServiceContractHeader: Record "Service Contract Header"; var ServCheckCreditLimit: Codeunit "Serv. Check Credit Limit"; var IsHandled: Boolean)
    begin
        if (ServiceContractHeader."Contract No." = '') or IsNullGuid(ServiceContractHeader.SystemId) then
            exit;

        if ServiceContractHeader.IsTemporary() then
            exit;

        DocumentAttachmentMgmt.DeleteAttachedDocuments(ServiceContractHeader, true);

        if ServiceContractHeader."Customer No." = '' then
            exit;

        DocumentAttachmentFlow_ForServiceContractHeaderInsert(ServiceContractHeader, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceContractLineInsert(var Rec: Record "Service Contract Line"; RunTrigger: Boolean)
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
    begin
        if (Rec."Line No." = 0) or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if Rec."Service Item No." <> '' then
            if ServiceItem.Get(Rec."Service Item No.") then
                DocumentAttachmentMgmt.CopyAttachments(ServiceItem, Rec);

        if Rec."Item No." <> '' then
            if Item.Get(Rec."Item No.") then
                DocumentAttachmentMgmt.CopyAttachments(Item, Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Line", 'OnAfterValidateEvent', 'Service Item No.', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceContractLineServiceItemNoChange(var Rec: Record "Service Contract Line"; var xRec: Record "Service Contract Line"; CurrFieldNo: Integer)
    begin
        if (Rec."Line No." = 0) or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."Service Item No." <> xRec."Service Item No.") and (xRec."Service Item No." <> '') then
            DocumentAttachmentMgmt.DeleteAttachedDocuments(xRec, false);

        DocumentAttachmentFlow_ForServiceContractLineInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Contract Line", 'OnAfterValidateEvent', 'Item No.', false, false)]
    local procedure DocumentAttachmentFlow_ForServiceContractLineItemNoChange(var Rec: Record "Service Contract Line"; var xRec: Record "Service Contract Line"; CurrFieldNo: Integer)
    begin
        if (Rec."Line No." = 0) or IsNullGuid(Rec.SystemId) then
            exit;

        if Rec.IsTemporary() then
            exit;

        if (Rec."Item No." <> xRec."Item No.") and (xRec."Item No." <> '') then
            DocumentAttachmentMgmt.DeleteAttachedDocuments(xRec, false);

        DocumentAttachmentFlow_ForServiceContractLineInsert(Rec, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SignServContractDoc", 'OnAfterToServContractHeaderInsert', '', false, false)]
    local procedure DocumentAttachmentFlow_FromServiceContractQuoteHeaderToServiceContractHeader(var ToServiceContractHeader: Record "Service Contract Header"; FromServiceContractHeader: Record "Service Contract Header")
    begin
        if (FromServiceContractHeader."Contract No." = '') or IsNullGuid(FromServiceContractHeader.SystemId) then
            exit;

        if FromServiceContractHeader.IsTemporary() then
            exit;

        if (ToServiceContractHeader."Contract No." = '') or IsNullGuid(ToServiceContractHeader.SystemId) then
            exit;

        if ToServiceContractHeader.IsTemporary() then
            exit;

        DocumentAttachmentMgmt.DeleteAttachedDocuments(ToServiceContractHeader, false);

        DocumentAttachmentMgmt.CopyAttachments(FromServiceContractHeader, ToServiceContractHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SignServContractDoc", 'OnAfterToServContractLineInsert', '', false, false)]
    local procedure DocumentAttachmentFlow_FromServiceContractQuoteLineToServiceContractLine(var ToServiceContractLine: Record "Service Contract Line"; FromServiceContractLine: Record "Service Contract Line")
    begin
        if (ToServiceContractLine."Contract No." = '') or IsNullGuid(ToServiceContractLine.SystemId) then
            exit;

        if ToServiceContractLine.IsTemporary() then
            exit;

        DocumentAttachmentMgmt.DeleteAttachedDocuments(ToServiceContractLine, false);

        DocumentAttachmentMgmt.CopyAttachments(FromServiceContractLine, ToServiceContractLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Service Contract Mgt.", 'OnAfterProcessServiceContractLine', '', false, false)]
    local procedure DocumentAttachmentFlow_OnServiceContractLineCopy(var ToServiceContractLine: Record "Service Contract Line"; FromServiceContractLine: Record "Service Contract Line")
    begin
        DocumentAttachmentFlow_FromServiceContractQuoteLineToServiceContractLine(ToServiceContractLine, FromServiceContractLine);
    end;
    #endregion [Service Management event subscribers]
}
