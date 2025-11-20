// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Service.History;
using Microsoft.Service.Document;

codeunit 6468 "Serv. Doc. Exchange Mgt."
{
    var
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
        AlreadyUsedInDocHdrErr: Label 'The incoming document has already been assigned to %1 %2 (%3).', Comment = '%1=document type, %2=document number, %3=table name, e.g. Sales Header.';
        CannotResendErr: Label 'You cannot send this electronic document because it is already delivered or in progress.';
        DocumentTypeEnumErr: Label '%1 Document Type %2 enum cannot be converted to %3 Document Type enum.', Comment = '%1 - Sales, %2 - Invoice, %3 - Service';
        NotSupportedSalesErr: Label 'Sales documents of type %1 are not supported.', Comment = '%1 will be Sales/Purchase Header. %2 will be invoice, Credit Memo.';
        SalesTxt: Label 'Sales';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Doc. Exch. Links", 'OnBeforeUpdateDocumentRecord', '', false, false)]
    local procedure OnBeforeUpdateDocumentRecord(DocRecRef: RecordRef; DocIdentifier: Text; DocOrigIdentifier: Text; var IsHandled: Boolean)
    begin
        case DocRecRef.Number of
            Database::"Service Invoice Header":
                begin
                    SetServiceInvoiceDocSent(DocRecRef, DocIdentifier, DocOrigIdentifier);
                    IsHandled := true;
                end;
            Database::"Service Cr.Memo Header":
                begin
                    SetServiceCrMemoDocSent(DocRecRef, DocIdentifier, DocOrigIdentifier);
                    IsHandled := true;
                end;
        end;
    end;

    local procedure SetServiceInvoiceDocSent(DocRecRef: RecordRef; DocIdentifier: Text; DocOriginalIdentifier: Text)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        DocRecRef.SetTable(ServiceInvoiceHeader);
        ServiceInvoiceHeader.Find();
        ServiceInvoiceHeader.Validate("Document Exchange Identifier",
          CopyStr(DocIdentifier, 1, MaxStrLen(ServiceInvoiceHeader."Document Exchange Identifier")));
        ServiceInvoiceHeader.Validate("Doc. Exch. Original Identifier",
          CopyStr(DocOriginalIdentifier, 1, MaxStrLen(ServiceInvoiceHeader."Doc. Exch. Original Identifier")));
        ServiceInvoiceHeader.Validate("Document Exchange Status", ServiceInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        ServiceInvoiceHeader.Modify(true);
    end;

    local procedure SetServiceCrMemoDocSent(DocRecRef: RecordRef; DocIdentifier: Text; DocOriginalIdentifier: Text)
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        DocRecRef.SetTable(ServiceCrMemoHeader);
        ServiceCrMemoHeader.Find();
        ServiceCrMemoHeader.Validate("Document Exchange Identifier",
          CopyStr(DocIdentifier, 1, MaxStrLen(ServiceCrMemoHeader."Document Exchange Identifier")));
        ServiceCrMemoHeader.Validate("Doc. Exch. Original Identifier",
          CopyStr(DocOriginalIdentifier, 1, MaxStrLen(ServiceCrMemoHeader."Doc. Exch. Original Identifier")));
        ServiceCrMemoHeader.Validate("Document Exchange Status", ServiceCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        ServiceCrMemoHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    internal procedure CheckAndUpdateDocExchServiceInvoiceStatus(ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        NewStatus: Enum "Service Document Exchange Status";
    begin
        NewStatus := MapDocExchStatusToServiceInvStatus(
            DocExchServiceMgt.GetDocumentStatus(ServiceInvoiceHeader.RecordId, ServiceInvoiceHeader."Document Exchange Identifier", ServiceInvoiceHeader."Doc. Exch. Original Identifier"));
        if NewStatus <> ServiceInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service" then begin
            ServiceInvoiceHeader.Validate(ServiceInvoiceHeader."Document Exchange Status", NewStatus);
            ServiceInvoiceHeader.Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    internal procedure CheckAndUpdateDocExchServiceCrMemoStatus(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        NewStatus: Enum "Service Document Exchange Status";
    begin
        NewStatus := MapDocExchStatusToServiceCMStatus(
            DocExchServiceMgt.GetDocumentStatus(ServiceCrMemoHeader.RecordId, ServiceCrMemoHeader."Document Exchange Identifier", ServiceCrMemoHeader."Doc. Exch. Original Identifier"));
        if NewStatus <> ServiceCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service" then begin
            ServiceCrMemoHeader.Validate(ServiceCrMemoHeader."Document Exchange Status", NewStatus);
            ServiceCrMemoHeader.Modify(true);
        end;
    end;

    local procedure MapDocExchStatusToServiceInvStatus(DocExchStatus: Text): Enum "Service Document Exchange Status"
    begin
        case UpperCase(DocExchStatus) of
            'FAILED':
                exit("Service Document Exchange Status"::"Delivery Failed");
            'SENT':
                exit("Service Document Exchange Status"::"Delivered to Recipient");
            'PENDING_CONNECTION':
                exit("Service Document Exchange Status"::"Pending Connection to Recipient");
            else
                exit("Service Document Exchange Status"::"Sent to Document Exchange Service");
        end;
    end;

    local procedure MapDocExchStatusToServiceCMStatus(DocExchStatus: Text): Enum "Service Document Exchange Status"
    begin
        case UpperCase(DocExchStatus) of
            'FAILED':
                exit("Service Document Exchange Status"::"Delivery Failed");
            'SENT':
                exit("Service Document Exchange Status"::"Delivered to Recipient");
            'PENDING_CONNECTION':
                exit("Service Document Exchange Status"::"Pending Connection to Recipient");
            else
                exit("Service Document Exchange Status"::"Sent to Document Exchange Service");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Doc. Exch. Serv.- Doc. Status", 'OnAfterCheckPostedDocs', '', false, false)]
    local procedure OnAfterCheckPostedDocs()
    begin
        CheckPostedServiceInvoices();
        CheckPostedServiceCrMemos();
    end;

    local procedure CheckPostedServiceInvoices()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetFilter(
            "Document Exchange Status",
            StrSubstNo('%1|%2',
                ServiceInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service",
                ServiceInvoiceHeader."Document Exchange Status"::"Pending Connection to Recipient"));
        if ServiceInvoiceHeader.FindSet() then
            repeat
                CheckAndUpdateDocExchServiceInvoiceStatus(ServiceInvoiceHeader);
                Commit();
            until ServiceInvoiceHeader.Next() = 0;
    end;

    local procedure CheckPostedServiceCrMemos()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetFilter(
            "Document Exchange Status",
            StrSubstNo('%1|%2',
                ServiceCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service",
                ServiceCrMemoHeader."Document Exchange Status"::"Pending Connection to Recipient"));
        if ServiceCrMemoHeader.FindSet() then
            repeat
                CheckAndUpdateDocExchServiceCrMemoStatus(ServiceCrMemoHeader);
                Commit();
            until ServiceCrMemoHeader.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Doc. Exch. Serv.- Doc. Status", 'OnBeforeCheckAndUpdateDocExchStatus', '', false, false)]
    local procedure OnBeforeCheckAndUpdateDocExchStatus(DocRecRef: RecordRef; var IsHandled: Boolean)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        case DocRecRef.Number of
            DATABASE::"Service Invoice Header":
                begin
                    DocRecRef.SetTable(ServiceInvoiceHeader);
                    CheckAndUpdateDocExchServiceInvoiceStatus(ServiceInvoiceHeader);
                    IsHandled := true;
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    DocRecRef.SetTable(ServiceCrMemoHeader);
                    CheckAndUpdateDocExchServiceCrMemoStatus(ServiceCrMemoHeader);
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Doc. Exch. Serv.- Doc. Status", 'OnAfterIsSupportedByDefaultDocExchStatusDrillDown', '', false, false)]
    local procedure OnAfterIsSupportedByDefaultDocExchStatusDrillDown(DocRecRef: RecordRef; var IsSupported: Boolean)
    begin
        IsSupported := IsSupported or
            (DocRecRef.Number in [DATABASE::"Service Invoice Header", DATABASE::"Service Cr.Memo Header"]);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Doc. Exch. Service Mgt.", 'OnBeforeCheckDocumentStatus', '', false, false)]
    local procedure OnBeforeCheckDocumentStatus(DocRecRef: RecordRef; var IsHandled: Boolean)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        case DocRecRef.Number of
            DATABASE::"Service Invoice Header":
                begin
                    DocRecRef.SetTable(ServiceInvoiceHeader);
                    if ServiceInvoiceHeader."Document Exchange Status" in
                       [ServiceInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service",
                        ServiceInvoiceHeader."Document Exchange Status"::"Delivered to Recipient",
                        ServiceInvoiceHeader."Document Exchange Status"::"Pending Connection to Recipient"]
                    then
                        Error(CannotResendErr);
                    IsHandled := true;
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    DocRecRef.SetTable(ServiceCrMemoHeader);
                    if ServiceCrMemoHeader."Document Exchange Status" in
                       [ServiceCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service",
                        ServiceCrMemoHeader."Document Exchange Status"::"Delivered to Recipient",
                        ServiceCrMemoHeader."Document Exchange Status"::"Pending Connection to Recipient"]
                    then
                        Error(CannotResendErr);
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Doc. Exch. Service Mgt.", 'OnBeforeGetPostSalesURL', '', false, false)]
    local procedure OnBeforeGetPostSalesURL(DocRecRef: RecordRef; var URL: Text; sender: Codeunit "Doc. Exch. Service Mgt.")
    begin
        case DocRecRef.Number of
            DATABASE::"Service Invoice Header":
                URL := sender.GetPostSalesInvURL();
            DATABASE::"Service Cr.Memo Header":
                URL := sender.GetPostSalesCrMemoURL();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document Attachment", 'OnBeforeSetFiltersFromMainRecord', '', false, false)]
    local procedure OnBeforeSetFiltersFromMainRecord(var MainRecordRef: RecordRef; var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IsHandled: Boolean)
    var
        ServiceHeader: Record "Service Header";
    begin
        case MainRecordRef.Number of
            DATABASE::"Service Header":
                begin
                    MainRecordRef.SetTable(ServiceHeader);
                    IncomingDocumentAttachment.SetRange("Document Table No. Filter", MainRecordRef.Number);
                    IncomingDocumentAttachment.SetRange("Document Type Filter", GetServiceIncomingDocumentType(ServiceHeader."Document Type"));
                    IncomingDocumentAttachment.SetRange("Document No. Filter", ServiceHeader."No.");
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Import Attachment - Inc. Doc.", 'OnBeforeCreateNewSalesPurchIncomingDoc', '', false, false)]
    local procedure OnBeforeCreateNewSalesPurchIncomingDoc(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IncomingDocEntryNo: Integer; var IsHandled: Boolean)
    var
        IncomingDocument: Record "Incoming Document";
        ServiceHeader: Record "Service Header";
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
        DocTableNo: Integer;
        DocType: Enum "Incoming Document Type";
        DocNo: Code[20];
    begin
        if IncomingDocumentAttachment.GetFilter("Document Table No. Filter") <> '' then
            DocTableNo := IncomingDocumentAttachment.GetRangeMin("Document Table No. Filter");
        if IncomingDocumentAttachment.GetFilter("Document Type Filter") <> '' then
            DocType := IncomingDocumentAttachment.GetRangeMin("Document Type Filter");
        if IncomingDocumentAttachment.GetFilter("Document No. Filter") <> '' then
            DocNo := IncomingDocumentAttachment.GetRangeMin("Document No. Filter");

        case DocTableNo of
            DATABASE::"Service Header":
                begin
                    ServiceHeader.Get(DocType, DocNo);
                    ImportAttachmentIncDoc.CreateIncomingDocumentExtended(IncomingDocumentAttachment, IncomingDocument, 0D, '', ServiceHeader.RecordId);
                    ServiceHeader."Incoming Document Entry No." := IncomingDocument."Entry No.";
                    ServiceHeader.Modify();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Import Attachment - Inc. Doc.", 'OnBeforeGetUnpostedSalesPurchaseDocType', '', false, false)]
    local procedure OnBeforeGetUnpostedSalesPurchaseDocType(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IncomingDocument: Record "Incoming Document"; var RelatedDocumentType: Enum "Incoming Related Document Type");
    var
        ServiceHeader: Record "Service Header";
    begin
        case IncomingDocumentAttachment.GetRangeMin("Document Table No. Filter") of
            DATABASE::"Service Header":
                begin
                    if IncomingDocumentAttachment.GetRangeMin("Document Type Filter") = ServiceHeader."Document Type"::"Credit Memo" then
                        RelatedDocumentType := IncomingDocument."Document Type"::"Service Credit Memo";
                    RelatedDocumentType := IncomingDocument."Document Type"::"Service Invoice";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document", 'OnTestIfAlreadyExists', '', false, false)]
    local procedure OnTestIfAlreadyExists(IncomingRelatedDocumentType: Enum "Incoming Related Document Type"; EntryNo: Integer)
    var
        ServiceHeader: Record "Service Header";
    begin
        case IncomingRelatedDocumentType of
            IncomingRelatedDocumentType::"Service Invoice",
            IncomingRelatedDocumentType::"Service Credit Memo":
                begin
                    ServiceHeader.SetRange("Incoming Document Entry No.", EntryNo);
                    if ServiceHeader.FindFirst() then
                        Error(AlreadyUsedInDocHdrErr, ServiceHeader."Document Type", ServiceHeader."No.", ServiceHeader.TableCaption());
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document", 'OnAfterClearRelatedRecords', '', false, false)]
    local procedure OnAfterClearRelatedRecords(IncomingRelatedDocumentType: Enum "Incoming Related Document Type"; EntryNo: Integer)
    var
        ServiceHeader: Record "Service Header";
    begin
        case IncomingRelatedDocumentType of
            IncomingRelatedDocumentType::"Service Invoice",
            IncomingRelatedDocumentType::"Service Credit Memo":
                begin
                    ServiceHeader.SetRange("Incoming Document Entry No.", EntryNo);
                    ServiceHeader.ModifyAll("Incoming Document Entry No.", 0, true);
                end;
        end;
    end;

    procedure SetServiceDoc(var ServiceHeader: Record "Service Header"; var IncomingDocument: Record "Incoming Document")
    begin
        if ServiceHeader."Incoming Document Entry No." = 0 then
            exit;
        IncomingDocument.Get(ServiceHeader."Incoming Document Entry No.");
        IncomingDocument.TestReadyForProcessing();
        IncomingDocument.TestIfAlreadyExists();
        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::Invoice:
                IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Service Invoice";
            ServiceHeader."Document Type"::"Credit Memo":
                IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Service Credit Memo";
        end;
        IncomingDocument.Modify();
        if not IncomingDocument.DocLinkExists(ServiceHeader) then
            ServiceHeader.AddLink(IncomingDocument.GetURL(), IncomingDocument.Description);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document", 'OnUpdateDocumentFieldsOnAfterUpdateDocuments', '', false, false)]
    local procedure OnUpdateDocumentFieldsOnAfterUpdateDocuments(var IncomingDocument: Record "Incoming Document"; var DocExists: Boolean)
    var
        ServiceHeader: Record "Service Header";
    begin
        // If service
        ServiceHeader.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        if ServiceHeader.FindFirst() then begin
            case ServiceHeader."Document Type" of
                ServiceHeader."Document Type"::Invoice:
                    IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Service Invoice";
                ServiceHeader."Document Type"::"Credit Memo":
                    IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Service Credit Memo";
                else
                    Error(NotSupportedSalesErr, Format(ServiceHeader."Document Type"));
            end;
            IncomingDocument."Document No." := ServiceHeader."No.";
            DocExists := true;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document", 'OnAfterFindUnpostedRecord', '', false, false)]
    local procedure OnAfterFindUnpostedRecord(var RelatedRecord: Variant; var RecordFound: Boolean; var IncomingDocument: Record "Incoming Document")
    var
        ServiceHeader: Record "Service Header";
    begin
        case IncomingDocument."Document Type" of
            IncomingDocument."Document Type"::"Service Invoice",
            IncomingDocument."Document Type"::"Service Credit Memo":
                begin
                    ServiceHeader.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
                    if ServiceHeader.FindFirst() then begin
                        RelatedRecord := ServiceHeader;
                        RecordFound := true;
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document", 'OnAfterGetRelatedRecordCaption', '', false, false)]
    local procedure OnAfterGetRelatedRecordCaption(var RelatedRecordRef: RecordRef; var RecCaption: Text)
    var
        IncomingDocument: Record "Incoming Document";
    begin
        case RelatedRecordRef.Number of
            Database::"Service Header":
                RecCaption := StrSubstNo('%1 %2', SalesTxt, IncomingDocument.GetRecordCaption(RelatedRecordRef));
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document", 'OnFindByDocumentNoAndPostingDateOnSetFilters', '', false, false)]
    local procedure OnFindByDocumentNoAndPostingDateOnSetFilters(var IncomingDocument: Record "Incoming Document"; MainRecordRef: RecordRef)
    var
        ServiceHeader: Record "Service Header";
    begin
        case MainRecordRef.Number of
            Database::"Service Invoice Header":
                begin
                    IncomingDocument.SetRange("Document Type", IncomingDocument."Document Type"::"Service Invoice");
                    IncomingDocument.SetRange(Posted, true);
                end;
            Database::"Service Cr.Memo Header":
                begin
                    IncomingDocument.SetRange("Document Type", IncomingDocument."Document Type"::"Service Credit Memo");
                    IncomingDocument.SetRange(Posted, true);
                end;
            Database::"Service Header":
                begin
                    MainRecordRef.SetTable(ServiceHeader);
                    case ServiceHeader."Document Type" of
                        ServiceHeader."Document Type"::Invoice, ServiceHeader."Document Type"::Order, ServiceHeader."Document Type"::Quote:
                            begin
                                IncomingDocument.SetRange("Document Type", IncomingDocument."Document Type"::"Service Invoice");
                                IncomingDocument.SetRange(Posted, false);
                            end;
                        ServiceHeader."Document Type"::"Credit Memo":
                            begin
                                IncomingDocument.SetRange("Document Type", IncomingDocument."Document Type"::"Service Credit Memo");
                                IncomingDocument.SetRange(Posted, false);
                            end;
                    end;
                end;
        end;
    end;

    procedure GetServiceIncomingDocumentType(ServiceDocumentType: Enum "Service Document Type") IncomingDocumentType: Enum "Incoming Document Type"
    var
        IsHandled: Boolean;
    begin
        case ServiceDocumentType of
            ServiceDocumentType::Quote:
                exit(IncomingDocumentType::Quote);
            ServiceDocumentType::Order:
                exit(IncomingDocumentType::Order);
            ServiceDocumentType::Invoice:
                exit(IncomingDocumentType::Invoice);
            ServiceDocumentType::"Credit Memo":
                exit(IncomingDocumentType::"Credit Memo");
            else begin
                IsHandled := false;
                OnGetServiceIncomingDocumentType(ServiceDocumentType, IncomingDocumentType, IsHandled);
                if not IsHandled then
                    error(DocumentTypeEnumErr, 'Service', ServiceDocumentType, 'Incoming');
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetServiceIncomingDocumentType(ServiceDocumentType: Enum "Service Document Type"; var IncomingDocumentType: Enum "Incoming Document Type"; var IsHandled: Boolean)
    begin
    end;
}
