// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using System.Utilities;
using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Foundation.Address;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.eServices.EDocument.Processing;
using Microsoft.eServices.EDocument.Processing.Import;

/// <summary>
/// The purpose of the codeunit is to generate inbound e-document invoices
/// </summary>
codeunit 5429 "Contoso Inbound E-Document"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PurchHeader: Record "Purchase Header";

    /// <summary>
    /// Adds a purchase header for the inbound e-document invoice to be created.
    /// </summary>
    procedure AddEDocPurchaseHeader(VendorNo: Code[20]; DocumentDate: Date; ExternalDocNo: Text[35])
    begin
        Clear(PurchHeader);
        PurchHeader."Document Type" := PurchHeader."Document Type"::Invoice;
        PurchHeader.Insert(true);
        PurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchHeader.Validate("Posting Date", DocumentDate);
        PurchHeader.Validate("Vendor Invoice No.", ExternalDocNo);
        PurchHeader.Modify(true);
    end;

    /// <summary>
    /// Adds a purchase line for the inbound e-document invoice to be created.
    /// </summary>
    procedure AddEDocPurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; DeferralCode: Code[10]; UnitOfMeasureCode: Code[10])
    begin
        AddEDocPurchaseLine(LineType, No, '', Description, Quantity, DirectUnitCost, DeferralCode, UnitOfMeasureCode);
    end;

    /// <summary>
    /// Adds a purchase line for the inbound e-document invoice to be created.
    /// </summary>
    procedure AddEDocPurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; UnitOfMeasureCode: Code[10])
    begin
        AddEDocPurchaseLine(LineType, No, '', Description, Quantity, DirectUnitCost, '', UnitOfMeasureCode);
    end;

    /// <summary>
    /// Adds a purchase line for the inbound e-document invoice to be created.
    /// </summary>
    procedure AddEDocPurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; TaxGroupCode: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; UnitOfMeasureCode: Code[10])
    begin
        AddEDocPurchaseLine(LineType, No, TaxGroupCode, Description, Quantity, DirectUnitCost, '', UnitOfMeasureCode);
    end;

    /// <summary>
    /// Adds a purchase line for the inbound e-document invoice to be created.
    /// </summary>
    procedure AddEDocPurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; TaxGroupCode: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; DeferralCode: Code[10]; UnitOfMeasureCode: Code[10])
    var
        PurchLine: Record "Purchase Line";
        LineNo: Integer;
    begin
        PurchHeader.TestField("No.");

        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if PurchLine.FindLast() then
            LineNo := PurchLine."Line No.";
        LineNo += 10000;

        PurchLine."Document Type" := PurchLine."Document Type"::Invoice;
        PurchLine."Document No." := PurchHeader."No.";
        PurchLine."Line No." := LineNo;
        PurchLine.Insert(true);
        PurchLine.Validate(Type, LineType);
        PurchLine.Validate("No.", No);
        if TaxGroupCode <> '' then
            PurchLine.Validate("Tax Group Code", TaxGroupCode);
        if Description <> '' then
            PurchLine.Validate(Description, Description);
        PurchLine.Validate(Quantity, Quantity);
        PurchLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchLine.Validate("Deferral Code", DeferralCode);
        PurchLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchLine.Modify(true);
    end;

    /// <summary>
    /// Generates the inbound e-document invoice based on the added header and lines.
    /// </summary>
    procedure Generate()
    var
        PurchLine: Record "Purchase Line";
        EDocumentService: Record "E-Document Service";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        NoLinesAddedLbl: Label 'No lines have been added to the Purchase Header %1', Comment = '%1 = Purchase Header No.';
    begin
        PurchHeader.TestField("No.");
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if PurchLine.IsEmpty() then
            Error(NoLinesAddedLbl, PurchHeader."No.");
        EDocumentService := GetEDocService();
        TempBlob := SaveSamplePurchInvReportToPDF();
        //PurchInvHeader := PostPurchaseInvoice();
        EDocument := CreateEDocument(TempBlob, EDocumentService);
        FinalizeEDocument(EDocument);
    end;

    local procedure SaveSamplePurchInvReportToPDF() TempBlob: Codeunit "Temp Blob"
    var
        PurchLine: Record "Purchase Line";
        EDocSamplePurchInvPDF: Codeunit "E-Doc Sample Purch.Inv. PDF";
        CannotGeneratePdfLbl: Label 'Failed to generate PDF for Sample Purchase Invoice %1', Comment = '%1 = Purchase Invoice No.';
    begin
        EDocSamplePurchInvPDF.TransferFromPurchHeader(PurchHeader);

        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if PurchLine.FindSet() then
            repeat
                EDocSamplePurchInvPDF.TransferFromPurchLine(PurchLine);
            until PurchLine.Next() = 0;

        TempBlob := EDocSamplePurchInvPDF.GeneratePDF();
        if TempBlob.Length() = 0 then
            Error(CannotGeneratePdfLbl, PurchHeader."No.");
    end;

    local procedure CreateEDocument(TempBlob: Codeunit "Temp Blob"; EDocumentService: Record "E-Document Service") EDocument: Record "E-Document"
    var
        EDocImport: Codeunit "E-Doc. Import";
        ResInStream: InStream;
        FileName: Text;
    begin
        TempBlob.CreateInStream(ResInStream);
        FileName := 'PurchaseInvoice' + PurchHeader."No." + '.pdf';
        EDocImport.CreateFromType(
            EDocument, EDocumentService, Enum::"E-Doc. File Format"::PDF, FileName, ResInStream);
        EDocument."Document Type" := EDocument."Document Type"::"Purchase Invoice"; // TODO: Do i need this after reimplenentation?
        EDocument."Read into Draft Impl." := Enum::"E-Doc. Read into Draft"::"Demo Invoice";
        EDocument."Structured Data Entry No." := InsertEDocDataStorageWithPurchHeaderTableView();
        EDocument.Modify();
    end;

    local procedure FinalizeEDocument(EDocument: Record "E-Document")
    var
        EDocImportParameters: Record "E-Doc. Import Parameters";
        EDocImport: Codeunit "E-Doc. Import";
    begin
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Finish draft";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);
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
        Content := PurchHeader.GetView();
        EDocumentDataStorage."Data Storage".CreateInStream(InStream);
        EDocumentDataStorage."Data Storage Size" := StrLen(Content);
        EDocumentDataStorage.Insert();
        exit(EDocumentDataStorage."Entry No.");
    end;

#pragma warning disable AA0228
    local procedure CreateEDocPurchInvoice(EDocEntryNo: Integer; PurchInvHeader: Record "Purch. Inv. Header")
    var
        EDocPurchaseHeader: Record "E-Document Purchase Header";
    begin
        EDocPurchaseHeader := CreateEDocPurchHeader(EDocEntryNo, PurchInvHeader);
        CreateEDocRecordLink(EDocEntryNo, Database::"E-Document Purchase Header", EDocPurchaseHeader.SystemId, Database::"Purch. Inv. Header", PurchInvHeader.SystemId);
        CreateEDocVendorAssignHistory(EDocPurchaseHeader, PurchInvHeader);
        CreateEDocPurchLines(PurchInvHeader."No.", EDocEntryNo, EDocPurchaseHeader."Currency Code");
    end;
#pragma warning restore AA0228
    local procedure CreateEDocPurchHeader(EDocEntryNo: Integer; PurchInvHeader: Record "Purch. Inv. Header") EDocPurchaseHeader: Record "E-Document Purchase Header"
    var
        CompanyInformation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        CountryRegion: Record "Country/Region";
    begin
        EDocPurchaseHeader."E-Document Entry No." := EDocEntryNo;
        CompanyInformation.Get();
        EDocPurchaseHeader."Customer Company Name" := CompanyInformation.Name;
        EDocPurchaseHeader."Customer Company Id" := CompanyInformation."Bank Account No.";
        CountryRegion.Get(CompanyInformation."Country/Region Code");
        EDocPurchaseHeader."Customer Address" :=
            CopyStr(
                CompanyInformation.Address + ' ' + CompanyInformation."Address 2" + ', ' + CompanyInformation.City + ', ' + CompanyInformation.County + ', ' + CompanyInformation."Post Code" + ' ' + CountryRegion.Name,
                1, MaxStrLen(EDocPurchaseHeader."Customer Address"));
        EDocPurchaseHeader."Shipping Address" := EDocPurchaseHeader."Customer Address";
        EDocPurchaseHeader."Shipping Address Recipient" := EDocPurchaseHeader."Customer Company Name";
        EDocPurchaseHeader."Sales Invoice No." := PurchHeader."Vendor Invoice No.";
        EDocPurchaseHeader."Document Date" := PurchInvHeader."Posting Date";
        EDocPurchaseHeader."Due Date" := PurchInvHeader."Due Date";
        Vendor.Get(PurchInvHeader."Buy-from Vendor No.");
        EDocPurchaseHeader."Vendor Company Name" := Vendor.Name + ' ' + Vendor.Contact;
        EDocPurchaseHeader."Vendor Address" := PurchInvHeader."Pay-to Address" + ', ' + Vendor.City + ', ' + Vendor.County + ', ' + Vendor."Post Code" + ' ' + Vendor."Country/Region Code";
        EDocPurchaseHeader."Vendor Address Recipient" := EDocPurchaseHeader."Vendor Company Name";
        GeneralLedgerSetup.Get();
        EDocPurchaseHeader."Currency Code" := GeneralLedgerSetup."LCY Code";
        PurchInvHeader.CalcFields("Amount Including VAT");
        EDocPurchaseHeader.Total := PurchInvHeader."Amount Including VAT";
        EDocPurchaseHeader."[BC] Vendor No." := PurchInvHeader."Buy-from Vendor No.";
        EDocPurchaseHeader.Insert();
    end;

    local procedure CreateEDocPurchLines(InvNo: Code[20]; EDocEntryNo: Integer; CurrencyCode: Code[10])
    var
        EDocPurchaseLine: Record "E-Document Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        UnitOfMeasure: Record "Unit of Measure";
        AllocAccSystemIds: List of [Guid];
    begin
        PurchInvLine.SetRange("Document No.", InvNo);
        PurchInvLine.Findset();
        repeat
            Clear(EDocPurchaseLine);
            UpdatePuchLineTypeAndNumberOnEDocPurchaseLine(EDocPurchaseLine, PurchInvLine);
            if EDocPurchaseLine."[BC] Purchase Line Type" = EDocPurchaseLine."[BC] Purchase Line Type"::"Allocation Account" then begin
                if AllocAccSystemIds.Contains(PurchInvLine."Alloc. Purch. Line SystemId") then
                    continue;
                PurchInvLine.SetRange("Alloc. Purch. Line SystemId", PurchInvLine."Alloc. Purch. Line SystemId");
                PurchInvLine.CalcSums("Direct Unit Cost", "Amount Including VAT");
                PurchInvLine.SetRange("Alloc. Purch. Line SystemId");
                AllocAccSystemIds.Add(PurchInvLine."Alloc. Purch. Line SystemId");
            end;
            EDocPurchaseLine."E-Document Entry No." := EDocEntryNo;
            EDocPurchaseLine."Line No." := PurchInvLine."Line No.";
            EDocPurchaseLine.Description := PurchInvLine.Description;
            EDocPurchaseLine.Quantity := PurchInvLine.Quantity;
            if PurchInvLine."Unit of Measure Code" <> '' then
                UnitOfMeasure.Get(PurchInvLine."Unit of Measure Code")
            else
                UnitOfMeasure.Init();
            EDocPurchaseLine."Unit of Measure" := UnitOfMeasure.Description;
            EDocPurchaseLine."Unit Price" := PurchInvLine."Direct Unit Cost";
            EDocPurchaseLine."Sub Total" := PurchInvLine."Amount Including VAT";
            EDocPurchaseLine."Currency Code" := CurrencyCode;
            EDocPurchaseLine."[BC] Deferral Code" := PurchInvLine."Deferral Code";
            EDocPurchaseLine."[BC] Variant Code" := PurchInvLine."Variant Code";
            EDocPurchaseLine.Insert();
            CreateEDocRecordLink(EDocEntryNo, Database::"E-Document Purchase Line", EDocPurchaseLine.SystemId, Database::"Purch. Inv. Line", PurchInvLine.SystemId);
            CreateEDocPurchaseLineHistory(PurchInvLine, EDocPurchaseLine);
        until PurchInvLine.Next() = 0;
    end;

    local procedure UpdatePuchLineTypeAndNumberOnEDocPurchaseLine(var EDocPurchaseLine: Record "E-Document Purchase Line"; PurchInvLine: Record "Purch. Inv. Line")
    begin
        if PurchInvLine."Allocation Account No." = '' then begin
            EDocPurchaseLine."[BC] Purchase Line Type" := PurchInvLine.Type;
            EDocPurchaseLine."[BC] Purchase Type No." := PurchInvLine."No.";
            exit;
        end;
        EDocPurchaseLine."[BC] Purchase Line Type" := EDocPurchaseLine."[BC] Purchase Line Type"::"Allocation Account";
        EDocPurchaseLine."[BC] Purchase Type No." := PurchInvLine."Allocation Account No.";
    end;

    local procedure CreateEDocRecordLink(EDocEntryNo: Integer; SourceTableID: Integer; SourceSystemSystemID: Guid; TargetTableID: Integer; TargetSystemID: Guid)
    var
        EDocRecordLink: Record "E-Doc. Record Link";
        EntryNo: Integer;
    begin
        if EDocRecordLink.FindLast() then
            EntryNo := EDocRecordLink."Entry No." + 1
        else
            EntryNo := 1;
        EDocRecordLink."Entry No." := EntryNo;
        EDocRecordLink."E-Document Entry No." := EDocEntryNo;
        EDocRecordLink."Source Table No." := SourceTableID;
        EDocRecordLink."Source SystemId" := SourceSystemSystemID;
        EDocRecordLink."Target Table No." := TargetTableID;
        EDocRecordLink."Target SystemId" := TargetSystemID;
        EDocRecordLink.Insert();
    end;

    local procedure CreateEDocVendorAssignHistory(EDocPurchaseHeader: Record "E-Document Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header")
    var
        EDocVendorAssignHistory: Record "E-Doc. Vendor Assign. History";
        EntryNo: Integer;
    begin
        if EDocVendorAssignHistory.FindLast() then
            EntryNo := EDocVendorAssignHistory."Entry No." + 1
        else
            EntryNo := 1;
        EDocVendorAssignHistory."Entry No." := EntryNo;
        EDocVendorAssignHistory."Vendor Company Name" := EDocPurchaseHeader."Vendor Company Name";
        EDocVendorAssignHistory."Vendor Address" := EDocPurchaseHeader."Vendor Address";
        EDocVendorAssignHistory."Vendor VAT Id" := EDocPurchaseHeader."Vendor VAT Id";
        EDocVendorAssignHistory."Vendor GLN" := EDocPurchaseHeader."Vendor GLN";
        EDocVendorAssignHistory."Purch. Inv. Header SystemId" := PurchInvHeader.SystemId;
        EDocVendorAssignHistory.Insert();
    end;

    local procedure CreateEDocPurchaseLineHistory(PurchInvLine: Record "Purch. Inv. Line"; EDocPurchaseLine: Record "E-Document Purchase Line")
    var
        EDocPurchaseLineHistory: Record "E-Doc. Purchase Line History";
        EntryNo: Integer;
    begin
        if EDocPurchaseLineHistory.FindLast() then
            EntryNo := EDocPurchaseLineHistory."Entry No." + 1
        else
            EntryNo := 1;
        EDocPurchaseLineHistory."Entry No." := EntryNo;
        EDocPurchaseLineHistory."Vendor No." := PurchInvLine."Buy-from Vendor No.";
        EDocPurchaseLineHistory."Product Code" := EDocPurchaseLine."Product Code";
        EDocPurchaseLineHistory.Description := PurchInvLine.Description;
        EDocPurchaseLineHistory."Purch. Inv. Line SystemId" := PurchInvLine.SystemId;
    end;

    local procedure GetEDocService() EDocumentService: Record "E-Document Service"
    var
        CreateEDocDemodataService: Codeunit "Create E-Doc DemoData Service";
    begin
        EDocumentService.Get(CreateEDocDemodataService.EDocumentServiceCode());
    end;

}