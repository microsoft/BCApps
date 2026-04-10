// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Attachment;
using Microsoft.HumanResources.Employee;
using Microsoft.Integration.Entity;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System;
using System.Environment;
using System.IO;
using System.Reflection;
using System.Utilities;

codeunit 5503 "Graph Mgt - Attachment Buffer"
{
    Permissions = TableData "Incoming Document Attachment" = rimd, tabledata "Tenant Media" = r;

    trigger OnRun()
    begin
    end;

    var
        DocumentIDNotSpecifiedForAttachmentsErr: Label 'You must specify a document id to get the attachments.';
        DocumentIDorTypeNotSpecifiedForAttachmentsErr: Label 'You must specify a document id and a document type to get the attachments.';
        DocumentDoesNotExistErr: Label 'No document with the specified ID exists.';
        MultipleDocumentsFoundForIdErr: Label 'Multiple documents have been found for the specified criteria.';
        CannotInsertAnAttachmentThatAlreadyExistsErr: Label 'You cannot insert an attachment because an attachment already exists.';
        CannotModifyAnAttachmentThatDoesntExistErr: Label 'You cannot modify an attachment that does not exist.';
        CannotDeleteAnAttachmentThatDoesntExistErr: Label 'You cannot delete an attachment that does not exist.';
        EmptyGuid: Guid;
        AttachmentLinkedToAnotherDocumentErr: Label 'The attachment is linked to another document than you specified.';
        DocumentTypeInvalidErr: Label 'Document type is not valid.';
        UnsopportedDocumentTypeErr: Label 'The selected Document type %1 is not supported.', Comment = '%1 name of document type, e.g. Journal, Cusotmer, Item, Sales Invoice...';
        CannotFindParentKeyErr: Label 'Cannot find the No. field on the parent record. Double check if the proper type is provided.';
        AttachmentLoadLimitExceededErr: Label 'Loading more than %1 attachments is not supported. Set a filter to reduce the response size.', Comment = '%1 - an integer';

    [Scope('Cloud')]
    procedure LoadDocumentAttachments(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; DocumentFilter: Text)
    var
        DocumentAttachment: Record "Document Attachment";
        LoadContent: Boolean;
    begin
        DocumentAttachment.SetView(DocumentFilter);
        LoadContent := DocumentAttachment.Count() = 1;
        if DocumentAttachment.FindSet() then
            repeat
                TransferDocAttachmentToBuffer(DocumentAttachment, TempAttachmentEntityBuffer, LoadContent)
            until DocumentAttachment.Next() = 0;
    end;

    local procedure TransferDocAttachmentToBuffer(var DocumentAttachment: Record "Document Attachment"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; LoadContent: Boolean)
    var
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        ContentOutStream: OutStream;
    begin
        Clear(TempAttachmentEntityBuffer."Byte Size");
        TempAttachmentEntityBuffer."Created Date-Time" := DocumentAttachment."Attached Date";
        TempAttachmentEntityBuffer."File Name" := CopyStr(FileManagement.CreateFileNameWithExtension(DocumentAttachment."File Name", DocumentAttachment."File Extension"), 1, MaxStrLen(TempAttachmentEntityBuffer."File Name"));
        TempAttachmentEntityBuffer.Type := DocumentAttachment."File Type";
        TempAttachmentEntityBuffer."Attachment Type" := TempAttachmentEntityBuffer."Attachment Type"::"Document Attachment";
        TempAttachmentEntityBuffer.Id := DocumentAttachment.SystemId;
        ConvertDocumentTypeFromDocumentAttachment(DocumentAttachment, TempAttachmentEntityBuffer);
        TempAttachmentEntityBuffer."Document Flow Sales" := DocumentAttachment."Document Flow Sales";
        TempAttachmentEntityBuffer."Line No." := DocumentAttachment."Line No.";

        TempAttachmentEntityBuffer."Document Id" := GetDocumentAttachmentDocumentId(DocumentAttachment);
        if TempAttachmentEntityBuffer.Insert() then;

        if LoadContent then begin
            TempAttachmentEntityBuffer.Content.CreateOutStream(ContentOutStream);
            DocumentAttachment.ExportToStream(ContentOutStream);
            TempAttachmentEntityBuffer.Modify();
        end;

        if not LoadContent and DocumentAttachment.HasContent() then begin
            DocumentAttachment.GetAsTempBlob(TempBlob);

            TempAttachmentEntityBuffer."Byte Size" := TempBlob.Length();
            TempAttachmentEntityBuffer.Modify();
        end;
    end;

    local procedure GetDocumentAttachmentDocumentId(var DocumentAttachment: Record "Document Attachment"): Guid
    var
        DummySalesHeader: Record "Sales Header";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
        DataTypeManagement: Codeunit "Data Type Management";
        MainRecordRef: RecordRef;
        FieldRefVar: FieldRef;
        ParentId: Guid;
    begin
        if DocumentAttachment."No." = '' then
            exit(ParentId);

        MainRecordRef.Open(DocumentAttachment."Table ID");
        if not DataTypeManagement.FindFieldByName(MainRecordRef, FieldRefVar, DummySalesHeader.FieldName("No.")) then
            exit(ParentId);

        case MainRecordRef.Number of
            Database::"Sales Header":
                begin
                    if DocumentAttachment."Document Type" = DocumentAttachment."Document Type"::Invoice then begin
                        SalesInvoiceEntityAggregate.Get(DocumentAttachment."No.", false);
                        exit(SalesInvoiceEntityAggregate.Id);
                    end;
                    if DocumentAttachment."Document Type" = DocumentAttachment."Document Type"::Quote then begin
                        SalesQuoteEntityBuffer.Get(DocumentAttachment."No.");
                        exit(SalesQuoteEntityBuffer.Id);
                    end;
                    if DocumentAttachment."Document Type" = DocumentAttachment."Document Type"::Order then begin
                        SalesOrderEntityBuffer.Get(DocumentAttachment."No.");
                        exit(SalesOrderEntityBuffer.Id);
                    end;
                    if DocumentAttachment."Document Type" = DocumentAttachment."Document Type"::"Credit Memo" then begin
                        SalesCrMemoEntityBuffer.Get(DocumentAttachment."No.", false);
                        exit(SalesCrMemoEntityBuffer.Id);
                    end;
                end;
            Database::"Purchase Header":
                begin
                    if DocumentAttachment."Document Type" = DocumentAttachment."Document Type"::Invoice then begin
                        PurchInvEntityAggregate.Get(DocumentAttachment."No.", false);
                        exit(PurchInvEntityAggregate.Id);
                    end;
                    if DocumentAttachment."Document Type" = DocumentAttachment."Document Type"::Order then begin
                        PurchaseOrderEntityBuffer.Get(DocumentAttachment."No.");
                        exit(PurchaseOrderEntityBuffer.Id);
                    end;
                    if DocumentAttachment."Document Type" = DocumentAttachment."Document Type"::"Credit Memo" then begin
                        PurchCrMemoEntityBuffer.Get(DocumentAttachment."No.", false);
                        exit(PurchCrMemoEntityBuffer.Id);
                    end;
                end;
            Database::"Sales Invoice Header":
                begin
                    SalesInvoiceEntityAggregate.Get(DocumentAttachment."No.", true);
                    exit(SalesInvoiceEntityAggregate.Id)
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoEntityBuffer.Get(DocumentAttachment."No.", true);
                    exit(SalesCrMemoEntityBuffer.Id);
                end;
            Database::"Purch. Inv. Header":
                begin
                    PurchInvEntityAggregate.Get(DocumentAttachment."No.", true);
                    exit(PurchInvEntityAggregate.Id)
                end;
            Database::"Purch. Cr. Memo Hdr.":
                begin
                    PurchCrMemoEntityBuffer.Get(DocumentAttachment."No.", true);
                    exit(PurchCrMemoEntityBuffer.Id);
                end;
        end;

        FieldRefVar.SetRange(DocumentAttachment."No.");
        MainRecordRef.FindFirst();
        exit(MainRecordRef.Field(MainRecordRef.SystemIdNo).Value);
    end;

    local procedure ConvertDocumentTypeFromDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary)
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        case DocumentAttachment."Table ID" of
            Database::"Sales Header":
                begin
                    SalesHeader.Get(DocumentAttachment."Document Type", DocumentAttachment."No.");
                    case SalesHeader."Document Type" of
                        SalesHeader."Document Type"::"Quote":
                            begin
                                TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Sales Quote";
                                exit;
                            end;
                        SalesHeader."Document Type"::"Order":
                            begin
                                TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Sales Order";
                                exit;
                            end;
                        SalesHeader."Document Type"::"Invoice":
                            begin
                                TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Sales Invoice";
                                exit;
                            end;
                        SalesHeader."Document Type"::"Credit Memo":
                            begin
                                TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Sales Credit Memo";
                                exit;
                            end;
                    end;
                end;
            Database::"Purchase Header":
                begin
                    PurchaseHeader.Get(DocumentAttachment."Document Type", DocumentAttachment."No.");
                    case PurchaseHeader."Document Type" of
                        PurchaseHeader."Document Type"::"Invoice":
                            begin
                                TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Purchase Invoice";
                                exit;
                            end;
                        PurchaseHeader."Document Type"::"Order":
                            begin
                                TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Purchase Order";
                                exit;
                            end;
                        PurchaseHeader."Document Type"::"Credit Memo":
                            begin
                                TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Purchase Credit Memo";
                                exit;
                            end;
                    end;
                end;
            Database::"Purch. Inv. Header":
                begin
                    TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Purchase Invoice";
                    exit;
                end;
            Database::"Sales Invoice Header":
                begin
                    TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Sales Invoice";
                    exit;
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Sales Credit Memo";
                    exit;
                end;
            Database::"Purch. Cr. Memo Hdr.":
                begin
                    TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Purchase Credit Memo";
                    exit;
                end;
            Database::Employee:
                begin
                    TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Employee";
                    exit;
                end;
            Database::Item:
                begin
                    TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Item";
                    exit;
                end;
            Database::Job:
                begin
                    TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Job";
                    exit;
                end;
            Database::Customer:
                begin
                    TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Customer";
                    exit;
                end;
            Database::Vendor:
                begin
                    TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Vendor";
                    exit;
                end;
            else
                TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::" ";
        end;
    end;

    procedure ConvertDocumentTypeToDocumentAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var DocumentAttachment: Record "Document Attachment")
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
    begin
        case TempAttachmentEntityBuffer."Document Type" of
            TempAttachmentEntityBuffer."Document Type"::"Sales Quote":
                begin
                    DocumentAttachment."Table ID" := Database::"Sales Header";
                    DocumentAttachment."Document Type" := DocumentAttachment."Document Type"::Quote;
                    exit;
                end;
            TempAttachmentEntityBuffer."Document Type"::"Sales Order":
                begin
                    DocumentAttachment."Table ID" := Database::"Sales Header";
                    DocumentAttachment."Document Type" := DocumentAttachment."Document Type"::Order;
                    exit;
                end;
            TempAttachmentEntityBuffer."Document Type"::"Sales Invoice":
                begin
                    SalesInvoiceEntityAggregate.SetRange(Id, TempAttachmentEntityBuffer."Document Id");
                    SalesInvoiceEntityAggregate.FindFirst();
                    DocumentAttachment."Document Type" := DocumentAttachment."Document Type"::Invoice;

                    if SalesInvoiceEntityAggregate.Posted then begin
                        DocumentAttachment."Table ID" := Database::"Sales Invoice Header";
                        DocumentAttachment."No." := SalesInvoiceEntityAggregate."No.";
                        exit;
                    end else begin
                        DocumentAttachment."Table ID" := Database::"Sales Header";
                        DocumentAttachment."No." := SalesInvoiceEntityAggregate."No.";
                        exit;
                    end;
                end;
            TempAttachmentEntityBuffer."Document Type"::"Sales Credit Memo":
                begin
                    SalesCrMemoEntityBuffer.SetRange(Id, TempAttachmentEntityBuffer."Document Id");
                    SalesCrMemoEntityBuffer.FindFirst();
                    DocumentAttachment."Document Type" := DocumentAttachment."Document Type"::"Credit Memo";

                    if SalesCrMemoEntityBuffer.Posted then begin
                        DocumentAttachment."Table ID" := Database::"Sales Cr.Memo Header";
                        DocumentAttachment."No." := SalesCrMemoEntityBuffer."No.";
                        exit;
                    end else begin
                        DocumentAttachment."Table ID" := Database::"Sales Header";
                        DocumentAttachment."No." := SalesCrMemoEntityBuffer."No.";
                        exit;
                    end;
                end;
            TempAttachmentEntityBuffer."Document Type"::"Purchase Invoice":
                begin
                    PurchInvEntityAggregate.SetRange(Id, TempAttachmentEntityBuffer."Document Id");
                    PurchInvEntityAggregate.FindFirst();
                    DocumentAttachment."Document Type" := DocumentAttachment."Document Type"::Invoice;

                    if PurchInvEntityAggregate.Posted then begin
                        DocumentAttachment."Table ID" := Database::"Purch. Inv. Header";
                        DocumentAttachment."No." := PurchInvEntityAggregate."No.";
                        exit;
                    end else begin
                        DocumentAttachment."Table ID" := Database::"Purchase Header";
                        DocumentAttachment."No." := PurchInvEntityAggregate."No.";
                        exit;
                    end;
                end;
            TempAttachmentEntityBuffer."Document Type"::"Purchase Order":
                begin
                    DocumentAttachment."Document Type" := DocumentAttachment."Document Type"::Order;
                    DocumentAttachment."Table ID" := Database::"Purchase Header";
                    exit;
                end;
            TempAttachmentEntityBuffer."Document Type"::"Purchase Credit Memo":
                begin
                    PurchCrMemoEntityBuffer.SetRange(Id, TempAttachmentEntityBuffer."Document Id");
                    PurchCrMemoEntityBuffer.FindFirst();
                    DocumentAttachment."Document Type" := DocumentAttachment."Document Type"::"Credit Memo";

                    if PurchCrMemoEntityBuffer.Posted then begin
                        DocumentAttachment."Table ID" := Database::"Purch. Cr. Memo Hdr.";
                        DocumentAttachment."No." := PurchCrMemoEntityBuffer."No.";
                        exit;
                    end else begin
                        DocumentAttachment."Table ID" := Database::"Purchase Header";
                        DocumentAttachment."No." := PurchCrMemoEntityBuffer."No.";
                        exit;
                    end;
                end;
            TempAttachmentEntityBuffer."Document Type"::"Employee":
                begin
                    DocumentAttachment."Table ID" := Database::Employee;
                    exit;
                end;
            TempAttachmentEntityBuffer."Document Type"::"Item":
                begin
                    DocumentAttachment."Table ID" := Database::Item;
                    exit;
                end;
            TempAttachmentEntityBuffer."Document Type"::"Job":
                begin
                    DocumentAttachment."Table ID" := Database::Job;
                    exit;
                end;
            TempAttachmentEntityBuffer."Document Type"::"Customer":
                begin
                    DocumentAttachment."Table ID" := Database::Customer;
                    exit;
                end;
            TempAttachmentEntityBuffer."Document Type"::"Vendor":
                begin
                    DocumentAttachment."Table ID" := Database::Vendor;
                    exit;
                end;
            else
                Error(UnsopportedDocumentTypeErr, TempAttachmentEntityBuffer."Document Type");
        end;
    end;

    [Scope('Cloud')]
    procedure LoadAttachments(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; DocumentIdFilter: Text; AttachmentIdFilter: Text)
    var
        IncomingDocument: Record "Incoming Document";
        DocumentRecordRef: RecordRef;
        DocumentId: Guid;
        GLEntryNo: Integer;
    begin
        TempAttachmentEntityBuffer.Reset();
        TempAttachmentEntityBuffer.DeleteAll();

        if not IsLinkedAttachment(DocumentIdFilter) then begin
            LoadUnlinkedAttachmentsToBuffer(TempAttachmentEntityBuffer, AttachmentIdFilter);
            exit;
        end;

        FindParentDocument(DocumentIdFilter, DocumentRecordRef);
        if not FindIncomingDocument(DocumentRecordRef, IncomingDocument) then
            exit;

        if IsGLEntry(DocumentRecordRef) then
            GLEntryNo := GetGLEntryNo(DocumentRecordRef)
        else
            DocumentId := GetDocumentId(DocumentRecordRef);

        LoadLinkedAttachmentsToBuffer(TempAttachmentEntityBuffer, IncomingDocument, AttachmentIdFilter);
        if TempAttachmentEntityBuffer.FindSet() then
            repeat
                if GLEntryNo <> 0 then
                    TempAttachmentEntityBuffer."G/L Entry No." := GLEntryNo
                else
                    TempAttachmentEntityBuffer."Document Id" := DocumentId;
                TempAttachmentEntityBuffer.Modify(true);
            until TempAttachmentEntityBuffer.Next() = 0;
    end;

    [Scope('Cloud')]
    procedure LoadAttachmentsWithDocumentType(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; DocumentIdFilter: Text; AttachmentIdFilter: Text; DocumentTypeFilter: Text)
    var
        IncomingDocument: Record "Incoming Document";
        DocumentRecordRef: RecordRef;
        DocumentId: Guid;
        ErrorMsg: Text;
    begin
        TempAttachmentEntityBuffer.Reset();
        TempAttachmentEntityBuffer.DeleteAll();

        if not IsLinkedAttachment(DocumentIdFilter) then begin
            LoadUnlinkedAttachmentsToBuffer(TempAttachmentEntityBuffer, AttachmentIdFilter);
            exit;
        end;

        FindParentDocumentWithDocumentTypeSafe(DocumentIdFilter, DocumentTypeFilter, DocumentRecordRef, ErrorMsg);
        if ErrorMsg <> '' then
            Error(ErrorMsg);

        if not FindIncomingDocument(DocumentRecordRef, IncomingDocument) then
            exit;

        DocumentId := GetDocumentId(DocumentRecordRef);

        LoadLinkedAttachmentsToBuffer(TempAttachmentEntityBuffer, IncomingDocument, AttachmentIdFilter);
        if TempAttachmentEntityBuffer.FindSet() then
            repeat
                TempAttachmentEntityBuffer."Document Id" := DocumentId;
                if IsGLEntry(DocumentRecordRef) then
                    TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::Journal;
                TempAttachmentEntityBuffer.Modify(true);
            until TempAttachmentEntityBuffer.Next() = 0;
    end;

    [Scope('Cloud')]
    procedure LoadAttachmentsWithoutDocumentType(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; AttachmentIdFilter: Text)
    var
        DocumentRecordRef: RecordRef;
        DocumentId: Guid;
    begin
        TempAttachmentEntityBuffer.Reset();
        TempAttachmentEntityBuffer.DeleteAll();

        LoadAttachmentsToBuffer(TempAttachmentEntityBuffer, AttachmentIdFilter);
        if TempAttachmentEntityBuffer.FindSet() then
            repeat
                TempAttachmentEntityBuffer."Document Id" := DocumentId;
                if IsGLEntry(DocumentRecordRef) then
                    TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::Journal;
                TempAttachmentEntityBuffer.Modify(true);
            until TempAttachmentEntityBuffer.Next() = 0;
    end;

    [Scope('Cloud')]
    procedure PropagateInsertAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        ErrorMsg: Text;
    begin
        if PropagateInsertLinkedAttachment(TempAttachmentEntityBuffer, TempFieldBuffer, ErrorMsg) then
            exit;
        ThrowErrorIfAny(ErrorMsg);
        PropagateInsertUnlinkedAttachment(TempAttachmentEntityBuffer, TempFieldBuffer);
    end;

    [Scope('Cloud')]
    procedure PropagateInsertAttachmentSafe(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        ErrorMsg: Text;
    begin
        if PropagateInsertLinkedAttachment(TempAttachmentEntityBuffer, TempFieldBuffer, ErrorMsg) then
            exit;
        // Ignore an error from above if any, because we don't want to ask the user
        // to upload the same attachment twice because of a small error like wrong documentId, etc.
        // The client can then handle this and link the attachment and the document afterwards.
        PropagateInsertUnlinkedAttachment(TempAttachmentEntityBuffer, TempFieldBuffer);
    end;

    [Scope('Cloud')]
    procedure PropagateInsertAttachmentSafeWithDocumentType(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        ErrorMsg: Text;
    begin
        if PropagateInsertLinkedAttachmentWithDocumentType(TempAttachmentEntityBuffer, TempFieldBuffer, ErrorMsg) then
            exit;
        PropagateInsertUnlinkedAttachment(TempAttachmentEntityBuffer, TempFieldBuffer);
    end;

    [Scope('Cloud')]
    procedure PropagateInsertAttachmentSafeWithoutDocumentType(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        ErrorMsg: Text;
    begin
        if PropagateInsertAttachmentWithoutDocumentType(TempAttachmentEntityBuffer, TempFieldBuffer, ErrorMsg) then
            exit;
    end;


    local procedure PropagateInsertLinkedAttachmentWithDocumentType(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempFieldBuffer: Record "Field Buffer" temporary; var ErrorMsg: Text): Boolean
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        LastUsedIncomingDocumentAttachment: Record "Incoming Document Attachment";
        UnlinkedAttachment: Record "Unlinked Attachment";
        DocumentRecordRef: RecordRef;
        AttachmentRecordRef: RecordRef;
        LineNo: Integer;
        Name: Text[250];
        Extension: Text[30];
        DocumentIdFilter: Text;
        DocumentTypeFilter: Text;
        DocumentId: Guid;
        AttachmentId: Guid;
    begin
        DocumentIdFilter := GetDocumentIdFilter(TempAttachmentEntityBuffer);
        DocumentTypeFilter := GetDocumentTypeFilter(TempAttachmentEntityBuffer);

        if not (IsLinkedAttachment(DocumentIdFilter)) then
            exit(false);

        FindParentDocumentWithDocumentTypeSafe(DocumentIdFilter, DocumentTypeFilter, DocumentRecordRef, ErrorMsg);
        if ErrorMsg <> '' then
            exit(false);

        VerifyCRUDIsPossibleSafe(DocumentRecordRef, ErrorMsg);
        if ErrorMsg <> '' then
            exit(false);

        FindOrCreateIncomingDocument(DocumentRecordRef, IncomingDocument);

        LastUsedIncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        if not LastUsedIncomingDocumentAttachment.FindLast() then
            LineNo := GetIncrement()
        else
            LineNo := LastUsedIncomingDocumentAttachment."Line No." + GetIncrement();

        if not IsNullGuid(TempAttachmentEntityBuffer.Id) then begin
            IncomingDocumentAttachment.SetRange(SystemId, TempAttachmentEntityBuffer.Id);
            if IncomingDocumentAttachment.FindFirst() then begin
                ErrorMsg := CannotInsertAnAttachmentThatAlreadyExistsErr;
                exit(false);
            end;
        end;

        DocumentId := GetDocumentId(DocumentRecordRef);
        TransferToIncomingDocumentAttachment(TempAttachmentEntityBuffer, IncomingDocumentAttachment, TempFieldBuffer, true);
        FileNameToNameAndExtension(TempAttachmentEntityBuffer."File Name", Name, Extension);
        IncomingDocumentAttachment."Incoming Document Entry No." := IncomingDocument."Entry No.";
        IncomingDocumentAttachment."Line No." := LineNo;
        IncomingDocumentAttachment.Name := Name;
        IncomingDocumentAttachment."File Extension" := Extension;
        if IncomingDocument.Posted then begin
            IncomingDocumentAttachment."Document No." := IncomingDocument."Document No.";
            IncomingDocumentAttachment."Posting Date" := IncomingDocument."Posting Date";
        end;

        if IsNullGuid(TempAttachmentEntityBuffer.Id) then
            IncomingDocumentAttachment.Insert(true)
        else begin
            IncomingDocumentAttachment.SystemId := TempAttachmentEntityBuffer.Id;
            IncomingDocumentAttachment.Insert(true, true);
        end;

        if FindUnlinkedAttachment(TempAttachmentEntityBuffer.Id, UnlinkedAttachment) then begin
            AttachmentId := UnlinkedAttachment.SystemId;
            UnlinkedAttachment.Delete(true);
            AttachmentRecordRef.GetTable(IncomingDocumentAttachment);
        end;

        TempAttachmentEntityBuffer.Id := IncomingDocumentAttachment.SystemId;

        exit(true);
    end;

    local procedure GetIncrement(): Integer
    begin
        exit(10000);
    end;

    local procedure PropagateInsertAttachmentWithoutDocumentType(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempFieldBuffer: Record "Field Buffer" temporary; var ErrorMsg: Text): Boolean
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        LastUsedIncomingDocumentAttachment: Record "Incoming Document Attachment";
        LineNo: Integer;
        Name: Text[250];
        Extension: Text[30];
    begin
        FileNameToNameAndExtension(TempAttachmentEntityBuffer."File Name", Name, Extension);
        IncomingDocument.Description := CopyStr(Name, 1, MaxStrLen(IncomingDocument.Description));
        IncomingDocument.Insert(true);

        LastUsedIncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        if not LastUsedIncomingDocumentAttachment.FindLast() then
            LineNo := GetIncrement()
        else
            LineNo := LastUsedIncomingDocumentAttachment."Line No." + GetIncrement();

        if not IsNullGuid(TempAttachmentEntityBuffer.Id) then begin
            IncomingDocumentAttachment.SetRange(SystemId, TempAttachmentEntityBuffer.Id);
            if IncomingDocumentAttachment.FindFirst() then begin
                ErrorMsg := CannotInsertAnAttachmentThatAlreadyExistsErr;
                exit(false);
            end;
        end;

        TransferToIncomingDocumentAttachment(TempAttachmentEntityBuffer, IncomingDocumentAttachment, TempFieldBuffer, true);
        IncomingDocumentAttachment."Incoming Document Entry No." := IncomingDocument."Entry No.";
        IncomingDocumentAttachment."Line No." := LineNo;
        IncomingDocumentAttachment.Name := Name;
        IncomingDocumentAttachment."File Extension" := Extension;
        if IncomingDocument.Posted then begin
            IncomingDocumentAttachment."Document No." := IncomingDocument."Document No.";
            IncomingDocumentAttachment."Posting Date" := IncomingDocument."Posting Date";
        end;

        if IsNullGuid(TempAttachmentEntityBuffer.Id) then
            IncomingDocumentAttachment.Insert(true)
        else begin
            IncomingDocumentAttachment.SystemId := TempAttachmentEntityBuffer.Id;
            IncomingDocumentAttachment.Insert(true, true);
        end;

        TempAttachmentEntityBuffer.Id := IncomingDocumentAttachment.SystemId;

        exit(true);
    end;

    local procedure PropagateInsertUnlinkedAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempFieldBuffer: Record "Field Buffer" temporary): Boolean
    var
        UnlinkedAttachment: Record "Unlinked Attachment";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocument: Record "Incoming Document";
        AttachmentRecordRef: RecordRef;
        AttachmentId: Guid;
    begin
        if not IsNullGuid(TempAttachmentEntityBuffer.Id) then
            if FindUnlinkedAttachment(TempAttachmentEntityBuffer.Id, UnlinkedAttachment) then
                Error(CannotInsertAnAttachmentThatAlreadyExistsErr);
        Clear(UnlinkedAttachment);
        TransferToUnlinkedAttachment(TempAttachmentEntityBuffer, UnlinkedAttachment, TempFieldBuffer, true);

        if IsNullGuid(TempAttachmentEntityBuffer.Id) then
            UnlinkedAttachment.Insert(true)
        else begin
            UnlinkedAttachment.SystemId := TempAttachmentEntityBuffer.Id;
            UnlinkedAttachment.Insert(true, true);
        end;

        UnlinkedAttachment.Find();

        if FindLinkedAttachment(TempAttachmentEntityBuffer.Id, IncomingDocumentAttachment) then begin
            AttachmentId := IncomingDocumentAttachment.SystemId;
            IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.");
            DeleteLinkedAttachment(IncomingDocumentAttachment, IncomingDocument);
            AttachmentRecordRef.GetTable(UnlinkedAttachment);
        end;

        Clear(TempAttachmentEntityBuffer."Document Id");
        TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::" ";
        TempAttachmentEntityBuffer.Id := UnlinkedAttachment.SystemId;
        exit(true);
    end;

    local procedure PropagateInsertLinkedAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempFieldBuffer: Record "Field Buffer" temporary; var ErrorMsg: Text): Boolean
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        LastUsedIncomingDocumentAttachment: Record "Incoming Document Attachment";
        UnlinkedAttachment: Record "Unlinked Attachment";
        DocumentRecordRef: RecordRef;
        AttachmentRecordRef: RecordRef;
        LineNo: Integer;
        Name: Text[250];
        Extension: Text[30];
        DocumentIdFilter: Text;
        GLEntryNoFilter: Text;
        DocumentId: Guid;
        AttachmentId: Guid;
    begin
        DocumentIdFilter := GetDocumentIdFilter(TempAttachmentEntityBuffer);
        GLEntryNoFilter := GetGLEntryNoFilter(TempAttachmentEntityBuffer);
        if not (IsLinkedAttachment(DocumentIdFilter) or IsLinkedAttachment(GLEntryNoFilter)) then
            exit(false);

        if GLEntryNoFilter <> '' then
            FindParentDocumentSafe(GLEntryNoFilter, DocumentRecordRef, ErrorMsg)
        else
            FindParentDocumentSafe(DocumentIdFilter, DocumentRecordRef, ErrorMsg);
        if ErrorMsg <> '' then
            exit(false);

        VerifyCRUDIsPossibleSafe(DocumentRecordRef, ErrorMsg);
        if ErrorMsg <> '' then
            exit(false);

        FindOrCreateIncomingDocument(DocumentRecordRef, IncomingDocument);

        LastUsedIncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        if not LastUsedIncomingDocumentAttachment.FindLast() then
            LineNo := GetIncrement()
        else
            LineNo := LastUsedIncomingDocumentAttachment."Line No." + GetIncrement();

        if not IsNullGuid(TempAttachmentEntityBuffer.Id) then
            if IncomingDocumentAttachment.GetBySystemId(TempAttachmentEntityBuffer.Id) then begin
                ErrorMsg := CannotInsertAnAttachmentThatAlreadyExistsErr;
                exit(false);
            end;

        DocumentId := GetDocumentId(DocumentRecordRef);
        TransferToIncomingDocumentAttachment(TempAttachmentEntityBuffer, IncomingDocumentAttachment, TempFieldBuffer, true);
        FileNameToNameAndExtension(TempAttachmentEntityBuffer."File Name", Name, Extension);
        IncomingDocumentAttachment."Incoming Document Entry No." := IncomingDocument."Entry No.";
        IncomingDocumentAttachment."Line No." := LineNo;
        IncomingDocumentAttachment.Name := Name;
        IncomingDocumentAttachment."File Extension" := Extension;
        if IncomingDocument.Posted then begin
            IncomingDocumentAttachment."Document No." := IncomingDocument."Document No.";
            IncomingDocumentAttachment."Posting Date" := IncomingDocument."Posting Date";
        end;
        if IsNullGuid(TempAttachmentEntityBuffer.Id) then
            IncomingDocumentAttachment.Insert(true)
        else begin
            IncomingDocumentAttachment.SystemId := TempAttachmentEntityBuffer.Id;
            IncomingDocumentAttachment.Insert(true, true);
        end;

        if FindUnlinkedAttachment(TempAttachmentEntityBuffer.Id, UnlinkedAttachment) then begin
            AttachmentId := UnlinkedAttachment.SystemId;
            UnlinkedAttachment.Delete(true);
            AttachmentRecordRef.GetTable(IncomingDocumentAttachment);
        end;

        TempAttachmentEntityBuffer.Id := IncomingDocumentAttachment.SystemId;

        exit(true);
    end;


    [Scope('Cloud')]
    procedure PropagateModifyAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        UnlinkedAttachment: Record "Unlinked Attachment";
        DocumentRecordRef: RecordRef;
        DocumentRecord: Variant;
        DocumentIdFilter: Text;
        GLEntryNoFilter: Text;
        IsUnlinked: Boolean;
        IsLinked: Boolean;
        ShouldBeLinked: Boolean;
        ShouldBeUnlinked: Boolean;
    begin
        IsUnlinked := FindUnlinkedAttachment(TempAttachmentEntityBuffer.Id, UnlinkedAttachment);
        if IsUnlinked then begin
            TransferToUnlinkedAttachment(TempAttachmentEntityBuffer, UnlinkedAttachment, TempFieldBuffer, false);
            UnlinkedAttachment.Modify(true);
            ShouldBeLinked := not IsNullGuid(TempAttachmentEntityBuffer."Document Id");
            if ShouldBeLinked then
                LinkAttachmentToDocument(
                  TempAttachmentEntityBuffer.Id, TempAttachmentEntityBuffer."Document Id", TempAttachmentEntityBuffer."File Name");
            exit;
        end;

        IncomingDocumentAttachment.SetAutoCalcFields(Content);
        IsLinked := IncomingDocumentAttachment.GetBySystemId(TempAttachmentEntityBuffer.Id);
        if IsLinked then begin
            ShouldBeUnlinked := IsNullGuid(TempAttachmentEntityBuffer."Document Id") and (TempAttachmentEntityBuffer."G/L Entry No." = 0);
            if ShouldBeUnlinked then begin
                IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.");
                IncomingDocument.GetRecord(DocumentRecord);
                DocumentRecordRef := DocumentRecord;
                VerifyCRUDIsPossible(DocumentRecordRef);
                TransferToIncomingDocumentAttachment(TempAttachmentEntityBuffer, IncomingDocumentAttachment, TempFieldBuffer, false);
                UnlinkAttachmentFromDocument(IncomingDocumentAttachment);
                exit;
            end;
            DocumentIdFilter := GetDocumentIdFilter(TempAttachmentEntityBuffer);
            GLEntryNoFilter := GetGLEntryNoFilter(TempAttachmentEntityBuffer);
            if GLEntryNoFilter <> '' then
                FindParentDocument(GLEntryNoFilter, DocumentRecordRef)
            else
                FindParentDocument(DocumentIdFilter, DocumentRecordRef);
            if not FindIncomingDocument(DocumentRecordRef, IncomingDocument) then
                Error(AttachmentLinkedToAnotherDocumentErr);
            VerifyCRUDIsPossible(DocumentRecordRef);
            TransferToIncomingDocumentAttachment(TempAttachmentEntityBuffer, IncomingDocumentAttachment, TempFieldBuffer, false);
            IncomingDocumentAttachment.Modify(true);
            exit;
        end;

        Error(CannotModifyAnAttachmentThatDoesntExistErr);
    end;

    [Scope('Cloud')]
    procedure PropagateModifyAttachmentWithDocumentType(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        UnlinkedAttachment: Record "Unlinked Attachment";
        DocumentRecordRef: RecordRef;
        DocumentRecord: Variant;
        DocumentIdFilter: Text;
        DocumentTypeFilter: Text;
        ErrorMsg: Text;
        IsUnlinked: Boolean;
        IsLinked: Boolean;
        ShouldBeLinked: Boolean;
        ShouldBeUnlinked: Boolean;
    begin
        IsUnlinked := FindUnlinkedAttachment(TempAttachmentEntityBuffer.Id, UnlinkedAttachment);
        if IsUnlinked then begin
            TransferToUnlinkedAttachment(TempAttachmentEntityBuffer, UnlinkedAttachment, TempFieldBuffer, false);
            UnlinkedAttachment.Modify(true);
            ShouldBeLinked := not IsNullGuid(TempAttachmentEntityBuffer."Document Id");
            if ShouldBeLinked then
                LinkAttachmentToDocumentWithDocumentType(
                  TempAttachmentEntityBuffer.Id, TempAttachmentEntityBuffer."Document Id", TempAttachmentEntityBuffer."Document Type", TempAttachmentEntityBuffer."File Name");
            exit;
        end;

        IncomingDocumentAttachment.SetAutoCalcFields(Content);
        IncomingDocumentAttachment.SetRange(SystemId, TempAttachmentEntityBuffer.Id);
        IsLinked := IncomingDocumentAttachment.FindFirst();
        if IsLinked then begin
            ShouldBeUnlinked := IsNullGuid(TempAttachmentEntityBuffer."Document Id");
            if ShouldBeUnlinked then begin
                IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.");
                IncomingDocument.GetRecord(DocumentRecord);
                DocumentRecordRef := DocumentRecord;
                VerifyCRUDIsPossible(DocumentRecordRef);
                TransferToIncomingDocumentAttachment(TempAttachmentEntityBuffer, IncomingDocumentAttachment, TempFieldBuffer, false);
                UnlinkAttachmentFromDocument(IncomingDocumentAttachment);
                exit;
            end;
            DocumentIdFilter := GetDocumentIdFilter(TempAttachmentEntityBuffer);
            DocumentTypeFilter := GetDocumentTypeFilter(TempAttachmentEntityBuffer);

            FindParentDocumentWithDocumentTypeSafe(DocumentIdFilter, DocumentTypeFilter, DocumentRecordRef, ErrorMsg);
            if ErrorMsg <> '' then
                Error(ErrorMsg);

            if not FindIncomingDocument(DocumentRecordRef, IncomingDocument) then
                Error(AttachmentLinkedToAnotherDocumentErr);
            VerifyCRUDIsPossible(DocumentRecordRef);
            TransferToIncomingDocumentAttachment(TempAttachmentEntityBuffer, IncomingDocumentAttachment, TempFieldBuffer, false);
            IncomingDocumentAttachment.Modify(true);
            exit;
        end;

        Error(CannotModifyAnAttachmentThatDoesntExistErr);
    end;

    [Scope('Cloud')]
    procedure PropagateModifyAttachmentWithoutDocumentType(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        IncomingDocumentAttachment.SetAutoCalcFields(Content);
        if not IncomingDocumentAttachment.GetBySystemId(TempAttachmentEntityBuffer.Id) then
            Error(CannotModifyAnAttachmentThatDoesntExistErr);
        IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.");
        TransferToIncomingDocumentAttachment(TempAttachmentEntityBuffer, IncomingDocumentAttachment, TempFieldBuffer, false);
        IncomingDocumentAttachment.Modify(true);
    end;

    procedure PropagateDeleteAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary)
    var
        DocumentAttachment: Record "Document Attachment";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        UnlinkedAttachment: Record "Unlinked Attachment";
        DocumentRecordRef: RecordRef;
        DocumentIdFilter: Text;
        GLEntryNoFilter: Text;
    begin
        if TempAttachmentEntityBuffer."Attachment Type" = TempAttachmentEntityBuffer."Attachment Type"::"Document Attachment" then begin
            DocumentAttachment.GetBySystemId(TempAttachmentEntityBuffer.Id);
            DocumentAttachment.Delete(true);
            exit;
        end;

        if FindUnlinkedAttachment(TempAttachmentEntityBuffer.Id, UnlinkedAttachment) then begin
            UnlinkedAttachment.Delete(true);
            exit;
        end;

        if not IncomingDocumentAttachment.GetBySystemId(TempAttachmentEntityBuffer.Id) then
            Error(CannotDeleteAnAttachmentThatDoesntExistErr);

        DocumentIdFilter := GetDocumentIdFilter(TempAttachmentEntityBuffer);
        GLEntryNoFilter := GetGLEntryNoFilter(TempAttachmentEntityBuffer);
        if DocumentIdFilter <> '' then begin
            if GLEntryNoFilter <> '' then
                FindParentDocument(GLEntryNoFilter, DocumentRecordRef)
            else
                FindParentDocument(DocumentIdFilter, DocumentRecordRef);
            if not FindIncomingDocument(DocumentRecordRef, IncomingDocument) then
                Error(AttachmentLinkedToAnotherDocumentErr);
            VerifyCRUDIsPossible(DocumentRecordRef);
        end;

        DeleteLinkedAttachment(IncomingDocumentAttachment, IncomingDocument);
    end;

    procedure PropagateDeleteAttachmentWithDocumentType(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary)
    var
        DocumentAttachment: Record "Document Attachment";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        UnlinkedAttachment: Record "Unlinked Attachment";
        DocumentRecordRef: RecordRef;
        DocumentIdFilter: Text;
        DocumentTypeFilter: Text;
        ErrorMsg: Text;
    begin
        if TempAttachmentEntityBuffer."Attachment Type" = TempAttachmentEntityBuffer."Attachment Type"::"Document Attachment" then begin
            DocumentAttachment.GetBySystemId(TempAttachmentEntityBuffer.Id);
            DocumentAttachment.Delete(true);
            exit;
        end;

        if FindUnlinkedAttachment(TempAttachmentEntityBuffer.Id, UnlinkedAttachment) then begin
            UnlinkedAttachment.Delete(true);
            exit;
        end;

        IncomingDocumentAttachment.SetRange(SystemId, TempAttachmentEntityBuffer.Id);
        if not IncomingDocumentAttachment.FindFirst() then
            Error(CannotDeleteAnAttachmentThatDoesntExistErr);

        DocumentIdFilter := GetDocumentIdFilter(TempAttachmentEntityBuffer);
        DocumentTypeFilter := GetDocumentTypeFilter(TempAttachmentEntityBuffer);
        FindParentDocumentWithDocumentTypeSafe(DocumentIdFilter, DocumentTypeFilter, DocumentRecordRef, ErrorMsg);
        if ErrorMsg <> '' then
            Error(ErrorMsg);

        if not FindIncomingDocument(DocumentRecordRef, IncomingDocument) then
            Error(AttachmentLinkedToAnotherDocumentErr);

        VerifyCRUDIsPossible(DocumentRecordRef);
        DeleteLinkedAttachment(IncomingDocumentAttachment, IncomingDocument);
    end;

    procedure PropagateDeleteAttachmentWithoutDocumentType(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary)
    var
        DocumentAttachment: Record "Document Attachment";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        UnlinkedAttachment: Record "Unlinked Attachment";
    begin
        if TempAttachmentEntityBuffer."Attachment Type" = TempAttachmentEntityBuffer."Attachment Type"::"Document Attachment" then begin
            DocumentAttachment.GetBySystemId(TempAttachmentEntityBuffer.Id);
            DocumentAttachment.Delete(true);
            exit;
        end;

        if FindUnlinkedAttachment(TempAttachmentEntityBuffer.Id, UnlinkedAttachment) then begin
            UnlinkedAttachment.Delete(true);
            exit;
        end;

        if not IncomingDocumentAttachment.GetBySystemId(TempAttachmentEntityBuffer.Id) then
            Error(CannotDeleteAnAttachmentThatDoesntExistErr);

        if not IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.") then
            Error(AttachmentLinkedToAnotherDocumentErr);

        DeleteLinkedAttachment(IncomingDocumentAttachment, IncomingDocument);
    end;

    procedure DeleteLinkedAttachment(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IncomingDocument: Record "Incoming Document")
    var
        AdditionalIncomingDocumentAttachment: Record "Incoming Document Attachment";
        DummyRecordID: RecordID;
        LineNo: Integer;
        IsDefault: Boolean;
        IsMain: Boolean;
    begin
        LineNo := IncomingDocumentAttachment."Line No.";
        IsDefault := IncomingDocumentAttachment.Default;
        IsMain := IncomingDocumentAttachment."Main Attachment";
        if (not IsDefault) and (not IsMain) then
            IncomingDocumentAttachment.Delete(true)
        else begin
            IncomingDocumentAttachment.Default := false;
            IncomingDocumentAttachment."Main Attachment" := false;
            IncomingDocumentAttachment.Modify();
            IncomingDocumentAttachment.Delete(true);
            AdditionalIncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
            AdditionalIncomingDocumentAttachment.SetFilter("Line No.", '<>%1', LineNo);
            if AdditionalIncomingDocumentAttachment.FindFirst() then begin
                AdditionalIncomingDocumentAttachment.Validate(Default, IsDefault);
                AdditionalIncomingDocumentAttachment.Validate("Main Attachment", IsMain);
                AdditionalIncomingDocumentAttachment.Modify(true);
            end;
        end;

        IncomingDocumentAttachment.Reset();
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        if IncomingDocumentAttachment.FindFirst() then
            exit;

        if IncomingDocument.Posted then begin
            IncomingDocument."Related Record ID" := DummyRecordID;
            IncomingDocument."Posted Date-Time" := 0DT;
            IncomingDocument.Posted := false;
            IncomingDocument.Processed := false;
            IncomingDocument.Status := IncomingDocument.Status::Released;
            IncomingDocument."Document No." := '';
            IncomingDocument."Document Type" := IncomingDocument."Document Type"::" ";
            IncomingDocument."Posting Date" := 0D;
            IncomingDocument.Modify(true);
        end;

        IncomingDocument.Delete(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateAttachments(var TempOldAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempNewAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; DocumentId: Guid)
    begin
        DeleteUnusedAttachments(TempOldAttachmentEntityBuffer, TempNewAttachmentEntityBuffer);
        LinkNewAttachmentsToDocument(TempOldAttachmentEntityBuffer, TempNewAttachmentEntityBuffer, DocumentId);
    end;

    local procedure DeleteUnusedAttachments(var TempOldAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempNewAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary)
    begin
        if TempOldAttachmentEntityBuffer.FindSet() then
            repeat
                if not TempNewAttachmentEntityBuffer.Get(TempOldAttachmentEntityBuffer.Id) then
                    PropagateDeleteAttachment(TempOldAttachmentEntityBuffer);
            until TempOldAttachmentEntityBuffer.Next() = 0;
    end;

    procedure InsertFromTempAttachmentEntityBufferToDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        FileManagement: Codeunit "File Management";
    begin
        DocumentAttachment."Attached Date" := CurrentDateTime();

        if HasRegisteredField(TempAttachmentEntityBuffer.FieldNo("Line No."), TempFieldBuffer) then
            DocumentAttachment.Validate("Line No.", TempAttachmentEntityBuffer."Line No.");

        if HasRegisteredField(TempAttachmentEntityBuffer.FieldNo("File Name"), TempFieldBuffer) then begin
            DocumentAttachment.Validate("File Extension", FileManagement.GetExtension(TempAttachmentEntityBuffer."File Name"));
            DocumentAttachment.Validate("File Name", CopyStr(FileManagement.GetFileNameWithoutExtension(TempAttachmentEntityBuffer."File Name"), 1, MaxStrLen(DocumentAttachment."File Name")));
        end;

        ConvertDocumentTypeToDocumentAttachment(TempAttachmentEntityBuffer, DocumentAttachment);
        SetDocumentAttachmentNo(DocumentAttachment, TempAttachmentEntityBuffer);

        if HasRegisteredField(TempAttachmentEntityBuffer.FieldNo("Document Flow Sales"), TempFieldBuffer) then
            DocumentAttachment.Validate("Document Flow Sales", TempAttachmentEntityBuffer."Document Flow Sales");

        if HasRegisteredField(TempAttachmentEntityBuffer.FieldNo("Document Flow Purchase"), TempFieldBuffer) then
            DocumentAttachment.Validate("Document Flow Purchase", TempAttachmentEntityBuffer."Document Flow Purchase");

        DocumentAttachment.Insert();
    end;

    procedure ModifyFromTempAttachmentEntityBufferToDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        ExistingDocumentAttachment: Record "Document Attachment";
        FileManagement: Codeunit "File Management";
        RenameRecord: Boolean;
        ModifyRecord: Boolean;
    begin
        ExistingDocumentAttachment.Copy(DocumentAttachment);
        if HasRegisteredField(TempAttachmentEntityBuffer.FieldNo("Document Type"), TempFieldBuffer) then begin
            ConvertDocumentTypeToDocumentAttachment(TempAttachmentEntityBuffer, DocumentAttachment);
            RenameRecord := true;
        end;

        if HasRegisteredField(TempAttachmentEntityBuffer.FieldNo("Document Id"), TempFieldBuffer) then begin
            SetDocumentAttachmentNo(DocumentAttachment, TempAttachmentEntityBuffer);
            RenameRecord := true;
        end;

        if HasRegisteredField(TempAttachmentEntityBuffer.FieldNo("Line No."), TempFieldBuffer) then begin
            DocumentAttachment."Line No." := TempAttachmentEntityBuffer."Line No.";
            RenameRecord := true;
        end;

        if RenameRecord then begin
            ExistingDocumentAttachment.Rename(DocumentAttachment."Table ID", DocumentAttachment."No.", DocumentAttachment."Document Type", DocumentAttachment."Line No.", DocumentAttachment.ID);
            DocumentAttachment.Find();
        end;

        if HasRegisteredField(TempAttachmentEntityBuffer.FieldNo("Document Flow Sales"), TempFieldBuffer) then begin
            DocumentAttachment.Validate("Document Flow Sales", TempAttachmentEntityBuffer."Document Flow Sales");
            ModifyRecord := true;
        end;

        if HasRegisteredField(TempAttachmentEntityBuffer.FieldNo("Document Flow Purchase"), TempFieldBuffer) then begin
            DocumentAttachment.Validate("Document Flow Purchase", TempAttachmentEntityBuffer."Document Flow Purchase");
            ModifyRecord := true;
        end;

        if HasRegisteredField(TempAttachmentEntityBuffer.FieldNo("File Name"), TempFieldBuffer) then begin
            DocumentAttachment.Validate("File Extension", FileManagement.GetExtension(TempAttachmentEntityBuffer."File Name"));
            DocumentAttachment.Validate("File Name", CopyStr(FileManagement.GetFileNameWithoutExtension(TempAttachmentEntityBuffer."File Name"), 1, MaxStrLen(DocumentAttachment."File Name")));
            ModifyRecord := true;
        end;

        if ModifyRecord then
            DocumentAttachment.Modify(true);
    end;

    procedure SetDocumentAttachmentNo(var DocumentAttachment: Record "Document Attachment"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary)
    var
        DummySalesHeader: Record "Sales Header";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        DataTypeManagement: Codeunit "Data Type Management";
        MainRecordRef: RecordRef;
        FieldRefVar: FieldRef;
    begin
        MainRecordRef.Open(DocumentAttachment."Table ID");
        case DocumentAttachment."Table ID" of
            Database::"Sales Invoice Header":
                begin
                    SalesInvoiceEntityAggregate.SetRange(Id, TempAttachmentEntityBuffer."Document Id");
                    SalesInvoiceEntityAggregate.FindFirst();
                    DocumentAttachment."No." := SalesInvoiceEntityAggregate."No.";
                    exit;
                end;
            Database::"Purch. Inv. Header":
                begin
                    PurchInvEntityAggregate.SetRange(Id, TempAttachmentEntityBuffer."Document Id");
                    PurchInvEntityAggregate.FindFirst();
                    DocumentAttachment."No." := PurchInvEntityAggregate."No.";
                    exit;
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    SalesCrMemoEntityBuffer.SetRange(Id, TempAttachmentEntityBuffer."Document Id");
                    SalesCrMemoEntityBuffer.FindFirst();
                    DocumentAttachment."No." := SalesCrMemoEntityBuffer."No.";
                    exit;
                end;
            Database::"Purch. Cr. Memo Hdr.":
                begin
                    PurchCrMemoEntityBuffer.SetRange(Id, TempAttachmentEntityBuffer."Document Id");
                    PurchCrMemoEntityBuffer.FindFirst();
                    DocumentAttachment."No." := PurchCrMemoEntityBuffer."No.";
                    exit;
                end;
        end;

        MainRecordRef.GetBySystemId(TempAttachmentEntityBuffer."Document Id");
        if not DataTypeManagement.FindFieldByName(MainRecordRef, FieldRefVar, DummySalesHeader.FieldName("No.")) then
            Error(CannotFindParentKeyErr);
        DocumentAttachment."No." := FieldRefVar.Value();
    end;

    local procedure LinkNewAttachmentsToDocument(var TempOldAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var TempNewAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; DocumentId: Guid)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        UnlinkedAttachment: Record "Unlinked Attachment";
        AttachmentId: Guid;
        FileName: Text[250];
    begin
        if TempNewAttachmentEntityBuffer.FindSet() then
            repeat
                AttachmentId := TempNewAttachmentEntityBuffer.Id;
                FileName := TempNewAttachmentEntityBuffer."File Name";
                if not TempOldAttachmentEntityBuffer.Get(AttachmentId) then
                    case true of
                        FindUnlinkedAttachment(AttachmentId, UnlinkedAttachment):
                            begin
                                if FileName = '' then
                                    FileName := UnlinkedAttachment."File Name";
                                LinkAttachmentToDocument(UnlinkedAttachment.SystemId, DocumentId, FileName);
                            end;
                        FindLinkedAttachment(AttachmentId, IncomingDocumentAttachment):
                            begin
                                IncomingDocumentAttachment.CalcFields(Content);
                                TempNewAttachmentEntityBuffer.Content := IncomingDocumentAttachment.Content;
                                TempNewAttachmentEntityBuffer.Modify(true);
                                CopyAttachment(TempNewAttachmentEntityBuffer, UnlinkedAttachment, true);
                                if FileName = '' then
                                    FileName := NameAndExtensionToFileName(
                                        IncomingDocumentAttachment.Name, IncomingDocumentAttachment."File Extension");
                                LinkAttachmentToDocument(UnlinkedAttachment.SystemId, DocumentId, FileName);
                            end;
                        else begin
                            CopyAttachment(TempNewAttachmentEntityBuffer, UnlinkedAttachment, false);
                            if FileName = '' then
                                FileName := UnlinkedAttachment."File Name";
                            LinkAttachmentToDocument(UnlinkedAttachment.SystemId, DocumentId, FileName);
                        end;
                    end
                else
                    if TempNewAttachmentEntityBuffer."File Name" <> TempOldAttachmentEntityBuffer."File Name" then
                        if FindLinkedAttachment(AttachmentId, IncomingDocumentAttachment) then begin
                            FileNameToNameAndExtension(FileName, IncomingDocumentAttachment.Name, IncomingDocumentAttachment."File Extension");
                            IncomingDocumentAttachment.Modify(true);
                        end;
            until TempNewAttachmentEntityBuffer.Next() = 0;
    end;

    local procedure LinkAttachmentToDocument(AttachmentId: Guid; DocumentId: Guid; FileName: Text[250])
    var
        TempFieldBuffer: Record "Field Buffer" temporary;
        TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary;
        UnlinkedAttachment: Record "Unlinked Attachment";
        ErrorMsg: Text;
    begin
        UnlinkedAttachment.SetAutoCalcFields(Content);
        UnlinkedAttachment.Get(AttachmentId);
        TransferFromUnlinkedAttachment(TempAttachmentEntityBuffer, UnlinkedAttachment);
        TempAttachmentEntityBuffer."Document Id" := DocumentId;
        TempAttachmentEntityBuffer."File Name" := FileName;
        RegisterFieldSet(TempAttachmentEntityBuffer.FieldNo("Created Date-Time"), TempFieldBuffer);
        RegisterFieldSet(TempAttachmentEntityBuffer.FieldNo("File Name"), TempFieldBuffer);
        RegisterFieldSet(TempAttachmentEntityBuffer.FieldNo(Content), TempFieldBuffer);
        PropagateInsertLinkedAttachment(TempAttachmentEntityBuffer, TempFieldBuffer, ErrorMsg);
    end;

    local procedure LinkAttachmentToDocumentWithDocumentType(AttachmentId: Guid; DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; FileName: Text[250])
    var
        TempFieldBuffer: Record "Field Buffer" temporary;
        TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary;
        UnlinkedAttachment: Record "Unlinked Attachment";
        ErrorMsg: Text;
    begin
        UnlinkedAttachment.SetAutoCalcFields(Content);
        UnlinkedAttachment.Get(AttachmentId);
        TransferFromUnlinkedAttachment(TempAttachmentEntityBuffer, UnlinkedAttachment);
        TempAttachmentEntityBuffer."Document Id" := DocumentId;
        TempAttachmentEntityBuffer."Document Type" := DocumentType;
        TempAttachmentEntityBuffer."File Name" := FileName;
        RegisterFieldSet(TempAttachmentEntityBuffer.FieldNo("Created Date-Time"), TempFieldBuffer);
        RegisterFieldSet(TempAttachmentEntityBuffer.FieldNo("File Name"), TempFieldBuffer);
        RegisterFieldSet(TempAttachmentEntityBuffer.FieldNo(Content), TempFieldBuffer);
        PropagateInsertLinkedAttachmentWithDocumentType(TempAttachmentEntityBuffer, TempFieldBuffer, ErrorMsg);
    end;

    local procedure UnlinkAttachmentFromDocument(var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    var
        TempFieldBuffer: Record "Field Buffer" temporary;
        TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary;
    begin
        TransferFromIncomingDocumentAttachment(TempAttachmentEntityBuffer, IncomingDocumentAttachment, EmptyGuid);
        RegisterFieldSet(TempAttachmentEntityBuffer.FieldNo("Created Date-Time"), TempFieldBuffer);
        RegisterFieldSet(TempAttachmentEntityBuffer.FieldNo("File Name"), TempFieldBuffer);
        RegisterFieldSet(TempAttachmentEntityBuffer.FieldNo(Content), TempFieldBuffer);
        PropagateInsertUnlinkedAttachment(TempAttachmentEntityBuffer, TempFieldBuffer);
    end;

    procedure CopyAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var UnlinkedAttachment: Record "Unlinked Attachment"; GenerateNewId: Boolean)
    begin
        UnlinkedAttachment.TransferFields(TempAttachmentEntityBuffer);
        Clear(UnlinkedAttachment.Id);
        UnlinkedAttachment.Insert(true);
    end;

    procedure RegisterFieldSet(FieldNo: Integer; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        LastOrderNo: Integer;
    begin
        LastOrderNo := 1;
        if TempFieldBuffer.FindLast() then
            LastOrderNo := TempFieldBuffer.Order + 1;

        Clear(TempFieldBuffer);
        TempFieldBuffer.Order := LastOrderNo;
        TempFieldBuffer."Table ID" := DATABASE::"Attachment Entity Buffer";
        TempFieldBuffer."Field ID" := FieldNo;
        TempFieldBuffer.Insert();
    end;

    local procedure HasRegisteredField(FieldNo: Integer; var TempFieldBuffer: Record "Field Buffer" temporary): Boolean
    begin
        TempFieldBuffer.SetRange("Field ID", FieldNo);
        TempFieldBuffer.SetRange("Table ID", Database::"Attachment Entity Buffer");
        exit(TempFieldBuffer.FindFirst());
    end;

    local procedure GetDocumentIdFilter(var AttachmentEntityBuffer: Record "Attachment Entity Buffer"): Text
    var
        DocumentIdFilter: Text;
    begin
        if IsNullGuid(AttachmentEntityBuffer."Document Id") then begin
            DocumentIdFilter := AttachmentEntityBuffer.GetFilter("Document Id");
            if DocumentIdFilter = '' then
                DocumentIdFilter := Format(EmptyGuid);
        end else
            DocumentIdFilter := Format(AttachmentEntityBuffer."Document Id");
        exit(DocumentIdFilter);
    end;

    local procedure GetDocumentTypeFilter(var AttachmentEntityBuffer: Record "Attachment Entity Buffer"): Text
    var
        DocumentTypeFilter: Text;
    begin
        if AttachmentEntityBuffer."Document Type" = AttachmentEntityBuffer."Document Type"::" " then
            DocumentTypeFilter := AttachmentEntityBuffer.GetFilter("Document Type")
        else
            DocumentTypeFilter := Format(AttachmentEntityBuffer."Document Type");
        exit(DocumentTypeFilter);
    end;

    local procedure GetGLEntryNoFilter(var AttachmentEntityBuffer: Record "Attachment Entity Buffer"): Text
    var
        GLEntryNoFilter: Text;
    begin
        if AttachmentEntityBuffer."G/L Entry No." = 0 then
            GLEntryNoFilter := AttachmentEntityBuffer.GetFilter("G/L Entry No.")
        else
            GLEntryNoFilter := Format(AttachmentEntityBuffer."G/L Entry No.");
        exit(GLEntryNoFilter);
    end;

    local procedure IsLinkedAttachment(DocumentIdFilter: Text): Boolean
    begin
        exit((DocumentIdFilter <> '') and (DocumentIdFilter <> Format(EmptyGuid)));
    end;

    local procedure IsPostedDocument(var DocumentRecordRef: RecordRef): Boolean
    begin
        exit(
          (DocumentRecordRef.Number = DATABASE::"Sales Invoice Header") or (DocumentRecordRef.Number = DATABASE::"Purch. Inv. Header") or (DocumentRecordRef.Number = Database::"Sales Cr.Memo Header") or (DocumentRecordRef.Number = Database::"Purch. Cr. Memo Hdr."));
    end;

    local procedure IsGeneralJournalLine(var DocumentRecordRef: RecordRef): Boolean
    begin
        exit(DocumentRecordRef.Number = DATABASE::"Gen. Journal Line");
    end;

    local procedure IsGLEntry(var DocumentRecordRef: RecordRef): Boolean
    begin
        exit(DocumentRecordRef.Number = DATABASE::"G/L Entry");
    end;

    local procedure IsSalesInvoice(var DocumentRecordRef: RecordRef): Boolean
    var
        DocumentType: Option Quote,Invoice,"Journal Line","G/L Entry","Sales Order","Sales Credit Memo","Purchase Order","Purchase Credit Memo";
    begin
        if DocumentRecordRef.Number = DATABASE::"Sales Invoice Header" then
            exit(true);
        if DocumentRecordRef.Number = DATABASE::"Sales Header" then begin
            GetDocumentType(DocumentRecordRef, DocumentType);
            exit(DocumentType = DocumentType::Invoice);
        end;
        exit(false);
    end;

    local procedure IsPurchaseInvoice(var DocumentRecordRef: RecordRef): Boolean
    var
        DocumentType: Option Quote,Invoice,"Journal Line","G/L Entry","Sales Order","Sales Credit Memo","Purchase Order","Purchase Credit Memo";
    begin
        if DocumentRecordRef.Number = DATABASE::"Purch. Inv. Header" then
            exit(true);
        if DocumentRecordRef.Number = DATABASE::"Purchase Header" then begin
            GetDocumentType(DocumentRecordRef, DocumentType);
            exit(DocumentType = DocumentType::Invoice);
        end;
        exit(false);
    end;

    local procedure IsSalesQuote(var DocumentRecordRef: RecordRef): Boolean
    var
        DocumentType: Option Quote,Invoice,"Journal Line","G/L Entry","Sales Order","Sales Credit Memo","Purchase Order","Purchase Credit Memo";
    begin
        GetDocumentType(DocumentRecordRef, DocumentType);
        exit(DocumentType = DocumentType::Quote);
    end;

    local procedure IsSalesOrder(var DocumentRecordRef: RecordRef): Boolean
    var
        DocumentType: Option Quote,Invoice,"Journal Line","G/L Entry","Sales Order","Sales Credit Memo","Purchase Order","Purchase Credit Memo";
    begin
        GetDocumentType(DocumentRecordRef, DocumentType);
        exit(DocumentType = DocumentType::"Sales Order");
    end;

    local procedure IsPurchaseOrder(var DocumentRecordRef: RecordRef): Boolean
    var
        DocumentType: Option Quote,Invoice,"Journal Line","G/L Entry","Sales Order","Sales Credit Memo","Purchase Order","Purchase Credit Memo";
    begin
        GetDocumentType(DocumentRecordRef, DocumentType);
        exit(DocumentType = DocumentType::"Purchase Order");
    end;

    local procedure IsSalesCreditMemo(var DocumentRecordRef: RecordRef): Boolean
    var
        DocumentType: Option Quote,Invoice,"Journal Line","G/L Entry","Sales Order","Sales Credit Memo","Purchase Order","Purchase Credit Memo";
    begin
        GetDocumentType(DocumentRecordRef, DocumentType);
        exit(DocumentType = DocumentType::"Sales Credit Memo");
    end;

    local procedure IsPurchaseCreditMemo(var DocumentRecordRef: RecordRef): Boolean
    var
        DocumentType: Option Quote,Invoice,"Journal Line","G/L Entry","Sales Order","Sales Credit Memo","Purchase Order","Purchase Credit Memo";
    begin
        GetDocumentType(DocumentRecordRef, DocumentType);
        exit(DocumentType = DocumentType::"Purchase Credit Memo");
    end;

    local procedure GetDocumentType(var DocumentRecordRef: RecordRef; var DocumentType: Option Quote,Invoice,"Journal Line","G/L Entry","Sales Order","Sales Credit Memo","Purchase Order","Purchase Credit Memo")
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        if DocumentRecordRef.Number = DATABASE::"Gen. Journal Line" then begin
            DocumentType := DocumentType::"Journal Line";
            exit;
        end;

        if DocumentRecordRef.Number = DATABASE::"G/L Entry" then begin
            DocumentType := DocumentType::"G/L Entry";
            exit;
        end;

        if DocumentRecordRef.Number = DATABASE::"Sales Invoice Header" then begin
            DocumentType := DocumentType::Invoice;
            exit;
        end;

        if DocumentRecordRef.Number = Database::"Sales Cr.Memo Header" then begin
            DocumentType := DocumentType::"Sales Credit Memo";
            exit;
        end;

        if DocumentRecordRef.Number = Database::"Purch. Cr. Memo Hdr." then begin
            DocumentType := DocumentType::"Purchase Credit Memo";
            exit;
        end;

        if DocumentRecordRef.Number = DATABASE::"Purch. Inv. Header" then begin
            DocumentType := DocumentType::Invoice;
            exit;
        end;

        if DocumentRecordRef.Number = DATABASE::"Purchase Header" then begin
            DocumentRecordRef.SetTable(PurchaseHeader);

            if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice then begin
                DocumentType := DocumentType::Invoice;
                exit;
            end;

            if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then begin
                DocumentType := DocumentType::"Purchase Order";
                exit;
            end;

            if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then begin
                DocumentType := DocumentType::"Purchase Credit Memo";
                exit;
            end;
        end;

        if DocumentRecordRef.Number = Database::"Sales Header" then begin
            DocumentRecordRef.SetTable(SalesHeader);

            if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then begin
                DocumentType := DocumentType::Invoice;
                exit;
            end;

            if SalesHeader."Document Type" = SalesHeader."Document Type"::Quote then begin
                DocumentType := DocumentType::Quote;
                exit;
            end;

            if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
                DocumentType := DocumentType::"Sales Order";
                exit;
            end;

            if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then begin
                DocumentType := DocumentType::"Sales Credit Memo";
                exit;
            end;
        end;
    end;

    local procedure GetDocumentId(var DocumentRecordRef: RecordRef): Guid
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
        GraphMgtPurchCrMemo: Codeunit "Graph Mgt - Purch. Cr. Memo";
        Id: Guid;
    begin
        case DocumentRecordRef.Number of
            Database::"Sales Invoice Header":
                begin
                    DocumentRecordRef.SetTable(SalesInvoiceHeader);
                    exit(SalesInvoiceAggregator.GetSalesInvoiceHeaderId(SalesInvoiceHeader));
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    DocumentRecordRef.SetTable(SalesCrMemoHeader);
                    exit(GraphMgtSalCrMemoBuf.GetSalesCrMemoHeaderId(SalesCrMemoHeader));
                end;
            Database::"Purch. Inv. Header":
                begin
                    DocumentRecordRef.SetTable(PurchInvHeader);
                    exit(PurchInvAggregator.GetPurchaseInvoiceHeaderId(PurchInvHeader));
                end;
            Database::"Gen. Journal Line", Database::"G/L Entry":
                begin
                    Evaluate(Id, Format(DocumentRecordRef.Field(DocumentRecordRef.SystemIdNo()).Value()));
                    exit(Id);
                end;
            Database::"Purch. Cr. Memo Hdr.":
                begin
                    DocumentRecordRef.SetTable(PurchCrMemoHdr);
                    exit(GraphMgtPurchCrMemo.GetPurchaseCrMemoHeaderId(PurchCrMemoHdr));
                end;
        end;

        Evaluate(Id, Format(DocumentRecordRef.Field(DocumentRecordRef.SystemIdNo()).Value()));
        exit(Id);
    end;

    local procedure GetGLEntryNo(var DocumentRecordRef: RecordRef): Integer
    var
        DummyGLEntry: Record "G/L Entry";
        DataTypeManagement: Codeunit "Data Type Management";
        EntryNoFieldRef: FieldRef;
        EntryNo: Integer;
    begin
        if DataTypeManagement.FindFieldByName(DocumentRecordRef, EntryNoFieldRef, DummyGLEntry.FieldName("Entry No.")) then
            Evaluate(EntryNo, Format(EntryNoFieldRef.Value));
        exit(EntryNo);
    end;

    procedure GetDocumentIdFromAttachmentId(AttachmentId: Guid): Guid
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocument: Record "Incoming Document";
        DocumentRecordRef: RecordRef;
        DocumentVariant: Variant;
    begin
        IncomingDocumentAttachment.SetFilter(SystemId, AttachmentId);
        if not IncomingDocumentAttachment.FindFirst() then
            exit(EmptyGuid);

        IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.");

        if not IncomingDocument.GetRecord(DocumentVariant) then
            exit(EmptyGuid);

        DocumentRecordRef.GetTable(DocumentVariant);

        exit(GetDocumentId(DocumentRecordRef));
    end;

    procedure GetDocumentTypeFromAttachmentIdAndDocumentId(AttachmentId: Guid; DocumentId: Guid): Enum "Attachment Entity Buffer Document Type"
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocument: Record "Incoming Document";
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        AttachmentEntityBufferDocType: Enum "Attachment Entity Buffer Document Type";
    begin
        if not IncomingDocumentAttachment.GetBySystemId(AttachmentId) then
            exit(AttachmentEntityBufferDocType::" ");

        IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.");
        case IncomingDocument."Document Type" of
            IncomingDocument."Document Type"::Journal:
                exit(AttachmentEntityBufferDocType::Journal);

            IncomingDocument."Document Type"::"Sales Credit Memo":
                exit(AttachmentEntityBufferDocType::"Sales Credit Memo");

            IncomingDocument."Document Type"::"Sales Invoice":
                if SalesHeader.GetBySystemId(DocumentId) then begin
                    if SalesHeader."Incoming Document Entry No." = IncomingDocument."Entry No." then begin
                        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
                            exit(AttachmentEntityBufferDocType::"Sales Order");
                        if SalesHeader."Document Type" = SalesHeader."Document Type"::Quote then
                            exit(AttachmentEntityBufferDocType::"Sales Quote");
                        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then
                            exit(AttachmentEntityBufferDocType::"Sales Invoice");
                        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
                            exit(AttachmentEntityBufferDocType::"Sales Credit Memo");
                    end;
                end else
                    exit(AttachmentEntityBufferDocType::"Sales Invoice");

            IncomingDocument."Document Type"::"Purchase Invoice":
                begin
                    if PurchaseHeader.GetBySystemId(DocumentId) then
                        if PurchaseHeader."Incoming Document Entry No." = IncomingDocument."Entry No." then
                            if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then
                                exit(AttachmentEntityBufferDocType::"Purchase Order");

                    exit(AttachmentEntityBufferDocType::"Purchase Invoice");
                end;

            IncomingDocument."Document Type"::"Purchase Credit Memo":
                exit(AttachmentEntityBufferDocType::"Purchase Credit Memo");

            IncomingDocument."Document Type"::" ":
                begin
                    if GLEntry.Get(IncomingDocument."Related Record ID") then
                        exit(AttachmentEntityBufferDocType::Journal);

                    exit(AttachmentEntityBufferDocType::" ");
                end;
        end;
    end;

    local procedure VerifyCRUDIsPossibleSafe(var DocumentRecordRef: RecordRef; var ErrorMsg: Text)
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        SearchSalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        SearchPurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        SearchSalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        SearchSalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        SalesCreditMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        SearchSalesCreditMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
        SearchPurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        SearchPurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        DocumentId: Guid;
    begin
        DocumentId := GetDocumentId(DocumentRecordRef);

        if IsGeneralJournalLine(DocumentRecordRef) then begin
            GenJournalLine.SetRange(SystemId, DocumentId);
            if not GenJournalLine.FindFirst() then begin
                ErrorMsg := DocumentDoesNotExistErr;
                exit;
            end;
            exit;
        end;

        if IsGLEntry(DocumentRecordRef) and IsNullGuid(DocumentId) then
            exit;

        if IsGLEntry(DocumentRecordRef) then begin
            if not GLEntry.GetBySystemId(DocumentId) then begin
                ErrorMsg := DocumentDoesNotExistErr;
                exit;
            end;
            exit;
        end;

        if IsSalesInvoice(DocumentRecordRef) then begin
            SalesInvoiceEntityAggregate.SetRange(Id, DocumentId);
            if not SalesInvoiceEntityAggregate.FindFirst() then begin
                ErrorMsg := DocumentDoesNotExistErr;
                exit;
            end;
            SearchSalesInvoiceEntityAggregate.Copy(SalesInvoiceEntityAggregate);
            if SearchSalesInvoiceEntityAggregate.Next() <> 0 then
                ErrorMsg := MultipleDocumentsFoundForIdErr;
            exit;
        end;

        if IsPurchaseInvoice(DocumentRecordRef) then begin
            PurchInvEntityAggregate.SetRange(Id, DocumentId);
            if not PurchInvEntityAggregate.FindFirst() then begin
                ErrorMsg := DocumentDoesNotExistErr;
                exit;
            end;
            SearchPurchInvEntityAggregate.Copy(PurchInvEntityAggregate);
            if SearchPurchInvEntityAggregate.Next() <> 0 then
                ErrorMsg := MultipleDocumentsFoundForIdErr;
            exit;
        end;

        if IsSalesQuote(DocumentRecordRef) then begin
            SalesQuoteEntityBuffer.SetRange(Id, DocumentId);
            if not SalesQuoteEntityBuffer.FindFirst() then begin
                ErrorMsg := DocumentDoesNotExistErr;
                exit;
            end;
            SearchSalesQuoteEntityBuffer.Copy(SalesQuoteEntityBuffer);
            if SearchSalesQuoteEntityBuffer.Next() <> 0 then
                ErrorMsg := MultipleDocumentsFoundForIdErr;
            exit;
        end;

        if IsSalesOrder(DocumentRecordRef) then begin
            SalesOrderEntityBuffer.SetRange(Id, DocumentId);
            if not SalesOrderEntityBuffer.FindFirst() then begin
                ErrorMsg := DocumentDoesNotExistErr;
                exit;
            end;
            SearchSalesOrderEntityBuffer.Copy(SalesOrderEntityBuffer);
            if SearchSalesOrderEntityBuffer.Next() <> 0 then
                ErrorMsg := MultipleDocumentsFoundForIdErr;
            exit;
        end;

        if IsSalesCreditMemo(DocumentRecordRef) then begin
            SalesCreditMemoEntityBuffer.SetRange(Id, DocumentId);
            if not SalesCreditMemoEntityBuffer.FindFirst() then begin
                ErrorMsg := DocumentDoesNotExistErr;
                exit;
            end;
            SearchSalesCreditMemoEntityBuffer.Copy(SalesCreditMemoEntityBuffer);
            if SearchSalesCreditMemoEntityBuffer.Next() <> 0 then
                ErrorMsg := MultipleDocumentsFoundForIdErr;
            exit;
        end;

        if IsPurchaseOrder(DocumentRecordRef) then begin
            PurchaseOrderEntityBuffer.SetRange(Id, DocumentId);
            if not PurchaseOrderEntityBuffer.FindFirst() then begin
                ErrorMsg := DocumentDoesNotExistErr;
                exit;
            end;
            SearchPurchaseOrderEntityBuffer.Copy(PurchaseOrderEntityBuffer);
            if SearchPurchaseOrderEntityBuffer.Next() <> 0 then
                ErrorMsg := MultipleDocumentsFoundForIdErr;
            exit;
        end;

        if IsPurchaseCreditMemo(DocumentRecordRef) then begin
            PurchCrMemoEntityBuffer.SetRange(Id, DocumentId);
            if not PurchCrMemoEntityBuffer.FindFirst() then begin
                ErrorMsg := DocumentDoesNotExistErr;
                exit;
            end;
            SearchPurchCrMemoEntityBuffer.Copy(PurchCrMemoEntityBuffer);
            if SearchPurchCrMemoEntityBuffer.Next() <> 0 then
                ErrorMsg := MultipleDocumentsFoundForIdErr;
            exit;
        end;

        ErrorMsg := DocumentDoesNotExistErr;
    end;

    local procedure VerifyCRUDIsPossible(var DocumentRecordRef: RecordRef)
    var
        ErrorMsg: Text;
    begin
        VerifyCRUDIsPossibleSafe(DocumentRecordRef, ErrorMsg);
        ThrowErrorIfAny(ErrorMsg);
    end;

    local procedure FindLinkedAttachment(AttachmentId: Guid; var IncomingDocumentAttachment: Record "Incoming Document Attachment"): Boolean
    begin
        IncomingDocumentAttachment.SetRange(SystemId, AttachmentId);
        exit(IncomingDocumentAttachment.FindFirst());
    end;

    local procedure FindUnlinkedAttachment(AttachmentId: Guid; var UnlinkedAttachment: Record "Unlinked Attachment"): Boolean
    begin
        exit(UnlinkedAttachment.Get(AttachmentId));
    end;

    local procedure FindParentDocumentSafe(DocumentIdFilter: Text; var DocumentRecordRef: RecordRef; var ErrorMsg: Text)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
        TypeHelper: Codeunit "Type Helper";
        Value: Variant;
        DummyGLEntryNo: Integer;
    begin
        if DocumentIdFilter = '' then begin
            ErrorMsg := DocumentIDNotSpecifiedForAttachmentsErr;
            exit;
        end;

        DummyGLEntryNo := 0;
        Value := DummyGLEntryNo;
        if TypeHelper.Evaluate(Value, DocumentIdFilter, '', 'en-US') then begin
            GLEntry.SetFilter("Entry No.", DocumentIdFilter);
            if GLEntry.FindFirst() then begin
                DocumentRecordRef.GetTable(GLEntry);
                exit;
            end;
        end;

        GenJournalLine.SetFilter(SystemId, DocumentIdFilter);
        if GenJournalLine.FindFirst() then begin
            DocumentRecordRef.GetTable(GenJournalLine);
            exit;
        end;

        SalesHeader.SetFilter(SystemId, DocumentIdFilter);
        if SalesHeader.FindFirst() then begin
            DocumentRecordRef.GetTable(SalesHeader);
            exit;
        end;

        if SalesInvoiceAggregator.GetSalesInvoiceHeaderFromId(DocumentIdFilter, SalesInvoiceHeader) then begin
            DocumentRecordRef.GetTable(SalesInvoiceHeader);
            exit;
        end;

        PurchaseHeader.SetFilter(SystemId, DocumentIdFilter);
        if PurchaseHeader.FindFirst() then begin
            DocumentRecordRef.GetTable(PurchaseHeader);
            exit;
        end;

        if PurchInvAggregator.GetPurchaseInvoiceHeaderFromId(DocumentIdFilter, PurchInvHeader) then begin
            DocumentRecordRef.GetTable(PurchInvHeader);
            exit;
        end;

        ErrorMsg := DocumentDoesNotExistErr;
    end;

    local procedure FindParentDocument(DocumentIdFilter: Text; var DocumentRecordRef: RecordRef)
    var
        ErrorMsg: Text;
    begin
        FindParentDocumentSafe(DocumentIdFilter, DocumentRecordRef, ErrorMsg);
        ThrowErrorIfAny(ErrorMsg);
    end;

    local procedure FindParentDocumentWithDocumentTypeSafe(DocumentIdFilter: Text; DocumentTypeFilter: Text; var DocumentRecordRef: RecordRef; var ErrorMsg: Text)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        GenJournalLine: Record "Gen. Journal Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        GLEntry: Record "G/L Entry";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
        GraphMgtPurchCrMemo: Codeunit "Graph Mgt - Purch. Cr. Memo";
        AttachmentEntityBufferDocType: Enum "Attachment Entity Buffer Document Type";
    begin
        if (DocumentIdFilter = '') or (DocumentTypeFilter = '') then begin
            ErrorMsg := DocumentIDorTypeNotSpecifiedForAttachmentsErr;
            exit;
        end;

        Evaluate(AttachmentEntityBufferDocType, DocumentTypeFilter);
        case AttachmentEntityBufferDocType of
            AttachmentEntityBufferDocType::Journal:
                begin
                    if GLEntry.GetBySystemId(DocumentIdFilter) then begin
                        DocumentRecordRef.GetTable(GLEntry);
                        exit;
                    end;
                    if GenJournalLine.GetBySystemId(DocumentIdFilter) then begin
                        DocumentRecordRef.GetTable(GenJournalLine);
                        exit;
                    end;
                end;
            AttachmentEntityBufferDocType::"Sales Order", AttachmentEntityBufferDocType::"Sales Quote":
                if SalesHeader.GetBySystemId(DocumentIdFilter) then begin
                    DocumentRecordRef.GetTable(SalesHeader);
                    exit;
                end;
            AttachmentEntityBufferDocType::"Sales Invoice":
                begin
                    if SalesHeader.GetBySystemId(DocumentIdFilter) then
                        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then begin
                            DocumentRecordRef.GetTable(SalesHeader);
                            exit;
                        end;
                    if SalesInvoiceAggregator.GetSalesInvoiceHeaderFromId(DocumentIdFilter, SalesInvoiceHeader) then begin
                        DocumentRecordRef.GetTable(SalesInvoiceHeader);
                        exit;
                    end;
                end;
            AttachmentEntityBufferDocType::"Sales Credit Memo":
                begin
                    if SalesHeader.GetBySystemId(DocumentIdFilter) then
                        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then begin
                            DocumentRecordRef.GetTable(SalesHeader);
                            exit;
                        end;
                    if GraphMgtSalCrMemoBuf.GetSalesCrMemoHeaderFromId(DocumentIdFilter, SalesCrMemoHeader) then begin
                        DocumentRecordRef.GetTable(SalesCrMemoHeader);
                        exit;
                    end;
                end;
            AttachmentEntityBufferDocType::"Purchase Invoice":
                begin
                    if PurchaseHeader.GetBySystemId(DocumentIdFilter) then
                        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice then begin
                            DocumentRecordRef.GetTable(PurchaseHeader);
                            exit;
                        end;
                    if PurchInvAggregator.GetPurchaseInvoiceHeaderFromId(DocumentIdFilter, PurchInvHeader) then begin
                        DocumentRecordRef.GetTable(PurchInvHeader);
                        exit;
                    end;
                end;
            AttachmentEntityBufferDocType::"Purchase Order":
                if PurchaseHeader.GetBySystemId(DocumentIdFilter) then
                    if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then begin
                        DocumentRecordRef.GetTable(PurchaseHeader);
                        exit;
                    end;
            AttachmentEntityBufferDocType::"Purchase Credit Memo":
                begin
                    if PurchaseHeader.GetBySystemId(DocumentIdFilter) then
                        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then begin
                            DocumentRecordRef.GetTable(PurchaseHeader);
                            exit;
                        end;
                    if GraphMgtPurchCrMemo.GetPurchaseCrMemoHeaderFromId(DocumentIdFilter, PurchCrMemoHdr) then begin
                        DocumentRecordRef.GetTable(PurchCrMemoHdr);
                        exit;
                    end;
                end;
            AttachmentEntityBufferDocType::" ":
                ErrorMsg := DocumentIDorTypeNotSpecifiedForAttachmentsErr;
        end;
        ErrorMsg := DocumentTypeInvalidErr;
    end;

    local procedure FindIncomingDocument(var DocumentRecordRef: RecordRef; var IncomingDocument: Record "Incoming Document"): Boolean
    begin
        if IsPostedDocument(DocumentRecordRef) or IsGLEntry(DocumentRecordRef) then
            exit(IncomingDocument.FindByDocumentNoAndPostingDate(DocumentRecordRef, IncomingDocument));
        exit(IncomingDocument.FindFromIncomingDocumentEntryNo(DocumentRecordRef, IncomingDocument));
    end;

    local procedure FindOrCreateIncomingDocument(var DocumentRecordRef: RecordRef; var IncomingDocument: Record "Incoming Document")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        if FindIncomingDocument(DocumentRecordRef, IncomingDocument) then
            exit;

        IncomingDocument.Init();
        IncomingDocument."Related Record ID" := DocumentRecordRef.RecordId;

        if IsSalesInvoice(DocumentRecordRef) and IsPostedDocument(DocumentRecordRef) then begin
            DocumentRecordRef.SetTable(SalesInvoiceHeader);
            IncomingDocument.Description := CopyStr(SalesInvoiceHeader."Sell-to Customer Name", 1, MaxStrLen(IncomingDocument.Description));
            IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Sales Invoice";
            IncomingDocument."Document No." := SalesInvoiceHeader."No.";
            IncomingDocument."Posting Date" := SalesInvoiceHeader."Posting Date";
            IncomingDocument."Posted Date-Time" := CurrentDateTime;
            IncomingDocument.Status := IncomingDocument.Status::Posted;
            IncomingDocument.Posted := true;
            IncomingDocument.Insert(true);
            exit;
        end;

        if IsGeneralJournalLine(DocumentRecordRef) then begin
            DocumentRecordRef.SetTable(GenJournalLine);
            IncomingDocument.Description := CopyStr(GenJournalLine.Description, 1, MaxStrLen(IncomingDocument.Description));
            IncomingDocument."Document Type" := IncomingDocument."Document Type"::Journal;
            IncomingDocument.Insert(true);
            GenJournalLine."Incoming Document Entry No." := IncomingDocument."Entry No.";
            GenJournalLine.Modify();
            DocumentRecordRef.GetTable(GenJournalLine);
            exit;
        end;

        if IsGLEntry(DocumentRecordRef) then begin
            DocumentRecordRef.SetTable(GLEntry);
            IncomingDocument.Description := CopyStr(GLEntry.Description, 1, MaxStrLen(IncomingDocument.Description));
            IncomingDocument."Document No." := GLEntry."Document No.";
            IncomingDocument."Posting Date" := GLEntry."Posting Date";
            IncomingDocument.Status := IncomingDocument.Status::Posted;
            IncomingDocument.Posted := true;
            IncomingDocument.Insert(true);
            exit;
        end;

        if DocumentRecordRef.Number = DATABASE::"Sales Header" then begin
            DocumentRecordRef.SetTable(SalesHeader);
            IncomingDocument.Description := CopyStr(SalesHeader."Sell-to Customer Name", 1, MaxStrLen(IncomingDocument.Description));
            if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
                IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Sales Credit Memo"
            else
                IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Sales Invoice";
            IncomingDocument."Document No." := SalesHeader."No.";
            IncomingDocument.Insert(true);
            SalesHeader."Incoming Document Entry No." := IncomingDocument."Entry No.";
            SalesHeader.Modify();
            exit;
        end;

        if IsPurchaseInvoice(DocumentRecordRef) and IsPostedDocument(DocumentRecordRef) then begin
            DocumentRecordRef.SetTable(PurchInvHeader);
            IncomingDocument.Description := CopyStr(PurchInvHeader."Buy-from Vendor Name", 1, MaxStrLen(IncomingDocument.Description));
            IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Purchase Invoice";
            IncomingDocument."Posting Date" := PurchInvHeader."Posting Date";
            IncomingDocument."Document No." := PurchInvHeader."No.";
            IncomingDocument."Posted Date-Time" := CurrentDateTime;
            IncomingDocument.Status := IncomingDocument.Status::Posted;
            IncomingDocument.Posted := true;
            IncomingDocument.Insert(true);
            exit;
        end;

        if DocumentRecordRef.Number = DATABASE::"Purchase Header" then begin
            DocumentRecordRef.SetTable(PurchaseHeader);
            IncomingDocument.Description := CopyStr(PurchaseHeader."Buy-from Vendor Name", 1, MaxStrLen(IncomingDocument.Description));
            if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then
                IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Purchase Credit Memo"
            else
                IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Purchase Invoice";
            IncomingDocument."Document No." := PurchaseHeader."No.";
            IncomingDocument.Insert(true);
            PurchaseHeader."Incoming Document Entry No." := IncomingDocument."Entry No.";
            PurchaseHeader.Modify();
            exit;
        end;

        if IsSalesCreditMemo(DocumentRecordRef) and IsPostedDocument(DocumentRecordRef) then begin
            DocumentRecordRef.SetTable(SalesCrMemoHeader);
            IncomingDocument.Description := CopyStr(SalesCrMemoHeader."Sell-to Customer Name", 1, MaxStrLen(IncomingDocument.Description));
            IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Sales Credit Memo";
            IncomingDocument."Posting Date" := SalesCrMemoHeader."Posting Date";
            IncomingDocument."Document No." := SalesCrMemoHeader."No.";
            IncomingDocument."Posted Date-Time" := CurrentDateTime;
            IncomingDocument.Status := IncomingDocument.Status::Posted;
            IncomingDocument.Posted := true;
            IncomingDocument.Insert(true);
            exit;
        end;

        if IsPurchaseCreditMemo(DocumentRecordRef) and IsPostedDocument(DocumentRecordRef) then begin
            DocumentRecordRef.SetTable(PurchCrMemoHdr);
            IncomingDocument.Description := CopyStr(PurchCrMemoHdr."Buy-from Vendor Name", 1, MaxStrLen(IncomingDocument.Description));
            IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Purchase Credit Memo";
            IncomingDocument."Posting Date" := PurchCrMemoHdr."Posting Date";
            IncomingDocument."Document No." := PurchCrMemoHdr."No.";
            IncomingDocument."Posted Date-Time" := CurrentDateTime;
            IncomingDocument.Status := IncomingDocument.Status::Posted;
            IncomingDocument.Posted := true;
            IncomingDocument.Insert(true);
            exit;
        end;
    end;

    local procedure LoadLinkedAttachmentsToBuffer(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var IncomingDocument: Record "Incoming Document"; AttachmentIdFilter: Text)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        LoadContent: Boolean;
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        LoadContent := AttachmentIdFilter <> '';
        if LoadContent then
            IncomingDocumentAttachment.SetFilter(SystemId, AttachmentIdFilter);

        if not IncomingDocumentAttachment.FindSet() then
            exit;

        repeat
            if LoadContent then
                IncomingDocumentAttachment.CalcFields(Content); // Needed for transferring
            TransferFromIncomingDocumentAttachment(TempAttachmentEntityBuffer, IncomingDocumentAttachment);
            if not LoadContent then
                IncomingDocumentAttachment.CalcFields(Content); // Needed for getting content length
            TempBlob.FromRecord(IncomingDocumentAttachment, IncomingDocumentAttachment.FieldNo(Content));
            TempAttachmentEntityBuffer."Byte Size" := GetContentLength(TempBlob);
            TempAttachmentEntityBuffer.Modify(true);
        until IncomingDocumentAttachment.Next() = 0;
    end;

    local procedure LoadAttachmentsToBuffer(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; AttachmentIdFilter: Text)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        LoadContent: Boolean;
        LoadedAttachmentCounter: Integer;
    begin
        LoadedAttachmentCounter := 0;
        LoadContent := AttachmentIdFilter <> '';
        if LoadContent then
            IncomingDocumentAttachment.SetFilter(SystemId, AttachmentIdFilter);

        if not IncomingDocumentAttachment.FindSet() then
            exit;

        repeat
            if LoadedAttachmentCounter > AttachmentLoadUpperLimit() then
                Error(AttachmentLoadLimitExceededErr, Format(AttachmentLoadUpperLimit()));

            if LoadContent then
                IncomingDocumentAttachment.CalcFields(Content); // Needed for transferring
            TransferFromIncomingDocumentAttachment(TempAttachmentEntityBuffer, IncomingDocumentAttachment);
            LoadedAttachmentCounter += 1;
            if not LoadContent then
                IncomingDocumentAttachment.CalcFields(Content); // Needed for getting content length
            TempBlob.FromRecord(IncomingDocumentAttachment, IncomingDocumentAttachment.FieldNo(Content));
            TempAttachmentEntityBuffer."Byte Size" := GetContentLength(TempBlob);
            TempAttachmentEntityBuffer.Modify(true);
        until IncomingDocumentAttachment.Next() = 0;
    end;

    local procedure AttachmentLoadUpperLimit(): Integer
    begin
        exit(100000);
    end;

    local procedure LoadUnlinkedAttachmentsToBuffer(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; AttachmentIdFilter: Text)
    var
        UnlinkedAttachment: Record "Unlinked Attachment";
        TempBlob: Codeunit "Temp Blob";
        LoadContent: Boolean;
    begin
        LoadContent := AttachmentIdFilter <> '';
        if LoadContent then
            UnlinkedAttachment.SetFilter(Id, AttachmentIdFilter);

        if not UnlinkedAttachment.FindSet() then
            exit;

        repeat
            Clear(TempAttachmentEntityBuffer);
            if LoadContent then
                UnlinkedAttachment.CalcFields(Content); // Needed for transferring
            TransferFromUnlinkedAttachment(TempAttachmentEntityBuffer, UnlinkedAttachment);
            if not LoadContent then
                UnlinkedAttachment.CalcFields(Content); // Needed for getting content length
            TempBlob.FromRecord(UnlinkedAttachment, UnlinkedAttachment.FieldNo(Content));
            TempAttachmentEntityBuffer."Byte Size" := GetContentLength(TempBlob);
            TempAttachmentEntityBuffer.Modify(true);
        until UnlinkedAttachment.Next() = 0;
    end;

    local procedure TransferToIncomingDocumentAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var TempFieldBuffer: Record "Field Buffer" temporary; IsNewAttachment: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        TypeHelper: Codeunit "Type Helper";
        AttachmentRecordRef: RecordRef;
        UpdateFileName: Boolean;
        Name: Text[250];
        Extension: Text[30];
    begin
        if not IsNewAttachment then begin
            TempBlob.FromRecord(TempAttachmentEntityBuffer, TempAttachmentEntityBuffer.FieldNo(Content));
            TempAttachmentEntityBuffer."Byte Size" := GetContentLength(TempBlob);
        end;
        TempFieldBuffer.SetRange("Field ID", TempAttachmentEntityBuffer.FieldNo("File Name"));
        UpdateFileName := TempFieldBuffer.FindFirst();
        if UpdateFileName then
            FileNameToNameAndExtension(TempAttachmentEntityBuffer."File Name", Name, Extension);
        AttachmentRecordRef.GetTable(IncomingDocumentAttachment);
        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, TempAttachmentEntityBuffer, AttachmentRecordRef);
        AttachmentRecordRef.SetTable(IncomingDocumentAttachment);
        if UpdateFileName then begin
            IncomingDocumentAttachment.Validate(Name, Name);
            IncomingDocumentAttachment.Validate("File Extension", Extension);
        end;
    end;

    local procedure TransferToUnlinkedAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var UnlinkedAttachment: Record "Unlinked Attachment"; var TempFieldBuffer: Record "Field Buffer" temporary; IsNewAttachment: Boolean)
    var
        TypeHelper: Codeunit "Type Helper";
        AttachmentRecordRef: RecordRef;
    begin
        if not IsNewAttachment then
            TempAttachmentEntityBuffer.CalcFields(Content);
        AttachmentRecordRef.GetTable(UnlinkedAttachment);
        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, TempAttachmentEntityBuffer, AttachmentRecordRef);
        AttachmentRecordRef.SetTable(UnlinkedAttachment);
    end;

    procedure TransferFromIncomingDocumentAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    begin
        Clear(TempAttachmentEntityBuffer);
        TempAttachmentEntityBuffer.TransferFields(IncomingDocumentAttachment, true);
        TempAttachmentEntityBuffer.Id := IncomingDocumentAttachment.SystemId;
        TempAttachmentEntityBuffer."File Name" := NameAndExtensionToFileName(
            IncomingDocumentAttachment.Name, IncomingDocumentAttachment."File Extension");
        TransferDocumentTypeFromIncomingDocument(TempAttachmentEntityBuffer, IncomingDocumentAttachment);
        TempAttachmentEntityBuffer.Insert(true);
    end;

    local procedure TransferFromIncomingDocumentAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var IncomingDocumentAttachment: Record "Incoming Document Attachment"; DocumentId: Guid)
    begin
        Clear(TempAttachmentEntityBuffer);
        TempAttachmentEntityBuffer.TransferFields(IncomingDocumentAttachment, true);
        TempAttachmentEntityBuffer."Document Id" := DocumentId;
        TempAttachmentEntityBuffer.Id := IncomingDocumentAttachment.SystemId;
        TempAttachmentEntityBuffer."File Name" := NameAndExtensionToFileName(
            IncomingDocumentAttachment.Name, IncomingDocumentAttachment."File Extension");
        TransferDocumentTypeFromIncomingDocument(TempAttachmentEntityBuffer, IncomingDocumentAttachment);
        TempAttachmentEntityBuffer.Insert(true);
    end;

    procedure TransferFromUnlinkedAttachment(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var UnlinkedAttachment: Record "Unlinked Attachment")
    begin
        Clear(TempAttachmentEntityBuffer);
        TempAttachmentEntityBuffer.TransferFields(UnlinkedAttachment, true);
        TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::" ";
        TempAttachmentEntityBuffer.Id := UnlinkedAttachment.SystemId;
        TempAttachmentEntityBuffer.Insert(true);
    end;

    [Scope('Cloud')]
    procedure GetContentLength(var TempBlob: Codeunit "Temp Blob"): Integer
    var
        ContentInStream: InStream;
    begin
        if not TempBlob.HasValue() then
            exit(0);
        TempBlob.CreateInStream(ContentInStream);

        exit(GetContentLength(ContentInStream));
    end;

    local procedure GetContentLength(var ContentInStream: InStream): Integer
    var
        MemoryStream: DotNet MemoryStream;
        ContentLength: Integer;
    begin
        MemoryStream := MemoryStream.MemoryStream();
        CopyStream(MemoryStream, ContentInStream);
        ContentLength := MemoryStream.Length;
        MemoryStream.Close();
        exit(ContentLength);
    end;

    local procedure ThrowErrorIfAny(ErrorMsg: Text)
    begin
        if ErrorMsg <> '' then
            Error(ErrorMsg);
    end;

    local procedure FileNameToNameAndExtension(FileName: Text; var Name: Text[250]; var Extension: Text[30])
    var
        FileManagement: Codeunit "File Management";
    begin
        Extension := CopyStr(FileManagement.GetExtension(FileName), 1, MaxStrLen(Extension));
        Name := CopyStr(FileManagement.GetFileNameWithoutExtension(FileName), 1, MaxStrLen(Name));
    end;

    local procedure NameAndExtensionToFileName(Name: Text[250]; Extension: Text[30]): Text[250]
    begin
        if Extension <> '' then
            exit(StrSubstNo('%1.%2', Name, Extension));
        exit(Name);
    end;

    local procedure TransferDocumentTypeFromIncomingDocument(var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; IncomingDocumentAttachment: Record "Incoming Document Attachment")
    var
        IncomingDocument: Record "Incoming Document";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.");
        case IncomingDocument."Document Type" of
            IncomingDocument."Document Type"::Journal:
                TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::Journal;

            IncomingDocument."Document Type"::"Sales Credit Memo":
                TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Sales Credit Memo";

            IncomingDocument."Document Type"::"Sales Invoice":
                if SalesHeader.Get(IncomingDocument."Related Record ID") then begin
                    if SalesHeader."Incoming Document Entry No." = IncomingDocument."Entry No." then begin
                        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
                            TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Sales Order";
                        if SalesHeader."Document Type" = SalesHeader."Document Type"::Quote then
                            TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Sales Quote";
                        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then
                            TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Sales Invoice";
                        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
                            TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Sales Credit Memo";
                    end;
                end else
                    TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Sales Invoice";

            IncomingDocument."Document Type"::"Purchase Invoice":
                if PurchaseHeader.Get(IncomingDocument."Related Record ID") then begin
                    if PurchaseHeader."Incoming Document Entry No." = IncomingDocument."Entry No." then
                        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then
                            TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Purchase Order"
                        else
                            TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Purchase Invoice";
                end else
                    TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Purchase Invoice";

            IncomingDocument."Document Type"::"Purchase Credit Memo":
                TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::"Purchase Credit Memo";

            IncomingDocument."Document Type"::" ":
                TempAttachmentEntityBuffer."Document Type" := TempAttachmentEntityBuffer."Document Type"::" ";
        end;
    end;
}

