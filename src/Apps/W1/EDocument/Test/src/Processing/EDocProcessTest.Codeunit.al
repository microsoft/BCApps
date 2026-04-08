// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.Bank.Reconciliation;
using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;
using System.TestLibraries.Utilities;

codeunit 139883 "E-Doc Process Test"
{
    Subtype = Test;
    TestType = IntegrationTest;

    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryEDoc: Codeunit "Library - E-Document";
        EDocImplState: Codeunit "E-Doc. Impl. State";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        IsInitialized: Boolean;


    [Test]
    procedure ProcessStructureReceivedData()
    var
        EDocument: Record "E-Document";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        EDocDataStorage: Record "E-Doc. Data Storage";
        EDocLogRecord: Record "E-Document Log";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocumentLog: Codeunit "E-Document Log";
        InStream: InStream;
        Text: Text;
    begin
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        EDocumentLog.SetBlob('Test', Enum::"E-Doc. File Format"::PDF, 'Data');
        EDocumentLog.SetFields(EDocument, EDocumentService);
        EDocLogRecord := EDocumentLog.InsertLog(Enum::"E-Document Service Status"::Imported, Enum::"Import E-Doc. Proc. Status"::Unprocessed);

        EDocument."Structure Data Impl." := "Structure Received E-Doc."::"PDF Mock";
        EDocument."Unstructured Data Entry No." := EDocLogRecord."E-Doc. Data Storage Entry No.";
        EDocument."File Name" := 'Test.pdf';
        EDocument.Modify();

        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::Unprocessed);
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Structure received data";

        EDocument.CalcFields("Import Processing Status");
        Assert.AreEqual(Enum::"Import E-Doc. Proc. Status"::Unprocessed, EDocument."Import Processing Status", 'The status should be updated to the one after the step executed.');
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);
        EDocument.CalcFields("Import Processing Status");
        Assert.AreEqual(Enum::"Import E-Doc. Proc. Status"::Readable, EDocument."Import Processing Status", 'The status should be updated to the one after the step executed.');
        EDocument.Get(EDocument."Entry No");
        EDocDataStorage.Get(EDocument."Structured Data Entry No.");
        EDocDataStorage.CalcFields("Data Storage");
        EDocDataStorage."Data Storage".CreateInStream(InStream);
        InStream.Read(Text);
        Assert.AreEqual('Mocked content', Text, 'The data should be read from the mock converter.');
        Assert.AreEqual(Enum::"E-Doc. File Format"::JSON, EDocDataStorage."File Format", 'The data type should be updated to JSON.');
    end;

    [Test]
    procedure ProcessingDoesSequenceOfSteps()
    var
        EDocument: Record "E-Document";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        EDocLogRecord: Record "E-Document Log";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocumentLog: Codeunit "E-Document Log";
        ImportEDocumentProcess: Codeunit "Import E-Document Process";
    begin
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        EDocumentLog.SetBlob('Test', Enum::"E-Doc. File Format"::PDF, 'Data');
        EDocumentLog.SetFields(EDocument, EDocumentService);
        EDocLogRecord := EDocumentLog.InsertLog(Enum::"E-Document Service Status"::Imported, Enum::"Import E-Doc. Proc. Status"::Unprocessed);

        EDocument."Unstructured Data Entry No." := EDocLogRecord."E-Doc. Data Storage Entry No.";
        EDocument."Structure Data Impl." := "Structure Received E-Doc."::"PDF Mock";
        EDocument."Read into Draft Impl." := "E-Doc. Read into Draft"::"PDF Mock";
        EDocument."File Name" := 'Test.pdf';
        EDocument.Modify();

        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::Unprocessed);
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        EDocument.CalcFields("Import Processing Status");
        Assert.AreEqual(ImportEDocumentProcess.GetStatusForStep(TempEDocImportParameters."Step to Run", false), EDocument."Import Processing Status", 'The status should be updated to the one after the step executed.');
    end;

    [Test]
    procedure ProcessingUndoesSteps()
    var
        EDocument: Record "E-Document";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        EDocLogRecord: Record "E-Document Log";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocumentLog: Codeunit "E-Document Log";
        ImportEDocumentProcess: Codeunit "Import E-Document Process";
    begin
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        EDocumentLog.SetBlob('Test', Enum::"E-Doc. File Format"::PDF, 'Data');
        EDocumentLog.SetFields(EDocument, EDocumentService);
        EDocLogRecord := EDocumentLog.InsertLog(Enum::"E-Document Service Status"::Imported, Enum::"Import E-Doc. Proc. Status"::Unprocessed);

        EDocument."Unstructured Data Entry No." := EDocLogRecord."E-Doc. Data Storage Entry No.";
        EDocument."Structure Data Impl." := "Structure Received E-Doc."::"PDF Mock";
        EDocument."Read into Draft Impl." := "E-Doc. Read into Draft"::"PDF Mock";
        EDocument."File Name" := 'Test.pdf';
        EDocument.Modify();

        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::Unprocessed);
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        EDocument.CalcFields("Import Processing Status");
        Assert.AreEqual(ImportEDocumentProcess.GetStatusForStep(TempEDocImportParameters."Step to Run", false), EDocument."Import Processing Status", 'The status should be updated to the one after the step executed.');

        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Structure received data";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        EDocument.CalcFields("Import Processing Status");
        Assert.AreEqual(ImportEDocumentProcess.GetStatusForStep(TempEDocImportParameters."Step to Run", false), EDocument."Import Processing Status", 'The status should be updated to the one after the step executed.');
    end;

    [Test]
    procedure PreparingPurchaseDraftFindsPurchaseOrderWhenSpecified()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        EDocLogRecord: Record "E-Document Log";
        PurchaseHeader: Record "Purchase Header";
        EDocumentLog: Codeunit "E-Document Log";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocImport: Codeunit "E-Doc. Import";
    begin
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := 'EDOC-001';
        PurchaseHeader.Insert();
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."Purchase Order No." := PurchaseHeader."No.";
        EDocumentPurchaseHeader."Vendor VAT Id" := '13124234';
        EDocumentPurchaseHeader.Insert();

        EDocumentLog.SetBlob('Test', Enum::"E-Doc. File Format"::PDF, 'Data');
        EDocumentLog.SetFields(EDocument, EDocumentService);
        EDocLogRecord := EDocumentLog.InsertLog(Enum::"E-Document Service Status"::Imported, Enum::"Import E-Doc. Proc. Status"::Unprocessed);

        EDocument."Unstructured Data Entry No." := EDocLogRecord."E-Doc. Data Storage Entry No.";
        EDocument.Modify();

        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::"Ready for draft");
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        EDocumentPurchaseHeader.SetRecFilter();
        EDocumentPurchaseHeader.FindFirst();
        Assert.AreEqual(PurchaseHeader."No.", EDocumentPurchaseHeader."[BC] Purchase Order No.", 'The purchase order should be found when explicitly specified in the E-Document.');
        EDocument.SetRecFilter();

        PurchaseHeader.SetRecFilter();
        PurchaseHeader.Delete();
    end;

    [Test]
    procedure PreparingPurchaseDraftFindsVendorByTaxId()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocImport: Codeunit "E-Doc. Import";
    begin
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2.Insert();
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."Vendor VAT Id" := Vendor2."VAT Registration No.";
        EDocumentPurchaseHeader.Insert();

        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::"Ready for draft");
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        EDocumentPurchaseHeader.SetRecFilter();
        EDocumentPurchaseHeader.FindFirst();
        Assert.AreEqual(Vendor2."No.", EDocumentPurchaseHeader."[BC] Vendor No.", 'The vendor should be found when the tax id is specified and it matches the one in BC.');

        Vendor2.SetRecFilter();
        Vendor2.Delete();
    end;

    [Test]
    procedure PreparingPurchaseDraftFindsAccountConfiguredWithTextToAccountMapping()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        GLAccount: Record "G/L Account";
        TextToAccountMapping: Record "Text-to-Account Mapping";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocImport: Codeunit "E-Doc. Import";
    begin
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);
        GLAccount."No." := 'EDOC001';
        GLAccount.Insert();

        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2.Insert();

        TextToAccountMapping."Debit Acc. No." := GLAccount."No.";
        TextToAccountMapping."Vendor No." := Vendor2."No.";
        TextToAccountMapping."Mapping Text" := 'Test description';
        TextToAccountMapping.Insert();

        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."Vendor VAT Id" := Vendor2."VAT Registration No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine.Description := 'Test description';
        EDocumentPurchaseLine.Insert();

        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::"Ready for draft");
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        EDocumentPurchaseLine.SetRecFilter();
        EDocumentPurchaseLine.FindFirst();

        EDocumentPurchaseHeader.SetRecFilter();
        EDocumentPurchaseHeader.FindFirst();
        Assert.AreEqual(Vendor2."No.", EDocumentPurchaseHeader."[BC] Vendor No.", 'The vendor should be found when the tax id is specified and it matches the one in BC.');
        Assert.AreEqual("Purchase Line Type"::"G/L Account", EDocumentPurchaseLine."[BC] Purchase Line Type", 'The purchase line type should be set to G/L Account.');
        Assert.AreEqual(GLAccount."No.", EDocumentPurchaseLine."[BC] Purchase Type No.", 'The G/L Account configured in the Text-to-Account Mapping should be found.');

        Vendor2.SetRecFilter();
        Vendor2.Delete();
        GLAccount.SetRecFilter();
        GLAccount.Delete();
        TextToAccountMapping.SetRecFilter();
        TextToAccountMapping.Delete();
    end;

    [Test]
    procedure FinishDraftCanBeUndone()
    var
        EDocument: Record "E-Document";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        PurchaseHeader: Record "Purchase Header";
        EDocLogRecord: Record "E-Document Log";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentLog: Codeunit "E-Document Log";
        EDocumentProcessing: Codeunit "E-Document Processing";
    begin
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);
        EDocument."Document Type" := "E-Document Type"::"Purchase Invoice";
        EDocument.Modify();
        EDocumentService."Import Process" := "E-Document Import Process"::"Version 2.0";
        EDocumentService.Modify();

        EDocumentLog.SetBlob('Test', Enum::"E-Doc. File Format"::XML, 'Data');
        EDocumentLog.SetFields(EDocument, EDocumentService);
        EDocLogRecord := EDocumentLog.InsertLog(Enum::"E-Document Service Status"::Imported, Enum::"Import E-Doc. Proc. Status"::Readable);

        EDocument."Structured Data Entry No." := EDocLogRecord."E-Doc. Data Storage Entry No.";
        EDocument.Modify();


        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::"Draft Ready");
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Finish draft";
        TempEDocImportParameters."Processing Customizations" := "E-Doc. Proc. Customizations"::"Mock Create Purchase Invoice";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        PurchaseHeader.SetRange("E-Document Link", EDocument.SystemId);
        PurchaseHeader.FindFirst();

        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Structure received data";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        Assert.RecordIsEmpty(PurchaseHeader);
    end;

    [Test]
    procedure FinishDraftFromReadyForDraftStateSucceeds()
    var
        EDocument: Record "E-Document";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        PurchaseHeader: Record "Purchase Header";
        EDocLogRecord: Record "E-Document Log";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentLog: Codeunit "E-Document Log";
        EDocumentProcessing: Codeunit "E-Document Processing";
    begin
        // [SCENARIO] When finalize action is invoked from Ready for draft state, the system should automatically run Prepare draft first and then Finish draft
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);
        EDocument."Document Type" := "E-Document Type"::"Purchase Invoice";
        EDocument.Modify();
        EDocumentService."Import Process" := "E-Document Import Process"::"Version 2.0";
        EDocumentService.Modify();

        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."Vendor VAT Id" := Vendor."VAT Registration No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine."Product Code" := '1234';
        EDocumentPurchaseLine.Description := 'Test description';
        EDocumentPurchaseLine.Insert();

        EDocumentLog.SetBlob('Test', Enum::"E-Doc. File Format"::XML, 'Data');
        EDocumentLog.SetFields(EDocument, EDocumentService);
        EDocLogRecord := EDocumentLog.InsertLog(Enum::"E-Document Service Status"::Imported, Enum::"Import E-Doc. Proc. Status"::Readable);

        EDocument."Structured Data Entry No." := EDocLogRecord."E-Doc. Data Storage Entry No.";
        EDocument.Modify();

        // [GIVEN] E-Document is in Ready for draft state
        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::"Ready for draft");
        EDocument.CalcFields("Import Processing Status");
        Assert.AreEqual(Enum::"Import E-Doc. Proc. Status"::"Ready for draft", EDocument."Import Processing Status", 'The status should be Ready for draft before processing.');

        // [WHEN] Finish draft step is executed (simulating finalize action)
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Finish draft";
        TempEDocImportParameters."Processing Customizations" := "E-Doc. Proc. Customizations"::"Mock Create Purchase Invoice";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        // [THEN] The document is processed (the system ran Prepare draft automatically and then Finish draft)
        EDocument.CalcFields("Import Processing Status");
        Assert.AreEqual(Enum::"Import E-Doc. Proc. Status"::Processed, EDocument."Import Processing Status", 'The status should be Processed after finalize action from Ready for draft state.');

        PurchaseHeader.SetRange("E-Document Link", EDocument.SystemId);
        Assert.IsFalse(PurchaseHeader.IsEmpty(), 'The purchase header should be created.');
    end;

    #region HistoricalMatchingTest

    [Test]
    procedure ProcessingInboundDocumentCreatesLinks()
    var
        EDocument: Record "E-Document";
        TempEDocImportParams: Record "E-Doc. Import Parameters";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        EDocRecordLink: Record "E-Doc. Record Link";
    begin
        // [SCENARIO] A incoming e-document purchase invoice is received and processed, links should be created between the e-document and the purchase header and lines.
        Initialize(Enum::"Service Integration"::"Mock");
        EDocumentService."Read into Draft Impl." := "E-Doc. Read into Draft"::PEPPOL;
        EDocumentService.Modify();

        EDocRecordLink.DeleteAll();

        // [GIVEN] An inbound e-document is received and fully processed
        TempEDocImportParams."Step to Run" := "Import E-Document Steps"::"Finish draft";
        WorkDate(DMY2Date(1, 1, 2027)); // Peppol document date is in 2026
        Assert.IsTrue(LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-invoice-0.xml', TempEDocImportParams), 'The e-document should be processed');

        EDocument.Get(EDocument."Entry No");
        PurchaseHeader.Get(EDocument."Document Record ID");

        // [THEN] The e-document is linked to the purchase header and lines
        EDocRecordLink.SetRange("Target Table No.", Database::"Purchase Header");
        EDocRecordLink.SetRange("Target SystemId", PurchaseHeader.SystemId);
        Assert.RecordCount(EDocRecordLink, 1);

        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindSet();
        repeat
            EDocRecordLink.SetRange("Target Table No.", Database::"Purchase Line");
            EDocRecordLink.SetRange("Target SystemId", PurchaseLine.SystemId);
            Assert.RecordCount(EDocRecordLink, 1);
        until PurchaseLine.Next() = 0;
    end;

    [Test]
    procedure PostingInboundDocumentCreatesHistoricalRecords()
    var
        EDocument: Record "E-Document";
        TempEDocImportParams: Record "E-Doc. Import Parameters";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        EDocVendorAssignmentHistory: Record "E-Doc. Vendor Assign. History";
        EDocPurchaseLineHistory: Record "E-Doc. Purchase Line History";
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        EDocRecordLink: Record "E-Doc. Record Link";
    begin
        // [SCENARIO] A incoming e-document purchase invoice is received, processed, and posted. Historical records should be created.
        Initialize(Enum::"Service Integration"::"Mock");
        EDocumentService."Read into Draft Impl." := "E-Doc. Read into Draft"::PEPPOL;
        EDocumentService.Modify();

        // [GIVEN] An inbound e-document is received and fully processed
        TempEDocImportParams."Step to Run" := "Import E-Document Steps"::"Finish draft";
        WorkDate(DMY2Date(1, 1, 2027)); // Peppol document date is in 2026
        Assert.IsTrue(LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-invoice-0.xml', TempEDocImportParams), 'The e-document should be processed');

        EDocument.Get(EDocument."Entry No");
        PurchaseHeader.Get(EDocument."Document Record ID");
        // [GIVEN] The received purchase invoice is modified for posting
        LibraryEDoc.EditPurchaseDocumentFromEDocumentForPosting(PurchaseHeader, EDocument);

        // [WHEN] The received purchase invoice is posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchaseInvoiceHeader.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        PurchaseInvoiceHeader.FindFirst();

        // [THEN] The historical records are created
        EDocVendorAssignmentHistory.SetRange("Purch. Inv. Header SystemId", PurchaseInvoiceHeader.SystemId);
        Assert.RecordCount(EDocVendorAssignmentHistory, 1);
        PurchaseInvoiceLine.SetRange("Document No.", PurchaseInvoiceHeader."No.");
        PurchaseInvoiceLine.FindSet();
        repeat
            EDocPurchaseLineHistory.SetRange("Purch. Inv. Line SystemId", PurchaseInvoiceLine.SystemId);
            Assert.RecordCount(EDocPurchaseLineHistory, 1);
        until PurchaseInvoiceLine.Next() = 0;
        // [THEN] The links should be deleted, these are there momentarily while the purchase invoice is not yet posted
        EDocRecordLink.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.RecordCount(EDocRecordLink, 0);
    end;
    #endregion

    [Test]
    procedure AdditionalFieldsAreConsideredWhenCreatingPurchaseInvoice()
    var
        EDocPurchLineFieldSetup: Record "ED Purchase Line Field Setup";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        EDocument: Record "E-Document";
        TempEDocImportParams: Record "E-Doc. Import Parameters";
        PurchaseHeader: Record "Purchase Header";
        EDocPurchLineField: Record "E-Document Line - Field";
        EDocPurchaseLine: Record "E-Document Purchase Line";
        Location: Record Location;
        EDocImport: Codeunit "E-Doc. Import";
    begin
        // [SCENARIO] Additional fields are configured for the e-document, and an incoming e-document is received. When creating a purchase invoice, the configured fields should be considered.
        Initialize(Enum::"Service Integration"::"Mock");
        EDocumentService."Read into Draft Impl." := "E-Doc. Read into Draft"::PEPPOL;
        EDocumentService.Modify();
        // [GIVEN] Additional fields are configured
        EDocPurchLineFieldSetup."Field No." := PurchaseInvoiceLine.FieldNo("Location Code");
        EDocPurchLineFieldSetup.Insert();
        EDocPurchLineFieldSetup."Field No." := PurchaseInvoiceLine.FieldNo("IC Partner Code");
        EDocPurchLineFieldSetup.Insert();
        // [GIVEN] An inbound e-document is received and a draft created
        TempEDocImportParams."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        WorkDate(DMY2Date(1, 1, 2027)); // Peppol document date is in 2026
        Assert.IsTrue(LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-invoice-0.xml', TempEDocImportParams), 'The draft for the e-document should be created');

        // [WHEN] Storing custom values for the additional fields of the first line
        EDocPurchLineField."E-Document Entry No." := EDocument."Entry No";
        EDocPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPurchaseLine.FindFirst();
        EDocPurchLineField."Line No." := EDocPurchaseLine."Line No.";
        EDocPurchLineField."Field No." := PurchaseInvoiceLine.FieldNo("Location Code");
        Location.Code := 'TESTLOC';
        if Location.Insert() then;
        EDocPurchLineField."Code Value" := Location.Code;
        EDocPurchLineField.Insert();

        // [WHEN] Creating a purchase invoice from the draft
        TempEDocImportParams."Step to Run" := "Import E-Document Steps"::"Finish draft";
        Assert.IsTrue(EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParams), 'The e-document should be processed');

        // [THEN] The additional fields should be set on the purchase invoice line
        EDocument.Get(EDocument."Entry No");
        PurchaseHeader.Get(EDocument."Document Record ID");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindFirst();
        Assert.AreEqual(Location.Code, PurchaseLine."Location Code", 'The location code should be set on the purchase line.');
    end;

    [Test]
    procedure AdditionalFieldsShouldNotBeConsideredIfNotConfigured()
    var
        EDocPurchLineFieldSetup: Record "ED Purchase Line Field Setup";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        EDocument: Record "E-Document";
        TempEDocImportParams: Record "E-Doc. Import Parameters";
        PurchaseHeader: Record "Purchase Header";
        EDocPurchLineField: Record "E-Document Line - Field";
        EDocPurchaseLine: Record "E-Document Purchase Line";
        Location: Record Location;
        EDocImport: Codeunit "E-Doc. Import";
    begin
        // [SCENARIO] Additional fields are configured for the e-document, but the general setup is not configured. When creating a purchase invoice, the configured fields should not be considered.
        Initialize(Enum::"Service Integration"::"Mock");
        EDocumentService."Read into Draft Impl." := "E-Doc. Read into Draft"::PEPPOL;
        EDocumentService.Modify();
        // [GIVEN] Additional fields are configured
        EDocPurchLineFieldSetup."Field No." := PurchaseInvoiceLine.FieldNo("Location Code");
        EDocPurchLineFieldSetup.Insert();
        EDocPurchLineFieldSetup."Field No." := PurchaseInvoiceLine.FieldNo("IC Partner Code");
        EDocPurchLineFieldSetup.Insert();
        // [GIVEN] An inbound e-document is received and a draft created
        TempEDocImportParams."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        WorkDate(DMY2Date(1, 1, 2027)); // Peppol document date is in 2026
        Assert.IsTrue(LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-invoice-0.xml', TempEDocImportParams), 'The draft for the e-document should be created');

        // [GIVEN] Custom values for the additional fields of the first line are configured
        EDocPurchLineField."E-Document Entry No." := EDocument."Entry No";
        EDocPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPurchaseLine.FindFirst();
        EDocPurchLineField."Line No." := EDocPurchaseLine."Line No.";
        EDocPurchLineField."Field No." := PurchaseInvoiceLine.FieldNo("Location Code");
        Location.Code := 'TESTLOC';
        if Location.Insert() then;
        EDocPurchLineField."Code Value" := Location.Code;
        EDocPurchLineField.Insert();

        // [WHEN] Removing the general setup for the additional fields
        EDocPurchLineFieldSetup.DeleteAll();
        // [WHEN] Creating a purchase invoice from the draft
        TempEDocImportParams."Step to Run" := "Import E-Document Steps"::"Finish draft";
        Assert.IsTrue(EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParams), 'The e-document should be processed');

        // [THEN] The additional fields should not be set on the purchase invoice line
        EDocument.Get(EDocument."Entry No");
        PurchaseHeader.Get(EDocument."Document Record ID");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindFirst();
        Assert.AreNotEqual(Location.Code, PurchaseLine."Location Code", 'The location code should not be set on the purchase line.');
    end;

    [Test]
    procedure PreparingPurchaseDraftFindsItemReference()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        Item: Record Item;
        ItemReference: Record "Item Reference";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocImport: Codeunit "E-Doc. Import";
    begin
        // [GIVEN] An E-Doc received with Product code as an existing Item Reference
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2.Insert();
        LibraryInventory.CreateItem(Item);
        ItemReference := CreateItemReference(Vendor2, Item);

        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."Vendor VAT Id" := Vendor2."VAT Registration No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine."Product Code" := ItemReference."Reference No.";
        EDocumentPurchaseLine.Description := 'Test description';
        EDocumentPurchaseLine.Insert();

        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::"Ready for draft");
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";

        // [WHEN] Filling in the draft
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        EDocumentPurchaseLine.SetRecFilter();
        EDocumentPurchaseLine.FindFirst();

        EDocumentPurchaseHeader.SetRecFilter();
        EDocumentPurchaseHeader.FindFirst();

        // [THEN] The draft is populated with the information in the item reference
        Assert.AreEqual(Vendor2."No.", EDocumentPurchaseHeader."[BC] Vendor No.", 'The vendor should be found when the tax id is specified and it matches the one in BC.');
        Assert.AreEqual(Enum::"Purchase Line Type"::Item, EDocumentPurchaseLine."[BC] Purchase Line Type", 'The purchase line type should be set to Item.');
        Assert.AreEqual(Item."No.", EDocumentPurchaseLine."[BC] Purchase Type No.", 'The item configured in the item reference should be found.');

        Vendor2.SetRecFilter();
        if Vendor2.Delete() then;
        Item.SetRecFilter();
        if Item.Delete() then;
        ItemReference.SetRecFilter();
        if ItemReference.Delete() then;
    end;

    [Test]
    procedure ItemReferenceIsNotConsideredWhenOutsideOfDateValidity()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        Item: Record Item;
        ItemReference: Record "Item Reference";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocImport: Codeunit "E-Doc. Import";
    begin
        // [GIVEN] An E-Doc received with Product code as an existing Item Reference
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2.Insert();

        LibraryInventory.CreateItem(Item);

        ItemReference := CreateItemReference(Vendor2, Item);

        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."Vendor VAT Id" := Vendor2."VAT Registration No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine."Product Code" := ItemReference."Reference No.";
        EDocumentPurchaseLine.Description := 'Test description';
        EDocumentPurchaseLine.Insert();

        // [GIVEN] The item reference is only valid in the future (not on the e-document's default posting date)
        ItemReference."Starting Date" := CalcDate('<+1D>', WorkDate());
        ItemReference.Modify();

        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::"Ready for draft");
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";

        // [WHEN] Filling in the draft
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        EDocumentPurchaseLine.SetRecFilter();
        EDocumentPurchaseLine.FindFirst();

        EDocumentPurchaseHeader.SetRecFilter();
        EDocumentPurchaseHeader.FindFirst();

        // [THEN] The line has no item match found
        Assert.AreEqual(Vendor2."No.", EDocumentPurchaseHeader."[BC] Vendor No.", 'The vendor should be found when the tax id is specified and it matches the one in BC.');
        Assert.AreNotEqual(Enum::"Purchase Line Type"::Item, EDocumentPurchaseLine."[BC] Purchase Line Type", 'The purchase line type should not be item (item reference doesn''t match).');

        Vendor2.SetRecFilter();
        if Vendor2.Delete() then;
        Item.SetRecFilter();
        if Item.Delete() then;
        ItemReference.SetRecFilter();
        if ItemReference.Delete() then;
    end;

    [Test]
    procedure FinishDraftCreditMemoCanBeUndone()
    var
        EDocument: Record "E-Document";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        PurchaseHeader: Record "Purchase Header";
        EDocLogRecord: Record "E-Document Log";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentLog: Codeunit "E-Document Log";
        EDocumentProcessing: Codeunit "E-Document Processing";
    begin
        // [SCENARIO] A credit memo created via FinishDraft can be reverted
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);
        EDocument."Document Type" := "E-Document Type"::"Purchase Credit Memo";
        EDocument.Modify();
        EDocumentService."Import Process" := "E-Document Import Process"::"Version 2.0";
        EDocumentService.Modify();

        EDocumentLog.SetBlob('Test', Enum::"E-Doc. File Format"::XML, 'Data');
        EDocumentLog.SetFields(EDocument, EDocumentService);
        EDocLogRecord := EDocumentLog.InsertLog(Enum::"E-Document Service Status"::Imported, Enum::"Import E-Doc. Proc. Status"::Readable);

        EDocument."Structured Data Entry No." := EDocLogRecord."E-Doc. Data Storage Entry No.";
        EDocument.Modify();

        // [GIVEN] A credit memo is created via FinishDraft
        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::"Draft Ready");
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Finish draft";
        TempEDocImportParameters."Processing Customizations" := "E-Doc. Proc. Customizations"::"Mock Create Purchase Invoice";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        PurchaseHeader.SetRange("E-Document Link", EDocument.SystemId);
        PurchaseHeader.FindFirst();
        Assert.AreEqual("Purchase Document Type"::"Credit Memo", PurchaseHeader."Document Type", 'The document type should be Credit Memo.');

        // [WHEN] Undo is performed
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Structure received data";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        // [THEN] The credit memo is removed
        Assert.RecordIsEmpty(PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('EditDimensionSetEntriesHandler')]
    procedure ManuallyAddedDimensionsOnDraftAreCarriedToPurchaseInvoice()
    var
        EDocument: Record "E-Document";
        TempEDocImportParams: Record "E-Doc. Import Parameters";
        EDocPurchaseLine: Record "E-Document Purchase Line";
        EDocPurchaseLineReread: Record "E-Document Purchase Line";
        DimensionValue: Record "Dimension Value";
        DimSetEntry: Record "Dimension Set Entry";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        // [SCENARIO] When the user edits dimensions on an e-document draft line via LookupDimensions,
        // the changes should be persisted to the database.
        Initialize(Enum::"Service Integration"::"Mock");
        EDocumentService."Read into Draft Impl." := "E-Doc. Read into Draft"::PEPPOL;
        EDocumentService.Modify();

        // [GIVEN] An inbound e-document is received and a draft is created
        TempEDocImportParams."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        WorkDate(DMY2Date(1, 1, 2027));
        Assert.IsTrue(LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-invoice-0.xml', TempEDocImportParams), 'The draft should be created');

        // [GIVEN] A dimension value to add via the Dimensions lookup
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);

        // [WHEN] LookupDimensions is called on the draft line (simulating the Dimensions page action)
        EDocPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPurchaseLine.FindFirst();
        EDocPurchaseLine.LookupDimensions(); // Opens modal handled by EditDimensionSetEntriesHandler

        // [THEN] The dimension should be persisted on the e-document purchase line when re-read from the database
        EDocPurchaseLineReread.Get(EDocPurchaseLine."E-Document Entry No.", EDocPurchaseLine."Line No.");

        DimSetEntry.SetRange("Dimension Set ID", EDocPurchaseLineReread."[BC] Dimension Set ID");
        DimSetEntry.SetRange("Dimension Code", DimensionValue."Dimension Code");
        DimSetEntry.SetRange("Dimension Value Code", DimensionValue.Code);
        Assert.RecordIsNotEmpty(DimSetEntry);
    end;

    [ModalPageHandler]
    procedure EditDimensionSetEntriesHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    var
        DimensionCode: Code[20];
        DimensionValueCode: Code[20];
    begin
        DimensionCode := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20);
        DimensionValueCode := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20);
        EditDimensionSetEntries.New();
        EditDimensionSetEntries."Dimension Code".SetValue(DimensionCode);
        EditDimensionSetEntries.DimensionValueCode.SetValue(DimensionValueCode);
        EditDimensionSetEntries.OK().Invoke();
    end;

    [Test]
    procedure ProcessingInboundCreditNoteCreatesCorrectDocumentType()
    var
        EDocument: Record "E-Document";
        TempEDocImportParams: Record "E-Doc. Import Parameters";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        EDocRecordLink: Record "E-Doc. Record Link";
    begin
        // [SCENARIO] A PEPPOL CreditNote processed through the full pipeline creates a Purchase Credit Memo with correct content
        Initialize(Enum::"Service Integration"::"Mock");
        EDocumentService."Read into Draft Impl." := "E-Doc. Read into Draft"::PEPPOL;
        EDocumentService.Modify();

        EDocRecordLink.DeleteAll();

        // [GIVEN] An inbound credit note e-document is received and fully processed
        TempEDocImportParams."Step to Run" := "Import E-Document Steps"::"Finish draft";
        WorkDate(DMY2Date(1, 1, 2027));
        Assert.IsTrue(LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-creditnote-0.xml', TempEDocImportParams), 'The credit note e-document should be processed');

        // [THEN] The E-Document type is Purchase Credit Memo
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual("E-Document Type"::"Purchase Credit Memo", EDocument."Document Type", 'The document type should be Purchase Credit Memo.');

        // [THEN] A Purchase Credit Memo header is created with correct fields
        PurchaseHeader.Get(EDocument."Document Record ID");
        Assert.AreEqual("Purchase Document Type"::"Credit Memo", PurchaseHeader."Document Type", 'The purchase header document type should be Credit Memo.');
        Assert.AreEqual(EDocument.SystemId, PurchaseHeader."E-Document Link", 'The E-Document link should be set on the purchase header.');
        Assert.AreEqual('CN-5001', PurchaseHeader."Vendor Cr. Memo No.", 'The vendor credit memo number should match the CreditNote ID.');
        Assert.AreEqual(Vendor."No.", PurchaseHeader."Buy-from Vendor No.", 'The vendor should be resolved from the CreditNote.');
        Assert.AreEqual(2500, PurchaseHeader."Doc. Amount Incl. VAT", 'The document amount incl. VAT should match the CreditNote total.');
        Assert.AreEqual('5', PurchaseHeader."Vendor Order No.", 'The Vendor Order No. should match the OrderReference from the CreditNote.');

        // [THEN] The purchase credit memo has the correct number of lines
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.RecordCount(PurchaseLine, 1);

        // [THEN] Links are created between e-document and purchase records
        EDocRecordLink.SetRange("Target Table No.", Database::"Purchase Header");
        EDocRecordLink.SetRange("Target SystemId", PurchaseHeader.SystemId);
        Assert.RecordCount(EDocRecordLink, 1);
    end;

    [Test]
    procedure ProcessingInboundInvoiceStillCreatesCorrectDocumentType()
    var
        EDocument: Record "E-Document";
        TempEDocImportParams: Record "E-Doc. Import Parameters";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] After the refactoring, a PEPPOL Invoice still creates a Purchase Invoice with correct content (regression check)
        Initialize(Enum::"Service Integration"::"Mock");
        EDocumentService."Read into Draft Impl." := "E-Doc. Read into Draft"::PEPPOL;
        EDocumentService.Modify();

        TempEDocImportParams."Step to Run" := "Import E-Document Steps"::"Finish draft";
        WorkDate(DMY2Date(1, 1, 2027));
        Assert.IsTrue(LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-invoice-0.xml', TempEDocImportParams), 'The invoice e-document should be processed');

        // [THEN] The E-Document type is Purchase Invoice
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual("E-Document Type"::"Purchase Invoice", EDocument."Document Type", 'The document type should be Purchase Invoice.');

        // [THEN] A Purchase Invoice header is created with correct fields
        PurchaseHeader.Get(EDocument."Document Record ID");
        Assert.AreEqual("Purchase Document Type"::Invoice, PurchaseHeader."Document Type", 'The purchase header document type should be Invoice.');
        Assert.AreEqual('103033', PurchaseHeader."Vendor Invoice No.", 'The vendor invoice number should match the Invoice ID.');
        Assert.AreEqual('2', PurchaseHeader."Vendor Order No.", 'The vendor order number should match the OrderReference from the Invoice.');
        Assert.AreEqual(Vendor."No.", PurchaseHeader."Buy-from Vendor No.", 'The vendor should be resolved from the Invoice.');
        Assert.AreEqual(14140, PurchaseHeader."Doc. Amount Incl. VAT", 'The document amount incl. VAT should match the Invoice total.');

        // [THEN] The purchase invoice has the correct number of lines (2 from peppol-invoice-0.xml)
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.RecordCount(PurchaseLine, 2);
    end;

    local procedure Initialize(Integration: Enum "Service Integration")
    var
        TransformationRule: Record "Transformation Rule";
        EDocument: Record "E-Document";
        EDocDataStorage: Record "E-Doc. Data Storage";
        EDocumentServiceStatus: Record "E-Document Service Status";
        EDocPurchLineFieldSetup: Record "ED Purchase Line Field Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        LibraryVariableStorage.Clear();
        Clear(EDocImplState);
        EDocPurchLineFieldSetup.DeleteAll();

        PurchInvHeader.DeleteAll();
        VendorLedgerEntry.DeleteAll();

        if IsInitialized then
            exit;

        GLSetup.GetRecordOnce();
        GLSetup."VAT Reporting Date Usage" := GLSetup."VAT Reporting Date Usage"::Disabled;
        GLSetup.Modify();

        // Set a currency that can be used across all localizations
        Currency.Init();
        Currency.Validate(Code, 'XYZ');
        if Currency.Insert(true) then
            LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 1.0, 1.0);

        EDocument.DeleteAll();
        EDocumentServiceStatus.DeleteAll();
        EDocumentService.DeleteAll();
        EDocDataStorage.DeleteAll();

        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::Mock, Integration);
        LibraryEDoc.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::Mock, Integration);
        EDocumentService."Import Process" := "E-Document Import Process"::"Version 2.0";
        EDocumentService."Read into Draft Impl." := "E-Doc. Read into Draft"::PEPPOL;
        EDocumentService.Modify();

        TransformationRule.DeleteAll();
        TransformationRule.CreateDefaultTransformations();

        IsInitialized := true;
    end;

#pragma warning disable AA0244
    local procedure CreateItemReference(Vendor: Record Vendor; Item: Record Item) ItemReference: Record "Item Reference"
#pragma warning restore AA0244
    begin
        ItemReference."Item No." := Item."No.";
        ItemReference."Variant Code" := '';
        ItemReference."Unit of Measure" := '';
        ItemReference."Reference Type" := "Item Reference Type"::Vendor;
        ItemReference."Reference Type No." := Vendor."No.";
        ItemReference."Reference No." := 'TESTITMREFNO';
        ItemReference.Insert();
    end;

}
