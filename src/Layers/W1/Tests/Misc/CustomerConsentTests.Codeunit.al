codeunit 134960 "Customer Consent Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Customer Consent]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseNoModalPageHandler')]
    [Scope('OnPrem')]
    procedure ConsentNotConfirmedWhenChooseNo()
    var
        CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 407179] The ConfirmUserConsent function of the "Customer Consent Mgt." codeunit returns false if user choose No in the "Cust. Consent Confirmation" page
        Assert.IsFalse(CustomerConsentMgt.ConfirmUserConsent(), '');
    end;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseYesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ConsentConfirmedWhenChooseYes()
    var
        CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 407179] The ConfirmUserConsent function of the "Customer Consent Mgt." codeunit returns true if user choose Yes in the "Cust. Consent Confirmation" page
        Assert.IsTrue(CustomerConsentMgt.ConfirmUserConsent(), '');
    end;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseNoModalPageHandler')]
    [Scope('OnPrem')]
    procedure DocExchServiceNotEnabledWithoutConsent()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        // [FEATURE] [UT] [Document Exchange Service]
        // [SCENARIO 407179] Stan cannot enable the Document Exchange Service without confirming customer consent
        DocExchServiceSetup.Validate(Enabled, true);
        DocExchServiceSetup.TestField(Enabled, false);
    end;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseYesModalPageHandler')]
    [Scope('OnPrem')]
    procedure DocExchServiceEnabledWithConsent()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        // [FEATURE] [UT] [Document Exchange Service]
        // [SCENARIO 407179] Stan cann enable the Document Exchange Service without confirming customer consent
        DocExchServiceSetup.Validate(Enabled, true);
        DocExchServiceSetup.TestField(Enabled, true);
    end;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseNoModalPageHandler')]
    [Scope('OnPrem')]
    procedure VATRegValidationServiceSetupNotEnabledWithoutConsent()
    var
        VATRegistrationConfigPage: TestPage "VAT Registration Config";
    begin
        // [FEATURE] [UT] [VAT Registration No.]
        // [SCENARIO 407179] Stan cannot enable the VAT Registration Validation Service without confirming customer consent
        VATRegistrationConfigPage.OpenEdit();
        VATRegistrationConfigPage.Enabled.SetValue(true);
        VATRegistrationConfigPage.Enabled.AssertEquals(false);
    end;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseYesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VATRegValidationServiceSetupEnabledWithConsent()
    var
        VATRegistrationConfigPage: TestPage "VAT Registration Config";
    begin
        // [FEATURE] [UT] [VAT Registration No.]
        // [SCENARIO 407179] Stan cann enable the VAT Registration Validation Service without confirming customer consent
        VATRegistrationConfigPage.OpenEdit();
        VATRegistrationConfigPage.Enabled.SetValue(true);
        VATRegistrationConfigPage.Enabled.AssertEquals(true);
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

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}