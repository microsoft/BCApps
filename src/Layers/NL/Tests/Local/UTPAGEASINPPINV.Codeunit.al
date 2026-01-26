codeunit 144034 "UT PAG EASINPPINV"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        MustBeEnabledMsg: Label 'Must be enabled';
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EnableControlsPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Invoice] [Document Amount] [UI]
        // [SCENARIO] Total DocAmount fields are enabled on Invoice page if "Check Doc. Total Amounts" is on.
        Initialize();
        // [GIVEN] "Check Doc. Total Amounts" is 'Yes'
        EnableDocTotalAmounts();
        // [GIVEN] Create Purchase Invoice.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Open Invoice page
        OpenPurchaseInvoice(PurchaseInvoicePage, PurchaseHeader."No.");

        // [THEN] Verify DocAmountVAT and DocAmount are enabled on Purchase Invoice.
        Assert.IsTrue(PurchaseInvoicePage.DocAmountVAT.Enabled(), MustBeEnabledMsg);
        Assert.IsTrue(PurchaseInvoicePage.DocAmount.Enabled(), MustBeEnabledMsg);
        PurchaseInvoicePage.Close();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Invoice] [Statistics] [UI]
        // [SCENARIO] validate Statisitc - OnAction trigger of Page ID - 51 Purchase Invoice.
        Initialize();
        // [GIVEN] Create Purchase Invoice. Transaction Model is Autocommit, because it is explicitly called on Statisitc - OnAction trigger of Page Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice);
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);  // Required inside PurchaseStatisticsPageHandler.
        OpenPurchaseInvoice(PurchaseInvoice, PurchaseHeader."No.");

        // [WHEN] Invokes Action - Statistics on Purchase Invoice page and verification of Quantity is done inside PurchaseStatisticsPageHandler.
        PurchaseInvoice.Statistics.Invoke();  // Opens PurchaseStatisticsPageHandler.
        PurchaseInvoice.Close();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsHandler')]
    [Scope('OnPrem')]
    procedure OnActionPurchaseStatisticsPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Invoice] [Statistics] [UI]
        // [SCENARIO] validate Statisitc - OnAction trigger of Page ID - 51 Purchase Invoice.
        Initialize();
        // [GIVEN] Create Purchase Invoice. Transaction Model is Autocommit, because it is explicitly called on Statisitc - OnAction trigger of Page Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice);
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);  // Required inside PurchaseStatisticsHandler.
        OpenPurchaseInvoice(PurchaseInvoice, PurchaseHeader."No.");

        // [WHEN] Invokes Action - Statistics on Purchase Invoice page and verification of Quantity is done inside PurchaseStatisticsHandler.
        PurchaseInvoice.PurchaseStatistics.Invoke();  // Opens PurchaseStatisticsHandler.
        PurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('MoveNegativePurchaseLinesRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure OnActionMoveNegativeLinesPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Invoice] [Move Negative Lines] [UI]
        // [SCENARIO] validate Move Negative Purchase Lines - OnAction trigger of Page ID - 51 Purchase Invoice.
        Initialize();
        // [GIVEN] Create Purchase Invoice.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice);
        PurchaseLine.Quantity := -LibraryRandom.RandDec(10, 2);  // Negative Quantity required.
        PurchaseLine.Modify();
        Commit(); // Commit required, because it is explicitly called by Show Document function of Report ID - 6698 Move Negative Purchase Lines.
        OpenPurchaseInvoice(PurchaseInvoice, PurchaseHeader."No.");

        // [WHEN] Run action "Move Negative Purchase Lines"
        PurchaseInvoice.MoveNegativeLines.Invoke();  // Opens - MoveNegativePurchaseLinesRequestPageHandler

        // [THEN] Verify Purchase Credit Memo with positive line is created.
        PurchaseLine2.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine2.SetRange("No.", PurchaseLine."No.");
        PurchaseLine2.FindFirst();
        PurchaseLine2.TestField(Quantity, -PurchaseLine.Quantity);
        PurchaseInvoice.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EnableControlsPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemoPage: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Credit Memo] [Document Amount] [UI]
        // [SCENARIO] Total DocAmount fields are enabled on Credit memo page if "Check Doc. Total Amounts" is on.
        Initialize();
        // [GIVEN] "Check Doc. Total Amounts" is 'Yes'
        EnableDocTotalAmounts();
        // [GIVEN] Create Purchase Credit Memo.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        // [WHEN] Open Credit Memo page
        OpenPurchaseCreditMemo(PurchaseCreditMemoPage, PurchaseHeader."No.");

        // [THEN] Verify DocAmountVAT and DocAmount are enabled on Purchase Credit Memo.
        Assert.IsTrue(PurchaseCreditMemoPage.DocAmountVAT.Enabled(), MustBeEnabledMsg);
        Assert.IsTrue(PurchaseCreditMemoPage.DocAmount.Enabled(), MustBeEnabledMsg);
        PurchaseCreditMemoPage.Close();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT PAG EASINPPINV");
        LibraryVariableStorage.Clear();
        LibraryPurchase.DisableWarningOnCloseUnpostedDoc();
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    begin
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Pay-to Vendor No." := CreateVendor();
        PurchaseHeader.Insert();
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType);
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := CreateItem();
        PurchaseLine.Quantity := LibraryRandom.RandDec(10, 2);
        PurchaseLine.Amount := LibraryRandom.RandDec(10, 2);
        PurchaseLine."Line Amount" := PurchaseLine.Quantity * PurchaseLine.Amount;
        PurchaseLine.Insert();
    end;

    local procedure CreateVendor(): Code[20]
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        Vendor: Record Vendor;
    begin
        VendorPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        VendorPostingGroup."Invoice Rounding Account" := LibraryUTUtility.GetNewCode();
        VendorPostingGroup.Insert();
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor."Vendor Posting Group" := VendorPostingGroup.Code;
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item.Insert();
        exit(Item."No.");
    end;

    local procedure EnableDocTotalAmounts()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Check Doc. Total Amounts" := true;
        PurchasesPayablesSetup.Modify();
    end;

    local procedure OpenPurchaseInvoice(var PurchaseInvoice: TestPage "Purchase Invoice"; No: Code[20])
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenPurchaseCreditMemo(var PurchaseCreditMemo: TestPage "Purchase Credit Memo"; No: Code[20])
    begin
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.FILTER.SetFilter("No.", No);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        Quantity: Variant;
    begin
        LibraryVariableStorage.Dequeue(Quantity);
        PurchaseStatistics.Quantity.AssertEquals(Quantity);
    end;
#endif    

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        Quantity: Variant;
    begin
        LibraryVariableStorage.Dequeue(Quantity);
        PurchaseStatistics.Quantity.AssertEquals(Quantity);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MoveNegativePurchaseLinesRequestPageHandler(var MoveNegativePurchaseLines: TestRequestPage "Move Negative Purchase Lines")
    begin
        MoveNegativePurchaseLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

