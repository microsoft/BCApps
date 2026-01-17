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
        EDocImportParameters: Record "E-Doc. Import Parameters";
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
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Structure received data";

        EDocument.CalcFields("Import Processing Status");
        Assert.AreEqual(Enum::"Import E-Doc. Proc. Status"::Unprocessed, EDocument."Import Processing Status", 'The status should be updated to the one after the step executed.');
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);
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
        EDocImportParameters: Record "E-Doc. Import Parameters";
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
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);

        EDocument.CalcFields("Import Processing Status");
        Assert.AreEqual(ImportEDocumentProcess.GetStatusForStep(EDocImportParameters."Step to Run", false), EDocument."Import Processing Status", 'The status should be updated to the one after the step executed.');
    end;

    [Test]
    procedure ProcessingUndoesSteps()
    var
        EDocument: Record "E-Document";
        EDocImportParameters: Record "E-Doc. Import Parameters";
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
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);

        EDocument.CalcFields("Import Processing Status");
        Assert.AreEqual(ImportEDocumentProcess.GetStatusForStep(EDocImportParameters."Step to Run", false), EDocument."Import Processing Status", 'The status should be updated to the one after the step executed.');

        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Structure received data";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);

        EDocument.CalcFields("Import Processing Status");
        Assert.AreEqual(ImportEDocumentProcess.GetStatusForStep(EDocImportParameters."Step to Run", false), EDocument."Import Processing Status", 'The status should be updated to the one after the step executed.');
    end;

    [Test]
    procedure PreparingPurchaseDraftFindsPurchaseOrderWhenSpecified()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocImportParameters: Record "E-Doc. Import Parameters";
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
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);

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
        EDocImportParameters: Record "E-Doc. Import Parameters";
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
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);

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
        EDocImportParameters: Record "E-Doc. Import Parameters";
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
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);

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
        EDocImportParameters: Record "E-Doc. Import Parameters";
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
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Finish draft";
        EDocImportParameters."Processing Customizations" := "E-Doc. Proc. Customizations"::"Mock Create Purchase Invoice";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);

        PurchaseHeader.SetRange("E-Document Link", EDocument.SystemId);
        PurchaseHeader.FindFirst();

        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Structure received data";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);

        Assert.RecordIsEmpty(PurchaseHeader);
    end;

    #region LinkToExistingDocument

    [Test]
    procedure LinkToExistingDocumentSetsEDocumentLink()
    var
        EDocument: Record "E-Document";
        EDocImportParameters: Record "E-Doc. Import Parameters";
        ExistingPurchaseHeader: Record "Purchase Header";
        LinkedPurchaseHeader: Record "Purchase Header";
        EDocLogRecord: Record "E-Document Log";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentLog: Codeunit "E-Document Log";
        EDocumentProcessing: Codeunit "E-Document Processing";
    begin
        // [SCENARIO] When linking an e-document to an existing purchase document, the E-Document Link is set on the purchase document
        Initialize(Enum::"Service Integration"::"Mock");

        // [GIVEN] An inbound e-document in Draft Ready state
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

        // [GIVEN] An existing purchase invoice
        ExistingPurchaseHeader."No." := 'EXISTING-001';
        ExistingPurchaseHeader."Document Type" := "Purchase Document Type"::Invoice;
        ExistingPurchaseHeader.Insert();

        // [WHEN] Finishing draft with Link To Existing Doc. Rec. ID set
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Finish draft";
        EDocImportParameters."Link To Existing Doc. Rec. ID" := ExistingPurchaseHeader.RecordId();
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);

        // [THEN] The existing purchase document has E-Document Link set
        LinkedPurchaseHeader.SetRange("E-Document Link", EDocument.SystemId);
        Assert.RecordCount(LinkedPurchaseHeader, 1);
        LinkedPurchaseHeader.FindFirst();
        Assert.AreEqual(ExistingPurchaseHeader."No.", LinkedPurchaseHeader."No.", 'The linked document should be the existing one');

        // Cleanup
        ExistingPurchaseHeader.Delete();
    end;

    [Test]
    procedure LinkToExistingDocumentDoesNotCreateNewPurchaseInvoice()
    var
        EDocument: Record "E-Document";
        EDocImportParameters: Record "E-Doc. Import Parameters";
        ExistingPurchaseHeader: Record "Purchase Header";
        AllPurchaseHeaders: Record "Purchase Header";
        EDocLogRecord: Record "E-Document Log";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentLog: Codeunit "E-Document Log";
        EDocumentProcessing: Codeunit "E-Document Processing";
        InitialCount: Integer;
    begin
        // [SCENARIO] When linking an e-document to an existing purchase document, no new purchase invoice is created
        Initialize(Enum::"Service Integration"::"Mock");

        // [GIVEN] An inbound e-document in Draft Ready state
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

        // [GIVEN] An existing purchase invoice and count of all purchase headers
        ExistingPurchaseHeader."No." := 'EXISTING-002';
        ExistingPurchaseHeader."Document Type" := "Purchase Document Type"::Invoice;
        ExistingPurchaseHeader.Insert();
        InitialCount := AllPurchaseHeaders.Count();

        // [WHEN] Finishing draft with Link To Existing Doc. Rec. ID set
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Finish draft";
        EDocImportParameters."Link To Existing Doc. Rec. ID" := ExistingPurchaseHeader.RecordId();
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);

        // [THEN] No new purchase header was created
        Assert.AreEqual(InitialCount, AllPurchaseHeaders.Count(), 'No new purchase document should be created when linking to existing');

        // Cleanup
        ExistingPurchaseHeader.Delete();
    end;

    [Test]
    procedure LinkToExistingDocumentMarksEDocumentAsProcessed()
    var
        EDocument: Record "E-Document";
        EDocImportParameters: Record "E-Doc. Import Parameters";
        ExistingPurchaseHeader: Record "Purchase Header";
        EDocLogRecord: Record "E-Document Log";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentLog: Codeunit "E-Document Log";
        EDocumentProcessing: Codeunit "E-Document Processing";
    begin
        // [SCENARIO] When linking an e-document to an existing purchase document, the e-document is marked as processed
        Initialize(Enum::"Service Integration"::"Mock");

        // [GIVEN] An inbound e-document in Draft Ready state
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

        // [GIVEN] An existing purchase invoice
        ExistingPurchaseHeader."No." := 'EXISTING-003';
        ExistingPurchaseHeader."Document Type" := "Purchase Document Type"::Invoice;
        ExistingPurchaseHeader.Insert();

        // [WHEN] Finishing draft with Link To Existing Doc. Rec. ID set
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Finish draft";
        EDocImportParameters."Link To Existing Doc. Rec. ID" := ExistingPurchaseHeader.RecordId();
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);

        // [THEN] The e-document import processing status is Processed
        EDocument.CalcFields("Import Processing Status");
        Assert.AreEqual(Enum::"Import E-Doc. Proc. Status"::Processed, EDocument."Import Processing Status", 'The e-document should be marked as processed after linking');

        // Cleanup
        ExistingPurchaseHeader.Delete();
    end;

    [Test]
    procedure LinkToExistingDocumentUpdatesDocumentAmounts()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocImportParameters: Record "E-Doc. Import Parameters";
        ExistingPurchaseHeader: Record "Purchase Header";
        EDocLogRecord: Record "E-Document Log";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentLog: Codeunit "E-Document Log";
        EDocumentProcessing: Codeunit "E-Document Processing";
    begin
        // [SCENARIO] When linking an e-document to an existing purchase document, document amounts are updated on the purchase document
        Initialize(Enum::"Service Integration"::"Mock");

        // [GIVEN] An inbound e-document in Draft Ready state with total amounts
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

        // Set up e-document purchase header with amounts
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader.Total := 1000;
        EDocumentPurchaseHeader."Total VAT" := 200;
        if not EDocumentPurchaseHeader.Insert() then
            EDocumentPurchaseHeader.Modify();

        // [GIVEN] An existing purchase invoice
        ExistingPurchaseHeader."No." := 'EXISTING-004';
        ExistingPurchaseHeader."Document Type" := "Purchase Document Type"::Invoice;
        ExistingPurchaseHeader.Insert();

        // [WHEN] Finishing draft with Link To Existing Doc. Rec. ID set
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Finish draft";
        EDocImportParameters."Link To Existing Doc. Rec. ID" := ExistingPurchaseHeader.RecordId();
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);

        // [THEN] The purchase document has the e-document amounts
        ExistingPurchaseHeader.Get(ExistingPurchaseHeader."Document Type", ExistingPurchaseHeader."No.");
        Assert.AreEqual(1000, ExistingPurchaseHeader."Doc. Amount Incl. VAT", 'The document amount incl. VAT should be set from e-document');
        Assert.AreEqual(200, ExistingPurchaseHeader."Doc. Amount VAT", 'The document VAT amount should be set from e-document');

        // Cleanup
        ExistingPurchaseHeader.Delete();
    end;

    [Test]
    procedure GetPurchaseDocTypeFilterReturnsCorrectType()
    var
        EDocumentProcessing: Codeunit "E-Document Processing";
        PurchaseDocType: Enum "Purchase Document Type";
    begin
        // [SCENARIO] GetPurchaseDocTypeFilter correctly maps E-Document types to Purchase Document types
        Initialize(Enum::"Service Integration"::"Mock");

        // [WHEN/THEN] Purchase Invoice maps to Invoice
        PurchaseDocType := EDocumentProcessing.GetPurchaseDocTypeFilter(Enum::"E-Document Type"::"Purchase Invoice");
        Assert.AreEqual(Enum::"Purchase Document Type"::Invoice, PurchaseDocType, 'Purchase Invoice should map to Invoice');

        // [WHEN/THEN] Purchase Credit Memo maps to Credit Memo
        PurchaseDocType := EDocumentProcessing.GetPurchaseDocTypeFilter(Enum::"E-Document Type"::"Purchase Credit Memo");
        Assert.AreEqual(Enum::"Purchase Document Type"::"Credit Memo", PurchaseDocType, 'Purchase Credit Memo should map to Credit Memo');

        // [WHEN/THEN] Purchase Order maps to Order
        PurchaseDocType := EDocumentProcessing.GetPurchaseDocTypeFilter(Enum::"E-Document Type"::"Purchase Order");
        Assert.AreEqual(Enum::"Purchase Document Type"::Order, PurchaseDocType, 'Purchase Order should map to Order');
    end;

    #endregion

    #region HistoricalMatchingTest

    [Test]
    procedure ProcessingInboundDocumentCreatesLinks()
    var
        EDocument: Record "E-Document";
        EDocImportParams: Record "E-Doc. Import Parameters";
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
        EDocImportParams."Step to Run" := "Import E-Document Steps"::"Finish draft";
        WorkDate(DMY2Date(1, 1, 2027)); // Peppol document date is in 2026
        Assert.IsTrue(LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-invoice-0.xml', EDocImportParams), 'The e-document should be processed');

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
        EDocImportParams: Record "E-Doc. Import Parameters";
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
        EDocImportParams."Step to Run" := "Import E-Document Steps"::"Finish draft";
        WorkDate(DMY2Date(1, 1, 2027)); // Peppol document date is in 2026
        Assert.IsTrue(LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-invoice-0.xml', EDocImportParams), 'The e-document should be processed');

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
        EDocImportParams: Record "E-Doc. Import Parameters";
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
        EDocImportParams."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        WorkDate(DMY2Date(1, 1, 2027)); // Peppol document date is in 2026
        Assert.IsTrue(LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-invoice-0.xml', EDocImportParams), 'The draft for the e-document should be created');

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
        EDocImportParams."Step to Run" := "Import E-Document Steps"::"Finish draft";
        Assert.IsTrue(EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParams), 'The e-document should be processed');

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
        EDocImportParams: Record "E-Doc. Import Parameters";
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
        EDocImportParams."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        WorkDate(DMY2Date(1, 1, 2027)); // Peppol document date is in 2026
        Assert.IsTrue(LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-invoice-0.xml', EDocImportParams), 'The draft for the e-document should be created');

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
        EDocImportParams."Step to Run" := "Import E-Document Steps"::"Finish draft";
        Assert.IsTrue(EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParams), 'The e-document should be processed');

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
        EDocImportParameters: Record "E-Doc. Import Parameters";
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
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";

        // [WHEN] Filling in the draft
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);

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
        EDocImportParameters: Record "E-Doc. Import Parameters";
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
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";

        // [WHEN] Filling in the draft
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);

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

    local procedure Initialize(Integration: Enum "Service Integration")
    var
        TransformationRule: Record "Transformation Rule";
        EDocument: Record "E-Document";
        EDocDataStorage: Record "E-Doc. Data Storage";
        EDocumentsSetup: Record "E-Documents Setup";
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
        EDocumentsSetup.InsertNewExperienceSetup();

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
