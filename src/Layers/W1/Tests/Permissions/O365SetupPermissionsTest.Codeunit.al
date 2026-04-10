codeunit 139450 "O365 Setup Permissions Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Test Framework] [O365] [Permissions]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryIncomingDocuments: Codeunit "Library - Incoming Documents";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryNoSeries: Codeunit "Library - No. Series";

    [Test]
    [Scope('OnPrem')]
    procedure O365SetupUtility()
    var
        NoSeries: Record "No. Series";
        NoSeries2: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryLowerPermissions.SetO365Setup();
        LibraryUtility.CreateNoSeries(NoSeries, true, false, true);
        LibraryUtility.CreateNoSeries(NoSeries2, true, false, true);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '001', '999');
        LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, NoSeries2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure O365SetupPurchase()
    var
        OrderAddress: Record "Order Address";
        Purchasing: Record Purchasing;
        StandardPurchaseCode: Record "Standard Purchase Code";
        StandardPurchaseLine: Record "Standard Purchase Line";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorBankAccount: Record "Vendor Bank Account";
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
    begin
        LibraryLowerPermissions.SetO365Setup();
        LibraryPurchase.CreateVendorWithVATRegNo(Vendor);
        LibraryPurchase.CreateOrderAddress(OrderAddress, Vendor."No.");
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        LibraryPurchase.CreateStandardPurchaseCode(StandardPurchaseCode);
        LibraryPurchase.CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode.Code);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        LibraryPurchase.CreateVendorPurchaseCode(StandardVendorPurchaseCode, Vendor."No.", StandardPurchaseCode.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure O365SetupSales()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        CustomerPostingGroup: Record "Customer Posting Group";
        CustomerPriceGroup: Record "Customer Price Group";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        ShipToAddress: Record "Ship-to Address";
        StandardSalesCode: Record "Standard Sales Code";
        StandardSalesLine: Record "Standard Sales Line";
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryLowerPermissions.SetO365Setup();
        LibraryUtility.CreateNoSeries(NoSeries, true, false, true);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '001', '999');
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Direct Debit Mandate Nos.", NoSeries.Code);
        SalesReceivablesSetup.Modify(true);
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        LibrarySales.CreateStandardSalesCode(StandardSalesCode);
        LibrarySales.CreateStandardSalesLine(StandardSalesLine, StandardSalesCode.Code);
        LibrarySales.CreateCustomerSalesCode(StandardCustomerSalesCode, Customer."No.", StandardSalesCode.Code);
        LibrarySales.CreateCustomerMandate(SEPADirectDebitMandate, Customer."No.", CustomerBankAccount.Code, Today, Today);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure O365SetupERM()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        AnalysisView: Record "Analysis View";
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        TextToAccountMapping: Record "Text-to-Account Mapping";
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        CountryRegion: Record "Country/Region";
        CurrencyForReminderLevel: Record "Currency for Reminder Level";
        CustomerDiscountGroup: Record "Customer Discount Group";
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinanceChargeText: Record "Finance Charge Text";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GLBudgetEntry: Record "G/L Budget Entry";
        GLBudgetName: Record "G/L Budget Name";
        GenJournalTemplate: Record "Gen. Journal Template";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        ItemAnalysisView: Record "Item Analysis View";
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        PostCode: Record "Post Code";
        ReasonCode: Record "Reason Code";
        ReminderLevel: Record "Reminder Level";
        ReminderTerms: Record "Reminder Terms";
        ReminderText: Record "Reminder Text";
        GenJournalBatch: Record "Gen. Journal Batch";
        SourceCode: Record "Source Code";
        VATPostingSetup: Record "VAT Posting Setup";
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        StandardGeneralJournal: Record "Standard General Journal";
        VATStatementName: Record "VAT Statement Name";
        VATStatementTemplate: Record "VAT Statement Template";
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxGroup: Record "Tax Group";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
        GLAccountCode: Code[20];
        CurrencyCode: Code[10];
    begin
        LibraryLowerPermissions.SetO365Setup();
        // [GIVEN] A customer and a Vendor
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        LibraryPurchase.CreateVendorWithVATRegNo(Vendor);

        GLAccountCode := LibraryERM.CreateGLAccountNoWithDirectPosting();
        LibraryERM.CreateAnalysisView(AnalysisView);
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        LibraryERM.CreateAccountMapping(TextToAccountMapping, CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10));
        LibraryERM.CreateAccountMappingCustomer(TextToAccountMapping, CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10), Customer."No.");
        LibraryERM.CreateAccountMappingGLAccount(
          TextToAccountMapping, CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10), GLAccountCode, GLAccountCode);
        LibraryERM.CreateAccountMappingVendor(TextToAccountMapping, CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10), Vendor."No.");
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccountPostingGroup(BankAccountPostingGroup);
        LibraryERM.CreateCountryRegion(CountryRegion);
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup);
        LibraryERM.CreateDeferralTemplateCode("Deferral Calculation Method"::"Equal per Period", "Deferral Calculation Start Date"::"Beginning of Period", 12);
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        LibraryERM.CreateFinanceChargeText(
          FinanceChargeText, FinanceChargeTerms.Code, 1, CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10));
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, Today, GLAccountCode, GLBudgetName.Name);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10), CurrencyCode, 0);
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10), CurrencyCode, 0);
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Inventory);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryERM.CreatePostCode(PostCode);
        LibraryERM.CreateReasonCode(ReasonCode);
        LibraryERM.CreateReminderTerms(ReminderTerms);
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTerms.Code);
        LibraryERM.CreateReminderText(
          ReminderText, ReminderTerms.Code, ReminderLevel."No.", "Reminder Text Position"::Ending, CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10));
        LibraryERM.CreateCurrencyForReminderLevel(CurrencyForReminderLevel, ReminderTerms.Code, CurrencyCode);
        LibraryERM.CreateRecurringTemplateName(GenJournalTemplate);
        LibraryERM.CreateRecurringBatchName(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateSourceCode(SourceCode);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 5.5);
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CountryRegion.Code);
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalTemplate.Name);
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxJurisdiction.Code);
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroup.Code, TaxDetail."Tax Type"::"Excise Tax", Today);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure O365SetupDimension()
    var
        Customer: Record Customer;
        AnalysisView: Record "Analysis View";
        Dimension: Record Dimension;
        Dimension2: Record Dimension;
        DimensionCombination: Record "Dimension Combination";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        DimensionValueCombination: Record "Dimension Value Combination";
        DefaultDimension: Record "Default Dimension";
        SelectedDimension: Record "Selected Dimension";
    begin
        LibraryLowerPermissions.SetO365Setup();
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        LibraryERM.CreateAnalysisView(AnalysisView);

        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimension(Dimension2);
        LibraryDimension.CreateDimensionCombination(DimensionCombination, Dimension.Code, Dimension2.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue2, Dimension2.Code);
        LibraryDimension.CreateDimValueCombination(
          DimensionValueCombination, Dimension.Code, Dimension2.Code, DimensionValue.Code, DimensionValue2.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension.Code, DimensionValue.Code);
        LibraryDimension.CreateSelectedDimension(SelectedDimension, 1, DATABASE::Dimension, AnalysisView.Code, Dimension.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure O365SetupIncomingDocuments()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        LibraryLowerPermissions.SetO365Setup();
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure O365SetupFiscalYear()
    begin
        LibraryLowerPermissions.SetO365Setup();
        LibraryFiscalYear.CreateFiscalYear();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure O365SetupWorkflow()
    var
        Customer: Record Customer;
        Dimension: Record Dimension;
        Workflow: Record Workflow;
        WorkflowTableRelation: Record "Workflow - Table Relation";
        WorkflowStepArgument: Record "Workflow Step Argument";
        NotificationSetup: Record "Notification Setup";
        WFEventResponseCombination: Record "WF Event/Response Combination";
    begin
        LibraryLowerPermissions.SetO365Setup();
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        LibraryDimension.CreateDimension(Dimension);

        LibraryWorkflow.CreateWorkflowCategory();
        LibraryWorkflow.CreateTemplateWorkflow(Workflow);
        LibraryWorkflow.CreateWorkflow(Workflow);
        LibraryWorkflow.CreateWorkflowTableRelation(
          WorkflowTableRelation, DATABASE::Workflow, Workflow.FieldNo(Code), DATABASE::Customer, Customer.FieldNo("No."));
        LibraryWorkflow.CreateWorkflowStepArgument(WorkflowStepArgument, WorkflowStepArgument.Type::Response, UserId, '', '', "Workflow Approver Type"::"Salesperson/Purchaser", true);
        LibraryWorkflow.CreateNotificationSetup(
          NotificationSetup, UserId, NotificationSetup."Notification Type"::Approval, NotificationSetup."Notification Method"::Email);
        LibraryWorkflow.CreateDynamicRequestPageEntity(
          LibraryUtility.GenerateGUID(), DATABASE::"Purchase Header", DATABASE::"Purchase Line");
        LibraryWorkflow.CreateDynamicRequestPageField(DATABASE::Dimension, Dimension.FieldNo(Code));
        LibraryWorkflow.CreatePredecessor(WFEventResponseCombination.Type::"Event", CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10),
          WFEventResponseCombination."Predecessor Type"::"Event", CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10));
        LibraryWorkflow.CreateEventPredecessor(
          CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10), CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10));
        LibraryWorkflow.CreateResponsePredecessor(
          CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10), CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure O365SetupFixedAssets()
    var
        DepreciationBook: Record "Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASubclass: Record "FA Subclass";
        FAJournalSetup: Record "FA Journal Setup";
        Maintenance: Record Maintenance;
        DepreciationTableHeader: Record "Depreciation Table Header";
        InsuranceType: Record "Insurance Type";
        FAJournalTemplate: Record "FA Journal Template";
    begin
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddO365FASetup();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFASubclass(FASubclass);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        LibraryFixedAsset.CreateMaintenance(Maintenance);
        LibraryFixedAsset.CreateDepreciationTableHeader(DepreciationTableHeader);
        LibraryFixedAsset.CreateInsuranceType(InsuranceType);
        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure O365FullTimeSheetArchive()
    var
        TimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        TimeSheetLineArchive: Record "Time Sheet Line Archive";
    begin
        LibraryLowerPermissions.SetO365Full();

        TimeSheetHeaderArchive.Init();
        TimeSheetHeaderArchive."No." :=
          LibraryUtility.GenerateRandomCode(TimeSheetHeaderArchive.FieldNo("No."), DATABASE::"Time Sheet Header Archive");
        TimeSheetHeaderArchive.Insert();

        TimeSheetLineArchive.Init();
        TimeSheetLineArchive."Time Sheet No." := TimeSheetHeaderArchive."No.";
        TimeSheetLineArchive."Line No." := 10000;
        TimeSheetLineArchive.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure O365BasicTimeSheetArchive()
    var
        TimeSheetHeaderArchive: Record "Time Sheet Header Archive";
        TimeSheetLineArchive: Record "Time Sheet Line Archive";
    begin
        TimeSheetHeaderArchive.Init();
        TimeSheetHeaderArchive."No." :=
          LibraryUtility.GenerateRandomCode(TimeSheetHeaderArchive.FieldNo("No."), DATABASE::"Time Sheet Header Archive");
        TimeSheetHeaderArchive.Insert();

        TimeSheetLineArchive.Init();
        TimeSheetLineArchive."Time Sheet No." := TimeSheetHeaderArchive."No.";
        TimeSheetLineArchive."Line No." := 10000;
        TimeSheetLineArchive.Insert();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddO365Basic();

        // Verify read permissions
        TimeSheetLineArchive.Find();
        TimeSheetLineArchive.Find();
    end;
}

