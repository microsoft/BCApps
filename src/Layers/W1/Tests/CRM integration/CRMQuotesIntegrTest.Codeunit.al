codeunit 139172 "CRM Quotes Integr.Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM integration]        
    end;

    var
        FieldMustHaveAValueErr: Label '%1 must have a value in %2';
        MissingWriteInProductNoErr: Label '%1 %2 %3 contains a write-in product. You must choose the default write-in product in Sales & Receivables Setup window.', Comment = '%1 - Dataverse service name,%2 - document type (order or quote), %3 - document number';
        SalesQuotenoteNotFoundErr: Label 'Couldn''t find a note for sales quote %1 with note text %2.', Locked = true;
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        SalesHeaderArchiveErr: Label 'The sales quote %1 was nor properly archived';
        EmptyCRMIntegrationRecErr: Label 'The empty CRM integration record for CRM Quote %1 doesn''t exist';
        SalesHeaderNotCreatedErr: Label 'The Sales Header corresponding to the CRM Quote %1 was not created';
        SalesQuoteDeleteErr: Label 'The Sales Header corresponding to the CRM Quote %1 was not deleted succesfully';
        SalesOrderCreateErr: Label 'The Sales Order corresponding to the won processed CRM QUote %1 was not created';

    [Test]
    [Scope('OnPrem')]
    procedure CRMQuoteFCY()
    var
        CRMQuote: Record "CRM Quote";
        SalesHeader: Record "Sales Header";
        FCYCurrencyCode: Code[10];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 144800] CRM Quote in FCY can be created in NAV
        Initialize();
        ClearCRMData();

        // [GIVEN]  CRM Quote in 'X' currency
        FCYCurrencyCode := GetFCYCurrencyCode();
        CreateCRMQuoteWithCurrency(CRMQuote, FCYCurrencyCode);

        // [WHEN] The user clicks 'Create in NAV' CRM Sales Quotes page
        CreateSalesQuoteInNAV(CRMQuote, SalesHeader);

        // [THEN] Sales Quote created, where "Currency Code" is 'X'
        SalesHeader.TestField("Currency Code", FCYCurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMQuoteFCYNotExists()
    var
        CRMQuote: Record "CRM Quote";
        SalesHeader: Record "Sales Header";
        FCYCurrencyCode: Code[10];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 144800] CRM Quote in FCY cannot be created in NAV if Currency not exists
        Initialize();
        ClearCRMData();

        // [GIVEN]  CRM Quote in 'X' currency, Currency not exists in NAV
        FCYCurrencyCode := GetFCYCurrencyCode();
        DeleteCurrencyInNAV(FCYCurrencyCode);
        CreateCRMQuoteWithCurrency(CRMQuote, FCYCurrencyCode);

        // [WHEN] The user clicks 'Create in NAV' CRM Sales Quotes page
        asserterror CreateSalesQuoteInNAV(CRMQuote, SalesHeader);

        // [THEN] Error: Currency 'X' does not exist
        Assert.ExpectedErrorCannotFind(Database::Currency);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMQuoteLCY()
    var
        CRMQuote: Record "CRM Quote";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 144800] CRM Sales Quote in LCY can be created in NAV
        Initialize();
        ClearCRMData();

        // [GIVEN] CRM Quote in local currency
        CreateCRMQuoteInLCY(CRMQuote);

        // [WHEN] The user clicks 'Process Sales Quote' CRM Sales Quotes page
        CreateSalesQuoteInNAV(CRMQuote, SalesHeader);

        // [THEN] Sales Quote created, where "Currency Code" is ''
        SalesHeader.TestField("Currency Code", '');
        // [GIVEN] CRM Sales Quote's "State" is Submitted, "Status" is 'InProgress'
        VerifyCRMQuoteStateAndStatus(
          CRMQuote, CRMQuote.StateCode::Active, CRMQuote.StatusCode::InProgress);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnFreightAccountIsEmpty()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CRMQuote: Record "CRM Quote";
        CRMQuotedetail: Record "CRM Quotedetail";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Freight]
        // [SCENARIO 172256] Error expected when create NAV Sales Quote from CRM Sales Quote with freight amount, if "Sales & Receivables Setup"."G/L Freight Account No." is empty
        Initialize();
        ClearCRMData();

        // [GIVEN] "G/L Freight Account No." is empty in Sales & Receivables Setup
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Freight G/L Acc. No.", '');
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] CRM Quote, where is freight amount 300
        GeneralLedgerSetup.Get();
        CreateCRMQuoteWithCurrency(CRMQuote, GeneralLedgerSetup.GetCurrencyCode(''));
        LibraryCRMIntegration.CreateCRMQuoteLine(CRMQuote, CRMQuotedetail);
        CRMQuote.FreightAmount := LibraryRandom.RandDecInRange(10, 100, 2);
        CRMQuote.Modify();

        // [WHEN] Run 'Create in NAV' CRM Sales Quotes page
        asserterror CreateSalesQuoteInNAV(CRMQuote, SalesHeader);

        // [THEN] Sales Quote created, where is "Order Discount Amount" = 700
        Assert.ExpectedError(
          StrSubstNo(
            FieldMustHaveAValueErr,
            SalesReceivablesSetup.FieldCaption("Freight G/L Acc. No."),
            SalesReceivablesSetup.TableCaption()));
    end;

    [Test] //this
    [Scope('OnPrem')]
    procedure NotDefinedWriteInProductNo()
    var
        CRMProductName: Codeunit "CRM Product Name";
        SalesHeader: Record "Sales Header";
        SalesSetup: Record "Sales & Receivables Setup";
        CRMQuote: Record "CRM Quote";
        CRMQuotedetail: Record "CRM Quotedetail";
    begin
        // [SCENARIO 211596] Creating Sales Quote from CRM Sales Quote when SalesSetup."Write-in Product No." is not defined leads to error
        Initialize();

        // [GIVEN] Write-in Product No. is not defined
        LibraryCRMIntegration.SetSalesSetupWriteInProduct(SalesSetup."Write-in Product Type"::Item, '');

        // [GIVEN] CRM Sales Quote created with line with empty Product Id (sign of write-in product)
        CreateCRMQuoteInLCY(CRMQuote);
        CreateCRMQuotedetailWithEmptyProductId(CRMQuote, CRMQuotedetail);

        // [WHEN] NAV Quote is being created from CRM Quote
        asserterror CreateSalesQuoteInNAV(CRMQuote, SalesHeader);

        // [THEN] Function failed with error "Write-in Product No. must have a value in Sales & Receivables Setup"
        Assert.ExpectedError(
          StrSubstNo(
            MissingWriteInProductNoErr,
            CRMProductName.CDSServiceName(),
            'Quote',
            SalesHeader."Your Reference"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WriteInProductItem()
    var
        CRMQuote: Record "CRM Quote";
        CRMQuotedetail: Record "CRM Quotedetail";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // [SCENARIO 211596] Create Sales Quote from CRM Sales Quote with write-in product defined as item
        Initialize();

        // [GIVEN] Setup write-in product as Item 'ITEM'
        LibraryCRMIntegration.PrepareWriteInProductItem(Item);

        // [GIVEN] CRM Sales Quote created with line with empty Product Id (sign of write-in product)
        CreateCRMQuoteInLCY(CRMQuote);
        CreateCRMQuotedetailWithEmptyProductId(CRMQuote, CRMQuotedetail);

        // [WHEN] NAV Quote is being created from CRM Quote
        CreateSalesQuoteInNAV(CRMQuote, SalesHeader);

        // [THEN] Created NAV Sales Quote contains line with item 'ITEM'
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
        SalesLine.TestField("No.", Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WriteInProductResource()
    var
        CRMQuote: Record "CRM Quote";
        CRMQuotedetail: Record "CRM Quotedetail";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Resource: Record Resource;
    begin
        // [SCENARIO 211596] Create Sales Quote from CRM Sales Quote with write-in product defined as resource
        Initialize();

        // [GIVEN] Setup write-in product as Resource 'RES'
        LibraryCRMIntegration.PrepareWriteInProductResource(Resource);

        // [GIVEN] CRM Sales Quote created with line with empty Product Id (sign of write-in product)
        CreateCRMQuoteInLCY(CRMQuote);
        CreateCRMQuotedetailWithEmptyProductId(CRMQuote, CRMQuotedetail);

        // [WHEN] NAV Quote is being created from CRM Quote
        CreateSalesQuoteInNAV(CRMQuote, SalesHeader);

        // [THEN] Created NAV Sales Quote contains line with resource 'RES'
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange(Type, SalesLine.Type::Resource);
        SalesLine.FindFirst();
        SalesLine.TestField("No.", Resource."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LongProductDescriptionItem()
    var
        CRMQuote: Record "CRM Quote";
        CRMQuotedetail: Record "CRM Quotedetail";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 211535] Long CRM Product (item) description causes creating additional sales lines with Description field containing trancated product description part
        Initialize();

        // [GIVEN] CRM Quote in local currency with item
        CreateCRMQuoteInLCY(CRMQuote);
        LibraryCRMIntegration.CreateCRMQuoteLine(CRMQuote, CRMQuotedetail);

        // [GIVEN] Mock 250 symbols length CRMQuotedetail.ProductDescription
        MockLongCRMQuotedetailProductDescription(CRMQuotedetail);

        // [WHEN] NAV Quote is being created from CRM Quote
        CreateSalesQuoteInNAV(CRMQuote, SalesHeader);

        // [THEN] Created NAV Sales Quote contains 5 lines, long description split by 5 pieces for 50 symbols
        VerifySalesLinesDescription(SalesHeader, CRMQuotedetail.ProductDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LongProductDescriptionResource()
    var
        CRMQuote: Record "CRM Quote";
        CRMQuotedetail: Record "CRM Quotedetail";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 211535] Long CRM Product (resource) description causes creating additional sales lines with Description field containing trancated product description part
        Initialize();
        ClearCRMData();

        // [GIVEN] CRM Quote in local currency with resource
        CreateCRMQuoteInLCY(CRMQuote);
        LibraryCRMIntegration.CreateCRMQuoteLineWithResource(CRMQuote, CRMQuotedetail);

        // [GIVEN] Mock 250 symbols length CRMQuotedetail.ProductDescription
        MockLongCRMQuotedetailProductDescription(CRMQuotedetail);

        // [WHEN] NAV Quote is being created from CRM Quote
        CreateSalesQuoteInNAV(CRMQuote, SalesHeader);

        // [THEN] Created NAV Sales Quote contains 5 lines, long description split by 5 pieces for 50 symbols
        VerifySalesLinesDescription(SalesHeader, CRMQuotedetail.ProductDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LongWriteInProductDescription()
    var
        CRMQuote: Record "CRM Quote";
        CRMQuotedetail: Record "CRM Quotedetail";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        // [SCENARIO 211535] Long write-in product description causes creating additional sales lines with Description field containing trancated product description part
        Initialize();

        // [GIVEN] Setup write-in product as Item 'ITEM'
        LibraryCRMIntegration.PrepareWriteInProductItem(Item);

        // [GIVEN] CRM Sales Quote created with line with empty Product Id (sign of write-in product)
        CreateCRMQuoteInLCY(CRMQuote);
        CreateCRMQuotedetailWithEmptyProductId(CRMQuote, CRMQuotedetail);

        // [GIVEN] Mock 250 symbols length CRMQuotedetail.ProductDescription
        MockLongCRMQuotedetailProductDescription(CRMQuotedetail);

        // [WHEN] NAV Quote is being created from CRM Quote
        CreateSalesQuoteInNAV(CRMQuote, SalesHeader);

        // [THEN] Created NAV Sales Quote contains 5 lines, long description split by 5 pieces for 50 symbols
        VerifySalesLinesWriteInDescription(SalesHeader, CRMQuotedetail.ProductDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineItemDescriptionUsedInsteadOfProductDescription()
    var
        CRMQuote: Record "CRM Quote";
        CRMQuotedetail: Record "CRM Quotedetail";
        SalesHeader: Record "Sales Header";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        Description: Text;
    begin
        // CRM Sales Quote Line Description (and not CRM Product Description) is used as Business Central Sales Quote line description
        Initialize();

        // [GIVEN] CRM Quote in local currency with item
        CreateCRMQuoteInLCY(CRMQuote);
        LibraryCRMIntegration.CreateCRMQuoteLine(CRMQuote, CRMQuotedetail);

        // [GIVEN] Mock 250 symbols length CRMQuotedetail.ProductDescription
        MockLongCRMQuotedetailProductDescription(CRMQuotedetail);

        // [GIVEN] Mock long CRMQuotedetail.Description
        MockLongCRMQuotedetailDescription(CRMQuotedetail);

        // [WHEN] NAV Quote is being created from CRM Quote
        CreateSalesQuoteInNAV(CRMQuote, SalesHeader);

        // [THEN] Created NAV Sales Quote is using CRMQuotedetail.Description as Description

        TempBlob.FromRecord(CRMQuotedetail, CRMQuotedetail.FieldNo(Description));
        TempBlob.CreateInStream(InStream, TextEncoding::UTF16);
        InStream.Read(Description);
        VerifySalesLinesDescription(SalesHeader, Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMQuoteNoteToSalesQuoteNote()
    var
        CRMQuote: Record "CRM Quote";
        CRMAnnotation: Record "CRM Annotation";
        CRMQuotedetail: Record "CRM Quotedetail";
        SalesHeader: Record "Sales Header";
        AnnotationText: Text;
    begin
        // CRM Sales Quote note is used as Business Central Sales Quote note
        Initialize();

        // [GIVEN] CRM Quote in local currency with item
        CreateCRMQuoteInLCY(CRMQuote);
        LibraryCRMIntegration.CreateCRMQuoteLine(CRMQuote, CRMQuotedetail);

        // [GIVEN] A CRM note bound to the Sales Quote
        AnnotationText := LibraryRandom.RandText(25);
        MockCRMQuoteNote(CRMAnnotation, CRMQuote, AnnotationText);

        // [WHEN] NAV Quote is being created from CRM Quote
        CreateSalesQuoteInNAV(CRMQuote, SalesHeader);

        // [THEN] Created NAV Sales Quote has a note with the mocked note text
        VerifySalesQuoteNote(SalesHeader, AnnotationText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesQuoteInNAVWithJobQueueSunshine()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMQuote: Record "CRM Quote";
        CRMQuotedetail: Record "CRM Quotedetail";
    begin
        // [SCENARIO 211593] Job queue entry "Process submitted Sales Quotes" makes NAV Sales Quote from Submitted CRM Sales Quote
        Initialize();
        ClearCRMData();

        // [GIVEN] CRM Quote in local currency with item
        CreateCRMQuoteInLCY(CRMQuote);
        LibraryCRMIntegration.CreateCRMQuoteLine(CRMQuote, CRMQuotedetail);

        // [WHEN] Job queue entry "Process submitted Sales Quotes" is being run
        RunCodeunitProcessActivatedCRMQuotes();

        // [THEN] Nav Sales Quote created
        Assert.IsTrue(CRMIntegrationRecord.FindByCRMID(CRMQuote.QuoteId), 'Coupled sales header not found');
        Assert.AreEqual(CRMIntegrationRecord."Table ID", DATABASE::"Sales Header", StrSubstNo(SalesHeaderNotCreatedErr, CRMQuote.QuoteId));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesQuoteInNAVWithJobQueueAfterFail()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMQuote: array[2] of Record "CRM Quote";
        CRMQuotedetail: array[2] of Record "CRM Quotedetail";
    begin
        // [SCENARIO 211593] Job queue entry "Process submitted Sales Quotes" should not stop processing quotes after first fail
        Initialize();
        ClearCRMData();

        // [GIVEN] CRM Quote 1 for customer 1 in local currency with item
        CreateCRMQuoteInLCY(CRMQuote[1]);
        LibraryCRMIntegration.CreateCRMQuoteLine(CRMQuote[1], CRMQuotedetail[1]);

        // [GIVEN] Remove coupling for customer 1 to cause error while creating NAV Sales Quote
        CRMIntegrationRecord.FindByCRMID(CRMQuote[1].CustomerId);
        CRMIntegrationRecord.Delete();

        // [GIVEN] CRM Quote 2 for customer 2 in local currency with item
        CreateCRMQuoteInLCY(CRMQuote[2]);
        LibraryCRMIntegration.CreateCRMQuoteLine(CRMQuote[2], CRMQuotedetail[2]);

        // [WHEN] Job queue entry "Process submitted Sales Quotes" is being run
        RunCodeunitProcessActivatedCRMQuotes();

        // [THEN] Nav Sales Quote 1 is not created
        Assert.IsFalse(CRMIntegrationRecord.FindByCRMID(CRMQuote[1].QuoteId), 'Sales Quote 1 should not be created');

        // [THEN] Nav Sales Quote 2 created
        Assert.IsTrue(CRMIntegrationRecord.FindByCRMID(CRMQuote[2].QuoteId), 'Sales Quote 2 not found');
        CRMIntegrationRecord.TestField("Table ID", DATABASE::"Sales Header");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMQuoteNameToSalesHeaderExternalDocumentNo()
    var
        SalesHeader: Record "Sales Header";
        CRMQuote: Record "CRM Quote";
        CRMQuotedetail: Record "CRM Quotedetail";
    begin
        // [FEATURE] [External Document No.]
        // [SCENARIO 230310] CRM Sales Quote Name field value is copied to Sales Header External Document No field
        Initialize();

        // [GIVEN] CRM Quote in local currency with item
        CreateCRMQuoteInLCY(CRMQuote);
        LibraryCRMIntegration.CreateCRMQuoteLine(CRMQuote, CRMQuotedetail);

        // [GIVEN] CRM Quote Name = "ABC"
        CRMQuote.Name :=
          UpperCase(LibraryUtility.GenerateRandomText(MaxStrLen(CRMQuote.Name)));
        CRMQuote.Modify();

        // [WHEN] NAV Quote is being created from CRM Quote
        CreateSalesQuoteInNAV(CRMQuote, SalesHeader);

        // [THEN] Created sales header has External Document No. = "ABC"
        SalesHeader.TestField(
          "External Document No.",
          CopyStr(CRMQuote.Name, 1, MaxStrLen(SalesHeader."External Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMExistingQuoteWon()
    var
        CRMQuote: Record "CRM Quote";
        SalesHeader: Record "Sales Header";
        CRMQuotedetail: Record "CRM Quotedetail";
        ProcessedSalesHeader: Record "Sales Header";
        CRMIntegrationRecord: Record "CRM Integration Record";
        BlankGUID: Guid;
    begin
        // [SCENARIO] When releasing a CRM quote that gets created in Business Central, when the CRM Quote is "Won", the Sales Quote is deleted, a sales quote archieve is created
        Initialize();
        ClearCRMData();
        ClearSalesTables();

        // [GIVEN] Create CRM Quote in local currency and a CRM Quotedetail
        CreateCRMQuoteInLCY(CRMQuote);
        LibraryCRMIntegration.CreateCRMQuoteLine(CRMQuote, CRMQuotedetail);

        // [WHEN] The user clicks 'Process Sales Quote' on the CRM Sales Quotes page on the initial CRM Quote
        CreateSalesQuoteInNAV(CRMQuote, SalesHeader);
        Commit();

        // [GIVEN] The sales quote's status becomes "Won"
        WinCRMQuote(CRMQuote);

        // [WHEN] The user clicks 'Process Sales Quote' CRM Sales Quotes page on the revisioned CRM Quote
        CreateSalesQuoteInNAV(CRMQuote, ProcessedSalesHeader);
        Commit();

        // [THEN] The won CRM quote is a corresponding to an empty Sales Quote
        Assert.IsTrue(CRMIntegrationRecord.Get(CRMQuote.QuoteId, BlankGUID), StrSubstNo(EmptyCRMIntegrationRecErr, CRMQuote.QuoteId));

        // [THEN] A BC Sales Order has been created for the processed won quote
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", ProcessedSalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Your Reference", CRMQuote.QuoteNumber);
        Assert.IsTrue(SalesHeader.FindFirst(), StrSubstNo(SalesOrderCreateErr, CRMQuote.QuoteId));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMNewQuoteWon()
    var
        CRMQuote: Record "CRM Quote";
        SalesHeader: Record "Sales Header";
        CRMQuotedetail: Record "CRM Quotedetail";
        ProcessedSalesHeader: Record "Sales Header";
        CRMIntegrationRecord: Record "CRM Integration Record";
        BlankGUID: Guid;
    begin
        // [SCENARIO] When releasing a CRM quote and the CRM Quote is "Won" before the Sales Quote has been created, a sales quote archieve is created
        Initialize();
        ClearCRMData();
        ClearSalesTables();

        // [GIVEN] Create CRM Quote in local currency and a CRM Quotedetail
        CreateCRMQuoteInLCY(CRMQuote);
        LibraryCRMIntegration.CreateCRMQuoteLine(CRMQuote, CRMQuotedetail);

        // [GIVEN] The sales quote's status becomes "Won"
        WinCRMQuote(CRMQuote);

        // [WHEN] The user clicks 'Process Sales Quote' on the CRM Sales Quotes page on the won CRM Quote
        CreateSalesQuoteInNAV(CRMQuote, ProcessedSalesHeader);

        // [THEN] The won CRM quote is a corresponding to an empty Sales Quote
        Assert.IsTrue(CRMIntegrationRecord.Get(CRMQuote.QuoteId, BlankGUID), StrSubstNo(EmptyCRMIntegrationRecErr, CRMQuote.QuoteId));

        // [THEN] A BC Sales Order has been created for the processed won quote
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Your Reference", CRMQuote.QuoteNumber);
        Assert.IsTrue(SalesHeader.FindFirst(), StrSubstNo(SalesOrderCreateErr, CRMQuote.QuoteId));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMExistingQuoteWonMultipleJobs()
    var
        CRMQuote: Record "CRM Quote";
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        CRMQuotedetail: Record "CRM Quotedetail";
        ProcessedSalesHeader: Record "Sales Header";
        CRMIntegrationRecord: Record "CRM Integration Record";
        BlankGUID: Guid;
    begin
        // [SCENARIO] When releasing a CRM quote that gets created in Business Central, when the CRM Quote is "Won", the Sales Quote is deleted, a sales quote archieve is created
        Initialize();
        ClearCRMData();
        ClearSalesTables();

        // [GIVEN] Create CRM Quote in local currency and a CRM Quotedetail
        CreateCRMQuoteInLCY(CRMQuote);
        LibraryCRMIntegration.CreateCRMQuoteLine(CRMQuote, CRMQuotedetail);

        // [WHEN] The user clicks 'Process Sales Quote' on the CRM Sales Quotes page on the initial CRM Quote
        CreateSalesQuoteInNAV(CRMQuote, SalesHeader);
        Commit();

        // [GIVEN] The sales quote's status becomes "Won"
        WinCRMQuote(CRMQuote);

        // [WHEN] The user clicks 'Process Sales Quote' on the CRM Sales Quotes page on the won CRM Quote
        CreateSalesQuoteInNAV(CRMQuote, ProcessedSalesHeader);
        // [WHEN] The user clicks again 'Process Sales Quote' on the CRM Sales Quotes page on the won CRM Quote
        CreateSalesQuoteInNAV(CRMQuote, ProcessedSalesHeader);

        // [THEN] The sales quote and sales qoutes lines are deleted from the Sales Quotes
        Assert.AreEqual(SalesHeader."Document Type"::Quote, SalesHeader."Document Type", StrSubstNo(SalesQuoteDeleteErr, CRMQuote.QuoteId));

        // [THEN] The initial sales quote is being archieved
        Assert.IsTrue(SalesHeaderArchive.Get(SalesHeaderArchive."Document Type"::Quote, SalesHeader."No.", 1, 1),
          StrSubstNo(SalesHeaderArchiveErr, CRMQuote.QuoteId));

        // [THEN] The won CRM quote is a corresponding to an empty Sales Quote
        Assert.IsTrue(CRMIntegrationRecord.Get(CRMQuote.QuoteId, BlankGUID), StrSubstNo(EmptyCRMIntegrationRecErr, CRMQuote.QuoteId));

        // [THEN] A BC Sales Order has been created for the processed won quote
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Your Reference", CRMQuote.QuoteNumber);
        Assert.IsTrue(SalesHeader.FindFirst(), StrSubstNo(SalesOrderCreateErr, CRMQuote.QuoteId));
    end;

    local procedure Initialize()
    var
        MyNotifications: Record "My Notifications";
        CRMConnectionSetup: Record "CRM Connection Setup";
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        // Lazy Setup.
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;

        LibraryPatterns.SetNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        CRMConnectionSetup.Get();
        CRMConnectionSetup."Is S.Order Integration Enabled" := true;
        CRMConnectionSetup."Is Enabled" := true;
        CRMConnectionSetup."Unit Group Mapping Enabled" := false;
        CRMConnectionSetup.Modify();
        isInitialized := true;
        MyNotifications.InsertDefault(UpdateCurrencyExchangeRates.GetMissingExchangeRatesNotificationID(), '', '', false);
        Commit();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
    end;

    local procedure ClearCRMData()
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMAccount: Record "CRM Account";
        CRMQuote: Record "CRM Quote";
    begin
        CRMAccount.DeleteAll();
        CRMTransactioncurrency.DeleteAll();
        CRMQuote.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure ClearSalesTables()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.DeleteAll();
        SalesHeaderArchive.DeleteAll();
        SalesLine.DeleteAll();
        SalesHeaderArchive.DeleteAll();
    end;

    local procedure CreateCRMQuoteWithCurrency(var CRMQuote: Record "CRM Quote"; CurrencyCode: Code[10])
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        LibraryCRMIntegration.CreateCRMTransactionCurrency(CRMTransactioncurrency, CopyStr(CurrencyCode, 1, 5));
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CreateCRMQuote(CRMQuote, CRMTransactioncurrency.TransactionCurrencyId, CRMAccount.AccountId);
    end;

    local procedure CreateCRMQuote(var CRMQuote: Record "CRM Quote"; CurrencyId: Guid; AccountId: Guid)
    begin
        LibraryCRMIntegration.CreateCRMQuoteWithCustomerFCY(CRMQuote, AccountId, CurrencyId);
    end;

    local procedure CreateCRMQuoteInLCY(var CRMQuote: Record "CRM Quote")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        CreateCRMQuoteWithCurrency(CRMQuote, GeneralLedgerSetup.GetCurrencyCode(''));
    end;

    local procedure CreateCRMQuotedetailWithEmptyProductId(CRMQuote: Record "CRM Quote"; var CRMQuotedetail: Record "CRM Quotedetail")
    begin
        CRMQuotedetail.Init();
        LibraryCRMIntegration.PrepareCRMQuoteLine(CRMQuote, CRMQuotedetail, CRMQuotedetail.ProductId);
    end;

    local procedure MockLongCRMQuotedetailProductDescription(var CRMQuotedetail: Record "CRM Quotedetail")
    begin
        CRMQuotedetail.ProductDescription :=
          CopyStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(CRMQuotedetail.ProductDescription)),
            1,
            MaxStrLen(CRMQuotedetail.ProductDescription));
        CRMQuotedetail.Modify();
    end;

    local procedure MockLongCRMQuotedetailDescription(var CRMQuotedetail: Record "CRM Quotedetail")
    var
        OutStream: OutStream;
    begin
        CRMQuotedetail.Description.CreateOutStream(OutStream);
        OutStream.Write(LibraryUtility.GenerateRandomText(LibraryRandom.RandIntInRange(150, 3000)));
        CRMQuotedetail.Modify();
    end;

    local procedure MockCRMQuoteNote(var CRMAnnotation: Record "CRM Annotation"; CRMQuote: Record "CRM Quote"; AnnotationText: Text)
    var
        OutStream: OutStream;
    begin
        CRMAnnotation.AnnotationId := CreateGuid();
        CRMAnnotation.IsDocument := false;
        CRMAnnotation.ObjectId := CRMQuote.QuoteId;
        CRMAnnotation.NoteText.CreateOutStream(OutStream, TEXTENCODING::UTF16);
        OutStream.Write(AnnotationText);
        CRMAnnotation.Insert();
    end;

    local procedure RunCodeunitProcessActivatedCRMQuotes()
    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
    begin
        CODEUNIT.Run(CODEUNIT::"Auto Process Sales Quotes", TempJobQueueEntry);
    end;

    local procedure CreateSalesQuoteInNAV(CRMQuote: Record "CRM Quote"; var SalesHeader: Record "Sales Header")
    var
        CRMQuoteToSalesQuote: Codeunit "CRM Quote to Sales Quote";
    begin
        CRMQuoteToSalesQuote.ProcessInNAV(CRMQuote, SalesHeader);
    end;

    local procedure DeleteCurrencyInNAV(CurrencyISOCode: Text)
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyISOCode);
        Currency.Delete(true);
    end;

    local procedure GetFCYCurrencyCode(): Code[10]
    var
        Currency: Record Currency;
        "Code": Code[10];
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandIntInRange(10, 20), 1));
        Code := LibraryUtility.GenerateGUID();
        Currency.Rename('.' + CopyStr(Code, StrLen(Code) - 3));
        exit(Currency.Code);
    end;

    local procedure VerifyCRMQuoteStateAndStatus(var CRMQuote: Record "CRM Quote"; ExpectedState: Integer; ExpectedStatus: Integer)
    begin
        CRMQuote.Find();
        CRMQuote.TestField(StateCode, ExpectedState);
        CRMQuote.TestField(StatusCode, ExpectedStatus);
    end;

    local procedure VerifySalesLinesDescription(SalesHeader: Record "Sales Header"; ProductDescription: Text)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindSet();
        repeat
            SalesLine.Next();
            VerifySalesLineDescriptionAndTrancateProdDescription(SalesLine, ProductDescription);
        until StrLen(ProductDescription) = 0;
    end;

    local procedure VerifySalesLinesWriteInDescription(SalesHeader: Record "Sales Header"; ProductDescription: Text)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindSet();
        VerifySalesLineDescriptionAndTrancateProdDescription(SalesLine, ProductDescription);
        repeat
            SalesLine.Next();
            VerifySalesLineDescriptionAndTrancateProdDescription(SalesLine, ProductDescription);
        until StrLen(ProductDescription) = 0;
    end;

    local procedure VerifySalesLineDescriptionAndTrancateProdDescription(SalesLine: Record "Sales Line"; var ProductDescription: Text)
    begin
        Assert.AreEqual(
          CopyStr(ProductDescription, 1, MaxStrLen(SalesLine.Description)),
          SalesLine.Description,
          'Invalid description');
        ProductDescription := CopyStr(ProductDescription, MaxStrLen(SalesLine.Description) + 1);
    end;

    local procedure VerifySalesQuoteNote(SalesHeader: Record "Sales Header"; AnnotationText: Text)
    var
        RecordLink: Record "Record Link";
        RecordLinkManagement: Codeunit "Record Link Management";
        ActualText: Text;
    begin
        RecordLink.SetAutoCalcFields(Note);
        RecordLink.SetRange("Record ID", SalesHeader.RecordId);
        RecordLink.FindSet();
        repeat
            ActualText := RecordLinkManagement.ReadNote(RecordLink);
            if ActualText = AnnotationText then
                exit;
        until RecordLink.Next() = 0;
        Error(SalesQuotenoteNotFoundErr, SalesHeader."No.", AnnotationText);
    end;

    [Scope('OnPrem')]
    procedure WinCRMQuote(var CRMQuote: Record "CRM Quote")
    var
        CRMSalesOrder: Record "CRM Salesorder";
    begin
        CRMQuote.Validate(StateCode, CRMQuote.StateCode::Won);
        CRMQuote.Validate(StatusCode, CRMQuote.StatusCode::Won);
        CRMQuote.Modify(true);
        LibraryCRMIntegration.CreateCRMSalesOrder(CRMSalesOrder);
        CRMSalesOrder.OrderNumber := CRMQuote.QuoteNumber;
        CRMSalesOrder.AccountId := CRMQuote.AccountId;
        CRMSalesOrder.CustomerId := CRMQuote.CustomerId;
        CRMSalesOrder.CustomerIdType := CRMQuote.CustomerIdType;
        CRMSalesOrder.TransactionCurrencyId := CRMQuote.TransactionCurrencyId;
        CRMSalesOrder.QuoteId := CRMQuote.QuoteId;
        CRMSalesOrder.StateCode := CRMSalesOrder.StateCode::Submitted;
        CRMSalesOrder.Modify(true);
    end;
}

