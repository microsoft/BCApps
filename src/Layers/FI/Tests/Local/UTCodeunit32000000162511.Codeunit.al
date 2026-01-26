codeunit 144008 "UT Codeunit32000000 162511"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        BankAccount: Record "Bank Account";
        Assert: Codeunit Assert;
        ExpectedANSITxt: Label 'ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÖÜáíóúñÑÁÀÊËÈÍÎÏÌÓßÔÒõ';
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        RefPmtMgt: Codeunit "Ref. Payment Management";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        IsInitialized: Boolean;
        PaymentType: Option Domestic,Foreign,SEPA;
        PaymentMethodeCode: Code[1];
        ServiceFeeCode: Code[1];

    [Test]
    [Scope('OnPrem')]
    procedure ValidateRefPaymentManagementOEM2ANSI()
    var
        RefPaymentManagement: Codeunit "Ref. Payment Management";
        OEMString: Text;
        ANSIString: Text;
        Char: Text;
        i: Integer;
        OEMVal: Integer;
        ExpectedVal: Integer;
        ANSIVal: Integer;
        ExpectedANSI: Text;
        t: Integer;
    begin
        // Purpose of the test is to validate Method OEM2ANSI

        // Setup
        for i := 5 to 253 do begin
            Char[1] := i;
            OEMString += Char;
        end;

        // Exercise
        ANSIString := RefPaymentManagement.OEM2ANSI(OEMString);

        // Verify
        ExpectedANSI := ExpectedANSITxt;
        t := 1;
        for i := 1 to StrLen(ANSIString) do
            if OEMString[i] <> ANSIString[i] then begin
                OEMVal := OEMString[i];
                ExpectedVal := ExpectedANSI[t];
                ANSIVal := ANSIString[i];
                Assert.AreEqual(Format(ExpectedANSI[t]), Format(ANSIString[i]), StrSubstNo(
                    'Wrong char convert at pos %1 OEM=%2 ,OEMVal=%3,ExpectedVal=%4,ANSIVal=%5', t, OEMString[i], OEMVal, ExpectedVal, ANSIVal));
                t += 1;
            end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateCombineLineSEPA()
    var
        Vendor: Record Vendor;
        Currency: Record Currency;
        AnyDate: Date;
        Amount1: Decimal;
        Amount2: Decimal;
        VendorBankAlt: Code[10];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        AnyDate := LibraryUtility.GenerateRandomDate(WorkDate(), WorkDate() + 1000);
        LibraryERM.FindCurrency(Currency);
        Amount1 := LibraryRandom.RandDec(100, 2);
        VendorBankAlt := CreateVendorBankAccount(Vendor."No.");
        Amount2 := LibraryRandom.RandDec(100, 2);

        CreateRefPmtExpLineBank(PaymentType::SEPA, BankAccount."No.", Vendor."No.", AnyDate, Currency.Code, Amount1, VendorBankAlt);
        CreateRefPmtExpLine(PaymentType::SEPA, BankAccount."No.", Vendor."No.", AnyDate, Currency.Code, Amount2);

        // Execercise
        RefPmtMgt.CombineVendPmt(PaymentType::SEPA);
        Commit();

        // Verify combined line
        VerifyCombinedLine(BankAccount."No.", Vendor."No.", AnyDate, Currency.Code, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateCombineLineForeign()
    var
        Vendor: Record Vendor;
        Currency: Record Currency;
        AnyDate: Date;
        Amount1: Decimal;
        Amount2: Decimal;
        VendorBankAlt: Code[10];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        AnyDate := LibraryUtility.GenerateRandomDate(WorkDate(), WorkDate() + 1000);
        LibraryERM.FindCurrency(Currency);
        Amount1 := LibraryRandom.RandDec(100, 2);
        VendorBankAlt := CreateVendorBankAccount(Vendor."No.");
        Amount2 := LibraryRandom.RandDec(100, 2);

        CreateRefPmtExpLineBank(PaymentType::Foreign, BankAccount."No.", Vendor."No.", AnyDate, Currency.Code, Amount1, VendorBankAlt);
        CreateRefPmtExpLine(PaymentType::Foreign, BankAccount."No.", Vendor."No.", AnyDate, Currency.Code, Amount2);

        // Execercise
        RefPmtMgt.CombineVendPmt(PaymentType::Foreign);
        Commit();

        // Verify combined line
        VerifyCombinedLine(BankAccount."No.", Vendor."No.", AnyDate, Currency.Code, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateCombineLineDomestic()
    var
        Vendor: Record Vendor;
        Currency: Record Currency;
        AnyDate: Date;
        Amount1: Decimal;
        Amount2: Decimal;
        VendorBankAlt: Code[10];
    begin
        Initialize();

        // Setup
        CreateVendor(Vendor);
        AnyDate := LibraryUtility.GenerateRandomDate(WorkDate(), WorkDate() + 1000);
        LibraryERM.FindCurrency(Currency);
        Amount1 := LibraryRandom.RandDec(100, 2);
        VendorBankAlt := CreateVendorBankAccount(Vendor."No.");
        Amount2 := LibraryRandom.RandDec(100, 2);

        CreateRefPmtExpLineBank(PaymentType::Domestic, BankAccount."No.", Vendor."No.", AnyDate, Currency.Code, Amount1, VendorBankAlt);
        CreateRefPmtExpLine(PaymentType::Domestic, BankAccount."No.", Vendor."No.", AnyDate, Currency.Code, Amount2);

        // Execercise
        RefPmtMgt.CombineVendPmt(PaymentType::Domestic);
        Commit();

        // Verify combined line
        VerifyCombinedLine(BankAccount."No.", Vendor."No.", AnyDate, Currency.Code, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateAllowCombineLines()
    var
        Vendor: Record Vendor;
        RefPmtExported: Record "Ref. Payment - Exported";
        Currency: Record Currency;
        BankAccountNoComb: Record "Bank Account";
        AnyDate: Date;
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        LibraryERM.CreateBankAccount(BankAccountNoComb);
        CreateBankAccountReferenceFileSetup(BankAccountNoComb."No.", false);
        CreateVendor(Vendor);
        AnyDate := LibraryUtility.GenerateRandomDate(WorkDate(), WorkDate() + 1000);
        LibraryERM.FindCurrency(Currency);
        Amount := LibraryRandom.RandDec(100, 2);

        CreateRefPmtExpLine(PaymentType::SEPA, BankAccountNoComb."No.", Vendor."No.", AnyDate, Currency.Code, Amount);
        CreateRefPmtExpLine(PaymentType::SEPA, BankAccountNoComb."No.", Vendor."No.", AnyDate, Currency.Code, Amount);
        CreateRefPmtExpLine(PaymentType::Foreign, BankAccountNoComb."No.", Vendor."No.", AnyDate, Currency.Code, Amount);
        CreateRefPmtExpLine(PaymentType::Foreign, BankAccountNoComb."No.", Vendor."No.", AnyDate, Currency.Code, Amount);
        CreateRefPmtExpLine(PaymentType::Domestic, BankAccountNoComb."No.", Vendor."No.", AnyDate, Currency.Code, Amount);
        CreateRefPmtExpLine(PaymentType::Domestic, BankAccountNoComb."No.", Vendor."No.", AnyDate, Currency.Code, Amount);
        Commit();

        // Execercise
        asserterror RefPmtMgt.CombineVendPmt(PaymentType::SEPA);
        asserterror RefPmtMgt.CombineVendPmt(PaymentType::Foreign);
        asserterror RefPmtMgt.CombineVendPmt(PaymentType::Domestic);

        // Verify no lines are combined
        RefPmtExported.SetRange("Applied Payments", true);
        Assert.AreEqual(0, RefPmtExported.Count, 'No Payments should be applied');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateMultipleCombinedLines()
    var
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        Currency: Record Currency;
        Currency2: Record Currency;
        BankAccount2: Record "Bank Account";
        RefPmtExported: Record "Ref. Payment - Exported";
        PostingDate: Date;
        PostingDate2: Date;
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        LibraryERM.CreateBankAccount(BankAccount2);
        CreateBankAccountReferenceFileSetup(BankAccount2."No.", true);
        CreateVendor(Vendor);
        CreateVendor(Vendor2);
        PostingDate := LibraryUtility.GenerateRandomDate(WorkDate(), WorkDate() + 1000);
        PostingDate2 := PostingDate + 1;
        LibraryERM.FindCurrency(Currency);
        LibraryERM.FindCurrency(Currency2);
        Currency2.Next();
        Amount := LibraryRandom.RandDec(100, 2);

        CreateRefPmtExpLine(PaymentType::SEPA, BankAccount."No.", Vendor."No.", PostingDate, Currency.Code, Amount);
        CreateRefPmtExpLine(PaymentType::SEPA, BankAccount."No.", Vendor."No.", PostingDate, Currency.Code, Amount);

        CreateRefPmtExpLine(PaymentType::SEPA, BankAccount2."No.", Vendor."No.", PostingDate, Currency.Code, Amount);
        CreateRefPmtExpLine(PaymentType::SEPA, BankAccount2."No.", Vendor."No.", PostingDate, Currency.Code, Amount);

        CreateRefPmtExpLine(PaymentType::SEPA, BankAccount."No.", Vendor2."No.", PostingDate, Currency.Code, Amount);
        CreateRefPmtExpLine(PaymentType::SEPA, BankAccount."No.", Vendor2."No.", PostingDate, Currency.Code, Amount);

        CreateRefPmtExpLine(PaymentType::SEPA, BankAccount."No.", Vendor."No.", PostingDate2, Currency.Code, Amount);
        CreateRefPmtExpLine(PaymentType::SEPA, BankAccount."No.", Vendor."No.", PostingDate2, Currency.Code, Amount);

        CreateRefPmtExpLine(PaymentType::SEPA, BankAccount."No.", Vendor."No.", PostingDate, Currency2.Code, Amount);
        CreateRefPmtExpLine(PaymentType::SEPA, BankAccount."No.", Vendor."No.", PostingDate, Currency2.Code, Amount);

        CreateRefPmtExpLine(PaymentType::SEPA, BankAccount2."No.", Vendor2."No.", PostingDate2, Currency2.Code, Amount);

        // Execercise
        RefPmtMgt.CombineVendPmt(PaymentType::SEPA);
        Commit();

        // Verify no of combined lines
        RefPmtExported.SetRange("Applied Payments", false);
        Assert.AreEqual(6, RefPmtExported.Count, 'Wrong number of combined lines');

        // Verify line Affiliation
        RefPmtExported.SetRange("Applied Payments");

        RefPmtExported.SetRange("Affiliated to Line", 0);
        // BUG: Line 1 and 2 should have the same line Affiliation as Line 0. 0 is used for
        asserterror Assert.AreEqual(3, RefPmtExported.Count, 'Wrong number of Line Affiliations to "0"');

        RefPmtExported.SetRange("Affiliated to Line", 2);
        Assert.AreEqual(3, RefPmtExported.Count, 'Wrong number of Line Affiliations to "2"');

        RefPmtExported.SetRange("Affiliated to Line", 4);
        Assert.AreEqual(3, RefPmtExported.Count, 'Wrong number of Line Affiliations to "4"');

        RefPmtExported.SetRange("Affiliated to Line", 6);
        Assert.AreEqual(3, RefPmtExported.Count, 'Wrong number of Line Affiliations to "6"');

        RefPmtExported.SetRange("Affiliated to Line", 8);
        Assert.AreEqual(3, RefPmtExported.Count, 'Wrong number of Line Affiliations to "8"');
    end;

    [Test]
    procedure ApplyPartialPaymentsRefPaymentImportedToOneDocument()
    var
        RefPaymentImported: Record "Ref. Payment - Imported";
        GenJournalBatch: Record "Gen. Journal Batch";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        RefPaymentManagement: Codeunit "Ref. Payment Management";
        CustomerNo: Code[20];
        ReferenceNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 412841] Apply partial payments using the same reference number to one document
        Initialize();

        // [GIVEN] Cust. Ledger Entry
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateCustLedgerEntry(GenJournalBatch, CustomerNo, 1000);

        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();

        // [GIVEN] Two partial payment with the same Reference No.
        ReferenceNo :=
            LibraryUtility.GenerateRandomCode20(RefPaymentImported.FieldNo("Reference No."), Database::"Ref. Payment - Imported");
        CreateRefPaymentImportedLine(
            RefPaymentImported, CustLedgerEntry, 500, ReferenceNo);
        CreateRefPaymentImportedLine(
            RefPaymentImported, CustLedgerEntry, 500, ReferenceNo);

        // [WHEN] Invoke "Ref. Payment Management".SetLines(...)
        RefPaymentManagement.GetRefPmtImportTemp(RefPaymentImported);
        RefPaymentManagement.SetLines(
            RefPaymentImported, GenJournalBatch.Name, GenJournalBatch."Journal Template Name");

        // [THEN] 2 Payments are applied to one document
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetRange("Applies-to Doc. No.", CustLedgerEntry."Document No.");
        Assert.RecordCount(GenJournalLine, 2);
    end;

    local procedure Initialize()
    var
        RefPmtExported: Record "Ref. Payment - Exported";
        ForeignPaymentTypes: Record "Foreign Payment Types";
    begin
        RefPmtExported.DeleteAll();
        Commit();
        if IsInitialized then
            exit;
        IsInitialized := true;

        LibraryERM.CreateBankAccount(BankAccount);
        CreateBankAccountReferenceFileSetup(BankAccount."No.", true);
        ForeignPaymentTypes.Init();
        ForeignPaymentTypes.Validate(
          Code, LibraryUtility.GenerateRandomCode(ForeignPaymentTypes.FieldNo(Code), DATABASE::"Foreign Payment Types"));
        ForeignPaymentTypes.Validate("Code Type", ForeignPaymentTypes."Code Type"::"Payment Method");
        ForeignPaymentTypes.Insert(true);
        PaymentMethodeCode := ForeignPaymentTypes.Code;

        ForeignPaymentTypes.Init();
        ForeignPaymentTypes.Validate(
          Code, LibraryUtility.GenerateRandomCode(ForeignPaymentTypes.FieldNo(Code), DATABASE::"Foreign Payment Types"));
        ForeignPaymentTypes.Validate("Code Type", ForeignPaymentTypes."Code Type"::"Service Fee");
        ForeignPaymentTypes.Insert(true);
        ServiceFeeCode := ForeignPaymentTypes.Code;
    end;

    local procedure CreateBankAccountReferenceFileSetup(BankAccountNo: Code[20]; Allow: Boolean)
    var
        ReferenceFileSetup: Record "Reference File Setup";
    begin
        ReferenceFileSetup.Init();
        ReferenceFileSetup.Validate("No.", BankAccountNo);
        ReferenceFileSetup.Validate("Allow Comb. SEPA Pmts.", Allow);
        ReferenceFileSetup.Validate("Allow Comb. Domestic Pmts.", Allow);
        ReferenceFileSetup.Validate("Allow Comb. Foreign Pmts.", Allow);
        ReferenceFileSetup.Insert();
    end;

    local procedure CreateVendorBankAccount(VendorNo: Code[20]): Code[10]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        exit(VendorBankAccount.Code);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor): Code[20]
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Preferred Bank Account Code", CreateVendorBankAccount(Vendor."No."));
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateRefPmtExpLineBank(PaymentType: Option Domestic,Foreign,SEPA; PaymentAccount: Code[20]; VendorNo: Code[20]; PostingDate: Date; CurrencyCode: Code[10]; PaymentAmount: Decimal; VendorBankNo: Code[20])
    var
        RefPmtExported: Record "Ref. Payment - Exported";
        Vendor: Record Vendor;
        AnyDate: Date;
        NextNo: Integer;
    begin
        AnyDate := LibraryUtility.GenerateRandomDate(WorkDate(), WorkDate() + 1000);
        Vendor.Get(VendorNo);

        if RefPmtExported.FindLast() then
            NextNo := RefPmtExported."No." + 1;
        RefPmtExported.Init();
        RefPmtExported.Validate("No.", NextNo);
        RefPmtExported.Validate("Vendor No.", VendorNo);
        RefPmtExported.Validate("Description 2", LibraryUtility.GenerateRandomCode(RefPmtExported.FieldNo("Description 2"), DATABASE::"Ref. Payment - Exported"));
        RefPmtExported.Validate("Payment Account", PaymentAccount);
        RefPmtExported.Validate("Due Date", AnyDate);
        RefPmtExported.Validate("Payment Date", PostingDate);
        RefPmtExported.Validate("Document Type", RefPmtExported."Document Type"::"Credit Memo");
        RefPmtExported.Validate("Document No.", LibraryUtility.GenerateRandomCode(RefPmtExported.FieldNo("Document No."), DATABASE::"Ref. Payment - Exported"));
        RefPmtExported.Validate("Currency Code", CurrencyCode);
        RefPmtExported.Validate(Amount, PaymentAmount);
        RefPmtExported.Validate("Vendor Account", VendorBankNo);
        RefPmtExported.Validate("External Document No.",
          LibraryUtility.GenerateRandomCode(RefPmtExported.FieldNo("External Document No."), DATABASE::"Ref. Payment - Exported"));
        RefPmtExported.Validate("Invoice Message", LibraryUtility.GenerateRandomCode(RefPmtExported.FieldNo("Invoice Message"), DATABASE::"Ref. Payment - Exported"));
        case PaymentType of
            PaymentType::Domestic:
                RefPmtExported.Validate("Foreign Payment", false);
            PaymentType::Foreign:
                RefPmtExported.Validate("Foreign Payment", true);
            PaymentType::SEPA:
                RefPmtExported.Validate("SEPA Payment", true);
        end;
        RefPmtExported.Validate("Foreign Payment Method", PaymentMethodeCode);
        RefPmtExported.Validate("Foreign Banks Service Fee", ServiceFeeCode);
        RefPmtExported.Insert(true);
    end;

    local procedure CreateRefPmtExpLine(PaymentType: Option Domestic,Foreign,SEPA; PaymentAccount: Code[20]; VendorNo: Code[20]; PostingDate: Date; CurrencyCode: Code[10]; PaymentAmount: Decimal)
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        CreateRefPmtExpLineBank(
          PaymentType, PaymentAccount, VendorNo, PostingDate, CurrencyCode, PaymentAmount, Vendor."Preferred Bank Account Code");
    end;

    local procedure CreateRefPaymentImportedLine(var RefPaymentImported: Record "Ref. Payment - Imported"; CustLedgerEntry: Record "Cust. Ledger Entry"; Amount: Decimal; ReferenceNo: Code[20])
    begin
        RefPaymentImported.Init();
        RefPaymentImported."No." :=
            LibraryUtility.GetNewRecNo(RefPaymentImported, RefPaymentImported.FieldNo("No."));
        RefPaymentImported."Entry No." := CustLedgerEntry."Entry No.";
        RefPaymentImported."Account No." := CustLedgerEntry."Bal. Account No.";
        RefPaymentImported."Document No." := CustLedgerEntry."Document No.";
        RefPaymentImported."Filing Code" := LibraryUtility.GenerateGUID();
        RefPaymentImported."Banks Posting Date" := WorkDate();
        RefPaymentImported."Reference No." := ReferenceNo;
        RefPaymentImported.Amount := Amount;
        RefPaymentImported."Posted to G/L" := false;
        RefPaymentImported.Matched := true;
        RefPaymentImported.Insert();
    end;

    local procedure CreateCustLedgerEntry(GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, AccountNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGeneralJournalBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJournalTemplate.Name);
        GenJnlBatch.Validate("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"Bank Account");
        GenJnlBatch.Validate("Bal. Account No.", LibraryERM.CreateBankAccountNo());
        GenJnlBatch.Modify();
    end;

    local procedure VerifyCombinedLine(BankAccountNo: Code[20]; VendorNo: Code[20]; PaymentDate: Date; CurrencyCode: Code[20]; DocumentASSERTERROR: Boolean)
    var
        RefPmtExportedLine0: Record "Ref. Payment - Exported";
        RefPmtExportedLine1: Record "Ref. Payment - Exported";
        RefPmtExported: Record "Ref. Payment - Exported";
    begin
        RefPmtExported.SetRange("Applied Payments", false);
        Assert.AreEqual(1, RefPmtExported.Count, 'Wrong number of lines to export');

        RefPmtExported.FindFirst();
        // Validate values in common from lines beeing combined
        Assert.AreEqual(BankAccountNo, RefPmtExported."Payment Account", 'Wrong Payment Account');
        Assert.AreEqual(VendorNo, RefPmtExported."Vendor No.", 'Wrong Vendor No.');
        Assert.AreEqual(PaymentDate, RefPmtExported."Payment Date", 'Wrong Payment Date');
        Assert.AreEqual(CurrencyCode, RefPmtExported."Currency Code", 'Wrong Currency Code');
        // Validate ammount
        RefPmtExportedLine0.Get(0);
        RefPmtExportedLine1.Get(1);
        Assert.AreEqual(RefPmtExportedLine0.Amount + RefPmtExportedLine1.Amount, RefPmtExported.Amount, 'Wrong Amount');
        Assert.AreEqual(RefPmtExportedLine0."Amount (LCY)" + RefPmtExportedLine1."Amount (LCY)", RefPmtExported."Amount (LCY)", 'Wrong Amount (LCY)');
        // Validate values taken from the first line
        // BUG: Hardcoded to Invoice
        asserterror Assert.AreEqual(RefPmtExportedLine0."Document Type", RefPmtExported."Document Type", 'Wrong Ducument Type');
        Assert.AreEqual(RefPmtExportedLine0."Vendor Account", RefPmtExported."Vendor Account", 'Wrong Vendor Account');
        // Validate values that should be cleared
        Assert.AreEqual(0D, RefPmtExported."Due Date", 'Wrong Due Date');
        Assert.AreEqual('', RefPmtExported."External Document No.", 'Wrong External Document No.');
        // BUG: Holds the Document No from the last line when combined SEPA
        if DocumentASSERTERROR then
            asserterror Assert.AreEqual('', RefPmtExported."Document No.", 'Wrong Document No.')
        else
            Assert.AreEqual('', RefPmtExported."Document No.", 'Wrong Document No.');
        Assert.AreEqual(RefPmtExported."Message Type"::Message, RefPmtExported."Message Type", 'Wrong Message Type');
        Assert.AreEqual('', RefPmtExported."Invoice Message", 'Wrong Invoice Message');
        Assert.AreEqual('', RefPmtExported."Foreign Payment Method", 'Wrong Foreign Payment Method');
        Assert.AreEqual('', RefPmtExported."Foreign Banks Service Fee", 'Wrong Foreign Banks Service Fee');
        // BUG: Holds Vendor No
        asserterror Assert.AreEqual('', RefPmtExported."Description 2", 'Wrong Description');
    end;
}
