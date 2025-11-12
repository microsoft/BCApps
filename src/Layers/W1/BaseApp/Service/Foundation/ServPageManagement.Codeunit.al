// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Service.Document;
using Microsoft.Service.Contract;
using Microsoft.Service.Archive;

codeunit 6466 "Serv. Page Management"
{
#if not CLEAN25
    var
        PageManagement: Codeunit "Page Management";
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Page Management", 'OnConditionalCardPageIDNotFound', '', false, false)]
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
#if not CLEAN25
        PageManagement.RunOnAfterGetServiceHeaderPageID(RecRef, ServiceHeader, Result);
#endif
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetServiceHeaderPageID(RecRef: RecordRef; ServiceHeader: Record Microsoft.Service.Document."Service Header"; var Result: Integer)
    begin
    end;

}
