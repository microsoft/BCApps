codeunit 134400 "ERM Incoming Documents"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Incoming Documents]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryIncomingDocuments: Codeunit "Library - Incoming Documents";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        CannotDeleteDefaultAttachmentErr: Label 'You cannot delete the default attachment.';
        DeleteOtherAttachmentsFirstErr: Label 'You must delete all other attachments before you can delete attachment marked as Default.';
        MainAttachErr: Label 'You must delete all other attachments before you can delete attachment marked as Main Attachment.';
        ReplaceMainAttachmentQst: Label 'Are you sure you want to replace the attached file?';
        DoYouWantToRemoveReferenceQst: Label 'Do you want to remove the reference?';
        DetachQst: Label 'Do you want to remove the reference from this incoming document to posted document %1, posting date %2?', Comment = '%1 Posted Document No. %2 Posting Date';
        RemovePostedRecordManuallyMsg: Label 'The reference to the posted record has been removed.';
        DeleteRecordQst: Label 'The reference to the record has been removed.\\Do you want to delete the record?';
        DocPostedErr: Label 'The document related to this incoming document has been posted.';
        DialogTxt: Label 'Dialog';
        EmptyLinkToRelatedRecordErr: Label 'Link to related record is empty.';
        CannotReplaceMainAttachmentErr: Label 'Cannot replace the main attachment because the document has already been sent to OCR.';
        TotalsMismatchErr: Label 'The invoice cannot be posted because the total is different from the total on the related incoming document.';
        EmailNotSentErr: Label ' The email was not sent to the customer.';
        NoAttachmentsErr: Label 'The email has no attachments.';
        NoOfAttachmentsSameErr: Label 'The number of attachments must be the same.';

    [Test]
    [Scope('OnPrem')]
    procedure SetGetURL()
    var
        IncomingDoc: Record "Incoming Document";
        LocalURL: Text;
    begin
        IncomingDoc.Init();
        Assert.AreEqual('', IncomingDoc.GetURL(), 'Expected empty url.');
        LocalURL := 'abcdefghijklmnopqrstuvxyz1234.txt';
        IncomingDoc.SetURL(LocalURL);
        Assert.AreEqual(LocalURL, IncomingDoc.GetURL(), 'Wrong URL');
        // verify that it works for strings > 250
        while StrLen(LocalURL) <= 250 do
            LocalURL += 'abcdefghijklmnopqrstuvxyz1234.txt';
        IncomingDoc.SetURL(LocalURL);
        Assert.AreEqual(LocalURL, IncomingDoc.GetURL(), 'Wrong URL');
        // verify that it works for strings > 750
        while StrLen(LocalURL) <= 750 do
            LocalURL += 'abcdefghijklmnopqrstuvxyz1234.txt';
        IncomingDoc.SetURL(LocalURL);
        Assert.AreEqual(LocalURL, IncomingDoc.GetURL(), 'Wrong URL');
        // verify that it fails for strings > length of URL field
        while StrLen(LocalURL) <= MaxStrLen(IncomingDoc.URL) do
            LocalURL += 'abcdefghijklmnopqrstuvxyz1234.txt';
        asserterror IncomingDoc.SetURL(LocalURL);
    end;

    [Test]
    [HandlerFunctions('IncomingDocumentCardHandler')]
    [Scope('OnPrem')]
    procedure ShowIncomingDocumentCard()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.TestField(Released, false);
        IncomingDocument.ShowCardFromEntryNo(IncomingDocument."Entry No.");
    end;

    [Test]
    [HandlerFunctions('IncomingDocumentsLookupHandlerPrevRec')]
    [Scope('OnPrem')]
    procedure SelectIncomingDocument()
    var
        IncomingDocument: Record "Incoming Document";
        DummyRecordID: RecordID;
        PrevEntryNo: Integer;
        NewEntryNo: Integer;
    begin
        // Init
        CreateNewIncomingDocument(IncomingDocument);
        PrevEntryNo := IncomingDocument."Entry No.";
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        // Execute
        NewEntryNo := IncomingDocument.SelectIncomingDocument(IncomingDocument."Entry No.", DummyRecordID); // Opens page 190

        // Validate
        Assert.AreEqual(PrevEntryNo, NewEntryNo, '');
    end;

    [Test]
    [HandlerFunctions('IncomingDocumentsLookupHandler')]
    [Scope('OnPrem')]
    procedure SelectIncomingDocumentForPostedDoc()
    var
        IncomingDocument: Record "Incoming Document";
        DummyRecordID: RecordID;
    begin
        // Init
        CreateNewIncomingDocument(IncomingDocument);

        // Execute
        IncomingDocument.SelectIncomingDocumentForPostedDocument('TEST', DMY2Date(1, 1, 2000), DummyRecordID); // Opens page 190

        // Validate
        IncomingDocument.Find();
        Assert.IsTrue(IncomingDocument.Posted, '');
        Assert.AreEqual('TEST', IncomingDocument."Document No.", '');
        Assert.AreEqual(DMY2Date(1, 1, 2000), IncomingDocument."Posting Date", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Release()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.TestField(Released, false);
        IncomingDocument.Release();
        IncomingDocument.TestField(Released, true);
        IncomingDocument.TestField(Status, IncomingDocument.Status::Released);
        IncomingDocument.TestField("Released Date-Time");
        IncomingDocument.TestField("Released By User ID", UserSecurityId());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Reject()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.TestField(Released, false);
        IncomingDocument.Release();
        IncomingDocument.TestField(Released, true);
        IncomingDocument.Reject();
        IncomingDocument.TestField(Released, false);
        IncomingDocument.TestField(Status, IncomingDocument.Status::Rejected);
        IncomingDocument.TestField("Released Date-Time", 0DT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateGenJnlLine()
    var
        IncomingDocument: Record "Incoming Document";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        CreateNewIncomingDocument(IncomingDocument);

        GenJnlLine.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        GenJnlLine.DeleteAll();

        IncomingDocument.Release();
        IncomingDocument.Modify();
        CreateAndAssignGenJournalLineToIncomingDocument(IncomingDocument);
        IncomingDocument.Modify();
        IncomingDocument.TestField("Document Type", IncomingDocument."Document Type"::Journal);

        GenJnlLine.FindFirst();
        Assert.IsTrue(GenJnlLine.HasLinks, 'Gen. Jnl. Line is missing a link.');
        Assert.AreEqual(GenJnlLine.GetIncomingDocumentURL(), IncomingDocument.GetURL(), 'Gen. Jnl. Line has a wrong URL.');
        GenJnlLine."Document No." := LibraryUtility.GenerateGUID();
        GenJnlLine."Posting Date" := WorkDate();
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
        GenJnlLine.Validate("Account No.", GetIncomeStatementAcc());
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", GetBalanceSheetAcc());
        GenJnlLine.Validate(Amount, 1);
        GenJnlLine.Modify();
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJnlLine);
        ValidatePostedIncomingDocument(IncomingDocument);
    end;

    [Test]
    [HandlerFunctions('PurchInvHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchInvoice()
    var
        IncomingDocument: Record "Incoming Document";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        PurchaseHeader.SetFilter("Incoming Document Entry No.", '<>0');
        PurchaseHeader.DeleteAll();

        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.Release();
        IncomingDocument.Modify();
        IncomingDocument.CreatePurchInvoice();  // Opens page 51 "Purchase Invoice"
        IncomingDocument.Modify();
        IncomingDocument.TestField("Document Type", IncomingDocument."Document Type"::"Purchase Invoice");

        PurchaseHeader.FindFirst();
        PurchaseHeader.TestField("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.TestField("Incoming Document Entry No.", IncomingDocument."Entry No.");
        Assert.IsTrue(PurchaseHeader.HasLinks, 'Purchase Invoice is missing a link.');

        LibraryPurchase.CreateVendor(Vendor);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader."Vendor Invoice No." := PurchaseHeader."No.";
        PurchaseHeader.Modify();

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GetIncomeStatementAcc(), 1);

        CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchaseHeader);
        ValidatePostedIncomingDocument(IncomingDocument);
    end;

    [Test]
    [HandlerFunctions('IncomingDocumentsLookupHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchInvoiceAndSelectIncomingDoc()
    var
        IncomingDocument: Record "Incoming Document";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // Init
        PurchaseHeader.SetFilter("Incoming Document Entry No.", '<>0');
        PurchaseHeader.DeleteAll();
        PurchaseHeader.Reset();
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.Release();
        IncomingDocument.Modify();

        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader."Vendor Invoice No." := PurchaseHeader."No.";
        PurchaseHeader.Modify();

        // Execute
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        Assert.IsFalse(PurchaseInvoice.IncomingDocCard.Enabled(), '');
        Assert.IsFalse(PurchaseInvoice.RemoveIncomingDoc.Enabled(), '');
        Assert.IsTrue(PurchaseInvoice.SelectIncomingDoc.Enabled(), '');
        Assert.IsTrue(PurchaseInvoice.IncomingDocAttachFile.Enabled(), '');

        PurchaseInvoice.SelectIncomingDoc.Invoke(); // Opens page 190

        // Verify
        Assert.IsTrue(PurchaseInvoice.IncomingDocCard.Enabled(), '');
        Assert.IsTrue(PurchaseInvoice.RemoveIncomingDoc.Enabled(), '');
        Assert.IsTrue(PurchaseInvoice.SelectIncomingDoc.Enabled(), '');
        Assert.IsFalse(PurchaseInvoice.IncomingDocAttachFile.Enabled(), '');

        PurchaseHeader.Find();
        Assert.AreEqual(IncomingDocument."Entry No.", PurchaseHeader."Incoming Document Entry No.", '');

        PurchaseInvoice.RemoveIncomingDoc.Invoke();
        PurchaseHeader.Find();
        Assert.AreEqual(0, PurchaseHeader."Incoming Document Entry No.", '');

        PurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('IncomingDocumentsLookupHandler')]
    [Scope('OnPrem')]
    procedure CreateAndDeletePurchInvoiceAndSelectIncomingDoc()
    var
        IncomingDocument: Record "Incoming Document";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        ErrorMessage: Record "Error Message";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // Init
        PurchaseHeader.SetFilter("Incoming Document Entry No.", '<>0');
        PurchaseHeader.DeleteAll();
        PurchaseHeader.Reset();
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.Release();
        IncomingDocument.Modify();

        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader."Vendor Invoice No." := PurchaseHeader."No.";
        PurchaseHeader.Modify();

        // Execute
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        PurchaseInvoice.SelectIncomingDoc.Invoke(); // Opens page 190
        PurchaseInvoice.Close();
        PurchaseHeader.Find();
        Assert.AreEqual(IncomingDocument."Entry No.", PurchaseHeader."Incoming Document Entry No.", '');
        PurchaseHeader.Delete(true);

        // Verify
        IncomingDocument.Find();
        Assert.AreEqual('', IncomingDocument."Document No.", '');
        Assert.AreEqual(IncomingDocument."Document Type"::" ", IncomingDocument."Document Type", '');
        Assert.AreEqual(IncomingDocument.Status::Released, IncomingDocument.Status, '');
        ErrorMessage.SetContext(IncomingDocument);
        Assert.AreEqual(0, ErrorMessage.ErrorMessageCount(
            ErrorMessage."Message Type"::Error), 'No errors should have been found.');
    end;

    [Test]
    [HandlerFunctions('PurchCrMemoHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchCreditMemo()
    var
        IncomingDocument: Record "Incoming Document";
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetFilter("Incoming Document Entry No.", '<>0');
        PurchaseHeader.DeleteAll();

        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.Release();
        Commit();
        IncomingDocument.CreatePurchCreditMemo();  // Opens page 52 "Purchase Credit Memo"
        IncomingDocument.Modify();
        IncomingDocument.TestField("Document Type", IncomingDocument."Document Type"::"Purchase Credit Memo");

        PurchaseHeader.FindFirst();
        PurchaseHeader.TestField("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.TestField("Incoming Document Entry No.", IncomingDocument."Entry No.");
        Assert.IsTrue(PurchaseHeader.HasLinks, 'Purchase Credit Memo is missing a link.');
    end;

    [Test]
    [HandlerFunctions('SalesInvHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        IncomingDocument: Record "Incoming Document";
    begin
        SalesHeader.SetFilter("Incoming Document Entry No.", '<>0');
        SalesHeader.DeleteAll();

        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.Release();
        IncomingDocument.Modify();
        IncomingDocument.CreateSalesInvoice();  // Opens page 43 "Sales Invoice"
        IncomingDocument.Modify();
        IncomingDocument.TestField("Document Type", IncomingDocument."Document Type"::"Sales Invoice");

        SalesHeader.FindFirst();
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.TestField("Incoming Document Entry No.", IncomingDocument."Entry No.");
        Assert.IsTrue(SalesHeader.HasLinks, 'Sales Invoice is missing a link.');

        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader.Modify();

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GetIncomeStatementAcc(), 1);

        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);
        ValidatePostedIncomingDocument(IncomingDocument);
    end;

    [Test]
    [HandlerFunctions('IncomingDocumentsLookupHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceAndSelectIncomingDoc()
    var
        IncomingDocument: Record "Incoming Document";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Init
        SalesHeader.SetFilter("Incoming Document Entry No.", '<>0');
        SalesHeader.DeleteAll();
        SalesHeader.Reset();
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.Release();
        IncomingDocument.Modify();

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Modify();

        // Execute
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        Assert.IsFalse(SalesInvoice.IncomingDocCard.Enabled(), '');
        Assert.IsFalse(SalesInvoice.RemoveIncomingDoc.Enabled(), '');
        Assert.IsTrue(SalesInvoice.SelectIncomingDoc.Enabled(), '');
        Assert.IsTrue(SalesInvoice.IncomingDocAttachFile.Enabled(), '');

        SalesInvoice.SelectIncomingDoc.Invoke(); // Opens page 190

        // Verify
        Assert.IsTrue(SalesInvoice.IncomingDocCard.Enabled(), '');
        Assert.IsTrue(SalesInvoice.RemoveIncomingDoc.Enabled(), '');
        Assert.IsTrue(SalesInvoice.SelectIncomingDoc.Enabled(), '');
        Assert.IsFalse(SalesInvoice.IncomingDocAttachFile.Enabled(), '');

        SalesHeader.Find();
        Assert.AreEqual(IncomingDocument."Entry No.", SalesHeader."Incoming Document Entry No.", '');

        SalesInvoice.RemoveIncomingDoc.Invoke();
        SalesHeader.Find();
        Assert.AreEqual(0, SalesHeader."Incoming Document Entry No.", '');

        SalesInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('SalesCrMemoHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        IncomingDocument: Record "Incoming Document";
    begin
        SalesHeader.SetFilter("Incoming Document Entry No.", '<>0');
        SalesHeader.DeleteAll();

        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.Release();
        Commit();
        IncomingDocument.CreateSalesCreditMemo();  // Opens page 44 "Sales Credit Memo"
        IncomingDocument.Modify();
        IncomingDocument.TestField("Document Type", IncomingDocument."Document Type"::"Sales Credit Memo");

        SalesHeader.FindFirst();
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.TestField("Incoming Document Entry No.", IncomingDocument."Entry No.");
        Assert.IsTrue(SalesHeader.HasLinks, 'Sales Credit Memo is missing a link.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReadyForPosting()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.Release();
        IncomingDocument.Modify();
        IncomingDocument.TestReadyForProcessing();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnDelete()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        // Init
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocumentAttachment."Incoming Document Entry No." := IncomingDocument."Entry No.";
        IncomingDocumentAttachment."Line No." := 10000;
        IncomingDocumentAttachment.Insert(true);
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");

        // Execute
        IncomingDocument.Delete(true);

        // Verify;
        Assert.AreEqual(0, IncomingDocumentAttachment.Count, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangeOfDocType1()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.Release();
        IncomingDocument.Modify();
        CreateAndAssignGenJournalLineToIncomingDocument(IncomingDocument);
        asserterror IncomingDocument.CreatePurchInvoice();
    end;

    [Test]
    [HandlerFunctions('PurchInvHandler')]
    [Scope('OnPrem')]
    procedure TestChangeOfDocType2()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.Release();
        IncomingDocument.Modify();
        IncomingDocument.CreatePurchInvoice();
        asserterror IncomingDocument.CreateGenJnlLine();
        asserterror IncomingDocument.CreatePurchCreditMemo();
        asserterror IncomingDocument.CreateSalesInvoice();
        asserterror IncomingDocument.CreateSalesCreditMemo();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetGenJournalLine()
    var
        IncomingDocument: Record "Incoming Document";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.Release();
        IncomingDocument.Modify();
        GenJnlLine.Init();
        GenJnlLine."Incoming Document Entry No." := IncomingDocument."Entry No.";
        IncomingDocument.SetGenJournalLine(GenJnlLine);
        IncomingDocument.TestField("Document Type", IncomingDocument."Document Type"::Journal);
        Assert.IsTrue(GenJnlLine.HasLinks, 'No link was attached to Gen. Jnl. Line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetPurchDoc()
    var
        IncomingDocument: Record "Incoming Document";
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.Release();
        IncomingDocument.Modify();
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
        PurchaseHeader."Incoming Document Entry No." := IncomingDocument."Entry No.";
        IncomingDocument.SetPurchDoc(PurchaseHeader);
        IncomingDocument.TestField("Document Type", IncomingDocument."Document Type"::"Purchase Invoice");
        Assert.IsTrue(PurchaseHeader.HasLinks, 'No link was attached to Purchase Header');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetSalesDoc()
    var
        IncomingDocument: Record "Incoming Document";
        SalesHeader: Record "Sales Header";
    begin
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.Release();
        IncomingDocument.Modify();
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."Incoming Document Entry No." := IncomingDocument."Entry No.";
        IncomingDocument.SetSalesDoc(SalesHeader);
        IncomingDocument.TestField("Document Type", IncomingDocument."Document Type"::"Sales Invoice");
        Assert.IsTrue(SalesHeader.HasLinks, 'No link was attached to Sales Header');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetPostedDocFields()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376596] TAB 130 "Incoming Document".SetPostedDocFields() updates Incoming Document fields correctly in case of Status=New
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.TestField("Posted Date-Time", 0DT);
        IncomingDocument.SetPostedDocFields(Today, '1111');
        IncomingDocument.TestField(Posted, true);
        IncomingDocument.TestField("Posted Date-Time");
        IncomingDocument.TestField("Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetPostedDocFieldsForcePosted_Positive()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376596] TAB 130 "Incoming Document".SetPostedDocFields() updates Incoming Document fields correctly in case of Status=Posted and ForcePosted=TRUE
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.UpdateIncomingDocumentFromPosting(IncomingDocument."Entry No.", DMY2Date(1, 1, 2015), 'TEST');

        IncomingDocument.Find();
        IncomingDocument.SetPostedDocFieldsForcePosted(DMY2Date(1, 1, 2015), 'TEST', true);

        IncomingDocument.TestField(Posted, true);
        IncomingDocument.TestField(Processed, true);
        IncomingDocument.TestField("Posted Date-Time");
        IncomingDocument.TestField("Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetPostedDocFieldsForcePosted_Negative()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376596] TAB 130 "Incoming Document".SetPostedDocFields() throws an error 'The document related to this incoming document has been posted.' in case of Status=Posted and ForcePosted=FALSE
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.UpdateIncomingDocumentFromPosting(IncomingDocument."Entry No.", DMY2Date(1, 1, 2015), 'TEST');

        IncomingDocument.Find();
        asserterror IncomingDocument.SetPostedDocFieldsForcePosted(DMY2Date(1, 1, 2015), 'TEST', false);
        Assert.ExpectedErrorCode(DialogTxt);
        Assert.ExpectedError(DocPostedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePostGenJnlLineNotApproved()
    var
        IncomingDocument: Record "Incoming Document";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LibraryIncomingDocuments.InitIncomingDocuments();
        UpdateIncomingDocumentsSetup();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        GenJnlLine.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        GenJnlLine.DeleteAll();

        CreateAndAssignGenJournalLineToIncomingDocument(IncomingDocument);

        GenJnlLine.FindFirst();
        GenJnlLine."Document No." := LibraryUtility.GenerateGUID();
        GenJnlLine.Modify();
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJnlLine);
        ValidatePostedIncomingDocument(IncomingDocument);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearRelatedGenJnlLine()
    var
        IncomingDocument: Record "Incoming Document";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup.
        LibraryIncomingDocuments.InitIncomingDocuments();
        UpdateIncomingDocumentsSetup();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        CreateAndAssignGenJournalLineToIncomingDocument(IncomingDocument);

        // Pre-Exercise Verify.
        GenJournalLine.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        Assert.IsTrue(GenJournalLine.FindFirst(), 'There should be a new record connected to the incoming document.');

        // Exercise.
        IncomingDocument.Delete(true);

        // Verify.
        GenJournalLine.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        Assert.IsTrue(GenJournalLine.IsEmpty, 'There should not be any records connected to the incoming document.');
    end;

    [Test]
    [HandlerFunctions('PurchInvHandler')]
    [Scope('OnPrem')]
    procedure ClearRelatedPurchaseInvoice()
    var
        IncomingDocument: Record "Incoming Document";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup.
        LibraryIncomingDocuments.InitIncomingDocuments();
        UpdateIncomingDocumentsSetup();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.CreatePurchInvoice();
        IncomingDocument.Modify();

        // Pre-Exercise Verify.
        PurchaseHeader.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        Assert.IsTrue(PurchaseHeader.FindFirst(), 'There should be a new record connected to the incoming document.');

        // Exercise.
        IncomingDocument.Delete(true);

        // Verify.
        PurchaseHeader.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        Assert.IsTrue(PurchaseHeader.IsEmpty, 'There should not be any records connected to the incoming document.');
    end;

    [Test]
    [HandlerFunctions('PurchCrMemoHandler')]
    [Scope('OnPrem')]
    procedure ClearRelatedPurchaseCrMemo()
    var
        IncomingDocument: Record "Incoming Document";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup.
        LibraryIncomingDocuments.InitIncomingDocuments();
        UpdateIncomingDocumentsSetup();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.CreatePurchCreditMemo();
        IncomingDocument.Modify();

        // Pre-Exercise Verify.
        PurchaseHeader.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        Assert.IsTrue(PurchaseHeader.FindFirst(), 'There should be a new record connected to the incoming document.');

        // Exercise.
        IncomingDocument.Delete(true);

        // Verify.
        PurchaseHeader.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        Assert.IsTrue(PurchaseHeader.IsEmpty, 'There should not be any records connected to the incoming document.');
    end;

    [Test]
    [HandlerFunctions('SalesInvHandler')]
    [Scope('OnPrem')]
    procedure ClearRelatedSalesInvoice()
    var
        IncomingDocument: Record "Incoming Document";
        SalesHeader: Record "Sales Header";
    begin
        // Setup.
        LibraryIncomingDocuments.InitIncomingDocuments();
        UpdateIncomingDocumentsSetup();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.CreateSalesInvoice();
        IncomingDocument.Modify();

        // Pre-Exercise Verify.
        SalesHeader.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        Assert.IsTrue(SalesHeader.FindFirst(), 'There should be a new record connected to the incoming document.');

        // Exercise.
        IncomingDocument.Delete(true);

        // Verify.
        SalesHeader.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        Assert.IsTrue(SalesHeader.IsEmpty, 'There should not be any records connected to the incoming document.');
    end;

    [Test]
    [HandlerFunctions('SalesCrMemoHandler')]
    [Scope('OnPrem')]
    procedure ClearRelatedSalesCrMemo()
    var
        IncomingDocument: Record "Incoming Document";
        SalesHeader: Record "Sales Header";
    begin
        // Setup.
        LibraryIncomingDocuments.InitIncomingDocuments();
        UpdateIncomingDocumentsSetup();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.CreateSalesCreditMemo();
        IncomingDocument.Modify();

        // Pre-Exercise Verify.
        SalesHeader.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        Assert.IsTrue(SalesHeader.FindFirst(), 'There should be a new record connected to the incoming document.');

        // Exercise.
        IncomingDocument.Delete(true);

        // Verify.
        SalesHeader.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        Assert.IsTrue(SalesHeader.IsEmpty, 'There should not be any records connected to the incoming document.');
    end;

    local procedure CreateIncomingDocumentWithoutAttachments(var IncomingDocument: Record "Incoming Document")
    begin
        if IncomingDocument.FindLast() then;
        IncomingDocument.Init();
        IncomingDocument."Entry No." += 1;
        IncomingDocument.Insert();
    end;

    local procedure CreateIncomingDocumentWithMainAttachment(var IncomingDocument: Record "Incoming Document"; var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    var
        FileName: Text;
    begin
        CreateIncomingDocumentWithoutAttachments(IncomingDocument);

        FileName := CreateDummyFile('xml');
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        ImportAttachToIncomingDoc(IncomingDocumentAttachment, FileName);
        IncomingDocumentAttachment.Get(IncomingDocumentAttachment."Incoming Document Entry No.", IncomingDocumentAttachment."Line No.");
    end;

    local procedure CreateIncomingDocumentWithPDFAttachment(var IncomingDocument: Record "Incoming Document"; var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    var
        FileName: Text;
    begin
        CreateIncomingDocumentWithoutAttachments(IncomingDocument);

        FileName := CreateDummyFile('pdf');
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        ImportAttachToIncomingDoc(IncomingDocumentAttachment, FileName);
        IncomingDocumentAttachment.Get(IncomingDocumentAttachment."Incoming Document Entry No.", IncomingDocumentAttachment."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertTableAttachment()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        // Init();
        if IncomingDocumentAttachment.Get(0, 0) then
            IncomingDocumentAttachment.Delete();
        IncomingDocumentAttachment.Init();
        // Execute
        IncomingDocumentAttachment."Incoming Document Entry No." := 1;
        IncomingDocumentAttachment.Insert(true);
        // Verify
        Assert.AreNotEqual(Format(0DT), Format(IncomingDocumentAttachment."Created Date-Time"), '');
        Assert.AreNotEqual('', IncomingDocumentAttachment."Created By User Name", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportAttachment()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        IncomingDocumentAttachment.Init(); // to satisfy preCAL

        ImportAndVerifyAttachment('jpg', IncomingDocumentAttachment.Type::Image);
        ImportAndVerifyAttachment('bmp', IncomingDocumentAttachment.Type::Image);
        ImportAndVerifyAttachment('png', IncomingDocumentAttachment.Type::Image);
        ImportAndVerifyAttachment('pdf', IncomingDocumentAttachment.Type::PDF);
        ImportAndVerifyAttachment('xlsx', IncomingDocumentAttachment.Type::Excel);
        ImportAndVerifyAttachment('docx', IncomingDocumentAttachment.Type::Word);
        ImportAndVerifyAttachment('pptx', IncomingDocumentAttachment.Type::PowerPoint);
        ImportAndVerifyAttachment('msg', IncomingDocumentAttachment.Type::Email);
        ImportAndVerifyAttachment('xml', IncomingDocumentAttachment.Type::XML);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportAttachment()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileManagement: Codeunit "File Management";
        OutStr: OutStream;
        FileName: Text;
    begin
        // Init
        IncomingDocumentAttachment.Init();
        FileName := IncomingDocumentAttachment.Export('', false);   // Returns as entry no. is 0

        if IncomingDocumentAttachment.FindLast() then;
        IncomingDocumentAttachment."Incoming Document Entry No." += 1;
        IncomingDocumentAttachment."Line No." := 10000;
        IncomingDocumentAttachment.Init();
        FileName := IncomingDocumentAttachment.Export('', false);   // Returns as there is no content

        if not IncomingDocumentAttachment.Find() then
            IncomingDocumentAttachment.Insert(true);
        IncomingDocumentAttachment.Content.CreateOutStream(OutStr, TEXTENCODING::UTF8);
        OutStr.WriteText('<hello world/>');
        IncomingDocumentAttachment.Type := IncomingDocumentAttachment.Type::XML;
        IncomingDocumentAttachment."File Extension" := 'xml';
        IncomingDocumentAttachment.Modify();

        // Execute
        FileName := FileManagement.ServerTempFileName(IncomingDocumentAttachment."File Extension");
        FileName := IncomingDocumentAttachment.Export(FileName, false);

        // Verify

        // File.OPEN(FileName);
        // File.TEXTMODE(TRUE);
        // File.READ(Text);
        // File.Close();
        // FileManagement.DeleteServerFile(FileName); Fails in snap
        // Assert.AreEqual('<hello world/>',Text,'');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddAttachmentToExistingEntry()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        GLEntry: Record "G/L Entry";
        IncomingDocumentCard: TestPage "Incoming Document";
        FileName: Text;
    begin
        // Init
        GLEntry.FindLast();
        GLEntry.TestField("Posting Date");
        GLEntry.TestField("Document No.");

        IncomingDocument.SetRange("Document No.", GLEntry."Document No.");
        IncomingDocument.SetRange("Posting Date", GLEntry."Posting Date");
        IncomingDocumentAttachment.SetRange("Document No.", GLEntry."Document No.");
        IncomingDocumentAttachment.SetRange("Posting Date", GLEntry."Posting Date");
        IncomingDocument.DeleteAll();
        IncomingDocumentAttachment.DeleteAll();

        // Execution
        FileName := CreateDummyFile('xml');
        ImportAttachToIncomingDoc(IncomingDocumentAttachment, FileName);

        // Verify
        IncomingDocument.FindFirst();
        IncomingDocument.TestField(Description);
        IncomingDocument.TestField(Released);
        IncomingDocument.TestField(Posted);
        IncomingDocument.TestField("Document No.", GLEntry."Document No.");
        IncomingDocument.TestField("Posting Date", GLEntry."Posting Date");
        IncomingDocument.TestField("Related Record ID");

        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        Assert.AreNotEqual(IncomingDocumentCard.Record.Value, '', EmptyLinkToRelatedRecordErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddAttachmentToExistingSalesDoc()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        SalesHeader: Record "Sales Header";
        EnumAssignmentMgt: Codeunit "Enum Assignment Management";
        IncomingDocumentCard: TestPage "Incoming Document";
        FileName: Text;
    begin
        // Init
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader.Insert(true);

        IncomingDocumentAttachment.FilterGroup(4);
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", 0);
        IncomingDocumentAttachment.SetRange("Document Table No. Filter", DATABASE::"Sales Header");
        IncomingDocumentAttachment.SetRange("Document Type Filter", EnumAssignmentMgt.GetSalesIncomingDocumentType(SalesHeader."Document Type"));
        IncomingDocumentAttachment.SetRange("Document No. Filter", SalesHeader."No.");
        IncomingDocumentAttachment.FilterGroup(0);

        // Execution
        FileName := CreateDummyFile('xml');
        ImportAttachToIncomingDoc(IncomingDocumentAttachment, FileName);

        // Verify
        Assert.IsTrue(IncomingDocumentAttachment."Incoming Document Entry No." > 0, '');
        SalesHeader.Find();
        Assert.AreEqual(IncomingDocumentAttachment."Incoming Document Entry No.", SalesHeader."Incoming Document Entry No.", '');
        IncomingDocument.Get(SalesHeader."Incoming Document Entry No.");
        IncomingDocument.TestField(Description);
        IncomingDocument.TestField(Released);
        IncomingDocument.TestField(Posted, false);
        IncomingDocument.TestField("Document No.", '');
        IncomingDocument.TestField("Posting Date", 0D);
        IncomingDocument.TestField("Related Record ID", SalesHeader.RecordId);

        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        Assert.AreNotEqual(IncomingDocumentCard.Record.Value, '', EmptyLinkToRelatedRecordErr);
        IncomingDocumentCard.Record.AssertEquals(IncomingDocument.GetRecordLinkText());
    end;

    [Test]
    procedure TestIncomingDocumentPropagatedToArchivedSalesDoc()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        EnumAssignmentMgt: Codeunit "Enum Assignment Management";
        ArchiveManagement: Codeunit ArchiveManagement;
        IncomingDocumentCard: TestPage "Incoming Document";
        FileName: Text;
    begin
        // [GIVEN] Sales Order exists      
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader.Insert(true);

        // [GIVEN] Incoming Document Attachment exists   
        IncomingDocumentAttachment.FilterGroup(4);
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", 0);
        IncomingDocumentAttachment.SetRange("Document Table No. Filter", Database::"Sales Header");
        IncomingDocumentAttachment.SetRange("Document Type Filter", EnumAssignmentMgt.GetSalesIncomingDocumentType(SalesHeader."Document Type"));
        IncomingDocumentAttachment.SetRange("Document No. Filter", SalesHeader."No.");
        IncomingDocumentAttachment.FilterGroup(0);

        // [GIVEN] The document is attached to Sales document incoming document        
        FileName := CreateDummyFile('xml');
        ImportAttachToIncomingDoc(IncomingDocumentAttachment, FileName);
        SalesHeader.Find();

        // [WHEN] The Sales document is archived
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.FindLast();

        // [THEN] The incoming document is linked to archived document
        IncomingDocumentAttachment.TestField("Incoming Document Entry No.");
        Assert.AreEqual(IncomingDocumentAttachment."Incoming Document Entry No.", SalesHeaderArchive."Incoming Document Entry No.", 'Incoming Document Entry No. are not correct.');
        IncomingDocument.Get(SalesHeaderArchive."Incoming Document Entry No.");

        // [THEN] The attachment exists
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        Assert.AreNotEqual(IncomingDocumentCard.Record.Value, '', EmptyLinkToRelatedRecordErr);
        IncomingDocumentCard.Record.AssertEquals(IncomingDocument.GetRecordLinkText());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddAttachmentToExistingPurchDoc()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        PurchaseHeader: Record "Purchase Header";
        EnumAssignmentMgt: Codeunit "Enum Assignment Management";
        IncomingDocumentCard: TestPage "Incoming Document";
        FileName: Text;
    begin
        // Init
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader.Insert(true);

        IncomingDocumentAttachment.FilterGroup(4);
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", 0);
        IncomingDocumentAttachment.SetRange("Document Table No. Filter", DATABASE::"Purchase Header");
        IncomingDocumentAttachment.SetRange("Document Type Filter", EnumAssignmentMgt.GetPurchIncomingDocumentType(PurchaseHeader."Document Type"));
        IncomingDocumentAttachment.SetRange("Document No. Filter", PurchaseHeader."No.");
        IncomingDocumentAttachment.FilterGroup(0);

        // Execution
        FileName := CreateDummyFile('xml');
        ImportAttachToIncomingDoc(IncomingDocumentAttachment, FileName);

        // Verify
        Assert.IsTrue(IncomingDocumentAttachment."Incoming Document Entry No." > 0, '');
        PurchaseHeader.Find();
        Assert.AreEqual(IncomingDocumentAttachment."Incoming Document Entry No.", PurchaseHeader."Incoming Document Entry No.", '');
        IncomingDocument.Get(PurchaseHeader."Incoming Document Entry No.");
        IncomingDocument.TestField(Description);
        IncomingDocument.TestField(Released);
        IncomingDocument.TestField(Posted, false);
        IncomingDocument.TestField("Document No.", '');
        IncomingDocument.TestField("Posting Date", 0D);
        IncomingDocument.TestField("Related Record ID", PurchaseHeader.RecordId);

        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        Assert.AreNotEqual(IncomingDocumentCard.Record.Value, '', EmptyLinkToRelatedRecordErr);
        IncomingDocumentCard.Record.AssertEquals(IncomingDocument.GetRecordLinkText());
    end;

    [Test]
    procedure TestIncomingDocumentPropagatedToArchivedPurchaseDoc()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        EnumAssignmentMgt: Codeunit "Enum Assignment Management";
        ArchiveManagement: Codeunit ArchiveManagement;
        IncomingDocumentCard: TestPage "Incoming Document";
        FileName: Text;
    begin
        // [GIVEN] Purchase Order exists      
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader.Insert(true);

        // [GIVEN] Incoming Document Attachment exists   
        IncomingDocumentAttachment.FilterGroup(4);
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", 0);
        IncomingDocumentAttachment.SetRange("Document Table No. Filter", Database::"Purchase Header");
        IncomingDocumentAttachment.SetRange("Document Type Filter", EnumAssignmentMgt.GetPurchIncomingDocumentType(PurchaseHeader."Document Type"));
        IncomingDocumentAttachment.SetRange("Document No. Filter", PurchaseHeader."No.");
        IncomingDocumentAttachment.FilterGroup(0);

        // [GIVEN] The document is attached to purchase document incoming document        
        FileName := CreateDummyFile('xml');
        ImportAttachToIncomingDoc(IncomingDocumentAttachment, FileName);
        PurchaseHeader.Find();

        // [WHEN] The purchase document is archived
        ArchiveManagement.StorePurchDocument(PurchaseHeader, false);
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeaderArchive.FindLast();

        // [THEN] The incoming document is linked to archived document
        IncomingDocumentAttachment.TestField("Incoming Document Entry No.");
        Assert.AreEqual(IncomingDocumentAttachment."Incoming Document Entry No.", PurchaseHeaderArchive."Incoming Document Entry No.", 'Incoming Document Entry No. are not correct.');
        IncomingDocument.Get(PurchaseHeaderArchive."Incoming Document Entry No.");

        // [THEN] The attachment exists
        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        Assert.AreNotEqual(IncomingDocumentCard.Record.Value, '', EmptyLinkToRelatedRecordErr);
        IncomingDocumentCard.Record.AssertEquals(IncomingDocument.GetRecordLinkText());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddAttachmentToExistingGenJnlLine()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        IncomingDocumentCard: TestPage "Incoming Document";
        FileName: Text;
    begin
        // Init
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalLine."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        if GenJournalLine.FindLast() then;
        GenJournalLine."Line No." += 10000;
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Invoice;
        GenJournalLine.Insert(true);

        IncomingDocumentAttachment.FilterGroup(4);
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", 0);
        IncomingDocumentAttachment.SetRange("Journal Template Name Filter", GenJournalLine."Journal Template Name");
        IncomingDocumentAttachment.SetRange("Journal Batch Name Filter", GenJournalLine."Journal Batch Name");
        IncomingDocumentAttachment.SetRange("Journal Line No. Filter", GenJournalLine."Line No.");
        IncomingDocumentAttachment.FilterGroup(0);

        // Execution
        FileName := CreateDummyFile('xml');
        ImportAttachToIncomingDoc(IncomingDocumentAttachment, FileName);

        // Verify
        Assert.IsTrue(IncomingDocumentAttachment."Incoming Document Entry No." > 0, '');
        GenJournalLine.Find();
        Assert.AreEqual(IncomingDocumentAttachment."Incoming Document Entry No.", GenJournalLine."Incoming Document Entry No.", '');
        IncomingDocument.Get(GenJournalLine."Incoming Document Entry No.");
        IncomingDocument.TestField(Description);
        IncomingDocument.TestField(Released);
        IncomingDocument.TestField(Posted, false);
        IncomingDocument.TestField("Document No.", '');
        IncomingDocument.TestField("Posting Date", 0D);
        IncomingDocument.TestField("Related Record ID", GenJournalLine.RecordId);

        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);
        Assert.AreNotEqual(IncomingDocumentCard.Record.Value, '', EmptyLinkToRelatedRecordErr);
        IncomingDocumentCard.Record.AssertEquals(IncomingDocument.GetRecordLinkText());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMainAttachmentIsSetForFirstAttachment()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        // Init
        CreateIncomingDocumentWithMainAttachment(IncomingDocument, IncomingDocumentAttachment);

        // Verify
        Assert.AreEqual(IncomingDocumentAttachment."Main Attachment", true, 'Main Attachment should be set on the main document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMainAttachmentIsNotSetForSecondAttachment()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocumentAttachment2: Record "Incoming Document Attachment";
        FileName2: Text;
    begin
        // Init
        CreateIncomingDocumentWithMainAttachment(IncomingDocument, IncomingDocumentAttachment);

        // Execution
        FileName2 := CreateDummyFile('xml');
        IncomingDocumentAttachment2.SetRange("Incoming Document Entry No.", IncomingDocumentAttachment."Incoming Document Entry No.");
        ImportAttachToIncomingDoc(IncomingDocumentAttachment2, FileName2);
        IncomingDocumentAttachment2.Get(
          IncomingDocumentAttachment2."Incoming Document Entry No.", IncomingDocumentAttachment2."Line No.");

        // Verify
        Assert.AreEqual(IncomingDocumentAttachment."Main Attachment", true, 'Main Attachment should be set on the main document');
        Assert.AreEqual(IncomingDocumentAttachment2."Main Attachment", false, 'Main Attachment should not be set on the second document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotDeleteMainAttachment()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocumentAttachment2: Record "Incoming Document Attachment";
        FileName2: Text;
    begin
        // Init
        CreateIncomingDocumentWithMainAttachment(IncomingDocument, IncomingDocumentAttachment);
        IncomingDocumentAttachment.Default := false;
        IncomingDocumentAttachment.Modify();

        // Execution
        FileName2 := CreateDummyFile('xml');
        IncomingDocumentAttachment2.SetRange("Incoming Document Entry No.", IncomingDocumentAttachment."Incoming Document Entry No.");
        ImportAttachToIncomingDoc(IncomingDocumentAttachment2, FileName2);
        IncomingDocumentAttachment2.Get(
          IncomingDocumentAttachment2."Incoming Document Entry No.", IncomingDocumentAttachment2."Line No.");
        IncomingDocumentAttachment2.Default := true;
        IncomingDocumentAttachment2.Modify();

        // Verify
        asserterror IncomingDocumentAttachment.Delete(true);
        Assert.ExpectedError(MainAttachErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingDefaultAttachmentDoesntReplaceMainAttachment()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocumentAttachment2: Record "Incoming Document Attachment";
        MainIncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileName2: Text;
    begin
        // Init
        CreateIncomingDocumentWithMainAttachment(IncomingDocument, IncomingDocumentAttachment);
        IncomingDocumentAttachment.Default := false;
        IncomingDocumentAttachment.Modify();

        FileName2 := CreateDummyFile('xml');
        IncomingDocumentAttachment2.SetRange("Incoming Document Entry No.", IncomingDocumentAttachment."Incoming Document Entry No.");
        ImportAttachToIncomingDoc(IncomingDocumentAttachment2, FileName2);
        IncomingDocumentAttachment2.Get(
          IncomingDocumentAttachment2."Incoming Document Entry No.", IncomingDocumentAttachment2."Line No.");

        // Execute
        IncomingDocumentAttachment2.Validate(Default, true);
        IncomingDocumentAttachment2.Modify();

        // Verify
        IncomingDocumentAttachment.Get(IncomingDocumentAttachment."Incoming Document Entry No.", IncomingDocumentAttachment."Line No.");
        IncomingDocumentAttachment2.Get(
          IncomingDocumentAttachment2."Incoming Document Entry No.", IncomingDocumentAttachment2."Line No.");
        IncomingDocument.GetMainAttachment(MainIncomingDocumentAttachment);

        Assert.AreEqual(IncomingDocumentAttachment."Main Attachment", true, 'Main Attachment should be set on the main document');
        Assert.AreEqual(IncomingDocumentAttachment2."Main Attachment", false, 'Main Attachment should not be set on the second document');
        Assert.AreEqual(IncomingDocumentAttachment.Default, false, 'Main Attachment should not be default');
        Assert.AreEqual(IncomingDocumentAttachment2.Default, true, 'Default attachment should be set');
        Assert.AreEqual(
          IncomingDocumentAttachment."Incoming Document Entry No.", MainIncomingDocumentAttachment."Incoming Document Entry No.",
          'IncomingDocument.GetMainAttachment result does not match expected value');
        Assert.AreEqual(
          IncomingDocumentAttachment."Line No.", MainIncomingDocumentAttachment."Line No.",
          'IncomingDocument.GetMainAttachment result does not match expected value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotReplaceMainAttachment()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileName: Text;
    begin
        // Init
        CreateIncomingDocumentWithMainAttachment(IncomingDocument, IncomingDocumentAttachment);
        IncomingDocument."OCR Status" := IncomingDocument."OCR Status"::"Awaiting Verification";

        FileName := CreateDummyFile('xml');

        // Execution
        asserterror IncomingDocument.ReplaceMainAttachment(FileName);

        // Verify
        Assert.ExpectedError(CannotReplaceMainAttachmentErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestReplaceMainAttachment()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocumentAttachment2: Record "Incoming Document Attachment";
        MainIncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileManagement: Codeunit "File Management";
        FileName2: Text;
        FileName3: Text;
    begin
        // Init
        CreateIncomingDocumentWithMainAttachment(IncomingDocument, IncomingDocumentAttachment);

        FileName2 := CreateDummyFile('xml');
        IncomingDocumentAttachment2.SetRange("Incoming Document Entry No.", IncomingDocumentAttachment."Incoming Document Entry No.");
        ImportAttachToIncomingDoc(IncomingDocumentAttachment2, FileName2);
        IncomingDocumentAttachment2.Get(
          IncomingDocumentAttachment2."Incoming Document Entry No.", IncomingDocumentAttachment2."Line No.");

        FileName3 := CreateDummyFile('xml');

        LibraryVariableStorage.Enqueue(ReplaceMainAttachmentQst);
        LibraryVariableStorage.Enqueue(true);

        // Execution
        IncomingDocument.ReplaceMainAttachment(FileName3);

        // Verify
        LibraryVariableStorage.AssertEmpty();
        IncomingDocument.GetMainAttachment(MainIncomingDocumentAttachment);
        IncomingDocumentAttachment2.Get(
          IncomingDocumentAttachment2."Incoming Document Entry No.", IncomingDocumentAttachment2."Line No.");

        Assert.IsFalse(
          IncomingDocumentAttachment.Get(IncomingDocumentAttachment."Incoming Document Entry No.", IncomingDocumentAttachment."Line No."),
          'Previous Incoming Document Attachment should be removed');
        Assert.AreEqual(IncomingDocumentAttachment2."Main Attachment", false, 'Main Attachment should not be set on the third document');
        Assert.AreEqual(MainIncomingDocumentAttachment."Main Attachment", true, 'Main Attachment should be set on the new document');
        Assert.AreEqual(MainIncomingDocumentAttachment.Default, true, 'Default should be set on the main document');
        Assert.AreEqual(
          MainIncomingDocumentAttachment.Name, FileManagement.GetFileNameWithoutExtension(FileName3), 'Wrong file name is set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetDocNoWithoutIncomingDoc()
    var
        PostedDocsWithNoIncDoc: TestPage "Posted Docs. With No Inc. Doc.";
    begin
        // init
        CreateTestGLEntries();

        // Execution
        PostedDocsWithNoIncDoc.OpenView();
        PostedDocsWithNoIncDoc.DocNoFilter.SetValue(Format(2));
        PostedDocsWithNoIncDoc.First();

        // Verification
        Assert.AreEqual('Test', PostedDocsWithNoIncDoc."First Posting Description".Value, '');
        Assert.AreEqual(Format(2), PostedDocsWithNoIncDoc."Document No.".Value, '');
    end;

    [Test]
    [HandlerFunctions('IncomingDocumentsLookupHandler')]
    [Scope('OnPrem')]
    procedure TestUpdateIncomingDocumentFromDocNoWOIncDoc()
    var
        IncomingDocument: Record "Incoming Document";
        PostedDocsWithNoIncDoc: TestPage "Posted Docs. With No Inc. Doc.";
    begin
        // [SCENARIO 124640] Annie can get a list of document numbers without an incoming document from the Incoming Documents page.

        // [GIVEN] We have some G/LEntries without an incoming document and we have a new incoming document.
        CreateTestGLEntries();
        IncomingDocument.DeleteAll();
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.TestField("Entry No.");

        // [WHEN] We open the "Posted Documents without Incoming Document" and select the first and click "Select Inc..."
        PostedDocsWithNoIncDoc.OpenView();
        PostedDocsWithNoIncDoc.DocNoFilter.SetValue(Format(2));
        PostedDocsWithNoIncDoc.First();
        PostedDocsWithNoIncDoc.SelectIncomingDoc.Invoke(); // Opens page 190 - see pagehandler

        // [THEN] PAge 190 opens and the user can select an IC to attach to the posted document.
        IncomingDocument.Find();
        Assert.IsTrue(IncomingDocument.Posted, '');
        Assert.AreEqual('2', IncomingDocument."Document No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDefaultAttachmentOnInsert()
    var
        IncomingDocument: Record "Incoming Document";
        DefaultIncomingDocumentAttachment: Record "Incoming Document Attachment";
        NonDefaultIncomingDocumentAttachment: Record "Incoming Document Attachment";
        DefaultAttachmentNo: Integer;
        NonDefaultAttachmentNo: Integer;
    begin
        // Init
        CreateNewIncomingDocument(IncomingDocument);
        DefaultAttachmentNo := InsertIncomingDocumentAttachment(IncomingDocument);
        DefaultIncomingDocumentAttachment.Get(IncomingDocument."Entry No.", DefaultAttachmentNo);
        NonDefaultAttachmentNo := InsertIncomingDocumentAttachment(IncomingDocument);
        NonDefaultIncomingDocumentAttachment.Get(IncomingDocument."Entry No.", NonDefaultAttachmentNo);

        // Verify;
        Assert.IsTrue(DefaultIncomingDocumentAttachment.Default, '');
        Assert.IsFalse(NonDefaultIncomingDocumentAttachment.Default, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDefaultAttachmentOnImport()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileName: Text;
    begin
        // Init
        CreateIncomingDocumentWithoutAttachments(IncomingDocument);
        IncomingDocument.SetRange("Entry No.", IncomingDocument."Entry No.");
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");

        // Execute
        FileName := CreateDummyFile('xml');
        ImportAttachToIncomingDoc(IncomingDocumentAttachment, FileName);
        FileName := CreateDummyFile('pdf');
        ImportAttachToIncomingDoc(IncomingDocumentAttachment, FileName);
        FileName := CreateDummyFile('jpg');
        ImportAttachToIncomingDoc(IncomingDocumentAttachment, FileName);

        // Verify;
        IncomingDocumentAttachment.FindSet();
        Assert.IsTrue(IncomingDocumentAttachment.Default, '');
        while IncomingDocumentAttachment.Next() <> 0 do
            Assert.IsFalse(IncomingDocumentAttachment.Default, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDefaultAttachmentChange()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        Attachment1No: Integer;
        Attachment2No: Integer;
        Attachment3No: Integer;
    begin
        // Init
        CreateNewIncomingDocument(IncomingDocument);
        Attachment1No := InsertIncomingDocumentAttachment(IncomingDocument);
        Attachment2No := InsertIncomingDocumentAttachment(IncomingDocument);
        Attachment3No := InsertIncomingDocumentAttachment(IncomingDocument);

        // Execute
        IncomingDocumentAttachment.Get(IncomingDocument."Entry No.", Attachment3No);
        IncomingDocumentAttachment.Validate(Default, true);
        IncomingDocumentAttachment.Modify(true);

        // Verify
        Assert.IsTrue(IncomingDocumentAttachment.Default, '');
        IncomingDocumentAttachment.Get(IncomingDocument."Entry No.", Attachment2No);
        Assert.IsFalse(IncomingDocumentAttachment.Default, '');
        IncomingDocumentAttachment.Get(IncomingDocument."Entry No.", Attachment1No);
        Assert.IsFalse(IncomingDocumentAttachment.Default, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDefaultAttachmentDeleteDisallowed()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        Attachment1No: Integer;
    begin
        // Init
        CreateNewIncomingDocument(IncomingDocument);
        Attachment1No := InsertIncomingDocumentAttachment(IncomingDocument);
        InsertIncomingDocumentAttachment(IncomingDocument);
        InsertIncomingDocumentAttachment(IncomingDocument);

        // Execute
        IncomingDocumentAttachment.Get(IncomingDocument."Entry No.", Attachment1No);

        // Verify
        asserterror IncomingDocumentAttachment.Delete(true);
        Assert.ExpectedError(DeleteOtherAttachmentsFirstErr);

        // Verify - 2
        asserterror IncomingDocumentAttachment.DeleteAttachment();
        Assert.ExpectedError(CannotDeleteDefaultAttachmentErr);
    end;

    [Test]
    [HandlerFunctions('IncomingDocumentCardHandler')]
    [Scope('OnPrem')]
    procedure TestShowIncomingDocumentCard()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        // [SCENARIO 124640] Annie can see the Incoming Document Card from a posted entry.

        // [GIVEN] We have a posted incoming document.
        IncomingDocument.DeleteAll();
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.TestField("Entry No.");
        IncomingDocument.Release();
        IncomingDocument.SetPostedDocFields(DMY2Date(1, 1, 2000), 'TEST');

        // [WHEN] We call the ShowCard method
        IncomingDocument.ShowCard('TEST', DMY2Date(1, 1, 2000));

        // [THEN] Page 189 opens. Verified by page handler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetFiltersFromMainRecSalesHeader()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        SalesHeader: Record "Sales Header";
        RecRef: RecordRef;
    begin
        // [SCENARIO] User wants to create a new incoming document to an existing entity from the factbox

        // [GIVEN] We have a sales document (credit memo) with no incoming document
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        SalesHeader."No." := '1234';

        // [WHEN] The user clicks create incoming document from file,
        RecRef.GetTable(SalesHeader);
        IncomingDocumentAttachment.SetFiltersFromMainRecord(RecRef, IncomingDocumentAttachment);

        // [THEN] the sales header fields are set as filters on the attachment
        Assert.AreEqual(DATABASE::"Sales Header", IncomingDocumentAttachment.GetRangeMin("Document Table No. Filter"), '');
        Assert.AreEqual(SalesHeader."Document Type", IncomingDocumentAttachment.GetRangeMin("Document Type Filter"), '');
        Assert.AreEqual(SalesHeader."No.", IncomingDocumentAttachment.GetRangeMin("Document No. Filter"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetFiltersFromMainRecPurchHeader()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        PurchaseHeader: Record "Purchase Header";
        RecRef: RecordRef;
    begin
        // [SCENARIO] User wants to create a new incoming document to an existing entity from the factbox

        // [GIVEN] We have a Purchase document (credit memo) with no incoming document
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
        PurchaseHeader."No." := '1234';

        // [WHEN] The user clicks create incoming document from file,
        RecRef.GetTable(PurchaseHeader);
        IncomingDocumentAttachment.SetFiltersFromMainRecord(RecRef, IncomingDocumentAttachment);

        // [THEN] the Purchase header fields are set as filters on the attachment
        Assert.AreEqual(DATABASE::"Purchase Header", IncomingDocumentAttachment.GetRangeMin("Document Table No. Filter"), '');
        Assert.AreEqual(PurchaseHeader."Document Type", IncomingDocumentAttachment.GetRangeMin("Document Type Filter"), '');
        Assert.AreEqual(PurchaseHeader."No.", IncomingDocumentAttachment.GetRangeMin("Document No. Filter"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetFiltersFromMainRecGenJnlLine()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RecRef: RecordRef;
    begin
        // [SCENARIO] User wants to create a new incoming document to an existing entity from the factbox

        // [GIVEN] We have a GenJournalLine with no incoming document
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalLine.Init();
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalLine."Line No." := 10000;

        // [WHEN] The user clicks create incoming document from file,
        RecRef.GetTable(GenJournalLine);
        IncomingDocumentAttachment.SetFiltersFromMainRecord(RecRef, IncomingDocumentAttachment);

        // [THEN] the journal line fields are set as filters on the attachment
        Assert.AreEqual(DATABASE::"Gen. Journal Line", IncomingDocumentAttachment.GetRangeMin("Document Table No. Filter"), '');
        Assert.AreEqual(GenJournalLine."Journal Batch Name", IncomingDocumentAttachment.GetRangeMin("Journal Batch Name Filter"), '');
        Assert.AreEqual(
          GenJournalLine."Journal Template Name", IncomingDocumentAttachment.GetRangeMin("Journal Template Name Filter"), '');
        Assert.AreEqual(GenJournalLine."Line No.", IncomingDocumentAttachment.GetRangeMin("Journal Line No. Filter"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetFiltersFromMainRecGLEntry()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        GLEntry: Record "G/L Entry";
        RecRef: RecordRef;
    begin
        // [SCENARIO] User wants to create a new incoming document to an existing entity from the factbox

        // [GIVEN] We have a GLEnry with no incoming document
        GLEntry.Init();
        GLEntry."Document No." := '1234';
        GLEntry."Posting Date" := Today;

        // [WHEN] The user clicks create incoming document from file,
        RecRef.GetTable(GLEntry);
        IncomingDocumentAttachment.SetFiltersFromMainRecord(RecRef, IncomingDocumentAttachment);

        // [THEN] the GLEntry fields are set as filters on the attachment
        Assert.AreEqual(GLEntry."Document No.", IncomingDocumentAttachment.GetRangeMin("Document No."), '');
        Assert.AreEqual(GLEntry."Posting Date", IncomingDocumentAttachment.GetRangeMin("Posting Date"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetFiltersFromMainRecPostedPurchInvoice()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        PurchInvHeader: Record "Purch. Inv. Header";
        RecRef: RecordRef;
    begin
        // [SCENARIO] User wants to create a new incoming document to an existing entity from the factbox

        // [GIVEN] We have a PurchInvHeader with no incoming document
        PurchInvHeader.Init();
        PurchInvHeader."No." := '1234';
        PurchInvHeader."Posting Date" := Today;

        // [WHEN] The user clicks create incoming document from file,
        RecRef.GetTable(PurchInvHeader);
        IncomingDocumentAttachment.SetFiltersFromMainRecord(RecRef, IncomingDocumentAttachment);

        // [THEN] the PurchInvHeader fields are set as filters on the attachment
        Assert.AreEqual(PurchInvHeader."No.", IncomingDocumentAttachment.GetRangeMin("Document No."), '');
        Assert.AreEqual(PurchInvHeader."Posting Date", IncomingDocumentAttachment.GetRangeMin("Posting Date"), '');
    end;

    [Test]
    [HandlerFunctions('IncomingDocumentsLookupHandlerPrevRec,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestUnlinkPostedDocumentFromIncomingDocument()
    var
        IncomingDocument: Record "Incoming Document";
        GLEntry: Record "G/L Entry";
        IncomingDocumentCard: TestPage "Incoming Document";
        DocumentNo: Code[20];
        PostingDate: Date;
        MessageText: Text;
    begin
        CreateNewIncomingDocument(IncomingDocument);
        CreateTestGLEntries();

        GLEntry.FindFirst();

        DocumentNo := GLEntry."Document No.";
        PostingDate := GLEntry."Posting Date";

        IncomingDocument.Get(IncomingDocument."Entry No.");
        IncomingDocument."Document Type" := IncomingDocument."Document Type"::Journal;
        IncomingDocument.Modify();

        IncomingDocument.SelectIncomingDocumentForPostedDocument(DocumentNo, PostingDate, GLEntry.RecordId);

        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);

        LibraryVariableStorage.Enqueue(StrSubstNo(DetachQst, DocumentNo, Format(PostingDate)));
        LibraryVariableStorage.Enqueue(true);

        MessageText := RemovePostedRecordManuallyMsg;
        LibraryVariableStorage.Enqueue(MessageText);
        IncomingDocumentCard.RemoveReferencedRecord.Invoke();

        IncomingDocument.Get(IncomingDocument."Entry No.");
        Assert.AreEqual(false, IncomingDocument.Posted, 'Posted should be set to false for the incoming document');
        Assert.AreEqual(0D, IncomingDocument."Posting Date", 'Posting date is not set correctly');
        Assert.AreEqual(0DT, IncomingDocument."Posted Date-Time", 'Posting date time is not set correctly');
        Assert.AreEqual(IncomingDocument."Document Type"::" ", IncomingDocument."Document Type", 'Document Type should be removed');
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure UnlinkNotPostedDocumentFromIncomingDocumentPurchaseHeader(DoDelete: Boolean)
    var
        IncomingDocument: Record "Incoming Document";
        PurchaseHeader: Record "Purchase Header";
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        PurchaseHeader.SetFilter("Incoming Document Entry No.", '<>0');
        PurchaseHeader.DeleteAll();

        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.Release();
        IncomingDocument.Modify();
        IncomingDocument.CreatePurchInvoice();  // Opens page 51 "Purchase Invoice"
        IncomingDocument.Modify();
        IncomingDocument.TestField("Document Type", IncomingDocument."Document Type"::"Purchase Invoice");

        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);

        LibraryVariableStorage.Enqueue(DoYouWantToRemoveReferenceQst);
        LibraryVariableStorage.Enqueue(true);

        LibraryVariableStorage.Enqueue(DeleteRecordQst);
        LibraryVariableStorage.Enqueue(DoDelete);
        IncomingDocumentCard.RemoveReferencedRecord.Invoke();

        IncomingDocument.Get(IncomingDocument."Entry No.");
        Assert.AreEqual(false, IncomingDocument.Posted, 'Posted should be set to false for the incoming document');
        Assert.AreEqual(0D, IncomingDocument."Posting Date", 'Posting date is not set correctly');
        Assert.AreEqual(0DT, IncomingDocument."Posted Date-Time", 'Posting date time is not set correctly');
        Assert.AreEqual(IncomingDocument."Document Type"::" ", IncomingDocument."Document Type", 'Document Type should be removed');
        if DoDelete then
            Assert.IsFalse(PurchaseHeader.FindFirst(), 'Purchase document should not be deleted')
        else begin
            Clear(PurchaseHeader);
            Assert.IsTrue(PurchaseHeader.FindFirst(), 'Purchase document should not be deleted');
            Assert.AreEqual(
              0, PurchaseHeader."Incoming Document Entry No.", 'Incoming Document Entry No. should be removed from Purchase header');
        end;
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchInvHandler')]
    [Scope('OnPrem')]
    procedure TestUnlinkNotPostedDocumentFromIncomingDocumentPurchaseHeader()
    begin
        UnlinkNotPostedDocumentFromIncomingDocumentPurchaseHeader(false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesInvHandler')]
    [Scope('OnPrem')]
    procedure TestUnlinkNotPostedDocumentFromIncomingDocumentSalesHeader()
    var
        IncomingDocument: Record "Incoming Document";
        SalesHeader: Record "Sales Header";
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        SalesHeader.SetFilter("Incoming Document Entry No.", '<>0');
        SalesHeader.DeleteAll();

        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.Release();
        IncomingDocument.Modify();
        IncomingDocument.CreateSalesInvoice();
        IncomingDocument.Modify();
        IncomingDocument.TestField("Document Type", IncomingDocument."Document Type"::"Sales Invoice");

        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);

        LibraryVariableStorage.Enqueue(DoYouWantToRemoveReferenceQst);
        LibraryVariableStorage.Enqueue(true);

        LibraryVariableStorage.Enqueue(DeleteRecordQst);
        LibraryVariableStorage.Enqueue(false);
        IncomingDocumentCard.RemoveReferencedRecord.Invoke();

        IncomingDocument.Get(IncomingDocument."Entry No.");
        Assert.AreEqual(false, IncomingDocument.Posted, 'Posted should be set to false for the incoming document');
        Assert.AreEqual(0D, IncomingDocument."Posting Date", 'Posting date is not set correctly');
        Assert.AreEqual(0DT, IncomingDocument."Posted Date-Time", 'Posting date time is not set correctly');
        Assert.AreEqual(IncomingDocument."Document Type"::" ", IncomingDocument."Document Type", 'Document Type should be removed');
        Clear(SalesHeader);
        Assert.IsTrue(SalesHeader.FindFirst(), 'Sales document should not be deleted');
        Assert.AreEqual(
          0, SalesHeader."Incoming Document Entry No.", 'Incoming Document Entry No. should be removed from Purchase header');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestUnlinkNotPostedDocumentFromIncomingDocumentJournalLine()
    var
        IncomingDocument: Record "Incoming Document";
        GenJournalLine: Record "Gen. Journal Line";
        IncomingDocumentCard: TestPage "Incoming Document";
    begin
        GenJournalLine.SetFilter("Incoming Document Entry No.", '<>0');
        GenJournalLine.DeleteAll();

        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.Release();
        IncomingDocument.Modify();
        CreateAndAssignGenJournalLineToIncomingDocument(IncomingDocument);
        IncomingDocument.TestField("Document Type", IncomingDocument."Document Type"::Journal);

        IncomingDocumentCard.OpenEdit();
        IncomingDocumentCard.GotoRecord(IncomingDocument);

        LibraryVariableStorage.Enqueue(DoYouWantToRemoveReferenceQst);
        LibraryVariableStorage.Enqueue(true);

        LibraryVariableStorage.Enqueue(DeleteRecordQst);
        LibraryVariableStorage.Enqueue(false);
        IncomingDocumentCard.RemoveReferencedRecord.Invoke();

        IncomingDocument.Get(IncomingDocument."Entry No.");
        Assert.AreEqual(false, IncomingDocument.Posted, 'Posted should be set to false for the incoming document');
        Assert.AreEqual(0D, IncomingDocument."Posting Date", 'Posting date is not set correctly');
        Assert.AreEqual(0DT, IncomingDocument."Posted Date-Time", 'Posting date time is not set correctly');
        Assert.AreEqual(IncomingDocument."Document Type"::" ", IncomingDocument."Document Type", 'Document Type should be removed');

        Clear(GenJournalLine);
        Assert.IsTrue(GenJournalLine.FindFirst(), 'Genearal Journal Line should not be deleted');
        Assert.AreEqual(
          0, GenJournalLine."Incoming Document Entry No.", 'Incoming Document Entry No. should be removed from Purchase header');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchInvHandler')]
    [Scope('OnPrem')]
    procedure TestUnlinkingAndDeletingNonPostedDocumentFromIncomingDocument()
    begin
        UnlinkNotPostedDocumentFromIncomingDocumentPurchaseHeader(true);
    end;

    [Test]
    [HandlerFunctions('HyperlinkHandler')]
    [Scope('OnPrem')]
    procedure TestHyperlinkToDocumentURL()
    var
        IncomingDocument: Record "Incoming Document";
        DocumentNo: Text[10];
        PostingDate: Date;
    begin
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.SetURL('about:blank');
        DocumentNo := 'TEST';
        PostingDate := DMY2Date(1, 1, 2000);

        IncomingDocument.SetPostedDocFields(PostingDate, DocumentNo);

        // Running should open IE
        IncomingDocument.HyperlinkToDocument(DocumentNo, PostingDate);
    end;

    [Test]
    [HandlerFunctions('HyperlinkHandler')]
    [Scope('OnPrem')]
    procedure TestHyperlinkToDocumentAttachment()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileName: Text;
        DocumentNo: Text[10];
        PostingDate: Date;
    begin
        CreateNewIncomingDocument(IncomingDocument);

        DocumentNo := 'TEST';
        PostingDate := DMY2Date(1, 1, 2000);

        IncomingDocument.SetPostedDocFields(PostingDate, DocumentNo);

        FileName := CreateDummyFile('xml');
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        ImportAttachToIncomingDoc(IncomingDocumentAttachment, FileName);

        IncomingDocument.HyperlinkToDocument(DocumentNo, PostingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIncomingDocsShouldFilterProcessedDocs()
    var
        ProcessedIncomingDocument: Record "Incoming Document";
        UnprocessedIncomingDocument: Record "Incoming Document";
        IncomingDocumentsPage: TestPage "Incoming Documents";
    begin
        ProcessedIncomingDocument.DeleteAll();
        CreateIncomingDocument(ProcessedIncomingDocument, 'Processed Document', true);
        CreateIncomingDocument(UnprocessedIncomingDocument, 'Unprocessed Document', false);

        IncomingDocumentsPage.OpenEdit();
        IncomingDocumentsPage.ShowUnprocessed.Invoke();

        IncomingDocumentsPage.First();
        Assert.IsFalse(IncomingDocumentsPage.ShowUnprocessed.Enabled(), 'Expected that ShowUnprocessed action is disabled');
        Assert.IsTrue(IncomingDocumentsPage.ShowAll.Enabled(), 'Expected that ShowUnprocessed action is disabled');
        Assert.AreEqual(
          UnprocessedIncomingDocument.Description, IncomingDocumentsPage.Description.Value,
          'Expected that Description match the Processed Document');
        Assert.IsFalse(IncomingDocumentsPage.Next(), 'Expected that list contains only one record');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIncomingDocsShouldShowAllDocsOnShowAllAction()
    var
        ProcessedIncomingDocument: Record "Incoming Document";
        UnprocessedIncomingDocument: Record "Incoming Document";
        IncomingDocumentsPage: TestPage "Incoming Documents";
    begin
        ProcessedIncomingDocument.DeleteAll();
        CreateIncomingDocument(ProcessedIncomingDocument, 'Processed Document', true);
        CreateIncomingDocument(UnprocessedIncomingDocument, 'Unprocessed Document', false);

        IncomingDocumentsPage.OpenEdit();
        IncomingDocumentsPage.FILTER.SetFilter(Processed, Format(true));
        IncomingDocumentsPage.ShowAll.Invoke();

        Assert.IsTrue(IncomingDocumentsPage.First(), 'Expected that list contains 2 records');
        Assert.IsTrue(IncomingDocumentsPage.Next(), 'Expected that list contains 2 records');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIncomingDocumentSetToProcessedUnprocessed()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentPage: TestPage "Incoming Document";
    begin
        IncomingDocument.DeleteAll();

        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.Description := 'Unprocessed Document';
        IncomingDocument.Processed := false;
        IncomingDocument.Modify();

        IncomingDocumentPage.OpenEdit();
        IncomingDocumentPage.GotoRecord(IncomingDocument);
        IncomingDocumentPage.SetToProcessed.Invoke();

        IncomingDocument.Get(IncomingDocument."Entry No.");
        Assert.IsTrue(IncomingDocument.Processed, 'Expected that record is set as processed');

        IncomingDocumentPage.SetToUnprocessed.Invoke();
        IncomingDocument.Get(IncomingDocument."Entry No.");
        Assert.IsFalse(IncomingDocument.Processed, 'Expected that record is set as processed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleUpdateIncomingDocumentFromPosting()
    var
        IncomingDocument: Record "Incoming Document";
        PostingDate: Date;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376596] TAB130 "Incoming Document".UpdateIncomingDocumentFromPosting() uses last Document No and Date in case of multiple call
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.UpdateIncomingDocumentFromPosting(IncomingDocument."Entry No.", DMY2Date(1, 1, 2015), 'TEST');

        PostingDate := LibraryRandom.RandDate(10);
        DocumentNo := LibraryUtility.GenerateGUID();
        IncomingDocument.Find();
        IncomingDocument.UpdateIncomingDocumentFromPosting(IncomingDocument."Entry No.", PostingDate, DocumentNo);

        IncomingDocument.Find();
        Assert.AreEqual(DocumentNo, IncomingDocument."Document No.", IncomingDocument.FieldCaption("Document No."));
        Assert.AreEqual(PostingDate, IncomingDocument."Posting Date", IncomingDocument.FieldCaption("Posting Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_DocDateAndDueDateNotValidatedWhenChangeSalesInvPostingDateFromIncDoc()
    var
        SalesHeader: Record "Sales Header";
        DocDate: Date;
        DueDate: Date;
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 378141] "Document Date" and "Due Date" should not be validated when change "Posting Date" of Sales Invoice related to Incoming Document

        // [GIVEN] Incoming Document with "Entry No." = "X", "Document Date" = "01.01", "Due Date" = "10.01"
        // [GIVEN] Sales Invoice with "Incoming Document Entry No." = "X", "Posting Date" = "05.01", "Document Date" = "01.01", "Due Date" = "10.01"
        DocDate := LibraryRandom.RandDate(100);
        DueDate := LibraryRandom.RandDate(100);
        MockSalesHeaderWithDateAndIncomingDocEntryNo(SalesHeader, DocDate, DueDate);

        // [WHEN] Change "Posting Date" of Sales Invoice to "08.01"
        SalesHeader.Validate("Posting Date", DueDate + 1);

        // [THEN] "Document Date" of Sales Invoice is "01.01"
        SalesHeader.TestField("Document Date", DocDate);

        // [THEN] "Due Date" of Sales Invoice is "10.01"
        SalesHeader.TestField("Due Date", DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_DocDateAndDueDateNotValidatedWhenChangePurchInvPostingDateFromIncDoc()
    var
        PurchHeader: Record "Purchase Header";
        DocDate: Date;
        DueDate: Date;
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 378141] "Document Date" and "Due Date" should not be validated when change "Posting Date" of Purchase Invoice related to Incoming Document

        // [GIVEN] Incoming Document with "Entry No." = "X", "Document Date" = "01.01", "Due Date" = "10.01"
        // [GIVEN] Purchase Invoice with "Incoming Document Entry No." = "X", "Posting Date" = "05.01", "Document Date" = "01.01", "Due Date" = "10.01"
        DocDate := LibraryRandom.RandDate(100);
        DueDate := LibraryRandom.RandDate(100);
        MockPurchHeaderWithDateAndIncomingDocEntryNo(PurchHeader, DocDate, DueDate);

        // [WHEN] Change "Posting Date" of Purchase Invoice to "08.01"
        PurchHeader.Validate("Posting Date", DueDate + 1);

        // [THEN] "Document Date" of Purchase Invoice is "01.01"
        PurchHeader.TestField("Document Date", DocDate);

        // [THEN] "Due Date" of Purchase Purchase is "10.01"
        PurchHeader.TestField("Due Date", DueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAutomaticCreationActionsDisabled()
    begin
        // [WHEN] "Data Exchange Type" is not set on the Incoming Documents
        // [THEN] "Create Document" and "Create General Jounal Line" actions are disabled
        TestAutomaticCreationActions(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAutomaticCreationActionsEnabled()
    begin
        // [WHEN] "Data Exchange Type" is set on the Incoming Documents
        // [THEN] "Create Document" and "Create General Jounal Line" actions are enabled
        TestAutomaticCreationActions(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TableIncomingDocumentsVendorInvoiceFieldLength()
    var
        IncomingDocument: Record "Incoming Document";
        PurchaseHeader: Record "Purchase Header";
        LibraryTablesUT: Codeunit "Library - Tables UT";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 228770] TAB130."Vendor Invoice No." field must have the same length and type of TAB38."Vendor Invoice No." field
        LibraryTablesUT.CompareFieldTypeAndLength(
          IncomingDocument, IncomingDocument.FieldNo("Vendor Invoice No."),
          PurchaseHeader, PurchaseHeader.FieldNo("Vendor Invoice No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindByDocumentNoAndPostingDateIncomingDocument()
    var
        IncomingDocument: Record "Incoming Document";
        DocumentNo: Text;
        IncomingDocumentEntryNo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 407834] "Incoming Document".FindByDocumentNoAndPostingDate must return record if Document No. filter is max length and contains escape symbols

        // [GIVEN] "Incoming Document" with "Document No." contains special characters
        CreateIncomingDocumentWithoutAttachments(IncomingDocument);
        IncomingDocumentEntryNo := IncomingDocument."Entry No.";
        DocumentNo := 'AAAAAA-AAAAAA(AAAAA)';
        IncomingDocument.Validate("Document No.", DocumentNo);
        IncomingDocument.Validate("Posting Date", WorkDate());
        IncomingDocument.Reset();

        IncomingDocument.FindByDocumentNoAndPostingDate(
            IncomingDocument, DocumentNo, Format(WorkDate()));

        IncomingDocument.TestField("Entry No.", IncomingDocumentEntryNo);
    end;

    [Test]
    procedure CreateNewIncomingDocInPageNoAttachedFiles()
    var
        IncomingDocuments: array[2] of Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocumentsPage: TestPage "Incoming Documents";
        NoAttachmentExpectedErr: Label 'Document attachment factbox must be empty.';
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Incoming Doc. Attachments" factbox does not show any attachments when a new incoming document is created after another doc. with attachments

        // [GIVEN] Create incoming document "D1" with attachment
        CreateIncomingDocumentWithMainAttachment(IncomingDocuments[1], IncomingDocumentAttachment);

        // [GIVEN] Create incoming document "D2" without attachments
        CreateIncomingDocumentWithoutAttachments(IncomingDocuments[2]);

        // [GIVEN] Open the page "Incoming Documents" and navigate to the document "D1" to initialize the factobox with the document record
        IncomingDocumentsPage.OpenView();
        IncomingDocumentsPage.GoToRecord(IncomingDocuments[1]);

        // [WHEN] Move to the document "D2"
        IncomingDocumentsPage.GoToRecord(IncomingDocuments[2]);

        // [THEN] List of attachments in the factbox is empty
        Assert.IsFalse(IncomingDocumentsPage.IncomingDocAttachFactBox.First(), NoAttachmentExpectedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowIncomingDocumentAttachedWhenOpenVendorLedgerEntries()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [SCENARIO 477906] "Error: The length of the string is 21, but it must be less than or equal to 20 characters. Value: '12000-009 (21% VAT)'" error message appears in the Incoming Document Factbox when the Document No. contains a % sign.

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create an Incoming Document.
        CreateIncomingDocumentWithPDFAttachment(IncomingDocument, IncomingDocumentAttachment);

        // [GIVEN] Create a Purchase Header & Validate Vendor Invoice No.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", Format(LibraryRandom.RandInt(1000)));

        // [GIVEN] Attach Incoming Document with Purchase Invoice.
        PurchaseHeader."Incoming Document Entry No." := IncomingDocument."Entry No.";
        IncomingDocument.SetPurchDoc(PurchaseHeader);
        PurchaseHeader.Modify(true);

        // [GIVEN] Create a Purchase Line with an Item.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(0));

        // [GIVEN] Post Purchase Invoice.
        CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchaseHeader);

        // [GIVEN] Find Posted Purchase Invoice.
        PurchInvHeader.SetRange("Vendor Invoice No.", PurchaseHeader."Vendor Invoice No.");
        PurchInvHeader.FindFirst();

        // [GIVEN] Open Posted Purchase Invoice Page & Find Incoming Doc Attach FactBox.
        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.GoToRecord(PurchInvHeader);
        PostedPurchaseInvoice.IncomingDocAttachFactBox.First();

        // [GIVEN] Verify Correct Incoming Document is attached to Posted Purchase Invoice & Close the Page.
        PostedPurchaseInvoice.IncomingDocAttachFactBox.Name.AssertEquals(IncomingDocumentAttachment.Name);
        PostedPurchaseInvoice.Close();

        // [GIVEN] Find Vendor Ledger Entry.
        VendorLedgerEntry.SetRange("Document No.", PurchInvHeader."No.");
        VendorLedgerEntry.FindFirst();

        // [WHEN] Open Vendor Ledger Entries Page & Find Incoming Doc Attach FactBox.
        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.GoToRecord(VendorLedgerEntry);
        VendorLedgerEntries.IncomingDocAttachFactBox.First();

        // [VERIFY] Verify Correct Incoming Document is attached to Vendor Ledger Entries & Close the Page.
        VendorLedgerEntries.IncomingDocAttachFactBox.Name.AssertEquals(IncomingDocumentAttachment.Name);
        VendorLedgerEntries.Close();
    end;

    local procedure TestAutomaticCreationActions(DataExchangeTypeHasValue: Boolean)
    var
        IncomingDocumentRec: Record "Incoming Document";
        IncomingDocumentPage: TestPage "Incoming Document";
        IncomingDocuments: TestPage "Incoming Documents";
    begin
        CreateNewIncomingDocument(IncomingDocumentRec);

        if DataExchangeTypeHasValue then begin
            IncomingDocumentRec."Data Exchange Type" := LibraryUtility.GenerateGUID();
            IncomingDocumentRec.Modify();
        end;

        IncomingDocumentPage.OpenEdit();
        IncomingDocumentPage.GotoRecord(IncomingDocumentRec);
        Assert.AreEqual(DataExchangeTypeHasValue, IncomingDocumentPage.CreateGenJnlLine.Enabled(), 'Editable value unexpected.');
        Assert.AreEqual(DataExchangeTypeHasValue, IncomingDocumentPage.CreateDocument.Enabled(), 'Editable value unexpected.');

        IncomingDocuments.OpenView();
        IncomingDocuments.GotoRecord(IncomingDocumentRec);
        Assert.AreEqual(DataExchangeTypeHasValue, IncomingDocuments.CreateGenJnlLine.Enabled(), 'Editable value unexpected.');
        Assert.AreEqual(DataExchangeTypeHasValue, IncomingDocuments.CreateDocument.Enabled(), 'Editable value unexpected.');
    end;

    local procedure GetIncomeStatementAcc(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        exit(LibraryERM.FindDirectPostingGLAccount(GLAccount));
    end;

    local procedure GetBalanceSheetAcc(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        exit(LibraryERM.FindDirectPostingGLAccount(GLAccount));
    end;

    local procedure CreateNewIncomingDocument(var IncomingDocument: Record "Incoming Document")
    begin
        LibraryIncomingDocuments.InitIncomingDocuments();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        Commit();
    end;

    local procedure CreateDummyFile(Extension: Text): Text
    var
        FileManagement: Codeunit "File Management";
        File: File;
        FileName: Text;
    begin
        FileName := FileManagement.ServerTempFileName(Extension);
        File.Create(FileName);
        File.Write('<TEST>hello</TEST>');
        File.Close();
        exit(FileManagement.DownloadTempFile(FileName));
    end;

    local procedure CreateTestGLEntries()
    var
        GLEntry: Record "G/L Entry";
        i: Integer;
    begin
        if GLEntry.FindLast() then;
        for i := 1 to 10 do begin
            GLEntry."Entry No." += 1;
            GLEntry."G/L Account No." := 'TEST';
            GLEntry."Posting Date" := WorkDate() - i mod 3;
            GLEntry."Document No." := Format(i);
            GLEntry.Description := 'Test';
            GLEntry.Amount := 1;
            GLEntry."Debit Amount" := 1;
            GLEntry."Credit Amount" := 0;
            GLEntry.Insert();
        end;
    end;

    local procedure CreateAndAssignGenJournalLineToIncomingDocument(var IncomingDocument: Record "Incoming Document")
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.Trap();
        IncomingDocument.CreateGenJnlLine();
        GeneralJournal.Close();
        IncomingDocument.Modify();
    end;

    local procedure CreateRecurringJournalLines(var GenJournalLine: Record "Gen. Journal Line"; GenJnlBatch: Record "Gen. Journal Batch")
    var
        IncomingDocument: Record "Incoming Document";
        RecurringFrequency: DateFormula;
        Amount: Decimal;
        LineNo: Integer;
    begin
        Amount := LibraryRandom.RandDec(100, 2);
        for LineNo := 1 to 2 do begin
            LibraryERM.CreateGeneralJnlLine(
                GenJournalLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
                GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
                LibraryERM.CreateGLAccountNo(), Amount);
            GenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"F  Fixed");
            Evaluate(RecurringFrequency, '<' + Format(LibraryRandom.RandInt(10)) + 'M >');
            GenJournalLine.Validate("Recurring Frequency", RecurringFrequency);
            CreateIncomingDocumentWithoutAttachments(IncomingDocument);
            GenJournalLine.Validate("Incoming Document Entry No.", IncomingDocument."Entry No.");
            GenJournalLine.Modify(true);
            Amount := -Amount
        end;
    end;

    local procedure MockSalesHeaderWithDateAndIncomingDocEntryNo(var SalesHeader: Record "Sales Header"; DocDate: Date; DueDate: Date)
    var
        IncomingDocument: Record "Incoming Document";
    begin
        CreateNewIncomingDocument(IncomingDocument);
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader.Insert(true);
        SalesHeader."Posting Date" := WorkDate();
        SalesHeader."Document Date" := DocDate;
        SalesHeader."Due Date" := DueDate;
        SalesHeader."Incoming Document Entry No." := IncomingDocument."Entry No.";
        SalesHeader.Modify();
    end;

    local procedure MockPurchHeaderWithDateAndIncomingDocEntryNo(var PurchHeader: Record "Purchase Header"; DocDate: Date; DueDate: Date)
    var
        IncomingDocument: Record "Incoming Document";
    begin
        CreateNewIncomingDocument(IncomingDocument);
        PurchHeader.Init();
        PurchHeader."Document Type" := PurchHeader."Document Type"::Invoice;
        PurchHeader.Insert(true);
        PurchHeader."Posting Date" := WorkDate();
        PurchHeader."Document Date" := DocDate;
        PurchHeader."Due Date" := DueDate;
        PurchHeader."Incoming Document Entry No." := IncomingDocument."Entry No.";
        PurchHeader.Modify();
    end;

    local procedure ValidatePostedIncomingDocument(var IncomingDocument: Record "Incoming Document")
    begin
        IncomingDocument.Get(IncomingDocument."Entry No.");
        IncomingDocument.TestField(Posted);
        IncomingDocument.TestField("Posted Date-Time");
        IncomingDocument.TestField("Document No.");
        IncomingDocument.TestField("Posting Date");
        Assert.IsTrue(IncomingDocument.PostedDocExists(IncomingDocument."Document No.", IncomingDocument."Posting Date"), '');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchInvHandler(var PurchaseInvoice: Page "Purchase Invoice")
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchCrMemoHandler(var PurchaseCreditMemo: Page "Purchase Credit Memo")
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesInvHandler(var SalesInvoice: Page "Sales Invoice")
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesCrMemoHandler(var SalesCreditMemo: Page "Sales Credit Memo")
    begin
    end;

    local procedure UpdateIncomingDocumentsSetup()
    var
        IncomingDocumentsSetup: Record "Incoming Documents Setup";
    begin
        IncomingDocumentsSetup.Fetch();
        IncomingDocumentsSetup.Validate("Require Approval To Create", false);
        IncomingDocumentsSetup.Modify(true);
    end;

    local procedure ImportAttachToIncomingDoc(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; FilePath: Text)
    var
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
    begin
        IncomingDocumentAttachment.Init();
        ImportAttachmentIncDoc.ImportAttachment(IncomingDocumentAttachment, FilePath);
    end;

    local procedure ImportAndVerifyAttachment(Extension: Text; ExpectedContentType: Option)
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        // Init
        FileName := CreateDummyFile(Extension);
        CreateIncomingDocumentWithoutAttachments(IncomingDocument);
        IncomingDocument.SetRange("Entry No.", IncomingDocument."Entry No.");

        // Execute
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        ImportAttachToIncomingDoc(IncomingDocumentAttachment, FileName);
        // FileManagement.DeleteServerFile(FileName); Fails in SNAP

        // Verify
        Assert.AreEqual(1, IncomingDocumentAttachment.Count, '');
        IncomingDocumentAttachment.FindFirst();
        IncomingDocumentAttachment.CalcFields(Content);
        Assert.IsTrue(IncomingDocumentAttachment.Content.HasValue, '');
        Assert.AreEqual(ExpectedContentType, IncomingDocumentAttachment.Type, '');
        Assert.AreEqual(LowerCase(Extension), IncomingDocumentAttachment."File Extension", '');
        Assert.AreEqual(
          CopyStr(FileManagement.GetFileNameWithoutExtension(FileName), 1, MaxStrLen(IncomingDocumentAttachment.Name)),
          IncomingDocumentAttachment.Name, '');

        // Clean-up + test delete
        IncomingDocument.Find();
        IncomingDocument.Delete(true);
        Assert.AreEqual(0, IncomingDocumentAttachment.Count, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IncomingDocumentForEveryPurchInvoicePostedFromPurchOrder()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PartialQty: array[2] of Decimal;
        DocNo: array[2] of Code[20];
        i: Integer;
    begin
        // [SCENARIO 489204] Stan can post purchase order partially multiple times and see incoming document attached to every purchase invoice

        PurchaseHeader.SetFilter("Incoming Document Entry No.", '<>0');
        PurchaseHeader.DeleteAll();

        // [GIVEN] Incoming document attached to the purchase order
        CreateIncomingDocumentWithMainAttachment(IncomingDocument, IncomingDocumentAttachment);
        LibraryPurchase.CreatePurchaseOrderForVendorNo(PurchaseHeader, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Incoming Document Entry No.", IncomingDocument."Entry No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);

        PartialQty[1] := PurchaseLine."Qty. to Receive" / 2;
        PartialQty[2] := PurchaseLine."Qty. to Receive" - PartialQty[1];

        // [WHEN] Post purchase order partially two times
        for i := 1 to ArrayLen(PartialQty) do begin
            PurchaseLine.Find();
            PurchaseLine.Validate("Qty. to Receive", PartialQty[i]);
            PurchaseLine.Modify(true);
            PurchaseHeader.Find();
            PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
            PurchaseHeader.Modify(true);

            DocNo[i] := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        end;
        // [THEN] Two incoming document attached exists, per each posted invoice
        for i := 1 to ArrayLen(DocNo) do begin
            Assert.IsTrue(IncomingDocument.PostedDocExists(DocNo[i], PurchaseHeader."Posting Date"), 'Incoming document for posted invoice not found');
            Assert.RecordCount(IncomingDocumentAttachment, 1);
            IncomingDocumentAttachment.FindFirst();
            IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
            Assert.AreEqual(1, IncomingDocumentAttachment.Count, '');
            IncomingDocumentAttachment.FindFirst();
            IncomingDocumentAttachment.CalcFields(Content);
            Assert.IsTrue(IncomingDocumentAttachment.Content.HasValue, '');
        end;
    end;

    [Test]
    procedure IncDocEntryNoClearedInGenJnlLinePostedFromTemplateWithUnlinkInDocOption()
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 556017] Incoming Document Entry No. is cleared in Gen. Journal Line posted from template with "Unlink Inc. Doc On Posting" option

        // [GIVEN] Gen. Recurring Journal Template with "Unlink Inc. Doc On Posting" option
        // Bug 573613: "Unlink Inc. Doc On Posting" option must work right for the recurring journal
        InsertGenJnlTemplateWithUnlinkIncDocOption(GenJnlTemplate);
        LibraryERM.CreateRecurringBatchName(GenJnlBatch, GenJnlTemplate.Name);
        // [GIVEN] General two recurring journal lines with template and batch
        // [GIVEN] Incoming document is assigned to each general journal line through the "Incoming Document Entry No." field
        CreateRecurringJournalLines(GenJournalLine, GenJnlBatch);

        // [WHEN] Post general journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Incoming Document Entry No. is blank in both Gen. Journal Lines
        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.Findset();
        repeat
            GenJournalLine.TestField("Incoming Document Entry No.", 0);
        until GenJournalLine.Next() = 0;
    end;

    [Test]
    procedure CannotSetUnlinkIncDocOnPostingOnNonRecurringGenJnlTemplate()
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        // [SCENARIO 573613] Stan cannot enable the "Unlink Inc. Doc On Posting" option on non-recurring general journal template

        // [GIVEN] Non-recurring general journal template
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);

        // [WHEN] Enable "Unlink Inc. Doc On Posting" option
        asserterror GenJnlTemplate.Validate("Unlink Inc. Doc On Posting", true);

        // [THEN] An error is thrown
        Assert.ExpectedError('Recurring must have a value in Gen. Journal Template');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PurchInvHandler')]
    procedure VerifyIncomingDocumentOnPurchaseInvoiceWhenCommentLineUsed()
    var
        IncomingDocument: Record "Incoming Document";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO 555670] Check purchase invoice and incoming document amount verification process by adding a comment line.
        // [GIVEN] Delete existing purchase header records.
        PurchaseHeader.SetFilter("Incoming Document Entry No.", '<>0');
        PurchaseHeader.DeleteAll();

        // [GIVEN] Create Incoming Document With VAT Amount.
        CreateIncomingDocWithVATAmount(IncomingDocument);

        // [WHEN] Create Purchase Invoice via Incoming Documents.
        IncomingDocument.CreatePurchInvoice();
        IncomingDocument.Modify(true);

        // [THEN] Verify Incomig Document Type as Purchase Invoice.
        IncomingDocument.TestField("Document Type", IncomingDocument."Document Type"::"Purchase Invoice");

        // [WHEN] Create Purchase Header and Purchase Line with Type blank(Comment).
        ModifyPurchaseHeaderAndCreatePurchaseLineWithCommentLine(PurchaseHeader, IncomingDocument);

        // [GIVEN] Open Purchase Invoice Page.
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeader);

        // [THEN] Verify a error occurs when Post action was Invoke.
        asserterror PurchaseInvoice.Post.Invoke();
        Assert.ExpectedError(TotalsMismatchErr);
    end;

    [Test]
    [HandlerFunctions('GLPostingPreviewPageHandler,GetSpecificLineFromTemplateListHandler')]
    [Scope('OnPrem')]
    procedure NoErrorOnPostingWhenAttachTheIncomingDoc()
    var
        GenJournalLine: Record "Gen. Journal Line";
        IncomingDocument: Record "Incoming Document";
        TestGenJnlPostPreview: Codeunit "Test Gen. Jnl. Post Preview";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 560363] The changes to the Gen. Journal Line record can be saved if you try to Preview Posting a Payment journal with a Incoming Attachment on line
        BindSubscription(TestGenJnlPostPreview);

        // [GIVEN] Initialize the Incoming Document
        LibraryIncomingDocuments.InitIncomingDocuments();

        // [GIVEN] Update Incoming document
        UpdateIncomingDocumentsSetup();

        // [GIVEN] Create Incoming document with attachment
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);

        // [GIVEN] Create General Journal Line of Vendor
        LibraryJournals.CreateGenJournalLineWithBatch(
                 GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
                 LibraryPurchase.CreateVendorNo(), LibraryRandom.RandDecInRange(10, 10000, 2));

        // [GIVEN] Set Payment Template on Gen. Journal Template
        SetPaymentTypeJournalTemplate(GenJournalLine);

        // [GIVEN] Update Incoming document Entry No. on Gen. Journal Line
        GenJournalLine.Validate("Incoming Document Entry No.", IncomingDocument."Entry No.");
        GenJournalLine.Modify(true);

        // [GIVEN] Commit all the change before open the Payment Journal page
        Commit();

        // [GIVEN] Enqueue the Gen. Journal Template
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");

        // [WHEN] Open the payment Journal page and go to created record
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.Value := GenJournalLine."Journal Batch Name";
        PaymentJournal.GoToRecord(GenJournalLine);

        // [WHEN] Preview the Payment journal
        PaymentJournal.Preview.Invoke();

        // [THEN] Close the Posting preview page without any issue
        PaymentJournal.Close();

        //[THEN]  Variable storage should be empty.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesInvHandler,IncomingDocumentsLookupHandler')]
    procedure AttachIncomingDocumentsNotCalledForReminders()
    var
        Customer: Record Customer;
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IssuedReminderHeader: Record "Issued Reminder Header";
        SalesHeader: Record "Sales Header";
        SendEmailMock: Codeunit "Send Email Mock";
        IssuedReminder: TestPage "Issued Reminder";
        DocumentNo: Code[20];
        FileName: Text;
    begin
        // [GIVEN] Delete existing sales header 
        SalesHeader.SetFilter("Incoming Document Entry No.", '<>0');
        SalesHeader.DeleteAll();

        // [GIVEN] Create Customer with Reminder Terms.
        CreateCustomerWithReminderTerms(Customer);

        // [GIVEN] Create a new Incoming Document.
        CreateNewIncomingDocument(IncomingDocument);

        // [GIVEN] Attach file on Incoming Document.
        IncomingDocument.Release();
        IncomingDocument.Modify(true);
        FileName := CreateDummyFile('xml');
        ImportAttachToIncomingDoc(IncomingDocumentAttachment, FileName);

        // [WHEN] Create a new Sales Invoice from Incoming Document.
        IncomingDocument.CreateSalesInvoice();  // Opens page 43 "Sales Invoice"
        IncomingDocument.Modify(true);
        IncomingDocument.TestField("Document Type", IncomingDocument."Document Type"::"Sales Invoice");

        // [THEN] Verify new Sales Invoice was created.
        SalesHeader.FindFirst();
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.TestField("Incoming Document Entry No.", IncomingDocument."Entry No.");

        // [GIVEN] Open the Sales Invoice and attach the Incoming Document to it.
        OpenSalesInvoiceAndAssignIncomingDoc(IncomingDocument."Entry No.", Customer."No.");

        // [GIVEN] Create a Sales Line and post the existing Sales Invoice.
        DocumentNo := CreateSalesLineAndPost(SalesHeader);

        // [GIVEN] Create a new Issued Reminder.
        CreateIssuedReminder(IssuedReminderHeader, Customer."No.", DocumentNo);

        // [WHEN] Send Email from Issued Reminder Page. 
        BindSubscription(SendEmailMock);
        SendEmailMock.AddSupportedScenario(Enum::"Email Scenario"::Reminder);
        IssuedReminder.OpenEdit();
        IssuedReminder.GoToRecord(IssuedReminderHeader);
        IssuedReminder."Send by &Email".Invoke();
        Commit();
        UnbindSubscription(SendEmailMock);

        // [THEN] Verify the number of attachments in the sent email from the Issued Reminder page.
        VerifyReminderMailWithAttachmentSentForCustomer(Customer, SendEmailMock);
    end;

    local procedure SetPaymentTypeJournalTemplate(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(GenJournalLine."Journal Template Name");
        GenJournalTemplate."Page ID" := PAGE::"Payment Journal";
        GenJournalTemplate.Type := GenJournalTemplate.Type::Payments;
        GenJournalTemplate.Modify();
    end;

    local procedure InsertIncomingDocumentAttachment(IncomingDocument: Record "Incoming Document"): Integer
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        LineNo: Integer;
    begin
        LineNo := 10000;
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        if IncomingDocumentAttachment.FindLast() then
            LineNo += IncomingDocumentAttachment."Line No.";

        IncomingDocumentAttachment.Init();
        IncomingDocumentAttachment."Incoming Document Entry No." := IncomingDocument."Entry No.";
        IncomingDocumentAttachment."Line No." := LineNo;
        IncomingDocumentAttachment.Name := LibraryUtility.GenerateGUID();
        IncomingDocumentAttachment.Insert(true);
        exit(LineNo);
    end;

    local procedure InsertGenJnlTemplateWithUnlinkIncDocOption(var GenJnlTemplate: Record "Gen. Journal Template")
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        GenJnlTemplate.Validate(Recurring, true);
        GenJnlTemplate.Validate("Force Doc. Balance", false);
        GenJnlTemplate.Validate("Unlink Inc. Doc On Posting", true);
        GenJnlTemplate.Modify(true);
    end;

    local procedure CreateIncomingDocWithVATAmount(var IncomingDocument: Record "Incoming Document")
    begin
        CreateIncomingDocumentWithoutAttachments(IncomingDocument);

        IncomingDocument.Description := CreateGuid();
        IncomingDocument.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        IncomingDocument.Validate("Amount Incl. VAT", LibraryRandom.RandIntInRange(100, 200));
        IncomingDocument.Validate("Amount Excl. VAT", IncomingDocument."Amount Incl. VAT" - LibraryRandom.RandInt(50));
        IncomingDocument.Validate("VAT Amount", IncomingDocument."Amount Incl. VAT" - IncomingDocument."Amount Excl. VAT");
        IncomingDocument.Modify(true);
    end;

    local procedure ModifyPurchaseHeaderAndCreatePurchaseLineWithCommentLine(var PurchaseHeader: Record "Purchase Header"; IncomingDocument: Record "Incoming Document")
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
            Item,
            LibraryRandom.RandIntInRange(1000, 2000),
            LibraryRandom.RandIntInRange(3000, 4000));

        PurchaseHeader.FindFirst();
        PurchaseHeader.TestField("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.TestField("Incoming Document Entry No.", IncomingDocument."Entry No.");
        PurchaseHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Currency Code", IncomingDocument."Currency Code");
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::" ",
            '',
            0);
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::Item,
            Item."No.",
            LibraryRandom.RandInt(10));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure IncomingDocumentsLookupHandler(var IncomingDocuments: TestPage "Incoming Documents")
    begin
        IncomingDocuments.Last();
        IncomingDocuments.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure IncomingDocumentsLookupHandlerPrevRec(var IncomingDocuments: TestPage "Incoming Documents")
    begin
        IncomingDocuments.Previous();
        IncomingDocuments.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure IncomingDocumentCardHandler(var IncomingDocumentCard: TestPage "Incoming Document")
    begin
        IncomingDocumentCard.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Question, '');
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    var
        ActualMessageVariant: Variant;
        ActualMessage: Text;
    begin
        LibraryVariableStorage.Dequeue(ActualMessageVariant);
        ActualMessage := ActualMessageVariant;
        Assert.IsTrue(StrPos(Message, ActualMessage) > 0, '');
    end;

    [HyperlinkHandler]
    [Scope('OnPrem')]
    procedure HyperlinkHandler(MessageTxt: Text)
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLPostingPreviewPageHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    begin
        GLPostingPreview.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetSpecificLineFromTemplateListHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.Filter.SetFilter(Name, LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateList.Last();
        GeneralJournalTemplateList.OK().Invoke();
    end;

    local procedure CreateIncomingDocument(var IncomingDocument: Record "Incoming Document"; Description: Text[50]; ProcessedState: Boolean)
    begin
        CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument.Description := Description;
        IncomingDocument.Processed := ProcessedState;
        IncomingDocument.Modify();
    end;

    local procedure CreateCustomerWithReminderTerms(var Customer: Record Customer)
    var
        ReminderLevel: Record "Reminder Level";
        ReminderTerms: Record "Reminder Terms";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateReminderTerms(ReminderTerms);
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTerms.Code);
        Evaluate(ReminderLevel."Grace Period", '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        ReminderLevel.Validate("Additional Fee (LCY)", LibraryRandom.RandInt(10));
        ReminderLevel.Validate("Calculate Interest", true);
        ReminderLevel.Modify(true);

        Customer.Validate("Reminder Terms Code", ReminderTerms.Code);
        Customer.Modify(true);
    end;

    local procedure OpenSalesInvoiceAndAssignIncomingDoc(EntryNo: Integer; CustomerNo: Code[20])
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.Filter.SetFilter("Incoming Document Entry No.", Format(EntryNo));
        SalesInvoice."Sell-to Customer No.".SetValue(CustomerNo);
        SalesInvoice.SelectIncomingDoc.Invoke();
        SalesInvoice.Close();
    end;

    local procedure CreateSalesLineAndPost(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item,
            LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(1000, 2000));
        SalesLine.Modify(true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        exit(DocumentNo);
    end;

    local procedure CreateIssuedReminder(var IssuedReminderHeader: Record "Issued Reminder Header"; CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        ReminderIssue: Codeunit "Reminder-Issue";
        ReminderHeaderNo: Code[20];
    begin
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustomerNo);
        ReminderHeader.Modify(true);

        LibraryERM.CreateReminderLine(ReminderLine, ReminderHeader."No.", ReminderLine.Type::"Customer Ledger Entry");
        ReminderLine.Validate("Document No.", DocumentNo);
        ReminderLine.Modify(true);
        ReminderHeaderNo := ReminderHeader."No.";
        ReminderIssue.Set(ReminderHeader, false, ReminderHeader."Document Date");
        LibraryERM.RunReminderIssue(ReminderIssue);

        IssuedReminderHeader.SetRange("Pre-Assigned No.", ReminderHeaderNo);
        IssuedReminderHeader.FindFirst();
        IssuedReminderHeader.Rename(DocumentNo);
    end;

    local procedure VerifyReminderMailWithAttachmentSentForCustomer(var Customer: Record Customer; SendEmailMock: Codeunit "Send Email Mock")
    var
        TempEmailItemSent: Record "Email Item" temporary;
        TempBlobList: Codeunit "Temp Blob List";
        AttachmentNames: List of [Text];
    begin
        SendEmailMock.GetEmailsSent(TempEmailItemSent);
        TempEmailItemSent.SetRange("Send to", Customer."E-Mail");
        Assert.IsTrue(TempEmailItemSent.FindFirst(), EmailNotSentErr);
        Assert.IsTrue(TempEmailItemSent.HasAttachments(), NoAttachmentsErr);
        TempEmailItemSent.GetAttachments(TempBlobList, AttachmentNames);
        Assert.AreEqual(1, TempBlobList.Count(), NoOfAttachmentsSameErr);
    end;
}

