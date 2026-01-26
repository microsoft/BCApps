codeunit 144136 "ERM Free Invoice"
{
    // 1. Purpose of the test is to verify error when Free Invoice Account on Customer Posting Group is blank and Free Type is Total Amt.
    // 2. Purpose of the test is to verify error when Free Invoice Account on Customer Posting Group is blank and Free Type is Only VAT Amt.
    // 3. Purpose of the test is to verify customer ledger entries when Free Type in Payment Method is blank.
    // 4. Purpose of the test is to verify customer ledger entries when Free Type in Payment Method is Total Amt.
    // 5. Purpose of the test is to verify customer ledger entries when Free Type in Payment Method is Only VAT Amt.
    // 
    // Covers Test Cases for WI - 346250
    // ----------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                          TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------
    // BlankFreeInvoiceAccountWithFreeTypeAsTotalAmtError,BlankFreeInvoiceAccountWithFreeTypeAsOnlyVATAmtError                     156342
    // InvoiceWithFreeTypeAsBlankInPaymentMethod,InvoiceWithFreeTypeAsTotalAmtInPaymentMethod                 156345,156346,156347,156348
    // InvoiceWithFreeTypeAsOnlyVATAmtInPaymentMethod                                                         156349,156350,156351,156352

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        BlankFreeInvoiceAccountErr: Label 'Free Invoice Account must have a value in Customer Posting Group: Code=%1. It cannot be zero or empty.';

    [Test]
    [Scope('OnPrem')]
    procedure BlankFreeInvoiceAccountWithFreeTypeAsTotalAmtError()
    var
        PaymentMethod: Record "Payment Method";
    begin
        // Purpose of the test is to verify error when Free Invoice Account on Customer Posting Group is blank and Free Type is Total Amt.
        BlankFreeInvoiceAccountOnCustomerPostingGroup(PaymentMethod."Free Type"::"Total Amt.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankFreeInvoiceAccountWithFreeTypeAsOnlyVATAmtError()
    var
        PaymentMethod: Record "Payment Method";
    begin
        // Purpose of the test is to verify error when Free Invoice Account on Customer Posting Group is blank and Free Type is Only VAT Amt.
        BlankFreeInvoiceAccountOnCustomerPostingGroup(PaymentMethod."Free Type"::"Only VAT Amt.");
    end;

    local procedure BlankFreeInvoiceAccountOnCustomerPostingGroup(FreeType: Option)
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup.
        UpdateCustomerPostingGroupAndCreateSalesInvoice(SalesHeader, '', FreeType);  // Using blank for Free Invoice Account.

        // Exercise.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
        Assert.ExpectedError(StrSubstNo(BlankFreeInvoiceAccountErr, SalesHeader."Customer Posting Group"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceWithFreeTypeAsBlankInPaymentMethod()
    var
        SalesHeader: Record "Sales Header";
        PaymentMethod: Record "Payment Method";
        OldFreeInvoiceAccount: Code[20];
        DocumentNo: Code[20];
    begin
        // Purpose of the test is to verify customer ledger entries when Free Type in Payment Method is blank.

        // Setup.
        OldFreeInvoiceAccount :=
          UpdateCustomerPostingGroupAndCreateSalesInvoice(SalesHeader, CreateGLAccount(), PaymentMethod."Free Type"::" ");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
        VerifyCustomerLedgerEntry(DocumentNo, SalesHeader."Payment Method Code", '', true, SalesHeader."Document Type"::Invoice);  // Using blank for Bal. Account No. and TRUE for Open.

        // Tear Down.
        UpdateCustomerPostingGroup(SalesHeader."Customer Posting Group", OldFreeInvoiceAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceWithFreeTypeAsTotalAmtInPaymentMethod()
    var
        PaymentMethod: Record "Payment Method";
    begin
        // Purpose of the test case is to verify customer ledger entries when Free Type in Payment Method is Total Amt.
        InvoiceWithFreeTypeInPaymentMethod(PaymentMethod."Free Type"::"Total Amt.", false);  // Using FALSE for Open.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceWithFreeTypeAsOnlyVATAmtInPaymentMethod()
    var
        PaymentMethod: Record "Payment Method";
    begin
        // Purpose of the test case is to verify customer ledger entries when Free Type in Payment Method is Only VAT Amt.
        InvoiceWithFreeTypeInPaymentMethod(PaymentMethod."Free Type"::"Only VAT Amt.", true);  // Using TRUE for Open.
    end;

    local procedure InvoiceWithFreeTypeInPaymentMethod(FreeType: Option; Open: Boolean)
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        OldFreeInvoiceAccount: Code[20];
        GLAccountNo: Code[20];
    begin
        // Setup.
        GLAccountNo := CreateGLAccount();
        OldFreeInvoiceAccount := UpdateCustomerPostingGroupAndCreateSalesInvoice(SalesHeader, GLAccountNo, FreeType);

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
        VerifyCustomerLedgerEntry(DocumentNo, SalesHeader."Payment Method Code", '', Open, "Gen. Journal Document Type"::Invoice);  // Using blank for Bal. Account No.
        VerifyCustomerLedgerEntry(DocumentNo, '', GLAccountNo, false, "Gen. Journal Document Type"::" ");  // Using blank for Payment Method Code, FALSE for Open and 0 for blank Document Type.

        // Tear Down.
        UpdateCustomerPostingGroup(SalesHeader."Customer Posting Group", OldFreeInvoiceAccount);
    end;

    local procedure CreateCustomer(CustomerPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."Customer Posting Group" := CustomerPostingGroup;
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreatePaymentMethod(FreeType: Option): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod."Free Type" := FreeType;
        PaymentMethod.Modify(true);
        exit(PaymentMethod.Code);
    end;

    local procedure UpdateCustomerPostingGroupAndCreateSalesInvoice(var SalesHeader: Record "Sales Header"; FreeInvoiceAccount: Code[20]; FreeType: Option) OldFreeInvoiceAccount: Code[20]
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        CustomerPostingGroup: Code[20];
    begin
        CustomerPostingGroup := LibrarySales.FindCustomerPostingGroup();
        OldFreeInvoiceAccount := UpdateCustomerPostingGroup(CustomerPostingGroup, FreeInvoiceAccount);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(CustomerPostingGroup));
        SalesHeader.Validate("Payment Method Code", CreatePaymentMethod(FreeType));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Using random for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure UpdateCustomerPostingGroup("Code": Code[20]; NewFreeInvoiceAccount: Code[20]) OldFreeInvoiceAccount: Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(Code);
        OldFreeInvoiceAccount := CustomerPostingGroup."Free Invoice Account";
        CustomerPostingGroup."Free Invoice Account" := NewFreeInvoiceAccount;
        CustomerPostingGroup.Modify(true);
    end;

    local procedure VerifyCustomerLedgerEntry(DocumentNo: Code[20]; PaymentMethod: Code[10]; BalAccountNo: Code[20]; Open: Boolean; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Payment Method Code", PaymentMethod);
        CustLedgerEntry.TestField("Bal. Account No.", BalAccountNo);
        CustLedgerEntry.TestField(Open, Open);
    end;
}

