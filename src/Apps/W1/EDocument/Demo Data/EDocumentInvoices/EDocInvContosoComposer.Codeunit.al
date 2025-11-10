// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.History;
using System.Utilities;
using System.IO;
using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Foundation.Address;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.eServices.EDocument.Processing;
using Microsoft.eServices.EDocument.Processing.Import;
using System.Environment.Configuration;
using Microsoft.Foundation.Reporting;
using System.Reflection;

/// <summary>
/// The purpose of the codeunit is to compose entities for generating the e-document invoices
/// </summary>
codeunit 5429 "E-Doc. Inv. Contoso Composer"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TempPurchHeader: Record "Purchase Header" temporary;
        TempPurchLine: Record "Purchase Line" temporary;

    /// <summary>
    /// 
    /// </summary>
    procedure AddEDocPurchaseHeader(VendorNo: Code[20]; DocumentDate: Date; ExternalDocNo: Text[35])
    begin
        if TempPurchHeader."No." = '' then
            TempPurchHeader."No." := '1'
        else
            TempPurchHeader."No." := IncStr(TempPurchHeader."No.");
        TempPurchHeader."Buy-from Vendor No." := VendorNo;
        TempPurchHeader."Vendor Invoice No." := ExternalDocNo;
        TempPurchHeader."Posting Date" := DocumentDate;
        TempPurchHeader.Insert();
        Clear(TempPurchLine);
    end;

    /// <summary>
    /// 
    /// </summary>
    /// <param name="LineType"></param>
    /// <param name="No"></param>
    /// <param name="Description"></param>
    /// <param name="Quantity"></param>
    /// <param name="DirectUnitCost"></param>
    /// <param name="DeferralCode"></param>
    /// <param name="UnitOfMeasureCode"></param>
    procedure AddEDocPurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; DeferralCode: Code[10]; UnitOfMeasureCode: Code[10])
    begin
        AddEDocPurchaseLine(LineType, No, '', Description, Quantity, DirectUnitCost, DeferralCode, UnitOfMeasureCode);
    end;

    /// <summary>
    /// 
    /// </summary>
    /// <param name="LineType"></param>
    /// <param name="No"></param>
    /// <param name="Description"></param>
    /// <param name="Quantity"></param>
    /// <param name="DirectUnitCost"></param>
    /// <param name="UnitOfMeasureCode"></param>
    procedure AddEDocPurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; UnitOfMeasureCode: Code[10])
    begin
        AddEDocPurchaseLine(LineType, No, '', Description, Quantity, DirectUnitCost, '', UnitOfMeasureCode);
    end;

    /// <summary>
    /// 
    /// </summary>
    /// <param name="LineType"></param>
    /// <param name="No"></param>
    /// <param name="TaxGroupCode"></param>
    /// <param name="Description"></param>
    /// <param name="Quantity"></param>
    /// <param name="DirectUnitCost"></param>
    /// <param name="UnitOfMeasureCode"></param>
    procedure AddEDocPurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; TaxGroupCode: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; UnitOfMeasureCode: Code[10])
    begin
        AddEDocPurchaseLine(LineType, No, TaxGroupCode, Description, Quantity, DirectUnitCost, '', UnitOfMeasureCode);
    end;

    /// <summary>
    /// 
    /// </summary>
    /// <param name="LineType"></param>
    /// <param name="No"></param>
    /// <param name="TaxGroupCode"></param>
    /// <param name="Description"></param>
    /// <param name="Quantity"></param>
    /// <param name="DirectUnitCost"></param>
    /// <param name="DeferralCode"></param>
    /// <param name="UnitOfMeasureCode"></param>
    procedure AddEDocPurchaseLine(LineType: Enum "Purchase Line Type"; No: Code[20]; TaxGroupCode: Code[20]; Description: Text[100]; Quantity: Decimal; DirectUnitCost: Decimal; DeferralCode: Code[10]; UnitOfMeasureCode: Code[10])
    begin
        TempPurchHeader.TestField("No.");
        TempPurchLine."Document No." := TempPurchHeader."No.";
        TempPurchLine."Line No." += 10000;
        TempPurchLine.Type := LineType;
        TempPurchLine."No." := No;
        TempPurchLine."Tax Group Code" := TaxGroupCode;
        TempPurchLine.Description := Description;
        TempPurchLine.Quantity := Quantity;
        TempPurchLine."Direct Unit Cost" := DirectUnitCost;
        TempPurchLine."Deferral Code" := DeferralCode;
        TempPurchLine."Unit of Measure Code" := UnitOfMeasureCode;
        TempPurchLine.Insert();
    end;

    /// <summary>
    /// 
    /// </summary>
    procedure ProcessComposedEntries()
    var
        EDocumentService: Record "E-Document Service";
        PurchHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        DesignTimeReportSelection: codeunit "Design-time Report Selection";
        LayoutName: Text[250];
    begin
        EDocumentService := GetEDocService();
        LayoutName := InsertTenantReportLayout();
        DesignTimeReportSelection.SetSelectedLayout(LayoutName, GetCurrAppId());
        TempPurchHeader.Reset();
        TempPurchHeader.FindSet();
        repeat
            PurchHeader := CreatePurchInvFromTempBuffer();
            //GeneratePDFWithCustomLayout(PurchHeader); // TODO: Double check
            PurchInvHeader := PostPurchaseInvoice(PurchHeader);
            TempBlob := SavePurchInvReportToPDF(PurchInvHeader);
            EDocument := CreateEDocument(TempBlob, PurchInvHeader, EDocumentService);
            CreateEDocPurchHeaderWithLines(EDocument."Entry No", PurchInvHeader);
            EDocument."Document Record ID" := PurchInvHeader.RecordId();
            EDocument."Bill-to/Pay-to No." := PurchInvHeader."Pay-to Vendor No.";
            EDocument."Bill-to/Pay-to Name" := PurchInvHeader."Pay-to Name";
            EDocument."Document No." := PurchInvHeader."No.";
            EDocument.Modify();
        until TempPurchHeader.Next() = 0;
        DesignTimeReportSelection.ClearLayoutSelection();
        //CleanupTenantReportLayout(LayoutName); // TODO: Double check
    end;

    local procedure CreatePurchInvFromTempBuffer() PurchHeader: Record "Purchase Header"
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchHeader."Document Type" := PurchHeader."Document Type"::Invoice;
        PurchHeader.Insert(true);
        PurchHeader.Validate("Buy-from Vendor No.", TempPurchHeader."Buy-from Vendor No.");
        PurchHeader.Validate("Posting Date", TempPurchHeader."Posting Date");
        PurchHeader.Validate("Vendor Invoice No.", TempPurchHeader."Vendor Invoice No.");
        PurchHeader.Modify(true);
        TempPurchLine.SetRange("Document No.", TempPurchHeader."No.");
        TempPurchLine.FindSet();
        repeat
            clear(PurchLine);
            PurchLine."Document Type" := PurchLine."Document Type"::Invoice;
            PurchLine."Document No." := PurchHeader."No.";
            PurchLine."Line No." := TempPurchLine."Line No.";
            PurchLine.Insert(true);
            PurchLine.Validate(Type, TempPurchLine.Type);
            PurchLine.Validate("No.", TempPurchLine."No.");
            if TempPurchLine."Tax Group Code" <> '' then
                PurchLine.Validate("Tax Group Code", TempPurchLine."Tax Group Code");
            if TempPurchLine.Description <> '' then
                PurchLine.Validate(Description, TempPurchLine.Description);
            PurchLine.Validate(Quantity, TempPurchLine.Quantity);
            PurchLine.Validate("Direct Unit Cost", TempPurchLine."Direct Unit Cost");
            PurchLine.Validate("Deferral Code", TempPurchLine."Deferral Code");
            PurchLine.Validate("Unit of Measure Code", TempPurchLine."Unit of Measure Code");
            PurchLine.Modify(true);
        until TempPurchLine.Next() = 0;
    end;

#pragma warning disable AA0228
    local procedure GeneratePDFWithCustomLayout(var PurchaseHeader: Record "Purchase Header")
    var
        StandardPurchaseOrder: Report "Standard Purchase - Order";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        FilePath: Text;
    begin
        PurchaseHeader.SetRecFilter();
        StandardPurchaseOrder.SetTableView(PurchaseHeader);
        FilePath := CopyStr(FileManagement.ServerTempFileName('pdf'), 1, 250);
        StandardPurchaseOrder.SaveAsPdf(FilePath);
        FileManagement.BLOBImportFromServerFile(TempBlob, FilePath);
    end;
#pragma warning restore AA0228

    local procedure InsertTenantReportLayout(): Text[250]
    var
        ReportLayoutList: Record "Report Layout List";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        EmptyGuid: Guid;
    begin
        ReportLayoutList.SetRange("Report ID", Report::"Purchase - Invoice");
        ReportLayoutList.SetRange(Name, GetLayoutName());
        ReportLayoutList.FindFirst();
        if not TenantReportLayoutSelection.Get(ReportLayoutList."Report ID", CompanyName, EmptyGuid) then begin
            TenantReportLayoutSelection.Init();
            TenantReportLayoutSelection."App ID" := ReportLayoutList."Application ID";
            TenantReportLayoutSelection."Company Name" := CopyStr(CompanyName, 1, MaxStrLen(TenantReportLayoutSelection."Company Name"));
            TenantReportLayoutSelection."Layout Name" := ReportLayoutList.Name;
            TenantReportLayoutSelection."Report ID" := ReportLayoutList."Report ID";
            TenantReportLayoutSelection."User ID" := EmptyGuid;
            TenantReportLayoutSelection.Insert(true);
        end;
        exit(TenantReportLayoutSelection."Layout Name");
    end;

    local procedure GetLayoutName(): Text[250]
    begin
        exit('SamplePurchaseInvoice');
    end;

    local procedure GetCurrAppId(): Guid
    var
        CurrModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrModuleInfo);
        exit(CurrModuleInfo.Id)
    end;

#pragma warning disable AA0228
    local procedure CleanupTenantReportLayout(LayoutName: Text)
    var
        TenantReportLayout: Record "Tenant Report Layout";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        TenantReportLayout.SetRange(Name, LayoutName);
        TenantReportLayout.DeleteAll(true);
        TenantReportLayoutSelection.SetRange("Layout Name", LayoutName);
        TenantReportLayoutSelection.DeleteAll(true);
    end;
#pragma warning restore AA0228

    local procedure PostPurchaseInvoice(PurchHeader: Record "Purchase Header") PurchInvHeader: Record "Purch. Inv. Header"
    var
        PurchPost: Codeunit "Purch.-Post";
    begin
        PurchHeader.Invoice := true;
        PurchHeader.Receive := true;
        PurchHeader.Modify(true);
        PurchPost.Run(PurchHeader);
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchHeader."No.");
        PurchInvHeader.FindFirst();
    end;

    local procedure SavePurchInvReportToPDF(PurchInvHeader: Record "Purch. Inv. Header") TempBlob: Codeunit "Temp Blob"
    var
        PurchaseInvoiceReport: Report "Purchase - Invoice";
        FileManagement: Codeunit "File Management";
        FilePath: Text[250];
    begin
        PurchInvHeader.SetRecFilter();
        PurchaseInvoiceReport.SetTableView(PurchInvHeader);
        FilePath := CopyStr(FileManagement.ServerTempFileName('pdf'), 1, 250);
        PurchaseInvoiceReport.SaveAsPdf(FilePath);
        FileManagement.BLOBImportFromServerFile(TempBlob, FilePath);
        if TempBlob.Length() = 0 then
            Error('Failed to generate PDF for Purchase Invoice %1', PurchInvHeader."No.");
    end;

    local procedure CreateEDocument(TempBlob: Codeunit "Temp Blob"; PurchInvHeader: Record "Purch. Inv. Header"; EDocumentService: Record "E-Document Service") EDocument: Record "E-Document"
    var
        EDocImport: Codeunit "E-Doc. Import";
        ResInStream: InStream;
        FileName: Text;
    begin
        TempBlob.CreateInStream(ResInStream);
        FileName := 'PurchaseInvoice' + PurchInvHeader."No." + '.pdf';
        EDocImport.CreateFromType(
            EDocument, EDocumentService, Enum::"E-Doc. File Format"::PDF, FileName, ResInStream);
        EDocument."Document Type" := EDocument."Document Type"::"Purchase Invoice";
        EDocument."Read into Draft Impl." := Enum::"E-Doc. Read into Draft"::"Demo Invoice";
        EDocument.Status := EDocument.Status::Processed;
        EDocument."Import Processing Status" := EDocument."Import Processing Status"::Processed; // TODO: Check why eventually i have unprocessed after executing all the steps
        EDocument."Structured Data Entry No." := InsertDummyEDocDataStorage();
        EDocument.Modify();
        UpdateEDocServiceStatus(EDocument."Entry No", EDocumentService);
    end;

    local procedure InsertDummyEDocDataStorage(): Integer
    var
        EDocumentDataStorage: Record "E-Doc. Data Storage";
    begin
        if EDocumentDataStorage.FindLast() then
            EDocumentDataStorage."Entry No." := EDocumentDataStorage."Entry No." + 1;
        EDocumentDataStorage.Init();
        EDocumentDataStorage.Insert();
        exit(EDocumentDataStorage."Entry No.");
    end;

    local procedure CreateEDocPurchHeaderWithLines(EDocEntryNo: Integer; PurchInvHeader: Record "Purch. Inv. Header")
    var
        CompanyInformation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        CountryRegion: Record "Country/Region";
        EDocPurchaseHeader: Record "E-Document Purchase Header";
        EDocPurchaseLine: Record "E-Document Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        UnitOfMeasure: Record "Unit of Measure";
        AllocAccSystemIds: List of [Guid];
    begin
        EDocPurchaseHeader."E-Document Entry No." := EDocEntryNo;
        CompanyInformation.Get();
        EDocPurchaseHeader."Customer Company Name" := CompanyInformation.Name;
        EDocPurchaseHeader."Customer Company Id" := CompanyInformation."Bank Account No."; // TODO: Need to double check this, probably ADI return different results
        CountryRegion.Get(CompanyInformation."Country/Region Code");
        EDocPurchaseHeader."Customer Address" :=
            CopyStr(
                CompanyInformation.Address + ' ' + CompanyInformation."Address 2" + ', ' + CompanyInformation.City + ', ' + CompanyInformation.County + ', ' + CompanyInformation."Post Code" + ' ' + CountryRegion.Name,
                1, MaxStrLen(EDocPurchaseHeader."Customer Address"));
        EDocPurchaseHeader."Shipping Address" := EDocPurchaseHeader."Customer Address";
        EDocPurchaseHeader."Shipping Address Recipient" := EDocPurchaseHeader."Customer Company Name";
        EDocPurchaseHeader."Sales Invoice No." := TempPurchHeader."Vendor Invoice No.";
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
        CreateEDocRecordLink(EDocEntryNo, Database::"E-Document Purchase Header", EDocPurchaseHeader.SystemId, Database::"Purch. Inv. Header", PurchInvHeader.SystemId);
        CreateEDocVendorAssignHistory(EDocPurchaseHeader, PurchInvHeader);

        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
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
            // EDocumentPurchaseLine."Product Code" := '????' // TODO: Update
            EDocPurchaseLine.Description := PurchInvLine.Description;
            EDocPurchaseLine.Quantity := PurchInvLine.Quantity;
            if PurchInvLine."Unit of Measure Code" <> '' then
                UnitOfMeasure.Get(PurchInvLine."Unit of Measure Code")
            else
                UnitOfMeasure.Init();
            EDocPurchaseLine."Unit of Measure" := UnitOfMeasure.Description;
            EDocPurchaseLine."Unit Price" := PurchInvLine."Direct Unit Cost";
            EDocPurchaseLine."Sub Total" := PurchInvLine."Amount Including VAT";
            EDocPurchaseLine."Currency Code" := EDocPurchaseHeader."Currency Code";
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

    local procedure UpdateEDocServiceStatus(EDocumentEnryNo: Integer; EDocumentService: Record "E-Document Service")
    var
        EDocServiceStatus: Record "E-Document Service Status";
    begin
        EDocServiceStatus.Get(EDocumentEnryNo, EDocumentService.Code);
        EDocServiceStatus.Status := Enum::"E-Document Service Status"::Imported;
        EDocServiceStatus.Modify();
    end;

    local procedure GetEDocService() EDocumentService: Record "E-Document Service"
    var
        CreateEDocDemodataService: Codeunit "Create E-Doc DemoData Service";
    begin
        EDocumentService.Get(CreateEDocDemodataService.EDocumentServiceCode());
    end;

}