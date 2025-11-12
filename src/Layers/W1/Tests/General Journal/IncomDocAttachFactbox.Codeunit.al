codeunit 134408 "Incom. Doc. Attach. FactBox"
{
    // We don't ship this test codeunit due to UI interactions in run via TestTool.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Incoming Document] [Attachment] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPlainTextFile: Codeunit "Library - Plain Text File";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        UnexpectedFileNameNoErr: Label 'Unexpected number of stored file names.';
        MainAttachmentErr: Label 'Main Attachment must be enabled.';

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournal_Multiline_Attach_Prev_Next()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournalTestPage: TestPage "General Journal";
    begin
        // [FEATURE] [General Journal]
        // [SCENARIO 320295] Stan adds an attachment to newly created general journal line.

        // Stan opens empty journal.
        // Stan specifies "Account Type" = "G/L Account" and newly "Account No." = "G/L Account" => new line "Line[1]" saved to DB
        // Stan clicks "UploadMainAttachment" on Incoming Document Attachment Factbox
        // Stan attaches File "A" to the "Line[1]"
        // Stan finds "UploadMainAttachment" is disabled because main attachment is already uploaded, and "SupportAttachments" is enabled. 
        // Stan moves to the second line.
        // Stan specifies "Account Type" = "G/L Account" and newly "Account No." = "G/L Account" => new line "Line[2]" saved to DB
        // Stan clicks "UploadMainAttachment" on Incoming Document Attachment Factbox
        // Stan attaches File "B" to the "Line[2]"
        // Stan finds "UploadMainAttachment" is disabled because main attachment is already uploaded, and "SupportAttachments" is enabled. 

        CreateGeneralJournalBatch(GenJournalLine, GenJournalTemplate.Type::General);

        GeneralJournalTestPage.Trap();

        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        GeneralJournalTestPage."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        GeneralJournalTestPage."Account No.".SetValue(LibraryERM.CreateGLAccountNoWithDirectPosting());
        PrepareAttachmentRecordForGenJournalLine(GenJournalLine);
        GeneralJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Invoke();
        GeneralJournalTestPage.New();
        GeneralJournalTestPage."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        GeneralJournalTestPage."Account No.".SetValue(LibraryERM.CreateGLAccountNoWithDirectPosting());
        PrepareAttachmentRecordForGenJournalLine(GenJournalLine);
        GeneralJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Invoke();

        // We saved attached file names in Library - Variable Storage.
        Assert.RecordCount(GenJournalLine, LibraryVariableStorage.Length());
        Assert.AreEqual(2, LibraryVariableStorage.Length(), UnexpectedFileNameNoErr);

        // We return to first line and check the correct file is shown in "Incoming Document Attachment Factbox" (File "A")
        GeneralJournalTestPage.Previous();
        Assert.IsFalse(GeneralJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Enabled(), 'UploadMainAttachment should be disabled because main attachment is already uploaded.');
        // [TODO] For now the testability of the "fileuploaded" is not possible. Add it back when it is possible.
        // Assert.IsTrue(GeneralJournalTestPage.IncomingDocAttachFactBox.UploadSupportAttachments.Enabled(), 'SupportAttachments should be enabled because main attachment is already uploaded.');
        GeneralJournalTestPage.IncomingDocAttachFactBox.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        // We move to second line and check the correct file is shown in "Incoming Document Attachment Factbox" (File "B")
        GeneralJournalTestPage.Next();
        Assert.IsFalse(GeneralJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Enabled(), 'UploadMainAttachment should be disabled because main attachment is already uploaded.');
        // [TODO] For now the testability of the "fileuploaded" is not possible. Add it back when it is possible.
        // Assert.IsTrue(GeneralJournalTestPage.IncomingDocAttachFactBox.UploadSupportAttachments.Enabled(), 'SupportAttachments should be enabled because main attachment is already uploaded.');
        GeneralJournalTestPage.IncomingDocAttachFactBox.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        GeneralJournalTestPage.Next();
        GeneralJournalTestPage."Account No.".AssertEquals('');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJournal_Multiline_Attach_Prev_Next()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournalTestPage: TestPage "Payment Journal";
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO 320295] Stan adds an attachment to newly created payment journal line.

        // Stan opens empty journal.
        // Stan specifies "Account Type" = "G/L Account" and newly "Account No." = "G/L Account" => new line "Line[1]" saved to DB
        // Stan clicks "UploadMainAttachment" on Incoming Document Attachment Factbox
        // Stan attaches File "A" to the "Line[1]"
        // Stan finds "UploadMainAttachment" is disabled because main attachment is already uploaded, and "SupportAttachments" is enabled. 
        // Stan moves to the second line.
        // Stan specifies "Account Type" = "G/L Account" and newly "Account No." = "G/L Account" => new line "Line[2]" saved to DB
        // Stan clicks "UploadMainAttachment" on Incoming Document Attachment Factbox
        // Stan attaches File "B" to the "Line[2]"
        // Stan finds "UploadMainAttachment" is disabled because main attachment is already uploaded, and "SupportAttachments" is enabled. 

        CreateGeneralJournalBatch(GenJournalLine, GenJournalTemplate.Type::Payments);

        PaymentJournalTestPage.Trap();

        PAGE.Run(PAGE::"Payment Journal", GenJournalLine);

        PaymentJournalTestPage."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        PaymentJournalTestPage."Account No.".SetValue(LibraryERM.CreateGLAccountNoWithDirectPosting());
        PrepareAttachmentRecordForGenJournalLine(GenJournalLine);
        PaymentJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Invoke();

        PaymentJournalTestPage.New();
        PaymentJournalTestPage."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        PaymentJournalTestPage."Account No.".SetValue(LibraryERM.CreateGLAccountNoWithDirectPosting());
        PrepareAttachmentRecordForGenJournalLine(GenJournalLine);
        PaymentJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Invoke();

        // We saved attached file names in Library - Variable Storage.
        Assert.RecordCount(GenJournalLine, LibraryVariableStorage.Length());
        Assert.AreEqual(2, LibraryVariableStorage.Length(), UnexpectedFileNameNoErr);

        // We return to first line and check the correct file is shown in "Incoming Document Attachment Factbox" (File "A")
        PaymentJournalTestPage.Previous();
        PaymentJournalTestPage.IncomingDocAttachFactBox.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(PaymentJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Enabled(), 'UploadMainAttachment should be disabled because main attachment is already uploaded.');
        // [TODO] For now the testability of the "fileuploaded" is not possible. Add it back when it is possible.
        // Assert.IsTrue(PaymentJournalTestPage.IncomingDocAttachFactBox.UploadSupportAttachments.Enabled(), 'SupportAttachments should be enabled because main attachment is already uploaded.');
        // We move to second line and check the correct file is shown in "Incoming Document Attachment Factbox" (File "B")
        PaymentJournalTestPage.Next();
        PaymentJournalTestPage.IncomingDocAttachFactBox.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(PaymentJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Enabled(), 'UploadMainAttachment should be disabled because main attachment is already uploaded.');
        // [TODO] For now the testability of the "fileuploaded" is not possible. Add it back when it is possible.
        // Assert.IsTrue(PaymentJournalTestPage.IncomingDocAttachFactBox.UploadSupportAttachments.Enabled(), 'SupportAttachments should be enabled because main attachment is already uploaded.');
        PaymentJournalTestPage.Next();
        PaymentJournalTestPage."Account No.".AssertEquals('');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseJournal_Multiline_Attach_Prev_Next()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseJournalTestPage: TestPage "Purchase Journal";
    begin
        // [FEATURE] [Purchase Journal]
        // [SCENARIO 320295] Stan adds an attachment to newly created purchase journal line.

        // Stan opens empty journal.
        // Stan specifies "Account Type" = "G/L Account" and newly "Account No." = "G/L Account" => new line "Line[1]" saved to DB
        // Stan clicks "UploadMainAttachment" on Incoming Document Attachment Factbox
        // Stan attaches File "A" to the "Line[1]"
        // Stan finds "UploadMainAttachment" is disabled because main attachment is already uploaded, and "SupportAttachments" is enabled. 
        // Stan moves to the second line.
        // Stan specifies "Account Type" = "G/L Account" and newly "Account No." = "G/L Account" => new line "Line[2]" saved to DB
        // Stan clicks "UploadMainAttachment" on Incoming Document Attachment Factbox
        // Stan attaches File "B" to the "Line[2]"
        // Stan finds "UploadMainAttachment" is disabled because main attachment is already uploaded, and "SupportAttachments" is enabled. 

        CreateGeneralJournalBatch(GenJournalLine, GenJournalTemplate.Type::Purchases);

        PurchaseJournalTestPage.Trap();

        PAGE.Run(PAGE::"Purchase Journal", GenJournalLine);

        PurchaseJournalTestPage."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        PurchaseJournalTestPage."Account No.".SetValue(LibraryERM.CreateGLAccountNoWithDirectPosting());
        PrepareAttachmentRecordForGenJournalLine(GenJournalLine);
        PurchaseJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Invoke();

        PurchaseJournalTestPage.New();
        PurchaseJournalTestPage."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        PurchaseJournalTestPage."Account No.".SetValue(LibraryERM.CreateGLAccountNoWithDirectPosting());
        PrepareAttachmentRecordForGenJournalLine(GenJournalLine);
        PurchaseJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Invoke();


        // We saved attached file names in Library - Variable Storage.
        Assert.RecordCount(GenJournalLine, LibraryVariableStorage.Length());
        Assert.AreEqual(2, LibraryVariableStorage.Length(), UnexpectedFileNameNoErr);

        // We return to first line and check the correct file is shown in "Incoming Document Attachment Factbox" (File "A")
        PurchaseJournalTestPage.Previous();
        PurchaseJournalTestPage.IncomingDocAttachFactBox.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(PurchaseJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Enabled(), 'UploadMainAttachment should be disabled because main attachment is already uploaded.');
        // [TODO] For now the testability of the "fileuploaded" is not possible. Add it back when it is possible.
        // Assert.IsTrue(PurchaseJournalTestPage.IncomingDocAttachFactBox.UploadSupportAttachments.Enabled(), 'SupportAttachments should be enabled because main attachment is already uploaded.');
        // We move to second line and check the correct file is shown in "Incoming Document Attachment Factbox" (File "B")
        PurchaseJournalTestPage.Next();
        PurchaseJournalTestPage.IncomingDocAttachFactBox.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        PurchaseJournalTestPage.Next();
        Assert.IsFalse(PurchaseJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Enabled(), 'UploadMainAttachment should be disabled because main attachment is already uploaded.');
        // [TODO] For now the testability of the "fileuploaded" is not possible. Add it back when it is possible.
        // Assert.IsTrue(PurchaseJournalTestPage.IncomingDocAttachFactBox.UploadSupportAttachments.Enabled(), 'SupportAttachments should be enabled because main attachment is already uploaded.');
        PurchaseJournalTestPage."Account No.".AssertEquals('');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesJournal_Multiline_Attach_Prev_Next()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        SalesJournalTestPage: TestPage "Sales Journal";
    begin
        // [FEATURE] [Sales Journal]
        // [SCENARIO 320295] Stan adds an attachment to newly created sales journal line.

        // Stan opens empty journal.
        // Stan specifies "Account Type" = "G/L Account" and newly "Account No." = "G/L Account" => new line "Line[1]" saved to DB
        // Stan clicks "UploadMainAttachment" on Incoming Document Attachment Factbox
        // Stan attaches File "A" to the "Line[1]"
        // Stan finds "UploadMainAttachment" is disabled because main attachment is already uploaded, and "SupportAttachments" is enabled. 
        // Stan moves to the second line.
        // Stan specifies "Account Type" = "G/L Account" and newly "Account No." = "G/L Account" => new line "Line[2]" saved to DB
        // Stan clicks "UploadMainAttachment" on Incoming Document Attachment Factbox
        // Stan attaches File "B" to the "Line[2]"
        // Stan finds "UploadMainAttachment" is disabled because main attachment is already uploaded, and "SupportAttachments" is enabled. 

        CreateGeneralJournalBatch(GenJournalLine, GenJournalTemplate.Type::Sales);

        SalesJournalTestPage.Trap();

        PAGE.Run(PAGE::"Sales Journal", GenJournalLine);

        SalesJournalTestPage."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        SalesJournalTestPage."Account No.".SetValue(LibraryERM.CreateGLAccountNoWithDirectPosting());
        PrepareAttachmentRecordForGenJournalLine(GenJournalLine);
        SalesJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Invoke();

        SalesJournalTestPage.New();
        SalesJournalTestPage."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        SalesJournalTestPage."Account No.".SetValue(LibraryERM.CreateGLAccountNoWithDirectPosting());
        PrepareAttachmentRecordForGenJournalLine(GenJournalLine);
        SalesJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Invoke();

        // We saved attached file names in Library - Variable Storage.
        Assert.RecordCount(GenJournalLine, LibraryVariableStorage.Length());
        Assert.AreEqual(2, LibraryVariableStorage.Length(), UnexpectedFileNameNoErr);

        // We return to first line and check the correct file is shown in "Incoming Document Attachment Factbox" (File "A")
        SalesJournalTestPage.Previous();
        SalesJournalTestPage.IncomingDocAttachFactBox.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(SalesJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Enabled(), 'UploadMainAttachment should be disabled because main attachment is already uploaded.');
        // [TODO] For now the testability of the "fileuploaded" is not possible. Add it back when it is possible.
        // Assert.IsTrue(SalesJournalTestPage.IncomingDocAttachFactBox.UploadSupportAttachments.Enabled(), 'SupportAttachments should be enabled because main attachment is already uploaded.');
        // We move to second line and check the correct file is shown in "Incoming Document Attachment Factbox" (File "B")
        SalesJournalTestPage.Next();
        SalesJournalTestPage.IncomingDocAttachFactBox.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(SalesJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Enabled(), 'UploadMainAttachment should be disabled because main attachment is already uploaded.');
        // [TODO] For now the testability of the "fileuploaded" is not possible. Add it back when it is possible.
        // Assert.IsTrue(SalesJournalTestPage.IncomingDocAttachFactBox.UploadSupportAttachments.Enabled(), 'SupportAttachments should be enabled because main attachment is already uploaded.');
        SalesJournalTestPage.Next();
        SalesJournalTestPage."Account No.".AssertEquals('');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashReceiptJournal_Multiline_Attach_Prev_Next()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournalTestPage: TestPage "Cash Receipt Journal";
    begin
        // [FEATURE] [Cash Receipt Journal]
        // [SCENARIO 320295] Stan adds an attachment to newly created cash receipt journal line.

        // Stan opens empty journal.
        // Stan specifies "Account Type" = "G/L Account" and newly "Account No." = "G/L Account" => new line "Line[1]" saved to DB
        // Stan clicks "UploadMainAttachment" on Incoming Document Attachment Factbox
        // Stan attaches File "A" to the "Line[1]"
        // Stan finds "UploadMainAttachment" is disabled because main attachment is already uploaded, and "SupportAttachments" is enabled. 
        // Stan moves to the second line.
        // Stan specifies "Account Type" = "G/L Account" and newly "Account No." = "G/L Account" => new line "Line[2]" saved to DB
        // Stan clicks "UploadMainAttachment" on Incoming Document Attachment Factbox
        // Stan attaches File "B" to the "Line[2]"
        // Stan finds "UploadMainAttachment" is disabled because main attachment is already uploaded, and "SupportAttachments" is enabled. 

        CreateGeneralJournalBatch(GenJournalLine, GenJournalTemplate.Type::"Cash Receipts");

        CashReceiptJournalTestPage.Trap();

        PAGE.Run(PAGE::"Cash Receipt Journal", GenJournalLine);

        CashReceiptJournalTestPage."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        CashReceiptJournalTestPage."Account No.".SetValue(LibraryERM.CreateGLAccountNoWithDirectPosting());
        PrepareAttachmentRecordForGenJournalLine(GenJournalLine);
        CashReceiptJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Invoke();

        CashReceiptJournalTestPage.New();
        CashReceiptJournalTestPage."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        CashReceiptJournalTestPage."Account No.".SetValue(LibraryERM.CreateGLAccountNoWithDirectPosting());
        PrepareAttachmentRecordForGenJournalLine(GenJournalLine);
        CashReceiptJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Invoke();

        // We saved attached file names in Library - Variable Storage.
        Assert.RecordCount(GenJournalLine, LibraryVariableStorage.Length());
        Assert.AreEqual(2, LibraryVariableStorage.Length(), UnexpectedFileNameNoErr);

        // We return to first line and check the correct file is shown in "Incoming Document Attachment Factbox" (File "A")
        CashReceiptJournalTestPage.Previous();
        CashReceiptJournalTestPage.IncomingDocAttachFactBox.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(CashReceiptJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Enabled(), 'UploadMainAttachment should be disabled because main attachment is already uploaded.');
        // [TODO] For now the testability of the "fileuploaded" is not possible. Add it back when it is possible.
        // Assert.IsTrue(CashReceiptJournalTestPage.IncomingDocAttachFactBox.UploadSupportAttachments.Enabled(), 'SupportAttachments should be enabled because main attachment is already uploaded.');
        // We move to second line and check the correct file is shown in "Incoming Document Attachment Factbox" (File "B")
        CashReceiptJournalTestPage.Next();
        CashReceiptJournalTestPage.IncomingDocAttachFactBox.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(CashReceiptJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Enabled(), 'UploadMainAttachment should be disabled because main attachment is already uploaded.');
        // [TODO] For now the testability of the "fileuploaded" is not possible. Add it back when it is possible.
        // Assert.IsTrue(CashReceiptJournalTestPage.IncomingDocAttachFactBox.UploadSupportAttachments.Enabled(), 'SupportAttachments should be enabled because main attachment is already uploaded.');
        CashReceiptJournalTestPage.Next();
        CashReceiptJournalTestPage."Account No.".AssertEquals('');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('YesConfirmHandler')]
    procedure AttachIncomingDocFilesShouldNotGiveErrorWhenCreatePurchDocUsingRecurringLines()
    var
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        StandardPurchaseCode: Record "Standard Purchase Code";
        VendorCard: TestPage "Vendor Card";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [GIVEN] Create VAT Business Posting Group.
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);

        // [GIVEN] Create VAT Product Posting Group.
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);

        // [GIVEN] Create VAT Posting Setup.
        CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProdPostingGroup);

        // [GIVEN] Create Vendor and Validate VAT Bus. Posting Group.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup.Code);
        Vendor.Modify(true);

        // [GIVEN] Create GL Account and Validate VAT Prod. Posting Group.
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup.Code);
        GLAccount.Modify(true);

        // [GIVEN] Create Standard Purchase Code.
        CreateStandardPurchaseCode(StandardPurchaseCode, GLAccount, Vendor);

        // [GIVEN] Open Vendor Card.
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        // [GIVEN] Run New Purchase Invoice action from Vendor Card.
        PurchaseInvoice.Trap();
        VendorCard.NewPurchaseInvoice.Invoke();

        // [WHEN] Assign Vendor Invoice No. in created Purchase Invoice.
        PurchaseInvoice."Vendor Invoice No.".Activate();
        Commit();

        // [VERIFY] Verify no error is thrown when run Import New action from Incoming Doc Attach FactBox.
        PurchaseInvoice.IncomingDocAttachFactBox.UploadMainAttachment.Invoke();

        PurchaseInvoice.Close();
    end;

    [Test]
    procedure MainAttachmentEnabledAfterPostingGeneralJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournalTestPage: TestPage "General Journal";
    begin
        // [SCENARIO 558845] Main Attachment is enabled after posting the General Journal.

        // [GIVEN] Create General Journal Batch With General type.
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalTemplate.Type::General);

        // [GIVEN] Create General Journal Line.
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch."Name",
            GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNoWithDirectPosting(),
            LibraryRandom.RandInt(5));

        // [GIVEN] Validate "Bal. Account No.".
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalLine.Modify(true);

        // [GIVEN] Post General Journal.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Open General Journal.
        GeneralJournalTestPage.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        // [GIVEN] Prepare Attachment Record For General Journal and Validate "Account No.".
        PrepareAttachmentRecordForGenJournalLine(GenJournalLine);
        GeneralJournalTestPage."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        GeneralJournalTestPage."Account No.".SetValue(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [THEN] Upload Main Attachment action must be enabled.
        Assert.AreEqual(GeneralJournalTestPage.IncomingDocAttachFactBox.UploadMainAttachment.Enabled(), true, MainAttachmentErr);
    end;

    [Test]
    [HandlerFunctions('GLPostingPreviewHandler')]
    procedure PaymentJournalPreviewPostingWithMainAttachmentInOneLineAndSupportingAttachmentOnOtherLine()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournalPage: TestPage "Payment Journal";
        DocumentNo: Text;
    begin
        // [SCENARIO 596981] Verify Payment Journal Preview Posting without any error when Main Attachment in One Line and Supporting Attachment on Other Line.

        // [GIVEN] Create General Journal Batch.
        CreateGeneralJournalBatch(GenJournalLine, GenJournalTemplate.Type::Payments);
        DocumentNo := LibraryRandom.RandText(9) + Format(LibraryRandom.RandIntInRange(1, 1));
        PaymentJournalPage.Trap();
        Page.Run(Page::"Payment Journal", GenJournalLine);

        // [GIVEN] Create First Line.
        PaymentJournalPage."Document No.".SetValue(DocumentNo);
        PaymentJournalPage."Account Type".SetValue(GenJournalLine."Account Type"::Vendor);
        PaymentJournalPage."Account No.".SetValue(LibraryPurchase.CreateVendorNo());
        PaymentJournalPage."Bal. Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        PaymentJournalPage."Bal. Account No.".SetValue(LibraryERM.CreateGLAccountNoWithDirectPosting());
        PaymentJournalPage.Amount.SetValue(LibraryRandom.RandInt(10000));

        // [GIVEN] Run Import New action from Incoming Doc Attach FactBox.
        PrepareAttachmentRecordForGenJournalLine(GenJournalLine);
        PaymentJournalPage.IncomingDocAttachFactBox.UploadMainAttachment.Invoke();

        // [GIVEN] Create Second Line.
        PaymentJournalPage.New();
        PaymentJournalPage."Document No.".SetValue(IncStr(DocumentNo));
        PaymentJournalPage."Account Type".SetValue(GenJournalLine."Account Type"::Vendor);
        PaymentJournalPage."Account No.".SetValue(LibraryPurchase.CreateVendorNo());
        PaymentJournalPage."Bal. Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        PaymentJournalPage."Bal. Account No.".SetValue(LibraryERM.CreateGLAccountNoWithDirectPosting());
        PaymentJournalPage.Amount.SetValue(LibraryRandom.RandInt(10000));

        // [WHEN] Run Import New action from Incoming Doc Attach FactBox.
        PrepareAttachmentRecordForGenJournalLine(GenJournalLine);
        PaymentJournalPage.IncomingDocAttachFactBox.UploadMainAttachment.Invoke();

        // [THEN] Go to the next line.
        // No Error occured.
        PaymentJournalPage.Next();

        // No errors occur when previewing a posting in the Payment Journal, with the main attachment on one line and the supporting attachment on another line.
        PaymentJournalPage.Preview.Invoke();
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalLine: Record "Gen. Journal Line"; GenJournalTemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalTemplateType);

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Commit();
    end;

    local procedure PrepareAttachmentRecordForGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
        FileManagement: Codeunit "File Management";
        ContentOutStream: OutStream;
        BlobInStream: InStream;
        RecRef: RecordRef;
        FileName: Text;
    begin
        RecRef.GetTable(GenJournalLine);
        RecRef.FindLast();

        IncomingDocumentAttachment.SetFiltersFromMainRecord(RecRef, IncomingDocumentAttachment);

        FileName := LibraryPlainTextFile.Create('txt');
        LibraryPlainTextFile.AddLine(LibraryUtility.GenerateGUID());
        LibraryPlainTextFile.Close();

        FileManagement.BLOBImportFromServerFile(TempBlob, FileName);

        TempBlob.CreateInStream(BlobInStream);
        IncomingDocumentAttachment.Content.CreateOutStream(ContentOutStream);
        CopyStream(ContentOutStream, BlobInStream);
        ImportAttachmentIncDoc.ImportAttachment(IncomingDocumentAttachment, FileName);

        LibraryVariableStorage.Enqueue(FileManagement.GetFileNameWithoutExtension(FileName));
        Commit();
    end;

    local procedure CreateVATPostingSetup(
      var VATPostingSetup: Record "VAT Posting Setup";
      VATBusPostingGroup: Record "VAT Business Posting Group";
      VATProdPostingGroup: Record "VAT Product Posting Group")
    begin
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateStandardPurchaseCode(
        var StandardPurchaseCode: Record "Standard Purchase Code";
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor)
    var
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
    begin
        LibraryPurchase.CreateStandardPurchaseCode(StandardPurchaseCode);

        LibraryPurchase.CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode.Code);
        StandardPurchaseLine.Validate(Type, StandardPurchaseLine.Type::"G/L Account");
        StandardPurchaseLine.Validate("No.", GLAccount."No.");
        StandardPurchaseLine.Modify(true);

        LibraryPurchase.CreateVendorPurchaseCode(StandardVendorPurchaseCode, Vendor."No.", StandardPurchaseCode.Code);
        StandardVendorPurchaseCode.Validate("Insert Rec. Lines On Invoices", StandardVendorPurchaseCode."Insert Rec. Lines On Invoices"::Automatic);
        StandardVendorPurchaseCode.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    procedure GLPostingPreviewHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    begin
        GLPostingPreview.OK().Invoke();
    end;
}

