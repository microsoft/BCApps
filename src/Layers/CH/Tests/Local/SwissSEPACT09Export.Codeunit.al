codeunit 144354 "Swiss SEPA CT 09 Export"
{
    // // [FEATURE] [SEPA] [Credit Transfer] [Swiss]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryXMLRead: Codeunit "Library - XML Read";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        PaymentFormGbl: Option ESR,"ESR+","Post Payment Domestic","Bank Payment Domestic","Cash Outpayment Order Domestic","Post Payment Abroad","Bank Payment Abroad","SWIFT Payment Abroad","Cash Outpayment Order Abroad";
        PaymentTypeGbl: Option " ","1","2.1","2.2","3","4","5","6";
        ExportHasErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
        FieldBlankErr: Label 'The %1 field must be filled.', Comment = '%1= field name. Example: The Name field must be filled.';
        FieldKeyBlankErr: Label '%1 %2 must have a value in %3.', Comment = '%1=table name, %2=key field value, %3=field name. Example: Customer 10000 must have a value in Name.';
        UnknownSwissPaymentTypeErr: Label 'Unknown Swiss SEPA CT export payment type.';
        ReferenceNumberIsDefinedErr: Label 'For vendor %1 and document %2, a reference number is defined. \The document type must be "Invoice".';
        MessageToRecipientMsg: Label 'Payment of %1 %2 to vendor %3', Comment = '%1 document type, %2 Document No., %3 Vendor No.';
        GetPaymentTypeErr: Label 'Wrong result of GetPaymentType';
        IBANTypeErr: Label 'The IBAN type on the recipient bank account must match the payment reference type.';
        QRIBANErr: Label 'The recipient bank account has an IBAN that is of type QR-IBAN. This type requires that the recipient bank account has a SEPA CT export payment type that is type 3.';
        QRRefErr: Label 'The payment reference is a QR reference. This type requires that the recipient bank account has a SEPA CT export payment type that is type 3.';

    [Test]
    [Scope('OnPrem')]
    procedure SwissDemodataIncludesSwissSEPACTExpImpSetup()
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 220991] There is a Swiss SEPA CT "Bank Export/Import Setup" in demodata
        Assert.AreEqual('SEPACTSWISS 00100109', FindSwissSEPACTBankExpImpCode(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CHMgt_IsDomesticCurrency()
    var
        CHMgt: Codeunit CHMgt;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 220991] COD 11503 "CHMgt".IsDomesticCurrency() returns TRUE only in case of "","CHF","EUR" currency codes

        Assert.IsTrue(CHMgt.IsDomesticCurrency(''), '');
        Assert.IsTrue(CHMgt.IsDomesticCurrency('CHF'), '');
        Assert.IsTrue(CHMgt.IsDomesticCurrency(GetEURCurrency()), '');
        Assert.IsFalse(CHMgt.IsDomesticCurrency(GetForeignCurrency()), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CHMgt_IsDomesticIBAN()
    var
        CHMgt: Codeunit CHMgt;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 220991] COD 11503 "CHMgt".IsDomesticIBAN() returns TRUE only in case of "CH..." or "LI..." IBAN codes
        Assert.IsTrue(CHMgt.IsDomesticIBAN('CH12345'), '');
        Assert.IsTrue(CHMgt.IsDomesticIBAN('LI12345'), '');
        Assert.IsFalse(CHMgt.IsDomesticIBAN('DE12345'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CHMgt_IsSwissSEPACTExport_Negative()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CHMgt: Codeunit CHMgt;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 220991] COD 11503 "CHMgt".IsSwissSEPACTExport() returns FALSE in case of W1 SEPA CT Bank Export\Import Setup
        GenJournalLine.Init();
        Assert.IsFalse(CHMgt.IsSwissSEPACTExport(GenJournalLine), '');

        InitGenJournalLine(GenJournalLine, FindW1SEPACTBankExpImpCode());
        Assert.IsFalse(CHMgt.IsSwissSEPACTExport(GenJournalLine), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CHMgt_IsSwissSEPACTExport_Positive()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CHMgt: Codeunit CHMgt;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 220991] COD 11503 "CHMgt".IsSwissSEPACTExport() returns TRUE in case of Swiss SEPA CT Bank Export\Import Setup
        InitGenJournalLine(GenJournalLine, FindSwissSEPACTBankExpImpCode());
        Assert.IsTrue(CHMgt.IsSwissSEPACTExport(GenJournalLine), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CHMgt_ReplaceXMLNamespaceCaption()
    var
        TempBlob: Codeunit "Temp Blob";
        CHMgt: Codeunit CHMgt;
        TypeHelper: Codeunit "Type Helper";
        OutStream: OutStream;
        InStream: InStream;
        OldCaption: Text;
        NewCaption: Text;
        CaptionTemplate: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 220991] COD 11503 "CHMgt".ReplaceXMLNamespaceCaption() replaces XML namespace's string
        CaptionTemplate := '<Document xmlns="%1">';
        OldCaption := LibraryUtility.GenerateRandomXMLText(LibraryRandom.RandIntInRange(1000, 2000));
        NewCaption := LibraryUtility.GenerateRandomXMLText(LibraryRandom.RandIntInRange(1000, 2000));

        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(StrSubstNo(CaptionTemplate, OldCaption));
        CHMgt.ReplaceXMLNamespaceCaption(TempBlob, OldCaption, NewCaption);

        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        Assert.AreEqual(
          StrSubstNo(CaptionTemplate, NewCaption), TypeHelper.ReadAsTextWithSeparator(InStream, ''), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportData_SetVendorAsRecipient_PaymentType1()
    var
        PaymentExportData: Record "Payment Export Data";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 220991] TAB 1226 "Payment Export Data".SetVendorAsRecipient() in case of "Payment Type" = "1" for Payment Form = ESR
        Vendor.Get(CreateVendorWithBankAccount_ESR());
        VendorBankAccount.Get(Vendor."No.", Vendor."Preferred Bank Account Code");

        PaymentExportData.Init();

        PaymentExportData.SetSwissExport(true);
        PaymentExportData.SetVendorAsRecipient(Vendor, VendorBankAccount);

        VerifyPaymentExportDataFields(
          PaymentExportData, PaymentExportData."Swiss Payment Form"::ESR, PaymentExportData."Swiss Payment Type"::"1",
          '', '', DelChr(VendorBankAccount."ESR Account No.", '=', '-'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportData_SetVendorAsRecipient_PaymentType1ESRPlus()
    var
        PaymentExportData: Record "Payment Export Data";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 225490] TAB 1226 "Payment Export Data".SetVendorAsRecipient() in case of "Payment Type" = "1" for Payment Form = ESR+
        Vendor.Get(CreateVendorWithBankAccount_ESRPlus());
        VendorBankAccount.Get(Vendor."No.", Vendor."Preferred Bank Account Code");

        PaymentExportData.Init();

        PaymentExportData.SetSwissExport(true);
        PaymentExportData.SetVendorAsRecipient(Vendor, VendorBankAccount);

        VerifyPaymentExportDataFields(
          PaymentExportData, PaymentExportData."Swiss Payment Form"::"ESR+", PaymentExportData."Swiss Payment Type"::"1",
          '', '', DelChr(VendorBankAccount."ESR Account No.", '=', '-'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportData_SetVendorAsRecipient_PaymentType21()
    var
        PaymentExportData: Record "Payment Export Data";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 220991] TAB 1226 "Payment Export Data".SetVendorAsRecipient() in case of "Payment Type" = "2.1"
        // [SCENARIO 426542] "Recipient Acc. No." of Payment Export Data record when Giro Account No. = "25-009034-2" and "Payment Type" = "2.1".

        // [GIVEN] Vendor with Preferred Bank Account which has Giro Account No. = "25-009034-2" and Payment Type = "2.1".
        Vendor.Get(CreateVendorWithBankAccount_GiroPost());
        VendorBankAccount.Get(Vendor."No.", Vendor."Preferred Bank Account Code");

        // [WHEN] Run SetVendorAsRecipient function of Payment Export Data table.
        PaymentExportData.Init();
        PaymentExportData.SetSwissExport(true);
        PaymentExportData.SetVendorAsRecipient(Vendor, VendorBankAccount);

        // [THEN] PaymentExportData."Recipient Acc. No." was set to "250090342", i.e. dashes were removed when Giro Account No. was copied.
        VerifyPaymentExportDataFields(
            PaymentExportData, PaymentExportData."Swiss Payment Form"::"Post Payment Domestic",
            PaymentExportData."Swiss Payment Type"::"2.1", '', '', DelChr(VendorBankAccount."Giro Account No.", '=', '-'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportData_SetVendorAsRecipient_PaymentType22()
    var
        PaymentExportData: Record "Payment Export Data";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 220991] TAB 1226 "Payment Export Data".SetVendorAsRecipient() in case of "Payment Type" = "2.2"
        Vendor.Get(CreateVendorWithBankAccount_Clearing());
        VendorBankAccount.Get(Vendor."No.", Vendor."Preferred Bank Account Code");

        PaymentExportData.Init();

        PaymentExportData.SetSwissExport(true);
        PaymentExportData.SetVendorAsRecipient(Vendor, VendorBankAccount);

        VerifyPaymentExportDataFields(
          PaymentExportData, PaymentExportData."Swiss Payment Form"::"Bank Payment Domestic", PaymentExportData."Swiss Payment Type"::"2.2",
          VendorBankAccount."Clearing No.", VendorBankAccount.IBAN, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportData_SetVendorAsRecipient_RemoveSpacesFromIBAN()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        PaymentExportData: Record "Payment Export Data";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 234977] When function SetVendorAsRecipient from "Payment Export Data" table is run for Payment Type "2.2" then text 'IBAN', all spaces and colons are removed from IBAN stored in "Recipient Bank Acc. No.".
        Initialize();

        // [GIVEN] Vendor Bank Account with payment type 2.2 with IBAN = 'CH 3808:8881: 2345 :6789 :: 012 :IBAN'
        Vendor.Get(CreateVendorWithBankAccount_Clearing());
        VendorBankAccount.Get(Vendor."No.", Vendor."Preferred Bank Account Code");
        VendorBankAccount.IBAN := 'CH 3808:8881: 2345 :6789 :: 012 :IBAN';
        VendorBankAccount.Modify(true);

        // [WHEN] Set Vendor as Recipient in Payment Export Data table
        PaymentExportData.Init();
        PaymentExportData.SetSwissExport(true);
        PaymentExportData.SetVendorAsRecipient(Vendor, VendorBankAccount);

        // [THEN] IBAN = 'CH3808888123456789012'
        PaymentExportData.TestField("Recipient Bank Acc. No.", 'CH3808888123456789012');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportData_SetVendorAsRecipient_PaymentType3()
    var
        PaymentExportData: Record "Payment Export Data";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 220991] TAB 1226 "Payment Export Data".SetVendorAsRecipient() in case of "Payment Type" = "3"
        Vendor.Get(CreateVendorWithBankAccount_DomesticSWIFT());
        VendorBankAccount.Get(Vendor."No.", Vendor."Preferred Bank Account Code");

        PaymentExportData.Init();

        PaymentExportData.SetSwissExport(true);
        PaymentExportData.SetVendorAsRecipient(Vendor, VendorBankAccount);

        VerifyPaymentExportDataFields(
          PaymentExportData, PaymentExportData."Swiss Payment Form"::"Bank Payment Domestic", PaymentExportData."Swiss Payment Type"::"3",
          VendorBankAccount."SWIFT Code", VendorBankAccount.IBAN, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportData_SetVendorAsRecipient_PaymentType4()
    var
        PaymentExportData: Record "Payment Export Data";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 220991] TAB 1226 "Payment Export Data".SetVendorAsRecipient() in case of "Payment Type" = "4"
        Vendor.Get(CreateVendorWithBankAccount_DomesticSWIFT());
        VendorBankAccount.Get(Vendor."No.", Vendor."Preferred Bank Account Code");

        PaymentExportData.Init();

        PaymentExportData.SetSwissExport(true);
        PaymentExportData."Currency Code" := GetForeignCurrency();
        PaymentExportData.SetVendorAsRecipient(Vendor, VendorBankAccount);

        VerifyPaymentExportDataFields(
          PaymentExportData, PaymentExportData."Swiss Payment Form"::"Bank Payment Domestic", PaymentExportData."Swiss Payment Type"::"4",
          VendorBankAccount."SWIFT Code", VendorBankAccount.IBAN, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportData_SetVendorAsRecipient_PaymentType5()
    var
        PaymentExportData: Record "Payment Export Data";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 220991] TAB 1226 "Payment Export Data".SetVendorAsRecipient() in case of "Payment Type" = "5"
        CreateVendorWithBankAccount_AbroadSEPA(VendorBankAccount);
        Vendor.Get(VendorBankAccount."Vendor No.");

        PaymentExportData.Init();

        PaymentExportData.SetSwissExport(true);
        PaymentExportData."Currency Code" := GetEURCurrency();
        PaymentExportData.SetVendorAsRecipient(Vendor, VendorBankAccount);

        VerifyPaymentExportDataFields(
          PaymentExportData, PaymentExportData."Swiss Payment Form"::"Post Payment Abroad", PaymentExportData."Swiss Payment Type"::"5",
          VendorBankAccount."SWIFT Code", VendorBankAccount.IBAN, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportData_SetVendorAsRecipient_PaymentType6IBANAndSWIFT()
    var
        PaymentExportData: Record "Payment Export Data";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 220991] TAB 1226 "Payment Export Data".SetVendorAsRecipient() in case of "Payment Type" = "6" for pair IBAN + SWIFT
        Vendor.Get(CreateVendorWithBankAccount_Abroad());
        VendorBankAccount.Get(Vendor."No.", Vendor."Preferred Bank Account Code");

        PaymentExportData.Init();

        PaymentExportData.SetSwissExport(true);
        PaymentExportData."Currency Code" := GetForeignCurrency();
        PaymentExportData.SetVendorAsRecipient(Vendor, VendorBankAccount);

        VerifyPaymentExportDataFields(
          PaymentExportData, PaymentExportData."Swiss Payment Form"::"Bank Payment Abroad", PaymentExportData."Swiss Payment Type"::"6",
          VendorBankAccount."SWIFT Code", VendorBankAccount.IBAN, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportData_SetVendorAsRecipient_PaymentType6IBANAndPstlAddr()
    var
        PaymentExportData: Record "Payment Export Data";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 225521] TAB 1226 "Payment Export Data".SetVendorAsRecipient() in case of "Payment Type" = "6" for pair IBAN and Postal Address
        CreateVendorWithBankAccount_AbroadWithIBANAndPstlAddr(VendorBankAccount);
        Vendor.Get(VendorBankAccount."Vendor No.");

        PaymentExportData.Init();

        PaymentExportData.SetSwissExport(true);
        PaymentExportData."Currency Code" := GetForeignCurrency();
        PaymentExportData.SetVendorAsRecipient(Vendor, VendorBankAccount);

        VerifyPaymentExportDataFields(
          PaymentExportData, PaymentExportData."Swiss Payment Form"::"Bank Payment Abroad", PaymentExportData."Swiss Payment Type"::"6",
          VendorBankAccount."SWIFT Code", VendorBankAccount.IBAN, '');
        VerifyPaymentExportDataAddrFields(
          PaymentExportData, VendorBankAccount.Name, VendorBankAccount.Address,
          VendorBankAccount."Post Code", VendorBankAccount."Country/Region Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportData_SetVendorAsRecipient_PaymentType6BankAccAndSWIFT()
    var
        PaymentExportData: Record "Payment Export Data";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 225521] TAB 1226 "Payment Export Data".SetVendorAsRecipient() in case of "Payment Type" = "6" for pair Bank Account No and SWIFT
        CreateVendorWithBankAccount_AbroadWithBankAccNoAndSWIFT(VendorBankAccount);
        Vendor.Get(VendorBankAccount."Vendor No.");

        PaymentExportData.Init();

        PaymentExportData.SetSwissExport(true);
        PaymentExportData."Currency Code" := GetForeignCurrency();
        PaymentExportData.SetVendorAsRecipient(Vendor, VendorBankAccount);

        VerifyPaymentExportDataFields(
          PaymentExportData, PaymentExportData."Swiss Payment Form"::"Bank Payment Abroad", PaymentExportData."Swiss Payment Type"::"6",
          VendorBankAccount."SWIFT Code", '', VendorBankAccount."Bank Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportData_SetVendorAsRecipient_PaymentType6BankAccAndPstlAddr()
    var
        PaymentExportData: Record "Payment Export Data";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 225521] TAB 1226 "Payment Export Data".SetVendorAsRecipient() in case of "Payment Type" = "6" for pair Bank Account No and Postal Address
        CreateVendorWithBankAccount_AbroadWithBankAccNoAndPstlAddr(VendorBankAccount);
        Vendor.Get(VendorBankAccount."Vendor No.");

        PaymentExportData.Init();

        PaymentExportData.SetSwissExport(true);
        PaymentExportData."Currency Code" := GetForeignCurrency();
        PaymentExportData.SetVendorAsRecipient(Vendor, VendorBankAccount);

        VerifyPaymentExportDataFields(
          PaymentExportData, PaymentExportData."Swiss Payment Form"::"Bank Payment Abroad", PaymentExportData."Swiss Payment Type"::"6",
          VendorBankAccount."SWIFT Code", '', VendorBankAccount."Bank Account No.");
        VerifyPaymentExportDataAddrFields(
          PaymentExportData, VendorBankAccount.Name, VendorBankAccount.Address,
          VendorBankAccount."Post Code", VendorBankAccount."Country/Region Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorBankAccount_GetBankAccountNo()
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 220991] TAB 288 "Vendor Bank Account".GetBankAccountNo() returns correct value
        VendorBankAccount.Init();
        VendorBankAccount."SWIFT Code" := LibraryUtility.GenerateGUID();
        VendorBankAccount."ESR Account No." := LibraryUtility.GenerateGUID();
        VendorBankAccount."Giro Account No." := LibraryUtility.GenerateGUID();
        VendorBankAccount."Clearing No." := '12345';
        VendorBankAccount.IBAN := LibraryUtility.GenerateGUID();
        VendorBankAccount."Bank Identifier Code" := LibraryUtility.GenerateGUID();
        VendorBankAccount."Bank Account No." := LibraryUtility.GenerateGUID();

        VendorBankAccount."Payment Form" := VendorBankAccount."Payment Form"::ESR;
        Assert.AreEqual(VendorBankAccount."ESR Account No.", VendorBankAccount.GetBankAccountNo(), '');

        VendorBankAccount."Payment Form" := VendorBankAccount."Payment Form"::"Post Payment Domestic";
        Assert.AreEqual(VendorBankAccount."Giro Account No.", VendorBankAccount.GetBankAccountNo(), '');

        VendorBankAccount."Payment Form" := VendorBankAccount."Payment Form"::"Bank Payment Domestic";
        Assert.AreEqual(VendorBankAccount."Clearing No.", VendorBankAccount.GetBankAccountNo(), '');

        VendorBankAccount."Payment Form" := VendorBankAccount."Payment Form"::"Post Payment Abroad";
        Assert.AreEqual(VendorBankAccount.IBAN, VendorBankAccount.GetBankAccountNo(), '');

        VendorBankAccount."Payment Form" := VendorBankAccount."Payment Form"::"Bank Payment Abroad";
        Assert.AreEqual(VendorBankAccount.IBAN, VendorBankAccount.GetBankAccountNo(), '');

        VendorBankAccount.IBAN := '';
        Assert.AreEqual(VendorBankAccount."Bank Account No.", VendorBankAccount.GetBankAccountNo(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorBankAccountCard_SWIFTCode()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        VendorBankAccountCard: TestPage "Vendor Bank Account Card";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 220991] PAG 425 "Vendor Bank Account Card"."SWIFT Code" field is enabled in case of "Payment Form" = Post\Bank Payment Domestic\Abroad
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, LibraryPurchase.CreateVendorNo());
        VendorBankAccountCard.OpenEdit();
        VendorBankAccountCard.GotoRecord(VendorBankAccount);
        for VendorBankAccount."Payment Form" := VendorBankAccount."Payment Form"::ESR to VendorBankAccount."Payment Form"::"Cash Outpayment Order Abroad" do begin
            VendorBankAccountCard."Payment Form".SetValue(VendorBankAccount."Payment Form");
            if VendorBankAccount."Payment Form" in [VendorBankAccount."Payment Form"::"Post Payment Domestic", VendorBankAccount."Payment Form"::"Bank Payment Domestic",
                                  VendorBankAccount."Payment Form"::"Post Payment Abroad", VendorBankAccount."Payment Form"::"Bank Payment Abroad",
                                  VendorBankAccount."Payment Form"::"SWIFT Payment Abroad"]
            then
                Assert.IsTrue(VendorBankAccountCard."SWIFT Code".Enabled(), '')
            else
                Assert.IsFalse(VendorBankAccountCard."SWIFT Code".Enabled(), '');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJounral_ReferenceNoIsVisible()
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 220991] PAGE 256 "Payment Journal" has visible field "Reference No."
        PaymentJournal.OpenView();
        Assert.IsTrue(PaymentJournal."Reference No.".Enabled(), '');
        Assert.IsTrue(PaymentJournal."Reference No.".Visible(), '');
    end;

    [Test]
    [HandlerFunctions('DTASuggest_RPH,MessageHandler')]
    [Scope('OnPrem')]
    procedure DTASuggest_GLBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Report] [DTA]
        // [SCENARIO 220991] REP 3010546 "DTA Suggest Vendor Payments" inserts G\L balance line in case of "Insert Bank Balance Account" = FALSE
        Initialize();

        // [GIVEN] Posted open purchase invoice
        CreatePostPurchaseInvoice(PurchaseLine);

        // [WHEN] Run REP 3010546 "DTA Suggest Vendor Payments" using "Insert Bank Balance Account" = FALSE
        RunDTASuggestVendorPayments(GenJournalLine, PurchaseLine."Buy-from Vendor No.", false);

        // [THEN] There are two journal lines: Vendor and G/L Account (balance), both having "Bal. Account No." = ""
        Assert.RecordCount(GenJournalLine, 2);

        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Bal. Account No.", '');
        Assert.RecordIsNotEmpty(GenJournalLine);

        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
        Assert.RecordIsNotEmpty(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('DTASuggest_RPH,MessageHandler')]
    [Scope('OnPrem')]
    procedure DTASuggest_BankBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Report] [DTA]
        // [SCENARIO 220991] REP 3010546 "DTA Suggest Vendor Payments" inserts bank balance account inline in case of "Insert Bank Balance Account" = TRUE
        Initialize();

        // [GIVEN] Posted open purchase invoice
        CreatePostPurchaseInvoice(PurchaseLine);

        // [WHEN] Run REP 3010546 "DTA Suggest Vendor Payments" using "Insert Bank Balance Account" = TRUE, Gen. Journal Batch with  "Bal. Account No." = "X"
        RunDTASuggestVendorPayments(GenJournalLine, PurchaseLine."Buy-from Vendor No.", true);
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        // [THEN] There is one journal line: vendor payment with "Bal. Account Type" = "Bank Account", "Bal. Account No." = "X"
        Assert.RecordCount(GenJournalLine, 1);

        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.SetRange("Bal. Account No.", GenJournalBatch."Bal. Account No.");
        Assert.RecordIsNotEmpty(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_Negative_UnknownPaymentType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export in case of unknown "Payment Type"
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Cash Outpayment Order Abroad"
        VendorNo := CreateVendorWithBankAccount(PaymentFormGbl::"Cash Outpayment Order Abroad", '', '', '', '');
        // [GIVEN] Vendor payment journal line
        CreatePaymentJournalLine(GenJournalLine, VendorNo, '', '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] The file export has one or more errors (Unknown swiss SEPA CT export payment type)
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(ExportHasErrorsErr);
        VerifyPaymentJnlExportErrorText(GenJournalLine, UnknownSwissPaymentTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType1_Negative_BlankedReferenceNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "1" in case of blanked journal line's "Reference No."
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "ESR" (typed "ESR Account No.")
        VendorNo := CreateVendorWithBankAccount_ESR();
        // [GIVEN] Vendor payment journal line with "Currency Code" = "", "Reference No." = ""
        CreatePaymentJournalLine(GenJournalLine, VendorNo, '', '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] The file export has one or more errors ("Reference No." must be specified)
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(ExportHasErrorsErr);
        VerifyPaymentJnlExportErrorText(GenJournalLine, StrSubstNo(FieldBlankErr, GenJournalLine.FieldCaption("Reference No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType1_Negative_BlankedESRAccountNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "1" in case of blanked "ESR Account No." for Payment Form ESR
        // [SCENARIO 254013] Swiss SEPA CT export for "Payment Type" = "1" in case of blanked "ESR Account No." (and typed optional BIC, IBAN) for Payment Form ESR
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "ESR", "ESR Account No." = "", "Bank Identifier Code" = "A", IBAN = "B"
        VendorNo := CreateVendorWithBankAccount(PaymentFormGbl::ESR, '', '', '', GetIBAN(true));
        UpdateVendorBankAccBIC(VendorNo);

        // [GIVEN] Vendor payment journal line with "Currency Code" = "", typed "Reference No."
        CreatePaymentJournalLine(GenJournalLine, VendorNo, '', GetReferenceNo(),
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] The file export has one or more errors (Vendor Bank Account "X" must have a value in ESR Account No.)
        VerifyPaymentJnlExportErrorForBlankedVendorBankField(GenJournalLine, VendorBankAccount.FieldCaption("ESR Account No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType1_Negative_BlankedESRAccountNoForESRPlus()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 225490] Swiss SEPA CT export for "Payment Type" = "1" in case of blanked "ESR Account No." for Payment Form ESR+
        // [SCENARIO 254013] Swiss SEPA CT export for "Payment Type" = "1" in case of blanked "ESR Account No." (and typed optional BIC, IBAN) for Payment Form ESR
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "ESR+" and "ESR Account No." = "", "Bank Identifier Code" = "A", IBAN = "B"
        VendorNo := CreateVendorWithBankAccount(PaymentFormGbl::"ESR+", '', '', '', GetIBAN(true));
        UpdateVendorBankAccBIC(VendorNo);

        // [GIVEN] Vendor payment journal line with "Currency Code" = "", typed "Reference No."
        CreatePaymentJournalLine(GenJournalLine, VendorNo, '', GetReferenceNo(),
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] The file export has one or more errors (Vendor Bank Account "X" must have a value in ESR Account No.)
        VerifyPaymentJnlExportErrorForBlankedVendorBankField(GenJournalLine, VendorBankAccount.FieldCaption("ESR Account No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType1_CHF()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        FileName: Text;
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "1" in case of "Payment Form" = "ESR", currency code "CHF"
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "ESR" (typed "ESR Account No.")
        VendorNo := CreateVendorWithBankAccount_ESR();

        // [GIVEN] Vendor bank account has Payment Fee Code of option Own
        UpdateVendorBankAccPaymentFee(VendorNo, VendorBankAccount."Payment Fee Code"::Own);

        // [GIVEN] Vendor payment journal line with "Currency Code" = "", typed "Payment Reference"
        CreatePaymentJournalLine(GenJournalLine, VendorNo, '', GetReferenceNo(),
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "1"
        // [THEN] <ChrgBr> = 'DEBT' (TFS 308455)
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"1");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType1_EUR()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "1" in case of "Payment Form" = "ESR", currency code "EUR"
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "ESR" (typed "ESR Account No.")
        VendorNo := CreateVendorWithBankAccount_ESR();
        // [GIVEN] Vendor payment journal line with "Currency Code" = "EUR", typed "Payment Reference"
        CreatePaymentJournalLine(GenJournalLine, VendorNo, GetEURCurrency(), GetReferenceNo(),
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "1"
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"1");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType21_CHF()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        FileName: Text;
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "2.1" in case of "Payment Form" = "Post Payment Domestic", currency code "CHF"
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Post Payment Domestic" (typed "Giro Account No.")
        VendorNo := CreateVendorWithBankAccount_GiroPost();

        // [GIVEN] Vendor bank account has Payment Fee Code of option " "
        UpdateVendorBankAccPaymentFee(VendorNo, VendorBankAccount."Payment Fee Code"::" ");

        // [GIVEN] Vendor payment journal line with "Currency Code" = ""
        CreatePaymentJournalLine(GenJournalLine, VendorNo, '', '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "2.1"
        // [THEN] <ChrgBr> = 'SLEV' (TFS 308455)
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"2.1");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType21_EUR()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "2.1" in case of "Payment Form" = "Post Payment Domestic", currency code "EUR"
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Post Payment Domestic" (typed "Giro Account No.")
        VendorNo := CreateVendorWithBankAccount_GiroPost();
        // [GIVEN] Vendor payment journal line with "Currency Code" = "EUR"
        CreatePaymentJournalLine(GenJournalLine, VendorNo, GetEURCurrency(), '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "2.1"
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"2.1");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType22_Negative_BlankedIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        BankDirectory: Record "Bank Directory";
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "2.2" in case of blanked "IBAN"
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Bank Payment Domestic" (typed "Clearing No." and IBAN = "")
        BankDirectory.FindFirst();
        VendorNo := CreateVendorWithBankAccount(PaymentFormGbl::"Bank Payment Domestic", '', BankDirectory."Clearing No.", '', '');
        // [GIVEN] Vendor payment journal line with "Currency Code" = ""
        CreatePaymentJournalLine(GenJournalLine, VendorNo, '', '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] The file export has one or more errors (Vendor Bank Account "X" must have a value in IBAN.)
        VerifyPaymentJnlExportErrorForBlankedVendorBankField(GenJournalLine, VendorBankAccount.FieldCaption(IBAN));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType22_CHF()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        FileName: Text;
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "2.2" in case of "Payment Form" = "Bank Payment Domestic", currency code "CHF"
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Bank Payment Domestic" (typed "Clearing No." and IBAN)
        VendorNo := CreateVendorWithBankAccount_Clearing();

        // [GIVEN] Vendor bank account has Payment Fee Code of option Own
        UpdateVendorBankAccPaymentFee(VendorNo, VendorBankAccount."Payment Fee Code"::Own);

        // [GIVEN] Vendor payment journal line with "Currency Code" = ""
        CreatePaymentJournalLine(GenJournalLine, VendorNo, '', '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "2.2"
        // [THEN] <ChrgBr> = 'DEBT' (TFS 308455)
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"2.2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType22_EUR()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "2.2" in case of "Payment Form" = "Bank Payment Domestic", currency code "EUR"
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Bank Payment Domestic" (typed "Clearing No." and IBAN)
        VendorNo := CreateVendorWithBankAccount_Clearing();
        // [GIVEN] Vendor payment journal line with "Currency Code" = "EUR"
        CreatePaymentJournalLine(GenJournalLine, VendorNo, GetEURCurrency(), '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "2.2"
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"2.2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType3_Negative_BlankedSWIFT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "3" in case of blanked "SWIFT Code"
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Bank Payment Domestic" ("SWIFT Code" = "" and domestic IBAN)
        VendorNo := CreateVendorWithBankAccount(PaymentFormGbl::"Bank Payment Domestic", '', '', '', GetIBAN(true));
        // [GIVEN] Vendor payment journal line with "Currency Code" = ""
        CreatePaymentJournalLine(GenJournalLine, VendorNo, '', '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] The file export has one or more errors (Vendor Bank Account "X" must have a value in SWIFT Code.)
        VerifyPaymentJnlExportErrorForBlankedVendorBankField(GenJournalLine, VendorBankAccount.FieldCaption("SWIFT Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType3_Negative_BlankedIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "3" in case of blanked "IBAN"
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Bank Payment Domestic" (typed domestic "SWIFT Code" = "" and IBAN = "")
        VendorNo := CreateVendorWithBankAccount(PaymentFormGbl::"Bank Payment Domestic", '', '', GetSWIFT(true), '');
        // [GIVEN] Vendor payment journal line with "Currency Code" = ""
        CreatePaymentJournalLine(GenJournalLine, VendorNo, '', '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] The file export has one or more errors (Vendor Bank Account "X" must have a value in IBAN.)
        VerifyPaymentJnlExportErrorForBlankedVendorBankField(GenJournalLine, VendorBankAccount.FieldCaption(IBAN));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType3_CHF()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        FileName: Text;
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "3" in case of "Payment Form" = "Bank Payment Domestic", currency code "CHF"
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Bank Payment Domestic" (typed domestic "SWIFT Code" and domestic IBAN)
        VendorNo := CreateVendorWithBankAccount_DomesticSWIFT();

        // [GIVEN] Vendor bank account has Payment Fee Code of option Beneficiary
        UpdateVendorBankAccPaymentFee(VendorNo, VendorBankAccount."Payment Fee Code"::Beneficiary);

        // [GIVEN] Vendor payment journal line with "Currency Code" = ""
        CreatePaymentJournalLine(GenJournalLine, VendorNo, '', '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "3"
        // [THEN] <ChrgBr> = 'CRED' (TFS 308455)
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"3");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType3_EUR()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "3" in case of "Payment Form" = "Bank Payment Domestic", currency code "EUR"
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Bank Payment Domestic" (typed domestic "SWIFT Code" and domestic IBAN)
        VendorNo := CreateVendorWithBankAccount_DomesticSWIFT();
        // [GIVEN] Vendor payment journal line with "Currency Code" = "EUR"
        CreatePaymentJournalLine(GenJournalLine, VendorNo, GetEURCurrency(), '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "3"
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"3");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType4_Negative_BlankedSWIFT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "4" in case of blanked "SWIFT Code"
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Bank Payment Domestic" ("SWIFT Code" = "" and domestic IBAN)
        VendorNo := CreateVendorWithBankAccount(PaymentFormGbl::"Bank Payment Domestic", '', '', '', GetIBAN(true));
        // [GIVEN] Vendor payment journal line with "Currency Code" = "USD"
        CreatePaymentJournalLine(GenJournalLine, VendorNo, GetForeignCurrency(), '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] The file export has one or more errors (Vendor Bank Account "X" must have a value in SWIFT Code.)
        VerifyPaymentJnlExportErrorForBlankedVendorBankField(GenJournalLine, VendorBankAccount.FieldCaption("SWIFT Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType4_Negative_BlankedIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "4" in case of blanked "IBAN"
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Bank Payment Domestic" (domestic "SWIFT Code" and IBAN = "")
        VendorNo := CreateVendorWithBankAccount(PaymentFormGbl::"Bank Payment Domestic", '', '', GetSWIFT(true), '');
        // [GIVEN] Vendor payment journal line with "Currency Code" = "USD"
        CreatePaymentJournalLine(GenJournalLine, VendorNo, GetForeignCurrency(), '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] The file export has one or more errors (Vendor Bank Account "X" must have a value in IBAN.)
        VerifyPaymentJnlExportErrorForBlankedVendorBankField(GenJournalLine, VendorBankAccount.FieldCaption(IBAN));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType4_USD()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        FileName: Text;
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "4" in case of "Payment Form" = "Bank Payment Domestic", currency code "USD"
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Bank Payment Domestic" (typed domestic "SWIFT Code" and domestic IBAN)
        VendorNo := CreateVendorWithBankAccount_DomesticSWIFT();

        // [GIVEN] Vendor bank account has Payment Fee Code of option Share
        UpdateVendorBankAccPaymentFee(VendorNo, VendorBankAccount."Payment Fee Code"::Share);

        // [GIVEN] Vendor payment journal line with "Currency Code" = "USD"
        CreatePaymentJournalLine(GenJournalLine, VendorNo, GetForeignCurrency(), '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "4"
        // [THEN] <ChrgBr> = 'SHAR' (TFS 308455)
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"4");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType5_EUR()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        FileName: Text;
        MessageID: Text;
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "5" in case of "Payment Form" = "Bank Payment Abroad", currency code "EUR"
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Bank Payment Abroad" (no "SWIFT Code" and abroad IBAN)
        CreateVendorWithBankAccount_AbroadSEPA(VendorBankAccount);

        // [GIVEN] Vendor payment journal line with "Currency Code" = "EUR"
        CreatePaymentJournalLine(GenJournalLine, VendorBankAccount."Vendor No.", GetEURCurrency(), '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "5"
        // [THEN] <ChrgBr> = 'SLEV' (TFS 308455)
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"5");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType6_CHF()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        FileName: Text;
        PaymentType6: Option ,"IBAN and SWIFT","IBAN and PstlAddr","BankAccNo and SWIFT","BankAccNo and PstlAddr","IBAN and BankAccNo";
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "6" for pair IBAN + SWIFT, currency code "CHF"
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Bank Payment Abroad" (typed abroad "SWIFT Code" and abroad IBAN)
        VendorNo := CreateVendorWithBankAccount_Abroad();

        // [GIVEN] Vendor bank account has Payment Fee Code of option Own
        UpdateVendorBankAccPaymentFee(VendorNo, VendorBankAccount."Payment Fee Code"::Own);

        // [GIVEN] Vendor payment journal line with "Currency Code" = ""
        CreatePaymentJournalLine(GenJournalLine, VendorNo, '', '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "6"
        // [THEN] <ChrgBr> = 'DEBT' (TFS 308455)
        VerifyXMLFileWithPstlAddr(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"6", PaymentType6::"IBAN and SWIFT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType6_USD()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        PaymentType6: Option ,"IBAN and SWIFT","IBAN and PstlAddr","BankAccNo and SWIFT","BankAccNo and PstlAddr","IBAN and BankAccNo";
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "6" for pair IBAN + SWIFT, currency code "USD"
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Bank Payment Abroad" (typed abroad "SWIFT Code" and abroad IBAN)
        VendorNo := CreateVendorWithBankAccount_Abroad();
        // [GIVEN] Vendor payment journal line with "Currency Code" = "USD"
        CreatePaymentJournalLine(GenJournalLine, VendorNo, GetForeignCurrency(), '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "6"
        VerifyXMLFileWithPstlAddr(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"6", PaymentType6::"IBAN and SWIFT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType6_IBANAndSWIFTAndPstlAddrWithCountryCode()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        FileName: Text;
        PaymentType6: Option ,"IBAN and SWIFT","IBAN and PstlAddr","BankAccNo and SWIFT","BankAccNo and PstlAddr","IBAN and BankAccNo";
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 264198] Swiss SEPA CT export for "Payment Type" = "6" for pair IBAN + SWIFT, currency code "USD" and Postal Address
        Initialize();

        // [GIVEN] Vendor with bank account of "Payment Form" = "Bank Payment Abroad" (abroad "SWIFT Code" and abroad IBAN)
        VendorNo := CreateVendorWithBankAccount_Abroad();
        VendorBankAccount.SetRange("Vendor No.", VendorNo);
        VendorBankAccount.FindFirst();
        UpdateVendorBankAccNameAddr(VendorBankAccount);
        VendorBankAccount.Modify();

        // [GIVEN] Vendor payment journal line with "Currency Code" = "USD"
        CreatePaymentJournalLine(GenJournalLine, VendorNo, GetForeignCurrency(), '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "6" without node <CdtrAgt>/<PstlAdr>
        VerifyXMLFileWithPstlAddr(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"6", PaymentType6::"IBAN and SWIFT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType6_IBANAndSWIFTAndPstlAddrWithBlankCountryCode()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        FileName: Text;
        PaymentType6: Option ,"IBAN and SWIFT","IBAN and PstlAddr","BankAccNo and SWIFT","BankAccNo and PstlAddr","IBAN and BankAccNo";
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 264198] Swiss SEPA CT export for "Payment Type" = "6" for pair IBAN + SWIFT, currency code "USD" and Postal Address with blank Country/Region Code
        Initialize();

        // [GIVEN] Vendor with bank account of "Payment Form" = "Bank Payment Abroad" (abroad "SWIFT Code" and abroad IBAN) and blank Country/Region Code
        VendorNo := CreateVendorWithBankAccount_Abroad();
        VendorBankAccount.SetRange("Vendor No.", VendorNo);
        VendorBankAccount.FindFirst();
        UpdateVendorBankAccNameAddr(VendorBankAccount);
        VendorBankAccount."Country/Region Code" := '';
        VendorBankAccount.Modify();

        // [GIVEN] Vendor payment journal line with "Currency Code" = "USD"
        CreatePaymentJournalLine(GenJournalLine, VendorNo, GetForeignCurrency(), '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "6" without node <CdtrAgt>/<PstlAdr>
        VerifyXMLFileWithPstlAddr(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"6", PaymentType6::"IBAN and SWIFT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType6_IBANAndPstlAddr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        PaymentType6: Option ,"IBAN and SWIFT","IBAN and PstlAddr","BankAccNo and SWIFT","BankAccNo and PstlAddr","IBAN and BankAccNo";
        FileName: Text;
        MessageID: Text;
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 225521] Swiss SEPA CT export for "Payment Type" = "6" for pair IBAN and Postal Address
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Bank Payment Abroad" with IBAN and Postal Address
        CreateVendorWithBankAccount_AbroadWithIBANAndPstlAddr(VendorBankAccount);

        // [GIVEN] Vendor payment journal line
        CreatePaymentJournalLine(GenJournalLine, VendorBankAccount."Vendor No.", GetForeignCurrency(), '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "6"
        VerifyXMLFileWithPstlAddr(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"6", PaymentType6::"IBAN and PstlAddr");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType6_BankAccNoAndSWIFT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        PaymentType6: Option ,"IBAN and SWIFT","IBAN and PstlAddr","BankAccNo and SWIFT","BankAccNo and PstlAddr","IBAN and BankAccNo";
        FileName: Text;
        MessageID: Text;
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 225521] Swiss SEPA CT export for "Payment Type" = "6" for pair Bank Account No and SWIFT
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Bank Payment Abroad" with Bank Account No and SWIFT
        CreateVendorWithBankAccount_AbroadWithBankAccNoAndSWIFT(VendorBankAccount);

        // [GIVEN] Vendor payment journal line
        CreatePaymentJournalLine(GenJournalLine, VendorBankAccount."Vendor No.", GetForeignCurrency(), '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "6"
        VerifyXMLFileWithPstlAddr(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"6", PaymentType6::"BankAccNo and SWIFT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType6_BankAccNoAndPstlAddr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        PaymentType6: Option ,"IBAN and SWIFT","IBAN and PstlAddr","BankAccNo and SWIFT","BankAccNo and PstlAddr","IBAN and BankAccNo";
        FileName: Text;
        MessageID: Text;
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 225521] Swiss SEPA CT export for "Payment Type" = "6" for pair Bank Account No and Postal Address
        Initialize();

        // [GIVEN] Vendor with bank account having "Payment Form" = "Bank Payment Abroad" with Bank Account No and Postal Address
        CreateVendorWithBankAccount_AbroadWithBankAccNoAndPstlAddr(VendorBankAccount);

        // [GIVEN] Vendor payment journal line
        CreatePaymentJournalLine(GenJournalLine, VendorBankAccount."Vendor No.", GetForeignCurrency(), '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "6"
        VerifyXMLFileWithPstlAddr(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"6", PaymentType6::"BankAccNo and PstlAddr");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType6_MsgToRecipient()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 235211] Swiss SEPA CT export for "Payment Type" = "6". When Stan exports a Payment Line to an XML file, "Message to Recipient" value gets to <Ustrd> section of the file.
        Initialize();

        // [GIVEN] Vendor with bank account having "Swiss Payment Type" = "6"
        VendorNo := CreateVendorWithBankAccount_Abroad();

        // [GIVEN] Vendor payment journal line with non-empty "Message to Recipient" = "M1"
        CreatePaymentJournalLine(GenJournalLine, VendorNo, GetForeignCurrency(), '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);
        GenJournalLine."Message to Recipient" :=
          PadStr(
            LibraryUtility.GenerateRandomXMLText(MaxStrLen(GenJournalLine."Message to Recipient")),
            MaxStrLen(GenJournalLine."Message to Recipient"));
        GenJournalLine.Modify();

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "6". "Message to Recipient" value got to <Ustrd> section of XML document.
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"6");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GetAccountNo()
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 220991] GetBankAccountNo from Vendor Bank Account removes dashes from ESR Account No.
        Initialize();
        VendorBankAccount.Init();
        VendorBankAccount."Payment Form" := VendorBankAccount."Payment Form"::ESR;
        VendorBankAccount."ESR Account No." := '11-2222-33';
        Assert.AreEqual('11222233', VendorBankAccount.GetBankAccountNo(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_Negative_PaymentType3_BankAccountBlankSWIFT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 423336] Swiss SEPA CT export for Bank Account with blank SWIFT Code and Payment Type 3
        Initialize();

        // [GIVEN] Payment Journal line for Vendor with bank account of Payment Type 3
        VendorNo := CreateVendorWithBankAccount_DomesticSWIFT();
        CreatePaymentJournalLine(GenJournalLine, VendorNo, GetEURCurrency(), '',
            GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [GIVEN] SWIFT Code is blank in Bank Account in Payment Journal
        ResetSWIFTCodeInBankAccount(GenJournalLine."Bal. Account No.");

        // [WHEN] Export payment to file
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] The file export has error 'Bank Account must have a value in SWIFT Code.'
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(ExportHasErrorsErr);
        VerifyPaymentJnlExportErrorText(
            GenJournalLine,
            StrSubstNo(
                FieldKeyBlankErr, BankAccount.TableCaption(), GenJournalLine."Bal. Account No.", BankAccount.FieldCaption("SWIFT Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_Negative_PaymentType5_BankAccountBlankSWIFT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 220615] Swiss SEPA CT export for Bank Account with blank SWIFT Code and Payment Type 5
        Initialize();
        CreateVendorWithBankAccount_AbroadSEPA(VendorBankAccount);
        // [GIVEN] Payment Journal line for Vendor with bank account of Payment Type 5
        CreatePaymentJournalLine(GenJournalLine, VendorBankAccount."Vendor No.", GetEURCurrency(), '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [GIVEN] SWIFT Code is blank in Bank Account in Payment Journal
        ResetSWIFTCodeInBankAccount(GenJournalLine."Bal. Account No.");

        // [WHEN] Export payment to file
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] The file export has error 'Bank Account must have a value in SWIFT Code.'
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(ExportHasErrorsErr);
        VerifyPaymentJnlExportErrorText(
          GenJournalLine,
          StrSubstNo(
            FieldKeyBlankErr, BankAccount.TableCaption(), GenJournalLine."Bal. Account No.", BankAccount.FieldCaption("SWIFT Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_Negative_PaymentType6_BankAccountBlankSWIFT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 264198] Swiss SEPA CT export requires SWIFT Code in Bank Account for Payment Type 6
        Initialize();

        // [GIVEN] Payment Journal line for Vendor with bank account of Payment Type 6
        VendorBankAccount.SetRange("Vendor No.", CreateVendorWithBankAccount_Abroad());
        VendorBankAccount.FindFirst();
        CreatePaymentJournalLine(GenJournalLine, VendorBankAccount."Vendor No.", GetForeignCurrency(), '',
          GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);

        // [GIVEN] SWIFT Code is blank in Bank Account
        ResetSWIFTCodeInBankAccount(GenJournalLine."Bal. Account No.");

        // [WHEN] Export payment to file
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] The file export has error 'Bank Account must have a value in SWIFT Code.'
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(ExportHasErrorsErr);
        VerifyPaymentJnlExportErrorText(
          GenJournalLine,
          StrSubstNo(
            FieldKeyBlankErr, BankAccount.TableCaption(), GenJournalLine."Bal. Account No.", BankAccount.FieldCaption("SWIFT Code")));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentWithReferenceNo()
    var
        GenJournalLineInvoice: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Report] [Suggest Vendor Payments]
        // [SCENARIO 225483] Reference No. is transferred to Gen. Journal Line via Suggest Vendor Payments report without 'Summarize Per Vendor' option
        Initialize();

        // [GIVEN] Vendor Invoice of vendor "V" is posted with Reference No. = "Ref00001"
        CreatePostGenJnlPurchInvoiceWithReferenceNo(GenJournalLineInvoice);

        // [WHEN] Suggest Vendor Payments for vendor "V" without 'Summarize per Vendor' option
        InitGenJournalLine(GenJournalLine, FindSwissSEPACTBankExpImpCode());
        RunSuggestVendorPaymentsForVendor(GenJournalLine, GenJournalLineInvoice."Account No.", false, false);

        // [THEN] Gen. Journal Line is created for vendor "V" with Reference No. = "Ref00001"
        VerifyReferenceNoOnGenJnlLine(GenJournalLine, GenJournalLineInvoice."Account No.", GenJournalLineInvoice."Reference No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostExportedVendorPaymentWithReferenceNo()
    var
        GenJournalLineInvoice: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 229093] Post exported Payment Journal line for invoice with Reference No.
        Initialize();

        // [GIVEN] Vendor Invoice of vendor "V" is posted with Reference No. = "Ref00001"
        CreatePostGenJnlPurchInvoiceWithReferenceNo(GenJournalLineInvoice);

        // [GIVEN] Payment Journal line is suggested for vendor "V" for the invoice
        InitGenJournalLine(GenJournalLine, FindSwissSEPACTBankExpImpCode());
        RunSuggestVendorPaymentsForVendor(GenJournalLine, GenJournalLineInvoice."Account No.", false, false);

        // [WHEN] Post Payment Journal line
        GenJournalLine.SetRange("Account No.", GenJournalLineInvoice."Account No.");
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Vendor Ledger Entry is closed and has Reference No. = "Ref00001"
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        VendorLedgerEntry.TestField("Reference No.", GenJournalLineInvoice."Reference No.");
        VendorLedgerEntry.TestField(Open, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostVendorPaymentWithReferenceNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 229093] Post Payment Journal line for invoice with Reference No.
        Initialize();

        // [GIVEN] Vendor Payment Journal Line with Reference No. = "Ref00001"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, CreateVendorWithBankAccount_ESR(), LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Reference No.", GetReferenceNo());
        GenJournalLine.Modify(true);

        // [WHEN] Post Payment Journal line
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error raised that '...reference number is defined. The document type must be "Invoice".'
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
          StrSubstNo(ReferenceNumberIsDefinedErr, GenJournalLine."Account No.", GenJournalLine."Document No."));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentWithReferenceNoSummarizeOneEntry()
    var
        GenJournalLineInvoice: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [Report] [Suggest Vendor Payments]
        // [SCENARIO 263854] Reference No. is transferred to Gen. Journal Line via Suggest Vendor Payments report for one vendor entry with 'Summarize per Vendor' option
        Initialize();

        // [GIVEN] Vendor Invoice of vendor "V" is posted with Reference No. = "Ref00001"
        CreatePostGenJnlPurchInvoiceWithReferenceNo(GenJournalLineInvoice);

        // [GIVEN] Vendor bank account has Payment Fee Code of option Own
        UpdateVendorBankAccPaymentFee(GenJournalLineInvoice."Account No.", VendorBankAccount."Payment Fee Code"::Own);

        // [WHEN] Suggest Vendor Payments for vendor "V" with 'Summarize per Vendor' option
        InitGenJournalLine(GenJournalLine, FindSwissSEPACTBankExpImpCode());
        RunSuggestVendorPaymentsForVendor(GenJournalLine, GenJournalLineInvoice."Account No.", true, false);

        // [THEN] Gen. Journal Line is created for vendor "V" with Reference No. = "Ref00001"
        VerifyReferenceNoOnGenJnlLine(GenJournalLine, GenJournalLineInvoice."Account No.", GenJournalLineInvoice."Reference No.");
        // [THEN] "Payment Fee Code" has option Own (TFS 308455)
        GenJournalLine.TestField("Payment Fee Code", VendorBankAccount."Payment Fee Code"::Own);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentWithReferenceNoSummarizeTwoEntries()
    var
        GenJournalLineInvoice: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Report] [Suggest Vendor Payments]
        // [SCENARIO 263854] Reference No. is not transferred to Gen. Journal Line via Suggest Vendor Payments report for more than one vendor entry with 'Summarize per Vendor' option
        Initialize();

        // [GIVEN] Two Vendor Invoices of vendor "V" are posted with Reference No. = "Ref00001" and "Ref00002"
        CreatePostGenJnlPurchInvoiceWithReferenceNo(GenJournalLineInvoice);
        CreatePostGenJnlPurchDoc(
          GenJournalLineInvoice, GenJournalLineInvoice."Document Type"::Invoice, GenJournalLineInvoice."Account No.",
          -LibraryRandom.RandDecInRange(1000, 2000, 2), GetReferenceNo2());

        // [WHEN] Suggest Vendor Payments for vendor "V" with 'Summarize per Vendor' option
        InitGenJournalLine(GenJournalLine, FindSwissSEPACTBankExpImpCode());
        RunSuggestVendorPaymentsForVendor(GenJournalLine, GenJournalLineInvoice."Account No.", true, false);

        // [THEN] Gen. Journal Line is created for vendor "V" with blank Reference No.
        VerifyReferenceNoOnGenJnlLine(GenJournalLine, GenJournalLineInvoice."Account No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_IsSEPACountryYes()
    var
        CHMgt: Codeunit CHMgt;
    begin
        // [FEATURE] [UT]
        // [SCENARIO ] CH is defined as SEPA Country
        Assert.IsTrue(CHMgt.IsSEPACountry('CH'), 'Should be SEPA Country');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_IsSEPACountryNo()
    var
        CHMgt: Codeunit CHMgt;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 225521] RS is defined as not SEPA Country
        Assert.IsFalse(CHMgt.IsSEPACountry('RS'), 'Should be not SEPA Country');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentForInvoiceWithNotPreferredVendorBankAccountSwiss()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [Report] [Suggest Vendor Payments]
        // [SCENARIO 232397]  Recipient Bank Account is transferred from Vendor Ledger Entry to Gen. Journal Line via Suggest Vendor Payments report for Swiss SEPA
        Initialize();

        // [GIVEN] Vendor "V" has Preferred Bank Account Code = "B"
        // [GIVEN] Vendor Invoice of vendor "V" is posted with Vendor Bank Account Code = "A"
        CreatePostGenJnlPurchInvoiceWithNewVendorBankAccount(VendorBankAccount);

        // [WHEN] Suggest Vendor Payments for vendor "V" for Swiss SEPA CT Journal Batch
        InitGenJournalLine(GenJournalLine, FindSwissSEPACTBankExpImpCode());
        RunSuggestVendorPaymentsForVendor(GenJournalLine, VendorBankAccount."Vendor No.", false, false);

        // [THEN] Gen. Journal Line is created for vendor "V" with Recipient Bank Account = "A"
        VerifyRecipienBankAccountOnPaymentLine(VendorBankAccount."Vendor No.", VendorBankAccount.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentForInvoiceWithNotPreferredVendorBankAccountW1()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [Report] [Suggest Vendor Payments]
        // [SCENARIO 232397]  Recipient Bank Account is transferred from Vendor Ledger Entry to Gen. Journal Line via Suggest Vendor Payments report for W1 SEPA
        Initialize();

        // [GIVEN] Vendor "V" has Preferred Bank Account Code = "B"
        // [GIVEN] Vendor Invoice of vendor "V" is posted with Vendor Bank Account Code = "A"
        CreatePostGenJnlPurchInvoiceWithNewVendorBankAccount(VendorBankAccount);

        // [WHEN] Suggest Vendor Payments for vendor "V" for W1 SEPA CT Journal Batch
        InitGenJournalLine(GenJournalLine, FindW1SEPACTBankExpImpCode());
        RunSuggestVendorPaymentsForVendor(GenJournalLine, VendorBankAccount."Vendor No.", false, false);

        // [THEN] Gen. Journal Line is created for vendor "V" with Recipient Bank Account = "A"
        VerifyRecipienBankAccountOnPaymentLine(VendorBankAccount."Vendor No.", VendorBankAccount.Code);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentRPH')]
    [Scope('OnPrem')]
    procedure SuggestVendorPayments_ExcludeCreditMemosActionOnRequestPage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        // [FEATURE] [Report] [Suggest Vendor Payments] [UI]
        // [SCENARIO 233548] There is an action "Exclude Credit Memos" on a request page for REP 393 "Suggest Vendor Payments"
        Initialize();

        // [GIVEN] Payment jounral
        // [WHEN] Perform "Suggest Vendor Payments" action
        InitGenJournalLine(GenJournalLine, FindSwissSEPACTBankExpImpCode());
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.UseRequestPage(true);
        Commit();
        SuggestVendorPayments.RunModal();

        // [THEN] There is an action "Exclude Credit Memos" on a request page and it is visible, editable
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), '');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPayments_IncludeCreditMemos()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Report] [Suggest Vendor Payments]
        // [SCENARIO 233548] Credit memo payment is suggested when run REP 393 "Suggest Vendor Payments" in case of "Exclude Credit Memos" = FALSE
        Initialize();

        // [GIVEN] Posted purchase invoice and credit memo
        CreatePostGenJnlPurchInvoiceWithReferenceNo(GenJournalLine);
        VendorNo := GenJournalLine."Account No.";
        CreatePostGenJnlPurchCreditMemo(GenJournalLine, VendorNo, -GenJournalLine.Amount / 3);

        // [WHEN] Suggest Vendor Payments, use "Exclude Credit Memos" = FALSE
        InitGenJournalLine(GenJournalLine, FindSwissSEPACTBankExpImpCode());
        RunSuggestVendorPaymentsForVendor(GenJournalLine, VendorNo, false, false);

        // [THEN] Two payments have been suggested including credit memo payment
        Assert.RecordCount(GenJournalLine, 2);
        GenJournalLine.SetRange("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::"Credit Memo");
        Assert.RecordIsNotEmpty(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPayments_ExcludeCreditMemos()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Report] [Suggest Vendor Payments]
        // [SCENARIO 233548] Credit memo payment is not suggested when run REP 393 "Suggest Vendor Payments" in case of "Exclude Credit Memos" = TRUE
        Initialize();

        // [GIVEN] Posted purchase invoice and credit memo
        CreatePostGenJnlPurchInvoiceWithReferenceNo(GenJournalLine);
        VendorNo := GenJournalLine."Account No.";
        CreatePostGenJnlPurchCreditMemo(GenJournalLine, VendorNo, -GenJournalLine.Amount / 3);

        // [WHEN] Suggest Vendor Payments, use "Exclude Credit Memos" = TRUE
        InitGenJournalLine(GenJournalLine, FindSwissSEPACTBankExpImpCode());
        RunSuggestVendorPaymentsForVendor(GenJournalLine, VendorNo, false, true);

        // [THEN] One invoice payment has been suggested
        Assert.RecordCount(GenJournalLine, 1);
        GenJournalLine.SetRange("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        Assert.RecordIsNotEmpty(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePaymentExportDataRecipientAccNoForVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentExportData: Record "Payment Export Data";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 235349] "Payment Jnl. Export Text" has no error when field "Payment Export Data"."Recipient Acc. No." is filled
        Initialize();

        // [GIVEN] "Gen. Journal Line" with "Recipient Acc. No." is not blanked
        // [GIVEN] SEPA export has value "Swiss Payment Type" = "1"
        CreateGenJournalBatch(GenJournalBatch, CreateBankAccount(FindSwissSEPACTBankExpImpCode()));
        CreateGenJournalLine(GenJournalLine, GenJournalBatch);
        PaymentJnlExportErrorText.DeleteAll();

        // [WHEN] Invoke "SEPA CT Fill Export Buffer"."FillExportBuffer"
        GenJournalLine.SetRecFilter();
        SEPACTFillExportBuffer.FillExportBuffer(GenJournalLine, PaymentExportData);

        // [THEN] "Payment Jnl. Export Error Text" has no errors.
        Assert.RecordCount(PaymentJnlExportErrorText, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPayments_SwissDescriptionAndMessageToRecipient()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        ExternalDocNo: Code[35];
    begin
        // [FEATURE] [Report] [Suggest Vendor Payments]
        // [SCENARIO 234269] Suggest Vendor Payment report populates Description and Message to Recipient for Swiss.
        Initialize();

        // [GIVEN] Vendor "V" with bank account with "Payment Form" = "ESR".
        // [GIVEN] Posted Purchase Journal Line with Invoice for "V" and with External Document No = "EXT".
        Vendor.Get(CreateVendorWithBankAccount_ESR());
        ExternalDocNo :=
          CopyStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(GenJournalLine."External Document No.")),
            1, MaxStrLen(GenJournalLine."External Document No."));
        CreatePostGenJnlPurchDocWithExternalDocNo(GenJournalLine, GenJournalLine."Document Type"::Invoice, Vendor."No.", ExternalDocNo);

        // [WHEN] Suggest Vendor Payments for vendor "V" and fill the Payment Journal.
        InitGenJournalLine(GenJournalLine, FindSwissSEPACTBankExpImpCode());
        RunSuggestVendorPaymentsForVendor(GenJournalLine, Vendor."No.", false, false);

        // [THEN] Payment Journal Line created for "V" where Description = "V.Name, EXT" and "Message To Recipient" = "Payment of Invoice EXT, Vendor No. "V"".
        VerifySuggestedJournalLineDescriptionMessageToRecipient(
          Vendor, ExternalDocNo, CopyStr(Vendor.Name + ', ' + ExternalDocNo, 1, MaxStrLen(GenJournalLine.Description)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPayments_SwissDescriptionWithLongVendorName()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        ExternalDocNo: Code[35];
    begin
        // [FEATURE] [Report] [Suggest Vendor Payments]
        // [SCENARIO 264227] Suggest Vendor Payment report populates Description for Swiss in case of long vendor Name and long External Document No.
        Initialize();

        // [GIVEN] Vendor with Name = "AB", where "AB" - 50-chars including "A" - 13-chars string, "B" - 37-chars string
        // [GIVEN] Posted Purchase Journal Line with Invoice with External Document No = "E", where "E" - 35-chars string
        Vendor.Get(CreateVendorWithBankAccount_ESR());
        Vendor.Name := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)), 1, MaxStrLen(Vendor.Name));
        Vendor.Modify();
        ExternalDocNo :=
          CopyStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(GenJournalLine."External Document No.")),
            1, MaxStrLen(GenJournalLine."External Document No."));
        CreatePostGenJnlPurchDocWithExternalDocNo(GenJournalLine, GenJournalLine."Document Type"::Invoice, Vendor."No.", ExternalDocNo);

        // [WHEN] Suggest Vendor Payments
        InitGenJournalLine(GenJournalLine, FindSwissSEPACTBankExpImpCode());
        RunSuggestVendorPaymentsForVendor(GenJournalLine, Vendor."No.", false, false);

        // [THEN] Payment Journal Line created with Description = "A, E"
        asserterror
          VerifySuggestedJournalLineDescriptionMessageToRecipient(
            Vendor, ExternalDocNo,
            CopyStr(CopyStr(Vendor.Name, 1, 13) + ', ' + ExternalDocNo, 1, MaxStrLen(GenJournalLine.Description)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_BatchBooking_49Payments()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CHMgt: Codeunit CHMgt;
        FileName: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 253444] Batch Booking is false when xml is exported with payment's quantity less than 'No Of Payments For BatchBooking' value (50)
        Initialize();

        // [GIVEN] Vendor with bank account of "Payment Form" = "ESR"
        VendorNo := CreateVendorWithBankAccount_ESR();

        // [GIVEN] Vendor payment journal lines of 49 payments
        CreateSetOfPaymentJournalLine(GenJournalLine, VendorNo, CHMgt.NoOfPaymentsForBatchBooking() - 1);

        // [WHEN] Export payments to file
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with tags 'NbOfTxs' = 49, 'BtchBookg' = false
        VerifyXMLFileBatchBooking(FileName, CHMgt.NoOfPaymentsForBatchBooking() - 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_BatchBooking_50Payments()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CHMgt: Codeunit CHMgt;
        FileName: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 253444] Batch Booking is true when xml is exported with payment's quantity equals to 'No Of Payments For BatchBooking' value (50)
        Initialize();

        // [GIVEN] Vendor with bank account of "Payment Form" = "ESR"
        VendorNo := CreateVendorWithBankAccount_ESR();

        // [GIVEN] Vendor payment journal lines of 50 payments
        CreateSetOfPaymentJournalLine(GenJournalLine, VendorNo, CHMgt.NoOfPaymentsForBatchBooking());

        // [WHEN] Export payments to file
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with tags 'NbOfTxs' = 50, 'BtchBookg' = true
        VerifyXMLFileBatchBooking(FileName, CHMgt.NoOfPaymentsForBatchBooking(), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportData_SetCustomerAsRecipient_PaymentType22()
    var
        PaymentExportData: Record "Payment Export Data";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 275414] TAB 1226 "Payment Export Data".SetCustomerAsRecipient() in case of "Payment Type" = "2.2"
        Customer.Get(CreateCustomerWithBankAccount_DomesticIBAN());
        CustomerBankAccount.Get(Customer."No.", Customer."Preferred Bank Account Code");

        PaymentExportData.Init();

        PaymentExportData.SetSwissExport(true);
        PaymentExportData."Currency Code" := GetCurrencyCode('');
        PaymentExportData.SetCustomerAsRecipient(Customer, CustomerBankAccount);

        VerifyPaymentExportDataFields(
          PaymentExportData, PaymentExportData."Swiss Payment Form"::ESR, PaymentExportData."Swiss Payment Type"::"2.2",// "Swiss Payment Form"::ESR - default value
          CopyStr(CustomerBankAccount.IBAN, 1, MaxStrLen(PaymentExportData."Recipient Bank BIC")),
          CustomerBankAccount.IBAN, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportData_SetCustomerAsRecipient_PaymentType6()
    var
        PaymentExportData: Record "Payment Export Data";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 275414] TAB 1226 "Payment Export Data".SetCustomerAsRecipient() in case of "Payment Type" = "6"
        CreateCustomerWithBankAccount_AbroadWithBankAccNoAndIBAN(CustomerBankAccount);
        Customer.Get(CustomerBankAccount."Customer No.");

        PaymentExportData.Init();

        PaymentExportData.SetSwissExport(true);
        PaymentExportData."Currency Code" := GetForeignCurrency();
        PaymentExportData.SetCustomerAsRecipient(Customer, CustomerBankAccount);

        VerifyPaymentExportDataFields(
          PaymentExportData, PaymentExportData."Swiss Payment Form"::ESR, PaymentExportData."Swiss Payment Type"::"6",// "Swiss Payment Form"::ESR - default value
          CustomerBankAccount."SWIFT Code", CustomerBankAccount.IBAN, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Customer_XMLExport_PaymentType22_CHF()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        MessageID: Text;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [XML] [Export] [Customer]
        // [SCENARIO 275414] Swiss SEPA CT export for "Payment Type" = "2.2" in case of currency code "CHF"
        Initialize();

        // [GIVEN] Customer with bank account with domestic IBAN and domestic currency
        CustomerNo := CreateCustomerWithBankAccount_DomesticIBAN();

        // [GIVEN] Customer refund journal line with "Currency Code" = ""
        CreatePaymentJournalLine(GenJournalLine, CustomerNo, '', '',
          GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Refund);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "2.2"
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"2.2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Customer_XMLExport_PaymentType22_EUR()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        MessageID: Text;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [XML] [Export] [Customer]
        // [SCENARIO 220991] Swiss SEPA CT export for "Payment Type" = "2.2" in case of currency code "EUR"
        Initialize();

        // [GIVEN] Customer with bank account with domestic IBAN and domestic currency
        CustomerNo := CreateCustomerWithBankAccount_DomesticIBAN();

        // [GIVEN] Customer refund journal line with "Currency Code" = "EUR"
        CreatePaymentJournalLine(GenJournalLine, CustomerNo, GetEURCurrency(), '',
          GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Refund);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "2.2"
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"2.2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Customer_XMLExport_PaymentType6()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerBankAccount: Record "Customer Bank Account";
        PaymentType6: Option ,"IBAN and SWIFT","IBAN and PstlAddr","BankAccNo and SWIFT","BankAccNo and PstlAddr","IBAN and BankAccNo";
        FileName: Text;
        MessageID: Text;
    begin
        // [FEATURE] [XML] [Export] [Customer]
        // [SCENARIO 225521] Swiss SEPA CT export for "Payment Type" = "6"
        Initialize();

        // [GIVEN] Customer with bank account with IBAN and Bank Account No.
        CreateCustomerWithBankAccount_AbroadWithBankAccNoAndIBAN(CustomerBankAccount);

        // [GIVEN] Customer refund journal line
        CreatePaymentJournalLine(GenJournalLine, CustomerBankAccount."Customer No.", GetForeignCurrency(), '',
          GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Refund);

        // [WHEN] Export payments to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "6"
        VerifyXMLFileWithBankAccNo(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"6", PaymentType6::"IBAN and BankAccNo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerBankAccountGetPaymentTypeReturnFalse()
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 275414] Function "Customer Bank Account"."GetPaymentType" returns FALSE if "Customer Bank Account"."IBAN" is blank
        CustomerBankAccount.Init();
        CustomerBankAccount.IBAN := '';
        Assert.IsFalse(CustomerBankAccount.GetPaymentType(PaymentTypeGbl, ''), GetPaymentTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerBankAccountGetPaymentTypeReturnPaymentType22()
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 275414] Function "Customer Bank Account"."GetPaymentType" returns Swiss Payment Type = 2.2 if "IBAN" has value and is domestic, "Bank Account No." is blanked, Currency is domestic
        CustomerBankAccount.Init();
        CustomerBankAccount.IBAN := GetIBAN(true);
        CustomerBankAccount."Bank Account No." := '';
        Assert.IsTrue(CustomerBankAccount.GetPaymentType(PaymentTypeGbl, GetCurrencyCode('')), GetPaymentTypeErr);
        Assert.AreEqual(PaymentTypeGbl::"2.2", PaymentTypeGbl, GetPaymentTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerBankAccountGetPaymentTypeReturnPaymentType6()
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 275414] Function "Customer Bank Account"."GetPaymentType" returns Swiss Payment Type = 6 if "IBAN" has value and is domestic, "Bank Account No." has value
        CustomerBankAccount.Init();
        CustomerBankAccount.IBAN := GetIBAN(true);
        CustomerBankAccount."Bank Account No." := LibraryUtility.GenerateGUID();
        Assert.IsTrue(CustomerBankAccount.GetPaymentType(PaymentTypeGbl, GetCurrencyCode('')), GetPaymentTypeErr);
        Assert.AreEqual(PaymentTypeGbl::"6", PaymentTypeGbl, GetPaymentTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLExport_PaymentType6_Negative_BlankedSWIFTCode()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerBankAccount: Record "Customer Bank Account";
        BankAccount: Record "Bank Account";
    begin
        // [FEATURE] [XML] [Export] [Customer]
        // [SCENARIO 275414] Swiss SEPA CT export for "Payment Type" = "6" in case of blanked bank account's "SWIFT Code"
        Initialize();

        // [GIVEN] Customer with bank account with "IBAN" and "Bank Account No."
        CreateCustomerWithBankAccount_AbroadWithBankAccNoAndIBAN(CustomerBankAccount);

        // [GIVEN] Customer payment journal line with "Currency Code" = ""
        CreatePaymentJournalLine(GenJournalLine, CustomerBankAccount."Customer No.", GetForeignCurrency(), '',
          GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Refund);

        // [GIVEN] Bank Account with "SWIFT Code" = ''
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccount."SWIFT Code" := '';
        BankAccount.Modify();

        // [WHEN] Export payments to file
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] The file export has one or more errors ("SWIFT Code" must be specified)
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(ExportHasErrorsErr);
        VerifyPaymentJnlExportErrorText(
          GenJournalLine,
          StrSubstNo(
            FieldKeyBlankErr, BankAccount.TableCaption(), GenJournalLine."Bal. Account No.", BankAccount.FieldCaption("SWIFT Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Customer_XMLExport_Negative_BlankedIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        // [FEATURE] [XML] [Export] [Customer]
        // [SCENARIO 275414] Swiss SEPA CT export in case of blanked customer bank account's "IBAN"
        Initialize();

        // [GIVEN] Customer with bank account with "IBAN" = '' and "Bank Account No."
        CreateCustomerWithPreferredBankAccount(CustomerBankAccount, '', GetSWIFT(false), '', '');
        CustomerBankAccount."Bank Account No." := LibraryUtility.GenerateGUID();
        CustomerBankAccount.Modify();

        // [GIVEN] Customer payment journal line with "Currency Code" = ""
        CreatePaymentJournalLine(GenJournalLine, CustomerBankAccount."Customer No.", GetForeignCurrency(), '',
          GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Refund);

        // [WHEN] Export payments to file
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] The file export has one or more errors ("IBAN" must be specified)
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(ExportHasErrorsErr);
        VerifyPaymentJnlExportErrorText(
          GenJournalLine,
          StrSubstNo(
            FieldKeyBlankErr, CustomerBankAccount.TableCaption(), CustomerBankAccount.Code, CustomerBankAccount.FieldCaption(IBAN)));
    end;

    [Test]
    [HandlerFunctions('CreatePaymentModalPageHandler,PaymentJournalModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePaymentWithReferenceNo()
    var
        GenJournalLineInvoice: Record "Gen. Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // [FEATURE] [Create Payment]
        // [SCENARIO 319395] Reference No. is transferred to Gen. Journal Line via Create Payment from Vendor Ledger Entries page
        Initialize();

        // [GIVEN] Vendor Invoice "VI001" is posted with Reference No. = "Ref00001"
        CreatePostGenJnlPurchInvoiceWithReferenceNo(GenJournalLineInvoice);
        CreateGenJournalBatchAndTemplate(GenJournalBatch, GenJournalTemplate);
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);

        // [WHEN] Create Payment for vendor invoice "VI001"
        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.FILTER.SetFilter("Vendor No.", GenJournalLineInvoice."Account No.");
        VendorLedgerEntries."Create Payment".Invoke();

        // [THEN] Gen. Journal Line is created for vendor invoice "VI001" with Reference No. = "Ref00001"
        GenJournalLine.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Reference No.", GenJournalLineInvoice."Reference No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure XMLExport_PaymentType21_QRReferenceNormalIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export] [Payment Reference]
        // [SCENARIO 423342] Swiss SEPA CT export for "Payment Type" = "2.1" in case of normal IBAN + QR Payment Reference.
        Initialize();

        // [GIVEN] Vendor payment journal line for Payment Type = "2.1" and filled-in QR Payment Reference.
        // [GIVEN] Vendor Bank Account has normal IBAN (not QR-IBAN).
        VendorNo := CreateVendorWithBankAccount_GiroPost();
        CreateVendPmtJnlLineWithPaymentReference(GenJournalLine, VendorNo, '', GetQRReferenceNo());

        // [WHEN] Export payment to file.
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "2.1"
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"2.1");
    end;

    [Test]
    procedure XMLExport_PaymentType21_CRReferenceNormalIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export] [Payment Reference]
        // [SCENARIO 426123] Swiss SEPA CT export for "Payment Type" = "2.1" in case of normal IBAN + CR Payment Reference.
        Initialize();

        // [GIVEN] Vendor payment journal line for Payment Type = "2.1" and filled-in CR Payment Reference.
        // [GIVEN] Vendor Bank Account has normal IBAN (not QR-IBAN).
        VendorNo := CreateVendorWithBankAccount_GiroPost();
        CreateVendPmtJnlLineWithPaymentReference(GenJournalLine, VendorNo, '', GetCRReferenceNo());

        // [WHEN] Export payment to file.
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "2.1".
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"2.1");
    end;

    [Test]
    procedure XMLExport_PaymentType22_QRReferenceNormalIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export] [Payment Reference]
        // [SCENARIO 423342] Swiss SEPA CT export for "Payment Type" = "2.2" in case of normal IBAN and QR Payment Reference.
        Initialize();

        // [GIVEN] Vendor payment journal line for Payment Type = "2.2" and filled-in QR Payment Reference.
        // [GIVEN] Vendor Bank Account has normal IBAN (not QR-IBAN).
        VendorNo := CreateVendorWithBankAccount_Clearing();
        CreateVendPmtJnlLineWithPaymentReference(GenJournalLine, VendorNo, '', GetQRReferenceNo());

        // [WHEN] Export payment to file.
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File was not exported, an error is thrown: Payment Reference of QR type must only be used with Payment Type 3.
        VerifyPaymentJnlExportErrorText(GenJournalLine, QRRefErr);
    end;

    [Test]
    procedure XMLExport_PaymentType22_CRReferenceQRIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export] [Payment Reference]
        // [SCENARIO 423342] Swiss SEPA CT export for "Payment Type" = "2.2" in case of QR-IBAN and CR Payment Reference.
        Initialize();

        // [GIVEN] Vendor payment journal line for Payment Type = "2.2" and filled-in CR Payment Reference.
        // [GIVEN] Vendor Bank Account has QR-IBAN.
        VendorNo := CreateVendorWithBankAccount_Clearing();
        UpdateVendorBankAccIBAN(VendorNo, GetQRIBAN());
        CreateVendPmtJnlLineWithPaymentReference(GenJournalLine, VendorNo, '', GetCRReferenceNo());

        // [WHEN] Export payment to file.
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File was not exported, an error is thrown: IBAN of QR-IBAN type must only be used with Payment Type 3.
        VerifyPaymentJnlExportErrorText(GenJournalLine, QRIBANErr);
    end;

    [Test]
    procedure XMLExport_PaymentType22_QRReferenceQRIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export] [Payment Reference]
        // [SCENARIO 423342] Swiss SEPA CT export for "Payment Type" = "2.2" in case of QR-IBAN and QR Payment Reference.
        Initialize();

        // [GIVEN] Vendor payment journal line for Payment Type = "2.2" and filled-in QR Payment Reference.
        // [GIVEN] Vendor Bank Account has QR-IBAN.
        VendorNo := CreateVendorWithBankAccount_Clearing();
        UpdateVendorBankAccIBAN(VendorNo, GetQRIBAN());
        CreateVendPmtJnlLineWithPaymentReference(GenJournalLine, VendorNo, '', GetQRReferenceNo());

        // [WHEN] Export payment to file.
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File was not exported, two errors are thrown: Payment Reference of QR type and IBAN of QR-IBAN type must only be used with Payment Type 3.
        PaymentJnlExportErrorText.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        PaymentJnlExportErrorText.SetRange("Journal Line No.", GenJournalLine."Line No.");
        Assert.RecordCount(PaymentJnlExportErrorText, 2);
        PaymentJnlExportErrorText.FindFirst();
        PaymentJnlExportErrorText.TestField("Error Text", QRRefErr);
        PaymentJnlExportErrorText.Next();
        PaymentJnlExportErrorText.TestField("Error Text", QRIBANErr);
    end;

    [Test]
    procedure XMLExport_PaymentType22_CRReferenceNormalIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export] [Payment Reference]
        // [SCENARIO 426123] Swiss SEPA CT export for "Payment Type" = "2.2" in case of normal IBAN + CR Payment Reference.
        Initialize();

        // [GIVEN] Vendor payment journal line for Payment Type = "2.2" and filled-in CR Payment Reference.
        // [GIVEN] Vendor Bank Account has normal IBAN (not QR-IBAN).
        VendorNo := CreateVendorWithBankAccount_Clearing();
        CreateVendPmtJnlLineWithPaymentReference(GenJournalLine, VendorNo, '', GetCRReferenceNo());

        // [WHEN] Export payment to file.
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "2.2".
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"2.2");
    end;

    [Test]
    procedure XMLExport_PaymentType22_UnstrdReferenceNormalIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export] [Payment Reference]
        // [SCENARIO 426123] Swiss SEPA CT export for "Payment Type" = "2.2" in case of normal IBAN + unstructured Payment Reference.
        Initialize();

        // [GIVEN] Vendor payment journal line for Payment Type = "2.2" and filled-in unstructured Payment Reference.
        // [GIVEN] Vendor Bank Account has normal IBAN (not QR-IBAN).
        VendorNo := CreateVendorWithBankAccount_Clearing();
        CreateVendPmtJnlLineWithPaymentReference(GenJournalLine, VendorNo, '', LibraryUtility.GenerateGUID());

        // [WHEN] Export payment to file.
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "2.2". "SCOR" and IBAN were not added under <CdOrPrtry> tag.
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"2.2");
    end;

    [Test]
    procedure XMLExport_PaymentType3_QRReferenceNormalIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export] [Payment Reference]
        // [SCENARIO 423342] Swiss SEPA CT export for "Payment Type" = "3" in case of QR Payment Reference and normal IBAN.
        Initialize();

        // [GIVEN] Vendor payment journal line for Payment Type = "3" and filled-in QR Payment Reference.
        // [GIVEN] Vendor Bank Account has normal IBAN (not QR-IBAN).
        VendorNo := CreateVendorWithBankAccount_DomesticSWIFT();
        CreateVendPmtJnlLineWithPaymentReference(GenJournalLine, VendorNo, '', GetQRReferenceNo());

        // [WHEN] Export payment to file.
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File was not exported, an error about matching Payment Reference type and IBAN type is thrown.
        VerifyPaymentJnlExportErrorText(GenJournalLine, IBANTypeErr);
    end;

    [Test]
    procedure XMLExport_PaymentType3_CRReferenceQRIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export] [Payment Reference]
        // [SCENARIO 423342] Swiss SEPA CT export for "Payment Type" = "3" in case of CR Payment Reference and QR-IBAN.
        Initialize();

        // [GIVEN] Vendor payment journal line for Payment Type = "3" and filled-in CR Payment Reference.
        // [GIVEN] Vendor Bank Account has QR-IBAN.
        VendorNo := CreateVendorWithBankAccount_DomesticSWIFT();
        UpdateVendorBankAccIBAN(VendorNo, GetQRIBAN());
        CreateVendPmtJnlLineWithPaymentReference(GenJournalLine, VendorNo, '', GetCRReferenceNo());

        // [WHEN] Export payment to file.
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File was not exported, an error about matching Payment Reference type and IBAN type is thrown.
        VerifyPaymentJnlExportErrorText(GenJournalLine, IBANTypeErr);
    end;

    [Test]
    procedure XMLExport_PaymentType3_UstrdReferenceQRIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export] [Payment Reference]
        // [SCENARIO 423342] Swiss SEPA CT export for "Payment Type" = "3" in case of unstructured Payment Reference and QR-IBAN.
        Initialize();

        // [GIVEN] Vendor payment journal line for Payment Type = "3" and filled-in unstructured Payment Reference.
        // [GIVEN] Vendor Bank Account has QR-IBAN.
        VendorNo := CreateVendorWithBankAccount_DomesticSWIFT();
        UpdateVendorBankAccIBAN(VendorNo, GetQRIBAN());
        CreateVendPmtJnlLineWithPaymentReference(GenJournalLine, VendorNo, '', LibraryUtility.GenerateGUID());

        // [WHEN] Export payment to file.
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File was not exported, an error about matching Payment Reference type and IBAN type is thrown.
        VerifyPaymentJnlExportErrorText(GenJournalLine, IBANTypeErr);
    end;

    [Test]
    procedure XMLExport_PaymentType3_BlankReferenceQRIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export] [Payment Reference]
        // [SCENARIO 432184] Swiss SEPA CT export for "Payment Type" = "3" in case of blank Payment Reference and QR-IBAN.
        Initialize();

        // [GIVEN] Vendor payment journal line for Payment Type = "3" and blank Payment Reference.
        // [GIVEN] Vendor Bank Account has QR-IBAN.
        VendorNo := CreateVendorWithBankAccount_DomesticSWIFT();
        UpdateVendorBankAccIBAN(VendorNo, GetQRIBAN());
        CreateVendPmtJnlLineWithPaymentReference(GenJournalLine, VendorNo, '', '');

        // [WHEN] Export payment to file.
        asserterror GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File was not exported, an error about matching Payment Reference type and IBAN type is thrown.
        VerifyPaymentJnlExportErrorText(GenJournalLine, IBANTypeErr);
    end;

    [Test]
    procedure XMLExport_PaymentType3_QRReferenceQRIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export] [Payment Reference]
        // [SCENARIO 423342] Swiss SEPA CT export for "Payment Type" = "3" in case of QR Payment Reference and QR-IBAN.
        Initialize();

        // [GIVEN] Vendor payment journal line for Payment Type = "3" and filled-in QR Payment Reference.
        // [GIVEN] Vendor Bank Account has QR-IBAN.
        VendorNo := CreateVendorWithBankAccount_DomesticSWIFT();
        UpdateVendorBankAccIBAN(VendorNo, GetQRIBAN());
        CreateVendPmtJnlLineWithPaymentReference(GenJournalLine, VendorNo, '', GetQRReferenceNo());

        // [WHEN] Export payment to file.
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "3".
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"3");
    end;

    [Test]
    procedure XMLExport_PaymentType3_CRReferenceNormalIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export] [Payment Reference]
        // [SCENARIO 423342] Swiss SEPA CT export for "Payment Type" = "3" in case of CR Payment Reference and normal IBAN.
        Initialize();

        // [GIVEN] Vendor payment journal line for Payment Type = "3" and filled-in CR Payment Reference.
        // [GIVEN] Vendor Bank Account has normal IBAN (not QR-IBAN).
        VendorNo := CreateVendorWithBankAccount_DomesticSWIFT();
        CreateVendPmtJnlLineWithPaymentReference(GenJournalLine, VendorNo, '', GetCRReferenceNo());

        // [WHEN] Export payment to file.
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "3".
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"3");
    end;

    [Test]
    procedure XMLExport_PaymentType3_UstrdReferenceNormalIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export] [Payment Reference]
        // [SCENARIO 426123] Swiss SEPA CT export for "Payment Type" = "3" in case of unstructured Payment Reference and normal IBAN.
        Initialize();

        // [GIVEN] Vendor payment journal line for Payment Type = "3" and filled-in unstructured Payment Reference.
        // [GIVEN] Vendor Bank Account has normal IBAN (not QR-IBAN).
        VendorNo := CreateVendorWithBankAccount_DomesticSWIFT();
        CreateVendPmtJnlLineWithPaymentReference(GenJournalLine, VendorNo, '', LibraryUtility.GenerateGUID());

        // [WHEN] Export payment to file.
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "3". "SCOR" and IBAN were not added under <CdOrPrtry> tag.
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"3");
    end;

    [Test]
    procedure XMLExport_PaymentType3_BlankReferenceNormalIBAN()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        MessageID: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [XML] [Export] [Payment Reference]
        // [SCENARIO 432184] Swiss SEPA CT export for "Payment Type" = "3" in case of blank Payment Reference and normal IBAN.
        Initialize();

        // [GIVEN] Vendor payment journal line for Payment Type = "3" and blank Payment Reference.
        // [GIVEN] Vendor Bank Account has normal IBAN (not QR-IBAN).
        VendorNo := CreateVendorWithBankAccount_DomesticSWIFT();
        CreateVendPmtJnlLineWithPaymentReference(GenJournalLine, VendorNo, '', '');

        // [WHEN] Export payment to file.
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "3". "SCOR" and IBAN were not added under <CdOrPrtry> tag.
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"3");
    end;

    [Test]
    procedure XMLExport_PaymentType5_QRReference()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        FileName: Text;
        MessageID: Text;
    begin
        // [FEATURE] [XML] [Export] [Payment Reference]
        // [SCENARIO 357682] Swiss SEPA CT export for "Payment Type" = "5" in case of QR Payment Reference
        Initialize();

        // [GIVEN] Vendor payment journal line for Payment Type = "5" and filled-in QR Payment Reference
        CreateVendorWithBankAccount_AbroadSEPA(VendorBankAccount);
        CreateVendPmtJnlLineWithPaymentReference(GenJournalLine, VendorBankAccount."Vendor No.", GetEURCurrency(), GetQRReferenceNo());

        // [WHEN] Export payment to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "5"
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"5");
    end;

    [Test]
    procedure XMLExport_PaymentType5_CRReference()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        FileName: Text;
        MessageID: Text;
    begin
        // [FEATURE] [XML] [Export] [Payment Reference]
        // [SCENARIO 357682] Swiss SEPA CT export for "Payment Type" = "5" in case of CR Payment Reference
        Initialize();

        // [GIVEN] Vendor payment journal line for Payment Type = "5" and filled-in CR Payment Reference
        CreateVendorWithBankAccount_AbroadSEPA(VendorBankAccount);
        CreateVendPmtJnlLineWithPaymentReference(GenJournalLine, VendorBankAccount."Vendor No.", GetEURCurrency(), GetCRReferenceNo());

        // [WHEN] Export payment to file
        MessageID := GetMessageID(GenJournalLine."Bal. Account No.");
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        // [THEN] XML File has been exported with correct Swiss SEPA CT scheme for "Payment Type" = "5"
        VerifyXMLFile(GenJournalLine, FileName, MessageID, PaymentTypeGbl::"5");
    end;

    [Test]
    procedure XMLExport_Combined_Type1_Type3SCOR_Type3QRR()
    var
        VendorNo: array[3] of Code[20];
        PaymentReferenceNo: array[3] of Code[50];
        ESRReferenceNo: array[3] of Code[50];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 381289] Swiss SEPA CT combined export for 3 lines: Payment Type 1, Payment Type 3-SCOR, Payment Type 3-QRR
        Initialize();

        // [GIVEN] Payment journal with 3 lines for different vendors having: Payment Type 1, Payment Type 3-SCOR, Payment Type 3-QRR + QR-IBAN
        VendorNo[1] := CreateVendorWithBankAccount_ESR();
        VendorNo[2] := CreateVendorWithBankAccount_DomesticSWIFT();
        VendorNo[3] := CreateVendorWithBankAccount_DomesticSWIFT();
        UpdateVendorBankAccIBAN(VendorNo[3], GetQRIBAN());
        ESRReferenceNo[1] := GetReferenceNo();
        PaymentReferenceNo[2] := GetCRReferenceNo();
        PaymentReferenceNo[3] := GetQRReferenceNo();

        // [WHEN] Export payment journal to xml
        // [THEN] "CdOrPrtry" tag: is not exported for Type1, exported with "SCOR" value for Type3-SCOR and "QRR" value for Type3-QRR
        VerifyXMLExportForSevCombinedLines(VendorNo, PaymentReferenceNo, ESRReferenceNo);
    end;

    [Test]
    procedure XMLExport_Combined_Type1_Type3QRR_Type3SCOR()
    var
        VendorNo: array[3] of Code[20];
        PaymentReferenceNo: array[3] of Code[50];
        ESRReferenceNo: array[3] of Code[50];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 381289] Swiss SEPA CT combined export for 3 lines: Payment Type 1, Payment Type 3-QRR, Payment Type 3-SCOR
        Initialize();

        // [GIVEN] Payment journal with 3 lines for different vendors having: Payment Type 1, Payment Type 3-QRR + QR-IBAN, Payment Type 3-SCOR
        VendorNo[1] := CreateVendorWithBankAccount_ESR();
        VendorNo[2] := CreateVendorWithBankAccount_DomesticSWIFT();
        VendorNo[3] := CreateVendorWithBankAccount_DomesticSWIFT();
        UpdateVendorBankAccIBAN(VendorNo[2], GetQRIBAN());
        ESRReferenceNo[1] := GetReferenceNo();
        PaymentReferenceNo[2] := GetQRReferenceNo();
        PaymentReferenceNo[3] := GetCRReferenceNo();

        // [WHEN] Export payment journal to xml
        // [THEN] "CdOrPrtry" tag: is not exported for Type1, exported with "SCOR" value for Type3-SCOR and "QRR" value for Type3-QRR
        VerifyXMLExportForSevCombinedLines(VendorNo, PaymentReferenceNo, ESRReferenceNo);
    end;

    [Test]
    procedure XMLExport_Combined_Type3SCOR_Type1_Type3QRR()
    var
        VendorNo: array[3] of Code[20];
        PaymentReferenceNo: array[3] of Code[50];
        ESRReferenceNo: array[3] of Code[50];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 381289] Swiss SEPA CT combined export for 3 lines: Payment Type 3-SCOR, Payment Type 1, Payment Type 3-QRR
        Initialize();

        // [GIVEN] Payment journal with 3 lines for different vendors having: Payment Type 3-SCOR, Payment Type 1, Payment Type 3-QRR + QR-IBAN
        VendorNo[1] := CreateVendorWithBankAccount_DomesticSWIFT();
        VendorNo[2] := CreateVendorWithBankAccount_ESR();
        VendorNo[3] := CreateVendorWithBankAccount_DomesticSWIFT();
        UpdateVendorBankAccIBAN(VendorNo[3], GetQRIBAN());
        PaymentReferenceNo[1] := GetCRReferenceNo();
        ESRReferenceNo[2] := GetReferenceNo();
        PaymentReferenceNo[3] := GetQRReferenceNo();

        // [WHEN] Export payment journal to xml
        // [THEN] "CdOrPrtry" tag: is not exported for Type1, exported with "SCOR" value for Type3-SCOR and "QRR" value for Type3-QRR
        VerifyXMLExportForSevCombinedLines(VendorNo, PaymentReferenceNo, ESRReferenceNo);
    end;

    [Test]
    procedure XMLExport_Combined_Type3SCOR_Type3QRR_Type1()
    var
        VendorNo: array[3] of Code[20];
        PaymentReferenceNo: array[3] of Code[50];
        ESRReferenceNo: array[3] of Code[50];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 381289] Swiss SEPA CT combined export for 3 lines: Payment Type 3-SCOR, Payment Type 3-QRR, Payment Type 1
        Initialize();

        // [GIVEN] Payment journal with 3 lines for different vendors having: Payment Type 3-SCOR, Payment Type 3-QRR + QR-IBAN, Payment Type 1
        VendorNo[1] := CreateVendorWithBankAccount_DomesticSWIFT();
        VendorNo[2] := CreateVendorWithBankAccount_DomesticSWIFT();
        VendorNo[3] := CreateVendorWithBankAccount_ESR();
        UpdateVendorBankAccIBAN(VendorNo[2], GetQRIBAN());
        PaymentReferenceNo[1] := GetCRReferenceNo();
        PaymentReferenceNo[2] := GetQRReferenceNo();
        ESRReferenceNo[3] := GetReferenceNo();

        // [WHEN] Export payment journal to xml
        // [THEN] "CdOrPrtry" tag: is not exported for Type1, exported with "SCOR" value for Type3-SCOR and "QRR" value for Type3-QRR
        VerifyXMLExportForSevCombinedLines(VendorNo, PaymentReferenceNo, ESRReferenceNo);
    end;

    [Test]
    procedure XMLExport_Combined_Type3QRR_Type3SCOR_Type1()
    var
        VendorNo: array[3] of Code[20];
        PaymentReferenceNo: array[3] of Code[50];
        ESRReferenceNo: array[3] of Code[50];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 381289] Swiss SEPA CT combined export for 3 lines: Payment Type 3-QRR, Payment Type 3-SCOR, Payment Type 1
        Initialize();

        // [GIVEN] Payment journal with 3 lines for different vendors having: Payment Type 3-QRR + QR-IBAN, Payment Type 3-SCOR, Payment Type 1
        VendorNo[1] := CreateVendorWithBankAccount_DomesticSWIFT();
        VendorNo[2] := CreateVendorWithBankAccount_DomesticSWIFT();
        VendorNo[3] := CreateVendorWithBankAccount_ESR();
        UpdateVendorBankAccIBAN(VendorNo[1], GetQRIBAN());
        PaymentReferenceNo[1] := GetQRReferenceNo();
        PaymentReferenceNo[2] := GetCRReferenceNo();
        ESRReferenceNo[3] := GetReferenceNo();

        // [WHEN] Export payment journal to xml
        // [THEN] "CdOrPrtry" tag: is not exported for Type1, exported with "SCOR" value for Type3-SCOR and "QRR" value for Type3-QRR
        VerifyXMLExportForSevCombinedLines(VendorNo, PaymentReferenceNo, ESRReferenceNo);
    end;

    [Test]
    procedure XMLExport_Combined_Type3QRR_Type1_Type3SCOR()
    var
        VendorNo: array[3] of Code[20];
        PaymentReferenceNo: array[3] of Code[50];
        ESRReferenceNo: array[3] of Code[50];
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 381289] Swiss SEPA CT combined export for 3 lines: Payment Type 3-QRR, Payment Type 1, Payment Type 3-SCOR
        Initialize();

        // [GIVEN] Payment journal with 3 lines for different vendors having: Payment Type 3-QRR + QR-IBAN, Payment Type 1, Payment Type 3-SCOR
        VendorNo[1] := CreateVendorWithBankAccount_DomesticSWIFT();
        VendorNo[2] := CreateVendorWithBankAccount_ESR();
        VendorNo[3] := CreateVendorWithBankAccount_DomesticSWIFT();
        UpdateVendorBankAccIBAN(VendorNo[1], GetQRIBAN());
        PaymentReferenceNo[1] := GetQRReferenceNo();
        ESRReferenceNo[2] := GetReferenceNo();
        PaymentReferenceNo[3] := GetCRReferenceNo();

        // [WHEN] Export payment journal to xml
        // [THEN] "CdOrPrtry" tag: is not exported for Type1, exported with "SCOR" value for Type3-SCOR and "QRR" value for Type3-QRR
        VerifyXMLExportForSevCombinedLines(VendorNo, PaymentReferenceNo, ESRReferenceNo);
    end;

    [Test]
    procedure PaymentReferenceNonNumericValueInPaymentJournal()
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 466837] Non-numeric values in Payment Reference field in Payment Journal.
        Initialize();

        // [GIVEN] Opened Payment Journal.
        PaymentJournal.OpenEdit();

        // [WHEN] Set alphabetical value to Payment Reference field.
        PaymentJournal."Payment Reference".SetValue('ABC');

        // [THEN] The value was set.
        Assert.AreEqual('ABC', PaymentJournal."Payment Reference".Value, '');

        // [WHEN] Set special characters as a value to Payment Reference field.
        PaymentJournal."Payment Reference".SetValue('{!@#}');

        // [THEN] The value was set.
        Assert.AreEqual('{!@#}', PaymentJournal."Payment Reference".Value, '');
    end;

    [Test]
    procedure PaymentReferenceNonNumericValueInPurchaseInvoice()
    var
        PurchaseInvoiceCard: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI] [Purchase]
        // [SCENARIO 466837] Non-numeric values in Payment Reference field in Purchase Invoice.
        Initialize();

        // [GIVEN] Opened Purchase Invoice card.
        PurchaseInvoiceCard.OpenNew();

        // [WHEN] Set alphabetical value to Payment Reference field.
        PurchaseInvoiceCard."Payment Reference".SetValue('ABC');

        // [THEN] The value was set.
        Assert.AreEqual('ABC', PurchaseInvoiceCard."Payment Reference".Value, '');

        // [WHEN] Set special characters as a value to Payment Reference field.
        PurchaseInvoiceCard."Payment Reference".SetValue('{!@#}');

        // [THEN] The value was set.
        Assert.AreEqual('{!@#}', PurchaseInvoiceCard."Payment Reference".Value, '');
    end;

    [Test]
    [HandlerFunctions('PostedPurchInvUpdatePaymentRefModalPageHandler')]
    procedure PaymentReferenceNonNumericValueInPostedPurchaseInvoice()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [UI] [Purchase]
        // [SCENARIO 466837] Non-numeric values in Payment Reference field in Posted Purchase Invoice.
        Initialize();

        // [GIVEN] Opened Posted Purchase Invoice card.
        PostedPurchaseInvoice.OpenView();

        // [WHEN] Open Update Document page, set alphabetical value to Payment Reference field using PostedPurchInvUpdatePaymentRefModalPageHandler.
        LibraryVariableStorage.Enqueue('ABC');
        PostedPurchaseInvoice."Update Document".Invoke();

        // [THEN] The value was set.
        PurchInvHeader.Get(PostedPurchaseInvoice."No.".Value);
        Assert.AreEqual('ABC', PurchInvHeader."Payment Reference", '');

        // [WHEN] Open Update Document page, set special characters as a value to Payment Reference field using PostedPurchInvUpdatePaymentRefModalPageHandler.
        LibraryVariableStorage.Enqueue('{!@#}');
        PostedPurchaseInvoice."Update Document".Invoke();

        // [THEN] The value was set.
        PurchInvHeader.Get(PostedPurchaseInvoice."No.".Value);
        Assert.AreEqual('{!@#}', PurchInvHeader."Payment Reference", '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure PaymentReferenceNonNumericValueInVendorLedgerEntry()
    var
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // [FEATURE] [UI] [Purchase]
        // [SCENARIO 466837] Non-numeric values in Payment Reference field in Vendor Ledger Entry.
        Initialize();

        // [GIVEN] Opened Vendor Ledger Entries list.
        VendorLedgerEntries.OpenEdit();

        // [WHEN] Set alphabetical value to Payment Reference field.
        VendorLedgerEntries."Payment Reference".SetValue('ABC');

        // [THEN] The value was set.
        Assert.AreEqual('ABC', VendorLedgerEntries."Payment Reference".Value, '');

        // [WHEN] Set special characters as a value to Payment Reference field.
        VendorLedgerEntries."Payment Reference".SetValue('{!@#}');

        // [THEN] The value was set.
        Assert.AreEqual('{!@#}', VendorLedgerEntries."Payment Reference".Value, '');
    end;

    [Test]
    procedure IsSwissSEPACTExportWhenEmptyBalAccInBatch()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        CHMgt: Codeunit CHMgt;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 470690] Run IsSwissSEPACTExport() of codeunit 11503 CHMgt when Bal. Account is empty in batch and not empty in Gen. Journal Line.

        // [GIVEN] Gen. Journal Batch with empty Bal. Account No.
        CreateGenJournalBatch(GenJournalBatch, '');

        // [GIVEN] Gen. Journal Line with non-empty Bal. Account No.
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Bal. Account No." := CreateBankAccount(FindSwissSEPACTBankExpImpCode());
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");

        // [WHEN] Run IsSwissSEPACTExport() of codeunit 11503 CHMgt.
        // [THEN] The function returns true.
        Assert.IsTrue(CHMgt.IsSwissSEPACTExport(GenJournalLine), '');
    end;

    [Test]
    procedure IsSwissSEPACTExportWhenEmptyBalAccInBatchAndLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        CHMgt: Codeunit CHMgt;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 470690] Run IsSwissSEPACTExport() of codeunit 11503 CHMgt when Bal. Account is empty in batch and empty in Gen. Journal Line.

        // [GIVEN] Gen. Journal Batch with empty Bal. Account No.
        CreateGenJournalBatch(GenJournalBatch, '');

        // [GIVEN] Gen. Journal Line with empty Bal. Account No.
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Bal. Account No." := '';
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");

        // [WHEN] Run IsSwissSEPACTExport() of codeunit 11503 CHMgt.
        // [THEN] The function returns false.
        Assert.IsFalse(CHMgt.IsSwissSEPACTExport(GenJournalLine), '');
    end;

    local procedure Initialize()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Swiss SEPA CT Export");
        LibraryVariableStorage.Clear();
        Clear(LibraryXMLRead);
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Swiss SEPA CT Export");
        IsInitialized := true;

        UpdateCompanyInfo();
        GLSetup.Get();
        GLSetup.TestField("LCY Code", 'CHF');

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Swiss SEPA CT Export");
    end;

    local procedure InitGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PaymentExportFormat: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch, CreateBankAccount(PaymentExportFormat));
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
    end;

    local procedure CreatePaymentJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; CurrencyCode: Code[10]; ReferenceNo: Code[35]; AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch, CreateBankAccount(FindSwissSEPACTBankExpImpCode()));
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            DocumentType, AccountType, AccountNo, GenJournalLine."Bal. Account Type"::"Bank Account",
            GenJournalBatch."Bal. Account No.", LibraryRandom.RandDecInRange(1000, 2000, 2));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Reference No.", ReferenceNo);
        GenJournalLine.Validate("Message to Recipient", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        GenJournalLine.SetRecFilter();
    end;

    local procedure CreateVendPmtJnlLineWithPaymentReference(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; CurrencyCode: Code[10]; PaymentReference: Code[50])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch, CreateBankAccount(FindSwissSEPACTBankExpImpCode()));
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, AccountNo, GenJournalLine."Bal. Account Type"::"Bank Account",
            GenJournalBatch."Bal. Account No.", LibraryRandom.RandDecInRange(1000, 2000, 2));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Payment Reference", PaymentReference);
        GenJournalLine.Validate("Message to Recipient", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        GenJournalLine.SetRecFilter();
    end;

    local procedure CreateSetOfPaymentJournalLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; PaymentQty: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        i: Integer;
    begin
        CreateGenJournalBatch(GenJournalBatch, CreateBankAccount(FindSwissSEPACTBankExpImpCode()));
        for i := 1 to PaymentQty do begin
            LibraryJournals.CreateGenJournalLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
              GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo, GenJournalLine."Bal. Account Type"::"Bank Account",
              GenJournalBatch."Bal. Account No.", LibraryRandom.RandDecInRange(1000, 2000, 2));
            GenJournalLine.Validate("Reference No.", GetReferenceNo());
            GenJournalLine.Modify(true);
        end;
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
    end;

    local procedure CreateBankAccount(PaymentExportFormat: Code[20]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.IBAN := GetIBAN(true);
        BankAccount."SWIFT Code" := GetSWIFT(true);
        BankAccount.Validate("Payment Export Format", PaymentExportFormat);
        BankAccount.Validate("Credit Transfer Msg. Nos.", LibraryERM.CreateNoSeriesCode());
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateCustomerWithBankAccount(GiroAccountNo: Code[11]; SWIFTCode: Code[20]; NewIBAN: Code[50]): Code[20]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CreateCustomerWithPreferredBankAccount(
          CustomerBankAccount, GiroAccountNo, SWIFTCode, NewIBAN, '');
        exit(CustomerBankAccount."Customer No.");
    end;

    local procedure CreateCustomerWithPreferredBankAccount(var CustomerBankAccount: Record "Customer Bank Account"; GiroAccountNo: Code[11]; SWIFTCode: Code[20]; NewIBAN: Code[50]; CountryCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(LibrarySales.CreateCustomerNo());
        CreateCustomerBankAccount(
          CustomerBankAccount, Customer."No.", GiroAccountNo, SWIFTCode, NewIBAN, CountryCode);
        Customer.Validate("Preferred Bank Account Code", CustomerBankAccount.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account"; CustomerNo: Code[20]; GiroAccountNo: Code[11]; SWIFTCode: Code[20]; NewIBAN: Code[50]; CountryCode: Code[10]): Code[20]
    begin
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CustomerNo);
        CustomerBankAccount."Giro Account No." := GiroAccountNo;
        CustomerBankAccount."SWIFT Code" := SWIFTCode;
        CustomerBankAccount.IBAN := NewIBAN;
        CustomerBankAccount."Country/Region Code" := CountryCode;
        CustomerBankAccount.Modify(true);
        exit(CustomerBankAccount.Code);
    end;

    local procedure CreateCustomerWithBankAccount_AbroadWithBankAccNoAndIBAN(var CustomerBankAccount: Record "Customer Bank Account")
    begin
        CreateCustomerWithPreferredBankAccount(CustomerBankAccount, '', GetSWIFT(false), GetIBAN(false), '');
        CustomerBankAccount."Bank Account No." := LibraryUtility.GenerateGUID();
        CustomerBankAccount.Modify();
    end;

    local procedure CreateCustomerWithBankAccount_DomesticIBAN(): Code[20]
    begin
        exit(CreateCustomerWithBankAccount('', '', GetIBAN(true)));
    end;

    local procedure CreateVendorWithBankAccount_ESR(): Code[20]
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        CreateVendorBankAccountESR(VendorBankAccount, CreateVendorNo(), PaymentFormGbl::ESR, GetESRAccountNo());

        Vendor.Get(VendorBankAccount."Vendor No.");
        Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithBankAccount_ESRPlus(): Code[20]
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        CreateVendorBankAccountESR(VendorBankAccount, CreateVendorNo(), PaymentFormGbl::"ESR+", GetESRAccountNo());

        Vendor.Get(VendorBankAccount."Vendor No.");
        Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithBankAccount_GiroPost(): Code[20]
    begin
        exit(CreateVendorWithBankAccount(PaymentFormGbl::"Post Payment Domestic", GetGiroAccountNo(), '', '', ''));
    end;

    local procedure CreateVendorWithBankAccount_Clearing(): Code[20]
    var
        BankDirectory: Record "Bank Directory";
    begin
        BankDirectory.FindFirst();
        exit(
          CreateVendorWithBankAccount(PaymentFormGbl::"Bank Payment Domestic", '', BankDirectory."Clearing No.", '', GetIBAN(true)));
    end;

    local procedure CreateVendorWithBankAccount_DomesticSWIFT(): Code[20]
    begin
        exit(CreateVendorWithBankAccount(PaymentFormGbl::"Bank Payment Domestic", '', '', GetSWIFT(true), GetIBAN(true)));
    end;

    local procedure CreateVendorWithBankAccount_AbroadSEPA(var VendorBankAccount: Record "Vendor Bank Account")
    begin
        CreateVendorWithPreferredBankAccount(
          VendorBankAccount,
          PaymentFormGbl::"Post Payment Abroad", '', '', '', GetIBAN(false), GetDomesticSEPACountry());
    end;

    local procedure CreateVendorWithBankAccount_Abroad(): Code[20]
    begin
        exit(CreateVendorWithBankAccount(PaymentFormGbl::"Bank Payment Abroad", '', '', GetSWIFT(false), GetIBAN(false)));
    end;

    local procedure CreateVendorWithBankAccount(PaymentForm: Option; GiroAccountNo: Code[11]; ClearingNo: Code[5]; SWIFTCode: Code[20]; NewIBAN: Code[50]): Code[20]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        CreateVendorWithPreferredBankAccount(
          VendorBankAccount, PaymentForm, GiroAccountNo, ClearingNo, SWIFTCode, NewIBAN, '');
        exit(VendorBankAccount."Vendor No.");
    end;

    local procedure CreateVendorWithPreferredBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; PaymentForm: Option; GiroAccountNo: Code[11]; ClearingNo: Code[5]; SWIFTCode: Code[20]; NewIBAN: Code[50]; CountryCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(CreateVendorNo());
        CreateVendorBankAccount(
          VendorBankAccount, Vendor."No.", PaymentForm, GiroAccountNo, ClearingNo, SWIFTCode, NewIBAN, CountryCode);
        Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; VendorNo: Code[20]; PaymentForm: Option; GiroAccountNo: Code[11]; ClearingNo: Code[5]; SWIFTCode: Code[20]; NewIBAN: Code[50]; CountryCode: Code[10]): Code[20]
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.Validate("Payment Form", PaymentForm);
        VendorBankAccount.Validate("Giro Account No.", GiroAccountNo);
        VendorBankAccount.Validate("Clearing No.", ClearingNo);
        VendorBankAccount.Validate("SWIFT Code", SWIFTCode);
        VendorBankAccount.Validate(IBAN, NewIBAN);
        VendorBankAccount.Validate("Country/Region Code", CountryCode);
        VendorBankAccount.Modify(true);
        exit(VendorBankAccount.Code);
    end;

    local procedure CreateVendorBankAccountESR(var VendorBankAccount: Record "Vendor Bank Account"; VendorNo: Code[20]; PaymentForm: Option; ESRAccountNo: Code[11])
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.Validate("Payment Form", PaymentForm);
        VendorBankAccount.Validate("ESR Type", VendorBankAccount."ESR Type"::"9/27");
        VendorBankAccount.Validate("ESR Account No.", ESRAccountNo);
        VendorBankAccount.Modify(true);
    end;

    local procedure CreateVendorWithBankAccount_AbroadWithIBANAndPstlAddr(var VendorBankAccount: Record "Vendor Bank Account")
    begin
        CreateVendorWithPreferredBankAccount(
          VendorBankAccount, PaymentFormGbl::"Bank Payment Abroad", '', '', '', GetIBAN(false), '');
        UpdateVendorBankAccNameAddr(VendorBankAccount);
        VendorBankAccount.Modify();
    end;

    local procedure CreateVendorWithBankAccount_AbroadWithBankAccNoAndSWIFT(var VendorBankAccount: Record "Vendor Bank Account")
    begin
        CreateVendorWithPreferredBankAccount(
          VendorBankAccount, PaymentFormGbl::"Bank Payment Abroad", '', '', GetSWIFT(false), '', '');
        VendorBankAccount."Bank Account No." := LibraryUtility.GenerateGUID();
        VendorBankAccount.Modify();
    end;

    local procedure CreateVendorWithBankAccount_AbroadWithBankAccNoAndPstlAddr(var VendorBankAccount: Record "Vendor Bank Account")
    begin
        CreateVendorWithPreferredBankAccount(
          VendorBankAccount, PaymentFormGbl::"Bank Payment Abroad", '', '', '', '', '');
        VendorBankAccount."Bank Account No." := LibraryUtility.GenerateGUID();
        UpdateVendorBankAccNameAddr(VendorBankAccount);
        VendorBankAccount.Modify();
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; BankAccountNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccountNo);
        GenJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreatePostPurchaseInvoice(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateGenJnlPurchDoc(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; LineAmount: Decimal; ReferenceNo: Code[35])
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, DocumentType, GenJournalLine."Account Type"::Vendor, VendorNo, LineAmount);
        GenJournalLine.Validate("Reference No.", ReferenceNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePostGenJnlPurchInvoiceWithReferenceNo(var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreatePostGenJnlPurchDoc(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateVendorWithBankAccount_ESR(),
          -LibraryRandom.RandDecInRange(1000, 2000, 2), GetReferenceNo());
    end;

    local procedure CreatePostGenJnlPurchCreditMemo(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; LineAmount: Decimal)
    begin
        CreatePostGenJnlPurchDoc(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", VendorNo, LineAmount, '');
    end;

    local procedure CreatePostGenJnlPurchDoc(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; LineAmount: Decimal; ReferenceNo: Code[35])
    begin
        CreateGenJnlPurchDoc(GenJournalLine, DocumentType, VendorNo, LineAmount, ReferenceNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostGenJnlPurchDocWithExternalDocNo(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; ExternalDocNo: Code[35])
    begin
        CreateGenJnlPurchDoc(
          GenJournalLine, DocumentType, VendorNo,
          -LibraryRandom.RandDecInRange(1000, 2000, 2), GetReferenceNo());
        GenJournalLine.Validate("External Document No.", ExternalDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostGenJnlPurchInvoiceWithNewVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, CreateVendorWithBankAccount_ESR(), -LibraryRandom.RandDec(100, 2));
        CreateVendorBankAccountESR(VendorBankAccount, GenJournalLine."Account No.", PaymentFormGbl::ESR, GetESRAccountNo());
        GenJournalLine.Validate("Reference No.", GetReferenceNo()); // required for ESR
        GenJournalLine.Validate("Recipient Bank Account", VendorBankAccount.Code);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateVendorNo(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Name, LibraryUtility.GenerateGUID());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryJournals.CreateGenJournalLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, CreateVendorWithBankAccount_DomesticSWIFT(),
          GenJournalLine."Bal. Account Type"::"Bank Account", GenJournalBatch."Bal. Account No.", LibraryRandom.RandIntInRange(10, 100));
        GenJournalLine."Recipient Bank Account" := GetPrefferedBankAccountNo(GenJournalLine."Account No.");
        GenJournalLine."Reference No." := LibraryUtility.GenerateGUID();
        GenJournalLine.Modify();
    end;

    local procedure CreateGenJournalBatchAndTemplate(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalTemplate: Record "Gen. Journal Template")
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.FindFirst();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", NoSeries.Code);
        GenJournalBatch.Modify(true);
    end;

    local procedure AddVendPmtJnlLineWithPaymentReference(GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; PaymentReference: Code[50]; ReferenceNo: Code[50])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, AccountNo,
          GenJournalLine."Bal. Account Type"::"Bank Account",
          GenJournalBatch."Bal. Account No.", LibraryRandom.RandDecInRange(1000, 2000, 2));
        GenJournalLine.Validate("Payment Reference", PaymentReference);
        GenJournalLine.Validate("Reference No.", CopyStr(ReferenceNo, 1, MaxStrLen(GenJournalLine."Reference No.")));
        GenJournalLine.Modify(true);
    end;

    local procedure GenJournalLine_XMLExport(var GenJournalLine: Record "Gen. Journal Line") FileName: Text
    begin
        FileName := SwissSEPACTExportFile(GenJournalLine);
        GenJournalLine.Find();
        Assert.IsTrue(GenJournalLine."Exported to Payment File", '');
        Commit(); // Prevent roll back in LibraryXMLRead.VerifyElementAbsenceInSubtree()
    end;

    local procedure UpdateCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Name := LibraryUtility.GenerateGUID();
        CompanyInformation."VAT Registration No." := LibraryUtility.GenerateGUID();
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateVendorBankAccNameAddr(var VendorBankAccount: Record "Vendor Bank Account")
    var
        CountryRegion: Record "Country/Region";
    begin
        VendorBankAccount.Name := LibraryUtility.GenerateGUID();
        VendorBankAccount.Address := LibraryUtility.GenerateGUID();
        VendorBankAccount."Post Code" := LibraryUtility.GenerateGUID();
        CountryRegion.Next(LibraryRandom.RandInt(10));
        VendorBankAccount."Country/Region Code" := CountryRegion.Code;
    end;

    local procedure UpdateVendorBankAccBIC(VendorNo: Code[20])
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        FindVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount."Bank Identifier Code" := LibraryUtility.GenerateGUID();
        VendorBankAccount.Modify();
    end;

    local procedure UpdateVendorBankAccPaymentFee(VendorNo: Code[20]; PaymentFee: Integer)
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount.SetRange("Vendor No.", VendorNo);
        VendorBankAccount.FindFirst();
        VendorBankAccount.Validate("Payment Fee Code", PaymentFee);
        VendorBankAccount.Modify(true);
    end;

    local procedure UpdateVendorBankAccIBAN(VendorNo: Code[20]; NewIBAN: Code[50])
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount.SetRange("Vendor No.", VendorNo);
        VendorBankAccount.FindFirst();
        VendorBankAccount.Validate(IBAN, NewIBAN);
        VendorBankAccount.Modify(true);
    end;

    local procedure FindW1SEPACTBankExpImpCode(): Code[20]
    begin
        exit(FindSEPACTBankExpImpCode(CODEUNIT::"SEPA CT-Export File"));
    end;

    local procedure FindSwissSEPACTBankExpImpCode(): Code[20]
    begin
        exit(FindSEPACTBankExpImpCode(CODEUNIT::"Swiss SEPA CT-Export File"));
    end;

    local procedure FindSEPACTBankExpImpCode(ProcDodeunitID: Integer): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.SetRange(Direction, BankExportImportSetup.Direction::Export);
        BankExportImportSetup.SetRange("Processing Codeunit ID", ProcDodeunitID);
        BankExportImportSetup.SetRange("Processing XMLport ID", XMLPORT::"SEPA CT pain.001.001.09");
        BankExportImportSetup.SetRange("Check Export Codeunit", CODEUNIT::"SEPA CT-Check Line");
        BankExportImportSetup.FindFirst();
        exit(BankExportImportSetup.Code);
    end;

    local procedure FindVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; VendorNo: Code[20])
    begin
        VendorBankAccount.SetRange("Vendor No.", VendorNo);
        VendorBankAccount.FindFirst();
    end;

    local procedure GetSWIFT(Domestic: Boolean): Code[20]
    begin
        if Domestic then
            exit('XXXXCHYY');
        exit('XXXXDEYY');
    end;

    local procedure GetIBAN(Domestic: Boolean): Code[50]
    begin
        if Domestic then
            exit('CH3808888123456789012');
        exit('DE62007620110623852957');
    end;

    local procedure GetQRIBAN(): Code[50]
    begin
        exit('CH9730024503254925417');
    end;

    local procedure GetReferenceNo(): Code[35]
    begin
        exit('310000000003139471430009010');
    end;

    local procedure GetReferenceNo2(): Code[35]
    begin
        exit('310000000001234567890009014');
    end;

    local procedure GetQRReferenceNo(): Code[50]
    begin
        exit('210000000003139471430009017');
    end;

    local procedure GetCRReferenceNo(): Code[50]
    begin
        exit('RF06000000000000000002001');
    end;

    local procedure GetMessageID(BankAccountNo: Code[20]): Text
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountNo);
        exit(LibraryUtility.GetNextNoFromNoSeries(BankAccount."Credit Transfer Msg. Nos.", Today));
    end;

    local procedure GetCurrencyCode(CurrencyCode: Code[10]): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if CurrencyCode <> '' then
            exit(CurrencyCode);

        GLSetup.Get();
        exit(GLSetup."LCY Code");
    end;

    local procedure GetEURCurrency(): Code[10]
    begin
        exit('EUR');
    end;

    local procedure GetForeignCurrency(): Code[10]
    begin
        exit('USD');
    end;

    local procedure GetDomesticSEPACountry(): Code[10]
    begin
        exit('CH');
    end;

    local procedure GetESRAccountNo(): Code[11]
    begin
        exit('01-039139-1');
    end;

    local procedure GetGiroAccountNo(): Code[11]
    begin
        exit('25-9034-2');
    end;

    local procedure GetPrefferedBankAccountNo(VendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        exit(Vendor."Preferred Bank Account Code");
    end;

    local procedure GetChargeBearerFromPaymentFeeCode(var ChargeBearer: Option DEBT,CRED,SHAR,SLEV; GenJournalLine: Record "Gen. Journal Line")
    begin
        case GenJournalLine."Payment Fee Code" of
            GenJournalLine."Payment Fee Code"::" ":
                ChargeBearer := ChargeBearer::SLEV;
            GenJournalLine."Payment Fee Code"::Beneficiary:
                ChargeBearer := ChargeBearer::CRED;
            GenJournalLine."Payment Fee Code"::Own:
                ChargeBearer := ChargeBearer::DEBT;
            GenJournalLine."Payment Fee Code"::Share:
                ChargeBearer := ChargeBearer::SHAR;
        end;
    end;

    local procedure ResetSWIFTCodeInBankAccount(BankAccNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccNo);
        BankAccount."SWIFT Code" := '';
        BankAccount.Modify();
    end;

    local procedure RunDTASuggestVendorPayments(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; InsertBankBalAccount: Boolean)
    var
        Vendor: Record Vendor;
        DTASuggestVendorPayments: Report "DTA Suggest Vendor Payments";
    begin
        InitGenJournalLine(GenJournalLine, '');
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        Vendor.SetRange("No.", VendorNo);
        LibraryVariableStorage.Enqueue(InsertBankBalAccount);

        Commit();
        Clear(DTASuggestVendorPayments);
        DTASuggestVendorPayments.DefineJournalName(GenJournalLine);
        DTASuggestVendorPayments.SetTableView(Vendor);
        DTASuggestVendorPayments.UseRequestPage(true);
        DTASuggestVendorPayments.RunModal();
    end;

    local procedure RunSuggestVendorPaymentsForVendor(GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; SummarizePerVendor: Boolean; ExcludeCreditMemos: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        GenJournalBatch."No. Series" := '';
        GenJournalBatch.Modify();
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.InitializeRequest2(
          WorkDate(), false, 0, false, WorkDate(), LibraryUtility.GenerateGUID(), SummarizePerVendor,
          GenJournalBatch."Bal. Account Type".AsInteger(), GenJournalBatch."Bal. Account No.", 0, ExcludeCreditMemos);
        Vendor.SetRange("No.", VendorNo);
        SuggestVendorPayments.SetTableView(Vendor);
        SuggestVendorPayments.UseRequestPage(false);
        SuggestVendorPayments.RunModal();
    end;

    local procedure SwissSEPACTExportFile(var GenJournalLine: Record "Gen. Journal Line") FileName: Text
    var
        CreditTransferRegister: Record "Credit Transfer Register";
        TempBlob: Codeunit "Temp Blob";
        SwissSEPACTExportFile: Codeunit "Swiss SEPA CT-Export File";
        FileMgt: Codeunit "File Management";
    begin
        SwissSEPACTExportFile.EnableExportToServerFile();
        SwissSEPACTExportFile.Run(GenJournalLine);

        CreditTransferRegister.FindLast();
        CreditTransferRegister.TestField(Status, CreditTransferRegister.Status::"File Created");
        CreditTransferRegister.CalcFields("Exported File");

        TempBlob.FromRecord(CreditTransferRegister, CreditTransferRegister.FieldNo("Exported File"));

        FileName := FileMgt.ServerTempFileName('xml');
        FileMgt.BLOBExportToServerFile(TempBlob, FileName);
    end;

    local procedure RetriveDataForVerification(GenJournalLine: Record "Gen. Journal Line"; var AccountName: Text[100]; var GiroAccountNo: Code[11]; var ClearingNo: Code[5]; var IBAN: Code[50]; var SWIFTCode: Code[20]; var BankAccountNo: Text[30]; var ESRAccountNo: Code[11])
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        case GenJournalLine."Account Type" of
            GenJournalLine."Account Type"::Customer:
                begin
                    Customer.Get(GenJournalLine."Account No.");
                    AccountName := Customer.Name;
                    CustomerBankAccount.Get(GenJournalLine."Account No.", GenJournalLine."Recipient Bank Account");
                    GiroAccountNo := CustomerBankAccount."Giro Account No.";
                    IBAN := CustomerBankAccount.IBAN;
                    SWIFTCode := CustomerBankAccount."SWIFT Code";
                    BankAccountNo := CustomerBankAccount."Bank Account No.";
                end;
            GenJournalLine."Account Type"::Vendor:
                begin
                    Vendor.Get(GenJournalLine."Account No.");
                    AccountName := Vendor.Name;
                    VendorBankAccount.Get(GenJournalLine."Account No.", GenJournalLine."Recipient Bank Account");
                    GiroAccountNo := DelChr(VendorBankAccount."Giro Account No.", '=', '-');
                    ClearingNo := VendorBankAccount."Clearing No.";
                    IBAN := VendorBankAccount.IBAN;
                    SWIFTCode := VendorBankAccount."SWIFT Code";
                    BankAccountNo := VendorBankAccount."Bank Account No.";
                    ESRAccountNo := DelChr(VendorBankAccount."ESR Account No.", '=', '-');
                end;
        end;
    end;

    local procedure VerifyPaymentExportDataFields(PaymentExportData: Record "Payment Export Data"; ExpectedSwissPaymentForm: Option; ExpectedSwissPaymentType: Option; ExpectedRecipientBankBIC: Code[35]; ExpectedRecipientBankAccNo: Text[100]; ExpectedRecipientAccNo: Text[30])
    begin
        PaymentExportData.TestField("Swiss Payment Form", ExpectedSwissPaymentForm);
        PaymentExportData.TestField("Swiss Payment Type", ExpectedSwissPaymentType);
        PaymentExportData.TestField("Recipient Bank BIC", ExpectedRecipientBankBIC);
        PaymentExportData.TestField("Recipient Bank Acc. No.", ExpectedRecipientBankAccNo);
        PaymentExportData.TestField("Recipient Acc. No.", ExpectedRecipientAccNo);
    end;

    local procedure VerifyPaymentExportDataAddrFields(PaymentExportData: Record "Payment Export Data"; ExpectedRecipientBankName: Text[100]; ExpectedRecipientBankAddress: Text[100]; ExpectedRecipientBankPostCode: Code[20]; ExpectedRecipientBankCountryRegion: Code[10])
    begin
        PaymentExportData.TestField("Recipient Bank Name", ExpectedRecipientBankName);
        PaymentExportData.TestField("Recipient Bank Address", ExpectedRecipientBankAddress);
        PaymentExportData.TestField("Recipient Bank Post Code", ExpectedRecipientBankPostCode);
        PaymentExportData.TestField("Recipient Bank Country/Region", ExpectedRecipientBankCountryRegion);
    end;

    local procedure VerifyPaymentJnlExportErrorText(GenJournalLine: Record "Gen. Journal Line"; ExpectedText: Text)
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        PaymentJnlExportErrorText.SetRange("Journal Line No.", GenJournalLine."Line No.");
        PaymentJnlExportErrorText.FindFirst();
        PaymentJnlExportErrorText.TestField("Error Text", ExpectedText);
    end;

    local procedure VerifyPaymentJnlExportErrorForBlankedVendorBankField(GenJournalLine: Record "Gen. Journal Line"; VendorBankAccountFieldCaption: Text)
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(ExportHasErrorsErr);

        VerifyPaymentJnlExportErrorText(
          GenJournalLine,
          StrSubstNo(
            FieldKeyBlankErr,
            VendorBankAccount.TableCaption(), GenJournalLine."Recipient Bank Account", VendorBankAccountFieldCaption));
    end;

    local procedure VerifyRecipienBankAccountOnPaymentLine(VendorNo: Code[20]; VendorBankAccCode: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Account No.", VendorNo);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Recipient Bank Account", VendorBankAccCode);
    end;

    local procedure VerifySuggestedJournalLineDescriptionMessageToRecipient(Vendor: Record Vendor; ExternalDocNo: Code[35]; ExpectedDescription: Text[100])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Account No.", Vendor."No.");
        GenJournalLine.FindFirst();
        GenJournalLine.TestField(Description, ExpectedDescription);
        GenJournalLine.TestField(
          "Message to Recipient",
          StrSubstNo(
            MessageToRecipientMsg, Format(GenJournalLine."Document Type"::Invoice), ExternalDocNo, Vendor."No."));
    end;

    local procedure VerifyReferenceNoOnGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; ReferenceNo: Code[35])
    begin
        GenJournalLine.SetRange("Account No.", AccountNo);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Reference No.", ReferenceNo);
    end;

    local procedure VerifyXMLFile(GenJournalLine: Record "Gen. Journal Line"; FileName: Text; MessageID: Text; PaymentType: Option)
    begin
        LibraryXMLRead.Initialize(FileName);
        VerifyXMLFileHeader();
        VerifyXMLFileGroupHeader(GenJournalLine, MessageID);
        VerifyXMLFilePmtInf(GenJournalLine, MessageID, PaymentType);
        VerifyXMLFileTrxInf(GenJournalLine, MessageID, PaymentType);
        VerifyXMLFileRmtInf(GenJournalLine, PaymentType);
    end;

    local procedure VerifyXMLFileBatchBooking(FileName: Text; NoOfPayments: Integer; BatchBooking: Boolean)
    begin
        LibraryXMLRead.Initialize(FileName);
        VerifyXMLFileHeader();
        LibraryXMLRead.VerifyNodeValueInSubtree('PmtInf', 'BtchBookg', BatchBooking);
        LibraryXMLRead.VerifyNodeValueInSubtree('PmtInf', 'NbOfTxs', NoOfPayments);
    end;

    local procedure VerifyXMLFileWithPstlAddr(GenJournalLine: Record "Gen. Journal Line"; FileName: Text; MessageID: Text; PaymentType: Option; PaymentType6: Option ,"IBAN and SWIFT","IBAN and PstlAddr","BankAccNo and SWIFT","BankAccNo and PstlAddr","IBAN and BankAccNo")
    begin
        LibraryXMLRead.Initialize(FileName);
        VerifyXMLFileHeader();
        VerifyXMLFileGroupHeaderWithPstlAddr(GenJournalLine, MessageID);
        VerifyXMLFilePmtInf(GenJournalLine, MessageID, PaymentType);
        VerifyXMLFileTrxInfExtended(GenJournalLine, MessageID, PaymentType, PaymentType6);
    end;

    local procedure VerifyXMLFileWithBankAccNo(GenJournalLine: Record "Gen. Journal Line"; FileName: Text; MessageID: Text; PaymentType: Option; PaymentType6: Option ,"IBAN and SWIFT","IBAN and PstlAddr","BankAccNo and SWIFT","BankAccNo and PstlAddr","IBAN and BankAccNo")
    begin
        LibraryXMLRead.Initialize(FileName);
        VerifyXMLFileHeader();
        VerifyXMLFileGroupHeader(GenJournalLine, MessageID);
        VerifyXMLFilePmtInf(GenJournalLine, MessageID, PaymentType);
        VerifyXMLFileTrxInfExtended(GenJournalLine, MessageID, PaymentType, PaymentType6);
    end;

    local procedure VerifyXMLFileHeader()
    begin
        LibraryXMLRead.VerifyXMLDeclaration('1.0', 'UTF-8', 'no');
        LibraryXMLRead.VerifyAttributeValue('Document', 'xmlns', 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.09');
        LibraryXMLRead.VerifyAttributeValue('Document', 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
        LibraryXMLRead.VerifyAttributeValue('Document', 'xsi:schemaLocation', 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.09 pain.001.001.09.ch.03.xsd');
    end;

    local procedure VerifyXMLFileGroupHeader(GenJournalLine: Record "Gen. Journal Line"; MessageID: Text)
    var
        CompanyInformation: Record "Company Information";
    begin
        LibraryXMLRead.VerifyNodeValueInSubtree('GrpHdr', 'MsgId', MessageID);
        LibraryXMLRead.VerifyNodeValueInSubtree('GrpHdr', 'NbOfTxs', '1');
        LibraryXMLRead.VerifyNodeValueInSubtree('GrpHdr', 'CtrlSum', Format(GenJournalLine.Amount, 0, 9));
        CompanyInformation.Get();
        LibraryXMLRead.VerifyNodeValueInSubtree('InitgPty', 'Nm', CompanyInformation.Name);
        LibraryXMLRead.VerifyElementAbsenceInSubtree('InitgPty', 'PstlAdr');
        LibraryXMLRead.VerifyNodeValueInSubtree('InitgPty', 'Id', CompanyInformation."VAT Registration No.");
    end;

    local procedure VerifyXMLFileGroupHeaderWithPstlAddr(GenJournalLine: Record "Gen. Journal Line"; MessageID: Text)
    var
        CompanyInformation: Record "Company Information";
    begin
        LibraryXMLRead.VerifyNodeValueInSubtree('GrpHdr', 'MsgId', MessageID);
        LibraryXMLRead.VerifyNodeValueInSubtree('GrpHdr', 'NbOfTxs', '1');
        LibraryXMLRead.VerifyNodeValueInSubtree('GrpHdr', 'CtrlSum', Format(GenJournalLine.Amount, 0, 9));
        CompanyInformation.Get();
        LibraryXMLRead.VerifyNodeValueInSubtree('InitgPty', 'Nm', CompanyInformation.Name);
        LibraryXMLRead.VerifyNodeValueInSubtree('InitgPty', 'Id', CompanyInformation."VAT Registration No.");
    end;

    local procedure VerifyXMLFilePmtInf(GenJournalLine: Record "Gen. Journal Line"; MessageID: Text; PaymentType: Option)
    var
        CompanyInformation: Record "Company Information";
        BankAccount: Record "Bank Account";
        ChargeBearer: Option DEBT,CRED,SHAR,SLEV;
    begin
        LibraryXMLRead.VerifyNodeValueInSubtree('PmtInf', 'PmtInfId', MessageID + '/1');
        LibraryXMLRead.VerifyNodeValueInSubtree('PmtInf', 'PmtMtd', 'TRF');
        LibraryXMLRead.VerifyNodeValueInSubtree('PmtInf', 'BtchBookg', 'false');
        LibraryXMLRead.VerifyNodeValueInSubtree('PmtInf', 'NbOfTxs', '1');
        LibraryXMLRead.VerifyNodeAbsenceInSubtree('PmtInf', 'CtrlSum');
        case PaymentType of
            PaymentTypeGbl::"1":
                LibraryXMLRead.VerifyNodeValueInSubtree('PmtTpInf', 'LclInstrm', 'CH01');
            PaymentTypeGbl::"2.1":
                LibraryXMLRead.VerifyNodeValueInSubtree('PmtTpInf', 'LclInstrm', 'CH02');
            PaymentTypeGbl::"2.2":
                LibraryXMLRead.VerifyNodeValueInSubtree('PmtTpInf', 'LclInstrm', 'CH03');
            PaymentTypeGbl::"5":
                begin
                    LibraryXMLRead.VerifyNodeValueInSubtree('PmtTpInf', 'InstrPrty', 'NORM');
                    LibraryXMLRead.VerifyNodeValueInSubtree('PmtTpInf', 'Cd', 'SEPA');
                end;
            else
                LibraryXMLRead.VerifyElementAbsenceInSubtree('PmtInf', 'PmtTpInf');
        end;
        LibraryXMLRead.VerifyNodeValueInSubtree('ReqdExctnDt', 'Dt', Format(GenJournalLine."Posting Date", 0, 9));
        CompanyInformation.Get();
        LibraryXMLRead.VerifyNodeValueInSubtree('Dbtr', 'Nm', CompanyInformation.Name);
        LibraryXMLRead.VerifyNodeAbsenceInSubtree('Dbtr', 'Id');
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        LibraryXMLRead.VerifyNodeValueInSubtree('DbtrAcct', 'IBAN', BankAccount.IBAN);

        // <ChrgBr> is matching Payment Fee Code (TFS 308455)
        if PaymentType = PaymentTypeGbl::"5" then
            LibraryXMLRead.VerifyNodeValueInSubtree('PmtInf', 'ChrgBr', 'SLEV')
        else begin
            GetChargeBearerFromPaymentFeeCode(ChargeBearer, GenJournalLine);
            LibraryXMLRead.VerifyNodeValueInSubtree('PmtInf', 'ChrgBr', Format(ChargeBearer));
        end;
    end;

    local procedure VerifyXMLFileTrxInf(GenJournalLine: Record "Gen. Journal Line"; MessageID: Text; PaymentType: Option)
    begin
        VerifyXMLFileTrxInfExtended(GenJournalLine, MessageID, PaymentType, 0);
    end;

    local procedure VerifyXMLFileTrxInfExtended(GenJournalLine: Record "Gen. Journal Line"; MessageID: Text; PaymentType: Option; PaymentType6: Option ,"IBAN and SWIFT","IBAN and PstlAddr","BankAccNo and SWIFT","BankAccNo and PstlAddr","IBAN and BankAccNo")
    var
        VendorBankAccount: Record "Vendor Bank Account";
        AccountName: Text[100];
        GiroAccountNo: Code[11];
        ClearingNo: Code[5];
        IBAN: Code[50];
        SWIFTCode: Code[20];
        BankAccountNo: Text[30];
        ESRAccountNo: Code[11];
    begin
        LibraryXMLRead.VerifyNodeValueInSubtree('PmtId', 'InstrId', MessageID + '/1');
        LibraryXMLRead.VerifyNodeValueInSubtree('PmtId', 'EndToEndId', MessageID + '/1');
        LibraryXMLRead.VerifyNodeValueInSubtree('Amt', 'InstdAmt', Format(GenJournalLine.Amount, 0, 9));
        LibraryXMLRead.VerifyAttributeValueInSubtree('Amt', 'InstdAmt', 'Ccy', GetCurrencyCode(GenJournalLine."Currency Code"));
        RetriveDataForVerification(GenJournalLine, AccountName, GiroAccountNo, ClearingNo, IBAN, SWIFTCode, BankAccountNo, ESRAccountNo);
        LibraryXMLRead.VerifyNodeValueInSubtree('Cdtr', 'Nm', AccountName);
        case PaymentType of
            PaymentTypeGbl::"1":
                begin
                    LibraryXMLRead.VerifyElementAbsenceInSubtree('CdtTrfTxInf', 'CdtrAgt');
                    LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAcct', 'Id', ESRAccountNo);
                    LibraryXMLRead.VerifyNodeAbsenceInSubtree('CdtrAcct', 'IBAN');
                    LibraryXMLRead.VerifyNodeValueInSubtree('CdtTrfTxInf', 'RmtInf', GenJournalLine."Reference No.");
                end;
            PaymentTypeGbl::"2.1":
                begin
                    LibraryXMLRead.VerifyElementAbsenceInSubtree('CdtTrfTxInf', 'CdtrAgt');
                    LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAcct', 'Id', GiroAccountNo);
                    LibraryXMLRead.VerifyNodeAbsenceInSubtree('CdtrAcct', 'IBAN');
                end;
            PaymentTypeGbl::"2.2":
                begin
                    LibraryXMLRead.VerifyNodeAbsenceInSubtree('CdtrAgt', 'Id');
                    LibraryXMLRead.VerifyNodeAbsenceInSubtree('CdtrAgt', 'BICFI');
                    LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAgt', 'Cd', 'CHBCC');
                    if GenJournalLine."Account Type" = GenJournalLine."Account Type"::Vendor then
                        LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAgt', 'MmbId', ClearingNo);
                    LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAcct', 'IBAN', IBAN);
                    LibraryXMLRead.VerifyNodeAbsenceInSubtree('CdtrAcct', 'Othr');
                end;
            PaymentTypeGbl::"5":
                begin
                    LibraryXMLRead.VerifyNodeAbsenceInSubtree('CdtrAgt', 'BICFI');
                    LibraryXMLRead.VerifyNodeAbsenceInSubtree('CdtrAgt', 'Id');
                    LibraryXMLRead.VerifyElementAbsenceInSubtree('CdtrAgt', 'ClrSysMmbId');
                    LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAcct', 'IBAN', IBAN);
                    LibraryXMLRead.VerifyNodeAbsenceInSubtree('CdtrAcct', 'Othr');
                end;
            PaymentTypeGbl::"6":
                begin
                    case PaymentType6 of
                        PaymentType6::"IBAN and SWIFT":
                            begin
                                LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAgt', 'BICFI', SWIFTCode);
                                LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAcct', 'IBAN', IBAN);
                                LibraryXMLRead.VerifyNodeAbsenceInSubtree('CdtrAcct', 'Othr');
                                LibraryXMLRead.VerifyElementAbsenceInSubtree('CdtrAgt', 'PstlAdr');
                            end;
                        PaymentType6::"IBAN and PstlAddr":
                            begin
                                LibraryXMLRead.VerifyNodeAbsenceInSubtree('CdtrAgt', 'BICFI');
                                LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAcct', 'IBAN', IBAN);
                                VendorBankAccount.Get(GenJournalLine."Account No.", GenJournalLine."Recipient Bank Account");
                                VerifyXMLFileNmAddr(VendorBankAccount);
                            end;
                        PaymentType6::"BankAccNo and SWIFT":
                            begin
                                LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAgt', 'BICFI', SWIFTCode);
                                LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAcct', 'Id', BankAccountNo);
                            end;
                        PaymentType6::"BankAccNo and PstlAddr":
                            begin
                                LibraryXMLRead.VerifyNodeAbsenceInSubtree('CdtrAgt', 'BICFI');
                                LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAcct', 'Id', BankAccountNo);
                                VendorBankAccount.Get(GenJournalLine."Account No.", GenJournalLine."Recipient Bank Account");
                                VerifyXMLFileNmAddr(VendorBankAccount);
                            end;
                        PaymentType6::"IBAN and BankAccNo":
                            begin
                                LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAgt', 'BICFI', SWIFTCode);
                                LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAcct', 'IBAN', IBAN);
                            end;
                    end;
                    LibraryXMLRead.VerifyNodeAbsenceInSubtree('CdtrAgt', 'Id');
                    LibraryXMLRead.VerifyElementAbsenceInSubtree('CdtrAgt', 'ClrSysMmbId');
                end;
            else begin
                LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAgt', 'BICFI', SWIFTCode);
                LibraryXMLRead.VerifyNodeAbsenceInSubtree('CdtrAgt', 'Id');
                LibraryXMLRead.VerifyElementAbsenceInSubtree('CdtrAgt', 'ClrSysMmbId');
                LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAcct', 'IBAN', IBAN);
                LibraryXMLRead.VerifyNodeAbsenceInSubtree('CdtrAcct', 'Othr');
            end;
        end;
    end;

    local procedure VerifyXMLFileRmtInf(GenJournalLine: Record "Gen. Journal Line"; PaymentType: Option)
    var
        BankMgt: Codeunit BankMgt;
    begin
        case PaymentType of
            PaymentTypeGbl::"1":
                begin
                    LibraryXMLRead.VerifyNodeValueInSubtree('RmtInf', 'Strd', GenJournalLine."Reference No.");
                    LibraryXMLRead.VerifyElementAbsenceInSubtree('RmtInf', 'Ustrd');
                    LibraryXMLRead.VerifyElementAbsenceInSubtree('Strd', 'AddtlRmtInf');
                end;
            PaymentTypeGbl::"2.1",
            PaymentTypeGbl::"2.2":
                begin
                    LibraryXMLRead.VerifyNodeValueInSubtree('RmtInf', 'Ustrd', GenJournalLine."Message to Recipient");
                    LibraryXMLRead.VerifyElementAbsenceInSubtree('RmtInf', 'Strd');
                end;
            else
                if (GenJournalLine."Payment Reference" <> '') and
                   (BankMgt.IsQRReference(GenJournalLine."Payment Reference") or BankMgt.IsCreditReferenceISO11649(GenJournalLine."Payment Reference"))
                then begin
                    LibraryXMLRead.VerifyElementAbsenceInSubtree('RmtInf', 'Ustrd');
                    LibraryXMLRead.VerifyNodeValueInSubtree('Strd', 'Ref', GenJournalLine."Payment Reference");
                    if (StrLen(DelChr(GenJournalLine."Payment Reference")) = 27) AND
                       (PaymentType <> PaymentTypeGbl::"5")
                    then begin
                        LibraryXMLRead.VerifyNodeValueInSubtree('Strd', 'Prtry', 'QRR');
                        asserterror LibraryXMLRead.VerifyNodeValueInSubtree('Strd', 'Cd', 'SCOR');
                    end else begin
                        LibraryXMLRead.VerifyNodeValueInSubtree('Strd', 'Cd', 'SCOR');
                        LibraryXMLRead.VerifyElementAbsenceInSubtree('Strd', 'Prtry');
                    end;
                end else begin
                    LibraryXMLRead.VerifyNodeValueInSubtree('RmtInf', 'Ustrd', GenJournalLine."Message to Recipient");
                    LibraryXMLRead.VerifyElementAbsenceInSubtree('RmtInf', 'Strd');
                end;
        end;
    end;

    local procedure VerifyXMLFileNmAddr(VendorBankAccount: Record "Vendor Bank Account")
    begin
        LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAgt', 'Nm', VendorBankAccount.Name);
        LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAgt', 'StrtNm', VendorBankAccount.Address);
        LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAgt', 'PstCd', VendorBankAccount."Post Code");
        LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAgt', 'Ctry', VendorBankAccount."Country/Region Code");
    end;

    local procedure VerifyXMLExportForSevCombinedLines(VendorNo: array[3] of Code[20]; PaymentReferenceNo: array[3] of Code[50]; ESRReferenceNo: array[3] of Code[50])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        i: Integer;
    begin
        CreateGenJournalBatch(GenJournalBatch, CreateBankAccount(FindSwissSEPACTBankExpImpCode()));
        for i := 1 to ArrayLen(VendorNo) do
            AddVendPmtJnlLineWithPaymentReference(GenJournalBatch, VendorNo[i], PaymentReferenceNo[i], ESRReferenceNo[i]);

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        FileName := GenJournalLine_XMLExport(GenJournalLine);

        LibraryXMLRead.Initialize(FileName);
        Assert.AreEqual(ArrayLen(VendorNo), LibraryXMLRead.GetNodesCount('CdtrRefInf'), '<CdtrRefInf> node count');
        Assert.AreEqual(ArrayLen(VendorNo), LibraryXMLRead.GetNodesCount('Ref'), '<Ref> node count');
        Assert.AreEqual(ArrayLen(VendorNo) - 1, LibraryXMLRead.GetNodesCount('CdOrPrtry'), '<CdOrPrtry> node count');
        LibraryXMLRead.VerifyNodeValueInSubtree('CdOrPrtry', 'Prtry', 'QRR');
        LibraryXMLRead.VerifyNodeValueInSubtree('CdOrPrtry', 'Cd', 'SCOR');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DTASuggest_RPH(var DTASuggestVendorPayments: TestRequestPage "DTA Suggest Vendor Payments")
    begin
        DTASuggestVendorPayments."Posting Date".SetValue(WorkDate());
        DTASuggestVendorPayments."Due Date from".SetValue(WorkDate());
        DTASuggestVendorPayments."Due Date to".SetValue(WorkDate());
        DTASuggestVendorPayments.InsertBankBalanceAccount.SetValue(LibraryVariableStorage.DequeueBoolean());
        DTASuggestVendorPayments.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentRPH(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    begin
        LibraryVariableStorage.Enqueue(SuggestVendorPayments.ExcludeCreditMemos.Visible());
        LibraryVariableStorage.Enqueue(SuggestVendorPayments.ExcludeCreditMemos.Editable());
        SuggestVendorPayments.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreatePaymentModalPageHandler(var CreatePayment: TestPage "Create Payment")
    begin
        CreatePayment."Batch Name".SetValue(LibraryVariableStorage.DequeueText());
        CreatePayment.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PaymentJournalModalPageHandler(var PaymentJournal: TestPage "Payment Journal")
    begin
        PaymentJournal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PostedPurchInvUpdatePaymentRefModalPageHandler(var PostedPurchInvoiceUpdate: TestPage "Posted Purch. Invoice - Update")
    begin
        PostedPurchInvoiceUpdate."Payment Reference".SetValue(LibraryVariableStorage.DequeueText());
        PostedPurchInvoiceUpdate.OK().Invoke();
    end;
}

