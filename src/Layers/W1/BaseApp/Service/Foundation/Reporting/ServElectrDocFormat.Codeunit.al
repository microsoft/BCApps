// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Sales.Peppol;

codeunit 6464 "Serv. Electr. Doc. Format"
{

    procedure ValidateElectronicServiceDocument(ServiceHeader: Record "Service Header"; ElectronicFormat: Code[20])
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        if not ElectronicDocumentFormat.Get(ElectronicFormat, "Electronic Document Format Usage"::"Service Validation") then
            exit; // no validation required

        CODEUNIT.Run(ElectronicDocumentFormat."Codeunit ID", ServiceHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Electronic Document Format", 'OnGetDocumentFormatUsageCaseElse', '', false, false)]
    local procedure OnGetDocumentUsageCaseElse(DocumentRecordRef: RecordRef; var DocumentFormatUsage: Enum "Electronic Document Format Usage"; var IsHandled: Boolean)
    begin
        case DocumentRecordRef.Number of
            Database::"Service Invoice Header":
                begin
                    DocumentFormatUsage := "Electronic Document Format Usage"::"Service Invoice";
                    IsHandled := true;
                end;
            Database::"Service Cr.Memo Header":
                begin
                    DocumentFormatUsage := "Electronic Document Format Usage"::"Service Credit Memo";
                    IsHandled := true;
                end;
            Database::"Service Header":
                begin
                    GetDocumentUsageForServiceHeader(DocumentRecordRef, DocumentFormatUsage);
                    IsHandled := true;
                end;
        end;
    end;

    local procedure GetDocumentUsageForServiceHeader(DocumentRecordRef: RecordRef; var DocumentFormatUsage: Enum "Electronic Document Format Usage")
    var
        ServiceHeader: Record "Service Header";
#if not CLEAN25
        ElectronitDocumentFormat: Record "Electronic Document Format";
        DocumentUsage: Option;
#endif
        IsHandled: Boolean;
    begin
        DocumentRecordRef.SetTable(ServiceHeader);

        IsHandled := false;
        OnBeforeGetDocumentFormatUsageForServiceHeader(ServiceHeader, DocumentFormatUsage, IsHandled);
#if not CLEAN25
        DocumentUsage := DocumentFormatUsage.AsInteger();
        ElectronitDocumentFormat.RunOnBeforeGetDocumentUsageForServiceHeader(ElectronitDocumentFormat, ServiceHeader, DocumentUsage, IsHandled);
        if DocumentFormatUsage.AsInteger() <> DocumentUsage then
            DocumentFormatUsage := "Electronic Document Format Usage".FromInteger(DocumentUsage);
#endif
        if IsHandled then
            exit;

        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::Invoice:
                DocumentFormatUsage := "Electronic Document Format Usage"::"Service Invoice";
            ServiceHeader."Document Type"::"Credit Memo":
                DocumentFormatUsage := "Electronic Document Format Usage"::"Service Credit Memo";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDocumentFormatUsageForServiceHeader(ServiceHeader: Record "Service Header"; var DocumentUsage: Enum "Electronic Document Format Usage"; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Electronic Document Format", 'OnGetDocumentNoCaseElse', '', false, false)]
    local procedure OnGetDocumentNoCaseElse(DocumentVariant: Variant; var DocumentNo: Code[20]; var IsHandled: Boolean; DocumentRecordRef: RecordRef)
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        case DocumentRecordRef.Number of
            DATABASE::"Service Invoice Header":
                begin
                    ServiceInvoiceHeader := DocumentVariant;
                    DocumentNo := ServiceInvoiceHeader."No.";
                    IsHandled := true;
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoHeader := DocumentVariant;
                    DocumentNo := ServiceCrMemoHeader."No.";
                    IsHandled := true;
                end;
            DATABASE::"Service Header":
                begin
                    ServiceHeader := DocumentVariant;
                    DocumentNo := ServiceHeader."No.";
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Electronic Document Format", 'OnGetDocumentTypeCaseElse', '', false, false)]
    local procedure OnGetDocumentTypeCaseElse(DocumentVariant: Variant; var DocumentTypeText: Text[50]; DocumentRecordRef: RecordRef)
    var
        DummyServiceHeader: Record "Service Header";
    begin
        case DocumentRecordRef.Number of
            DATABASE::"Service Invoice Header":
                DocumentTypeText := Format(DummyServiceHeader."Document Type"::Invoice);
            DATABASE::"Service Cr.Memo Header":
                DocumentTypeText := Format(DummyServiceHeader."Document Type"::"Credit Memo");
            DATABASE::"Service Header":
                begin
                    DummyServiceHeader := DocumentVariant;
                    if DummyServiceHeader."Document Type" = DummyServiceHeader."Document Type"::Quote then
                        DocumentTypeText := Format(DummyServiceHeader."Document Type"::Quote);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Electronic Document Format", 'OnAfterShouldLogUptake', '', false, false)]
    local procedure OnAfterShouldLogUptake(var ElectronicDocumentFormat: Record "Electronic Document Format"; var Result: Boolean)
    begin
        if ElectronicDocumentFormat."Codeunit ID" in [
            Codeunit::"PEPPOL Service Validation", Codeunit::"Exp. Serv.Inv. PEPPOL BIS3.0", Codeunit::"Exp. Serv.CrM. PEPPOL BIS3.0"]
        then
            Result := true;
    end;
}