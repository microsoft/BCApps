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
        EDocumentPurchaseHeader."Sales Invoice No." := EDocument."Incoming E-Document No.";
        EDocumentPurchaseHeader."Fiscal Invoice Number PAC" := CopyStr(
            EDocument."Source Details", 1, MaxStrLen(EDocumentPurchaseHeader."Fiscal Invoice Number PAC"));
        EDocumentPurchaseHeader.Modify();
    end;

    procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"E-Document", OnBeforeModifyEvent, '', false, false)]
    local procedure FillFromDraftOnBeforeEDocumentModify(var Rec: Record "E-Document"; var xRec: Record "E-Document"; RunTrigger: Boolean)
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
    begin
        if Rec.IsTemporary() then
            exit;
        if Rec.Direction <> Rec.Direction::Incoming then
            exit;
        if Rec."Read into Draft Impl." <> "E-Doc. Read into Draft"::"CFDI MX" then
            exit;
        if Rec."Source Details" <> '' then
            exit;
        if not EDocumentPurchaseHeader.Get(Rec."Entry No") then
            exit;

        Rec."Source Details" := EDocumentPurchaseHeader."Fiscal Invoice Number PAC";
        if Rec."Incoming E-Document No." = '' then
            Rec."Incoming E-Document No." := EDocumentPurchaseHeader."Sales Invoice No.";
        if Rec."Amount Excl. VAT" = 0 then
            Rec."Amount Excl. VAT" := EDocumentPurchaseHeader."Sub Total";
        if Rec."Amount Incl. VAT" = 0 then
            Rec."Amount Incl. VAT" := EDocumentPurchaseHeader.Total;
        if Rec."Currency Code" = '' then
            Rec."Currency Code" := EDocumentPurchaseHeader."Currency Code";
    end;
}
