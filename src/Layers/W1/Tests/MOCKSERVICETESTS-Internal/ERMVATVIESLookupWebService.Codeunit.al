codeunit 134192 "ERM VAT VIES Lookup WebService"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Registration No.] [VAT Registration Log]  [Web Service] [UI]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        ValidVATNoMsg: Label 'The specified VAT registration number is valid.';
        DetailsNotVerifiedMsg: Label 'The specified VAT registration number is valid.\The VAT VIES validation service did not provide additional details.';
        CustomerUpdatedMsg: Label 'The customer has been updated.';
        VendorUpdatedMsg: Label 'The vendor has been updated.';
        ContactUpdatedMsg: Label 'The contact has been updated.';
        CompInfoUpdatedMsg: Label 'The company information has been updated.';
        NameTxt: Label 'Name', Locked = true;
        Name2Txt: Label 'Name2', Locked = true;
        StreetTxt: Label 'Street', Locked = true;
        Street2Txt: Label 'Street2', Locked = true;
        CityTxt: Label 'City', Locked = true;
        City2Txt: Label 'City2', Locked = true;
        PostCodeTxt: Label 'PostCode', Locked = true;
        PostCode2Txt: Label 'PostCode2', Locked = true;
        Valid2Txt: Label 'Valid2', Locked = true;
        ValidNoDetailsTxt: Label 'ValidNoDetails', Locked = true;
        AllMatchedTxt: Label 'AllMatched', Locked = true;
        DEVATTxt: Label 'DE813261484', Locked = true;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CustomerAllValid()
    var
        Customer: Record Customer;
    begin
        // [SCENARIO 342180] Validate customer VAT number, default template, valid VIES response
        Initialize();
        EnableSetup(Valid2Txt);
        MockCustomer(Customer, 'DE', Name2Txt, Street2Txt, City2Txt, PostCode2Txt);

        Customer.Validate("VAT Registration No.", DEVATTxt);

        Assert.ExpectedMessage(ValidVATNoMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure VendorAllValid()
    var
        Vendor: Record Vendor;
    begin
        // [SCENARIO 342180] Validate vendor VAT number, default template, valid VIES response
        Initialize();
        EnableSetup(Valid2Txt);
        MockVendor(Vendor, 'DE', Name2Txt, Street2Txt, City2Txt, PostCode2Txt);

        Vendor.Validate("VAT Registration No.", DEVATTxt);

        Assert.ExpectedMessage(ValidVATNoMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ContactAllValid()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO 342180] Validate contact VAT number, default template, valid VIES response
        Initialize();
        EnableSetup(Valid2Txt);
        MockContact(Contact, 'DE', Name2Txt, Street2Txt, City2Txt, PostCode2Txt);

        Contact.Validate("VAT Registration No.", DEVATTxt);

        Assert.ExpectedMessage(ValidVATNoMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CompanyInfoAllValid()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO 342180] Validate company information VAT number, default template, valid VIES response
        Initialize();
        EnableSetup(Valid2Txt);
        UpdateCompanyInfo(CompanyInformation, 'DE', Name2Txt, Street2Txt, City2Txt, PostCode2Txt);

        CompanyInformation.Validate("VAT Registration No.", DEVATTxt);

        Assert.ExpectedMessage(ValidVATNoMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CustomerValidNoDetails()
    var
        Customer: Record Customer;
    begin
        // [SCENARIO 342180] Validate customer VAT number, no details VIES response
        Initialize();
        EnableSetup(ValidNoDetailsTxt);
        MockCustomer(Customer, 'DE', Name2Txt, Street2Txt, City2Txt, PostCode2Txt);

        Customer.Validate("VAT Registration No.", DEVATTxt);

        Assert.ExpectedMessage(DetailsNotVerifiedMsg, LibraryUtility.ConvertCRLFToBackSlash(LibraryVariableStorage.DequeueText()));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CustomerAllMatched()
    var
        Customer: Record Customer;
    begin
        // [SCENARIO 342180] Validate customer VAT number, validate All template, valid VIES response
        Initialize();
        EnableSetup(AllMatchedTxt);
        MockCustomer(Customer, 'DE', Name2Txt, Street2Txt, City2Txt, PostCode2Txt);
        MockTemplateValidateAll('DE');

        Customer.Validate("VAT Registration No.", DEVATTxt);

        Assert.ExpectedMessage(ValidVATNoMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DetailsValidationAcceptAllMPH,MessageHandler')]
    procedure CustomerNameNotValidAccept()
    var
        Customer: Record Customer;
    begin
        // [SCENARIO 342180] Validate customer VAT number, not valid Name VIES response, accept
        Initialize();
        EnableSetup(Valid2Txt);
        MockCustomer(Customer, 'DE', NameTxt, Street2Txt, City2Txt, PostCode2Txt);

        Customer.Validate("VAT Registration No.", DEVATTxt);

        Customer.TestField(Name, Name2Txt);
        Assert.ExpectedMessage(CustomerUpdatedMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DetailsValidationAcceptAllMPH,MessageHandler')]
    procedure VendorStreetNotValidAccept()
    var
        Vendor: Record Vendor;
    begin
        // [SCENARIO 342180] Validate vendor VAT number, not valid Street VIES response, accept
        Initialize();
        EnableSetup(Valid2Txt);
        MockVendor(Vendor, 'DE', Name2Txt, StreetTxt, City2Txt, PostCode2Txt);

        Vendor.Validate("VAT Registration No.", DEVATTxt);

        Vendor.TestField(Address, Street2Txt);
        Assert.ExpectedMessage(VendorUpdatedMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DetailsValidationAcceptAllMPH,MessageHandler')]
    procedure ContactCityNotValidAccept()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO 342180] Validate contact VAT number, not valid City VIES response, accept
        Initialize();
        EnableSetup(Valid2Txt);
        MockContact(Contact, 'DE', Name2Txt, Street2Txt, CityTxt, PostCode2Txt);

        Contact.Validate("VAT Registration No.", DEVATTxt);

        Contact.TestField(City, City2Txt);
        Assert.ExpectedMessage(ContactUpdatedMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DetailsValidationAcceptAllMPH,MessageHandler')]
    procedure CompanyInfoPostCodeNotValidAccept()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO 342180] Validate company information VAT number, not valid Post Code VIES response, accept
        Initialize();
        EnableSetup(Valid2Txt);
        UpdateCompanyInfo(CompanyInformation, 'DE', Name2Txt, Street2Txt, City2Txt, PostCodeTxt);

        CompanyInformation.Validate("VAT Registration No.", DEVATTxt);

        CompanyInformation.TestField("Post Code", PostCode2Txt);
        Assert.ExpectedMessage(CompInfoUpdatedMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        ClearTemplates();
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

    local procedure EnableSetup(MockServiceURLPath: Text)
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        VATRegNoSrvConfig.Get();
        VATRegNoSrvConfig.Enabled := true;
        VATRegNoSrvConfig."Service Endpoint" :=
          CopyStr(
            StrSubstNo('https://localhost:8080/ValidateVATRegNo/%1', MockServiceURLPath),
            1, MaxStrLen(VATRegNoSrvConfig."Service Endpoint"));
        VATRegNoSrvConfig.Modify();
    end;

    local procedure MockTemplateValidateAll(Country: Code[10])
    var
        VATRegNoSrvTemplate: Record "VAT Reg. No. Srv. Template";
    begin
        VATRegNoSrvTemplate.Init();
        VATRegNoSrvTemplate.Code := LibraryUtility.GenerateGUID();
        VATRegNoSrvTemplate."Country/Region Code" := Country;
        VATRegNoSrvTemplate."Validate Name" := true;
        VATRegNoSrvTemplate."Validate City" := true;
        VATRegNoSrvTemplate."Validate Street" := true;
        VATRegNoSrvTemplate."Validate Post Code" := true;
        VATRegNoSrvTemplate.Insert();
    end;

    local procedure MockCustomer(var Customer: Record Customer; Country: Text; Name: Text; Street: Text; City: Text; PostCode: Text)
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open(Database::Customer);
        MockRecord(RecordRef, Country, Name, Street, City, PostCode);
        RecordRef.SetTable(Customer);
    end;

    local procedure MockVendor(var Vendor: Record Vendor; Country: Text; Name: Text; Street: Text; City: Text; PostCode: Text)
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open(Database::Vendor);
        MockRecord(RecordRef, Country, Name, Street, City, PostCode);
        RecordRef.SetTable(Vendor);
    end;

    local procedure MockContact(var Contact: Record Contact; Country: Text; Name: Text; Street: Text; City: Text; PostCode: Text)
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open(Database::Contact);
        MockRecord(RecordRef, Country, Name, Street, City, PostCode);
        RecordRef.SetTable(Contact);
    end;

    local procedure MockRecord(var RecordRef: RecordRef; Country: Text; Name: Text; Street: Text; City: Text; PostCode: Text)
    var
        Customer: Record Customer;
    begin
        ValidateField(RecordRef, Customer.FieldNo("No."), LibraryUtility.GenerateGUID());
        ValidateField(RecordRef, Customer.FieldNo("Country/Region Code"), Country);
        ValidateField(RecordRef, Customer.FieldNo(Name), Name);
        ValidateField(RecordRef, Customer.FieldNo(Address), Street);
        ValidateField(RecordRef, Customer.FieldNo(City), City);
        ValidateField(RecordRef, Customer.FieldNo("Post Code"), PostCode);
        RecordRef.Insert();
    end;

    local procedure UpdateCompanyInfo(var CompanyInformation: Record "Company Information"; Country: Text; Name: Text; Street: Text; City: Text; PostCode: Text)
    begin
        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := CopyStr(Country, 1, MaxStrLen(CompanyInformation."Country/Region Code"));
        CompanyInformation.Name := CopyStr(Name, 1, MaxStrLen(CompanyInformation.Name));
        CompanyInformation.Address := CopyStr(Street, 1, MaxStrLen(CompanyInformation.Address));
        CompanyInformation.City := CopyStr(City, 1, MaxStrLen(CompanyInformation.City));
        CompanyInformation."Post Code" := CopyStr(PostCode, 1, MaxStrLen(CompanyInformation."Post Code"));
        CompanyInformation.Modify();
    end;

    local procedure ValidateField(var RecordRef: RecordRef; FieldNo: Integer; Value: Text)
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecordRef.Field(FieldNo);
        FieldRef.Validate(Value);
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ModalPageHandler]
    procedure DetailsValidationAcceptAllMPH(var VATRegistrationLogDetails: TestPage "VAT Registration Log Details")
    begin
        VATRegistrationLogDetails.AcceptAll.Invoke();
    end;
}
