codeunit 139176 "CRM Statistics FactBox Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [UI] [CRM Statistics FactBox]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibrarySales: Codeunit "Library - Sales";
        LibraryApplicationArea: Codeunit "Library - Application Area";

    [Test]
    [Scope('OnPrem')]
    procedure CRMCasesFromCRMStatisticsFactBoxCustomerList()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer List] [Case]
        OpenCRMCasesFromCRMStatisticsFactBox(HostPageName::CustomerList);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMOpportunitiesFromCRMStatisticsFactBoxCustomerList()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer List] [Opportunity]
        OpenCRMOpportunitiesFromCRMStatisticsFactBox(HostPageName::CustomerList);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMQuotesFromCRMStatisticsFactBoxCustomerList()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer List] [Quote]
        OpenCRMQuotesFromCRMStatisticsFactBox(HostPageName::CustomerList);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMCasesFromCRMStatisticsFactBoxCustomerCard()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer Card] [Case]
        OpenCRMCasesFromCRMStatisticsFactBox(HostPageName::CustomerCard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMOpportunitiesFromCRMStatisticsFactBoxCustomerCard()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer Card] [Opportunity]
        OpenCRMOpportunitiesFromCRMStatisticsFactBox(HostPageName::CustomerCard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMQuotesFromCRMStatisticsFactBoxCustomerCard()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer Card] [Quote]
        OpenCRMQuotesFromCRMStatisticsFactBox(HostPageName::CustomerCard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMCasesFromCRMStatisticsFactBoxFoundationCustomerList()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer List] [Case]
        LibraryApplicationArea.EnableFoundationSetup();
        OpenCRMCasesFromCRMStatisticsFactBox(HostPageName::CustomerList);
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMOpportunitiesFromCRMStatisticsFactBoxFoundationCustomerList()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer List] [Opportunity]
        LibraryApplicationArea.EnableFoundationSetup();
        OpenCRMOpportunitiesFromCRMStatisticsFactBox(HostPageName::CustomerList);
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMQuotesFromCRMStatisticsFactBoxFoundationCustomerList()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer List] [Quote]
        LibraryApplicationArea.EnableFoundationSetup();
        OpenCRMQuotesFromCRMStatisticsFactBox(HostPageName::CustomerList);
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMCasesFromCRMStatisticsFactBoxFoundationCustomerCard()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer Card] [Case]
        LibraryApplicationArea.EnableFoundationSetup();
        OpenCRMCasesFromCRMStatisticsFactBox(HostPageName::CustomerCard);
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMOpportunitiesFromCRMStatisticsFactBoxFoundationCustomerCard()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer Card] [Opportunity]
        LibraryApplicationArea.EnableFoundationSetup();
        OpenCRMOpportunitiesFromCRMStatisticsFactBox(HostPageName::CustomerCard);
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMQuotesFromCRMStatisticsFactBoxFoundationCustomerCard()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer Card] [Quote]
        LibraryApplicationArea.EnableFoundationSetup();
        OpenCRMQuotesFromCRMStatisticsFactBox(HostPageName::CustomerCard);
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMStatisticsFactBoxNotVisibleOnCustomerCard()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer Card]
        CRMStatisticsFactBoxNotVisibleOnHostPage(HostPageName::CustomerCard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMStatisticsFactBoxNotVisibleOnCustomerList()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer List]
        CRMStatisticsFactBoxNotVisibleOnHostPage(HostPageName::CustomerList);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMStatisticsFactBoxNotVisibleOnFoundationCustomerCard()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer Card]
        LibraryApplicationArea.EnableFoundationSetup();
        CRMStatisticsFactBoxNotVisibleOnHostPage(HostPageName::CustomerCard);
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMStatisticsFactBoxNotVisibleOnFoundationCustomerList()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer List]
        LibraryApplicationArea.EnableFoundationSetup();
        CRMStatisticsFactBoxNotVisibleOnHostPage(HostPageName::CustomerList);
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMStatisticsFactBoxNotVisibleOnCustomerCardNoCRM()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer Card]
        CRMStatisticsFactBoxNotVisibleWhenCRMDisabled(HostPageName::CustomerCard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMStatisticsFactBoxNotVisibleOnCustomerListNoCRM()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer List]
        CRMStatisticsFactBoxNotVisibleWhenCRMDisabled(HostPageName::CustomerList);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMStatisticsFactBoxNotVisibleOnFoundationCustomerCardNoCRM()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer Card]
        LibraryApplicationArea.EnableFoundationSetup();
        CRMStatisticsFactBoxNotVisibleWhenCRMDisabled(HostPageName::CustomerCard);
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMStatisticsFactBoxNotVisibleOnFoundationCustomerListNoCRM()
    var
        HostPageName: Option CustomerCard,CustomerList,MiniCustomerCard,MiniCustomerList;
    begin
        // [FEATURE] [Customer List]
        LibraryApplicationArea.EnableFoundationSetup();
        CRMStatisticsFactBoxNotVisibleWhenCRMDisabled(HostPageName::CustomerList);
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    local procedure CRMStatisticsFactBoxNotVisibleOnHostPage(HostPageName: Option CustomerCard,CustomerList)
    var
        Customer: Record Customer;
    begin
        LibraryCRMIntegration.ResetEnvironment();
        // [SCENARIO] The CRM Statistics FactBox is only visible when the customer has a CRM coupling
        // [GIVEN] No matter if the CRM is enabled globally
        LibraryCRMIntegration.ConfigureCRM();

        // [WHEN] The customer is not coupled in CRM
        LibrarySales.CreateCustomer(Customer);

        // [THEN] The CRM Statistics FactBox is not visible on the host page
        LibraryCRMIntegration.AssertVisibilityOnHostPage(HostPageName, Customer."No.", false);
    end;

    local procedure CRMStatisticsFactBoxNotVisibleWhenCRMDisabled(HostPageName: Option CustomerCard,CustomerList)
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        // [SCENARIO] The CRM Statistics FactBox is not visible when the customer has a CRM coupling, but CRM is disabled
        // [GIVEN] A customer having a CRM Coupling
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [WHEN] The CRM integration is disabled from CRM Connection Setup
        CRMConnectionSetup.Get();
        CRMConnectionSetup.Validate("Is Enabled", false);
        CRMConnectionSetup.Modify();

        // [THEN] The CRM Statistics FactBox is not visible on the host page
        LibraryCRMIntegration.AssertVisibilityOnHostPage(HostPageName, Customer."No.", false);
    end;

    local procedure OpenCRMCasesFromCRMStatisticsFactBox(HostPageName: Option CustomerCard,CustomerList)
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIncident: Record "CRM Incident";
        CRMCaseList: TestPage "CRM Case List";
        LinkedPageName: Option Cases,Opportunities,Quotes;
        CaseCounter: Integer;
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        // [SCENARIO] Open the CRM Opportunities list page from the CRM Statistics FactBox on the Customer List
        // [GIVEN] CRM is enabled, coupled customer and account with cases exist
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        // [GIVEN] Two active, one canceled and one resolved case are associated with the account
        LibraryCRMIntegration.AddCRMCaseWithStatusToCRMAccount(CRMAccount, CRMIncident.StateCode::Canceled);
        LibraryCRMIntegration.AddCRMCaseWithStatusToCRMAccount(CRMAccount, CRMIncident.StateCode::Resolved);
        LibraryCRMIntegration.AddCRMCaseWithStatusToCRMAccount(CRMAccount, CRMIncident.StateCode::Active);
        CRMIncident.Get(LibraryCRMIntegration.AddCRMCaseToCRMAccount(CRMAccount));
        CRMCaseList.Trap();

        // [WHEN] The user clicks on the CRM Cases link in the CRM Statistics FactBox
        LibraryCRMIntegration.OpenNAVLinkOnHostPage(HostPageName, LinkedPageName::Cases, Customer."No.");

        // [THEN] The CRM Statistics FactBox is visible
        LibraryCRMIntegration.AssertVisibilityOnHostPage(HostPageName, Customer."No.", true);
        // [THEN] The page filters out canceled and resolved cases, so there is a single record on the page
        CaseCounter := 0;
        repeat
            CaseCounter += 1;
        until CRMCaseList.Next() = false;
        Assert.AreEqual(2, CaseCounter, 'Incorrect number of CRM Cases');

        // [THEN] The CRM Cases list page opens and it contains the correct information on the line
        Assert.AreEqual(CRMIncident.Title, CRMCaseList.Title.Value, 'Unexpected CRMIncident title');
    end;

    local procedure OpenCRMOpportunitiesFromCRMStatisticsFactBox(HostPageName: Option CustomerCard,CustomerList)
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMOpportunity: Record "CRM Opportunity";
        CRMOpportunityList: TestPage "CRM Opportunity List";
        LinkedPageName: Option Cases,Opportunities,Quotes;
        OpportunityCounter: Integer;
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        // [SCENARIO] Open the CRM Opportunities list page from the CRM Statistics FactBox on the Customer List
        // [GIVEN] CRM is enabled, coupled customer and account with opportunities exist
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.AddCRMOpportunityWithStatusToCRMAccount(CRMAccount, CRMOpportunity.StateCode::Lost);
        LibraryCRMIntegration.AddCRMOpportunityWithStatusToCRMAccount(CRMAccount, CRMOpportunity.StateCode::Won);
        LibraryCRMIntegration.AddCRMOpportunityWithStatusToCRMAccount(CRMAccount, CRMOpportunity.StateCode::Open);
        CRMOpportunity.Get(LibraryCRMIntegration.AddCRMOpportunityToCRMAccount(CRMAccount));
        CRMOpportunityList.Trap();

        // [WHEN] The user clicks on the CRM Opportunities link in the CRM Statistics FactBox
        LibraryCRMIntegration.OpenNAVLinkOnHostPage(HostPageName, LinkedPageName::Opportunities, Customer."No.");

        // [THEN] The CRM Statistics FactBox is visible
        LibraryCRMIntegration.AssertVisibilityOnHostPage(HostPageName, Customer."No.", true);
        // [THEN] The lost and won opportunities are filtered out from the list
        OpportunityCounter := 0;
        repeat
            OpportunityCounter += 1;
        until CRMOpportunityList.Next() = false;
        Assert.AreEqual(2, OpportunityCounter, 'Incorrect number of CRM opportunities');

        // [THEN] The CRM Opportunities list page opens and it contains the correct information on the line
        Assert.AreEqual(CRMOpportunity.Name, CRMOpportunityList.Name.Value, 'Unexpected CRMOpportunity name');
    end;

    local procedure OpenCRMQuotesFromCRMStatisticsFactBox(HostPageName: Option CustomerCard,CustomerList)
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMQuote: Record "CRM Quote";
        CRMQuoteList: TestPage "CRM Sales Quote List";
        LinkedPageName: Option Cases,Opportunities,Quotes;
        QuoteCounter: Integer;
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        // [SCENARIO] Open the CRM Opportunities list page from the CRM Statistics FactBox on the Customer List
        // [GIVEN] CRM is enabled, coupled customer and account with opportunities exist
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.AddCRMQuoteWithStatusToCRMAccount(CRMAccount, CRMQuote.StateCode::Closed);
        LibraryCRMIntegration.AddCRMQuoteWithStatusToCRMAccount(CRMAccount, CRMQuote.StateCode::Draft);
        LibraryCRMIntegration.AddCRMQuoteWithStatusToCRMAccount(CRMAccount, CRMQuote.StateCode::Won);
        LibraryCRMIntegration.AddCRMQuoteWithStatusToCRMAccount(CRMAccount, CRMQuote.StateCode::Active);
        CRMQuote.Get(LibraryCRMIntegration.AddCRMQuoteToCRMAccount(CRMAccount));
        CRMQuoteList.Trap();

        // [WHEN] The user clicks on the CRM Quotes link in the CRM Statistics FactBox
        LibraryCRMIntegration.OpenNAVLinkOnHostPage(HostPageName, LinkedPageName::Quotes, Customer."No.");

        // [THEN] The CRM Statistics FactBox is visible
        LibraryCRMIntegration.AssertVisibilityOnHostPage(HostPageName, Customer."No.", true);

        // [THEN] The closed, draft quotes are filtered out
        QuoteCounter := 0;
        repeat
            QuoteCounter += 1;
        until CRMQuoteList.Next() = false;
        Assert.AreEqual(3, QuoteCounter, 'Incorrect number of CRM Quotes');

        // [THEN] The CRM Quotes list page opens and it contains the correct information on the line
        Assert.AreEqual(CRMQuote.Name, CRMQuoteList.Name.Value, 'Unexpected CRMQuote name');
    end;
}

