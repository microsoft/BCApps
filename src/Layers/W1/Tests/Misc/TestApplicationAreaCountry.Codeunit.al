codeunit 139099 "Test ApplicationArea Country"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Application Area]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CountryAppAreaConfiguration()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        // [SCENARIO 290518] Applicatiomn Area Setup is set per country
        Initialize();

        // [GIVEN] Enable Basic user experience
        LibraryApplicationArea.EnableFoundationSetup();

        // [WHEN] Get application area setup
        ApplicationAreaMgmtFacade.GetApplicationAreaSetupRecFromCompany(ApplicationAreaSetup, CompanyName);

        // [THEN] Verify application area setup: "Basic EU" is 'Yes', VAT is 'Yes, "Sales Tax' is 'No'
        Assert.IsTrue(ApplicationAreaSetup."Basic EU", 'Application Area #BasicEU should be TRUE.');
        Assert.IsFalse(ApplicationAreaSetup."Sales Tax", 'Application Area #SalesTax should be FALSE.');
        Assert.IsTrue(ApplicationAreaSetup.VAT, 'Application Area #VAT should be TRUE.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SessionApplicationAreaStartsUnrestricted()
    var
        ChangeStatus: TestPage "Change Status on Prod. Order";
    begin
        Assert.AreEqual('', ApplicationArea(), 'Each test must start with unrestricted application areas.');
        ChangeStatus.OpenView();
        Assert.AreNotEqual('', ChangeStatus.FirmPlannedStatus.Caption(), 'Manufacturing fields must be available to tests.');
        ChangeStatus.Close();

        ApplicationArea('#Basic');
        Assert.AreEqual('#Basic', ApplicationArea(), 'Tests must still be able to restrict application areas.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SessionApplicationAreaDoesNotLeakBetweenTests()
    var
        Routing: TestPage Routing;
    begin
        Assert.AreEqual('', ApplicationArea(), 'A previous test must not restrict application areas for this test.');
        Routing.OpenView();
        Assert.IsTrue(Routing.RoutingLine.Visible(), 'Manufacturing page parts must be available to tests.');
        Assert.IsTrue(Routing."Co&mments".Enabled(), 'Manufacturing actions must be available to tests.');
        Routing.Close();

        ApplicationArea('#Manufacturing');
        Assert.AreEqual('#Manufacturing', ApplicationArea(), 'Tests must still be able to restrict application areas.');
    end;

    [TestDataSource(Codeunit::"Application Area Test Cases", 'ApplicationArea')]
    [Scope('OnPrem')]
    procedure SessionApplicationAreaDoesNotLeakBetweenCases(Context: Interface ITestContext)
    var
        ChangeStatus: TestPage "Change Status on Prod. Order";
    begin
        Assert.AreEqual('', ApplicationArea(), 'Each data-driven test case must start with unrestricted application areas.');
        ChangeStatus.OpenView();
        Assert.AreNotEqual('', ChangeStatus.FirmPlannedStatus.Caption(), 'Manufacturing fields must be available to each test case.');
        ChangeStatus.Close();

        ApplicationArea('#Basic');
        Assert.AreEqual('#Basic', ApplicationArea(), 'Test cases must still be able to restrict application areas.');
    end;

    local procedure Initialize()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
    begin
        LibraryApplicationArea.DisableApplicationAreaSetup();
        ExperienceTierSetup.DeleteAll(true);
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.AssertEmpty();

        if IsInitialized then
            exit;

        Commit();

        LibrarySetupStorage.Save(DATABASE::"Company Information");

        IsInitialized := true;
    end;
}

