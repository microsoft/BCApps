codeunit 144006 "UT COD Bank Nos Check"
{
    // This Reference Nos test COD144006 works in collaboration with COD144005. Cod144005 verifies that posting documents will
    // actually call the Reference No generating code (and it's errorhandling)
    // COD144006 (this codeunit) verifies the concrete Reference Number genration and specifically that the right errors are
    // generated when FI Sales & Receivables Setup is set to NOT generate a valid numerical-only Reference No of max length 20
    // (inlcuding checkdigit).
    // 
    // This codeunit replaces these manual tests for FI Reference No.
    // 60780Test CaseREFNUM - Validate digits in Reference No. for Prepayment Invoice
    // 60781Test CaseREFNUM - Prepayment Invoice posting with Blank Sales & Receivables Setup
    // 60782Test CaseEBANK  - Validate Reference Number on Service Invoice and Prepayment Invoice
    // 60783Test CaseREFNUM - Validate Reference Nos. with invalid data
    // 60784Test CaseREFNUM - Validate Reference Nos. with invalid No. Series
    // 60785Test CaseREFNUM - Validate Reference No for Sales and Service Prepayment Invoice
    // 60788Test CaseREFNUM - Validate Reference No. in Service Invoice using different Reference Nos. option
    // 60789Test CaseREFNUM - Verify Reference No. in Prepayment Invoice using different options in Sales & Receivables Setup
    // 60790Test CaseREFNUM - Validate Reference No. in Service Order using different Reference Nos. options in Sales and Receivables Setup.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reference No] [UT]
    end;

    var
        CompanyInformation: Record "Company Information";
        BankNosCheck: Codeunit "Bank Nos Check";
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        Initialized: Boolean;
        BankAccountNumberErr: Label 'Error in Bank Account number, check the number.';
        IncorrectRefNoErr: Label 'Incorrect reference number.';
        RefNoToShortErr: Label 'Minimum length for a Reference is 2 characters.';
        BankAccountNoMissingDashErr: Label 'Type account number in correct format with hyphen.';
        RefNoNumericButTooLongErr: Label 'Reference number cannot be over 20 character long';
        RefNosMissingInSalesSetupErr: Label 'Reference Nos. must have a value in Sales & Receivables Setup';
        RefNoNotNumericErr: Label 'The value string must be numeric';

    [Test]
    [Scope('OnPrem')]
    procedure TestInvReferenceCheckReferenceToSHort()
    var
        PurchInvReference: Text[70];
    begin
        // Setup
        PurchInvReference := ' ';
        // Exercise
        asserterror BankNosCheck.InvReferenceCheck(PurchInvReference);
        // Verify
        Assert.ExpectedError(RefNoToShortErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvReferenceCheckFormatError()
    var
        PurchInvReference: Text[70];
    begin
        // Setup Format Error in
        PurchInvReference := '159030-776';
        // Exercise
        asserterror BankNosCheck.InvReferenceCheck(PurchInvReference);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvReferenceCheckValideRef()
    var
        PurchInvReference: Text[70];
    begin
        // Setup
        PurchInvReference := '268745';
        // Exercise
        BankNosCheck.InvReferenceCheck(PurchInvReference);
        // Verify Above should not fail as Reference is valid number
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvReferenceCheckAlmostValidRef()
    var
        PurchInvReference: Text[70];
    begin
        // Setup Valid number + '1'
        PurchInvReference := '2687451';
        // Exercise
        asserterror BankNosCheck.InvReferenceCheck(PurchInvReference);
        // Verify
        Assert.ExpectedError(IncorrectRefNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCheckBankAccountNoMissingDash()
    var
        BankAccNro: Text[15];
        BankAccCode: Code[20];
    begin
        // Setup Format Error
        BankAccNro := '123';
        BankAccCode := '';

        // Exercise
        asserterror BankNosCheck.CheckBankAccount(BankAccNro, BankAccCode);
        // Verify
        Assert.ExpectedError(BankAccountNoMissingDashErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCheckBankAccountValidAccountNo()
    var
        BankAccNro: Text[15];
        BankAccCode: Code[20];
    begin
        // Setup Valid Bank Account No
        BankAccNro := '159030-776';
        BankAccCode := '';

        // Exercise & Verify
        Assert.IsTrue(BankNosCheck.CheckBankAccount(BankAccNro, BankAccCode), 'Failed on valid Bank Account number');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCheckBankAccountInvalidAccountNo()
    var
        BankAccNro: Text[15];
        BankAccCode: Code[20];
    begin
        // Setup Invalid Bank Account No
        BankAccNro := '159030-777';
        BankAccCode := '';

        // Exercise
        asserterror BankNosCheck.CheckBankAccount(BankAccNro, BankAccCode);
        // Verify
        Assert.ExpectedError(BankAccountNumberErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetRefNoToInvoicePlusCustomer()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup."Invoice No." := true;
        SalesSetup."Customer No." := true;
        SalesSetup.Date := false;
        SalesSetup."Reference Nos." := '';
        SalesSetup."Default Number" := '';
        SalesSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSalesInvReferenceNoNumber()
    var
        PostingNo: Code[20];
        BillToCustomer: Code[20];
        NewRefNo: Code[20];
    begin
        // This test is not created for functionality, but for documentation. In FI it should not be possible to NOT generate a
        // Reference No. and it wwould require that one could post with BilltoCustomer =='' and with resulting Invoice No. == ''
        // Setup
        SetRefNoToInvoicePlusCustomer();
        PostingNo := '';
        BillToCustomer := '';
        // Exercise
        NewRefNo := BankNosCheck.CreateSalesInvReference(PostingNo, BillToCustomer);
        // Verify
        Assert.AreEqual('', NewRefNo, 'Incorrect NewRefNo');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSalesInvReferenceNumericalButTooLong()
    var
        PostingNo: Code[20];
        BillToCustomer: Code[20];
    begin
        // Setup: RefNo adds a checkdigit, so below will exceed 20 chars
        SetRefNoToInvoicePlusCustomer();
        PostingNo := Format(1000000000 + LibraryRandom.RandInt(999999999));
        BillToCustomer := Format(1000000000 + LibraryRandom.RandInt(999999999));
        // Exercise
        asserterror BankNosCheck.CreateSalesInvReference(PostingNo, BillToCustomer);
        // Verify
        Assert.ExpectedError(RefNoNumericButTooLongErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSalesInvReferenceNotNumerical()
    var
        PostingNo: Code[20];
        BillToCustomer: Code[20];
        NewRefNo: Code[20];
    begin
        // [SCENARIO 300042] Numeric part is taken to Reference No from not numeric numbers

        // [GIVEN] Posting No. of the invoice = 'AB12345678'
        SetRefNoToInvoicePlusCustomer();
        PostingNo := 'AB12345678';
        BillToCustomer := '123456789';

        // [WHEN] Create Invoice Reference
        NewRefNo := BankNosCheck.CreateSalesInvReference(PostingNo, BillToCustomer);

        // [THEN] Reference No = '123456789AB123456781' includes numeric part of Posting No.
        Assert.AreEqual(BillToCustomer + '123456781', NewRefNo, IncorrectRefNoErr); // tailing 1 is a check symbol
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSalesInvReferenceComprehensive()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        PostingNo: Code[20];
        BillToCustomer: Code[20];
        NewRefNo: Code[20];
        ExpectedRefNo: Text[20];
    begin
        // Setup
        SetRefNoToInvoicePlusCustomer();
        PostingNo := '1010';
        BillToCustomer := '1010';
        // Exercise
        NewRefNo := BankNosCheck.CreateSalesInvReference(PostingNo, BillToCustomer);
        // Verify, with constant input, the check digit is 6
        Assert.AreEqual('101010106', NewRefNo, 'Incorrect NewRefNo');
        // Excersice + Verify
        BankNosCheck.InvReferenceCheck(NewRefNo);

        // Setup for DateNumber in string
        SalesSetup.Get();
        SalesSetup.Date := true;
        SalesSetup.Modify();
        // Exercise
        NewRefNo := BankNosCheck.CreateSalesInvReference(PostingNo, BillToCustomer);
        // Verify, ignore checkdigit in end
        ExpectedRefNo := Format(WorkDate(), 0, '<day,2><Month,2><year,2>') + '10101010';
        Assert.IsTrue(StrPos(NewRefNo, ExpectedRefNo) > 0, 'Missing Date in RefNo');

        // Setup for Default Number in RefNo string
        SalesSetup.Get();
        SalesSetup."Default Number" := '9';
        SalesSetup.Modify();
        // Exercise
        NewRefNo := BankNosCheck.CreateSalesInvReference(PostingNo, BillToCustomer);
        // Verify, ignore checkdigit in end
        ExpectedRefNo := '9' + Format(WorkDate(), 0, '<day,2><Month,2><year,2>') + '10101010';
        Assert.IsTrue(StrPos(NewRefNo, ExpectedRefNo) > 0, 'Missing Default Number in RefNo');

        // Setup for Default Number in RefNo string
        SalesSetup.Get();
        SalesSetup."Default Number" := 'A';
        SalesSetup.Modify();
        // Exercise
        asserterror BankNosCheck.CreateSalesInvReference(PostingNo, BillToCustomer);
        // Verify
        Assert.ExpectedError(RefNoNotNumericErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetRefNoToNothing()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup."Invoice No." := false;
        SalesSetup."Customer No." := false;
        SalesSetup.Date := false;
        SalesSetup."Reference Nos." := '';
        SalesSetup."Default Number" := '';
        SalesSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSalesInvReferenceNoRefNoSetup()
    var
        PostingNo: Code[20];
        BillToCustomer: Code[20];
    begin
        // Setup
        SetRefNoToNothing();
        PostingNo := '1010';
        BillToCustomer := '1010';
        // Exercise
        asserterror BankNosCheck.CreateSalesInvReference(PostingNo, BillToCustomer);
        // Verify
        Assert.ExpectedError(RefNosMissingInSalesSetupErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchMessageCheckMessageType0()
    var
        PurchaseHeader: Record "Purchase Header";
        PayToVendor: Record Vendor;
    begin
        // Setup
        Initialize();
        CreateVendorWithBankAccount(PayToVendor, 'Vendor2', 'Bank2', '229018-02332');
        PayToVendor."Our Account No." := '1030';
        PayToVendor.Modify();

        PurchaseHeader."Message Type" := 0;
        PurchaseHeader."Invoice Message" := 'InitialValue';
        PurchaseHeader."Pay-to Vendor No." := PayToVendor."No.";
        PurchaseHeader."Vendor Invoice No." := '9999';
        // Exercise
        BankNosCheck.PurchMessageCheck(PurchaseHeader);
        // Verify
        Assert.AreEqual('', PurchaseHeader."Invoice Message", 'Invoice Message should be empty for Message Type 0');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPurchMessageCheckMessageType1NoVendorInvoiceNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PayToVendor: Record Vendor;
    begin
        // Setup
        Initialize();
        CreateVendorWithBankAccount(PayToVendor, 'Vendor2', 'Bank2', '229018-02332');
        PayToVendor."Our Account No." := '1030';
        PayToVendor.Modify();
        // Message Type 1 generates Invoice Message based on Our Account No. and Pay-to Vendor No.
        PurchaseHeader."Message Type" := 1;
        PurchaseHeader."Invoice Message" := 'InitialValue';
        PurchaseHeader."Pay-to Vendor No." := PayToVendor."No.";
        PurchaseHeader."Vendor Invoice No." := '';
        // Exercise
        BankNosCheck.PurchMessageCheck(PurchaseHeader);
        // Verify
        Assert.AreEqual('', PurchaseHeader."Invoice Message", 'Invoice Message should be empty for Message Type 1 and no Invoice');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchMessageCheckMessageType1AndMsgLen12()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PayToVendor: Record Vendor;
    begin
        // Setup
        Initialize();
        CreateVendorWithBankAccount(Vendor, 'Vendor1', 'Bank1', '229018-02332');
        CreateVendorWithBankAccount(PayToVendor, 'Vendor2', 'Bank2', '229018-02332');
        PayToVendor."Our Account No." := '1030';
        PayToVendor.Modify();
        // Message Type 1 generates Invoice Message based on Our Account No. and Pay-to Vendor No.
        PurchaseHeader."Message Type" := 1;
        PurchaseHeader."Invoice Message" := 'InitialValue';
        PurchaseHeader."Pay-to Vendor No." := PayToVendor."No.";
        PurchaseHeader."Vendor Invoice No." := '9999';
        // Exercise
        BankNosCheck.PurchMessageCheck(PurchaseHeader);
        // Verify OurAccountNo is in position 1-10, VendorInvoiceNo in position 11 length 15
        Assert.AreEqual('1030      ', CopyStr(PurchaseHeader."Invoice Message", 1, 10), 'Our Account No. not in Invoice Message');
        Assert.AreEqual('9999           ', CopyStr(PurchaseHeader."Invoice Message", 11, 15), 'Pay-to Vendor not in Invoice Message');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Question: Text[1024])
    begin
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchMessageCheckMessageType2()
    var
        PurchaseHeader: Record "Purchase Header";
        PayToVendor: Record Vendor;
    begin
        // Setup
        Initialize();
        CreateVendorWithBankAccount(PayToVendor, 'Vendor2', 'Bank2', '229018-02332');
        PayToVendor."Our Account No." := '1030';
        PayToVendor.Modify();

        PurchaseHeader."Message Type" := 0;
        PurchaseHeader."Invoice Message" := 'InitialValue';
        PurchaseHeader."Pay-to Vendor No." := PayToVendor."No.";
        PurchaseHeader."Vendor Invoice No." := '9999';
        // Exercise
        BankNosCheck.PurchMessageCheck(PurchaseHeader);
        // Verify
        Assert.AreEqual('', PurchaseHeader."Invoice Message", 'Invoice Message should be empty for Message Type 0');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestConvertBankAccEmptyBankAccNo()
    var
        BankAccNro: Text[15];
        BankAccCode: Code[20];
    begin
        // Setup
        BankAccNro := '';
        BankAccCode := '';
        // Exercise
        asserterror BankNosCheck.ConvertBankAcc(BankAccNro, BankAccCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestConvertBankAccShortBankAccNo()
    var
        BankAccNro: Text[15];
        BankAccCode: Code[20];
    begin
        // Setup
        BankAccNro := '4123456-12';
        BankAccCode := '';
        // Exercise
        BankNosCheck.ConvertBankAcc(BankAccNro, BankAccCode);
        // Verify
        Assert.AreEqual('41234560000012', BankAccNro, 'BankAccNro Conversion error');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestConvertBankAccLongtBankAccNo()
    var
        BankAccNro: Text[15];
        BankAccCode: Code[20];
    begin
        // Setup
        BankAccNro := '212345-12';
        BankAccCode := '';
        // Exercise
        BankNosCheck.ConvertBankAcc(BankAccNro, BankAccCode);
        // Verify
        Assert.AreEqual('21234500000012', BankAccNro, 'BankAccNro Conversion error');
    end;

    local procedure CreateVendorWithBankAccount(var Vendor: Record Vendor; Name: Text; BankAccountName: Text; BankAccountNo: Text)
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendor(Vendor);

        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Name := CopyStr(BankAccountName, 1, 50);
        VendorBankAccount."Bank Account No." := CopyStr(BankAccountNo, 1, 30);
        VendorBankAccount.Modify(true);

        Vendor.Name := CopyStr(Name, 1, 50);
        Vendor."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor."Preferred Bank Account Code" := VendorBankAccount.Code;
        Vendor.Modify(true);
    end;

    local procedure Initialize()
    begin
        if not Initialized then begin
            CompanyInformation.Get();
            Initialized := true;
        end;
    end;
}

