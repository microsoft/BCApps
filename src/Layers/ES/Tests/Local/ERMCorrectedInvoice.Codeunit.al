codeunit 144073 "ERM Corrected Invoice"
{
    // // [FEATURE] [UT]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        CorrInvDoesNotExistErr: Label 'The Corrected Invoice No. does not exist';
        IncorrectAccOrBalAccTypeErr: Label 'Account Type or Bal. Account Type must be a Customer or Vendor.';
        CorrectiveInvoiceTxt: Label 'Corrective Invoice %1';

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoCorrectedInvExists()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales] [Document]
        // [SCENARIO 261095] Stan can specify the existing value of Sales Invoice in field "Corrected Invoice No." of Sales Credit Memo

        CustNo := LibrarySales.CreateCustomerNo();
        DocNo := MockSalesInvoice(CustNo);

        SalesHeader.Init();
        SalesHeader.Validate("Bill-to Customer No.", CustNo);
        SalesHeader.Validate("Corrected Invoice No.", DocNo);
        SalesHeader.TestField("Corrected Invoice No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoCorrectedInvDoesNotExist()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
    begin
        // [FEATURE] [Sales] [Document]
        // [SCENARIO 261095] Stan cannot specify the not existed value of Sales Invoice in field "Corrected Invoice No." of Sales Credit Memo

        CustNo := LibrarySales.CreateCustomerNo();

        SalesHeader.Init();
        SalesHeader.Validate("Bill-to Customer No.", CustNo);
        asserterror SalesHeader.Validate("Corrected Invoice No.", LibraryUtility.GenerateGUID());
        Assert.ExpectedError(CorrInvDoesNotExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoCorrectedInvExists()
    var
        PurchHeader: Record "Purchase Header";
        VendNo: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Document]
        // [SCENARIO 261095] Stan can specify the existing value of Purchase Invoice in field "Corrected Invoice No." of Purchase Credit Memo

        VendNo := LibraryPurchase.CreateVendorNo();
        DocNo := MockPurchInvoice(VendNo);

        PurchHeader.Init();
        PurchHeader.Validate("Pay-to Vendor No.", VendNo);
        PurchHeader.Validate("Corrected Invoice No.", DocNo);
        PurchHeader.TestField("Corrected Invoice No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoCorrectedInvDoesNotExist()
    var
        PurchHeader: Record "Purchase Header";
        VendNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Document]
        // [SCENARIO 261095] Stan can specify the not existed value of Purchase Invoice in field "Corrected Invoice No." of Purchase Credit Memo

        VendNo := LibraryPurchase.CreateVendorNo();

        PurchHeader.Init();
        PurchHeader.Validate("Pay-to Vendor No.", VendNo);
        asserterror PurchHeader.Validate("Corrected Invoice No.", LibraryUtility.GenerateGUID());
        Assert.ExpectedError(CorrInvDoesNotExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToSpecifyCorrTypeInJournalWithInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Journal]
        // [SCENARIO 261095] Stan cannot specify "Correction Type" in General Journal Line with "Document Type" = Invoice

        GenJournalLine.Init();
        asserterror GenJournalLine.Validate("Correction Type", GenJournalLine."Correction Type"::Difference);
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Document Type"), Format(GenJournalLine."Document Type"::"Credit Memo"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToSpecifyCorrInvNoInJournalWithInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Journal]
        // [SCENARIO 261095] Stan cannot specify "Corrected Invoice No." in General Journal Line with "Document Type" = Invoice

        GenJournalLine.Init();
        asserterror GenJournalLine.Validate("Corrected Invoice No.", LibraryUtility.GenerateGUID());
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Document Type"), Format(GenJournalLine."Document Type"::"Credit Memo"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToSpecifyCorrTypeInJournalWithGLAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Journal]
        // [SCENARIO 261095] Stan cannot specify "Correction Type" in General Journal Line with "G/L Account" for either "Account Type" or "Bal. Account Type"

        GenJournalLine.Init();
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::"Credit Memo");
        asserterror GenJournalLine.Validate("Correction Type", GenJournalLine."Correction Type"::Difference);
        Assert.ExpectedError(IncorrectAccOrBalAccTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToSpecifyCorrInvNoInJournalWithGLAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Journal]
        // [SCENARIO 261095] Stan cannot specify "Corrected Invoice No." in General Journal Line with "G/L Account" for either "Account Type" or "Bal. Account Type"

        GenJournalLine.Init();
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::"Credit Memo");
        asserterror GenJournalLine.Validate("Corrected Invoice No.", LibraryUtility.GenerateGUID());
        Assert.ExpectedError(IncorrectAccOrBalAccTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineWithSalesCrMemoCorrectedInvExists()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustNo: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales] [Journal]
        // [SCENARIO 261095] Stan can specify the existing value of Sales Invoice in field "Corrected Invoice No." of General Journal Line

        CustNo := LibrarySales.CreateCustomerNo();
        DocNo := MockSalesInvoice(CustNo);

        GenJournalLine.Init();
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::"Credit Memo");
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.Validate("Account No.", CustNo);
        GenJournalLine.Validate("Corrected Invoice No.", DocNo);
        GenJournalLine.TestField("Corrected Invoice No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineWithSalesCrMemoCorrectedInvDoesNotExist()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustNo: Code[20];
    begin
        // [FEATURE] [Sales] [Journal]
        // [SCENARIO 261095] Stan cannot specify the not existed value of Sales Invoice in field "Corrected Invoice No." of General Journal Line

        CustNo := LibrarySales.CreateCustomerNo();

        GenJournalLine.Init();
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::"Credit Memo");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.Validate("Bal. Account No.", CustNo);
        asserterror GenJournalLine.Validate("Corrected Invoice No.", LibraryUtility.GenerateGUID());
        Assert.ExpectedError(CorrInvDoesNotExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineWithPurchCrMemoCorrectedInvExists()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendNo: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Journal]
        // [SCENARIO 261095] Stan can specify the existing value of Purchase Invoice in field "Corrected Invoice No." of General Journal Line

        VendNo := LibraryPurchase.CreateVendorNo();
        DocNo := MockPurchInvoice(VendNo);

        GenJournalLine.Init();
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::"Credit Memo");
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.Validate("Account No.", VendNo);
        GenJournalLine.Validate("Corrected Invoice No.", DocNo);
        GenJournalLine.TestField("Corrected Invoice No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineWithPurchCrMemoCorrectedInvDoesNotExist()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Journal]
        // [SCENARIO 261095] Stan cannot specify the not existed value of Purchase Invoice in field "Corrected Invoice No." of General Journal Line

        VendNo := LibraryPurchase.CreateVendorNo();

        GenJournalLine.Init();
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::"Credit Memo");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.Validate("Bal. Account No.", VendNo);
        asserterror GenJournalLine.Validate("Corrected Invoice No.", LibraryUtility.GenerateGUID());
        Assert.ExpectedError(CorrInvDoesNotExistErr);
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoicesModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoCorrectedDocNoLookUpOK()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        CustNo: Code[20];
        ExpectedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo] [LookUP] [Corrected Invoice No]
        // [SCENARIO 267532] When Stan looks up "Corrected Invoice No." on Sales Credit Memo page and then selects Invoice on Posted Sales Invoices page and confirms his choice
        // [SCENARIO 267532] then "Corrected Invoice No." = Posted Sales Invoice "No."

        // [GIVEN] Posted Sales Invoice "I"
        CustNo := LibrarySales.CreateCustomerNo();
        ExpectedInvoiceNo := MockSalesInvoice(CustNo);
        LibraryVariableStorage.Enqueue(ExpectedInvoiceNo);

        // [GIVEN] Stan opened Sales Credit Memo page and looked up "Corrected Invoice No."
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustNo);
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo."Corrected Invoice No.".Lookup();

        // [WHEN] Stan selects Invoice "I" on page Posted Sales Invoices and pushes OK

        // [THEN] Sales Credit Memo has "Corrected Invoice No." = "I"
        SalesCreditMemo."Corrected Invoice No.".AssertEquals(ExpectedInvoiceNo);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseInvoicesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoCorrectedDocNoLookUpOK()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        VendorNo: Code[20];
        ExpectedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo] [LookUP] [Corrected Invoice No]
        // [SCENARIO 267532] When Stan looks up "Corrected Invoice No." on Purchase Credit Memo page and then selects Invoice on Posted Purchase Invoices page and confirms his choice
        // [SCENARIO 267532] then "Corrected Invoice No." = Posted Purchase Invoice "No."

        // [GIVEN] Posted Purchase Invoice "I"
        VendorNo := LibraryPurchase.CreateVendorNo();
        ExpectedInvoiceNo := MockPurchInvoice(VendorNo);
        LibraryVariableStorage.Enqueue(ExpectedInvoiceNo);

        // [GIVEN] Stan opened Purchase Credit Memo page and looked up "Corrected Invoice No."
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo."Corrected Invoice No.".Lookup();

        // [WHEN] Stan selects Invoice "I" on page Posted Purchase Invoices and pushes OK

        // [THEN] Purchase Credit Memo has "Corrected Invoice No." = "I"
        PurchaseCreditMemo."Corrected Invoice No.".AssertEquals(ExpectedInvoiceNo);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoicesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoCorrectedDocNoLookUpOK()
    var
        ServiceHeader: Record "Service Header";
        ServiceCreditMemo: TestPage "Service Credit Memo";
        CustNo: Code[20];
        ExpectedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Service] [Credit Memo] [LookUP] [Corrected Invoice No]
        // [SCENARIO 267532] When Stan looks up "Corrected Invoice No." on Service Credit Memo page and then selects Invoice on Posted Service Invoices page and confirms his choice
        // [SCENARIO 267532] then "Corrected Invoice No." = Posted Service Invoice "No."

        // [GIVEN] Posted Service Invoice "I"
        CustNo := LibrarySales.CreateCustomerNo();
        ExpectedInvoiceNo := MockServiceInvoice(CustNo);
        LibraryVariableStorage.Enqueue(ExpectedInvoiceNo);

        // [GIVEN] Stan opened Service Credit Memo page and looked up "Corrected Invoice No."
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CustNo);
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.GotoRecord(ServiceHeader);
        ServiceCreditMemo."Corrected Invoice No.".Lookup();

        // [WHEN] Stan selects Invoice "I" on page Posted Service Invoices and pushes OK

        // [THEN] Service Credit Memo has "Corrected Invoice No." = "I"
        ServiceCreditMemo."Corrected Invoice No.".AssertEquals(ExpectedInvoiceNo);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDescriptionNotChangedAfterPostingSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        GLDocumentType: Enum "Gen. Journal Document Type";
        CustomerNo: Code[20];
        PostedInvoiceNo: Code[20];
        PostedCrMemoNo: Code[20];
        PostingDescription: Text[100];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Corrected Invoice No]
        // [SCENARIO 389191] Stan sets Posting Description and posts Sales Credit Memo.
        CustomerNo := LibrarySales.CreateCustomerNo();
        PostingDescription := LibraryUtility.GenerateGUID();

        // [GIVEN] Posted Sales Invoice "I".
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, CustomerNo);
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [GIVEN] Sales Credit Memo with "Corrected Invoice No." = "I" and "Posting Description" = "PD".
        LibrarySales.CreateSalesCreditMemoForCustomerNo(SalesHeader, CustomerNo);
        SalesHeader.Validate("Corrected Invoice No.", PostedInvoiceNo);
        SalesHeader.Validate("Posting Description", PostingDescription);
        SalesHeader.Modify(true);

        // [WHEN] Post Sales Credit Memo.
        PostedCrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Posted Credit Memo has "Posting Description" = "PD".
        // [THEN] General Ledger Entries for Posted Sales Credit Memo have "Description" = "PD".
        SalesCrMemoHeader.Get(PostedCrMemoNo);
        SalesCrMemoHeader.TestField("Posting Description", PostingDescription);
        VerifyGLEntriesDescription(GLDocumentType::"Credit Memo", PostedCrMemoNo, PostingDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankPostingDescriptionChangedAfterPostingSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        GLDocumentType: Enum "Gen. Journal Document Type";
        CustomerNo: Code[20];
        PostedInvoiceNo: Code[20];
        PostedCrMemoNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Corrected Invoice No]
        // [SCENARIO 389191] Blank Posting Description is filled with Corrected Invoice number after posting Sales Credit Memo.
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Posted Sales Invoice "I".
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, CustomerNo);
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [GIVEN] Sales Credit Memo "CRM" with "Corrected Invoice No." = "I" and blank "Posting Description".
        LibrarySales.CreateSalesCreditMemoForCustomerNo(SalesHeader, CustomerNo);
        SalesHeader.Validate("Corrected Invoice No.", PostedInvoiceNo);
        SalesHeader.Validate("Posting Description", '');
        SalesHeader.Modify(true);

        // [WHEN] Post Sales Credit Memo.
        PostedCrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Posted Credit Memo has "Posting Description" = "Corrective Invoice CRM".
        // [THEN] General Ledger Entries for Posted Sales Credit Memo have "Description" = "Corrective Invoice CRM".
        SalesCrMemoHeader.Get(PostedCrMemoNo);
        SalesCrMemoHeader.TestField("Posting Description", StrSubstNo(CorrectiveInvoiceTxt, SalesHeader."No."));
        VerifyGLEntriesDescription(GLDocumentType::"Credit Memo", PostedCrMemoNo, StrSubstNo(CorrectiveInvoiceTxt, SalesHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDescriptionNotChangedAfterPostingPurchaseCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        GLDocumentType: Enum "Gen. Journal Document Type";
        VendorNo: Code[20];
        PostedInvoiceNo: Code[20];
        PostedCrMemoNo: Code[20];
        PostingDescription: Text[100];
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Corrected Invoice No]
        // [SCENARIO 389191] Stan sets Posting Description and posts Purchase Credit Memo.
        VendorNo := LibraryPurchase.CreateVendorNo();
        PostingDescription := LibraryUtility.GenerateGUID();

        // [GIVEN] Posted Purchase Invoice "I".
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, VendorNo);
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Purchase Credit Memo with "Corrected Invoice No." = "I" and "Posting Description" = "PD".
        LibraryPurchase.CreatePurchaseCreditMemoForVendorNo(PurchaseHeader, VendorNo);
        PurchaseHeader.Validate("Corrected Invoice No.", PostedInvoiceNo);
        PurchaseHeader.Validate("Posting Description", PostingDescription);
        PurchaseHeader.Modify(true);

        // [WHEN] Post Purchase Credit Memo.
        PostedCrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Posted Credit Memo has "Posting Description" = "PD".
        // [THEN] General Ledger Entries for Posted Purchase Credit Memo have "Description" = "PD".
        PurchCrMemoHeader.Get(PostedCrMemoNo);
        PurchCrMemoHeader.TestField("Posting Description", PostingDescription);
        VerifyGLEntriesDescription(GLDocumentType::"Credit Memo", PostedCrMemoNo, PostingDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankPostingDescriptionChangedAfterPostingPurchaseCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        GLDocumentType: Enum "Gen. Journal Document Type";
        VendorNo: Code[20];
        PostedInvoiceNo: Code[20];
        PostedCrMemoNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Corrected Invoice No]
        // [SCENARIO 389191] Blank Posting Description is filled with Corrected Invoice number after posting Purchase Credit Memo.
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Posted Purchase Invoice "I".
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, VendorNo);
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Purchase Credit Memo "CRM" with "Corrected Invoice No." = "I" and blank "Posting Description".
        LibraryPurchase.CreatePurchaseCreditMemoForVendorNo(PurchaseHeader, VendorNo);
        PurchaseHeader.Validate("Corrected Invoice No.", PostedInvoiceNo);
        PurchaseHeader.Validate("Posting Description", '');
        PurchaseHeader.Modify(true);

        // [WHEN] Post Purchase Credit Memo.
        PostedCrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Posted Credit Memo has "Posting Description" = "Corrective Invoice CRM".
        // [THEN] General Ledger Entries for Posted Purchase Credit Memo have "Description" = "Corrective Invoice CRM".
        PurchCrMemoHeader.Get(PostedCrMemoNo);
        PurchCrMemoHeader.TestField("Posting Description", StrSubstNo(CorrectiveInvoiceTxt, PurchaseHeader."No."));
        VerifyGLEntriesDescription(GLDocumentType::"Credit Memo", PostedCrMemoNo, StrSubstNo(CorrectiveInvoiceTxt, PurchaseHeader."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostingDescriptionNotChangedAfterPostingServiceCrMemo()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServPostYesNo: Codeunit "Service-Post (Yes/No)";
        ServiceDocType: Enum "Service Document Type";
        CustomerNo: Code[20];
        PostedInvoiceNo: Code[20];
        PostedCrMemoNo: Code[20];
        PostingDescription: Text[100];
    begin
        // [FEATURE] [Service] [Credit Memo] [Corrected Invoice No]
        // [SCENARIO 389191] Stan sets Posting Description and posts Service Credit Memo.
        CustomerNo := LibrarySales.CreateCustomerNo();
        PostingDescription := LibraryUtility.GenerateGUID();

        // [GIVEN] Posted Service Invoice "I".
        LibraryService.CreateServiceDocumentForCustomerNo(ServiceHeader, ServiceDocType::Invoice, CustomerNo);
        ServPostYesNo.PostDocument(ServiceHeader);
        PostedInvoiceNo := ServiceHeader."Last Posting No.";

        // [GIVEN] Service Credit Memo with "Corrected Invoice No." = "I" and "Posting Description" = "PD".
        LibraryService.CreateServiceDocumentForCustomerNo(ServiceHeader, ServiceDocType::"Credit Memo", CustomerNo);
        ServiceHeader.Validate("Corrected Invoice No.", PostedInvoiceNo);
        ServiceHeader.Validate("Posting Description", PostingDescription);
        ServiceHeader.Modify(true);

        // [WHEN] Post Service Credit Memo.
        ServPostYesNo.PostDocument(ServiceHeader);
        PostedCrMemoNo := ServiceHeader."Last Posting No.";

        // [THEN] Posted Credit Memo has "Posting Description" = "PD".
        // [THEN] General Ledger Entries for Posted Service Credit Memo have "Description" = "PD".
        ServiceCrMemoHeader.Get(PostedCrMemoNo);
        ServiceCrMemoHeader.TestField("Posting Description", PostingDescription);
        VerifyGLEntriesServiceCrMemoDescription(PostedCrMemoNo, PostingDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure BlankPostingDescriptionChangedAfterPostingServiceCrMemo()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServPostYesNo: Codeunit "Service-Post (Yes/No)";
        ServiceDocType: Enum "Service Document Type";
        CustomerNo: Code[20];
        PostedInvoiceNo: Code[20];
        PostedCrMemoNo: Code[20];
    begin
        // [FEATURE] [Service] [Credit Memo] [Corrected Invoice No]
        // [SCENARIO 389191] Blank Posting Description is filled with Corrected Invoice number after posting Service Credit Memo.
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Posted Service Invoice "I".
        LibraryService.CreateServiceDocumentForCustomerNo(ServiceHeader, ServiceDocType::Invoice, CustomerNo);
        ServPostYesNo.PostDocument(ServiceHeader);
        PostedInvoiceNo := ServiceHeader."Last Posting No.";

        // [GIVEN] Service Credit Memo "CRM" with "Corrected Invoice No." = "I" and blank "Posting Description".
        LibraryService.CreateServiceDocumentForCustomerNo(ServiceHeader, ServiceDocType::"Credit Memo", CustomerNo);
        ServiceHeader.Validate("Corrected Invoice No.", PostedInvoiceNo);
        ServiceHeader.Validate("Posting Description", '');
        ServiceHeader.Modify(true);

        // [WHEN] Post Service Credit Memo.
        ServPostYesNo.PostDocument(ServiceHeader);
        PostedCrMemoNo := ServiceHeader."Last Posting No.";

        // [THEN] Posted Credit Memo has "Posting Description" = "Corrective Invoice CRM".
        // [THEN] General Ledger Entries for Posted Service Credit Memo have "Description" = "Corrective Invoice CRM".
        ServiceCrMemoHeader.Get(PostedCrMemoNo);
        ServiceCrMemoHeader.TestField("Posting Description", StrSubstNo(CorrectiveInvoiceTxt, ServiceHeader."No."));
        VerifyGLEntriesServiceCrMemoDescription(PostedCrMemoNo, StrSubstNo(CorrectiveInvoiceTxt, ServiceHeader."No."));
    end;

    local procedure MockSalesInvoice(CustNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."Bill-to Customer No." := CustNo;
        SalesInvoiceHeader.Insert();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure MockPurchInvoice(VendNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Init();
        PurchInvHeader."No." := LibraryUtility.GenerateGUID();
        PurchInvHeader."Pay-to Vendor No." := VendNo;
        PurchInvHeader.Insert();
        exit(PurchInvHeader."No.");
    end;

    local procedure MockServiceInvoice(CustNo: Code[20]): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.Init();
        ServiceInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        ServiceInvoiceHeader."Bill-to Customer No." := CustNo;
        ServiceInvoiceHeader.Insert();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure VerifyGLEntriesDescription(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; ExpectedDescription: Text[100])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Posting Date", WorkDate());
        GLEntry.SetLoadFields(Description);
        GLEntry.FindSet();
        repeat
            GLEntry.TestField(Description, ExpectedDescription);
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyGLEntriesServiceCrMemoDescription(DocumentNo: Code[20]; ExpectedDescription: Text[100])
    var
        GLEntry: Record "G/L Entry";
        GLDocumentType: Enum "Gen. Journal Document Type";
    begin
        GLEntry.SetRange("Document Type", GLDocumentType::"Credit Memo");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Posting Date", WorkDate());
        GLEntry.SetFilter("Credit Amount", '<>%1', 0);
        GLEntry.SetLoadFields(Description);
        GLEntry.FindSet();
        repeat
            GLEntry.TestField(Description, ExpectedDescription);
        until GLEntry.Next() = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicesModalPageHandler(var PostedSalesInvoices: TestPage "Posted Sales Invoices")
    begin
        PostedSalesInvoices.GotoKey(LibraryVariableStorage.DequeueText());
        PostedSalesInvoices.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoicesModalPageHandler(var PostedPurchaseInvoices: TestPage "Posted Purchase Invoices")
    begin
        PostedPurchaseInvoices.GotoKey(LibraryVariableStorage.DequeueText());
        PostedPurchaseInvoices.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoicesModalPageHandler(var PostedServiceInvoices: TestPage "Posted Service Invoices")
    begin
        PostedServiceInvoices.GotoKey(LibraryVariableStorage.DequeueText());
        PostedServiceInvoices.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

