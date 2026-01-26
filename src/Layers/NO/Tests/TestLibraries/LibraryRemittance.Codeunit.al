codeunit 143009 "Library - Remittance"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        SuggestPaymentsMsg: Label 'You have created suggested vendor payment lines for all currencies.';

    [Scope('OnPrem')]
    procedure SetupDomesticRemittancePayment(PaymentSystem: Option; var RemittanceAgreement: Record "Remittance Agreement"; var RemittanceAccount: Record "Remittance Account"; var Vendor: Record Vendor; var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateRemittanceAgreement(RemittanceAgreement, PaymentSystem);
        CreateDomesticRemittanceAccount(RemittanceAgreement.Code, RemittanceAccount);

        CreateVendorSetupForRemittance(Vendor, RemittanceAccount, false);
        // Following values are added to export file. The don't have any special requirement, but
        // the should be different to make sure that the values are written in the right places.
        // E.g. just putting Vendor.Code in each field doesn't work.
        Vendor.Validate("Our Account No.", '123456');
        Vendor.Modify(true);

        CreatePaymentGenJournalBatch(GenJournalBatch, false);
        CreateGenJournalLine(GenJournalLine, GenJournalBatch, Vendor, RemittanceAgreement, '');
    end;

    [Scope('OnPrem')]
    procedure SetupForeignRemittancePayment(PaymentSystem: Option; var RemittanceAgreement: Record "Remittance Agreement"; var RemittanceAccount: Record "Remittance Account"; var Vendor: Record Vendor; var GenJournalLine: Record "Gen. Journal Line"; IsRemittanceSepa: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorBankAccount: Record "Vendor Bank Account";
        CurrencyCode: Code[10];
    begin
        CreateRemittanceAgreement(RemittanceAgreement, PaymentSystem);

        if IsRemittanceSepa then
            CurrencyCode := 'EUR'
        else
            CurrencyCode := FindForeignCurrencyCode();

        CreateForeignRemittanceAccount(RemittanceAgreement.Code, RemittanceAccount, CurrencyCode, IsRemittanceSepa);
        CreateVendorSetupForRemittance(Vendor, RemittanceAccount, IsRemittanceSepa);

        // Following values are added to export file. The don't have any special requirement, but
        // the should be different to make sure that the values are written in the right places.
        // E.g. just putting Vendor.Code in each field doesn't work.
        Vendor.Validate(Address, '222 Reagan Drive');
        Vendor.Validate("Post Code", 'US-SC 27136');
        Vendor.Validate(City, 'Colombia');

        if IsRemittanceSepa then begin
            VendorBankAccount.Reset();
            VendorBankAccount.SetFilter("Vendor No.", Vendor."No.");
            VendorBankAccount.FindFirst();
            VendorBankAccount.Validate("Bank Account No.", '33445556675');
            VendorBankAccount.Modify(true);
        end;
        Vendor.Validate("Recipient Bank Account No.", '33445556675'); // Number following a certain format including checksum.

        Vendor.Validate("Our Account No.", '123456');
        Vendor.Validate("Own Vendor Recipient Ref.", true);
        Vendor.Validate("Payment Type Code Abroad", '14');
        Vendor.Validate("Specification (Norges Bank)", 'ICBC');
        Vendor.Validate(SWIFT, '11111111111');
        Vendor.Validate("Rcpt. Bank Country/Region Code", 'US');

        Vendor.Modify(true);

        CreatePaymentGenJournalBatch(GenJournalBatch, IsRemittanceSepa);
        CreateGenJournalLine(GenJournalLine, GenJournalBatch, Vendor, RemittanceAgreement, CurrencyCode);
    end;

    [Scope('OnPrem')]
    procedure GetLastPaymentOrderID(): Integer
    var
        RemittancePaymentOrder: Record "Remittance Payment Order";
    begin
        if RemittancePaymentOrder.FindLast() then
            exit(RemittancePaymentOrder.ID);
        exit(0);
    end;

    [Scope('OnPrem')]
    procedure GetGenJournalLinesFromWaitingJournal(PaymentOrderID: Integer; var TempGenJournalLine: Record "Gen. Journal Line" temporary)
    var
        WaitingJournal: Record "Waiting Journal";
    begin
        // Read the Payment Lines from the Waiting Journal and
        // pump them back into a temporary Gen. Journal Line table.
        // The original lines are deleted in the process.
        WaitingJournal.SetRange(Reference, PaymentOrderID);
        WaitingJournal.FindSet();
        repeat
            TempGenJournalLine.TransferFields(WaitingJournal);
            TempGenJournalLine.Insert();
        until WaitingJournal.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateRemittanceAgreement(var RemittanceAgreement: Record "Remittance Agreement"; PaymentSystem: Option)
    begin
        RemittanceAgreement.Init();
        RemittanceAgreement.Validate(Code,
          LibraryUtility.GenerateRandomCode(RemittanceAgreement.FieldNo(Code), DATABASE::"Remittance Agreement"));
        RemittanceAgreement.Validate(Description, Format(RemittanceAgreement."Payment System"::"DnB Telebank"));
        RemittanceAgreement.Validate("Payment System", PaymentSystem);
        RemittanceAgreement.Validate("Operator No.",
          LibraryUtility.GenerateRandomCode(RemittanceAgreement.FieldNo("Operator No."), DATABASE::"Remittance Agreement"));
        RemittanceAgreement.Validate("Company/Agreement No.",
          LibraryUtility.GenerateRandomCode(RemittanceAgreement.FieldNo("Company/Agreement No."), DATABASE::"Remittance Agreement"));
        RemittanceAgreement.Validate(Password, RemittanceAgreement.Code);
        RemittanceAgreement.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateForeignRemittanceAccount(AgreementCode: Code[10]; var RemittanceAccount: Record "Remittance Account"; CurrencyCode: Code[10]; IsRemittanceSepa: Boolean)
    var
        ChargeGLAccount: Record "G/L Account";
        RoundOffGLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
    begin
        RemittanceAccount.Init();
        RemittanceAccount.Validate(Code,
          LibraryUtility.GenerateRandomCode(RemittanceAccount.FieldNo(Code), DATABASE::"Remittance Account"));
        RemittanceAccount.Validate("Remittance Agreement Code", AgreementCode);
        RemittanceAccount.Validate(Type, RemittanceAccount.Type::Foreign);
        RemittanceAccount.Validate(Description, 'Foreign');
        RemittanceAccount.Validate("Bank Account No.", '53371255555'); // Number must follow certain rules and checksum.
        RemittanceAccount.Validate("Recipient ref. 1 - Invoice", 'PAYMENT OF INVOICE %3');
        RemittanceAccount.Validate("Currency Code", CurrencyCode);
        RemittanceAccount.Validate("Recipient Ref. Abroad", 'PAYMENT OF INVOICE %4');
        RemittanceAccount.Validate("Account Type", RemittanceAccount."Account Type"::"Bank account");
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Payment Export Format", FindRemittanceExportSetup(IsRemittanceSepa));
        BankAccount.Validate("Currency Code", CurrencyCode);
        if IsRemittanceSepa then begin
            BankAccount.Validate(IBAN, 'GB 80 RBOS 161732 41116737'); // just needs to be a valid IBAN to pass the checks
            BankAccount.Validate("Credit Transfer Msg. Nos.", LibraryERM.CreateNoSeriesCode());
        end;

        BankAccount.Modify(true);
        RemittanceAccount.Validate("Account No.", BankAccount."No.");
        LibraryERM.CreateGLAccount(ChargeGLAccount);
        RemittanceAccount.Validate("Charge Account No.", ChargeGLAccount."No.");
        LibraryERM.CreateGLAccount(RoundOffGLAccount);
        RemittanceAccount.Validate("Round off/Divergence Acc. No.", RoundOffGLAccount."No.");
        RemittanceAccount.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateDomesticRemittanceAccount(AgreementCode: Code[10]; var RemittanceAccount: Record "Remittance Account")
    begin
        RemittanceAccount.Init();
        RemittanceAccount.Validate(Code,
          LibraryUtility.GenerateRandomCode(RemittanceAccount.FieldNo(Code), DATABASE::"Remittance Account"));
        RemittanceAccount.Validate("Remittance Agreement Code", AgreementCode);
        RemittanceAccount.Validate(Type, RemittanceAccount.Type::Domestic);
        RemittanceAccount.Validate(Description, 'Domestic');
        RemittanceAccount.Validate("Bank Account No.", '79900503534'); // Number must follow certain rules and checksum.
        RemittanceAccount.Validate("Account Type", RemittanceAccount."Account Type"::"Bank account");
        RemittanceAccount.Validate("Account No.", FindBankAccount(false));

        RemittanceAccount.Validate("Recipient ref. 1 - Invoice", 'PAYMENT OF INVOICE %3');
        RemittanceAccount.Validate("Recipient Ref. Abroad", 'PAYMENT OF INVOICE %4');
        RemittanceAccount.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVendorSetupForRemittance(var Vendor: Record Vendor; RemittanceAccount: Record "Remittance Account"; IsRemittanceSepa: Boolean)
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Remittance := true;
        Vendor.Validate("Remittance Account Code", RemittanceAccount.Code);

        Vendor.Modify(true);

        if IsRemittanceSepa then begin
            LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
            VendorBankAccount.Validate(IBAN, 'BE68 5390 0754 7034');
            VendorBankAccount.Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; IsRemittanceSepa: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.FindFirst();

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", FindBankAccount(IsRemittanceSepa));
        GenJournalBatch.Validate("Allow Payment Export", true);
        GenJournalBatch.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; Vendor: Record Vendor; RemittanceAgreement: Record "Remittance Agreement"; CurrencyCode: Code[10])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", -LibraryRandom.RandDec(10, 2));

        if CurrencyCode <> '' then
            GenJournalLine."Currency Code" := CurrencyCode;
        GenJournalLine.Validate("Payment Type Code Abroad", Vendor."Payment Type Code Abroad");
        GenJournalLine.Validate("Payment Type Code Domestic", Vendor."Payment Type Code Domestic");
        GenJournalLine.Validate("Specification (Norges Bank)", Vendor."Specification (Norges Bank)");
        GenJournalLine.Validate("Posting Date", Today); // "Posting Date" compared "TODAY" in CU 15000001
        GenJournalLine.Validate("Remittance Agreement Code", RemittanceAgreement.Code);
        GenJournalLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateReturnFileSetupEntry(AgreementCode: Code[10]; FilePath: Text)
    var
        ReturnFileSetup: Record "Return File Setup";
    begin
        ReturnFileSetup.SetRange("Agreement Code", AgreementCode);
        ReturnFileSetup.DeleteAll(true);

        ReturnFileSetup.Init();
        ReturnFileSetup.Validate("Agreement Code", AgreementCode);
        ReturnFileSetup.Validate("Line No.", 10000);
        ReturnFileSetup.Validate("Return File Name", CopyStr(FilePath, 1, MaxStrLen(ReturnFileSetup."Return File Name")));
        ReturnFileSetup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure PostGenJournalLine(GenJournalLine: Record "Gen. Journal Line"): Code[10]
    begin
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);
        exit(GenJournalLine."Journal Batch Name");
    end;

    [Scope('OnPrem')]
    procedure FindBankAccount(IsRemittanceSepa: Boolean): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.FindFirst();
        BankAccount.Validate("Payment Export Format", FindRemittanceExportSetup(IsRemittanceSepa));
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    [Scope('OnPrem')]
    procedure FindForeignCurrencyCode(): Code[10]
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        Currency.SetFilter(Code, '<>%1', GeneralLedgerSetup."LCY Code");
        Currency.FindFirst();
        exit(Currency.Code);
    end;

    [Scope('OnPrem')]
    procedure FindRemittanceExportSetup(IsRemittanceSepa: Boolean): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        if IsRemittanceSepa then
            BankExportImportSetup.SetRange("Processing Codeunit ID", CODEUNIT::"SEPA CT-Export File")
        else
            BankExportImportSetup.SetRange("Processing Codeunit ID", CODEUNIT::"Export Remittance");
        BankExportImportSetup.FindFirst();
        exit(BankExportImportSetup.Code);
    end;

    [Scope('OnPrem')]
    procedure GetTempFileName(): Text
    var
        FileMgt: Codeunit "File Management";
    begin
        exit(FileMgt.ServerTempFileName('txt'));
    end;

    [Scope('OnPrem')]
    procedure ExecuteSuggestRemittancePayments(var LibraryVariableStorage: Codeunit "Library - Variable Storage"; RemittanceAccount: Record "Remittance Account"; Vendor: Record Vendor; var GenJournalLine: Record "Gen. Journal Line"; BatchName: Code[10])
    var
        GenJournalLine2: Record "Gen. Journal Line";
        SuggestRemittancePayments: Report "Suggest Remittance Payments";
        RemittanceTools: Codeunit "Remittance Tools";
        RecipientRef: Code[80];
    begin
        // Execute Suggest Remittance Payments
        GenJournalLine."Journal Batch Name" := BatchName;
        LibraryVariableStorage.Enqueue(RemittanceAccount.Code);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(SuggestPaymentsMsg);
        SuggestRemittancePayments.SetGenJnlLine(GenJournalLine);
        SuggestRemittancePayments.RunModal();

        // Verify
        GenJournalLine2.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine2.SetRange("Journal Batch Name", BatchName);
        GenJournalLine2.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine2.SetFilter(Amount, '<>0');
        Assert.AreEqual(1, GenJournalLine2.Count, 'Invalid number of payment lines.');
        Assert.IsTrue(GenJournalLine2.FindFirst(), 'Payment line not found.');
        Assert.AreEqual(GenJournalLine.Amount, -GenJournalLine2.Amount, 'Wrong amount');
        case RemittanceAccount.Type of
            RemittanceAccount.Type::Domestic:
                if not GenJournalLine2."Structured Payment" then begin
                    // Insert formatted text on unstructured payments
                    RecipientRef := RemittanceTools.FormatRecipientRef(RemittanceAccount, GenJournalLine2, 1);
                    Assert.AreEqual(GenJournalLine2."Recipient Ref. 1", RecipientRef, 'Recipient Ref. 1');
                    RecipientRef := RemittanceTools.FormatRecipientRef(RemittanceAccount, GenJournalLine2, 2);
                    Assert.AreEqual(GenJournalLine2."Recipient Ref. 2", RecipientRef, 'Recipient Ref. 2');
                    RecipientRef := RemittanceTools.FormatRecipientRef(RemittanceAccount, GenJournalLine2, 3);
                    Assert.AreEqual(GenJournalLine2."Recipient Ref. 3", RecipientRef, 'Recipient Ref. 3');
                end;
            RemittanceAccount.Type::Foreign:
                begin
                    RecipientRef := RemittanceTools.FormatRecipientRef(RemittanceAccount, GenJournalLine2, 0);
                    Assert.AreEqual(GenJournalLine2."Recipient Ref. Abroad", RecipientRef, 'Recipient Ref. Abroad');
                end;
        end;

        GenJournalLine.Copy(GenJournalLine2);
    end;

    [Scope('OnPrem')]
    procedure ExecuteRemittanceExportPaymentFile(var LibraryVariableStorage: Codeunit "Library - Variable Storage"; RemittanceAgreement: Record "Remittance Agreement"; RemittanceAccount: Record "Remittance Account"; Vendor: Record Vendor; var GenJournalLine: Record "Gen. Journal Line"; BatchName: Code[10]) FileName: Text
    begin
        // Setup
        ExecuteSuggestRemittancePayments(LibraryVariableStorage, RemittanceAccount, Vendor, GenJournalLine, BatchName);

        // Execute Export Payments
        LibraryVariableStorage.Enqueue(RemittanceAgreement.Code);
        FileName := GetTempFileName();
        LibraryVariableStorage.Enqueue(FileName);
        CODEUNIT.Run(CODEUNIT::"Export Payment File (Yes/No)", GenJournalLine);

        // Verify
        Assert.IsFalse(GenJournalLine.FindFirst(), 'Payment line found.');
    end;
}

