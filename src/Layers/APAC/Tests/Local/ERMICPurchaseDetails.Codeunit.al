codeunit 141083 "ERM IC Purchase Details"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Intercompany]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        SameCodeMissingDimErr: Label 'The %1 %2 with %3 %4 is required for %5 %6.', Comment = '%1 = "Dimension code" caption, %2= "Dimension Code" value, %3 = "Dimension value code" caption, %4 = "Dimension value code" value, %5 = Table caption (Vendor), %6 = Table value (XYZ)';
        UnexpectedErr: Label 'Expected value is different from Actual value.';
        VendorRegisterMsg: Label 'Vendor %1 is not registered. Do you wish to continue?';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VendorNoWithoutVendorRegistrationMsg()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
    begin
        // [SCENARIO] Program populates a warning message when creates a purchase order with Unregistered Vendor if, Vendor Registration Warning field is True.
        // Setup.
        GeneralLedgerSetup.Get();
        UpdateEnableGSTAustraliaGeneralLedgerSetup(true);  // Using True for Enable GST (Australia).
        UpdateVendorRegistrationWarningOnPurchasesPayablesSetup(true);  // Using True for Vendor Registration Warning.
        VendorNo := CreateVendorWithDimension('', false);  // Using False For Registerd.
        LibraryVariableStorage.Enqueue(VendorNo);  // Enqueue value for ConfirmHandler.

        // Exercise & Verify: Verification done in ConfirmHandler.
        asserterror LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);

        // TearDown.
        UpdateEnableGSTAustraliaGeneralLedgerSetup(GeneralLedgerSetup."Enable GST (Australia)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithDifferentDimensionOnInvAndBankAccPostingGrp()
    var
        DefaultDimension: Record "Default Dimension";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        // [SCENARIO] program does not create any posted purchase invoice after posting a purchase invoice if purchase invoice dimensions & Bank account posting groups A\C dimensions are different and value posting=Same Code.
        // Setup.
        GLAccountNo := CreateGLAccountWithDimension();
        CreatePurchaseInvoice(
          PurchaseLine, CreateVendorWithDimension(GLAccountNo, true), LibraryInventory.CreateItem(Item), PurchaseLine.Type::Item);  // Using True For Registerd.
        PurchaseHeader.Get(PurchaseLine."Document Type"::Invoice, PurchaseLine."Document No.");
        FindDefaultDimensionCode(DefaultDimension, GLAccountNo);

        // [WHEN] Post Invoice as Receive and Invoice.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Error "Select Dimension Value Code..."
        Assert.ExpectedError(
          StrSubstNo(SameCodeMissingDimErr, DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code", DefaultDimension.FieldCaption("Dimension Value Code"), DefaultDimension."Dimension Value Code", GLAccount.TableCaption(), GLAccountNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvWithSameDimensionOnInvAndBankAccPostingGrp()
    var
        DefaultDimension: Record "Default Dimension";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [SCENARIO] program create any posted purchase invoice after posting a purchase invoice if purchase invoice dimensions & Bank account posting groups A\C dimensions are same and value posting=Same Code.
        // Setup.
        GLAccountNo := CreateGLAccountWithDimension();
        CreatePurchaseInvoice(
          PurchaseLine, CreateVendorWithDimension(GLAccountNo, true), LibraryInventory.CreateItem(Item), PurchaseLine.Type::Item);  // Using True For Registerd.
        PurchaseHeader.Get(PurchaseLine."Document Type"::Invoice, PurchaseLine."Document No.");
        FindDefaultDimensionCode(DefaultDimension, GLAccountNo);
        UpdateDimensionPurchaseHeader(PurchaseHeader, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");

        // [WHEN] Post Invoice as Receive and Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify.
        VerifyGLEntry(DocumentNo, GLAccountNo, PurchaseLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchCreditMemoWithICPartner()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ICSetup: Record "IC Setup";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        PostedCreditMemoNo: Code[20];
    begin
        // [SCENARIO] Program create correct G\L Entry after posting the Purchase Credit Memos with IC Partner which one is created from Copy functionality on posted Purchase invoice.
        // Setup.
        if not ICSetup.Get() then begin
            ICSetup.Init();
            ICSetup.Insert();
        end;
        ICSetup."Auto. Send Transactions" := false;
        ICSetup.Modify();
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseInvoice(PurchaseLine, Vendor."No.", CreateGLAccountWithDimension(), PurchaseLine.Type::"G/L Account");
        UpdateICDetailsOnPurchaseLine(PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type"::Invoice, PurchaseLine."Document No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // Exercise.
        PostedCreditMemoNo := CreateAndPostPurchaseCreditMemoFromCopyDoc(DocumentNo, PurchaseLine."Buy-from Vendor No.");

        // Verify.
        VerifyGLEntry(PostedCreditMemoNo, PurchaseLine."No.", PurchaseLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoWithICPartner()
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        ICSetup: Record "IC Setup";
        DocumentNo: Code[20];
        PostedCreditMemoNo: Code[20];
    begin
        // [SCENARIO] Program create correct G\L Entry after posting the Sales Credit Memos with IC Partner which one is created from Copy functionality on posted Sales invoice.
        // Setup.
        if not ICSetup.Get() then begin
            ICSetup.Init();
            ICSetup.Insert();
        end;
        ICSetup."Auto. Send Transactions" := false;
        ICSetup.Modify();
        LibrarySales.CreateCustomer(Customer);
        DocumentNo := CreateAndPostSalesInvoice(SalesLine, Customer."No.", CreateGLAccountWithDimension());

        // Exercise.
        PostedCreditMemoNo := CreateAndPostSalesCreditMemoFromCopyDoc(DocumentNo, Customer."No.");

        // Verify.
        VerifyGLEntry(PostedCreditMemoNo, SalesLine."No.", SalesLine.Amount);
    end;

    local procedure CreateAndPostPurchaseCreditMemoFromCopyDoc(DocumentNo: Code[20]; VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, "Purchase Document Type From"::"Posted Invoice", DocumentNo, false, false);  // Using False for IncludeHeader and RecalcLines.
        PurchaseHeader.Validate("Vendor Cr. Memo No.", DocumentNo);
        PurchaseHeader.Validate("Reason Code", CreateReason());
        PurchaseHeader.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Post as Receive and Invoice.
    end;

    local procedure CreateAndPostSalesCreditMemoFromCopyDoc(DocumentNo: Code[20]; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", DocumentNo, false, false);  // Using False for IncludeHeader and RecalcLines.
        SalesHeader.Validate("Reason Code", CreateReason());
        SalesHeader.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Post as Ship and Invoice.
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; No: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", No, LibraryRandom.RandDec(10, 2));  // Using Random Value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("IC Partner Code", FindICPartner());
        SalesLine.Validate("IC Partner Reference", FindICGLAccount());
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Post as Ship and Invoice.
    end;

    local procedure CreateBankAccount(GLBankAccountNo: Code[20]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Bank Acc. Posting Group", CreateBankAccountPostingGroup(GLBankAccountNo));
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateBankAccountPostingGroup(GLBankAccountNo: Code[20]): Code[20]
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        LibraryERM.CreateBankAccountPostingGroup(BankAccountPostingGroup);
        BankAccountPostingGroup.Validate("G/L Account No.", GLBankAccountNo);
        BankAccountPostingGroup.Modify(true);
        exit(BankAccountPostingGroup.Code);
    end;

    local procedure CreateDimensionWithDefaultValue(TableID: Integer; No: Code[20])
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, TableID, No, Dimension.Code, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Same Code");
        DefaultDimension.Modify(true);
    end;

    local procedure CreateGLAccountWithDimension(): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        CreateDimensionWithDefaultValue(DATABASE::"G/L Account", GLAccount."No.");
        exit(GLAccount."No.");
    end;

    local procedure CreatePaymentMethod(BalAccountNo: Code[20]): Code[20]
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bal. Account Type", PaymentMethod."Bal. Account Type"::"Bank Account");
        PaymentMethod.Validate("Bal. Account No.", CreateBankAccount(BalAccountNo));
        PaymentMethod.Modify(true);
        exit(PaymentMethod.Code);
    end;

    local procedure CreatePurchaseInvoice(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; No: Code[20]; Type: Enum "Purchase Line Type")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Using Random Value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateReason(): Code[10]
    var
        ReasonCode: Record "Reason Code";
    begin
        LibraryERM.CreateReasonCode(ReasonCode);
        exit(ReasonCode.Code);
    end;

    local procedure CreateVendorWithDimension(BalAccountNo: Code[20]; Registered: Boolean): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Registered, Registered);
        Vendor.Validate("Payment Method Code", CreatePaymentMethod(BalAccountNo));
        Vendor.Modify(true);
        CreateDimensionWithDefaultValue(DATABASE::Vendor, Vendor."No.");
        exit(Vendor."No.");
    end;

    local procedure FindDefaultDimensionCode(var DefaultDimension: Record "Default Dimension"; No: Code[20])
    begin
        DefaultDimension.SetRange("No.", No);
        DefaultDimension.FindFirst();
    end;

    local procedure FindICPartner(): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.SetRange(Blocked, false);
        ICPartner.FindFirst();
        exit(ICPartner.Code);
    end;

    local procedure FindICGLAccount(): Code[20]
    var
        ICGLAccount: Record "IC G/L Account";
    begin
        ICGLAccount.SetRange("Account Type", ICGLAccount."Account Type"::Posting);
        ICGLAccount.SetRange(Blocked, false);
        ICGLAccount.FindFirst();
        exit(ICGLAccount."No.");
    end;

    local procedure UpdateDimensionPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        DimensionCombination: Record "Dimension Combination";
    begin
        // Update Dimension value on Purchase Header Dimension.
        LibraryDimension.CreateDimensionCombination(DimensionCombination, DimensionCode, DimensionCode);
        PurchaseHeader.Validate(
          "Dimension Set ID", LibraryDimension.CreateDimSet(PurchaseHeader."Dimension Set ID", DimensionCode, DimensionValueCode));
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateEnableGSTAustraliaGeneralLedgerSetup(EnableGSTAustralia: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Enable GST (Australia)", EnableGSTAustralia);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateICDetailsOnPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("IC Partner Code", FindICPartner());
        PurchaseLine.Validate("IC Partner Reference", FindICGLAccount());
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateVendorRegistrationWarningOnPurchasesPayablesSetup(VendorRegistrationWarning: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Vendor Registration Warning", VendorRegistrationWarning);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        CreditAmount: Decimal;
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindSet();
        repeat
            CreditAmount += GLEntry."Credit Amount";
        until GLEntry.Next() = 0;
        Assert.AreNearlyEqual(CreditAmount, Amount, LibraryERM.GetAmountRoundingPrecision(), UnexpectedErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    var
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        Assert.AreEqual(StrSubstNo(VendorRegisterMsg, '%1', VendorNo), Question, UnexpectedErr);
    end;
}
