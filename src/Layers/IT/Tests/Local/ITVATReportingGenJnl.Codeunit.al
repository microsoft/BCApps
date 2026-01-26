codeunit 144006 "IT - VAT Reporting - Gen. Jnl."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVATUtils: Codeunit "Library - VAT Utils";
        isInitialized: Boolean;
        ErrorYouMustSpecify: Label 'You must specify a value for the %1 field';

    [Test]
    [Scope('OnPrem')]
    procedure ZeroThresholdAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATTransRepAmount: Record "VAT Transaction Report Amount";
        Amount: Decimal;
        GenPostingType: Enum "General Posting Type";
        DocumentType: Enum "Gen. Journal Document Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        // Gen. Journal Line with Customer Invoice.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Starting Date = WorkDate(), [Threshold Amount Incl. VAT.] = 0, Line Amount > 0.
        // Expected Result: [Include in VAT Transac. Rep.] = Yes in Gen. Journal Line.
        Initialize();

        // Setup.
        DocumentType := GenJournalLine."Document Type"::Invoice;
        AccountType := GenJournalLine."Account Type"::Customer;

        // Create Default Amount Threshold.
        CreateVATTransReportAmount(VATTransRepAmount, WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Calculate Gen. Journal Line Amount.
        Amount := LibraryRandom.RandDec(10000, 2);

        // Create Gen. Journal Line.
        GenPostingType := GetGenPostingType(AccountType);
        CreateGenJnlLine(GenJournalLine, DocumentType, GenPostingType, AccountType, CreateDefaultAccount(GenPostingType, AccountType), Amount);

        // Verify Include in VAT Transac. Rep.
        GenJournalLine.TestField("Include in VAT Transac. Rep.", true);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiThreshholdFutureBelow()
    begin
        // Gen. Journal Line with Customer Invoice.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Starting Date = WorkDate(), [Threshold Amount Incl. VAT.] > Line Amount.
        // Starting Date = +10D, [Threshold Amount Incl. VAT.] < Line Amount.
        // Expected Result: [Include in VAT Transac. Rep.] = Yes in Gen. Journal Line.
        VerifyMultipleThreshold(LibraryRandom.RandInt(10), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiThreshholdFutureAbove()
    begin
        // Gen. Journal Line with Customer Invoice.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Starting Date = WorkDate(), [Threshold Amount Incl. VAT.] < Line Amount.
        // Starting Date = +10D, [Threshold Amount Incl. VAT.] > Line Amount.
        // Expected Result: [Include in VAT Transac. Rep.] = Yes in Gen. Journal Line.
        VerifyMultipleThreshold(LibraryRandom.RandInt(10), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiThreshholdPastBelow()
    begin
        // Gen. Journal Line with Customer Invoice.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Starting Date = WorkDate(), [Threshold Amount Incl. VAT.] > Line Amount.
        // Starting Date = -10D, [Threshold Amount Incl. VAT.] < Line Amount.
        // Expected Result: [Include in VAT Transac. Rep.] = Yes in Gen. Journal Line.
        VerifyMultipleThreshold(-LibraryRandom.RandInt(10), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiThreshholdPastAbove()
    begin
        // Gen. Journal Line with Customer Invoice.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Starting Date = WorkDate(), [Threshold Amount Incl. VAT.] < Line Amount.
        // Starting Date = -10D, [Threshold Amount Incl. VAT.] > Line Amount.
        // Expected Result: [Include in VAT Transac. Rep.] = Yes in Gen. Journal Line.
        VerifyMultipleThreshold(-LibraryRandom.RandInt(10), true);
    end;

    local procedure VerifyMultipleThreshold(Days: Integer; InclInVATTransRep: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATTransRepAmount: Record "VAT Transaction Report Amount";
        Amount: Decimal;
        GenPostingType: Enum "General Posting Type";
        DocumentType: Enum "Gen. Journal Document Type";
        AccountType: Enum "Gen. Journal Account Type";
        Delta: DateFormula;
    begin
        Initialize();

        // Setup.
        DocumentType := GenJournalLine."Document Type"::Invoice;
        AccountType := GenJournalLine."Account Type"::Customer;

        // Create Default Amount Threshold.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Calculate Gen. Journal Line Amount.
        Amount := CalculateAmount(WorkDate(), true, InclInVATTransRep);

        // Create Additional Amount Threshold (overriding expected behaviour).
        Evaluate(Delta, '<' + Format(Days) + 'D>');
        CreateVATTransReportAmount(VATTransRepAmount, CalcDate(Delta, WorkDate()));
        if InclInVATTransRep then begin
            VATTransRepAmount.Validate("Threshold Amount Incl. VAT", Amount * 2);
            VATTransRepAmount.Validate("Threshold Amount Excl. VAT", Amount * 2);
        end else begin
            VATTransRepAmount.Validate("Threshold Amount Incl. VAT", Amount / 2);
            VATTransRepAmount.Validate("Threshold Amount Excl. VAT", Amount / 2);
        end;
        VATTransRepAmount.Modify(true);

        // Create Gen. Journal Line.
        GenPostingType := GetGenPostingType(AccountType);
        CreateGenJnlLine(GenJournalLine, DocumentType, GenPostingType, AccountType, CreateDefaultAccount(GenPostingType, AccountType), Amount);

        // Verify Include in VAT Transac. Rep.
        GenJournalLine.TestField("Include in VAT Transac. Rep.", true); // Amount is no longer compared to Threshold.

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlCustomerInvIncl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Gen. Journal Line with Customer Invoice.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes in Gen. Journal Line.
        VerifyGenJnlLineIncl(GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlCustomerInvExcl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Gen. Journal Line with Customer Invoice.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount < [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No in Gen. Journal Line.
        VerifyGenJnlLineIncl(GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlCustomerInvExcl2()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Gen. Journal Line with Customer Invoice.
        // [Include in VAT Transac. Rep.] = No in VAT Posting Setup.
        // Line Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No in Gen. Journal Line.
        VerifyGenJnlLineIncl(GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlVendorInvIncl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Gen. Journal Line with Vendor Invoice.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes in Gen. Journal Line.
        VerifyGenJnlLineIncl(GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlVendorInvExcl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Gen. Journal Line with Vendor Invoice.
        // [Include in VAT Transac. Rep.] = No in VAT Posting Setup.
        // Line Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No in Gen. Journal Line.
        VerifyGenJnlLineIncl(GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlVendorInvExcl2()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Gen. Journal Line with Vendor Invoice.
        // [Include in VAT Transac. Rep.] = No in VAT Posting Setup.
        // Line Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No in Gen. Journal Line.
        VerifyGenJnlLineIncl(GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, false, true);
    end;

    local procedure VerifyGenJnlLineIncl(DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; InclInVATSetup: Boolean; InclInVATTransRep: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        GenPostingType: Enum "General Posting Type";
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(InclInVATSetup);

        // Create Gen. Journal Line.
        Amount := CalculateAmount(WorkDate(), true, InclInVATTransRep);
        GenPostingType := GetGenPostingType(AccountType);
        CreateGenJnlLine(GenJournalLine, DocumentType, GenPostingType, AccountType, CreateDefaultAccount(GenPostingType, AccountType), Amount);

        // Verify Include in VAT Transac. Rep.
        GenJournalLine.TestField("Include in VAT Transac. Rep.", InclInVATSetup); // Amount is no longer compared to Threshold.

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EUCountryGenJnlKnCustInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCountryGenJnlLine(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale,
          GenJournalLine."Account Type"::Customer, false, CreateCountry());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EUCountryGenJnlIndSalesPay()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCountryGenJnlLine(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Sale,
          GenJournalLine."Account Type"::"G/L Account", true, CreateCountry());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EUCountryGenJnlKnVendInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCountryGenJnlLine(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase,
          GenJournalLine."Account Type"::Vendor, false, CreateCountry());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EUCountryGenJnlIndPurchPay()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyCountryGenJnlLine(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Purchase,
          GenJournalLine."Account Type"::"G/L Account", true, CreateCountry());
    end;

    local procedure VerifyCountryGenJnlLine(DocumentType: Enum "Gen. Journal Document Type"; GenPostingType: Enum "General Posting Type"; AccountType: Enum "Gen. Journal Account Type"; IndividualPerson: Boolean; CountryRegionCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        AccountNo: Code[20];
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Create Gen. Journal Line.
        Amount := CalculateAmount(WorkDate(), true, true);

        // Create Account.
        AccountNo := CreateAccount(GenPostingType, AccountType, IndividualPerson, GenJournalLine.Resident::"Non-Resident", false);
        case AccountType of
            GenJournalLine."Account Type"::Customer:
                AssignCountry(DATABASE::Customer, AccountNo, CountryRegionCode);
            GenJournalLine."Account Type"::Vendor:
                AssignCountry(DATABASE::Vendor, AccountNo, CountryRegionCode);
        end;

        // Create Gen. Journal Line.
        CreateGenJnlLine(GenJournalLine, DocumentType, GenPostingType, AccountType, AccountNo, Amount);

        // Update Individual Person, Resident.
        if AccountType = GenJournalLine."Account Type"::"G/L Account" then
            UpdateIndResGenJnlLine(GenJournalLine, IndividualPerson, GenJournalLine.Resident::"Non-Resident", CountryRegionCode);

        // Verify Include in VAT Transac. Rep.
        GenJournalLine.TestField("Include in VAT Transac. Rep.", false);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlManualInclude()
    var
        GeneralJournalTestPage: TestPage "General Journal";
        CashReceiptJournalTestPage: TestPage "Cash Receipt Journal";
        PaymentJournalTestPage: TestPage "Payment Journal";
        PurchaseJournalTestPage: TestPage "Purchase Journal";
        SalesJournalTestPage: TestPage "Sales Journal";
    begin
        // Verify EDITABLE is TRUE through pages because property is not available through record.
        // General Journal.
        GeneralJournalTestPage.OpenEdit();
        Assert.IsTrue(GeneralJournalTestPage."Include in VAT Transac. Rep.".Editable(), 'EDITABLE should be TRUE for the field ' + GeneralJournalTestPage."Include in VAT Transac. Rep.".Caption);
        GeneralJournalTestPage.Close();

        // Cash Receipt Journal Journal.
        Commit();
        // Required for Cash Receipt Journal.
        CashReceiptJournalTestPage.OpenEdit();
        Assert.IsTrue(CashReceiptJournalTestPage."Include in VAT Transac. Rep.".Editable(), 'EDITABLE should be TRUE for the field ' + CashReceiptJournalTestPage."Include in VAT Transac. Rep.".Caption);
        CashReceiptJournalTestPage.Close();
        // Payment Journal.
        PaymentJournalTestPage.OpenEdit();
        Assert.IsTrue(PaymentJournalTestPage."Include in VAT Transac. Rep.".Editable(), 'EDITABLE should be TRUE for the field ' + PaymentJournalTestPage."Include in VAT Transac. Rep.".Caption);
        PaymentJournalTestPage.Close();

        // Purchase Journal.
        Commit();
        // Required for Purchase Journal.
        PurchaseJournalTestPage.OpenEdit();
        Assert.IsTrue(PurchaseJournalTestPage."Include in VAT Transac. Rep.".Editable(), 'EDITABLE should be TRUE for the field ' + PurchaseJournalTestPage."Include in VAT Transac. Rep.".Caption);
        PurchaseJournalTestPage.Close();

        // Sales Journal.
        Commit();
        // Required for Sales Journal.
        SalesJournalTestPage.OpenEdit();
        Assert.IsTrue(SalesJournalTestPage."Include in VAT Transac. Rep.".Editable(), 'EDITABLE should be TRUE for the field ' + SalesJournalTestPage."Include in VAT Transac. Rep.".Caption);
        SalesJournalTestPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlCustInvPostIncl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Gen. Journal Line with Customer Invoice.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes in VAT Entry.
        VerifyGenJnlLinePostIncl(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::Customer, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlCustInvPostExcl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Gen. Journal Line with Customer Invoice.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount < [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No in VAT Entry.
        VerifyGenJnlLinePostIncl(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::Customer, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlCustPayPostIncl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Gen. Journal Line with Payment from Individual Person Customer.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes in VAT Entry.
        VerifyGenJnlLinePostIncl(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::"G/L Account", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlCustPayPostExcl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Gen. Journal Line with Payment from Individual Person Customer.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount < [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No in VAT Entry.
        VerifyGenJnlLinePostIncl(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::"G/L Account", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlVendInvPostIncl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Gen. Journal Line with Vendor Invoice.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes in VAT Entry.
        VerifyGenJnlLinePostIncl(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::Vendor, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlVendInvPostExcl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Gen. Journal Line with Vendor Invoice.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount < [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No in VAT Entry.
        VerifyGenJnlLinePostIncl(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::Vendor, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlVendPayPostIncl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Gen. Journal Line with Payment to Individual Person Vendor.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount > [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = Yes in VAT Entry.
        VerifyGenJnlLinePostIncl(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::"G/L Account", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlVendPayPostExcl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Gen. Journal Line with Payment to Individual Person Vendor.
        // [Include in VAT Transac. Rep.] = Yes in VAT Posting Setup.
        // Line Amount < [Threshold Amount Incl. VAT.]
        // Expected Result: [Include in VAT Transac. Rep.] = No in VAT Entry.
        VerifyGenJnlLinePostIncl(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::"G/L Account", false);
    end;

    local procedure VerifyGenJnlLinePostIncl(DocumentType: Enum "Gen. Journal Document Type"; GenPostingType: Enum "General Posting Type"; AccountType: Enum "Gen. Journal Account Type"; InclInVATTransRep: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Create Gen. Journal Line.
        Amount := CalculateAmount(WorkDate(), true, InclInVATTransRep);
        CreateGenJnlLine(GenJournalLine, DocumentType, GenPostingType, AccountType, CreateDefaultAccount(GenPostingType, AccountType), Amount);

        // Enter VAT Registration No.
        UpdateReqFldsGenJnlLine(GenJournalLine);

        // Post Gen. Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify Include in VAT Transac. Rep.
        VerifyIncludeVAT(DocumentType, GenJournalLine."Document No.", true); // Amount is no longer compared to Threshold.

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlIndCustResFiscalCode()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that error message is generated when posting Gen. Journal Line without [Fiscal Code].
        // Gen. Posting Type = Sale.
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Resident.
        // Expected Result: posting is aborted with error message.
        VerifyGenJnlLineReqFields(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::"G/L Account", true, GenJournalLine.Resident::Resident, GenJournalLine.FieldNo("Fiscal Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlIndCustNonResCntryRegion()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that error message is generated when posting Gen. Journal Line without [Country/Region Code].
        // Gen. Posting Type = Sale.
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifyGenJnlLineReqFields(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::"G/L Account", true, GenJournalLine.Resident::"Non-Resident", GenJournalLine.FieldNo("Country/Region Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlIndCustNonResFirstName()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that error message is generated when posting Gen. Journal Line without [First Name].
        // Gen. Posting Type = Sale.
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifyGenJnlLineReqFields(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::"G/L Account", true, GenJournalLine.Resident::"Non-Resident", GenJournalLine.FieldNo("First Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlIndCustNonResLastName()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that error message is generated when posting Gen. Journal Line without [Last Name].
        // Gen. Posting Type = Sale.
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifyGenJnlLineReqFields(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::"G/L Account", true, GenJournalLine.Resident::"Non-Resident", GenJournalLine.FieldNo("Last Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlIndCustNonResDateOfBirth()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that error message is generated when posting Gen. Journal Line without [Date of Birth].
        // Gen. Posting Type = Sale.
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifyGenJnlLineReqFields(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::"G/L Account", true, GenJournalLine.Resident::"Non-Resident", GenJournalLine.FieldNo("Date of Birth"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlIndCustNonResPlOfBirth()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that error message is generated when posting Gen. Journal Line without [Place of Birth].
        // Gen. Posting Type = Sale.
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifyGenJnlLineReqFields(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::"G/L Account", true, GenJournalLine.Resident::"Non-Resident", GenJournalLine.FieldNo("Place of Birth"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlKnCustResVATRegNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that error message is generated when posting Gen. Journal Line without [VAT Registration No.].
        // Gen. Posting Type = Sale.
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = No.
        // Resident = Resident.
        // Expected Result: posting is aborted with error message.
        VerifyGenJnlLineReqFields(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::Customer, false, GenJournalLine.Resident::Resident, GenJournalLine.FieldNo("VAT Registration No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlIndVendResFiscalCode()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that error message is generated when posting Gen. Journal Line without [Fiscal Code].
        // Gen. Posting Type = Purchase.
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Resident.
        // Expected Result: posting is aborted with error message.
        VerifyGenJnlLineReqFields(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::"G/L Account", true, GenJournalLine.Resident::Resident, GenJournalLine.FieldNo("Fiscal Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlIndVendNonResCtryRegion()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that error message is generated when posting Gen. Journal Line without [Country/Region Code].
        // Gen. Posting Type = Purchase.
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifyGenJnlLineReqFields(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::"G/L Account", true, GenJournalLine.Resident::"Non-Resident", GenJournalLine.FieldNo("Country/Region Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlIndVendNonResFirstName()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that error message is generated when posting Gen. Journal Line without [First Name].
        // Gen. Posting Type = Purchase.
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifyGenJnlLineReqFields(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::"G/L Account", true, GenJournalLine.Resident::"Non-Resident", GenJournalLine.FieldNo("First Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlIndVendNonResLastName()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that error message is generated when posting Gen. Journal Line without [Last Name].
        // Gen. Posting Type = Purchase.
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifyGenJnlLineReqFields(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::"G/L Account", true, GenJournalLine.Resident::"Non-Resident", GenJournalLine.FieldNo("Last Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlIndVendNonResDateOfBirth()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that error message is generated when posting Gen. Journal Line without [Place of Birth].
        // Gen. Posting Type = Purchase.
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifyGenJnlLineReqFields(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::"G/L Account", true, GenJournalLine.Resident::"Non-Resident", GenJournalLine.FieldNo("Date of Birth"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlIndVendNonResPlOfBirth()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that error message is generated when posting Gen. Journal Line without [Place of Birth].
        // Gen. Posting Type = Purchase.
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is aborted with error message.
        VerifyGenJnlLineReqFields(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::"G/L Account", true, GenJournalLine.Resident::"Non-Resident", GenJournalLine.FieldNo("Place of Birth"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlKnVendResVATRegNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that error message is generated when posting Gen. Journal Line without [VAT Registration No.].
        // Gen. Posting Type = Purchase.
        // [Include in VAT Transac. Rep.] = Yes.
        // Individual Person = No.
        // Resident = Resident.
        // Expected Result: posting is aborted with error message.
        VerifyGenJnlLineReqFields(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::Vendor, false, GenJournalLine.Resident::Resident, GenJournalLine.FieldNo("VAT Registration No."));
    end;

    local procedure VerifyGenJnlLineReqFields(DocumentType: Enum "Gen. Journal Document Type"; GenPostingType: Enum "General Posting Type"; AccountType: Enum "Gen. Journal Account Type"; IndividualPerson: Boolean; Resident: Option; FieldId: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        FieldRef: FieldRef;
        RecordRef: RecordRef;
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(true);

        // Create Gen. Journal Line.
        Amount := CalculateAmount(WorkDate(), true, true);
        CreateGenJnlLine(GenJournalLine, DocumentType, GenPostingType, AccountType, CreateDefaultAccount(GenPostingType, AccountType), Amount);

        // Modify Individual Person, Resident.
        GenJournalLine.Validate("Individual Person", IndividualPerson);
        GenJournalLine.Validate(Resident, Resident);

        // Update Required Fields for Individual Person and Non-Resident.
        UpdateReqFldsGenJnlLine(GenJournalLine);

        // Remove Value from Field under test.
        RecordRef.GetTable(GenJournalLine);
        FieldRef := RecordRef.Field(FieldId);
        ClearField(RecordRef, FieldRef);
        GenJournalLine.Find();

        // Try to Post Gen. Journal Line and verify Error Message.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Assert.ExpectedError(StrSubstNo(ErrorYouMustSpecify, FieldRef.Caption));

        // Tear Down.
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlIndCustResFiscalCodeExcl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that no error message is generated when posting Gen. Journal Line without [Fiscal Code].
        // Gen. Posting Type = Sale.
        // [Include in VAT Transac. Rep.] = No.
        // Individual Person = Yes.
        // Resident = Resident.
        // Expected Result: posting is completed successfully.
        VerifyGenJnlLineReqFieldsExcl(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::"G/L Account", true, GenJournalLine.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlIndCustNonResExcl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that no error message is generated when posting Gen. Journal Line without [Country/Region Code] and other required details.
        // Gen. Posting Type = Sale.
        // [Include in VAT Transac. Rep.] = No.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is completed successfully.
        VerifyGenJnlLineReqFieldsExcl(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::"G/L Account", true, GenJournalLine.Resident::"Non-Resident");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlKnCustResExcl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that no error message is generated when posting Gen. Journal Line without [VAT Registration No.].
        // Gen. Posting Type = Sale.
        // [Include in VAT Transac. Rep.] = No.
        // Individual Person = No.
        // Resident = Resident.
        // Expected Result: posting is completed successfully.
        VerifyGenJnlLineReqFieldsExcl(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::Customer, false, GenJournalLine.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlIndVendResFiscalCodeExcl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that no error message is generated when posting Gen. Journal Line without [Fiscal Code].
        // Gen. Posting Type = Purchase.
        // [Include in VAT Transac. Rep.] = No.
        // Individual Person = Yes.
        // Resident = Resident.
        // Expected Result: posting is completed successfully.
        VerifyGenJnlLineReqFieldsExcl(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::"G/L Account", true, GenJournalLine.Resident::Resident);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlIndVendNonResExcl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that no error message is generated when posting Gen. Journal Line without [Country/Region Code] and other required fields.
        // Gen. Posting Type = Purchase.
        // [Include in VAT Transac. Rep.] = No.
        // Individual Person = Yes.
        // Resident = Non-Resident.
        // Expected Result: posting is completed successfully.
        VerifyGenJnlLineReqFieldsExcl(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::"G/L Account", true, GenJournalLine.Resident::"Non-Resident");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlKnVendResExcl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that no error message is generated when posting Gen. Journal Line without [VAT Registration No.].
        // Gen. Posting Type = Purchase.
        // [Include in VAT Transac. Rep.] = No.
        // Individual Person = No.
        // Resident = Resident.
        // Expected Result: posting is completed successfully.
        VerifyGenJnlLineReqFieldsExcl(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::Vendor, false, GenJournalLine.Resident::Resident);
    end;

    local procedure VerifyGenJnlLineReqFieldsExcl(DocumentType: Enum "Gen. Journal Document Type"; GenPostingType: Enum "General Posting Type"; AccountType: Enum "Gen. Journal Account Type"; IndividualPerson: Boolean; Resident: Option)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        AccountNo: Code[20];
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(false);

        // Create Account.
        AccountNo := CreateAccount(GenPostingType, AccountType, IndividualPerson, Resident, false);

        // Create Gen. Journal Line.
        Amount := CalculateAmount(WorkDate(), true, true);
        CreateGenJnlLine(GenJournalLine, DocumentType, GenPostingType, AccountType, AccountNo, Amount);

        if AccountType = GenJournalLine."Account Type"::"G/L Account" then begin
            GenJournalLine.Validate("Individual Person", IndividualPerson);
            GenJournalLine.Validate(Resident, Resident);
            GenJournalLine.Modify(true);
        end;

        // Post Gen. Journal Line (no error message).
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Tear Down.
        TearDown();
    end;

    local procedure Initialize()
    begin
        TearDown(); // Cleanup.
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;

        isInitialized := true;
        CreateVATReportSetup();
        Commit();

        TearDown(); // Cleanup for the first test.
    end;

    local procedure AdjustAmountSign(Amount: Decimal; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; GenPostingType: Enum "General Posting Type"): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if ((DocumentType = GenJournalLine."Document Type"::Invoice) and (AccountType = GenJournalLine."Account Type"::Vendor)) or
           ((DocumentType = GenJournalLine."Document Type"::Refund) and (AccountType = GenJournalLine."Account Type"::Vendor)) or
           ((DocumentType = GenJournalLine."Document Type"::Payment) and (AccountType = GenJournalLine."Account Type"::Customer)) or
           ((DocumentType = GenJournalLine."Document Type"::"Credit Memo") and (AccountType = GenJournalLine."Account Type"::Customer)) or
           ((DocumentType = GenJournalLine."Document Type"::Invoice) and (AccountType = GenJournalLine."Account Type"::"G/L Account") and (GenPostingType = GenJournalLine."Gen. Posting Type"::Sale)) or
           ((DocumentType = GenJournalLine."Document Type"::"Credit Memo") and (AccountType = GenJournalLine."Account Type"::"G/L Account") and (GenPostingType = GenJournalLine."Gen. Posting Type"::Purchase))
        then
            Amount := -Abs(Amount);
        exit(Amount);
    end;

    local procedure AssignCountry(TableID: Option; AccountNo: Code[20]; CountryRegionCode: Code[10])
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        case TableID of
            DATABASE::Customer:
                begin
                    Customer.Get(AccountNo);
                    Customer.Validate("Country/Region Code", CountryRegionCode);
                    Customer.Modify(true);
                end;
            DATABASE::Vendor:
                begin
                    Vendor.Get(AccountNo);
                    Vendor.Validate("Country/Region Code", CountryRegionCode);
                    Vendor.Modify(true);
                end;
        end;
    end;

    local procedure CalculateAmount(StartingDate: Date; InclVAT: Boolean; InclInVATTransRep: Boolean) Amount: Decimal
    var
        Delta: Decimal;
    begin
        // Random delta should be less than difference between Threshold Incl. VAT and Excl. VAT.
        Delta := LibraryRandom.RandDec(GetThresholdAmount(StartingDate, true) - GetThresholdAmount(StartingDate, false), 2);

        if not InclInVATTransRep then
            Delta := -Delta;

        Amount := GetThresholdAmount(StartingDate, InclVAT) + Delta;
    end;

    local procedure ClearField(RecordRef: RecordRef; FieldRef: FieldRef)
    var
        FieldRef2: FieldRef;
        RecordRef2: RecordRef;
    begin
        RecordRef2.Open(RecordRef.Number, true); // Open temp table.
        FieldRef2 := RecordRef2.Field(FieldRef.Number);

        FieldRef.Validate(FieldRef2.Value); // Clear field value.
        RecordRef.Modify(true);
    end;

    local procedure CreateAccount(GenPostingType: Enum "General Posting Type"; AccountType: Enum "Gen. Journal Account Type"; IndividualPerson: Boolean; Resident: Option; InclVAT: Boolean) AccountNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        case AccountType of
            GenJournalLine."Account Type"::"G/L Account":
                AccountNo := CreateGLAccount(GenPostingType);
            GenJournalLine."Account Type"::Customer:
                AccountNo := CreateCustomer(IndividualPerson, Resident, true, InclVAT);
            GenJournalLine."Account Type"::Vendor:
                AccountNo := CreateVendor(IndividualPerson, Resident, true, InclVAT);
        end;
    end;

    local procedure CreateCountry(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Intrastat Code", CountryRegion.Code); // Fill with Country Code as value is not important for test.
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    local procedure CreateCustomer(IndividualPerson: Boolean; Resident: Option; ReqFlds: Boolean; PricesInclVAT: Boolean): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibrarySales.CreateCustomer(Customer);
        if not FindVATPostingSetup(VATPostingSetup, true) then
            FindVATPostingSetup(VATPostingSetup, false);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Individual Person", IndividualPerson);
        Customer.Validate(Resident, Resident);

        if ReqFlds then begin
            if Resident = Customer.Resident::"Non-Resident" then
                Customer.Validate("Country/Region Code", GetCountryCode());
            if not IndividualPerson then
                Customer.Validate("VAT Registration No.", LibraryUtility.GenerateRandomCode(Customer.FieldNo("VAT Registration No."), DATABASE::Customer))
            else
                case Resident of
                    Customer.Resident::Resident:
                        Customer."Fiscal Code" := LibraryUtility.GenerateRandomCode(Customer.FieldNo("Fiscal Code"), DATABASE::Customer); // Validation of Fiscal Code is not important.
                    Customer.Resident::"Non-Resident":
                        begin
                            Customer.Validate("First Name", LibraryUtility.GenerateRandomCode(Customer.FieldNo("First Name"), DATABASE::Customer));
                            Customer.Validate("Last Name", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Last Name"), DATABASE::Customer));
                            Customer.Validate("Date of Birth", CalcDate('<-' + Format(LibraryRandom.RandInt(100)) + 'Y>'));
                            Customer.Validate("Place of Birth", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Place of Birth"), DATABASE::Customer));
                        end;
                end;
        end;

        Customer.Validate("Prices Including VAT", PricesInclVAT);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateDefaultAccount(GenPostingType: Enum "General Posting Type"; AccountType: Enum "Gen. Journal Account Type") AccountNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        AccountNo := CreateAccount(GenPostingType, AccountType, false, GenJournalLine.Resident::Resident, false); // This is Default Option.
    end;

    local procedure CreateGLAccount(GenPostingType: Enum "General Posting Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT"); // Always use Normal for G/L Accounts.
        if not FindVATPostingSetup(VATPostingSetup, true) then
            FindVATPostingSetup(VATPostingSetup, false);

        // Gen. Posting Type, Gen. Bus. and VAT Bus. Posting Groups are required for General Journal.
        if GenPostingType <> GLAccount."Gen. Posting Type"::" " then begin
            GLAccount.Validate("Gen. Posting Type", GenPostingType);
            GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
            GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        end;
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateVendor(IndividualPerson: Boolean; Resident: Option; ReqFlds: Boolean; PricesInclVAT: Boolean): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        if not FindVATPostingSetup(VATPostingSetup, true) then
            FindVATPostingSetup(VATPostingSetup, false);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Individual Person", IndividualPerson);
        Vendor.Validate(Resident, Resident);

        if ReqFlds then begin
            if Resident = Vendor.Resident::"Non-Resident" then
                Vendor.Validate("Country/Region Code", GetCountryCode());

            if not IndividualPerson then
                Vendor.Validate("VAT Registration No.", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("VAT Registration No."), DATABASE::Vendor))
            else
                case Resident of
                    Vendor.Resident::Resident:
                        Vendor."Fiscal Code" := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Fiscal Code"), DATABASE::Vendor); // Validation of Fiscal Code is not important.
                    Vendor.Resident::"Non-Resident":
                        begin
                            Vendor.Validate("First Name", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("First Name"), DATABASE::Vendor));
                            Vendor.Validate("Last Name", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Last Name"), DATABASE::Vendor));
                            Vendor.Validate("Date of Birth", CalcDate('<-' + Format(LibraryRandom.RandInt(100)) + 'Y>'));
                            Vendor.Validate("Birth City", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Birth City"), DATABASE::Vendor));
                        end;
                end;
        end;

        Vendor.Validate("Prices Including VAT", PricesInclVAT);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; GenPostingType: Enum "General Posting Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BalAccountType: Enum "Gen. Journal Document Type";
        BalAccountNo: Code[20];
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        case AccountType of
            GenJournalLine."Account Type"::"G/L Account":
                begin
                    BalAccountType := GenJournalLine."Bal. Account Type"::"Bank Account";
                    BalAccountNo := FindBankAccount();
                end;
            GenJournalLine."Account Type"::Customer:
                begin
                    BalAccountType := GenJournalLine."Bal. Account Type"::"G/L Account";
                    BalAccountNo := CreateGLAccount(GenPostingType);
                end;
            GenJournalLine."Account Type"::Vendor:
                begin
                    BalAccountType := GenJournalLine."Bal. Account Type"::"G/L Account";
                    BalAccountNo := CreateGLAccount(GenPostingType);
                end;
        end;
        Amount := AdjustAmountSign(Amount, DocumentType, AccountType, GenPostingType);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        // Create VAT Report Setup.
        if VATReportSetup.IsEmpty() then
            VATReportSetup.Insert(true);
        VATReportSetup.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        VATReportSetup.Modify(true);
    end;

    local procedure CreateVATTransReportAmount(var VATTransRepAmount: Record "VAT Transaction Report Amount"; StartingDate: Date)
    begin
        VATTransRepAmount.Init();
        VATTransRepAmount.Validate("Starting Date", StartingDate);
        VATTransRepAmount.Insert(true);
    end;

    local procedure EnableUnrealizedVAT(UnrealVAT: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Unrealized VAT", UnrealVAT);
        GLSetup.Modify(true);
    end;

    local procedure GetCountryCode(): Code[10]
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        CountryRegion.SetFilter(Code, '<>%1', CompanyInformation."Country/Region Code");
        CountryRegion.SetFilter("Intrastat Code", '');
        LibraryERM.FindCountryRegion(CountryRegion);
        exit(CountryRegion.Code);
    end;

    local procedure GetGenPostingType(AccountType: Enum "Gen. Journal Account Type") GenPostingType: Enum "General Posting Type"
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        case AccountType of
            GenJournalLine."Account Type"::Customer:
                GenPostingType := GenJournalLine."Gen. Posting Type"::Sale;
            GenJournalLine."Account Type"::Vendor:
                GenPostingType := GenJournalLine."Gen. Posting Type"::Purchase;
        end;
    end;

    local procedure GetThresholdAmount(StartingDate: Date; InclVAT: Boolean) Amount: Decimal
    var
        VATTransactionReportAmount: Record "VAT Transaction Report Amount";
    begin
        VATTransactionReportAmount.SetFilter("Starting Date", '<=%1', StartingDate);
        VATTransactionReportAmount.FindLast();

        if InclVAT then
            Amount := VATTransactionReportAmount."Threshold Amount Incl. VAT"
        else
            Amount := VATTransactionReportAmount."Threshold Amount Excl. VAT";
    end;

    local procedure FindBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.FindBankAccount(BankAccount);
        exit(BankAccount."No.");
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindSet();
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; IncludeInVATTransacRep: Boolean): Boolean
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '''''');
        VATPostingSetup.SetRange("VAT %", LibraryVATUtils.FindMaxVATRate(VATPostingSetup."VAT Calculation Type"::"Normal VAT"));
        VATPostingSetup.SetRange("Deductible %", 100);
        VATPostingSetup.SetRange("Include in VAT Transac. Rep.", IncludeInVATTransacRep);
        exit(VATPostingSetup.FindFirst())
    end;

    local procedure SetupThresholdAmount(StartingDate: Date)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATTransRepAmount: Record "VAT Transaction Report Amount";
        ThresholdAmount: Decimal;
        VATRate: Decimal;
    begin
        // Law States Threshold Incl. VAT as 3600 and Threshold Excl. VAT as 3000.
        // For test purpose Threshold Excl. VAT is generated randomly in 1000..10000 range.
        CreateVATTransReportAmount(VATTransRepAmount, StartingDate);
        VATRate := LibraryVATUtils.FindMaxVATRate(VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        ThresholdAmount := 1000 * LibraryRandom.RandInt(10);
        VATTransRepAmount.Validate("Threshold Amount Incl. VAT", ThresholdAmount * (1 + VATRate / 100));
        VATTransRepAmount.Validate("Threshold Amount Excl. VAT", ThresholdAmount);

        VATTransRepAmount.Modify(true);
    end;

    local procedure UpdateIndResGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; IndividualPerson: Boolean; Resident: Option; CountryRegionCode: Code[10])
    begin
        GenJournalLine.Validate("Individual Person", IndividualPerson);
        GenJournalLine.Validate(Resident, Resident);
        GenJournalLine.Validate("Country/Region Code", CountryRegionCode);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateReqFldsGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        // Update fields required for posting when Incl. in VAT Transac. Report is TRUE.
        if GenJournalLine.Resident = GenJournalLine.Resident::"Non-Resident" then
            GenJournalLine.Validate("Country/Region Code", GetCountryCode());

        if GenJournalLine."Individual Person" and (GenJournalLine.Resident = GenJournalLine.Resident::"Non-Resident") then begin
            GenJournalLine.Validate("First Name", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("First Name"), DATABASE::"Gen. Journal Line"));
            GenJournalLine.Validate("Last Name", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Last Name"), DATABASE::"Gen. Journal Line"));
            GenJournalLine.Validate("Date of Birth", CalcDate('<-' + Format(LibraryRandom.RandInt(100)) + 'Y>'));
            GenJournalLine.Validate("Place of Birth", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Place of Birth"), DATABASE::"Gen. Journal Line"));
        end;

        if GenJournalLine."Individual Person" and (GenJournalLine.Resident = GenJournalLine.Resident::Resident) then
            GenJournalLine."Fiscal Code" := LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Fiscal Code"), DATABASE::"Gen. Journal Line");
        // Validation skipped.
        if not GenJournalLine."Individual Person" and (GenJournalLine.Resident = GenJournalLine.Resident::Resident) then
            GenJournalLine."VAT Registration No." := LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("VAT Registration No."), DATABASE::"Gen. Journal Line");
        // Validation skipped.
        GenJournalLine.Modify(true);
    end;

    local procedure VerifyIncludeVAT(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; InclInVATTransRep: Boolean)
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, DocumentType, DocumentNo);
        repeat
            VATEntry.TestField("Include in VAT Transac. Rep.", InclInVATTransRep);
        until VATEntry.Next() = 0;
    end;

    local procedure TearDown()
    var
        VATTransRepAmount: Record "VAT Transaction Report Amount";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("Include in VAT Transac. Rep.", true);
        VATPostingSetup.ModifyAll("Sales Prepayments Account", '', true);
        VATPostingSetup.ModifyAll("Purch. Prepayments Account", '', true);
        VATPostingSetup.ModifyAll("Include in VAT Transac. Rep.", false, true);

        VATPostingSetup.Reset();
        VATPostingSetup.SetFilter("Unrealized VAT Type", '<>%1', VATPostingSetup."Unrealized VAT Type"::" ");
        VATPostingSetup.ModifyAll("Sales VAT Unreal. Account", '', true);
        VATPostingSetup.ModifyAll("Purch. VAT Unreal. Account", '', true);
        VATPostingSetup.ModifyAll("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ", true);

        VATTransRepAmount.DeleteAll(true);
        EnableUnrealizedVAT(false);
    end;
}

