codeunit 134417 "ERM Delete Documents"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ArchiveManagement: Codeunit ArchiveManagement;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        AllowPostedDocumentDeletionDate: Date;
        ValidationErr: Label 'The expected and actual values are equal.';
        SalesDocDeletionErr: Label 'You cannot delete posted sales documents that are posted after %1.';
        PurchDocDeletionErr: Label 'You cannot delete posted purchase documents that are posted after %1.';
        DocumentStillExistsErr: Label 'The document still exists', Locked = true;
        CannotDeleteSalesOrderLineErr: Label 'You cannot delete the order line because it is associated with purchase order %1 line %2';
        AllowSalesDocumentDeletionBeforeBlankErr: Label 'The date %1 must be set on the page %2 before deleting sales documents.', Comment = '%1 = Field name, %2 = Page name';
        AllowPurchaseDocumentDeletionBeforeBlankErr: Label 'The date %1 must be set on the page %2 before deleting purchase documents.', Comment = '%1 = Field name, %2 = Page name';

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseAndArchivePurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        NoOfArchivedVerAfterRelease: Integer;
    begin
        // [FEATURE] [Document Archive]
        // [SCENARIO] Check the functionality of Purchase Quote Archive.

        // [GIVEN] Create Purchase Quote.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Quote);

        // [WHEN] Release and Archive Purchase Quote.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields("No. of Archived Versions");
        NoOfArchivedVerAfterRelease := PurchaseHeader."No. of Archived Versions";
        ArchiveManagement.StorePurchDocument(PurchaseHeader, false);

        // [THEN] Verify Archived Version in Purchase Header Archive.
        FindPurchaseHeaderArchive(PurchaseHeaderArchive, PurchaseHeaderArchive."Document Type"::Quote, PurchaseHeader."No.");
        Assert.AreEqual(0, NoOfArchivedVerAfterRelease, ValidationErr);  // Value important for verification.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeOrderFromPurchaseQuote()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchArchiveQuotes: Option;
    begin
        // [FEATURE] [Document Archive]
        // [SCENARIO] Check the functionality of Purchase Quote while making it into Order.

        // [GIVEN] Create Purchase Quote.
        Initialize();
        PurchArchiveQuotes := SetPurchArchiveQuotes(PurchasesPayablesSetup."Archive Quotes"::Always);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Quote);

        // [WHEN] Make an Order of Quote.
        CODEUNIT.Run(CODEUNIT::"Purch.-Quote to Order", PurchaseHeader);

        // [THEN] Verify Item Number,Quantity,Type and Unit of Measure Code in Purchase Quote Archive.
        VerifyPurchaseLineArchive(PurchaseLine, PurchaseHeader);
        Assert.IsFalse(PurchaseHeader.Find(), 'Quote header is not deleted');
        Assert.IsFalse(PurchaseLine.Find(), 'Quote line is not deleted');
        SetPurchArchiveQuotes(PurchArchiveQuotes);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseAndArchivePurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        NoOfArchivedVerAfterRelease: Integer;
    begin
        // [FEATURE] [Document Archive]
        // [SCENARIO] Check the functionality of Purchase Order Archive.

        // [GIVEN] Create Purchase Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // [WHEN] Release and Archive Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields("No. of Archived Versions");
        NoOfArchivedVerAfterRelease := PurchaseHeader."No. of Archived Versions";
        ArchiveManagement.StorePurchDocument(PurchaseHeader, false);

        // [THEN] Verify Archived Version in Purchase Header Archive.
        FindPurchaseHeaderArchive(PurchaseHeaderArchive, PurchaseHeaderArchive."Document Type"::Order, PurchaseHeader."No.");
        Assert.AreEqual(0, NoOfArchivedVerAfterRelease, ValidationErr);  // Value important for verification.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAndPostPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Document Archive]
        // [SCENARIO] Check the functionality of Purchase Order Archive while posting an Order.

        // [GIVEN] Create Purchase Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // [WHEN] Release and Archive Purchase Order and finally posting it.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        ArchiveManagement.StorePurchDocument(PurchaseHeader, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify Item Number,Quantity,Type and Unit of Measure Code in Purchase Order.
        VerifyPurchaseLineArchive(PurchaseLine, PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseAndArchiveSalesQuote()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        OldStockOutWarning: Boolean;
        NoOfArchivedVerAfterRelease: Integer;
    begin
        // [FEATURE] [Document Archive]
        // [SCENARIO] Check the functionality of Sales Quote Archive.

        // [GIVEN] Create Sales Quote.
        Initialize();
        OldStockOutWarning := UpdateStockOutWarning(false);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote);

        // [WHEN] Release and Archive Sales Quote.
        ReleaseAndArchiveSalesDoc(SalesHeader, NoOfArchivedVerAfterRelease);

        // [THEN] Verify Archived Version in Sales Header Archive.
        FindSalesHeaderArchive(SalesHeaderArchive, SalesHeaderArchive."Document Type"::Quote, SalesHeader."No.");
        Assert.AreEqual(0, NoOfArchivedVerAfterRelease, ValidationErr);  // Value important for verification.

        // 4.Tear Down: Set Stockout Warning to original state.
        UpdateStockOutWarning(OldStockOutWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeOrderFromSalesQuote()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OldStockOutWarning: Boolean;
        ArchiveQuotes: Option;
    begin
        // [FEATURE] [Document Archive]
        // [SCENARIO] Check the functionality of Sales Quote Archive while making it into Order.

        // [GIVEN] Create Sales Quote.
        Initialize();
        ArchiveQuotes := SetSalesArchiveQuotes(SalesReceivablesSetup."Archive Quotes"::Always);
        OldStockOutWarning := UpdateStockOutWarning(false);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote);

        // [WHEN] Make an Order of Quote
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order", SalesHeader);

        // [THEN] Verify Item Number,Quantity,Type and Unit of Measure Code in Sales Quote.
        VerifySalesLineArchive(SalesLine, SalesHeader);
        Assert.IsFalse(SalesHeader.Find(), 'Quote header is not deleted');
        Assert.IsFalse(SalesLine.Find(), 'Quote line is not deleted');

        // 4.Tear Down: Set Stockout Warning to original state.
        UpdateStockOutWarning(OldStockOutWarning);
        SetSalesArchiveQuotes(ArchiveQuotes);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeInvoiceFromSalesQuote()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OldStockOutWarning: Boolean;
        ArchiveQuotes: Option;
    begin
        // [FEATURE] [Document Archive]
        // [SCENARIO 426014] Check the functionality of Sales Quote Archive while making it into Invoice.

        // [GIVEN] Create Sales Quote.
        Initialize();
        ArchiveQuotes := SetSalesArchiveQuotes(SalesReceivablesSetup."Archive Quotes"::Always);
        OldStockOutWarning := UpdateStockOutWarning(false);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote);

        // [WHEN] Make an Invoice of Quote.
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Invoice", SalesHeader);

        // [THEN] Verify Item Number,Quantity,Type and Unit of Measure Code in Sales Quote.
        VerifySalesLineArchive(SalesLine, SalesHeader);
        Assert.IsFalse(SalesHeader.Find(), 'Quote header is not deleted');
        Assert.IsFalse(SalesLine.Find(), 'Quote line is not deleted');

        // 4.Tear Down: Set Stockout Warning to original state.
        UpdateStockOutWarning(OldStockOutWarning);
        SetSalesArchiveQuotes(ArchiveQuotes);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseAndArchiveSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        OldStockOutWarning: Boolean;
        NoOfArchivedVerAfterRelease: Integer;
    begin
        // [FEATURE] [Document Archive]
        // [SCENARIO] Check the functionality of Sales Order Archive.

        // [GIVEN] Create Sales Order.
        Initialize();
        OldStockOutWarning := UpdateStockOutWarning(false);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // [WHEN] Release and Archive Sales Order.
        ReleaseAndArchiveSalesDoc(SalesHeader, NoOfArchivedVerAfterRelease);

        // [THEN] Verify Archived Version in Sales Header Archive.
        FindSalesHeaderArchive(SalesHeaderArchive, SalesHeaderArchive."Document Type"::Order, SalesHeader."No.");
        Assert.AreEqual(0, NoOfArchivedVerAfterRelease, ValidationErr);  // Value important for verification.

        // 4.Tear Down: Set Stockout Warning to original state.
        UpdateStockOutWarning(OldStockOutWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAndPostSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OldStockOutWarning: Boolean;
    begin
        // [FEATURE] [Document Archive]
        // [SCENARIO] Check the functionality of Sales Order Archive while posting an Order.

        // [GIVEN] Create Sales Order.
        Initialize();
        OldStockOutWarning := UpdateStockOutWarning(false);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // [WHEN] Release and Archive Sales Order and finally posting it.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify Item Number,Quantity,Type and Unit of Measure Code in Sales Order Archive.
        VerifySalesLineArchive(SalesLine, SalesHeader);

        // 4.Tear Down: Set Stockout Warning to original state.
        UpdateStockOutWarning(OldStockOutWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteApprovedInvoicedPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentType: Enum "Purchase Document Type";
    begin
        // [FEATURE] [Purchase] [Approval Management]
        // [SCENARIO 363783] Report "Delete Invoiced Purch. Orders" deletes Approval Entries related to deleted Purchase Order
        // [GIVEN] Invoiced Purchase Order "O"
        Initialize();
        DocumentType := PurchaseHeader."Document Type"::Order;
        ApprovedPurchaseDocumentScenario(DocumentType, PurchaseHeader);
        VerifyApprovalEntriesExist(PurchaseHeader.RecordId);

        // [WHEN] Run Report "Delete Invoiced Purch. Orders"
        RunReport(
          REPORT::"Delete Invoiced Purch. Orders",
          DATABASE::"Purchase Header",
          PurchaseHeader.FieldNo("No."),
          PurchaseHeader."No.");

        // [THEN] "O" deleted
        VerifyPurchaseDocumentDeleted(DocumentType, PurchaseHeader."No.");
        // [THEN] Approval Entries related to "O" are  deleted
        VerifyApprovalEntriesDeleted(PurchaseHeader.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteApprovedInvoicedSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        DocumentType: Enum "Sales Document Type";
    begin
        // [FEATURE] [Sales] [Approval Management]
        // [SCENARIO 363783] Report "Delete Invoiced Sales Orders" deletes Approval Entries related to deleted Sales Order
        // [GIVEN] Invoiced Sales Order "O"
        Initialize();
        DocumentType := SalesHeader."Document Type"::Order;
        ApprovedSalesDocumentScenario(DocumentType, SalesHeader);
        VerifyApprovalEntriesExist(SalesHeader.RecordId);

        // [WHEN] Run Report "Delete Invoiced Sales Orders"
        RunReport(
          REPORT::"Delete Invoiced Sales Orders",
          DATABASE::"Sales Header",
          SalesHeader.FieldNo("No."),
          SalesHeader."No.");

        // [THEN] "O" deleted
        VerifySalesDocumentDeleted(DocumentType, SalesHeader."No.");
        // [THEN] Approval Entries related to "O" are deleted
        VerifyApprovalEntriesDeleted(SalesHeader.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteApprovedInvoicedPurchaseBlanketOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentType: Enum "Purchase Document Type";
    begin
        // [FEATURE] [Purchase] [Approval Management]
        // [SCENARIO 363783] Report "Delete Invd Blnkt Purch Orders" deletes Approval Entries related to deleted Purchase Blanket Order
        // [GIVEN] Invoiced Purchase Blanket Order "O"
        Initialize();
        DocumentType := PurchaseHeader."Document Type"::"Blanket Order";
        ApprovedPurchaseDocumentScenario(DocumentType, PurchaseHeader);
        VerifyApprovalEntriesExist(PurchaseHeader.RecordId);

        // [WHEN] Run Report "Delete Invd Blnkt Purch Orders"
        RunReport(
          REPORT::"Delete Invd Blnkt Purch Orders",
          DATABASE::"Purchase Header",
          PurchaseHeader.FieldNo("No."),
          PurchaseHeader."No.");

        // [THEN] "O" deleted
        VerifyPurchaseDocumentDeleted(DocumentType, PurchaseHeader."No.");
        // [THEN] Approval Entries related to "O" are  deleted
        VerifyApprovalEntriesDeleted(PurchaseHeader.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteApprovedInvoicedSalesBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
        DocumentType: Enum "Sales Document Type";
    begin
        // [FEATURE] [Sales] [Approval Management]
        // [SCENARIO 363783] Report "Delete Invd Blnkt Sales Orders" deletes Approval Entries related to deleted Sales Blanket Order
        // [GIVEN] Invoiced Sales Blanket Order "O"
        Initialize();
        DocumentType := SalesHeader."Document Type"::"Blanket Order";
        ApprovedSalesDocumentScenario(DocumentType, SalesHeader);
        VerifyApprovalEntriesExist(SalesHeader.RecordId);

        // [WHEN] Run Report "Delete Invd Blnkt Sales Orders"
        RunReport(
          REPORT::"Delete Invd Blnkt Sales Orders",
          DATABASE::"Sales Header",
          SalesHeader.FieldNo("No."),
          SalesHeader."No.");

        // [THEN] "O" deleted
        VerifySalesDocumentDeleted(DocumentType, SalesHeader."No.");
        // [THEN] Approval Entries related to "O" are deleted
        VerifyApprovalEntriesDeleted(SalesHeader.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteApprovedInvoicedPurchaseReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentType: Enum "Purchase Document Type";
    begin
        // [FEATURE] [Purchase] [Approval Management]
        // [SCENARIO 363783] Report "Delete Invd Purch. Ret. Orders" deletes Approval Entries related to deleted Purchase Return Order
        // [GIVEN] Invoiced Purchase Return Order "O"
        Initialize();
        DocumentType := PurchaseHeader."Document Type"::"Return Order";
        ApprovedPurchaseDocumentScenario(DocumentType, PurchaseHeader);
        VerifyApprovalEntriesExist(PurchaseHeader.RecordId);

        // [WHEN] Run Report "Delete Invd Purch. Ret. Orders"
        RunReport(
          REPORT::"Delete Invd Purch. Ret. Orders",
          DATABASE::"Purchase Header",
          PurchaseHeader.FieldNo("No."),
          PurchaseHeader."No.");

        // [THEN] "O" deleted
        VerifyPurchaseDocumentDeleted(DocumentType, PurchaseHeader."No.");
        // [THEN] Approval Entries related to "O" are  deleted
        VerifyApprovalEntriesDeleted(PurchaseHeader.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteApprovedInvoicedSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        DocumentType: Enum "Sales Document Type";
    begin
        // [FEATURE] [Sales] [Approval Management]
        // [SCENARIO 363783] Report "Delete Invd Sales Ret. Orders" deletes Approval Entries related to deleted Sales Return Order
        // [GIVEN] Invoiced Sales Return Order "O"
        Initialize();
        DocumentType := SalesHeader."Document Type"::"Return Order";
        ApprovedSalesDocumentScenario(DocumentType, SalesHeader);
        VerifyApprovalEntriesExist(SalesHeader.RecordId);

        // [WHEN] Run Report "Delete Invd Sales Ret. Orders"
        RunReport(
          REPORT::"Delete Invd Sales Ret. Orders",
          DATABASE::"Sales Header",
          SalesHeader.FieldNo("No."),
          SalesHeader."No.");

        // [THEN] "O" deleted
        VerifySalesDocumentDeleted(DocumentType, SalesHeader."No.");
        // [THEN] Approval Entries related to "O" are deleted
        VerifyApprovalEntriesDeleted(SalesHeader.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteApprovedInvoicedServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        DocumentType: Enum "Service Document Type";
    begin
        // [FEATURE] [Services] [Approval Management]
        // [SCENARIO 363783] Report "Delete Invoiced Service Orders" deletes Approval Entries related to deleted Service Order
        // [GIVEN] Invoiced Service Order "O"
        Initialize();
        DocumentType := ServiceHeader."Document Type"::Order;
        ApprovedServiceDocumentScenario(DocumentType, ServiceHeader);
        VerifyApprovalEntriesExist(ServiceHeader.RecordId);

        // [WHEN] Run Report "Delete Invoiced Service Orders"
        RunReport(
          REPORT::"Delete Invoiced Service Orders",
          DATABASE::"Service Header",
          ServiceHeader.FieldNo("No."),
          ServiceHeader."No.");

        // [THEN] "O" deleted
        VerifyServiceDocumentDeleted(DocumentType, ServiceHeader."No.");
        // [THEN] Approval Entries related to "O" are deleted
        VerifyApprovalEntriesDeleted(ServiceHeader.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketAssemblyOrderAfterDeleteInvdBlnktSalesOrders()
    var
        SalesHeader: Record "Sales Header";
        AssemblyHeader: Record "Assembly Header";
        ATOLink: Record "Assemble-to-Order Link";
    begin
        // [FEATURE] [Blanket Order] [Sales] [Assembly]
        // [SCENARIO 377504] Report "Delete Invd Blnkt Sales Orders" should delete Blanket Assembly Order related to deleted Sales Blanket Order
        Initialize();

        // [GIVEN] Blanket Sales Order "S"
        MockSalesOrder(SalesHeader."Document Type"::"Blanket Order", SalesHeader);

        // [GIVEN] Blanket Assembly Order "A" related to "S"
        MockBlanketAssemblyOrder(SalesHeader."No.", AssemblyHeader, ATOLink);

        // [WHEN] Run Report "Delete Invd Blnkt Sales Orders"
        RunReport(REPORT::"Delete Invd Blnkt Sales Orders", DATABASE::"Sales Header", SalesHeader.FieldNo("No."), SalesHeader."No.");
        // [THEN] Assembly Order "A" is deleted
        AssemblyHeader.SetRange("Document Type", AssemblyHeader."Document Type"::"Blanket Order");
        AssemblyHeader.SetRange("No.", AssemblyHeader."No.");
        Assert.RecordIsEmpty(AssemblyHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdSalesInvAllowedDeletionBeforeDateIsEmpty()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Allow Document Deletion] [Sales]
        // [SCENARIO 169264] Delete posted Sales Invoice. "Allow Document Deletion Before" is not set up.
        Initialize();
        // [GIVEN] "Sales Setup"."Allow Document Deletion Before" = 0D.
        LibrarySales.SetAllowDocumentDeletionBeforeDate(0D);
        // [GIVEN] Posted Sales Invoice.
        MockPostedSalesInvoice(SalesInvoiceHeader, AllowPostedDocumentDeletionDate);
        Commit();
        // [WHEN] Delete posted Sales Invoice.
        asserterror SalesInvoiceHeader.Delete(true);
        // [THEN] Error "Allow Document Deletion Before must have a value in Sales & Receivables Setup"
        Assert.ExpectedError(
          StrSubstNo(AllowSalesDocumentDeletionBeforeBlankErr, SalesReceivablesSetup.FieldCaption("Allow Document Deletion Before"),
            SalesReceivablesSetup.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdSalesInvWithPostingDateAfterAllowedDeletionBeforeDate()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Allow Document Deletion] [Sales]
        // [SCENARIO 169264] Delete posted Sales Invoice. Posted Sales Invoice date is greater/equal than allowed deletion before date.
        Initialize();
        // [GIVEN] "Sales Setup"."Allow Document Deletion Before" = AllowPostedDocumentDeletionDate.
        LibrarySales.SetAllowDocumentDeletionBeforeDate(AllowPostedDocumentDeletionDate);
        SalesSetup.Get();
        // [GIVEN] Posted Sales Invoice with "Posting Date" = AllowPostedDocumentDeletionDate.
        MockPostedSalesInvoice(SalesInvoiceHeader, AllowPostedDocumentDeletionDate);
        Commit();
        // [WHEN] Delete posted Sales Invoice.
        asserterror SalesInvoiceHeader.Delete(true);
        // [THEN] Posted Sales Invoice is not deleted. Error message.
        Assert.ExpectedError(StrSubstNo(SalesDocDeletionErr, SalesSetup."Allow Document Deletion Before"));
        VerifyPostedSalesInvoiceExists(SalesInvoiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdSalesInvWithPostingDateBeforeAllowedDeletionBeforeDate()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Allow Document Deletion] [Sales]
        // [SCENARIO 169264] Delete posted Sales Invoice. Posted Sales Invoice date is less than allowed deletion before date.
        Initialize();
        // [GIVEN] "Sales Setup"."Allow Document Deletion Before" = AllowPostedDocumentDeletionDate.
        LibrarySales.SetAllowDocumentDeletionBeforeDate(AllowPostedDocumentDeletionDate);
        // [GIVEN] Posted Sales Invoice with "Posting Date" = AllowPostedDocumentDeletionDate - 1.
        MockPostedSalesInvoice(SalesInvoiceHeader, AllowPostedDocumentDeletionDate - 1);
        Commit();
        // [WHEN] Delete posted Sales Invoice.
        SalesInvoiceHeader.Delete(true);
        // [THEN] Posted Sales Invoice is deleted.
        VerifyPostedSalesInvoiceDeleted(SalesInvoiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdSalesCrMemoAllowedDeletionBeforeDateIsEmpty()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Allow Document Deletion] [Sales]
        // [SCENARIO 169264] Delete posted Sales Credit Memo. "Allow Document Deletion Before" is not set up.
        Initialize();
        // [GIVEN] "Sales Setup"."Allow Document Deletion Before" = 0D.
        LibrarySales.SetAllowDocumentDeletionBeforeDate(0D);
        // [GIVEN] Posted Sales Credit Memo.
        MockPostedSalesCrMemo(SalesCrMemoHeader, AllowPostedDocumentDeletionDate);
        Commit();
        // [WHEN] Delete posted Sales Credit Memo.
        asserterror SalesCrMemoHeader.Delete(true);
        // [THEN] Error "Allow Document Deletion Before must have a value in Sales & Receivables Setup"
        Assert.ExpectedError(
          StrSubstNo(AllowSalesDocumentDeletionBeforeBlankErr, SalesReceivablesSetup.FieldCaption("Allow Document Deletion Before"),
            SalesReceivablesSetup.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdSalesCrMemoWithPostingDateAfterAllowedDeletionBeforeDate()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Allow Document Deletion] [Sales]
        // [SCENARIO 169264] Delete posted Sales Credit Memo. Posted Sales Credit Memo date is greater/equal than allowed deletion before date.
        Initialize();
        // [GIVEN] "Sales Setup"."Allow Document Deletion Before" = AllowPostedDocumentDeletionDate.
        LibrarySales.SetAllowDocumentDeletionBeforeDate(AllowPostedDocumentDeletionDate);
        SalesSetup.Get();
        // [GIVEN] Posted Sales Credit Memo with "Posting Date" = AllowPostedDocumentDeletionDate.
        MockPostedSalesCrMemo(SalesCrMemoHeader, AllowPostedDocumentDeletionDate);
        Commit();
        // [WHEN] Delete posted Sales Credit Memo.
        asserterror SalesCrMemoHeader.Delete(true);
        // [THEN] Posted Sales Credit Memo is not deleted. Error message.
        Assert.ExpectedError(StrSubstNo(SalesDocDeletionErr, SalesSetup."Allow Document Deletion Before"));
        VerifyPostedSalesCrMemoExists(SalesCrMemoHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdSalesCrMemoWithPostingDateBeforeAllowedDeletionBeforeDate()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Allow Document Deletion] [Sales]
        // [SCENARIO 169264] Delete posted Sales Credit Memo. Posted Sales Credit Memo date is less than allowed deletion before date.
        Initialize();
        // [GIVEN] "Sales Setup"."Allow Document Deletion Before" = AllowPostedDocumentDeletionDate.
        LibrarySales.SetAllowDocumentDeletionBeforeDate(AllowPostedDocumentDeletionDate);
        // [GIVEN] Posted Sales Credit Memo with "Posting Date" = AllowPostedDocumentDeletionDate - 1.
        MockPostedSalesCrMemo(SalesCrMemoHeader, AllowPostedDocumentDeletionDate - 1);
        Commit();
        // [WHEN] Delete posted Sales Credit Memo.
        SalesCrMemoHeader.Delete(true);
        // [THEN] Posted Sales Credit Memo is deleted.
        VerifyPostedSalesCrMemoDeleted(SalesCrMemoHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdPurchInvAllowedDeletionBeforeDateIsEmpty()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [Allow Document Deletion] [Purchase]
        // [SCENARIO 169264] Delete posted Purchase Invoice. "Allow Document Deletion Before" is not set up.
        Initialize();
        // [GIVEN] "Purchase Setup"."Allow Document Deletion Before" = 0D.
        LibraryPurchase.SetAllowDocumentDeletionBeforeDate(0D);
        // [GIVEN] Posted Purchase Invoice.
        MockPostedPurchaseInvoice(PurchInvHeader, AllowPostedDocumentDeletionDate);
        Commit();
        // [WHEN] Delete posted Purchase Invoice.
        asserterror PurchInvHeader.Delete(true);
        // [THEN] Error "Allow Document Deletion Before must have a value in Purchases & Payables Setup"
        Assert.ExpectedError(
          StrSubstNo(AllowPurchaseDocumentDeletionBeforeBlankErr, PurchasesPayablesSetup.FieldCaption("Allow Document Deletion Before"),
            PurchasesPayablesSetup.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdPurchInvWithPostingDateAfterAllowedDeletionBeforeDate()
    var
        PurchSetup: Record "Purchases & Payables Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [FEATURE] [Allow Document Deletion] [Purchase]
        // [SCENARIO 169264] Delete posted Purchase Invoice. Posted Purchase Invoice date is greater/equal than allowed deletion before date.
        Initialize();
        // [GIVEN] "Purchase Setup"."Allow Document Deletion Before" = AllowPostedDocumentDeletionDate.
        LibraryPurchase.SetAllowDocumentDeletionBeforeDate(AllowPostedDocumentDeletionDate);
        PurchSetup.Get();
        // [GIVEN] Posted Purchase Invoice with "Posting Date" = AllowPostedDocumentDeletionDate.
        MockPostedPurchaseInvoice(PurchInvHeader, AllowPostedDocumentDeletionDate);
        Commit();
        // [WHEN] Delete posted Purchase Invoice.
        asserterror PurchInvHeader.Delete(true);
        // [THEN] Posted Purchase Invoice is not deleted. Error message.
        Assert.ExpectedError(StrSubstNo(PurchDocDeletionErr, PurchSetup."Allow Document Deletion Before"));
        VerifyPostedPurchaseInvoiceExists(PurchInvHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdPurchInvWithPostingDateBeforeAllowedDeletionBeforeDate()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [FEATURE] [Allow Document Deletion] [Purchase]
        // [SCENARIO 169264] Delete posted Purchase Invoice. Posted Purchase Invoice date is less than allowed deletion before date.
        Initialize();
        // [GIVEN] "Purchase Setup"."Allow Document Deletion Before" = AllowPostedDocumentDeletionDate.
        LibraryPurchase.SetAllowDocumentDeletionBeforeDate(AllowPostedDocumentDeletionDate);
        // [GIVEN] Posted Purchase Invoice with "Posting Date" = AllowPostedDocumentDeletionDate - 1.
        MockPostedPurchaseInvoice(PurchInvHeader, AllowPostedDocumentDeletionDate - 1);
        Commit();
        // [WHEN] Delete posted Purchase Invoice.
        PurchInvHeader.Delete(true);
        // [THEN] Posted Purchase Invoice is deleted.
        VerifyPostedPurchaseInvoiceDeleted(PurchInvHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdPurchCrMemoAllowedDeletionBeforeDateIsEmpty()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [Allow Document Deletion] [Purchase]
        // [SCENARIO 169264] Delete posted Purchase Credit Memo. "Allow Document Deletion Before" is not set up.
        Initialize();
        // [GIVEN] "Purchase Setup"."Allow Document Deletion Before" = 0D.
        LibraryPurchase.SetAllowDocumentDeletionBeforeDate(0D);
        // [GIVEN] Posted Purchase Credit Memo.
        MockPostedPurchaseCrMemo(PurchCrMemoHdr, AllowPostedDocumentDeletionDate);
        Commit();
        // [WHEN] Delete posted Purchase Credit Memo.
        asserterror PurchCrMemoHdr.Delete(true);
        // [THEN] Error "Allow Document Deletion Before must have a value in Purchases & Payables Setup"
        Assert.ExpectedError(
          StrSubstNo(AllowPurchaseDocumentDeletionBeforeBlankErr, PurchasesPayablesSetup.FieldCaption("Allow Document Deletion Before"),
            PurchasesPayablesSetup.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdPurchCrMemoWithPostingDateAfterAllowedDeletionBeforeDate()
    var
        PurchSetup: Record "Purchases & Payables Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [Allow Document Deletion] [Purchase]
        // [SCENARIO 169264] Delete posted Purchase Credit Memo. Posted Purchase Credit Memo date is greater/equal than allowed deletion before date.
        Initialize();
        // [GIVEN] "Purchase Setup"."Allow Document Deletion Before" = AllowPostedDocumentDeletionDate.
        LibraryPurchase.SetAllowDocumentDeletionBeforeDate(AllowPostedDocumentDeletionDate);
        PurchSetup.Get();
        // [GIVEN] Posted Purchase Credit Memo with "Posting Date" = AllowPostedDocumentDeletionDate.
        MockPostedPurchaseCrMemo(PurchCrMemoHdr, AllowPostedDocumentDeletionDate);
        Commit();
        // [WHEN] Delete posted Purchase Credit Memo.
        asserterror PurchCrMemoHdr.Delete(true);
        // [THEN] Posted Purchase Credit Memo is not deleted. Error message.
        Assert.ExpectedError(StrSubstNo(PurchDocDeletionErr, PurchSetup."Allow Document Deletion Before"));
        VerifyPostedPurchaseCrMemoExists(PurchCrMemoHdr."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdPurchCrMemoWithPostingDateBeforeAllowedDeletionBeforeDate()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [Allow Document Deletion] [Purchase]
        // [SCENARIO 169264] Delete posted Purchase Credit Memo. Posted Purchase Credit Memo date is less than allowed deletion before date.
        Initialize();
        // [GIVEN] "Purchase Setup"."Allow Document Deletion Before" = AllowPostedDocumentDeletionDate.
        LibraryPurchase.SetAllowDocumentDeletionBeforeDate(AllowPostedDocumentDeletionDate);
        // [GIVEN] Posted Purchase Credit Memo with "Posting Date" = AllowPostedDocumentDeletionDate - 1.
        MockPostedPurchaseCrMemo(PurchCrMemoHdr, AllowPostedDocumentDeletionDate - 1);
        Commit();
        // [WHEN] Delete posted Purchase Credit Memo.
        PurchCrMemoHdr.Delete(true);
        // [THEN] Posted Purchase Credit Memo is deleted.
        VerifyPostedPurchaseCrMemoDeleted(PurchCrMemoHdr."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdPurchRcptsAllowedDeletionBeforeDateIsEmpty()
    var
        PurchRcptHeader: array[2] of Record "Purch. Rcpt. Header";
        PurchaseSetup: Record "Purchases & Payables Setup";
        PostingDate: array[2] of Date;
    begin
        // [FEATURE] [Allow Document Deletion] [Purchase]
        // [SCENARIO 463858] Delete posted Purchase Receipts. "Allow Document Deletion Before" is not set up.
        Initialize();

        // [GIVEN] "Purchase Setup"."Allow Document Deletion Before" = 0D.
        LibraryPurchase.SetAllowDocumentDeletionBeforeDate(0D);

        // [GIVEN] Receive on two different dates
        PostingDate[1] := CalcDate('<-5D>', AllowPostedDocumentDeletionDate);
        PostingDate[2] := AllowPostedDocumentDeletionDate;
        MockPostedPurchaseReceipt(PurchRcptHeader, PostingDate);
        Commit();

        // [WHEN] Delete posted Purchase Receipts
        asserterror PurchRcptHeader[1].Delete(true);
        asserterror PurchRcptHeader[2].Delete(true);

        // [THEN] Error "Allow Document Deletion Before must have a value in Purchases & Payables Setup"
        Assert.ExpectedError(StrSubstNo(AllowPurchaseDocumentDeletionBeforeBlankErr, PurchaseSetup.FieldCaption("Allow Document Deletion Before"), PurchaseSetup.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdPurchRcptsWithPostingDateAfterAllowedDeletionBeforeDate()
    var
        PurchRcptHeader: array[2] of Record "Purch. Rcpt. Header";
        PurchaseSetup: Record "Purchases & Payables Setup";
        PostingDate: array[2] of Date;
    begin
        // [FEATURE] [Allow Document Deletion] [Purchase]
        // [SCENARIO 463858] Delete posted Purchase Receipts. On second receipt, posting date is greater/equal then allowed deletion date. On the first receipt, posting date is less then allowed deletion date
        Initialize();

        // [GIVEN] "Purchase Setup"."Allow Document Deletion Before" = AllowPostedDocumentDeletionDate.
        LibraryPurchase.SetAllowDocumentDeletionBeforeDate(AllowPostedDocumentDeletionDate);
        PurchaseSetup.Get();

        // [GIVEN] Receive on two different dates
        PostingDate[1] := CalcDate('<-5D>', AllowPostedDocumentDeletionDate);
        PostingDate[2] := AllowPostedDocumentDeletionDate;
        MockPostedPurchaseReceipt(PurchRcptHeader, PostingDate);
        Commit();

        // [WHEN] Delete first receipt
        PurchRcptHeader[1].Delete(true);

        // [THEN] Posted Purchase Receipt is deleted
        VerifyPostedDocDeleted(Database::"Purch. Rcpt. Header", PurchRcptHeader[1].FieldName("No."), PurchRcptHeader[1]."No.");

        // [WHEN] Delete second receipt
        asserterror PurchRcptHeader[2].Delete(true);

        // [THEN] Verfiy second purchase receipt is not deleted
        Assert.ExpectedError(StrSubstNo(PurchDocDeletionErr, PurchaseSetup."Allow Document Deletion Before"));
        VerifyPostedDocExists(Database::"Purch. Rcpt. Header", PurchRcptHeader[2].FieldName("No."), PurchRcptHeader[2]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdReturnShptsAllowedDeletionBeforeDateIsEmpty()
    var
        ReturnShipmentHeader: array[2] of Record "Return Shipment Header";
        PurchaseSetup: Record "Purchases & Payables Setup";
        PostingDate: array[2] of Date;
    begin
        // [FEATURE] [Allow Document Deletion] [Purchase]
        // [SCENARIO 463858] Delete posted Return Shipments. "Allow Document Deletion Before" is not set up.
        Initialize();

        // [GIVEN] "Purchase Setup"."Allow Document Deletion Before" = 0D.
        LibraryPurchase.SetAllowDocumentDeletionBeforeDate(0D);

        // [GIVEN] Receive shipments
        PostingDate[1] := CalcDate('<-2D>', AllowPostedDocumentDeletionDate);
        PostingDate[2] := AllowPostedDocumentDeletionDate;
        MockPostedReturnShipment(ReturnShipmentHeader, PostingDate);
        Commit();

        // [WHEN] Delete posted Return Shipments
        asserterror ReturnShipmentHeader[1].Delete(true);
        asserterror ReturnShipmentHeader[2].Delete(true);

        // [THEN] Error "Allow Document Deletion Before must have a value in Purchases & Payables Setup"
        Assert.ExpectedError(StrSubstNo(AllowPurchaseDocumentDeletionBeforeBlankErr, PurchaseSetup.FieldCaption("Allow Document Deletion Before"), PurchaseSetup.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdReturnShptsWithPostingDateAfterAllowedDeletionBeforeDate()
    var
        ReturnShipmentHeader: array[2] of Record "Return Shipment Header";
        PurchaseSetup: Record "Purchases & Payables Setup";
        PostingDate: array[2] of Date;
    begin
        // [FEATURE] [Allow Document Deletion] [Purchase]
        // [SCENARIO 463858] Delete posted Return Shipments. On second return, posting date is greater/equal then allowed deletion date. On the first return, posting date is less then allowed deletion date
        Initialize();

        // [GIVEN] "Purchase Setup"."Allow Document Deletion Before" = AllowPostedDocumentDeletionDate.
        LibraryPurchase.SetAllowDocumentDeletionBeforeDate(AllowPostedDocumentDeletionDate);
        PurchaseSetup.Get();

        // [GIVEN] Receive on two different dates
        PostingDate[1] := CalcDate('<-2D>', AllowPostedDocumentDeletionDate);
        PostingDate[2] := AllowPostedDocumentDeletionDate;
        MockPostedReturnShipment(ReturnShipmentHeader, PostingDate);
        Commit();

        // [WHEN] Delete first receipt
        ReturnShipmentHeader[1].Delete(true);

        // [THEN] Posted Return Shipment is deleted
        VerifyPostedDocDeleted(Database::"Return Shipment Header", ReturnShipmentHeader[1].FieldName("No."), ReturnShipmentHeader[1]."No.");

        // [WHEN] Delete second return shipment
        asserterror ReturnShipmentHeader[2].Delete(true);

        // [THEN] Verfiy second return shipment is not deleted
        Assert.ExpectedError(StrSubstNo(PurchDocDeletionErr, PurchaseSetup."Allow Document Deletion Before"));
        VerifyPostedDocExists(Database::"Return Shipment Header", ReturnShipmentHeader[2].FieldName("No."), ReturnShipmentHeader[2]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdSaleShptsAllowedDeletionBeforeDateIsEmpty()
    var
        SalesShipmentHeader: array[2] of Record "Sales Shipment Header";
        SalesSetup: Record "Sales & Receivables Setup";
        PostingDate: array[2] of Date;
    begin
        // [FEATURE] [Allow Document Deletion] [Sales]
        // [SCENARIO 463858] Delete posted Sales Shipments. "Allow Document Deletion Before" is not set up.
        Initialize();

        // [GIVEN] "Sales Setup"."Allow Document Deletion Before" = 0D.
        LibrarySales.SetAllowDocumentDeletionBeforeDate(0D);

        // [GIVEN] Ship on two different dates
        PostingDate[1] := CalcDate('<-5D>', AllowPostedDocumentDeletionDate);
        PostingDate[2] := AllowPostedDocumentDeletionDate;
        MockPostedSalesShipment(SalesShipmentHeader, PostingDate);
        Commit();

        // [WHEN] Delete posted Sales Shipments
        asserterror SalesShipmentHeader[1].Delete(true);
        asserterror SalesShipmentHeader[2].Delete(true);

        // [THEN] Error "Allow Document Deletion Before must have a value in Sales & Receivables Setup"
        Assert.ExpectedError(StrSubstNo(AllowSalesDocumentDeletionBeforeBlankErr, SalesSetup.FieldCaption("Allow Document Deletion Before"), SalesSetup.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdSaleShptssWithPostingDateAfterAllowedDeletionBeforeDate()
    var
        SalesShipmentHeader: array[2] of Record "Sales Shipment Header";
        SalesSetup: Record "Sales & Receivables Setup";
        PostingDate: array[2] of Date;
    begin
        // [FEATURE] [Allow Document Deletion] [Sales]
        // [SCENARIO 463858] Delete posted Sales Shipments. On second shipment, posting date is greater/equal then allowed deletion date. On the first shipment, posting date is less then allowed deletion date
        Initialize();

        // [GIVEN] "Sales Setup"."Allow Document Deletion Before" = AllowPostedDocumentDeletionDate.
        LibrarySales.SetAllowDocumentDeletionBeforeDate(AllowPostedDocumentDeletionDate);
        SalesSetup.Get();

        // [GIVEN] Ship on two different dates
        PostingDate[1] := CalcDate('<-5D>', AllowPostedDocumentDeletionDate);
        PostingDate[2] := AllowPostedDocumentDeletionDate;
        MockPostedSalesShipment(SalesShipmentHeader, PostingDate);
        Commit();

        // Mock No. Printed
        SalesShipmentHeader[1]."No. Printed" := 1;
        SalesShipmentHeader[1].Modify();
        SalesShipmentHeader[2]."No. Printed" := 1;
        SalesShipmentHeader[2].Modify();

        // [WHEN] Delete first shipment
        SalesShipmentHeader[1].Delete(true);

        // [THEN] Posted Sales Shipment is deleted
        VerifyPostedDocDeleted(Database::"Sales Shipment Header", SalesShipmentHeader[1].FieldName("No."), SalesShipmentHeader[1]."No.");

        // [WHEN] Delete second shipment
        asserterror SalesShipmentHeader[2].Delete(true);

        // [THEN] Verfiy second sales shipment is not deleted
        Assert.ExpectedError(StrSubstNo(SalesDocDeletionErr, SalesSetup."Allow Document Deletion Before"));
        VerifyPostedDocExists(Database::"Sales Shipment Header", SalesShipmentHeader[2].FieldName("No."), SalesShipmentHeader[2]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdReturnRcptsAllowedDeletionBeforeDateIsEmpty()
    var
        ReturnReceiptHeader: array[2] of Record "Return Receipt Header";
        SalesSetup: Record "Sales & Receivables Setup";
        PostingDate: array[2] of Date;
    begin
        // [FEATURE] [Allow Document Deletion] [Sales]
        // [SCENARIO 463858] Delete posted Return Receipts. "Allow Document Deletion Before" is not set up.
        Initialize();

        // [GIVEN] "Sales Setup"."Allow Document Deletion Before" = 0D.
        LibrarySales.SetAllowDocumentDeletionBeforeDate(0D);

        // [GIVEN] Return receipts
        PostingDate[1] := CalcDate('<-2D>', AllowPostedDocumentDeletionDate);
        PostingDate[2] := AllowPostedDocumentDeletionDate;
        MockPostedReturnReceipt(ReturnReceiptHeader, PostingDate);
        Commit();

        // [WHEN] Delete posted Return Receipts
        asserterror ReturnReceiptHeader[1].Delete(true);
        asserterror ReturnReceiptHeader[2].Delete(true);

        // [THEN] Error "Allow Document Deletion Before must have a value in Sales & Receivables Setup"
        Assert.ExpectedError(StrSubstNo(AllowSalesDocumentDeletionBeforeBlankErr, SalesSetup.FieldCaption("Allow Document Deletion Before"), SalesSetup.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePstdReturnRcptsWithPostingDateAfterAllowedDeletionBeforeDate()
    var
        ReturnReceiptHeader: array[2] of Record "Return Receipt Header";
        SalesSetup: Record "Sales & Receivables Setup";
        PostingDate: array[2] of Date;
    begin
        // [FEATURE] [Allow Document Deletion] [Sales]
        // [SCENARIO 463858] Delete posted Return Receipts. On second return, posting date is greater/equal then allowed deletion date. On the first return, posting date is less then allowed deletion date
        Initialize();

        // [GIVEN] "Sales Setup"."Allow Document Deletion Before" = AllowPostedDocumentDeletionDate.
        LibrarySales.SetAllowDocumentDeletionBeforeDate(AllowPostedDocumentDeletionDate);
        SalesSetup.Get();

        // [GIVEN] Receive on two different dates
        PostingDate[1] := CalcDate('<-2D>', AllowPostedDocumentDeletionDate);
        PostingDate[2] := AllowPostedDocumentDeletionDate;
        MockPostedReturnReceipt(ReturnReceiptHeader, PostingDate);
        Commit();

        // Mock No. Printed
        ReturnReceiptHeader[1]."No. Printed" := 1;
        ReturnReceiptHeader[1].Modify();
        ReturnReceiptHeader[2]."No. Printed" := 1;
        ReturnReceiptHeader[2].Modify();

        // [WHEN] Delete first return receipt
        ReturnReceiptHeader[1].Delete(true);

        // [THEN] Posted Return Receipt is deleted
        VerifyPostedDocDeleted(Database::"Return Receipt Header", ReturnReceiptHeader[1].FieldName("No."), ReturnReceiptHeader[1]."No.");

        // [WHEN] Delete second return receipt
        asserterror ReturnReceiptHeader[2].Delete(true);

        // [THEN] Verfiy second return receipt is not deleted
        Assert.ExpectedError(StrSubstNo(SalesDocDeletionErr, SalesSetup."Allow Document Deletion Before"));
        VerifyPostedDocExists(Database::"Return Receipt Header", ReturnReceiptHeader[2].FieldName("No."), ReturnReceiptHeader[2]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BatchDeleteInvoicedSalesOrderWithItemCharge()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Delete Documents] [Order] [Sales]
        // [SCENARIO 208384] Test where the "Delete Invoiced Sales Orders" batch job delete Sales Order with Charge(Item) which is shipped and Invoiced.
        Initialize();

        // [GIVEN] Sales Order with Charge(Item)
        // [GIVEN] Post Sales Order with only Ship option
        // [GIVEN] New Sales Invoice for Posted Shipment Line.
        // [GIVEN] Post Sales Invoice
        // [GIVEN] Set Quantity to zero - Charge(Item) should not be more shipped and invoiced.
        InvoicedSalesOrderWithItemCharge(SalesHeader);

        // [WHEN] Run Delete Invoiced Sales Order Batch report for above Order, that is already Ship and Invoiced.
        DeleteInvoiceSalesOrder(SalesHeader);

        // [THEN] Since all lines do have a quantity to ship and quantity to invoice of 0, the complete sales order should be deleted.
        Assert.IsFalse(SalesHeader.Find(), DocumentStillExistsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualDeleteInvoicedSalesOrderWithItemCharge()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Delete Documents] [Order] [Sales]
        // [SCENARIO 208384] Manually delete Sales Order with Charge(Item) which is shipped and Invoiced.
        Initialize();

        // [GIVEN] Sales Order with Charge(Item)
        // [GIVEN] Post Sales Order with only Ship option
        // [GIVEN] New Sales Invoice for Posted Shipment Line.
        // [GIVEN] Post Sales Invoice
        // [GIVEN] Set Quantity to zero - Charge(Item) should not be more shipped and invoiced.
        InvoicedSalesOrderWithItemCharge(SalesHeader);

        // [WHEN] Manually delete Invoiced Sales Order
        SalesHeader.Delete(true);

        // [THEN] Since all lines do have a quantity to ship and quantity to invoice of 0, the complete sales order should be deleted.
        Assert.IsFalse(SalesHeader.Find(), DocumentStillExistsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BatchDeleteInvoicedPurchaseOrderWithItemCharge()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Delete Documents] [Order] [Purchase]
        // [SCENARIO 208384] Test where the "Delete Invoiced Purchase Orders" batch job delete Purchase Order with Charge(Item) which is received and Invoiced.
        Initialize();

        // [GIVEN] Purchase Order with Charge(Item)
        // [GIVEN] Post Purchase Order with only Receive option
        // [GIVEN] New Purcase Invoice for Posted Received Line
        // [GIVEN] Post Purchase Invoice
        // [GIVEN] Set Quantity to zero - Charge(Item) should not be more received and invoiced.
        InvoicedPurchaseOrderWithItemCharger(PurchaseHeader);

        // [WHEN] Run Delete Invoiced Purchase Order Batch report for above Order
        DeleteInvoicePurchOrder(PurchaseHeader);

        // [THEN] Since all lines do have a quantity to received and quantity to invoice of 0, the complete Purchase order should be deleted.
        Assert.IsFalse(PurchaseHeader.Find(), DocumentStillExistsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualDeleteInvoicedPurchaseOrderWithItemCharge()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Delete Documents] [Order] [Purchase]
        // [SCENARIO 208384] Manually delete Purchase Order with Charge(Item) which is received and Invoiced.
        Initialize();

        // [GIVEN] Purchase Order with Charge(Item)
        // [GIVEN] Post Purchase Order with only Receive option
        // [GIVEN] New Purcase Invoice for Posted Received Line
        // [GIVEN] Post Purchase Invoice
        // [GIVEN] Set Quantity to zero - Charge(Item) should not be more received and invoiced
        InvoicedPurchaseOrderWithItemCharger(PurchaseHeader);

        // [WHEN] Manually delete Invoiced Purchase Order
        PurchaseHeader.Delete(true);

        // [THEN] Since all lines do have a quantity to received and quantity to invoice of 0, the complete Purchase order should be deleted.
        Assert.IsFalse(PurchaseHeader.Find(), DocumentStillExistsErr);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure DoNotClearLinkOnSalesLineToManuallyDeletedInvoicedPurchaseForSpecialOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptNo: Code[20];
    begin
        // [FEATURE] [Delete Documents] [Order] [Sales] [Purchase] [Special Order]
        // [SCENARIO 266106] When you manually delete an invoiced purchase for special order, the related sales keeps the link to it, in order to prevent the sales be planned for a second time.
        Initialize();

        // [GIVEN] Sales order set up for Special Order.
        CreateSalesOrderForSpecialOrder(SalesHeader);

        // [GIVEN] Purchase order is created from the sales line using "Get Special Order".
        CreatePurchOrderForSpecialOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        FilterPurchaseLines(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLine.FindFirst();

        // [GIVEN] Receive the purchase order.
        ReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create and post purchase invoice from the purchase order using "Get Receipt Lines".
        CreateAndPostPurchInvoiceViaGetReceiptLines(ReceiptNo);

        // [WHEN] Delete the purchase order manually.
        PurchaseHeader.Delete(true);

        // [THEN] The special order link on the sales line still points to the deleted purchase.
        FilterSalesLines(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.TestField("Special Order Purchase No.", PurchaseLine."Document No.");
        SalesLine.TestField("Special Order Purch. Line No.", PurchaseLine."Line No.");
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure ClearLinkOnSalesLineToManuallyDeletedNotInvoicedPurchaseForSpecialOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Delete Documents] [Order] [Sales] [Purchase] [Special Order]
        // [SCENARIO 266106] When you manually delete a purchase for special order, and the purchase has not been invoiced yet, this clears the special order link on the sales line.
        Initialize();

        // [GIVEN] Sales order set up for Special Order.
        CreateSalesOrderForSpecialOrder(SalesHeader);

        // [GIVEN] Purchase order is created from the sales line using "Get Special Order".
        CreatePurchOrderForSpecialOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");

        // [WHEN] Delete the purchase order manually.
        PurchaseHeader.Delete(true);

        // [THEN] "Special Order Purchase No." and "Special Order Purch. Line No." fields are cleared on the sales line.
        FilterSalesLines(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.TestField("Special Order Purchase No.", '');
        SalesLine.TestField("Special Order Purch. Line No.", 0);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteInvoicedSalesOrderForSpecialOrderClearsLinksOnPurchaseLine()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ShipmentNo: Code[20];
    begin
        // [FEATURE] [Delete Documents] [Order] [Sales] [Purchase] [Special Order]
        // [SCENARIO 261010] Link to a sales line set up for Special Order is cleared on purchase line after you delete the sales line using "Delete Invoiced Sales Orders" batch job.
        Initialize();

        // [GIVEN] Sales order line set up for Special Order.
        CreateSalesOrderForSpecialOrder(SalesHeader);

        // [GIVEN] Purchase order is created from the sales line using "Get Special Order" functionality.
        CreatePurchOrderForSpecialOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");

        // [GIVEN] Ship the sales order.
        ShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Create and post sales invoice from the sales order using "Get Shipment Lines".
        CreateAndPostSalesInvoiceViaGetShipmentLines(ShipmentNo);

        // [WHEN] Delete the fully invoiced sales order.
        DeleteInvoiceSalesOrder(SalesHeader);

        // [THEN] "Special Order Sales No." and "Special Order Sales Line No." fields are cleared on the purchase line.
        FilterPurchaseLines(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Special Order Sales No.", '');
        PurchaseLine.TestField("Special Order Sales Line No.", 0);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteInvoicedSalesOrderForDropShipmentClearsLinksOnPurchaseLine()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ShipmentNo: Code[20];
    begin
        // [FEATURE] [Delete Documents] [Order] [Sales] [Purchase] [Drop Shipment]
        // [SCENARIO 261010] Link to a sales line set up for Drop Shipment is cleared on purchase line after you delete the sales line using "Delete Invoiced Sales Orders" batch job.
        Initialize();

        // [GIVEN] Sales order line set up for Drop Shipment.
        CreateSalesOrderForDropShipment(SalesHeader);

        // [GIVEN] Purchase order is created from the sales line using "Get Drop Shipment" functionality.
        CreatePurchOrderForDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");

        // [GIVEN] Ship the sales order.
        ShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Create and post sales invoice from the sales order using "Get Shipment Lines".
        CreateAndPostSalesInvoiceViaGetShipmentLines(ShipmentNo);

        // [WHEN] Delete the fully invoiced sales order.
        DeleteInvoiceSalesOrder(SalesHeader);

        // [THEN] "Sales Order No." and "Sales Order Line No." fields are cleared on the purchase line.
        FilterPurchaseLines(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Sales Order No.", '');
        PurchaseLine.TestField("Sales Order Line No.", 0);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteInvoicedPurchOrderForSpecialOrderLinksOnSalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptNo: Code[20];
    begin
        // [FEATURE] [Delete Documents] [Order] [Sales] [Purchase] [Special Order]
        // [SCENARIO 261010] Link to a purchase line set up for Special Order is not cleared on sales line after you delete the purchase line using "Delete Invoiced Purchase Orders" batch job.
        // [SCENARIO 314595]
        Initialize();

        // [GIVEN] Sales order line set up for Special Order.
        CreateSalesOrderForSpecialOrder(SalesHeader);

        // [GIVEN] Purchase order "PO" is created from the sales line using "Get Special Order" functionality (Purchase Line with Line No 10000).
        CreatePurchOrderForSpecialOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();

        // [GIVEN] Receive the purchase order.
        ReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create and post purchase invoice from the purchase order using "Get Receipt Lines".
        CreateAndPostPurchInvoiceViaGetReceiptLines(ReceiptNo);

        // [WHEN] Delete the fully invoiced purchase order.
        DeleteInvoicePurchOrder(PurchaseHeader);

        // [THEN] "Special Order Purchase No." = "PO" and "Special Order Purch. Line No." = 10000 in the sales line.
        FilterSalesLines(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.TestField("Special Order Purchase No.", PurchaseHeader."No.");
        SalesLine.TestField("Special Order Purch. Line No.", PurchaseLine."Line No.");
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure DeletePartiallyInvoicedSalesOrderForDeletedPartiallyInvoicedSpecialPurchaseOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QtyToReceive: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Delete Documents] [Order] [Sales] [Purchase] [Special Order]
        // [SCENARIO 289945] Special Sales Order can be deleted if associated partially invoiced Special Purchase Order was already deleted

        Initialize();

        // [GIVEN] Created Special Order Sales Order
        CreateSalesOrderForSpecialOrder(SalesHeader);

        // [GIVEN] Created Purchase Order and get Sales Order from Special Order.
        CreatePurchOrderForSpecialOrder(PurchaseHeader, SalesHeader."Sell-to Customer No.");

        // [GIVEN] "Qty. to Receive" on Purchase Line set to part of full Quantity
        FilterPurchaseLines(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        QtyToReceive := PurchaseLine.Quantity * LibraryRandom.RandDecInDecimalRange(0.2, 0.9, 2);
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);

        // [GIVEN] Purchase Order posted with Receive and Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] "Qty. to Ship" on Sales Line set to half of full Quantity
        FilterSalesLines(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate("Qty. to Ship", QtyToReceive);
        SalesLine.Modify(true);

        // [GIVEN] Sales Order posted with Ship and Invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Purchase Order deleted
        PurchaseHeader.Delete(true);

        // [WHEN] Delete Sales Order
        DocumentNo := SalesHeader."No.";
        SalesHeader.Delete(true);

        // [THEN] Sales Order deleted
        Assert.IsFalse(SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo), '');
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CanChangeCurrencyOnPOWithDropShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Sales] [Purchases] [FCY] [Drop Shipment]
        // [SCENARIO 299349] Stan can set "USD" in "Currency Code" of Purchase Order with Drop Shipment
        Initialize();

        CreateSalesOrderForDropShipment(SalesHeader);

        CreatePurchOrderForDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");

        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);

        PurchaseHeader.TestField("Currency Code", CurrencyCode);
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);

        PurchaseLine.TestField("Drop Shipment");
        PurchaseLine.TestField("Sales Order No.", SalesHeader."No.");
        PurchaseLine.TestField("Sales Order Line No.", SalesLine."Line No.");
        PurchaseLine.TestField(Quantity, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CannotChangeCurrencyOnSOWithDropShipment()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Sales] [Purchases] [FCY] [Drop Shipment]
        // [SCENARIO 299349] Stan can't set "USD" in "Currency Code" of Sales Order with Drop Shipment
        Initialize();

        CreateSalesOrderForDropShipment(SalesHeader);

        CreatePurchOrderForDropShipment(PurchaseHeader, SalesHeader."Sell-to Customer No.");
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);

        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        asserterror SalesHeader.Validate("Currency Code", CurrencyCode);

        Assert.ExpectedError(StrSubstNo(CannotDeleteSalesOrderLineErr, PurchaseLine."Document No.", PurchaseLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletingFullyShippedAndInvoicedSalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Delete Documents]
        // [SCENARIO 302289] A user can delete a fully shipped and invoiced sales line.
        Initialize();

        // [GIVEN] Sales order with two lines.
        // [GIVEN] Set "Qty. to Ship" on the second line to 0.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesLine[1], SalesHeader);
        CreateSalesLine(SalesLine[2], SalesHeader);
        SalesLine[2].Validate("Qty. to Ship", 0);
        SalesLine[2].Modify(true);

        // [GIVEN] Ship and invoice the sales order. Only the first line is thus posted.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [WHEN] Delete the fully posted first line.
        SalesLine[1].Find();
        SalesLine[1].Delete(true);

        // [THEN] The first line is deleted.
        // [THEN] The second line stays.
        Assert.IsFalse(SalesLine[1].Find(), '');
        Assert.IsTrue(SalesLine[2].Find(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletingFullyReceivedAndInvoicedPurchaseLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Delete Documents]
        // [SCENARIO 302289] A user can delete a fully received and invoiced purchase line.
        Initialize();

        // [GIVEN] Purchase order with two lines.
        // [GIVEN] Set "Qty. to Receive" on the second line to 0.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLine(PurchaseLine[1], PurchaseHeader);
        CreatePurchaseLine(PurchaseLine[2], PurchaseHeader);
        PurchaseLine[2].Validate("Qty. to Receive", 0);
        PurchaseLine[2].Modify(true);

        // [GIVEN] Receive and invoice the purchase order. Only the first line is thus posted.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // [WHEN] Delete the fully posted first line.
        PurchaseLine[1].Find();
        PurchaseLine[1].Delete(true);

        // [THEN] The first line is deleted.
        // [THEN] The second line stays.
        Assert.IsFalse(PurchaseLine[1].Find(), '');
        Assert.IsTrue(PurchaseLine[2].Find(), '');
    end;

    [Test]
    procedure DeleteInvoicedPurchOrderWithItemChargeNotFullyAssigned()
    var
        ItemCharge: Record "Item Charge";
        PurchaseHeader: Record "Purchase Header";
        ItemPurchaseLine: array[2] of Record "Purchase Line";
        ItemChargePurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Delete Documents] [Item Charge]
        // [SCENARIO 400059] Do not delete purchase order with not fully assigned item charge.
        Initialize();
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Purchase order with two item lines "L1", "L2" and item charge line "IC".
        // [GIVEN] "L1".Quantity = 2, "L2".Quantity = 1, "IC".Quantity = 1.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, ItemPurchaseLine[1], PurchaseHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), 2, '', WorkDate());
        LibraryPurchase.CreatePurchaseLine(
          ItemPurchaseLine[2], PurchaseHeader, ItemPurchaseLine[2].Type::Item, LibraryInventory.CreateItemNo(), 1);
        LibraryPurchase.CreatePurchaseLine(
          ItemChargePurchaseLine, PurchaseHeader, ItemChargePurchaseLine.Type::"Charge (Item)", ItemCharge."No.", 1);
        ItemChargePurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        ItemChargePurchaseLine.Modify(true);

        // [GIVEN] Set 1 pc on line "L1" to receive and invoice.
        UpdateQtyToReceiveOnPurchaseLine(ItemPurchaseLine[1], 1);
        UpdateQtyToReceiveOnPurchaseLine(ItemPurchaseLine[2], 0);
        UpdateQtyToReceiveOnPurchaseLine(ItemChargePurchaseLine, 0);

        // [GIVEN] Receive and invoice line "L1".
        PostPurchaseDocument(PurchaseHeader);

        // [GIVEN] Set 1 pc on lines "L2" and "IC" to receive and invoice.
        UpdateQtyToReceiveOnPurchaseLine(ItemPurchaseLine[1], 0);
        UpdateQtyToReceiveOnPurchaseLine(ItemPurchaseLine[2], 1);
        UpdateQtyToReceiveOnPurchaseLine(ItemChargePurchaseLine, 1);

        // [GIVEN] Assign item charge equally to both item lines "L1" and "L2".
        CreateItemChargeAssignmentPurch(ItemChargePurchaseLine, ItemPurchaseLine[1], ItemCharge, 0.5);
        CreateItemChargeAssignmentPurch(ItemChargePurchaseLine, ItemPurchaseLine[2], ItemCharge, 0.5);

        // [GIVEN] Receive and invoice lines "L2" and "IC".
        PostPurchaseDocument(PurchaseHeader);

        // [GIVEN] Set quantity = 1 on line "L1" so it becomes fully received and invoiced.
        ItemPurchaseLine[1].Find();
        ItemPurchaseLine[1].Validate(Quantity, 1);
        ItemPurchaseLine[1].Modify(true);

        // [WHEN] Delete fully invoiced purchase order via report 499.
        DeleteInvoicePurchOrder(PurchaseHeader);

        // [THEN] The purchase order has not been deleted.
        PurchaseHeader.Find();

        // [THEN] None of purchase lines have been deleted.
        ItemPurchaseLine[1].Find();
        ItemPurchaseLine[2].Find();
        ItemChargePurchaseLine.Find();

        // [THEN] That is because the item charge line "IC" has remaining quantity to assign.
        ItemChargePurchaseLine.CalcFields("Qty. to Assign");
        ItemChargePurchaseLine.TestField("Qty. to Assign", 0.5);
    end;

    [Test]
    procedure DeletingSalesOrderWithErroneouslyPostedItemChargeForZeroAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Delete Documents] [Item Charge]
        // [SCENARIO 404143] Delete sales order with erroneously posted item charge for zero amount.
        Initialize();

        // [GIVEN] Mock sales order with posted item charge for zero amount.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);
        SalesLine."Quantity Shipped" := SalesLine.Quantity;
        SalesLine."Quantity Invoiced" := SalesLine.Quantity;
        SalesLine."Outstanding Quantity" := 0;
        SalesLine."Qty. Shipped Not Invoiced" := 0;
        SalesLine.Modify();

        // [WHEN] Run "Delete Invoiced Sales Orders".
        DeleteInvoiceSalesOrder(SalesHeader);

        // [THEN] The sales order is deleted.
        Assert.IsFalse(SalesHeader.Find(), 'Sales order is not deleted');
    end;

    [Test]
    procedure DeletingPurchOrderWithErroneouslyPostedItemChargeForZeroAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Delete Documents] [Item Charge]
        // [SCENARIO 404143] Delete purchase order with erroneously posted item charge for zero amount.
        Initialize();

        // [GIVEN] Mock purchase order with posted item charge for zero amount.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);
        PurchaseLine."Quantity Received" := PurchaseLine.Quantity;
        PurchaseLine."Quantity Invoiced" := PurchaseLine.Quantity;
        PurchaseLine."Outstanding Quantity" := 0;
        PurchaseLine."Qty. Rcd. Not Invoiced" := 0;
        PurchaseLine.Modify();

        // [WHEN] Run "Delete Invoiced Purchase Orders".
        DeleteInvoicePurchOrder(PurchaseHeader);

        // [THEN] The purchase order is deleted.
        Assert.IsFalse(PurchaseHeader.Find(), 'Purchase order is not deleted');
    end;

    [Test]
    procedure DeletingPurchaseLineArchiveDeletesPurchaseCommentLineArchive()
    var
        PurchCommentLineArchive: Record "Purch. Comment Line Archive";
        PurchaseLineArchive: Record "Purchase Line Archive";
    begin
        // when deleting a purchase line archive, the corresponding purchase comment line archive should be deleted but no other purchase comment line archive
        // incorrect filter PurchCommentLineArchive.SetRange("No.", "No."); on the OnDelete trigger of Purchase Line Archive caused issues.
        PurchaseLineArchive."Document Type" := PurchaseLineArchive."Document Type"::Order;
        PurchaseLineArchive."Document No." := CopyStr(LibraryRandom.RandText(MaxStrLen(PurchaseLineArchive."Document No.")), 1, MaxStrLen(PurchaseLineArchive."Document No."));
        PurchaseLineArchive."Line No." := 10000;
        PurchaseLineArchive."Doc. No. Occurrence" := 1;
        PurchaseLineArchive."Version No." := 1;
        PurchaseLineArchive."No." := CopyStr(LibraryRandom.RandText(MaxStrLen(PurchaseLineArchive."No.")), 1, MaxStrLen(PurchaseLineArchive."No."));
        PurchaseLineArchive.Insert();

        PurchCommentLineArchive."Document Type" := PurchaseLineArchive."Document Type";
        PurchCommentLineArchive."No." := PurchaseLineArchive."Document No."; // line to be deleted
        PurchCommentLineArchive."Document Line No." := PurchaseLineArchive."Line No.";
        PurchCommentLineArchive."Doc. No. Occurrence" := PurchaseLineArchive."Doc. No. Occurrence";
        PurchCommentLineArchive."Version No." := PurchaseLineArchive."Version No.";
        PurchCommentLineArchive."Line No." := 1;
        PurchCommentLineArchive.Insert();

        PurchCommentLineArchive."Document Type" := PurchaseLineArchive."Document Type";
        PurchCommentLineArchive."No." := PurchaseLineArchive."No."; // line should not be deleted
        PurchCommentLineArchive."Document Line No." := PurchaseLineArchive."Line No.";
        PurchCommentLineArchive."Doc. No. Occurrence" := PurchaseLineArchive."Doc. No. Occurrence";
        PurchCommentLineArchive."Version No." := PurchaseLineArchive."Version No.";
        PurchCommentLineArchive."Line No." := 1;
        PurchCommentLineArchive.Insert();

        PurchaseLineArchive.Delete(true);

        // still exists
        PurchCommentLineArchive.Get(PurchaseLineArchive."Document Type", PurchaseLineArchive."No.", PurchaseLineArchive."Doc. No. Occurrence", PurchaseLineArchive."Version No.", PurchaseLineArchive."Line No.", 1);
        // deleted
        asserterror PurchCommentLineArchive.Get(PurchaseLineArchive."Document Type", PurchaseLineArchive."Document No.", PurchaseLineArchive."Doc. No. Occurrence", PurchaseLineArchive."Version No.", PurchaseLineArchive."Line No.", 1);
        Assert.AssertRecordNotFound();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Delete Documents");
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Delete Documents");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        AllowPostedDocumentDeletionDate := LibraryERM.GetDeletionBlockedAfterDate();
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Delete Documents");
    end;

    local procedure ApprovedPurchaseDocumentScenario(DocumentType: Enum "Purchase Document Type"; var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandInt(10));

        PurchaseHeader.Status := PurchaseHeader.Status::Released;
        PurchaseHeader.Modify();

        PurchaseLine."Quantity Invoiced" := PurchaseLine.Quantity;
        PurchaseLine."Qty. to Invoice" := 0;
        PurchaseLine."Quantity Received" := PurchaseLine.Quantity;
        PurchaseLine."Qty. to Receive" := 0;
        PurchaseLine."Outstanding Quantity" := 0;
        PurchaseLine."Qty. Rcd. Not Invoiced" := 0;
        PurchaseLine."Qty. Assigned" := PurchaseLine.Quantity;
        PurchaseLine.Modify();

        // Exercise
        MockApprovalEntry(PurchaseHeader.RecordId);
    end;

    local procedure ApprovedSalesDocumentScenario(DocumentType: Enum "Sales Document Type"; var SalesHeader: Record "Sales Header")
    begin
        // Setup
        MockSalesOrder(DocumentType, SalesHeader);

        // Exercise
        MockApprovalEntry(SalesHeader.RecordId);
    end;

    local procedure ApprovedServiceDocumentScenario(DocumentType: Enum "Service Document Type"; var ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        // Setup

        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, '');

        ServiceHeader.Status := ServiceHeader.Status::Finished;
        ServiceHeader.Modify();

        ServiceLine.Quantity := LibraryRandom.RandInt(10);
        ServiceLine."Quantity Invoiced" := ServiceLine.Quantity;
        ServiceLine."Qty. to Invoice" := 0;
        ServiceLine."Quantity Shipped" := ServiceLine.Quantity;
        ServiceLine."Qty. to Ship" := 0;
        ServiceLine."Outstanding Quantity" := 0;
        ServiceLine."Qty. Shipped Not Invoiced" := 0;

        ServiceLine.Modify();

        // Exercise
        MockApprovalEntry(ServiceHeader.RecordId);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(100));  // Using RANDOM value for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor());
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        // LibraryRandom used for Random Quantity.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchOrderForSpecialOrder(var PurchaseHeader: Record "Purchase Header"; CustomerNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Sell-to Customer No.", CustomerNo);
        PurchaseHeader.Modify(true);
        LibraryPurchase.GetSpecialOrder(PurchaseHeader);
    end;

    local procedure CreatePurchOrderForDropShipment(var PurchaseHeader: Record "Purchase Header"; CustomerNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Sell-to Customer No.", CustomerNo);
        PurchaseHeader.Modify(true);
        LibraryPurchase.GetDropShipment(PurchaseHeader);
    end;

    local procedure CreateAndPostPurchInvoiceViaGetReceiptLines(ReceiptNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        PurchRcptLine.SetRange("Document No.", ReceiptNo);
        PurchRcptLine.FindFirst();

        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, PurchRcptLine."Pay-to Vendor No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        // LibraryRandom used for Random Quantity.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderForSpecialOrder(var SalesHeader: Record "Sales Header")
    var
        Purchasing: Record Purchasing;
        SalesLine: Record "Sales Line";
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", true);
        Purchasing.Modify(true);

        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderForDropShipment(var SalesHeader: Record "Sales Header")
    var
        Purchasing: Record Purchasing;
        SalesLine: Record "Sales Line";
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Modify(true);

        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoiceViaGetShipmentLines(ShipmentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        SalesShipmentLine.SetRange("Document No.", ShipmentNo);
        SalesShipmentLine.FindFirst();

        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, SalesShipmentLine."Bill-to Customer No.");
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateItemChargeAssignmentPurch(ItemChargePurchaseLine: Record "Purchase Line"; ItemPurchaseLine: Record "Purchase Line"; ItemCharge: Record "Item Charge"; Qty: Decimal)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        LibraryPurchase.CreateItemChargeAssignment(
          ItemChargeAssignmentPurch, ItemChargePurchaseLine, ItemCharge,
          ItemPurchaseLine."Document Type", ItemPurchaseLine."Document No.", ItemPurchaseLine."Line No.", ItemPurchaseLine."No.", Qty,
          ItemChargePurchaseLine."Direct Unit Cost");
        ItemChargeAssignmentPurch.Insert(true);
    end;

    local procedure FilterPurchaseHeaders(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        PurchaseHeader.SetRange("Document Type", DocumentType);
        PurchaseHeader.SetRange("No.", DocumentNo);
    end;

    local procedure FilterPurchaseLines(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
    end;

    local procedure FilterSalesHeaders(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange("No.", DocumentNo);
    end;

    local procedure FilterSalesLines(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
    end;

    local procedure FilterServiceHeaders(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; DocumentNo: Code[20])
    begin
        ServiceHeader.SetRange("Document Type", DocumentType);
        ServiceHeader.SetRange("No.", DocumentNo);
    end;

    local procedure FilterServiceLines(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; DocumentNo: Code[20])
    begin
        ServiceLine.SetRange("Document Type", DocumentType);
        ServiceLine.SetRange("No.", DocumentNo);
    end;

    local procedure FindPurchaseHeaderArchive(var PurchaseHeaderArchive: Record "Purchase Header Archive"; DocumentType: Enum "Purchase Document Type"; No: Code[20])
    begin
        PurchaseHeaderArchive.SetRange("Document Type", DocumentType);
        PurchaseHeaderArchive.SetRange("No.", No);
        PurchaseHeaderArchive.FindFirst();
    end;

    local procedure FindSalesHeaderArchive(var SalesHeaderArchive: Record "Sales Header Archive"; DocumentType: Enum "Sales Document Type"; No: Code[20])
    begin
        SalesHeaderArchive.SetRange("Document Type", DocumentType);
        SalesHeaderArchive.SetRange("No.", No);
        SalesHeaderArchive.SetRange("Version No.", 1); // required for CH
        SalesHeaderArchive.FindFirst();
    end;

    local procedure MockApprovalEntry(SourceRecordID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.Init();
        ApprovalEntry."Sequence No." := 1;
        ApprovalEntry."Table ID" := SourceRecordID.TableNo;
        ApprovalEntry."Sender ID" := UserId;
        ApprovalEntry."Record ID to Approve" := SourceRecordID;
        ApprovalEntry.Insert();
    end;

    local procedure MockSalesOrder(DocumentType: Enum "Sales Document Type"; var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        SalesHeader.Status := SalesHeader.Status::Released;
        SalesHeader.Modify();

        SalesLine."Quantity Invoiced" := SalesLine.Quantity;
        SalesLine."Qty. to Invoice" := 0;
        SalesLine."Quantity Shipped" := SalesLine.Quantity;
        SalesLine."Qty. to Ship" := 0;
        SalesLine."Outstanding Quantity" := 0;
        SalesLine."Qty. Shipped Not Invoiced" := 0;
        SalesLine."Qty. Assigned" := SalesLine.Quantity;
        SalesLine.Modify();
    end;

    local procedure MockBlanketAssemblyOrder(SalesHeaderNo: Code[20]; var AssemblyHeader: Record "Assembly Header"; var ATOLink: Record "Assemble-to-Order Link")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Blanket Order");
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        SalesLine.FindFirst();
        SalesLine."Qty. to Assemble to Order" := LibraryRandom.RandInt(10);
        SalesLine.Modify();

        AssemblyHeader.Init();
        AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::"Blanket Order";
        AssemblyHeader."No." := LibraryUtility.GenerateGUID();
        AssemblyHeader.Insert();

        ATOLink.Init();
        ATOLink.Type := ATOLink.Type::Sale;
        ATOLink."Assembly Document Type" := ATOLink."Assembly Document Type"::"Blanket Order";
        ATOLink."Assembly Document No." := AssemblyHeader."No.";
        ATOLink."Document Type" := ATOLink."Document Type"::"Blanket Order";
        ATOLink."Document No." := SalesHeaderNo;
        ATOLink."Document Line No." := SalesLine."Line No.";
        ATOLink.Insert();
    end;

    local procedure MockPostedSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; PostingDate: Date)
    begin
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := LibraryUtility.GenerateRandomCode(SalesInvoiceHeader.FieldNo("No."), DATABASE::"Sales Invoice Header");
        SalesInvoiceHeader."Posting Date" := PostingDate;
        SalesInvoiceHeader."No. Printed" := 1;
        // to avoid confirm on deletion
        SalesInvoiceHeader.Insert();
    end;

    local procedure MockPostedSalesCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; PostingDate: Date)
    begin
        SalesCrMemoHeader.Init();
        SalesCrMemoHeader."No." := LibraryUtility.GenerateRandomCode(SalesCrMemoHeader.FieldNo("No."), DATABASE::"Sales Invoice Header");
        SalesCrMemoHeader."Posting Date" := PostingDate;
        SalesCrMemoHeader."No. Printed" := 1;
        // to avoid confirm on deletion
        SalesCrMemoHeader.Insert();
    end;

    local procedure MockPostedPurchaseInvoice(var PurchInvHeader: Record "Purch. Inv. Header"; PostingDate: Date)
    begin
        PurchInvHeader.Init();
        PurchInvHeader."No." := LibraryUtility.GenerateRandomCode(PurchInvHeader.FieldNo("No."), DATABASE::"Sales Invoice Header");
        PurchInvHeader."Posting Date" := PostingDate;
        PurchInvHeader."No. Printed" := 1;
        // to avoid confirm on deletion
        PurchInvHeader.Insert();
    end;

    local procedure MockPostedPurchaseCrMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PostingDate: Date)
    begin
        PurchCrMemoHdr.Init();
        PurchCrMemoHdr."No." := LibraryUtility.GenerateRandomCode(PurchCrMemoHdr.FieldNo("No."), DATABASE::"Sales Invoice Header");
        PurchCrMemoHdr."Posting Date" := PostingDate;
        PurchCrMemoHdr."No. Printed" := 1;
        // to avoid confirm on deletion
        PurchCrMemoHdr.Insert();
    end;

    local procedure PostPurchaseDocument(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Find();
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure ReleaseAndArchiveSalesDoc(var SalesHeader: Record "Sales Header"; var NoOfArchivedVerAfterRelease: Integer)
    begin
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields("No. of Archived Versions");
        NoOfArchivedVerAfterRelease := SalesHeader."No. of Archived Versions";
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);
    end;

    local procedure RunReport(ReportNo: Integer; TableNo: Integer; FieldNo: Integer; FieldFilter: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        RecVar: Variant;
    begin
        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.SetRange(FieldFilter);
        RecVar := RecRef;
        REPORT.Run(ReportNo, false, false, RecVar);
        RecRef.Close();
    end;

    local procedure UpdateStockOutWarning(NewStockOutWarning: Boolean) OldStockOutWarning: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldStockOutWarning := SalesReceivablesSetup."Stockout Warning";
        SalesReceivablesSetup.Validate("Stockout Warning", NewStockOutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateQtyToReceiveOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; QtyToReceive: Decimal)
    begin
        PurchaseLine.Find();
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
    end;

    local procedure VerifyPurchaseLineArchive(PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLineArchive: Record "Purchase Line Archive";
    begin
        PurchaseLineArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLineArchive.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLineArchive.FindFirst();
        PurchaseLineArchive.TestField("No.", PurchaseLine."No.");
        PurchaseLineArchive.TestField("Unit of Measure Code", PurchaseLine."Unit of Measure Code");
        PurchaseLineArchive.TestField(Quantity, PurchaseLine.Quantity);
    end;

    local procedure VerifySalesLineArchive(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        SalesLineArchive: Record "Sales Line Archive";
    begin
        SalesLineArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesLineArchive.SetRange("Document No.", SalesHeader."No.");
        SalesLineArchive.FindFirst();
        SalesLineArchive.TestField("No.", SalesLine."No.");
        SalesLineArchive.TestField("Unit of Measure Code", SalesLine."Unit of Measure Code");
        SalesLineArchive.TestField(Quantity, SalesLine.Quantity);
    end;

    local procedure VerifyApprovalEntriesExist(SourceRecordID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.Init();
        ApprovalEntry.SetRange("Record ID to Approve", SourceRecordID);
        Assert.RecordIsNotEmpty(ApprovalEntry);
    end;

    local procedure VerifyApprovalEntriesDeleted(SourceRecordID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.Init();
        ApprovalEntry.SetRange("Record ID to Approve", SourceRecordID);
        Assert.RecordIsEmpty(ApprovalEntry)
    end;

    local procedure VerifyPurchaseDocumentDeleted(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        FilterPurchaseHeaders(PurchaseHeader, DocumentType, DocumentNo);
        Assert.RecordIsEmpty(PurchaseHeader);
        FilterPurchaseLines(PurchaseLine, DocumentType, DocumentNo);
        Assert.RecordIsEmpty(PurchaseLine);
    end;

    local procedure VerifySalesDocumentDeleted(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        FilterSalesHeaders(SalesHeader, DocumentType, DocumentNo);
        Assert.RecordIsEmpty(SalesHeader);
        FilterSalesLines(SalesLine, DocumentType, DocumentNo);
        Assert.RecordIsEmpty(SalesLine);
    end;

    local procedure VerifyServiceDocumentDeleted(DocumentType: Enum "Service Document Type"; DocumentNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        FilterServiceHeaders(ServiceHeader, DocumentType, DocumentNo);
        Assert.RecordIsEmpty(ServiceHeader);
        FilterServiceLines(ServiceLine, DocumentType, DocumentNo);
        Assert.RecordIsEmpty(ServiceLine);
    end;

    local procedure VerifyPostedSalesInvoiceDeleted(DocNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("No.", DocNo);
        Assert.RecordIsEmpty(SalesInvoiceHeader);
    end;

    local procedure VerifyPostedSalesInvoiceExists(DocNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("No.", DocNo);
        Assert.RecordIsNotEmpty(SalesInvoiceHeader);
    end;

    local procedure VerifyPostedSalesCrMemoDeleted(DocNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("No.", DocNo);
        Assert.RecordIsEmpty(SalesCrMemoHeader);
    end;

    local procedure VerifyPostedSalesCrMemoExists(DocNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("No.", DocNo);
        Assert.RecordIsNotEmpty(SalesCrMemoHeader);
    end;

    local procedure VerifyPostedPurchaseInvoiceDeleted(DocNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("No.", DocNo);
        Assert.RecordIsEmpty(PurchInvHeader);
    end;

    local procedure VerifyPostedPurchaseInvoiceExists(DocNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("No.", DocNo);
        Assert.RecordIsNotEmpty(PurchInvHeader);
    end;

    local procedure VerifyPostedPurchaseCrMemoDeleted(DocNo: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("No.", DocNo);
        Assert.RecordIsEmpty(PurchCrMemoHdr);
    end;

    local procedure VerifyPostedPurchaseCrMemoExists(DocNo: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("No.", DocNo);
        Assert.RecordIsNotEmpty(PurchCrMemoHdr);
    end;

    local procedure InvoicedSalesOrderWithItemCharge(var SalesHeader: Record "Sales Header") DocumentNo: Text[20]
    var
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        LibrarySales.SetStockoutWarning(false);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify(true);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        LibrarySales.CreateSalesHeader(
          SalesInvoiceHeader, SalesInvoiceHeader."Document Type"::Invoice, SalesHeader."Bill-to Customer No.");

        SalesGetShipment.SetSalesHeader(SalesInvoiceHeader);
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);

        LibrarySales.PostSalesDocument(SalesInvoiceHeader, true, true);

        SalesHeader.Find();
        ReleaseSalesDocument.Reopen(SalesHeader);
        SalesLine.Find();
        SalesLine.Validate(Quantity, 0);
        SalesLine.Modify(true);
    end;

    local procedure InvoicedPurchaseOrderWithItemCharger(var PurchaseHeader: Record "Purchase Header") DocumentNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoiceHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseLine."Document Type"::Order);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', '', LibraryRandom.RandDec(10, 2), '', 0D);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Validate("Qty. to Receive", 0);
        PurchaseLine.Modify(true);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        LibraryPurchase.CreatePurchHeader(
          PurchaseInvoiceHeader, PurchaseInvoiceHeader."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.");

        PurchGetReceipt.SetPurchHeader(PurchaseInvoiceHeader);
        PurchRcptLine.SetRange("Document No.", DocumentNo);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        LibraryPurchase.PostPurchaseDocument(PurchaseInvoiceHeader, true, true);

        PurchaseHeader.Find();
        ReleasePurchaseDocument.Reopen(PurchaseHeader);
        PurchaseLine.Find();
        PurchaseLine.Validate(Quantity, 0);
        PurchaseLine.Modify(true);
    end;

    local procedure DeleteInvoiceSalesOrder(SalesHeader: Record "Sales Header")
    var
        DeleteInvoicedSalesOrders: Report "Delete Invoiced Sales Orders";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", SalesHeader."No.");
        DeleteInvoicedSalesOrders.SetTableView(SalesHeader);
        DeleteInvoicedSalesOrders.UseRequestPage(false);
        DeleteInvoicedSalesOrders.Run();
    end;

    local procedure DeleteInvoicePurchOrder(PurchaseHeader: Record "Purchase Header")
    var
        DeleteInvoicedPurchOrders: Report "Delete Invoiced Purch. Orders";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        DeleteInvoicedPurchOrders.SetTableView(PurchaseHeader);
        DeleteInvoicedPurchOrders.UseRequestPage(false);
        DeleteInvoicedPurchOrders.Run();
    end;

    local procedure SetPurchArchiveQuotes(NewArchiveQuotes: Option) ArchiveQuotes: Option
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        ArchiveQuotes := PurchasesPayablesSetup."Archive Quotes";
        if ArchiveQuotes <> NewArchiveQuotes then begin
            PurchasesPayablesSetup."Archive Quotes" := NewArchiveQuotes;
            PurchasesPayablesSetup.Modify();
        end;
    end;

    local procedure SetSalesArchiveQuotes(NewArchiveQuotes: Option) ArchiveQuotes: Option
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        ArchiveQuotes := SalesReceivablesSetup."Archive Quotes";
        if ArchiveQuotes <> NewArchiveQuotes then begin
            SalesReceivablesSetup."Archive Quotes" := NewArchiveQuotes;
            SalesReceivablesSetup.Modify();
        end;
    end;

    local procedure MockPostedPurchaseReceipt(var PurchRcptHeader: array[2] of Record "Purch. Rcpt. Header"; PostingDate: array[2] of Date)
    begin
        PurchRcptHeader[1].Init();
        PurchRcptHeader[1]."No." := LibraryUtility.GenerateRandomCode(PurchRcptHeader[1].FieldNo("No."), DATABASE::"Purch. Rcpt. Header");
        PurchRcptHeader[1]."Posting Date" := PostingDate[1];
        PurchRcptHeader[1].Insert();

        PurchRcptHeader[2].Init();
        PurchRcptHeader[2]."No." := LibraryUtility.GenerateRandomCode(PurchRcptHeader[2].FieldNo("No."), DATABASE::"Purch. Rcpt. Header");
        PurchRcptHeader[2]."Posting Date" := PostingDate[2];
        PurchRcptHeader[2].Insert();
    end;

    local procedure MockPostedReturnShipment(var ReturnShipmentHeader: array[2] of Record "Return Shipment Header"; PostingDate: array[2] of Date)
    begin
        ReturnShipmentHeader[1].Init();
        ReturnShipmentHeader[1]."No." := LibraryUtility.GenerateRandomCode(ReturnShipmentHeader[1].FieldNo("No."), DATABASE::"Return Shipment Header");
        ReturnShipmentHeader[1]."Posting Date" := PostingDate[1];
        ReturnShipmentHeader[1].Insert();

        ReturnShipmentHeader[2].Init();
        ReturnShipmentHeader[2]."No." := LibraryUtility.GenerateRandomCode(ReturnShipmentHeader[2].FieldNo("No."), DATABASE::"Return Shipment Header");
        ReturnShipmentHeader[2]."Posting Date" := PostingDate[2];
        ReturnShipmentHeader[2].Insert();
    end;

    local procedure MockPostedSalesShipment(var SalesShipmentHeader: array[2] of Record "Sales Shipment Header"; PostingDate: array[2] of Date)
    begin
        SalesShipmentHeader[1].Init();
        SalesShipmentHeader[1]."No." := LibraryUtility.GenerateRandomCode(SalesShipmentHeader[1].FieldNo("No."), DATABASE::"Sales Shipment Header");
        SalesShipmentHeader[1]."Posting Date" := PostingDate[1];
        SalesShipmentHeader[1]."No. Printed" := 1;
        SalesShipmentHeader[1].Insert();

        SalesShipmentHeader[2].Init();
        SalesShipmentHeader[2]."No." := LibraryUtility.GenerateRandomCode(SalesShipmentHeader[2].FieldNo("No."), DATABASE::"Sales Shipment Header");
        SalesShipmentHeader[2]."Posting Date" := PostingDate[2];
        SalesShipmentHeader[2]."No. Printed" := 1;
        SalesShipmentHeader[2].Insert();
    end;

    local procedure MockPostedReturnReceipt(var ReturnReceiptHeader: array[2] of Record "Return Receipt Header"; PostingDate: array[2] of Date)
    begin
        ReturnReceiptHeader[1].Init();
        ReturnReceiptHeader[1]."No." := LibraryUtility.GenerateRandomCode(ReturnReceiptHeader[1].FieldNo("No."), DATABASE::"Return Receipt Header");
        ReturnReceiptHeader[1]."Posting Date" := PostingDate[1];
        ReturnReceiptHeader[1]."No. Printed" := 1;
        ReturnReceiptHeader[1].Insert();

        ReturnReceiptHeader[2].Init();
        ReturnReceiptHeader[2]."No." := LibraryUtility.GenerateRandomCode(ReturnReceiptHeader[2].FieldNo("No."), DATABASE::"Return Receipt Header");
        ReturnReceiptHeader[2]."Posting Date" := PostingDate[2];
        ReturnReceiptHeader[2]."No. Printed" := 1;
        ReturnReceiptHeader[2].Insert();
    end;

    local procedure VerifyPostedDocDeleted(TableId: Integer; FieldName: Text; FieldValue: Code[20])
    var
        DataTypeMgt: Codeunit "Data Type Management";
        RecRef: RecordRef;
        FieldReference: FieldRef;
    begin
        RecRef.Open(TableId);
        DataTypeMgt.FindFieldByName(RecRef, FieldReference, FieldName);
        FieldReference.SetRange(FieldValue);
        Assert.RecordIsEmpty(RecRef);
    end;

    local procedure VerifyPostedDocExists(TableId: Integer; FieldName: Text; FieldValue: Code[20])
    var
        DataTypeMgt: Codeunit "Data Type Management";
        RecRef: RecordRef;
        FieldReference: FieldRef;
    begin
        RecRef.Open(TableId);
        DataTypeMgt.FindFieldByName(RecRef, FieldReference, FieldName);
        FieldReference.SetRange(FieldValue);
        Assert.RecordIsNotEmpty(RecRef);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListPageHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerWithEnqueueMessage(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

