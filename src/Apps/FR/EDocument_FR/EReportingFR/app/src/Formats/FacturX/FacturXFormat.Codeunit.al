// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.Purchases.Document;
using System.IO;
using System.Utilities;

codeunit 10979 "Factur-X Format" implements "E-Document"
{
    Access = Internal;

    var
        ImportFacturXFR: Codeunit "Import Factur-X";

    procedure Check(var SourceDocumentHeader: RecordRef; EDocumentService: Record "E-Document Service"; EDocumentProcessingPhase: Enum "E-Document Processing Phase")
    var
        FREDocHelpers: Codeunit "EDoc. Helpers";
    begin
        FREDocHelpers.CheckSIRENNotEmpty();
        FREDocHelpers.CheckSIRETNotEmpty();
        FREDocHelpers.CheckSellerCountryCode();
        FREDocHelpers.CheckBuyerElectronicAddress(SourceDocumentHeader);
    end;

    procedure Create(EDocumentService: Record "E-Document Service"; var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        EDocErrorHelper: Codeunit "E-Document Error Helper";
    begin
        case EDocument."Document Type" of
            EDocument."Document Type"::"Sales Invoice",
            EDocument."Document Type"::"Service Invoice",
            EDocument."Document Type"::"Sales Credit Memo",
            EDocument."Document Type"::"Service Credit Memo",
            EDocument."Document Type"::"Issued Reminder",
            EDocument."Document Type"::"Issued Finance Charge Memo":
                CreateSourceDocumentBlob(SourceDocumentHeader, TempBlob);
            else
                EDocErrorHelper.LogSimpleErrorMessage(EDocument, StrSubstNo(DocumentTypeNotSupportedErr, EDocument.FieldCaption("Document Type"), EDocument."Document Type"));
        end;
    end;

    procedure CreateBatch(EDocService: Record "E-Document Service"; var EDocument: Record "E-Document"; var SourceDocumentHeaders: RecordRef; var SourceDocumentsLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    begin
        // Factur-X FR generates individual PDF files, so batch processing iterates through source document headers
        // Each document is processed independently, and the final TempBlob contains the last document's PDF
        Clear(TempBlob);

        if SourceDocumentHeaders.FindSet() then
            repeat
                CreateSourceDocumentBlob(SourceDocumentHeaders, TempBlob);
            until SourceDocumentHeaders.Next() = 0;
    end;

#pragma warning disable AL0432
    procedure GetBasicInfoFromReceivedDocument(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    begin
        ImportFacturXFR.ParseBasicInfo(EDocument, TempBlob);
    end;

    procedure GetCompleteInfoFromReceivedDocument(var EDocument: Record "E-Document"; var CreatedDocumentHeader: RecordRef; var CreatedDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        TempPurchaseHeader: Record "Purchase Header" temporary;
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        ImportFacturXFR.ParseCompleteInfo(EDocument, TempPurchaseHeader, TempPurchaseLine, TempBlob);

        CreatedDocumentHeader.GetTable(TempPurchaseHeader);
        CreatedDocumentLines.GetTable(TempPurchaseLine);
    end;
#pragma warning restore AL0432

    local procedure CreateSourceDocumentBlob(var SourceDocumentHeader: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        TempRecordExportBuffer: Record "Record Export Buffer" temporary;
        ExportFacturXFRDocument: Codeunit "Export Factur-X Document";
    begin
        TempRecordExportBuffer.RecordID := SourceDocumentHeader.RecordId;
        TempRecordExportBuffer.Insert();

        ExportFacturXFRDocument.ExportDocument(TempRecordExportBuffer);
        if not TempRecordExportBuffer."File Content".HasValue() then
            exit;
        TempBlob.FromRecord(TempRecordExportBuffer, TempRecordExportBuffer.FieldNo("File Content"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"E-Document Service", 'OnAfterGetDefaultFileExtension', '', false, false)]
    local procedure HandleOnAfterGetDefaultFileExtension(EDocumentService: Record "E-Document Service"; var FileExtension: Text)
    var
        PDFFileTypeTok: Label '.pdf', Locked = true;
    begin
        if EDocumentService."Document Format" <> EDocumentService."Document Format"::"Factur-X FR" then
            exit;

        FileExtension := PDFFileTypeTok;
    end;

    [EventSubscriber(ObjectType::Table, Database::"E-Document Log", 'OnBeforeExportDataStorage', '', false, false)]
    local procedure HandleOnBeforeExportDataStorage(EDocumentLog: Record "E-Document Log"; var FileName: Text)
    var
        EDocumentService: Record "E-Document Service";
        EDOCLogFileTxt: Label 'E-Document_Log_%1', Comment = '%1 = E-Doc. Entry No', Locked = true;
    begin
        if not EDocumentService.Get(EDocumentLog."Service Code") then
            exit;

        if EDocumentService."Document Format" <> EDocumentService."Document Format"::"Factur-X FR" then
            exit;

        FileName := StrSubstNo(EDOCLogFileTxt, EDocumentLog."E-Doc. Entry No");
        FileName += EDocumentService.GetDefaultFileExtension();
    end;

    [EventSubscriber(ObjectType::Table, Database::"E-Document Service", 'OnAfterValidateEvent', 'Document Format', false, false)]
    local procedure OnAfterValidateDocumentFormat(var Rec: Record "E-Document Service"; var xRec: Record "E-Document Service"; CurrFieldNo: Integer)
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        if Rec."Document Format" <> Rec."Document Format"::"Factur-X FR" then
            exit;

        EDocServiceSupportedType.SetRange("E-Document Service Code", Rec.Code);
        if not EDocServiceSupportedType.IsEmpty() then
            exit;

        EDocServiceSupportedType.Init();
        EDocServiceSupportedType."E-Document Service Code" := Rec.Code;

        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Sales Invoice";
        EDocServiceSupportedType.Insert();

        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Sales Credit Memo";
        EDocServiceSupportedType.Insert();

        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Service Invoice";
        EDocServiceSupportedType.Insert();

        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Service Credit Memo";
        EDocServiceSupportedType.Insert();

        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Issued Reminder";
        EDocServiceSupportedType.Insert();

        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Issued Finance Charge Memo";
        EDocServiceSupportedType.Insert();

        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Purchase Invoice";
        EDocServiceSupportedType.Insert();

        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Purchase Credit Memo";
        EDocServiceSupportedType.Insert();
    end;

    var
        DocumentTypeNotSupportedErr: Label '%1 %2 is not supported by Factur-X FR Format.', Comment = '%1 = Document Type caption, %2 = Document Type';
}
