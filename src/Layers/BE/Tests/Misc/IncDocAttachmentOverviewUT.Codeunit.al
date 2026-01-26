codeunit 134418 "Inc Doc Attachment Overview UT"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Incoming Documents] [Attachment]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        SupportingAttachmentsTxt: Label 'Supporting Attachments';
        IncomingDocMustBeFoundErr: Label 'Incoming Document must be found.';
        ViewIncoDocIsNotEnabledErr: Label 'View Incoming Document action is not enabled';
        RemoveIncoDocIsEnabledErr: Label 'Remove Incoming Document action must be Disable';
        Initialized: Boolean;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Inc Doc Attachment Overview UT");
        LibrarySetupStorage.Restore();
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Inc Doc Attachment Overview UT");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        Initialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        ;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Inc Doc Attachment Overview UT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFieldDefinitionsMatch()
    var
        IncDocAttachmentOverviewRecRef: RecordRef;
        IncDocAttachmentRecRef: RecordRef;
        CommonFieldRefArray: array[7] of FieldRef;
        IncDocumentSpecificFieldRefArray: array[5] of FieldRef;
    begin
        Initialize();
        GetCommonFields(CommonFieldRefArray);
        GetIncDocAttachmentOverviewSpecificFields(IncDocumentSpecificFieldRefArray);

        IncDocAttachmentOverviewRecRef.Open(DATABASE::"Inc. Doc. Attachment Overview");
        IncDocAttachmentRecRef.Open(DATABASE::"Incoming Document Attachment");

        VerifyFieldDefinitionsMatchTableFields(IncDocAttachmentOverviewRecRef, CommonFieldRefArray);
        VerifySpecificFieldsNotPresentInMainTable(IncDocAttachmentRecRef, IncDocumentSpecificFieldRefArray);

        Assert.AreEqual(
          IncDocAttachmentOverviewRecRef.FieldCount, ArrayLen(CommonFieldRefArray) + ArrayLen(IncDocumentSpecificFieldRefArray),
          'Table Definitions do not match');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLoadFromIncomingDocumentNoAttachments()
    var
        IncomingDocument: Record "Incoming Document";
        TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary;
    begin
        Initialize();
        CreateIncomingDocument(IncomingDocument, '');
        TempIncDocAttachmentOverview.InsertFromIncomingDocument(IncomingDocument, TempIncDocAttachmentOverview);

        Assert.IsFalse(TempIncDocAttachmentOverview.FindFirst(), 'Table should be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLoadFormIncomingDocumentURLOnly()
    var
        IncomingDocument: Record "Incoming Document";
        TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary;
        DocumentURL: Text;
    begin
        // Setup
        Initialize();
        DocumentURL := LibraryUtility.GenerateRandomText(300);
        CreateIncomingDocument(IncomingDocument, DocumentURL);

        // Execute
        TempIncDocAttachmentOverview.InsertFromIncomingDocument(IncomingDocument, TempIncDocAttachmentOverview);

        // Verify
        Assert.IsTrue(TempIncDocAttachmentOverview.Find('-'), 'There should be only one record in TempTable');
        Assert.AreEqual(TempIncDocAttachmentOverview."Sorting Order", 1, 'Sorting order was not set correctly');
        Assert.AreEqual(
          TempIncDocAttachmentOverview."Incoming Document Entry No.", IncomingDocument."Entry No.", 'Entry No. Does not match');
        Assert.AreEqual(TempIncDocAttachmentOverview."Line No.", 0, 'Line No. does not match');
        Assert.AreEqual(
          TempIncDocAttachmentOverview.Name, CopyStr(IncomingDocument.GetURL(), 1, MaxStrLen(TempIncDocAttachmentOverview.Name)),
          'Name was not set correctly');
        Assert.AreEqual(TempIncDocAttachmentOverview.Type, TempIncDocAttachmentOverview.Type::" ", 'Type was not set correctly');
        Assert.AreEqual(
          TempIncDocAttachmentOverview."Attachment Type", TempIncDocAttachmentOverview."Attachment Type"::Link,
          'URL was not set correcly');
        Assert.AreEqual(TempIncDocAttachmentOverview.Indentation, 0, 'Indentation was not set correctly');

        Assert.IsTrue(TempIncDocAttachmentOverview.Next() = 0, 'There should be only one record in the TempTable');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLoadFromIncomingDocumentSingleAttachment()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary;
        DocumentURL: Text;
    begin
        // Setup
        Initialize();
        DocumentURL := '';
        CreateIncomingDocument(IncomingDocument, DocumentURL);
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment);

        // Execute
        TempIncDocAttachmentOverview.InsertFromIncomingDocument(IncomingDocument, TempIncDocAttachmentOverview);

        // Verify
        Assert.IsTrue(TempIncDocAttachmentOverview.Find('-'), 'There should be only one record in TempTable');
        VerifyLineMatchesIncomingDocumentAttachment(TempIncDocAttachmentOverview, IncomingDocumentAttachment, 1, 0);
        Assert.IsTrue(TempIncDocAttachmentOverview.Next() = 0, 'There should be only one record in the TempTable');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLoadFromIncomingDocumentMultipleAttachments()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocumentAttachment2: Record "Incoming Document Attachment";
        TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary;
        DocumentURL: Text;
        SortingOrder: Integer;
    begin
        // Setup
        Initialize();
        DocumentURL := '';
        CreateIncomingDocument(IncomingDocument, DocumentURL);
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment);
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment2);

        // Execute
        TempIncDocAttachmentOverview.InsertFromIncomingDocument(IncomingDocument, TempIncDocAttachmentOverview);

        // Verify
        SortingOrder := 1;
        Assert.IsTrue(TempIncDocAttachmentOverview.Find('-'), 'Temp table should not be empty');
        VerifyLineMatchesIncomingDocumentAttachment(TempIncDocAttachmentOverview, IncomingDocumentAttachment, SortingOrder, 0);
        Assert.IsTrue(TempIncDocAttachmentOverview.Next() <> 0, 'There should be more records in the temp table');

        SortingOrder += 1;
        VerifyGroupLine(TempIncDocAttachmentOverview, IncomingDocument, SortingOrder);
        Assert.IsTrue(TempIncDocAttachmentOverview.Next() <> 0, 'There should be more records in the temp table');

        SortingOrder += 1;
        VerifyLineMatchesIncomingDocumentAttachment(TempIncDocAttachmentOverview, IncomingDocumentAttachment2, SortingOrder, 1);
        Assert.IsTrue(TempIncDocAttachmentOverview.Next() = 0, 'There should not be more records in the temp table');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLoadDifferentDocuments()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocument2: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocumentAttachment2: Record "Incoming Document Attachment";
        IncomingDocumentAttachment3: Record "Incoming Document Attachment";
        TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary;
        DocumentURL: Text;
        SortingOrder: Integer;
    begin
        // Setup
        Initialize();
        DocumentURL := '';
        CreateIncomingDocument(IncomingDocument2, DocumentURL);
        CreateIncomingDocumentAttachment(IncomingDocument2, IncomingDocumentAttachment3);

        CreateIncomingDocument(IncomingDocument, DocumentURL);
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment);
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment2);

        // Execute
        TempIncDocAttachmentOverview.InsertFromIncomingDocument(IncomingDocument2, TempIncDocAttachmentOverview);
        TempIncDocAttachmentOverview.DeleteAll();
        TempIncDocAttachmentOverview.InsertFromIncomingDocument(IncomingDocument, TempIncDocAttachmentOverview);

        // Verify
        SortingOrder := 1;
        Assert.IsTrue(TempIncDocAttachmentOverview.Find('-'), 'Temp table should not be empty');
        VerifyLineMatchesIncomingDocumentAttachment(TempIncDocAttachmentOverview, IncomingDocumentAttachment, SortingOrder, 0);
        Assert.IsTrue(TempIncDocAttachmentOverview.Next() <> 0, 'There should be more records in the temp table');

        SortingOrder += 1;
        VerifyGroupLine(TempIncDocAttachmentOverview, IncomingDocument, SortingOrder);
        Assert.IsTrue(TempIncDocAttachmentOverview.Next() <> 0, 'There should be more records in the temp table');

        SortingOrder += 1;
        VerifyLineMatchesIncomingDocumentAttachment(TempIncDocAttachmentOverview, IncomingDocumentAttachment2, SortingOrder, 1);
        Assert.IsTrue(TempIncDocAttachmentOverview.Next() = 0, 'There should not be more records in the temp table');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteRemovesIncomingDocumentAttachment()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocumentAttachment2: Record "Incoming Document Attachment";
        TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary;
        DocumentURL: Text;
    begin
        // Setup
        Initialize();
        DocumentURL := '';
        CreateIncomingDocument(IncomingDocument, DocumentURL);
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment2);
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment);

        // Execute
        TempIncDocAttachmentOverview.InsertFromIncomingDocument(IncomingDocument, TempIncDocAttachmentOverview);
        TempIncDocAttachmentOverview.Delete(true);

        // Verify
        Assert.IsFalse(
          IncomingDocumentAttachment.Get(IncomingDocumentAttachment."Incoming Document Entry No.", IncomingDocumentAttachment."Line No."),
          'Deleting an overview line should remove a permanent line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFactBoxLoadFromPostedDocument()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // Setup
        Initialize();
        CreateIncomingDocument(IncomingDocument, '');
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment);
        CreatePurchaseInvoiceAndPost(VendorLedgerEntry, IncomingDocument);
        PurchInvHeader.Get(VendorLedgerEntry."Document No.");

        // Execute
        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);

        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.GotoRecord(VendorLedgerEntry);

        // Verify
        Assert.AreEqual(
          PostedPurchaseInvoice.IncomingDocAttachFactBox.Name.Value, IncomingDocumentAttachment.Name, 'Name value should be set');
        Assert.IsFalse(PostedPurchaseInvoice.IncomingDocAttachFactBox.Next(), 'There should not be more records');

        Assert.AreEqual(
          VendorLedgerEntries.IncomingDocAttachFactBox.Name.Value, IncomingDocumentAttachment.Name, 'Name value should be set');
        Assert.IsFalse(VendorLedgerEntries.IncomingDocAttachFactBox.Next(), 'There should not be more records');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFactBoxLoadFromNotPostedDocument()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // Setup
        Initialize();
        CreateIncomingDocument(IncomingDocument, '');
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment);
        CreatePurchaseInvoice(PurchaseHeader, IncomingDocument);

        // Execute
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // Verify
        Assert.AreEqual(PurchaseInvoice.IncomingDocAttachFactBox.Name.Value, IncomingDocumentAttachment.Name, 'Name value should be set');
        Assert.IsFalse(PurchaseInvoice.IncomingDocAttachFactBox.Next(), 'There should not be more records');
    end;

    [Test]
    [HandlerFunctions('JournalTemplateModalHandler')]
    [Scope('OnPrem')]
    procedure TestFactBoxLoadFromJournalLine()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocumentAttachment2: Record "Incoming Document Attachment";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup
        Initialize();
        CreateIncomingDocument(IncomingDocument, '');
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment);
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment2);
        CreateGenJournalLine(GenJournalLine, IncomingDocument);

        // Execute
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.Value(GenJournalLine."Journal Batch Name");
        GeneralJournal.GotoRecord(GenJournalLine);

        // Verify
        GeneralJournal.IncomingDocAttachFactBox.First();
        Assert.AreEqual(GeneralJournal.IncomingDocAttachFactBox.Name.Value, IncomingDocumentAttachment.Name, 'Name value should be set');
        Assert.IsTrue(GeneralJournal.IncomingDocAttachFactBox.Next(), 'There should be more records');
        Assert.IsTrue(GeneralJournal.IncomingDocAttachFactBox.Next(), 'There should be more records');
        Assert.AreEqual(GeneralJournal.IncomingDocAttachFactBox.Name.Value, IncomingDocumentAttachment2.Name, 'Name value should be set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFactBoxNoIncomingDocuments()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // Setup
        Initialize();
        CreateIncomingDocument(IncomingDocument, '');
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment);
        CreatePurchaseInvoice(PurchaseHeader, IncomingDocument);
        IncomingDocument.Reject();
        IncomingDocument.Delete(true);

        // Execute
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // Verify
        Assert.IsFalse(PurchaseInvoice.IncomingDocAttachFactBox.Next(), 'There should not be any records');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFactBoxIncomingDocument()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocuments: TestPage "Incoming Documents";
    begin
        // Setup
        Initialize();
        CreateIncomingDocument(IncomingDocument, '');
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment);

        // Execute
        IncomingDocuments.OpenEdit();
        IncomingDocuments.GotoRecord(IncomingDocument);

        // Verify
        Assert.AreEqual(
          IncomingDocuments.IncomingDocAttachFactBox.Name.Value, IncomingDocumentAttachment.Name, 'Name value should be set');
        Assert.IsFalse(IncomingDocuments.IncomingDocAttachFactBox.Next(), 'There should not be more records');
    end;

    [Test]
    [HandlerFunctions('DeleteIncomingDocumentHandler')]
    [Scope('OnPrem')]
    procedure TestFactBoxUpdatedAfterDeletingDocument()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // Setup
        Initialize();
        CreateIncomingDocument(IncomingDocument, '');
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment);
        CreatePurchaseInvoice(PurchaseHeader, IncomingDocument);

        // Execute
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.IncomingDocAttachFactBox.IncomingDoc.Invoke();

        // Verify
        Assert.IsFalse(PurchaseInvoice.IncomingDocAttachFactBox.Next(), 'There should not be any records');
    end;

    [Test]
    [HandlerFunctions('IncomingDocumentsPageHandler')]
    [Scope('OnPrem')]
    procedure SelectIncomingDocOnPurchReturnOrderShowsUploadedIncomingDocs()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO 545860] Select Incoming Document action under Incoming Document action 
        // On Purchase Return Order page shows the uploaded Incoming Documents.
        Initialize();

        // [GIVEN] Create an Incoming Document.
        CreateIncomingDocument(IncomingDocument, LibraryRandom.RandText(4));

        // [GIVEN] Create an Incoming Document Attachment.
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment);

        // [GIVEN] Create a Purchase Return Order.
        CreatePurchaseReturnOrder(PurchaseHeader, IncomingDocument);

        // [WHEN] Run Select Incoming Document action.
        LibraryVariableStorage.Enqueue(IncomingDocument."Entry No.");
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder.SelectIncomingDoc.Invoke();

        // [THEN] Incoming Document is found in IncomingDocumentsPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ViewIncomingDocOnPurchReturnOrderIsEnabled()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO 545860]  View Incoming Document action is enable on Purchase Return Order  
        // page when incoming document is uploded on Purchase Return Order page.
        Initialize();

        // [GIVEN] Create an Incoming Document.
        CreateIncomingDocument(IncomingDocument, LibraryRandom.RandText(4));

        // [GIVEN] Create an Incoming Document Attachment.
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment);

        // [WHEN] Create a Purchase Return Order with Incoming Document.
        CreatePurchaseReturnOrder(PurchaseHeader, IncomingDocument);

        // [THEN] View Incoming Document action is enable on Purchase Return Order Page.
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        Assert.IsTrue(PurchaseReturnOrder.IncomingDocCard.Enabled(), ViewIncoDocIsNotEnabledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveIncomingDocOnPurchReturnOrderIsDisabled()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO 545860] Remove Incoming Document action is disable on Purchase Return Order  
        // page when incoming document is removed from Purchase Return Order page.
        Initialize();

        // [GIVEN] Create an Incoming Document.
        CreateIncomingDocument(IncomingDocument, LibraryRandom.RandText(4));

        // [GIVEN] Create an Incoming Document Attachment.
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment);

        // [GIVEN] Create a Purchase Return Order.
        CreatePurchaseReturnOrder(PurchaseHeader, IncomingDocument);

        // [WHEN] Run Remove Incoming Document action.
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder.RemoveIncomingDoc.Invoke();

        // [THEN] Remove Incoming Document action is disable on Purchase Return Order Page.
        Assert.IsFalse(PurchaseReturnOrder.RemoveIncomingDoc.Enabled(), RemoveIncoDocIsEnabledErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ViewIncoDocActionEnableOnPurchReturnOrderArchive()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
        PurchaseReturnOrderArchive: TestPage "Purchase Return Order Archive";
    begin
        // [SCENARIO 545860] View Incoming Document action is enable on Purchase Return Order Archive 
        // page when Purchase Return Order with incoming Document is archived.
        Initialize();

        // [GIVEN] Create an Incoming Document.
        CreateIncomingDocument(IncomingDocument, LibraryRandom.RandText(4));

        // [GIVEN] Create an Incoming Document Attachment.
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment);

        // [GIVEN] Create a Purchase Return Order.
        CreatePurchaseReturnOrder(PurchaseHeader, IncomingDocument);

        // [GIVEN] Set Archive Order True.
        LibraryPurchase.SetArchiveOrders(true);

        // [GIVEN] Archive Purchase Order.
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);

        // [WHEN] Find Purchase Document Archive.
        FindPurchDocumentArchive(PurchaseHeaderArchive, PurchaseHeader);

        // [THEN] View Incoming Document action is enable on Purchase Return Order Archive Page.
        PurchaseReturnOrderArchive.OpenEdit();
        PurchaseReturnOrderArchive.GoToRecord(PurchaseHeaderArchive);
        Assert.IsTrue(PurchaseReturnOrderArchive.IncomingDocCard.Enabled(), ViewIncoDocIsNotEnabledErr);
    end;

    local procedure GetCommonFields(var FieldRefArray: array[7] of FieldRef)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        RecRef: RecordRef;
        I: Integer;
    begin
        I := 1;
        RecRef.Open(DATABASE::"Incoming Document Attachment");
        IncomingDocumentAttachment.Init();
        AddToArray(FieldRefArray, I, RecRef.Field(IncomingDocumentAttachment.FieldNo("Incoming Document Entry No.")));
        AddToArray(FieldRefArray, I, RecRef.Field(IncomingDocumentAttachment.FieldNo("Line No.")));
        AddToArray(FieldRefArray, I, RecRef.Field(IncomingDocumentAttachment.FieldNo("Created Date-Time")));
        AddToArray(FieldRefArray, I, RecRef.Field(IncomingDocumentAttachment.FieldNo("Created By User Name")));
        AddToArray(FieldRefArray, I, RecRef.Field(IncomingDocumentAttachment.FieldNo(Name)));
        AddToArray(FieldRefArray, I, RecRef.Field(IncomingDocumentAttachment.FieldNo(Type)));
        AddToArray(FieldRefArray, I, RecRef.Field(IncomingDocumentAttachment.FieldNo("File Extension")));
    end;

    local procedure GetIncDocAttachmentOverviewSpecificFields(var FieldRefArray: array[5] of FieldRef)
    var
        IncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview";
        RecRef: RecordRef;
        I: Integer;
    begin
        I := 1;
        RecRef.Open(DATABASE::"Inc. Doc. Attachment Overview");
        IncDocAttachmentOverview.Init();
        AddToArray(FieldRefArray, I, RecRef.Field(IncDocAttachmentOverview.FieldNo("Attachment Type")));
        AddToArray(FieldRefArray, I, RecRef.Field(IncDocAttachmentOverview.FieldNo("Sorting Order")));
        AddToArray(FieldRefArray, I, RecRef.Field(IncDocAttachmentOverview.FieldNo(Indentation)));
        AddToArray(FieldRefArray, I, RecRef.Field(IncDocAttachmentOverview.FieldNo("Posting Date")));
        AddToArray(FieldRefArray, I, RecRef.Field(IncDocAttachmentOverview.FieldNo("Document No.")));
    end;

    local procedure AddToArray(var FieldRefArray: array[17] of FieldRef; var I: Integer; CurrFieldRef: FieldRef)
    begin
        FieldRefArray[I] := CurrFieldRef;
        I += 1;
    end;

    local procedure CreateIncomingDocument(var IncomingDocument: Record "Incoming Document"; AttachmentURL: Text)
    begin
        Clear(IncomingDocument);
        IncomingDocument.Init();
        IncomingDocument.SetURL(AttachmentURL);
        IncomingDocument.Insert(true);
    end;

    local procedure CreateIncomingDocumentAttachment(var IncomingDocument: Record "Incoming Document"; var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    var
        FileManagement: Codeunit "File Management";
        AnyXMLTxt: Text;
    begin
        AnyXMLTxt := '<test><test2 /></test>';
        IncomingDocument.AddXmlAttachmentFromXmlText(IncomingDocumentAttachment, FileManagement.CreateFileNameWithExtension(Format(CreateGuid()), 'XML'), AnyXMLTxt);
    end;

    local procedure CreatePurchaseInvoiceAndPost(var VendLedgEntry: Record "Vendor Ledger Entry"; var IncomingDocument: Record "Incoming Document")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseInvoice(PurchaseHeader, IncomingDocument);

        IncomingDocument.Release();
        VendLedgEntry.SetRange("Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
        VendLedgEntry.SetRange("Document No.", LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        VendLedgEntry.FindFirst();

        VendLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
    end;

    local procedure CreatePurchaseInvoice(var PurchHeader: Record "Purchase Header"; var IncomingDocument: Record "Incoming Document")
    var
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, Vendor."No.");
        PurchHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateRandomText(10));
        PurchHeader.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        PurchHeader."Incoming Document Entry No." := IncomingDocument."Entry No.";
        PurchHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", 1);
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);

        IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Purchase Invoice";
        IncomingDocument."Document No." := PurchHeader."No.";
        IncomingDocument.Modify();
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; var IncomingDocument: Record "Incoming Document")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"Bank Account", '', 0);
        GenJournalLine."Incoming Document Entry No." := IncomingDocument."Entry No.";
        GenJournalLine.Modify();

        IncomingDocument."Document Type" := IncomingDocument."Document Type"::Journal;
        IncomingDocument.Modify(true);
    end;

    local procedure VerifyFieldDefinitionsMatchTableFields(RecRef: RecordRef; FieldRefArray: array[17] of FieldRef)
    var
        FieldRefTemplate: FieldRef;
        FieldRefTable: FieldRef;
        I: Integer;
    begin
        for I := 1 to ArrayLen(FieldRefArray) do begin
            FieldRefTemplate := FieldRefArray[I];
            FieldRefTable := RecRef.Field(FieldRefTemplate.Number);
            ValidateFieldDefinitionsMatch(FieldRefTable, FieldRefTemplate);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifySpecificFieldsNotPresentInMainTable(RecRef: RecordRef; FieldRefArray: array[17] of FieldRef)
    var
        I: Integer;
    begin
        for I := 1 to ArrayLen(FieldRefArray) do
            Assert.IsFalse(
              RecRef.FieldExist(FieldRefArray[I].Number),
              StrSubstNo('Field with ID %1 should not be present in table %2', FieldRefArray[I].Number, RecRef.Number));
    end;

    local procedure ValidateFieldDefinitionsMatch(FieldRef1: FieldRef; FieldRef2: FieldRef)
    begin
        Assert.AreEqual(FieldRef1.Name, FieldRef2.Name, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'names'));
        Assert.AreEqual(FieldRef1.Caption, FieldRef2.Caption, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'captions'));
        Assert.IsTrue(FieldRef1.Type = FieldRef2.Type, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'types'));
        Assert.AreEqual(FieldRef1.Length, FieldRef2.Length, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'lengths'));
        Assert.AreEqual(
          FieldRef1.OptionMembers, FieldRef2.OptionMembers, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'option string'));
        Assert.AreEqual(
          FieldRef1.OptionCaption, FieldRef2.OptionCaption, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'option caption'));
        Assert.AreEqual(FieldRef1.Relation, FieldRef2.Relation, ErrorMessageForFieldComparison(FieldRef1, FieldRef2, 'table relation'));
    end;

    local procedure VerifyLineMatchesIncomingDocumentAttachment(TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary; IncomingDocumentAttachment: Record "Incoming Document Attachment"; SortingOrder: Integer; Indentation: Integer)
    begin
        Assert.AreEqual(TempIncDocAttachmentOverview."Sorting Order", SortingOrder, 'Sorting order was not set correctly');
        Assert.AreEqual(
          TempIncDocAttachmentOverview."Incoming Document Entry No.", IncomingDocumentAttachment."Incoming Document Entry No.",
          'Entry No. Does not match');
        Assert.AreEqual(TempIncDocAttachmentOverview."Line No.", IncomingDocumentAttachment."Line No.", 'Line No. does not match');
        Assert.AreEqual(TempIncDocAttachmentOverview.Name, IncomingDocumentAttachment.Name, 'Name was not set correctly');
        Assert.AreEqual(TempIncDocAttachmentOverview.Type, IncomingDocumentAttachment.Type, 'Type was not set correctly');
        if SortingOrder = 1 then
            Assert.AreEqual(
              TempIncDocAttachmentOverview."Attachment Type", TempIncDocAttachmentOverview."Attachment Type"::"Main Attachment",
              'Attachment Type was not set correctly')
        else
            Assert.AreEqual(
              TempIncDocAttachmentOverview."Attachment Type", TempIncDocAttachmentOverview."Attachment Type"::"Supporting Attachment",
              'Attachment Type was not set correctly');

        Assert.AreEqual(TempIncDocAttachmentOverview.Indentation, Indentation, 'Indentation was not set correctly');
    end;

    local procedure VerifyGroupLine(TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary; IncomingDocument: Record "Incoming Document"; ExpectedSortingOrder: Integer)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        ExpectedGroupCaptionTxt: Text;
    begin
        Assert.AreEqual(TempIncDocAttachmentOverview."Sorting Order", ExpectedSortingOrder, 'Sorting order was not set correctly');
        Assert.AreEqual(
          TempIncDocAttachmentOverview."Incoming Document Entry No.", IncomingDocument."Entry No.", 'Entry No. Does not match');
        Assert.AreEqual(TempIncDocAttachmentOverview."Line No.", 0, 'Line No. does not match');
        ExpectedGroupCaptionTxt := SupportingAttachmentsTxt;
        Assert.AreEqual(TempIncDocAttachmentOverview.Name, ExpectedGroupCaptionTxt, 'Name was not set correctly');
        Assert.AreEqual(TempIncDocAttachmentOverview.Type, IncomingDocumentAttachment.Type::" ", 'Type was not set correctly');
        Assert.AreEqual(
          TempIncDocAttachmentOverview."Attachment Type", TempIncDocAttachmentOverview."Attachment Type"::Group,
          'Attachment Type was not set correctly');
        Assert.AreEqual(TempIncDocAttachmentOverview.Indentation, 0, 'Indentation was not set correctly');
    end;

    local procedure ErrorMessageForFieldComparison(FieldRef1: FieldRef; FieldRef2: FieldRef; MismatchType: Text): Text
    begin
        exit(
          Format(
            'Field ' +
            MismatchType +
            ' on fields ' +
            FieldRef1.Record().Name() + '.' + FieldRef1.Name + ' and ' + FieldRef2.Record().Name() + '.' + FieldRef2.Name + ' do not match.'));
    end;

    local procedure CreatePurchaseReturnOrder(var PurchHeader: Record "Purchase Header"; var IncomingDocument: Record "Incoming Document")
    var
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::"Return Order", Vendor."No.");
        PurchHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateRandomText(10));
        PurchHeader.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        PurchHeader."Incoming Document Entry No." := IncomingDocument."Entry No.";
        PurchHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", LibraryRandom.RandInt(0));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchLine.Modify(true);
    end;

    local procedure FindPurchDocumentArchive(var PurchaseHeaderArchive: Record "Purchase Header Archive"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeaderArchive.FindFirst();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DeleteIncomingDocumentHandler(var IncomingDocumentCard: Page "Incoming Document"; var Response: Action)
    var
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocument.Init();
        IncomingDocumentCard.GetRecord(IncomingDocument);
        IncomingDocument.Delete(true);
        Response := ACTION::OK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JournalTemplateModalHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    var
        TemplateNameVariant: Variant;
        TemplateName: Text;
    begin
        LibraryVariableStorage.Dequeue(TemplateNameVariant);
        TemplateName := TemplateNameVariant;
        GeneralJournalTemplateList.FILTER.SetFilter(Name, TemplateName);
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure IncomingDocumentsPageHandler(var IncomingDocuments: TestPage "Incoming Documents")
    begin
        IncomingDocuments.Filter.SetFilter("Entry No.", Format(LibraryVariableStorage.DequeueInteger()));
        Assert.IsTrue(IncomingDocuments.First(), IncomingDocMustBeFoundErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Just to Handle the Message.
    end;
}

