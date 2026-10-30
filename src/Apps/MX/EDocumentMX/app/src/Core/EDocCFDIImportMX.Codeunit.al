// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using System.IO;
using System.Utilities;

codeunit 3368 "EDoc CFDI Import MX"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure ParseBasicInfo(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    var
        GLSetup: Record "General Ledger Setup";
        TempXMLBuffer: Record "XML Buffer" temporary;
        DocStream: InStream;
        RootPath: Text;
        DocType: Text;
        RFC: Text;
        VendorNo: Code[20];
        DocDate: Date;
        AmountExclVAT, AmountInclVAT : Decimal;
    begin
        TempXMLBuffer.DeleteAll();
        TempBlob.CreateInStream(DocStream, TextEncoding::UTF8);
        TempXMLBuffer.LoadFromStream(DocStream);

        GLSetup.Get();
        EDocument.Direction := EDocument.Direction::Incoming;

        RootPath := GetRootPath(TempXMLBuffer);

        DocType := GetAttr(TempXMLBuffer, RootPath + '/@TipoDeComprobante');
        case DocType of
            InvoiceTok:
                EDocument."Document Type" := EDocument."Document Type"::"Purchase Invoice";
            CreditMemoTok:
                EDocument."Document Type" := EDocument."Document Type"::"Purchase Credit Memo";
            else
                Error(UnsupportedDocTypeErr, DocType);
        end;

        EDocument."Incoming E-Document No." := CopyStr(
            BuildFolioSerie(TempXMLBuffer, RootPath), 1, MaxStrLen(EDocument."Incoming E-Document No."));

        EDocument."Source Details" := CopyStr(
            GetAttr(TempXMLBuffer, RootPath + '/cfdi:Complemento/tfd:TimbreFiscalDigital/@UUID'),
            1, MaxStrLen(EDocument."Source Details"));

        if ParseCFDIDate(GetAttr(TempXMLBuffer, RootPath + '/@Fecha'), DocDate) then
            EDocument."Document Date" := DocDate;

        EvaluateDecimal(GetAttr(TempXMLBuffer, RootPath + '/@SubTotal'), AmountExclVAT);
        EDocument."Amount Excl. VAT" := AmountExclVAT;

        EvaluateDecimal(GetAttr(TempXMLBuffer, RootPath + '/@Total'), AmountInclVAT);
        EDocument."Amount Incl. VAT" := AmountInclVAT;

        SetCurrencyCode(EDocument, GLSetup."LCY Code", GetAttr(TempXMLBuffer, RootPath + '/@Moneda'));

        RFC := GetAttr(TempXMLBuffer, RootPath + '/cfdi:Emisor/@Rfc');
        EDocument."Bill-to/Pay-to Name" := CopyStr(
            GetAttr(TempXMLBuffer, RootPath + '/cfdi:Emisor/@Nombre'), 1, MaxStrLen(EDocument."Bill-to/Pay-to Name"));

        VendorNo := FindVendorByRFC(RFC);
        if VendorNo <> '' then
            EDocument."Bill-to/Pay-to No." := VendorNo;
    end;

    procedure ParseLines(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        DocStream: InStream;
        RootPath: Text;
        ConceptoEntryNos: List of [Integer];
        EntryNo: Integer;
        LineNo: Integer;
    begin
        TempXMLBuffer.DeleteAll();
        TempBlob.CreateInStream(DocStream, TextEncoding::UTF8);
        TempXMLBuffer.LoadFromStream(DocStream);

        RootPath := GetRootPath(TempXMLBuffer);

        TempXMLBuffer.Reset();
        TempXMLBuffer.SetRange(Type, TempXMLBuffer.Type::Element);
        TempXMLBuffer.SetRange(Path, RootPath + '/cfdi:Conceptos/cfdi:Concepto');
        if TempXMLBuffer.FindSet() then
            repeat
                ConceptoEntryNos.Add(TempXMLBuffer."Entry No.");
            until TempXMLBuffer.Next() = 0;

        foreach EntryNo in ConceptoEntryNos do begin
            LineNo += 10000;
            ParseConceptoLine(TempXMLBuffer, EntryNo, EDocument."Entry No", LineNo);
        end;
    end;

    local procedure ParseConceptoLine(var TempXMLBuffer: Record "XML Buffer" temporary; ConceptoEntryNo: Integer; EDocEntryNo: Integer; LineNo: Integer)
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        Cantidad, ValorUnitario, Importe, Descuento : Decimal;
    begin
        EvaluateDecimal(GetConceptoAttr(TempXMLBuffer, ConceptoEntryNo, 'Cantidad'), Cantidad);
        EvaluateDecimal(GetConceptoAttr(TempXMLBuffer, ConceptoEntryNo, 'ValorUnitario'), ValorUnitario);
        EvaluateDecimal(GetConceptoAttr(TempXMLBuffer, ConceptoEntryNo, 'Importe'), Importe);
        EvaluateDecimal(GetConceptoAttr(TempXMLBuffer, ConceptoEntryNo, 'Descuento'), Descuento);

        EDocumentPurchaseLine.Init();
        EDocumentPurchaseLine."E-Document Entry No." := EDocEntryNo;
        EDocumentPurchaseLine."Line No." := LineNo;
        EDocumentPurchaseLine.Description := CopyStr(
            GetConceptoAttr(TempXMLBuffer, ConceptoEntryNo, 'Descripcion'), 1, MaxStrLen(EDocumentPurchaseLine.Description));
        EDocumentPurchaseLine."Product Code" := CopyStr(
            GetConceptoAttr(TempXMLBuffer, ConceptoEntryNo, 'NoIdentificacion'), 1, MaxStrLen(EDocumentPurchaseLine."Product Code"));
        EDocumentPurchaseLine."Unit of Measure" := CopyStr(
            GetConceptoAttr(TempXMLBuffer, ConceptoEntryNo, 'Unidad'), 1, MaxStrLen(EDocumentPurchaseLine."Unit of Measure"));
        EDocumentPurchaseLine.Quantity := Cantidad;
        EDocumentPurchaseLine."Unit Price" := ValorUnitario;
        EDocumentPurchaseLine."Sub Total" := Importe - Descuento;
        EDocumentPurchaseLine."Total Discount" := Descuento;
        EDocumentPurchaseLine.Insert();
    end;

    local procedure GetConceptoAttr(var TempXMLBuffer: Record "XML Buffer" temporary; ParentEntryNo: Integer; AttrName: Text): Text
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.SetRange(Type, TempXMLBuffer.Type::Attribute);
        TempXMLBuffer.SetRange("Parent Entry No.", ParentEntryNo);
        TempXMLBuffer.SetRange(Name, AttrName);
        if TempXMLBuffer.FindFirst() then
            exit(TempXMLBuffer.Value);
        exit('');
    end;

    local procedure GetAttr(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text): Text
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.SetRange(Type, TempXMLBuffer.Type::Attribute);
        TempXMLBuffer.SetRange(Path, XPath);
        if TempXMLBuffer.FindFirst() then
            exit(TempXMLBuffer.Value);
        exit('');
    end;

    local procedure GetRootPath(var TempXMLBuffer: Record "XML Buffer" temporary): Text
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.SetRange(Type, TempXMLBuffer.Type::Element);
        TempXMLBuffer.SetRange("Parent Entry No.", 0);
        if TempXMLBuffer.FindFirst() then
            exit(TempXMLBuffer.Path);
        Error(InvalidXMLErr);
    end;

    local procedure BuildFolioSerie(var TempXMLBuffer: Record "XML Buffer" temporary; RootPath: Text): Text
    var
        Serie: Text;
        Folio: Text;
    begin
        Serie := GetAttr(TempXMLBuffer, RootPath + '/@Serie');
        Folio := GetAttr(TempXMLBuffer, RootPath + '/@Folio');
        if Serie <> '' then
            exit(Serie + '-' + Folio);
        exit(Folio);
    end;

    local procedure ParseCFDIDate(DateTimeText: Text; var ResultDate: Date): Boolean
    var
        DateText: Text;
    begin
        // CFDI Fecha format: YYYY-MM-DDTHH:MM:SS — extract date portion
        if DateTimeText = '' then
            exit(false);
        DateText := CopyStr(DateTimeText, 1, 10);
        exit(Evaluate(ResultDate, DateText, 9));
    end;

    local procedure EvaluateDecimal(ValueText: Text; var Result: Decimal)
    begin
        if ValueText = '' then
            exit;
        Evaluate(Result, ValueText, 9);
    end;

    local procedure SetCurrencyCode(var EDocument: Record "E-Document"; LCYCode: Code[10]; CFDICurrencyCode: Text)
    var
        CurrCode: Code[10];
    begin
        CurrCode := CopyStr(CFDICurrencyCode, 1, MaxStrLen(CurrCode));
        if (CurrCode = LCYCode) or (CurrCode = '') then
            EDocument."Currency Code" := ''
        else
            EDocument."Currency Code" := CurrCode;
    end;

    local procedure FindVendorByRFC(RFC: Text): Code[20]
    var
        Vendor: Record Vendor;
    begin
        if RFC = '' then
            exit('');

        Vendor.SetRange("RFC No.", CopyStr(RFC, 1, MaxStrLen(Vendor."RFC No.")));
        if Vendor.FindFirst() then
            exit(Vendor."No.");

        Vendor.Reset();
        Vendor.SetRange("VAT Registration No.", CopyStr(RFC, 1, MaxStrLen(Vendor."VAT Registration No.")));
        if Vendor.FindFirst() then
            exit(Vendor."No.");

        exit('');
    end;

    var
        InvoiceTok: Label 'I', Locked = true;
        CreditMemoTok: Label 'E', Locked = true;
        UnsupportedDocTypeErr: Label 'CFDI document type %1 is not supported for import. Only Invoice (I) and Credit Memo (E) are supported.', Comment = '%1 = TipoDeComprobante value';
        InvalidXMLErr: Label 'The file is not a valid CFDI XML document.';
}
