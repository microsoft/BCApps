codeunit 144014 "ERM Prepayments Local"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryUtility: Codeunit "Library - Utility";
        EntryType: Option Sale,Purchase;
        IsInitialized: Boolean;
        PostingDateMustNotBeAfterErr: Label 'Posting date must not be after %1 in %2';
        EntryNotAppliedErr: Label 'The %1 no. %2 is not applied fully because of remaining amount %3.';
        FieldValueIncorrectErr: Label 'Field %1 value is incorrect';

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPrepmtToPurchInvWithEarlierDate()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        PrepmtDocNo: Code[20];
        InvNo: Code[20];
        PostingDate: Date;
        Amount: Decimal;
    begin
        // Check that prepayment cannot be applied to purchase invoice with the earlier date

        PostPurchInvWithPrepayment(PrepmtDocNo, InvNo, PostingDate, Amount);
        asserterror ApplyVendEntries(
            VendLedgEntry."Document Type"::Payment, PrepmtDocNo, VendLedgEntry."Document Type"::Invoice, InvNo, Amount);
        Assert.ExpectedError(StrSubstNo(PostingDateMustNotBeAfterErr, PostingDate, VendLedgEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPrepmtToSalesInvWithEarlierDate()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        PrepmtDocNo: Code[20];
        InvNo: Code[20];
        PostingDate: Date;
        Amount: Decimal;
    begin
        // Check that prepayment cannot be applied to sales invoice with the earlier date

        PostSalesInvWithPrepayment(PrepmtDocNo, InvNo, PostingDate, Amount);
        asserterror ApplyCustEntries(
            CustLedgEntry."Document Type"::Payment, PrepmtDocNo, CustLedgEntry."Document Type"::Invoice, InvNo, -Amount);
        Assert.ExpectedError(StrSubstNo(PostingDateMustNotBeAfterErr, PostingDate, CustLedgEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPurchInvToPrepmtWithEarlierDate()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        PrepmtDocNo: Code[20];
        InvNo: Code[20];
        PostingDate: Date;
        Amount: Decimal;
    begin
        // Check that purchase invoice with the earlier date cannot be applied to prepayment

        PostPurchInvWithPrepayment(PrepmtDocNo, InvNo, PostingDate, Amount);
        asserterror ApplyVendEntries(
            VendLedgEntry."Document Type"::Invoice, InvNo, VendLedgEntry."Document Type"::Payment, PrepmtDocNo, -Amount);
        Assert.ExpectedError(StrSubstNo(PostingDateMustNotBeAfterErr, PostingDate, VendLedgEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplySalesInvToPrepmtWithEarlierDate()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        PrepmtDocNo: Code[20];
        InvNo: Code[20];
        PostingDate: Date;
        Amount: Decimal;
    begin
        // Check that sales invoice with the earlier date cannot be be applide to prepayment

        PostSalesInvWithPrepayment(PrepmtDocNo, InvNo, PostingDate, Amount);
        asserterror ApplyCustEntries(
            CustLedgEntry."Document Type"::Invoice, InvNo, CustLedgEntry."Document Type"::Payment, PrepmtDocNo, Amount);
        Assert.ExpectedError(StrSubstNo(PostingDateMustNotBeAfterErr, PostingDate, CustLedgEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPurchPrepmtToPrepmtRefund()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        PrepmtDocNo: Code[20];
        RefundDocNo: Code[20];
        Amount: Decimal;
    begin
        // Check that purchase prepayment with earlier date can be applied to prepayment refund

        PostPurchPrepmtWithRefund(PrepmtDocNo, RefundDocNo, Amount);
        ApplyVendEntries(
          VendLedgEntry."Document Type"::Payment, PrepmtDocNo, VendLedgEntry."Document Type"::Refund, RefundDocNo, Amount);
        VerifyZeroRemainingAmountInVendLedgEntries(PrepmtDocNo, RefundDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplySalesPrepmtToPrepmtRefund()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        PrepmtDocNo: Code[20];
        RefundDocNo: Code[20];
        Amount: Decimal;
    begin
        // Check that sales prepayment with earlier date can be applied to prepayment refund

        PostSalesPrepmtWithRefund(PrepmtDocNo, RefundDocNo, Amount);
        ApplyCustEntries(
          CustLedgEntry."Document Type"::Payment, PrepmtDocNo, CustLedgEntry."Document Type"::Refund, RefundDocNo, Amount);
        VerifyZeroRemainingAmountInCustLedgEntries(PrepmtDocNo, RefundDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPurchPrepmtRefundToPrepmt()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        PrepmtDocNo: Code[20];
        RefundDocNo: Code[20];
        Amount: Decimal;
    begin
        // Check that purchase prepayment refund purchase can be applied to prepayment with earlier date

        PostPurchPrepmtWithRefund(PrepmtDocNo, RefundDocNo, Amount);
        ApplyVendEntries(
          VendLedgEntry."Document Type"::Refund, RefundDocNo, VendLedgEntry."Document Type"::Payment, PrepmtDocNo, -Amount);
        VerifyZeroRemainingAmountInVendLedgEntries(PrepmtDocNo, RefundDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplySalesPrepmtRefundToPrepmt()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        PrepmtDocNo: Code[20];
        RefundDocNo: Code[20];
        Amount: Decimal;
    begin
        // Check that sales  prepayment refund purchase can be applied to prepayment with earlier date

        PostSalesPrepmtWithRefund(PrepmtDocNo, RefundDocNo, Amount);
        ApplyCustEntries(
          CustLedgEntry."Document Type"::Refund, RefundDocNo, CustLedgEntry."Document Type"::Payment, PrepmtDocNo, -Amount);
        VerifyZeroRemainingAmountInCustLedgEntries(PrepmtDocNo, RefundDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnSalesPrepayment()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        PrepmtDocNo: Code[20];
        InvNo: Code[20];
        PostingDate: Date;
        Amount: Decimal;
    begin
        // Check Customer Ledger Entries after running Return Prepayment report
        PostSalesInvWithPrepayment(PrepmtDocNo, InvNo, PostingDate, Amount);
        CustLedgEntry.SetRange("Document No.", PrepmtDocNo);
        CustLedgEntry.FindFirst();
        RunReturnPrepaymentReport(CustLedgEntry."Entry No.", EntryType::Sale);
        VerifyCustLedgEntry(PrepmtDocNo, CustLedgEntry."Document Type"::" ", true, -CustLedgEntry.Amount);
        VerifyCustLedgEntry(PrepmtDocNo, CustLedgEntry."Document Type"::Payment, false, CustLedgEntry.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnPurchPrepayment()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        PrepmtDocNo: Code[20];
        InvNo: Code[20];
        PostingDate: Date;
        Amount: Decimal;
    begin
        // Check Vendor Ledger Entries after running Return Prepayment report
        PostPurchInvWithPrepayment(PrepmtDocNo, InvNo, PostingDate, Amount);
        VendLedgEntry.SetRange("Document No.", PrepmtDocNo);
        VendLedgEntry.FindFirst();
        RunReturnPrepaymentReport(VendLedgEntry."Entry No.", EntryType::Purchase);
        VerifyVendLedgEntry(PrepmtDocNo, VendLedgEntry."Document Type"::" ", true, VendLedgEntry.Amount);
        VerifyVendLedgEntry(PrepmtDocNo, VendLedgEntry."Document Type"::Payment, false, -VendLedgEntry.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnSalesPrepaymentDimSetID()
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        PrepmtDocNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Dimensions]
        // [SCENARIO 308893] Customer Ledger Entries created on "Return Prepayment" report have correct Dimension Set ID
        Initialize();

        // [GIVEN] Posted Sales Prepayment "PAY01" with modified "Dimension Set ID" = 123
        Amount := CreateSalesInvoice(SalesHeader, CalcDate('<-1D>', WorkDate()));
        CreatePrepmtGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, WorkDate(), GenJournalLine."Account Type"::Customer,
          SalesHeader."Sell-to Customer No.", -Amount, SalesHeader."No.");
        GenJournalLine.Validate("Dimension Set ID", CreateDimSet(GenJournalLine."Dimension Set ID"));
        GenJournalLine.Modify(true);
        PrepmtDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report "Return Prepayments" for the Customer Ledger Entry of "PAY01"
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::Payment, PrepmtDocNo);
        RunReturnPrepaymentReport(CustLedgEntry."Entry No.", EntryType::Sale);

        // [THEN] "Dimension Set ID" = 123 on both created Customer Ledger Entries
        VerifyCustLedgEntryDimSetID(PrepmtDocNo, CustLedgEntry."Document Type"::" ", true, GenJournalLine."Dimension Set ID");
        VerifyCustLedgEntryDimSetID(PrepmtDocNo, CustLedgEntry."Document Type"::Payment, false, GenJournalLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnPurchPrepaymentDimSetID()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PrepmtDocNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Dimensions]
        // [SCENARIO 308893] Vendor Ledger Entries created on "Return Prepayment" report have correct Dimension Set ID
        Initialize();

        // [GIVEN] Posted Purchase Prepayment "PAY01" with modified "Dimension Set ID" = 123
        Amount := CreatePurchInvoice(PurchaseHeader, CalcDate('<-1D>', WorkDate()));
        CreatePrepmtGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, WorkDate(), GenJournalLine."Account Type"::Vendor,
          PurchaseHeader."Buy-from Vendor No.", Amount, PurchaseHeader."No.");
        GenJournalLine.Validate("Dimension Set ID", CreateDimSet(GenJournalLine."Dimension Set ID"));
        GenJournalLine.Modify(true);
        PrepmtDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report "Return Prepayments" for the Vendor Ledger Entry of "PAY01"
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Payment, PrepmtDocNo);
        RunReturnPrepaymentReport(VendLedgEntry."Entry No.", EntryType::Purchase);

        // [THEN] "Dimension Set ID" = 123 on both created Vendor Ledger Entries
        VerifyVendLedgEntryDimSetID(PrepmtDocNo, VendLedgEntry."Document Type"::" ", true, GenJournalLine."Dimension Set ID");
        VerifyVendLedgEntryDimSetID(PrepmtDocNo, VendLedgEntry."Document Type"::Payment, false, GenJournalLine."Dimension Set ID");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
    end;

    local procedure PostPurchInvWithPrepayment(var PrepmtDocNo: Code[20]; var InvNo: Code[20]; var PostingDate: Date; var Amount: Decimal)
    var
        PurchHeader: Record "Purchase Header";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        Amount := CreatePurchInvoice(PurchHeader, CalcDate('<-1D>', WorkDate()));
        PostingDate := PurchHeader."Posting Date";
        CreatePostPrepmtGenJnlLine(
          GenJnlLine, GenJnlLine."Document Type"::Payment, WorkDate(), GenJnlLine."Account Type"::Vendor,
          PurchHeader."Buy-from Vendor No.", Amount, PurchHeader."No.");
        PrepmtDocNo := GenJnlLine."Document No.";
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
    end;

    local procedure PostSalesInvWithPrepayment(var PrepmtDocNo: Code[20]; var InvNo: Code[20]; var PostingDate: Date; var Amount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        Amount := CreateSalesInvoice(SalesHeader, CalcDate('<-1D>', WorkDate()));
        PostingDate := SalesHeader."Posting Date";
        CreatePostPrepmtGenJnlLine(
          GenJnlLine, GenJnlLine."Document Type"::Payment, WorkDate(), GenJnlLine."Account Type"::Customer,
          SalesHeader."Sell-to Customer No.", -Amount, SalesHeader."No.");
        PrepmtDocNo := GenJnlLine."Document No.";
        InvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure PostPurchPrepmtWithRefund(var PrepmtDocNo: Code[20]; var RefundDocNo: Code[20]; var Amount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendNo: Code[20];
    begin
        VendNo := LibraryPurchase.CreateVendorNo();
        Amount := LibraryRandom.RandDec(100, 2);
        PrepmtDocNo :=
          CreatePostPrepmtGenJnlLine(
            GenJnlLine, GenJnlLine."Document Type"::Payment, CalcDate('<-1D>', WorkDate()), GenJnlLine."Account Type"::Vendor,
            VendNo, Amount, ''); // pass empty value for Prepmt Doc. No.
        RefundDocNo :=
          CreatePostPrepmtGenJnlLine(
            GenJnlLine, GenJnlLine."Document Type"::Refund, WorkDate(), GenJnlLine."Account Type"::Vendor,
            VendNo, -Amount, '');
    end;

    local procedure PostSalesPrepmtWithRefund(var PrepmtDocNo: Code[20]; var RefundDocNo: Code[20]; var Amount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        CreateSalesInvoice(SalesHeader, CalcDate('<-1D>', WorkDate()));
        Amount := -LibraryRandom.RandDec(100, 2);
        PrepmtDocNo :=
          CreatePostPrepmtGenJnlLine(
            GenJnlLine, GenJnlLine."Document Type"::Payment, CalcDate('<-1D>', WorkDate()), GenJnlLine."Account Type"::Customer,
            SalesHeader."Sell-to Customer No.", Amount, SalesHeader."No.");
        RefundDocNo :=
          CreatePostPrepmtGenJnlLine(
            GenJnlLine, GenJnlLine."Document Type"::Refund, WorkDate(), GenJnlLine."Account Type"::Customer,
            SalesHeader."Sell-to Customer No.", -Amount, SalesHeader."No.");
    end;

    local procedure CreatePurchInvoice(var PurchHeader: Record "Purchase Header"; PostingDate: Date): Decimal
    var
        PurchLine: Record "Purchase Line";
        VendNo: Code[20];
        GLAccNo: Code[20];
    begin
        VendNo := LibraryPurchase.CreateVendorNo();
        GLAccNo := LibraryERM.CreateGLAccountWithPurchSetup();
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice, VendNo);
        PurchHeader.Validate("Posting Date", PostingDate);
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccNo, LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
        exit(PurchLine."Amount Including VAT");
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; PostingDate: Date): Decimal
    var
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        GLAccNo: Code[20];
    begin
        CustNo := LibrarySales.CreateCustomerNo();
        GLAccNo := LibraryERM.CreateGLAccountWithSalesSetup();
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccNo, LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        exit(SalesLine."Amount Including VAT");
    end;

    local procedure InitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        LibraryERM.FindGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
    end;

    local procedure CreatePostPrepmtGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; EntryAmount: Decimal; PrepmtDocNo: Code[20]): Code[20]
    begin
        CreatePrepmtGenJnlLine(GenJnlLine, DocType, PostingDate, AccountType, AccountNo, EntryAmount, PrepmtDocNo);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine."Document No.");
    end;

    local procedure CreatePrepmtGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; EntryAmount: Decimal; PrepmtDocNo: Code[20]): Code[20]
    begin
        InitGenJnlLine(GenJnlLine);
        LibraryJournals.CreateGenJournalLine(
          GenJnlLine, GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", DocType, AccountType, AccountNo,
          GenJnlLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), EntryAmount);
        GenJnlLine.Validate(Prepayment, true);
        GenJnlLine.Validate("Posting Date", PostingDate);
        if PrepmtDocNo <> '' then
            GenJnlLine.Validate("Prepayment Document No.", PrepmtDocNo);
        GenJnlLine.Modify(true);
        exit(GenJnlLine."Document No.");
    end;

    local procedure CreateDimSet(DimSetID: Integer): Integer
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, LibraryUtility.GenerateGUID(), Dimension.Code);
        exit(LibraryDimension.CreateDimSet(DimSetID, Dimension.Code, DimensionValue.Code));
    end;

    local procedure ApplyCustEntries(DocumentTypeApplyWhat: Enum "Gen. Journal Document Type"; DocumentNoApplyWhat: Code[20]; DocTypeApplyTo: Enum "Gen. Journal Document Type"; DocNoApplyTo: Code[20]; AmountToApply: Decimal)
    var
        ApplCustLedgEntry: Record "Cust. Ledger Entry";
        ApplToCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(ApplCustLedgEntry, DocumentTypeApplyWhat, DocumentNoApplyWhat);
        LibraryERM.SetApplyCustomerEntry(ApplCustLedgEntry, AmountToApply);
        LibraryERM.FindCustomerLedgerEntry(ApplToCustLedgEntry, DocTypeApplyTo, DocNoApplyTo);
        LibraryERM.SetAppliestoIdCustomer(ApplToCustLedgEntry);
        LibraryERM.PostCustLedgerApplication(ApplCustLedgEntry);
    end;

    local procedure ApplyVendEntries(DocumentTypeApplyWhat: Enum "Gen. Journal Document Type"; DocumentNoApplyWhat: Code[20]; DocTypeApplyTo: Enum "Gen. Journal Document Type"; DocNoApplyTo: Code[20]; AmountToApply: Decimal)
    var
        ApplVendLedgEntry: Record "Vendor Ledger Entry";
        ApplToVendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(ApplVendLedgEntry, DocumentTypeApplyWhat, DocumentNoApplyWhat);
        LibraryERM.SetApplyVendorEntry(ApplVendLedgEntry, AmountToApply);
        LibraryERM.FindVendorLedgerEntry(ApplToVendLedgEntry, DocTypeApplyTo, DocNoApplyTo);
        LibraryERM.SetAppliestoIdVendor(ApplToVendLedgEntry);
        LibraryERM.PostVendLedgerApplication(ApplVendLedgEntry);
    end;

    local procedure VerifyZeroRemainingAmountInVendLedgEntries(PrepmtDocNo: Code[20]; RefundDocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VerifyZeroRemainingAmountInVendLedgEntry(VendLedgEntry."Document Type"::Payment, PrepmtDocNo);
        VerifyZeroRemainingAmountInVendLedgEntry(VendLedgEntry."Document Type"::Refund, RefundDocNo);
    end;

    local procedure VerifyZeroRemainingAmountInVendLedgEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, DocType, DocNo);
        VendLedgEntry.CalcFields("Remaining Amount");
        Assert.AreEqual(
          0, VendLedgEntry."Remaining Amount", StrSubstNo(EntryNotAppliedErr, VendLedgEntry.TableCaption(), VendLedgEntry."Entry No.", VendLedgEntry."Remaining Amount"));
    end;

    local procedure VerifyZeroRemainingAmountInCustLedgEntries(PrepmtDocNo: Code[20]; RefundDocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        VerifyZeroRemainingAmountInCustLedgEntry(CustLedgEntry."Document Type"::Payment, PrepmtDocNo);
        VerifyZeroRemainingAmountInCustLedgEntry(CustLedgEntry."Document Type"::Refund, RefundDocNo);
    end;

    local procedure VerifyZeroRemainingAmountInCustLedgEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, DocType, DocNo);
        CustLedgEntry.CalcFields("Remaining Amount");
        Assert.AreEqual(
          0, CustLedgEntry."Remaining Amount", StrSubstNo(EntryNotAppliedErr, CustLedgEntry.TableCaption(), CustLedgEntry."Entry No.", CustLedgEntry."Remaining Amount"));
    end;

    local procedure RunReturnPrepaymentReport(EntryNo: Integer; EntryType: Option)
    var
        ReturnPrepayment: Report "Return Prepayment";
    begin
        ReturnPrepayment.InitializeRequest(EntryNo, EntryType);
        ReturnPrepayment.UseRequestPage := false;
        ReturnPrepayment.Run();
    end;

    local procedure VerifyCustLedgEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; IsPrepayment: Boolean; VerifyAmount: Decimal)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetRange("Document No.", DocumentNo);
        CustLedgEntry.SetRange("Document Type", DocumentType);
        CustLedgEntry.SetRange(Prepayment, IsPrepayment);
        CustLedgEntry.FindFirst();
        Assert.AreEqual(VerifyAmount, CustLedgEntry.Amount,
          StrSubstNo(FieldValueIncorrectErr, CustLedgEntry.FieldCaption(Amount)));
    end;

    local procedure VerifyVendLedgEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; IsPrepayment: Boolean; VerifyAmount: Decimal)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetRange("Document No.", DocumentNo);
        VendLedgEntry.SetRange("Document Type", DocumentType);
        VendLedgEntry.SetRange(Prepayment, IsPrepayment);
        VendLedgEntry.FindFirst();
        Assert.AreEqual(VerifyAmount, VendLedgEntry.Amount,
          StrSubstNo(FieldValueIncorrectErr, VendLedgEntry.FieldCaption(Amount)));
    end;

    local procedure VerifyCustLedgEntryDimSetID(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; IsPrepayment: Boolean; VerifyDimSetID: Integer)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetRange("Document No.", DocumentNo);
        CustLedgEntry.SetRange("Document Type", DocumentType);
        CustLedgEntry.SetRange(Prepayment, IsPrepayment);
        CustLedgEntry.FindFirst();
        Assert.AreEqual(VerifyDimSetID, CustLedgEntry."Dimension Set ID",
          StrSubstNo(FieldValueIncorrectErr, CustLedgEntry.FieldCaption("Dimension Set ID")));
    end;

    local procedure VerifyVendLedgEntryDimSetID(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; IsPrepayment: Boolean; VerifyDimSetID: Integer)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetRange("Document No.", DocumentNo);
        VendLedgEntry.SetRange("Document Type", DocumentType);
        VendLedgEntry.SetRange(Prepayment, IsPrepayment);
        VendLedgEntry.FindFirst();
        Assert.AreEqual(VerifyDimSetID, VendLedgEntry."Dimension Set ID",
          StrSubstNo(FieldValueIncorrectErr, VendLedgEntry.FieldCaption("Dimension Set ID")));
    end;
}

