// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using System.Utilities;

codeunit 3369 "EDoc CFDI Read Draft MX" implements IStructuredFormatReader
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        CFDIImport: Codeunit "EDoc CFDI Import MX";
    begin
        // ParseBasicInfo populates the local EDocument copy (vendor, date, amounts, UUID, document type).
        // Do NOT call EDocument.Modify() here — the framework calls it after ReadIntoDraft returns
        // to save "Process Draft Impl.", and a prior Modify() would advance the timestamp causing a conflict.
        CFDIImport.ParseBasicInfo(EDocument, TempBlob);
        CFDIImport.ParseLines(EDocument, TempBlob);

        EDocumentPurchaseHeader.InsertForEDocument(EDocument);
        PopulatePurchaseHeader(EDocumentPurchaseHeader, EDocument);

        if EDocument."Document Type" = EDocument."Document Type"::"Purchase Credit Memo" then
            exit("E-Doc. Process Draft"::"Purchase Credit Memo");
        exit("E-Doc. Process Draft"::"Purchase Invoice");
    end;

    local procedure PopulatePurchaseHeader(var EDocumentPurchaseHeader: Record "E-Document Purchase Header"; EDocument: Record "E-Document")
    begin
        EDocumentPurchaseHeader."Vendor Company Name" := EDocument."Bill-to/Pay-to Name";
        EDocumentPurchaseHeader."[BC] Vendor No." := EDocument."Bill-to/Pay-to No.";
        EDocumentPurchaseHeader."Document Date" := EDocument."Document Date";
        EDocumentPurchaseHeader."Sub Total" := EDocument."Amount Excl. VAT";
        EDocumentPurchaseHeader.Total := EDocument."Amount Incl. VAT";
        EDocumentPurchaseHeader."Currency Code" := EDocument."Currency Code";
        // "Sales Invoice No." (field 5) is mapped by the framework to PurchaseHeader."Vendor Invoice No."
        EDocumentPurchaseHeader."Sales Invoice No." := EDocument."Incoming E-Document No.";
        // MX extension field — carries the UUID to the subscriber that sets PurchaseHeader."Fiscal Invoice Number PAC"
        EDocumentPurchaseHeader."Fiscal Invoice Number PAC" := CopyStr(
            EDocument."Source Details", 1, MaxStrLen(EDocumentPurchaseHeader."Fiscal Invoice Number PAC"));
        EDocumentPurchaseHeader.Modify();
    end;

    procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
    begin
    end;
}
