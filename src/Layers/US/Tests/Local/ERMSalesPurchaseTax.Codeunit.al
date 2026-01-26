codeunit 142050 "ERM Sales/Purchase Tax"
{
    //
    // Check the functionalities of Sales/Purchase Tax.
    //  1. Verify that G/L Entry and VAT entry should be exist after posting Sales Return Order with Tax Liable.
    //  2. Verify Creation of Sales Tax Group.
    //  3. Verify Creation of Sales Tax Jurisdiction.
    //  4. Verify creation of Sales Tax Area.
    //  5. Verify Creation of Sales Tax Detail.
    //  6. Verify Posted Purchase Credit Memo after posting Purchase Credit Memo with Tax Liable.
    //  7. Verify Posted Purchase Invoice after posting Purchase Inoice with Tax Liable.
    //  8. Verify G/L Entry after posting Purchase Order with Tax Liable.
    //  9. Verify Purchase Order after Make Order from Purchase Blanket Order with Tax Liable.
    // 10. Verify Purchase Order after Make Order from Purchase Quote with Tax Liable.
    // 11. Verify Posted Service Credit Memo after posting Service Credit Memo with Tax Liable.
    // 12. Verify Posted Service Shipment after posting Service Order with Tax Liable.
    // 13. Verify created Service Line after Make Order from Service Quote with Tax Liable.
    // 14. Verify Sales Order after Make Order from Sales Blanket Order with Tax Liable.
    // 15. Verify G/L Entry after posting Sales Credit Memo with Tax Liable.
    // 16. Verify that G/L Entry and VAT entry after posting Sales Invoice with Tax Liable.
    // 17. Verify that G/L Entry and VAT entry after posting Sales Order with Tax Liable.
    // 18. Verify Sales Order after Make Order from Sales Quote with Tax Liable.
    // 19. Verify that G/L Entry and VAT Entry after posting Service Invoice with Tax Liable.
    // 20. Verify Amount after posting Invoice using Sales Journal in G/L Entry using currency.
    // 21. Verify Amount after posting Credit Memo using Sales Journal in G/L Entry using currency.
    // 22. Verify Amount after posting Invoice using Sales Journal in G/L Entry without using currency.
    // 23. Verify G/L Entry after posting Payment applied with Invoice using Currency.
    // 24. Verify G/L Entry after posting Payment applied with Credit Memo using Currency.
    // 25. Verify G/L Entry after posting Payment applied with Invoice  without using Currency.
    // 26. Verify Tax Amount on Sales Order Statistics.
    // 27. Verify values on Sales Tax Lines page using Sales Order Statistics with Tax Liable.
    // 28. Verify Posted Sales Invoice after posting Sales Order with Tax Liable.
    // 29. Verify G/L Entry after applying Refund with Credit Memo using General Journal Line.
    // 30. Verify Tax Amount on Sales Credit Memo Statistics page.
    // 31. Verify values on Sales Tax Lines page using Sales Credit Memo Statistics page.
    // 32. Verify G/L Entry after applying Payment with Invoice using General Journal Line with Currency.
    // 33. Verify values on Sales Line Archive after archiving Sales Order.
    // 34. Verify values on Sales Header Archive after archiving Sales Order and verify G/L Entry Amount.
    // 35. Verify G/L Entry after applying Payment with Invoice using General Journal Line.
    // 36. Verify G/L Entry Amount after post Sales Order after Make Order from Sales Blanket Order.
    // 37. Verify Tax Amount on Sales Quote Statistics page.
    // 38. Verify Tax Amount on Sales Order Statistics created after Make Order from Sales Quote.
    // 39. Verify G/L Entry Amount after post Sales Order after Make Order from Sales Quote.
    // 40. Verify G/L Entry Amount after post Sales Order using Make Order from Sales Quote with Customer Invoice Discount.
    // 41. Verify values on Sales Tax Lines page using Service Order Statistics page.
    // 42. Verify Tax Amount on Sales Credit Memo Statistics page.
    // 43. Verify that multiple PAC web services can be defined and any one can be selected in G/L Setup.
    // 44. Verify error while Requesting Stamp Document on Posted Sales Invoice if PAC certificate is not installed.
    // 45. Verify GST/HST field of VAT Entry for posted purchase invoice.
    // 46. Verify options in the field GST/HST of Gen. Journal Line.
    // 47. Verify options in the field GST/HST of VAT Entry.
    // 48. Verify error while Requesting Stamp Document on Posted Sales Invoice if PAC Environment is set to Disable in G/L Setup.
    // 49 Verify Sales Document should not get Posted Without Description on Sales Line.
    // 50. Verify Service Document Should not get Posted Without Description on Service Line.
    // 51. Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_General when Sales Order open.
    // 52. Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_Invoice when Sales Order open.
    // 53. Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_Shipping when Sales Order open.
    // 54. Verify Sales Tax Amount Field is Editable on Sales Tax Lines_Prepayment when Sales Order open.
    // 55. Verify Tax Amount not Editable after Releasing on Sales Tax Lines_Shipping on Sales Order Statistics.
    // 56. Verify Tax Amount is Editable after Releasing and Tax Amount should be Updated Amount after Reopening Sales Order.
    // 57. Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_General when Purchase Order open.
    // 58. Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_Invoice when Purchase Order open.
    // 59. Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_Shipping when Purchase Order open.
    // 60. Verify Sales Tax Amount Field is Editable on Sales Tax Lines_Prepayment when Purchase Order open.
    // 59. Verify Tax Amount not Editable after Releasing on Sales Tax Lines_Shipping on Purchase Order Statistics.
    // 60. Verify Tax Amount is Editable after Releasing and Tax Amount should be Updated Amount after Reopening Purchase Order.
    // 61. Verify Tax Amount and Total are correct in Sales Invoice Test Report when using Tax Liable with mutiple Tax Jurisdictions and US Country.
    // 62. Verify Tax Amount and Total are correct in Sales Invoice Test Report when using Tax Liable with mutiple Tax Jurisdictions and CA Country.
    // 63. Verify Tax Amount and Total are correct in Purchase Invoice Test Report when using Tax Liable with mutiple Tax Jurisdictions and US Country.
    // 64. Verify Tax Amount and Total are correct in Purchase Invoice Test Report when using Tax Liable with mutiple Tax Jurisdictions and CA Country.
    //
    // Covers Test Cases for WI - 327533
    // ----------------------------------------------------------------------------------------------
    // Test Function Name                                                                      TFS ID
    // ----------------------------------------------------------------------------------------------
    // GLEntryAfterPostSalesRetOrder                                                           171355
    // SalesTaxGroup, SalesTaxJurisdiction, SalesTaxArea, SalesTaxDetail                       171356
    //
    // Covers Test Cases for WI - 327940
    // ----------------------------------------------------------------------------------------------
    // Test Function Name                                                                      TFS ID
    // ----------------------------------------------------------------------------------------------
    // PostedPurchCrMemoUsingTaxLiable                                                         171357
    // PostedPurchaseInvoiceUsingTaxLiable                                                     171358
    // GLEntryAfterPostPurchaseOrderUsingTaxLiable                                             171359
    // PurchaseBlanketOrderUsingMakeOrderUsingTaxLiable                                        171360
    // PurchaseQuoteUsingMakeOrderUsingTaxLiable                                               171361
    // PostedServiceCrMemoUsingTaxLiable                                                       171362
    // PostedServiceShpmtUsingTaxLiable                                                        171363
    // ServiceOrderUsingMakeOrderUsingTaxLiable                                                171364
    //
    // Covers Test Cases for WI - 327557
    // ----------------------------------------------------------------------------------------------
    // Test Function Name                                                                      TFS ID
    // ----------------------------------------------------------------------------------------------
    // MakeOrderFromSalesBlanketOrderUsingTaxLiable                                            171349
    // GLEntryAfterPostSalesCrMemoUsingTaxLiable                                               171351
    // GLEntryAfterPostSalesInvoiceUsingTaxLiable                                              171352
    // GLEntryAfterPostSalesOrderUsingTaxLiable                                                171353
    // MakeOrderFromSalesQuoteUsingTaxLiable                                                   171354
    // PostedServiceInvoiceUsingTaxLiable                                                      185550
    //
    // Covers Test Cases for WI - 329406
    // ----------------------------------------------------------------------------------------------
    // Test Function Name                                                                      TFS ID
    // ----------------------------------------------------------------------------------------------
    // InvoiceUsingSalesJournalWithCurrency, CrMemoUsingSalesJournalWithCurrency               170975
    // InvoiceUsingSalesJournal, ApplyGenJournalUsingInvoice                                   171018
    // ApplyGenJournalUsingInvoiceWithCurrency                                                 170978
    // ApplyGenJournalUsingCrMemoWithCurrency
    //
    // Covers Test Cases for WI - 331405
    // ----------------------------------------------------------------------------------------------
    // Test Function Name                                                                      TFS ID
    // ----------------------------------------------------------------------------------------------
    // StatisticsSalesOrderUsingTaxLiable, SalesTaxLinesUsingTaxLiable
    // ValuesAfterPostSalesOrderUsingTaxLiable                                                 171016
    // ApplyRefundGenJournalLineUsingCrMemo                                                    171021
    // StatisticsSalesCrMemoUsingTaxLiable
    // SalesTaxLinesUsingSalesCrMemo                                                           171005
    // ApplyInvoiceGenJournalLineUsingCurrency                                                 171984
    // SalesOrderArchive, PostSalesOrderArchive                                                170986
    //
    // Covers Test Cases for WI - 329407
    // ----------------------------------------------------------------------------------------------
    // Test Function Name                                                                      TFS ID
    // ----------------------------------------------------------------------------------------------
    // ApplyPaymentGenJournalLineUsingOrder                                                    171022
    // MakeOrderFromSalesBlanketOrderAndPost                                                   171024
    // StatisticsOnSalesQuoteUsingTaxLiable, StatisticsOnSalesOrderAfterMakeOrderFromSalesQuote
    // GLEntryAfterPostSalesOrderUsingMakeOrder                                                286290
    // GLEntryAfterPostSalesOrderUsingMakeOrderWithInvDisc                                     171023
    // VATLinesUsingStatisticsOnServiceOrderTaxLiable                                          171025
    // StatisticsOnServiceCrMemoUsingTaxLiable                                                 171027
    //
    // Covers Test Cases for WI - 335012
    // ----------------------------------------------------------------------------------------------
    // Test Function Name                                                                      TFS ID
    // ----------------------------------------------------------------------------------------------
    // GeneralLedgerSetupWithMultiplePACServices                                               299315
    //
    // Covers Test Cases for WI - 330785
    // ----------------------------------------------------------------------------------------------
    // Test Function Name                                                                      TFS ID
    // ----------------------------------------------------------------------------------------------
    // GSTHSTInVATEntryForPostedPurchaseDocument                                               202401
    // OptionsInTheFieldGSTHSTOfGenJournalLine                                                 202399
    // OptionsInTheFieldGSTHSTOfVATEntry                                                       202400
    //
    // Covers Test Cases: Bug ID: 331437
    // -----------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                      TFS Bug ID
    // -----------------------------------------------------------------------------------------------------------------------------------
    // PostSalesDocWithoutDescription,PostServiceDocWithoutDescription
    //
    // Covers Test Cases: Bug ID: 335910
    // --------------------------------------------------------------------------------------------------
    // Test Function Name                                                                      TFS Bug ID
    // --------------------------------------------------------------------------------------------------
    // NoOfVATLinesGeneralWhenSalesOrderOpen,NoVATLinesInvoiceWhenSalesOrderOpen
    // NoVATLinesShippingWhenSalesOrderOpen,NoVATLinesPrepaymentWhenSalesOrderOpen
    // NoVATLinesShippingAfterSalesOrderReleased,SalesTaxAmountWhenSalesOrderReopen,
    // NoOfVATLinesGeneralWhenPurchaseOrderOpen,NoOfVATLinesInvoiceWhenPurchaseOrderOpen,
    // NoOfVATLinesShippingWhenPurchaseOrderOpen,NoOfVATLinesPrepaymentWhenPurchaseOrderOpen
    // NoVATLinesShippingAfterPurchaseOrderReleased,SalesTaxAmountWhenPurchaseOrderReopen
    //
    // Covers Test Cases: Bug ID: 343158
    // --------------------------------------------------------------------------------------------------
    // Test Function Name                                                                      TFS Bug ID
    // --------------------------------------------------------------------------------------------------
    // SalesInvoiceTestReportUsingTaxLiableWithUSCountry
    // SalesInvoiceTestReportUsingTaxLiableWithCACountry
    // PurchaseInvoiceTestReportUsingTaxLiableWithUSCountry
    // PurchaseInvoiceTestReportUsingTaxLiableWithCACountry
    //
    // Bug ID: 100401
    // --------------------------------------------------------------------------------------------------
    // Test Function Name                                                                      TFS Bug ID
    // --------------------------------------------------------------------------------------------------
    // SalesOrderLineTaxAmountRouding
    // PurchaseOrderLineTaxAmountRouding

    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Tax]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERMTax: Codeunit "Library - ERM Tax";
        ERMSalesPurchaseTax: Codeunit "ERM Sales/Purchase Tax";
        isInitialized: Boolean;
        AmountErr: Label '%1 must be %2 in %3.';
        TaxAmountMsg: Label '%1 must not be editable.';
        TaxAmountErr: Label 'Tax Amount is not correct in Test Report';
        TaxAmountNotEqualTotalErr: Label 'Tax Amount is not equal to Total in Test Report';
        VATCalculationTypeErr: Label 'The %1 field must contain Normal VAT, Reverse Charge VAT, or Sales Tax.';
        DialogCodeErr: Label 'Dialog';
        TaxAreaCodeVisibleErr: Label '%1 must be visible.';
        TaxAreaCodeEditableErr: Label '%1 must be editable.';
        TaxAreaCodeNotEditableErr: Label '%1 must not be editable.';

#if not CLEAN26
    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostSalesRetOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
        VATAmount: Variant;
        DocumentNo: Code[20];
    begin
        // Verify that G/L Entry and VAT entry should be exist after posting Sales Return Order with Tax Liable.

        // Setup: Create Sales Return Order.
        Initialize();
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Return Order");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        OpenSalesRetOrdPage(SalesReturnOrder, SalesHeader);
        SalesReturnOrder.Statistics.Invoke();  // Invoke to open Sales Order Statistics page.

        // Exercise: Post Sales Return Order.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify that G/L Entry and VAT entry should be exist after posting Sales Return Order with Tax Liable.
        LibraryVariableStorage.Dequeue(VATAmount);
        VerifyGLEntry(DocumentNo, SalesLine."Line Amount", VATAmount);
        VerifyVATEntry(DocumentNo, SalesLine."Line Amount", VATAmount);
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatsHandler')]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostSalesRetOrderNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
        VATAmount: Variant;
        DocumentNo: Code[20];
    begin
        // Verify that G/L Entry and VAT entry should be exist after posting Sales Return Order with Tax Liable.

        // Setup: Create Sales Return Order.
        Initialize();
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Return Order");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        OpenSalesRetOrdPage(SalesReturnOrder, SalesHeader);
        SalesReturnOrder.SalesOrderStats.Invoke();  // Invoke to open Sales Order Statistics page.

        // Exercise: Post Sales Return Order.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify that G/L Entry and VAT entry should be exist after posting Sales Return Order with Tax Liable.
        LibraryVariableStorage.Dequeue(VATAmount);
        VerifyGLEntry(DocumentNo, SalesLine."Line Amount", VATAmount);
        VerifyVATEntry(DocumentNo, SalesLine."Line Amount", VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesTaxGroup()
    var
        TaxGroup: Record "Tax Group";
    begin
        // Verify creation of Sales Tax Group.

        // Setup.
        Initialize();

        // Exercise.
        LibraryERM.CreateTaxGroup(TaxGroup);

        // Verify: Verify created Tax Group exists.
        TaxGroup.Get(TaxGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesTaxJurisdiction()
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        JurisdictionCode: Code[10];
    begin
        // Verify creation of Sales Tax Jurisdiction.

        // Setup.
        Initialize();

        // Exercise.
        JurisdictionCode := LibraryERMTax.CreateTaxJurisdictionWithSelfReportTo_US();

        // Verify: Verify created Tax Jurisdiction exists.
        TaxJurisdiction.Get(JurisdictionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesTaxArea()
    var
        TaxArea: Record "Tax Area";
    begin
        // Verify creation of Sales Tax Area.

        // Setup.
        Initialize();

        // Exercise.
        LibraryERM.CreateTaxArea(TaxArea);

        // Verify: Verify created Tax Area exists.
        TaxArea.Get(TaxArea.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesTaxDetail()
    var
        TaxDetail: Record "Tax Detail";
    begin
        // Verify creation of Sales Tax Detail.

        // Setup.
        Initialize();

        // Exercise.
        CreateSalesTaxDetail(TaxDetail);

        // Verify: Verify created Tax Detail exists.
        TaxDetail.Get(TaxDetail."Tax Jurisdiction Code", TaxDetail."Tax Group Code", TaxDetail."Tax Type", TaxDetail."Effective Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoUsingTaxLiable()
    var
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        DocumentNo: Code[20];
    begin
        // Verify Posted Purchase Credit Memo after posting Purchase Credit Memo with Tax Liable.

        // Setup.
        Initialize();

        // Exercise.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo");

        // Verify: Verify Posted Purchase Credit Memo after posting Purchase Credit Memo with Tax Liable.
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.FindFirst();
        PurchCrMemoLine.TestField("Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.");
        PurchCrMemoLine.TestField("Tax Liable", true);
        PurchCrMemoLine.TestField("Tax Area Code", PurchaseLine."Tax Area Code");
        PurchCrMemoLine.TestField(Quantity, PurchaseLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceUsingTaxLiable()
    var
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        DocumentNo: Code[20];
    begin
        // Verify Posted Purchase Invoice after posting Purchase Inoice with Tax Liable.

        // Setup.
        Initialize();

        // Exercise.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice);

        // Verify: Verify Posted Purchase Invoice after posting Purchase Inoice with Tax Liable.
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField("Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.");
        PurchInvLine.TestField("Tax Liable", true);
        PurchInvLine.TestField("Tax Area Code", PurchaseLine."Tax Area Code");
        PurchInvLine.TestField(Quantity, PurchaseLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostPurchaseOrderUsingTaxLiable()
    var
        PurchaseLine: Record "Purchase Line";
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
    begin
        // Verify G/L Entry after posting Purchase Order with Tax Liable.

        // Setup.
        Initialize();

        // Exercise.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Order);

        // Verify: Verify G/L Entry after posting Purchase Order with Tax Liable.
        FindGLEntry(GLEntry, DocumentNo);
        GLEntry.TestField(Amount, PurchaseLine.Amount);
        GLEntry.TestField("Tax Area Code", PurchaseLine."Tax Area Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderUsingMakeOrderUsingTaxLiable()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Purchase Order after Make Order from Purchase Blanket Order with Tax Liable.

        // Setup: Create Purchase Blanket Order.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Blanket Order");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise: Make Order from Purchase Blanket Order.
        LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader);

        // Verify: Verify Purchase Order after Make Order from Purchase Blanket Order with Tax Liable.
        VerifyPurchaseOrderAfterMakeOrder(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteUsingMakeOrderUsingTaxLiable()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Purchase Order after Make Order from Purchase Quote with Tax Liable.

        // Setup: Create Purchase Quote.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Quote);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise: Make Order from Purchase Quote.
        LibraryPurchase.QuoteMakeOrder(PurchaseHeader);

        // Verify: Verify Purchase Order after Make Order from Purchase Quote with Tax Liable.
        VerifyPurchaseOrderAfterMakeOrder(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceCrMemoUsingTaxLiable()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        // Verify Posted Service Credit Memo after posting Service Credit Memo with Tax Liable.

        // Setup: Create Service Credit Memo.
        Initialize();
        CreateServiceDocument(ServiceLine, ServiceHeader."Document Type"::"Credit Memo");
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        // Exercise: Post Service Credit Memo.
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // Verify: Verify Posted Service Credit Memo after posting Service Credit Memo with Tax Liable.
        ServiceCrMemoLine.SetRange("Customer No.", ServiceLine."Customer No.");
        ServiceCrMemoLine.FindFirst();
        ServiceCrMemoLine.TestField("No.", ServiceLine."No.");
        ServiceCrMemoLine.TestField(Quantity, ServiceLine.Quantity);
        ServiceCrMemoLine.TestField("Tax Liable", true);
        ServiceCrMemoLine.TestField("Tax Area Code", ServiceLine."Tax Area Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceShpmtUsingTaxLiable()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Verify Posted Service Shipment after posting Service Order with Tax Liable.

        // Setup: Create Tax Area Line, find VAT Posting Setup and create Service Order.
        Initialize();
        CreateAndModifyServiceLine(ServiceHeader, ServiceHeader."Document Type"::Order);

        // 2. Exercise: Post Service Order as Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify Posted Service Shipment after posting Service Order with Tax Liable.
        VerifyServiceShipment(ServiceHeader."No.", ServiceHeader."Customer No.", ServiceHeader."Tax Area Code");
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderUsingMakeOrderUsingTaxLiable()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Verify created Service Line after Make Order from Service Quote with Tax Liable.

        // Setup.
        Initialize();
        CreateAndModifyServiceLine(ServiceHeader, ServiceHeader."Document Type"::Quote);

        // 2. Exercise.
        LibraryService.CreateOrderFromQuote(ServiceHeader);

        // 3. Verify: Verify created Service Line after Make Order from Service Quote with Tax Liable.
        FindServiceLine(ServiceLine, ServiceHeader."Customer No.");
        ServiceLine.TestField("Tax Area Code", ServiceHeader."Tax Area Code");
        ServiceLine.TestField("Tax Liable", true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderFromSalesBlanketOrderUsingTaxLiable()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Verify Sales Order after Make Order from Sales Blanket Order with Tax Liable.

        // Setup: Create Sales Blanket Order.
        Initialize();
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Blanket Order");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise: Make Order from Sales Blanket Order.
        LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);

        // Verify: Verify Sales Order after Make Order from Sales Blanket Order with Tax Liable.
        VerifySalesOrderAfterMakeOrder(SalesHeader);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostSalesCrMemoUsingTaxLiable()
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify G/L Entry after posting Sales Credit Memo with Tax Liable.

        // Setup: Create Sales Credit Memo.
        Initialize();
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise: Post Sales Credit Memo.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify G/L Entry after posting Sales Credit Memo with Tax Liable.
        FindGLEntry(GLEntry, DocumentNo);
        GLEntry.TestField(Amount, SalesLine."Line Amount");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostSalesInvoiceUsingTaxLiable()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        VATAmount: Variant;
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Verify that G/L Entry and VAT entry after posting Sales Invoice with Tax Liable.

        // Setup: Create Sales Invoice.
        Initialize();
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        OpenSalesInvoicePage(SalesInvoice, SalesHeader);
        SalesInvoice.Statistics.Invoke();  // Invoke to open Sales Order Statistics page.

        // Exercise: Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify that G/L Entry and VAT Entry after posting Sales Invoice with Tax Liable.
        LibraryVariableStorage.Dequeue(VATAmount);
        Amount := VATAmount;
        VerifyGLEntry(DocumentNo, -SalesLine."Line Amount", -Amount);
        VerifyVATEntry(DocumentNo, -SalesLine."Line Amount", -Amount);
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatsHandler')]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostSalesInvoiceUsingTaxLiableNonModal()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        VATAmount: Variant;
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Verify that G/L Entry and VAT entry after posting Sales Invoice with Tax Liable.

        // Setup: Create Sales Invoice.
        Initialize();
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        OpenSalesInvoicePage(SalesInvoice, SalesHeader);
        SalesInvoice.SalesOrderStats.Invoke();  // Invoke to open Sales Order Statistics page.

        // Exercise: Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify that G/L Entry and VAT Entry after posting Sales Invoice with Tax Liable.
        LibraryVariableStorage.Dequeue(VATAmount);
        Amount := VATAmount;
        VerifyGLEntry(DocumentNo, -SalesLine."Line Amount", -Amount);
        VerifyVATEntry(DocumentNo, -SalesLine."Line Amount", -Amount);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostSalesOrderUsingTaxLiable()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        VATAmount: Variant;
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Verify that G/L Entry and VAT entry after posting Sales Order with Tax Liable.

        // Setup: Create Sales Order.
        Initialize();
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        OpenSalesOrderPage(SalesOrder, SalesHeader);
        SalesOrder.Statistics.Invoke();  // Invoke to open Sales Order Statistics page.

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify that G/L Entry and VAT Entry after posting Sales Order with Tax Liable.
        LibraryVariableStorage.Dequeue(VATAmount);
        Amount := VATAmount;
        VerifyGLEntry(DocumentNo, -SalesLine."Line Amount", -Amount);
        VerifyVATEntry(DocumentNo, -SalesLine."Line Amount", -Amount);
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatsHandler')]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostSalesOrderUsingTaxLiableNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        VATAmount: Variant;
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Verify that G/L Entry and VAT entry after posting Sales Order with Tax Liable.

        // Setup: Create Sales Order.
        Initialize();
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        OpenSalesOrderPage(SalesOrder, SalesHeader);
        SalesOrder.SalesOrderStats.Invoke();  // Invoke to open Sales Order Statistics page.

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify that G/L Entry and VAT Entry after posting Sales Order with Tax Liable.
        LibraryVariableStorage.Dequeue(VATAmount);
        Amount := VATAmount;
        VerifyGLEntry(DocumentNo, -SalesLine."Line Amount", -Amount);
        VerifyVATEntry(DocumentNo, -SalesLine."Line Amount", -Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderPageHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderFromSalesQuoteUsingTaxLiable()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Verify Sales Order after Make Order from Sales Quote with Tax Liable.

        // Setup: Create Sales Quote.
        Initialize();
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Quote);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise: Make Order from Sales Quote.
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order (Yes/No)", SalesHeader);

        // Verify: Verify Sales Order after Make Order from Sales Quote with Tax Liable.
        VerifySalesOrderAfterMakeOrder(SalesHeader);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceUsingTaxLiable()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        VATAmount: Decimal;
    begin
        // Verify that G/L Entry and VAT Entry after posting Service Invoice with Tax Liable.

        // Setup: Create Service Invoice and calculate the VAT Amount.
        Initialize();
        CreateServiceDocument(ServiceLine, ServiceHeader."Document Type"::Invoice);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        VATAmount := ((ServiceLine."Qty. to Invoice" * ServiceLine."Unit Price") * (ServiceLine."VAT %" / 100));

        // Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify: Verify that G/L Entry and VAT Entry after posting Service Invoice with Tax Liable.
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceLine."Document No.");
        ServiceInvoiceHeader.FindFirst();
        VerifyGLEntry(ServiceInvoiceHeader."No.", -ServiceLine."Line Amount", -VATAmount);
        VerifyVATEntry(ServiceInvoiceHeader."No.", -ServiceLine."Line Amount", -VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceUsingSalesJournalWithCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Amount after posting Invoice using Sales Journal in G/L Entry using currency.
        SetupForPostSalesJournal(GenJournalLine."Document Type"::Invoice, CreateCurrency(), -LibraryRandom.RandDec(10, 2));  // Using RANDOM value for Amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrMemoUsingSalesJournalWithCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Amount after posting Credit Memo using Sales Journal in G/L Entry using currency.
        SetupForPostSalesJournal(GenJournalLine."Document Type"::"Credit Memo", CreateCurrency(), LibraryRandom.RandDec(10, 2));  // Using RANDOM value for Amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceUsingSalesJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Amount after posting Invoice using Sales Journal in G/L Entry without using currency.
        SetupForPostSalesJournal(GenJournalLine."Document Type"::Invoice, '', -LibraryRandom.RandDec(10, 2));  // Using RANDOM value for Amount and Using blank for Currency Code.
    end;

    local procedure SetupForPostSalesJournal(DocumentType: Enum "Gen. Journal Document Type"; CurrencyCode: Code[10]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        AmountLCY: Decimal;
    begin
        // Verify Amount after posting Sales Journal in G/L Entry.

        // Setup: Create Credit Memo from Sales Journal and calculate Amount LCY.
        Initialize();
        PostGenJournalLineUsingTaxSetup(GenJournalLine, DocumentType, CurrencyCode, Amount);
        AmountLCY := GenJournalLine."Amount (LCY)";

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Amount after posting General Journal in G/L Entry.
        VerifyGLEntryAmount(GenJournalLine."Document No.", GenJournalLine."Account No.", -AmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyGenJournalUsingInvoiceWithCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify G/L Entry after posting Payment applied with Invoice using Currency.
        SetupForApplyGenJournalLine(
          GenJournalLine."Document Type"::Invoice, CreateCurrency(), -LibraryRandom.RandDec(10, 2));  // Using RANDOM value for Amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyGenJournalUsingCrMemoWithCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify G/L Entry after posting Payment applied with Credit Memo using Currency.
        SetupForApplyGenJournalLine(
          GenJournalLine."Document Type"::"Credit Memo", CreateCurrency(), LibraryRandom.RandDec(10, 2));  // Using RANDOM value for Amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyGenJournalUsingInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify G/L Entry after posting Payment applied with Invoice  without using Currency.
        SetupForApplyGenJournalLine(
          GenJournalLine."Document Type"::Invoice, '', -LibraryRandom.RandDec(10, 2));  // Using RANDOM value for Amount and Using blank for Currency Code.
    end;

    local procedure SetupForApplyGenJournalLine(DocumentType: Enum "Gen. Journal Document Type"; CurrencyCode: Code[10]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        AmountLCY: Decimal;
    begin
        // Verify G/L Entry after posting Payment applied with Credit Memo.

        // Setup.
        Initialize();
        PostGenJournalLineUsingTaxSetup(GenJournalLine, DocumentType, CurrencyCode, Amount);
        AmountLCY := GenJournalLine."Amount (LCY)";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise & Verify: Setup Gen. Journal Line and verify G/L Entry.
        SetupAndVerifyGenJournalLine(
          GenJournalLine, GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", GenJournalLine."Account No.",
          GenJournalLine."Currency Code", GetPaymentDocType(DocumentType), DocumentType, GenJournalLine.Amount, -AmountLCY);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsSalesOrderUsingTaxLiable()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Tax: Decimal;
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount on Sales Order Statistics.

        // Setup: Create Sales Order and open Sales Order page.
        Initialize();
        Tax := CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        TaxAmount := SalesLine."Line Amount" * Tax / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue value for PurchaseOrderStatisticsHandler.
        OpenSalesOrderPage(SalesOrder, SalesHeader);

        // Exercise.
        SalesOrder.Statistics.Invoke();  // Invoke to open Sales Order Statistics page.

        // Verify: Verify Tax Amount on Sales Order Statistics. Verification done in SalesOrderStatisticsModalPageHandler.
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler,SalesTaxLinesSubformDynPageHandler')]
    [Scope('OnPrem')]
    procedure SalesTaxLinesUsingTaxLiable()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Tax: Decimal;
        TaxAmount: Decimal;
    begin
        // Verify values on Sales Tax Lines page using Sales Order Statistics with Tax Liable.

        // Setup: Create Sales Order and open Sales Order page.
        Initialize();
        Tax := CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        TaxAmount := SalesLine."Line Amount" * Tax / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."Tax Group Code");  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount");  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount" + TaxAmount);  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        OpenSalesOrderPage(SalesOrder, SalesHeader);

        // Exercise.
        SalesOrder.Statistics.Invoke();  // Invoke to open Sales Order Statistics page.

        // Verify: Verify values on Sales Tax Lines Subform Dyn page. Verification done in SalesTaxLinesSubformDynPageHandler.
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatsNonModalPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsSalesOrderUsingTaxLiableNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Tax: Decimal;
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount on Sales Order Statistics.

        // Setup: Create Sales Order and open Sales Order page.
        Initialize();
        Tax := CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        TaxAmount := SalesLine."Line Amount" * Tax / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue value for PurchaseOrderStatisticsHandler.
        OpenSalesOrderPage(SalesOrder, SalesHeader);

        // Exercise.
        SalesOrder.SalesOrderStats.Invoke();  // Invoke to open Sales Order Statistics page.

        // Verify: Verify Tax Amount on Sales Order Statistics. Verification done in SalesOrderStatisticsModalPageHandler.
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsDrillDownNonModalPageHandler,SalesTaxLinesSubformDynPageHandler')]
    [Scope('OnPrem')]
    procedure SalesTaxLinesUsingTaxLiableNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Tax: Decimal;
        TaxAmount: Decimal;
    begin
        // Verify values on Sales Tax Lines page using Sales Order Statistics with Tax Liable.

        // Setup: Create Sales Order and open Sales Order page.
        Initialize();
        Tax := CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        TaxAmount := SalesLine."Line Amount" * Tax / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."Tax Group Code");  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount");  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount" + TaxAmount);  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        OpenSalesOrderPage(SalesOrder, SalesHeader);

        // Exercise.
        SalesOrder.SalesOrderStats.Invoke();  // Invoke to open Sales Order Statistics page.

        // Verify: Verify values on Sales Tax Lines Subform Dyn page. Verification done in SalesTaxLinesSubformDynPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValuesAfterPostSalesOrderUsingTaxLiable()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify Posted Sales Invoice after posting Sales Order with Tax Liable.

        // Setup: Create Sales Order.
        Initialize();
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Posted Sales Invoice after posting Sales Order with Tax Liable.
        VerifySalesInvoiceLine(SalesLine, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyRefundGenJournalLineUsingCrMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify G/L Entry after applying Refund with Credit Memo using General Journal Line.

        // Setup: Create and post Sales Credit Memo.
        Initialize();
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise & Verify: Setup Gen. Journal Line and verify G/L Entry.
        SetupAndVerifyGenJournalLine(
          GenJournalLine, DocumentNo, SalesLine."Sell-to Customer No.",
          CreateGLAccount(SalesLine."VAT Prod. Posting Group", SalesLine."Tax Group Code"),
          '', GenJournalLine."Document Type"::Refund,
          GenJournalLine."Document Type"::"Credit Memo", SalesLine."Line Amount", -SalesLine."Line Amount");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsSalesCrMemoUsingTaxLiable()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        Tax: Decimal;
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount on Sales Credit Memo Statistics page.

        // Setup: Create Sales Order and open Sales Credit Memo page.
        Initialize();
        Tax := CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        TaxAmount := SalesLine."Line Amount" * Tax / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue value for SalesOrderStatisticsModalPageHandler.
        OpenSalesCrMemoPage(SalesCreditMemo, SalesHeader);

        // Exercise.
        SalesCreditMemo.Statistics.Invoke();  // Invoke to open Sales Credit Memo Statistics page.

        // Verify: Verify Tax Amount on Sales Credit Memo Statistics page. Verification done in SalesOrderStatisticsModalPageHandler.
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler,SalesTaxLinesSubformDynPageHandler')]
    [Scope('OnPrem')]
    procedure SalesTaxLinesUsingSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        Tax: Decimal;
        TaxAmount: Decimal;
    begin
        // Verify values on Sales Tax Lines page using Sales Credit Memo Statistics page.

        // Setup: Create Sales Order.
        Initialize();
        Tax := CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        TaxAmount := SalesLine."Line Amount" * Tax / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."Tax Group Code");  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount");  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount" + TaxAmount);  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        OpenSalesCrMemoPage(SalesCreditMemo, SalesHeader);

        // Exercise.
        SalesCreditMemo.Statistics.Invoke();  // Invoke to open Sales Credit Memo Statistics page.

        // Verify: Verify values on Sales Tax Lines Subform Dyn page. Verification done in SalesTaxLinesSubformDynPageHandler.
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatsNonModalPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsSalesCrMemoUsingTaxLiableNonModal()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        Tax: Decimal;
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount on Sales Credit Memo Statistics page.

        // Setup: Create Sales Order and open Sales Credit Memo page.
        Initialize();
        Tax := CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        TaxAmount := SalesLine."Line Amount" * Tax / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue value for PurchaseOrderStatisticsHandler.
        OpenSalesCrMemoPage(SalesCreditMemo, SalesHeader);

        // Exercise.
        SalesCreditMemo.SalesOrderStats.Invoke();  // Invoke to open Sales Credit Memo Statistics page.

        // Verify: Verify Tax Amount on Sales Credit Memo Statistics page. Verification done in SalesOrderStatisticsModalPageHandler.
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsDrillDownNonModalPageHandler,SalesTaxLinesSubformDynPageHandler')]
    [Scope('OnPrem')]
    procedure SalesTaxLinesUsingSalesCrMemoNonModal()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        Tax: Decimal;
        TaxAmount: Decimal;
    begin
        // Verify values on Sales Tax Lines page using Sales Credit Memo Statistics page.

        // Setup: Create Sales Order.
        Initialize();
        Tax := CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        TaxAmount := SalesLine."Line Amount" * Tax / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."Tax Group Code");  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount");  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount" + TaxAmount);  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        OpenSalesCrMemoPage(SalesCreditMemo, SalesHeader);

        // Exercise.
        SalesCreditMemo.SalesOrderStats.Invoke();  // Invoke to open Sales Credit Memo Statistics page.

        // Verify: Verify values on Sales Tax Lines Subform Dyn page. Verification done in SalesTaxLinesSubformDynPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvoiceGenJournalLineUsingCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        AmountLCY: Decimal;
    begin
        // Verify G/L Entry after applying Payment with Invoice using General Journal Line with Currency.

        // Setup: Create and post Sales Credit Memo.
        Initialize();
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesLine.Validate("Currency Code", CreateCurrency());
        SalesLine.Modify(true);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        AmountLCY := LibraryERM.ConvertCurrency(SalesLine."Line Amount", SalesLine."Currency Code", '', WorkDate());
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise & Verify: Setup Gen. Journal Line using Currency and verify G/L Entry.
        SetupAndVerifyGenJournalLine(
          GenJournalLine, DocumentNo, SalesLine."Sell-to Customer No.",
          CreateGLAccount(SalesLine."VAT Prod. Posting Group", SalesLine."Tax Group Code"),
          SalesLine."Currency Code", GenJournalLine."Document Type"::Payment,
          GenJournalLine."Document Type"::Invoice, -SalesLine."Line Amount", AmountLCY);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderArchive()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // Verify values on Sales Line Archive after archiving Sales Order.

        // Setup.
        Initialize();
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // Verify: Verify values on Sales Line Archive after archiving Sales Order.
        VerifySalesLineArchive(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderArchive()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify values on Sales Header Archive after archiving Sales Order and verify G/L Entry Amount.

        // Setup: Modify Sales and Receivables setup, "Archive Quotes and Orders" as TRUE to archive Sales Order with posting.
        Initialize();
        LibrarySales.SetArchiveOrders(true);
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify values on Sales Header Archive after archiving Sales Order and verify G/L Entry Amount.
        VerifySalesHeaderArchive(SalesHeader);
        VerifyGLEntryAmount(DocumentNo, '', -SalesLine."Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentGenJournalLineUsingOrder()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify G/L Entry after applying Payment with Invoice using General Journal Line.

        // Setup: Create and post Sales Credit Memo.
        Initialize();
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise & Verify: Setup Gen. Journal Line and verify G/L Entry for Payment applied with Invoice.
        SetupAndVerifyGenJournalLine(
          GenJournalLine, DocumentNo, SalesLine."Sell-to Customer No.",
          CreateGLAccount(SalesLine."VAT Prod. Posting Group", SalesLine."Tax Group Code"),
          '', GenJournalLine."Document Type"::Payment,
          GenJournalLine."Document Type"::Invoice, -SalesLine."Line Amount", SalesLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderFromSalesBlanketOrderAndPost()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderOrder: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        DocumentNo: Code[20];
    begin
        // Verify G/L Entry Amount after post Sales Order after Make Order from Sales Blanket Order.

        // Setup: Create and Make Order from Sales Blanket Order.
        Initialize();
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Blanket Order");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);
        FindSalesOrder(SalesHeaderOrder, SalesHeader."Sell-to Customer No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeaderOrder, true, true);

        // Verify: Verify G/L Entry Amount after post Sales Order after Make Order from Sales Blanket Order.
        VerifyGLEntryAmount(DocumentNo, '', -SalesLine."Line Amount");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatsModalPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsOnSalesQuoteUsingTaxLiable()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        Tax: Decimal;
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount on Sales Quote Statistics page.

        // Setup: Create Sales Quote and open Sales Quote page.
        Initialize();
        Tax := CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Quote);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        TaxAmount := SalesLine."Line Amount" * Tax / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue value for SalesStatsModalPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount" + TaxAmount);  // Enqueue value for SalesStatsModalPageHandler.
        OpenSalesQuotePage(SalesQuote, SalesHeader);

        // Exercise.
        SalesQuote.Statistics.Invoke();

        // Verify: Verify Tax Amount on Sales Quote Statistics page. Verification done in SalesStatsModalPageHandler.
    end;
#endif
    [Test]
    [HandlerFunctions('SalesStatsPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsOnSalesQuoteUsingTaxLiableNonModal()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
        Tax: Decimal;
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount on Sales Quote Statistics page.

        // Setup: Create Sales Quote and open Sales Quote page.
        Initialize();
        Tax := CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Quote);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        TaxAmount := SalesLine."Line Amount" * Tax / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue value for SalesStatsPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount" + TaxAmount);  // Enqueue value for SalesStatsPageHandler.
        OpenSalesQuotePage(SalesQuote, SalesHeader);

        // Exercise.
        SalesQuote.SalesStats.Invoke();

        // Verify: Verify Tax Amount on Sales Quote Statistics page. Verification done in SalesStatsPageHandler.
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderPageHandler,SalesOrderStatisticsModalPageHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure StatisticsOnSalesOrderAfterMakeOrderFromSalesQuote()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderOrder: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesOrder: TestPage "Sales Order";
        Tax: Decimal;
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount on Sales Order Statistics created after Make Order from Sales Quote.

        // Setup: Create Sales Quote, Make Order and open Sales Order page create after Make Order.
        Initialize();
        Tax := CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Quote);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        TaxAmount := SalesLine."Line Amount" * Tax / 100;
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order (Yes/No)", SalesHeader);
        FindSalesOrder(SalesHeaderOrder, SalesHeader."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue value for SalesOrderStatisticsHandler.
        OpenSalesOrderPage(SalesOrder, SalesHeaderOrder);

        // Exercise.
        SalesOrder.Statistics.Invoke();  // Invoke to open Sales Order Statistics page.

        // Verify: Verify Tax Amount on Sales Order Statistics. Verification done in SalesOrderStatisticsModalPageHandler.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;
#endif
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderPageHandler,SalesOrderStatsNonModalPageHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure StatisticsOnSalesOrderAfterMakeOrderFromSalesQuoteNM()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderOrder: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesOrder: TestPage "Sales Order";
        Tax: Decimal;
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount on Sales Order Statistics created after Make Order from Sales Quote.

        // Setup: Create Sales Quote, Make Order and open Sales Order page create after Make Order.
        Initialize();
        Tax := CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Quote);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        TaxAmount := SalesLine."Line Amount" * Tax / 100;
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order (Yes/No)", SalesHeader);
        FindSalesOrder(SalesHeaderOrder, SalesHeader."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue value for SalesOrderStatisticsHandler.
        OpenSalesOrderPage(SalesOrder, SalesHeaderOrder);

        // Exercise.
        SalesOrder.SalesOrderStats.Invoke();  // Invoke to open Sales Order Statistics page.

        // Verify: Verify Tax Amount on Sales Order Statistics. Verification done in SalesOrderStatisticsModalPageHandler.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderPageHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostSalesOrderUsingMakeOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderOrder: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        DocumentNo: Code[20];
    begin
        // Verify G/L Entry Amount after post Sales Order after Make Order from Sales Quote.

        // Setup: Create Sales Quote, Make Order and find Sales Order create after Make Order.
        Initialize();
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Quote);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order (Yes/No)", SalesHeader);
        FindSalesOrder(SalesHeaderOrder, SalesHeader."Sell-to Customer No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeaderOrder, true, true);

        // Verify: Verify G/L Entry Amount after post Sales Order after Make Order from Sales Quote.
        VerifyGLEntryAmount(DocumentNo, '', -SalesLine."Line Amount");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderPageHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostSalesOrderUsingMakeOrderWithInvDisc()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeaderOrder: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        DocumentNo: Code[20];
    begin
        // Verify G/L Entry Amount after post Sales Order using Make Order from Sales Quote with Customer Invoice Discount.

        // Setup: Set Automatic Cost Posting to TRUE and create Sales Quote, Make Order and find Sales Order create after Make Order.
        Initialize();
        ModifyInventorySetup();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CreateCustomerWithInvDisc());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(10));  // Using RANDOM value for Quantity.
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order (Yes/No)", SalesHeader);
        FindSalesOrder(SalesHeaderOrder, SalesHeader."Sell-to Customer No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeaderOrder, true, true);

        // Verify: Verify G/L Entry Amount after post Sales Order after Make Order from Sales Quote using Customer Invoice Discount.
        VerifyGLEntryAmount(DocumentNo, '', -SalesLine."Line Amount");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

#if not CLEAN27
    [Test]
    [HandlerFunctions('ServiceOrderStatsPageHandler,SalesTaxLinesSubformDynPageHandler')]
    [Scope('OnPrem')]
    procedure VATLinesUsingStatisticsOnServiceOrderTaxLiable()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        Tax: Decimal;
        TaxAmount: Decimal;
    begin
        // Verify values on Sales Tax Lines page using Service Order Statistics page.

        // Setup: Create Service Order and find Service Line.
        Initialize();
        Tax := CreateAndModifyServiceLine(ServiceHeader, ServiceHeader."Document Type"::Order);
        FindServiceLine(ServiceLine, ServiceHeader."Customer No.");
        TaxAmount := ServiceLine."Line Amount" * Tax / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        LibraryVariableStorage.Enqueue(ServiceLine."Tax Group Code");  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        LibraryVariableStorage.Enqueue(ServiceLine."Line Amount");  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        LibraryVariableStorage.Enqueue(ServiceLine."Line Amount" + TaxAmount);  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        OpenServiceOrderPage(ServiceHeader, ServiceOrder);

        // Exercise.
        ServiceOrder.Statistics.Invoke();  // Invoke to open Service Order Statistics page.

        // Verify: Verify values on Sales Tax Lines Subform Dyn page. Verification done in SalesTaxLinesSubformDynPageHandler.
    end;

    [Test]
    [HandlerFunctions('ServiceCrMemoStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsOnServiceCrMemoUsingTaxLiable()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCreditMemo: TestPage "Service Credit Memo";
        Tax: Decimal;
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount on Sales Credit Memo Statistics page.

        // Setup: Create Service Credit Memo and open Service Credit Memo page.
        Initialize();
        Tax := CreateServiceDocument(ServiceLine, ServiceHeader."Document Type"::"Credit Memo");
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        TaxAmount := ServiceLine."Line Amount" * Tax / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue value for ServiceCrMemoStatisticsPageHandler.
        OpenServiceCrMemoPage(ServiceHeader, ServiceCreditMemo);

        // Exercise.
        ServiceCreditMemo.Statistics.Invoke();  // Invoke to open Service Order Statistics page.

        // Verify: Verify Tax Amount on Service Credit Memo Statistics page. Verification done in ServiceCrMemoStatisticsPageHandler.
    end;
#endif
    [Test]
    [HandlerFunctions('ServiceOrderStatsPageHandlerNM,SalesTaxLinesSubformDynPageHandler')]
    [Scope('OnPrem')]
    procedure VATLinesUsingStatisticsOnServiceOrderTaxLiableNM()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        Tax: Decimal;
        TaxAmount: Decimal;
    begin
        // Verify values on Sales Tax Lines page using Service Order Statistics page.

        // Setup: Create Service Order and find Service Line.
        Initialize();
        Tax := CreateAndModifyServiceLine(ServiceHeader, ServiceHeader."Document Type"::Order);
        FindServiceLine(ServiceLine, ServiceHeader."Customer No.");
        TaxAmount := ServiceLine."Line Amount" * Tax / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        LibraryVariableStorage.Enqueue(ServiceLine."Tax Group Code");  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        LibraryVariableStorage.Enqueue(ServiceLine."Line Amount");  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        LibraryVariableStorage.Enqueue(ServiceLine."Line Amount" + TaxAmount);  // Enqueue value for SalesTaxLinesSubformDynPageHandler.
        OpenServiceOrderPage(ServiceHeader, ServiceOrder);

        // Exercise.
        ServiceOrder.ServiceOrderStats.Invoke();  // Invoke to open Service Order Statistics page.

        // Verify: Verify values on Sales Tax Lines Subform Dyn page. Verification done in SalesTaxLinesSubformDynPageHandler.
    end;

    [Test]
    [HandlerFunctions('ServiceCrMemoStatsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure StatisticsOnServiceCrMemoUsingTaxLiableNM()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCreditMemo: TestPage "Service Credit Memo";
        Tax: Decimal;
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount on Sales Credit Memo Statistics page.

        // Setup: Create Service Credit Memo and open Service Credit Memo page.
        Initialize();
        Tax := CreateServiceDocument(ServiceLine, ServiceHeader."Document Type"::"Credit Memo");
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        TaxAmount := ServiceLine."Line Amount" * Tax / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue value for ServiceCrMemoStatisticsPageHandler.
        OpenServiceCrMemoPage(ServiceHeader, ServiceCreditMemo);

        // Exercise.
        ServiceCreditMemo.ServiceStats.Invoke();  // Invoke to open Service Order Statistics page.

        // Verify: Verify Tax Amount on Service Credit Memo Statistics page. Verification done in ServiceCrMemoStatisticsPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralLedgerSetupWithMultiplePACServices()
    var
        PACWebService: Record "PAC Web Service";
        PACWebService2: Record "PAC Web Service";
    begin
        // Verify that multiple PAC web services can be defined and any one can be selected in G/L Setup.

        // Setup: Create multiple PAC web services.
        Initialize();
        CreatePACWebServices(PACWebService);
        CreatePACWebServices(PACWebService2);

        // Exercise.
        UpdateGLSetup(PACWebService2.Code, false);

        // Verify.
        VerifyGLSetupPACode(PACWebService2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTHSTInVATEntryForPostedPurchaseDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
    begin
        // Verify GST/HST field of VAT Entry for posted purchase invoice.

        // Setup: Create Purchase Order with GST/HST.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Invoice);
        PurchaseLine.Validate("GST/HST", PurchaseLine."GST/HST"::"New Housing Rebates");
        PurchaseLine.Modify(true);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify GST/HST field in posted purchase invoice.
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        VATEntry.TestField("GST/HST", VATEntry."GST/HST"::"New Housing Rebates");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OptionsInTheFieldGSTHSTOfGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Verify options in the field GST/HST of Gen. Journal Line.

        // Setup.
        Initialize();
        FindGenJournalTemplateAndBatch(GenJournalBatch, GenJournalTemplate.Type::"Sales Tax");
        LibrarySales.CreateCustomer(Customer);

        // Exercise: Create Journal lines with different GST/HST options.
        CreateMultipleGenJournalLineWithGSTHSTOptions(GenJournalLine, GenJournalBatch, Customer."No.");

        // Verify: Verify GST/HST options on Journal lines.
        VerifyGSTHSTFieldOnJournalLine(GenJournalBatch, GenJournalLine."GST/HST"::" ");
        VerifyGSTHSTFieldOnJournalLine(GenJournalBatch, GenJournalLine."GST/HST"::"Self Assessment");
        VerifyGSTHSTFieldOnJournalLine(GenJournalBatch, GenJournalLine."GST/HST"::Rebate);
        VerifyGSTHSTFieldOnJournalLine(GenJournalBatch, GenJournalLine."GST/HST"::"New Housing Rebates");
        VerifyGSTHSTFieldOnJournalLine(GenJournalBatch, GenJournalLine."GST/HST"::"Pension Rebate");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OptionsInTheFieldGSTHSTOfVATEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Verify options in the field GST/HST of VAT Entry.

        // Setup.
        Initialize();
        FindGenJournalTemplateAndBatch(GenJournalBatch, GenJournalTemplate.Type::"Sales Tax");
        LibrarySales.CreateCustomer(Customer);

        // Exercise: Create Journal lines with different GST/HST options.
        CreateMultipleGenJournalLineWithGSTHSTOptions(GenJournalLine, GenJournalBatch, Customer."No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify GST/HST options on Journal lines.
        VerifyGSTHSTFieldOnVATEntry(Customer."No.", GenJournalLine."GST/HST"::" ");
        VerifyGSTHSTFieldOnVATEntry(Customer."No.", GenJournalLine."GST/HST"::"Self Assessment");
        VerifyGSTHSTFieldOnVATEntry(Customer."No.", GenJournalLine."GST/HST"::Rebate);
        VerifyGSTHSTFieldOnVATEntry(Customer."No.", GenJournalLine."GST/HST"::"New Housing Rebates");
        VerifyGSTHSTFieldOnVATEntry(Customer."No.", GenJournalLine."GST/HST"::"Pension Rebate");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceDocWithoutDescription()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Verify Service Document Could not be Post Without Description on Service Line.

        // Setup: Create Sevice Invoice and Update Service Line
        Initialize();
        CreateServiceDocument(ServiceLine, ServiceHeader."Document Type"::Invoice);
        ServiceHeader.Get(ServiceLine."Document Type"::Invoice, ServiceLine."Document No.");
        ServiceLine.Validate(Description, '');
        ServiceLine.Modify(true);

        // Exercise: Post Service Document.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify: Verify Error will appear while posting Service Document Without Description.
        Assert.ExpectedTestFieldError(ServiceLine.FieldCaption(Description), '');
    end;
#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsticsPageHandler,SalesTaxLinesSubformNotEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoOfVATLinesGeneralWhenSalesOrderOpen()
    var
        SalesNoOfLinesStatistics: Option General,Invoicing,Shipping,Prepayment;
    begin
        // [SCENARIO] Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_General when Sales Order open for on-prem.
        // [GIVEN] setups needed to generate tax lines.
        Initialize();

        LibraryVariableStorage.Enqueue(SalesNoOfLinesStatistics::General);
        // [GIVEN] A Sales Order
        // [WHEN] The No. Vat Lines on the general tab is pressed.
        // [THEN] The Tax Amount is not editable.
        SetupSalesVATLines();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsticsPageHandler,SalesTaxLinesSubformEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoOfVATLinesGeneralWhenSalesOrderOpenD365()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        SalesNoOfLinesStatistics: Option General,Invoicing,Shipping,Prepayment;
    begin
        // [SCENARIO] Verify Sales Tax Amount Field is Editable on Sales Tax Lines_General when Sales Order open on D365.
        // [GIVEN] setups needed to generate tax lines.
        Initialize();
        LibraryVariableStorage.Enqueue(SalesNoOfLinesStatistics::General);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        // [GIVEN] A Sales Order
        // [WHEN] The No. Vat Lines on the general tab is pressed.
        // [THEN] The Tax Amount is editable.
        SetupSalesVATLines();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsticsPageHandler,SalesTaxLinesSubformNotEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoVATLinesInvoiceWhenSalesOrderOpen()
    var
        SalesNoOfLinesStatistics: Option General,Invoicing,Shipping,Prepayment;
    begin
        // [SCENARIO] Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_Invoicing when Sales Order open for on-prem.
        // [GIVEN] setups needed to generate tax lines.
        Initialize();
        LibraryVariableStorage.Enqueue(SalesNoOfLinesStatistics::Invoicing);
        // [GIVEN] A Sales Order
        // [WHEN] The No. Vat Lines on the invoicing tab is pressed.
        // [THEN] The Tax Amount is editable.

        SetupSalesVATLines();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsticsPageHandler,SalesTaxLinesSubformEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoVATLinesInvoiceWhenSalesOrderOpenD365()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        SalesNoOfLinesStatistics: Option General,Invoicing,Shipping,Prepayment;
    begin
        // [SCENARIO] Verify Sales Tax Amount Field is editable on Sales Tax Lines_Invoicing when Sales Order open for D365.
        // [GIVEN] setups needed to generate tax lines.
        Initialize();
        LibraryVariableStorage.Enqueue(SalesNoOfLinesStatistics::Invoicing);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        // [GIVEN] A Sales Order
        // [WHEN] The No. Vat Lines on the invoicing tab is pressed.
        // [THEN] The Tax Amount is editable.

        SetupSalesVATLines();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsticsPageHandler,SalesTaxLinesSubformNotEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoVATLinesShippingWhenSalesOrderOpen()
    var
        SalesNoOfLinesStatistics: Option General,Invoicing,Shipping,Prepayment;
    begin
        // Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_Shipping when Sales Order open.
        Initialize();
        LibraryVariableStorage.Enqueue(SalesNoOfLinesStatistics::Shipping);
        SetupSalesVATLines();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsticsPageHandler,SalesTaxLinesPageHandler')]
    [Scope('OnPrem')]
    procedure NoVATLinesPrepaymentWhenSalesOrderOpen()
    var
        SalesNoOfLinesStatistics: Option General,Invoicing,Shipping,Prepayment;
    begin
        // Verify Sales Tax Amount Field is Editable on Sales Tax Lines_Prepayment when Sales Order open.
        Initialize();
        EnqueueValuesInOrderStatistics(SalesNoOfLinesStatistics::Prepayment, true, 0, false);
        SetupSalesVATLines();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsticsPageHandler,SalesTaxLinesSubformNotEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoVATLinesShippingAfterSalesOrderReleased()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        SalesNoOfLines: Option General,Invoice,Shipping;
    begin
        // Verify Tax Amount not Editable after Releasing on Sales Tax Lines_Shipping on Sales Order Statistics.

        // Setup: Create and Release Sales Order.
        Initialize();
        UpdateSetups(true, LibraryRandom.RandIntInRange(10, 100));
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryVariableStorage.Enqueue(SalesNoOfLines::Shipping);
        OpenSalesOrderPage(SalesOrder, SalesHeader);

        // Exercise: Open Sales Statistics.
        SalesOrder.Statistics.Invoke();

        // Verify: Verify Tax Amount not editable on Sales Tax Lines_Shipping Tab after releasing.
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsticsPageHandler,SalesTaxLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesTaxAmountWhenSalesOrderReopen()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Amount: Variant;
        TaxAmount: Decimal;
        SalesNoOfLines: Option General,Invoice,Shipping;
    begin
        // Verify Tax Amount is Editable after Releasing and Tax Amount should be Updated Amount after Reopening Sales Order.

        // Setup: Create and Release Sales Order.
        Initialize();
        UpdateSetups(true, LibraryRandom.RandIntInRange(10, 100));
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        TaxAmount := LibraryRandom.RandDec(0, 2);
        EnqueueValuesInOrderStatistics(SalesNoOfLines::Invoice, true, TaxAmount, true);
        OpenSalesOrderPage(SalesOrder, SalesHeader);

        // After Releasing Sales Order update Tax Amount on Sales Tax Lines.
        SalesOrder.Statistics.Invoke();

        // After Updating Tax Amount Reopen Sales Order.
        LibrarySales.ReopenSalesDocument(SalesHeader);
        LibraryVariableStorage.Dequeue(Amount);
        EnqueueValuesInOrderStatistics(SalesNoOfLines::General, false, Amount, false);

        // Exercise: Open Sales Statistics.
        SalesOrder.Statistics.Invoke();

        // Verify: Verify Tax Amount should be Updated Tax Amount after reopening Sales Tax Lines Subform Dyn page.
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsNonModalPageHandler,SalesTaxLinesSubformNotEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoOfVATLinesGeneralWhenSalesOrderOpenNM()
    var
        SalesNoOfLinesStatistics: Option General,Invoicing,Shipping,Prepayment;
    begin
        // [SCENARIO] Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_General when Sales Order open for on-prem.
        // [GIVEN] setups needed to generate tax lines.
        Initialize();

        LibraryVariableStorage.Enqueue(SalesNoOfLinesStatistics::General);
        // [GIVEN] A Sales Order
        // [WHEN] The No. Vat Lines on the general tab is pressed.
        // [THEN] The Tax Amount is not editable.
        SetupSalesVATLinesNM();
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsNonModalPageHandler,SalesTaxLinesSubformEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoOfVATLinesGeneralWhenSalesOrderOpenD365NM()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        SalesNoOfLinesStatistics: Option General,Invoicing,Shipping,Prepayment;
    begin
        // [SCENARIO] Verify Sales Tax Amount Field is Editable on Sales Tax Lines_General when Sales Order open on D365.
        // [GIVEN] setups needed to generate tax lines.
        Initialize();
        LibraryVariableStorage.Enqueue(SalesNoOfLinesStatistics::General);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        // [GIVEN] A Sales Order
        // [WHEN] The No. Vat Lines on the general tab is pressed.
        // [THEN] The Tax Amount is editable.
        SetupSalesVATLinesNM();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsNonModalPageHandler,SalesTaxLinesSubformNotEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoVATLinesInvoiceWhenSalesOrderOpenNM()
    var
        SalesNoOfLinesStatistics: Option General,Invoicing,Shipping,Prepayment;
    begin
        // [SCENARIO] Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_Invoicing when Sales Order open for on-prem.
        // [GIVEN] setups needed to generate tax lines.
        Initialize();
        LibraryVariableStorage.Enqueue(SalesNoOfLinesStatistics::Invoicing);
        // [GIVEN] A Sales Order
        // [WHEN] The No. Vat Lines on the invoicing tab is pressed.
        // [THEN] The Tax Amount is editable.

        SetupSalesVATLinesNM();
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsNonModalPageHandler,SalesTaxLinesSubformEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoVATLinesInvoiceWhenSalesOrderOpenD365NM()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        SalesNoOfLinesStatistics: Option General,Invoicing,Shipping,Prepayment;
    begin
        // [SCENARIO] Verify Sales Tax Amount Field is editable on Sales Tax Lines_Invoicing when Sales Order open for D365.
        // [GIVEN] setups needed to generate tax lines.
        Initialize();
        LibraryVariableStorage.Enqueue(SalesNoOfLinesStatistics::Invoicing);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        // [GIVEN] A Sales Order
        // [WHEN] The No. Vat Lines on the invoicing tab is pressed.
        // [THEN] The Tax Amount is editable.

        SetupSalesVATLinesNM();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsNonModalPageHandler,SalesTaxLinesSubformNotEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoVATLinesShippingWhenSalesOrderOpenNM()
    var
        SalesNoOfLinesStatistics: Option General,Invoicing,Shipping,Prepayment;
    begin
        // Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_Shipping when Sales Order open.
        Initialize();
        LibraryVariableStorage.Enqueue(SalesNoOfLinesStatistics::Shipping);
        SetupSalesVATLinesNM();
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsNonModalPageHandler,SalesTaxLinesPageHandler')]
    [Scope('OnPrem')]
    procedure NoVATLinesPrepaymentWhenSalesOrderOpenNM()
    var
        SalesNoOfLinesStatistics: Option General,Invoicing,Shipping,Prepayment;
    begin
        // Verify Sales Tax Amount Field is Editable on Sales Tax Lines_Prepayment when Sales Order open.
        Initialize();
        EnqueueValuesInOrderStatistics(SalesNoOfLinesStatistics::Prepayment, true, 0, false);
        SetupSalesVATLinesNM();
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsNonModalPageHandler,SalesTaxLinesSubformNotEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoVATLinesShippingAfterSalesOrderReleasedNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        SalesNoOfLines: Option General,Invoice,Shipping;
    begin
        // Verify Tax Amount not Editable after Releasing on Sales Tax Lines_Shipping on Sales Order Statistics.

        // Setup: Create and Release Sales Order.
        Initialize();
        UpdateSetups(true, LibraryRandom.RandIntInRange(10, 100));
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryVariableStorage.Enqueue(SalesNoOfLines::Shipping);
        OpenSalesOrderPage(SalesOrder, SalesHeader);

        // Exercise: Open Sales Statistics.
        SalesOrder.SalesOrderStats.Invoke();

        // Verify: Verify Tax Amount not editable on Sales Tax Lines_Shipping Tab after releasing.
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsNonModalPageHandler,SalesTaxLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesTaxAmountWhenSalesOrderReopenNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Amount: Variant;
        TaxAmount: Decimal;
        SalesNoOfLines: Option General,Invoice,Shipping;
    begin
        // Verify Tax Amount is Editable after Releasing and Tax Amount should be Updated Amount after Reopening Sales Order.

        // Setup: Create and Release Sales Order.
        Initialize();
        UpdateSetups(true, LibraryRandom.RandIntInRange(10, 100));
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        TaxAmount := LibraryRandom.RandDec(0, 2);
        EnqueueValuesInOrderStatistics(SalesNoOfLines::Invoice, true, TaxAmount, true);
        OpenSalesOrderPage(SalesOrder, SalesHeader);

        // After Releasing Sales Order update Tax Amount on Sales Tax Lines.
        SalesOrder.SalesOrderStats.Invoke();

        // After Updating Tax Amount Reopen Sales Order.
        LibrarySales.ReopenSalesDocument(SalesHeader);
        LibraryVariableStorage.Dequeue(Amount);
        EnqueueValuesInOrderStatistics(SalesNoOfLines::General, false, Amount, false);

        // Exercise: Open Sales Statistics.
        SalesOrder.SalesOrderStats.Invoke();

        // Verify: Verify Tax Amount should be Updated Tax Amount after reopening Sales Tax Lines Subform Dyn page.
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatsForGenPageHandler,SalesTaxLinesSubformNotEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoOfVATLinesGeneralWhenPurchaseOrderOpen()
    var
        PurchaseNoOfLinesOnStats: Option General,Invoicing,Shipping,Prepayment;
    begin
        // Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_General when Purchase Order open.
        Initialize();
        LibraryVariableStorage.Enqueue(PurchaseNoOfLinesOnStats::General);
        SetupPurchaseVATLines();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatsForGenPageHandler,SalesTaxLinesSubformNotEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoOfVATLinesGeneralWhenPurchOrderOpen()
    var
        PurchaseNoOfLinesOnStats: Option General,Invoicing,Shipping,Prepayment;
    begin
        // Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_General when Purchase Order open.
        Initialize();
        LibraryVariableStorage.Enqueue(PurchaseNoOfLinesOnStats::General);
        SetupPurchVATLines();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatsForGenPageHandler,SalesTaxLinesSubformEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoOfVATLinesGeneralWhenPurchaseOrderOpenD365()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PurchaseNoOfLinesOnStats: Option General,Invoicing,Shipping,Prepayment;
    begin
        // Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_General when Purchase Order open.
        Initialize();
        LibraryVariableStorage.Enqueue(PurchaseNoOfLinesOnStats::General);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetupPurchaseVATLines();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatsForGenPageHandler,SalesTaxLinesSubformEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoOfVATLinesGeneralWhenPurchOrderOpenD365()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PurchaseNoOfLinesOnStats: Option General,Invoicing,Shipping,Prepayment;
    begin
        // Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_General when Purchase Order open.
        Initialize();
        LibraryVariableStorage.Enqueue(PurchaseNoOfLinesOnStats::General);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetupPurchVATLines();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatsForGenPageHandler,SalesTaxLinesSubformNotEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoOfVATLinesInvoiceWhenPurchaseOrderOpen()
    var
        PurchaseNoOfLinesOnStats: Option General,Invoicing,Shipping,Prepayment;
    begin
        // Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_Invoice when Purchase Order open.
        Initialize();
        LibraryVariableStorage.Enqueue(PurchaseNoOfLinesOnStats::Invoicing);
        SetupPurchaseVATLines();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatsForGenPageHandler,SalesTaxLinesSubformNotEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoOfVATLinesInvoiceWhenPurchOrderOpen()
    var
        PurchaseNoOfLinesOnStats: Option General,Invoicing,Shipping,Prepayment;
    begin
        // Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_Invoice when Purchase Order open.
        Initialize();
        LibraryVariableStorage.Enqueue(PurchaseNoOfLinesOnStats::Invoicing);
        SetupPurchVATLines();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatsForGenPageHandler,SalesTaxLinesSubformEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoOfVATLinesInvoiceWhenPurchaseOrderOpenD365()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PurchaseNoOfLinesOnStats: Option General,Invoicing,Shipping,Prepayment;
    begin
        // Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_Invoice when Purchase Order open.
        Initialize();
        LibraryVariableStorage.Enqueue(PurchaseNoOfLinesOnStats::Invoicing);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetupPurchaseVATLines();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatsForGenPageHandler,SalesTaxLinesSubformEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoOfVATLinesInvoiceWhenPurchOrderOpenD365()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PurchaseNoOfLinesOnStats: Option General,Invoicing,Shipping,Prepayment;
    begin
        // Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_Invoice when Purchase Order open.
        Initialize();
        LibraryVariableStorage.Enqueue(PurchaseNoOfLinesOnStats::Invoicing);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetupPurchVATLines();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatsForGenPageHandler,SalesTaxLinesSubformNotEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoOfVATLinesShippingWhenPurchaseOrderOpen()
    var
        PurchaseNoOfLinesOnStats: Option General,Invoicing,Shipping,Prepayment;
    begin
        // Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_Shipping when Purchse Order open.
        Initialize();
        LibraryVariableStorage.Enqueue(PurchaseNoOfLinesOnStats::Shipping);
        SetupPurchaseVATLines();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatsForGenPageHandler,SalesTaxLinesSubformNotEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoOfVATLinesShippingWhenPurchOrderOpen()
    var
        PurchaseNoOfLinesOnStats: Option General,Invoicing,Shipping,Prepayment;
    begin
        // Verify Sales Tax Amount Field is Not Editable on Sales Tax Lines_Shipping when Purchse Order open.
        Initialize();
        LibraryVariableStorage.Enqueue(PurchaseNoOfLinesOnStats::Shipping);
        SetupPurchVATLines();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatsForGenPageHandler,SalesTaxLinesPageHandler')]
    [Scope('OnPrem')]
    procedure NoOfVATLinesPrepaymentWhenPurchaseOrderOpen()
    var
        PurchaseNoOfLinesOnStats: Option General,Invoicing,Shipping,Prepayment;
    begin
        // Verify Sales Tax Amount Field is Editable on Sales Tax Lines_Prepayment when Purchse Order open.
        Initialize();
        EnqueueValuesInOrderStatistics(PurchaseNoOfLinesOnStats::Prepayment, true, 0, false);
        SetupPurchaseVATLines();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatsForGenPageHandler,SalesTaxLinesPageHandler')]
    [Scope('OnPrem')]
    procedure NoOfVATLinesPrepaymentWhenPurchOrderOpen()
    var
        PurchaseNoOfLinesOnStats: Option General,Invoicing,Shipping,Prepayment;
    begin
        // Verify Sales Tax Amount Field is Editable on Sales Tax Lines_Prepayment when Purchse Order open.
        Initialize();
        EnqueueValuesInOrderStatistics(PurchaseNoOfLinesOnStats::Prepayment, true, 0, false);
        SetupPurchVATLines();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatsForGenPageHandler,SalesTaxLinesSubformNotEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoVATLinesShippingAfterPurchaseOrderReleased()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseNoOfLines: Option General,Invoicing,Shipping,Prepayment;
    begin
        // Verify Tax Amount not Editable after Releasing on Sales Tax Lines_Shipping on Purchase Order Statistics.

        // Setup: Create and Release Sales Order.
        Initialize();
        UpdateSetups(true, LibraryRandom.RandIntInRange(10, 100));
        CreateAndModifyPurchaseDocument(PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryVariableStorage.Enqueue(PurchaseNoOfLines::Shipping);
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);
        OpenPurchaseOrderPage(PurchaseOrder, PurchaseHeader);

        // Exercise: Open Purchase Statistics.
        PurchaseOrder.Statistics.Invoke();

        // Verify: Verify Tax Amount not editable on Sales Tax Lines_Shipping Tab after releasing.
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatsForGenPageHandler,SalesTaxLinesSubformNotEditableDynModalPageHandler')]
    [Scope('OnPrem')]
    procedure NoVATLinesShippingAfterPurchOrderReleased()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseNoOfLines: Option General,Invoicing,Shipping,Prepayment;
    begin
        // Verify Tax Amount not Editable after Releasing on Sales Tax Lines_Shipping on Purchase Order Statistics.

        // Setup: Create and Release Sales Order.
        Initialize();
        UpdateSetups(true, LibraryRandom.RandIntInRange(10, 100));
        CreateAndModifyPurchaseDocument(PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryVariableStorage.Enqueue(PurchaseNoOfLines::Shipping);
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);
        OpenPurchaseOrderPage(PurchaseOrder, PurchaseHeader);

        // Exercise: Open Purchase Statistics.
        PurchaseOrder.PurchaseOrderStats.Invoke();

        // Verify: Verify Tax Amount not editable on Sales Tax Lines_Shipping Tab after releasing.
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatsForGenPageHandler,SalesTaxLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesTaxAmountWhenPurchaseOrderReopen()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        PurchaseOrder: TestPage "Purchase Order";
        Amount: Variant;
        TaxAmount: Decimal;
        PurchaseNoOfLines: Option General,Invoice,Shipping;
    begin
        // Verify Tax Amount is Editable after Releasing and Tax Amount should be Updated Amount after Reopening Purchase Order.

        // Setup: Create and Release Purchase Order.
        Initialize();
        UpdateSetups(true, LibraryRandom.RandIntInRange(10, 100));
        CreateAndModifyPurchaseDocument(PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);
        TaxAmount := LibraryRandom.RandInt(3);
        EnqueueValuesInOrderStatistics(PurchaseNoOfLines::Invoice, true, TaxAmount, true);
        OpenPurchaseOrderPage(PurchaseOrder, PurchaseHeader);

        // After Releasing Purchase Order update Tax Amount on Sales Tax Lines.
        PurchaseOrder.Statistics.Invoke();

        // After Updating Tax Amount Reopen Purchase Order.
        LibraryVariableStorage.Dequeue(Amount);
        ReleasePurchaseDocument.Reopen(PurchaseHeader);
        EnqueueValuesInOrderStatistics(PurchaseNoOfLines::General, false, Amount, false);

        // Exercise: Open Purchase Statistics.
        PurchaseOrder.Statistics.Invoke();

        // Verify: Verify Tax Amount should be Updated Tax Amount after reopening Sales Tax Lines Subform Dyn page.
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatsForGenPageHandler,SalesTaxLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesTaxAmountWhenPurchOrderReopen()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        PurchaseOrder: TestPage "Purchase Order";
        Amount: Variant;
        TaxAmount: Decimal;
        PurchaseNoOfLines: Option General,Invoice,Shipping;
    begin
        // Verify Tax Amount is Editable after Releasing and Tax Amount should be Updated Amount after Reopening Purchase Order.

        // Setup: Create and Release Purchase Order.
        Initialize();
        UpdateSetups(true, LibraryRandom.RandIntInRange(10, 100));
        CreateAndModifyPurchaseDocument(PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);
        TaxAmount := LibraryRandom.RandInt(3);
        EnqueueValuesInOrderStatistics(PurchaseNoOfLines::Invoice, true, TaxAmount, true);
        OpenPurchaseOrderPage(PurchaseOrder, PurchaseHeader);

        // After Releasing Purchase Order update Tax Amount on Sales Tax Lines.
        PurchaseOrder.PurchaseOrderStats.Invoke();

        // After Updating Tax Amount Reopen Purchase Order.
        LibraryVariableStorage.Dequeue(Amount);
        ReleasePurchaseDocument.Reopen(PurchaseHeader);
        EnqueueValuesInOrderStatistics(PurchaseNoOfLines::General, false, Amount, false);

        // Exercise: Open Purchase Statistics.
        PurchaseOrder.PurchaseOrderStats.Invoke();

        // Verify: Verify Tax Amount should be Updated Tax Amount after reopening Sales Tax Lines Subform Dyn page.
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceTestReportUsingTaxLiableWithUSCountry()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxArea: Record "Tax Area";
        TaxBelowMaximum1: Decimal;
        TaxBelowMaximum2: Decimal;
        TaxAmount: Decimal;
        Total: Decimal;
    begin
        // Verify Tax Amount and Total is correct in Sales Invoice - Test Report using Tax Liable with US country.

        // Setup: Create Sales Invoice with Tax Area Country.
        // Exercise: Run and Save Sales Document Test Report.
        // To repro the issue, we need make sure 3rd digits after the decimal point is (5,7). Here "Sales Tax Amount" = 1(Qty) * 0.1 (Direct Unit Cost) * TaxBelowMaximum / 100
        Initialize();
        TaxBelowMaximum1 := LibraryRandom.RandIntInRange(5, 6);
        TaxBelowMaximum2 := TaxBelowMaximum1 + 1; // Make different with TaxBelowMaximum1
        RunSalesDocumentTestReportWithTwoTaxAreaLines(
          SalesLine, SalesHeader."Document Type"::Invoice, TaxBelowMaximum1, TaxBelowMaximum2, TaxArea."Country/Region"::US, 1, 0.1);

        // Verify: Verify Tax Amount and Total
        TaxAmount := Round(SalesLine."Unit Price" * TaxBelowMaximum1 / 100 + SalesLine."Unit Price" * TaxBelowMaximum2 / 100);
        Total := Round(LibraryReportDataset.Sum('VATAmount') / 2, LibraryERM.GetAmountRoundingPrecision());

        Assert.AreEqual(TaxAmount, SumTaxAmountInTestReport(), TaxAmountErr);
        Assert.AreEqual(Total, SumTaxAmountInTestReport(), TaxAmountNotEqualTotalErr);
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceTestReportUsingTaxLiableWithCACountry()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxArea: Record "Tax Area";
        TaxBelowMaximum1: Decimal;
        TaxBelowMaximum2: Decimal;
        TaxAmount: Decimal;
        Total: Decimal;
    begin
        // Verify Tax Amount and Total is correct in Sales Invoice - Test Report using Tax Liable with US country.

        // Setup: Create Sales Invoice with Tax Area Country.
        // Exercise: Run and Save Sales Document Test Report.
        // To repro the issue, we need make sure 3rd digits after the decimal point is (5,7). Here "Sales Tax Amount" = 1(Qty) * 0.1 (Direct Unit Cost) * TaxBelowMaximum / 100
        Initialize();
        TaxBelowMaximum1 := LibraryRandom.RandIntInRange(5, 7);
        TaxBelowMaximum2 := LibraryRandom.RandIntInRange(5, 7) + 100; // Make different with TaxBelowMaximum1.
        RunSalesDocumentTestReportWithTwoTaxAreaLines(
          SalesLine, SalesHeader."Document Type"::Invoice, TaxBelowMaximum1, TaxBelowMaximum2, TaxArea."Country/Region"::CA, 1, 0.1);

        // Verify: Verify Tax Amount and Total
        TaxAmount := Round(SalesLine."Unit Price" * TaxBelowMaximum1 / 100) + Round(SalesLine."Unit Price" * TaxBelowMaximum2 / 100);
        Total := Round(LibraryReportDataset.Sum('VATAmount') / 2, LibraryERM.GetAmountRoundingPrecision());

        Assert.AreEqual(TaxAmount, SumTaxAmountInTestReport(), TaxAmountErr);
        Assert.AreEqual(Total, SumTaxAmountInTestReport(), TaxAmountNotEqualTotalErr);
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestReportTaxAmount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxGroup: Record "Tax Group";
        TaxDetail: Record "Tax Detail";
        i: Integer;
    begin
        // [FEATURE] [Sales] [Sales Tax]
        // [SCENARIO 374921] "Tax Amount" rounding in "Sales Document - Test" when 3 tax jurisdictions involved.
        Initialize();
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxArea(TaxArea);

        // [GIVEN] 3 Tax Jurisdictions. Tax % = 3.35 in each Tax Jurisdiction.
        for i := 1 to 3 do begin
            CreateSalesTaxDetailWithCountry(
              TaxDetail, LibraryERMTax.CreateTaxJurisdictionWithSelfReportTo_US(), TaxGroup.Code, 3.35);
            LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");
        end;

        // [GIVEN] Sales Invoice invoice with Amount = 10.
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 25));
        CreateSalesInvoiceWithCertainAmount(SalesHeader, VATPostingSetup, TaxArea.Code, 1, 10, TaxGroup.Code);

        // [WHEN] Run "Sales Document - Test" report.
        LibraryVariableStorage.Enqueue(SalesHeader."Document Type");
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        Commit();
        REPORT.Run(REPORT::"Sales Document - Test");

        // [THEN] Report contains "Tax Amount" = 10 * 0.0335 + 10 * 0.0335 + 10 * 0.0335 = 1.005 = 1.01.
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(
          -GetVATEntryAmount(LibrarySales.PostSalesDocument(SalesHeader, true, true)),
          LibraryReportDataset.Sum('SalesTaxAmountLine__Tax_Amount_'), TaxAmountErr);
    end;

    [Test]
    [HandlerFunctions('PurchaseDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceTestReportUsingTaxLiableWithUSCountry()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxArea: Record "Tax Area";
        TaxBelowMaximum1: Decimal;
        TaxBelowMaximum2: Decimal;
        Total: Decimal;
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount and Total is correct in Purchase Invoice - Test Report using Tax Liable with US country.

        // Setup: Create Sales Invoice with Tax Area Country.
        // Exercise: Run and Save Purchase Document Test Report.
        // To repro the issue, we need make sure 3rd digits after the decimal point is (5,7). Here "Sales Tax Amount" = 1(Qty) * 0.1 (Direct Unit Cost) * TaxBelowMaximum / 100
        Initialize();
        TaxBelowMaximum1 := LibraryRandom.RandIntInRange(5, 6);
        TaxBelowMaximum2 := TaxBelowMaximum1 + 1; // Make different with TaxBelowMaximum1
        RunPurchaseDocumentTestReportWithTwoTaxAreaLines(
          PurchaseLine, PurchaseHeader."Document Type"::Invoice, TaxBelowMaximum1, TaxBelowMaximum2, TaxArea."Country/Region"::US, 1, 0.1);

        // Verify: Verify Tax Amount and Total
        TaxAmount := Round(PurchaseLine.Amount * TaxBelowMaximum1 / 100 + PurchaseLine.Amount * TaxBelowMaximum2 / 100);
        Total := Round(LibraryReportDataset.Sum('VATAmount') / 2, LibraryERM.GetAmountRoundingPrecision());

        Assert.AreEqual(TaxAmount, SumTaxAmountInTestReport(), TaxAmountErr);
        Assert.AreEqual(Total, SumTaxAmountInTestReport(), TaxAmountNotEqualTotalErr);
    end;

    [Test]
    [HandlerFunctions('PurchaseDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceTestReportUsingTaxLiableWithCACountry()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxArea: Record "Tax Area";
        TaxBelowMaximum1: Decimal;
        TaxBelowMaximum2: Decimal;
        Total: Decimal;
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount and Total is correct in Purchase Invoice - Test Report using Tax Liable with US country.

        // Setup: Create Sales Invoice with Tax Area Country.
        // Exercise: Run and Save Purchase Document Test Report.
        // To repro the issue, we need make sure 3rd digits after the decimal point is (5,7). Here "Sales Tax Amount" = 1(Qty) * 0.1 (Direct Unit Cost) * TaxBelowMaximum / 100
        Initialize();
        TaxBelowMaximum1 := LibraryRandom.RandIntInRange(5, 7);
        TaxBelowMaximum2 := LibraryRandom.RandIntInRange(5, 7) + 100; // Make different with TaxBelowMaximum1.
        RunPurchaseDocumentTestReportWithTwoTaxAreaLines(
          PurchaseLine, PurchaseHeader."Document Type"::Invoice, TaxBelowMaximum1, TaxBelowMaximum2, TaxArea."Country/Region"::CA, 1, 0.1);

        // Verify: Verify Tax Amount and Total
        TaxAmount := Round(PurchaseLine.Amount * TaxBelowMaximum1 / 100) + Round(PurchaseLine.Amount * TaxBelowMaximum2 / 100);
        Total := Round(LibraryReportDataset.Sum('VATAmount') / 2, LibraryERM.GetAmountRoundingPrecision());

        Assert.AreEqual(TaxAmount, SumTaxAmountInTestReport(), TaxAmountErr);
        Assert.AreEqual(Total, SumTaxAmountInTestReport(), TaxAmountNotEqualTotalErr);
    end;

    [Test]
    [HandlerFunctions('PurchaseDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseDocumentTestReportTaxAmount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxGroup: Record "Tax Group";
        TaxDetail: Record "Tax Detail";
        i: Integer;
    begin
        // [FEATURE] [Purchase] [Purchase Tax]
        // [SCENARIO 374921] "Tax Amount" rounding in "Purchase Document - Test" when 3 tax jurisdictions involved.
        Initialize();
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxArea(TaxArea);

        // [GIVEN] 3 Tax Jurisdictions. Tax % = 3.35 in each Tax Jurisdiction.
        for i := 1 to 3 do begin
            CreateSalesTaxDetailWithCountry(
              TaxDetail, LibraryERMTax.CreateTaxJurisdictionWithSelfReportTo_US(), TaxGroup.Code, 3.35);
            LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");
        end;

        // [GIVEN] Purchase Invoice invoice with Amount = 10.
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 25));
        CreatePurchaseInvoiceWithCertainAmount(PurchaseHeader, VATPostingSetup, TaxArea.Code, 1, 10, TaxGroup.Code);

        // [WHEN] Run "Purchase Document - Test" report.
        LibraryVariableStorage.Enqueue(PurchaseHeader."Document Type");
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        Commit();
        REPORT.Run(REPORT::"Purchase Document - Test");

        // [THEN] Report contains "Tax Amount" = 10 * 0.0335 + 10 * 0.0335 + 10 * 0.0335 = 1.005 = 1.01.
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(
          GetVATEntryAmount(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true)),
          LibraryReportDataset.Sum('SalesTaxAmountLine__Tax_Amount_'), TaxAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderLineTaxAmountRouding()
    var
        SalesHeader: Record "Sales Header";
        SalesLinePositive: Record "Sales Line";
        SalesLineNegative: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        Quantity: Decimal;
        Price: Decimal;
    begin
        // BUG 100401:
        // Negative Sales Tax rounds down. We have different for positive / negative quanities for certain Tax % and amounts.
        // [SETUP]
        Initialize();
        Quantity := 1;
        AdjustTaxPriceRoundingPrecision(TaxDetail, Price, TaxAreaCode);

        // [Excercise]
        CreateAndReleaseSalesDocument(SalesLinePositive, SalesHeader."Document Type"::Order, TaxDetail, TaxAreaCode, Quantity, Price);
        CreateAndReleaseSalesDocument(SalesLineNegative, SalesHeader."Document Type"::Order, TaxDetail, TaxAreaCode, -Quantity, Price);

        // [Verification]
        Assert.AreEqual(
          -SalesLinePositive."Amount Including VAT",
          SalesLineNegative."Amount Including VAT",
          StrSubstNo(
            AmountErr,
            SalesLineNegative.FieldCaption("Amount Including VAT"),
            -SalesLinePositive."Amount Including VAT",
            SalesLineNegative.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderLineTaxAmountRouding()
    var
        PurchaseHeader: Record "Sales Header";
        PurchaseLinePositive: Record "Purchase Line";
        PurchaseLineNegative: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        Quantity: Decimal;
        Price: Decimal;
    begin
        // BUG 100401:
        // Negative Purchase Tax rounds down. We have different for positive / negative quanities for certain Tax % and amounts.
        // [SETUP]
        Initialize();
        Quantity := 1;
        AdjustTaxPriceRoundingPrecision(TaxDetail, Price, TaxAreaCode);

        // [Excercise]
        CreateAndReleasePurchaseDocument(
          PurchaseLinePositive, PurchaseHeader."Document Type"::Order, TaxDetail, TaxAreaCode, Quantity, Price);
        CreateAndReleasePurchaseDocument(
          PurchaseLineNegative, PurchaseHeader."Document Type"::Order, TaxDetail, TaxAreaCode, -Quantity, Price);

        // [Verification]
        Assert.AreEqual(
          -PurchaseLinePositive."Amount Including VAT",
          PurchaseLineNegative."Amount Including VAT",
          StrSubstNo(
            AmountErr,
            PurchaseLineNegative.FieldCaption("Amount Including VAT"),
            -PurchaseLinePositive."Amount Including VAT",
            PurchaseLineNegative.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyUnrealizedSalesOrderWithTax()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJnlLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        TaxAreaCode: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales] [Unrealized VAT]
        // [SCENARIO 377055] G/L Entry with Unrealized VAT Amount should be posted to "Unreal. Tax Acc. (Sales)" from Tax Jurisdiction when unapply payment

        // [GIVEN] Unrealized Sales Tax setup. Tax Jurisdiction with "Unreal. Tax Acc. (Sales)" = "X"
        Initialize();
        VATEntry.DeleteAll();
        LibraryERM.SetUnrealizedVAT(true);
        SetupUnrealTaxJurisdiction(TaxAreaCode, TaxDetail, TaxJurisdiction, TaxDetail."Tax Type"::"Sales Tax Only");
        CreateSalesTaxVATPostingSetup(VATPostingSetup);

        // [GIVEN] Posted Sales Invoice with Unrealized Sales Tax setup
        CreateSalesInvoiceWithCertainAmount(
          SalesHeader, VATPostingSetup, TaxAreaCode,
          LibraryRandom.RandInt(100), LibraryRandom.RandDec(100, 2), TaxDetail."Tax Group Code");
        FindSalesLine(SalesLine, SalesHeader);
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Payment applied to Sales Invoice
        CreateAndPostGenJournalLineUsingApplication(
          GenJnlLine, DocNo, GenJnlLine."Account Type"::Customer, SalesHeader."Bill-to Customer No.",
          LibraryERM.CreateGLAccountNo(), '', GenJnlLine."Document Type"::Payment,
          GenJnlLine."Applies-to Doc. Type"::Invoice, -SalesLine."Line Amount");

        // [WHEN] Unapply Payment
        UnapplyCustLedgerEntry(GenJnlLine."Document Type", GenJnlLine."Document No.");

        // [THEN] G/L Entry with tax will be posted to "G/L Account No." = "X"
        VerifyVATGLEntryOnUnapplication(
          GenJnlLine."Document No.", FindCustUnapplicationTransactionNo(GenJnlLine."Document Type", GenJnlLine."Document No."),
          TaxJurisdiction."Unreal. Tax Acc. (Sales)");

        TaxJurisdiction.Validate("Unrealized VAT Type", TaxJurisdiction."Unrealized VAT Type"::" ");
        TaxJurisdiction.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyUnrealizedPurchOrderWithTax()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GenJnlLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        TaxAreaCode: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Unrealized VAT]
        // [SCENARIO 377055] G/L Entry with Unrealized VAT Amount should be posted to "Unreal. Tax Acc. (Purchase)" from Tax Jurisdiction when unapply payment

        // [GIVEN] Unrealized Purchase Tax setup. Tax Jurisdiction with "Unreal. Tax Acc. (Purchase)" = "X"
        Initialize();
        VATEntry.DeleteAll();
        LibraryERM.SetUnrealizedVAT(true);
        SetupUnrealTaxJurisdiction(TaxAreaCode, TaxDetail, TaxJurisdiction, TaxDetail."Tax Type"::"Sales Tax Only");
        CreateSalesTaxVATPostingSetup(VATPostingSetup);

        // [GIVEN] Posted Purchase Invoice with Unrealized Sales Tax setup
        CreatePurchaseInvoiceWithCertainAmount(
          PurchHeader, VATPostingSetup, TaxAreaCode,
          LibraryRandom.RandInt(100), LibraryRandom.RandDec(100, 2), TaxDetail."Tax Group Code");
        FindPurchLine(PurchLine, PurchHeader);
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [GIVEN] Payment applied to Sales Invoice
        CreateAndPostGenJournalLineUsingApplication(
          GenJnlLine, DocNo, GenJnlLine."Account Type"::Vendor, PurchHeader."Pay-to Vendor No.",
          LibraryERM.CreateGLAccountNo(), '', GenJnlLine."Document Type"::Payment,
          GenJnlLine."Applies-to Doc. Type"::Invoice, PurchLine."Line Amount");

        // [WHEN] Unapply Payment
        UnapplyVendLedgerEntry(GenJnlLine."Document Type", GenJnlLine."Document No.");

        // [THEN] G/L Entry with tax will be posted to "G/L Account No." = "X"
        VerifyVATGLEntryOnUnapplication(
          GenJnlLine."Document No.", FindVendUnapplicationTransactionNo(GenJnlLine."Document Type", GenJnlLine."Document No."),
          TaxJurisdiction."Unreal. Tax Acc. (Purchases)");

        TaxJurisdiction.Validate("Unrealized VAT Type", TaxJurisdiction."Unrealized VAT Type"::" ");
        TaxJurisdiction.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeVATAmountGenJnlLineWhenSalesTax()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        MaxVATDiffAllowed: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [VAT Amount]
        // [SCENARIO 269045] VAT Amount can be adjusted in Gen. Journal Line when VAT Calculation Type = "Sales Tax"
        Initialize();
        MaxVATDiffAllowed := LibraryRandom.RandDecInRange(10, 20, 2);

        // [GIVEN] "Max. VAT Difference Allowed" = 10.0 in General Ledger Setup
        LibraryERM.SetMaxVATDifferenceAllowed(MaxVATDiffAllowed);

        // [GIVEN] Gen. Journal Batch with "Allow VAT Difference" = TRUE
        CreateGenJournalBatchWithAllowVATDifference(GenJournalBatch);

        // [GIVEN] Gen. Journal Line with VAT Calculation Type = "Sales Tax", Amount = 1100.0 and VAT Amount = 100.0
        CreateGenJournalLineWithGLAccount(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
        GenJournalLine."VAT Calculation Type" := GenJournalLine."VAT Calculation Type"::"Sales Tax";
        GenJournalLine."VAT %" := LibraryRandom.RandDecInRange(10, 20, 2);
        GenJournalLine."VAT Amount" := Round(GenJournalLine.Amount * GenJournalLine."VAT %" / (100 + GenJournalLine."VAT %"));
        VATAmount := GenJournalLine."VAT Amount" + MaxVATDiffAllowed;

        // [WHEN] Validate VAT Amount = 90.0 in Gen. Journal Line
        GenJournalLine.Validate("VAT Amount", VATAmount);

        // [THEN] VAT Amount = 90.0 in Gen. Journal Line
        GenJournalLine.TestField("VAT Amount", VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeBalVATAmountGenJnlLineWhenSalesTax()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        MaxVATDiffAllowed: Decimal;
        BalVATAmount: Decimal;
    begin
        // [FEATURE] [Bal. VAT Amount]
        // [SCENARIO 269045] Bal. VAT Amount can be adjusted in Gen. Journal Line when VAT Calculation Type = "Sales Tax"
        Initialize();
        MaxVATDiffAllowed := LibraryRandom.RandDecInRange(10, 20, 2);

        // [GIVEN] "Max. VAT Difference Allowed" = 10.0 in General Ledger Setup
        LibraryERM.SetMaxVATDifferenceAllowed(MaxVATDiffAllowed);

        // [GIVEN] Gen. Journal Batch with "Allow VAT Difference" = TRUE
        CreateGenJournalBatchWithAllowVATDifference(GenJournalBatch);

        // [GIVEN] Gen. Journal Line with VAT Calculation Type = "Sales Tax", Amount = 1100.0 and Bal. VAT Amount = 100.0
        CreateGenJournalLineWithGLAccount(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
        GenJournalLine."Bal. VAT Calculation Type" := GenJournalLine."Bal. VAT Calculation Type"::"Sales Tax";
        GenJournalLine."Bal. VAT %" := LibraryRandom.RandDecInRange(10, 20, 2);
        GenJournalLine."Bal. VAT Amount" :=
          -Round(GenJournalLine.Amount * GenJournalLine."Bal. VAT %" / (100 + GenJournalLine."Bal. VAT %"));
        BalVATAmount := GenJournalLine."Bal. VAT Amount" + MaxVATDiffAllowed;

        // [WHEN] Validate Bal. VAT Amount = 90.0 in Gen. Journal Line
        GenJournalLine.Validate("Bal. VAT Amount", BalVATAmount);

        // [THEN] Bal. VAT Amount = 90.0 in Gen. Journal Line
        GenJournalLine.TestField("Bal. VAT Amount", BalVATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeVATAmountGenJnlLineWhenFullVATErr()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Full VAT] [VAT Amount]
        // [SCENARIO 269045] Error when validate VAT Amount in Gen. Journal Line with VAT Calculation Type = "Full VAT"
        Initialize();

        // [GIVEN] Gen. Journal Batch with "Allow VAT Difference" = TRUE
        CreateGenJournalBatchWithAllowVATDifference(GenJournalBatch);

        // [GIVEN] Gen. Journal Line with VAT Calculation Type = "Full VAT" and <blank> VAT Amount
        CreateGenJournalLineWithGLAccount(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
        GenJournalLine."VAT Calculation Type" := GenJournalLine."VAT Calculation Type"::"Full VAT";

        // [WHEN] Validate VAT Amount = 100.0 in Gen. Journal Line
        asserterror GenJournalLine.Validate("VAT Amount", LibraryRandom.RandDecInRange(10, 20, 2));

        // [THEN] Error: "VAT Calculation Type must be Normal VAT, Reverse Charge VAT or Sales Tax."
        Assert.ExpectedError(StrSubstNo(VATCalculationTypeErr, GenJournalLine.FieldCaption("VAT Calculation Type")));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeBalVATAmountGenJnlLineWhenFullVATErr()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Full VAT] [Bal. VAT Amount]
        // [SCENARIO 269045] Error when validate Bal. VAT Amount in Gen. Journal Line with VAT Calculation Type = "Full VAT"
        Initialize();

        // [GIVEN] Gen. Journal Batch with "Allow VAT Difference" = TRUE
        CreateGenJournalBatchWithAllowVATDifference(GenJournalBatch);

        // [GIVEN] Gen. Journal Line with VAT Calculation Type = "Full VAT" and <blank> Bal. VAT Amount
        CreateGenJournalLineWithGLAccount(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
        GenJournalLine."Bal. VAT Calculation Type" := GenJournalLine."Bal. VAT Calculation Type"::"Full VAT";

        // [WHEN] Validate Bal. VAT Amount = 100.0 in Gen. Journal Line
        asserterror GenJournalLine.Validate("Bal. VAT Amount", LibraryRandom.RandDecInRange(10, 20, 2));

        // [THEN] Error: "Bal. VAT Calculation Type must be Normal VAT, Reverse Charge VAT or Sales Tax."
        Assert.ExpectedError(StrSubstNo(VATCalculationTypeErr, GenJournalLine.FieldCaption("Bal. VAT Calculation Type")));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInvoiceSubformTaxAreaCodeVisibleEditable()
    var
        SalesOrderInvoiceSubform: TestPage "Sales Order Invoice Subform";
    begin
        // [FEATURE] [Sales Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Sales Order Invoice Subform is Visible and Editable

        // [GIVEN] Sales Order Invoice Subform page.

        // [WHEN] Sales Order Invoice Subform is opened in Edit mode.
        SalesOrderInvoiceSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible and Editable are set to TRUE.
        Assert.IsTrue(
          SalesOrderInvoiceSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, SalesOrderInvoiceSubform."Tax Area Code".Caption));
        Assert.IsTrue(
          SalesOrderInvoiceSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeEditableErr, SalesOrderInvoiceSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesTaxLinesSubformTaxAreaCodeVisibleEditable()
    var
        SalesTaxLinesSubform: TestPage "Sales Tax Lines Subform";
    begin
        // [FEATURE] [Sales Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Sales Tax Lines Subform is Visible and Editable

        // [GIVEN] Sales Tax Lines Subform page.

        // [WHEN] Sales Tax Lines Subform is opened in Edit mode.
        SalesTaxLinesSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible and Editable are set to TRUE.
        Assert.IsTrue(
          SalesTaxLinesSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, SalesTaxLinesSubform."Tax Area Code".Caption));
        Assert.IsTrue(
          SalesTaxLinesSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeEditableErr, SalesTaxLinesSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesTaxLinesServSubformTaxAreaCodeVisibleEditable()
    var
        SalesTaxLinesServSubform: TestPage "Sales Tax Lines Serv. Subform";
    begin
        // [FEATURE] [Sales Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Sales Tax Lines Serv. Subform is Visible and Editable

        // [GIVEN] Sales Tax Lines Serv. Subform page.

        // [WHEN] Sales Tax Lines Serv. Subform is opened in Edit mode.
        SalesTaxLinesServSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible and Editable are set to TRUE.
        Assert.IsTrue(
          SalesTaxLinesServSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, SalesTaxLinesServSubform."Tax Area Code".Caption));
        Assert.IsTrue(
          SalesTaxLinesServSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeEditableErr, SalesTaxLinesServSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceSubformTaxAreaCodeVisibleEditable()
    var
        PostedSalesInvoiceSubform: TestPage "Posted Sales Invoice Subform";
    begin
        // [FEATURE] [Sales Invoice Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Posted Sales Invoice Subform is Visible and not Editable

        // [GIVEN] Posted Sales Invoice Subform page.

        // [WHEN] Posted Sales Invoice Subform is opened in Edit mode.
        PostedSalesInvoiceSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible is set to TRUE and Editable is set to FALSE.
        Assert.IsTrue(
          PostedSalesInvoiceSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, PostedSalesInvoiceSubform."Tax Area Code".Caption));
        Assert.IsFalse(
          PostedSalesInvoiceSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeNotEditableErr, PostedSalesInvoiceSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoSubformTaxAreaCodeVisibleEditable()
    var
        PostedSalesCrMemoSubform: TestPage "Posted Sales Cr. Memo Subform";
    begin
        // [FEATURE] [Sales Cr.Memo Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Posted Sales Cr. Memo Subform is Visible and not Editable

        // [GIVEN] Posted Sales Cr. Memo Subform page.

        // [WHEN] Posted Sales Cr. Memo Subform is opened in Edit mode.
        PostedSalesCrMemoSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible is set to TRUE and Editable is set to FALSE.
        Assert.IsTrue(
          PostedSalesCrMemoSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, PostedSalesCrMemoSubform."Tax Area Code".Caption));
        Assert.IsFalse(
          PostedSalesCrMemoSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeNotEditableErr, PostedSalesCrMemoSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderSubformTaxAreaCodeVisibleEditable()
    var
        SalesOrderSubform: TestPage "Sales Order Subform";
    begin
        // [FEATURE] [Sales Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Sales Order Subform is Visible and Editable

        // [GIVEN] Sales Order Subform page.

        // [WHEN] Sales Order Subform is opened in Edit mode.
        SalesOrderSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible and Editable are set to TRUE.
        Assert.IsTrue(
          SalesOrderSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, SalesOrderSubform."Tax Area Code".Caption));
        Assert.IsTrue(
          SalesOrderSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeEditableErr, SalesOrderSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceSubformTaxAreaCodeVisibleEditable()
    var
        SalesInvoiceSubform: TestPage "Sales Invoice Subform";
    begin
        // [FEATURE] [Sales Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Sales Invoice Subform is Visible and Editable

        // [GIVEN] Sales Invoice Subform page.

        // [WHEN] Sales Invoice Subform is opened in Edit mode.
        SalesInvoiceSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible and Editable are set to TRUE.
        Assert.IsTrue(
          SalesInvoiceSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, SalesInvoiceSubform."Tax Area Code".Caption));
        Assert.IsTrue(
          SalesInvoiceSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeEditableErr, SalesInvoiceSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderSubformTaxAreaCodeVisibleEditable()
    var
        BlanketSalesOrderSubform: TestPage "Blanket Sales Order Subform";
    begin
        // [FEATURE] [Sales Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Blanket Sales Order Subform is Visible and Editable

        // [GIVEN] Blanket Sales Order Subform page.

        // [WHEN] Blanket Sales Order Subform is opened in Edit mode.
        BlanketSalesOrderSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible and Editable are set to TRUE.
        Assert.IsTrue(
          BlanketSalesOrderSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, BlanketSalesOrderSubform."Tax Area Code".Caption));
        Assert.IsTrue(
          BlanketSalesOrderSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeEditableErr, BlanketSalesOrderSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderArchiveSubformTaxAreaCodeVisibleEditable()
    var
        SalesOrderArchiveSubform: TestPage "Sales Order Archive Subform";
    begin
        // [FEATURE] [Sales Line Archive] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Sales Order Archive Subform is Visible and not Editable

        // [GIVEN] Sales Order Archive Subform page.

        // [WHEN] Sales Order Archive Subform is opened in Edit mode.
        SalesOrderArchiveSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible is set to TRUE and Editable is set to FALSE.
        Assert.IsTrue(
          SalesOrderArchiveSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, SalesOrderArchiveSubform."Tax Area Code".Caption));
        Assert.IsFalse(
          SalesOrderArchiveSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeNotEditableErr, SalesOrderArchiveSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteArchiveSubformTaxAreaCodeVisibleEditable()
    var
        SalesQuoteArchiveSubform: TestPage "Sales Quote Archive Subform";
    begin
        // [FEATURE] [Sales Line Archive] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Sales Quote Archive Subform is Visible and not Editable

        // [GIVEN] Sales Quote Archive Subform page.

        // [WHEN] Sales Quote Archive Subform is opened in Edit mode.
        SalesQuoteArchiveSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible is set to TRUE and Editable is set to FALSE.
        Assert.IsTrue(
          SalesQuoteArchiveSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, SalesQuoteArchiveSubform."Tax Area Code".Caption));
        Assert.IsFalse(
          SalesQuoteArchiveSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeNotEditableErr, SalesQuoteArchiveSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderSubformTaxAreaCodeVisibleEditable()
    var
        SalesReturnOrderSubform: TestPage "Sales Return Order Subform";
    begin
        // [FEATURE] [Sales Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Sales Return Order Subform is Visible and Editable

        // [GIVEN] Sales Return Order Subform page.

        // [WHEN] Sales Return Order Subform is opened in Edit mode.
        SalesReturnOrderSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible and Editable are set to TRUE.
        Assert.IsTrue(
          SalesReturnOrderSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, SalesReturnOrderSubform."Tax Area Code".Caption));
        Assert.IsTrue(
          SalesReturnOrderSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeEditableErr, SalesReturnOrderSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteSubformTaxAreaCodeVisibleEditable()
    var
        SalesQuoteSubform: TestPage "Sales Quote Subform";
    begin
        // [FEATURE] [Sales Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Sales Quote Subform is Visible and Editable

        // [GIVEN] Sales Quote Subform page.

        // [WHEN] Sales Quote Subform is opened in Edit mode.
        SalesQuoteSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible and Editable are set to TRUE.
        Assert.IsTrue(
          SalesQuoteSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, SalesQuoteSubform."Tax Area Code".Caption));
        Assert.IsTrue(
          SalesQuoteSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeEditableErr, SalesQuoteSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoSubformTaxAreaCodeVisibleEditable()
    var
        SalesCrMemoSubform: TestPage "Sales Cr. Memo Subform";
    begin
        // [FEATURE] [Sales Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Sales Cr. Memo Subform is Visible and Editable

        // [GIVEN] Sales Cr. Memo Subform page.

        // [WHEN] Sales Cr. Memo Subform is opened in Edit mode.
        SalesCrMemoSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible and Editable are set to TRUE.
        Assert.IsTrue(
          SalesCrMemoSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, SalesCrMemoSubform."Tax Area Code".Caption));
        Assert.IsTrue(
          SalesCrMemoSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeEditableErr, SalesCrMemoSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceSubformTaxAreaCodeVisibleEditable()
    var
        PostedPurchInvoiceSubform: TestPage "Posted Purch. Invoice Subform";
    begin
        // [FEATURE] [Purchase Invoice Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Posted Purch. Invoice Subform is Visible and not Editable

        // [GIVEN] Posted Purch. Invoice Subform page.

        // [WHEN] Posted Purch. Invoice Subform is opened in Edit mode.
        PostedPurchInvoiceSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible is set to TRUE and Editable is set to FALSE.
        Assert.IsTrue(
          PostedPurchInvoiceSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, PostedPurchInvoiceSubform."Tax Area Code".Caption));
        Assert.IsFalse(
          PostedPurchInvoiceSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeNotEditableErr, PostedPurchInvoiceSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoSubformTaxAreaCodeVisibleEditable()
    var
        PostedPurchCrMemoSubform: TestPage "Posted Purch. Cr. Memo Subform";
    begin
        // [FEATURE] [Purchase Cr.Memo Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Posted Purch. Cr. Memo Subform is Visible and not Editable

        // [GIVEN] Posted Purch. Cr. Memo Subform page.

        // [WHEN] Posted Purch. Cr. Memo Subform is opened in Edit mode.
        PostedPurchCrMemoSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible is set to TRUE and Editable is set to FALSE.
        Assert.IsTrue(
          PostedPurchCrMemoSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, PostedPurchCrMemoSubform."Tax Area Code".Caption));
        Assert.IsFalse(
          PostedPurchCrMemoSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeNotEditableErr, PostedPurchCrMemoSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderSubformTaxAreaCodeVisibleEditable()
    var
        BlanketPurchaseOrderSubform: TestPage "Blanket Purchase Order Subform";
    begin
        // [FEATURE] [Purchase Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Blanket Purchase Order Subform is Visible and Editable

        // [GIVEN] Blanket Purchase Order Subform page.

        // [WHEN] Blanket Purchase Order Subform is opened in Edit mode.
        BlanketPurchaseOrderSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible and Editable are set to TRUE.
        Assert.IsTrue(
          BlanketPurchaseOrderSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, BlanketPurchaseOrderSubform."Tax Area Code".Caption));
        Assert.IsTrue(
          BlanketPurchaseOrderSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeEditableErr, BlanketPurchaseOrderSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteArchiveSubformTaxAreaCodeVisibleEditable()
    var
        PurchaseQuoteArchiveSubform: TestPage "Purchase Quote Archive Subform";
    begin
        // [FEATURE] [Purchase Archive Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Purchase Quote Archive Subform is Visible and not Editable

        // [GIVEN] Purchase Quote Archive Subform page.

        // [WHEN] Purchase Quote Archive Subform is opened in Edit mode.
        PurchaseQuoteArchiveSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible is set to TRUE and Editable is set to FALSE.
        Assert.IsTrue(
          PurchaseQuoteArchiveSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, PurchaseQuoteArchiveSubform."Tax Area Code".Caption));
        Assert.IsFalse(
          PurchaseQuoteArchiveSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeNotEditableErr, PurchaseQuoteArchiveSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderArchiveSubformTaxAreaCodeVisibleEditable()
    var
        PurchaseOrderArchiveSubform: TestPage "Purchase Order Archive Subform";
    begin
        // [FEATURE] [Purchase Archive Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Purchase Order Archive Subform is Visible and not Editable

        // [GIVEN] Purchase Order Archive Subform page.

        // [WHEN] Purchase Order Archive Subform is opened in Edit mode.
        PurchaseOrderArchiveSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible is set to TRUE and Editable is set to FALSE.
        Assert.IsTrue(
          PurchaseOrderArchiveSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, PurchaseOrderArchiveSubform."Tax Area Code".Caption));
        Assert.IsFalse(
          PurchaseOrderArchiveSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeNotEditableErr, PurchaseOrderArchiveSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderSubformTaxAreaCodeVisibleEditable()
    var
        PurchaseOrderSubform: TestPage "Purchase Order Subform";
    begin
        // [FEATURE] [Purchase Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Purchase Order Subform is Visible and Editable

        // [GIVEN] Purchase Order Subform page.

        // [WHEN] Purchase Order Subform is opened in Edit mode.
        PurchaseOrderSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible and Editable are set to TRUE.
        Assert.IsTrue(
          PurchaseOrderSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, PurchaseOrderSubform."Tax Area Code".Caption));
        Assert.IsTrue(
          PurchaseOrderSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeEditableErr, PurchaseOrderSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceSubformTaxAreaCodeVisibleEditable()
    var
        PurchInvoiceSubform: TestPage "Purch. Invoice Subform";
    begin
        // [FEATURE] [Purchase Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Purch. Invoice Subform is Visible and Editable

        // [GIVEN] Purch. Invoice Subform page.

        // [WHEN] Purch. Invoice Subform is opened in Edit mode.
        PurchInvoiceSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible and Editable are set to TRUE.
        Assert.IsTrue(
          PurchInvoiceSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, PurchInvoiceSubform."Tax Area Code".Caption));
        Assert.IsTrue(
          PurchInvoiceSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeEditableErr, PurchInvoiceSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderSubformTaxAreaCodeVisibleEditable()
    var
        PurchaseReturnOrderSubform: TestPage "Purchase Return Order Subform";
    begin
        // [FEATURE] [Purchase Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Purchase Return Order Subform is Visible and Editable

        // [GIVEN] Purchase Return Order Subform page.

        // [WHEN] Purchase Return Order Subform is opened in Edit mode.
        PurchaseReturnOrderSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible and Editable are set to TRUE.
        Assert.IsTrue(
          PurchaseReturnOrderSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, PurchaseReturnOrderSubform."Tax Area Code".Caption));
        Assert.IsTrue(
          PurchaseReturnOrderSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeEditableErr, PurchaseReturnOrderSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteSubformTaxAreaCodeVisibleEditable()
    var
        PurchaseQuoteSubform: TestPage "Purchase Quote Subform";
    begin
        // [FEATURE] [Purchase Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Purchase Quote Subform is Visible and Editable

        // [GIVEN] Purchase Quote Subform page.

        // [WHEN] Purchase Quote Subform is opened in Edit mode.
        PurchaseQuoteSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible and Editable are set to TRUE.
        Assert.IsTrue(
          PurchaseQuoteSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, PurchaseQuoteSubform."Tax Area Code".Caption));
        Assert.IsTrue(
          PurchaseQuoteSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeEditableErr, PurchaseQuoteSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoSubformTaxAreaCodeVisibleEditable()
    var
        PurchCrMemoSubform: TestPage "Purch. Cr. Memo Subform";
    begin
        // [FEATURE] [Purchase Line] [UT]
        // [SCENARIO 301481] "Tax Area Code" field on page Purch. Cr. Memo Subform is Visible and Editable

        // [GIVEN] Purch. Cr. Memo Subform page.

        // [WHEN] Purch. Cr. Memo Subform is opened in Edit mode.
        PurchCrMemoSubform.OpenEdit();

        // [THEN] "Tax Area Code" field's properties Visible and Editable are set to TRUE.
        Assert.IsTrue(
          PurchCrMemoSubform."Tax Area Code".Visible(),
          StrSubstNo(TaxAreaCodeVisibleErr, PurchCrMemoSubform."Tax Area Code".Caption));
        Assert.IsTrue(
          PurchCrMemoSubform."Tax Area Code".Editable(),
          StrSubstNo(TaxAreaCodeEditableErr, PurchCrMemoSubform."Tax Area Code".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaxDetailRateHasFourDecimalPlaces()
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
        TaxDetails: TestPage "Tax Details";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 312423] A "Tax Below Maximum" and "Tax Above Maximum" of Tax Detail has four decimal places

        Initialize();
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, '', 0, 0D);
        TaxDetail.Validate("Tax Below Maximum", 12.3456);
        TaxDetail.Validate("Tax Above Maximum", 12.3456);
        TaxDetail.Modify(true);

        TaxDetails.OpenEdit();
        TaxDetails.FILTER.SetFilter("Tax Jurisdiction Code", TaxDetail."Tax Jurisdiction Code");
        TaxDetails."Tax Below Maximum".AssertEquals('12.3456');
        TaxDetails."Tax Above Maximum".AssertEquals('12.3456');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaxDefaultSalesHasFourDecimalPlaces()
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxJurisdictions: TestPage "Tax Jurisdictions";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 312424] A "Default Sales & Use Tax" of Tax Jurisdiction has four decimal places

        // [GIVEN] Create Tax Juridiction.
        Initialize();
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);

        // [WHEN] page Tax Juridictions is opened in Edit mode.
        TaxJurisdictions.OpenEdit();

        // [THEN] Go to created record. Set value with 4 decimal places. Check the value.
        TaxJurisdictions.FILTER.SetFilter(Code, TaxJurisdiction.Code);
        TaxJurisdictions."Default Sales and Use Tax".SetValue('9.1234');
        TaxJurisdictions."Default Sales and Use Tax".AssertEquals('9.1234');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseApplyPaymentUnrealizedUseTax()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GenJnlLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        TaxAreaCode: Code[20];
        DocNo: Code[20];
        TaxAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment] [Apply] [Unrealized VAT] [Use Tax]
        // [SCENARIO 318764]  G/L Entry with Unrealized VAT Amount should be posted from "Unreal. Rev. Charge (Purch.)"  to "Reverse Charge (Purchases)" from Tax Jurisdiction when apply payment

        // [GIVEN] Unrealized Purchase Tax setup. Tax Jurisdiction with "Unreal. Rev. Charge (Purch.)" = "X" and "Reverse Charge (Purchases)" = "Y"
        Initialize();
        VATEntry.DeleteAll();
        LibraryERM.SetUnrealizedVAT(true);
        SetupUnrealTaxJurisdiction(TaxAreaCode, TaxDetail, TaxJurisdiction, TaxDetail."Tax Type"::"Sales and Use Tax");
        CreateSalesTaxVATPostingSetup(VATPostingSetup);

        // [GIVEN] Posted Purchase Invoice with Unrealized Sales Tax setup and "Use Tax" enabled
        CreatePurchaseInvoiceWithCertainAmount(
          PurchHeader, VATPostingSetup, TaxAreaCode,
          LibraryRandom.RandInt(100), LibraryRandom.RandDec(100, 2), TaxDetail."Tax Group Code");
        FindPurchLine(PurchLine, PurchHeader);
        PurchLine.Validate("Use Tax", true);
        PurchLine.Modify(true);
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        TaxAmount := GetVATEntryRemainingUnrealAmount(DocNo);
        Assert.AreNotEqual(TaxAmount, 0, 'Unrealized tax amount should not be zero.');

        // [WHEN] Payment applied to Purchase Invoice
        CreateAndPostGenJournalLineUsingApplication(
          GenJnlLine, DocNo, GenJnlLine."Account Type"::Vendor, PurchHeader."Pay-to Vendor No.",
          LibraryERM.CreateGLAccountNo(), '', GenJnlLine."Document Type"::Payment,
          GenJnlLine."Applies-to Doc. Type"::Invoice, PurchLine."Line Amount");

        // [THEN] G/L Entry with tax will be posted to "Y" from "X"
        VerifyGLEntryAmount(GenJnlLine."Document No.", TaxJurisdiction.GetRevChargeAccount(true), TaxAmount);
        VerifyGLEntryAmount(GenJnlLine."Document No.", TaxJurisdiction.GetRevChargeAccount(false), -TaxAmount);

        // [THEN] G/L Entry with "Tax Account (Purchases)" and "Unreal. Tax Acc. (Purchases)" are not posted
        VerifyGLEntryDoesNotExist(GenJnlLine."Document No.", TaxJurisdiction.GetPurchAccount(true));
        VerifyGLEntryDoesNotExist(GenJnlLine."Document No.", TaxJurisdiction.GetPurchAccount(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseUnapplyPaymentUnrealizedUseTax()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GenJnlLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        TaxAreaCode: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Payment] [Unapply] [Unrealized VAT] [Use Tax]
        // [SCENARIO 318764] G/L Entry with Unrealized VAT Amount should be posted to "Unreal. Rev. Charge (Purch.)" from Tax Jurisdiction when unapply payment

        // [GIVEN] Unrealized Purchase Tax setup. Tax Jurisdiction with "Unreal. Rev. Charge (Purch.)" = "X" and "Reverse Charge (Purchases)" = "Y"
        Initialize();
        VATEntry.DeleteAll();
        LibraryERM.SetUnrealizedVAT(true);
        SetupUnrealTaxJurisdiction(TaxAreaCode, TaxDetail, TaxJurisdiction, TaxDetail."Tax Type"::"Sales and Use Tax");
        CreateSalesTaxVATPostingSetup(VATPostingSetup);

        // [GIVEN] Posted Purchase Invoice with Unrealized Sales Tax setup
        CreatePurchaseInvoiceWithCertainAmount(
          PurchHeader, VATPostingSetup, TaxAreaCode,
          LibraryRandom.RandInt(100), LibraryRandom.RandDec(100, 2), TaxDetail."Tax Group Code");
        FindPurchLine(PurchLine, PurchHeader);
        PurchLine.Validate("Use Tax", true);
        PurchLine.Modify(true);
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [GIVEN] Payment applied to Purchase Invoice
        CreateAndPostGenJournalLineUsingApplication(
          GenJnlLine, DocNo, GenJnlLine."Account Type"::Vendor, PurchHeader."Pay-to Vendor No.",
          LibraryERM.CreateGLAccountNo(), '', GenJnlLine."Document Type"::Payment,
          GenJnlLine."Applies-to Doc. Type"::Invoice, PurchLine."Line Amount");

        // [WHEN] Unapply Payment
        UnapplyVendLedgerEntry(GenJnlLine."Document Type", GenJnlLine."Document No.");

        // [THEN] G/L Entry with tax will be posted to "G/L Account No." = "Y"
        VerifyVATGLEntryOnUnapplication(
          GenJnlLine."Document No.", FindVendUnapplicationTransactionNo(GenJnlLine."Document Type", GenJnlLine."Document No."),
          TaxJurisdiction."Unreal. Rev. Charge (Purch.)");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsChangePrepaymentPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPrepaymentGetsUpdatedFromStatistics()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        PrepmntAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Prepayment]
        // [SCENARIO 319776] Prepayment on Sales Lines updates after "Prepmt. Amount Excl. Tax" is changed on Sales Order Stats. page
        Initialize();
        // [GIVEN] Sales Order with TaxAreaCode for Customer and Prepayment %
        UpdateSetups(TRUE, LibraryRandom.RandIntInRange(10, 100));
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.VALIDATE("Prepayment %", LibraryRandom.RandInt(100));
        SalesHeader.MODIFY(TRUE);

        // [WHEN] Open Sales Order Stats. (10038) and modify Prepayment Amount
        PrepmntAmount := LibraryRandom.RandDec(ROUND(SalesLine.Amount, 1), 2);
        LibraryVariableStorage.Enqueue(PrepmntAmount);
        OpenSalesOrderPage(SalesOrder, SalesHeader);
        SalesOrder.Statistics.Invoke();

        // [THEN] Sales Line is updated
        SalesLine.SETRANGE("Document No.", SalesHeader."No.");
        SalesLine.SETRANGE("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();
        SalesLine.TESTFIELD("Prepmt. Line Amount", PrepmntAmount);
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsChangePrepaymentPageHandlerNM')]
    [Scope('OnPrem')]
    procedure SalesOrderPrepaymentGetsUpdatedFromStatisticsNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        PrepmntAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Prepayment]
        // [SCENARIO 319776] Prepayment on Sales Lines updates after "Prepmt. Amount Excl. Tax" is changed on Sales Order Stats. page
        Initialize();
        // [GIVEN] Sales Order with TaxAreaCode for Customer and Prepayment %
        UpdateSetups(TRUE, LibraryRandom.RandIntInRange(10, 100));
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.VALIDATE("Prepayment %", LibraryRandom.RandInt(100));
        SalesHeader.MODIFY(TRUE);

        // [WHEN] Open Sales Order Stats. (10038) and modify Prepayment Amount
        PrepmntAmount := LibraryRandom.RandDec(ROUND(SalesLine.Amount, 1), 2);
        LibraryVariableStorage.Enqueue(PrepmntAmount);
        OpenSalesOrderPage(SalesOrder, SalesHeader);
        SalesOrder.SalesOrderStats.Invoke();

        // [THEN] Sales Line is updated
        SalesLine.SETRANGE("Document No.", SalesHeader."No.");
        SalesLine.SETRANGE("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();
        SalesLine.TESTFIELD("Prepmt. Line Amount", PrepmntAmount);
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryApplicationArea.EnablePremiumSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        isInitialized := true;
        Commit();
        BindSubscription(ERMSalesPurchaseTax);
    end;

    local procedure CreateGenJournalTemplateWithAllowVATDifference(): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate("Allow VAT Difference", true);
        GenJournalTemplate.Modify(true);
        exit(GenJournalTemplate.Name);
    end;

    local procedure CreateGenJournalBatchWithAllowVATDifference(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, CreateGenJournalTemplateWithAllowVATDifference());
        GenJournalBatch.Validate("Allow VAT Difference", true);
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGenJournalLineWithGLAccount(var GenJournalLine: Record "Gen. Journal Line"; GenJournalTemplateName: Code[10]; GenJournalBatchName: Code[10])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplateName, GenJournalBatchName, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDecInRange(1000, 2000, 2));
    end;

    local procedure AdjustTaxPriceRoundingPrecision(var TaxDetail: Record "Tax Detail"; var Price: Decimal; var TaxAreaCode: Code[20])
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxAmount: Integer;
        RoundingPrecision: Decimal;
    begin
        TaxAmount := 50; // to get 1.5 multiplier
        CreateSalesTaxDetail(TaxDetail);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");
        TaxDetail.Validate("Tax Below Maximum", TaxAmount);
        TaxDetail.Modify(true);
        TaxAreaCode := TaxArea.Code;

        RoundingPrecision := 1 / Power(10, LibraryRandom.RandInt(5));
        UpdateGLSetupAmountRoundingPrecision(RoundingPrecision);
        Price := (LibraryRandom.RandInt(1000) * 2 + 1) * RoundingPrecision;
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocument(PurchaseLine, DocumentType);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostGenJournalLineUsingApplication(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; AccountNo: Code[20]; CurrencyCode: Code[10]; Type: Enum "Gen. Journal Document Type"; AppliesToDocType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    begin
        CreateGenJournalLine(GenJournalLine, Type, BalAccountType, BalAccountNo, 0);
        GenJournalLine.Validate("Bal. Account No.", AccountNo);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndModifyServiceLine(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"): Decimal
    var
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail);
        FindVATPostingSetup(VATPostingSetup);
        LibraryService.CreateServiceHeader(
          ServiceHeader, DocumentType, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group", TaxAreaCode));
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group", TaxDetail."Tax Group Code"));
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ModifyServiceLine(ServiceLine);
        exit(TaxDetail."Tax Below Maximum");
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]; TaxAreaCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Tax Liable", true);
        Customer.Validate("Tax Area Code", TaxAreaCode);
        Customer.Validate("Tax Identification Type", Customer."Tax Identification Type"::"Legal Entity");
        Customer.Validate("RFC No.", GetRandomCode(LibraryUtility.GetFieldLength(DATABASE::Customer, Customer.FieldNo("RFC No.")) - 1));  // Taken Length less than RFC No. Length as Tax Identification Type is Legal Entity.
        Customer.Validate("CURP No.", GetRandomCode(LibraryUtility.GetFieldLength(DATABASE::Customer, Customer.FieldNo("CURP No."))));
        Customer.Validate("Post Code", PostCode.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithInvDisc(): Code[20]
    var
        Customer: Record Customer;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", '', 0);
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        CustInvoiceDisc.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGLAccount(VATProdPostingGroup: Code[20]; TaxGroupCode: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Validate("Tax Group Code", TaxGroupCode);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]; TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Validate("Unit Price", LibraryRandom.RandInt(10));  // Using RANDOM value for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    var
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail);
        CreatePurchaseDocumentWithCertainTax(PurchaseLine, DocumentType, TaxDetail, TaxAreaCode);
    end;

    local procedure CreatePurchaseDocumentWithCertainTax(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; TaxDetail: Record "Tax Detail"; TaxAreaCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, DocumentType, CreateVendor(VATPostingSetup."VAT Bus. Posting Group", TaxAreaCode));
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group", TaxDetail."Tax Group Code"),
          LibraryRandom.RandInt(10));  // Using RANDOM value for Quantity.
    end;

    local procedure CreateAndReleasePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; TaxDetail: Record "Tax Detail"; TaxAreaCode: Code[20]; Quantity: Decimal; Cost: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocumentWithCertainTax(PurchaseLine, DocumentType, TaxDetail, TaxAreaCode);
        UpdatePurchaseLineAmount(PurchaseLine, Quantity, Cost);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseLine.Find();
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"): Decimal
    var
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail);
        exit(CreateSalesDocumentWithCertainTax(SalesLine, DocumentType, TaxDetail, TaxAreaCode));
    end;

    local procedure CreateSalesDocumentWithCertainTax(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; TaxDetail: Record "Tax Detail"; TaxAreaCode: Code[20]): Decimal
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group", TaxAreaCode));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group", TaxDetail."Tax Group Code"),
          LibraryRandom.RandInt(10));  // Using RANDOM value for Quantity.
        exit(TaxDetail."Tax Below Maximum");
    end;

    local procedure CreateSalesInvoiceWithCertainAmount(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; TaxAreaCode: Code[20]; Qty: Decimal; UnitPrice: Decimal; TaxGroupCode: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group", TaxAreaCode));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group", TaxGroupCode), Qty);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceWithCertainAmount(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; TaxAreaCode: Code[20]; Qty: Decimal; DirectUnitCost: Decimal; TaxGroupCode: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          CreateVendor(VATPostingSetup."VAT Bus. Posting Group", TaxAreaCode), TaxAreaCode);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group", TaxGroupCode), Qty);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndReleaseSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; TaxDetail: Record "Tax Detail"; TaxAreaCode: Code[20]; Quantity: Decimal; Price: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocumentWithCertainTax(SalesLine, DocumentType, TaxDetail, TaxAreaCode);
        UpdateSalesLineAmount(SalesLine, Quantity, Price);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesLine.Find();
    end;

    local procedure CreateSalesDocumentWithTwoTaxAreaLines(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; TaxBelowMaximum1: Decimal; TaxBelowMaximum2: Decimal; Country: Option; Qty: Decimal; UnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: array[2] of Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaWithTwoLines(TaxDetail, TaxBelowMaximum1, TaxBelowMaximum2, Country);
        FindVATPostingSetup(VATPostingSetup);

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group", TaxAreaCode));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group", TaxDetail[1]."Tax Group Code"), Qty);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);

        exit(SalesHeader."No.");
    end;

    local procedure CreatePurchaseDocumentWithTwoTaxAreaLines(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; TaxBelowMaximum1: Decimal; TaxBelowMaximum2: Decimal; Country: Option; Qty: Decimal; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: array[2] of Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaWithTwoLines(TaxDetail, TaxBelowMaximum1, TaxBelowMaximum2, Country);
        FindVATPostingSetup(VATPostingSetup);

        CreatePurchaseHeader(PurchaseHeader, DocumentType, CreateVendor(VATPostingSetup."VAT Bus. Posting Group", TaxAreaCode), TaxAreaCode);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group", TaxDetail[1]."Tax Group Code"), Qty);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);

        exit(PurchaseHeader."No.");
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Bill-to Address", SalesHeader."Sell-to Customer No.");
        SalesHeader.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; TaxAreaCode: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
    end;

    local procedure CreateMultipleGenJournalLineWithGSTHSTOptions(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20])
    begin
        CreateGenJournalLineForTypeSalesTax(GenJournalLine, GenJournalBatch, AccountNo, GenJournalLine."GST/HST"::" ");
        CreateGenJournalLineForTypeSalesTax(GenJournalLine, GenJournalBatch, AccountNo, GenJournalLine."GST/HST"::"Self Assessment");
        CreateGenJournalLineForTypeSalesTax(GenJournalLine, GenJournalBatch, AccountNo, GenJournalLine."GST/HST"::Rebate);
        CreateGenJournalLineForTypeSalesTax(GenJournalLine, GenJournalBatch, AccountNo, GenJournalLine."GST/HST"::"New Housing Rebates");
        CreateGenJournalLineForTypeSalesTax(GenJournalLine, GenJournalBatch, AccountNo, GenJournalLine."GST/HST"::"Pension Rebate");
    end;

    local procedure CreateGenJournalLineForTypeSalesTax(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; GSTHST: Enum "GST HST Tax Type")
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        LibraryERM.FindGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer, AccountNo, LibraryRandom.RandDec(100, 2));  // Using random for Amount.
        GenJournalLine.Validate("GST/HST", GSTHST);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateServiceDocument(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"): Decimal
    var
        ServiceHeader: Record "Service Header";
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail);
        FindVATPostingSetup(VATPostingSetup);
        LibraryService.CreateServiceHeader(
          ServiceHeader, DocumentType, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group", TaxAreaCode));
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group", TaxDetail."Tax Group Code"));
        ModifyServiceLine(ServiceLine);
        exit(TaxDetail."Tax Below Maximum");
    end;

    local procedure CreateTaxAreaLine(var TaxDetail: Record "Tax Detail"): Code[20]
    begin
        exit(CreateTaxAreaLineWithTaxType(TaxDetail, TaxDetail."Tax Type"::"Sales Tax Only"));
    end;

    local procedure CreateTaxAreaLineWithTaxType(var TaxDetail: Record "Tax Detail"; TaxType: Option): Code[20]
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        CreateSalesTaxDetailWithTaxType(TaxDetail, TaxType);
        LibraryERM.CreateTaxArea(TaxArea);
        // TFS ID 343371: Check that TaxArea with maxstrlen Description doesn't raise StringOverflow
        TaxArea.Validate(Description, LibraryUtility.GenerateRandomXMLText(MaxStrLen(TaxArea.Description)));
        TaxArea.Modify(true);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");
        exit(TaxArea.Code);
    end;

    local procedure CreateTaxAreaWithTwoLines(var TaxDetail: array[2] of Record "Tax Detail"; TaxBelowMaximum1: Decimal; TaxBelowMaximum2: Decimal; Country: Option): Code[20]
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxGroupCode: Code[20];
        TaxAreaCode: Code[20];
        TaxBelowMaximum: array[2] of Decimal;
        i: Integer;
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxAreaWithCountryRegion(Country);
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        TaxBelowMaximum[1] := TaxBelowMaximum1;
        TaxBelowMaximum[2] := TaxBelowMaximum2;
        for i := 1 to 2 do begin
            CreateSalesTaxDetailWithCountry(
              TaxDetail[i], LibraryERMTax.CreateTaxJurisdictionWithCountryRegion(Country), TaxGroupCode, TaxBelowMaximum[i]);
            LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxDetail[i]."Tax Jurisdiction Code");
        end;
        exit(TaxAreaCode);
    end;

    local procedure CreateSalesTaxDetail(var TaxDetail: Record "Tax Detail")
    begin
        CreateSalesTaxDetailWithTaxType(TaxDetail, TaxDetail."Tax Type"::"Sales Tax Only");
    end;

    local procedure CreateSalesTaxDetailWithTaxType(var TaxDetail: Record "Tax Detail"; TaxType: Option)
    begin
        LibraryERMTax.CreateTaxDetailWithTaxType(
          TaxDetail, LibraryERMTax.CreateTaxJurisdictionWithSelfReportTo_US(),
          LibraryERMTax.CreateTaxGroupCode(), TaxType, LibraryRandom.RandInt(10), 0);
    end;

    local procedure CreateSalesTaxDetailWithCountry(var TaxDetail: Record "Tax Detail"; TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20]; TaxBelowMaximum: Decimal)
    begin
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, TaxBelowMaximum);
    end;

    local procedure CreateAndModifyPurchaseDocument(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Order);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]; TaxAreaCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate("Tax Liable", true);
        Vendor.Validate("Tax Area Code", TaxAreaCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePACWebServices(var TempPACWebService: Record "PAC Web Service" temporary)
    begin
        TempPACWebService.Init();
        TempPACWebService.Validate(Code, LibraryUtility.GenerateRandomCode(TempPACWebService.FieldNo(Code), DATABASE::"PAC Web Service"));
        TempPACWebService.Insert();
    end;

    local procedure CreateSalesTaxVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        if not VATPostingSetup.Get('', '') then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, '', '');
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Modify(true);
    end;

    local procedure SetupUnrealTaxJurisdiction(var TaxAreaCode: Code[20]; var TaxDetail: Record "Tax Detail"; var TaxJurisdiction: Record "Tax Jurisdiction"; TaxType: Option)
    begin
        TaxAreaCode := CreateTaxAreaLineWithTaxType(TaxDetail, TaxType);
        TaxJurisdiction.Get(TaxDetail."Tax Jurisdiction Code");
        TaxJurisdiction.Validate("Unreal. Tax Acc. (Sales)", LibraryERM.CreateGLAccountNo());
        TaxJurisdiction.Validate("Unreal. Tax Acc. (Purchases)", LibraryERM.CreateGLAccountNo());
        TaxJurisdiction.Validate("Unreal. Rev. Charge (Purch.)", LibraryERM.CreateGLAccountNo());
        TaxJurisdiction.Validate("Unrealized VAT Type", TaxJurisdiction."Unrealized VAT Type"::Percentage);
        TaxJurisdiction.Modify(true);
    end;

    local procedure EnqueueValuesInOrderStatistics(NoOfLines: Option; TaxAmountEditable: Boolean; TaxAmount: Decimal; ChangeTaxAmount: Boolean)
    begin
        LibraryVariableStorage.Enqueue(NoOfLines);
        LibraryVariableStorage.Enqueue(TaxAmountEditable);
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(ChangeTaxAmount);
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
    end;

    local procedure FindSalesOrder(var SalesHeaderOrder: Record "Sales Header"; CustomerNo: Code[20])
    begin
        SalesHeaderOrder.SetRange("Document Type", SalesHeaderOrder."Document Type"::Order);
        SalesHeaderOrder.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeaderOrder.FindFirst();
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; CustomerNo: Code[20])
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Customer No.", CustomerNo);
        ServiceLine.FindFirst();
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure FindGenJournalTemplateAndBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, Type);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure FindPurchLine(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.FindFirst();
    end;

    local procedure FindCustUnapplicationTransactionNo(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.SetRange("Document Type", DocType);
        DtldCustLedgEntry.SetRange("Document No.", DocNo);
        DtldCustLedgEntry.SetRange(Unapplied, true);
        DtldCustLedgEntry.FindLast();
        exit(DtldCustLedgEntry."Transaction No.");
    end;

    local procedure FindVendUnapplicationTransactionNo(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]): Integer
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        DtldVendLedgEntry.SetRange("Document Type", DocType);
        DtldVendLedgEntry.SetRange("Document No.", DocNo);
        DtldVendLedgEntry.SetRange(Unapplied, true);
        DtldVendLedgEntry.FindLast();
        exit(DtldVendLedgEntry."Transaction No.");
    end;

    local procedure GetPaymentDocType(DocumentType: Enum "Gen. Journal Document Type"): Enum "Gen. Journal Document Type"
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        case DocumentType of
            GenJnlLine."Document Type"::Invoice:
                exit(GenJnlLine."Document Type"::Payment);
            GenJnlLine."Document Type"::"Credit Memo":
                exit(GenJnlLine."Document Type"::Refund);
            else
                exit(GenJnlLine."Document Type"::" ");
        end;
    end;

    local procedure GetRandomCode(FieldLength: Integer) RandomCode: Code[20]
    begin
        RandomCode := LibraryUtility.GenerateGUID();
        repeat
            RandomCode += Format(LibraryRandom.RandInt(9));  // Generating any Random integer value.
        until StrLen(RandomCode) = FieldLength;
    end;

    local procedure GetVATEntryAmount(DocumentNo: Code[20]): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.CalcSums(Amount);
        exit(VATEntry.Amount);
    end;

    local procedure GetVATEntryRemainingUnrealAmount(DocumentNo: Code[20]): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        exit(VATEntry."Remaining Unrealized Amount");
    end;

    local procedure ModifyInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", true);
        InventorySetup.Modify(true);
    end;

    local procedure ModifyServiceLine(var ServiceLine: Record "Service Line")
    begin
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Using RANDOM value for Quantity.
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Using RANDOM value for Unit Price.
        ServiceLine.Modify(true);
    end;

    local procedure OpenSalesRetOrdPage(var SalesReturnOrder: TestPage "Sales Return Order"; SalesHeader: Record "Sales Header")
    begin
        SalesReturnOrder.OpenView();
        SalesReturnOrder.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesInvoicePage(var SalesInvoice: TestPage "Sales Invoice"; SalesHeader: Record "Sales Header")
    begin
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesOrderPage(var SalesOrder: TestPage "Sales Order"; SalesHeader: Record "Sales Header")
    begin
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesCrMemoPage(var SalesCreditMemo: TestPage "Sales Credit Memo"; SalesHeader: Record "Sales Header")
    begin
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesQuotePage(var SalesQuote: TestPage "Sales Quote"; SalesHeader: Record "Sales Header")
    begin
        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);
    end;

    local procedure OpenServiceOrderPage(ServiceHeader: Record "Service Header"; var ServiceOrder: TestPage "Service Order")
    begin
        ServiceOrder.OpenView();
        ServiceOrder.GotoRecord(ServiceHeader);
    end;

    local procedure OpenServiceCrMemoPage(ServiceHeader: Record "Service Header"; var ServiceCreditMemo: TestPage "Service Credit Memo")
    begin
        ServiceCreditMemo.OpenView();
        ServiceCreditMemo.GotoRecord(ServiceHeader);
    end;

    local procedure OpenPurchaseOrderPage(var PurchaseOrder: TestPage "Purchase Order"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchaseHeader);
    end;

    local procedure PostGenJournalLineUsingTaxSetup(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; CurrencyCode: Code[10]; Amount: Decimal)
    var
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail);
        FindVATPostingSetup(VATPostingSetup);
        CreateGenJournalLine(
          GenJournalLine, DocumentType, GenJournalLine."Account Type"::"G/L Account",
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group", TaxDetail."Tax Group Code"), Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::Customer);
        GenJournalLine.Validate("Bal. Account No.", CreateCustomer(VATPostingSetup."VAT Bus. Posting Group", TaxAreaCode));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure RunSalesDocumentTestReportWithTwoTaxAreaLines(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; TaxBelowMaximum1: Decimal; TaxBelowMaximum2: Decimal; CountryCode: Option; Qty: Decimal; UnitPrice: Decimal)
    var
        DocumentNo: Code[20];
    begin
        DocumentNo :=
          CreateSalesDocumentWithTwoTaxAreaLines(
            SalesLine, DocumentType, TaxBelowMaximum1, TaxBelowMaximum2, CountryCode, Qty, UnitPrice);

        RunDocumentTestReport(DocumentType, DocumentNo, REPORT::"Sales Document - Test");
        LibraryReportDataset.LoadDataSetFile();
    end;

    local procedure RunPurchaseDocumentTestReportWithTwoTaxAreaLines(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; TaxBelowMaximum1: Decimal; TaxBelowMaximum2: Decimal; CountryCode: Option; Qty: Decimal; DirectUnitCost: Decimal)
    var
        DocumentNo: Code[20];
    begin
        DocumentNo :=
          CreatePurchaseDocumentWithTwoTaxAreaLines(
            PurchaseLine, DocumentType, TaxBelowMaximum1, TaxBelowMaximum2, CountryCode, Qty, DirectUnitCost);

        RunDocumentTestReport(DocumentType, DocumentNo, REPORT::"Purchase Document - Test");
        LibraryReportDataset.LoadDataSetFile();
    end;

    local procedure RunDocumentTestReport(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; ReportType: Integer)
    begin
        Commit(); // Required to run the report.

        LibraryVariableStorage.Enqueue(DocumentType);
        LibraryVariableStorage.Enqueue(DocumentNo);
        REPORT.Run(ReportType);
    end;

    local procedure SetupAndVerifyGenJournalLine(GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; AccountNo: Code[20]; BalAccountNo: Code[20]; CurrencyCode: Code[10]; Type: Enum "Gen. Journal Document Type"; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; GLAmount: Decimal)
    begin
        CreateAndPostGenJournalLineUsingApplication(
          GenJournalLine, DocumentNo, GenJournalLine."Account Type"::Customer,
          AccountNo, BalAccountNo, CurrencyCode, Type, DocumentType, Amount);

        // Verify G/L Entry after applying document using General Journal Line.
        VerifyGLEntryAmount(GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", -GLAmount);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure SetupSalesVATLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // Setup: Create Sales Order with Tax Area Code.
        // Initialize();
        UpdateSetups(true, LibraryRandom.RandIntInRange(10, 100));
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandInt(5));
        SalesHeader.Modify(true);
        OpenSalesOrderPage(SalesOrder, SalesHeader);

        // Exercise: Invoke Sales Order Statistics.
        SalesOrder.Statistics.Invoke();

        // Verify: Each page handler will determine the editability of Tax Amount.
    end;
#endif
    local procedure SetupSalesVATLinesNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // Setup: Create Sales Order with Tax Area Code.
        // Initialize();
        UpdateSetups(true, LibraryRandom.RandIntInRange(10, 100));
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandInt(5));
        SalesHeader.Modify(true);
        OpenSalesOrderPage(SalesOrder, SalesHeader);

        // Exercise: Invoke Sales Order Statistics.
        SalesOrder.SalesOrderStats.Invoke();

        // Verify: Each page handler will determine the editability of Tax Amount.
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure SetupPurchaseVATLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // Setup: Create Purchase Order with Tax Area Code.
        UpdateSetups(true, LibraryRandom.RandIntInRange(10, 100));
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandInt(5));
        PurchaseHeader.Modify(true);
        OpenPurchaseOrderPage(PurchaseOrder, PurchaseHeader);

        // Exercise: Invoke Purchase Order Statistics.
        PurchaseOrder.Statistics.Invoke();

        // Verify: Verify Tax Amount Field is not editable on Sales Tax Lines Subform Dyn page.
    end;
#endif

    local procedure SetupPurchVATLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // Setup: Create Purchase Order with Tax Area Code.
        UpdateSetups(true, LibraryRandom.RandIntInRange(10, 100));
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandInt(5));
        PurchaseHeader.Modify(true);
        OpenPurchaseOrderPage(PurchaseOrder, PurchaseHeader);

        // Exercise: Invoke Purchase Order Statistics.
        PurchaseOrder.PurchaseOrderStats.Invoke();

        // Verify: Verify Tax Amount Field is not editable on Sales Tax Lines Subform Dyn page.
    end;

    local procedure SumTaxAmountInTestReport(): Decimal
    begin
        exit(LibraryReportDataset.Sum('SalesTaxAmountLine__Tax_Amount__Control1020000'));
    end;

    local procedure UpdateGLSetup(PACCode: Code[10]; SimSignature: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        IsolatedCertificate: Record "Isolated Certificate";
    begin
        IsolatedCertificate.Init();
        IsolatedCertificate.Insert(true);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("PAC Code", PACCode);
        GeneralLedgerSetup.Validate("SAT Certificate", IsolatedCertificate.Code);
        GeneralLedgerSetup.Validate("Sim. Signature", SimSignature);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateGLSetupAmountRoundingPrecision(Precision: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Amount Rounding Precision" := Precision;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateSetups(AllowVATDifference: Boolean; MaxVATDifferenceAllowed: Decimal) OldMaxVATDifferenceAllowed: Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // Update General Ledger Setup with Max. VAT Difference Allowed.
        GeneralLedgerSetup.Get();
        OldMaxVATDifferenceAllowed := GeneralLedgerSetup."Max. VAT Difference Allowed";
        GeneralLedgerSetup.Validate("Max. VAT Difference Allowed", MaxVATDifferenceAllowed);
        GeneralLedgerSetup.Modify(true);

        // Update Sales Receivables Setup with Allow VAT Difference as True.
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Allow VAT Difference", AllowVATDifference);
        SalesReceivablesSetup.Modify(true);

        // Update Purchases Payable Setup with Allow VAT Difference and Use Tax Area Code as True.
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Allow VAT Difference", AllowVATDifference);
        PurchasesPayablesSetup.Validate("Use Vendor's Tax Area Code", AllowVATDifference);
        PurchasesPayablesSetup.Modify(true);
        exit(OldMaxVATDifferenceAllowed);
    end;

    local procedure UpdateSalesLineAmount(var SalesLine: Record "Sales Line"; NewQuantity: Decimal; NewPrice: Decimal)
    begin
        SalesLine.Validate(Quantity, NewQuantity);
        SalesLine.Validate("Unit Price", NewPrice);
        SalesLine.Modify(true);
    end;

    local procedure UnapplyCustLedgerEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocType, DocNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure UnapplyVendLedgerEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, DocType, DocNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendLedgEntry);
    end;

    local procedure UpdatePurchaseLineAmount(var PurchaseLine: Record "Purchase Line"; NewQuantity: Decimal; NewPrice: Decimal)
    begin
        PurchaseLine.Validate(Quantity, NewQuantity);
        PurchaseLine.Validate("Direct Unit Cost", NewPrice);
        PurchaseLine.Modify(true);
    end;

    local procedure VerifyPurchaseOrderAfterMakeOrder(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseHeaderOrder: Record "Purchase Header";
    begin
        PurchaseHeaderOrder.SetRange("Document Type", PurchaseHeaderOrder."Document Type"::Order);
        PurchaseHeaderOrder.SetRange("Vendor Invoice No.", PurchaseHeader."Vendor Invoice No.");
        PurchaseHeaderOrder.FindFirst();
        PurchaseHeaderOrder.TestField("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeaderOrder.TestField("Tax Liable", true);
        PurchaseHeaderOrder.TestField("Tax Area Code", PurchaseHeader."Tax Area Code");
        PurchaseHeaderOrder.TestField(Amount, PurchaseHeader.Amount);
    end;

    local procedure VerifySalesOrderAfterMakeOrder(SalesHeader: Record "Sales Header")
    var
        SalesHeaderOrder: Record "Sales Header";
    begin
        FindSalesOrder(SalesHeaderOrder, SalesHeader."Sell-to Customer No.");
        SalesHeaderOrder.TestField("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesHeaderOrder.TestField("Tax Liable", true);
        SalesHeaderOrder.TestField("Tax Area Code", SalesHeader."Tax Area Code");
        SalesHeaderOrder.TestField(Amount, SalesHeader.Amount);
    end;

    local procedure VerifySalesHeaderArchive(SalesHeader: Record "Sales Header")
    var
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.FindFirst();
        SalesHeaderArchive.TestField("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesHeaderArchive.TestField("Tax Area Code", SalesHeader."Tax Area Code");
        SalesHeaderArchive.TestField("Tax Liable", true);
    end;

    local procedure VerifySalesInvoiceLine(SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("Tax Group Code", SalesLine."Tax Group Code");
        SalesInvoiceLine.TestField("Tax Area Code", SalesLine."Tax Area Code");
        SalesInvoiceLine.TestField("Tax Liable", true);
        SalesInvoiceLine.TestField("Line Amount", SalesLine."Line Amount");
    end;

    local procedure VerifySalesLineArchive(SalesLine: Record "Sales Line")
    var
        SalesLineArchive: Record "Sales Line Archive";
    begin
        SalesLineArchive.SetRange("Document No.", SalesLine."Document No.");
        SalesLineArchive.FindFirst();
        SalesLineArchive.TestField("Qty. to Ship", SalesLine."Qty. to Ship");
        SalesLineArchive.TestField(Quantity, SalesLine.Quantity);
        SalesLineArchive.TestField("Qty. to Invoice", SalesLine."Qty. to Invoice");
        SalesLineArchive.TestField("Tax Area Code", SalesLine."Tax Area Code");
        SalesLineArchive.TestField("Tax Liable", true);
    end;

    local procedure VerifyServiceShipment(OrderNo: Code[20]; CustomerNo: Code[20]; TaxAreaCode: Code[20])
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipmentHeader.FindFirst();
        ServiceShipmentHeader.TestField("Customer No.", CustomerNo);
        ServiceShipmentHeader.TestField("Tax Area Code", TaxAreaCode);
        ServiceShipmentHeader.TestField("Tax Liable", true);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; Amount: Decimal; VATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), GLEntry.Amount, GLEntry.TableCaption()));
        Assert.AreNearlyEqual(
          VATAmount, GLEntry."VAT Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption("VAT Amount"), GLEntry."VAT Amount", GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntryDoesNotExist(DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        Assert.RecordIsEmpty(GLEntry);
    end;

    local procedure VerifyGLSetupPACode(PACCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("PAC Code", PACCode);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; Amount: Decimal; VATAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Base), VATEntry.Base, VATEntry.TableCaption()));
        Assert.AreNearlyEqual(
          VATAmount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Amount), VATEntry.Amount, VATEntry.TableCaption()));
    end;

    local procedure VerifyGLEntryAmount(DocumentNo: Code[20]; BalAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Bal. Account No.", BalAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), GLEntry.Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyGSTHSTFieldOnJournalLine(GenJournalBatch: Record "Gen. Journal Batch"; GSTHST: Enum "GST HST Tax Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetRange("GST/HST", GSTHST);
        GenJournalLine.FindFirst();
    end;

    local procedure VerifyGSTHSTFieldOnVATEntry(CustomerNo: Code[20]; GSTHST: Enum "GST HST Tax Type")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", CustomerNo);
        VATEntry.SetRange("GST/HST", GSTHST);
        VATEntry.FindFirst();
    end;

    local procedure VerifyVATGLEntryOnUnapplication(DocNo: Code[20]; TransactionNo: Integer; GLAccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("Transaction No.", TransactionNo);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        Assert.RecordIsNotEmpty(GLEntry);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsticsPageHandler(var SalesOrderStats: TestPage "Sales Order Stats.")
    var
        SalesNoOfLinesStatistics: Variant;
        SalesNoOfLine: Option General,Invoicing,Shipping,Prepayment;
    begin
        LibraryVariableStorage.Dequeue(SalesNoOfLinesStatistics);
        SalesNoOfLine := SalesNoOfLinesStatistics;
        case SalesNoOfLine of
            SalesNoOfLine::General:
                SalesOrderStats.NoOfVATLines_General.DrillDown();
            SalesNoOfLine::Invoicing:
                SalesOrderStats.NoOfVATLines_Invoicing.DrillDown();
            SalesNoOfLine::Shipping:
                SalesOrderStats.NoOfVATLines_Shipping.DrillDown();
            SalesNoOfLine::Prepayment:
                SalesOrderStats.NoOfVATLines_Prepayment.DrillDown();
        end;
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Stats.")
    begin
        LibraryVariableStorage.Enqueue(SalesOrderStatistics."VATAmount[2]".AsDecimal()); // Enqueue value for SalesOrderStatisticsHandler.
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsNonModalPageHandler(var SalesOrderStats: TestPage "Sales Order Stats.")
    var
        SalesNoOfLinesStatistics: Variant;
        SalesNoOfLine: Option General,Invoicing,Shipping,Prepayment;
    begin
        LibraryVariableStorage.Dequeue(SalesNoOfLinesStatistics);
        SalesNoOfLine := SalesNoOfLinesStatistics;
        case SalesNoOfLine of
            SalesNoOfLine::General:
                SalesOrderStats.NoOfVATLines_General.DrillDown();
            SalesNoOfLine::Invoicing:
                SalesOrderStats.NoOfVATLines_Invoicing.DrillDown();
            SalesNoOfLine::Shipping:
                SalesOrderStats.NoOfVATLines_Shipping.DrillDown();
            SalesNoOfLine::Prepayment:
                SalesOrderStats.NoOfVATLines_Prepayment.DrillDown();
        end;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsHandler(var SalesOrderStatistics: TestPage "Sales Order Stats.")
    begin
        LibraryVariableStorage.Enqueue(SalesOrderStatistics."VATAmount[2]".AsDecimal()); // Enqueue value for SalesOrderStatisticsHandler.
    end;
#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsModalPageHandler(var SalesOrderStats: TestPage "Sales Order Stats.")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        SalesOrderStats."VATAmount[2]".AssertEquals(VATAmount);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsNonModalPageHandler(var SalesOrderStats: TestPage "Sales Order Stats.")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        SalesOrderStats."VATAmount[2]".AssertEquals(VATAmount);
    end;
#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsPageHandler(var SalesOrderStats: TestPage "Sales Order Stats.")
    begin
        SalesOrderStats.NoOfVATLines_General.DrillDown();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatsModalPageHandler(var SalesStats: TestPage "Sales Stats.")
    var
        TAXAmount: Variant;
        AmountIncludingTax: Variant;
    begin
        LibraryVariableStorage.Dequeue(TAXAmount);
        LibraryVariableStorage.Dequeue(AmountIncludingTax);
        SalesStats.TaxAmount.AssertEquals(TAXAmount);
        SalesStats.TotalAmount2.AssertEquals(AmountIncludingTax);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesStatsPageHandler(var SalesStats: TestPage "Sales Stats.")
    var
        TAXAmount: Variant;
        AmountIncludingTax: Variant;
    begin
        LibraryVariableStorage.Dequeue(TAXAmount);
        LibraryVariableStorage.Dequeue(AmountIncludingTax);
        SalesStats.TaxAmount.AssertEquals(TAXAmount);
        SalesStats.TotalAmount2.AssertEquals(AmountIncludingTax);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsDrillDownNonModalPageHandler(var SalesOrderStats: TestPage "Sales Order Stats.")
    begin
        SalesOrderStats.NoOfVATLines_General.DrillDown();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsChangePrepaymentPageHandler(var SalesOrderStats: TestPage "Sales Order Stats.")
    begin
        SalesOrderStats.PrepmtTotalAmount.SETVALUE(LibraryVariableStorage.DequeueDecimal());
        SalesOrderStats.OK().Invoke();
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsChangePrepaymentPageHandlerNM(var SalesOrderStats: TestPage "Sales Order Stats.")
    begin
        SalesOrderStats.PrepmtTotalAmount.SETVALUE(LibraryVariableStorage.DequeueDecimal());
        SalesOrderStats.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesTaxLinesSubformDynPageHandler(var SalesTaxLinesSubformDyn: TestPage "Sales Tax Lines Subform Dyn")
    var
        AmountIncludingTax: Variant;
        TaxAmount: Variant;
        TaxBaseAmount: Variant;
        TaxGroupCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        LibraryVariableStorage.Dequeue(TaxGroupCode);
        LibraryVariableStorage.Dequeue(TaxBaseAmount);
        LibraryVariableStorage.Dequeue(AmountIncludingTax);
        SalesTaxLinesSubformDyn."Tax Amount".AssertEquals(TaxAmount);
        SalesTaxLinesSubformDyn."Tax Group Code".AssertEquals(TaxGroupCode);
        SalesTaxLinesSubformDyn."Tax Base Amount".AssertEquals(TaxBaseAmount);
        SalesTaxLinesSubformDyn."Amount Including Tax".AssertEquals(AmountIncludingTax);
    end;

#if not CLEAN27
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderStatsPageHandler(var ServiceOrderStats: TestPage "Service Order Stats.")
    begin
        ServiceOrderStats."TempSalesTaxLine1.COUNT".DrillDown();  // Drilldown to open Service Tax Lines Subform Dyn page.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceCrMemoStatisticsPageHandler(var ServiceStats: TestPage "Service Stats.")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        ServiceStats.VATAmount.AssertEquals(VATAmount);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderStatsPageHandlerNM(var ServiceOrderStats: TestPage "Service Order Stats.")
    begin
        ServiceOrderStats."TempSalesTaxLine1.COUNT".DrillDown();  // Drilldown to open Service Tax Lines Subform Dyn page.
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceCrMemoStatsPageHandlerNM(var ServiceStats: TestPage "Service Stats.")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        ServiceStats.VATAmount.AssertEquals(VATAmount);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatsForGenPageHandler(var PurchaseOrderStats: TestPage "Purchase Order Stats.")
    var
        PurchaseNoOfLinesStatistics: Variant;
        PurchaseNoOfLine: Option General,Invoicing,Shipping,Prepayment;
    begin
        LibraryVariableStorage.Dequeue(PurchaseNoOfLinesStatistics);
        PurchaseNoOfLine := PurchaseNoOfLinesStatistics;
        case PurchaseNoOfLine of
            PurchaseNoOfLine::General:
                PurchaseOrderStats.NoOfVATLines.DrillDown();
            PurchaseNoOfLine::Invoicing:
                PurchaseOrderStats.NoOfVATLines_Invoice.DrillDown();
            PurchaseNoOfLine::Shipping:
                PurchaseOrderStats.NoOfVATLines_Shipping.DrillDown();
            PurchaseNoOfLine::Prepayment:
                PurchaseOrderStats.NoOfVATLines_Prepayment.DrillDown();
        end;
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderStatsForGenPageHandler(var PurchaseOrderStats: TestPage "Purchase Order Stats.")
    var
        PurchaseNoOfLinesStatistics: Variant;
        PurchaseNoOfLine: Option General,Invoicing,Shipping,Prepayment;
    begin
        LibraryVariableStorage.Dequeue(PurchaseNoOfLinesStatistics);
        PurchaseNoOfLine := PurchaseNoOfLinesStatistics;
        case PurchaseNoOfLine of
            PurchaseNoOfLine::General:
                PurchaseOrderStats.NoOfVATLines.DrillDown();
            PurchaseNoOfLine::Invoicing:
                PurchaseOrderStats.NoOfVATLines_Invoice.DrillDown();
            PurchaseNoOfLine::Shipping:
                PurchaseOrderStats.NoOfVATLines_Shipping.DrillDown();
            PurchaseNoOfLine::Prepayment:
                PurchaseOrderStats.NoOfVATLines_Prepayment.DrillDown();
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesTaxLinesPageHandler(var SalesTaxLinesSubformDyn: TestPage "Sales Tax Lines Subform Dyn")
    var
        TaxAmount: Variant;
        TaxAmountEditable: Variant;
        ChangeTaxAmount: Variant;
        TaxAmountAsDec: Decimal;
        ChangeTaxAmountAsBoolean: Boolean;
        TaxAmountEditableAsBoolean: Boolean;
    begin
        LibraryVariableStorage.Dequeue(TaxAmountEditable);
        LibraryVariableStorage.Dequeue(TaxAmount);
        LibraryVariableStorage.Dequeue(ChangeTaxAmount);
        TaxAmountAsDec := TaxAmount;
        ChangeTaxAmountAsBoolean := ChangeTaxAmount;
        TaxAmountEditableAsBoolean := TaxAmountEditable;
        if TaxAmountEditableAsBoolean then begin
            Assert.IsTrue(
              SalesTaxLinesSubformDyn."Tax Amount".Editable(), StrSubstNo(TaxAmountMsg, SalesTaxLinesSubformDyn."Tax Amount".Caption));
            if ChangeTaxAmountAsBoolean then begin
                SalesTaxLinesSubformDyn."Tax Amount".SetValue(SalesTaxLinesSubformDyn."Tax Amount".AsDecimal() - TaxAmountAsDec);
                LibraryVariableStorage.Enqueue(SalesTaxLinesSubformDyn."Tax Amount".Value);
            end
        end else
            SalesTaxLinesSubformDyn."Tax Amount".AssertEquals(TaxAmount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesTaxLinesSubformNotEditableDynModalPageHandler(var SalesTaxLinesSubformDyn: TestPage "Sales Tax Lines Subform Dyn")
    begin
        Assert.IsFalse(
          SalesTaxLinesSubformDyn."Tax Amount".Editable(), StrSubstNo(TaxAmountMsg, SalesTaxLinesSubformDyn."Tax Amount".Caption));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesTaxLinesSubformEditableDynModalPageHandler(var SalesTaxLinesSubformDyn: TestPage "Sales Tax Lines Subform Dyn")
    begin
        Assert.IsTrue(
          SalesTaxLinesSubformDyn."Tax Amount".Editable(), StrSubstNo(TaxAmountMsg, SalesTaxLinesSubformDyn."Tax Amount".Caption));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderPageHandler(var SalesOrder: TestPage "Sales Order")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesDocumentTestRequestPageHandler(var SalesDocumentTest: TestRequestPage "Sales Document - Test")
    var
        DocumentType: Variant;
        No: Variant;
        DocumentType2: Option;
    begin
        LibraryVariableStorage.Dequeue(DocumentType);
        LibraryVariableStorage.Dequeue(No);
        DocumentType2 := DocumentType;
        SalesDocumentTest."Sales Header".SetFilter("Document Type", Format(DocumentType2));
        SalesDocumentTest."Sales Header".SetFilter("No.", No);
        SalesDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseDocumentTestRequestPageHandler(var PurchaseDocumentTest: TestRequestPage "Purchase Document - Test")
    var
        DocumentType: Variant;
        No: Variant;
        DocumentType2: Option;
    begin
        LibraryVariableStorage.Dequeue(DocumentType);
        LibraryVariableStorage.Dequeue(No);
        DocumentType2 := DocumentType;
        PurchaseDocumentTest."Purchase Header".SetFilter("Document Type", Format(DocumentType2));
        PurchaseDocumentTest."Purchase Header".SetFilter("No.", No);
        PurchaseDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue - Enqueue", 'OnBeforeJobQueueScheduleTask', '', true, true)]
    local procedure DisableTaskOnBeforeJobQueueScheduleTask(var JobQueueEntry: Record "Job Queue Entry"; var DoNotScheduleTask: Boolean)
    begin
        DoNotScheduleTask := true;
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}
