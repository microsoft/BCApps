codeunit 144072 "UT COD VAT Exemption"
{
    // // [FEATURE] [UT] [VATEXEMP]
    // 
    // Test for feature VATEXEMP - VAT Exemption.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        DialogErr: Label 'Dialog';
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunDocumentTypeOrderSalesPostError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate OnRun Trigger of Codeunit - 80 Sales-Post.
        OnRunDocumentTypeSalesPost(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunDocumentTypeInvoiceSalesPostError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate OnRun Trigger of Codeunit - 80 Sales-Post.
        OnRunDocumentTypeSalesPost(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunDocumentTypeReturnOrderSalesPostError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate OnRun Trigger of Codeunit - 80 Sales-Post.
        OnRunDocumentTypeSalesPost(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunDocumentTypeCreditMemoSalesPostError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate OnRun Trigger of Codeunit - 80 Sales-Post.
        OnRunDocumentTypeSalesPost(SalesHeader."Document Type"::"Credit Memo");
    end;

    local procedure OnRunDocumentTypeSalesPost(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup.
        CreateSalesHeader(SalesHeader, DocumentType);

        // Exercise.
        asserterror CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        // Verify: Verify expected error code, actual error: It is not possible to post document with a customer with VAT exemption if an active VAT exemption doesn't exist.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnRunDocumentTypeCreditMemoServicePostError()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of the test is to validate OnRun Trigger of Codeunit - 5980 Service-Post.
        OnRunDocumentTypeServicePost(ServiceHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnRunDocumentTypeInvoiceServicePostError()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Purpose of the test is to validate OnRun Trigger of Codeunit - 5980 Service-Post.
        OnRunDocumentTypeServicePost(ServiceHeader."Document Type"::Invoice);
    end;

    local procedure OnRunDocumentTypeServicePost(DocumentType: Enum "Service Document Type")
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup: Create Service Document.
        CreateServiceHeader(ServiceHeader, DocumentType);
        CreateServiceLine(ServiceHeader."No.", DocumentType);

        // Exercise.
        asserterror CODEUNIT.Run(CODEUNIT::"Service-Post", ServiceHeader);

        // Verify: Verify expected error code, actual error: It is not possible to post document with a customer with VAT exemption if an active VAT exemption doesn't exist.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunDocumentTypeOrderPurchasePostError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnRun Trigger of Codeunit - 90 Purch.-Post.
        OnRunDocumentTypePurchasePost(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunDocumentTypeInvoicePurchasePostError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnRun Trigger of Codeunit - 90 Purch.-Post.
        OnRunDocumentTypePurchasePost(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunDocumentTypeReturnOrderPurchasePostError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnRun Trigger of Codeunit - 90 Purch.-Post.
        OnRunDocumentTypePurchasePost(PurchaseHeader."Document Type"::"Return Order");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRunDocumentTypeCreditMemoPurchasePostError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnRun Trigger of Codeunit - 90 Purch.-Post.
        OnRunDocumentTypePurchasePost(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [TransactionModel(TransactionModel::AutoCommit)]
    local procedure OnRunDocumentTypePurchasePost(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup.
        CreatePurchaseHeader(PurchaseHeader, DocumentType, true);  // Check VAT Exemption as TRUE.

        // Exercise.
        asserterror CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchaseHeader);

        // Verify: Verify expected error code, actual error: It is not possible to insert a vendor with VAT exemption if an active VAT exemption doesn't exist.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnRunVATPlafondPeriodAmountPurchasePostError()
    var
        VATPlafondPeriod: Record "VAT Plafond Period";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnRun Trigger of Codeunit - 90 Purch.-Post.

        // Setup: Create Purchase Invoice and VAT Plafond Period. Transaction Model Type Auto Commit is required as Commit is explicitly using on OnRun Trigger of Codeunit - 90 Purch.-Post.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, false);  // Check VAT Exemption as False.
        CreateGeneralPostingSetup(PurchaseHeader."Gen. Bus. Posting Group", CreatePurchaseLine(PurchaseHeader));
        CreateVATPlafondPeriod(VATPlafondPeriod, WorkDate());

        // Exercise.
        asserterror CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchaseHeader);

        // Verify: Verify expected error code, actual error: VAT Plafond Amount exceeded.
        Assert.ExpectedErrorCode(DialogErr);

        // Delete only if commited by purch-post
        if VATPlafondPeriod.Delete() then;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPlafondCalculatedAmountBasedOnDocumentDate()
    var
        VATPlafondPeriod: Record "VAT Plafond Period";
        PostingDate: Date;
        Amount: Decimal;
    begin
        // [SCENARIO 377801] Calculated Amount of VAT Plafond Period should be based on Document Date

        // [GIVEN] VAT Plafond Period with Year = "X"
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandIntInRange(5, 10)) + 'Y>', WorkDate());
        CreateVATPlafondPeriod(VATPlafondPeriod, PostingDate);

        // [GIVEN] VAT Entry with "Document Date" outside year "X"
        MockVATPlafondEntryWithDocDate(CalcDate('<' + Format(LibraryRandom.RandIntInRange(5, 10)) + 'Y>', PostingDate));

        // [WHEN] Post VAT Entry with "Document Date" inside year "X", "Plafond Entry" = Yes and "Amount" = 100
        Amount := MockVATPlafondEntryWithDocDate(PostingDate);

        // [THEN] "Calculated Amount" of VAT Plafond Period for Year "X" is 100
        VerifyVATPlafondCalculatedAmount(VATPlafondPeriod.Year, Amount);

        VATPlafondPeriod.Delete();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateGeneralPostingSetup(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup."Gen. Bus. Posting Group" := GenBusPostingGroup;
        GeneralPostingSetup."Gen. Prod. Posting Group" := GenProdPostingGroup;
        GeneralPostingSetup."Purch. Account" := CreateGLAccount();
        GeneralPostingSetup.Insert();
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item."VAT Prod. Posting Group" := CreateVATProductPostingGroup();
        Item."Inventory Posting Group" := LibraryUTUtility.GetNewCode10();
        Item."Base Unit of Measure" := LibraryUTUtility.GetNewCode10();
        Item.Insert();
        exit(Item."No.");
    end;

    local procedure CreateNumberSeries(): Code[10]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.Code := LibraryUTUtility.GetNewCode10();
        NoSeries."Date Order" := true;
        NoSeries.Insert();

        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine."Starting Date" := WorkDate();
        NoSeriesLine."Starting No." := Format(LibraryRandom.RandInt(10));
        NoSeriesLine.Insert();
        exit(NoSeries.Code);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VATExemption: Boolean)
    begin
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Pay-to Vendor No." := CreateVendor(PurchaseHeader."VAT Bus. Posting Group");
        PurchaseHeader."Buy-from Vendor No." := PurchaseHeader."Pay-to Vendor No.";
        PurchaseHeader."Gen. Bus. Posting Group" := LibraryUTUtility.GetNewCode10();
        PurchaseHeader."VAT Bus. Posting Group" := CreateVATBusinessPostingGroup(VATExemption);
        PurchaseHeader."Posting Date" := WorkDate();
        PurchaseHeader."Operation Type" := CreateNumberSeries();
        PurchaseHeader."Operation Occurred Date" := WorkDate();
        PurchaseHeader."Document Date" := WorkDate();
        PurchaseHeader."Posting No. Series" := CreateNumberSeries();
        PurchaseHeader."Vendor Invoice No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Receiving No. Series" := CreateNumberSeries();
        PurchaseHeader.Insert();
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"): Code[10]
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Type := PurchaseLine.Type::Item;
        Item.Get(CreateItem());
        CreateVATIdentifier(Item."VAT Prod. Posting Group");
        PurchaseLine."No." := Item."No.";
        PurchaseLine."Unit of Measure Code" := Item."Base Unit of Measure";
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."VAT Identifier" := Item."VAT Prod. Posting Group";  // VAT Identifier code as VAT Product Posting Group of Item.
        PurchaseLine.Quantity := LibraryRandom.RandDec(10, 2);
        PurchaseLine."Qty. to Receive" := PurchaseLine.Quantity;
        PurchaseLine."Qty. to Invoice" := PurchaseLine."Qty. to Receive";
        PurchaseLine."Gen. Bus. Posting Group" := PurchaseHeader."Gen. Bus. Posting Group";
        PurchaseLine."Gen. Prod. Posting Group" := LibraryUTUtility.GetNewCode10();
        PurchaseLine."VAT Prod. Posting Group" := CreateVATPostingSetup();
        PurchaseLine.Insert();
        exit(PurchaseLine."Gen. Prod. Posting Group");
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    begin
        SalesHeader."Document Type" := DocumentType;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Sell-to Customer No." := CreateCustomer();
        SalesHeader."Bill-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesHeader."VAT Bus. Posting Group" := CreateVATBusinessPostingGroup(true);  // Check VAT Exemption as True.
        SalesHeader."Posting Date" := WorkDate();
        SalesHeader."Document Date" := WorkDate();
        SalesHeader."Operation Type" := CreateNumberSeries();
        SalesHeader."Operation Occurred Date" := WorkDate();
        SalesHeader.Insert();
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type")
    begin
        ServiceHeader."Document Type" := DocumentType;
        ServiceHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceHeader."Customer No." := CreateCustomer();
        ServiceHeader."Bill-to Customer No." := ServiceHeader."Customer No.";
        ServiceHeader."Posting Date" := WorkDate();
        ServiceHeader."Document Date" := WorkDate();
        ServiceHeader."Operation Type" := CreateNumberSeries();
        ServiceHeader."Posting No. Series" := CreateNumberSeries();
        ServiceHeader."Operation Occurred Date" := WorkDate();
        ServiceHeader."VAT Bus. Posting Group" := CreateVATBusinessPostingGroup(true);  // Check VAT Exemption as True.
        ServiceHeader."Shipping No. Series" := CreateNumberSeries();
        ServiceHeader.Insert();
    end;

    local procedure CreateServiceLine(DocumentNo: Code[20]; DocumentType: Enum "Service Document Type")
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        Item.Get(CreateItem());
        ServiceLine."Document Type" := DocumentType;
        ServiceLine."Document No." := DocumentNo;
        ServiceLine.Type := ServiceLine.Type::Item;
        ServiceLine."No." := Item."No.";
        ServiceLine."Unit of Measure Code" := Item."Base Unit of Measure";
        ServiceLine.Quantity := LibraryRandom.RandInt(10);
        ServiceLine."Qty. to Invoice" := ServiceLine.Quantity;
        ServiceLine."Shipment No." := LibraryUTUtility.GetNewCode();
        ServiceLine.Insert();
    end;

    local procedure CreateVATBusinessPostingGroup(CheckVATExemption: Boolean): Code[20]
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
    begin
        VATBusPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        VATBusPostingGroup."Check VAT Exemption" := CheckVATExemption;
        VATBusPostingGroup.Insert();
        exit(VATBusPostingGroup.Code);
    end;

    local procedure CreateVATIdentifier("Code": Code[20])
    var
        VATIdentifier: Record "VAT Identifier";
    begin
        VATIdentifier.Code := Code;
        VATIdentifier."Subject to VAT Plafond" := true;
        VATIdentifier.Insert();
    end;

    local procedure CreateVATPostingSetup(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup."VAT Prod. Posting Group" := LibraryUTUtility.GetNewCode10();
        VATPostingSetup.Insert();
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateVATProductPostingGroup(): Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProductPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        VATProductPostingGroup.Insert();
        exit(VATProductPostingGroup.Code);
    end;

    local procedure CreateVATPlafondPeriod(var VATPlafondPeriod: Record "VAT Plafond Period"; PostingDate: Date)
    begin
        VATPlafondPeriod.Validate(Year, Date2DMY(PostingDate, 3));
        VATPlafondPeriod.Amount := -LibraryRandom.RandDec(10, 2);  // Negative Amount required.
        VATPlafondPeriod.Insert();
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor."Vendor Posting Group" := LibraryUTUtility.GetNewCode10();
        Vendor."Gen. Bus. Posting Group" := LibraryUTUtility.GetNewCode10();
        Vendor."VAT Bus. Posting Group" := VATBusPostingGroup;
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure MockVATPlafondEntryWithDocDate(DocumentDate: Date): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Init();
        VATEntry."Document Date" := DocumentDate;
        VATEntry.Type := VATEntry.Type::Purchase;
        VATEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry."Plafond Entry" := true;
        VATEntry.Base := LibraryRandom.RandDec(100, 2);
        VATEntry.Insert();
        exit(VATEntry.Base);
    end;

    local procedure VerifyVATPlafondCalculatedAmount(VATPlafondYear: Integer; ExpectedAmount: Decimal)
    var
        VATPlafondPeriod: Record "VAT Plafond Period";
    begin
        VATPlafondPeriod.Get(VATPlafondYear);
        VATPlafondPeriod.CalcFields("Calculated Amount");
        VATPlafondPeriod.TestField("Calculated Amount", ExpectedAmount);
    end;
}

