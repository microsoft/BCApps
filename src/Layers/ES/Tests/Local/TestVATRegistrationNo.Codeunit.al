codeunit 147592 "Test VAT Registration No."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        CompanyInformation: Record "Company Information";
        Assert: Codeunit Assert;
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        LengthExceededMsg: Label 'The length of the number exceeds the maximum limit of 9 characters.';
        InterruptedWarningMsg: Label 'interrupted';
        NoAlphanumericErr: Label 'There should not be any alphabetic characters in the mid part of the number.';
        ControlNotCorrectErr: Label 'The control element is not correct.';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestInvalidLengthVATFormatOnCustomer()
    var
        Customer: Record Customer;
    begin
        // Setup
        Initialize();

        CreateCustomer(Customer);

        // Exercise: Enter an invalid length VAT Registration No for Customer
        LibraryVariableStorage.Enqueue(LengthExceededMsg);
        LibraryVariableStorage.Enqueue(false);

        asserterror Customer.Validate("VAT Registration No.", 'A' + GenerateRandomNumberAsText(9));

        // Verify
        Assert.ExpectedError(InterruptedWarningMsg);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestInvalidLengthVATFormatOnVendor()
    var
        Vendor: Record Vendor;
    begin
        // Setup
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Vendor.Modify(true);

        // Exercise: Enter an invalid length VAT Registration No for Vendor
        LibraryVariableStorage.Enqueue(LengthExceededMsg);
        LibraryVariableStorage.Enqueue(false);

        asserterror Vendor.Validate("VAT Registration No.", 'A' + GenerateRandomNumberAsText(9));

        // Verify
        Assert.ExpectedError(InterruptedWarningMsg);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestInvalidLengthVATFormatOnContact()
    var
        Contact: Record Contact;
    begin
        // Setup
        Initialize();

        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Contact.Modify(true);

        // Exercise: Enter an invalid length VAT Registration No for Contact
        LibraryVariableStorage.Enqueue(LengthExceededMsg);
        LibraryVariableStorage.Enqueue(false);

        asserterror Contact.Validate("VAT Registration No.", 'A' + GenerateRandomNumberAsText(9));

        // Verify
        Assert.ExpectedError(InterruptedWarningMsg);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestInvalidVATFormatOnCustomerAlphabeticInMiddle()
    var
        Customer: Record Customer;
        VatNo: Text[20];
    begin
        // Setup
        Initialize();

        CreateCustomer(Customer);

        // Exercise: Enter an invalid format VAT Registration No for Customer alphabetic in middle
        LibraryVariableStorage.Enqueue(NoAlphanumericErr);
        LibraryVariableStorage.Enqueue(false);

        VatNo := CopyStr('A' + GenerateRandomNumberAsText(3) + LibraryUtility.GenerateRandomText(1) +
            GenerateRandomNumberAsText(4), 1, 20);

        asserterror Customer.Validate("VAT Registration No.", VatNo);

        // Verify
        Assert.ExpectedError(InterruptedWarningMsg);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestInvalidControlElemInVATFormat_K()
    begin
        InvalidControlElemInVATFormat('K');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestInvalidControlElemInVATFormat_P()
    begin
        InvalidControlElemInVATFormat('P');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestInvalidControlElemInVATFormat_Q()
    begin
        InvalidControlElemInVATFormat('Q');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestInvalidControlElemInVATFormat_S()
    begin
        InvalidControlElemInVATFormat('S');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestInvalidControlElemInVATFormat_E()
    begin
        InvalidControlElemInVATFormat('E');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestInvalidControlElemInVATFormat_A()
    begin
        InvalidControlElemInVATFormat('A');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestInvalidControlElemInVATFormat_B()
    begin
        InvalidControlElemInVATFormat('B');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestInvalidControlElemInVATFormat_H()
    begin
        InvalidControlElemInVATFormat('H');
    end;

    local procedure InvalidControlElemInVATFormat(ControlElem: Text[1])
    var
        Customer: Record Customer;
    begin
        // Setup
        Initialize();

        CreateCustomer(Customer);

        // Exercise
        LibraryVariableStorage.Enqueue(ControlNotCorrectErr);
        LibraryVariableStorage.Enqueue(false);

        asserterror Customer.Validate("VAT Registration No.", ControlElem + GenerateRandomNumberAsText(8));

        // Verify
        Assert.ExpectedError(InterruptedWarningMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidFormats_C()
    begin
        ValidFormatsABCEH('C');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidFormats_A()
    begin
        ValidFormatsABCEH('A');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidFormats_B()
    begin
        ValidFormatsABCEH('B');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidFormats_E()
    begin
        ValidFormatsABCEH('E');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidFormats_H()
    begin
        ValidFormatsABCEH('H');
    end;

    local procedure ValidFormatsABCEH(Control: Text[1])
    var
        Customer: Record Customer;
    begin
        // Setup
        Initialize();

        CreateCustomer(Customer);

        // Exercise - no error
        Customer.Validate("VAT Registration No.", Control + '12345674');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidFormat_X()
    begin
        ValidFormat('X5163241V');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidFormat_Y()
    begin
        ValidFormat('Y5163241P');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidFormat_Z()
    begin
        ValidFormat('Z5163241E');
    end;

    local procedure ValidFormat(VATNo: Text[9])
    var
        Customer: Record Customer;
    begin
        // Setup
        Initialize();

        CreateCustomer(Customer);

        // Exercise - no error
        Customer.Validate("VAT Registration No.", VATNo);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        ClearLastError();

        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        CompanyInformation.Get();
        SetVATRegNoFormats();

        IsInitialized := true;

        Commit();
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Customer.Modify(true);
    end;

    local procedure GenerateRandomNumberAsText(Length: Integer): Text
    var
        i: Integer;
        Output: Text;
    begin
        for i := 1 to Length do
            Output := Output + Format(LibraryRandom.RandInt(9));

        exit(Output);
    end;

    local procedure SetVATRegNoFormats()
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        AddVATRegNoFormat('@###?####');
        AddVATRegNoFormat('@########?');

        VATRegistrationNoFormat.SetFilter("Country/Region Code", CompanyInformation."Country/Region Code");
        VATRegistrationNoFormat.ModifyAll("Check VAT Registration No.", true, true);
    end;

    local procedure AddVATRegNoFormat(Format: Text[20])
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CompanyInformation."Country/Region Code");
        VATRegistrationNoFormat.Validate(Format, Format);
        VATRegistrationNoFormat.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        NewReply: Variant;
        NewMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(NewMessage);
        LibraryVariableStorage.Dequeue(NewReply);

        Assert.IsTrue(StrPos(Question, NewMessage) > 0, Question);

        Reply := NewReply;
    end;
}

