// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using System.Utilities;

codeunit 3352 "EDoc CFDI MX" implements "E-Document"
{

    procedure Check(var SourceDocumentHeader: RecordRef; EDocumentService: Record "E-Document Service"; EDocumentProcessingPhase: Enum "E-Document Processing Phase")
    var
        EDocCartaPorteValidationMX: Codeunit "EDoc Carta Porte Validation MX";
        EDocCFDIValidationMX: Codeunit "EDoc CFDI Validation MX";
        SalesHeader: Record "Sales Header";
    begin
        case SourceDocumentHeader.Number of
            Database::"Sales Header":
                begin
                    SourceDocumentHeader.SetTable(SalesHeader);
                    if ShouldValidateSalesHeaderAsCartaPorte(SalesHeader) then begin
                        SourceDocumentHeader.GetTable(SalesHeader);
                        EDocCartaPorteValidationMX.CheckShipmentDocument(SourceDocumentHeader);
                    end else begin
                        SourceDocumentHeader.GetTable(SalesHeader);
                        EDocCFDIValidationMX.CheckSalesDocument(SourceDocumentHeader);
                    end;
                end;
            Database::"Sales Invoice Header":
                EDocCFDIValidationMX.CheckSalesDocument(SourceDocumentHeader);
            Database::"Sales Cr.Memo Header":
                EDocCFDIValidationMX.CheckSalesDocument(SourceDocumentHeader);
            Database::"Service Invoice Header":
                EDocCFDIValidationMX.CheckServiceDocument(SourceDocumentHeader);
            Database::"Service Cr.Memo Header":
                EDocCFDIValidationMX.CheckServiceDocument(SourceDocumentHeader);
            Database::"Service Header":
                EDocCFDIValidationMX.CheckServiceDocument(SourceDocumentHeader);
            Database::"Cust. Ledger Entry":
                EDocCFDIValidationMX.CheckPaymentDocument(SourceDocumentHeader);
            Database::"Sales Shipment Header":
                EDocCartaPorteValidationMX.CheckShipmentDocument(SourceDocumentHeader);
            Database::"Transfer Shipment Header":
                EDocCartaPorteValidationMX.CheckTransferDocument(SourceDocumentHeader);
            Database::"Transfer Header":
                EDocCartaPorteValidationMX.CheckTransferDocument(SourceDocumentHeader);
            else
                Error(SourceDocumentNotSupportedErr, SourceDocumentHeader.Caption());
        end;

        EDocCFDIValidationMX.CheckCompanyInfo();
        EDocCFDIValidationMX.CheckCertificate(EDocumentService);
    end;

    local procedure ShouldValidateSalesHeaderAsCartaPorte(SalesHeader: Record "Sales Header"): Boolean
    begin
        exit(SalesHeader."Document Type" = SalesHeader."Document Type"::Order);
    end;

    /// <summary>
    /// Use it to create a blob representing the posted document.
    /// </summary>
    /// <param name="EDocumentService">The document service used to send the document electronically.</param>
    /// <param name="EDocument">Electronic document.</param>
    /// <param name="SourceDocumentHeader">The source document header as a recored ref.</param>
    /// <param name="SourceDocumentLines">The source document lines as a recored ref.</param>
    /// <param name="TempBlob">Tempblob that should contatin the exported document in the correspondant format.</param>
    procedure Create(EDocumentService: Record "E-Document Service"; var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        ExportInterfactura: Codeunit "Export Interfactura MX";
    begin
        OnBeforeExport(SourceDocumentHeader, SourceDocumentLines, TempBlob);
        ExportInterfactura.Export(SourceDocumentHeader, SourceDocumentLines, EDocument, TempBlob, false);
        OnAfterExport(SourceDocumentHeader, SourceDocumentLines, TempBlob);
    end;

    /// <summary>
    /// Use it to create a blob representing a batch of posted documents.
    /// </summary>
    /// <param name="EDocumentService">The document service used to send the document electronically.</param>
    /// <param name="EDocuments">Electronic document.</param>
    /// <param name="SourceDocumentHeaders">The source document header as a recored ref.</param>
    /// <param name="SourceDocumentsLines">The source document lines as a recored ref.</param>
    /// <param name="TempBlob">Tempblob that should contatin the exported document in the correspondant format.</param>
    procedure CreateBatch(EDocumentService: Record "E-Document Service"; var EDocuments: Record "E-Document"; var SourceDocumentHeaders: RecordRef; var SourceDocumentsLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        ExportInterfactura: Codeunit "Export Interfactura MX";
    begin
        ExportInterfactura.Export(SourceDocumentHeaders, SourceDocumentsLines, EDocuments, TempBlob, true);
    end;

    ///
    /// The following methods are to receive a document from an endpoint and prepare it to be a BC
    ///

    /// <summary>
    /// Use it to get the basic information of an E-Document from received blob.
    /// </summary>
    /// <param name="EDocument">Electronic document.</param>
    /// <param name="TempBlob">Contians received blob from external service</param>
    procedure GetBasicInfoFromReceivedDocument(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    begin
    end;

    procedure GetCompleteInfoFromReceivedDocument(var EDocument: Record "E-Document"; var CreatedDocumentHeader: RecordRef; var CreatedDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    begin
    end;

    var
        SourceDocumentNotSupportedErr: Label 'The source document %1 is not supported for CFDI MX.', Comment = '%1 = source document caption';

    [EventSubscriber(ObjectType::Table, Database::"E-Document Service", 'OnAfterValidateEvent', 'Document Format', false, false)]
    local procedure OnAfterValidateDocumentFormat(var Rec: Record "E-Document Service"; var xRec: Record "E-Document Service"; CurrFieldNo: Integer)
    begin
        if Rec."Document Format" <> Rec."Document Format"::CFDI then
            exit;

        EnsureSupportedTypes(Rec.Code);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Export", 'OnBeforeEDocumentCheck', '', false, false)]
    local procedure OnBeforeEDocumentCheck(RecRef: RecordRef; EDocumentProcessingPhase: Enum "E-Document Processing Phase"; var IsHandled: Boolean)
    var
        EDocumentService: Record "E-Document Service";
    begin
        EDocumentService.SetRange("Document Format", EDocumentService."Document Format"::CFDI);
        if EDocumentService.FindSet() then
            repeat
                EnsureSupportedTypes(EDocumentService.Code);
            until EDocumentService.Next() = 0;
    end;

    local procedure EnsureSupportedTypes(EDocumentServiceCode: Code[20])
    begin
        EnsureSupportedType(EDocumentServiceCode, Enum::"E-Document Type"::"Sales Invoice");
        EnsureSupportedType(EDocumentServiceCode, Enum::"E-Document Type"::"Sales Credit Memo");
        EnsureSupportedType(EDocumentServiceCode, Enum::"E-Document Type"::"Service Invoice");
        EnsureSupportedType(EDocumentServiceCode, Enum::"E-Document Type"::"Service Credit Memo");
        EnsureSupportedType(EDocumentServiceCode, Enum::"E-Document Type"::"Sales Shipment");
        EnsureSupportedType(EDocumentServiceCode, Enum::"E-Document Type"::"Transfer Shipment");
    end;

    local procedure EnsureSupportedType(EDocumentServiceCode: Code[20]; SourceDocumentType: Enum "E-Document Type")
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocumentServiceCode);
        EDocServiceSupportedType.SetRange("Source Document Type", SourceDocumentType);
        if not EDocServiceSupportedType.IsEmpty() then
            exit;

        EDocServiceSupportedType.Init();
        EDocServiceSupportedType."E-Document Service Code" := EDocumentServiceCode;
        EDocServiceSupportedType."Source Document Type" := SourceDocumentType;
        EDocServiceSupportedType.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforePurchaseHeaderModify(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentService: Record "E-Document Service";
    begin
        if IsNullGuid(Rec."E-Document Link") then
            exit;
        if Rec."Fiscal Invoice Number PAC" <> '' then
            exit;
        if not EDocument.GetBySystemId(Rec."E-Document Link") then
            exit;
        if not EDocumentService.Get(EDocument.Service) then
            exit;
        if EDocumentService."Document Format" <> EDocumentService."Document Format"::CFDI then
            exit;
        if not EDocumentPurchaseHeader.Get(EDocument."Entry No") then
            exit;
        Rec."Fiscal Invoice Number PAC" := EDocumentPurchaseHeader."Fiscal Invoice Number PAC";
    end;

    [EventSubscriber(ObjectType::Table, Database::"E-Document", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeEDocumentInsert(var Rec: Record "E-Document"; RunTrigger: Boolean)
    var
        EDocumentService: Record "E-Document Service";
    begin
        if Rec.Direction <> Rec.Direction::Incoming then
            exit;
        if not EDocumentService.Get(Rec.Service) then
            exit;
        if EDocumentService."Document Format" <> EDocumentService."Document Format"::CFDI then
            exit;
        Rec."Structure Data Impl." := "Structure Received E-Doc."::"Already Structured";
        Rec."Read into Draft Impl." := "E-Doc. Read into Draft"::"CFDI MX";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExport(var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExport(var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    begin
    end;

}