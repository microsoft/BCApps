codeunit 142061 "ERM Batch Reports DACH"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryVATEntryLinkForFASalesAccOnDispLoss()
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        FANo: Code[20];
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Fixed Asset] [VAT] [Sales] [G/L Entry - VAT Entry Link]
        // [SCENARIO 202344] VATEntry."G/L Account No." = FAPostingGroup."Sales Acc. on Disp. (Loss)" when post fixed asset sales invoice with "Depr. until FA Posting Date" = TRUE
        Initialize();

        // [GIVEN] Fixed Asset "FA" with "Sales Acc. on Disp. (Loss)" = "DispLossGLAcc", "Disposal Calculation Method" = "Gross", "VAT on Net Disposal Entries" = TRUE
        FANo := CreateFAWithBook();

        // [GIVEN] Posted purchase invoice fixed asset "FA" on "Posting Date" = 01-01-2019
        CreatePostFixedAssetPurchaseInvoice(WorkDate(), FANo, LibraryRandom.RandDecInRange(10000, 20000, 2));

        // [WHEN] Post sales invoice "SI" fixed asset "FA" on "Posting Date" = 01-02-2019 with "Depr. until FA Posting Date" = TRUE
        DocumentNo := CreatePostFixedAssetSalesInvoice(CalcDate('<1M>', WorkDate()), FANo, LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [THEN] There is a GLEntry "X" with "Document Type" = "Invoice", "Document No." = "SI", "Gen. Posting Type" = "Sale", "G/L Account No." = "DispLossGLAcc"
        GLAccountNo := GetFASalesAccOnDispLoss(FANo);
        FindGLEntry(GLEntry, GLEntry."Document Type"::Invoice, DocumentNo, GLEntry."Gen. Posting Type"::Sale, GLAccountNo);

        // [THEN] There is a VATEntry "Y" with "Document Type" = "Invoice", "Document No." = "SI", Type = "Sale", "G/L Account No." = ""
        FindVATEntry(VATEntry, VATEntry."Document Type"::Invoice, DocumentNo, VATEntry.Type::Sale, ''); // "G/L Acc. No." is not filled - default behavior.

        // [THEN] There is a "G/L Entry - VAT Entry Link" record with "G/L Entry No." = "X", "VAT Entry No." = "Y"
        GLEntryVATEntryLink.GET(GLEntry."Entry No.", VATEntry."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryVATEntryLinkForFASalesAccOnDispLossWithEventSubscriber()
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        ERMBatchReportsDACHSubscriber: Codeunit "ERM Batch Reports DACH";
        FANo: Code[20];
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [G/L Entry - VAT Entry Link]
        // [SCENARIO 423793] Extension can fill G/L Account No. on VAT entry inserted during posting utilizing event subscription
        Initialize();

        // [GIVEN] Fixed Asset "FA" with "Sales Acc. on Disp. (Loss)" = "DispLossGLAcc", "Disposal Calculation Method" = "Gross", "VAT on Net Disposal Entries" = TRUE
        FANo := CreateFAWithBook();

        // [GIVEN] Posted purchase invoice fixed asset "FA" on "Posting Date" = 01-01-2019
        BindSubscription(ERMBatchReportsDACHSubscriber);
        CreatePostFixedAssetPurchaseInvoice(WorkDate(), FANo, LibraryRandom.RandDecInRange(10000, 20000, 2));

        // [WHEN] Post sales invoice "SI" fixed asset "FA" on "Posting Date" = 01-02-2019 with "Depr. until FA Posting Date" = TRUE
        DocumentNo := CreatePostFixedAssetSalesInvoice(CalcDate('<1M>', WorkDate()), FANo, LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [THEN] There is a GLEntry "X" with "Document Type" = "Invoice", "Document No." = "SI", "Gen. Posting Type" = "Sale", "G/L Account No." = "DispLossGLAcc"
        GLAccountNo := GetFASalesAccOnDispLoss(FANo);
        FindGLEntry(GLEntry, GLEntry."Document Type"::Invoice, DocumentNo, GLEntry."Gen. Posting Type"::Sale, GLAccountNo);

        // [THEN] There is a VATEntry "Y" with "Document Type" = "Invoice", "Document No." = "SI", Type = "Sale", "G/L Acc. No." = "DispLossGLAcc"
        FindVATEntry(VATEntry, VATEntry."Document Type"::Invoice, DocumentNo, VATEntry.Type::Sale, GLAccountNo); // "G/L Acc. No." has been filled by a subscriber

        // [THEN] There is a "G/L Entry - VAT Entry Link" record with "G/L Entry No." = "X", "VAT Entry No." = "Y"
        GLEntryVATEntryLink.GET(GLEntry."Entry No.", VATEntry."Entry No.");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Batch Reports DACH");

        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Batch Reports DACH");
        IsInitialized := true;
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Batch Reports DACH");
    end;

    local procedure CreateFAWithBook(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("Disposal Calculation Method", DepreciationBook."Disposal Calculation Method"::Gross);
        DepreciationBook.Validate("VAT on Net Disposal Entries", true);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("G/L Integration - Depreciation", true);
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Modify(true);

        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());
        FADepreciationBook.Validate("No. of Depreciation Years", LibraryRandom.RandInt(5));
        FADepreciationBook.Modify(true);
        exit(FixedAsset."No.");
    end;

    local procedure CreatePostFixedAssetPurchaseInvoice(PostingDate: Date; FANo: Code[20]; DirectCost: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FANo, 1);
        PurchaseLine.Validate("Depreciation Book Code", GetFADeprBookCode(FANo));
        PurchaseLine.Validate("Direct Unit Cost", DirectCost);
        PurchaseLine.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePostFixedAssetSalesInvoice(PostingDate: Date; FANo: Code[20]; UnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset", FANo, 1);
        SalesLine.Validate("Depreciation Book Code", GetFADeprBookCode(FANo));
        SalesLine.Validate("Depr. until FA Posting Date", true);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure GetFASalesAccOnDispLoss(FANo: Code[20]): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
    begin
        FixedAsset.Get(FANo);
        FAPostingGroup.Get(FixedAsset."FA Posting Group");
        exit(FAPostingGroup."Sales Acc. on Disp. (Loss)");
    end;

    local procedure GetFADeprBookCode(FANo: Code[20]): Code[10]
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        FADepreciationBook.SetRange("FA No.", FANo);
        FADepreciationBook.FindFirst();
        exit(FADepreciationBook."Depreciation Book Code");
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GenPostingType: Enum "General Posting Type"; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Gen. Posting Type", GenPostingType);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; VATEntryType: Enum "General Posting Type"; GLAccountNo: Code[20])
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange(Type, VATEntryType);
        VATEntry.SetRange("G/L Acc. No.", GLAccountNo);
        VATEntry.FindFirst();
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Entry - VAT Entry Link", 'OnInsertLink', '', false, false)]
    local procedure HandleOnSetGLAccountNoInVATEntriesOnGLEntryVATEntryLinkInsert(var GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link")
    begin
        GLEntryVATEntryLink.AdjustGLAccountNoOnVATEntry();
    end;
}

