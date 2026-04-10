// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Service.Archive;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;

codeunit 6466 "Serv. Page Management"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Page Management", 'OnConditionalCardPageIDNotFound', '', true, false)]
    local procedure OnConditionalCardPageIDNotFound(RecordRef: RecordRef; var CardPageID: Integer);
    begin
        case RecordRef.Number of
            Database::"Service Header":
                CardPageID := GetServiceHeaderPageID(RecordRef);
            Database::"Service Contract Header":
                CardPageID := GetServiceContractHeaderPageID(RecordRef);
            Database::"Service Header Archive":
                CardPageID := GetServiceHeaderArchivePageID(RecordRef);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Page Management", OnBeforeGetConditionalListPageID, '', false, false)]
    local procedure OnBeforeGetConditionalListPageID(RecRef: RecordRef; var PageID: Integer; var IsHandled: Boolean; CheckDocumentTypeFilter: Boolean)
    var
        ConditionalListPageID: Integer;
    begin
        if IsHandled then
            exit;

        case RecRef.Number of
            Database::"Service Header":
                ConditionalListPageID := GetServiceHeaderListPageID(RecRef, CheckDocumentTypeFilter);
            Database::"Service Contract Header":
                ConditionalListPageID := GetServiceContractHeaderListPageID(RecRef, CheckDocumentTypeFilter);
            Database::"Service Header Archive":
                ConditionalListPageID := GetServiceHeaderArchiveListPageID(RecRef, CheckDocumentTypeFilter);
        end;

        if ConditionalListPageID <> 0 then begin
            PageID := ConditionalListPageID;
            IsHandled := true;
        end;
    end;

    local procedure GetServiceHeaderArchivePageID(RecRef: RecordRef): Integer
    var
        ServiceHeaderArchive: Record "Service Header Archive";
    begin
        RecRef.SetTable(ServiceHeaderArchive);
        case ServiceHeaderArchive."Document Type" of
            ServiceHeaderArchive."Document Type"::Quote:
                exit(Page::"Service Quote Archive");
            ServiceHeaderArchive."Document Type"::Order:
                exit(Page::"Service Order Archive");
        end;
    end;

    local procedure GetServiceHeaderPageID(RecRef: RecordRef) Result: Integer
    var
        ServiceHeader: Record "Service Header";
    begin
        RecRef.SetTable(ServiceHeader);
        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::Quote:
                Result := PAGE::"Service Quote";
            ServiceHeader."Document Type"::Order:
                Result := PAGE::"Service Order";
            ServiceHeader."Document Type"::Invoice:
                Result := PAGE::"Service Invoice";
            ServiceHeader."Document Type"::"Credit Memo":
                Result := PAGE::"Service Credit Memo";
        end;
        OnAfterGetServiceHeaderPageID(RecRef, ServiceHeader, Result);
    end;

    local procedure GetServiceContractHeaderPageID(RecRef: RecordRef): Integer
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        RecRef.SetTable(ServiceContractHeader);
        case ServiceContractHeader."Contract Type" of
            ServiceContractHeader."Contract Type"::Contract:
                exit(PAGE::"Service Contract");
            ServiceContractHeader."Contract Type"::Quote:
                exit(PAGE::"Service Contract Quote");
            ServiceContractHeader."Contract Type"::Template:
                exit(PAGE::"Service Contract Template");
        end;
    end;

    local procedure GetServiceHeaderListPageID(RecRef: RecordRef; CheckDocumentTypeFilter: Boolean): Integer
    var
        ServiceHeader: Record "Service Header";
        ServiceDocumentType: Enum "Service Document Type";
    begin
        RecRef.SetTable(ServiceHeader);
        if CheckDocumentTypeFilter then begin
            if ServiceHeader.GetFilter("Document Type") = '' then
                exit(0);
            if not Evaluate(ServiceDocumentType, ServiceHeader.GetFilter("Document Type")) then
                exit(0);
        end else begin
            if IsNullGuid(ServiceHeader.SystemId) then
                exit(0);
            ServiceDocumentType := ServiceHeader."Document Type";
        end;

        case ServiceDocumentType of
            ServiceHeader."Document Type"::Quote:
                exit(PAGE::"Service Quotes");
            ServiceHeader."Document Type"::Order:
                exit(PAGE::"Service Orders");
            ServiceHeader."Document Type"::Invoice:
                exit(PAGE::"Service Invoices");
            ServiceHeader."Document Type"::"Credit Memo":
                exit(PAGE::"Service Credit Memos");
        end;
    end;

    local procedure GetServiceHeaderArchiveListPageID(RecRef: RecordRef; CheckDocumentTypeFilter: Boolean): Integer
    var
        ServiceHeaderArchive: Record "Service Header Archive";
        ServiceDocumentType: Enum "Service Document Type";
    begin
        RecRef.SetTable(ServiceHeaderArchive);
        if CheckDocumentTypeFilter then begin
            if ServiceHeaderArchive.GetFilter("Document Type") = '' then
                exit(0);
            if not Evaluate(ServiceDocumentType, ServiceHeaderArchive.GetFilter("Document Type")) then
                exit(0);
        end else begin
            if IsNullGuid(ServiceHeaderArchive.SystemId) then
                exit(0);
            ServiceDocumentType := ServiceHeaderArchive."Document Type";
        end;

        case ServiceDocumentType of
            ServiceHeaderArchive."Document Type"::Quote:
                exit(PAGE::"Service Quote Archives");
            ServiceHeaderArchive."Document Type"::Order:
                exit(PAGE::"Service Order Archives");
        end;
    end;

    local procedure GetServiceContractHeaderListPageID(RecRef: RecordRef; CheckDocumentTypeFilter: Boolean): Integer
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractType: Enum "Service Contract Type";
    begin
        RecRef.SetTable(ServiceContractHeader);
        if CheckDocumentTypeFilter then begin
            if ServiceContractHeader.GetFilter("Contract Type") = '' then
                exit(0);
            if not Evaluate(ServiceContractType, ServiceContractHeader.GetFilter("Contract Type")) then
                exit(0);
        end else begin
            if IsNullGuid(ServiceContractHeader.SystemId) then
                exit(0);
            ServiceContractType := ServiceContractHeader."Contract Type";
        end;

        case ServiceContractType of
            ServiceContractHeader."Contract Type"::Contract:
                exit(PAGE::"Service Contracts");
            ServiceContractHeader."Contract Type"::Quote:
                exit(PAGE::"Service Contract Quotes");
            ServiceContractHeader."Contract Type"::Template:
                exit(PAGE::"Service Contract Template List");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetServiceHeaderPageID(RecRef: RecordRef; ServiceHeader: Record Microsoft.Service.Document."Service Header"; var Result: Integer)
    begin
    end;

}