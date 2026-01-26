codeunit 144057 "CFDI Customer Consent Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    trigger OnRun()
    begin
        // [FEATURE] [Customer Consent]
    end;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseNoModalPageHandler')]
    [Scope('OnPrem')]
    procedure ConsentNotConfirmedTestEnvWhenChooseNo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 407179] Stan cannot enable the CFDI feature without confirming the user consent
        Initialize();
        GeneralLedgerSetup.Validate("CFDI Enabled", true);
        GeneralLedgerSetup.Validate("CFDI Enabled", false);
    end;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseYesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ConsentConfirmedProdEnvWhenChooseYes()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 407179] Stan can enable the CFDI feature without confirming the user consent
        Initialize();
        GeneralLedgerSetup.Validate("CFDI Enabled", true);
        GeneralLedgerSetup.Validate("CFDI Enabled", true);
    end;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseNoModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WizardSetupNotCompletedWithoutConsent()
    var
        MexicanCFDIWizardPage: TestPage "Mexican CFDI Wizard";
        i: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 407179] Stan cannot complete the CFDI Wizard Setup without confirming the user consent
        Initialize();
        UpdateCompanyInformationWithCFDI();
        MexicanCFDIWizardPage.OpenEdit();
        For i := 1 to 8 do
            MexicanCFDIWizardPage.ActionNext.Invoke();
        Assert.IsFalse(MexicanCFDIWizardPage.ActionFinish.Enabled(), '');
    end;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseYesModalPageHandler')]
    [Scope('OnPrem')]
    procedure WizardSetupCompletedWithConsent()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        MexicanCFDIWizardPage: TestPage "Mexican CFDI Wizard";
        i: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 407179] Stan can complete the CFDI Wizard Setup without confirming the user consent
        Initialize();
        UpdateCompanyInformationWithCFDI();
        MexicanCFDIWizardPage.OpenEdit();
        For i := 1 to 8 do
            MexicanCFDIWizardPage.ActionNext.Invoke();
        MexicanCFDIWizardPage.ActionFinish.Invoke();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("CFDI Enabled", true);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        IsInitialized := true;
        Commit();
    end;

    local procedure UpdateCompanyInformationWithCFDI()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("SAT Postal Code", Format(LibraryRandom.RandIntInRange(10000, 99999)));
        CompanyInformation."SAT Tax Regime Classification" :=
          LibraryUtility.GenerateRandomCode(
            CompanyInformation.FieldNo("SAT Tax Regime Classification"), DATABASE::"Company Information");
        CompanyInformation.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerConsentConfirmationPageChooseNoModalPageHandler(var CustConsentConfPage: TestPage "Cust. Consent Confirmation")
    begin
        CustConsentConfPage.Cancel.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerConsentConfirmationPageChooseYesModalPageHandler(var CustConsentConfPage: TestPage "Cust. Consent Confirmation")
    begin
        CustConsentConfPage.Accept.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}