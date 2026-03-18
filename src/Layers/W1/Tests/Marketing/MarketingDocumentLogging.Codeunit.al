codeunit 136202 "Marketing Document Logging"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Archive] [Marketing]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTemplates: Codeunit "Library - Templates";
        IsInitialized: Boolean;
        ArchivedSalesHeaderError: Label '%1 %2=%3, %4=%5 must not exist.';

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ArchiveQuote()
    var
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Covers document number TC0046 - refer to TFS ID 21739.
        // Test Sales Line Archive after Archived Sales Quote.

        ArchiveSalesDocument(SalesLine."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ArchiveOrder()
    var
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Covers document number TC0046 - refer to TFS ID 21739.
        // Test Sales Line Archive after Archived Sales Order.

        ArchiveSalesDocument(SalesLine."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ArchiveReturnOrder()
    var
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Covers document number TC0046 - refer to TFS ID 21739.
        // Test Sales Line Archive after Archived Sales Return Order.

        ArchiveSalesDocument(SalesLine."Document Type"::"Return Order");
    end;

    local procedure ArchiveSalesDocument(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // 1. Setup: Create Sales Header and Sales Line with Type Item.
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType);

        // 2. Exercise: Archive the Sales Document.
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // 3. Verify: Verify the Created Sales Line Archive from Sales Document.
        VerifySalesLineArchive(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ArchiveQuoteTwice()
    var
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Covers document number TC0046 - refer to TFS ID 21739.
        // Test Sales Line Archive after Archived Sales Quote in Multiple Steps.

        ArchiveSalesDocumentTwice(SalesLine."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ArchiveOrderTwice()
    var
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Covers document number TC0046 - refer to TFS ID 21739.
        // Test Sales Line Archive after Archived Sales Order in Multiple Steps.

        ArchiveSalesDocumentTwice(SalesLine."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ArchiveReturnOrderTwice()
    var
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Covers document number TC0046 - refer to TFS ID 21739.
        // Test Sales Line Archive after Archived Sales Return Order in Multiple Steps.

        ArchiveSalesDocumentTwice(SalesLine."Document Type"::"Return Order");
    end;

    local procedure ArchiveSalesDocumentTwice(DocumentType: Enum "Sales Document Type")
    var
        Resource: Record Resource;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibraryResource: Codeunit "Library - Resource";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        Initialize();

        // 1. Setup: Create Sales Header and Sales Line with Type Item.
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType);

        // 2. Exercise: Archive the Sales Document, Create new Sales Line with Type Resource and again Archive the Sales Document.
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);
        LibraryResource.FindResource(Resource);

        // Use Random because value is not important.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, Resource."No.", LibraryRandom.RandInt(10));
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // 3. Verify: Verify the Created Sales Line Archive from Sales Document.
        VerifySalesLineArchive(SalesLine);
    end;

    [Test]
    [HandlerFunctions('StdSalesQuoteExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InteractionLogEntryQuote()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InteractionLogEntry: Record "Interaction Log Entry";
        SalesQuote: Report "Standard Sales - Quote";
    begin
        Initialize();

        // Covers document number TC0047 - refer to TFS ID 21739.
        // Test Sales Quote Report and Interaction Log entry.

        // 1. Setup: Create Sales Header and Sales Line with Type Item.
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote);
        LibraryReportDataset.SetFileName(LibraryUtility.GenerateGUID());
        SetRDLCReportLayout(REPORT::"Standard Sales - Quote");

        // 2. Exercise: Run Sales Quote Report with Log Interaction, Save it as as XLSX.
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeader.SetRange("No.", SalesHeader."No.");
        SalesQuote.SetTableView(SalesHeader);
        SalesQuote.InitializeRequest(true);
        Commit();
        SalesHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Quote", true, false, SalesHeader);

        // 3. Verify: Verify Saved Report have some data and Interaction Log Entry.
        LibraryUtilityOnPrem.CheckFileNotEmpty(LibraryReportDataset.GetFileName());
        InteractionLogEntry.SetRange("Contact No.", SalesHeader."Bill-to Contact No.");
        InteractionLogEntry.SetRange("Document No.", SalesHeader."No.");
        InteractionLogEntry.FindFirst();
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RestoreQuoteFromQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        // Covers document number TC0048 - refer to TFS ID 21739.
        // Test Sales Quote Successfully Restored from Archived Sales Quote.

        RestoreSalesDocument(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RestoreOrderFromOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        // Covers document number TC0049 - refer to TFS ID 21739.
        // Test Sales Order Successfully Restored from Archived Sales Order.

        RestoreSalesDocument(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RestoreReturnOrderFromOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        // Covers document number TC0049 - refer to TFS ID 21739.
        // Test Sales Return Order Successfully Restored from Archived Sales Return Order.

        RestoreSalesDocument(SalesHeader."Document Type"::"Return Order");
    end;

    local procedure RestoreSalesDocument(DocumentType: Enum "Sales Document Type")
    var
        Resource: Record Resource;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        LibraryResource: Codeunit "Library - Resource";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        Initialize();

        // 1. Setup: Create Sales Header, Sales Line with Type Item, Archive the Sales Document, Create new Sales Line for Type Resource and
        // again Archive Sales Document.
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType);
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);
        LibraryResource.FindResource(Resource);

        // Use Random because value is not important.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, Resource."No.", LibraryRandom.RandInt(10));
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // 2. Exercise: Restore the Sales Document from first archived Sales Document.
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.FindFirst();
        ArchiveManagement.RestoreSalesDocument(SalesHeaderArchive);

        // 3. Verify: Verify Sales Line after Restore Sales Document.
        VerifySalesLine(SalesHeaderArchive);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckCommentsQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        // Covers document number TC0050 - refer to TFS ID 21739.
        // Test Comments on Sales Quote Restored from Archived Sales Quote.

        CheckCommentsSalesDocument(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckCommentsOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        // Covers document number TC0050 - refer to TFS ID 21739.
        // Test Comments on Sales Order Restored from Archived Sales Order.

        CheckCommentsSalesDocument(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckCommentsReturnOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        // Covers document number TC0050 - refer to TFS ID 21739.
        // Test Comments on Sales Return Order Restored from Archived Sales Return Order.

        CheckCommentsSalesDocument(SalesHeader."Document Type"::"Return Order");
    end;

    local procedure CheckCommentsSalesDocument(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        SalesCommentLine: Record "Sales Comment Line";
        ArchiveManagement: Codeunit ArchiveManagement;
        Comment: Text[80];
        Comment2: Text[80];
    begin
        Initialize();

        // 1. Setup: Create Sales Header, Sales Line with Type Item, Create Comments for Sales Header and Sales Line, Archive the Sales
        // Document.
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, DocumentType, SalesHeader."No.", 0);
        Comment := SalesCommentLine.Comment;
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, DocumentType, SalesHeader."No.", SalesLine."Line No.");
        Comment2 := SalesCommentLine.Comment;
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // 2. Exercise: Delete Comments for Sales Header and Sales Line, Restore the Archived Sales Document.
        SalesCommentLine.SetRange("Document Type", SalesHeader."Document Type".AsInteger());
        SalesCommentLine.SetRange("No.", SalesHeader."No.");
        SalesCommentLine.DeleteAll(true);

        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.FindFirst();
        ArchiveManagement.RestoreSalesDocument(SalesHeaderArchive);

        // 3. Verify: Verify Comments on Service Header and Service Line.
        VerifySalesCommentLine(SalesHeader, 0, Comment);
        VerifySalesCommentLine(SalesHeader, SalesLine."Line No.", Comment2);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CommentsArchivePurchQuote()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        // Covers document number TC0050 - refer to TFS ID 21739.
        // Test Comments on Archived Purchase Quote.

        CheckCommentsPurchaseDocument(PurchaseHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CommentsArchivePurchOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        // Covers document number TC0050 - refer to TFS ID 21739.
        // Test Comments on Archived Purchase Order.

        CheckCommentsPurchaseDocument(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CommentsArchivePurchReturn()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        // Covers document number TC0050 - refer to TFS ID 21739.
        // Test Comments on Archived Purchase Return Order.

        CheckCommentsPurchaseDocument(PurchaseHeader."Document Type"::"Return Order");
    end;

    local procedure CheckCommentsPurchaseDocument(DocumentType: Enum "Purchase Document Type")
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCommentLine: Record "Purch. Comment Line";
        PurchCommentLine2: Record "Purch. Comment Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // 1. Setup: Create Purchase Header, Purchase Line with Type Item.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        // Use Random because value is not important.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // 2. Exercise: Create Comments for Purchase Header and Purchase Line, Archive the Purchase Document.
        LibraryPurchase.CreatePurchCommentLine(PurchCommentLine, DocumentType, PurchaseHeader."No.", 0);  // Use 0 for Purchase Header.
        LibraryPurchase.CreatePurchCommentLine(PurchCommentLine2, DocumentType, PurchaseHeader."No.", PurchaseLine."Line No.");
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);

        // 3. Verify: Verify Comments on Archived Purchase Document.
        VerifyPurchaseComments(PurchCommentLine);
        VerifyPurchaseComments(PurchCommentLine2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoArchiveDocumentOnMakeOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        Initialize();

        // Covers document number TC0051 - refer to TFS ID 21739.
        // Test No Archive Sales Quote created after make Order from Sales Quote with Archive Quotes and Orders False.

        // 1. Create Sales Header and Sales Line with Type Item, Modify Sales & Receivable Setup for Archive Quotes And Order field False,
        // stockout warning to false and Make Order from Sales Quote.
        CreateOrderFromQuote(SalesHeader, false);

        // 2. Verify: Verify Sales Header Archive not Created.
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        Assert.IsFalse(
          SalesHeaderArchive.FindFirst(),
          StrSubstNo(
            ArchivedSalesHeaderError, SalesHeaderArchive.TableCaption(), SalesHeaderArchive.FieldCaption("Document Type"),
            SalesHeaderArchive."Document Type", SalesHeaderArchive.FieldCaption("No."), SalesHeaderArchive."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchiveDocumentOnMakeOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        Initialize();

        // Covers document number TC0051 - refer to TFS ID 21739.
        // Test Archive Sales Quote created after make Order from Sales Quote with Archive Quotes and Orders True.

        // 1. Create Sales Header and Sales Line with Type Item, Modify Sales & Receivable Setup for Archive Quotes And Order field True,
        // stockout warning to false and Make Order from Sales Quote.
        LibrarySales.SetArchiveOrders(true);
        LibrarySales.SetArchiveQuoteAlways();
        CreateOrderFromQuote(SalesHeader, true);

        // 2. Verify: Verify Sales Header Archive Created.
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        // FIX SalesHeaderArchive.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoArchiveDocumentOnShipOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        Initialize();

        // Covers document number TC0052 - refer to TFS ID 21739.
        // Test No Archive Sales Order created on Posting Service Order as Ship with Archive Quotes and Orders False.

        // 1. Setup: Create Sales Header and Sales Line with Type Item, Modify Sales & Receivable Setup for Archive Quotes And
        // Order field False.
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        UpdateSalesAndReceivableSetup(false);

        // 2. Exercise: Post Sales Order as Ship.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // 3. Verify: Verify Sales Header Archive not Created.
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        Assert.IsFalse(
          SalesHeaderArchive.FindFirst(),
          StrSubstNo(
            ArchivedSalesHeaderError, SalesHeaderArchive.TableCaption(), SalesHeaderArchive.FieldCaption("Document Type"),
            SalesHeaderArchive."Document Type", SalesHeaderArchive.FieldCaption("No."), SalesHeaderArchive."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchiveDocumentOnShipOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        Initialize();

        // Covers document number TC0052 - refer to TFS ID 21739.
        // Test Archive Sales Order created on Posting Service Order as Ship with Archive Quotes and Orders True.

        // 1. Setup: Create Sales Header and Sales Line with Type Item, Modify Sales & Receivable Setup for Archive Quotes And
        // Order field True.
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        UpdateSalesAndReceivableSetup(true);

        // 2. Exercise: Post Sales Order as Ship.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // 3. Verify: Verify Sales Header Archive Created.
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.FindFirst();
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ArchivedSalesQuoteReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        ArchivedSalesQuote: Report "Archived Sales Quote";
        ArchiveManagement: Codeunit ArchiveManagement;
        FilePath: Text[1024];
    begin
        Initialize();

        // Covers document number TC0053 - refer to TFS ID 21739.
        // Test Archived Sales Quote Report successfully created.

        // 1. Setup: Create Sales Header and Sales Line with Type Item, Archive Sales Quote.
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote);
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // 2. Exercise: Save Archived Sales Quote as as XML and XLSX in local Temp folder.
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        ArchivedSalesQuote.SetTableView(SalesHeaderArchive);
        FilePath := TemporaryPath + Format(SalesHeaderArchive."Document Type") + SalesHeaderArchive."No." + '.xlsx';
        ArchivedSalesQuote.SaveAsExcel(FilePath);

        // 3. Verify: Verify Saved report have some Data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ArchivedSalesOrderReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        ArchivedSalesOrder: Report "Archived Sales Order";
        ArchiveManagement: Codeunit ArchiveManagement;
        FilePath: Text[1024];
    begin
        Initialize();

        // Covers document number TC0053 - refer to TFS ID 21739.
        // Test Archived Sales Order Report successfully created.

        // 1. Setup: Create Sales Header and Sales Line with Type Item, Archive Sales Quote.
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // 2. Exercise: Save Archived Sales Order as as XML and XLSX in local Temp folder.
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        ArchivedSalesOrder.SetTableView(SalesHeaderArchive);
        FilePath := TemporaryPath + Format(SalesHeaderArchive."Document Type") + SalesHeaderArchive."No." + '.xlsx';
        ArchivedSalesOrder.SaveAsExcel(FilePath);

        // 3. Verify: Verify Saved report have some Data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandlerFalse')]
    [Scope('OnPrem')]
    procedure ArchivedSalesReturnOrderReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        ArchSalesReturnOrder: Report "Arch. Sales Return Order";
        ArchiveManagement: Codeunit ArchiveManagement;
        FilePath: Text[1024];
    begin
        Initialize();

        // Covers document number TC0053 - refer to TFS ID 21739.
        // Test Arch. Sales Return Order Report successfully created.

        // 1. Setup: Create Sales Header and Sales Line with Type Item, Archive Sales Quote.
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order");
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // 2. Exercise: Save Arch. Sales Return Order as as XML and XLSX in local Temp folder.
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        ArchSalesReturnOrder.SetTableView(SalesHeaderArchive);
        FilePath := TemporaryPath + Format(SalesHeaderArchive."Document Type") + SalesHeaderArchive."No." + '.xlsx';
        ArchSalesReturnOrder.SaveAsExcel(FilePath);

        // 3. Verify: Verify Saved report have some Data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandlerFalse')]
    [Scope('OnPrem')]
    procedure SalesQuoteHeaderFromContact()
    var
        Contact: Record Contact;
        CustomerTemplate: Record "Customer Templ.";
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        // Test Create a Sales Quote from Contact.

        // 1. Setup: Create Contact, Customer Template.
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTemplate);
        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTemplate);

        // 2. Exercise: Create Sales Quote Header from Contact with Customer Template.
        SalesHeader.Init();
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Contact No.", Contact."No.");
        SalesHeader.Validate("Sell-to Customer Templ. Code", CustomerTemplate.Code);
        SalesHeader.Modify(true);

        // 3. Verify: Verify Values on Sales Header with Document Type Quote.
        VerifySalesHeaderQuoteValues(SalesHeader, Contact."No.", CustomerTemplate.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandlerFalse')]
    [Scope('OnPrem')]
    procedure SalesQuoteDocumentFromContact()
    var
        Contact: Record Contact;
        CustomerTemplate: Record "Customer Templ.";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Test Create a Sales Quote Document from Contact and Verify Values on Sales Quote Document.
        Initialize();
        // 1. Setup: Create Contact, Customer Template.
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTemplate);

        // 2. Exercise: Create Sales Quote Document from Contact with Customer Template and Random Quantity.
        SalesHeader.Init();
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Contact No.", Contact."No.");
        SalesHeader.Validate("Sell-to Customer Templ. Code", CustomerTemplate.Code);
        SalesHeader.Modify(true);
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);

        // 3. Verify: Verify Values on Sales Quote Document.
        VerifySalesHeaderQuoteValues(SalesHeader, Contact."No.", CustomerTemplate.Code);
        VerifySalesLineQuoteValues(SalesLine, Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandlerSpecific,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReleasedSalesQuoteAfterArchive()
    var
        Contact: Record Contact;
        CustomerTemplate: Record "Customer Templ.";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // Test Create Archive Document from Sales Quote Document with Contact and Release Sales Quote after Archiving.
        Initialize();
        // 1. Setup: Create Contact, Customer Template, Create Sales Quote Document from Contact with Customer Template and Random Quantity.
        // Archive the Sales Document.
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTemplate);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        SalesHeader.Init();
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Contact No.", Contact."No.");
        SalesHeader.Validate("Sell-to Customer Templ. Code", CustomerTemplate.Code);
        SalesHeader.Modify(true);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // 2. Exercise: Release Sales Document.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // 3. Verify: Verify Status on Sales Header.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.TestField(Status, SalesHeader.Status::Released);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RestoreSalesOrderWithDifferentLocation()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // Test and Verify that after restoring the acrhive document, Location on Sales Line do not get updated with location of Sales Header.

        // 1. Setup: Create sales order and archive the sales order.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrderWithDifferentLocation(SalesHeader, Customer."No.");
        ArchiveCreatedSalesOrder(SalesHeaderArchive, SalesHeader);

        // 2. Exercise: Restore archived sales order.
        ArchiveManagement.RestoreSalesDocument(SalesHeaderArchive);

        // 3. Verify: Sales line location not changed with header location.
        VerifySalesLine(SalesHeaderArchive);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler,ArchivedSalesQuoteReportHandler')]
    [Scope('OnPrem')]
    procedure ArchivedSalesQuoteReportWithVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        // Test Report Archived Sales Quote shows "VAT Amount Specification" when VAT Amount <> 0.
        ArchivedSalesReportWithVAT(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler,ArchivedSalesReturnOrderReportHandler')]
    [Scope('OnPrem')]
    procedure ArchivedSalesReturnOrderReportWithVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        // Test Report Archived Sales Return Order shows "VAT Amount Specification" when VAT Amount <> 0.
        ArchivedSalesReportWithVAT(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicePrintReportWithInteractionLogEntryAccRecPerm()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InteractionLogEntry: Record "Interaction Log Entry";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [SCENARIO 179174] Printing Posted Sales Invoice Report with Interaction Log Entry - Account Receivables Permission
        Initialize();

        // [GIVEN] Posted Sales Invoice "PSI" for Customer with Contact "C"
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice);
        OpenNewPostedSalesInvoice(
          PostedSalesInvoice,
          LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [GIVEN] Current User has Account Receivables Permission
        LibraryLowerPermissions.SetAccountReceivables();

        // [WHEN] Posted Sales Invoice Report printed
        PostedSalesInvoice.Print.Invoke();

        // [THEN] Interaction Log Entry for Contact "C" and Document No. "PSI" created
        InteractionLogEntry.SetRange("Contact No.", SalesHeader."Bill-to Contact No.");
        InteractionLogEntry.SetRange("Document No.", PostedSalesInvoice."No.".Value);
        Assert.RecordIsNotEmpty(InteractionLogEntry);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicePrintReportWithInteractionLogEntrySalesDocPostPerm()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InteractionLogEntry: Record "Interaction Log Entry";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [SCENARIO 179174] Printing Posted Sales Invoice Report with Interaction Log Entry - SALES DOC, POST Permission
        Initialize();

        // [GIVEN] Posted Sales Invoice "PSI" for Customer with Contact "C"
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice);
        OpenNewPostedSalesInvoice(
          PostedSalesInvoice,
          LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [GIVEN] Current User has SALES DOC, POST Permission
        LibraryLowerPermissions.SetSalesDocsPost();

        // [WHEN] Posted Sales Invoice Report printed
        PostedSalesInvoice.Print.Invoke();

        // [THEN] Interaction Log Entry for Contact "C" and Document No. "PSI" created
        InteractionLogEntry.SetRange("Contact No.", SalesHeader."Bill-to Contact No.");
        InteractionLogEntry.SetRange("Document No.", PostedSalesInvoice."No.".Value);
        Assert.RecordIsNotEmpty(InteractionLogEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchiveQuoteOnMakeInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        Initialize();

        // [FEATURE] [Quote] [Invoice]
        // [SCENARIO 366380] Archive Sales Quote created after "Make Invoice" from Sales Quote with Archive Quotes set True
        // [WHEN] Created Sales Quote and ran "Make Invoice" with Archive Quotes set True
        CreateInvoiceFromQuote(SalesHeader);

        // [THEN] Sales Quote is archived
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        Assert.RecordCount(SalesHeaderArchive, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyArchivedSalesOrderReportExecutedWithDifferentDocNoOccurence()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesHeader3: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        ArchivedSalesOrder: Report "Archived Sales Order";
        FilePath: Text[1024];
    begin
        // [SCENARIO: 491374] Error when Printing Archived Sales Order If the document is of the same versions but has different Doc. No. Occurence
        Initialize();

        // [GIVEN] Setup: Create Sales Header and Sales Line with Type Item, Archive Sales Order.
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // [THEN] Archive Sales Order 1 and created Sales Order 2 using deleted Sales Order 1
        SalesHeader2 := SalesHeader;
        SalesOrderPageOpenArchiveAndDelete(SalesHeader);
        SalesHeader2.Insert(true);

        // [THEN] Add line item to Sales Order 2, and archive the Sales Order 2 and create Sales Order 3
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader2, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesHeader3 := SalesHeader2;
        SalesOrderPageOpenArchiveAndDelete(SalesHeader2);
        SalesHeader3.Insert(true);

        // [THEN] Add line item to Sales Order 3, and archive the Sales Order 3
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader3, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesOrderPageOpenArchiveAndDelete(SalesHeader3);

        // [THEN] Save Archived Sales Order as as XML and XLSX in local Temp folder.
        SalesHeaderArchive.SetRange("Document Type", SalesHeader3."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader3."No.");
        ArchivedSalesOrder.SetTableView(SalesHeaderArchive);
        FilePath := TemporaryPath + Format(SalesHeaderArchive."Document Type") + SalesHeaderArchive."No." + '.xlsx';

        // [VERIFY] Verify: Test Archived Sales Order Report successfully created and Saved report have some Data
        ArchivedSalesOrder.SaveAsExcel(FilePath);
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    local procedure Initialize()
    var
        ReportSelections: Record "Report Selections";
        CompanyInformation: Record "Company Information";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Marketing Document Logging");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Marketing Document Logging");

        LibrarySales.SetCreditWarningsToNoWarnings();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ReportSelections.DeleteAll();
        CreateDefaultReportSelection();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibraryTemplates.EnableTemplatesFeature();

        CompanyInformation.Get();
        CompanyInformation."SWIFT Code" := 'A';
        CompanyInformation.Modify();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Marketing Document Logging");
    end;

    local procedure ArchivedSalesReportWithVAT(DocumentType: Enum "Sales Document Type")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ArchiveManagement: Codeunit ArchiveManagement;
        VATProdPostingGroup: Code[20];
    begin
        // Setup: Create and archive Sales Return Order.
        Initialize();
        VATProdPostingGroup := CreateSalesDocumentWithVAT(SalesHeader, SalesLine, DocumentType);
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // Exercise: Run Report Archived Sales Quote / Report Archived Sales Return Order.
        case DocumentType of
            SalesHeader."Document Type"::Quote:
                RunReportArchivedSalesQuote(SalesHeader);
            SalesHeader."Document Type"::"Return Order":
                RunReportArchivedSalesReturnOrder(SalesHeader);
        end;

        // Verify: Verify "VAT Amount Specification" shows in Report Archived Sales Return Order when VAT Amount <> 0.
        GeneralLedgerSetup.Get();
        VerifyArchivedSalesReportWithVAT(
          VATProdPostingGroup, Round(SalesLine."VAT %" / 100 * SalesLine."Line Amount", GeneralLedgerSetup."Amount Rounding Precision"));
    end;

    local procedure ArchiveCreatedSalesOrder(var SalesHeaderArchive: Record "Sales Header Archive"; SalesHeader: Record "Sales Header")
    var
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);
        SalesHeader.CalcFields("No. of Archived Versions");
        SalesHeaderArchive.Get(
          SalesHeader."Document Type", SalesHeader."No.", SalesHeader."Doc. No. Occurrence", SalesHeader."No. of Archived Versions");
    end;

    local procedure CreateDefaultReportSelection()
    var
        ReportSelections: Record "Report Selections";
    begin
        CreateReportSelection(ReportSelections.Usage::"S.Invoice", '1', REPORT::"Standard Sales - Invoice");
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.CreateLocation(Location);
        exit(Location.Code);
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateInvoiceFromQuote(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote);
        LibrarySales.SetArchiveQuoteAlways();
        Commit();
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Invoice", SalesHeader);
    end;

    local procedure CreateOrderFromQuote(var SalesHeader: Record "Sales Header"; ArchiveQuotesAndOrders: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        // 1. Setup: Create Sales Header and Sales Line with Type Item, Modify Sales & Receivable Setup for Archive Quotes And Order field
        // and stockout warning to false.
        CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote);
        UpdateSalesAndReceivableSetup(ArchiveQuotesAndOrders);
        LibrarySales.SetStockoutWarning(false);
        Commit();

        // 2. Exercise: Make Order from Sales Quote.
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order", SalesHeader);
    end;

    [Normal]
    local procedure CreateReportSelection(Usage: Enum "Report Selection Usage"; Sequence: Code[10]; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Init();
        ReportSelections.Usage := Usage;
        ReportSelections.Sequence := Sequence;
        ReportSelections."Report ID" := ReportID;
        ReportSelections.Insert();
    end;

    local procedure CreateSalesDocumentWithItem(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    begin
        Initialize();
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        // Use Random because value is not important.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesOrderWithDifferentLocation(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Location Code", CreateLocation());
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(100, 2));
        CreateSalesLineWithLocation(SalesHeader, SalesLine);
    end;

    local procedure CreateSalesLineWithLocation(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Location Code", CreateLocation());
        SalesLine.Modify(true);
    end;

    local procedure CreateCustomerWithVAT(VATBusPostingGroup: Code[20]): Code[20]
    begin
        exit(
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATBusPostingGroup));
    end;

    local procedure CreateSalesDocumentWithUnitPrice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithVAT(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"): Code[10]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
        CustomerNo: Code[20];
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CustomerNo := CreateCustomerWithVAT(VATPostingSetup."VAT Bus. Posting Group");
        Item.Get(CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        CreateSalesDocumentWithUnitPrice(SalesHeader, SalesLine, DocumentType, CustomerNo, Item."No.");
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure OpenNewPostedSalesInvoice(var PostedSalesInvoice: TestPage "Posted Sales Invoice"; PostedDocNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(PostedDocNo);
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
    end;

    local procedure UpdateSalesAndReceivableSetup(ArchiveOrders: Boolean)
    begin
        LibrarySales.SetArchiveOrders(ArchiveOrders);
    end;

    local procedure RunReportArchivedSalesQuote(SalesHeader: Record "Sales Header")
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        ArchivedSalesQuote: Report "Archived Sales Quote";
    begin
        Commit();
        Clear(ArchivedSalesQuote);
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        ArchivedSalesQuote.SetTableView(SalesHeaderArchive);
        ArchivedSalesQuote.Run();
    end;

    local procedure RunReportArchivedSalesReturnOrder(SalesHeader: Record "Sales Header")
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        ArchSalesReturnOrder: Report "Arch. Sales Return Order";
    begin
        Commit();
        Clear(ArchSalesReturnOrder);
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        ArchSalesReturnOrder.SetTableView(SalesHeaderArchive);
        ArchSalesReturnOrder.Run();
    end;

    local procedure VerifyPurchaseComments(PurchCommentLine: Record "Purch. Comment Line")
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        PurchCommentLineArchive: Record "Purch. Comment Line Archive";
    begin
        PurchaseHeaderArchive.SetRange("Document Type", PurchCommentLine."Document Type".AsInteger());
        PurchaseHeaderArchive.SetRange("No.", PurchCommentLine."No.");
        PurchaseHeaderArchive.FindFirst();

        PurchCommentLineArchive.Get(
          PurchaseHeaderArchive."Document Type", PurchaseHeaderArchive."No.", PurchaseHeaderArchive."Doc. No. Occurrence",
          PurchaseHeaderArchive."Version No.", PurchCommentLine."Document Line No.", PurchCommentLine."Line No.");
        PurchCommentLineArchive.TestField(Comment, PurchCommentLine.Comment);
    end;

    local procedure VerifySalesCommentLine(SalesHeader: Record "Sales Header"; DocumentLineNo: Integer; Comment: Text[80])
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        SalesCommentLine.SetRange("Document Type", SalesHeader."Document Type".AsInteger());
        SalesCommentLine.SetRange("No.", SalesHeader."No.");
        SalesCommentLine.SetRange("Document Line No.", DocumentLineNo);
        SalesCommentLine.FindFirst();
        SalesCommentLine.TestField(Comment, Comment);
    end;

    local procedure VerifySalesLine(SalesHeaderArchive: Record "Sales Header Archive")
    var
        SalesLineArchive: Record "Sales Line Archive";
        SalesLine: Record "Sales Line";
    begin
        SalesLineArchive.SetRange("Document Type", SalesHeaderArchive."Document Type");
        SalesLineArchive.SetRange("Document No.", SalesHeaderArchive."No.");
        SalesLineArchive.SetRange("Version No.", SalesHeaderArchive."Version No.");
        SalesLineArchive.FindSet();
        repeat
            SalesLine.Get(SalesHeaderArchive."Document Type", SalesHeaderArchive."No.", SalesLineArchive."Line No.");
            SalesLine.TestField(Type, SalesLineArchive.Type);
            SalesLine.TestField("No.", SalesLineArchive."No.");
            SalesLine.TestField(Quantity, SalesLineArchive.Quantity);
            SalesLine.TestField("Location Code", SalesLineArchive."Location Code");
        until SalesLineArchive.Next() = 0;
    end;

    local procedure VerifySalesHeaderQuoteValues(SalesHeader: Record "Sales Header"; SellToContactNo: Code[20]; SellToCustomerTemplateCode: Code[20])
    begin
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.TestField("Sell-to Contact No.", SellToContactNo);
        SalesHeader.TestField("Sell-to Customer Templ. Code", SellToCustomerTemplateCode);
        SalesHeader.TestField("Order Date", WorkDate());
        SalesHeader.TestField("Document Date", WorkDate());
    end;

    local procedure VerifySalesLineArchive(SalesLine: Record "Sales Line")
    var
        SalesLineArchive: Record "Sales Line Archive";
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        SalesLine.FindSet();
        SalesHeaderArchive.SetRange("Document Type", SalesLine."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesLine."Document No.");
        SalesHeaderArchive.FindLast();
        SalesLineArchive.SetRange("Document Type", SalesHeaderArchive."Document Type");
        SalesLineArchive.SetRange("Document No.", SalesHeaderArchive."No.");
        SalesLineArchive.SetRange("Version No.", SalesHeaderArchive."Version No.");
        repeat
            SalesLineArchive.SetRange("Line No.", SalesLine."Line No.");
            SalesLineArchive.FindFirst();
            SalesLineArchive.TestField(Type, SalesLine.Type);
            SalesLineArchive.TestField("No.", SalesLine."No.");
            SalesLineArchive.TestField(Quantity, SalesLine.Quantity);
        until SalesLine.Next() = 0;
    end;

    local procedure VerifySalesLineQuoteValues(SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.", ItemNo);
        SalesLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyArchivedSalesReportWithVAT(VATProdPostingGroup: Code[20]; VATAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VATAmountLine__VAT_Identifier_', VATProdPostingGroup);
        LibraryReportDataset.AssertElementWithValueExists('VATAmountLine__VAT_Amount_', VATAmount);
    end;

    local procedure SetRDLCReportLayout(ReportID: Integer)
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        ReportLayoutSelection.SetRange("Report ID", ReportID);
        ReportLayoutSelection.SetRange("Company Name", CompanyName);
        if ReportLayoutSelection.FindFirst() then begin
            ReportLayoutSelection.Type := ReportLayoutSelection.Type::"RDLC (built-in)";
            ReportLayoutSelection."Custom Report Layout Code" := '';
            ReportLayoutSelection.Modify();
        end else begin
            ReportLayoutSelection.Validate("Report ID", ReportID);
            ReportLayoutSelection."Company Name" := CompanyName();
            ReportLayoutSelection.Type := ReportLayoutSelection.Type::"RDLC (built-in)";
            ReportLayoutSelection."Custom Report Layout Code" := '';
            ReportLayoutSelection.Insert();
        end;

        TenantReportLayoutSelection.Init();
        TenantReportLayoutSelection."Company Name" := CompanyName();
        TenantReportLayoutSelection."Layout Name" := ReportLayoutSelection."Report Name";
        TenantReportLayoutSelection."Report ID" := ReportID;
        if not TenantReportLayoutSelection.Insert(true) then
            TenantReportLayoutSelection.Modify(true);
    end;

    local procedure SalesOrderPageOpenArchiveAndDelete(SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.Filter.SetFilter("Document Type", Format(SalesHeader."Document Type"::Order));
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");
        SalesOrder."Archive Document".Invoke();
        SalesOrder.Close();

        SalesHeader.Delete(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandlerSpecific(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Question: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ArchivedSalesQuoteReportHandler(var ArchivedSalesQuote: TestRequestPage "Archived Sales Quote")
    begin
        ArchivedSalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ArchivedSalesReturnOrderReportHandler(var ArchivedSalesReturnOrder: TestRequestPage "Arch. Sales Return Order")
    begin
        ArchivedSalesReturnOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceRequestHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesQuoteExcelRequestPageHandler(var StandardSalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
        StandardSalesQuote.SaveAsExcel(LibraryReportDataset.GetFileName());
    end;
}
