codeunit 147595 "SII Endpoint Url Validation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SII] [Endpoint URL]
    end;

    var
        Assert: Codeunit Assert;
        InvalidEndpointUrlErr: Label 'The endpoint URL %1 is not on the allow-list for this feature.', Comment = '%1 = the URL entered by the user';

    [Test]
    [Scope('OnPrem')]
    procedure ValidateEndpointUrlAcceptsAEATBaseUrl()
    var
        SIISetup: Record "SII Setup";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 636975] The historical AEAT base URL is still accepted by ValidateEndpointUrl.
        SIISetup.ValidateEndpointUrl('https://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/fe/SiiFactFEV1SOAP');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateEndpointUrlAcceptsRegionalHttpsUrl()
    var
        SIISetup: Record "SII Setup";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 636975] After removing the AEAT shortlist, any valid HTTPS URL (e.g. a regional endpoint) is accepted.
        SIISetup.ValidateEndpointUrl('https://sii.gipuzkoa.eus/JBS/HTML/wlpl/SSII-FACT/ws/fe/SiiFactFEV1SOAP');
        SIISetup.ValidateEndpointUrl('https://www.bizkaia.eus/ogasuna/sii/ws/fe/SiiFactFEV1SOAP');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateEndpointUrlRejectsHttpUrl()
    var
        SIISetup: Record "SII Setup";
        NonHttpsUrl: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 636975] Non-HTTPS URLs are rejected.
        NonHttpsUrl := 'http://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/fe/SiiFactFEV1SOAP';
        asserterror SIISetup.ValidateEndpointUrl(NonHttpsUrl);
        Assert.ExpectedError(StrSubstNo(InvalidEndpointUrlErr, NonHttpsUrl));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateEndpointUrlRejectsMalformedUrl()
    var
        SIISetup: Record "SII Setup";
        MalformedUrl: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 636975] Malformed URLs are rejected.
        MalformedUrl := 'not a url';
        asserterror SIISetup.ValidateEndpointUrl(MalformedUrl);
        Assert.ExpectedError(StrSubstNo(InvalidEndpointUrlErr, MalformedUrl));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsAllowedEndpointUrlReturnsTrueForRegionalHttpsUrl()
    var
        SIISetup: Record "SII Setup";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 636975] IsAllowedEndpointUrl returns true for any well-formed HTTPS URL, not just AEAT hosts.
        Assert.IsTrue(
            SIISetup.IsAllowedEndpointUrl('https://sii.gipuzkoa.eus/JBS/HTML/wlpl/SSII-FACT/ws/fe/SiiFactFEV1SOAP'),
            'Regional HTTPS endpoint URL should be allowed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsAllowedEndpointUrlReturnsFalseForHttpUrl()
    var
        SIISetup: Record "SII Setup";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 636975] IsAllowedEndpointUrl returns false for non-HTTPS URLs.
        Assert.IsFalse(
            SIISetup.IsAllowedEndpointUrl('http://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/fe/SiiFactFEV1SOAP'),
            'Non-HTTPS endpoint URL should not be allowed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateOnSetupAcceptsRegionalHttpsUrl()
    var
        SIISetup: Record "SII Setup";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 636975] Validating an endpoint field on the SII Setup record with a regional HTTPS URL succeeds.
        if not SIISetup.Get() then begin
            SIISetup.Init();
            SIISetup.Insert();
        end;
        SIISetup.Validate(InvoicesIssuedEndpointUrl, 'https://sii.gipuzkoa.eus/JBS/HTML/wlpl/SSII-FACT/ws/fe/SiiFactFEV1SOAP');
        SIISetup.TestField(InvoicesIssuedEndpointUrl, 'https://sii.gipuzkoa.eus/JBS/HTML/wlpl/SSII-FACT/ws/fe/SiiFactFEV1SOAP');
    end;
}
