codeunit 144093 "UT REP Withhold"
{
    // // [FEATURE] [UT] [Withhold Tax] [Report]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DialogErr: Label 'Dialog';
        INPSVendorNoCap: Label 'INPS_INPS__Vendor_No__';
        INPSGrossAmountCap: Label 'INPS__Gross_Amount_';
        INPSContributionBaseCap: Label 'INPS__Contribution_Base_';
        INPSTotalSocialSecurityAmountCap: Label 'INPS__Total_Social_Security_Amount_';
        INAILVendorNoCap: Label 'INAIL_INAIL__Vendor_No__';
        INAILGrossAmountCap: Label 'INAIL__INAIL_Gross_Amount_';
        INAILTotalAmountCap: Label 'INAIL__INAIL_Total_Amount_';
        TotalAmountCap: Label 'TotalAmount';
        VendNoCap: Label 'VendNo';
        VendorNumberCap: Label 'Vendor__No__';
        LibraryRandom: Codeunit "Library - Random";
        WithholdingTaxDocumentNumberCap: Label 'Withholding_Tax__Document_No__';
        WithholdingTaxPercentageCap: Label 'Withholding_Tax__Withholding_Tax___';
        WithholdingTaxTotalAmountCap: Label 'Withholding_Tax__Total_Amount_';
        WithholdingTaxAmtWithholdingTaxCap: Label 'WithholdingTaxAmt_WithholdingTax2';
        WithholdingTaxWithholdingTaxAmountCap: Label 'Withholding_Tax__Withholding_Tax_Amount_';
        WithholdingTaxPaymentCap: Label 'Withholding_Tax_PaymentCaption';
        WithholdingTaxPaymentTotalAmountCap: Label 'Withholding_Tax_Payment__Total_Amount_';
        WithholdingTaxPaymentWithholdingTaxAmountCap: Label 'Withholding_Tax_Payment__Withholding_Tax_Amount_';
        ErrorTextNumberCap: Label 'ErrorText_Number_';
        VATRegistrationNoBlankTxt: Label 'VAT Registration No. cannot be left blank.';
        VATRegistrationNoFormatTxt: Label 'VAT Registration No. value is not in valid format.';
        VATRegistrationNoVATRulesTxt: Label 'VAT Registration No. value doesn''t comply to local VAT Rules.';
        VendorBirthDateCap: Label 'Vendor__Birth_Date_';
        VendoFiscalCodeCap: Label 'Vendor__Fiscal_Code_';
        IncorrectValueErr: Label '%1 value is incorrect.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('CompensationDetailsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreReportBlankFromPaymentDateCompensationDetailsErr()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report - 12105 Compensation Details.
        PaymentAndRelatedDateCompensationDetails(0D, WorkDate());  // Blank From Payment Date and From Related Date as WORKDATE.
    end;

    [Test]
    [HandlerFunctions('CompensationDetailsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreReportBlankFromRelatedDateCompensationDetailsErr()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report - 12105 Compensation Details.
        PaymentAndRelatedDateCompensationDetails(WorkDate(), 0D);  // From Payment Date - WORKDATE and blank From Related Date.
    end;

    local procedure PaymentAndRelatedDateCompensationDetails(FromPaymentDate: Date; FromRelatedDate: Date)
    var
        Vendor: Record Vendor;
    begin
        // Setup: Enqueue values for handler - CompensationDetailsRequestPageHandler.
        Initialize();
        EnqueueVendorNoAndDates(
          LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor),
          FromPaymentDate, FromRelatedDate);

        // Exercise.
        asserterror RunReportCompensationDetails();  // Opens handler - CompensationDetailsRequestPageHandler.

        // Verify: Verify Error Code. Actual error message: From Payment Date and To Payment Date must be filled or From Related Date and To Related Date must be filled.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('CompensationDetailsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WithholdingTaxOnAfterGetRecordCompensationDetails()
    var
        WithholdingTax: Record "Withholding Tax";
        Contributions: Record Contributions;
        ContributionCode: Record "Contribution Code";
    begin
        // Purpose of the test is to validate Withholding Tax - OnAfterGetRecord Trigger of Report - 12105 Compensation Details.

        // Setup: Create Contributions and Withholding Tax.
        Initialize();
        CreateContributions(Contributions, ContributionCode."Contribution Type"::INPS);
        CreateWithholdingTax(WithholdingTax, Contributions."Vendor No.", true);
        EnqueueVendorNoAndDates(WithholdingTax."Vendor No.", WithholdingTax."Payment Date", WithholdingTax."Related Date");  // Enqueue values for handler - CompensationDetailsRequestPageHandler.

        // Exercise.
        RunReportCompensationDetails();  // Opens handler - CompensationDetailsRequestPageHandler.

        // Verify: Verify Withholding Tax - Vendor Number, Total Amount, Document Number and Withholding Tax Percentage on XML of Report - Compensation Details.
        VerifyValuesOnReport(
          VendorNumberCap, WithholdingTaxTotalAmountCap, WithholdingTaxPercentageCap,
          WithholdingTax."Vendor No.", WithholdingTax."Total Amount", WithholdingTax."Withholding Tax %");
        LibraryReportDataset.AssertElementWithValueExists(WithholdingTaxDocumentNumberCap, WithholdingTax."Document No.");
    end;

    [Test]
    [HandlerFunctions('ContributionRequestPageHandler')]
    [Scope('OnPrem')]
    procedure INPSOnAfterGetRecordContribution()
    var
        Contributions: Record Contributions;
        ContributionCode: Record "Contribution Code";
    begin
        // Purpose of the test is to validate INPS - OnAfterGetRecord Trigger of Report - 12102 Contribution.
        // Setup.
        Initialize();
        CreateContributions(Contributions, ContributionCode."Contribution Type"::INPS);
        RunContributionReport(ContributionCode."Contribution Type"::INPS);

        // Verify: Verify Contributions - Vendor Number, Gross Amount, Contribution Base and Total Social Security Amount on XML of Report - Contribution.
        VerifyValuesOnReport(
          INPSVendorNoCap, INPSGrossAmountCap, INPSContributionBaseCap,
          Contributions."Vendor No.", Contributions."Gross Amount", Contributions."Contribution Base");
        LibraryReportDataset.AssertElementWithValueExists(INPSTotalSocialSecurityAmountCap, Contributions."Total Social Security Amount");
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WithholdingTaxOnAfterGetRecordWithholdingTaxes()
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        // Purpose of the test is to validate Withholding Tax - OnAfterGetRecord Trigger of Report - 12101 Withholding Taxes.

        // Setup: Create Withholding Tax and Vendor.
        Initialize();
        CreateWithholdingTax(WithholdingTax, CreateVendor('', '', false), true);  // Blank Country/Region Code, VAT Registration No. and Individual Person mark FALSE.

        // Exercise.
        RunReportWithholdingTaxes();  // Opens handler - WithholdingTaxesRequestPageHandler.

        // Verify: Verify Withholding Taxes - Vendor Number, Total Amount, Withholding Tax Amount on XML of Report - Withholding Taxes.
        VerifyValuesOnReport(
          VendNoCap, TotalAmountCap, WithholdingTaxAmtWithholdingTaxCap,
          WithholdingTax."Vendor No.", WithholdingTax."Total Amount", WithholdingTax."Withholding Tax Amount");
    end;

    [Test]
    [HandlerFunctions('CertificationsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WithholdingTaxOnAfterGetRecordCertifications()
    var
        WithholdingTax: Record "Withholding Tax";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Certifications]
        // [SCENARIO] Validate Withholding Tax - OnAfterGetRecord Trigger of Report - 12106 Certifications.

        // [GIVEN] Withholding Tax and Vendor ("Name" = "A", "Name 2" = "B", Address = "C", "Individual Person" = No).
        Initialize();
        CreateWithholdingTax(WithholdingTax, CreateVendor('', '', false), true);  // Blank Country/Region Code, VAT Registration No. and Individual Person mark FALSE.

        // [WHEN] Run report "Certifications"
        RunReportCertifications(WithholdingTax."Vendor No.");  // Opens handler - CertificationsRequestPageHandler.

        // [THEN] Vendor Number, Total Amount, Withholding Tax Amount are correct
        VerifyValuesOnReport(
          VendorNumberCap, WithholdingTaxTotalAmountCap, WithholdingTaxWithholdingTaxAmountCap,
          WithholdingTax."Vendor No.", WithholdingTax."Total Amount", WithholdingTax."Withholding Tax Amount");

        // [THEN] Vendor Name = "A B", Vendor Address = "C"
        Vendor.Get(WithholdingTax."Vendor No.");
        VerifyVendorNameAndAddress(Vendor.Name + ' ' + Vendor."Name 2", Vendor.Address);
    end;

    [Test]
    [HandlerFunctions('CertificationsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WithholdingTaxOnAfterGetRecordCertifications_IndividualPerson()
    var
        WithholdingTax: Record "Withholding Tax";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Certifications]
        // [SCENARIO 378836] Validate Withholding Tax - OnAfterGetRecord Trigger of Report - 12106 Certifications (Individual Person).

        // [GIVEN] Withholding Tax and Vendor ("Name" = "A", "Name 2" = "B", Address = "C", "Individual Person" = Yes, "First Name" = "D", "Last Name" = "E", "Residence Address" = "F").
        Initialize();
        CreateWithholdingTax(WithholdingTax, CreateVendor('', '', true), true);  // Blank Country/Region Code, VAT Registration No. and Individual Person mark TRUE.

        // [WHEN] Run report "Certifications"
        RunReportCertifications(WithholdingTax."Vendor No.");  // Opens handler - CertificationsRequestPageHandler.

        // [THEN] Vendor Number, Total Amount, Withholding Tax Amount are correct
        VerifyValuesOnReport(
          VendorNumberCap, WithholdingTaxTotalAmountCap, WithholdingTaxWithholdingTaxAmountCap,
          WithholdingTax."Vendor No.", WithholdingTax."Total Amount", WithholdingTax."Withholding Tax Amount");

        // [THEN] Vendor Name = "D E", Vendor Address = "F"
        Vendor.Get(WithholdingTax."Vendor No.");
        VerifyVendorNameAndAddress(Vendor."First Name" + ' ' + Vendor."Last Name", Vendor."Residence Address");
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreReportBlankVendorNoWithholdingTaxTestError()
    begin
        // Purpose of the test is to validate Vendor - OnPreReport Trigger of Report - 12183 Withholding Tax - Test.
        // Setup.
        Initialize();
        EnqueueVendorNoAndDates('', WorkDate(), WorkDate());  // Enqueue Value for WithholdingTaxTestRequestPageHandler.

        // Exercise.
        asserterror RunReportWithholdingTaxTest();  // Opens handler - WithholdingTaxTestRequestPageHandler.

        // Verify: Verify Error Code. Actual error message: No. filter must be set before running the report.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreReportBlankStartingDateWithholdingTaxTestError()
    begin
        // Purpose of the test is to validate Vendor - OnPreReport Trigger of Report - 12183 Withholding Tax - Test.

        // Setup: Create vendor with blank Country/Region Code, VAT Registration No. and Individual Person mark TRUE.
        Initialize();
        EnqueueVendorNoAndDates(CreateVendor('', '', true), 0D, WorkDate());  // Start Date -0D, End Date -WorkDate(), Enqueue Value for WithholdingTaxTestRequestPageHandler.

        // Exercise.
        asserterror RunReportWithholdingTaxTest();  // Opens handler - WithholdingTaxTestRequestPageHandler.

        // Verify: Verify Error Code. Actual error message: Starting Date must not be blank.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreReportBlankEndDateWithholdingTaxTestError()
    begin
        // Purpose of the test is to validate Blank Vendor - OnPreReport Trigger of Report - 12183 Withholding Tax - Test.

        // Setup: Create vendor with blank Country/Region Code, VAT Registration No. and Individual Person mark TRUE.
        Initialize();
        EnqueueVendorNoAndDates(CreateVendor('', '', true), WorkDate(), 0D);  // Start Date -WorkDate(), End Date -0D, Enqueue Value for WithholdingTaxTestRequestPageHandler.

        // Exercise.
        asserterror RunReportWithholdingTaxTest();  // Opens handler - WithholdingTaxTestRequestPageHandler.

        // Verify: Verify Error Code. Actual error message: Ending Date must not be blank.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreReportHigherStartDateWithholdingTaxTestError()
    begin
        // Purpose of the test is to validate Blank Vendor - OnPreReport Trigger of Report - 12183 Withholding Tax - Test.

        // Setup: Create vendor with blank Country/Region Code, VAT Registration No. and Individual Person mark TRUE.
        Initialize();
        EnqueueVendorNoAndDates(
          CreateVendor('', '', true), CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()), WorkDate());  // Enqueue Value for WithholdingTaxTestRequestPageHandler, Calculated Start Date greater than End Date.

        // Exercise.
        asserterror RunReportWithholdingTaxTest();  // Opens handler - WithholdingTaxTestRequestPageHandler.

        // Verify: Verify Error Code. Actual error message: Start Date cannot be greater than End Date.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecBlankVatRegNoWithholdingTaxTest()
    begin
        // Purpose of the test is to validate Vendor - OnPreReport Trigger of Report - 12183 Withholding Tax - Test.

        // Setup: VAT Registration error text with blank VAT Registration Number and blank Country/Region Code.
        Initialize();
        WithholdingTaxTestValidation('', VATRegistrationNoBlankTxt, '');
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVatRegNoWithholdingTaxTest()
    begin
        // Purpose of the test is to validate Vendor - OnPreReport Trigger of Report - 12183 Withholding Tax - Test.

        // Setup: VAT Registration error text with VAT Registration Number and Country/Region Code, VAT Registration No. required 9 digit value.
        Initialize();
        WithholdingTaxTestValidation(
          Format(LibraryRandom.RandIntInRange(100000000, 999999999)), VATRegistrationNoFormatTxt, CreateCountryRegionCode());
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecUpdateGLSetupWithholdingTaxTest()
    begin
        // Purpose of the test is to validate Vendor - OnPreReport Trigger of Report - 12183 Withholding Tax - Test.

        // Setup: VAT Registration error text with VAT Registration No and blank Country/Region Code, VAT Registration No. required 9 digit value.
        Initialize();
        WithholdingTaxTestValidation(Format(LibraryRandom.RandIntInRange(100000000, 999999999)), VATRegistrationNoVATRulesTxt, '');
    end;

    local procedure WithholdingTaxTestValidation(VATRegistrationNo: Text[20]; VATRegistrationNoErrorTxt: Text[250]; CountryRegionCode: Code[10])
    var
        Vendor: Record Vendor;
    begin
        // Update General Ledger Setup and create Vendor.
        Initialize();
        LibraryITLocalization.SetValidateLocVATRegNo(true);
        CreateVendorAndWithholdingTax(Vendor, VATRegistrationNo, CountryRegionCode, false);  // Individual Person mark FALSE.

        // Exercise.
        RunReportWithholdingTaxTest();  // Opens handler - WithholdingTaxTestRequestPageHandler.

        // Verify: Verify VAT Registration Number error text on XML of Report - Withholding Tax - Test.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ErrorTextNumberCap, VATRegistrationNoErrorTxt);
    end;

    [Test]
    [HandlerFunctions('WithholdingTaxTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecIndividualPersonTrueWithholdingTaxTest()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord Trigger of Report - 12183 Withholding Tax - Test.
        // Setup.
        Initialize();
        CreateVendorAndWithholdingTax(Vendor, '', '', true);  // Create vendor with Country/Region Code, VAT Registration No. and Individual Person mark TRUE.

        // Exercise.
        RunReportWithholdingTaxTest();  // Opens handler - WithholdingTaxTestRequestPageHandler.

        // Verify: Verify Vendor Number,Fiscal Code,Birth Date on XML of Report - Withholding Tax - Test.
        VerifyValuesOnReport(
          VendorNumberCap, VendoFiscalCodeCap, VendorBirthDateCap, Vendor."No.", Vendor."Fiscal Code", Format(Vendor."Date of Birth"));
    end;

    [Test]
    [HandlerFunctions('SummaryWithholdingPaymentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WithholdingTaxPaymentOnSummaryWithholdingPaymentReport()
    var
        WithholdingTaxPayment: Record "Withholding Tax Payment";
    begin
        // Purpose of the test is to validate Withholding Tax Payment on Report - 12103 Withholding Tax Payment.
        // Setup.
        Initialize();
        CreateWithholdingTaxPayment(WithholdingTaxPayment);

        // Exercise.
        RunReportSummaryWithholdingPayment();  // Opens handler - SummaryWithholdingPaymentRequestPageHandler.

        // Verify: Verify Withholding Tax Payment - Withholding Tax Payment Caption, Total Amount, Withholding Tax Amount on XML of Report - Withholding Tax Payment.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(WithholdingTaxPaymentCap, WithholdingTaxPayment.TableCaption());
        LibraryReportDataset.AssertElementWithValueExists(WithholdingTaxPaymentTotalAmountCap, WithholdingTaxPayment."Total Amount");
        LibraryReportDataset.AssertElementWithValueExists(
          WithholdingTaxPaymentWithholdingTaxAmountCap, WithholdingTaxPayment."Withholding Tax Amount");
    end;

    [Test]
    [HandlerFunctions('ContributionRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordINAILContribution()
    var
        Contributions: Record Contributions;
        ContributionCode: Record "Contribution Code";
    begin
        // Purpose of the test is to validate INAIL - OnAfterGetRecord Trigger of Report - 12102 Contribution.
        // Setup.
        Initialize();
        CreateContributions(Contributions, ContributionCode."Contribution Type"::INAIL);
        RunContributionReport(ContributionCode."Contribution Type"::INAIL);

        // Verify: Verify Contributions - Vendor Number, INAIL Gross Amount, INAIL Total Amount on XML of Report - Contribution.
        VerifyValuesOnReport(
          INAILVendorNoCap, INAILGrossAmountCap, INAILTotalAmountCap,
          Contributions."Vendor No.", Contributions."INAIL Gross Amount", Contributions."INAIL Total Amount");
    end;

    [Test]
    [HandlerFunctions('CertificationsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordContributionsCertifications()
    var
        Contributions: Record Contributions;
        ContributionCode: Record "Contribution Code";
        WithholdingTax: Record "Withholding Tax";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Certifications]
        // [SCENARIO] Validate Contributions - OnAfterGetRecord Trigger of Report - 12106 Certifications.

        // [GIVEN] Withholding Tax and Contributions for Vendor with "Name" = "A", "Name 2" = "B", Address = "C", "Individual Person" = No
        Initialize();
        CreateWithholdingTax(WithholdingTax, CreateVendor('', '', false), true);  // Blank Country/Region Code, VAT Registration No. and Individual Person mark FALSE.
        CreateContributions(Contributions, ContributionCode."Contribution Type"::INAIL);

        // [WHEN] Run report "Certifications"
        RunReportCertifications(WithholdingTax."Vendor No.");  // Opens handler - CertificationsRequestPageHandler.

        // [THEN] Vendor Number, Total Amount, Withholding Tax Amount are correct
        VerifyValuesOnReport(
          VendorNumberCap, WithholdingTaxTotalAmountCap, WithholdingTaxWithholdingTaxAmountCap,
          WithholdingTax."Vendor No.", WithholdingTax."Total Amount", WithholdingTax."Withholding Tax Amount");

        // [THEN] Vendor Name = "A B", Vendor Address = "C"
        Vendor.Get(WithholdingTax."Vendor No.");
        VerifyVendorNameAndAddress(Vendor.Name + ' ' + Vendor."Name 2", Vendor.Address);
    end;

    [Test]
    [HandlerFunctions('ContributionRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ContributionReportSequentialContribType()
    var
        Contributions: Record Contributions;
        ContributionCode: Record "Contribution Code";
    begin
        // Purpose of the test is to verify that after running Contributions report with 2 different parameters sequentially
        // Contribution Payment line is not overridden, but added.
        Initialize();
        CreateContributions(Contributions, ContributionCode."Contribution Type"::INPS);
        RunContributionReport(ContributionCode."Contribution Type"::INPS);
        RunContributionReport(ContributionCode."Contribution Type"::INAIL);
        // Verify
        VerifyContributionPayment(ContributionCode."Contribution Type"::INPS, Contributions.Year, Contributions.Month);
        VerifyContributionPayment(ContributionCode."Contribution Type"::INAIL, Contributions.Year, Contributions.Month);
        Contributions.Get(Contributions."Entry No.");
        Assert.IsTrue(Contributions."INPS Paid", StrSubstNo(IncorrectValueErr, Contributions.FieldCaption("INPS Paid")));
        Assert.IsTrue(Contributions."INAIL Paid", StrSubstNo(IncorrectValueErr, Contributions.FieldCaption("INAIL Paid")));
    end;


    [Test]
    [HandlerFunctions('ConfirmHandler,WithholdingTaxesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WithholdingTaxesReport_EmptyTaxCode()
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        // [SCENARIO 485149] Withholding taxes report works for Withhold Tax with empty Tax Code
        Initialize();

        // [GIVEN] Create Withholding Tax with empty Tax Code for Vendor "XXX"
        CreateWithholdingTax(WithholdingTax, CreateVendor('', '', false), false);

        // [WHEN] Run report "Withholding Taxes"
        RunReportWithholdingTaxes();
        // UI Handled by WithholdingTaxesRequestPageHandler.

        // [THEN] Withholding Tax for Vendor = "XXX" is shown in report
        VerifyValuesOnReport(
          VendNoCap, TotalAmountCap, WithholdingTaxAmtWithholdingTaxCap,
          WithholdingTax."Vendor No.", WithholdingTax."Total Amount", WithholdingTax."Withholding Tax Amount");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        IsInitialized := true;
    end;

    local procedure CreateContributionCode(ContributionType: Option): Code[20]
    var
        ContributionCode: Record "Contribution Code";
        ContributionCodeLine: Record "Contribution Code Line";
    begin
        LibraryITLocalization.CreateContributionCode(ContributionCode, ContributionType);
        LibraryITLocalization.CreateContributionCodeLine(ContributionCodeLine, ContributionCode.Code, WorkDate(), ContributionType);
        exit(ContributionCode.Code);
    end;

    local procedure CreateContributions(var Contributions: Record Contributions; ContributionType: Option)
    var
        Contributions2: Record Contributions;
    begin
        Contributions."Entry No." := 1;
        if Contributions2.FindLast() then
            Contributions."Entry No." := Contributions2."Entry No." + 1;
        Contributions.Month := Date2DMY(WorkDate(), 2);  // 2 returns month.
        Contributions.Year := Date2DMY(WorkDate(), 3);  // 3 returns year.
        Contributions."Vendor No." := CreateVendor('', '', false);  // Blank Country/Region Code, VAT Registration No. and Individual Person mark FALSE.
        Contributions."Related Date" := WorkDate();
        Contributions."Payment Date" := WorkDate();
        Contributions."Gross Amount" := LibraryRandom.RandDec(10, 2);
        Contributions."Social Security Code" := CreateContributionCode(ContributionType);
        Contributions."INAIL Code" := Contributions."Social Security Code";
        Contributions."INAIL Total Amount" := LibraryRandom.RandDec(10, 2);
        Contributions."INAIL Gross Amount" := Contributions."INAIL Total Amount";
        Contributions.Insert();
    end;

    local procedure CreateCountryRegionCode(): Code[10]
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        VATRegistrationNoFormat."Country/Region Code" := CountryRegion.Code;
        VATRegistrationNoFormat.Format := LibraryUtility.GenerateGUID();
        VATRegistrationNoFormat.Insert();
        exit(VATRegistrationNoFormat."Country/Region Code");
    end;

    local procedure CreateVendor(VATRegistrationNo: Text[20]; CountryRegionCode: Code[10]; IndividualPerson: Boolean): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor);
        Vendor.Name := LibraryUtility.GenerateGUID();
        Vendor."Name 2" := LibraryUtility.GenerateGUID();
        Vendor.Address := LibraryUtility.GenerateGUID();
        Vendor."Individual Person" := IndividualPerson;
        Vendor."First Name" := LibraryUtility.GenerateGUID();
        Vendor."Last Name" := LibraryUtility.GenerateGUID();
        Vendor."Residence Address" := LibraryUtility.GenerateGUID();
        Vendor."Date of Birth" := WorkDate();
        Vendor."Fiscal Code" := Format(LibraryRandom.RandInt(100));
        Vendor."VAT Registration No." := VATRegistrationNo;
        Vendor."Country/Region Code" := CountryRegionCode;
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateVendorAndWithholdingTax(var Vendor: Record Vendor; VATRegistrationNo: Text[20]; CountryRegionCode: Code[10]; IndivisualPerson: Boolean)
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        Vendor.Get(CreateVendor(VATRegistrationNo, CountryRegionCode, IndivisualPerson));
        CreateWithholdingTax(WithholdingTax, Vendor."No.", true);
        EnqueueVendorNoAndDates(WithholdingTax."Vendor No.", WorkDate(), WorkDate());  // Enqueue Value for WithholdingTaxTestRequestPageHandler.
    end;

    local procedure CreateWithholdCode(): Code[20]
    var
        WithholdCode: Record "Withhold Code";
    begin
        WithholdCode.Code := LibraryUtility.GenerateRandomCode(WithholdCode.FieldNo(Code), DATABASE::"Withhold Code");
        WithholdCode.Insert();
        exit(WithholdCode.Code);
    end;

    local procedure CreateWithholdingTax(var WithholdingTax: Record "Withholding Tax"; VendorNo: Code[20]; FillInTaxCode: Boolean)
    var
        WithholdingTax2: Record "Withholding Tax";
    begin
        WithholdingTax."Entry No." := 1;
        if WithholdingTax2.FindLast() then
            WithholdingTax."Entry No." := WithholdingTax2."Entry No." + 1;
        WithholdingTax."Vendor No." := VendorNo;
        WithholdingTax."Payment Date" := WorkDate();
        WithholdingTax."Posting Date" := WorkDate();
        WithholdingTax."Related Date" := WorkDate();
        WithholdingTax."Total Amount" := LibraryRandom.RandDec(10, 2);
        WithholdingTax."Document No." := LibraryUtility.GenerateGUID();
        WithholdingTax."Withholding Tax %" := LibraryRandom.RandDec(10, 2);
        WithholdingTax.Month := Date2DMY(WorkDate(), 2);  // 2 returns month.
        WithholdingTax.Year := Date2DMY(WorkDate(), 3);  // 3 returns year.
        WithholdingTax."Withholding Tax Code" := CreateWithholdCode();
        WithholdingTax."Withholding Tax Amount" := WithholdingTax."Total Amount";
        if FillInTaxCode then
            WithholdingTax."Tax Code" := Format(LibraryRandom.RandIntInRange(1000, 9999));  // Using range for taking 4 character of Tax Code.
        WithholdingTax.Insert();
    end;

    local procedure CreateWithholdingTaxPayment(var WithholdingTaxPayment: Record "Withholding Tax Payment")
    var
        WithholdingTaxPayment2: Record "Withholding Tax Payment";
    begin
        WithholdingTaxPayment."Entry No." := 1;
        if WithholdingTaxPayment2.FindLast() then
            WithholdingTaxPayment."Entry No." := WithholdingTaxPayment2."Entry No." + 1;
        WithholdingTaxPayment."Payment Date" := WorkDate();
        WithholdingTaxPayment.Month := Date2DMY(WorkDate(), 2);  // 2 returns month.
        WithholdingTaxPayment.Year := Date2DMY(WorkDate(), 3);  // 3 returns year.
        WithholdingTaxPayment."Total Amount" := LibraryRandom.RandDec(10, 2);
        WithholdingTaxPayment."Withholding Tax Amount" := WithholdingTaxPayment."Total Amount";
        WithholdingTaxPayment."Tax Code" := Format(LibraryRandom.RandIntInRange(1000, 9999));  // Using range for taking 4 character of Tax Code.
        WithholdingTaxPayment.Insert();
    end;

    local procedure RunReportCompensationDetails()
    begin
        Commit();
        REPORT.Run(REPORT::"Compensation Details");
    end;

    local procedure RunReportWithholdingTaxes()
    begin
        Commit();
        REPORT.Run(REPORT::"Withholding Taxes");
    end;

    local procedure RunReportWithholdingTaxTest()
    begin
        Commit();
        REPORT.Run(REPORT::"Withholding Tax - Test");
    end;

    local procedure RunReportCertifications(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        Certifications: Report Certifications;
    begin
        Commit();
        Vendor.SetRange("No.", VendorNo);
        Certifications.SetTableView(Vendor);
        Certifications.RunModal();
    end;

    local procedure RunReportSummaryWithholdingPayment()
    begin
        Commit();
        REPORT.Run(REPORT::"Summary Withholding Payment");
    end;

    local procedure RunContributionReport(ContributionType: Option)
    begin
        LibraryVariableStorage.Enqueue(ContributionType); // Enqueue value for ContributionRequestPageHandler.
        Commit();
        REPORT.Run(REPORT::Contribution); // Opens handler - ContributionRequestPageHandler.
    end;

    local procedure EnqueueVendorNoAndDates(VendorNo: Code[20]; FromPaymentDate: Date; FromRelatedDate: Date)
    begin
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(FromPaymentDate);
        LibraryVariableStorage.Enqueue(FromRelatedDate);
    end;

    local procedure VerifyValuesOnReport(VendorNoCaption: Text; ExpectedCaption: Text; ExpectedCaption2: Text; VendorNo: Code[20]; ExpectedValue: Variant; ExpectedValue2: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VendorNoCaption, VendorNo);
        LibraryReportDataset.AssertElementWithValueExists(ExpectedCaption, ExpectedValue);
        LibraryReportDataset.AssertElementWithValueExists(ExpectedCaption2, ExpectedValue2);
    end;

    local procedure VerifyContributionPayment(ContribType: Option; ContribYear: Integer; ContribMonth: Integer)
    var
        DummyContributionPayment: Record "Contribution Payment";
    begin
        DummyContributionPayment.SetRange("Contribution Type", ContribType);
        DummyContributionPayment.SetRange(Year, ContribYear);
        DummyContributionPayment.SetRange(Month, ContribMonth);
        Assert.RecordIsNotEmpty(DummyContributionPayment);
    end;

    local procedure VerifyVendorNameAndAddress(ExpectedName: Text; ExpectedAddress: Text)
    begin
        LibraryReportDataset.AssertElementWithValueExists('Name__________Name_2_', ExpectedName);
        LibraryReportDataset.AssertElementWithValueExists('Vendor_Address', ExpectedAddress);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CertificationsRequestPageHandler(var Certifications: TestRequestPage Certifications)
    begin
        Certifications.FromPaymentDate.SetValue(WorkDate());
        Certifications.ToPaymentDate.SetValue(WorkDate());
        Certifications.FromRelatedDate.SetValue(WorkDate());
        Certifications.ToRelatedDate.SetValue(WorkDate());
        Certifications.INPSCertification.SetValue(true);
        Certifications.INAILCertification.SetValue(true);
        Certifications.ReportingFinale.SetValue(true);
        Certifications.PrintSubstituteData.SetValue(true);
        Certifications.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CompensationDetailsRequestPageHandler(var CompensationDetails: TestRequestPage "Compensation Details")
    var
        FromPaymentDate: Variant;
        FromRelatedDate: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(FromPaymentDate);
        LibraryVariableStorage.Dequeue(FromRelatedDate);
        CompensationDetails.Vendor.SetFilter("No.", No);
        CompensationDetails.FromPaymentDate.SetValue(FromPaymentDate);
        CompensationDetails.ToPaymentDate.SetValue(WorkDate());
        CompensationDetails.FromRelatedDate.SetValue(FromRelatedDate);
        CompensationDetails.ToRelatedDate.SetValue(WorkDate());
        CompensationDetails.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ContributionRequestPageHandler(var Contribution: TestRequestPage Contribution)
    var
        ContributionType: Variant;
    begin
        LibraryVariableStorage.Dequeue(ContributionType);
        Contribution.ContributionType.SetValue(ContributionType);
        Contribution.FinalPrinting.SetValue(true);
        Contribution.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SummaryWithholdingPaymentRequestPageHandler(var SummaryWithholdingPayment: TestRequestPage "Summary Withholding Payment")
    begin
        SummaryWithholdingPayment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WithholdingTaxesRequestPageHandler(var WithholdingTaxes: TestRequestPage "Withholding Taxes")
    begin
        WithholdingTaxes.FinalPrinting.SetValue(true);
        WithholdingTaxes.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WithholdingTaxTestRequestPageHandler(var WithholdingTaxTest: TestRequestPage "Withholding Tax - Test")
    var
        No: Variant;
        StartDate: Variant;
        EndDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        WithholdingTaxTest.Vendor.SetFilter("No.", No);
        WithholdingTaxTest.StartingDate.SetValue(StartDate);
        WithholdingTaxTest.EndingDate.SetValue(EndDate);
        WithholdingTaxTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

