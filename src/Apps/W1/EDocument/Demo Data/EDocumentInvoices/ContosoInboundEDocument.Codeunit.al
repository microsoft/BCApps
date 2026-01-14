// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;
using System.Utilities;

/// <summary>
/// The purpose of the codeunit is to generate inbound e-document invoices
/// </summary>
codeunit 5429 "Contoso Inbound E-Document"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        EDocPurchaseHeader: Record "E-Document Purchase Header";
        EDocSamplePurchaseInvoice: Codeunit "E-Doc Sample Purchase Invoice";

    /// <summary>
    /// Adds a purchase header for the inbound e-document invoice to be created.
    /// </summary>
    procedure AddEDocPurchaseHeader(VendorNo: Code[20]; DocumentDate: Date; ExternalDocNo: Text[35]; TotalTaxAmount: Decimal)
    begin
        EDocSamplePurchaseInvoice.InitSamplePurchInvHeader(EDocPurchaseHeader, VendorNo, DocumentDate, ExternalDocNo, TotalTaxAmount);
    end;


    /// <summary>
    /// Adds a purchase header for the inbound e-document invoice to be created.
    /// </summary>
    procedure AddEDocPurchaseHeader(VendorNo: Code[20]; DocumentDate: Date; ExternalDocNo: Text[35])
    begin
        EDocSamplePurchaseInvoice.InitSamplePurchInvHeader(EDocPurchaseHeader, VendorNo, DocumentDate, ExternalDocNo, 0);
    end;

    /// <summary>
    /// Adds a purchase line for the inbound e-document invoice to be created.
    /// </summary>
    procedure AddEDocPurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; UnitOfMeasureCode: Code[10])
    begin
        AddEDocPurchaseLine(LineType, No, Description, Quantity, DirectUnitCost, '', UnitOfMeasureCode);
    end;

    /// <summary>
    /// Adds a purchase line for the inbound e-document invoice to be created.
    /// </summary>
    procedure AddEDocPurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; DeferralCode: Code[10]; UnitOfMeasureCode: Code[10])
    begin
        EDocPurchaseHeader.TestField("[BC] Vendor No.");
        EDocSamplePurchaseInvoice.AddLine(
          EDocPurchaseHeader, LineType, No, Description, Quantity, DirectUnitCost, DeferralCode, UnitOfMeasureCode);
    end;

    /// <summary>
    /// Generates the inbound e-document invoice based on the added header and lines.
    /// </summary>
    procedure Generate()
    var
        EDocPurchaseLine: Record "E-Document Purchase Line";
        EDocumentService: Record "E-Document Service";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        NoLinesAddedLbl: Label 'No lines have been added to lines buffer to generate inbound e-document invoice.';
    begin
        EDocPurchaseHeader.TestField("[BC] Vendor No.");
        EDocPurchaseLine.SetRange("E-Document Entry No.", 0);
        if EDocPurchaseLine.IsEmpty() then
            Error(NoLinesAddedLbl);
        EDocumentService := GetEDocService();
        TempBlob := SaveSamplePurchInvReportToPDF();
        EDocument := CreateEDocument(TempBlob, EDocumentService);
        ProcessEDocument(EDocument);
        PostPurchaseInvoice(EDocument."Entry No");
    end;

    local procedure SaveSamplePurchInvReportToPDF() TempBlob: Codeunit "Temp Blob"
    var
        EDocPurchaseLine: Record "E-Document Purchase Line";
        EDocSamplePurchInvPDF: Codeunit "E-Doc Sample Purch.Inv. PDF";
        CannotGeneratePdfLbl: Label 'Failed to generate PDF for Sample Purchase Invoice';
    begin
        EDocSamplePurchInvPDF.AddHeader(EDocPurchaseHeader);
        EDocPurchaseLine.SetRange("E-Document Entry No.", EDocPurchaseHeader."E-Document Entry No.");
        EDocPurchaseLine.FindSet();
        repeat
            EDocSamplePurchInvPDF.AddLine(EDocPurchaseLine);
        until EDocPurchaseLine.Next() = 0;
        TempBlob := EDocSamplePurchInvPDF.GeneratePDF();
        if TempBlob.Length() = 0 then
            Error(CannotGeneratePdfLbl);
    end;

    local procedure CreateEDocument(TempBlob: Codeunit "Temp Blob"; EDocumentService: Record "E-Document Service") EDocument: Record "E-Document"
    var
        EDocPurchaseLine, NewEDocPurchaseLine : Record "E-Document Purchase Line";
        EDocImport: Codeunit "E-Doc. Import";
        ResInStream: InStream;
        FileName: Text;
        Total: Decimal;
    begin
        TempBlob.CreateInStream(ResInStream);
        FileName := 'PurchaseInvoice' + EDocPurchaseHeader."Sales Invoice No." + '.pdf';
        EDocImport.CreateFromType(
            EDocument, EDocumentService, Enum::"E-Doc. File Format"::PDF, FileName, ResInStream);
        EDocPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocPurchaseHeader.Insert();
        EDocument."Structure Data Impl." := Enum::"Structure Received E-Doc."::"Demo Invoice";
        EDocument."Structured Data Entry No." := InsertEDocDataStorageWithPurchHeaderTableView();
        EDocument.Modify();

        EDocPurchaseLine.SetRange("E-Document Entry No.", 0);
        EDocPurchaseLine.FindSet();
        repeat
            NewEDocPurchaseLine := EDocPurchaseLine;
            NewEDocPurchaseLine."E-Document Entry No." := EDocPurchaseHeader."E-Document Entry No.";
            NewEDocPurchaseLine.Insert();
            Total += EDocPurchaseLine."Sub Total";
        until EDocPurchaseLine.Next() = 0;
        EDocPurchaseHeader."Sub Total" := Total;
        EDocPurchaseHeader.Total := EDocPurchaseHeader."Sub Total" + EDocPurchaseHeader."Total VAT";
        EDocPurchaseHeader.Modify();
        EDocPurchaseLine.DeleteAll();
    end;

    local procedure ProcessEDocument(EDocument: Record "E-Document")
    var
        EDocImportParameters: Record "E-Doc. Import Parameters";
        EDocImport: Codeunit "E-Doc. Import";
    begin
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Finish draft";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);
    end;

    local procedure PostPurchaseInvoice(EDocEntryNo: Integer)
    var
        PurchHeader: Record "Purchase Header";
        EDocument: Record "E-Document";
        PurchPost: Codeunit "Purch.-Post";
    begin
        EDocument.Get(EDocEntryNo);
        EDocument.TestField("Document Record ID");
        PurchHeader.Get(EDocument."Document Record ID");
        PurchHeader.Invoice := true;
        PurchHeader.Receive := true;
        PurchHeader.Modify(true);
        PurchPost.Run(PurchHeader);
    end;

    local procedure InsertEDocDataStorageWithPurchHeaderTableView(): Integer
    var
        EDocumentDataStorage: Record "E-Doc. Data Storage";
        Content: Text;
        InStream: InStream;
    begin
        if EDocumentDataStorage.FindLast() then
            EDocumentDataStorage."Entry No." := EDocumentDataStorage."Entry No." + 1;
        EDocumentDataStorage.Init();
        EDocPurchaseHeader.TestField("E-Document Entry No.");
        Content := EDocPurchaseHeader.GetView();
        EDocumentDataStorage."Data Storage".CreateInStream(InStream);
        EDocumentDataStorage."Data Storage Size" := StrLen(Content);
        EDocumentDataStorage.Insert();
        exit(EDocumentDataStorage."Entry No.");
    end;

    local procedure GetEDocService() EDocumentService: Record "E-Document Service"
    var
        CreateEDocDemodataService: Codeunit "Create E-Doc DemoData Service";
    begin
        EDocumentService.Get(CreateEDocDemodataService.EDocumentServiceCode());
    end;

}