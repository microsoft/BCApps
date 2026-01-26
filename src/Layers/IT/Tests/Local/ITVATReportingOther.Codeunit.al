codeunit 144011 "IT - VAT Reporting - Other"
{
    // // [FEATURE] [VAT][Reports]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVATUtils: Codeunit "Library - VAT Utils";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        ConfirmTextVATTransReport: Label 'The report will change the value of the Include in VAT Transaction Report fields to Yes for those VAT entries that match the filters that you specified. Do you want to continue?';
        Xlsx: Label '.xlsx';
        RefundTok: Label 'Refund';
        CreditMemoTok: Label 'Credit Memo';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateVATCompNosInclSalesInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyVATTransactionData(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::"G/L Account", false, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateVATCompYesInclSalesInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyVATTransactionData(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::"G/L Account", true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateVATCompNosExclSalesInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyVATTransactionData(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::"G/L Account", false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateVATCompYesExclSalesInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyVATTransactionData(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::"G/L Account", true, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateVATCompNoInclSalesCM()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyVATTransactionData(GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::"G/L Account", false, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateVATCompNoInclSalesPay()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyVATTransactionData(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Sale, GenJournalLine."Account Type"::"G/L Account", false, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateVATCompNosInclPurchInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyVATTransactionData(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::"G/L Account", false, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateVATCompYesInclPurchInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyVATTransactionData(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::"G/L Account", true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateVATCompNosExclPurchInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyVATTransactionData(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::"G/L Account", false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateVATCompYesExclPurchInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyVATTransactionData(GenJournalLine."Document Type"::Invoice, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::"G/L Account", true, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateVATCompNoInclPurchCM()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyVATTransactionData(GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::"G/L Account", false, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateVATCompNoInclPurchPay()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VerifyVATTransactionData(GenJournalLine."Document Type"::Payment, GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Account Type"::"G/L Account", false, true);
    end;

    local procedure VerifyVATTransactionData(DocumentType: Enum "Gen. Journal Document Type"; GenPostingType: Enum "General Posting Type"; AccountType: Enum "Gen. Journal Account Type"; CompAgainstThreshold: Boolean; SetIncludeInVATTransRep: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        SetupThresholdAmount(WorkDate());
        LibraryVATUtils.UpdateVATPostingSetup(not SetIncludeInVATTransRep);

        // Create Gen. Journal Line.
        Amount := CalculateAmount(WorkDate(), true, CompAgainstThreshold);
        CreateGenJnlLine(GenJournalLine, DocumentType, GenPostingType, AccountType, CreateDefaultAccount(GenPostingType, AccountType), Amount);

        // Update Journal Line.
        UpdateReqFldsGenJnlLine(GenJournalLine);
        GenJournalLine.Validate("Include in VAT Transac. Rep.", not SetIncludeInVATTransRep);
        GenJournalLine.Modify(true);

        // Post Gen. Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify Include in VAT Transac. Rep.
        VerifyIncludeVAT(DocumentType, GenJournalLine."Document No.", not SetIncludeInVATTransRep);

        // Run Update VAT Transaction Data Report.
        RunUpdateVATTransDataReport(DocumentType, GenJournalLine."Document No.", CompAgainstThreshold, false, SetIncludeInVATTransRep);

        // Verify Include in VAT Transac. Rep.
        VerifyIncludeVAT(DocumentType, GenJournalLine."Document No.", SetIncludeInVATTransRep);

        // Tear Down.
        TearDown();
    end;

    [Test]
    [HandlerFunctions('RequestHandlerVendorAccountBillsList')]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListRefundAndCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        PurchaseDocNo: Code[20];
        Amount: Decimal;
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Purchase][Vendor Account Bills List]
        // [SCENARIO 379767] First row of Vendor Account Bills List report should be refund and second row should be applied credit memo
        Initialize();

        // [GIVEN] Posted credit memo
        CreateAndPostPurchaseCreditMemo(VendorNo, Amount, PaymentNo);

        // [GIVEN] Posted refund applied to credit memo
        PurchaseDocNo := CreateApplyAndPostGenJnlLine(
            GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Vendor,
            VendorNo, GenJournalLine."Applies-to Doc. Type"::"Credit Memo", PaymentNo, -Amount);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        Commit();

        // [WHEN] Run Vendor Account Bills List
        RunVendorAccountBillsListReport(VendorNo);

        // [THEN] Row 14 contains refund
        // [THEN] Row 16 contains credit memo
        VerifyVendorAccountBillsListRefundAndCreditMemo(PurchaseDocNo, PaymentNo);
    end;

    [Test]
    [HandlerFunctions('RequestHandlerCustomerBillsList')]
    [Scope('OnPrem')]
    procedure CustomerBillsListRefundAndCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        SalesDocNo: Code[20];
        Amount: Decimal;
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Sales][Customer Bills List]
        // [SCENARIO 379767] First row of Customer Bills List report should be refund and second row should be applied credit memo
        Initialize();

        // [GIVEN] Posted credit memo
        CreateAndPostSalesCreditMemo(CustomerNo, Amount, PaymentNo);

        // [GIVEN] Posted refund applied to credit memo
        SalesDocNo := CreateApplyAndPostGenJnlLine(
            GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Customer,
            CustomerNo, GenJournalLine."Applies-to Doc. Type"::"Credit Memo", PaymentNo, Amount);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        Commit();

        // [WHEN] Run Customer Bills List
        RunCustomerBillsListReport(CustomerNo);

        // [THEN] Row 15 contains refund
        // [THEN] Row 16 contains credit memo
        VerifyCustomerBillsListRefundAndCreditMemo(SalesDocNo, PaymentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseVATReportWithoutSpesometroAppointmentEntries()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportMediator: Codeunit "VAT Report Mediator";
        PostingDate: Date;
    begin
        // [FEATURE] [Release]
        // [SCENARIO 228087] Cassie can release VAT Report at date without Spesometro Appointment entries
        Initialize();
        UpdateCompanyInformation();

        // [GIVEN] Date without VAT Entries 15.03.2019
        PostingDate := GetLastVATEntryOpOccrDate() + 1;

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Release VAT Report
        VATReportMediator.Release(VATReportHeader);

        // [THEN] VAT Report Status = Released
        VATReportHeader.Find();
        VATReportHeader.TestField(Status, VATReportHeader.Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseVATReporIndividualTaxRepresentative()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        Vendor: Record Vendor;
        VATReportMediator: Codeunit "VAT Report Mediator";
        PostingDate: Date;
    begin
        // [FEATURE] [Release]
        // [SCENARIO 251924] Cassie can release VAT Report when individual Vendor as Tax Representative in Company Inf. with filled First and Last Name
        Initialize();
        UpdateCompanyInformation();

        // [GIVEN] Individual Vendor "Vend" with filled First and Last Name
        CreateIndividualVendor(Vendor);

        // [GIVEN] Vendor "Vend" as Tax Representative in Company Informatino
        UpdateCompanyInformationTaxRepresentative(Vendor."No.");

        // [GIVEN] Date without VAT Entries 15.03.2019
        PostingDate := GetLastVATEntryOpOccrDate() + 1;

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Release VAT Report
        VATReportMediator.Release(VATReportHeader);

        // [THEN] VAT Report Status = Released
        VATReportHeader.Find();
        VATReportHeader.TestField(Status, VATReportHeader.Status::Released);
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorWhenReleaseVATReporIndividualTaxRepresentativeWithoutFirstLastName()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        Vendor: Record Vendor;
        VATReportMediator: Codeunit "VAT Report Mediator";
        PostingDate: Date;
    begin
        // [FEATURE] [Release]
        // [SCENARIO 251924] Error must appear when releasing VAT Report when individual Vendor as Tax Representative in Company Inf. without First and Last Name
        Initialize();
        UpdateCompanyInformation();

        // [GIVEN] Individual Vendor "Vend" without First and Last Name
        CreateIndividualVendor(Vendor);
        Vendor.Validate("First Name", '');
        Vendor.Validate("Last Name", '');
        Vendor.Modify(true);

        // [GIVEN] Vendor "Vend" as Tax Representative in Company Informatino
        UpdateCompanyInformationTaxRepresentative(Vendor."No.");

        // [GIVEN] Date without VAT Entries 15.03.2019
        PostingDate := GetLastVATEntryOpOccrDate() + 1;

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Release VAT Report
        asserterror VATReportMediator.Release(VATReportHeader);

        // [THEN] "Error Messages" pages opens
        // [THEN] The first error: "First Name" in Vendor "Vend" must not be blank.
        // [THEN] The second error: "Last Name" in Vendor "Vend" must not be blank.
        // Values are remembered in ErrorMessagesPageHandler
        Assert.ExpectedMessage(Vendor.FieldName("First Name"), LibraryVariableStorage.DequeueText());
        Assert.ExpectedMessage(Vendor.FieldName("Last Name"), LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseVATReporNonIndividualTaxRepresentative()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        Vendor: Record Vendor;
        VATReportMediator: Codeunit "VAT Report Mediator";
        PostingDate: Date;
    begin
        // [FEATURE] [Release]
        // [SCENARIO 251924] Cassie can release VAT Report when non-individual Vendor as Tax Representative in Company Inf. with filled Name
        Initialize();
        UpdateCompanyInformation();

        // [GIVEN] Non-individual Vendor "Vend" with filled Name
        Vendor.Get(CreateVendor(false, Vendor.Resident::"Non-Resident", true, false));

        // [GIVEN] Vendor "Vend" as Tax Representative in Company Informatino
        UpdateCompanyInformationTaxRepresentative(Vendor."No.");

        // [GIVEN] Date without VAT Entries 15.03.2019
        PostingDate := GetLastVATEntryOpOccrDate() + 1;

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Release VAT Report
        VATReportMediator.Release(VATReportHeader);

        // [THEN] VAT Report Status = Released
        VATReportHeader.Find();
        VATReportHeader.TestField(Status, VATReportHeader.Status::Released);
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorWhenReleaseVATReporNonIndividualTaxRepresentativeWithoutName()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        Vendor: Record Vendor;
        VATReportMediator: Codeunit "VAT Report Mediator";
        PostingDate: Date;
    begin
        // [FEATURE] [Release]
        // [SCENARIO 251924] Cassie can release VAT Report when non-individual Vendor as Tax Representative in Company Inf. without Name
        Initialize();
        UpdateCompanyInformation();

        // [GIVEN] Non-individual Vendor "Vend" without Name
        Vendor.Get(CreateVendor(false, Vendor.Resident::"Non-Resident", true, false));
        Vendor.Validate(Name, '');
        Vendor.Modify(true);

        // [GIVEN] Vendor "Vend" as Tax Representative in Company Informatino
        UpdateCompanyInformationTaxRepresentative(Vendor."No.");

        // [GIVEN] Date without VAT Entries 15.03.2019
        PostingDate := GetLastVATEntryOpOccrDate() + 1;

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Release VAT Report
        asserterror VATReportMediator.Release(VATReportHeader);

        // [THEN] "Error Messages" pages opens
        // [THEN] Error: "Name" in Vendor "Vend" must not be blank.
        // Value is remembered in ErrorMessagesPageHandler
        Assert.ExpectedMessage(Vendor.FieldName(Name), LibraryVariableStorage.DequeueText());
    end;

    local procedure Initialize()
    begin
        TearDown(); // Cleanup.
        LibraryVariableStorage.Clear();
        Clear(LibraryReportValidation);
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;

        isInitialized := true;
        CreateVATReportSetup();
        Commit();
        LibrarySetupStorage.Save(DATABASE::"Company Information");

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

    local procedure CreateIndividualVendor(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendorWithVATRegNo(Vendor);
        Vendor.Validate("Fiscal Code", 'PNDLSN69C50F205N');
        Vendor.Validate("Individual Person", true);
        Vendor.Validate("First Name", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("First Name"), DATABASE::Vendor));
        Vendor.Validate("Last Name", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Last Name"), DATABASE::Vendor));
        Vendor.Validate(County, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(County), DATABASE::Vendor));
        Vendor.Modify(true);
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; GenPostingType: Enum "General Posting Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BalAccountType: Enum "Gen. Journal Account Type";
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

    local procedure CreateAndPostPurchaseCreditMemo(var VendorNo: Code[20]; var Amount: Decimal; var DocumentNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
        Amount := PurchaseLine."Amount Including VAT";
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesCreditMemo(var CustomerNo: Code[20]; var Amount: Decimal; var DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
        Amount := SalesLine."Amount Including VAT";
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateApplyAndPostGenJnlLine(DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
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

    local procedure RunVendorAccountBillsListReport(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        VendorAccountBillsList: Report "Vendor Account Bills List";
    begin
        Vendor.SetRange("No.", VendorNo);
        VendorAccountBillsList.SetTableView(Vendor);
        VendorAccountBillsList.UseRequestPage(true);
        VendorAccountBillsList.Run();
    end;

    local procedure RunCustomerBillsListReport(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        CustomerBillsList: Report "Customer Bills List";
    begin
        Customer.SetRange("No.", CustomerNo);
        CustomerBillsList.SetTableView(Customer);
        CustomerBillsList.UseRequestPage(true);
        CustomerBillsList.Run();
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

    local procedure GetLastVATEntryOpOccrDate(): Date
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey("Operation Occurred Date", Type, "Document Type", "Document No.", "Contract No.");
        VATEntry.FindLast();
        exit(VATEntry."Operation Occurred Date");
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
        VATPostingSetup.SetRange("Include in VAT Transac. Rep.", IncludeInVATTransacRep);
        VATPostingSetup.SetRange("Deductible %", 100);
        exit(VATPostingSetup.FindFirst())
    end;

    local procedure RunUpdateVATTransDataReport(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; CompAgainstThreshold: Boolean; TestOnly: Boolean; SetIncludeInVATTransRep: Boolean)
    var
        VATEntry: Record "VAT Entry";
        UpdateVATTransData: Report "Update VAT Transaction Data";
        SetIncludeInDataTransmission: Option "Set Fields","Clear Fields";
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        UpdateVATTransData.SetTableView(VATEntry);
        UpdateVATTransData.UseRequestPage(false);
        LibraryVariableStorage.Enqueue(ConfirmTextVATTransReport);
        if SetIncludeInVATTransRep then
            UpdateVATTransData.InitializeRequest(CompAgainstThreshold, TestOnly, SetIncludeInDataTransmission::"Set Fields")
        else
            UpdateVATTransData.InitializeRequest(CompAgainstThreshold, TestOnly, SetIncludeInDataTransmission::"Clear Fields");
        UpdateVATTransData.SaveAsExcel(TemporaryPath + Format(CreateGuid()) + Xlsx);
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

    local procedure UpdateCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Fiscal Code", '08106710158');
        CompanyInformation.Validate(County, 'MI');
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateCompanyInformationTaxRepresentative(TaxRepresentativeNo: Code[20])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Tax Representative No.", TaxRepresentativeNo);
        CompanyInformation.Modify(true);
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

    local procedure VerifyVendorAccountBillsListRefundAndCreditMemo(RefundNo: Code[20]; CreditMemoNo: Code[20])
    begin
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(16, 2, RefundTok);
        LibraryReportValidation.VerifyCellValue(16, 5, RefundNo);
        LibraryReportValidation.VerifyCellValue(18, 2, CreditMemoTok);
        LibraryReportValidation.VerifyCellValue(18, 5, CreditMemoNo);
    end;

    local procedure VerifyCustomerBillsListRefundAndCreditMemo(RefundNo: Code[20]; CreditMemoNo: Code[20])
    begin
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(17, 3, RefundTok);
        LibraryReportValidation.VerifyCellValue(17, 5, RefundNo);
        LibraryReportValidation.VerifyCellValue(18, 4, CreditMemoTok);
        LibraryReportValidation.VerifyCellValue(18, 6, CreditMemoNo);
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

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        Message: Variant;
    begin
        LibraryVariableStorage.Dequeue(Message);
        if StrPos(Question, Message) > 0 then
            Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ErrorMessagesPageHandler(var ErrorMessages: TestPage "Error Messages")
    var
        ErrorMessage: Record "Error Message";
    begin
        ErrorMessages.FILTER.SetFilter("Message Type", Format(ErrorMessage."Message Type"::Error));
        ErrorMessages.First();
        repeat
            LibraryVariableStorage.Enqueue(ErrorMessages.Description.Value);
        until ErrorMessages.Next() = false;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestHandlerVendorAccountBillsList(var VendorAccountBillsList: TestRequestPage "Vendor Account Bills List")
    begin
        VendorAccountBillsList.EndingDate.SetValue(LibraryRandom.RandDate(LibraryRandom.RandInt(10)));
        VendorAccountBillsList.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestHandlerCustomerBillsList(var CustomerBillsList: TestRequestPage "Customer Bills List")
    begin
        CustomerBillsList."Ending Date".SetValue(LibraryRandom.RandDate(LibraryRandom.RandInt(10)));
        CustomerBillsList.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;
}

