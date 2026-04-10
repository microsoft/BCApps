codeunit 134161 "Pmt Export Mgt Gen. Jnl Test"
{
    Permissions = TableData "Vendor Ledger Entry" = rimd,
                  TableData "Detailed Vendor Ledg. Entry" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [Payment Export Management]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPaymentExport: Codeunit "Library - Payment Export";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        ActualContentLengthErr: Label 'Only 35 characters should be read from the file.';
        ActualContentValueErr: Label 'Unexpected file content.';
        PmtJnlLineExportFlagErr: Label 'Payment Journal Line is not marked as exported.';
        RecordNotFoundErr: Label '%1 was not found.', Comment = '%1=TableCaption';

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ExportAgainPmtJnlLineAutoApplied()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        InvGenJournalLine: Record "Gen. Journal Line";
        PmtGenJournalLine: Record "Gen. Journal Line";
        DataExchMapping: Record "Data Exch. Mapping";
        Vendor: Record Vendor;
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
        MessageToRecipient: Text;
    begin
        // [SCENARIO 1] Re-Export Payment Journal Line to a File
        // [GIVEN] Gen. Journal Line of type Payment
        // [GIVEN] Gen. Journal Line is auto-applied to a Posted Purchase Invoice
        // [GIVEN] The Exported to Payment File flag is set to true on the Gen. Journal Line
        // [WHEN] User clicks the Export Payment to File action on the Payment Journal
        // [THEN] Confirmation message pops up
        // [THEN] File is created

        // Pre-Setup
        LibraryPaymentExport.CreateVendorWithBankAccount(Vendor);
        PostPurchaseInvoice(InvGenJournalLine, Vendor."No.");

        DefinePaymentExportFormat(DataExchMapping);
        UpdatePaymentMethodLineDef(Vendor."Payment Method Code", DataExchMapping."Data Exch. Line Def Code");

        // Setup
        LibraryPaymentExport.CreatePaymentExportBatch(GenJournalBatch, DataExchMapping."Data Exch. Def Code");
        UpdateBankExportImportSetup(GenJournalBatch."Bal. Account No.");

        LibraryPaymentExport.CreateVendorPmtJnlLine(PmtGenJournalLine, GenJournalBatch, Vendor."No.");
        MessageToRecipient := LibraryUtility.GenerateRandomText(MaxStrLen(PmtGenJournalLine."Message to Recipient"));
        PmtGenJournalLine."Message to Recipient" := CopyStr(MessageToRecipient, 1, MaxStrLen(PmtGenJournalLine."Message to Recipient"));
        if PmtGenJournalLine."Account Type" = PmtGenJournalLine."Account Type"::"Bank Account" then
            PmtGenJournalLine."Bank Payment Type" := PmtGenJournalLine."Bank Payment Type"::"Electronic Payment";
        if PmtGenJournalLine."Bal. Account Type" = PmtGenJournalLine."Bal. Account Type"::"Bank Account" then
            PmtGenJournalLine."Bank Payment Type" := PmtGenJournalLine."Bank Payment Type"::"Electronic Payment";
        PmtGenJournalLine.Modify();

        ApplyPaymentToPurchaseInvoice(PmtGenJournalLine, InvGenJournalLine);

        // Exercise
        PmtGenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        PmtGenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);

        PmtExportMgtGenJnlLine.EnableExportToServerTempFile(true, 'txt');
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(PmtGenJournalLine); // Will set exported flag
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(PmtGenJournalLine); // Will ask for export again

        // Verify
        ValidatePaymentFile(PmtExportMgtGenJnlLine.GetServerTempFileName(), MessageToRecipient);
        ValidateExportedPmtJnlLine(GenJournalBatch);
        ValidateCreditTransferRegister(DataExchMapping."Data Exch. Def Code", GenJournalBatch."Bal. Account No.");
    end;

    local procedure UpdatePaymentMethodLineDef(PaymentMethodCode: Code[10]; DataExchLineDefCode: Code[20])
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.Get(PaymentMethodCode);
        PaymentMethod.Validate("Pmt. Export Line Definition", DataExchLineDefCode);
        PaymentMethod.Modify(true);
    end;

    local procedure PostPurchaseInvoice(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure DefinePaymentExportFormat(var DataExchMapping: Record "Data Exch. Mapping")
    var
        PaymentExportData: Record "Payment Export Data";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        LibraryPaymentExport.CreateSimpleDataExchDefWithMapping(DataExchMapping,
          DATABASE::"Payment Export Data", PaymentExportData.FieldNo("Message to Recipient 1"));

        DataExchDef.Get(DataExchMapping."Data Exch. Def Code");
        DataExchDef.Validate("File Type", DataExchDef."File Type"::"Variable Text");
        DataExchDef.Validate("Reading/Writing XMLport", XMLPORT::"Export Generic CSV");
        DataExchDef.Modify(true);

        DataExchLineDef.Get(DataExchMapping."Data Exch. Def Code", DataExchMapping."Data Exch. Line Def Code");
        DataExchLineDef.Validate("Column Count", 1);
        DataExchLineDef.Modify(true);
    end;

    local procedure UpdateBankExportImportSetup(BankAccountNo: Code[20])
    var
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankAccount.Get(BankAccountNo);
        BankAccount.GetBankExportImportSetup(BankExportImportSetup);
        BankExportImportSetup."Processing Codeunit ID" := CODEUNIT::"Pmt Export Mgt Gen. Jnl Line";
        BankExportImportSetup.Modify();
    end;

    local procedure ApplyPaymentToPurchaseInvoice(var PmtGenJournalLine: Record "Gen. Journal Line"; InvGenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvGenJournalLine."Document No.");
        PmtGenJournalLine.Validate("Applies-to Doc. Type", PmtGenJournalLine."Applies-to Doc. Type"::Invoice);
        PmtGenJournalLine.Validate("Applies-to Doc. No.", VendorLedgerEntry."Document No.");
        PmtGenJournalLine.Validate(Amount, -InvGenJournalLine.Amount);
        PmtGenJournalLine.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure ValidatePaymentFile(FileName: Text; MessageToRecipient: Text)
    var
        ActualMessageToRecipient: Text[37];
    begin
        ActualMessageToRecipient := CopyStr(ReadPaymentFile(FileName), 1, 37);
        Assert.AreEqual(35, StrLen(DelChr(ActualMessageToRecipient, '=', '"')), ActualContentLengthErr);
        Assert.AreNotEqual(0, StrPos(MessageToRecipient, DelChr(ActualMessageToRecipient, '=', '"')), ActualContentValueErr);
    end;

    local procedure ReadPaymentFile(FileName: Text) Content: Text
    var
        PaymentFile: File;
    begin
        PaymentFile.WriteMode := false;
        PaymentFile.TextMode := true;
        PaymentFile.Open(FileName);
        PaymentFile.Read(Content);
        PaymentFile.Close();
    end;

    local procedure ValidateExportedPmtJnlLine(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        Assert.IsTrue(GenJournalLine."Exported to Payment File", PmtJnlLineExportFlagErr);
    end;

    local procedure ValidateCreditTransferRegister(Identifier: Code[20]; FromBankAccountNo: Code[20])
    var
        CreditTransferRegister: Record "Credit Transfer Register";
    begin
        CreditTransferRegister.SetRange(Identifier, Identifier);
        CreditTransferRegister.SetRange(Status, CreditTransferRegister.Status::"File Created");
        CreditTransferRegister.SetRange("From Bank Account No.", FromBankAccountNo);
        Assert.IsFalse(CreditTransferRegister.IsEmpty, StrSubstNo(RecordNotFoundErr, CreditTransferRegister.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPmtJnlLineManuallyApplied()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        InvGenJournalLine: Record "Gen. Journal Line";
        PmtGenJournalLine: Record "Gen. Journal Line";
        DataExchMapping: Record "Data Exch. Mapping";
        Vendor: Record Vendor;
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
        MessageToRecipient: Text;
    begin
        // [SCENARIO 2] Export Payment Journal Line to a File
        // [GIVEN] Gen. Journal Line of type Payment
        // [GIVEN] Gen. Journal Line is manually-applied to a Posted Purchase Invoice
        // [WHEN] User clicks the Export Payment to File action on the Payment Journal
        // [THEN] File is created

        // Pre-Setup
        LibraryPaymentExport.CreateVendorWithBankAccount(Vendor);
        PostPurchaseInvoice(InvGenJournalLine, Vendor."No.");

        DefinePaymentExportFormat(DataExchMapping);
        UpdatePaymentMethodLineDef(Vendor."Payment Method Code", DataExchMapping."Data Exch. Line Def Code");

        // Setup
        LibraryPaymentExport.CreatePaymentExportBatch(GenJournalBatch, DataExchMapping."Data Exch. Def Code");
        UpdateBankExportImportSetup(GenJournalBatch."Bal. Account No.");

        LibraryPaymentExport.CreateVendorPmtJnlLine(PmtGenJournalLine, GenJournalBatch, Vendor."No.");
        MessageToRecipient := LibraryUtility.GenerateRandomText(MaxStrLen(PmtGenJournalLine."Message to Recipient"));
        PmtGenJournalLine."Message to Recipient" := CopyStr(MessageToRecipient, 1, MaxStrLen(PmtGenJournalLine."Message to Recipient"));
        if PmtGenJournalLine."Account Type" = PmtGenJournalLine."Account Type"::"Bank Account" then
            PmtGenJournalLine."Bank Payment Type" := PmtGenJournalLine."Bank Payment Type"::"Electronic Payment";
        if PmtGenJournalLine."Bal. Account Type" = PmtGenJournalLine."Bal. Account Type"::"Bank Account" then
            PmtGenJournalLine."Bank Payment Type" := PmtGenJournalLine."Bank Payment Type"::"Electronic Payment";
        PmtGenJournalLine.Modify();

        ApplyPaymentToPurchaseInvoiceManually(PmtGenJournalLine, InvGenJournalLine);

        // Exercise
        PmtExportMgtGenJnlLine.EnableExportToServerTempFile(true, 'txt');
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(PmtGenJournalLine);

        // Verify
        ValidatePaymentFile(PmtExportMgtGenJnlLine.GetServerTempFileName(), MessageToRecipient);
        ValidateExportedPmtJnlLine(GenJournalBatch);
        ValidateCreditTransferRegister(DataExchMapping."Data Exch. Def Code", GenJournalBatch."Bal. Account No.");
    end;

    local procedure ApplyPaymentToPurchaseInvoiceManually(var PmtGenJournalLine: Record "Gen. Journal Line"; InvGenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvGenJournalLine."Document No.");
        VendorLedgerEntry.Validate("Applies-to ID", UserId);
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendorLedgerEntry);

        PmtGenJournalLine.Validate("Applies-to Doc. Type", PmtGenJournalLine."Applies-to Doc. Type"::Invoice);
        PmtGenJournalLine.Validate("Applies-to ID", UserId);
        PmtGenJournalLine.Validate(Amount, -InvGenJournalLine.Amount);
        PmtGenJournalLine.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPmtJnlLineNotApplied()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        InvGenJournalLine: Record "Gen. Journal Line";
        PmtGenJournalLine: Record "Gen. Journal Line";
        DataExchMapping: Record "Data Exch. Mapping";
        Vendor: Record Vendor;
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
        MessageToRecipient: Text;
    begin
        // [SCENARIO 3] Export Payment Journal Line to a File
        // [GIVEN] Gen. Journal Line of type Payment
        // [GIVEN] The Gen. Journal Line is not applied to any Posted Purchase Invoices
        // [WHEN] User clicks the Export Payment to File action on the Payment Journal
        // [THEN] File is created

        // Pre-Setup
        LibraryPaymentExport.CreateVendorWithBankAccount(Vendor);
        PostPurchaseInvoice(InvGenJournalLine, Vendor."No.");

        DefinePaymentExportFormat(DataExchMapping);
        UpdatePaymentMethodLineDef(Vendor."Payment Method Code", DataExchMapping."Data Exch. Line Def Code");

        // Setup
        LibraryPaymentExport.CreatePaymentExportBatch(GenJournalBatch, DataExchMapping."Data Exch. Def Code");
        UpdateBankExportImportSetup(GenJournalBatch."Bal. Account No.");

        LibraryPaymentExport.CreateVendorPmtJnlLine(PmtGenJournalLine, GenJournalBatch, Vendor."No.");
        MessageToRecipient := LibraryUtility.GenerateRandomText(MaxStrLen(PmtGenJournalLine."Message to Recipient"));
        PmtGenJournalLine."Message to Recipient" := CopyStr(MessageToRecipient, 1, MaxStrLen(PmtGenJournalLine."Message to Recipient"));
        if PmtGenJournalLine."Account Type" = PmtGenJournalLine."Account Type"::"Bank Account" then
            PmtGenJournalLine."Bank Payment Type" := PmtGenJournalLine."Bank Payment Type"::"Electronic Payment";
        if PmtGenJournalLine."Bal. Account Type" = PmtGenJournalLine."Bal. Account Type"::"Bank Account" then
            PmtGenJournalLine."Bank Payment Type" := PmtGenJournalLine."Bank Payment Type"::"Electronic Payment";
        PmtGenJournalLine.Modify();

        // Exercise
        PmtExportMgtGenJnlLine.EnableExportToServerTempFile(true, 'txt');
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(PmtGenJournalLine);

        // Verify
        ValidatePaymentFile(PmtExportMgtGenJnlLine.GetServerTempFileName(), MessageToRecipient);
        ValidateExportedPmtJnlLine(GenJournalBatch);
        ValidateCreditTransferRegister(DataExchMapping."Data Exch. Def Code", GenJournalBatch."Bal. Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPmtJnlLineAmountAfterExport()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        InvGenJournalLine: Record "Gen. Journal Line";
        PmtGenJournalLine: Record "Gen. Journal Line";
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        Vendor: Record Vendor;
        CountryRegion: Record "Country/Region";
        Currency: Record Currency;
        BankAcc: Record "Bank Account";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
        PaymentType: Code[20];
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 324483] Created Vendor Bank Account and Bank Account with equal Country/Region code.
        // [SCENARIO 324483] Started export process. GenJnlLine.Amout should be exported.

        // [GIVEN] Vendor, Vendor Bank Account and Bank Account created with Country/Region code
        LibraryERM.CreateCountryRegion(CountryRegion);
        PaymentType := LibraryUtility.GenerateGUID();
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        Currency.Get(CurrencyCode);
        Currency.Validate("Currency Factor", LibraryRandom.RandDecInRange(5, 10, 2));
        CreateVendorWithBankAccountAndCountryRegion(Vendor, PaymentType, CountryRegion.Code);
        CreateBankAccountWithExportFormatAndCountryRegion(
          BankAcc, CreatePaymentExportFormatWithFullSetupClient(PaymentType), CountryRegion.Code);

        PostPurchaseInvoice(InvGenJournalLine, Vendor."No.");
        DefinePaymentExportFormatForAmount(DataExchMapping, DataExchDef."File Type"::"Variable Text");
        UpdatePaymentMethodLineDef(Vendor."Payment Method Code", DataExchMapping."Data Exch. Line Def Code");

        // [GIVEN] GenJnlLine is created with Amount LCY and prepared to Export
        LibraryPaymentExport.CreatePaymentExportBatch(GenJournalBatch, DataExchMapping."Data Exch. Def Code");
        UpdateBankExportImportSetup(GenJournalBatch."Bal. Account No.");

        LibraryPaymentExport.CreateVendorPmtJnlLine(PmtGenJournalLine, GenJournalBatch, Vendor."No.");
        UpdateGenJnlLine(PmtGenJournalLine, Currency.Code);

        ApplyPaymentToPurchaseInvoiceManually(PmtGenJournalLine, InvGenJournalLine);

        // [WHEN] Export Process run
        PmtExportMgtGenJnlLine.EnableExportToServerTempFile(true, 'txt');
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(PmtGenJournalLine);

        // [THEN] Amount in exported file is equal to GenJnlLine.Amount
        Assert.AreEqual(PmtGenJournalLine.Amount, GetAmountFromFile(PmtExportMgtGenJnlLine.GetServerTempFileName()), 'Amount');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SavePaymentDetailsToFileForCurrencyWithFactorforLocalsBankAccount()
    var
        BankAcc: Record "Bank Account";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        CountryRegion: Record "Country/Region";
        Currency: Record Currency;
        PaymentType: Code[20];
    begin
        // [SCENARIO 324483] Created Vendor Bank Account and Bank Account with equal Country/Region code.
        // [SCENARIO 324483] Started export process. GenJnlLine.Amout should be exported.

        // [GIVEN] Vendor, Vendor Bank Account and Bank Account created with Country/Region code
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryERM.CreateCurrency(Currency);

        PaymentType := LibraryUtility.GenerateGUID();
        CreateCurrencyWithFactor(Currency);

        CreateVendorWithBankAccountAndCountryRegion(Vendor, PaymentType, CountryRegion.Code);
        CreateBankAccountWithExportFormatAndCountryRegion(
          BankAcc, CreatePaymentExportFormatWithFullSetupClient(PaymentType), CountryRegion.Code);
        CreateExportGenJournalBatch(GenJnlBatch, BankAcc."No.");

        // [GIVEN] GenJnlLine is created with Amount LCY and prepared to Export
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));
        UpdateGenJnlLine(GenJnlLine, Currency.Code);

        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // [WHEN] Export Process run
        CODEUNIT.Run(CODEUNIT::"Exp. Launcher Gen. Jnl.", GenJnlLine);

        // [THEN] Amount in exported file is equal to GenJnlLine.Amount
        Assert.AreEqual(GenJnlLine.Amount, GetAmountFromLongFile(GetFilePath(BankAcc."No.")), 'Amount');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVendorLedgerEntryAmountAfterExport()
    var
        Vendor: Record Vendor;
        CountryRegion: Record "Country/Region";
        Currency: Record Currency;
        BankAcc: Record "Bank Account";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        DataExch: Record "Data Exch.";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PmtExportMgtVendLedgEntry: Codeunit "Pmt Export Mgt Vend Ledg Entry";
        PaymentType: Code[20];
        LineNo: Integer;
    begin
        // [SCENARIO 324483] Created Vendor Bank Account and Bank Account with equal Country/Region code.
        // [SCENARIO 324483] Started preparing export process. VendorLedgerEntry. Amout should be validated in PaymentExportData.

        // [GIVEN] Vendor, Vendor Bank Account and Bank Account created with Country/Region code
        LineNo := 1000;
        LibraryERM.CreateCountryRegion(CountryRegion);

        PaymentType := LibraryUtility.GenerateGUID();
        CreateCurrencyWithFactor(Currency);
        CreateVendorWithBankAccountAndCountryRegion(Vendor, PaymentType, CountryRegion.Code);
        CreateBankAccountWithExportFormatAndCountryRegion(
          BankAcc, CreatePaymentExportFormatWithFullSetupClient(PaymentType), CountryRegion.Code);

        // [GIVEN] VendorLedgerEntry is created with Amount LCY and prepared to Export
        CreateVendorLedgerEntry(
          VendorLedgerEntry,
          VendorLedgerEntry."Document Type"::Invoice,
          true,
          Vendor."No.",
          BankAcc."No.",
          Vendor."Preferred Bank Account Code",
          Vendor."Payment Method Code",
          Currency);

        // [WHEN] Export Preparing Process run
        PmtExportMgtVendLedgEntry.PreparePaymentExportDataVLE(TempPaymentExportData, VendorLedgerEntry,
          DataExch."Entry No.", LineNo);

        // [THEN] Amount in TempPaymentExportData is equal to VendorLedgerEntry.Amount
        Assert.AreEqual(VendorLedgerEntry.Amount, TempPaymentExportData.Amount, 'Amount');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPaymentJournalWithEmployee()
    var
        Employee: Record Employee;
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        PaymentMethod: Record "Payment Method";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        // [FEATURE] [Employee]
        // [SCENARIO 330729] Export payment journal for employee using codeunit 1206 "Pmt Export Mgt Gen. Jnl Line" for processing.

        // [GIVEN] Employee "E".
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);

        // [GIVEN] Set up Data Exchange Definition for exporting "Amount" field.
        DefinePaymentExportFormatForAmount(DataExchMapping, DataExchDef."File Type"::"Variable Text");

        // [GIVEN] Set up payment method.
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Pmt. Export Line Definition", DataExchMapping."Data Exch. Line Def Code");
        PaymentMethod.Modify(true);

        // [GIVEN] Create bank account.
        // [GIVEN] Create payment journal batch for the bank account, allow payment export.
        // [GIVEN] Set up Bank Export/Import Setup for using processing codeunit 1206.
        LibraryPaymentExport.CreatePaymentExportBatch(GenJournalBatch, DataExchMapping."Data Exch. Def Code");
        UpdateBankExportImportSetup(GenJournalBatch."Bal. Account No.");

        // [GIVEN] Create payment journal line for employee "E" and Amount = "X" in the batch created.
        LibraryERM.CreateGeneralJnlLine(GenJournalLine,
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Employee, Employee."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Payment Method Code", PaymentMethod.Code);
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine.Modify(true);

        // [WHEN] Export the payment journal line.
        PmtExportMgtGenJnlLine.EnableExportToServerTempFile(true, 'txt');
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJournalLine);

        // [THEN] Read amount in the export file, ensure it is equal to "X".
        Assert.AreEqual(GenJournalLine.Amount, GetAmountFromFile(PmtExportMgtGenJnlLine.GetServerTempFileName()), 'Amount');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreparedPaymentDataFromPmtJournalWithEmployee()
    var
        Employee: Record Employee;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        // [FEATURE] [Employee] [UT]
        // [SCENARIO 330729] PreparePaymentExportDataJnl function in Codeunit 1206 "Pmt Export Mgt Gen. Jnl Line" populates Payment Export Data from a payment journal line with an employee.
        // [GIVEN] Employee "E".
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);
        Employee.Address := LibraryUtility.GenerateGUID();
        Employee.City := LibraryUtility.GenerateGUID();
        Employee.County := LibraryUtility.GenerateGUID();
        Employee."Post Code" := LibraryUtility.GenerateGUID();
        Employee."Country/Region Code" := LibraryUtility.GenerateGUID();
        Employee."E-Mail" := LibraryUtility.GenerateGUID();
        Employee.Modify();

        // [GIVEN] Payment journal line for employee "E".
        LibraryPaymentExport.CreatePaymentExportBatch(GenJournalBatch, '');
        LibraryERM.CreateGeneralJnlLine(GenJournalLine,
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Employee, Employee."No.", LibraryRandom.RandDec(100, 2));

        // [WHEN] Invoke "PreparePaymentExportDataJnl" function in Codeunit 1206.
        PmtExportMgtGenJnlLine.PreparePaymentExportDataJnl(TempPaymentExportData, GenJournalLine, 0, 0);
        // [THEN] Recipient information on Payment Export Data record is filled in with employee "E" data.
        TempPaymentExportData.TestField("Recipient Name", Employee.FullName());
        TempPaymentExportData.TestField("Recipient Address", Employee.Address);
        TempPaymentExportData.TestField("Recipient City", Employee.City);
        TempPaymentExportData.TestField("Recipient County", Employee.County);
        TempPaymentExportData.TestField("Recipient Post Code", Employee."Post Code");
        TempPaymentExportData.TestField("Recipient Country/Region Code", Employee."Country/Region Code");
        TempPaymentExportData.TestField("Recipient Email Address", Employee."E-Mail");
        TempPaymentExportData.TestField("Recipient Bank Acc. No.", Employee.GetBankAccountNo());
        TempPaymentExportData.TestField("Recipient Reg. No.", Employee."Bank Branch No.");
        TempPaymentExportData.TestField("Recipient Acc. No.", Employee."Bank Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataExchangeDefinitionTextPaddingForPaymentExport()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        InvGenJnlLine: Record "Gen. Journal Line";
        PmtGenJnlLine: Record "Gen. Journal Line";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        Vendor: Record Vendor;
        BankAcc: Record "Bank Account";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
        PaymentType: Code[20];
        PadChar: Text[1];
        PaddedAmount: Text;
        AmountLength: Integer;
        PaddedLength: Integer;
    begin
        // [SCENARIO 362731] Payment Export Data Exchange Definition can be setup to use Text Padding.

        // [GIVEN] Vendor, Vendor Bank Account and Bank Account.
        PaymentType := LibraryUtility.GenerateGUID();
        CreateVendorWithBankAccountAndCountryRegion(Vendor, PaymentType, '');
        CreateBankAccountWithExportFormatAndCountryRegion(BankAcc, CreatePaymentExportFormatWithFullSetupClient(PaymentType), '');

        PostPurchaseInvoice(InvGenJnlLine, Vendor."No.");
        DefinePaymentExportFormatForAmount(DataExchMapping, DataExchDef."File Type"::"Fixed Text");
        UpdatePaymentMethodLineDef(Vendor."Payment Method Code", DataExchMapping."Data Exch. Line Def Code");

        // [GIVEN] General Journal Line is created with Amount and prepared to export.
        LibraryPaymentExport.CreatePaymentExportBatch(GenJnlBatch, DataExchMapping."Data Exch. Def Code");
        UpdateBankExportImportSetup(GenJnlBatch."Bal. Account No.");
        LibraryPaymentExport.CreateVendorPmtJnlLine(PmtGenJnlLine, GenJnlBatch, Vendor."No.");
        PmtGenJnlLine.Validate("Bank Payment Type", PmtGenJnlLine."Bank Payment Type"::"Electronic Payment");
        PmtGenJnlLine.Modify(true);
        ApplyPaymentToPurchaseInvoiceManually(PmtGenJnlLine, InvGenJnlLine);

        // [GIVEN] Payment export's Data Dxchange Column Definition for Amount = "14.7" with Length = "6",
        // [GIVEN] Pad Character = "0" and "Text Padding Required" = "True", Justification = "Left".
        AmountLength := StrLen(Format(PmtGenJnlLine.Amount));
        PaddedLength := AmountLength + LibraryRandom.RandInt(10);
        PadChar := CopyStr(LibraryRandom.RandText(1), 1, 1);
        UpdateDataExchColumnDefToUsePadding(
            DataExchMapping."Data Exch. Def Code", DataExchMapping."Data Exch. Line Def Code", 1, DataExchColumnDef."Data Type"::Decimal,
            '<Precision,2:2><Standard Format,2>', PaddedLength, PadChar, DataExchColumnDef.Justification::Left);

        // [WHEN] Export Process is run.
        PmtExportMgtGenJnlLine.EnableExportToServerTempFile(true, 'txt');
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(PmtGenJnlLine);

        // [THEN] Amount text = "14.7000" in exported file is equal to Amount padded with Pad Character.
        PaddedAmount := PadStr(Format(PmtGenJnlLine.Amount), PaddedLength, PadChar);
        Assert.AreEqual(PaddedAmount, GetAmountTextFromFile(PmtExportMgtGenJnlLine.GetServerTempFileName()), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportDataVendorEmailBankCountyPostCode()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        BankAccount: Record "Bank Account";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        // [SCENARIO 413133] PreparePaymentExportDataJnl function in Cod1206 populates "Recipient Email Address", "Recipient Bank County", "Recipient Bank Post Code"

        // [GIVEN] Vendor "V" with "Email" = "Em" and Vendor Bank Account "VBA"
        LibraryPaymentExport.CreateVendorWithBankAccount(Vendor);
        Vendor.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Vendor.Modify();

        // [GIVEN] Vendor Bank Account "VBA" County = "C", 'Post Code' = "PC"
        VendorBankAccount.Get(Vendor."No.", Vendor."Preferred Bank Account Code");
        VendorBankAccount.Validate(County, LibraryUtility.GenerateGUID());
        VendorBankAccount.Validate("Post Code", LibraryUtility.GenerateGUID());
        VendorBankAccount.Modify();

        // [GIVEN] Payment journal line for Vendor "V", "Bal. Account No." = Bank with Name "BN"
        LibraryPaymentExport.CreatePaymentExportBatch(GenJournalBatch, '');
        LibraryERM.CreateGeneralJnlLine(GenJournalLine,
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(100, 2));
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        // [WHEN] Invoke "PreparePaymentExportDataJnl" function in Codeunit 1206.
        PmtExportMgtGenJnlLine.PreparePaymentExportDataJnl(TempPaymentExportData, GenJournalLine, 0, 0);

        // [THEN] Payment Export Data record is filled with "Recipient Email Address" = "Em", "Recipient Bank County" = "C", "Recipient Bank Post Code" = "PC"
        // "Sender Bank Name" = "BN"
        TempPaymentExportData.TestField("Recipient Email Address", Vendor."E-Mail");
        TempPaymentExportData.TestField("Recipient Bank County", VendorBankAccount.County);
        TempPaymentExportData.TestField("Recipient Bank Post Code", VendorBankAccount."Post Code");
        TempPaymentExportData.TestField("Sender Bank Name", BankAccount.Name);
    end;

    local procedure CreateVendorWithBankAccountAndCountryRegion(var Vendor: Record Vendor; PaymentType: Code[20]; CountryRegionCode: Code[10])
    var
        PaymentMethod: Record "Payment Method";
        VendorBankAcc: Record "Vendor Bank Account";
    begin
        LibraryPaymentExport.CreateVendorWithBankAccount(Vendor);
        VendorBankAcc.Get(Vendor."No.", Vendor."Preferred Bank Account Code");

        VendorBankAcc.IBAN := LibraryUtility.GenerateGUID();
        VendorBankAcc."Country/Region Code" := CountryRegionCode;
        VendorBankAcc.Modify(true);

        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Pmt. Export Line Definition", PaymentType);
        PaymentMethod.Modify(true);

        Vendor.Validate("Preferred Bank Account Code", VendorBankAcc.Code);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);
    end;

    local procedure CreateBankAccountWithExportFormatAndCountryRegion(var BankAcc: Record "Bank Account"; PaymentExportFormat: Code[20]; CountryRegionCode: Code[10])
    begin
        LibraryERM.CreateBankAccount(BankAcc);
        BankAcc.IBAN := LibraryUtility.GenerateGUID();
        BankAcc.Validate("Payment Export Format", PaymentExportFormat);
        BankAcc."Country/Region Code" := CountryRegionCode;
        BankAcc.Modify(true);
    end;

    local procedure ReadFile(FileName: Text) Content: Text
    var
        File: File;
    begin
        File.WriteMode := false;
        File.TextMode := true;
        File.Open(FileName);
        File.Read(Content);
        File.Close();
    end;

    local procedure GetAmountFromFile(FilePath: Text) Amount: Decimal
    var
        String: Text;
    begin
        String := ReadFile(FilePath);
        String := CopyStr(String, 2, StrLen(String) - 2);
        Evaluate(Amount, String);
    end;

    local procedure GetAmountFromLongFile(FilePath: Text) Amount: Decimal
    var
        String: Text;
    begin
        String := ReadFile(FilePath);
        String := CopyStr(String, StrPos(String, ',') + 1, StrLen(String) - StrPos(String, ','));
        String := CopyStr(String, StrPos(String, ',') + 1, StrLen(String) - StrPos(String, ','));
        String := CopyStr(String, 2, StrLen(String) - 2);
        Evaluate(Amount, String);
    end;

    local procedure GetAmountTextFromFile(FilePath: Text) String: Text
    begin
        String := ReadFile(FilePath);
        String := CopyStr(String, 2, StrLen(String) - 2);
    end;

    local procedure CreatePaymentExportFormatWithFullSetupClient(PaymentType: Code[20]): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        LibraryPaymentFormat: Codeunit "Library - Payment Format";
    begin
        LibraryPaymentFormat.CreateDataExchDef(
          DataExchDef, CODEUNIT::"Exp. Data Handling Gen. Jnl.",
          CODEUNIT::"Exp. Validation Gen. Jnl.", CODEUNIT::"Exp. Writing Gen. Jnl.", XMLPORT::"Export Generic CSV",
          CODEUNIT::"Save Data Exch. Blob Sample", CODEUNIT::"Exp. User Feedback Gen. Jnl.");

        DataExchLineDef.InsertRec(DataExchDef.Code, PaymentType, LibraryUtility.GenerateGUID(), 3);

        LibraryPaymentFormat.CreateDataExchColumnDef(DataExchColumnDef, DataExchDef.Code, DataExchLineDef.Code);

        LibraryPaymentFormat.CreateDataExchMapping(DataExchMapping, DataExchDef.Code, DataExchLineDef.Code,
          CODEUNIT::"Exp. Pre-Mapping Gen. Jnl.", CODEUNIT::"Exp. Mapping Gen. Jnl.", CODEUNIT::"Exp. Post-Mapping Gen. Jnl.");

        LibraryPaymentFormat.CreateDataExchFieldMapping(DataExchFieldMapping, DataExchDef.Code, DataExchLineDef.Code);

        LibraryPaymentFormat.CreateBankExportImportSetup(BankExportImportSetup, DataExchDef);

        exit(BankExportImportSetup.Code);
    end;

    local procedure DefinePaymentExportFormatForAmount(var DataExchMapping: Record "Data Exch. Mapping"; FileType: Option)
    var
        PaymentExportData: Record "Payment Export Data";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        LibraryPaymentExport.CreateSimpleDataExchDefWithMapping(DataExchMapping,
          DATABASE::"Payment Export Data", PaymentExportData.FieldNo(Amount));

        DataExchDef.Get(DataExchMapping."Data Exch. Def Code");
        DataExchDef.Validate("File Type", FileType);
        DataExchDef.Validate("Reading/Writing XMLport", XMLPORT::"Export Generic CSV");
        DataExchDef.Modify(true);

        DataExchLineDef.Get(DataExchMapping."Data Exch. Def Code", DataExchMapping."Data Exch. Line Def Code");
        DataExchLineDef.Validate("Column Count", 1);
        DataExchLineDef.Modify(true);
    end;

    local procedure UpdateDataExchColumnDefToUsePadding(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; ColumnNo: Integer; DataType: Option; DataFormat: Text; ColumnLength: Integer; PadCharacter: Text[1]; PadJustification: Option)
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        DataExchColumnDef.Get(DataExchDefCode, DataExchLineDefCode, ColumnNo);
        DataExchColumnDef.Validate("Data Type", DataType);
        DataExchColumnDef.Validate("Data Format", DataFormat);
        DataExchColumnDef.Validate(Length, ColumnLength);
        DataExchColumnDef.Validate("Text Padding Required", true);
        DataExchColumnDef.Validate("Pad Character", PadCharacter);
        DataExchColumnDef.Validate(Justification, PadJustification);
        DataExchColumnDef.Modify(true);
    end;

    local procedure CreateVendorLedgerEntry(var VendLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; Exported: Boolean; VendorCode: Code[20]; BankAccountCode: Code[20]; VendorBankAccountCode: Code[20]; VendorPaymentMethodCode: Code[10]; Currency: Record Currency)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        VendLedgerEntry.Init();
        VendLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendLedgerEntry, VendLedgerEntry.FieldNo("Entry No."));
        VendLedgerEntry."Vendor No." := VendorCode;
        VendLedgerEntry."Posting Date" := WorkDate();
        VendLedgerEntry."Document Type" := DocumentType;
        VendLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        VendLedgerEntry.Open := true;
        VendLedgerEntry."Due Date" := CalcDate('<1D>', VendLedgerEntry."Posting Date");
        VendLedgerEntry.Amount := -LibraryRandom.RandDecInRange(100, 1000, 2);
        VendLedgerEntry."Bal. Account Type" := VendLedgerEntry."Bal. Account Type"::"Bank Account";
        VendLedgerEntry."Bal. Account No." := BankAccountCode;
        VendLedgerEntry."Payment Method Code" := VendorPaymentMethodCode;
        VendLedgerEntry."Recipient Bank Account" := VendorBankAccountCode;
        VendLedgerEntry."Message to Recipient" := LibraryUtility.GenerateGUID();
        VendLedgerEntry."Exported to Payment File" := Exported;
        VendLedgerEntry."Currency Code" := Currency.Code;
        VendLedgerEntry."Amount (LCY)" := VendLedgerEntry.Amount * Currency."Currency Factor";
        VendLedgerEntry.Insert();
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry.Amount := VendLedgerEntry.Amount;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendLedgerEntry."Entry No.";
        DetailedVendorLedgEntry."Ledger Entry Amount" := true;
        DetailedVendorLedgEntry."Posting Date" := VendLedgerEntry."Date Filter";
        DetailedVendorLedgEntry.Insert();
    end;

    local procedure CreateExportGenJournalBatch(var GenJnlBatch: Record "Gen. Journal Batch"; BalAccountNo: Code[20])
    begin
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, LibraryPaymentExport.SelectPaymentJournalTemplate());
        GenJnlBatch.Validate("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"Bank Account");
        GenJnlBatch.Validate("Bal. Account No.", BalAccountNo);
        GenJnlBatch.Validate("Allow Payment Export", true);
        GenJnlBatch.Modify(true);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure GetFilePath(BankAccountCode: Code[20]): Text
    var
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DataExch: Record "Data Exch.";
    begin
        BankAccount.Get(BankAccountCode);
        BankAccount.TestField("Payment Export Format");
        BankExportImportSetup.Get(BankAccount."Payment Export Format");
        BankExportImportSetup.TestField("Data Exch. Def. Code");
        DataExch.SetRange("Data Exch. Def Code", BankExportImportSetup."Data Exch. Def. Code");
        DataExch.FindFirst();
        exit(DataExch."File Name");
    end;

    local procedure CreateCurrencyWithFactor(var Currency: Record Currency)
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithRandomExchRates());
        Currency.Validate("Currency Factor", LibraryRandom.RandDecInRange(5, 10, 2));
        Currency.Modify(true);
    end;

    local procedure UpdateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10])
    begin
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate(Amount, GenJournalLine.Amount);
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine.Modify(true);
    end;
}

