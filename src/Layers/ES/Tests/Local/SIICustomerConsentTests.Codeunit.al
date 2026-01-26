codeunit 147594 "SII Customer Consent Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Customer Consent]
    end;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseNoModalPageHandler')]
    [Scope('OnPrem')]
    procedure ConsentNotConfirmedWhenChooseNo()
    var
        SIISetup: Record "SII Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 407179] Stan cannot enable SII feature without confirming the customer consent
        InitSIISetup(SIISetup);
        SIISetup.Validate(Enabled, true);
        SIISetup.TestField(Enabled, false);
    end;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseYesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ConsentNotConfirmedWhenChooseYes()
    var
        SIISetup: Record "SII Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 407179] Stan cann enable SII feature with confirming the customer consent
        InitSIISetup(SIISetup);
        SIISetup.Validate(Enabled, true);
        SIISetup.TestField(Enabled, true);
    end;

    local procedure InitSIISetup(var SIISetup: Record "SII Setup")
    var
        IsolatedCertificate: Record "Isolated Certificate";
    begin
        IsolatedCertificate.Init();
        IsolatedCertificate.Insert(true);
        SIISetup."Certificate Code" := IsolatedCertificate.Code;
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
}