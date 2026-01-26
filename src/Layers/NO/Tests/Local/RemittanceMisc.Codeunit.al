codeunit 144135 "Remittance - Misc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Remittance]
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRemittance: Codeunit "Library - Remittance";
        InvalidTypeErr: Label 'The type Foreign cannot be used with the BBS payment system.';

    [Test]
    [Scope('OnPrem')]
    procedure StructuredPaymentOnGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExternalDocumentNo: Code[10];
        KIDNumber: Code[10];
    begin
        // [FEATURE] [Structured Payment]
        KIDNumber := GetKIDNumber();

        // According to testcases Gen. Journal Line is structured if
        // 1. KID exists
        // or
        // 2. External Doc No and Account No exists
        // but the implementation only checks KID or External Doc No.
        // This test replaces manul testcases 60554..60561

        GenJournalLine.Init();
        Assert.IsFalse(GenJournalLine."Structured Payment", 'Structured payment must be false on empty line');

        GenJournalLine.Validate(KID, KIDNumber);
        Assert.IsTrue(GenJournalLine."Structured Payment", 'KID assigned => Structured payment = true');

        ExternalDocumentNo :=
          LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("External Document No."), DATABASE::"Gen. Journal Line");
        GenJournalLine.Init();
        GenJournalLine.Validate("External Document No.", ExternalDocumentNo);
        Assert.IsTrue(GenJournalLine."Structured Payment", 'External Document No assigned => Structured payment = true');

        GenJournalLine.Init();
        GenJournalLine.Validate(KID, KIDNumber);
        GenJournalLine.Validate("External Document No.", ExternalDocumentNo);
        Assert.IsTrue(GenJournalLine."Structured Payment", 'External Document No and KID assigned => Structured payment = true');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BBSCanNotBeUsedWithForeignAccounts()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
    begin
        // [FEATURE] [BBS] [Foreign Account]
        // [SCENARIO 60564] The BBS Payment System can't be used together with Foreign Account.
        LibraryRemittance.CreateRemittanceAgreement(RemittanceAgreement, RemittanceAgreement."Payment System"::BBS);

        RemittanceAccount.Init();
        RemittanceAccount.Validate("Remittance Agreement Code", RemittanceAgreement.Code);
        asserterror RemittanceAccount.Validate(Type, RemittanceAccount.Type::Foreign);
        Assert.AreEqual(Format(InvalidTypeErr), GetLastErrorText,
          'Wrong Error Message when using Foreign Account with Payment System BBS');

        RemittanceAccount.Init();
        asserterror RemittanceAccount.Validate(Type, RemittanceAccount.Type::Foreign);
        // We don't care about the actual error message here. The important point is that you should be able to
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPmtTypeCodeAbroadInPurchJnl_Positive_InvoiceDocType()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT] [Vendor] [Payment Type Code Abroad]
        // [SCENARIO 378829] Vendor's "Payment Type Code Abroad", "Specification (Norges Bank)" are filled in Purchase Journal line when validate Vendor in case of Invoice document type

        // [GIVEN] Vendor "V" with "Payment Type Code Abroad" = "X", "Specification (Norges Bank)" = "Y"
        CreateVendorWithPmtTypeCodeAbroad(Vendor);
        // [GIVEN] Purchase Journal Line with "Document Type" = "Invoice", "Account Type" = "Vendor"
        GenJournalLine.Init();
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Vendor);

        // [WHEN] Validate Purchase Journal line "Account No." = "V"
        GenJournalLine.Validate("Account No.", Vendor."No.");

        // [THEN] Purchase Journal Line's "Payment Type Code Abroad" = "X", "Specification (Norges Bank)" = "Y"
        VerifyPurchJnlLinePmtTypeCodeAbroad(GenJournalLine, Vendor."Payment Type Code Abroad", Vendor."Specification (Norges Bank)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPmtTypeCodeAbroadInPurchJnl_Negative_OtherDocTypes()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        DocumentType: Option;
    begin
        // [FEATURE] [UT] [Vendor] [Payment Type Code Abroad]
        // [SCENARIO 378829] Vendor's "Payment Type Code Abroad", "Specification (Norges Bank)" are not filled in Purchase Journal line when validate Vendor in case of non-Invoice document type

        // [GIVEN] Vendor "V" with "Payment Type Code Abroad" = "X", "Specification (Norges Bank)" = "Y"
        CreateVendorWithPmtTypeCodeAbroad(Vendor);
        for DocumentType := GenJournalLine."Document Type"::" ".AsInteger() to GenJournalLine."Document Type"::Reminder.AsInteger() do
            if DocumentType <> GenJournalLine."Document Type"::Invoice.AsInteger() then begin
                // [GIVEN] Purchase Journal Line with "Document Type" = " "("Credit Memo", "Finance Charge Memo", Payment, Refund, Reminder), "Account Type" = "Vendor"
                GenJournalLine.Init();
                GenJournalLine.Validate("Document Type", DocumentType);
                GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Vendor);
                // [WHEN] Validate Purchase Journal line "Account No." = "V"
                GenJournalLine.Validate("Account No.", Vendor."No.");
                // [THEN] Purchase Journal Line's "Payment Type Code Abroad" = "", "Specification (Norges Bank)" = ""
                VerifyPurchJnlLinePmtTypeCodeAbroad(GenJournalLine, '', '');
            end;
    end;

    local procedure CreateVendorWithPmtTypeCodeAbroad(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Payment Type Code Abroad" := MockPaymentTypeCodeAbroad();
        Vendor."Specification (Norges Bank)" := LibraryUtility.GenerateGUID();
        Vendor.Modify();
    end;

    local procedure MockPaymentTypeCodeAbroad(): Code[2]
    var
        PaymentTypeCodeAbroad: Record "Payment Type Code Abroad";
    begin
        PaymentTypeCodeAbroad.Init();
        PaymentTypeCodeAbroad.Code :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(PaymentTypeCodeAbroad.FieldNo(Code), DATABASE::"Payment Type Code Abroad"), 1, MaxStrLen(PaymentTypeCodeAbroad.Code));
        PaymentTypeCodeAbroad.Insert();
        exit(PaymentTypeCodeAbroad.Code);
    end;

    local procedure GetKIDNumber(): Code[10]
    var
        DocumentTools: Codeunit DocumentTools;
    begin
        exit('1234' + DocumentTools.Modulus10('1234'));
    end;

    local procedure VerifyPurchJnlLinePmtTypeCodeAbroad(GenJournalLine: Record "Gen. Journal Line"; ExpectedPmtTypeCodeAbroad: Code[2]; ExpectedSpecNorgesBank: Code[60])
    begin
        Assert.AreEqual(
          ExpectedPmtTypeCodeAbroad, GenJournalLine."Payment Type Code Abroad", GenJournalLine.FieldCaption("Payment Type Code Abroad"));
        Assert.AreEqual(
          ExpectedSpecNorgesBank, GenJournalLine."Specification (Norges Bank)", GenJournalLine.FieldCaption("Specification (Norges Bank)"));
    end;
}

