codeunit 144008 "ERM VAT Allocation"
{
    // // [FEATURE] [VAT] [VAT Allocation]
    // RegF 24891 VAT Allocation
    // 
    // ----------------------------------------------------------------
    // Test Function Name                                        TFS ID
    // ----------------------------------------------------------------
    // VATAllocOnAdvStatementWithDimension                       89640
    // VATAllocOnAdvStatementWithCombinedDim                     89640

    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "VAT Document Entry Buffer" = rimd;

    var
        VATAllocationLineRef: Record "VAT Allocation Line";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        SettlementType: Option ,Purchase,Sale,FA,FPE;
        WrongValueErr: Label 'Incorrect amount %1 in %2 %3', Comment = '%2=Table,%3=Key';
        OperationTxt: Label 'OPERATION';
        IsInitialized: Boolean;
        WrongDimSetIDErr: Label 'Wrong dimension set ID.';

    [Test]
    [Scope('OnPrem')]
    procedure MultilinePurchaseInvoice()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        SettlementDocNo: Code[20];
        PostingDate: Date;
    begin
        Initialize();

        CreateVATPostingSetup(VATPostingSetup);
        Vendor.Get(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Item.Get(
          LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));

        PostingDate := WorkDate();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 9);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 13);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 17);
        PurchaseLine.ModifyAll("Direct Unit Cost", 60);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VATEntry.FindLast();
        SettlementDocNo :=
          CreateVATSettlement(VATEntry, PostingDate, PostingDate, VATEntry."Document No.", SettlementType::Purchase);
        FindGenJnlLine(GenJnlLine, VATPostingSetup, SettlementDocNo);

        CreateUpdateVATAllocationLine(GenJnlLine, 0.7, VATAllocationLineRef.Type::Charge);
        PostVATSettlement(GenJnlLine);
        DeleteVATAllocationLine(0);

        GLEntry.FindLast();
        Assert.AreEqual(
          126.36, GLEntry.Amount, StrSubstNo(WrongValueErr, GLEntry.Amount, GLEntry.TableName, GLEntry."Entry No."));
        VerifyMultipleValueEntry(55.08, 42.12, 29.16);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithFA()
    var
        Vendor: Record Vendor;
        FA: Record "Fixed Asset";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        GenJnlLine: Record "Gen. Journal Line";
        FALedgEntry: Record "FA Ledger Entry";
        SettlementDocNo: Code[20];
        PostingDate: Date;
        ReleaseDate: Date;
    begin
        Initialize();

        CreateVATPostingSetup(VATPostingSetup);
        Vendor.Get(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));

        PostingDate := WorkDate();

        LibraryFixedAsset.CreateFixedAssetWithCustomSetup(FA, VATPostingSetup);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FA."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", 10000);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        ReleaseDate := PostingDate + 5;
        CreateAndPostFAReleaseDoc(FA."No.", ReleaseDate);

        VATEntry.FindLast();
        SettlementDocNo :=
          CreateVATSettlement(VATEntry, 0D, ReleaseDate, VATEntry."Document No.", SettlementType::FA);

        FindGenJnlLine(GenJnlLine, VATPostingSetup, SettlementDocNo);
        CreateUpdateVATAllocationLine(GenJnlLine, 0.7, VATAllocationLineRef.Type::Charge);

        PostVATSettlement(GenJnlLine);
        DeleteVATAllocationLine(0);

        VATEntry.Reset();
        VATEntry.FindLast();
        VerifyVATBaseAndAmount(VATEntry, 3000, 540);

        FALedgEntry.Reset();
        FALedgEntry.SetCurrentKey("FA No.");
        FALedgEntry.SetRange("FA No.", FA."No.");
        FALedgEntry.SetRange("Posting Date", ReleaseDate);
        FALedgEntry.SetRange("Document Type", VATEntry."Document Type");
        FALedgEntry.SetRange("Document No.", VATEntry."Document No.");
        FALedgEntry.FindLast();
        Assert.AreEqual(
          540, FALedgEntry.Amount, StrSubstNo(WrongValueErr, FALedgEntry.Amount, FALedgEntry.TableName, FALedgEntry."Entry No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultilinePurchInvWithItemFA()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        FA: Record "Fixed Asset";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        SettlementDocNo: Code[20];
        PurchInvNo: Code[20];
        PostingDate: Date;
        ReleaseDate: Date;
    begin
        Initialize();

        CreateVATPostingSetup(VATPostingSetup);
        Vendor.Get(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Item.Get(
          LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));

        PostingDate := WorkDate();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 9);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 13);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 17);
        PurchaseLine.ModifyAll("Direct Unit Cost", 60);
        LibraryFixedAsset.CreateFixedAssetWithCustomSetup(FA, VATPostingSetup);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FA."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", 10000);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VATEntry.Reset();
        VATEntry.FindLast();
        PurchInvNo := VATEntry."Document No.";

        ReleaseDate := PostingDate + 5;
        CreateAndPostFAReleaseDoc(FA."No.", ReleaseDate);

        SettlementDocNo :=
          CreateVATSettlement(VATEntry, PostingDate, PostingDate, PurchInvNo, SettlementType::Purchase);
        FindGenJnlLine(GenJnlLine, VATPostingSetup, SettlementDocNo);

        CreateUpdateVATAllocationLine(GenJnlLine, 0.7, VATAllocationLineRef.Type::Charge);
        PostVATSettlement(GenJnlLine);
        DeleteVATAllocationLine(GenJnlLine."Unrealized VAT Entry No.");

        SettlementDocNo :=
          CreateVATSettlement(VATEntry, 0D, ReleaseDate, PurchInvNo, SettlementType::FA);
        FindGenJnlLine(GenJnlLine, VATPostingSetup, SettlementDocNo);

        CreateUpdateVATAllocationLine(GenJnlLine, 0.6, VATAllocationLineRef.Type::Charge);
        PostVATSettlement(GenJnlLine);
        DeleteVATAllocationLine(0);

        GLEntry.SetRange("G/L Account No.", VATPostingSetup."Purch. VAT Unreal. Account");
        GLEntry.FindLast();
        Assert.AreEqual(
          -720, GLEntry.Amount, StrSubstNo(WrongValueErr, GLEntry.Amount, GLEntry.TableName, GLEntry."Entry No."));

        VerifyMultilinePurchInvWithItemFA_VATEntry(PurchInvNo);
        VerifyMultipleValueEntry(55.08, 42.12, 29.16);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MultilinePurchInvWithItemGLAccFA()
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        Item: Record Item;
        Item2: Record Item;
        Vendor: Record Vendor;
        FA: Record "Fixed Asset";
        VATPostingSetup: Record "VAT Posting Setup";
        TempVATDocEntryBuffer: Record "VAT Document Entry Buffer";
        GenJnlLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        PostingDate: Date;
        ReleaseDate: Date;
        PurchInvNo: Code[20];
        PurchInvNo2: Code[20];
        EndDate: Date;
        DeprDate: Date;
        VATAmount: Decimal;
        ChargeAmount: Decimal;
        WriteoffAmount: Decimal;
    begin
        Initialize();

        CreateVATPostingSetup(VATPostingSetup);
        Vendor.Get(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Item.Get(
          LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        Item2.Get(
          LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));

        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" "));
        GLAccount2.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" "));

        PostingDate := WorkDate();

        LibraryFixedAsset.CreateFixedAssetWithCustomSetup(FA, VATPostingSetup);
        PurchInvNo :=
          PostMultilinePurchInvWithItemGLAccFAAndVerify_1(
            Vendor."No.", FA."No.", GLAccount."No.", GLAccount2."No.", Item."No.");
        PurchInvNo2 :=
          PostMultilinePurchInvWithItemGLAccFAAndVerify_2(Vendor."No.", Item."No.", Item2."No.");

        ReleaseDate := PostingDate + 5;
        CreateAndPostFAReleaseDoc(FA."No.", ReleaseDate);
        DeprDate := CalcDate('<-CM+2M-1D>', ReleaseDate);
        LibraryFixedAsset.CalcDepreciation(FA."No.", OperationTxt, DeprDate, true, false);
        EndDate := CalcDate('<CY>', PostingDate);

        DeleteVATAllocationLine(0);
        CreateVATSettlementWithPostingDate(
          TempVATDocEntryBuffer, VATEntry, PostingDate, EndDate, PurchInvNo, PurchInvNo, SettlementType::FA);

        GenJnlLine.SetRange("Journal Template Name", VATPostingSetup."VAT Settlement Template");
        GenJnlLine.SetRange("Journal Batch Name", VATPostingSetup."VAT Settlement Batch");
        GenJnlLine.SetRange("Document No.", TempVATDocEntryBuffer."Document No.");
        if GenJnlLine.FindSet() then
            repeat
                GenJnlLine.TestField("Unrealized VAT Entry No.");
                CreateUpdateVATAllocationLine(GenJnlLine, 0.8, VATAllocationLineRef.Type::Charge);
            until GenJnlLine.Next() = 0;

        PostVATSettlement(GenJnlLine);
        CreateVATSettlementWithPostingDate(
          TempVATDocEntryBuffer, VATEntry, PostingDate, EndDate, PurchInvNo, PurchInvNo2, SettlementType::Purchase);

        GenJnlLine.SetRange("Journal Template Name", VATPostingSetup."VAT Settlement Template");
        GenJnlLine.SetRange("Journal Batch Name", VATPostingSetup."VAT Settlement Batch");
        GenJnlLine.SetFilter("Document No.", '%1|%2', PurchInvNo, PurchInvNo2);
        if GenJnlLine.FindSet() then
            repeat
                GenJnlLine.TestField("Unrealized VAT Entry No.");
                if Abs(GenJnlLine.Amount) = 180 then begin
                    VATAmount := GenJnlLine.Amount * 0.8;
                    ChargeAmount := GenJnlLine.Amount * 0.1;
                    WriteoffAmount := GenJnlLine.Amount - VATAmount - ChargeAmount;
                    LibraryERM.UpdateVATAllocLine(
                      GenJnlLine."Unrealized VAT Entry No.", 10000, 0, '', -VATAmount);
                    LibraryERM.CreateVATAllocLine(
                      GenJnlLine."Unrealized VAT Entry No.", 20000, 2, '', -ChargeAmount);
                    LibraryERM.CreateVATAllocLine(
                      GenJnlLine."Unrealized VAT Entry No.", 30000, 1, LibraryERM.CreateGLAccountNo(), -WriteoffAmount);
                end else
                    CreateUpdateVATAllocationLine(GenJnlLine, 0.8, VATAllocationLineRef.Type::Charge);
            until GenJnlLine.Next() = 0;
        PostVATSettlement(GenJnlLine);

        // VerifyMultilinePurchInvWithItemGLAccFA(PurchInvNo,PurchInvNo2,EndDate,FA."No.",DeprDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAllocationWithDimension()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        DimensionValue: Record "Dimension Value";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        GenJnlLine: Record "Gen. Journal Line";
        SettlementDocNo: Code[20];
        PostingDate: Date;
        DimSetID: Integer;
    begin
        Initialize();

        CreateVATPostingSetup(VATPostingSetup);
        Vendor.Get(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Item.Get(
          LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));

        CreateDimensionValue(DimensionValue);

        PostingDate := WorkDate();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(50, 100));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VATEntry.FindLast();
        SettlementDocNo :=
          CreateVATSettlement(VATEntry, PostingDate, PostingDate, VATEntry."Document No.", SettlementType::Purchase);
        FindGenJnlLine(GenJnlLine, VATPostingSetup, SettlementDocNo);

        CreateUpdateVATAllocationLine(
          GenJnlLine, LibraryRandom.RandDecInDecimalRange(0.5, 1, 1), VATAllocationLineRef.Type::WriteOff);
        DimSetID := UpdateVATAllocationLineDim(GenJnlLine."Unrealized VAT Entry No.", DimensionValue);
        // PostVATSettlement(GenJnlLine);

        VerifyGLEntriesDimension(VATPostingSetup."Write-Off VAT Account", DimSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAllocOnAdvStatementWithDimension()
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        InvNo: Code[20];
        DimSetID: Integer;
    begin
        // Verify that dimensions are inherited from advance statement to VAT Allocation through VAT Settlement Worksheet.
        Initialize();

        CreateVATPostingSetup(VATPostingSetup);
        Vendor.Get(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));

        DimSetID := GenerateDimSetID();
        InvNo :=
          CreatePostAdvanceStatementWithDimension(Vendor, VATPostingSetup."VAT Prod. Posting Group", DimSetID);
        CreateVATSettlement(VATEntry, WorkDate(), WorkDate(), InvNo, SettlementType::Purchase);
        VerifyDimSetIDInVATAllocLines(VATPostingSetup."Purchase VAT Account", DimSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAllocOnAdvStatementWithCombinedDim()
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        DimMgt: Codeunit DimensionManagement;
        GlobalDimensionCode: Code[20];
        InvNo: Code[20];
        DimSetID: array[10] of Integer;
        i: Integer;
    begin
        // Verify that dimensions from Default VAT Allocation and Advance Statement are combined in VAT Allocation through VAT Settlement Worksheet.
        Initialize();

        CreateVATPostingSetup(VATPostingSetup);
        Vendor.Get(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));

        for i := 1 to 2 do
            DimSetID[i] := GenerateDimSetID();
        CreateDefaultVATAllocation(VATPostingSetup, DimSetID[1]);
        InvNo :=
          CreatePostAdvanceStatementWithDimension(Vendor, VATPostingSetup."VAT Prod. Posting Group", DimSetID[2]);
        CreateVATSettlement(VATEntry, WorkDate(), WorkDate(), InvNo, SettlementType::Purchase);
        VerifyDimSetIDInVATAllocLines(
          VATPostingSetup."Purchase VAT Account", DimMgt.GetCombinedDimensionSetID(DimSetID, GlobalDimensionCode, GlobalDimensionCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvLineDimIsTransferedToPostedGLEntry()
    var
        TempVATDocEntryBuffer: Record "VAT Document Entry Buffer" temporary;
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        VATEntryNo: array[2] of Integer;
        CombineDimSetID: array[2] of Integer;
        InvoiceDocNo: Code[20];
        SettlementDocNo: Code[20];
    begin
        // [FEATURE] [Dimensions]
        // [SCENARIO 380807] Purchase Invoice line's dimension is used when Suggest/CopyToJnl/Post VAT Settlement lines
        Initialize();
        CreateTwoVATPostingSetups(VATPostingSetup);

        // [GIVEN] Purchase Invoice with header "Dimension Set ID" = "A" two lines:
        // [GIVEN] Line1: VAT Posting Setup "VAT Setup 1", "Dimension Set ID" = "B"
        // [GIVEN] Line2: VAT Posting Setup "VAT Setup 2", "Dimension Set ID" = "C"
        CreatePurchaseInvoiceHeaderWithDimSetID(PurchaseHeader, VATPostingSetup[1]);
        CreatePurchaseLineWithDimSetID(PurchaseLine[1], PurchaseHeader, VATPostingSetup[1], CombineDimSetID[1]);
        CreatePurchaseLineWithDimSetID(PurchaseLine[2], PurchaseHeader, VATPostingSetup[2], CombineDimSetID[2]);
        // [GIVEN] Post the Invoice. Two unrealized VAT Entries have been created: "VAT1", "VAT2"
        InvoiceDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        VATEntryNo[1] := FindVATEntry(VATPostingSetup[1], InvoiceDocNo, 0);
        VATEntryNo[2] := FindVATEntry(VATPostingSetup[2], InvoiceDocNo, 0);
        // [GIVEN] Suggest VAT Settlement Worksheet lines
        SuggestVATSettlementLines(TempVATDocEntryBuffer, InvoiceDocNo, SettlementType::Purchase);
        // [GIVEN] Two VAT Allocation lines have been created:
        // [GIVEN] Line1: "VAT Entry No." = "VAT1", "Dimension Set ID" = "AB", where "AB" - combined Dimension set for Dim Sets "A", "B"
        // [GIVEN] Line2: "VAT Entry No." = "VAT2", "Dimension Set ID" = "AC", where "AC" - combined Dimension set for Dim Sets "A", "C"
        VerifyVATAllocLineDimSetIDByVATEntryNo(VATEntryNo[1], CombineDimSetID[1]);
        VerifyVATAllocLineDimSetIDByVATEntryNo(VATEntryNo[2], CombineDimSetID[2]);
        // [GIVEN] Perform "Copy Lines to Journal" action on VAT Settlement Worksheet
        SettlementDocNo := VATSettlementCopyToJnl(TempVATDocEntryBuffer, InvoiceDocNo);
        // [GIVEN] Two VAT Settlement Journal lines have been created:
        // [GIVEN] Line1: "Unrealized VAT Entry No." = "VAT1", "Dimension Set ID" = "AB"
        // [GIVEN] Line2: "Unrealized VAT Entry No." = "VAT2", "Dimension Set ID" = "AC"
        VerifyGenJnlLineDimSetIDByUnrealVATEntryNo(VATPostingSetup[1], SettlementDocNo, VATEntryNo[1], CombineDimSetID[1]);
        VerifyGenJnlLineDimSetIDByUnrealVATEntryNo(VATPostingSetup[2], SettlementDocNo, VATEntryNo[2], CombineDimSetID[2]);

        // [WHEN] Post VAT Settlement Journal
        FindGenJnlLine(GenJournalLine, VATPostingSetup[1], SettlementDocNo);
        PostVATSettlement(GenJournalLine);

        // [THEN] Realized VATEntry has been created with "Unrealized VAT Entry No." = "VAT1" and related GLEntry with "Dimension Set ID" = "AB"
        VATEntryNo[1] := FindVATEntry(VATPostingSetup[1], InvoiceDocNo, VATEntryNo[1]);
        VerifyGLEntryDimSetIDByVATEntryNo(VATEntryNo[1], CombineDimSetID[1]);
        // [THEN] Realized VATEntry has been created with "Unrealized VAT Entry No." = "VAT2" and related GLEntry with "Dimension Set ID" = "AC"
        VATEntryNo[2] := FindVATEntry(VATPostingSetup[2], InvoiceDocNo, VATEntryNo[2]);
        VerifyGLEntryDimSetIDByVATEntryNo(VATEntryNo[2], CombineDimSetID[2]);
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if IsInitialized then
            exit;

        InventorySetup.Get();
        InventorySetup."Automatic Cost Posting" := true;
        InventorySetup.Modify();

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
    end;

    local procedure CreateGLAccountWithSetup(var GLAccount: Record "G/L Account"; GenProdPostGroupCode: Code[20]; VATProdPostGroupCode: Code[20])
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostGroupCode);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostGroupCode);
        GLAccount.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.CreateManualVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("VAT %", 18);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateTwoVATPostingSetups(var VATPostingSetup: array[2] of Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        CreateVATPostingSetup(VATPostingSetup[1]);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup[2] := VATPostingSetup[1];
        VATPostingSetup[2].Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup[2].Insert(true);
    end;

    local procedure CreateGenPostingSetupWithNewProdGroup(var GenPostingSetup: Record "General Posting Setup"; GenBusPostGroupCode: Code[20])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GenPostingSetup, GenBusPostGroupCode, GenProductPostingGroup.Code);
        GenPostingSetup."Sales Account" := LibraryERM.CreateGLAccountNo();
        GenPostingSetup.Modify();
    end;

    local procedure CreatePostAdvanceStatementWithDimension(Vendor: Record Vendor; VATProdPostGroupCode: Code[20]; DimensionSetID: Integer): Code[20]
    var
        GenPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, Vendor."No.");
        PurchHeader.Validate("Empl. Purchase", true);
        PurchHeader.Validate("Dimension Set ID", DimensionSetID);
        PurchHeader.Modify(true);
        CreateGenPostingSetupWithNewProdGroup(GenPostingSetup, Vendor."Gen. Bus. Posting Group");
        CreateGLAccountWithSetup(GLAccount, GenPostingSetup."Gen. Prod. Posting Group", VATProdPostGroupCode);
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(10));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreateDefaultVATAllocation(VATPostingSetup: Record "VAT Posting Setup"; DimSetID: Integer)
    var
        DefVAtAllocationLine: Record "Default VAT Allocation Line";
    begin
        DefVAtAllocationLine.Init();
        DefVAtAllocationLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        DefVAtAllocationLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        DefVAtAllocationLine."Line No." := 10000;
        DefVAtAllocationLine.Validate(Type, DefVAtAllocationLine.Type::VAT);
        DefVAtAllocationLine.Validate("Account No.", LibraryERM.CreateGLAccountNo());
        DefVAtAllocationLine.Validate("Allocation %", LibraryRandom.RandIntInRange(1, 50));
        DefVAtAllocationLine.Insert(true);
        DefVAtAllocationLine."Line No." += 10000;
        DefVAtAllocationLine.Validate("Allocation %", 100 - DefVAtAllocationLine."Allocation %");
        DefVAtAllocationLine.Insert(true);
        // Validate "Dimension Set ID" in the end because OnInsert trigger zero out "Dimension Set ID"
        DefVAtAllocationLine.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        DefVAtAllocationLine.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        DefVAtAllocationLine.ModifyAll("Dimension Set ID", DimSetID);
    end;

    local procedure CreateVATSettlement(var VATEntry: Record "VAT Entry"; FromDate: Date; ToDate: Date; DocNo: Code[20]; SettlementType: Option): Code[20]
    var
        TempVATDocEntryBuffer: Record "VAT Document Entry Buffer" temporary;
        VATSettlementMgt: Codeunit "VAT Settlement Management";
    begin
        TempVATDocEntryBuffer.DeleteAll();
        TempVATDocEntryBuffer.SetRange("Date Filter", FromDate, ToDate);
        TempVATDocEntryBuffer.SetRange("Document No.", DocNo);
        VATSettlementMgt.Generate(TempVATDocEntryBuffer, SettlementType);
        TempVATDocEntryBuffer.SetRange("Document No.", DocNo);
        VATSettlementMgt.CopyToJnl(TempVATDocEntryBuffer, VATEntry);
        exit(TempVATDocEntryBuffer."Document No.");
    end;

    local procedure CreateVATSettlementWithPostingDate(var TempVATDocEntryBuffer: Record "VAT Document Entry Buffer"; var VATEntry: Record "VAT Entry"; FromDate: Date; ToDate: Date; DocNo: Code[20]; DocNo2: Code[20]; SettlementType: Option): Code[20]
    var
        VATSettlementMgt: Codeunit "VAT Settlement Management";
    begin
        TempVATDocEntryBuffer.DeleteAll();
        TempVATDocEntryBuffer.SetRange("Date Filter", FromDate, ToDate);
        TempVATDocEntryBuffer.SetFilter("Document No.", '%1|%2', DocNo, DocNo2);
        VATSettlementMgt.Generate(TempVATDocEntryBuffer, SettlementType);
        TempVATDocEntryBuffer.SetFilter("Document No.", '%1|%2', DocNo, DocNo2);
        if TempVATDocEntryBuffer.FindSet(true) then
            repeat
                TempVATDocEntryBuffer."Posting Date" := ToDate;
                TempVATDocEntryBuffer.Modify();
            until TempVATDocEntryBuffer.Next() = 0;
        VATSettlementMgt.CopyToJnl(TempVATDocEntryBuffer, VATEntry);
        exit(TempVATDocEntryBuffer."Document No.");
    end;

    local procedure CreatePurchaseInvoiceHeaderWithDimSetID(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Dimension Set ID", GenerateDimSetID());
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLineWithDimSetID(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; var CombineDimSetID: Integer)
    var
        DummyGLAccount: Record "G/L Account";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Purchase),
          LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Validate("Dimension Set ID", GenerateDimSetID());
        PurchaseLine.Modify(true);
        CombineDimSetID := CombineDimSetIDs(PurchaseHeader."Dimension Set ID", PurchaseLine."Dimension Set ID");
    end;

    local procedure PostVATSettlement(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
    begin
        GenJnlPostBatch.VATSettlement(GenJnlLine);
    end;

    local procedure PostMultilinePurchInvWithItemGLAccFAAndVerify_1(VendNo: Code[20]; FANo: Code[20]; GLAccNo: Code[20]; GLAccNo2: Code[20]; ItemNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FANo, 1);
        PurchaseLine.Validate("Direct Unit Cost", 55000);
        PurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccNo2, 1);
        PurchaseLine.Validate("Direct Unit Cost", 2000);
        PurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", 1000);
        PurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, 10);
        PurchaseLine.Validate("Direct Unit Cost", 870);
        PurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, 25);
        PurchaseLine.Validate("Direct Unit Cost", 60);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(VerifyMultilinePurchInvWithItemGLAccFA_VATEntry());
    end;

    local procedure PostMultilinePurchInvWithItemGLAccFAAndVerify_2(VendNo: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, 33);
        PurchaseLine.Validate("Direct Unit Cost", 60);
        PurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, 33);
        PurchaseLine.Validate("Direct Unit Cost", 60);
        PurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo2, 2);
        PurchaseLine.Validate("Direct Unit Cost", 250);
        PurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo2, 2);
        PurchaseLine.Validate("Direct Unit Cost", 300);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(VerifyMultilinePurchInvWithItemGLAccFA_VATEntry_2());
    end;

    local procedure CreateUpdateVATAllocationLine(GenJnlLine: Record "Gen. Journal Line"; Factor: Decimal; SecondLineType: Option)
    var
        VATAmount: Decimal;
        SecondLineAmount: Decimal;
    begin
        VATAmount := GenJnlLine.Amount * Factor;
        SecondLineAmount := GenJnlLine.Amount - VATAmount;
        LibraryERM.UpdateVATAllocLine(
          GenJnlLine."Unrealized VAT Entry No.", 10000, 0, '', -VATAmount);
        LibraryERM.CreateVATAllocLine(
          GenJnlLine."Unrealized VAT Entry No.", 20000, SecondLineType, '', -SecondLineAmount);
    end;

    local procedure SuggestVATSettlementLines(var TempVATDocEntryBuffer: Record "VAT Document Entry Buffer" temporary; DocumentNo: Code[20]; SettlementType: Option)
    var
        VATSettlementMgt: Codeunit "VAT Settlement Management";
    begin
        TempVATDocEntryBuffer.SetRange("Date Filter", WorkDate(), WorkDate());
        TempVATDocEntryBuffer.SetRange("Document No.", DocumentNo);
        VATSettlementMgt.Generate(TempVATDocEntryBuffer, SettlementType);
    end;

    local procedure VATSettlementCopyToJnl(var TempVATDocEntryBuffer: Record "VAT Document Entry Buffer" temporary; DocumentNo: Code[20]): Code[20]
    var
        VATEntry: Record "VAT Entry";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
    begin
        TempVATDocEntryBuffer.SetRange("Document No.", DocumentNo);
        VATSettlementMgt.CopyToJnl(TempVATDocEntryBuffer, VATEntry);
        exit(TempVATDocEntryBuffer."Document No.");
    end;

    local procedure UpdateVATAllocationLineDim(UnrealizedVATEntryNo: Integer; DimValue: Record "Dimension Value"): Integer
    var
        VATAllocationLine: Record "VAT Allocation Line";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
    begin
        VATAllocationLine.Get(UnrealizedVATEntryNo, 20000);
        DimMgt.GetDimensionSet(TempDimSetEntry, VATAllocationLine."Dimension Set ID");

        TempDimSetEntry."Dimension Code" := DimValue."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimValue.Code;
        TempDimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";
        if TempDimSetEntry.Insert() then;
        VATAllocationLine."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        VATAllocationLine.Modify();

        exit(VATAllocationLine."Dimension Set ID");
    end;

    local procedure DeleteVATAllocationLine(UnrealVATEntryNo: Integer)
    var
        VATAllocationLine: Record "VAT Allocation Line";
    begin
        if UnrealVATEntryNo <> 0 then
            VATAllocationLine.SetRange("VAT Entry No.", UnrealVATEntryNo);
        VATAllocationLine.DeleteAll();
    end;

    local procedure CreateDimensionValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure GenerateDimSetID(): Integer
    var
        DimensionValue: Record "Dimension Value";
        DimSetEntry: Record "Dimension Set Entry" temporary;
        DimensionMgt: Codeunit DimensionManagement;
    begin
        CreateDimensionValue(DimensionValue);
        DimSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        DimSetEntry."Dimension Value Code" := DimensionValue.Code;
        DimSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        DimSetEntry.Insert();
        exit(DimensionMgt.GetDimensionSetID(DimSetEntry));
    end;

    local procedure CombineDimSetIDs(DimSetID1: Integer; DimSetID2: Integer): Integer
    var
        DimensionMgt: Codeunit DimensionManagement;
        GlobalDimVal1: Code[20];
        GlobalDimVal2: Code[20];
        DimensionSetIDArr: array[10] of Integer;
    begin
        DimensionSetIDArr[1] := DimSetID1;
        DimensionSetIDArr[2] := DimSetID2;
        exit(DimensionMgt.GetCombinedDimensionSetID(DimensionSetIDArr, GlobalDimVal1, GlobalDimVal2));
    end;

    local procedure FindGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; DocNo: Code[20])
    begin
        GenJnlLine.SetRange("Journal Template Name", VATPostingSetup."VAT Settlement Template");
        GenJnlLine.SetRange("Journal Batch Name", VATPostingSetup."VAT Settlement Batch");
        GenJnlLine.SetRange("Document No.", DocNo);
        GenJnlLine.FindFirst();
        GenJnlLine.TestField("Unrealized VAT Entry No.");
    end;

    local procedure FindVATEntry(VATPostingSetup: Record "VAT Posting Setup"; DocumentNo: Code[20]; UnrealizedVATEntryNo: Integer): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATEntry.SetRange("Unrealized VAT Entry No.", UnrealizedVATEntryNo);
        VATEntry.FindFirst();
        exit(VATEntry."Entry No.");
    end;

    local procedure CreateAndPostFAReleaseDoc(FANo: Code[20]; PostingDate: Date)
    var
        FADocumentHeader: Record "FA Document Header";
    begin
        LibraryFixedAsset.CreateFAReleaseDoc(FADocumentHeader, FANo, PostingDate);
        LibraryFixedAsset.PostFADocument(FADocumentHeader);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure VerifyMultilinePurchInvWithItemFA_VATEntry(DocNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey("Document No.");
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.FindFirst();

        VerifyUnrealVATBaseAndAmount(VATEntry, 10000, 1800, 1);
        VerifyUnrealVATBaseAndAmount(VATEntry, 2340, 421.2, 1);
        VerifyVATBaseAndAmount(VATEntry, 1638, 294.84);
        VerifyVATBaseAndAmount(VATEntry, 702, 126.36);
        VerifyVATBaseAndAmount(VATEntry, 6000, 1080);
        VerifyVATBaseAndAmount(VATEntry, 4000, 720);
    end;

    local procedure VerifyMultilinePurchInvWithItemGLAccFA_VATEntry() DocNo: Code[20]
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.FindLast();
        DocNo := VATEntry."Document No.";
        VerifyUnrealVATBaseAndAmount(VATEntry, 1000, 180, -1);
        VerifyUnrealVATBaseAndAmount(VATEntry, 2000, 360, -1);
        VerifyUnrealVATBaseAndAmount(VATEntry, 10200, 1836, -1);
        VerifyUnrealVATBaseAndAmount(VATEntry, 55000, 9900, -1);
        exit(DocNo);
    end;

    local procedure VerifyMultilinePurchInvWithItemGLAccFA_VATEntry_2() DocNo: Code[20]
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.FindLast();
        DocNo := VATEntry."Document No.";
        // VerifyUnrealVATBaseAndAmount(VATEntry,3960,712.8,-1);
        // VerifyUnrealVATBaseAndAmount(VATEntry,1100,198,-1);
        VerifyUnrealVATBaseAndAmount(VATEntry, 5060, 910.8, -1);
        exit(DocNo);
    end;

    local procedure VerifyMultipleValueEntry(ExpectedAmt: Decimal; ExpectedAmt2: Decimal; ExpectedAmt3: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Find('+');
        Assert.AreEqual(
          ExpectedAmt, ValueEntry."Cost Posted to G/L", StrSubstNo(WrongValueErr, ValueEntry."Cost Posted to G/L", ValueEntry.TableName, ValueEntry."Entry No."));
        ValueEntry.Next(-1);
        Assert.AreEqual(
          ExpectedAmt2, ValueEntry."Cost Posted to G/L", StrSubstNo(WrongValueErr, ValueEntry."Cost Posted to G/L", ValueEntry.TableName, ValueEntry."Entry No."));
        ValueEntry.Next(-1);
        Assert.AreEqual(
          ExpectedAmt3, ValueEntry."Cost Posted to G/L", StrSubstNo(WrongValueErr, ValueEntry."Cost Posted to G/L", ValueEntry.TableName, ValueEntry."Entry No."));
    end;

    local procedure VerifyUnrealVATBaseAndAmount(var VATEntry: Record "VAT Entry"; ExpectedVATBase: Decimal; ExpectedVATAmount: Decimal; Step: Integer)
    begin
        Assert.AreEqual(
          ExpectedVATBase, VATEntry."Unrealized Base", StrSubstNo(WrongValueErr, VATEntry."Unrealized Base", VATEntry.TableName, VATEntry."Entry No."));
        Assert.AreEqual(
          ExpectedVATAmount, VATEntry."Unrealized Amount", StrSubstNo(WrongValueErr, VATEntry."Unrealized Amount", VATEntry.TableName, VATEntry."Entry No."));
        VATEntry.Next(Step);
    end;

    local procedure VerifyVATBaseAndAmount(var VATEntry: Record "VAT Entry"; ExpectedVATBase: Decimal; ExpectedVATAmount: Decimal)
    begin
        Assert.AreEqual(
          ExpectedVATBase, VATEntry.Base, StrSubstNo(WrongValueErr, VATEntry.Base, VATEntry.TableName, VATEntry."Entry No."));
        Assert.AreEqual(
          ExpectedVATAmount, VATEntry.Amount, StrSubstNo(WrongValueErr, VATEntry.Amount, VATEntry.TableName, VATEntry."Entry No."));
        VATEntry.Next();
    end;

    local procedure VerifyGLEntriesDimension(AccountNo: Code[20]; DimSetID: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", AccountNo);
        if GLEntry.FindLast() then
            Assert.AreEqual(DimSetID, GLEntry."Dimension Set ID", WrongDimSetIDErr);

        GLEntry.Reset();
        GLEntry.SetRange("Bal. Account No.", AccountNo);
        if GLEntry.FindLast() then
            Assert.AreEqual(DimSetID, GLEntry."Dimension Set ID", WrongDimSetIDErr);
    end;

    local procedure VerifyDimSetIDInVATAllocLines(AccNo: Code[20]; DimSetID: Integer)
    var
        VATAllocLine: Record "VAT Allocation Line";
    begin
        VATAllocLine.SetRange(Type, VATAllocLine.Type::VAT);
        VATAllocLine.SetRange("Account No.", AccNo);
        VATAllocLine.FindSet();
        repeat
            Assert.AreEqual(DimSetID, VATAllocLine."Dimension Set ID", WrongDimSetIDErr);
        until VATAllocLine.Next() = 0;
    end;

    local procedure VerifyVATAllocLineDimSetIDByVATEntryNo(VATEntryNo: Integer; ExpectedDimSetID: Integer)
    var
        VATAllocationLine: Record "VAT Allocation Line";
    begin
        VATAllocationLine.SetRange("VAT Entry No.", VATEntryNo);
        VATAllocationLine.FindFirst();
        Assert.AreEqual(ExpectedDimSetID, VATAllocationLine."Dimension Set ID", VATAllocationLine.FieldCaption("Dimension Set ID"));
    end;

    local procedure VerifyGenJnlLineDimSetIDByUnrealVATEntryNo(VATPostingSetup: Record "VAT Posting Setup"; DocumentNo: Code[20]; VATEntryNo: Integer; ExpectedDimSetID: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", VATPostingSetup."VAT Settlement Template");
        GenJournalLine.SetRange("Journal Batch Name", VATPostingSetup."VAT Settlement Batch");
        GenJournalLine.SetRange("Document No.", DocumentNo);
        GenJournalLine.SetRange("Unrealized VAT Entry No.", VATEntryNo);
        GenJournalLine.FindFirst();
        Assert.AreEqual(ExpectedDimSetID, GenJournalLine."Dimension Set ID", GenJournalLine.FieldCaption("Dimension Set ID"));
    end;

    local procedure VerifyGLEntryDimSetIDByVATEntryNo(VATEntryNo: Integer; ExpectedDimSetID: Integer)
    var
        GLEntry: Record "G/L Entry";
        GLRegister: Record "G/L Register";
    begin
        GLRegister.SetRange("From VAT Entry No.", VATEntryNo);
        GLRegister.SetRange("To VAT Entry No.", VATEntryNo);
        GLRegister.FindFirst();

        GLEntry.Get(GLRegister."From Entry No.");
        Assert.AreEqual(ExpectedDimSetID, GLEntry."Dimension Set ID", GLEntry.FieldCaption("Dimension Set ID"));
    end;
}

