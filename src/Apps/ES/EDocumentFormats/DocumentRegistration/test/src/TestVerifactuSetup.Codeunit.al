// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Verifactu.Test;

using Microsoft.EServices.EDocument;
using Microsoft.EServices.EDocument.Verifactu;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using System.Privacy;
using System.Security.Encryption;
using System.Text;
using System.Utilities;

codeunit 148003 "Test Verifactu Setup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        DisableSIIQst: Label 'SII setup will be disabled. Do you want to proceed?';
        DisableVerifactuQst: Label 'Verifactu setup will be disabled. Do you want to proceed?';
        // Hex-encoded DER building blocks. The tests assemble minimal certificate structures from them (no keys, names or signatures),
        // because seal detection only reads the QcStatements and CertificatePolicies extensions.
#pragma warning disable AA0240 // DER-encoded bytes, not phone numbers
        QcStatementsExtensionOidTok: Label '06082B06010505070103', Locked = true;
        CertificatePoliciesExtensionOidTok: Label '0603551D20', Locked = true;
        SubjectAltNameExtensionOidTok: Label '0603551D11', Locked = true;
        ExtendedKeyUsageExtensionOidTok: Label '0603551D25', Locked = true;
        ExtendedKeyUsageClientAuthTok: Label '300A06082B06010505070302', Locked = true;
        QcComplianceStatementTok: Label '3008060604008E460101', Locked = true;
        QcTypeStatementOidTok: Label '060604008E460106', Locked = true;
        QcTypeESealOidTok: Label '060704008E46010602', Locked = true;
        QcTypeESignOidTok: Label '060704008E46010601', Locked = true;
        PolicyQcpLegalQscdOidTok: Label '060704008BEC400103', Locked = true;
        PolicyQcpNaturalQscdOidTok: Label '060704008BEC400102', Locked = true;
#pragma warning restore AA0240
        SerialNumberTok: Label '020101', Locked = true;
        CriticalTok: Label '0101FF', Locked = true;
        SequenceTagTok: Label '30', Locked = true;
        OctetStringTagTok: Label '04', Locked = true;
        ExtensionsTagTok: Label 'A3', Locked = true;
        HexDigitsTok: Label '0123456789ABCDEF', Locked = true;

    [Test]
    procedure SealCertificateDetectedByESealQcType()
    var
        DocRegistrationCertMgt: Codeunit "Doc. Registration Cert. Mgt.";
        CertificateHex: Text;
    begin
        // [SCENARIO 656929] A certificate with the eIDAS QcType eSeal (0.4.0.1862.1.6.2) in its QcStatements extension is detected as an electronic seal certificate
        // [GIVEN] A certificate with a large unrelated extension (long-form DER lengths) followed by a QcStatements extension with QcType eSeal
        CertificateHex := CertificateWithExtensions(
            CertificateExtension(SubjectAltNameExtensionOidTok, PadStr('', 400, '0')) +
            CertificateExtension(QcStatementsExtensionOidTok, QcStatementsWithQcType(QcTypeESealOidTok)));

        // [THEN] It is detected as a seal certificate
        Assert.IsTrue(DocRegistrationCertMgt.IsSealCertificateData(HexToBase64(CertificateHex)), 'QcType eSeal certificate should be detected as seal certificate');
    end;

    [Test]
    procedure SealCertificateDetectedByQcpLegalPolicy()
    var
        DocRegistrationCertMgt: Codeunit "Doc. Registration Cert. Mgt.";
        CertificateHex: Text;
    begin
        // [SCENARIO 656929] A certificate with the legal person policy QCP-l-qscd (0.4.0.194112.1.3) is detected as an electronic seal certificate
        // [GIVEN] A certificate with a critical CertificatePolicies extension containing QCP-l-qscd
        CertificateHex := CertificateWithExtensions(
            DerElement(SequenceTagTok, CertificatePoliciesExtensionOidTok + CriticalTok + DerElement(OctetStringTagTok, CertificatePoliciesWith(PolicyQcpLegalQscdOidTok))));

        // [THEN] It is detected as a seal certificate
        Assert.IsTrue(DocRegistrationCertMgt.IsSealCertificateData(HexToBase64(CertificateHex)), 'QCP-l-qscd certificate should be detected as seal certificate');
    end;

    [Test]
    procedure RepresentativeCertificateNotDetectedAsSeal()
    var
        DocRegistrationCertMgt: Codeunit "Doc. Registration Cert. Mgt.";
        CertificateHex: Text;
    begin
        // [SCENARIO 656929] A representative certificate with QcType eSign (0.4.0.1862.1.6.1) and policy QCP-n-qscd (0.4.0.194112.1.2) is not a seal certificate
        CertificateHex := CertificateWithExtensions(
            CertificateExtension(QcStatementsExtensionOidTok, QcStatementsWithQcType(QcTypeESignOidTok)) +
            CertificateExtension(CertificatePoliciesExtensionOidTok, CertificatePoliciesWith(PolicyQcpNaturalQscdOidTok)));

        Assert.IsFalse(DocRegistrationCertMgt.IsSealCertificateData(HexToBase64(CertificateHex)), 'QcType eSign certificate should not be detected as seal certificate');
    end;

    [Test]
    procedure CertificateWithoutQcInformationNotDetectedAsSeal()
    var
        DocRegistrationCertMgt: Codeunit "Doc. Registration Cert. Mgt.";
    begin
        // [SCENARIO 656929] A certificate that does not identify itself as an electronic seal keeps using the standard endpoint
        // [GIVEN] A certificate without QcStatements or CertificatePolicies extensions
        // [THEN] It is not detected as a seal certificate
        Assert.IsFalse(
            DocRegistrationCertMgt.IsSealCertificateData(HexToBase64(CertificateWithExtensions(CertificateExtension(ExtendedKeyUsageExtensionOidTok, ExtendedKeyUsageClientAuthTok)))),
            'Certificate without eIDAS information should not be detected as seal certificate');
    end;

    [Test]
    procedure SealOidsOutsideQcExtensionsNotDetectedAsSeal()
    var
        DocRegistrationCertMgt: Codeunit "Doc. Registration Cert. Mgt.";
        CertificateHex: Text;
    begin
        // [SCENARIO 656929] The eSeal and QCP-l-qscd OIDs only count inside the QcStatements and CertificatePolicies extensions
        // [GIVEN] A certificate whose only extension is a subject alternative name that contains the eSeal and QCP-l-qscd OID bytes
        CertificateHex := CertificateWithExtensions(
            CertificateExtension(SubjectAltNameExtensionOidTok, DerElement(SequenceTagTok, QcTypeESealOidTok + PolicyQcpLegalQscdOidTok)));

        // [THEN] It is not detected as a seal certificate
        Assert.IsFalse(DocRegistrationCertMgt.IsSealCertificateData(HexToBase64(CertificateHex)), 'Seal OIDs outside the QcStatements and CertificatePolicies extensions should be ignored');
    end;

    [Test]
    procedure MalformedCertificateDataNotDetectedAsSeal()
    var
        DocRegistrationCertMgt: Codeunit "Doc. Registration Cert. Mgt.";
        CertificateHex: Text;
    begin
        // [SCENARIO 656929] Certificate data that cannot be parsed keeps using the standard endpoint
        // [GIVEN] A seal certificate structure that is truncated by two bytes
        CertificateHex := CertificateWithExtensions(CertificateExtension(QcStatementsExtensionOidTok, QcStatementsWithQcType(QcTypeESealOidTok)));
        CertificateHex := CopyStr(CertificateHex, 1, StrLen(CertificateHex) - 4);

        // [THEN] Neither the truncated data nor empty data is detected as a seal certificate
        Assert.IsFalse(DocRegistrationCertMgt.IsSealCertificateData(HexToBase64(CertificateHex)), 'Truncated certificate data should not be detected as seal certificate');
        Assert.IsFalse(DocRegistrationCertMgt.IsSealCertificateData(''), 'Empty certificate data should not be detected as seal certificate');
    end;

    [Test]
    procedure TryGetIsSealCertificateFailsWhenCertificateCannotBeRead()
    var
        IsolatedCertificate: Record "Isolated Certificate";
        DocRegistrationCertMgt: Codeunit "Doc. Registration Cert. Mgt.";
        IsSeal: Boolean;
    begin
        // [SCENARIO 656929] Detection does not fail when the certificate content is not available
        Initialize();

        // [GIVEN] Certificate "C" exists without stored certificate data
        // [WHEN] Detecting the certificate type of "C"
        // [THEN] Detection reports failure and the certificate is not treated as a seal certificate
        Assert.IsFalse(DocRegistrationCertMgt.TryGetIsSealCertificate(CreateCertificate(IsolatedCertificate), IsSeal), 'Detection should fail without certificate data');
        Assert.IsFalse(IsSeal, 'IsSeal should be false when detection fails');
    end;

    [Test]
    procedure DocumentSubmissionEndpointUrlDependsOnCertificateType()
    var
        VerifactuSetup: Record "Verifactu Setup";
    begin
        // [SCENARIO 656929] Seal certificates are sent to the AEAT www10 / prewww10 endpoint, other certificates to www1 / prewww1
        Assert.IsTrue(VerifactuSetup.GetDocumentSubmissionEndpointUrl(true).Contains('www10.'), 'Seal certificate should use the www10 endpoint');
        Assert.IsTrue(VerifactuSetup.GetDocumentSubmissionEndpointUrl(false).Contains('www1.'), 'Personal certificate should use the www1 endpoint');
        Assert.IsTrue(VerifactuSetup.GetDocumentSubmissionEndpointUrl(true).EndsWith('/wlpl/TIKE-CONT/ws/SistemaFacturacion/VerifactuSOAP'), 'Seal endpoint should point to the Verifactu SOAP service');
    end;

    [Test]
    procedure VerifactuSetupPageOpensAndInitializes()
    var
        VerifactuSetup: Record "Verifactu Setup";
    begin
        // [SCENARIO] Verifactu Setup page opens and initializes record with default values
        Initialize();

        // [GIVEN] Verifactu Setup table is empty
        VerifactuSetup.DeleteAll();

        // [WHEN] User opens Verifactu Setup page
        SimulatePageOpen(VerifactuSetup);

        // [THEN] A record is created if it does not exist
        VerifySetupRecordExists(VerifactuSetup);
    end;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseYesModalPageHandler')]
    procedure VerifactuSetupEnablesWithValidCertificate()
    var
        VerifactuSetup: Record "Verifactu Setup";
        IsolatedCertificate: Record "Isolated Certificate";
        CertCode: Code[20];
    begin
        // [SCENARIO] User enables Verifactu Setup when valid certificate is configured
        Initialize();

        // [GIVEN] Company Information has valid Post Code with Time Zone
        SetupCompanyInfoWithPostCode('Romance Standard Time');

        // [GIVEN] Verifactu Setup record exists
        CreateVerifactuSetup(VerifactuSetup);

        // [GIVEN] Certificate "C" exists in Isolated Certificate table
        CertCode := CreateCertificate(IsolatedCertificate);

        // [GIVEN] Setup field Certificate Code is set to "C"
        VerifactuSetup.Validate("Certificate Code", CertCode);
        VerifactuSetup.Modify(true);

        // [WHEN] User sets Enabled field to true
        VerifactuSetup.Validate(Enabled, true);
        VerifactuSetup.Modify(true);

        // [THEN] Enabled field is set to true
        // [THEN] No error is raised
        Assert.IsTrue(VerifactuSetup.Enabled, 'Setup should be enabled');
    end;

    [Test]
    procedure VerifactuSetupCannotEnableWithoutCertificate()
    var
        VerifactuSetup: Record "Verifactu Setup";
    begin
        // [SCENARIO] User cannot enable Verifactu Setup without a certificate
        Initialize();

        // [GIVEN] Verifactu Setup record exists
        CreateVerifactuSetup(VerifactuSetup);

        // [GIVEN] Certificate Code field is blank
        VerifactuSetup."Certificate Code" := '';
        VerifactuSetup.Modify(true);

        // [WHEN] User attempts to set Enabled field to true
        asserterror VerifactuSetup.Validate(Enabled, true);

        // [THEN] Error is raised with message about missing certificate
        // [THEN] Enabled field remains false
        Assert.ExpectedError('certificate');
    end;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseYesModalPageHandler')]
    procedure VerifactuSetupIsEnabledReturnsTrueWhenEnabled()
    var
        VerifactuSetup: Record "Verifactu Setup";
        IsolatedCertificate: Record "Isolated Certificate";
        CertCode: Code[20];
        IsEnabled: Boolean;
    begin
        // [SCENARIO] IsEnabled procedure returns true when setup is enabled
        Initialize();

        // [GIVEN] Company Information has valid Post Code with Time Zone
        SetupCompanyInfoWithPostCode('Romance Standard Time');

        // [GIVEN] Verifactu Setup record exists
        CreateVerifactuSetup(VerifactuSetup);

        // [GIVEN] Certificate "C" is assigned
        CertCode := CreateCertificate(IsolatedCertificate);
        VerifactuSetup.Validate("Certificate Code", CertCode);

        // [GIVEN] Enabled field is set to true
        VerifactuSetup.Validate(Enabled, true);
        VerifactuSetup.Modify(true);

        // [WHEN] IsEnabled procedure is called
        IsEnabled := VerifactuSetup.IsEnabled();

        // [THEN] Result is true
        Assert.IsTrue(IsEnabled, 'IsEnabled should return true');
    end;

    [Test]
    procedure VerifactuSetupIsEnabledReturnsFalseWhenDisabled()
    var
        VerifactuSetup: Record "Verifactu Setup";
        IsEnabled: Boolean;
    begin
        // [SCENARIO] IsEnabled procedure returns false when setup is disabled
        Initialize();

        // [GIVEN] Verifactu Setup record exists
        CreateVerifactuSetup(VerifactuSetup);

        // [GIVEN] Enabled field is set to false
        VerifactuSetup.Enabled := false;
        VerifactuSetup.Modify(true);

        // [WHEN] IsEnabled procedure is called
        IsEnabled := VerifactuSetup.IsEnabled();

        // [THEN] Result is false
        Assert.IsFalse(IsEnabled, 'IsEnabled should return false');
    end;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseYesModalPageHandler')]
    procedure VerifactuSetupCertificateCodeLookup()
    var
        VerifactuSetup: Record "Verifactu Setup";
        IsolatedCertificate: Record "Isolated Certificate";
        CertCode1: Code[20];
    begin
        // [SCENARIO] User can lookup and select certificate using drilldown
        Initialize();

        // [GIVEN] Company Information has valid Post Code with Time Zone
        SetupCompanyInfoWithPostCode('Romance Standard Time');

        // [GIVEN] Verifactu Setup record exists
        CreateVerifactuSetup(VerifactuSetup);

        // [GIVEN] Certificates "C1" and "C2" exist in Isolated Certificate table
        CertCode1 := CreateCertificate(IsolatedCertificate);
        CreateCertificate(IsolatedCertificate);

        // [WHEN] User performs lookup on Certificate Code field
        // [WHEN] User selects certificate "C1"
        VerifactuSetup.Validate("Certificate Code", CertCode1);
        VerifactuSetup.Modify(true);

        // [THEN] Certificate Code field is set to "C1"
        Assert.AreEqual(CertCode1, VerifactuSetup."Certificate Code", 'Certificate Code should be set');
    end;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseNoModalPageHandler')]
    procedure VerifactuSetupRemainsDisabledWhenConsentDeclined()
    var
        VerifactuSetup: Record "Verifactu Setup";
        IsolatedCertificate: Record "Isolated Certificate";
        CertCode: Code[20];
    begin
        // [SCENARIO] Setup remains disabled when user declines consent
        Initialize();

        // [GIVEN] Company Information has valid Post Code with Time Zone
        SetupCompanyInfoWithPostCode('Romance Standard Time');

        // [GIVEN] Verifactu Setup record exists
        CreateVerifactuSetup(VerifactuSetup);

        // [GIVEN] Certificate "C" exists in Isolated Certificate table
        CertCode := CreateCertificate(IsolatedCertificate);

        // [GIVEN] Setup field Certificate Code is set to "C"
        VerifactuSetup.Validate("Certificate Code", CertCode);
        VerifactuSetup.Modify(true);

        // [WHEN] User attempts to set Enabled field to true but declines consent
        VerifactuSetup.Validate(Enabled, true);
        VerifactuSetup.Modify(true);

        // [THEN] Enabled field remains false
        Assert.IsFalse(VerifactuSetup.Enabled, 'Setup should remain disabled when consent is declined');
    end;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseYesModalPageHandler,ConfirmSIISetupHandlerYes')]
    procedure VerifactuSetupEnablesWhenSIISetupDisabled()
    var
        VerifactuSetup: Record "Verifactu Setup";
        SIISetup: Record "SII Setup";
        IsolatedCertificate: Record "Isolated Certificate";
        CertCode: Code[20];
    begin
        // [SCENARIO] Verifactu Setup can be enabled when SII Setup is disabled
        IsInitialized := false;
        Initialize();

        // [GIVEN] Company Information has valid Post Code with Time Zone
        SetupCompanyInfoWithPostCode('Romance Standard Time');

        // [GIVEN] SII Setup exists and is enabled
        CreateSIISetup(SIISetup, true);

        // [GIVEN] Verifactu Setup record exists
        CreateVerifactuSetup(VerifactuSetup);

        // [GIVEN] Certificate "C" exists in Isolated Certificate table
        CertCode := CreateCertificate(IsolatedCertificate);

        // [GIVEN] Setup field Certificate Code is set to "C"
        VerifactuSetup.Validate("Certificate Code", CertCode);
        VerifactuSetup.Modify(true);

        // [WHEN] User sets Enabled field to true
        VerifactuSetup.Validate(Enabled, true);
        VerifactuSetup.Modify(true);

        // [THEN] Enabled field is set to true
        Assert.IsTrue(VerifactuSetup.Enabled, 'Setup should be enabled when SII Setup is disabled');
    end;

    [Test]
    [HandlerFunctions('ConfirmSIISetupHandlerNo')]
    procedure VerifactuSetupCannotEnableWhenSIISetupEnabled()
    var
        VerifactuSetup: Record "Verifactu Setup";
        SIISetup: Record "SII Setup";
        IsolatedCertificate: Record "Isolated Certificate";
        CertCode: Code[20];
    begin
        // [SCENARIO] Verifactu Setup cannot be enabled when SII Setup is enabled
        IsInitialized := false;
        Initialize();

        // [GIVEN] Company Information has valid Post Code with Time Zone
        SetupCompanyInfoWithPostCode('Romance Standard Time');

        // [GIVEN] SII Setup exists and is enabled
        CreateSIISetup(SIISetup, true);

        // [GIVEN] Verifactu Setup record exists
        CreateVerifactuSetup(VerifactuSetup);

        // [GIVEN] Certificate "C" exists in Isolated Certificate table
        CertCode := CreateCertificate(IsolatedCertificate);

        // [GIVEN] Setup field Certificate Code is set to "C"
        VerifactuSetup.Validate("Certificate Code", CertCode);
        VerifactuSetup.Modify(true);

        // [WHEN] User attempts to set Enabled field to true
        VerifactuSetup.Validate(Enabled, true);
        VerifactuSetup.Modify(true);

        // [THEN] Enabled field remains false
        Assert.IsFalse(VerifactuSetup.Enabled, 'Setup should remain disabled when SII Setup is enabled');
    end;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseYesModalPageHandler,ConfirmVerifactuSetupHandlerYes')]
    procedure SIISetupEnablesWhenVerifactuSetupDisabled()
    var
        VerifactuSetup: Record "Verifactu Setup";
        SIISetup: Record "SII Setup";
        IsolatedCertificate: Record "Isolated Certificate";
        CertCode: Code[20];
    begin
        // [SCENARIO] SII Setup can be enabled when Verifactu Setup is disabled
        IsInitialized := false;
        Initialize();

        // [GIVEN] Company Information has valid Post Code with Time Zone
        SetupCompanyInfoWithPostCode('Romance Standard Time');

        // [GIVEN] Verifactu Setup exists and is enabled
        CreateVerifactuSetup(VerifactuSetup);
        CertCode := CreateCertificate(IsolatedCertificate);
        VerifactuSetup.Validate("Certificate Code", CertCode);
        VerifactuSetup.Validate(Enabled, true);
        VerifactuSetup.Modify(true);

        // [GIVEN] SII Setup record exists
        CreateSIISetup(SIISetup, false);

        // [WHEN] User sets SII Setup Enabled field to true
        SIISetup."Certificate Code" := CertCode;
        SIISetup.Validate(Enabled, true);
        SIISetup.Modify();

        // [THEN] SII Setup Enabled field is set to true
        // [THEN] Verifactu Setup is disabled after user confirms
        Assert.IsTrue(SIISetup.Enabled, 'SII Setup should be enabled when Verifactu Setup is disabled');
        VerifactuSetup.Get();
        Assert.IsFalse(VerifactuSetup.Enabled, 'Verifactu Setup should be disabled');
    end;

    [Test]
    [HandlerFunctions('ConfirmVerifactuSetupHandlerNo,CustomerConsentConfirmationPageChooseYesModalPageHandler')]
    procedure SIISetupCannotEnableWhenVerifactuSetupEnabled()
    var
        VerifactuSetup: Record "Verifactu Setup";
        SIISetup: Record "SII Setup";
        IsolatedCertificate: Record "Isolated Certificate";
        CertCode: Code[20];
    begin
        // [SCENARIO] SII Setup cannot be enabled when Verifactu Setup is enabled and user declines
        IsInitialized := false;
        Initialize();

        // [GIVEN] Company Information has valid Post Code with Time Zone
        SetupCompanyInfoWithPostCode('Romance Standard Time');

        // [GIVEN] Verifactu Setup exists and is enabled
        CreateVerifactuSetup(VerifactuSetup);
        CertCode := CreateCertificate(IsolatedCertificate);
        VerifactuSetup.Validate("Certificate Code", CertCode);
        VerifactuSetup.Validate(Enabled, true);
        VerifactuSetup.Modify(true);

        // [GIVEN] SII Setup record exists and is disabled
        CreateSIISetup(SIISetup, false);

        // [WHEN] User attempts to set SII Setup Enabled field to true but declines confirmation
        SIISetup.Validate(Enabled, true);
        SIISetup.Modify();

        // [THEN] SII Setup Enabled field remains false
        // [THEN] Verifactu Setup remains enabled
        Assert.IsFalse(SIISetup.Enabled, 'SII Setup should remain disabled when Verifactu Setup is enabled');
        VerifactuSetup.Get();
        Assert.IsTrue(VerifactuSetup.Enabled, 'Verifactu Setup should remain enabled');
    end;

    [Test]
    procedure EnableSetupFailsWhenPostCodeTimeZoneIsBlank()
    var
        VerifactuSetup: Record "Verifactu Setup";
        IsolatedCertificate: Record "Isolated Certificate";
        CertCode: Code[20];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 622986] Verifactu Setup cannot be enabled when Post Code Time Zone is blank
        Initialize();

        // [GIVEN] Company Information has Post Code "PC" and City set with blank Time Zone
        SetupCompanyInfoWithPostCode('');

        // [GIVEN] Verifactu Setup record exists with valid certificate "C"
        CreateVerifactuSetup(VerifactuSetup);
        CertCode := CreateCertificate(IsolatedCertificate);
        VerifactuSetup."Certificate Code" := CertCode;
        VerifactuSetup.Modify(true);

        // [WHEN] User attempts to enable Verifactu Setup
        asserterror VerifactuSetup.Validate(Enabled, true);

        // [THEN] Error is raised about missing Time Zone
        Assert.ExpectedError('Time Zone');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseYesModalPageHandler')]
    procedure EnableSetupSucceedsWithValidCompanyInfo()
    var
        VerifactuSetup: Record "Verifactu Setup";
        IsolatedCertificate: Record "Isolated Certificate";
        CertCode: Code[20];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 622986] Verifactu Setup enables successfully with valid Company Information
        Initialize();

        // [GIVEN] Company Information has Post Code "PC" with Time Zone set
        SetupCompanyInfoWithPostCode('Romance Standard Time');

        // [GIVEN] Verifactu Setup record exists with valid certificate "C"
        CreateVerifactuSetup(VerifactuSetup);
        CertCode := CreateCertificate(IsolatedCertificate);
        VerifactuSetup.Validate("Certificate Code", CertCode);
        VerifactuSetup.Modify(true);

        // [WHEN] User enables Verifactu Setup
        VerifactuSetup.Validate(Enabled, true);
        VerifactuSetup.Modify(true);

        // [THEN] Enabled field is set to true
        Assert.IsTrue(VerifactuSetup.Enabled, 'Setup should be enabled with valid Company Information');
    end;

    [Test]
    procedure CheckCompanyInfoFailsWhenTimeZoneClearedAfterEnable()
    var
        Verifactu: Codeunit Verifactu;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 622986] CheckCompanyInformation fails when Post Code Time Zone is cleared after Verifactu was enabled
        Initialize();

        // [GIVEN] Company Information has Post Code "PC" with blank Time Zone
        SetupCompanyInfoWithPostCode('');

        // [WHEN] CheckCompanyInformation is called
        asserterror Verifactu.CheckCompanyInformation();

        // [THEN] Error is raised about missing Time Zone
        Assert.ExpectedError('Time Zone');
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure Initialize()
    var
        VerifactuSetup: Record "Verifactu Setup";
        SIISetup: Record "SII Setup";
    begin
        // code that is run before each test
        if IsInitialized then
            exit;
        // code that is run only once before the first test
        VerifactuSetup.DeleteAll();
        SIISetup.DeleteAll();
        IsInitialized := true;
    end;

    local procedure CreateVerifactuSetup(var VerifactuSetup: Record "Verifactu Setup")
    begin
        VerifactuSetup.DeleteAll();
        VerifactuSetup.Init();
        VerifactuSetup."Primary Key" := '';
        VerifactuSetup.Insert(true);
    end;

    local procedure CreateCertificate(var IsolatedCertificate: Record "Isolated Certificate"): Code[20]
    begin
        IsolatedCertificate.Init();
        IsolatedCertificate.Scope := IsolatedCertificate.Scope::Company;
        IsolatedCertificate.Insert(true);
        exit(IsolatedCertificate.Code);
    end;

    local procedure CertificateWithExtensions(ExtensionsHex: Text): Text
    begin
        // Certificate ::= SEQUENCE { TBSCertificate ::= SEQUENCE { serialNumber, extensions [3] } }; other fields are not needed for seal detection.
        exit(DerElement(SequenceTagTok, DerElement(SequenceTagTok, SerialNumberTok + DerElement(ExtensionsTagTok, DerElement(SequenceTagTok, ExtensionsHex)))));
    end;

    local procedure CertificateExtension(ExtensionOidHex: Text; ExtensionValueHex: Text): Text
    begin
        exit(DerElement(SequenceTagTok, ExtensionOidHex + DerElement(OctetStringTagTok, ExtensionValueHex)));
    end;

    local procedure QcStatementsWithQcType(QcTypeOidHex: Text): Text
    begin
        exit(DerElement(SequenceTagTok, QcComplianceStatementTok + DerElement(SequenceTagTok, QcTypeStatementOidTok + DerElement(SequenceTagTok, QcTypeOidHex))));
    end;

    local procedure CertificatePoliciesWith(PolicyOidHex: Text): Text
    begin
        exit(DerElement(SequenceTagTok, DerElement(SequenceTagTok, PolicyOidHex)));
    end;

    local procedure DerElement(TagHex: Text; ContentHex: Text): Text
    var
        ContentLength: Integer;
    begin
        ContentLength := StrLen(ContentHex) div 2;
        if ContentLength < 128 then
            exit(TagHex + ByteToHex(ContentLength) + ContentHex);
        if ContentLength < 256 then
            exit(TagHex + '81' + ByteToHex(ContentLength) + ContentHex);
        exit(TagHex + '82' + ByteToHex(ContentLength div 256) + ByteToHex(ContentLength mod 256) + ContentHex);
    end;

    local procedure ByteToHex(Value: Integer): Text
    begin
        exit(CopyStr(HexDigitsTok, Value div 16 + 1, 1) + CopyStr(HexDigitsTok, Value mod 16 + 1, 1));
    end;

    local procedure HexToBase64(HexText: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        OutStr: OutStream;
        InStr: InStream;
        ByteValue: Byte;
        i: Integer;
    begin
        TempBlob.CreateOutStream(OutStr);
        for i := 1 to StrLen(HexText) div 2 do begin
            ByteValue := (StrPos(HexDigitsTok, CopyStr(HexText, 2 * i - 1, 1)) - 1) * 16 + StrPos(HexDigitsTok, CopyStr(HexText, 2 * i, 1)) - 1;
            OutStr.Write(ByteValue);
        end;
        TempBlob.CreateInStream(InStr);
        exit(Base64Convert.ToBase64(InStr));
    end;

    local procedure CreateSIISetup(var SIISetup: Record "SII Setup"; IsEnabled: Boolean)
    begin
        SIISetup.DeleteAll();
        SIISetup.Init();
        SIISetup.Enabled := IsEnabled;
        if not SIISetup.Insert(true) then begin
            SIISetup.Enabled := IsEnabled;
            SIISetup.Modify(true);
        end;
    end;

    local procedure SimulatePageOpen(var VerifactuSetup: Record "Verifactu Setup")
    begin
        VerifactuSetup.Reset();
        if not VerifactuSetup.Get() then begin
            VerifactuSetup.Init();
            VerifactuSetup.Insert(true);
        end;
    end;

    local procedure VerifySetupRecordExists(var VerifactuSetup: Record "Verifactu Setup")
    begin
        Assert.IsTrue(VerifactuSetup.Get(), 'Verifactu Setup record should exist');
    end;

    local procedure SetupCompanyInfoWithPostCode(TimeZone: Text[180])
    var
        CompanyInformation: Record "Company Information";
        PostCode: Record "Post Code";
        PostCodeValue: Code[20];
        CityValue: Text[30];
    begin
        PostCodeValue := CopyStr(LibraryRandom.RandText(20), 1, MaxStrLen(PostCodeValue));
        CityValue := CopyStr(LibraryRandom.RandText(30), 1, MaxStrLen(CityValue));

        CompanyInformation.Get();
        CompanyInformation."Post Code" := PostCodeValue;
        CompanyInformation.City := CityValue;
        CompanyInformation.Modify();

        if PostCode.Get(PostCodeValue, CityValue) then
            PostCode.Delete();
        PostCode.Init();
        PostCode.Code := PostCodeValue;
        PostCode.City := CityValue;
        PostCode."Time Zone" := TimeZone;
        PostCode.Insert();
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
    procedure ConfirmSIISetupHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(DisableSIIQst, Question, 'Expected SII disable confirmation');
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmSIISetupHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(DisableSIIQst, Question, 'Expected SII disable confirmation');
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmVerifactuSetupHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(DisableVerifactuQst, Question, 'Expected Verifactu disable confirmation');
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmVerifactuSetupHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(DisableVerifactuQst, Question, 'Expected Verifactu disable confirmation');
        Reply := false;
    end;
}
