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

