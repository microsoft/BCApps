codeunit 144193 "IT - Non Ded.VAT - Annual VAT"
{
    // To Test the impact of calculation of Non Deductible VAT to prepare VAT Statement:
    //   1. Verify that system prints nondeductible base correctly when Amount Type is selected as Non Deductible Base for Annual VAT Communication Report Preview.
    //   2. Verify that system prints nondeductible amount correctly when Amount Type is selected as Non Deductible Amount for Annual VAT Communication Report Preview.
    //   3. Verify that system exports nondeductible base correctly when Amount Type is selected as Non Deductible Base for Annual VAT Communication.
    //   4. Verify that system exports nondeductible amount correctly when Amount Type is selected as Non Deductible Amount for Annual VAT Communication.
    //   5. Test to validate G/L Entry after post Sales Invoice.
    //   6. Test to validate G/L Entry after post Sales Credit Memo.
    //   7. Test to validate Data On VAT Register Print report after post Sales Invoice and Sales Credit Memo.
    // 
    // -------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                         TFS ID
    // -------------------------------------------------------------------------------------------------------
    // NonDeductibleBaseInAnnualVATCommReportPreview                                              255348
    // NonDeductibleAmountInAnnualVATCommReportPreview                                            255348
    // NonDeductibleBaseInExportedAnnualVATCommFile                                               255349
    // NonDeductibleAmountInExportedAnnualVATCommFile                                             255349
    // 
    // ----------------------------------------------------------------
    // Test Function Name                                       TFS ID
    // ----------------------------------------------------------------
    // VATAmountAfterPostSalesInvoice,
    // VATAmountAfterPostSalesCreditMemo,
    // VATRegisterPrintReportAfterPostSalesDocument             281787

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        NonDeductibleVATBaseAndAmountLbl: Label 'Total liability transactions (net of VAT)';
        WrongValueInReportErr: Label 'Value must be %1 in Report.', Comment = '.';
        WrongValueInFileErr: Label 'Actual value %1  is not the same as Expected value %2', Comment = '.';
        BaseLbl: Label 'Base';
        BaseErr: Label '%1 must be equal to %2.', Comment = '%1 = TableCaption, %2 = FieldValue';
        AmountErr: Label '%1 must be %2 in %3.', Comment = '%1 = FieldCaption, %2 = FieldValue, %3 = TableCaption';

    [Test]
    [Scope('OnPrem')]
    procedure NonDeductibleAmountInAnnualVATCommReportPreview()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Verify that system prints nondeductible amount correctly when Amount Type is selected as Non Deductible Amount for Annual VAT Communication Report Preview.
        NonDeductibleVATInAnnualVATCommReportPreview(VATStatementLine."Amount Type"::"Non-Deductible Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDeductibleBaseInAnnualVATCommReportPreview()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Verify that system prints nondeductible base correctly when Amount Type is selected as Non Deductible Base for Annual VAT Communication Report Preview.
        NonDeductibleVATInAnnualVATCommReportPreview(VATStatementLine."Amount Type"::"Non-Deductible Base");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDeductibleAmountInExportedAnnualVATCommFile()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Verify that system exports nondeductible amount correctly when Amount Type is selected as Non Deductible Amount for Annual VAT Communication.
        NonDeductibleVATInExportedAnnualVATCommFile(VATStatementLine."Amount Type"::"Non-Deductible Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonDeductibleBaseInExportedAnnualVATCommFile()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Verify that system exports nondeductible base correctly when Amount Type is selected as Non Deductible Base for Annual VAT Communication.
        NonDeductibleVATInExportedAnnualVATCommFile(VATStatementLine."Amount Type"::"Non-Deductible Base");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountAfterPostSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test to validate G/L Entry after post Sales Invoice.
        VATAmountInGlEntryAfterPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, -1);  // -1 used for sign.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountAfterPostSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test to validate G/L Entry after post Sales Credit Memo.
        VATAmountInGlEntryAfterPostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", 1);  // 1 used for sign.
    end;

    [Scope('OnPrem')]
    procedure VATRegisterPrintReportAfterPostSalesDocument()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedSalesInvoice: Code[20];
        PostedSalesCreditMemo: Code[20];
        SalesInvoiceAmount: Decimal;
        OldUnrealizedVAT: Boolean;
    begin
        // Test to validate Data On VAT Register Print report after post Sales Invoice and Sales Credit Memo.

        // Setup: Create VAT Posting Setup, find G/L Account, create and post Sales Invoice and Sales Credit Memo.
        Initialize();
        OldUnrealizedVAT := UpdateGeneralLedgerSetup(true);
        CreateVatPostingSetup(VATPostingSetup);
        FindAndUpdateGLAccount(GLAccount, VATPostingSetup);
        CreateSalesDocument(
          SalesHeader, SalesLine, GLAccount."VAT Bus. Posting Group", GLAccount."No.", SalesHeader."Document Type"::Invoice);
        PostedSalesInvoice := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceAmount := SalesLine."Line Amount";
        CreateSalesDocument(
          SalesHeader, SalesLine, GLAccount."VAT Bus. Posting Group", GLAccount."No.", SalesHeader."Document Type"::"Credit Memo");
        PostedSalesCreditMemo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Run VAT Register Print Report.
        RunVATRegisterPrintReport(VATPostingSetup);

        // Verify: Amount on VAT Register Print Report.
        LibraryReportValidation.OpenFile();
        VerifyVATRegisterPrintReport(PostedSalesInvoice, SalesInvoiceAmount);
        VerifyVATRegisterPrintReport(PostedSalesCreditMemo, -1 * SalesLine."Line Amount");

        // Teardown: Rollback General Ledger Setup.
        RestoreGeneralLedgerSetup(OldUnrealizedVAT);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        UpdateCompanyInformation();
        CheckAppointmentCode();

        IsInitialized := true;
        Commit();
    end;

    local procedure CheckAppointmentCode()
    var
        AppointmentCode: Record "Appointment Code";
    begin
        if not AppointmentCode.FindFirst() then
            CreateAppointmentCode();
    end;

    local procedure CreateAppointmentCode()
    var
        AppointmentCode: Record "Appointment Code";
    begin
        AppointmentCode.Init();
        AppointmentCode.Validate(
          Code,
          CopyStr(LibraryUtility.GenerateRandomCode(AppointmentCode.FieldNo(Code), DATABASE::"Appointment Code"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Appointment Code", AppointmentCode.FieldNo(Code))));
        AppointmentCode.Insert(true);
        AppointmentCode.Validate(Description, AppointmentCode.Code); // Validating Description with Code as value is not important.
        AppointmentCode.Modify(true);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("VAT Registration No.", Customer."No.");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateNoSeries(var NoSeries: Record "No. Series")
    var
        VatRegister: Record "VAT Register";
    begin
        FindVATRegister(VatRegister);
        NoSeries.Get(LibraryERM.CreateNoSeriesSalesCode());
        NoSeries.Validate("VAT Register", VatRegister.Code);
        NoSeries.Modify(true);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Deductible %", LibraryRandom.RandInt(99));
        VATPostingSetup.Modify(true);
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; VATBusPostingGroup: Code[20]; GLAccountNo: Code[20]; DocumentType: Enum "Sales Document Type")
    var
        NoSeries: Record "No. Series";
    begin
        CreateNoSeries(NoSeries);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(VATBusPostingGroup));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Use random value for Unit Price.
        SalesHeader.Validate("Operation Type", NoSeries.Code);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostGenJournalLine(AccountNo: Code[20]; AccountType: Enum "Gen. Journal Account Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        SelectAndClearGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          AccountType, AccountNo, LibraryRandom.RandDec(1000, 2)); // Using random value for field Amount.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CalculateNonDeductibleAmountFromVATEntry(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]) NonDeductibleAmount: Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntries(VATEntry, VATBusPostingGroup, VATProdPostingGroup);
        repeat
            NonDeductibleAmount += VATEntry."Nondeductible Amount";
        until VATEntry.Next() = 0;
    end;

    local procedure CalculateNonDeductibleBaseFromVATEntry(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]) NonDeductibleBase: Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntries(VATEntry, VATBusPostingGroup, VATProdPostingGroup);
        repeat
            NonDeductibleBase += VATEntry."Nondeductible Base";
        until VATEntry.Next() = 0;
    end;

    local procedure CreateVATStatementLine(VATStatementName: Record "VAT Statement Name"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; AmountType: Enum "VAT Statement Line Amount Type")
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.Validate(
          "Row No.",
          CopyStr(LibraryUtility.GenerateRandomCode(VATStatementLine.FieldNo("Row No."), DATABASE::"VAT Statement Line"),
            1, LibraryUtility.GetFieldLength(DATABASE::"VAT Statement Line", VATStatementLine.FieldNo("Row No."))));
        VATStatementLine.Validate(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.Validate("Gen. Posting Type", VATStatementLine."Gen. Posting Type"::Purchase);
        VATStatementLine.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        VATStatementLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        VATStatementLine.Validate("Amount Type", AmountType);
        VATStatementLine.Validate("Annual VAT Comm. Field", VATStatementLine."Annual VAT Comm. Field"::"CD2 - Total purchases");
        VATStatementLine.Modify(true);
    end;

    local procedure CreateVATStatementTemplateAndName(var VATStatementName: Record "VAT Statement Name")
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
    end;

    local procedure CreateVatPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT Identifier", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Sales VAT Unreal. Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GLAcountNo: Code[20])
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAcountNo);
        GLEntry.FindFirst();
    end;

    local procedure FindAndUpdateGLAccount(var GLAccount: Record "G/L Account"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        GLAccount.SetRange("Account Subcategory Entry No.", 0);
        LibraryERM.FindGLAccount(GLAccount);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure FindDeductiblePercent(): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        exit(VATPostingSetup."Deductible %");
    end;

    local procedure FindVATEntries(var VATEntry: Record "VAT Entry"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    begin
        VATEntry.SetRange("Posting Date", WorkDate());
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        VATEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        VATEntry.FindSet();
    end;

    local procedure FindVATRegister(var VATRegister: Record "VAT Register")
    begin
        VATRegister.SetRange(Type, VATRegister.Type::Sale);
        VATRegister.FindFirst();
    end;

    local procedure FindVATBookEntry(var VATBookEntry: Record "VAT Book Entry"; VatPostingSetup: Record "VAT Posting Setup")
    begin
        VATBookEntry.SetRange("VAT Bus. Posting Group", VatPostingSetup."VAT Bus. Posting Group");
        VATBookEntry.SetRange("VAT Prod. Posting Group", VatPostingSetup."VAT Prod. Posting Group");
        VATBookEntry.FindFirst();
    end;

    local procedure NonDeductibleVATInAnnualVATCommReportPreview(AmountType: Enum "VAT Statement Line Amount Type")
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementName: Record "VAT Statement Name";
        GLAccount: Record "G/L Account";
        Amount: Decimal;
        DeductiblePercent: Decimal;
    begin
        // Setup.
        Initialize();
        DeductiblePercent := FindDeductiblePercent();
        SetupTransactionData(VATStatementName, GLAccount, AmountType);
        if AmountType = VATStatementLine."Amount Type"::"Non-Deductible Base" then
            Amount := CalculateNonDeductibleBaseFromVATEntry(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group")
        else
            Amount := CalculateNonDeductibleAmountFromVATEntry(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");

        // Exercise: Run report Annual VAT Communication.
        RunReportAnnualVATCommunication(VATStatementName);

        // Verify: Verify amount in report preview.
        VerifyReportAnnualVATCommunication(Amount);

        // Tear Down.
        TearDown(
          VATStatementName."Statement Template Name", GLAccount."VAT Prod. Posting Group", GLAccount."VAT Bus. Posting Group",
          DeductiblePercent);
    end;

    local procedure NonDeductibleVATInExportedAnnualVATCommFile(AmountType: Enum "VAT Statement Line Amount Type")
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementName: Record "VAT Statement Name";
        GLAccount: Record "G/L Account";
        ExportedFileName: Text;
        Amount: Decimal;
        DeductiblePercent: Decimal;
    begin
        // Setup.
        Initialize();
        DeductiblePercent := FindDeductiblePercent();
        SetupTransactionData(VATStatementName, GLAccount, AmountType);
        if AmountType = VATStatementLine."Amount Type"::"Non-Deductible Base" then
            Amount := CalculateNonDeductibleBaseFromVATEntry(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group")
        else
            Amount := CalculateNonDeductibleAmountFromVATEntry(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");

        // Exercise: Run report and save the exported file.
        ExportedFileName := RunReportExpAnnualVATCommunicationAndSaveTheExportedFile(VATStatementName.Name);

        // Verify: Verify the exported file.
        // Using hard coded value 11 as this is the field length specified in the File Format.
        // Rounding off amount as it is specified in the file format and deleting character ',' from amount as it is not exported in file.
        VerifyExportedFile(
          ExportedFileName,
          PadStr('', 11 - StrLen(DelChr(Format(Round(Amount, 1)), '=', ',.')), ' ') + DelChr(Format(Round(Amount, 1)), '=', ',.'),
          2, 303, 11);

        // Tear Down.
        TearDown(
          VATStatementName."Statement Template Name", GLAccount."VAT Prod. Posting Group", GLAccount."VAT Bus. Posting Group",
          DeductiblePercent);
    end;

    local procedure RunReportAnnualVATCommunication(VATStatementName: Record "VAT Statement Name")
    var
        AppointmentCode: Record "Appointment Code";
        AnnualVATComm2010: Report "Annual VAT Comm. - 2010";
    begin
        AppointmentCode.FindFirst();
        Clear(AnnualVATComm2010);
        AnnualVATComm2010.UseRequestPage(false);
        AnnualVATComm2010.InitializeRequest(
          VATStatementName."Statement Template Name", VATStatementName.Name, AppointmentCode.Code,
          DMY2Date(1, 1, Date2DMY(WorkDate(), 3)), DMY2Date(31, 12, Date2DMY(WorkDate(), 3)));
        LibraryReportValidation.SetFileName(VATStatementName."Statement Template Name");
        AnnualVATComm2010.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    local procedure RunReportExpAnnualVATCommunicationAndSaveTheExportedFile(StatementName: Code[10]) ExportedFileName: Text
    var
        VATStatementName: Record "VAT Statement Name";
        AppointmentCode: Record "Appointment Code";
        ExpAnnualVATComm2010: Report "Exp.Annual VAT Comm. - 2010";
    begin
        VATStatementName.SetRange(Name, StatementName);
        VATStatementName.FindFirst();
        VATStatementName.SetFilter("Date Filter", '%1..%2', DMY2Date(1, 1, Date2DMY(WorkDate(), 3)), DMY2Date(31, 12, Date2DMY(WorkDate(), 3)));
        AppointmentCode.FindFirst();
        Clear(ExpAnnualVATComm2010);
        ExpAnnualVATComm2010.SetTableView(VATStatementName);
        ExpAnnualVATComm2010.UseRequestPage(false);
        ExpAnnualVATComm2010.InitializeRequest('', AppointmentCode.Code, true, true, true, true);
        ExpAnnualVATComm2010.RunModal();
        ExportedFileName := ExpAnnualVATComm2010.GetServerFileName();
    end;

    local procedure RunVATRegisterPrintReport(VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBookEntry: Record "VAT Book Entry";
        VATRegister: Record "VAT Register";
        VATRegisterPrint: Report "VAT Register - Print";
        CompanyInformation: array[7] of Text[50];
        PrintingType: Option Test,Final,Reprint;
        "Count": Integer;
    begin
        for Count := 1 to ArrayLen(CompanyInformation) do
            CompanyInformation[Count] := LibraryUtility.GetGlobalNoSeriesCode();
        FindVATRegister(VATRegister);
        FindVATBookEntry(VATBookEntry, VATPostingSetup);
        Clear(VATRegisterPrint);
        VATRegisterPrint.SetTableView(VATBookEntry);
        VATRegisterPrint.InitializeRequest(
          VATRegister, PrintingType::Test, WorkDate(),
          LibraryUtility.GenerateRandomDate(WorkDate(), CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(10)), WorkDate())), true,
          CompanyInformation);
        LibraryReportValidation.SetFileName(LibraryUtility.GetGlobalNoSeriesCode());
        VATRegisterPrint.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    local procedure SelectAndClearGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure SetupTransactionData(var VATStatementName: Record "VAT Statement Name"; var GLAccount: Record "G/L Account"; AmountType: Enum "VAT Statement Line Amount Type")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGLAccount(GLAccount);
        CreateAndPostGenJournalLine(GLAccount."No.", GenJournalLine."Account Type"::"G/L Account");
        CreateVATStatementTemplateAndName(VATStatementName);
        CreateVATStatementLine(VATStatementName, GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group", AmountType);
    end;

    local procedure TearDown(VATStatementTemplateName: Code[10]; VATProdPostingGroup: Code[20]; VATBusPostingGroup: Code[20]; DeductiblePercent: Decimal)
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Delete VAT Statement Template.
        VATStatementTemplate.SetRange(Name, VATStatementTemplateName);
        VATStatementTemplate.FindFirst();
        VATStatementTemplate.Delete(true);
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        VATPostingSetup.Validate("Deductible %", DeductiblePercent);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetup(NewUnrealizedVAT: Boolean) OldUnrealizedVAT: Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldUnrealizedVAT := GeneralLedgerSetup."Unrealized VAT";
        RestoreGeneralLedgerSetup(NewUnrealizedVAT);
    end;

    local procedure UpdateCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Fiscal Code" := CopyStr(LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Fiscal Code"), DATABASE::Vendor),
            1, LibraryUtility.GetFieldLength(DATABASE::Vendor, Vendor.FieldNo("Fiscal Code")));
        Vendor.Validate(
          "VAT Registration No.",
          CopyStr(LibraryUtility.GenerateRandomCode(Vendor.FieldNo("VAT Registration No."), DATABASE::Vendor),
            1, LibraryUtility.GetFieldLength(DATABASE::Vendor, Vendor.FieldNo("VAT Registration No."))));
        Vendor.Modify(true);
        CompanyInformation.Get();
        CompanyInformation.Validate("VAT Registration No.", Vendor."VAT Registration No.");
        CompanyInformation."Fiscal Code" := Vendor."Fiscal Code";  // Validation of Fiscal Code is out of scope for this feature.
        CompanyInformation.Validate("Tax Representative No.", Vendor."No.");
        CompanyInformation.Modify(true);
    end;

    local procedure VATAmountInGlEntryAfterPostSalesDocument(SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; Sign: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        CustomerPostingGroup: Record "Customer Posting Group";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
        VATAmount: Decimal;
        OldUnrealizedVAT: Boolean;
    begin
        // Setup: Create VAT Posting Setup and find G/L Account.
        Initialize();
        OldUnrealizedVAT := UpdateGeneralLedgerSetup(true);
        CreateVatPostingSetup(VATPostingSetup);
        FindAndUpdateGLAccount(GLAccount, VATPostingSetup);

        // Exercise: Create and Post Sales Document.
        CreateSalesDocument(SalesHeader, SalesLine, GLAccount."VAT Bus. Posting Group", GLAccount."No.", DocumentType);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VATAmount := (SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %") / 100;
        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");

        // Verify: Amount On G/L Entry.
        VerifyGLEntry(PostedDocumentNo, DocumentType, CustomerPostingGroup."Receivables Account", -Sign * SalesLine."Amount Including VAT");
        VerifyGLEntry(PostedDocumentNo, DocumentType, VATPostingSetup."Sales VAT Account", Sign * VATAmount);

        // Teardown: Rollback General Ledger Setup.
        RestoreGeneralLedgerSetup(OldUnrealizedVAT);
    end;

    local procedure VerifyVATRegisterPrintReport(DocumentNo: Code[20]; Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
        ActualAmount: Decimal;
    begin
        LibraryReportValidation.SetRange(SalesLine.FieldCaption("Document No."), DocumentNo);
        LibraryReportValidation.SetColumn(BaseLbl);
        Evaluate(ActualAmount, LibraryReportValidation.GetValue());
        Assert.AreEqual(Amount, ActualAmount, StrSubstNo(BaseErr, BaseLbl, Amount));
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; GLAcountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentType, DocumentNo, GLAcountNo);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), -1 * Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyExportedFile(FileName: Text; ExpectedValue: Text[1024]; LineNo: Integer; StartPos: Integer; FieldLength: Integer)
    var
        ActualValue: Text;
    begin
        ActualValue := LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), LineNo, StartPos, FieldLength);
        Assert.AreEqual(ExpectedValue, ActualValue, StrSubstNo(WrongValueInFileErr, ActualValue, ExpectedValue));
    end;

    local procedure VerifyReportAnnualVATCommunication(ExpectedAmount: Decimal)
    begin
        LibraryReportValidation.OpenFile();
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExists(NonDeductibleVATBaseAndAmountLbl),
          StrSubstNo(WrongValueInReportErr, NonDeductibleVATBaseAndAmountLbl));
        Assert.IsTrue(
          LibraryReportValidation.CheckIfDecimalValueExists(ExpectedAmount), StrSubstNo(WrongValueInReportErr, ExpectedAmount));
    end;

    local procedure RestoreGeneralLedgerSetup(UnrealizedVAT: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Modify(true);
    end;
}

