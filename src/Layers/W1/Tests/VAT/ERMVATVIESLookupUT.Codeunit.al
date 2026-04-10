codeunit 134193 "ERM VAT VIES Lookup UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Registration No.] [VAT Registration Log] [UT]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        DefaultTxt: Label 'Default';
        CustomerUpdatedMsg: Label 'The customer has been updated.';
        VendorUpdatedMsg: Label 'The vendor has been updated.';
        ContactUpdatedMsg: Label 'The contact has been updated.';
        CompInfoUpdatedMsg: Label 'The company information has been updated.';
        TemplateAccountType: Enum "VAT Reg. No. Srv. Template Account Type";
        VATRegLogAccountType: Enum "VAT Registration Log Account Type";
        VATRegLogDetailsStatus: Enum "VAT Reg. Log Details Status";
        VATRegLogDetailsFieldStatus: Enum "VAT Reg. Log Details Field Status";
        NameTxt: Label 'Name', Locked = true;
        Name2Txt: Label 'Name2', Locked = true;
        StreetTxt: Label 'Street', Locked = true;
        Street2Txt: Label 'Street2', Locked = true;
        CityTxt: Label 'CITY', Locked = true;
        City2Txt: Label 'CITY2', Locked = true;
        PostCodeTxt: Label 'POSTCODE', Locked = true;
        PostCode2Txt: Label 'POSTCODE2', Locked = true;
        Address2Txt: Label 'Address2', Locked = true;
        WrongLogEntryOnPageErr: Label 'Unexpected entry in VAT Registration Log page.';

    [Test]
    procedure CheckInitDefaultTemplate()
    var
        VATRegNoSrvTemplate: Record "VAT Reg. No. Srv. Template";
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        // [SCENARIO 342180] TAB 226 "VAT Reg. No. Srv. Template".CheckInitDefaultTemplate()
        Initialize();
        VerifyDefaultTemplateAbsence();
        VATRegNoSrvConfig.Get();

        VATRegNoSrvTemplate.CheckInitDefaultTemplate(VATRegNoSrvConfig);

        VATRegNoSrvTemplate.FindFirst();
        VATRegNoSrvTemplate.TestField(Code, DefaultTxt);
        VATRegNoSrvTemplate.TestField("Country/Region Code", '');
        VATRegNoSrvTemplate.TestField("Account Type", VATRegNoSrvTemplate."Account Type"::None);
        VATRegNoSrvTemplate.TestField("Account No.", '');
        VATRegNoSrvTemplate.TestField("Validate Name", false);
        VATRegNoSrvTemplate.TestField("Validate City", false);
        VATRegNoSrvTemplate.TestField("Validate Post Code", false);
        VATRegNoSrvTemplate.TestField("Validate Street", false);
        VATRegNoSrvTemplate.TestField("Ignore Details", false);

        VATRegNoSrvConfig.TestField("Default Template Code", DefaultTxt);
    end;

    [Test]
    procedure InitDefaultTemplateOnOpenSetupPage()
    var
        VATRegistrationConfig: TestPage "VAT Registration Config";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 342180] Default template is auto initialized for the very first open of VAT VIES Setup page
        Initialize();
        VerifyDefaultTemplateAbsence();

        VATRegistrationConfig.OpenEdit();
        VATRegistrationConfig.Close();

        VeriftDefaultTemplatePresence();
    end;

    [Test]
    procedure InitDefaultTemplateOnOpenTemplatesPage()
    var
        VATRegNoSrvTemplates: TestPage "VAT Reg. No. Srv. Templates";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 342180] Default template is auto initialized for the very first open of Templates page
        Initialize();
        VerifyDefaultTemplateAbsence();

        VATRegNoSrvTemplates.OpenEdit();
        VATRegNoSrvTemplates.Close();

        VeriftDefaultTemplatePresence();
    end;

    [Test]
    procedure InitDefaultTemplateOnFindTemplate()
    var
        VATRegNoSrvTemplate: Record "VAT Reg. No. Srv. Template";
        DummyVATRegistrationLog: Record "VAT Registration Log";
        TemplateCode: Code[20];
    begin
        // [SCENARIO 342180] Default template is auto initialized for the very first call of
        // [SCENARIO 342180] TAB 226 "VAT Reg. No. Srv. Template".FindTemplate()
        Initialize();
        VerifyDefaultTemplateAbsence();

        TemplateCode := VATRegNoSrvTemplate.FindTemplate(DummyVATRegistrationLog);

        Assert.AreEqual(UpperCase(DefaultTxt), TemplateCode, 'Default template');
        VeriftDefaultTemplatePresence();
    end;

    [Test]
    procedure FindTemplate()
    begin
        // [SCENARIO 342180] TAB 226 "VAT Reg. No. Srv. Template".FindTemplate()
        Initialize();
        InitDefaultTemplate();

        MockTemplateWithDisabledValidation('1', '', TemplateAccountType::None, '');
        MockTemplateWithDisabledValidation('2', 'DE', TemplateAccountType::None, '');
        MockTemplateWithDisabledValidation('3', 'ES', TemplateAccountType::None, '');
        MockTemplateWithDisabledValidation('4', 'DE', TemplateAccountType::Contact, '');
        MockTemplateWithDisabledValidation('5', 'DE', TemplateAccountType::Customer, '');
        MockTemplateWithDisabledValidation('6', 'DE', TemplateAccountType::Vendor, '');
        MockTemplateWithDisabledValidation('7', 'DE', TemplateAccountType::Contact, '10000');
        MockTemplateWithDisabledValidation('8', 'DE', TemplateAccountType::Customer, '10000');
        MockTemplateWithDisabledValidation('9', 'DE', TemplateAccountType::Vendor, '10000');

        VerifyTemplateSelection(UpperCase(DefaultTxt), 'FR', VATRegLogAccountType::Customer, '10000');
        VerifyTemplateSelection('3', 'ES', VATRegLogAccountType::Customer, '10000');
        VerifyTemplateSelection('8', 'DE', VATRegLogAccountType::Customer, '10000');
        VerifyTemplateSelection('9', 'DE', VATRegLogAccountType::Vendor, '10000');
        VerifyTemplateSelection('7', 'DE', VATRegLogAccountType::Contact, '10000');
        VerifyTemplateSelection('5', 'DE', VATRegLogAccountType::Customer, '20000');
        VerifyTemplateSelection('6', 'DE', VATRegLogAccountType::Vendor, '20000');
        VerifyTemplateSelection('4', 'DE', VATRegLogAccountType::Contact, '20000');
        VerifyTemplateSelection('2', 'DE', VATRegLogAccountType::"Company Information", '');
    end;

    [Test]
    procedure VATRegLogPage()
    var
        VATRegistrationLogPage: TestPage "VAT Registration Log";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 342180] Page 249 "VAT Registration Log" fields and actions visibility
        Initialize();

        VATRegistrationLogPage.OpenEdit();
        Assert.IsTrue(VATRegistrationLogPage."Country/Region Code".Visible(), 'Country/Region Code');
        Assert.IsTrue(VATRegistrationLogPage."VAT Registration No.".Visible(), 'VAT Registration No.');
        Assert.IsTrue(VATRegistrationLogPage.Status.Visible(), 'Status');
        Assert.IsTrue(VATRegistrationLogPage."Verified Date".Visible(), 'Verified Date');
        Assert.IsTrue(VATRegistrationLogPage."Request Identifier".Visible(), 'Request Identifier');
        Assert.IsTrue(VATRegistrationLogPage."Details Status".Visible(), 'Details Status');
        VATRegistrationLogPage.Close();

        VerifyValidationDetailActionVisbility(VATRegLogDetailsStatus::"Not Verified", false);
        VerifyValidationDetailActionVisbility(VATRegLogDetailsStatus::Valid, true);
        VerifyValidationDetailActionVisbility(VATRegLogDetailsStatus::"Not Valid", true);
        VerifyValidationDetailActionVisbility(VATRegLogDetailsStatus::"Partially Valid", true);
        VerifyValidationDetailActionVisbility(VATRegLogDetailsStatus::Ignored, true);
    end;

    [Test]
    procedure VATRegDetailsLogPage()
    var
        DummyVATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 342180] Page 247 "VAT Registration Log Details" fields and actions visibility
        Initialize();

        VerifyDetailsPageActionsVisbility('', DummyVATRegistrationLogDetails.Status::Valid, false, false);
        VerifyDetailsPageActionsVisbility('', DummyVATRegistrationLogDetails.Status::"Not Valid", false, false);

        VerifyDetailsPageActionsVisbility('1', DummyVATRegistrationLogDetails.Status::Valid, false, false);
        VerifyDetailsPageActionsVisbility('1', DummyVATRegistrationLogDetails.Status::"Not Valid", true, false);
        VerifyDetailsPageActionsVisbility('1', DummyVATRegistrationLogDetails.Status::Accepted, false, true);
        VerifyDetailsPageActionsVisbility('1', DummyVATRegistrationLogDetails.Status::Applied, false, false);
    end;

    [Test]
    procedure VATRegDetailsLogPageAcceptAction()
    var
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
        VATRegistrationLogDetailsPage: TestPage "VAT Registration Log Details";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 342180] Page 247 "VAT Registration Log Details" "Accept" action
        Initialize();

        MockVATRegLogDetail(VATRegistrationLogDetails, '1', VATRegLogDetailsFieldStatus::"Not Valid");

        VATRegistrationLogDetailsPage.OpenEdit();
        VATRegistrationLogDetailsPage.GoToRecord(VATRegistrationLogDetails);
        VATRegistrationLogDetailsPage.Accept.Invoke();
        VATRegistrationLogDetailsPage.Close();

        VATRegistrationLogDetails.Find();
        VATRegistrationLogDetails.TestField(Status, VATRegLogDetailsFieldStatus::Accepted);
    end;

    [Test]
    procedure VATRegDetailsLogPageResetAction()
    var
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
        VATRegistrationLogDetailsPage: TestPage "VAT Registration Log Details";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 342180] Page 247 "VAT Registration Log Details" "Reset" action
        Initialize();

        MockVATRegLogDetail(VATRegistrationLogDetails, '1', VATRegLogDetailsFieldStatus::Accepted);

        VATRegistrationLogDetailsPage.OpenEdit();
        VATRegistrationLogDetailsPage.GoToRecord(VATRegistrationLogDetails);
        VATRegistrationLogDetailsPage.Reset.Invoke();
        VATRegistrationLogDetailsPage.Close();

        VATRegistrationLogDetails.Find();
        VATRegistrationLogDetails.TestField(Status, VATRegLogDetailsFieldStatus::"Not Valid");
    end;

    [Test]
    procedure LogDetails_AllResponse_DefTemplate()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".LogDetails() in case of all response values and default template
        Initialize();

        MockVATRegLog(VATRegistrationLog, VATRegLogDetailsStatus::"Not Verified");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Customer, '10000');
        VATRegistrationLog.SetAccountDetails(NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        VATRegistrationLog.SetResponseDetails(Name2Txt, Address2Txt, Street2Txt, City2Txt, PostCode2Txt);

        Assert.AreEqual(true, VATRegistrationLog.LogDetails(), 'VATRegistrationLog.LogDetails()');
        VATRegistrationLog.TestField("Details Status", VATRegistrationLog."Details Status"::"Not Valid");
        Assert.RecordCount(VATRegistrationLogDetails, 5);

        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::Name,
          '', NameTxt, Name2Txt, VATRegLogDetailsFieldStatus::"Not Valid");
        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::Address,
          '', StreetTxt, Address2Txt, VATRegLogDetailsFieldStatus::"Not Valid");
        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::Street,
          '', StreetTxt, Street2Txt, VATRegLogDetailsFieldStatus::"Not Valid");
        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::City,
          '', CityTxt, City2Txt, VATRegLogDetailsFieldStatus::"Not Valid");
        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::"Post Code",
          '', PostCodeTxt, PostCode2Txt, VATRegLogDetailsFieldStatus::"Not Valid");
    end;

    [Test]
    procedure LogDetails_NoResponse_DefTemplate()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".LogDetails() in case of no response values and default template
        Initialize();

        MockVATRegLog(VATRegistrationLog, VATRegLogDetailsStatus::"Not Verified");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Customer, '10000');
        VATRegistrationLog.SetAccountDetails(NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        VATRegistrationLog.SetResponseDetails('', '', '', '', '');

        Assert.AreEqual(false, VATRegistrationLog.LogDetails(), 'VATRegistrationLog.LogDetails()');
        VATRegistrationLog.TestField("Details Status", VATRegistrationLog."Details Status"::"Not Verified");
        Assert.RecordIsEmpty(VATRegistrationLogDetails);
    end;

    [Test]
    procedure LogDetails_NoResponse_AllCheckTemplate()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".LogDetails() in case of all response values and all check template
        Initialize();
        MockTemplate('T', 'GB', TemplateAccountType::None, '', true, true, true, true, false);

        MockVATRegLog(VATRegistrationLog, VATRegLogDetailsStatus::"Not Verified");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Customer, '10000');
        VATRegistrationLog.SetAccountDetails(NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        VATRegistrationLog.SetResponseDetails('', '', '', '', '');

        Assert.AreEqual(true, VATRegistrationLog.LogDetails(), 'VATRegistrationLog.LogDetails()');
        VATRegistrationLog.TestField("Details Status", VATRegistrationLog."Details Status"::"Not Valid");
        Assert.RecordCount(VATRegistrationLogDetails, 4);

        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::Name,
          NameTxt, NameTxt, '', VATRegLogDetailsFieldStatus::"Not Valid");
        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::Street,
          StreetTxt, StreetTxt, '', VATRegLogDetailsFieldStatus::"Not Valid");
        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::City,
          CityTxt, CityTxt, '', VATRegLogDetailsFieldStatus::"Not Valid");
        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::"Post Code",
          PostCodeTxt, PostCodeTxt, '', VATRegLogDetailsFieldStatus::"Not Valid");
    end;

    [Test]
    procedure LogDetails_AllResponse_AllCheckTemplate()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".LogDetails() in case of all response values and all check template
        Initialize();
        MockTemplate('T', 'GB', TemplateAccountType::None, '', true, true, true, true, false);

        MockVATRegLog(VATRegistrationLog, VATRegLogDetailsStatus::"Not Verified");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Customer, '10000');
        VATRegistrationLog.SetAccountDetails(NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        VATRegistrationLog.SetResponseDetails(Name2Txt, Address2Txt, Street2Txt, City2Txt, PostCode2Txt);

        Assert.AreEqual(true, VATRegistrationLog.LogDetails(), 'VATRegistrationLog.LogDetails()');
        VATRegistrationLog.TestField("Details Status", VATRegistrationLog."Details Status"::"Not Valid");
        Assert.RecordCount(VATRegistrationLogDetails, 5);

        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::Name,
          NameTxt, NameTxt, Name2Txt, VATRegLogDetailsFieldStatus::"Not Valid");
        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::Address,
          '', StreetTxt, Address2Txt, VATRegLogDetailsFieldStatus::"Not Valid");
        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::Street,
          StreetTxt, StreetTxt, Street2Txt, VATRegLogDetailsFieldStatus::"Not Valid");
        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::City,
          CityTxt, CityTxt, City2Txt, VATRegLogDetailsFieldStatus::"Not Valid");
        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::"Post Code",
          PostCodeTxt, PostCodeTxt, PostCode2Txt, VATRegLogDetailsFieldStatus::"Not Valid");
    end;

    [Test]
    procedure LogDetails_Name_Matched()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".LogDetails() in case of all "Name" value matched
        Initialize();
        MockTemplate('T', 'GB', TemplateAccountType::None, '', true, false, false, false, false);

        MockVATRegLog(VATRegistrationLog, VATRegLogDetailsStatus::"Not Verified");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Customer, '10000');
        VATRegistrationLog.SetAccountDetails(NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        VATRegistrationLog.SetResponseMatchDetails(true, false, false, false);

        Assert.AreEqual(true, VATRegistrationLog.LogDetails(), 'VATRegistrationLog.LogDetails()');
        VATRegistrationLog.TestField("Details Status", VATRegistrationLog."Details Status"::Valid);
        Assert.RecordCount(VATRegistrationLogDetails, 1);

        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::Name,
          NameTxt, NameTxt, '', VATRegLogDetailsFieldStatus::Valid);
    end;

    [Test]
    procedure LogDetails_Name_NotMatched()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".LogDetails() in case of all "Name" value not matched
        Initialize();
        MockTemplate('T', 'GB', TemplateAccountType::None, '', true, false, false, false, false);

        MockVATRegLog(VATRegistrationLog, VATRegLogDetailsStatus::"Not Verified");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Customer, '10000');
        VATRegistrationLog.SetAccountDetails(NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        VATRegistrationLog.SetResponseMatchDetails(false, false, false, false);

        Assert.AreEqual(true, VATRegistrationLog.LogDetails(), 'VATRegistrationLog.LogDetails()');
        VATRegistrationLog.TestField("Details Status", VATRegistrationLog."Details Status"::"Not Valid");
        Assert.RecordCount(VATRegistrationLogDetails, 1);

        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::Name,
          NameTxt, NameTxt, '', VATRegLogDetailsFieldStatus::"Not Valid");
    end;

    [Test]
    procedure LogDetails_Street_Matched()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".LogDetails() in case of all "Street" value matched
        Initialize();
        MockTemplate('T', 'GB', TemplateAccountType::None, '', false, false, true, false, false);

        MockVATRegLog(VATRegistrationLog, VATRegLogDetailsStatus::"Not Verified");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Customer, '10000');
        VATRegistrationLog.SetAccountDetails(NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        VATRegistrationLog.SetResponseMatchDetails(false, true, false, false);

        Assert.AreEqual(true, VATRegistrationLog.LogDetails(), 'VATRegistrationLog.LogDetails()');
        VATRegistrationLog.TestField("Details Status", VATRegistrationLog."Details Status"::Valid);
        Assert.RecordCount(VATRegistrationLogDetails, 1);

        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::Street,
          StreetTxt, StreetTxt, '', VATRegLogDetailsFieldStatus::Valid);
    end;

    [Test]
    procedure LogDetails_Street_NotMatched()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".LogDetails() in case of all "Street" value not matched
        Initialize();
        MockTemplate('T', 'GB', TemplateAccountType::None, '', false, false, true, false, false);

        MockVATRegLog(VATRegistrationLog, VATRegLogDetailsStatus::"Not Verified");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Customer, '10000');
        VATRegistrationLog.SetAccountDetails(NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        VATRegistrationLog.SetResponseMatchDetails(false, false, false, false);

        Assert.AreEqual(true, VATRegistrationLog.LogDetails(), 'VATRegistrationLog.LogDetails()');
        VATRegistrationLog.TestField("Details Status", VATRegistrationLog."Details Status"::"Not Valid");
        Assert.RecordCount(VATRegistrationLogDetails, 1);

        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::Street,
          StreetTxt, StreetTxt, '', VATRegLogDetailsFieldStatus::"Not Valid");
    end;

    [Test]
    procedure LogDetails_City_Matched()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".LogDetails() in case of all "City" value matched
        Initialize();
        MockTemplate('T', 'GB', TemplateAccountType::None, '', false, true, false, false, false);

        MockVATRegLog(VATRegistrationLog, VATRegLogDetailsStatus::"Not Verified");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Customer, '10000');
        VATRegistrationLog.SetAccountDetails(NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        VATRegistrationLog.SetResponseMatchDetails(false, false, true, false);

        Assert.AreEqual(true, VATRegistrationLog.LogDetails(), 'VATRegistrationLog.LogDetails()');
        VATRegistrationLog.TestField("Details Status", VATRegistrationLog."Details Status"::Valid);
        Assert.RecordCount(VATRegistrationLogDetails, 1);

        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::City,
          CityTxt, CityTxt, '', VATRegLogDetailsFieldStatus::Valid);
    end;

    [Test]
    procedure LogDetails_City_NotMatched()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".LogDetails() in case of all "City" value not matched
        Initialize();
        MockTemplate('T', 'GB', TemplateAccountType::None, '', false, true, false, false, false);

        MockVATRegLog(VATRegistrationLog, VATRegLogDetailsStatus::"Not Verified");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Customer, '10000');
        VATRegistrationLog.SetAccountDetails(NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        VATRegistrationLog.SetResponseMatchDetails(false, false, false, false);

        Assert.AreEqual(true, VATRegistrationLog.LogDetails(), 'VATRegistrationLog.LogDetails()');
        VATRegistrationLog.TestField("Details Status", VATRegistrationLog."Details Status"::"Not Valid");
        Assert.RecordCount(VATRegistrationLogDetails, 1);

        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::City,
          CityTxt, CityTxt, '', VATRegLogDetailsFieldStatus::"Not Valid");
    end;

    [Test]
    procedure LogDetails_PostCode_Matched()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".LogDetails() in case of all "Post Code" value matched
        Initialize();
        MockTemplate('T', 'GB', TemplateAccountType::None, '', false, false, false, true, false);

        MockVATRegLog(VATRegistrationLog, VATRegLogDetailsStatus::"Not Verified");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Customer, '10000');
        VATRegistrationLog.SetAccountDetails(NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        VATRegistrationLog.SetResponseMatchDetails(false, false, false, true);

        Assert.AreEqual(true, VATRegistrationLog.LogDetails(), 'VATRegistrationLog.LogDetails()');
        VATRegistrationLog.TestField("Details Status", VATRegistrationLog."Details Status"::Valid);
        Assert.RecordCount(VATRegistrationLogDetails, 1);

        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::"Post Code",
          PostCodeTxt, PostCodeTxt, '', VATRegLogDetailsFieldStatus::Valid);
    end;

    [Test]
    procedure LogDetails_PostCode_NotMatched()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".LogDetails() in case of all "Post Code" value not matched
        Initialize();
        MockTemplate('T', 'GB', TemplateAccountType::None, '', false, false, false, true, false);

        MockVATRegLog(VATRegistrationLog, VATRegLogDetailsStatus::"Not Verified");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Customer, '10000');
        VATRegistrationLog.SetAccountDetails(NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        VATRegistrationLog.SetResponseMatchDetails(false, false, false, false);

        Assert.AreEqual(true, VATRegistrationLog.LogDetails(), 'VATRegistrationLog.LogDetails()');
        VATRegistrationLog.TestField("Details Status", VATRegistrationLog."Details Status"::"Not Valid");
        Assert.RecordCount(VATRegistrationLogDetails, 1);

        VerifyDetailsLog(
          VATRegistrationLog, VATRegistrationLogDetails."Field Name"::"Post Code",
          PostCodeTxt, PostCodeTxt, '', VATRegLogDetailsFieldStatus::"Not Valid");
    end;

    [Test]
    [HandlerFunctions('DetailsValidationAcceptAllMPH,MessageHandler')]
    procedure Customer_AcceptAll_UI()
    var
        Customer: Record Customer;
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".OpenModifyDetails() and Accept All for customer
        Initialize();
        PrepareCustomerLog(Customer, VATRegistrationLog);

        VATRegistrationLog.OpenModifyDetails();

        Assert.ExpectedMessage(CustomerUpdatedMsg, LibraryVariableStorage.DequeueText());
        VerifyCustomer(Customer, Name2Txt, Street2Txt, City2Txt, PostCode2Txt);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DetailsValidationAcceptAllMPH,MessageHandler')]
    procedure Vendor_AcceptAll_UI()
    var
        Vendor: Record Vendor;
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".OpenModifyDetails() and Accept All for vendor
        Initialize();
        PrepareVendorLog(Vendor, VATRegistrationLog);

        VATRegistrationLog.OpenModifyDetails();

        Assert.ExpectedMessage(VendorUpdatedMsg, LibraryVariableStorage.DequeueText());
        VerifyVendor(Vendor, Name2Txt, Street2Txt, City2Txt, PostCode2Txt);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DetailsValidationAcceptAllMPH,MessageHandler')]
    procedure Contact_AcceptAll_UI()
    var
        Contact: Record Contact;
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".OpenModifyDetails() and Accept All for contact
        Initialize();
        PrepareContactLog(Contact, VATRegistrationLog);

        VATRegistrationLog.OpenModifyDetails();

        Assert.ExpectedMessage(ContactUpdatedMsg, LibraryVariableStorage.DequeueText());
        VerifyContact(Contact, Name2Txt, Street2Txt, City2Txt, PostCode2Txt);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DetailsValidationAcceptAllMPH,MessageHandler')]
    procedure CompanyInfo_AcceptAll_UI()
    var
        CompanyInformation: Record "Company Information";
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".OpenModifyDetails() and Accept All for company information
        Initialize();
        PrepareCompanyInfoLog(CompanyInformation, VATRegistrationLog);

        VATRegistrationLog.OpenModifyDetails();

        Assert.ExpectedMessage(CompInfoUpdatedMsg, LibraryVariableStorage.DequeueText());
        VerifyCompanyInfo(CompanyInformation, Name2Txt, Street2Txt, City2Txt, PostCode2Txt);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DetailsValidationAcceptOneValueMPH,MessageHandler')]
    procedure Customer_AcceptOnlyName_UI()
    var
        Customer: Record Customer;
        VATRegistrationLog: Record "VAT Registration Log";
        DummyVATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".OpenModifyDetails() and Accept only Name for customer
        Initialize();
        PrepareCustomerLog(Customer, VATRegistrationLog);

        LibraryVariableStorage.Enqueue(Format(DummyVATRegistrationLogDetails."Field Name"::Name));
        VATRegistrationLog.OpenModifyDetails();

        Assert.ExpectedMessage(CustomerUpdatedMsg, LibraryVariableStorage.DequeueText());
        VerifyCustomer(Customer, Name2Txt, StreetTxt, CityTxt, PostCodeTxt);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DetailsValidationAcceptOneValueMPH,MessageHandler')]
    procedure Vendor_AcceptOnlyStreet_UI()
    var
        Vendor: Record Vendor;
        VATRegistrationLog: Record "VAT Registration Log";
        DummyVATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".OpenModifyDetails() and Accept only Street for vendor
        Initialize();
        PrepareVendorLog(Vendor, VATRegistrationLog);

        LibraryVariableStorage.Enqueue(Format(DummyVATRegistrationLogDetails."Field Name"::Street));
        VATRegistrationLog.OpenModifyDetails();

        Assert.ExpectedMessage(VendorUpdatedMsg, LibraryVariableStorage.DequeueText());
        VerifyVendor(Vendor, NameTxt, Street2Txt, CityTxt, PostCodeTxt);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DetailsValidationAcceptOneValueMPH,MessageHandler')]
    procedure Contact_AcceptOnlyCity_UI()
    var
        Contact: Record Contact;
        VATRegistrationLog: Record "VAT Registration Log";
        DummyVATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".OpenModifyDetails() and Accept only City for contact
        Initialize();
        PrepareContactLog(Contact, VATRegistrationLog);

        LibraryVariableStorage.Enqueue(Format(DummyVATRegistrationLogDetails."Field Name"::City));
        VATRegistrationLog.OpenModifyDetails();

        Assert.ExpectedMessage(ContactUpdatedMsg, LibraryVariableStorage.DequeueText());
        VerifyContact(Contact, NameTxt, StreetTxt, City2Txt, PostCodeTxt);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DetailsValidationAcceptOneValueMPH,MessageHandler')]
    procedure CompanyInfo_AcceptOnlyPostCode_UI()
    var
        CompanyInformation: Record "Company Information";
        VATRegistrationLog: Record "VAT Registration Log";
        DummyVATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 342180] TAB 249 "VAT Registration Log".OpenModifyDetails() and Accept only post code for company information
        Initialize();
        PrepareCompanyInfoLog(CompanyInformation, VATRegistrationLog);

        LibraryVariableStorage.Enqueue(Format(DummyVATRegistrationLogDetails."Field Name"::"Post Code"));
        VATRegistrationLog.OpenModifyDetails();

        Assert.ExpectedMessage(CompInfoUpdatedMsg, LibraryVariableStorage.DequeueText());
        VerifyCompanyInfo(CompanyInformation, NameTxt, StreetTxt, CityTxt, PostCode2Txt);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DetailsValidationAcceptAllMPH,MessageHandler')]
    procedure CustomerIsUpdatedOnContactUpdate()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        ContactBusinessRelation: Record "Contact Business Relation";
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 396853] Customer record is updated when linked contact details are updated from VAT VIES validation
        Initialize();
        PrepareContactLog(Contact, VATRegistrationLog);
        MockCustomer(Customer, '', '', '', '');
        MockContBusRelation(Contact."No.", ContactBusinessRelation."Link to Table"::Customer, Customer."No.");

        VATRegistrationLog.OpenModifyDetails();

        Assert.ExpectedMessage(ContactUpdatedMsg, LibraryVariableStorage.DequeueText());
        VerifyCustomer(Customer, Name2Txt, Street2Txt, City2Txt, PostCode2Txt);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DetailsValidationAcceptAllMPH,MessageHandler')]
    procedure VendorIsUpdatedOnContactUpdate()
    var
        Contact: Record Contact;
        Vendor: Record Vendor;
        ContactBusinessRelation: Record "Contact Business Relation";
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 396853] Vendor record is updated when linked contact details are updated from VAT VIES validation
        Initialize();
        PrepareContactLog(Contact, VATRegistrationLog);
        MockVendor(Vendor, '', '', '', '');
        MockContBusRelation(Contact."No.", ContactBusinessRelation."Link to Table"::Vendor, Vendor."No.");

        VATRegistrationLog.OpenModifyDetails();

        Assert.ExpectedMessage(ContactUpdatedMsg, LibraryVariableStorage.DequeueText());
        VerifyVendor(Vendor, Name2Txt, Street2Txt, City2Txt, PostCode2Txt);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DetailsValidationAcceptAllMPH,MessageHandler')]
    procedure ContactIsUpdatedOnCustomerUpdate()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 342180] Contact record is updated when linked customer details are updated from VAT VIES validation
        Initialize();
        PrepareCustomerLog(Customer, VATRegistrationLog);
        MockContact(Contact, '', '', '', '');
        MockContBusRelation(Contact."No.", ContactBusinessRelation."Link to Table"::Customer, Customer."No.");

        VATRegistrationLog.OpenModifyDetails();

        Assert.ExpectedMessage(CustomerUpdatedMsg, LibraryVariableStorage.DequeueText());
        VerifyContact(Contact, Name2Txt, Street2Txt, City2Txt, PostCode2Txt);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DetailsValidationAcceptAllMPH,MessageHandler')]
    procedure ContactIsUpdatedOnVendorUpdate()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 342180] Contact record is updated when linked vendor details are updated from VAT VIES validation
        Initialize();
        PrepareVendorLog(Vendor, VATRegistrationLog);
        MockContact(Contact, '', '', '', '');
        MockContBusRelation(Contact."No.", ContactBusinessRelation."Link to Table"::Vendor, Vendor."No.");

        VATRegistrationLog.OpenModifyDetails();

        Assert.ExpectedMessage(VendorUpdatedMsg, LibraryVariableStorage.DequeueText());
        VerifyContact(Contact, Name2Txt, Street2Txt, City2Txt, PostCode2Txt);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure LogDetails_AllResponse_Ignored()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [SCENARIO 410603] TAB "VAT Registration Log" "VAT Registration Log".LogDetails() in case of all response values and Ignore Details enabled
        Initialize();
        MockTemplate('T', 'GB', TemplateAccountType::None, '', false, false, false, false, true);

        MockVATRegLog(VATRegistrationLog, VATRegistrationLog."Details Status"::"Not Verified");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Customer, '10000');
        VATRegistrationLog.SetAccountDetails(NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        VATRegistrationLog.SetResponseDetails(Name2Txt, Address2Txt, Street2Txt, City2Txt, PostCode2Txt);

        Assert.AreEqual(true, VATRegistrationLog.LogDetails(), 'VATRegistrationLog.LogDetails');
        VATRegistrationLog.TestField("Details Status", VATRegistrationLog."Details Status"::Ignored);
        Assert.RecordCount(VATRegistrationLogDetails, 5);

        VerifyDetailsLog(
            VATRegistrationLog, VATRegistrationLogDetails."Field Name"::Name,
            '', NameTxt, Name2Txt, VATRegistrationLogDetails.Status::"Not Valid");
        VerifyDetailsLog(
            VATRegistrationLog, VATRegistrationLogDetails."Field Name"::Address,
            '', StreetTxt, Address2Txt, VATRegistrationLogDetails.Status::"Not Valid");
        VerifyDetailsLog(
            VATRegistrationLog, VATRegistrationLogDetails."Field Name"::Street,
            '', StreetTxt, Street2Txt, VATRegistrationLogDetails.Status::"Not Valid");
        VerifyDetailsLog(
            VATRegistrationLog, VATRegistrationLogDetails."Field Name"::City,
            '', CityTxt, City2Txt, VATRegistrationLogDetails.Status::"Not Valid");
        VerifyDetailsLog(
            VATRegistrationLog, VATRegistrationLogDetails."Field Name"::"Post Code",
            '', PostCodeTxt, PostCode2Txt, VATRegistrationLogDetails.Status::"Not Valid");
    end;

    [Test]
    procedure LogDetails_NoResponse_Ignored()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [SCENARIO 410603] TAB 249 "VAT Registration Log".LogDetails() in case of no response values and Ignore Details enabled
        Initialize();
        MockTemplate('T', 'GB', TemplateAccountType::None, '', false, false, false, false, true);

        MockVATRegLog(VATRegistrationLog, VATRegistrationLog."Details Status"::"Not Verified");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Customer, '10000');
        VATRegistrationLog.SetAccountDetails(NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        VATRegistrationLog.SetResponseDetails('', '', '', '', '');

        Assert.AreEqual(false, VATRegistrationLog.LogDetails(), 'VATRegistrationLog.LogDetails');
        VATRegistrationLog.TestField("Details Status", VATRegistrationLog."Details Status"::"Not Verified");
        Assert.RecordIsEmpty(VATRegistrationLogDetails);
    end;

    [Test]
    procedure LogDetails_Name_Matched_Ignored()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [SCENARIO 410603] TAB 249 "VAT Registration Log".LogDetails() in case of "Name" value matched and Ignore Details enabled
        Initialize();
        MockTemplate('T', 'GB', TemplateAccountType::None, '', true, false, false, false, true);

        MockVATRegLog(VATRegistrationLog, VATRegistrationLog."Details Status"::"Not Verified");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Customer, '10000');
        VATRegistrationLog.SetAccountDetails(NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        VATRegistrationLog.SetResponseMatchDetails(true, false, false, false);

        Assert.AreEqual(true, VATRegistrationLog.LogDetails(), 'VATRegistrationLog.LogDetails');
        VATRegistrationLog.TestField("Details Status", VATRegistrationLog."Details Status"::Ignored);
        Assert.RecordCount(VATRegistrationLogDetails, 1);

        VerifyDetailsLog(
            VATRegistrationLog, VATRegistrationLogDetails."Field Name"::Name,
            NameTxt, NameTxt, '', VATRegistrationLogDetails.Status::Valid);
    end;

    [Test]
    procedure LogDetails_Name_NotMatched_Ignored()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        // [SCENARIO 410603] TAB 249 "VAT Registration Log".LogDetails() in case of "Name" value not matched and Ignore Details enabled
        Initialize();
        MockTemplate('T', 'GB', TemplateAccountType::None, '', true, false, false, false, true);

        MockVATRegLog(VATRegistrationLog, VATRegistrationLog."Details Status"::"Not Verified");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Customer, '10000');
        VATRegistrationLog.SetAccountDetails(NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        VATRegistrationLog.SetResponseMatchDetails(false, false, false, false);

        Assert.AreEqual(true, VATRegistrationLog.LogDetails(), 'VATRegistrationLog.LogDetails');
        VATRegistrationLog.TestField("Details Status", VATRegistrationLog."Details Status"::Ignored);
        Assert.RecordCount(VATRegistrationLogDetails, 1);

        VerifyDetailsLog(
            VATRegistrationLog, VATRegistrationLogDetails."Field Name"::Name,
            NameTxt, NameTxt, '', VATRegistrationLogDetails.Status::"Not Valid");
    end;

    [Test]
    procedure ValidateVatRegistrationLogForContactCreatedByCustomer()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        VATRegistrationLog: Record "VAT Registration Log";
        CountryRegion: Record "Country/Region";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 461536] Verify VAT Registration Log on Contact when customer VAT Registration No. validated
        Initialize();
        InitDefaultTemplate();

        //[GIVEN] Create customer and mock contact
        PrepareCustomerLog(Customer, VATRegistrationLog);
        MockContact(Contact, '', '', '', '');
        MockContBusRelation(Contact."No.", ContactBusinessRelation."Link to Table"::Customer, Customer."No.");
        PrepareContactLog(Contact, VATRegistrationLog);

        // [GIVEN] Create Country and update EU country Code
        LibraryERM.CreateCountryRegion(CountryRegion);
        UpdateEUCountryRegion(CountryRegion.Code);

        // [GIVEN] Open customer card and validate "VAT Registration No."
        CustomerCard.OpenEdit();
        CustomerCard.GoToRecord(Customer);
        CustomerCard."Country/Region Code".SetValue(CountryRegion.Code);
        CustomerCard."VAT Registration No.".SetValue('');
        CustomerCard.Close();

        // [VERIFY] Verify VAT registration log created for contact
        VerifyVATRegNoAndCountryCodeInLog(2);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ValidateVatRegistrationLogForContactCreatedByVendor()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        VATRegistrationLog: Record "VAT Registration Log";
        CountryRegion: Record "Country/Region";
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO 461536] Verify VAt Registration Log on Contact when vendor VAT Registration No. validated
        Initialize();
        InitDefaultTemplate();

        //[GIVEN] Create vendor and mock contact
        PrepareVendorLog(Vendor, VATRegistrationLog);
        MockContact(Contact, '', '', '', '');
        MockContBusRelation(Contact."No.", ContactBusinessRelation."Link to Table"::Vendor, Vendor."No.");
        PrepareContactLog(Contact, VATRegistrationLog);

        // [GIVEN] Create Country and update EU country Code
        LibraryERM.CreateCountryRegion(CountryRegion);
        UpdateEUCountryRegion(CountryRegion.Code);

        // [GIVEN] Open vendor card and validate "VAT Registration No."
        VendorCard.OpenEdit();
        VendorCard.GoToRecord(Vendor);
        VendorCard."Country/Region Code".SetValue(CountryRegion.Code);
        VendorCard."VAT Registration No.".SetValue('');
        VendorCard.Close();

        // [VERIFY] Verify VAT registration log created for contact
        VerifyVATRegNoAndCountryCodeInLog(2);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATRegistrationLogHandler')]
    procedure TestVatRegistrationLogForContactCreatedByCustManually()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        VATRegistrationLog: Record "VAT Registration Log";
        CountryRegion: Record "Country/Region";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 472592] "VAT Registration No." is validated before Country/Region
        Initialize();

        // [GIVEN] Initialize VAT Registration Default Template 
        InitDefaultTemplate();

        //[GIVEN] Create customer and mock contact
        PrepareCustomerLog(Customer, VATRegistrationLog);
        MockContact(Contact, '', '', '', '');
        MockContBusRelation(Contact."No.", ContactBusinessRelation."Link to Table"::Customer, Customer."No.");
        PrepareContactLog(Contact, VATRegistrationLog);

        // [GIVEN] Create Country and update EU country Code
        LibraryERM.CreateCountryRegion(CountryRegion);
        UpdateEUCountryRegion(CountryRegion.Code);

        // [GIVEN] Open customer card and validate "VAT Registration No."
        CustomerCard.OpenEdit();
        CustomerCard.GoToRecord(Customer);
        CustomerCard."Country/Region Code".SetValue(CountryRegion.Code);
        CustomerCard."VAT Registration No.".SetValue('');
        CustomerCard.Close();

        // [GIVEN] Enqueue the VAT Registration No to verify on Handler page
        LibraryVariableStorage.Enqueue(VATRegistrationLog."VAT Registration No.");

        // [WHEN] Open Contact page and drilldown VAT Registration No. field
        OpenContactVATRegLog(Contact);

        // [VERIFY] Verify VAT registration log created for contact on Handler Page
    end;

    procedure Initialize()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        ClearTemplates();
        VATRegistrationLog.DeleteAll();
        VATRegistrationLogDetails.DeleteAll();
        LibraryVariableStorage.Clear();
    end;

    local procedure ClearTemplates()
    var
        VATRegNoSrvTemplate: Record "VAT Reg. No. Srv. Template";
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        VATRegNoSrvTemplate.DeleteAll();
        VATRegNoSrvConfig.Get();
        VATRegNoSrvConfig."Default Template Code" := '';
        VATRegNoSrvConfig.Modify();
    end;

    local procedure InitDefaultTemplate()
    var
        VATRegNoSrvTemplate: Record "VAT Reg. No. Srv. Template";
        DummyVATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        VATRegNoSrvTemplate.CheckInitDefaultTemplate(DummyVATRegNoSrvConfig);
    end;

    local procedure PrepareCustomerLog(var Customer: Record Customer; var VATRegistrationLog: Record "VAT Registration Log")
    begin
        MockCustomer(Customer, NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        MockVATRegLog(VATRegistrationLog, VATRegLogDetailsStatus::"Not Valid");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Customer, Customer."No.");
        PrepareVATRegLog(VATRegistrationLog, Customer.Name, Customer.Address, Customer.City, Customer."Post Code");
    end;

    local procedure PrepareVendorLog(var Vendor: Record Vendor; var VATRegistrationLog: Record "VAT Registration Log")
    begin
        MockVendor(Vendor, NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        MockVATRegLog(VATRegistrationLog, VATRegLogDetailsStatus::"Not Valid");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Vendor, Vendor."No.");
        PrepareVATRegLog(VATRegistrationLog, Vendor.Name, Vendor.Address, Vendor.City, Vendor."Post Code");
    end;

    local procedure PrepareContactLog(var Contact: Record Contact; var VATRegistrationLog: Record "VAT Registration Log")
    begin
        MockContact(Contact, NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        MockVATRegLog(VATRegistrationLog, VATRegLogDetailsStatus::"Not Valid");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::Contact, Contact."No.");
        PrepareVATRegLog(VATRegistrationLog, Contact.Name, Contact.Address, Contact.City, Contact."Post Code");
    end;

    local procedure PrepareCompanyInfoLog(var CompanyInformation: Record "Company Information"; var VATRegistrationLog: Record "VAT Registration Log")
    begin
        CompanyInformation.Get();
        UpdateCompanyInfo(CompanyInformation, NameTxt, StreetTxt, CityTxt, PostCodeTxt);
        MockVATRegLog(VATRegistrationLog, VATRegLogDetailsStatus::"Not Valid");
        UpdateVATRegLog(VATRegistrationLog, 'GB', VATRegistrationLog."Account Type"::"Company Information", '');
        PrepareVATRegLog(
          VATRegistrationLog, CompanyInformation.Name, CompanyInformation.Address, CompanyInformation.City, CompanyInformation."Post Code");
    end;

    local procedure PrepareVATRegLog(var VATRegistrationLog: Record "VAT Registration Log"; Name: Text; Street: Text; City: Text; PostCode: Text)
    begin
        VATRegistrationLog.SetAccountDetails(Name, Street, City, PostCode);
        VATRegistrationLog.SetResponseDetails(Name2Txt, Address2Txt, Street2Txt, City2Txt, PostCode2Txt);
        VATRegistrationLog.LogDetails();
        VATRegistrationLog.Modify();
    end;

    local procedure MockTemplateWithDisabledValidation(Code: Code[20]; Country: Code[10]; AccountType: Enum "VAT Reg. No. Srv. Template Account Type"; AccountNo: Code[20])
    begin
        MockTemplate(Code, Country, AccountType, AccountNo, false, false, false, false, false);
    end;

    local procedure MockTemplate(Code: Code[20]; Country: Code[10]; AccountType: Enum "VAT Reg. No. Srv. Template Account Type"; AccountNo: Code[20]; ValidateName: Boolean; ValidateCity: Boolean; ValidateStreet: Boolean; ValidatePostCode: Boolean; IgnoreDetails: Boolean)
    var
        VATRegNoSrvTemplate: Record "VAT Reg. No. Srv. Template";
    begin
        VATRegNoSrvTemplate.Init();
        VATRegNoSrvTemplate.Code := Code;
        VATRegNoSrvTemplate."Country/Region Code" := Country;
        VATRegNoSrvTemplate."Account Type" := AccountType;
        VATRegNoSrvTemplate."Account No." := AccountNo;
        VATRegNoSrvTemplate."Validate Name" := ValidateName;
        VATRegNoSrvTemplate."Validate City" := ValidateCity;
        VATRegNoSrvTemplate."Validate Street" := ValidateStreet;
        VATRegNoSrvTemplate."Validate Post Code" := ValidatePostCode;
        VATRegNoSrvTemplate."Ignore Details" := IgnoreDetails;
        VATRegNoSrvTemplate.Insert();
    end;

    local procedure MockVATRegLog(var VATRegistrationLog: Record "VAT Registration Log"; DetailsStatus: Enum "VAT Reg. Log Details Status")
    begin
        VATRegistrationLog.Init();
        VATRegistrationLog."Entry No." := LibraryUtility.GetNewRecNo(VATRegistrationLog, VATRegistrationLog.FieldNo("Entry No."));
        VATRegistrationLog."Details Status" := DetailsStatus;
        VATRegistrationLog.Insert();
    end;

    local procedure MockVATRegLogDetail(var VATRegistrationLogDetails: Record "VAT Registration Log Details"; Response: Text; Status: Enum "VAT Reg. Log Details Field Status")
    begin
        VATRegistrationLogDetails.Init();
        VATRegistrationLogDetails."Log Entry No." :=
          LibraryUtility.GetNewRecNo(VATRegistrationLogDetails, VATRegistrationLogDetails.FieldNo("Log Entry No."));
        VATRegistrationLogDetails.Response := CopyStr(Response, 1, MaxStrLen(VATRegistrationLogDetails.Response));
        VATRegistrationLogDetails.Status := Status;
        VATRegistrationLogDetails.Insert();
    end;

    local procedure MockCustomer(var Customer: Record Customer; Name: Text; Street: Text; City: Text; PostCode: Text)
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open(Database::Customer);
        MockRecord(RecordRef, Name, Street, City, PostCode);
        RecordRef.SetTable(Customer);
    end;

    local procedure MockVendor(var Vendor: Record Vendor; Name: Text; Street: Text; City: Text; PostCode: Text)
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open(Database::Vendor);
        MockRecord(RecordRef, Name, Street, City, PostCode);
        RecordRef.SetTable(Vendor);
    end;

    local procedure MockContact(var Contact: Record Contact; Name: Text; Street: Text; City: Text; PostCode: Text)
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open(Database::Contact);
        MockRecord(RecordRef, Name, Street, City, PostCode);
        RecordRef.SetTable(Contact);
    end;

    local procedure MockRecord(var RecordRef: RecordRef; Name: Text; Street: Text; City: Text; PostCode: Text)
    var
        Customer: Record Customer;
    begin
        ValidateField(RecordRef, Customer.FieldNo("No."), LibraryUtility.GenerateGUID());
        ValidateField(RecordRef, Customer.FieldNo(Name), Name);
        ValidateField(RecordRef, Customer.FieldNo(Address), Street);
        ValidateField(RecordRef, Customer.FieldNo(City), City);
        ValidateField(RecordRef, Customer.FieldNo("Post Code"), PostCode);
        RecordRef.Insert();
    end;

    local procedure MockContBusRelation(ContactNo: Code[20]; CVType: Enum "Contact Business Relation Link To Table"; CVNo: Code[20])
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation."Contact No." := ContactNo;
        ContactBusinessRelation."Link to Table" := CVType;
        ContactBusinessRelation."No." := CVNo;
        ContactBusinessRelation.Insert();
    end;

    local procedure ValidateField(var RecordRef: RecordRef; FieldNo: Integer; Value: Text)
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecordRef.Field(FieldNo);
        FieldRef.Validate(Value);
    end;

    local procedure UpdateVATRegLog(var VATRegistrationLog: Record "VAT Registration Log"; Country: Code[10]; AccountType: Enum "VAT Registration Log Account Type"; AccountNo: Code[20])
    begin
        VATRegistrationLog."Country/Region Code" := Country;
        VATRegistrationLog."Account Type" := AccountType;
        VATRegistrationLog."Account No." := AccountNo;
    end;

    local procedure UpdateCompanyInfo(var CompanyInformation: Record "Company Information"; Name: Text; Street: Text; City: Text; PostCode: Text)
    begin
        CompanyInformation.Get();
        CompanyInformation.Name := CopyStr(Name, 1, MaxStrLen(CompanyInformation.Name));
        CompanyInformation.Address := CopyStr(Street, 1, MaxStrLen(CompanyInformation.Address));
        CompanyInformation.City := CopyStr(City, 1, MaxStrLen(CompanyInformation.City));
        CompanyInformation."Post Code" := CopyStr(PostCode, 1, MaxStrLen(CompanyInformation."Post Code"));
        CompanyInformation.Modify();
    end;

    local procedure VerifyDefaultTemplateAbsence()
    var
        VATRegNoSrvTemplate: Record "VAT Reg. No. Srv. Template";
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        VATRegNoSrvConfig.Get();
        VATRegNoSrvConfig.TestField("Default Template Code", '');
        Assert.RecordIsEmpty(VATRegNoSrvTemplate);
    end;

    local procedure VeriftDefaultTemplatePresence()
    var
        VATRegNoSrvTemplate: Record "VAT Reg. No. Srv. Template";
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        Assert.RecordIsNotEmpty(VATRegNoSrvTemplate);
        VATRegNoSrvConfig.Get();
        VATRegNoSrvConfig.TestField("Default Template Code", DefaultTxt);
    end;

    local procedure VerifyTemplateSelection(Expected: Code[20]; Country: Code[10]; AccountType: Enum "VAT Registration Log Account Type"; AccountNo: Code[20])
    var
        DummyVATRegistrationLog: Record "VAT Registration Log";
        DummyVATRegNoSrvTemplate: Record "VAT Reg. No. Srv. Template";
    begin
        UpdateVATRegLog(DummyVATRegistrationLog, Country, AccountType, AccountNo);
        Assert.AreEqual(Expected, DummyVATRegNoSrvTemplate.FindTemplate(DummyVATRegistrationLog), 'FindTemplate');
    end;

    local procedure VerifyValidationDetailActionVisbility(DetailsStatus: Enum "VAT Reg. Log Details Status"; Expected: Boolean)
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogPage: TestPage "VAT Registration Log";
    begin
        MockVATRegLog(VATRegistrationLog, DetailsStatus);
        VATRegistrationLogPage.OpenEdit();
        VATRegistrationLogPage.GoToRecord(VATRegistrationLog);
        Assert.AreEqual(Expected, VATRegistrationLogPage.ValidationDetails.Enabled(), 'ValidationDetails');
        VATRegistrationLogPage.Close();
    end;

    local procedure VerifyDetailsPageActionsVisbility(Response: Text; Status: Enum "VAT Reg. Log Details Field Status"; ExpectedAccept: Boolean; ExpectedReset: Boolean)
    var
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
        VATRegistrationLogDetailsPage: TestPage "VAT Registration Log Details";
    begin
        MockVATRegLogDetail(VATRegistrationLogDetails, Response, Status);
        VATRegistrationLogDetailsPage.OpenEdit();
        VATRegistrationLogDetailsPage.GoToRecord(VATRegistrationLogDetails);
        Assert.AreEqual(ExpectedAccept, VATRegistrationLogDetailsPage.Accept.Enabled(), 'Accept');
        Assert.AreEqual(ExpectedReset, VATRegistrationLogDetailsPage.Reset.Enabled(), 'Reset');
        VATRegistrationLogDetailsPage.Close();
    end;

    local procedure VerifyDetailsLog(VATRegistrationLog: Record "VAT Registration Log"; FieldName: Enum "VAT Reg. Log Details Field"; Requested: Text; Current: Text; Response: Text; Status: Enum "VAT Reg. Log Details Field Status")
    var
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        VATRegistrationLogDetails.Get(VATRegistrationLog."Entry No.", FieldName);
        VATRegistrationLogDetails.TestField("Account Type", VATRegistrationLog."Account Type");
        VATRegistrationLogDetails.TestField("Account No.", VATRegistrationLog."Account No.");
        VATRegistrationLogDetails.TestField(Requested, Requested);
        VATRegistrationLogDetails.TestField("Current Value", Current);
        VATRegistrationLogDetails.TestField(Response, Response);
        VATRegistrationLogDetails.TestField(Status, Status);
    end;

    local procedure VerifyCustomer(var Customer: Record Customer; Name: Text; Street: Text; City: Text; PostCode: Text)
    var
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(Customer);
        VerifyRecord(RecordRef, Name, Street, City, PostCode);
    end;

    local procedure VerifyVendor(var Vendor: Record Vendor; Name: Text; Street: Text; City: Text; PostCode: Text)
    var
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(Vendor);
        VerifyRecord(RecordRef, Name, Street, City, PostCode);
    end;

    local procedure VerifyContact(var Contact: Record Contact; Name: Text; Street: Text; City: Text; PostCode: Text)
    var
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(Contact);
        VerifyRecord(RecordRef, Name, Street, City, PostCode);
    end;

    local procedure VerifyRecord(var RecordRef: RecordRef; Name: Text; Street: Text; City: Text; PostCode: Text)
    var
        DummyCustomer: Record Customer;
    begin
        RecordRef.Find();
        VerifyField(RecordRef, DummyCustomer.FieldNo(Name), Name);
        VerifyField(RecordRef, DummyCustomer.FieldNo(Address), Street);
        VerifyField(RecordRef, DummyCustomer.FieldNo(City), City);
        VerifyField(RecordRef, DummyCustomer.FieldNo("Post Code"), PostCode);
    end;

    local procedure VerifyField(var RecordRef: RecordRef; FieldNo: Integer; Expected: Text)
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecordRef.Field(FieldNo);
        FieldRef.TestField(Expected);
    end;

    local procedure VerifyCompanyInfo(var CompanyInformation: Record "Company Information"; Name: Text; Street: Text; City: Text; PostCode: Text)
    begin
        CompanyInformation.Find();
        CompanyInformation.TestField(Name, Name);
        CompanyInformation.TestField(Address, Street);
        CompanyInformation.TestField(City, City);
        CompanyInformation.TestField("Post Code", PostCode);
    end;

    local procedure UpdateEUCountryRegion(CountryCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryCode);
        CountryRegion."EU Country/Region Code" := CountryRegion.Code;
        CountryRegion."VAT Scheme" := LibraryUtility.GenerateGUID();
        CountryRegion.Modify();
    end;

    local procedure VerifyVATRegNoAndCountryCodeInLog(Expected: Integer)
    var
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        Assert.AreEqual(Expected, VATRegistrationLog.Count, '');
    end;

    local procedure OpenContactVATRegLog(Contact: Record Contact)
    var
        ContactCard: TestPage "Contact Card";
    begin
        ContactCard.OpenEdit();
        ContactCard.GotoRecord(Contact);
        ContactCard."VAT Registration No.".DrillDown();
        ContactCard.Close();
    end;

    [ModalPageHandler]
    procedure DetailsValidationAcceptAllMPH(var VATRegistrationLogDetails: TestPage "VAT Registration Log Details")
    begin
        VATRegistrationLogDetails.AcceptAll.Invoke();
    end;

    [ModalPageHandler]
    procedure DetailsValidationAcceptOneValueMPH(var VATRegistrationLogDetailsPage: TestPage "VAT Registration Log Details")
    begin
        VATRegistrationLogDetailsPage.Filter.SetFilter("Field Name", LibraryVariableStorage.DequeueText());
        VATRegistrationLogDetailsPage.Accept.Invoke();
    end;

    [ModalPageHandler]
    procedure VATRegistrationLogHandler(var VATRegistrationLog: TestPage "VAT Registration Log")
    var
        VATRegistrationNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATRegistrationNo);
        VATRegistrationLog.First();
        Assert.AreEqual(VATRegistrationNo, VATRegistrationLog."VAT Registration No.".Value, WrongLogEntryOnPageErr);
        VATRegistrationLog.OK().Invoke();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;
}
