codeunit 143002 "Library - DTA"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        BankMgt: Codeunit BankMgt;
        TestOption: Option "ESR5/15","ESR9/16","ESR9/27","ESR+5/15","ESR+9/16","ESR+9/27","Post Payment Domestic","Bank Payment Domestic","Cash Outpayment Order Domestic","Post Payment Abroad","Bank Payment Abroad","SWIFT Payment Abroad","Cash Outpayment Order Abroad","None";

    [Scope('OnPrem')]
    procedure CreateDTASetup(var DTASetup: Record "DTA Setup"; CurrencyCode: Code[3]; Backup: Boolean)
    var
        GLAccount: Record "G/L Account";
        BankCode: Code[10];
    begin
        BankCode := LibraryUtility.GenerateRandomCode(DTASetup.FieldNo("Bank Code"), DATABASE::"DTA Setup");

        DTASetup.Init();
        DTASetup.Validate("Bank Code", BankCode);
        DTASetup.Validate("DTA/EZAG", DTASetup."DTA/EZAG"::DTA);

        DTASetup.Validate("DTA Customer ID", LibraryUtility.GenerateRandomText(5));
        DTASetup.Validate("DTA Sender ID", LibraryUtility.GenerateRandomText(5));
        DTASetup.Validate("DTA File Folder", 'C:\Windows\Temp\');
        // Cannot use TEMPORARYPATH due to field size.
        DTASetup.Validate("DTA Filename", LibraryUtility.GenerateGUID());
        DTASetup.Validate("DTA Main Bank", true);
        if CurrencyCode <> '' then
            DTASetup.Validate("DTA Currency Code", CurrencyCode);

        DTASetup.Validate("Bal. Account Type", DTASetup."Bal. Account Type"::"G/L Account");
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange("Source Currency Code", CurrencyCode);
        GLAccount.FindFirst();
        DTASetup.Validate("Bal. Account No.", GLAccount."No.");

        if Backup then begin
            DTASetup.Validate("Backup Copy", true);
            DTASetup.Validate("Backup Folder", TemporaryPath);
        end;

        DTASetup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateEZAGSetup(var DTASetup: Record "DTA Setup"; CurrencyCode: Code[10])
    var
        GLAccount: Record "G/L Account";
        BankMgt: Codeunit BankMgt;
        OutStream: OutStream;
        EZAGAcctPart1: Text[2];
        EZAGAcctPart2: Text[6];
        EZAGAcctNo: Text[11];
        CheckDigit: Code[1];
        BankCode: Code[10];
    begin
        BankCode := LibraryUtility.GenerateRandomCode(DTASetup.FieldNo("Bank Code"), DATABASE::"DTA Setup");

        DTASetup.Init();

        DTASetup.Validate("Bank Code", BankCode);
        DTASetup.Validate("DTA/EZAG", DTASetup."DTA/EZAG"::EZAG);
        // Generate a valid EZAG Acct. No.
        EZAGAcctPart1 := Format(LibraryRandom.RandIntInRange(10, 99));
        EZAGAcctPart2 := Format(LibraryRandom.RandIntInRange(100000, 999999));
        CheckDigit := BankMgt.CalcCheckDigit(EZAGAcctPart1 + EZAGAcctPart2);
        EZAGAcctNo := EZAGAcctPart1 + '-' + EZAGAcctPart2 + '-' + CheckDigit;

        DTASetup.Validate("EZAG Debit Account No.", EZAGAcctNo);
        DTASetup.Validate("EZAG Charges Account No.", EZAGAcctNo);

        DTASetup.Validate("Last EZAG Order No.", Format(LibraryRandom.RandIntInRange(10, 99)));
        DTASetup.Validate("EZAG Media ID", LibraryUtility.GenerateRandomCode(DTASetup.FieldNo("EZAG Media ID"), DATABASE::"DTA Setup"));

        if CurrencyCode <> '' then
            DTASetup.Validate("DTA Currency Code", CurrencyCode);

        DTASetup.Validate("Bal. Account Type", DTASetup."Bal. Account Type"::"G/L Account");
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange("Source Currency Code", CurrencyCode);
        GLAccount.FindFirst();

        DTASetup.Validate("Bal. Account No.", GLAccount."No.");
        // Generate a dummy blob for the post and bar code logos
        DTASetup."EZAG Post Logo".CreateOutStream(OutStream);
        OutStream.WriteText(LibraryUtility.GenerateRandomText(LibraryRandom.RandInt(1000)));
        DTASetup.Validate("EZAG Bar Code", DTASetup."EZAG Post Logo");

        DTASetup.Validate("EZAG File Folder", 'C:\Windows\Temp\');
        DTASetup.Validate("DTA Filename", LibraryUtility.GenerateGUID());

        DTASetup.Insert();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateTestGenJournalLines(var Vendor: Record Vendor; var VendorBankAccount: Record "Vendor Bank Account"; var GenJournalLineArray: array[3] of Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch"; GenJournalLineCount: Integer; GenJournalLineDates: array[3] of Date; GenJournalLineAmounts: array[3] of Decimal; PaymentMethod: Option; CurrencyCode: Code[3]; DebitBankNo: Code[20]; UsePaymentTerms: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        PaymentTerms: Record "Payment Terms";
        DateFormula10Days: DateFormula;
        I: Integer;
    begin
        if UsePaymentTerms then begin
            // Create Payment Terms
            LibraryERM.CreatePaymentTerms(PaymentTerms);
            Evaluate(DateFormula10Days, '<10D>');
            PaymentTerms.Validate("Due Date Calculation", DateFormula10Days);
            PaymentTerms.Modify(true);
        end;

        // Create Vendor/Bank
        CreateVendor(Vendor);
        if UsePaymentTerms then begin
            Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
            Vendor.Modify(true);
        end;

        CreateVendorBankAccount(VendorBankAccount, Vendor."No.", PaymentMethod, DebitBankNo);

        // Post Invoice
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Purchases, false);
        for I := 1 to GenJournalLineCount do
            CreateGeneralJournalLine(
              GenJournalLineArray[I], GenJournalBatch, GenJournalLineDates[I], Vendor."No.",
              GenJournalLineArray[I]."Document Type"::Invoice, GenJournalLineAmounts[I], VendorBankAccount.Code, PaymentMethod, CurrencyCode);

        LibraryERM.PostGeneralJnlLine(GenJournalLineArray[GenJournalLineCount]);

        // Create General Journal Batch for Payment.
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments, true);
    end;

    [Scope('OnPrem')]
    procedure CreateVendor(var Vendor: Record Vendor)
    var
        PostCode: Record "Post Code";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        PostCode.FindFirst();
        Vendor.Validate("Post Code", PostCode.Code);
        Vendor.Validate(Address, LibraryUtility.GenerateRandomText(10));
        Vendor.Validate(City, PostCode.City);
        Vendor.Modify(true);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; VendorNo: Code[20]; PaymentMethod: Option; DebitBankNo: Code[20])
    var
        BankDirectory: Record "Bank Directory";
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);

        // Some code are hard coded because checksum is needed for them
        case PaymentMethod of
            TestOption::"ESR5/15":
                begin
                    VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::ESR);
                    VendorBankAccount.Validate("ESR Type", VendorBankAccount."ESR Type"::"5/15");
                    VendorBankAccount.Validate("ESR Account No.", '70622');
                end;
            TestOption::"ESR9/16":
                begin
                    VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::ESR);
                    VendorBankAccount.Validate("ESR Type", VendorBankAccount."ESR Type"::"9/16");
                    VendorBankAccount.Validate("ESR Account No.", '01-011543-2');
                end;
            TestOption::"ESR9/27":
                begin
                    VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::ESR);
                    VendorBankAccount.Validate("ESR Type", VendorBankAccount."ESR Type"::"9/27");
                    VendorBankAccount.Validate("ESR Account No.", '01-009083-5');
                end;
            TestOption::"ESR+5/15":
                begin
                    VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::"ESR+");
                    VendorBankAccount.Validate("ESR Type", VendorBankAccount."ESR Type"::"5/15");
                    VendorBankAccount.Validate("ESR Account No.", '10304');
                end;
            TestOption::"ESR+9/16":
                begin
                    VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::"ESR+");
                    VendorBankAccount.Validate("ESR Type", VendorBankAccount."ESR Type"::"9/16");
                    VendorBankAccount.Validate("ESR Account No.", '01-018200-4');
                end;
            TestOption::"ESR+9/27":
                begin
                    VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::"ESR+");
                    VendorBankAccount.Validate("ESR Type", VendorBankAccount."ESR Type"::"9/27");
                    VendorBankAccount.Validate("ESR Account No.", '01-001760-2');
                end;
            TestOption::"Post Payment Domestic":
                begin
                    VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::"Post Payment Domestic");
                    VendorBankAccount.Validate("Giro Account No.", '60-8000-1');
                end;
            TestOption::"Bank Payment Domestic":
                begin
                    VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::"Bank Payment Domestic");
                    VendorBankAccount.Validate("Bank Account No.", Format(LibraryRandom.RandIntInRange(100000, 999999)));
                    BankDirectory.Next(LibraryRandom.RandInt(BankDirectory.Count()));
                    VendorBankAccount.Validate("Clearing No.", BankDirectory."Clearing No.");
                    VendorBankAccount.Validate(IBAN, 'CH9300762011623852957');
                end;
            TestOption::"Cash Outpayment Order Domestic":
                VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::"Cash Outpayment Order Domestic");
            TestOption::"Post Payment Abroad":
                begin
                    VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::"Post Payment Abroad");
                    VendorBankAccount.Validate("Bank Account No.", Format(LibraryRandom.RandIntInRange(100000, 999999)));
                    VendorBankAccount.Validate("Country/Region Code", 'DE');
                end;
            TestOption::"Bank Payment Abroad":
                begin
                    VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::"Bank Payment Abroad");
                    VendorBankAccount.Validate(IBAN, 'CH9300762011623852957');
                    VendorBankAccount.Validate("Country/Region Code", 'DE');
                end;
            TestOption::"SWIFT Payment Abroad":
                begin
                    VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::"SWIFT Payment Abroad");
                    VendorBankAccount.Validate("SWIFT Code", 'DBAKKK');
                    VendorBankAccount.Validate(IBAN, 'DE9300762011623852957');
                    VendorBankAccount.Validate("Bank Account No.", Format(LibraryRandom.RandIntInRange(100000, 999999)));
                    VendorBankAccount.Validate("Country/Region Code", 'DE');
                    VendorBankAccount.Validate(Name, LibraryUtility.GenerateRandomText(5));
                end;
            TestOption::"Cash Outpayment Order Abroad":
                begin
                    VendorBankAccount.Validate("Payment Form", VendorBankAccount."Payment Form"::"Cash Outpayment Order Abroad");
                    VendorBankAccount.Validate("Country/Region Code", 'DE');
                end;
        end;

        VendorBankAccount.Validate("Balance Account No.", CreateGLAccount());
        if DebitBankNo <> '' then
            VendorBankAccount.Validate("Debit Bank", DebitBankNo);

        VendorBankAccount.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Enum "Gen. Journal Document Type"; CreateNoSeries: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, Type);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        if CreateNoSeries then begin
            LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
            LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, LibraryUtility.GenerateGUID(), '');
            GenJournalBatch.Validate("No. Series", NoSeries.Code);
            GenJournalBatch.Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTestPurchaseOrder(var Vendor: Record Vendor; var VendorBankAccount: Record "Vendor Bank Account"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var GenJournalBatch: Record "Gen. Journal Batch"; Amount: Decimal; Date: Date; PaymentMethod: Option; DebitBankNo: Code[20]; IsDiscounted: Boolean; CreateBankAccount: Boolean; PostPurchaseOrder: Boolean; InvoicePurchaseOrder: Boolean; GenerateESRISRCodingLine: Boolean)
    var
        Item: Record Item;
        GenJournalTemplate: Record "Gen. Journal Template";
        ESRISRCodingLine: Text[70];
        UpdateAmount: Boolean;
    begin
        CreateVendor(Vendor);
        if CreateBankAccount then
            CreateVendorBankAccount(VendorBankAccount, Vendor."No.", PaymentMethod, DebitBankNo);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Expected Receipt Date", Date);
        PurchaseHeader.Validate("Due Date", Date);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateRandomText(10));
        if IsDiscounted then
            PurchaseHeader.Validate("Payment Discount %", LibraryRandom.RandInt(100));
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);

        if PaymentMethod <> TestOption::None then begin
            if GenerateESRISRCodingLine then begin
                GetEntityESRISRCodingLine(ESRISRCodingLine, UpdateAmount, PaymentMethod, PurchaseLine."Amount Including VAT");
                PurchaseHeader.Validate("ESR/ISR Coding Line", ESRISRCodingLine);
            end else
                PurchaseHeader.Validate("Reference No.", '112123917450010481291000004');

            PurchaseHeader.Validate("Bank Code", VendorBankAccount.Code);
            PurchaseHeader.Modify(true);
        end;

        if PostPurchaseOrder then begin
            // Post Puchase Order after creating it.
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, InvoicePurchaseOrder);
            // Create General Journal Batch for Payment.
            CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments, true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; LineAmount: Decimal; VendorBankAccountNo: Code[20]; PaymentMethod: Option; CurrencyCode: Code[3])
    var
        ESRISRCodingLine: Text[70];
        UpdateAmount: Boolean;
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Vendor, VendorNo, GenJournalLine."Bal. Account Type"::"G/L Account", CreateGLAccount(), LineAmount);

        GenJournalLine.Validate("Document No.", GenJournalBatch.Name + Format(GenJournalLine."Line No."));
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Recipient Bank Account", VendorBankAccountNo);
        if CurrencyCode <> '' then
            GenJournalLine.Validate("Currency Code", CurrencyCode);

        GetEntityESRISRCodingLine(ESRISRCodingLine, UpdateAmount, PaymentMethod, LineAmount);
        GenJournalLine.Validate("ESR/ISR Coding Line", ESRISRCodingLine);
        if UpdateAmount then
            GenJournalLine.Validate(Amount, LineAmount);
        GenJournalLine.Modify(true);
    end;

    local procedure GetEntityESRISRCodingLine(var ESRISRCodingLine: Text; var UpdateAmount: Boolean; PaymentMethod: Option; Amount: Decimal)
    var
        ESRChecksum: Text[2];
        ESRAccountNo: Text[30];
        ESRReferenceNo: Text[30];
        ESRFormattedAmount: Text[30];
    begin
        UpdateAmount := false;
        ESRISRCodingLine := '';

        case PaymentMethod of
            TestOption::"ESR5/15":
                begin
                    ESRAccountNo := '70622';
                    ESRReferenceNo := '700675176944991';
                    ESRChecksum := Modulo11Helper(Amount, ESRReferenceNo, ESRAccountNo);
                    ESRISRCodingLine := '<' + ESRChecksum + '00010000' + DelStr(Format(Abs(100 * Amount)), 3, 1) + '> ' +
                      ESRReferenceNo + '+ ' + ESRAccountNo + '>';
                end;
            TestOption::"ESR9/16":
                begin
                    ESRAccountNo := '010115432';
                    ESRReferenceNo := '4097160015679962';
                    ESRFormattedAmount := '0100000' + DelStr(Format(Abs(100 * Amount)), 3, 1);
                    ESRISRCodingLine := ESRFormattedAmount + BankMgt.CalcCheckDigit(ESRFormattedAmount) + '>' +
                      ESRReferenceNo + '+ ' + ESRAccountNo + '>';
                end;
            TestOption::"ESR9/27":
                begin
                    ESRAccountNo := '010090835';
                    ESRReferenceNo := '330002000000000097010075184';
                    ESRFormattedAmount := '0100000' + DelStr(Format(Abs(100 * Amount)), 3, 1);
                    ESRISRCodingLine := ESRFormattedAmount + BankMgt.CalcCheckDigit(ESRFormattedAmount) + '> ' +
                      ESRReferenceNo + '+ ' + ESRAccountNo + '>';
                end;
            TestOption::"ESR+5/15":
                begin
                    ESRAccountNo := '10304';
                    ESRReferenceNo := '110112111111000';
                    ESRISRCodingLine := ESRReferenceNo + '+ ' + ESRAccountNo + '>';
                    UpdateAmount := true;
                end;
            TestOption::"ESR+9/16":
                begin
                    ESRAccountNo := '010182004';
                    ESRReferenceNo := '0066682402012046';
                    ESRISRCodingLine := '042>' + ESRReferenceNo + '+ ' + ESRAccountNo + '>';
                    UpdateAmount := true;
                end;
            TestOption::"ESR+9/27":
                begin
                    ESRAccountNo := '010017602';
                    ESRReferenceNo := '040471000000000000000020074';
                    ESRISRCodingLine := '042>' + ESRReferenceNo + '+ ' + ESRAccountNo + '>';
                    UpdateAmount := true;
                end;
        end;
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure Modulo11Helper(Amt: Decimal; ESRReferenceNo: Text; ESRAccountNo: Text) Checksum: Text[2]
    var
        AmtTxt: Text;
        Mod11Input: Text;
    begin
        AmtTxt := Format(Amt * 100, 0, '<Integer>');  // Amount on 9 digits, leading 0
        AmtTxt := CopyStr('000000000', 1, 9 - StrLen(AmtTxt)) + AmtTxt;

        Mod11Input := '0001' + AmtTxt + ESRReferenceNo + ESRAccountNo;
        Checksum := Format(StrCheckSum(Mod11Input, '432765432765432765432765432765432', 11));

        if StrLen(Checksum) = 1 then
            Checksum := '0' + Checksum;  // leading 0
        exit(Checksum);
    end;
}
