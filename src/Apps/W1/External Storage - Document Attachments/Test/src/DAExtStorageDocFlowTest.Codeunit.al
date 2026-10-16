// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments.Test;

using Microsoft.ExternalStorage.DocumentAttachments;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Attachment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using System.Environment;
using System.ExternalFileStorage;
using System.TestLibraries.ExternalFileStorage;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 136822 "DA Ext. Storage Doc. Flow Test"
{
    // Business document flows (posting, quote conversion) depend on demo setup data,
    // so they cannot run as unit tests in an empty company.
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;
    Permissions = tabledata "Document Attachment" = rimd,
                  tabledata "Tenant Media" = rmd,
                  tabledata "DA External Storage Setup" = rimd;

    var
        Any: Codeunit Any;
        FileConnectorMock: Codeunit "File Connector Mock";
        FileScenarioMock: Codeunit "File Scenario Mock";
        Assert: Codeunit "Library Assert";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure PurchaseQuoteConversionKeepsSharedExternalFile()
    var
        PurchaseQuote: Record "Purchase Header";
        PurchaseOrder: Record "Purchase Header";
        DocumentAttachment: Record "Document Attachment";
        OrderDocumentAttachment: Record "Document Attachment";
        PurchQuoteToOrder: Codeunit "Purch.-Quote to Order";
        QuoteNo: Code[20];
        ExternalFilePath: Text;
    begin
        // [SCENARIO] Make Order deletes the quote, not the external file now referenced by the order.
        Initialize();
        InitializeDocumentSetup();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        LibraryPurchase.CreatePurchHeader(PurchaseQuote, PurchaseQuote."Document Type"::Quote, '');
        QuoteNo := PurchaseQuote."No.";
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        DocumentAttachment.Rename(Database::"Purchase Header", QuoteNo, DocumentAttachment."Document Type"::Quote, 0, DocumentAttachment.ID);
        ExternalFilePath := DocumentAttachment."External File Path";

        PurchQuoteToOrder.Run(PurchaseQuote);
        PurchQuoteToOrder.GetPurchOrderHeader(PurchaseOrder);

        Assert.IsFalse(PurchaseQuote.Get(PurchaseQuote."Document Type"::Quote, QuoteNo), 'Make Order must delete the source quote');
        Assert.AreEqual(QuoteNo, PurchaseOrder."Quote No.", 'The order must originate from the quote');
        VerifySourceAttachmentDeleted(DocumentAttachment);
        FindHeaderAttachment(OrderDocumentAttachment, Database::"Purchase Header", PurchaseOrder."No.");
        Assert.IsTrue(OrderDocumentAttachment."Skip Delete On Copy", 'The actual quote copy flow must protect the destination');
        VerifySharedExternalFileRetained(OrderDocumentAttachment, ExternalFilePath);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure SalesPostingKeepsSharedExternalFile()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentAttachment: Record "Document Attachment";
        LineDocumentAttachment: Record "Document Attachment";
        PostedDocumentAttachment: Record "Document Attachment";
        PostedLineDocumentAttachment: Record "Document Attachment";
        SourceNo: Code[20];
        PostedNo: Code[20];
        ExternalFilePath: Text;
        LineExternalFilePath: Text;
    begin
        // [SCENARIO] Actual sales posting copies the external-only attachment before deleting its source.
        Initialize();
        InitializeDocumentSetup();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SourceNo := SalesHeader."No.";
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        DocumentAttachment.Rename(Database::"Sales Header", SourceNo, DocumentAttachment."Document Type"::Invoice, 0, DocumentAttachment.ID);
        ExternalFilePath := DocumentAttachment."External File Path";
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SourceNo);
        SalesLine.FindFirst();
        EnsureGeneralPostingSetup(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        CreateUploadedExternalOnlyAttachment(LineDocumentAttachment);
        LineDocumentAttachment.Rename(Database::"Sales Line", SourceNo, LineDocumentAttachment."Document Type"::Invoice, SalesLine."Line No.", LineDocumentAttachment.ID);
        LineExternalFilePath := LineDocumentAttachment."External File Path";

        PostedNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        Assert.IsFalse(SalesHeader.Get(SalesHeader."Document Type"::Invoice, SourceNo), 'Posting must delete the source sales invoice');
        VerifySourceAttachmentDeleted(DocumentAttachment);
        VerifySourceAttachmentDeleted(LineDocumentAttachment);
        FindHeaderAttachment(PostedDocumentAttachment, Database::"Sales Invoice Header", PostedNo);
        VerifySharedExternalFileRetained(PostedDocumentAttachment, ExternalFilePath);
        FindHeaderAttachment(PostedLineDocumentAttachment, Database::"Sales Invoice Line", PostedNo);
        VerifySharedExternalFileRetained(PostedLineDocumentAttachment, LineExternalFilePath);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure PurchasePostingKeepsSharedExternalFile()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentAttachment: Record "Document Attachment";
        LineDocumentAttachment: Record "Document Attachment";
        PostedDocumentAttachment: Record "Document Attachment";
        PostedLineDocumentAttachment: Record "Document Attachment";
        SourceNo: Code[20];
        PostedNo: Code[20];
        ExternalFilePath: Text;
        LineExternalFilePath: Text;
    begin
        // [SCENARIO] Actual purchase posting retains the file copied onto the posted invoice.
        Initialize();
        InitializeDocumentSetup();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        SourceNo := PurchaseHeader."No.";
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        DocumentAttachment.Rename(Database::"Purchase Header", SourceNo, DocumentAttachment."Document Type"::Invoice, 0, DocumentAttachment.ID);
        ExternalFilePath := DocumentAttachment."External File Path";
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", SourceNo);
        PurchaseLine.FindFirst();
        EnsureGeneralPostingSetup(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        CreateUploadedExternalOnlyAttachment(LineDocumentAttachment);
        LineDocumentAttachment.Rename(Database::"Purchase Line", SourceNo, LineDocumentAttachment."Document Type"::Invoice, PurchaseLine."Line No.", LineDocumentAttachment.ID);
        LineExternalFilePath := LineDocumentAttachment."External File Path";

        PostedNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        Assert.IsFalse(PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, SourceNo), 'Posting must delete the source purchase invoice');
        VerifySourceAttachmentDeleted(DocumentAttachment);
        VerifySourceAttachmentDeleted(LineDocumentAttachment);
        FindHeaderAttachment(PostedDocumentAttachment, Database::"Purch. Inv. Header", PostedNo);
        VerifySharedExternalFileRetained(PostedDocumentAttachment, ExternalFilePath);
        FindHeaderAttachment(PostedLineDocumentAttachment, Database::"Purch. Inv. Line", PostedNo);
        VerifySharedExternalFileRetained(PostedLineDocumentAttachment, LineExternalFilePath);
    end;

    local procedure Initialize()
    var
        DAExternalStorageSetup: Record "DA External Storage Setup";
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.DeleteAll();
        if DAExternalStorageSetup.Get() then
            DAExternalStorageSetup.Delete();

        FileScenarioMock.DeleteAllMappings();
        FileConnectorMock.Initialize();
    end;

    local procedure EnsureGeneralPostingSetup(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        LibraryERM: Codeunit "Library - ERM";
    begin
        if not GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup) then
            LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup, GenProdPostingGroup);

        LibraryERM.SetGeneralPostingSetupInvtAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupMfgAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupSalesAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPurchAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure InitializeDocumentSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryPurchase.SetQuoteNoSeriesInSetup();
        LibraryPurchase.SetOrderNoSeriesInSetup();
        LibraryPurchase.SetPostedNoSeriesInSetup();
        LibrarySales.SetPostedNoSeriesInSetup();
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Purchases & Payables Setup", PurchasesPayablesSetup.FieldNo("Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Invoice Nos."));
    end;

    local procedure CreateUploadedExternalOnlyAttachment(var DocumentAttachment: Record "Document Attachment")
    var
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
    begin
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        UploadDocumentAttachment(DocumentAttachment);
        Assert.IsTrue(DAExternalStorageImpl.DeleteFromInternalStorage(DocumentAttachment), 'The attachment must become external-only');
        RefreshAttachment(DocumentAttachment);
        Assert.IsFalse(DocumentAttachment."Stored Internally", 'The external-only fixture must release internal storage');
        Assert.IsFalse(DocumentAttachment."Document Reference ID".HasValue(), 'Internal media must not mask external file loss in the fixture');
        Assert.IsFalse(DocumentAttachment."Skip Delete On Copy", 'The source must be eligible for deletion');
    end;

    local procedure VerifySourceAttachmentDeleted(SourceDocumentAttachment: Record "Document Attachment")
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment := SourceDocumentAttachment;
        DocumentAttachment.SetRecFilter();
        Assert.IsTrue(DocumentAttachment.IsEmpty(), 'The actual document flow must delete the source attachment');
    end;

    local procedure FindHeaderAttachment(var DocumentAttachment: Record "Document Attachment"; TableId: Integer; DocumentNo: Code[20])
    begin
        DocumentAttachment.SetRange("Table ID", TableId);
        DocumentAttachment.SetRange("No.", DocumentNo);
        Assert.AreEqual(1, DocumentAttachment.Count(), 'The destination must have exactly one copied attachment');
        DocumentAttachment.FindFirst();
    end;

    local procedure VerifySharedExternalFileRetained(var DocumentAttachment: Record "Document Attachment"; ExternalFilePath: Text)
    var
        ExternalFileStorage: Codeunit "External File Storage";
        AttachmentInStream: InStream;
    begin
        RefreshAttachment(DocumentAttachment);
        Assert.IsTrue(DocumentAttachment."Stored Externally", 'The remaining attachment must stay external');
        Assert.AreEqual(ExternalFilePath, DocumentAttachment."External File Path", 'The shared path must remain unchanged');
        Assert.IsFalse(DocumentAttachment."Document Reference ID".HasValue(), 'Internal media must not mask external file loss');
        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'Do not delete a file while another attachment references it');
        Assert.IsTrue(DocumentAttachment.HasContent(), 'The remaining attachment must report content');
        ExternalFileStorage.Initialize(Enum::"File Scenario"::"Doc. Attach. - External Storage");
        Assert.IsTrue(ExternalFileStorage.GetFile(ExternalFilePath, AttachmentInStream), 'The remaining path must be readable through the mock connector');
    end;

    local procedure UploadDocumentAttachment(var DocumentAttachment: Record "Document Attachment")
    var
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
    begin
        Assert.IsTrue(DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment), 'Upload must succeed');
        RefreshAttachment(DocumentAttachment);
    end;

    local procedure SetupFileScenarioWithTestConnector()
    var
        AccountId: Guid;
    begin
        // Add a test account
        FileConnectorMock.AddAccount(AccountId);

        // Set up file scenario to use test connector using the mock
        FileScenarioMock.AddMapping(
            Enum::"File Scenario"::"Doc. Attach. - External Storage",
            AccountId,
            Enum::"Ext. File Storage Connector"::"Test File Storage Connector"
        );
    end;

    local procedure EnableFeatureWithDelete()
    var
        DAExternalStorageSetup: Record "DA External Storage Setup";
    begin
        if not DAExternalStorageSetup.Get() then begin
            DAExternalStorageSetup.Init();
            DAExternalStorageSetup.Insert();
        end;
        DAExternalStorageSetup.Validate(Enabled, true);
        DAExternalStorageSetup.Validate("Delete from External Storage", true);
        DAExternalStorageSetup.Modify();
    end;

    local procedure CreateDocumentAttachmentWithContent(var DocumentAttachment: Record "Document Attachment")
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('Test content for attachment ' + Any.AlphanumericText(10));
        TempBlob.CreateInStream(InStream);

        DocumentAttachment.Init();
        DocumentAttachment.ID := Any.IntegerInRange(10000, 99999);
        DocumentAttachment."Table ID" := Database::"Document Attachment";
        DocumentAttachment."No." := CopyStr(Any.AlphanumericText(20), 1, 20);
        DocumentAttachment."File Name" := 'TestFile_' + CopyStr(Any.AlphanumericText(5), 1, 5);
        DocumentAttachment."File Extension" := 'txt';
        DocumentAttachment."Stored Internally" := true;
        DocumentAttachment.Insert(false);
        DocumentAttachment.ImportAttachment(InStream, DocumentAttachment."File Name" + '.txt');
        DocumentAttachment.Modify(false);
    end;

    local procedure RefreshAttachment(var DocumentAttachment: Record "Document Attachment")
    begin
        DocumentAttachment.Get(
            DocumentAttachment."Table ID",
            DocumentAttachment."No.",
            DocumentAttachment."Document Type",
            DocumentAttachment."Line No.",
            DocumentAttachment.ID);
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
