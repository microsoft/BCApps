codeunit 139177 "Navigate to CRM from NAV Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [UI] [Hyperlink]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        ExpectedLinkEntity: Text;
        ExpectedLinkValue: Text;

    [Test]
    [HandlerFunctions('CRMHyperlinkHandler')]
    [Scope('OnPrem')]
    procedure TestNavigateToCRMAccountFromCustomerCard()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer Card]
        NavigateToCRMAccountHyperlinkFromNAV(HostPageName::CustomerCard);
    end;

    [Test]
    [HandlerFunctions('CRMHyperlinkHandler')]
    [Scope('OnPrem')]
    procedure TestNavigateToCRMAccountFromCustomerList()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer List]
        NavigateToCRMAccountHyperlinkFromNAV(HostPageName::CustomerList);
    end;

    [Test]
    [HandlerFunctions('CRMHyperlinkHandler')]
    [Scope('OnPrem')]
    procedure TestNavigateToCRMAccountFromFoundationCustomerCard()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer Card]
        LibraryApplicationArea.EnableFoundationSetup();
        NavigateToCRMAccountHyperlinkFromNAV(HostPageName::CustomerCard);
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('CRMHyperlinkHandler')]
    [Scope('OnPrem')]
    procedure TestNavigateToCRMAccountFromFoundationCustomerList()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer List]
        LibraryApplicationArea.EnableFoundationSetup();
        NavigateToCRMAccountHyperlinkFromNAV(HostPageName::CustomerList);
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('CRMHyperlinkHandler')]
    [Scope('OnPrem')]
    procedure TestNavigateToCRMTransactionCurrencyFromCurrencyCard()
    var
        CurrencyHostPageName: Option CurrencyCard,CurrencyList;
    begin
        // [FEATURE] [Currency Card]
        NavigateToCRMTransactionCurrencyFromNAV(CurrencyHostPageName::CurrencyCard);
    end;

    [Test]
    [HandlerFunctions('CRMHyperlinkHandler')]
    [Scope('OnPrem')]
    procedure TestNavigateToCRMTransactionCurrencyFromCurrencyList()
    var
        CurrencyHostPageName: Option CurrencyCard,CurrencyList;
    begin
        // [FEATURE] [Currency List]
        NavigateToCRMTransactionCurrencyFromNAV(CurrencyHostPageName::CurrencyList);
    end;

    [Test]
    [HandlerFunctions('CRMHyperlinkHandler')]
    [Scope('OnPrem')]
    procedure TestNavigateToCRMCaseFromCaseList()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIncident: Record "CRM Incident";
        CRMCaseList: TestPage "CRM Case List";
    begin
        // [FEATURE] [Case]
        // [SCENARIO] Navigate to CRM Case hyperlink from NAV CRM Cases page
        Initialize();

        // [GIVEN] CRM is enabled, coupled customer and account with one CRM Case exist
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMIncident.Get(LibraryCRMIntegration.AddCRMCaseToCRMAccount(CRMAccount));

        // [WHEN] The user clicks on the Case action on the NAV CRM Cases page
        CRMCaseList.OpenView();
        CRMCaseList.FILTER.SetFilter(Title, CRMIncident.Title);
        ExpectedLinkEntity := 'incident';
        ExpectedLinkValue := Format(CRMIncident.IncidentId);
        CRMCaseList.CRMGoToCase.Invoke();

        // [THEN] A hyperlink to CRM is opened (validated in CRMHyperlinkHandler)
    end;

    [Test]
    [HandlerFunctions('CRMHyperlinkHandler')]
    [Scope('OnPrem')]
    procedure TestNavigateToCRMOpportunityFromOpportunitiesList()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMOpportunity: Record "CRM Opportunity";
        CRMOpportunityList: TestPage "CRM Opportunity List";
    begin
        // [FEATURE] [Opportunity]
        // [SCENARIO] Navigate to CRM Opportunity hyperlink from NAV CRM Opportunities page
        Initialize();

        // [GIVEN] CRM is enabled, coupled customer and account with one CRM Opportunity exist
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMOpportunity.Get(LibraryCRMIntegration.AddCRMOpportunityToCRMAccount(CRMAccount));

        // [WHEN] The user clicks on the Oppotunity action on the NAV CRM Opportunities page
        CRMOpportunityList.OpenView();
        CRMOpportunityList.FILTER.SetFilter(TotalAmount, Format(CRMOpportunity.TotalAmount));
        ExpectedLinkEntity := 'opportunity';
        ExpectedLinkValue := Format(CRMOpportunity.OpportunityId);
        CRMOpportunityList.CRMGotoOpportunities.Invoke();

        // [THEN] A hyperlink to CRM is opened (validated in CRMHyperlinkHandler)
    end;

    [Test]
    [HandlerFunctions('CRMHyperlinkHandler')]
    [Scope('OnPrem')]
    procedure TestNavigateToCRMQuoteFromQuotesList()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMQuote: Record "CRM Quote";
        CRMQuoteList: TestPage "CRM Sales Quote List";
    begin
        // [FEATURE] [Quote]
        // [SCENARIO] Navigate to CRM Quote hyperlink from NAV CRM Quotes page
        Initialize();

        // [GIVEN] CRM is enabled, coupled customer and account with one CRM Quote exist
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMQuote.Get(LibraryCRMIntegration.AddCRMQuoteToCRMAccount(CRMAccount));

        // [WHEN] The user clicks on the Quote action on the NAV CRM Quotes page
        CRMQuoteList.OpenView();
        CRMQuoteList.FILTER.SetFilter(Name, CRMQuote.Name);
        ExpectedLinkEntity := 'quote';
        ExpectedLinkValue := Format(CRMQuote.QuoteId);
        CRMQuoteList.CRMGoToQuote.Invoke();

        // [THEN] A hyperlink to CRM is opened (validated in CRMHyperlinkHandler)
    end;

    [Test]
    [HandlerFunctions('CRMHyperlinkHandler')]
    [Scope('OnPrem')]
    procedure TestNavigateToCRMSalesOrderFromSalesOrderList()
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesOrderList: TestPage "CRM Sales Order List";
    begin
        // [FEATURE] [Sales Order]
        // [SCENARIO] Navigate to CRM Sales Order hyperlink from NAV CRM Sales Order page
        Initialize();

        // [GIVEN] CRM is enabled, a record exists in table CRM Salesorder
        LibraryCRMIntegration.CreateCRMSalesOrder(CRMSalesorder);
        // [GIVEN] CRM Salesorder is submitted
        CRMSalesorder.StateCode := CRMSalesorder.StateCode::Submitted;
        // [GIVEN] CRM Salesorder has not been submitted to backoffice.
        Clear(CRMSalesorder.LastBackofficeSubmit);
        CRMSalesorder.Modify();

        // [WHEN] The user clicks on the CRM SalesOrder action on the NAV CRM Sales Orders page
        CRMSalesOrderList.OpenView();
        CRMSalesOrderList.FILTER.SetFilter(Name, CRMSalesorder.Name);
        ExpectedLinkEntity := 'salesorder';
        ExpectedLinkValue := Format(CRMSalesorder.SalesOrderId);
        CRMSalesOrderList.CRMGoToSalesOrder.Invoke();

        // [THEN] A hyperlink to CRM is opened (validated in CRMHyperlinkHandler)
    end;

    local procedure NavigateToCRMAccountHyperlinkFromNAV(HostPageName: Option CustomerCard,CustomerList)
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // Navigate to CRM Account hyperlink from NAV pages
        Initialize();

        // [GIVEN] CRM is enabled, coupled customer and account exist
        LibraryCRMIntegration.CreateIntegrationTableMappingCustomer(IntegrationTableMapping);
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [WHEN] The user clicks on the CRM Account link in nav customer card/list pages
        ExpectedLinkEntity := 'account';
        ExpectedLinkValue := Format(CRMAccount.AccountId);
        LibraryCRMIntegration.OpenCRMAccountHyperLinkOnHostPage(HostPageName, Customer."No.");

        // [THEN] A hyperlink to CRM is opened (validated in CRMHyperlinkHandler)
    end;

    local procedure NavigateToCRMTransactionCurrencyFromNAV(CurrencyHostPageName: Option CurrencyCard,CurrencyList)
    var
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // Navigate to CRM Transaction Currency hyperlink from NAV pages
        Initialize();

        // [GIVEN] CRM is enabled, a coupled NAV Currency and CRM TransactionCurrency exists
        LibraryCRMIntegration.CreateIntegrationTableMappingCurrency(IntegrationTableMapping);
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);

        // [WHEN] The user clicks on the Transaction Currency link in nav currency card/list pages
        ExpectedLinkEntity := 'transactioncurrency';
        ExpectedLinkValue := Format(CRMTransactioncurrency.TransactionCurrencyId);
        LibraryCRMIntegration.OpenCRMTransactionCurrencyHyperLinkOnHostPage(CurrencyHostPageName, Currency.Code);

        // [THEN] A hyperlink to CRM is opened (validated in CRMHyperlinkHandler)
    end;

    local procedure AssertLinkContainsWord(Link: Text; Word: Text): Boolean
    begin
        exit(StrPos(Link, Word) <> 0);
    end;

    local procedure Initialize()
    begin
        ExpectedLinkEntity := '';
        ExpectedLinkValue := '';

        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
    end;

    [HyperlinkHandler]
    [Scope('OnPrem')]
    procedure CRMHyperlinkHandler(LinkAddress: Text)
    begin
        Assert.AreNotEqual('', LinkAddress, 'Did not expect the hyperlink to be empty');
        if ExpectedLinkEntity <> '' then
            AssertLinkContainsWord(LinkAddress, ExpectedLinkEntity);
        if ExpectedLinkValue <> '' then
            AssertLinkContainsWord(LinkAddress, ExpectedLinkValue);
    end;
}
