codeunit 144007 "E-Banking FI"
{
    // // [FEATURE] [Bank Payments]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        WrongBankAccountFormatErr: Label 'Type account number in correct format with hyphen.';
        DomesticBankAccTooLongErr: Label 'Domestic Bank Account No. must not exceed 15 characters.';

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorNameTruncatedWhenTooLong()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        RefPaymentExported: Record "Ref. Payment - Exported";
        SuggestBankPayments: Report "Suggest Bank Payments";
        TruncatedVendorName: Text;
    begin
        // Setup
        CreateVendor(Vendor);
        CreateAndPostPurchaseInvoice(PurchaseHeader, Vendor."No.");
        RefPaymentExported.DeleteAll(true);

        // Exercise
        Vendor.SetRecFilter();
        SuggestBankPayments.SetTableView(Vendor);
        SuggestBankPayments.InitializeRequest(CalcDate('<1M>', WorkDate()), false, 0);
        SuggestBankPayments.UseRequestPage := false;
        SuggestBankPayments.RunModal();

        // Verify
        RefPaymentExported.SetRange("Vendor No.", Vendor."No.");
        RefPaymentExported.FindFirst();
        TruncatedVendorName := CopyStr(Vendor.Name, 1, MaxStrLen(RefPaymentExported."Description 2"));
        Assert.AreEqual(TruncatedVendorName, RefPaymentExported."Description 2", 'Vendor Name not properly truncated')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBankAccNoValidatedOnCountryChangeFail()
    var
        BankAccount: Record "Bank Account";
    begin
        // Setup
        CreateBankAccount(BankAccount);

        // Exercise
        asserterror BankAccount.Validate("Bank Account No.", '1234567890');

        // Verify
        Assert.ExpectedError(WrongBankAccountFormatErr)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBankAccNoValidatedOnCountryChangeFailForeign()
    var
        BankAccount: Record "Bank Account";
    begin
        // Setup
        CreateForeignBankAccount(BankAccount);

        // Exercise & Verify (No error)
        BankAccount.Validate("Bank Account No.", '1234567890');
        asserterror BankAccount.Validate("Country/Region Code", 'FI');

        // Verify
        Assert.ExpectedError(WrongBankAccountFormatErr)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBankAccNoValidatedOnCountryChangeFailLongBankAcc()
    var
        BankAccount: Record "Bank Account";
    begin
        // Setup
        CreateBankAccount(BankAccount);

        // Exercise & Verify (No error)
        asserterror BankAccount.Validate("Bank Account No.", '1234567890123456');

        // Verify
        Assert.ExpectedError(DomesticBankAccTooLongErr)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustBankAccNoValidatedOnCountryChangeFail()
    var
        CustBankAccount: Record "Customer Bank Account";
    begin
        // Setup
        CreateCustomerWithBankAccount(CustBankAccount);

        // Exercise
        asserterror CustBankAccount.Validate("Bank Account No.", '1234567890');

        // Verify
        Assert.ExpectedError(WrongBankAccountFormatErr)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustBankAccNoValidatedOnCountryChangeFailForeign()
    var
        CustBankAccount: Record "Customer Bank Account";
    begin
        // Setup
        CreateForeignCustBankAccount(CustBankAccount);

        // Exercise & Verify (No error)
        CustBankAccount.Validate("Bank Account No.", '1234567890');
        asserterror CustBankAccount.Validate("Country/Region Code", 'FI');

        // Verify
        Assert.ExpectedError(WrongBankAccountFormatErr)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustBankAccNoValidatedOnCountryChangeFailLongBankAcc()
    var
        CustBankAccount: Record "Customer Bank Account";
    begin
        // Setup
        CreateCustomerWithBankAccount(CustBankAccount);

        // Exercise & Verify (No error)
        asserterror CustBankAccount.Validate("Bank Account No.", '1234567890123456');

        // Verify
        Assert.ExpectedError(DomesticBankAccTooLongErr)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendBankAccNoValidatedOnCountryChangeFail()
    var
        VendBankAccount: Record "Vendor Bank Account";
    begin
        // Setup
        CreateVendorWithBankAccount(VendBankAccount);

        // Exercise
        asserterror VendBankAccount.Validate("Bank Account No.", '1234567890');

        // Verify
        Assert.ExpectedError(WrongBankAccountFormatErr)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendBankAccNoValidatedOnCountryChangeFailForeign()
    var
        VendBankAccount: Record "Vendor Bank Account";
    begin
        // Setup
        CreateForeignVendBankAccount(VendBankAccount);

        // Exercise & Verify (No error)
        VendBankAccount.Validate("Bank Account No.", '1234567890');
        asserterror VendBankAccount.Validate("Country/Region Code", 'FI');

        // Verify
        Assert.ExpectedError(WrongBankAccountFormatErr)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendBankAccNoValidatedOnCountryChangeFailLongBankAcc()
    var
        VendBankAccount: Record "Vendor Bank Account";
    begin
        // Setup
        CreateVendorWithBankAccount(VendBankAccount);

        // Exercise & Verify (No error)
        asserterror VendBankAccount.Validate("Bank Account No.", '1234567890123456');

        // Verify
        Assert.ExpectedError(DomesticBankAccTooLongErr)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeVendorNoForNewLine()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        RefPaymentExported: Record "Ref. Payment - Exported";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 378418] empty Vendor No. can be changed for new record of FI bank payment
        // [GIVEN] Vendor with bank account
        CreateVendorWithBankAccount(VendorBankAccount);

        // [GIVEN] New FI bank payment
        CreateNewRefPaymentExported(RefPaymentExported);

        // [WHEN] "Ref. Payment - Exported"."Vendor No." is being validated with "Vendor"."No."
        SetRefPaymentExportedVendorNo(RefPaymentExported, VendorBankAccount."Vendor No.");

        // [THEN] Empty "Ref. Payment - Exported"."Vendor No." changed to Vendor."No."
        RefPaymentExported.TestField("Vendor No.", VendorBankAccount."Vendor No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeVendorNoForPartlyFilledLine()
    var
        VendorBankAccount: array[2] of Record "Vendor Bank Account";
        RefPaymentExported: Record "Ref. Payment - Exported";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 378418] Non-empty Vendor No. can be changed for partly record of FI bank payment, where Entry No. is 0
        // [GIVEN] Vendor[1] and Vendor[2] with bank account
        CreateVendorWithBankAccount(VendorBankAccount[1]);
        CreateVendorWithBankAccount(VendorBankAccount[2]);

        // [GIVEN] FI bank payment with filled Vendor No. = Vendor[1]."No." and Entry No. = 0
        CreateNewRefPaymentExported(RefPaymentExported);
        SetRefPaymentExportedVendorNo(RefPaymentExported, VendorBankAccount[1]."Vendor No.");

        // [WHEN] "Ref. Payment - Exported"."Vendor No." is being validated with "Vendor[2]"
        SetRefPaymentExportedVendorNo(RefPaymentExported, VendorBankAccount[2]."Vendor No.");

        // [THEN] "Ref. Payment - Exported"."Vendor No." changed to Vendor[2]
        RefPaymentExported.TestField("Vendor No.", VendorBankAccount[2]."Vendor No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ChangeVendorNoForFilledLineConfirmYes()
    var
        VendorBankAccount: array[2] of Record "Vendor Bank Account";
        RefPaymentExported: Record "Ref. Payment - Exported";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 378418] Vendor No. can be changed for record of FI bank payment, where Entry No. is not 0 after confirmation
        // [GIVEN] Vendor[1] and Vendor[2] with bank account
        CreateVendorWithBankAccount(VendorBankAccount[1]);
        CreateVendorWithBankAccount(VendorBankAccount[2]);

        // [GIVEN] "Ref. Payment - Exported" where "Vendor No." = "Vendor[1]" and "Entry No." = 100
        CreateRefPaymentExportedWithVendorAndEntry(RefPaymentExported, VendorBankAccount[1]."Vendor No.");

        // [GIVEN] "Ref. Payment - Exported"."Vendor No." is being validated with "Vendor[2]"
        // [WHEN] Answer Yes on confirmation
        SetRefPaymentExportedVendorNo(RefPaymentExported, VendorBankAccount[2]."Vendor No.");

        // [THEN] "Ref. Payment - Exported"."Vendor No." = "Vendor[2]"
        RefPaymentExported.TestField("Vendor No.", VendorBankAccount[2]."Vendor No.");
        // [THEN] "Ref. Payment - Exported"."Entry No." = 0 (reset)
        VerifyClearedRefPaymentExported(RefPaymentExported, VendorBankAccount[2]."Vendor No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure ChangeVendorNoForFilledLineConfirmNo()
    var
        VendorBankAccount: array[2] of Record "Vendor Bank Account";
        RefPaymentExported: Record "Ref. Payment - Exported";
        EntryNo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 378418] Vendor No. left unchanged for record of FI bank payment, when change was not confirmed
        // [GIVEN] Vendor[1] and Vendor[2] with bank account
        CreateVendorWithBankAccount(VendorBankAccount[1]);
        CreateVendorWithBankAccount(VendorBankAccount[2]);

        // [GIVEN] "Ref. Payment - Exported" where "Vendor No." = "Vendor[1]" and "Entry No." = 100
        CreateRefPaymentExportedWithVendorAndEntry(RefPaymentExported, VendorBankAccount[1]."Vendor No.");
        EntryNo := RefPaymentExported."Entry No.";

        // [GIVEN] "Ref. Payment - Exported"."Vendor No." is being validated with "Vendor[2]"
        // [WHEN] Answer No on confirmation
        asserterror SetRefPaymentExportedVendorNo(RefPaymentExported, VendorBankAccount[2]."Vendor No.");

        // [THEN] "Ref. Payment - Exported"."Vendor No." remains Vendor[1]
        RefPaymentExported.TestField("Vendor No.", VendorBankAccount[1]."Vendor No.");
        // [THEN] "Ref. Payment - Exported"."Entry No." = 100
        RefPaymentExported.TestField("Entry No.", EntryNo);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)));
        Vendor.Validate("Country/Region Code", 'FI');
        Vendor.Modify(true);
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account")
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Country/Region Code", 'FI');
        BankAccount.Modify();
    end;

    local procedure CreateCustomerWithBankAccount(var CustBankAccount: Record "Customer Bank Account")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustBankAccount, Customer."No.");
        CustBankAccount.Validate("Country/Region Code", 'FI');
        CustBankAccount.Modify();
    end;

    local procedure CreateVendorWithBankAccount(var VendBankAccount: Record "Vendor Bank Account")
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendBankAccount, Vendor."No.");
        VendBankAccount.Validate("Country/Region Code", 'FI');
        VendBankAccount.Modify();
    end;

    local procedure CreateForeignBankAccount(var BankAccount: Record "Bank Account")
    begin
        CreateBankAccount(BankAccount);
        BankAccount.Validate("Country/Region Code", 'GB');
        BankAccount.Modify();
    end;

    local procedure CreateForeignCustBankAccount(var CustBankAccount: Record "Customer Bank Account")
    begin
        CreateCustomerWithBankAccount(CustBankAccount);
        CustBankAccount.Validate("Country/Region Code", 'GB');
        CustBankAccount.Modify();
    end;

    local procedure CreateForeignVendBankAccount(var VendBankAccount: Record "Vendor Bank Account")
    begin
        CreateVendorWithBankAccount(VendBankAccount);
        VendBankAccount.Validate("Country/Region Code", 'GB');
        VendBankAccount.Modify();
    end;

    local procedure CreateAndPostPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseInvoice(PurchaseHeader, VendorNo);
        CreatePurchaseInvoiceLineWithItem(PurchaseLine, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
    end;

    local procedure CreatePurchaseInvoiceLineWithItem(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.",
          LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInDecimalRange(500, 1000, 2));
        PurchaseLine.Modify(true)
    end;

    local procedure CreateNewRefPaymentExported(var RefPaymentExported: Record "Ref. Payment - Exported")
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RefPaymentExported);

        RefPaymentExported.Init();
        RefPaymentExported."No." := LibraryUtility.GetNewLineNo(RecRef, RefPaymentExported.FieldNo("No."));
        RefPaymentExported.Insert();
    end;

    local procedure CreateRefPaymentExportedWithVendorAndEntry(var RefPaymentExported: Record "Ref. Payment - Exported"; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateAndPostPurchaseInvoice(PurchaseHeader, VendorNo);
        CreateNewRefPaymentExported(RefPaymentExported);
        SetRefPaymentExportedVendorNo(RefPaymentExported, VendorNo);
        RefPaymentExported.Validate("Entry No.", FindLastVendorLedgeEntryNo(VendorNo));
        RefPaymentExported.Modify();
    end;

    local procedure FindLastVendorLedgeEntryNo(VendorNo: Code[20]): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindLast();
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure SetRefPaymentExportedVendorNo(var RefPaymentExported: Record "Ref. Payment - Exported"; NewVendorNo: Code[20])
    begin
        RefPaymentExported.Validate("Vendor No.", NewVendorNo);
        RefPaymentExported.Modify(true);
    end;

    local procedure VerifyClearedRefPaymentExported(RefPaymentExported: Record "Ref. Payment - Exported"; ExpectedVendorNo: Code[20])
    begin
        RefPaymentExported.TestField("Entry No.", 0);
        RefPaymentExported.TestField("Vendor No.", ExpectedVendorNo);
        RefPaymentExported.TestField("Payment Account", '');
        RefPaymentExported.TestField("Due Date", 0D);
        RefPaymentExported.TestField("Payment Date", 0D);
        RefPaymentExported.TestField("Document No.", '');
        RefPaymentExported.TestField("Document Type", RefPaymentExported."Document Type"::" ");
        RefPaymentExported.TestField("Currency Code", '');
        RefPaymentExported.TestField(Amount, 0);
        RefPaymentExported.TestField("Amount (LCY)", 0);
        RefPaymentExported.TestField("Vendor Account", '');
        RefPaymentExported.TestField("Message Type", RefPaymentExported."Message Type"::"Reference No.");
        RefPaymentExported.TestField("Invoice Message", '');
        RefPaymentExported.TestField("Invoice Message 2", '');
        RefPaymentExported.TestField("Applies-to ID", '');
        RefPaymentExported.TestField("External Document No.", '');
        RefPaymentExported.TestField("Posting Date", 0D);
        RefPaymentExported.TestField("Foreign Payment Method", '');
        RefPaymentExported.TestField("Foreign Banks Service Fee", '');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

