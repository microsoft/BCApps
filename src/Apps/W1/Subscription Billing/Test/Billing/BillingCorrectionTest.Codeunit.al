namespace Microsoft.SubscriptionBilling;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Utilities;

codeunit 139686 "Billing Correction Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;
    Access = Internal;

    var
        BillingLine: Record "Billing Line";
        BillingLineArchive: Record "Billing Line Archive";
        BillingTemplate: Record "Billing Template";
        CustomerContract: Record "Customer Subscription Contract";
        PurchInvoiceHeader: Record "Purch. Inv. Header";
        PurchInvoiceLine: Record "Purch. Inv. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        ServiceObject: Record "Subscription Header";
        VendorContract: Record "Vendor Subscription Contract";
        Assert: Codeunit Assert;
        ContractTestLibrary: Codeunit "Contract Test Library";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        BillingDateFormula: DateFormula;
        BillingToDateFormula: DateFormula;
        IsInitialized: Boolean;
        PostedDocumentNo: Code[20];
        BillingLineCount: Integer;

    #region Tests

    [Test]
    [HandlerFunctions('CreateBillingDocsVendorPageHandler,ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure CancelPostedPurchaseInvoiceIfContractLineNumberWasChanged()
    var
        CommentLine: Record "Vend. Sub. Contract Line";
        ContractLine: Record "Vend. Sub. Contract Line";
    begin
        // [SCENARIO]: Create Vendor Contract with two lines and post invoice for that contract
        // [SCENARIO]: Delete the second contract line in that contract, add comment line and assign second service commitment to the contract again
        // [SCENARIO]: Create Credit Memo from Posted Purchase Invoice

        // [GIVEN]: Create contract and post invoice for that contract
        Initialize();
        PostPurchaseInvoiceForContract();

        // [WHEN]: Delete the second contract line in that contract
        ContractLine.SetRange("Subscription Contract No.", VendorContract."No.");
        ContractLine.FindLast();
        ContractLine.Delete(true);

        // [WHEN]: Add a comment line in the contract
        CommentLine.Init();
        CommentLine."Subscription Contract No." := VendorContract."No.";
        CommentLine."Line No." := ContractLine."Line No." + 10000; // Add a new line after the last one
        CommentLine."Contract Line Type" := "Contract Line Type"::Comment;
        CommentLine."Subscription Description" := 'This is a comment line.';
        CommentLine."Subscription Line Description" := 'This is a comment line.';
        CommentLine.Insert(false);

        // [WHEN]: Get the second service commitment into the contract again
        ContractTestLibrary.AssignServiceObjectForItemToVendorContract(VendorContract, ServiceObject, false);

        // [WHEN]: Create Credit Memo from Posted Sales Invoice using CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvoiceHeader, PurchaseHeader);

        // [THEN]: Assert that the Credit Memo was created successfully
        Assert.IsTrue(PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo", 'Credit Memo was not created successfully.');
    end;

    [Test]
    [HandlerFunctions('CreateBillingDocsCustomerPageHandler,ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure CancelPostedSalesInvoiceIfContractLineNumberWasChanged()
    var
        CommentLine: Record "Cust. Sub. Contract Line";
        ContractLine: Record "Cust. Sub. Contract Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [SCENARIO]: Create Customer Contract with two lines and post invoice for that contract
        // [SCENARIO]: Delete the second contract line in that contract, add comment line and assign second service commitment to the contract again
        // [SCENARIO]: Create Credit Memo from Posted Sales Invoice

        // [GIVEN]: Create contract and post invoice for that contract
        Initialize();
        PostSalesInvoiceForContract();

        // [WHEN]: Delete the second contract line in that contract
        ContractLine.SetRange("Subscription Contract No.", CustomerContract."No.");
        ContractLine.FindLast();
        ContractLine.Delete(true);

        // [WHEN]: Add a comment line in the contract
        CommentLine.Init();
        CommentLine."Subscription Contract No." := CustomerContract."No.";
        CommentLine."Line No." := ContractLine."Line No." + 10000; // Add a new line after the last one
        CommentLine."Contract Line Type" := "Contract Line Type"::Comment;
        CommentLine."Subscription Description" := 'This is a comment line.';
        CommentLine."Subscription Line Description" := 'This is a comment line.';
        CommentLine.Insert(false);

        // [WHEN]: Get the second service commitment into the contract again
        ContractTestLibrary.AssignServiceObjectForItemToCustomerContract(CustomerContract, ServiceObject, false);

        // [WHEN]: Cancel Posted Sales Invoice
        Commit(); // commit the changes before canceling the invoice
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [THEN]: Assert that the Credit Memo was created successfully
        SalesCrMemoHeader.SetRange("Applies-to Doc. No.", SalesInvoiceHeader."No.");
        Assert.RecordIsNotEmpty(SalesCrMemoHeader);
    end;

    [Test]
    [HandlerFunctions('CreateBillingDocsCustomerPageHandler,ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure CheckBillingLinesCreatedForCreditMemo()
    begin
        Initialize();

        PostSalesInvoiceForContract();
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesHeader);
        BillingLineArchive.SetRange("Subscription Contract No.", SalesInvoiceLine."Subscription Contract No.");
        BillingLineArchive.SetRange("Subscription Contract Line No.", SalesInvoiceLine."Subscription Contract Line No.");
        if BillingLineArchive.FindSet() then
            repeat
                BillingLine.SetRange("Correction Document Type", BillingLineArchive."Document Type");
                BillingLine.SetRange("Correction Document No.", BillingLineArchive."Document No.");
                BillingLine.SetRange("Subscription Contract No.", BillingLineArchive."Subscription Contract No.");
                BillingLine.SetRange("Subscription Contract Line No.", BillingLineArchive."Subscription Contract Line No.");
                BillingLine.SetRange("Billing from", BillingLineArchive."Billing from");
                BillingLine.SetRange("Billing to", BillingLineArchive."Billing to");
                BillingLine.FindFirst();
                BillingLine.TestField("Correction Document Type", Enum::"Rec. Billing Document Type"::"Credit Memo");
                BillingLine.TestField("Correction Document No.", SalesHeader."No.");
            until BillingLineArchive.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('CreateBillingDocsVendorPageHandler,ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure CheckBillingLinesCreatedForPurchaseCreditMemo()
    begin
        Initialize();

        PostPurchaseInvoiceForContract();
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvoiceHeader, PurchaseHeader);
        BillingLineArchive.SetRange("Subscription Contract No.", PurchInvoiceLine."Subscription Contract No.");
        BillingLineArchive.SetRange("Subscription Contract Line No.", PurchInvoiceLine."Subscription Contract Line No.");
        if BillingLineArchive.FindSet() then
            repeat
                BillingLine.SetRange("Correction Document Type", BillingLineArchive."Document Type");
                BillingLine.SetRange("Correction Document No.", BillingLineArchive."Document No.");
                BillingLine.SetRange("Subscription Contract No.", BillingLineArchive."Subscription Contract No.");
                BillingLine.SetRange("Subscription Contract Line No.", BillingLineArchive."Subscription Contract Line No.");
                BillingLine.SetRange("Billing from", BillingLineArchive."Billing from");
                BillingLine.SetRange("Billing to", BillingLineArchive."Billing to");
                BillingLine.FindFirst();
                BillingLine.TestField("Correction Document Type", Enum::"Rec. Billing Document Type"::"Credit Memo");
                BillingLine.TestField("Correction Document No.", SalesHeader."No.");
            until BillingLineArchive.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('CreateBillingDocsCustomerPageHandler,ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ExpectErrorWhenCopyingPostedContractInvoice()
    var
        i: Integer;
    begin
        Initialize();
        for i := 0 to 5 do begin
            PostSalesInvoiceForContract();
            SalesHeader2."Document Type" := Enum::"Sales Document Type".FromInteger(i);
            CopyDocMgt.SetProperties(true, false, false, true, true, true, false);
            if SalesHeader2."Document Type" = SalesHeader2."Document Type"::"Credit Memo" then
                CopyDocMgt.CopySalesDoc(Enum::"Sales Document Type From"::"Posted Invoice", SalesInvoiceHeader."No.", SalesHeader2)
            else
                asserterror CopyDocMgt.CopySalesDoc(Enum::"Sales Document Type From"::"Posted Invoice", SalesInvoiceHeader."No.", SalesHeader2);
        end;
    end;

    [Test]
    [HandlerFunctions('CreateBillingDocsVendorPageHandler,ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ExpectErrorWhenCopyingPostedVendorContractInvoice()
    var
        i: Integer;
    begin
        Initialize();
        for i := 0 to 5 do begin
            PostPurchaseInvoiceForContract();
            PurchaseHeader2."Document Type" := Enum::"Purchase Document Type".FromInteger(i);
            CopyDocMgt.SetProperties(true, false, false, true, true, true, false);
            if PurchaseHeader2."Document Type" = PurchaseHeader2."Document Type"::"Credit Memo" then
                CopyDocMgt.CopyPurchDoc(Enum::"Purchase Document Type From"::"Posted Invoice", PurchInvoiceHeader."No.", PurchaseHeader2)
            else
                asserterror CopyDocMgt.CopyPurchDoc(Enum::"Purchase Document Type From"::"Posted Invoice", PurchInvoiceHeader."No.", PurchaseHeader2);
        end;
    end;

    [Test]
    [HandlerFunctions('CreateBillingDocsCustomerPageHandler,ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ExpectErrorWhenNewerInvoiceExist()
    begin
        Initialize();

        PostSalesInvoiceForContract();
        Evaluate(BillingDateFormula, '<9M-CM>');
        Evaluate(BillingToDateFormula, '<12M+CM>');
        BillingTemplate."Billing Date Formula" := BillingDateFormula;
        BillingTemplate."Billing to Date Formula" := BillingToDateFormula;
        BillingTemplate.Modify(false);
        ContractTestLibrary.CreateBillingProposal(BillingTemplate, Enum::"Service Partner"::Customer);
        asserterror CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesHeader);
    end;

    [Test]
    [HandlerFunctions('CreateBillingDocsVendorPageHandler,ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ExpectErrorWhenNewerPurchaseInvoiceExist()
    begin
        Initialize();

        PostPurchaseInvoiceForContract();
        Evaluate(BillingDateFormula, '<9M-CM>');
        Evaluate(BillingToDateFormula, '<12M+CM>');
        BillingTemplate."Billing Date Formula" := BillingDateFormula;
        BillingTemplate."Billing to Date Formula" := BillingToDateFormula;
        BillingTemplate.Modify(false);
        ContractTestLibrary.CreateBillingProposal(BillingTemplate, Enum::"Service Partner"::Vendor);
        asserterror CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvoiceHeader, PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('CreateBillingDocsVendorPageHandler,PurchaseCreditMemosPageHandler,ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ExpectErrorWhenRelatedPurchaseLineExist()
    begin
        Initialize();

        PostPurchaseInvoiceForContract();
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvoiceHeader, PurchaseHeader);
        Commit(); // retain data after asserterror
        asserterror CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvoiceHeader, PurchaseHeader2);
        ContractTestLibrary.CreateBillingProposal(BillingTemplate, Enum::"Service Partner"::Vendor);
        Assert.AreEqual(BillingLineCount, BillingLine.Count, 'Only the billing lines for Credit Memo should exist');
        BillingLine.FindFirst();
        BillingLine.TestField("Document No.", PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('CreateBillingDocsCustomerPageHandler,SalesCreditMemosPageHandler,ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure ExpectErrorWhenRelatedSalesLineExist()
    begin
        Initialize();

        PostSalesInvoiceForContract();
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesHeader);
        Commit(); // retain data after asserterror
        asserterror CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesHeader2);
        ContractTestLibrary.CreateBillingProposal(BillingTemplate, Enum::"Service Partner"::Customer);
        BillingLine.Reset();
        BillingLine.SetRange("Document Type", Enum::"Rec. Billing Document Type"::Invoice);
        Assert.RecordIsEmpty(BillingLine);

        BillingLine.SetRange("Document Type", Enum::"Rec. Billing Document Type"::"Credit Memo");
        Assert.AreEqual(BillingLineCount, BillingLine.Count, 'Only the billing lines for Credit Memo should exist');
        BillingLine.FindFirst();
        BillingLine.TestField("Document No.", SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('CreateBillingDocsCustomerPageHandler,ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure TestChangeServiceStartDateAfterCorrectionCustomerContract()
    var
        ServiceCommitment: Record "Subscription Line";
    begin
        Initialize();

        PostSalesInvoiceForContract();
        ServiceCommitment.Get(BillingLine."Subscription Line Entry No.");
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesHeader); // Retrieve updated Subscription Line
        ServiceCommitment.Get(ServiceCommitment."Entry No.");
        ServiceCommitment.Validate("Subscription Line Start Date", LibraryRandom.RandDateFrom(ServiceCommitment."Subscription Line Start Date", 100));
    end;

    [Test]
    [HandlerFunctions('CreateBillingDocsVendorPageHandler,ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure TestChangeServiceStartDateAfterCorrectionVendorContract()
    var
        ServiceCommitment: Record "Subscription Line";
    begin
        Initialize();

        PostPurchaseInvoiceForContract();
        ServiceCommitment.Get(BillingLine."Subscription Line Entry No.");
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvoiceHeader, PurchaseHeader);
        // Retrieve updated Subscription Line
        ServiceCommitment.Get(ServiceCommitment."Entry No.");
        ServiceCommitment.Validate("Subscription Line Start Date", LibraryRandom.RandDateFrom(ServiceCommitment."Subscription Line Start Date", 100));
    end;

    [Test]
    [HandlerFunctions('CreateBillingDocsCustomerPageHandler,CreateBillingDocsVendorPageHandler,ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure PurchaseInvoiceCreatedForVendorContractWhenCustomerContractWithSameNoHasOpenCreditMemo()
    var
        VendorAmount: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 653306] Purchase invoice is created for a vendor contract when a customer contract with the same No. has an unposted corrective credit memo.
        Initialize();

        // [GIVEN] Create Customer contract with posted sales invoice and unposted corrective sales credit memo with amount higher than vendor amount.
        VendorAmount := LibraryRandom.RandIntInRange(10, 100);
        CreateCustomerContractWithPostedInvoiceAndCreditMemo(VendorAmount * 10);

        // [GIVEN] Create Vendor contract with the same No. as Customer contract.
        CreateVendorContractWithNo(CustomerContract."No.", VendorAmount);

        // [WHEN] Create billing documents for Vendor Contract.
        CreateBillingDocumentsForContract(Enum::"Service Partner"::Vendor, VendorContract."No.");

        // [THEN] Verify that a purchase invoice is created for Vendor Contract.
        VerifyPurchaseInvoiceCreated();
    end;

    [Test]
    [HandlerFunctions('ExchangeRateSelectionModalPageHandler,MessageHandler')]
    procedure RecurringBillingGroupingAmountExcludesCustomerLinesWithSameContractNo()
    var
        TempBillingLine: Record "Billing Line" temporary;
        BillingProposal: Codeunit "Billing Proposal";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 653307] Grouping line amount for a vendor contract includes only vendor billing lines when a customer contract has the same No.
        Initialize();

        // [GIVEN] Create Customer contract with billing lines.
        ContractTestLibrary.CreateCustomerContractAndCreateContractLinesForItems(CustomerContract, ServiceObject, '');
        CreateBillingProposalForContract(Enum::"Service Partner"::Customer, CustomerContract."No.");

        // [GIVEN] Create Vendor contract with the same No. as Customer contract and billing lines.
        CreateVendorContractWithNo(CustomerContract."No.", LibraryRandom.RandIntInRange(10, 100));
        CreateBillingProposalForContract(Enum::"Service Partner"::Vendor, VendorContract."No.");

        // [WHEN] Build recurring billing lines for Vendor Contract grouped by contract.
        TempBillingLine.SetRange(Partner, Enum::"Service Partner"::Vendor);
        BillingProposal.InitTempTable(TempBillingLine, Enum::"Contract Billing Grouping"::Contract);

        // [THEN] Verify that the grouping line amount for Vendor Contract equals the sum of vendor billing lines only.
        VerifyGroupingLineAmount(TempBillingLine, Enum::"Service Partner"::Vendor, VendorContract."No.");
    end;

    #endregion Tests

    #region Procedures

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Billing Correction Test");
        ClearAll();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Billing Correction Test");
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Billing Correction Test");
    end;

    local procedure PostPurchaseInvoiceForContract()
    begin
        ClearAll();
        BillingTemplate.DeleteAll(false);
        ContractTestLibrary.CreateVendorContractAndCreateContractLinesForItems(VendorContract, ServiceObject, '', true);
        ContractTestLibrary.DisableDeferralsForVendorContract(VendorContract, false);
        ContractTestLibrary.CreateBillingProposal(BillingTemplate, Enum::"Service Partner"::Vendor);
        BillingLine.SetRange("Billing Template Code", BillingTemplate.Code);
        BillingLine.SetRange(Partner, BillingLine.Partner::Vendor);
        Codeunit.Run(Codeunit::"Create Billing Documents", BillingLine);
        // Post Purchase Document
        BillingLineCount := BillingLine.Count;
        BillingLine.FindFirst();
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, BillingLine."Document No.");
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(false);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchInvoiceHeader.Get(PostedDocumentNo);
    end;

    local procedure PostSalesInvoiceForContract()
    begin
        ClearAll();
        ContractTestLibrary.CreateCustomerContractAndCreateContractLinesForItems(CustomerContract, ServiceObject, '', true);
        ContractTestLibrary.DisableDeferralsForCustomerContract(CustomerContract, false);
        ContractTestLibrary.CreateBillingProposal(BillingTemplate, Enum::"Service Partner"::Customer);
        BillingLine.SetRange("Billing Template Code", BillingTemplate.Code);
        BillingLine.SetRange(Partner, BillingLine.Partner::Customer);
        Codeunit.Run(Codeunit::"Create Billing Documents", BillingLine);
        // Post Sales Document
        BillingLineCount := BillingLine.Count;
        BillingLine.FindLast();
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, BillingLine."Document No.");
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.Get(PostedDocumentNo);
    end;

    local procedure CreateCustomerContractWithPostedInvoiceAndCreditMemo(CalculationBaseAmount: Decimal)
    begin
        ContractTestLibrary.CreateCustomerContractAndCreateContractLinesForItems(CustomerContract, ServiceObject, '');
        ContractTestLibrary.DisableDeferralsForCustomerContract(CustomerContract, false);
        SetSubscriptionLineCalculationBaseAmount(Enum::"Service Partner"::Customer, CustomerContract."No.", CalculationBaseAmount);
        CreateBillingDocumentsForContract(Enum::"Service Partner"::Customer, CustomerContract."No.");
        BillingLine.FindFirst();
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, BillingLine."Document No.");
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesHeader2);
    end;

    local procedure CreateVendorContractWithNo(ContractNo: Code[20]; CalculationBaseAmount: Decimal)
    var
        Vendor: Record Vendor;
        VendorServiceObject: Record "Subscription Header";
    begin
        ContractTestLibrary.CreateVendorInLCY(Vendor);
        VendorContract.Init();
        VendorContract."No." := ContractNo;
        VendorContract.Insert(true);
        VendorContract.Validate("Buy-from Vendor No.", Vendor."No.");
        VendorContract.Modify(true);
        ContractTestLibrary.AssignServiceObjectForItemToVendorContract(VendorContract, VendorServiceObject, false);
        ContractTestLibrary.DisableDeferralsForVendorContract(VendorContract, false);
        SetSubscriptionLineCalculationBaseAmount(Enum::"Service Partner"::Vendor, VendorContract."No.", CalculationBaseAmount);
    end;

    local procedure SetSubscriptionLineCalculationBaseAmount(ServicePartner: Enum "Service Partner"; ContractNo: Code[20]; CalculationBaseAmount: Decimal)
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        SubscriptionLine.SetRange(Partner, ServicePartner);
        SubscriptionLine.SetRange("Subscription Contract No.", ContractNo);
        SubscriptionLine.FindFirst();
        SubscriptionLine.Validate("Calculation Base %", 100);
        SubscriptionLine.Validate("Calculation Base Amount", CalculationBaseAmount);
        SubscriptionLine.Modify(true);
    end;

    local procedure CreateBillingProposalForContract(ServicePartner: Enum "Service Partner"; ContractNo: Code[20])
    var
        ContractBillingTemplate: Record "Billing Template";
        FilterCustomerContract: Record "Customer Subscription Contract";
        FilterVendorContract: Record "Vendor Subscription Contract";
        FilterText: Text;
    begin
        case ServicePartner of
            Enum::"Service Partner"::Customer:
                begin
                    FilterCustomerContract.SetRange("No.", ContractNo);
                    FilterText := FilterCustomerContract.GetView();
                end;
            Enum::"Service Partner"::Vendor:
                begin
                    FilterVendorContract.SetRange("No.", ContractNo);
                    FilterText := FilterVendorContract.GetView();
                end;
        end;
        ContractTestLibrary.CreateRecurringBillingTemplate(ContractBillingTemplate, '<2M-CM>', '<8M+CM>', FilterText, ServicePartner);
        ContractTestLibrary.CreateBillingProposal(ContractBillingTemplate, ServicePartner);
        BillingLine.Reset();
        BillingLine.SetRange("Billing Template Code", ContractBillingTemplate.Code);
        BillingLine.SetRange(Partner, ServicePartner);
        BillingLine.SetRange("Subscription Contract No.", ContractNo);
    end;

    local procedure CreateBillingDocumentsForContract(ServicePartner: Enum "Service Partner"; ContractNo: Code[20])
    begin
        CreateBillingProposalForContract(ServicePartner, ContractNo);
        Codeunit.Run(Codeunit::"Create Billing Documents", BillingLine);
    end;

    local procedure VerifyPurchaseInvoiceCreated()
    var
        InvoicePurchaseHeader: Record "Purchase Header";
    begin
        BillingLine.FindFirst();
        Assert.AreEqual(Enum::"Rec. Billing Document Type"::Invoice, BillingLine."Document Type", 'Billing line must be linked to an invoice.');
        InvoicePurchaseHeader.SetRange("Document Type", InvoicePurchaseHeader."Document Type"::Invoice);
        InvoicePurchaseHeader.SetRange("No.", BillingLine."Document No.");
        Assert.RecordIsNotEmpty(InvoicePurchaseHeader);
    end;

    local procedure VerifyGroupingLineAmount(var TempBillingLine: Record "Billing Line" temporary; ServicePartner: Enum "Service Partner"; ContractNo: Code[20])
    var
        PartnerBillingLine: Record "Billing Line";
    begin
        PartnerBillingLine.SetRange(Partner, ServicePartner);
        PartnerBillingLine.SetRange("Subscription Contract No.", ContractNo);
        PartnerBillingLine.CalcSums(Amount);
        TempBillingLine.SetRange(Indent, 0);
        TempBillingLine.SetRange("Subscription Contract No.", ContractNo);
        TempBillingLine.FindFirst();
        Assert.AreEqual(PartnerBillingLine.Amount, TempBillingLine.Amount, 'Grouping line amount must include only billing lines of the same partner.');
    end;

    #endregion Procedures

    #region Handlers

    [ModalPageHandler]
    procedure CreateBillingDocsCustomerPageHandler(var CreateBillingDocsCustomerPage: TestPage "Create Customer Billing Docs")
    begin
        CreateBillingDocsCustomerPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CreateBillingDocsVendorPageHandler(var CreateBillingDocsVendorPage: TestPage "Create Vendor Billing Docs")
    begin
        CreateBillingDocsVendorPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ExchangeRateSelectionModalPageHandler(var ExchangeRateSelectionPage: TestPage "Exchange Rate Selection")
    begin
        ExchangeRateSelectionPage.OK().Invoke();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [PageHandler]
    procedure PurchaseCreditMemosPageHandler(var PurchaseCreditMemosPage: TestPage "Purchase Credit Memos")
    begin
        PurchaseCreditMemosPage.OK().Invoke();
    end;

    [PageHandler]
    procedure PurchaseCrMemoPageHandler(var PurchaseCreditMemoPage: TestPage "Purchase Credit Memo")
    begin
        PurchaseCreditMemoPage.OK().Invoke();
    end;

    [PageHandler]
    procedure SalesCreditMemosPageHandler(var SalesCreditMemosPage: TestPage "Sales Credit Memos")
    begin
        SalesCreditMemosPage.OK().Invoke();
    end;

    [PageHandler]
    procedure SalesCrMemoPageHandler(var SalesCreditMemoPage: TestPage "Sales Credit Memo")
    begin
        SalesCreditMemoPage.OK().Invoke();
    end;

    #endregion Handlers
}
