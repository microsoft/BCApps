codeunit 144131 "UT REP VAT Statement"
{
    // Test for feature VATSTAT - VAT Statement.
    // 
    // Covers Test Cases for WI - 357980, 352242.
    // ----------------------------------------------------------------------------------
    // Test Function Name                                                        TFS ID
    // ----------------------------------------------------------------------------------
    // CustomerOnAfterGetRecordTestVATRegistrationNumber                          154920
    // VendorOnAfterGetRecordTestVATRegistrationNumber                            154923
    // 
    // Extra tests for Contacts and vendors and customers

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        CustomerNoCap: Label 'No_Customer';
        CustomerErrorCap: Label 'ErrorText_Customer';
        VATRegistrationBlankTxt: Label 'VAT Registration No. is blank.';
        VendorNoCap: Label 'No_Vendor';
        VendorErrorCap: Label 'ErrorText_Vendor';
        ContactNoLbl: Label 'No_Contact';
        ContactErrorLbl: Label 'ErrorText_Contact';
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        TElemInvalidErr: Label 'The first character (T Element) of the number is invalid.';

    [Test]
    [HandlerFunctions('TestVATRegistrationNumberRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOnAfterGetRecordTestVATRegistrationNumber()
    var
        Customer: Record Customer;
    begin
        // Purpose of the test is to validate Customer - OnAfterGetRecord Trigger of Report - 10742 Test VAT Registration Number.

        // Setup.
        Initialize();
        CreateCustomer(Customer);

        // Enqueue value for handler - TestVATRegistrationNumberRequestPageHandler.
        LibraryVariableStorage.Enqueue(true);  // Show Customers - True.
        LibraryVariableStorage.Enqueue(false);  // Show Vendors - False.
        LibraryVariableStorage.Enqueue(false);  // Show Contacts - False.

        // Exercise: Run Report - Test VAT Registration Number, Opens handler - TestVATRegistrationNumberRequestPageHandler.
        Commit();
        REPORT.Run(REPORT::"Test VAT Registration Number", true, false, Customer);  // Request page - TRUE and Printer - False.

        // Verify: Verify Customer Number, VAT Register number text - VAT Registration No. is blank on generated XML of Report - Test VAT Registration Number.
        VerifyTestVATRegistrationNumber(CustomerNoCap, Customer."No.", CustomerErrorCap, Format(VATRegistrationBlankTxt));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TestVATRegistrationNumberRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorOnAfterGetRecordTestVATRegistrationNumber()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate Vendor - OnAfterGetRecord Trigger of Report - 10742 Test VAT Registration Number.

        // Setup.
        Initialize();
        CreateVendor(Vendor);

        // Enqueue value for handler - TestVATRegistrationNumberRequestPageHandler.
        LibraryVariableStorage.Enqueue(false);  // Show Customers - False.
        LibraryVariableStorage.Enqueue(true);  // Show Vendors - True.
        LibraryVariableStorage.Enqueue(false);  // Show Contacts - False.

        // Exercise: Run Report - Test VAT Registration Number, Opens handler - TestVATRegistrationNumberRequestPageHandler.
        Commit();
        REPORT.Run(REPORT::"Test VAT Registration Number", true, false, Vendor);  // Request page - TRUE and Printer - False.

        // Verify: Verify Vendor Number, VAT Register number text - VAT Registration No. is blank on generated XML of Report - Test VAT Registration Number.
        VerifyTestVATRegistrationNumber(VendorNoCap, Vendor."No.", VendorErrorCap, Format(VATRegistrationBlankTxt));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TestVATRegistrationNumberRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ContactOnAfterGetRecordTestVATRegistrationNumber()
    var
        Contact: Record Contact;
    begin
        // Setup.
        Initialize();
        CreateContact(Contact);

        // Enqueue value for handler
        LibraryVariableStorage.Enqueue(false);  // Show Customers - False.
        LibraryVariableStorage.Enqueue(false);  // Show Vendors - False.
        LibraryVariableStorage.Enqueue(true);  // Show Contacts - TRUE.

        // Exercise: Run
        Commit();
        REPORT.Run(REPORT::"Test VAT Registration Number", true, false, Contact);

        // Verify
        VerifyTestVATRegistrationNumber(ContactNoLbl, Contact."No.", ContactErrorLbl, Format(VATRegistrationBlankTxt));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TestVATRegistrationNumberRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorCustomerTElemVATRegistrationNumber()
    var
        Customer: Record Customer;
    begin
        // Setup.
        Initialize();
        CreateCustomer(Customer);
        Customer."VAT Registration No." := 'I3256173P';
        Customer.Modify();

        // Enqueue value for handler
        LibraryVariableStorage.Enqueue(true);  // Show Customers - TRUE.
        LibraryVariableStorage.Enqueue(false);  // Show Vendors - False.
        LibraryVariableStorage.Enqueue(false);  // Show Contacts - False.

        // Exercise: Run
        Commit();
        REPORT.Run(REPORT::"Test VAT Registration Number", true, false, Customer);

        // Verify
        VerifyTestVATRegistrationNumber(CustomerNoCap, Customer."No.", CustomerErrorCap, TElemInvalidErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TestVATRegistrationNumberRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ValidCustomerVATRegistrationNumber()
    var
        Customer: Record Customer;
    begin
        // Setup.
        Initialize();
        CreateCustomer(Customer);
        Customer."VAT Registration No." := 'K5163241V';
        Customer.Modify();

        // Enqueue value for handler
        LibraryVariableStorage.Enqueue(true);  // Show Customers - TRUE.
        LibraryVariableStorage.Enqueue(false);  // Show Vendors - False.
        LibraryVariableStorage.Enqueue(false);  // Show Contacts - False.

        // Exercise: Run
        Commit();
        REPORT.Run(REPORT::"Test VAT Registration Number", true, false, Customer);

        // Verify
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueNotExist(CustomerNoCap, Customer."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryReportDataset.Reset();

        if IsInitialized then
            exit;

        IsInitialized := true;

        SetVATRegNoFormats();

        Commit();
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        Clear(Customer);
        Customer."No." := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer);
        Customer.Insert();
        Customer.SetRange("No.", Customer."No.");
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        Clear(Vendor);
        Vendor."No." := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor);
        Vendor.Insert();
        Vendor.SetRange("No.", Vendor."No.");
    end;

    local procedure CreateContact(var Contact: Record Contact)
    begin
        Clear(Contact);
        Contact."No." := LibraryUtility.GenerateRandomCode(Contact.FieldNo("No."), DATABASE::Contact);
        Contact.Insert();
        Contact.SetRange("No.", Contact."No.");
    end;

    local procedure SetVATRegNoFormats()
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        VATRegistrationNoFormat.SetFilter("Country/Region Code", CompanyInformation."Country/Region Code");
        VATRegistrationNoFormat.ModifyAll("Check VAT Registration No.", true, true);
    end;

    local procedure VerifyTestVATRegistrationNumber(NumberCaption: Text; Number: Code[20]; NumberErrorCaption: Text; Message: Text)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(NumberCaption, Number);
        LibraryReportDataset.AssertElementWithValueExists(NumberErrorCaption, Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TestVATRegistrationNumberRequestPageHandler(var TestVATRegistrationNumber: TestRequestPage "Test VAT Registration Number")
    var
        ShowCustomers: Variant;
        ShowVendors: Variant;
        ShowContacts: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowCustomers);
        LibraryVariableStorage.Dequeue(ShowVendors);
        LibraryVariableStorage.Dequeue(ShowContacts);
        TestVATRegistrationNumber.ShowCustomers.SetValue(ShowCustomers);
        TestVATRegistrationNumber.ShowVendors.SetValue(ShowVendors);
        TestVATRegistrationNumber.ShowContacts.SetValue(ShowContacts);
        TestVATRegistrationNumber.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

