codeunit 144134 "Remittance - Pages"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Remittance] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRemittance: Codeunit "Library - Remittance";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTemplates: Codeunit "Library - Templates";

    [Test]
    [Scope('OnPrem')]
    procedure TC60566CreateAndSetupRemittanceAgreement()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        ReturnFileSetup: Record "Return File Setup";
        RemittanceAgreementCard: TestPage "Remittance Agreement Card";
        ReturnFileSetupList: TestPage "Return File Setup List";
        "Code": Code[10];
        Description: Text[30];
        OperatorNo: Code[11];
        CompanyAgreementNo: Code[11];
        BBSCustomerUnitID: Code[10];
        PaymentFileName: Text;
        ReturnFileName: Text;
    begin
        // This test case is used to check if Remittance Agreements can be created. For each agreement which
        // is signed with the banks an agreement must be created. This will normally be one agreement.
        Code := LibraryUtility.GenerateRandomCode(RemittanceAgreement.FieldNo(Code), DATABASE::"Remittance Agreement");
        Description := 'Den Norske Bank';
        OperatorNo :=
          LibraryUtility.GenerateRandomCode(
            RemittanceAgreement.FieldNo("Operator No."),
            DATABASE::"Remittance Agreement");
        CompanyAgreementNo :=
          LibraryUtility.GenerateRandomCode(
            RemittanceAgreement.FieldNo("Company/Agreement No."),
            DATABASE::"Remittance Agreement");
        BBSCustomerUnitID :=
          LibraryUtility.GenerateRandomCode(
            RemittanceAgreement.FieldNo("BBS Customer Unit ID"),
            DATABASE::"Remittance Agreement");
        PaymentFileName := LibraryRemittance.GetTempFileName();
        ReturnFileName := LibraryRemittance.GetTempFileName();

        // Execute
        RemittanceAgreementCard.OpenNew();
        RemittanceAgreementCard.Code.Value := Code;
        RemittanceAgreementCard.Description.Value := Description;
        RemittanceAgreementCard."Payment System".Value := Format(RemittanceAgreement."Payment System"::"DnB Telebank");

        RemittanceAgreementCard."Operator No.".Value := OperatorNo;
        RemittanceAgreementCard."Company/Agreement No.".Value := CompanyAgreementNo;

        RemittanceAgreementCard."BBS Customer Unit ID".Value := BBSCustomerUnitID;

        RemittanceAgreementCard.FileName.Value :=
          CopyStr(PaymentFileName, 1, MaxStrLen(RemittanceAgreement."Payment File Name"));

        RemittanceAgreementCard."Save Return File".SetValue(true);
        RemittanceAgreementCard."Receipt Return Required".SetValue(true);
        RemittanceAgreementCard."On Hold Rejection Code".Value := 'RF';

        ReturnFileSetupList.Trap();
        RemittanceAgreementCard."Return File Setup List".Invoke();

        ReturnFileSetupList.New();
        ReturnFileSetupList.FileName.Value :=
          CopyStr(ReturnFileName, 1, MaxStrLen(ReturnFileSetup."Return File Name"));
        ReturnFileSetupList.OK().Invoke();

        RemittanceAgreementCard."New Document Per.".Value := Format(RemittanceAgreement."New Document Per."::Date);
        RemittanceAgreementCard.OK().Invoke();

        // Verify
        Assert.IsTrue(RemittanceAgreement.Get(Code), 'Remittance Agreement not found.');
        Assert.AreEqual(Description, RemittanceAgreement.Description, 'Description');
        Assert.AreEqual(RemittanceAgreement."Payment System"::"DnB Telebank", RemittanceAgreement."Payment System", 'Payment System');
        Assert.AreEqual(OperatorNo, RemittanceAgreement."Operator No.", 'Operator No.');
        Assert.AreEqual(CompanyAgreementNo, RemittanceAgreement."Company/Agreement No.", 'Company/Agreement No.');
        Assert.AreEqual(BBSCustomerUnitID, RemittanceAgreement."BBS Customer Unit ID", 'BBS Customer Unit ID');
        Assert.AreEqual(PaymentFileName, RemittanceAgreement."Payment File Name", 'Payment File Name');
        Assert.IsTrue(RemittanceAgreement."Save Return File", 'Save Return File');
        Assert.IsTrue(RemittanceAgreement."Receipt Return Required", 'Receipt Return Required');

        ReturnFileSetup.SetFilter("Agreement Code", Code);
        Assert.AreEqual(1, ReturnFileSetup.Count, 'Return File Setup Count doesn''t match');
        ReturnFileSetup.FindFirst();
        Assert.AreEqual(ReturnFileName, ReturnFileSetup."Return File Name", 'ReturnFileName');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC60568CreateAndSetupDomesticRemittanceAccount()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        RemittanceAccount2: Record "Remittance Account";
        BankAccount: Record "Bank Account";
        GLAccount: Record "G/L Account";
        RemittanceAccountCard: TestPage "Remittance Account Card";
    begin
        // Setup
        LibraryRemittance.CreateRemittanceAgreement(RemittanceAgreement, RemittanceAgreement."Payment System"::BBS);

        RemittanceAccount.Code := LibraryUtility.GenerateRandomCode(RemittanceAccount.FieldNo(Code), DATABASE::"Remittance Account");
        LibraryERM.FindBankAccount(BankAccount);
        RemittanceAccount."Bank Account No." := '79900503534'; // Number with special format and checksum.
        RemittanceAccount."Document No. Series" := LibraryUtility.GetGlobalNoSeriesCode();
        RemittanceAccount."Return Journal Template Name" := FindPaymentGenJournalTemplate();
        RemittanceAccount."Return Journal Name" := FindGenJournalBatchName(RemittanceAccount."Return Journal Template Name");
        RemittanceAccount."Recipient ref. 1 - Invoice" := 'PAYMENT OF INVOICE %2';
        RemittanceAccount."Recipient ref. 2 - Invoice" := 'OUR ACCOUNT NO. %3';
        RemittanceAccount."Recipient ref. 3 - Invoice" := 'OUR REF. %4';
        RemittanceAccount."Recipient ref. 1 - Cr. Memo" := 'BALANCING CREDIT MEMO %2';
        RemittanceAccount."Recipient ref. 2 - Cr. Memo" := 'OUR ACCOUNT NO. %3';
        RemittanceAccount."Recipient ref. 3 - Cr. Memo" := 'OUR REF. %4';

        LibraryERM.FindGLAccount(GLAccount);

        // Execute
        RemittanceAccountCard.OpenNew();
        RemittanceAccountCard.Code.Value := RemittanceAccount.Code;
        RemittanceAccountCard."Remittance Agreement Code".Value := RemittanceAgreement.Code;
        RemittanceAccountCard.Type.SetValue(RemittanceAccount.Type::Domestic);
        RemittanceAccountCard.Description.Value := RemittanceAccount.Code;
        RemittanceAccountCard."Bank Account No.".Value := RemittanceAccount."Bank Account No.";

        RemittanceAccountCard."Account Type".SetValue(RemittanceAccount."Account Type"::"Bank account");
        RemittanceAccountCard."Account No.".Value := BankAccount."No.";
        RemittanceAccountCard."Charge Account No.".Value := GLAccount."No.";
        RemittanceAccountCard."Round off/Divergence Acc. No.".Value := GLAccount."No.";
        RemittanceAccountCard."Document No. Series".Value := RemittanceAccount."Document No. Series";
        RemittanceAccountCard."New Document Per.".SetValue(RemittanceAccount."New Document Per."::Date);
        RemittanceAccountCard."Return Journal Template Name".Value := RemittanceAccount."Return Journal Template Name";
        RemittanceAccountCard."Return Journal Name".Value := RemittanceAccount."Return Journal Name";

        RemittanceAccountCard."Recipient ref. 1 - Invoice".Value := RemittanceAccount."Recipient ref. 1 - Invoice";
        RemittanceAccountCard."Recipient ref. 2 - Invoice".Value := RemittanceAccount."Recipient ref. 2 - Invoice";
        RemittanceAccountCard."Recipient ref. 3 - Invoice".Value := RemittanceAccount."Recipient ref. 3 - Invoice";
        RemittanceAccountCard."Recipient ref. 1 - Cr. Memo".Value := RemittanceAccount."Recipient ref. 1 - Cr. Memo";
        RemittanceAccountCard."Recipient ref. 2 - Cr. Memo".Value := RemittanceAccount."Recipient ref. 2 - Cr. Memo";
        RemittanceAccountCard."Recipient ref. 3 - Cr. Memo".Value := RemittanceAccount."Recipient ref. 3 - Cr. Memo";

        RemittanceAccountCard.OK().Invoke();

        // Verify
        RemittanceAccount2.Get(RemittanceAccount.Code);
        Assert.AreEqual(RemittanceAccount.Type::Domestic, RemittanceAccount2.Type, 'Not a Domestic Account');
        Assert.AreEqual(RemittanceAgreement.Code, RemittanceAccount2."Remittance Agreement Code", 'Remittance Agreement Code');
        Assert.AreEqual(RemittanceAccount."Bank Account No.", RemittanceAccount2."Bank Account No.", 'Bank Account No.');
        Assert.AreEqual(RemittanceAccount."Account Type"::"Bank account", RemittanceAccount2."Account Type", 'Account Type');
        Assert.AreEqual(BankAccount."No.", RemittanceAccount2."Account No.", 'Account No.');
        Assert.AreEqual(GLAccount."No.", RemittanceAccount2."Charge Account No.", 'Charge Account No.');
        Assert.AreEqual(GLAccount."No.", RemittanceAccount2."Round off/Divergence Acc. No.", 'Round off/Divergence Acc. No.');
        Assert.AreEqual(RemittanceAccount."Return Journal Template Name", RemittanceAccount2."Return Journal Template Name",
          'Return Journal Template Name');
        Assert.AreEqual(RemittanceAccount."Return Journal Name", RemittanceAccount2."Return Journal Name", 'Return Journal Name');
        Assert.AreEqual(RemittanceAccount."Recipient ref. 1 - Invoice", RemittanceAccount2."Recipient ref. 1 - Invoice",
          'Recipient ref. 1 - Invoice');
        Assert.AreEqual(RemittanceAccount."Recipient ref. 2 - Invoice", RemittanceAccount2."Recipient ref. 2 - Invoice",
          'Recipient ref. 2 - Invoice');
        Assert.AreEqual(RemittanceAccount."Recipient ref. 3 - Invoice", RemittanceAccount2."Recipient ref. 3 - Invoice",
          'Recipient ref. 3 - Invoice');
        Assert.AreEqual(RemittanceAccount."Recipient ref. 1 - Cr. Memo", RemittanceAccount2."Recipient ref. 1 - Cr. Memo",
          'RemittanceAccount."Recipient ref. 1 - Cr. Memo');
        Assert.AreEqual(RemittanceAccount."Recipient ref. 2 - Cr. Memo", RemittanceAccount2."Recipient ref. 2 - Cr. Memo",
          'RemittanceAccount."Recipient ref. 2 - Cr. Memo');
        Assert.AreEqual(RemittanceAccount."Recipient ref. 3 - Cr. Memo", RemittanceAccount2."Recipient ref. 3 - Cr. Memo",
          'RemittanceAccount."Recipient ref. 3 - Cr. Memo');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC60567CreateAndSetupForeignRemittanceAccount()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        RemittanceAccount2: Record "Remittance Account";
        BankAccount: Record "Bank Account";
        GLAccount: Record "G/L Account";
        RemittanceAccountCard: TestPage "Remittance Account Card";
    begin
        // [FEATURE] [Foreign Account]
        LibraryRemittance.CreateRemittanceAgreement(RemittanceAgreement, RemittanceAgreement."Payment System"::"DnB Telebank");

        RemittanceAccount.Code := LibraryUtility.GenerateRandomCode(RemittanceAccount.FieldNo(Code), DATABASE::"Remittance Account");
        RemittanceAccount."Currency Code" := LibraryRemittance.FindForeignCurrencyCode();
        LibraryERM.FindBankAccount(BankAccount);
        RemittanceAccount."Bank Account No." := '79900503534'; // Number with special format and checksum.
        RemittanceAccount."Document No. Series" := LibraryUtility.GetGlobalNoSeriesCode();
        RemittanceAccount."Return Journal Template Name" := FindPaymentGenJournalTemplate();
        RemittanceAccount."Return Journal Name" := FindGenJournalBatchName(RemittanceAccount."Return Journal Template Name");
        RemittanceAccount."Recipient Ref. Abroad" := 'PAYMENT INVOICE %2';
        LibraryERM.FindGLAccount(GLAccount);

        // Execute
        RemittanceAccountCard.OpenNew();
        RemittanceAccountCard.Code.Value := RemittanceAccount.Code;
        RemittanceAccountCard."Remittance Agreement Code".Value := RemittanceAgreement.Code;
        RemittanceAccountCard.Type.SetValue(RemittanceAccount.Type::Foreign);
        RemittanceAccountCard.Description.Value := RemittanceAccount.Code;
        RemittanceAccountCard."Bank Account No.".Value := RemittanceAccount."Bank Account No.";

        RemittanceAccountCard."Account Type".SetValue(RemittanceAccount."Account Type"::"Bank account");
        RemittanceAccountCard."Account No.".Value := BankAccount."No.";
        RemittanceAccountCard."Charge Account No.".Value := GLAccount."No.";
        RemittanceAccountCard."Round off/Divergence Acc. No.".Value := GLAccount."No.";
        RemittanceAccountCard."Document No. Series".Value := RemittanceAccount."Document No. Series";
        RemittanceAccountCard."New Document Per.".SetValue(RemittanceAccount."New Document Per."::Date);
        RemittanceAccountCard."Return Journal Template Name".Value := RemittanceAccount."Return Journal Template Name";
        RemittanceAccountCard."Return Journal Name".Value := RemittanceAccount."Return Journal Name";

        RemittanceAccountCard."Currency Code".Value := RemittanceAccount."Currency Code";
        RemittanceAccountCard."Recipient Ref. Abroad".Value := 'PAYMENT INVOICE %2';

        RemittanceAccountCard.OK().Invoke();

        // Verify
        RemittanceAccount2.Get(RemittanceAccount.Code);
        Assert.AreEqual(RemittanceAccount.Type::Foreign, RemittanceAccount2.Type, 'Not a Foreign Account');
        Assert.AreEqual(RemittanceAgreement.Code, RemittanceAccount2."Remittance Agreement Code", 'Remittance Agreement Code');
        Assert.AreEqual(RemittanceAccount."Bank Account No.", RemittanceAccount2."Bank Account No.", 'Bank Account No.');
        Assert.AreEqual(RemittanceAccount."Account Type"::"Bank account", RemittanceAccount2."Account Type", 'Account Type');
        Assert.AreEqual(BankAccount."No.", RemittanceAccount2."Account No.", 'Account No.');
        Assert.AreEqual(GLAccount."No.", RemittanceAccount2."Charge Account No.", 'Charge Account No.');
        Assert.AreEqual(GLAccount."No.", RemittanceAccount2."Round off/Divergence Acc. No.", 'Round off/Divergence Acc. No.');
        Assert.AreEqual(RemittanceAccount."Return Journal Template Name", RemittanceAccount2."Return Journal Template Name",
          'Return Journal Template Name');
        Assert.AreEqual(RemittanceAccount."Return Journal Name", RemittanceAccount2."Return Journal Name", 'Return Journal Name');
        Assert.AreEqual(RemittanceAccount."Currency Code", RemittanceAccount2."Currency Code", 'Currency Code');
        Assert.AreEqual(RemittanceAccount."Recipient Ref. Abroad", RemittanceAccount2."Recipient Ref. Abroad", 'Recipient Ref. Abroad');
    end;

    [Test]
    [HandlerFunctions('RemittanceAccountLookupHandler')]
    [Scope('OnPrem')]
    procedure TC60563CreateDomesticVendorUsingRemittance()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorTempl: Record "Vendor Templ.";
        VendorCard: TestPage "Vendor Card";
        RemittanceInfo: TestPage "Remittance Info";
    begin
        LibraryTemplates.EnableTemplatesFeature();
        // This test case is used to check if a new (Domestic) Vendor can be created and set up to use Remittance.
        LibraryRemittance.CreateRemittanceAgreement(RemittanceAgreement, RemittanceAgreement."Payment System"::"DnB Telebank");
        LibraryRemittance.CreateDomesticRemittanceAccount(RemittanceAgreement.Code, RemittanceAccount);
        VendorTempl.DeleteAll(true);

        // Execute
        VendorCard.OpenNew();
        VendorCard.Name.Value := 'Dom Vend1 REM';
        VendorCard."Post Code".Value := '5003';
        VendorCard."Country/Region Code".Value := 'NO';
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        VendorCard."Gen. Bus. Posting Group".Value := GeneralPostingSetup."Gen. Bus. Posting Group";
        VendorCard."VAT Bus. Posting Group".Value := VATPostingSetup."VAT Bus. Posting Group";
        VendorCard."Vendor Posting Group".Value := LibraryPurchase.FindVendorPostingGroup();
        VendorCard."Payment Terms Code".Value := LibraryERM.FindPaymentTermsCode();
        VendorCard.Remittance.SetValue(true);

        LibraryVariableStorage.Enqueue(RemittanceAccount.Code);
        VendorCard."Remittance Account Code".Lookup();
        VendorCard."Recipient Bank Account No.".Value := '53371228280'; // Number must follow certain rules and checksum.

        RemittanceInfo.Trap();
        VendorCard."Remittance Info".Invoke();

        RemittanceInfo."Remittance Account Code".AssertEquals(RemittanceAccount.Code);
        RemittanceInfo."Remittance Agreement Code".AssertEquals(RemittanceAgreement.Code);
        RemittanceInfo."Recipient Bank Account No.".AssertEquals('53371228280');
        RemittanceInfo."Own Vendor Recipient Ref.".SetValue(true);

        // According to Manual TestCase the following fields should be set automatically
        // when setting "Own Vendor Recipient Ref." to true, but it does don't do that.
        // RemittanceInfo."Recipient ref. 1 - inv.".ASSERTEQUALS('PAYMENT OF INVOICE %2');
        // RemittanceInfo."Recipient ref. 2 - inv.".ASSERTEQUALS('OUR ACCOUNT NO. %3');
        // RemittanceInfo."Recipient ref. 3 - inv.".ASSERTEQUALS('OUR REF. %4');
        // RemittanceInfo."Recipient ref. 1 - cred.".ASSERTEQUALS('VALUE');
        // RemittanceInfo."Recipient ref. 2 - cred.".ASSERTEQUALS('VALUE');
        // RemittanceInfo."Recipient ref. 3 - cred.".ASSERTEQUALS('VALUE');

        RemittanceInfo.OK().Invoke();
        VendorCard.OK().Invoke();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('RemittanceAccountLookupHandler')]
    [Scope('OnPrem')]
    procedure TC60562CreateForeignVendorUsingRemittance()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorTempl: Record "Vendor Templ.";
        VendorCard: TestPage "Vendor Card";
        RemittanceInfo: TestPage "Remittance Info";
        CurrencyCode: Code[10];
    begin
        LibraryTemplates.EnableTemplatesFeature();
        // This test case is used to check if a new (Foreign) Vendor can be created and set up to use Remittance.
        // Values are from the manuel testcases.
        CurrencyCode := LibraryRemittance.FindForeignCurrencyCode();
        LibraryRemittance.CreateRemittanceAgreement(RemittanceAgreement, RemittanceAgreement."Payment System"::"DnB Telebank");
        LibraryRemittance.CreateForeignRemittanceAccount(RemittanceAgreement.Code, RemittanceAccount, CurrencyCode, false);
        VendorTempl.DeleteAll(true);

        // Execute
        VendorCard.OpenNew();
        VendorCard.Name.Value := 'For Vend2 REM';
        VendorCard."Post Code".Value := '3771 MR';
        VendorCard.City.Value := 'Barneveld';
        VendorCard."Country/Region Code".Value := 'NL';
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        VendorCard."Gen. Bus. Posting Group".Value := GeneralPostingSetup."Gen. Bus. Posting Group";
        VendorCard."VAT Bus. Posting Group".Value := VATPostingSetup."VAT Bus. Posting Group";
        VendorCard."Vendor Posting Group".Value := LibraryPurchase.FindVendorPostingGroup();
        VendorCard."Payment Terms Code".Value := LibraryERM.FindPaymentTermsCode();
        VendorCard.Remittance.SetValue(true);

        LibraryVariableStorage.Enqueue(RemittanceAccount.Code);
        VendorCard."Remittance Account Code".Lookup();
        VendorCard."Recipient Bank Account No.".Value := '53371228280'; // Number must follow certain rules and checksum.

        RemittanceInfo.Trap();
        VendorCard."Remittance Info".Invoke();

        RemittanceInfo."Remittance Account Code".AssertEquals(RemittanceAccount.Code);
        RemittanceInfo."Remittance Agreement Code".AssertEquals(RemittanceAgreement.Code);
        RemittanceInfo."Recipient Bank Account No.".AssertEquals('53371228280');
        RemittanceInfo."Own Vendor Recipient Ref.".SetValue(true);

        // According to Manual TestCase the following fields should be set automatically
        // when setting "Own Vendor Recipient Ref." to true, but it does don't do that.
        // RemittanceInfo."Recipient ref. 1 - inv.".ASSERTEQUALS('PAYMENT OF INVOICE %2');
        // RemittanceInfo."Recipient ref. 2 - inv.".ASSERTEQUALS('OUR ACCOUNT NO. %3');
        // RemittanceInfo."Recipient ref. 3 - inv.".ASSERTEQUALS('OUR REF. %4');
        // RemittanceInfo."Recipient ref. 1 - cred.".ASSERTEQUALS('VALUE');
        // RemittanceInfo."Recipient ref. 2 - cred.".ASSERTEQUALS('VALUE');
        // RemittanceInfo."Recipient ref. 3 - cred.".ASSERTEQUALS('VALUE');

        RemittanceInfo.OK().Invoke();
        VendorCard.OK().Invoke();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC60664VerifySpecificationNorgesBankInRemittanceInfo()
    var
        Vendor: Record Vendor;
        PaymentTypeCodeAbroad: Record "Payment Type Code Abroad";
        Specification: Code[60];
    begin
        // The is cases tests the relation between "Payment Type Code Abroad" and
        // the Specification (Norges Bank) field.
        // When "Payment Type Code Abroad" is set, the Specification (Norges Bank)
        // set or cleared accordingly.
        Vendor.Init();
        Assert.AreEqual('', Vendor."Payment Type Code Abroad", 'Payment Type Code Abroad');
        Assert.AreEqual('', Vendor."Specification (Norges Bank)", 'Specification (Norges Bank)');

        PaymentTypeCodeAbroad.Find('-');
        Vendor.Validate("Payment Type Code Abroad", PaymentTypeCodeAbroad.Code);
        Specification := CopyStr(PaymentTypeCodeAbroad.Description, 1, 60);
        Assert.AreEqual(Specification, Vendor."Specification (Norges Bank)", 'Specification (Norges Bank)');

        PaymentTypeCodeAbroad.Next();
        Vendor.Validate("Payment Type Code Abroad", PaymentTypeCodeAbroad.Code);
        Specification := CopyStr(PaymentTypeCodeAbroad.Description, 1, 60);
        Assert.AreEqual(Specification, Vendor."Specification (Norges Bank)", 'Specification (Norges Bank)');

        Vendor.Validate("Payment Type Code Abroad", '');
        Assert.AreEqual('', Vendor."Specification (Norges Bank)", 'Specification (Norges Bank)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentTypeCodeAbroadOnPostPurchaseJournal()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Production Journal]
        // [SCENARIO 377247] Post Purchase Journal Job should transfer "Payment Type Code Abroad" field from Vendor to appropriate Vendor Ledger Entry

        // [GIVEN] Vendor with "Payment Type Code Abroad" = "X"
        LibraryRemittance.SetupForeignRemittancePayment(
          RemittanceAgreement."Payment System"::"DnB Telebank", RemittanceAgreement, RemittanceAccount, Vendor, GenJournalLine, false);

        // [WHEN] Post Purchase Journal for Vendor
        PostPurchaseJournal(RemittanceAccount."Round off/Divergence Acc. No.", Vendor."No.");

        // [THEN] Vendor Ledger Entry is created with "Payment Type Code Abroad" = "X"
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField("Payment Type Code Abroad", Vendor."Payment Type Code Abroad");
        VendorLedgerEntry.TestField("Specification (Norges Bank)", Vendor."Specification (Norges Bank)");
    end;

    local procedure FindPaymentGenJournalTemplate(): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.FindFirst();
        exit(GenJournalTemplate.Name);
    end;

    local procedure FindGenJournalBatchName(TemplateName: Code[10]): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.SetRange("Journal Template Name", TemplateName);
        GenJournalBatch.FindFirst();
        exit(GenJournalBatch.Name);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostCodesHandler(var PostCodes: TestPage "Post Codes")
    var
        City: Variant;
    begin
        LibraryVariableStorage.Dequeue(City);
        PostCodes.FindFirstField(City, City);
        PostCodes.OK().Invoke();
    end;

    local procedure PostPurchaseJournal(GLAccNo: Code[20]; VendorNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandInt(10));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccNo);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RemittanceAccountLookupHandler(var RemittanceAccountOVerview: TestPage "Remittance Account Overview")
    var
        AccountCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(AccountCode);
        RemittanceAccountOVerview.GotoKey(AccountCode);
        RemittanceAccountOVerview.OK().Invoke();
    end;
}

