codeunit 144510 "ERM FA Charges Allocation"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        Assert: Codeunit Assert;
        FAStatus: Option Inventory,Montage,Operation,Maintenance,Repair,Disposed,WrittenOff;
        WrongLineCountErr: Label 'FA Ledger Entry line count with FA Charge is incorrect';
        IncorrectAmountErr: Label 'FA Ledger Entry line Amount value is incorrect';
        DimValueMismatchErr: Label 'Dimension value mismatch';

    [Test]
    [Scope('OnPrem')]
    procedure FACharge1FA()
    var
        PurchaseHeader: Record "Purchase Header";
        FAChargeCode: Code[20];
        DocumentNo: Code[20];
        FixedAssetNo: array[4] of Code[20];
        FAChargeAmount: Decimal;
    begin
        // Verify FA Ledger Entries for FA Charge 1 Item
        FAChargeCode := CreateFACharge();

        CreateVendFAPurch(PurchaseHeader, FixedAssetNo, 1);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        FAChargeAmount := LibraryRandom.RandDec(1000, 2);
        CreateFAChargePurchDoc(PurchaseHeader, DocumentNo, FAChargeCode, FAChargeAmount);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        FindAndVerifyFALedgerEntryAmount(FixedAssetNo[1], FAChargeCode, 1, FAChargeAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FAChargeCM()
    var
        PurchaseHeader: Record "Purchase Header";
        Counter: Integer;
        FAReleaseDate: Date;
        FAChargeCode: Code[20];
        DocumentNo: Code[20];
        FixedAssetNo: array[4] of Code[20];
    begin
        // Verify FA Ledger Entries for FA Charge and Credit Memo
        FAChargeCode := CreateFACharge();

        CreateVendFAPurch(PurchaseHeader, FixedAssetNo, 4);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        FAReleaseDate := CalcDate('<CM+1M>', WorkDate());

        for Counter := 1 to 2 do
            CreateAndPostFAReleaseDoc(FixedAssetNo[Counter], FAReleaseDate);

        CreateFAChargePurchDoc(
          PurchaseHeader, DocumentNo, FAChargeCode,
          LibraryRandom.RandDec(1000, 2));
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        for Counter := 3 to 4 do begin
            CreateAndPostFAReleaseDoc(FixedAssetNo[Counter], FAReleaseDate);
            CreatePostReversedFAAct(FixedAssetNo[Counter], FAReleaseDate);
            ChangeFAStatus(FixedAssetNo[Counter], FAStatus::Inventory);
        end;

        CreateCreditMemoFromPostedDoc(
          PurchaseHeader, PurchaseHeader."Buy-from Vendor No.",
          CalcDate('<CM+2M>', WorkDate()),
          "Purchase Document Type From"::"Posted Invoice", DocumentNo);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Validate
        FindAndVerifyFALedgerEntryAmount(FixedAssetNo[3], FAChargeCode, 2, 0);
        FindAndVerifyFALedgerEntryAmount(FixedAssetNo[4], FAChargeCode, 2, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure FAChargeDeprBonus()
    var
        PurchaseHeader: Record "Purchase Header";
        FAChargeCode: Code[20];
        DocumentNo: Code[20];
        FixedAssetNo: array[4] of Code[20];
        FAReleaseDate: Date;
        DeprBonusPct: Decimal;
        PurchAmount: Decimal;
        PurchAndChargeAmount: Decimal;
        TaxDeprAmount: Decimal;
        DeprAmount: Decimal;
        DeprBonusAmount: Decimal;
        DeprDate: Date;
    begin
        // Verify Correct (Bonus) Depreciations Amounts after FA Charge
        FAChargeCode := CreateFACharge();

        PurchAmount := CreateVendFAPurch(PurchaseHeader, FixedAssetNo, 1);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchAndChargeAmount := PurchAmount + CreateFAChargePurchDoc(PurchaseHeader, DocumentNo, FAChargeCode, 5);
        DeprBonusPct := GetFADeprBonusPct(FixedAssetNo[1]);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        FAReleaseDate := CalcDate('<CM+1M>', WorkDate());
        CreateAndPostFAReleaseDoc(FixedAssetNo[1], FAReleaseDate);

        DeprDate := CalcDate('<CM+2M>', WorkDate());
        CalcBonusDepreciation(FixedAssetNo[1], GetTaxAccDeprBook(), DeprDate, true);
        CalcReleaseTaxDepr(FixedAssetNo[1], GetReleaseDeprBook(), GetTaxAccDeprBook(), DeprDate, true);

        DeprDate := CalcDate('<CM+3M>', WorkDate());
        CalcReleaseTaxDepr(FixedAssetNo[1], GetReleaseDeprBook(), GetTaxAccDeprBook(), DeprDate, true);

        DeprBonusAmount := Round(-PurchAndChargeAmount * (DeprBonusPct / 100), LibraryERM.GetAmountRoundingPrecision());
        TaxDeprAmount :=
          -Round((PurchAndChargeAmount + DeprBonusAmount) /
            GetDeprMonths(FixedAssetNo[1], GetTaxAccDeprBook()), LibraryERM.GetAmountRoundingPrecision());
        DeprAmount :=
          -Round(PurchAndChargeAmount /
            GetDeprMonths(FixedAssetNo[1], GetReleaseDeprBook()), LibraryERM.GetAmountRoundingPrecision());

        VerifyDeprLedgerEntry(FixedAssetNo[1], 1, true, GetTaxAccDeprBook(), DeprBonusAmount);
        VerifyDeprLedgerEntry(FixedAssetNo[1], 2, false, GetTaxAccDeprBook(), TaxDeprAmount);
        VerifyDeprLedgerEntry(FixedAssetNo[1], 2, false, GetReleaseDeprBook(), DeprAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAChargeDimensions()
    var
        PurchaseHeader: Record "Purchase Header";
        DimensionCode: array[2] of Code[20];
        DimensionValueCode: array[2] of Code[20];
        FAChargeNo: Code[20];
        DocumentNo: Code[20];
        FixedAssetNo: array[4] of Code[20];
    begin
        // Verify FA Ledger Entry and GL Entry correct dimensions from FA Charge
        FAChargeNo := CreateFACharge();

        CreateDimensionDimValue(FAChargeNo, DimensionCode[1], DimensionValueCode[1]);

        CreateVendFAPurch(PurchaseHeader, FixedAssetNo, 1);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateFAChargePurchDoc(PurchaseHeader, DocumentNo, FAChargeNo, 5);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VerifyFALedgerEntryDim(FAChargeNo);
        VerifyGLEntryDim(DocumentNo, FAChargeNo);
    end;

    local procedure CreateFA(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
    begin
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        SetRandFADeprBonus(FixedAsset."No.");
        DeprBook.Get(GetReleaseDeprBook());
        DeprBook.Validate("Default Final Rounding Amount", 0);
        DeprBook.Modify(true);
        exit(FixedAsset."No.");
    end;

    local procedure SetRandFADeprBonus(FixedAssetNo: Code[20])
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        FADeprBook.Get(FixedAssetNo, GetTaxAccDeprBook());
        FADeprBook.Validate("Depr. Bonus %", LibraryRandom.RandIntInRange(1, 99));
        FADeprBook.Modify(true);
    end;

    local procedure GetFADeprBonusPct(FixedAssetNo: Code[20]): Decimal
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        FADeprBook.Get(FixedAssetNo, GetTaxAccDeprBook());
        exit(FADeprBook."Depr. Bonus %");
    end;

    local procedure FindFADeprLedgerEntry(FixedAssetNo: Code[20]; var FALedgerEntry: Record "FA Ledger Entry"; FAChargeNo: Code[20]; DeprBookCode: Code[20])
    begin
        FALedgerEntry.SetRange("FA No.", FixedAssetNo);
        FALedgerEntry.SetRange("FA Charge No.", FAChargeNo);
        FALedgerEntry.SetRange("Depreciation Book Code", DeprBookCode);
        FALedgerEntry.FindFirst();
    end;

    local procedure VerifyFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; Amount: Decimal)
    begin
        Assert.AreEqual(Amount, FALedgerEntry.Amount, IncorrectAmountErr);
    end;

    local procedure VerifyFALedgerEntryAmount(var FALedgerEntry: Record "FA Ledger Entry"; Total: Decimal)
    var
        AmountSum: Decimal;
    begin
        repeat
            AmountSum += FALedgerEntry.Amount;
        until FALedgerEntry.Next() = 0;
        Assert.AreEqual(Total, AmountSum, IncorrectAmountErr);
    end;

    local procedure CreateVendFAPurch(var PurchaseHeader: Record "Purchase Header"; var FixedAssetNo: array[4] of Code[20]; "Count": Integer): Decimal
    var
        Vendor: Record Vendor;
        Counter: Integer;
    begin
        Setup();

        LibraryPurchase.CreateVendor(Vendor);
        for Counter := 1 to Count do
            FixedAssetNo[Counter] := CreateFA();

        CreatePurchInv(PurchaseHeader, Vendor."No.", FixedAssetNo, Count);

        PurchaseHeader.CalcFields(Amount);
        exit(PurchaseHeader.Amount);
    end;

    local procedure Setup()
    var
        TaxRegisterSetup: Record "Tax Register Setup";
        DeprBook: Record "Depreciation Book";
        PurchasePayablesSetup: Record "Purchases & Payables Setup";
    begin
        TaxRegisterSetup.Get();
        TaxRegisterSetup."Calculate TD for each FA" := false;
        TaxRegisterSetup."Rel. Act as Depr. Bonus Base" := true;
        TaxRegisterSetup.Modify(true);
        DeprBook.Get(GetTaxAccDeprBook());
        DeprBook."Allow Identical Document No." := true;
        DeprBook.Modify();
        PurchasePayablesSetup.Get();
        PurchasePayablesSetup."Ext. Doc. No. Mandatory" := false;
        PurchasePayablesSetup.Modify(true);
    end;

    local procedure CreateFACharge(): Code[20]
    var
        FACharge: Record "FA Charge";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        FACharge.Init();
        FACharge."No." := LibraryUtility.GenerateRandomCode(FACharge.FieldNo("No."), DATABASE::"FA Charge");
        FACharge."G/L Acc. for Released FA" := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" ");
        GLAccount.Get(FACharge."G/L Acc. for Released FA");
        FACharge."Gen. Prod. Posting Group" := GLAccount."Gen. Prod. Posting Group";
        FACharge."VAT Prod. Posting Group" := GLAccount."VAT Prod. Posting Group";
        FACharge.Insert();
        SetEmptyTransVATType(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        exit(FACharge."No.");
    end;

    local procedure AddPurchaseLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; No: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, Type,
          No,
          1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(50));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchInv(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; FixedAssetNo: array[4] of Code[20]; "Count": Integer): Decimal
    var
        PurchaseLine: Record "Purchase Line";
        Counter: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        for Counter := 1 to Count do
            AddPurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::"Fixed Asset", FixedAssetNo[Counter]);

        PurchaseHeader.CalcFields(Amount);

        exit(PurchaseHeader.Amount);
    end;

    local procedure CreateFAChargePurchDoc(var PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20]; FAChargeCode: Code[20]; AmountToAllocate: Decimal): Decimal
    var
        AllocateFACharges: Report "Allocate FA Charges";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          PurchaseHeader."Buy-from Vendor No.");

        PurchaseHeader.Reset();
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.FindFirst();

        AllocateFACharges.SetTableView(PurchaseHeader);
        AllocateFACharges.UseRequestPage(false);
        AllocateFACharges.SetParameters(2, DocumentNo, AmountToAllocate, FAChargeCode);
        AllocateFACharges.Run();

        PurchaseHeader.CalcFields(Amount);

        exit(PurchaseHeader.Amount);
    end;

    local procedure ReplaceFADocLineDeprBook(FANo: Code[20])
    var
        FADocLine: Record "FA Document Line";
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FADocLine.SetRange("Document Type", FADocLine."Document Type"::Release);
        FADocLine.SetRange("FA No.", FANo);
        FADocLine.FindFirst();
        FADocLine.Validate("Depreciation Book Code", FASetup."Release Depr. Book");
        FADocLine.Validate("New Depreciation Book Code", FASetup."Default Depr. Book");
        FADocLine.Modify(true);
    end;

    local procedure ChangeFAStatus(FANo: Code[20]; NewStatus: Option)
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.Get(FANo);
        FixedAsset.Validate(Status, NewStatus);
        FixedAsset.Modify(true);
    end;

    local procedure CountFAChargeLELines(var FALedgerEntry: Record "FA Ledger Entry"; "Count": Integer)
    begin
        Assert.AreEqual(Count, FALedgerEntry.Count, WrongLineCountErr);
    end;

    local procedure CreatePostReversedFAAct(FANo: Code[20]; FAReleaseDate: Date)
    var
        FADocumentHeader: Record "FA Document Header";
    begin
        LibraryFixedAsset.CreateFAReleaseDoc(FADocumentHeader, FANo, FAReleaseDate);
        ReplaceFADocLineDeprBook(FANo);
        LibraryFixedAsset.PostFADocument(FADocumentHeader);
    end;

    local procedure CreateCreditMemoFromPostedDoc(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; PostingDate: Date; PostedDocType: Enum "Purchase Document Type From"; PostedDocNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, PostedDocType, PostedDocNo, false, true);
    end;

    local procedure FindAndVerifyFALedgerEntryAmount(FANo: Code[20]; FAChargeCode: Code[20]; LinesNo: Integer; "Sum": Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FindFADeprLedgerEntry(FANo, FALedgerEntry, FAChargeCode, GetTaxAccDeprBook());
        CountFAChargeLELines(FALedgerEntry, LinesNo);
        VerifyFALedgerEntryAmount(FALedgerEntry, Sum);
    end;

    local procedure CalcDepreciation(FixedAssetNo: Code[20]; DeprBook: Code[10]; PostingDate: Date; Post: Boolean): Decimal
    begin
        exit(LibraryFixedAsset.CalcDepreciation(FixedAssetNo, DeprBook, PostingDate, Post, false));
    end;

    local procedure CalcBonusDepreciation(FixedAssetNo: Code[20]; DeprBookCode: Code[10]; FADeprDate: Date; Post: Boolean): Decimal
    begin
        exit(LibraryFixedAsset.CalcDepreciation(FixedAssetNo, DeprBookCode, FADeprDate, Post, true));
    end;

    local procedure VerifyDeprLedgerEntry(FixedAssetNo: Code[20]; "Count": Integer; DeprBonus: Boolean; DeprBookCode: Code[20]; DeprAmount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
        i: Integer;
    begin
        FALedgerEntry.Reset();
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
        FALedgerEntry.SetRange("Depr. Bonus", DeprBonus);
        FindFADeprLedgerEntry(FixedAssetNo, FALedgerEntry, '', DeprBookCode);
        for i := 1 to Count do begin
            VerifyFALedgerEntry(FALedgerEntry, DeprAmount);
            FALedgerEntry.Next();
        end;
    end;

    local procedure CreateDimensionDimValue(FAChargeCode: Code[20]; var DimensionCode: Code[20]; var DimensionValueCode: Code[20])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionCode := Dimension.Code;
        DimensionValueCode := DimensionValue.Code;

        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"FA Charge", FAChargeCode, DimensionCode, DimensionValueCode);
    end;

    local procedure SetEmptyTransVATType(VATBusPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroupCode, VATProdPostingGroupCode);
        VATPostingSetup."Trans. VAT Type" := VATPostingSetup."Trans. VAT Type"::" ";
        VATPostingSetup.Modify(true);
    end;

    local procedure VerifyDimensionSetID(var DefaultDimension: Record "Default Dimension"; DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DefaultDimension.FindSet();
        repeat
            DimensionSetEntry.Get(DimensionSetID, DefaultDimension."Dimension Code");
            Assert.AreEqual(DimensionSetEntry."Dimension Value Code", DefaultDimension."Dimension Value Code", DimValueMismatchErr);
        until DefaultDimension.Next() = 0;
    end;

    local procedure FindDefaultDimension(var DefaultDimension: Record "Default Dimension"; TableID: Integer; No: Code[20])
    begin
        DefaultDimension.SetRange("Table ID", TableID);
        DefaultDimension.SetRange("No.", No);
        DefaultDimension.FindSet();
    end;

    local procedure VerifyFALedgerEntryDim(FAChargeNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.Reset();
        FALedgerEntry.SetRange("FA Charge No.", FAChargeNo);
        FALedgerEntry.FindFirst();
        FindDefaultDimension(DefaultDimension, DATABASE::"FA Charge", FAChargeNo);
        VerifyDimensionSetID(DefaultDimension, FALedgerEntry."Dimension Set ID");
    end;

    local procedure VerifyGLEntryDim(DocNo: Code[20]; FAChargeNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::"Fixed Asset");
        GLEntry.FindSet();
        FindDefaultDimension(DefaultDimension, DATABASE::"FA Charge", FAChargeNo);
        repeat
            VerifyDimensionSetID(DefaultDimension, GLEntry."Dimension Set ID");
        until GLEntry.Next() = 0;
    end;

    local procedure GetDeprMonths(FANo: Code[20]; DeprBookCode: Code[20]): Decimal
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        FADeprBook.Get(FANo, DeprBookCode);
        exit(FADeprBook."No. of Depreciation Years" * 12);
    end;

    local procedure GetTaxAccDeprBook(): Code[10]
    var
        TaxRegisterSetup: Record "Tax Register Setup";
    begin
        TaxRegisterSetup.Get();
        exit(TaxRegisterSetup."Tax Depreciation Book");
    end;

    local procedure GetReleaseDeprBook(): Code[10]
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        exit(FASetup."Release Depr. Book");
    end;

    local procedure CalcReleaseTaxDepr(FANo: Code[20]; ReleaseDeprBook: Code[10]; TaxAccDeprBook: Code[10]; DeprDate: Date; Post: Boolean)
    begin
        CalcDepreciation(FANo, ReleaseDeprBook, DeprDate, Post);
        CalcDepreciation(FANo, TaxAccDeprBook, DeprDate, Post);
    end;

    local procedure CreateAndPostFAReleaseDoc(FANo: Code[20]; PostingDate: Date)
    var
        FADocumentHeader: Record "FA Document Header";
    begin
        LibraryFixedAsset.CreateFAReleaseDoc(FADocumentHeader, FANo, PostingDate);
        LibraryFixedAsset.PostFADocument(FADocumentHeader);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;
}

