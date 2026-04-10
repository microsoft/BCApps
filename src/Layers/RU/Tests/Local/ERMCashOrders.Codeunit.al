codeunit 144723 "ERM Cash Orders"
{
    // // [FEATURE] [Cash Order]

    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "Bank Account Ledger Entry" = i;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryERM: Codeunit "Library - ERM";
        DecimalFormatTok: Label '<Sign><Integer><Decimals,3>', Locked = true;
        StdTextTok: Label 'Amount %1, including VAT %2', Locked = true;
        DefaultPaymentPurposeTok: Label 'Amount %1, including VAT %2, Base %3, Appl Doc No %4, Appl Doc Date %5, Bank %6, Pers Acc No %7', Locked = true;
        CashReportCO4ReportType: Option "Cash Report CO-4","Cash Additional Sheet";
        VoidType: Option "Unapply and void check","Void check only";
        IsInitialized: Boolean;
        PageNumberTxt: Label 'Page %1', Comment = '%1 - Page Number';
        CashReportCO4Txt: Label 'Loose-leaf cashbook';
        CashAdditionalSheetTxt: Label 'Cashier report';
        VoidedEntriesPrintedErr: Label 'Voided lines must not be printed.';

    [Test]
    [Scope('OnPrem')]
    procedure CashOutgoingOrder()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CompanyInformation: Record "Company Information";
        Employee: Record Employee;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 377209] Export "Cash Outgoing Order" report
        Initialize();

        // [GIVEN] Bank payment "Gen. Journal Line" where "Posting Date" = 21 December 2015
        CreateBankOrder(GenJournalLine, LibraryRandom.RandInt(100));
        UpdateGenJournalLinePostingDate(GenJournalLine, DMY2Date(21, 12, 2015));

        // [GIVEN] Company Information's Director retrieved as Employee
        CompanyInformation.Get();
        Employee.Get(CompanyInformation."Director No.");

        // [WHEN] Export "Cash Outgoing Journal"
        RunCashOutgoingOrderReport(GenJournalLine);

        // [THEN] Date exported in formatted "21.12.2015" (DD.MM.YYYY)
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueByRef('CT', 11, 1, '21.12.2015');

        // TFSID 381057 Export "Cash Outgoing Order" with Director's Job Title filled
        // [THEN] Cash Outgoing Order is exported with Director's Job Title
        LibraryReportValidation.VerifyCellValueByRef('Z', 25, 1, Employee."Job Title");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashIngoingOrder()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Report]
        // [SCENARIO 377327] Export "Cash Ingoing Order" report
        Initialize();

        // [GIVEN] Bank payment "Gen. Journal Line" where "Posting Date" = 21 December 2015
        CreateBankOrder(GenJournalLine, LibraryRandom.RandInt(100));
        UpdateGenJournalLinePostingDate(GenJournalLine, DMY2Date(21, 12, 2015));

        // [WHEN] Export "Cash Ingoing Journal"
        RunCashIngoingOrderReport(GenJournalLine);

        // [THEN] Date exported in formatted "21.12.2015" (DD.MM.YYYY)
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueByRef('BB', 13, 1, '21.12.2015');
    end;

    [Test]
    [HandlerFunctions('OutgoingCashOrderMPH,StandardTextCodesMPH')]
    [Scope('OnPrem')]
    procedure CashOutgoingOrderPreviewPageStandardTextFormat()
    var
        StandardText: Record "Standard Text";
        GenJournalLine: Record "Gen. Journal Line";
        CheckManagement: Codeunit CheckManagement;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 377210] Substitute '%' with amounts in "Reason Code", "Cash Order Including" and "Cash Order Supplement" fields in Cash Outgoing Order
        Initialize();

        // [GIVEN] Standard Text "ST" with "Description" = 'Amount %1, including VAT %2'
        CreateStandardTextCode(StandardText);

        // [GIVEN] Bank payment "Gen. Journal Line" where "Amount" = -100 (to show Ingoing Cash Order)
        CreateBankOrder(GenJournalLine, LibraryRandom.RandInt(100));

        // [WHEN] Select "ST" in lookup dialog for fields "Reason Code", "Cash Order Including", "Cash Order Supplement" in Cash Ingoing Order
        LibraryVariableStorage.Enqueue(StandardText.Code);
        LibraryVariableStorage.Enqueue(GetGenJournalLineFormattedText(GenJournalLine, StandardText.Description, '', ''));
        CheckManagement.ShowPaymentDocument(GenJournalLine);

        // [THEN] "Reason Code" := 'Amount -100,00, including VAT 0,00
        // [THEN] "Cash Order Including" := 'Amount -100,00, including VAT 0,00
        // [THEN] "Cash Order Supplement" := 'Amount -100,00, including VAT 0,00
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('IngoingCashOrderMPH,StandardTextCodesMPH')]
    [Scope('OnPrem')]
    procedure CashIngoingOrderPreviewPageStandardTextFormat()
    var
        StandardText: Record "Standard Text";
        GenJournalLine: Record "Gen. Journal Line";
        CheckManagement: Codeunit CheckManagement;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 377210] Substitute '%' with amounts in "Reason Code", "Cash Order Including" and "Cash Order Supplement" fields
        Initialize();

        // [GIVEN] Standard Text "ST" with "Description" = 'Amount %1, including VAT %2'
        CreateStandardTextCode(StandardText);

        // [GIVEN] Bank payment "Gen. Journal Line" where "Amount" = -100 (to show Ingoing Cash Order)
        CreateBankOrder(GenJournalLine, -LibraryRandom.RandInt(100));

        // [WHEN] Select "ST" in lookup dialog for fields "Reason Code", "Cash Order Including", "Cash Order Supplement"
        LibraryVariableStorage.Enqueue(StandardText.Code);
        LibraryVariableStorage.Enqueue(GetGenJournalLineFormattedText(GenJournalLine, StandardText.Description, '', ''));
        CheckManagement.ShowPaymentDocument(GenJournalLine);

        // [THEN] "Reason Code" := 'Amount -100,00, including VAT 0,00
        // [THEN] "Cash Order Including" := 'Amount -100,00, including VAT 0,00
        // [THEN] "Cash Order Supplement" := 'Amount -100,00, including VAT 0,00
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocMgtFormatDate_UT()
    var
        LocalisationManagement: Codeunit "Localisation Management";
    begin
        // [SCENARIO 377209,377327] Convert Date to Text in "DD.MM.YYYY" format
        Assert.AreEqual('21.12.2015', LocalisationManagement.FormatDate(DMY2Date(21, 12, 2015)), '');
        Assert.AreEqual('01.02.2015', LocalisationManagement.FormatDate(DMY2Date(1, 2, 2015)), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePaymentVATInfo_FormattedValue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        StandardText: Record "Standard Text";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [SCENARIO 377210] Update "Payment Purpose", "Cash Order Including" and "Cash Order Supplement" fields' value considering "Standard Text".Description format
        Initialize();
        CreateBankOrder(GenJournalLine, LibraryRandom.RandInt(100));
        CreateStandardTextCode(StandardText);

        VendorBankAccount.Init();
        RunUpdatePaymentVATInfoScenario(GenJournalLine, StandardText, VendorBankAccount, false, StandardText.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePaymentVATInfo_UseDefaultPaymentPurpose()
    var
        GenJournalLine: Record "Gen. Journal Line";
        StandardText: Record "Standard Text";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [SCENARIO 377210] Call UpdatePaymentVATInfo using Default "Payment Purpose"
        Initialize();
        InitUpdatePaymentVATInfoUseDefaultPaymentPurpose(GenJournalLine, StandardText, VendorBankAccount);

        RunUpdatePaymentVATInfoScenario(
          GenJournalLine, StandardText, VendorBankAccount, true, VendorBankAccount."Def. Payment Purpose");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePaymentVATInfo_UseDefaultBlankVendBankBranchNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        StandardText: Record "Standard Text";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [SCENARIO 377210] Call UpdatePaymentVATInfo using Default "Payment Purpose" when "Vendor Bank Account"."Bank Branch No." is blank
        Initialize();
        InitUpdatePaymentVATInfoUseDefaultPaymentPurpose(GenJournalLine, StandardText, VendorBankAccount);

        VendorBankAccount.Get(GenJournalLine."Account No.", GenJournalLine."Beneficiary Bank Code");
        VendorBankAccount."Bank Branch No." := '';
        VendorBankAccount."Personal Account No." := '';
        VendorBankAccount.Modify();

        RunUpdatePaymentVATInfoScenario(GenJournalLine, StandardText, VendorBankAccount, true, DefaultPaymentPurposeTok);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePaymentVATInfo_UseDefaultVendorAccountNoVendorBank()
    var
        GenJournalLine: Record "Gen. Journal Line";
        StandardText: Record "Standard Text";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [SCENARIO 377210] Call UpdatePaymentVATInfo using Default "Payment Purpose" when "Gen. Journal Line"."Beneficiary Bank Code" is blank
        Initialize();
        InitUpdatePaymentVATInfoUseDefaultPaymentPurpose(GenJournalLine, StandardText, VendorBankAccount);

        GenJournalLine."Beneficiary Bank Code" := '';
        GenJournalLine.Modify();

        RunUpdatePaymentVATInfoScenario(GenJournalLine, StandardText, VendorBankAccount, true, StandardText.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePaymentVATInfo_UseDefaultCustomerAccountType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        StandardText: Record "Standard Text";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [SCENARIO 377210] Call UpdatePaymentVATInfo using Default "Payment Purpose" when "Gen. Journal Line"."Account Type" is not Vendor
        Initialize();
        InitUpdatePaymentVATInfoUseDefaultPaymentPurpose(GenJournalLine, StandardText, VendorBankAccount);

        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Account No." := LibrarySales.CreateCustomerNo();
        GenJournalLine.Modify();

        RunUpdatePaymentVATInfoScenario(GenJournalLine, StandardText, VendorBankAccount, true, StandardText.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePaymentVATInfo_UseDefaultBalBankCashAccountType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        StandardText: Record "Standard Text";
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
    begin
        // [SCENARIO 377210] Call UpdatePaymentVATInfo using Default "Payment Purpose" when balance Bank Account has "Cash Account" type
        Initialize();
        InitUpdatePaymentVATInfoUseDefaultPaymentPurpose(GenJournalLine, StandardText, VendorBankAccount);

        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount."Account Type" := BankAccount."Account Type"::"Cash Account";
        BankAccount.Modify();

        RunUpdatePaymentVATInfoScenario(GenJournalLine, StandardText, VendorBankAccount, true, StandardText.Description);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure CashReportCO4TypeCashReportCO4()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Report]
        // [SCENARIO 377232] Print "Cash Report CO - 4" with type "Cash Report CO-4"
        Initialize();
        SetAccountantNameInCompanyInformation(LibraryUtility.GenerateGUID());

        // [GIVEN] "Company Information"."Accountant Name" = "A"
        // [GIVEN] Cash Order Journal
        // [GIVEN] Printed Cash Outgoing Order with Number "XX001" and Posted Cash Order Journal
        // [WHEN] Print / Export "Cash Report CO-4" with type "Cash Report CO-4"
        DocumentNo :=
          RunPrintCO4ReportScenario(
            GenJournalLine, BankAccountNo, LibraryRandom.RandInt(10), CashReportCO4ReportType::"Cash Report CO-4");

        // [THEN] "P17" = Zero (written 0) (number of printed Cash Ingoing Orders)
        // [THEN] "E19" = One2 (written 1) (number of printed Cash Outgoing Orders)
        // [THEN] "N4" = "Cash Report CO - 4" (report type)
        // [THEN] "A9" = 001 (Only digits from number of printed Cash Order "XX001")
        // [THEN] "AI22" = "A" (Accountant Name from Company Information)
        VerifyCashReportCO4(DocumentNo, CashReportCO4Txt);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure CashReportCO4TypeCashAdditionalSheet()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Report]
        // [SCENARIO 377232] Print "Cash Report CO - 4" with type "Cash Additional Sheet"
        Initialize();
        SetAccountantNameInCompanyInformation(LibraryUtility.GenerateGUID());

        // [GIVEN] "Company Information"."Accountant Name" = "A"
        // [GIVEN] Cash Order Journal
        // [GIVEN] Printed Cash Outgoing Order with Number "XX001" and Posted Cash Order Journal
        // [WHEN] Print / Export "Cash Report CO-4" with type "Cash Additional Sheet"
        DocumentNo :=
          RunPrintCO4ReportScenario(
            GenJournalLine, BankAccountNo, LibraryRandom.RandInt(10), CashReportCO4ReportType::"Cash Additional Sheet");

        // [THEN] "P17" = Zero (written 0) (number of printed Cash Ingoing Orders)
        // [THEN] "E19" = One2 (written 1) (number of printed Cash Outgoing Orders)
        // [THEN] "N4" = "Cash Additional Sheet" (report type)
        // [THEN] "A9" = 001 (Only digits from number of printed Cash Order "XX001")
        // [THEN] "AI22" = "A" (Accountant Name from Company Information)
        VerifyCashReportCO4(DocumentNo, CashAdditionalSheetTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure CashReportCO4With70Lines()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        BankAccountNo: Code[20];
        NoSeriesCode: Code[20];
        Index: Integer;
        PageNumber: Integer;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 377232,377258] "Cash Report CO - 4" with 70 lines split on 3 pages when printing
        Initialize();
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();

        // [GIVEN] Cash Order Journal
        // [GIVEN] "Last Cash Report Page No." = '005'
        CreateCashOrderForVendor(GenJournalLine, NoSeriesCode, BankAccountNo);
        PageNumber := LibraryRandom.RandIntInRange(5, 10);
        UpdateLastCashReportPageNo(GenJournalLine, PageNumber);

        // [GIVEN] 70 Printed Cash Outgoing Orders
        PrintCashOrderFromJournalLine(GenJournalLine);
        for Index := 1 to 70 do
            CopyAndPrintCashOrderJournalLine(GenJournalLine, NoSeriesCode, LibraryRandom.RandInt(100));

        // [GIVEN] Posted Cash Order Journal
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJournalLine);

        // [WHEN] Print / Export "Cash Report CO-4"
        RunCashReportCO4(BankAccountNo, CashReportCO4ReportType::"Cash Report CO-4", false, false, GenJournalLine."Posting Date");

        // [THEN] 3 Pages generated
        // [THEN] 'BT2' = "Page 6"
        // [THEN] 'BT47' = "Page 7"
        // [THEN] 'BT87' = "Page 8"
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueByRef('BT', 2, 1, GetPageNoAsText(PageNumber + 1));
        LibraryReportValidation.VerifyCellValueByRef('BT', 47, 1, GetPageNoAsText(PageNumber + 2));
        LibraryReportValidation.VerifyCellValueByRef('BT', 88, 1, GetPageNoAsText(PageNumber + 3));

        // [THEN] "Last Cash Report Page No." = '008'
        BankAccount.Get(BankAccountNo);
        BankAccount.TestField("Last Cash Report Page No.", GetPageNoAsCode(PageNumber + 3));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsPageBreakRequired_UT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ExcelReportBuilderManager: Codeunit "Excel Report Builder Manager";
        Index: Integer;
    begin
        // [SCENARIO 377232] Unit tests for "Excel Report Builder Manager".IsPageBreakRequired functions
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Cash Order KO4 Template Code");
        ExcelReportBuilderManager.InitTemplate(GeneralLedgerSetup."Cash Order KO4 Template Code");
        ExcelReportBuilderManager.SetSheet('Sheet1');

        for Index := 1 to 46 do
            ExcelReportBuilderManager.AddSection('BODY');

        Assert.IsFalse(ExcelReportBuilderManager.IsPageBreakRequired('BODY', ''), '<BODY,>');
        Assert.IsFalse(ExcelReportBuilderManager.IsPageBreakRequired('BODY', 'BODY'), '<BODY,BODY>');
        Assert.IsTrue(ExcelReportBuilderManager.IsPageBreakRequired('FOOTER', ''), '<FOOTER,>');
        Assert.IsTrue(ExcelReportBuilderManager.IsPageBreakRequired('BODY', 'FOOTER'), '<BODY,FOOTER>');

        ExcelReportBuilderManager.AddSection('BODY');
        Assert.IsFalse(ExcelReportBuilderManager.IsPageBreakRequired('BODY', ''), '<BODY,>');
        Assert.IsTrue(ExcelReportBuilderManager.IsPageBreakRequired('BODY', 'BODY'), '<BODY,BODY>');

        ExcelReportBuilderManager.AddSection('BODY');
        Assert.IsTrue(ExcelReportBuilderManager.IsPageBreakRequired('BODY', ''), '<BODY,>');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashReportCO4WithoutLines()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        PageNumber: Integer;
        BankAccountNo: Code[20];
    begin
        // [FEATURE] [Report]
        // [SCENARIO 377257] "Cash Report CO - 4" without lines must not update "Last Cash Report Page No." of Cash Account
        Initialize();
        PageNumber := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] Empty Cash Order Journal
        // [GIVEN] "Last Cash Report Page No." = '005'
        CreateCashOrderForVendor(GenJournalLine, LibraryERM.CreateNoSeriesCode(), BankAccountNo);
        UpdateLastCashReportPageNo(GenJournalLine, PageNumber);

        // [WHEN] Print / Export "Cash Report CO-4"
        RunCashReportCO4(
          BankAccountNo, CashReportCO4ReportType::"Cash Report CO-4",
          false, false, GenJournalLine."Posting Date");

        // [THEN] "Last Cash Report Page No." = '005'
        BankAccount.Get(BankAccountNo);
        BankAccount.TestField("Last Cash Report Page No.", GetPageNoAsCode(PageNumber));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure CashReportCO4TwoJournalsOneCashAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLineNew: Record "Gen. Journal Line";
        BankAccountNo: Code[20];
        NoSeriesCode: Code[20];
        PageNumber: Integer;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 377267] Page numbering in "Cash Report CO - 4" must consider "Last Cash Report Page No." of Cash Account
        Initialize();
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        PageNumber := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] "Bank Account" "BA1" with type "Cash Account"
        // [GIVEN] "BA1"."Last Cash Report Page No." = '005'
        // [GIVEN] Cash Order Journal "COJ1" where "Bal. Account No." = "BA1"
        CreateCashOrderForVendor(GenJournalLine, NoSeriesCode, BankAccountNo);
        UpdateLastCashReportPageNo(GenJournalLine, PageNumber);

        // [GIVEN] Printed "Cash Outgoing Order" where "Posting Date" = "01.12.2015"
        PrintCashOrderFromJournalLine(GenJournalLine);

        // [GIVEN] Posted Cash Order Journal "COJ1"
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJournalLine);

        // [GIVEN] Print / Export "Cash Report CO-4"
        RunCashReportCO4(BankAccountNo, CashReportCO4ReportType::"Cash Report CO-4", false, true, GenJournalLine."Posting Date");

        // [GIVEN] "BA1"."Last Cash Report Page No." = '006' (updated)
        VerifyPageNumbers(BankAccountNo, PageNumber + 1);

        // [GIVEN] Cash Order Journal "COJ2" where "Bal. Account No." = "BA1" (the same bank account)
        CreateCashOrderForVendor(GenJournalLineNew, NoSeriesCode, GenJournalLineNew."Bal. Account No.");
        GenJournalLineNew."Bal. Account No." := BankAccountNo;
        GenJournalLineNew."Posting Date" := GenJournalLine."Posting Date" + 1;
        GenJournalLineNew.Modify();

        // [GIVEN] Printed "Cash Outgoing Order" where "Posting Date" = "02.12.2015" (next day)
        PrintCashOrderFromJournalLine(GenJournalLineNew);

        // [GIVEN] Posted Cash Order Journal "COJ2"
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJournalLineNew);

        // [WHEN] Print / Export "Cash Report CO-4"
        RunCashReportCO4(BankAccountNo, CashReportCO4ReportType::"Cash Report CO-4", false, true, GenJournalLineNew."Posting Date");

        // [THEN] "BA1"."Last Cash Report Page No." = '007' (updated)
        VerifyPageNumbers(BankAccountNo, PageNumber + 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure CashReportCO4PageNumberingTwoBanks()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: array[2] of Code[20];
        PageNumber: array[2] of Integer;
        FileName: Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 377267] Page numbering in "Cash Report CO - 4" must consider "Last Cash Report Page No." of a certain Cash Account
        Initialize();

        // [GIVEN] "Bank Account" "BA1" where "Last Cash Report Page No." = '000'
        // [GIVEN] Posted "Cash Order Journal" "COJ1" with 15 lines for "BA1"
        // [GIVEN] Printed "Cash Report CO-4" for "BA1"
        PageNumber[1] := LibraryRandom.RandIntInRange(15, 20);
        RunPrintCO4ReportScenario(GenJournalLine, BankAccountNo[1], PageNumber[1], CashReportCO4ReportType::"Cash Report CO-4");
        // [GIVEN] "BA1"."Last Cash Report Page No." = '015'
        VerifyPageNumbers(BankAccountNo[1], PageNumber[1] + 1);

        // [GIVEN] "Bank Account" "BA2" where "Last Cash Report Page No." = '000'
        FileName := LibraryReportValidation.GetFileName();
        Clear(LibraryReportValidation);
        Clear(GenJournalLine);
        PageNumber[2] := LibraryRandom.RandIntInRange(5, 10);
        // [GIVEN] Posted "Cash Order Journal" "COJ2" with 5 lines for "BA2"
        // [WHEN] Printed "Cash Report CO-4" for "BA2"
        RunPrintCO4ReportScenario(GenJournalLine, BankAccountNo[2], PageNumber[2], CashReportCO4ReportType::"Cash Report CO-4");

        // [THEN] "BA2"."Last Cash Report Page No." = '005'
        VerifyPageNumbers(BankAccountNo[2], PageNumber[2] + 1);

        // [THEN] "BA1"."Last Cash Report Page No." = '015'
        Clear(LibraryReportValidation);
        LibraryReportValidation.SetFullFileName(FileName);
        VerifyPageNumbers(BankAccountNo[1], PageNumber[1] + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashReportCO4DoesntPrintReversedBankLedgerEntries()
    var
        BankAccount: Record "Bank Account";
        Description: Text[50];
    begin
        // [FEATURE] [Report] [Cash Report CO-4] [UT]
        // [SCENARIO 377473] Cash Report CO-4 doesn't print reversed Bank Account Ledger Entries
        Initialize();
        Description := LibraryUtility.GenerateGUID();

        // [GIVEN] Bank Account with two Ledger Entries: Reversed and Not Reversed.
        CreateBankAccount(BankAccount, BankAccount."Account Type"::"Cash Account");
        MockBankLedgerEntry(BankAccount."No.", Description, false);
        MockBankLedgerEntry(BankAccount."No.", Description, true);

        // [WHEN] Run Cash Report CO-4
        RunCashReportCO4(BankAccount."No.", CashReportCO4ReportType::"Cash Report CO-4", false, false, WorkDate());

        // [THEN] Report prints only one line
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.SetRange(Description, Description);
        Assert.AreEqual(1, LibraryReportValidation.CountRows(), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure CashReportCO4DoesntPrintVoidedBankLedgerEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CheckLedgerEntry: Record "Check Ledger Entry";
        LocalisationMgt: Codeunit "Localisation Management";
        BankAccountNo: Code[20];
        ExportedDocumentNo: Code[20];
    begin
        // [FEATURE] [Report] [Cash Report CO-4]
        // [SCENARIO 378705] Cash Report CO-4 doesn't print voided Bank Account Ledger Entries
        Initialize();

        // [GIVEN] Bank Account with voided Ledger Entry
        CreateCashOrderForVendor(GenJournalLine, LibraryERM.CreateNoSeriesCode(), BankAccountNo);
        PrintCashOrderFromJournalLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FindCheckLedgEntry(
          CheckLedgerEntry, BankAccountNo, CheckLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        VoidCheckLedgEntry(CheckLedgerEntry, VoidType::"Void check only");
        ExportedDocumentNo := LocalisationMgt.DigitalPartCode(GenJournalLine."Document No.");

        // [WHEN] Run Cash Report CO-4
        RunCashReportCO4(BankAccountNo, CashReportCO4ReportType::"Cash Report CO-4", false, false, WorkDate());

        // [THEN] Report does not print voided and voiding lines
        LibraryReportValidation.OpenExcelFile();
        Assert.IsFalse(LibraryReportValidation.CheckIfValueExistsInSpecifiedColumn('A', ExportedDocumentNo), VoidedEntriesPrintedErr);
    end;

    [Test]
    [HandlerFunctions('CashReportCO4Handler')]
    [Scope('OnPrem')]
    procedure CashReportCO4AdditionalSheetWith70Lines()
    var
        BankAccount: Record "Bank Account";
        PageNumber: Integer;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 378506] Additional Sheet "Cash Report CO - 4" with 70 lines skips "Last Cash Report Page No." updating
        Initialize();

        // [GIVEN] Posted Cash Order Journal with 70 Printed Cash Outgoing Orders
        // [GIVEN] "Last Cash Report Page No." = "A"
        CreateCheckLedgerEntries(BankAccount, PageNumber, 70);

        // [WHEN] Print "Cash Report CO-4" with Report Type = "Cash Additional Sheet"
        LibraryVariableStorage.Enqueue(false);
        RunCashReportCO4WithRequestPage(BankAccount."No.", CashReportCO4ReportType::"Cash Additional Sheet", false, false, WorkDate());

        // [THEN] "Last Cash Report Page No." = "A"
        BankAccount.Find();
        BankAccount.TestField("Last Cash Report Page No.", GetPageNoAsCode(PageNumber));
    end;

    [Test]
    [HandlerFunctions('CashReportCO4Handler')]
    [Scope('OnPrem')]
    procedure CashReportCO4With70LinesPreview()
    var
        BankAccount: Record "Bank Account";
        PageNumber: Integer;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 378506] Preview "Cash Report CO - 4" with 70 lines skips "Last Cash Report Page No." updating
        Initialize();

        // [GIVEN] Posted Cash Order Journal with 70 Printed Cash Outgoing Orders
        // [GIVEN] "Last Cash Report Page No." = "A"
        CreateCheckLedgerEntries(BankAccount, PageNumber, 70);

        // [WHEN] Print "Cash Report CO-4" with Report Type = "Cash Report CO-4"
        LibraryVariableStorage.Enqueue(true);
        RunCashReportCO4WithRequestPage(BankAccount."No.", CashReportCO4ReportType::"Cash Report CO-4", false, false, WorkDate());

        // [THEN] "Last Cash Report Page No." = "A"
        BankAccount.Find();
        BankAccount.TestField("Last Cash Report Page No.", GetPageNoAsCode(PageNumber));
    end;

    [Test]
    [HandlerFunctions('CashReportCO4Handler')]
    [Scope('OnPrem')]
    procedure CashReportCO4AdditionalSheetWith70LinesPreview()
    var
        BankAccount: Record "Bank Account";
        PageNumber: Integer;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 378506] Preview Additional Sheet "Cash Report CO - 4" with 70 lines skips "Last Cash Report Page No." updating
        Initialize();

        // [GIVEN] Posted Cash Order Journal with 70 Printed Cash Outgoing Orders
        // [GIVEN] "Last Cash Report Page No." = "A"
        CreateCheckLedgerEntries(BankAccount, PageNumber, 70);

        // [WHEN] Print "Cash Report CO-4" with Report Type = "Cash Additional Sheet"
        LibraryVariableStorage.Enqueue(true);
        RunCashReportCO4WithRequestPage(BankAccount."No.", CashReportCO4ReportType::"Cash Additional Sheet", false, false, WorkDate());

        // [THEN] "Last Cash Report Page No." = "A"
        BankAccount.Find();
        BankAccount.TestField("Last Cash Report Page No.", GetPageNoAsCode(PageNumber));
    end;

    [Test]
    [HandlerFunctions('CashReportCO4Handler')]
    [Scope('OnPrem')]
    procedure CashReportCO4With70LinesReprint()
    var
        BankAccount: Record "Bank Account";
        PageNumber: Integer;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 379052] "Cash Report CO - 4" with 70 lines including reprinted update "Last Cash Report Page No."
        Initialize();

        // [GIVEN] Posted Cash Order Journal with 70 Printed Cash Outgoing Orders for 3 pages report
        CreateCheckLedgerEntries(BankAccount, PageNumber, 70);

        // [GIVEN] CheckLedgerEntry."Cashier Report No." = "A", BankAccount."Last Cash Report Page No." = "A" + 1
        SetCashReportPageNo(BankAccount, PageNumber);
        Commit();

        // [WHEN] Print "Cash Report CO-4" with Report Type = "Cash Report CO-4"
        LibraryVariableStorage.Enqueue(false);
        RunCashReportCO4WithRequestPage(BankAccount."No.", CashReportCO4ReportType::"Cash Report CO-4", false, false, WorkDate());

        // [THEN] "Last Cash Report Page No." = "A" + 2
        BankAccount.Find();
        BankAccount.TestField("Last Cash Report Page No.", GetPageNoAsCode(PageNumber + 2));
    end;

    [Test]
    [HandlerFunctions('CashReportCO4Handler')]
    [Scope('OnPrem')]
    procedure CashReportCO4With70LinesReprintPreview()
    var
        BankAccount: Record "Bank Account";
        PageNumber: Integer;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 379052] Preview "Cash Report CO - 4" with 70 lines including reprinted does not update "Last Cash Report Page No."
        Initialize();

        // [GIVEN] Posted Cash Order Journal with 70 Printed Cash Outgoing Orders for 3 pages report
        CreateCheckLedgerEntries(BankAccount, PageNumber, 70);

        // [GIVEN] CheckLedgerEntry."Cashier Report No." = "A", BankAccount."Last Cash Report Page No." = "A" + 1
        SetCashReportPageNo(BankAccount, PageNumber);
        Commit();

        // [WHEN] Preview "Cash Report CO-4" with Report Type = "Cash Report CO-4"
        LibraryVariableStorage.Enqueue(true);
        RunCashReportCO4WithRequestPage(BankAccount."No.", CashReportCO4ReportType::"Cash Report CO-4", false, false, WorkDate());

        // [THEN] "Last Cash Report Page No." = "A" + 1
        BankAccount.Find();
        BankAccount.TestField("Last Cash Report Page No.", GetPageNoAsCode(PageNumber + 1));
    end;

    [Test]
    [HandlerFunctions('CashReportCO4Handler')]
    [Scope('OnPrem')]
    procedure CashReportCO4AdditionalSheetWith70LinesReprint()
    var
        BankAccount: Record "Bank Account";
        PageNumber: Integer;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 379052] Additional Sheet "CO4" with 70 lines including reprinted does not update "Last Cash Report Page No."
        Initialize();

        // [GIVEN] Posted Cash Order Journal with 70 Printed Cash Outgoing Orders for 3 pages report
        CreateCheckLedgerEntries(BankAccount, PageNumber, 70);

        // [GIVEN] CheckLedgerEntry."Cashier Report No." = "A", BankAccount."Last Cash Report Page No." = "A" + 1
        SetCashReportPageNo(BankAccount, PageNumber);
        Commit();

        // [WHEN] Print "Cash Report CO-4" with Report Type = "Cash Additional Sheet"
        LibraryVariableStorage.Enqueue(false);
        RunCashReportCO4WithRequestPage(BankAccount."No.", CashReportCO4ReportType::"Cash Additional Sheet", false, false, WorkDate());

        // [THEN] "Last Cash Report Page No." = "A" + 1
        BankAccount.Find();
        BankAccount.TestField("Last Cash Report Page No.", GetPageNoAsCode(PageNumber + 1));
    end;

    [Test]
    [HandlerFunctions('CashReportCO4Handler')]
    [Scope('OnPrem')]
    procedure CashReportCO4AdditionalSheetWith70LinesReprintPreview()
    var
        BankAccount: Record "Bank Account";
        PageNumber: Integer;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 379052] Preview Additional Sheet "CO4" with 70 lines including reprinted does not update "Last Cash Report Page No."
        Initialize();

        // [GIVEN] Posted Cash Order Journal with 70 Printed Cash Outgoing Orders for 3 pages report
        CreateCheckLedgerEntries(BankAccount, PageNumber, 70);

        // [GIVEN] CheckLedgerEntry."Cashier Report No." = "A", BankAccount."Last Cash Report Page No." = "A" + 1
        SetCashReportPageNo(BankAccount, PageNumber);
        Commit();

        // [WHEN] Preview "Cash Report CO-4" with Report Type = "Cash Additional Sheet"
        LibraryVariableStorage.Enqueue(true);
        RunCashReportCO4WithRequestPage(BankAccount."No.", CashReportCO4ReportType::"Cash Additional Sheet", false, false, WorkDate());

        // [THEN] "Last Cash Report Page No." = "A" + 1
        BankAccount.Find();
        BankAccount.TestField("Last Cash Report Page No.", GetPageNoAsCode(PageNumber + 1));
    end;

    local procedure Initialize()
    begin
        Clear(LibraryReportValidation);
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if not IsInitialized then
            exit;
        IsInitialized := true;

        LibrarySetupStorage.Save(DATABASE::"Company Information");
    end;

    local procedure CreateBankOrder(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
    begin
        CreateGenJournalBatch(GenJournalBatch);
        CreateBankAccount(BankAccount, BankAccount."Account Type"::"Cash Account");
        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch,
          GenJournalLine."Account Type"::"Bank Account", BankAccount."No.", BankAccount."Bank Payment Order No. Series", Amount);

        GenJournalLine.SetRecFilter();
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account"; AccountType: Option): Code[20]
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Bank Payment Order No. Series", LibraryERM.CreateNoSeriesCode());
        BankAccount.Validate("Credit Cash Order No. Series", LibraryERM.CreateNoSeriesCode());
        BankAccount.Validate("Debit Cash Order No. Series", LibraryERM.CreateNoSeriesCode());
        BankAccount.Validate("Account Type", AccountType);
        BankAccount.Modify(true);

        exit(BankAccount."No.");
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::"Bank Payments");
        GenJournalTemplate.Modify(true);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; NoSeriesCode: Code[20]; LineAmount: Decimal)
    var
        BalanceBankAccount: Record "Bank Account";
        NoSeries: Codeunit "No. Series";
    begin
        CreateBankAccount(BalanceBankAccount, BalanceBankAccount."Account Type"::"Cash Account");
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, AccountType, AccountNo, LineAmount);
        GenJournalLine.Validate("Document No.", NoSeries.GetNextNo(NoSeriesCode));
        GenJournalLine.Validate("Bal. Account No.", BalanceBankAccount."No.");
        GenJournalLine.Validate("Bank Payment Type", "Bank Payment Type"::"Computer Check");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateStandardTextCode(var StandardText: Record "Standard Text")
    begin
        StandardText.Init();
        StandardText.Code := LibraryUtility.GenerateGUID();
        StandardText.Description := StdTextTok;
        StandardText.Insert(true);
    end;

    local procedure CreateVendorWithBankAccount(var Vendor: Record Vendor; var VendorBankAccount: Record "Vendor Bank Account")
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount."Bank Branch No." := LibraryUtility.GenerateGUID();
        VendorBankAccount."Personal Account No." := LibraryUtility.GenerateGUID();
        VendorBankAccount."Def. Payment Purpose" := DefaultPaymentPurposeTok;
        VendorBankAccount."Bank Account No." := LibraryERM.CreateBankAccountNo();
        VendorBankAccount.Modify();
    end;

    local procedure CreateCashOrderForVendor(var GenJournalLine: Record "Gen. Journal Line"; NoSeriesCode: Code[20]; var BankAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        CreateVendorWithBankAccount(Vendor, VendorBankAccount);
        CreateGenJournalBatch(GenJournalBatch);
        CreateGenJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, Vendor."No.",
          NoSeriesCode, LibraryRandom.RandInt(100));
        BankAccountNo := GenJournalLine."Bal. Account No.";
    end;

    local procedure CreateCheckLedgerEntries(var BankAccount: Record "Bank Account"; var PageNumber: Integer; EntriesCount: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        Index: Integer;
    begin
        CreateVendorWithBankAccount(Vendor, VendorBankAccount);
        CreateGenJournalBatch(GenJournalBatch);
        CreateGenJournalLineWithBlankDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Vendor, Vendor."No.",
          LibraryRandom.RandInt(100));

        BankAccount.Get(GenJournalLine."Bal. Account No.");

        PrintCashOrderFromJournalLine(GenJournalLine);
        for Index := 1 to EntriesCount do
            CopyAndPrintCashOrderWithBlankDocumentNo(GenJournalLine, LibraryRandom.RandInt(100));

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        PageNumber := LibraryRandom.RandIntInRange(5, 10);
        BankAccount."Last Cash Report Page No." := GetPageNoAsCode(PageNumber);
        BankAccount.Modify();
        Commit();
    end;

    local procedure CreateGenJournalLineWithBlankDocumentNo(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; LineAmount: Decimal)
    var
        BalanceBankAccount: Record "Bank Account";
    begin
        CreateBankAccount(BalanceBankAccount, BalanceBankAccount."Account Type"::"Cash Account");
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, AccountType, AccountNo, LineAmount);
        GenJournalLine.Validate("Bal. Account No.", BalanceBankAccount."No.");
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Computer Check");
        GenJournalLine.Validate("Document No.", '');
        GenJournalLine.Modify(true);
    end;

    local procedure MockBankLedgerEntry(BankAccountNo: Code[20]; NewDescription: Text[50]; NewReversed: Boolean)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.Init();
        BankAccountLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(BankAccountLedgerEntry, BankAccountLedgerEntry.FieldNo("Entry No."));
        BankAccountLedgerEntry."Bank Account No." := BankAccountNo;
        BankAccountLedgerEntry."Posting Date" := WorkDate();
        BankAccountLedgerEntry.Description := NewDescription;
        BankAccountLedgerEntry.Reversed := NewReversed;
        BankAccountLedgerEntry.Insert();
    end;

    local procedure CopyAndPrintCashOrderJournalLine(GenJournalLineSource: Record "Gen. Journal Line"; NoSeriesCode: Code[20]; LineAmount: Decimal)
    var
        GenJournalLineCopy: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
    begin
        GenJournalLineCopy.Copy(GenJournalLineSource);
        GenJournalLineCopy."Line No." := LibraryUtility.GetNewRecNo(GenJournalLineCopy, GenJournalLineCopy.FieldNo("Line No."));
        GenJournalLineCopy.Amount := LineAmount;
        GenJournalLineCopy."Document No." := NoSeries.GetNextNo(NoSeriesCode);
        GenJournalLineCopy.Insert();
        PrintCashOrderFromJournalLine(GenJournalLineCopy);
    end;

    local procedure CopyAndPrintCashOrderWithBlankDocumentNo(GenJournalLineSource: Record "Gen. Journal Line"; LineAmount: Decimal)
    var
        GenJournalLineCopy: Record "Gen. Journal Line";
    begin
        GenJournalLineCopy.Copy(GenJournalLineSource);
        GenJournalLineCopy."Line No." := LibraryUtility.GetNewRecNo(GenJournalLineCopy, GenJournalLineCopy.FieldNo("Line No."));
        GenJournalLineCopy.Amount := LineAmount;
        GenJournalLineCopy."Document No." := '';
        GenJournalLineCopy.Insert();
        PrintCashOrderFromJournalLine(GenJournalLineCopy);
    end;

    local procedure FindCheckLedgEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    begin
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        CheckLedgerEntry.SetRange("Document Type", DocType);
        CheckLedgerEntry.SetRange("Document No.", DocNo);
        CheckLedgerEntry.FindFirst();
    end;

    local procedure GetGenJournalLineFormattedText(GenJournalLine: Record "Gen. Journal Line"; FormatText: Text; BankBranchNo: Code[60]; PersonalAccNo: Code[20]): Text
    begin
        exit(
          StrSubstNo(
            FormatText,
            Format(GenJournalLine.Amount, 0, DecimalFormatTok),
            Format(Abs(GenJournalLine."VAT %"), 0, DecimalFormatTok),
            Format(Abs(GenJournalLine.Amount), 0, DecimalFormatTok),
            GenJournalLine."Applies-to Doc. No.",
            GenJournalLine."Applies-to Doc. Date",
            BankBranchNo,
            PersonalAccNo));
    end;

    local procedure GetPageNoAsCode(PageNumber: Integer): Code[20]
    begin
        exit(PadStr('', 5 - StrLen(Format(PageNumber)), '0') + Format(PageNumber));
    end;

    local procedure GetPageNoAsText(PageNumber: Integer): Text
    begin
        exit(StrSubstNo(PageNumberTxt, PageNumber));
    end;

    local procedure InitUpdatePaymentVATInfoUseDefaultPaymentPurpose(var GenJournalLine: Record "Gen. Journal Line"; var StandardText: Record "Standard Text"; var VendorBankAccount: Record "Vendor Bank Account")
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
    begin
        CreateBankOrder(GenJournalLine, -LibraryRandom.RandInt(100));
        CreateStandardTextCode(StandardText);

        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount."Account Type" := BankAccount."Account Type"::"Bank Account";
        BankAccount.Modify();

        CreateVendorWithBankAccount(Vendor, VendorBankAccount);

        GenJournalLine."Applies-to Doc. No." := LibraryUtility.GenerateGUID();
        GenJournalLine."Applies-to Doc. Date" := LibraryRandom.RandDate(10);
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        GenJournalLine."Account No." := Vendor."No.";
        GenJournalLine."Beneficiary Bank Code" := VendorBankAccount.Code;
        GenJournalLine.Modify();
    end;

    local procedure PrintCashOrderFromJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalLineToPrint: Record "Gen. Journal Line";
    begin
        GenJournalLineToPrint.Copy(GenJournalLine);
        GenJournalLineToPrint.SetRecFilter();
        RunCashOutgoingOrderReport(GenJournalLineToPrint);
        LibraryERM.RunAdjustGenJournalBalance(GenJournalLineToPrint);
    end;

    local procedure RunUpdatePaymentVATInfoScenario(var GenJournalLine: Record "Gen. Journal Line"; StandardText: Record "Standard Text"; VendorBankAccount: Record "Vendor Bank Account"; UseDeafultPaymentPurpose: Boolean; ExpectedFormat: Text)
    begin
        GenJournalLine.UpdatePaymentVATInfo(false);

        GenJournalLine.TestField("Payment Purpose", '');
        GenJournalLine.TestField("Cash Order Including", '');
        GenJournalLine.TestField("Cash Order Supplement", '');

        GenJournalLine."Payment Purpose" := StandardText.Description;
        GenJournalLine."Cash Order Including" := StandardText.Description;
        GenJournalLine."Cash Order Supplement" := StandardText.Description;

        GenJournalLine.UpdatePaymentVATInfo(UseDeafultPaymentPurpose);

        GenJournalLine.TestField(
          "Payment Purpose",
          GetGenJournalLineFormattedText(
            GenJournalLine, ExpectedFormat, VendorBankAccount."Bank Branch No.", VendorBankAccount."Personal Account No."));
        GenJournalLine.TestField(
          "Cash Order Including",
          GetGenJournalLineFormattedText(GenJournalLine, StandardText.Description, '', ''));
        GenJournalLine.TestField(
          "Cash Order Supplement",
          GetGenJournalLineFormattedText(GenJournalLine, StandardText.Description, '', ''));
    end;

    local procedure RunPrintCO4ReportScenario(var GenJournalLine: Record "Gen. Journal Line"; var BankAccountNo: Code[20]; PageNumber: Integer; ReportType: Option): Code[20]
    var
        DocumentNo: Code[20];
    begin
        CreateCashOrderForVendor(GenJournalLine, LibraryERM.CreateNoSeriesCode(), BankAccountNo);
        UpdateLastCashReportPageNo(GenJournalLine, PageNumber);
        DocumentNo := GenJournalLine."Document No.";
        PrintCashOrderFromJournalLine(GenJournalLine);
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJournalLine);
        RunCashReportCO4(BankAccountNo, ReportType, false, true, GenJournalLine."Posting Date");

        exit(DocumentNo);
    end;

    local procedure RunCashOutgoingOrderReport(var GenJournalLine: Record "Gen. Journal Line")
    var
        CashOutgoingOrder: Report "Cash Outgoing Order";
        FileManagement: Codeunit "File Management";
    begin
        LibraryReportValidation.SetFullFileName(FileManagement.ServerTempFileName('xlsx'));
        CashOutgoingOrder.SetFileNameSilent(LibraryReportValidation.GetFileName());
        CashOutgoingOrder.SetTableView(GenJournalLine);
        CashOutgoingOrder.UseRequestPage(false);
        CashOutgoingOrder.Run();
    end;

    local procedure RunCashIngoingOrderReport(var GenJournalLine: Record "Gen. Journal Line")
    var
        CashIngoingOrder: Report "Cash Ingoing Order";
        FileManagement: Codeunit "File Management";
    begin
        LibraryReportValidation.SetFullFileName(FileManagement.ServerTempFileName('xlsx'));
        CashIngoingOrder.SetFileNameSilent(LibraryReportValidation.GetFileName());
        CashIngoingOrder.SetTableView(GenJournalLine);
        CashIngoingOrder.UseRequestPage(false);
        CashIngoingOrder.Run();
    end;

    local procedure RunCashReportCO4(BankAccountNo: Code[20]; CashReportType: Option; PrintTitleSheet: Boolean; PrintLastSheet: Boolean; ReportDate: Date)
    var
        CashReportCO4: Report "Cash Report CO-4";
        FileManagement: Codeunit "File Management";
    begin
        LibraryReportValidation.SetFullFileName(FileManagement.ServerTempFileName('xlsx'));
        CashReportCO4.InitializeRequest(BankAccountNo, ReportDate, PrintTitleSheet, PrintLastSheet, CashReportType);
        CashReportCO4.SetFileNameSilent(LibraryReportValidation.GetFileName());
        CashReportCO4.UseRequestPage(false);
        CashReportCO4.Run();
    end;

    local procedure RunCashReportCO4WithRequestPage(BankAccountNo: Code[20]; CashReportType: Option; PrintTitleSheet: Boolean; PrintLastSheet: Boolean; ReportDate: Date)
    var
        CashReportCO4: Report "Cash Report CO-4";
        FileManagement: Codeunit "File Management";
    begin
        LibraryReportValidation.SetFullFileName(FileManagement.ServerTempFileName('xlsx'));
        CashReportCO4.InitializeRequest(BankAccountNo, ReportDate, PrintTitleSheet, PrintLastSheet, CashReportType);
        CashReportCO4.SetFileNameSilent(LibraryReportValidation.GetFileName());
        CashReportCO4.Run();
    end;

    local procedure SetAccountantNameInCompanyInformation(NewAccountantName: Text[50])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Accountant Name" := NewAccountantName;
        CompanyInformation.Modify();
    end;

    local procedure UpdateGenJournalLinePostingDate(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    begin
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateLastCashReportPageNo(GenJournalLine: Record "Gen. Journal Line"; PageNumber: Integer)
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount."Last Cash Report Page No." := GetPageNoAsCode(PageNumber);
        BankAccount.Modify();
    end;

    local procedure VerifyCashReportCO4(DocumentNo: Code[20]; ReportTypeCaption: Text)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueByRef('P', 17, 1, 'Zero');
        LibraryReportValidation.VerifyCellValueByRef('E', 19, 1, 'One2');
        LibraryReportValidation.VerifyCellValueByRef('N', 4, 1, ReportTypeCaption);
        LibraryReportValidation.VerifyCellValueByRef('A', 9, 1, DelChr(DocumentNo, '=', DelChr(DocumentNo, '<>', '0123456789')));
        LibraryReportValidation.VerifyCellValueByRef('AI', 22, 1, CompanyInformation."Accountant Name");
    end;

    local procedure VerifyPageNumbers(BankAccountNo: Code[20]; ExpectedPageNumber: Integer)
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountNo);
        BankAccount.TestField("Last Cash Report Page No.", GetPageNoAsCode(ExpectedPageNumber));

        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueByRef('BT', 2, 1, GetPageNoAsText(ExpectedPageNumber));
        LibraryReportValidation.VerifyCellValueByRef('W', 26, 1, Format(ExpectedPageNumber));
    end;

    local procedure VoidCheckLedgEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; VoidType: Option)
    var
        CheckManagement: Codeunit CheckManagement;
    begin
        LibraryVariableStorage.Enqueue(VoidType);
        CheckManagement.FinancialVoidCheck(CheckLedgerEntry);
        CheckLedgerEntry.Find();
    end;

    local procedure SetCheckLedgerLinePrinted(BankAccountNo: Code[20]; PageNo: Code[20])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        CheckLedgerEntry.FindFirst();
        CheckLedgerEntry.Validate("Cashier Report Printed", LibraryRandom.RandIntInRange(1, 5));
        CheckLedgerEntry.Validate("Cashier Report No.", PageNo);
        CheckLedgerEntry.Modify(true);
    end;

    local procedure SetCashReportPageNo(var BankAccount: Record "Bank Account"; var PageNo: Integer)
    begin
        PageNo := LibraryRandom.RandIntInRange(5, 10);
        SetCheckLedgerLinePrinted(BankAccount."No.", GetPageNoAsCode(PageNo));
        BankAccount."Last Cash Report Page No." := GetPageNoAsCode(PageNo + 1);
        BankAccount.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OutgoingCashOrderMPH(var OutgoingCashOrder: TestPage "Outgoing Cash Order")
    var
        StdTextCode: Code[10];
        ExpectedText: Text;
    begin
        StdTextCode := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(StdTextCode));
        ExpectedText := LibraryVariableStorage.DequeueText();

        LibraryVariableStorage.Enqueue(StdTextCode);
        OutgoingCashOrder."Payment Purpose".Lookup();
        OutgoingCashOrder."Payment Purpose".AssertEquals(ExpectedText);

        LibraryVariableStorage.Enqueue(StdTextCode);
        OutgoingCashOrder."Text 2".Lookup();
        OutgoingCashOrder."Text 2".AssertEquals(ExpectedText);

        LibraryVariableStorage.Enqueue(StdTextCode);
        OutgoingCashOrder."Cash Order Supplement".Lookup();
        OutgoingCashOrder."Cash Order Supplement".AssertEquals(ExpectedText);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure IngoingCashOrderMPH(var IngoingCashOrder: TestPage "Ingoing Cash Order")
    var
        StdTextCode: Code[10];
        ExpectedText: Text;
    begin
        StdTextCode := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(StdTextCode));
        ExpectedText := LibraryVariableStorage.DequeueText();

        LibraryVariableStorage.Enqueue(StdTextCode);
        IngoingCashOrder."Payment Purpose".Lookup();
        IngoingCashOrder."Payment Purpose".AssertEquals(ExpectedText);

        LibraryVariableStorage.Enqueue(StdTextCode);
        IngoingCashOrder."Text 2".Lookup();
        IngoingCashOrder."Text 2".AssertEquals(ExpectedText);

        LibraryVariableStorage.Enqueue(StdTextCode);
        IngoingCashOrder."Cash Order Supplement".Lookup();
        IngoingCashOrder."Cash Order Supplement".AssertEquals(ExpectedText);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure StandardTextCodesMPH(var StandardTextCodes: TestPage "Standard Text Codes")
    begin
        StandardTextCodes.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        StandardTextCodes.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfirmVoidCheckMPH(var ConfirmFinVoid: TestPage "Confirm Financial Void")
    begin
        ConfirmFinVoid.VoidType.SetValue(LibraryVariableStorage.DequeueInteger());
        ConfirmFinVoid.Yes().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CashReportCO4Handler(var CashReportCO4: TestRequestPage "Cash Report CO-4")
    begin
        CashReportCO4.PreviewMode.SetValue(LibraryVariableStorage.DequeueBoolean());
        CashReportCO4.OK().Invoke();
    end;
}

