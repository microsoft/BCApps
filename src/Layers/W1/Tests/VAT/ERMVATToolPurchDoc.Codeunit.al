codeunit 134052 "ERM VAT Tool - Purch. Doc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Rate Change] [Purchase]
        isInitialized := false;
    end;

    var
        VATRateChangeSetup2: Record "VAT Rate Change Setup";
        PurchaseHeader2: Record "Purchase Header";
        Assert: Codeunit Assert;
        ERMVATToolHelper: Codeunit "ERM VAT Tool - Helper";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        isInitialized: Boolean;
        GroupFilter: Label '%1|%2', Locked = true;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM VAT Tool - Purch. Doc");
        ERMVATToolHelper.ResetToolSetup();  // This resets the setup table for all test cases.
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM VAT Tool - Purch. Doc");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ERMVATToolHelper.SetupItemNos();
        ERMVATToolHelper.ResetToolSetup();  // This resets setup table for the first test case after database is restored.
        LibrarySetupStorage.SavePurchasesSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM VAT Tool - Purch. Doc");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchaseDocConvFalse()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Run VAT Rate Change with Perform Conversion = FALSE, expect no updates.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create data with groups to update.
        ERMVATToolHelper.CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', 1);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::Both, false, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: No data was updated
        ERMVATToolHelper.VerifyUpdateConvFalse(DATABASE::"Purchase Line");

        // Verify: Log entries
        ERMVATToolHelper.VerifyLogEntriesConvFalse(DATABASE::"Purchase Line", false);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchaseDocPShConvFalse()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Run VAT Rate Change with Perform Conversion = FALSE, expect no updates.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create data with groups to update.
        ERMVATToolHelper.CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', 1);
        ERMVATToolHelper.UpdateQtyToReceive(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::Both, false, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify that no data was updated
        ERMVATToolHelper.VerifyUpdateConvFalse(DATABASE::"Purchase Line");

        // Verify log entries
        ERMVATToolHelper.VerifyLogEntriesConvFalse(DATABASE::"Purchase Line", true);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchBlanketOrderVAT()
    begin
        // Purchase Blanket Order with one line, update VAT group only.
        VATToolPurchaseLine(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", false,
          PurchaseHeader2."Document Type"::"Blanket Order", false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchBlanketOrderGen()
    begin
        // Purchase Blanket Order with one line, update Gen. group only.
        VATToolPurchaseLine(VATRateChangeSetup2."Update Purchase Documents"::"Gen. Prod. Posting Group", false,
          PurchaseHeader2."Document Type"::"Blanket Order", false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchBlanketOrderBoth()
    begin
        // Purchase Blanket Order with one line, update both groups.
        VATToolPurchaseLine(VATRateChangeSetup2."Update Purchase Documents"::Both, false,
          PurchaseHeader2."Document Type"::"Blanket Order", false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchBlanketOrderNo()
    begin
        // Purchase Blanket Order with one line, don't update groups.
        asserterror VATToolPurchaseLine(
            VATRateChangeSetup2."Update Purchase Documents"::No, false, PurchaseHeader2."Document Type"::"Blanket Order", false, false,
            false);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchBlanketOrdMakeFull()
    begin
        // Purchase Blanket Order with one line, Make Purchase Order, update VAT group only.
        VATToolMakePurchOrder(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group",
          PurchaseHeader2."Document Type"::"Blanket Order", false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchBlanketOrdMakePart()
    begin
        // Purchase Blanket Order with one line, Make Purchase Order, update VAT group only.
        VATToolMakePurchOrder(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group",
          PurchaseHeader2."Document Type"::"Blanket Order", true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchBlOrdMakePartMake()
    begin
        // Purchase Blanket Order with one line, Make Purchase Order, update VAT group only, Make Order.
        VATToolMakePurchaseOrderMake(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group",
          PurchaseHeader2."Document Type"::"Blanket Order", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchBlOrdMakeOrderFRec()
    begin
        // Purchase Blanket Order with one line, Make Purchase Order, Fully Ship Purchase Order, update VAT group only. No update.
        VATToolMakePurchOrderRcv(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchBlOrdMakeOrderPRec()
    begin
        // Purchase Blanket Order with one line, Make Purchase Order, Partially Ship Purchase Order, update VAT group only.
        VATToolMakePurchOrderRcv(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchBlOrdMakeFRecPost()
    begin
        // Purchase Blanket Order with one line, Make Purchase Order, Fully Ship Purchase Order, Post, Update VAT group only.
        VATToolMakePurchOrderRcvPost(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchBlOrdMakePRecPost()
    begin
        // Purchase Blanket Order with one line, Make Purchase Order, Partially Ship Purchase Order, Post, Update VAT group only.
        VATToolMakePurchOrderRcvPost(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchaseBlOrdMakePShpMk()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderHeader: Record "Purchase Header";
    begin
        // Purchase Blanket Order with one line, Partial Make Purchase Order, Partially Ship Purchase Order, Make.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create Blanket Order.
        ERMVATToolHelper.CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '', GetLineCount(false));

        // SETUP: Make Order (Partial).
        ERMVATToolHelper.UpdateQtyToReceive(PurchaseHeader);
        ERMVATToolHelper.MakeOrderPurchase(PurchaseHeader, PurchaseOrderHeader);

        // SETUP: Post Partial Shipment.
        ERMVATToolHelper.UpdateQtyToReceive(PurchaseOrderHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseOrderHeader, true, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Make Purchase Order Is Completed Successfully.
        UpdateQtyBlanketOrder(PurchaseHeader);
        ERMVATToolHelper.MakeOrderPurchase(PurchaseHeader, PurchaseOrderHeader);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchQuoteVAT()
    begin
        // Purchase Blanket Order with one line, update VAT group only.
        VATToolPurchaseLine(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", false,
          PurchaseHeader2."Document Type"::Quote, false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchQuoteGen()
    begin
        // Purchase Blanket Order with one line, update Gen. group only.
        VATToolPurchaseLine(VATRateChangeSetup2."Update Purchase Documents"::"Gen. Prod. Posting Group", false,
          PurchaseHeader2."Document Type"::Quote, false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchQuoteBoth()
    begin
        // Purchase Blanket Order with one line, update both groups.
        VATToolPurchaseLine(VATRateChangeSetup2."Update Purchase Documents"::Both, false,
          PurchaseHeader2."Document Type"::Quote, false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchQuoteNo()
    begin
        // Purchase Blanket Order with one line, don't update groups.
        asserterror VATToolPurchaseLine(
            VATRateChangeSetup2."Update Purchase Documents"::No, false, PurchaseHeader2."Document Type"::Quote, false, false, false);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchQuoteMakeOrd()
    begin
        // Purchase Blanket Order with one line, Make Purchase Order, update VAT group only.
        VATToolMakePurchOrder(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group",
          PurchaseHeader2."Document Type"::Quote, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchaseInvoiceVAT()
    begin
        // Purchase Invoice with Multiple Lines, update VAT group only.
        VATToolPurchaseLine(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", false,
          PurchaseHeader2."Document Type"::Invoice, false, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchaseInvoiceVATAmt()
    begin
        // Purchase Invoice with Multiple Lines, Update VAT Group, Verify Amount.
        VATToolPurchaseLineAmount(PurchaseHeader2."Document Type"::Invoice, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderVAT()
    begin
        // Purchase Order with one line, update VAT group only.
        VATToolPurchaseLine(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", false,
          PurchaseHeader2."Document Type"::Order, false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchaseOrderVATAmt()
    begin
        // Purchase Order with Multiple Lines, Update VAT Group, Verify Amount.
        VATToolPurchaseLineAmount(PurchaseHeader2."Document Type"::Order, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderGen()
    begin
        // Purchase Order with one line, update Gen. group only.
        VATToolPurchaseLine(VATRateChangeSetup2."Update Purchase Documents"::"Gen. Prod. Posting Group", false,
          PurchaseHeader2."Document Type"::Order, false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATTooPurchOrderBoth()
    begin
        // Purchase Order with one line, update both groups.
        VATToolPurchaseLine(VATRateChangeSetup2."Update Purchase Documents"::Both, false,
          PurchaseHeader2."Document Type"::Order, false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderNo()
    begin
        // Purchase Order with one line, don't update groups.
        asserterror VATToolPurchaseLine(
            VATRateChangeSetup2."Update Purchase Documents"::No, false, PurchaseHeader2."Document Type"::Order, false, false, false);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderMultipleLines()
    begin
        // Purchase Order with multiple lines, update both groups.
        VATToolPurchaseLine(VATRateChangeSetup2."Update Purchase Documents"::Both, false,
          PurchaseHeader2."Document Type"::Order, false, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderMultipleLinesUpdateFirst()
    begin
        VATToolPurchOrderMultipleLinesUpdateSplit(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderMultipleLinesUpdateSecond()
    begin
        VATToolPurchOrderMultipleLinesUpdateSplit(false);
    end;

    local procedure VATToolPurchOrderMultipleLinesUpdateSplit(First: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenProdPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
        LineCount: Integer;
    begin
        // Purchase Order with multiple lines, update one line only.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Update VAT Change Tool Setup table and get new VAT group Code
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", true, true);
        ERMVATToolHelper.GetGroupsAfter(VATProdPostingGroup, GenProdPostingGroup, DATABASE::"Purchase Line");

        // SETUP: Create a Purchase Order with 2 lines and Save data to update in a temporary table.
        ERMVATToolHelper.CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', 2);

        // SETUP: Change VAT Prod. Posting Group to new on one of the lines.
        GetPurchaseLine(PurchaseHeader, PurchaseLine);
        LineCount := PurchaseLine.Count();
        if First then
            PurchaseLine.Next()
        else
            PurchaseLine.FindFirst();
        PurchaseLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        PurchaseLine.Modify(true);

        // SETUP: Ship (Partially).
        ERMVATToolHelper.UpdateQtyToReceive(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        GetPurchaseLine(PurchaseHeader, PurchaseLine);
        Assert.AreEqual(LineCount + 1, PurchaseLine.Count, ERMVATToolHelper.GetConversionErrorSplitLines());

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrdPartRecVAT()
    begin
        // Purchase Order with one partially received and released line, update VAT group and ignore header status.
        VATToolPurchaseLnPartRec(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group",
          PurchaseHeader2."Document Type"::Order, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchaseOrdPartShpVATAm()
    begin
        // Purchase Order with one partially shipped and released line, update VAT group and ignore header status. Verify Amount.
        VATToolPurchaseLineAmount(PurchaseHeader2."Document Type"::Order, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToollPurchOrdPartRecGen()
    begin
        // Purchase Order with one partially received and released line, update Gen group and ignore header status.
        VATToolPurchaseLnPartRec(VATRateChangeSetup2."Update Purchase Documents"::"Gen. Prod. Posting Group",
          PurchaseHeader2."Document Type"::Order, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToollPurchOrdPartRecBoth()
    begin
        // Purchase Order with one partially received and released line, update both groups and ignore header status.
        VATToolPurchaseLnPartRec(VATRateChangeSetup2."Update Purchase Documents"::Both,
          PurchaseHeader2."Document Type"::Order, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToollPurchOrdPartRecBothMultipleLines()
    begin
        // Purchase Order with multiple partially received and released lines, update both groups and ignore header status.
        VATToolPurchaseLnPartRec(
          VATRateChangeSetup2."Update Purchase Documents"::Both, PurchaseHeader2."Document Type"::Order, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToollPurchOrdPRAutoInsSetup()
    begin
        // Purchase Order with one partially received and released line, update both groups and ignore header status.
        VATToolPurchaseLnPartRec(VATRateChangeSetup2."Update Purchase Documents"::Both,
          PurchaseHeader2."Document Type"::Order, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToollPurchRetOrdPartRecBoth()
    begin
        // Purchase Return Order with one partially received and released line, update both groups and ignore header status.
        // No update expected.
        VATToolPurchaseLnPartRec(VATRateChangeSetup2."Update Purchase Documents"::Both,
          PurchaseHeader2."Document Type"::"Return Order", false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderFullyReceived()
    begin
        // Purchase Order with one fully received line, update both groups and ignore header status. No update expected.
        // Since the line is received, it is by default also released (it is important for ignore status option).
        VATToolPurchaseLine(VATRateChangeSetup2."Update Purchase Documents"::Both, true,
          PurchaseHeader2."Document Type"::Order, true, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrdReleasedIgn()
    begin
        // Purchase Order with one released line, update both groups and ignore header status.
        VATToolPurchaseLine(VATRateChangeSetup2."Update Purchase Documents"::Both, true,
          PurchaseHeader2."Document Type"::Order, true, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchrOrdReleasedNoIgn()
    begin
        // Purchase Order with one released line, update both groups and don't ignore header status. No update expected.
        VATToolPurchaseLine(VATRateChangeSetup2."Update Purchase Documents"::Both, false,
          PurchaseHeader2."Document Type"::Order, true, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchCreditMemo()
    begin
        // Purchase Credit Memo with one line, update both groups. Do not expect update.
        VATToolPurchaseLine(VATRateChangeSetup2."Update Purchase Documents"::Both, false,
          PurchaseHeader2."Document Type"::"Credit Memo", false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchInvoiceForReceipt()
    var
        TempRecRef: RecordRef;
    begin
        // Purchase Invoice with one line, related to a Receipt Line, update both groups. No update expected.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        PreparePurchInvoiceForReceipt(TempRecRef);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::Both, true, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, false);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyErrorLogEntries(TempRecRef, false);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderWhse()
    begin
        // Purchase Order with one line with warehouse integration, update both groups. Expect update.
        VATToolPurchaseLineWhse(VATRateChangeSetup2."Update Purchase Documents"::Both, 1, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderWhsePartRec()
    begin
        // Purchase Order with one partially shipped line with warehouse integration, update both groups. No update expected.
        VATToolPurchaseLineWhse(VATRateChangeSetup2."Update Purchase Documents"::Both, 1, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderReserve()
    begin
        // Purchase Order with one partially shipped line with reservation, update both groups. Update of reservation line expected.
        VATToolPurchLineReserve(VATRateChangeSetup2."Update Purchase Documents"::Both);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderItemTracking()
    begin
        // Purchase Order with one line with Item Tracking with Serial No., update both groups.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        PreparePurchDocItemTracking();

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::Both, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        VerifyPurchDocWithReservation(true);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderItemCharge()
    begin
        // Purchase Order with one line with Charge (Item), update both groups.
        VATToolPurchOrderItemChrgDiffDoc(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderItemChrgPRec()
    begin
        // Purchase Order with one line with Charge (Item), partially received, update both groups.
        // No update of Item Charge Assignment (Purchase) expected.
        VATToolPurchOrderItemChrgDiffDoc(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderItemChrgPInvoiced()
    begin
        // Purchase Order with one line with Charge (Item), partially received, update both groups.
        // No update of Item Charge Assignment (Purchase) expected.
        VATToolPurchOrderItemChrgDiffDoc(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderItemChargeSameDoc()
    begin
        // Sales Order with one line with Charge (Item), update both groups.
        VATToolPurchOrderItemChrgSameDoc(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderItemChrgPRecSameDoc()
    begin
        // Sales Order with one line with Charge (Item), partially shipped, update both groups. No update of Item Charge Assignment (Sales)
        // expected.
        VATToolPurchOrderItemChrgSameDoc(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderItemChrgPInvoicedSameDoc()
    begin
        // Sales Order with one line with Charge (Item), partially shipped, update both groups. No update of Item Charge Assignment (Sales)
        // expected.
        VATToolPurchOrderItemChrgSameDoc(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderDimensions()
    var
        PurchaseHeader: Record "Purchase Header";
        TempRecRef: RecordRef;
    begin
        // Purchase Order with one partially shipped line with Dimensions assigned, update both groups.
        // Verify that dimensions are copied to the new line.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        ERMVATToolHelper.CreatePurchaseDocumentWithRef(PurchaseHeader, TempRecRef, PurchaseHeader."Document Type"::Order, '', 1);

        // SETUP: Add Dimensions to the Purchase Lines and save them in a temporary table
        AddDimensionsForPurchLines(PurchaseHeader);

        // SETUP: Ship (Partially).
        ERMVATToolHelper.UpdateQtyToReceive(PurchaseHeader);
        ERMVATToolHelper.CreateLinesRefPurchase(TempRecRef, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::Both, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        VerifyPurchaseLnPartReceived(TempRecRef);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderPrepayment()
    var
        PurchaseHeader: Record "Purchase Header";
        TempRecRef: RecordRef;
    begin
        // Purchase Order with prepayment, update both groups. No update expected.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        ERMVATToolHelper.CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, ERMVATToolHelper.CreateVendor());
        PurchaseHeader.Validate("Prices Including VAT", true);
        ERMVATToolHelper.CreatePurchaseLines(PurchaseHeader, '', GetLineCount(false));
        TempRecRef.Open(DATABASE::"Purchase Line", true);
        ERMVATToolHelper.CreateLinesRefPurchase(TempRecRef, PurchaseHeader);

        // SETUP: Post prepayment.
        PostPurchasePrepayment(PurchaseHeader);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::Both, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, false);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyErrorLogEntries(TempRecRef, true);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderWithNegativeQty()
    begin
        VATToolPurchLineWithNegativeQty(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderWithNegativeQtyRec()
    begin
        VATToolPurchLineWithNegativeQty(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchOrderNoSpaceForNewLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineCount: Integer;
    begin
        // Sales Order with two lines, first partially received, no line number available between them. Update both groups.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        ERMVATToolHelper.CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', 1);
        AddLineWithNextLineNo(PurchaseHeader);
        GetPurchaseLine(PurchaseHeader, PurchaseLine);
        LineCount := PurchaseLine.Count();

        // SETUP: Receive
        ERMVATToolHelper.UpdateQtyToReceive(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::Both, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check that each line was splitted.
        GetPurchaseLine(PurchaseHeader, PurchaseLine);
        Assert.AreEqual(LineCount * 2, PurchaseLine.Count, ERMVATToolHelper.GetConversionErrorSplitLines());

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolPurchLineWithZeroOutstandingQty()
    var
        PurchaseHeader: Record "Purchase Header";
        VATRateChangeSetup: Record "VAT Rate Change Setup";
        VatProdPostingGroup: Code[20];
    begin
        // Check Description field value when out standing quantity is zero on purchase order.

        // Setup: Create posting groups to update and save them in VAT Change Tool Conversion table.
        Initialize();
        ERMVATToolHelper.UpdateVatRateChangeSetup(VATRateChangeSetup);
        SetupToolPurch(VATRateChangeSetup."Update Purchase Documents"::"VAT Prod. Posting Group", true, true);
        ERMVATToolHelper.CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '',
          LibraryRandom.RandInt(5));
        VatProdPostingGroup := GetVatProdPostingGroupFromPurchLine(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Verify Description field on vat rate change log entry.
        ERMVATToolHelper.VerifyValueOnZeroOutstandingQty(VatProdPostingGroup, DATABASE::"Purchase Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceUpdateForGLAccLineWhenPricesIncludingVATEnabled()
    var
        PurchaseLine: Record "Purchase Line";
        ExpectedUnitPrice: Decimal;
    begin
        // [FEATURE] [Prices Including VAT]
        // [SCENARIO 361066] A unit price of purchase line with "Prices Including VAT" and type "G/L Account" updates on "VAT Product Posting Group" change
        // [SCENARIO 361066] if "Update Unit Price For G/L Acc." is enabled in VAT Rate Change Setup

        Initialize();

        ERMVATToolHelper.CreatePostingGroups(false);
        ERMVATToolHelper.UpdateUnitPricesInclVATSetup(true, false, false);
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", true, true);
        CreatePurchInvoiceWithPricesIncludingVAT(PurchaseLine, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup());

        ERMVATToolHelper.RunVATRateChangeTool();

        ExpectedUnitPrice := CalcChangedUnitPriceGivenDiffVATPostingSetup(PurchaseLine);
        PurchaseLine.Find();
        PurchaseLine.TestField("Direct Unit Cost", ExpectedUnitPrice);

        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceDoesNotUpdateForGLAccLineWhenPricesIncludingVATEnabled()
    var
        PurchaseLine: Record "Purchase Line";
        ExpectedUnitPrice: Decimal;
    begin
        // [FEATURE] [Prices Including VAT]
        // [SCENARIO 361066] A unit price of purchase line with "Prices Including VAT" and type "G/L Account" does not update on "VAT Product Posting Group" change
        // [SCENARIO 361066] if "Update Unit Price For G/L Acc." is disabled in VAT Rate Change Setup

        Initialize();

        ERMVATToolHelper.CreatePostingGroups(false);
        ERMVATToolHelper.UpdateUnitPricesInclVATSetup(false, false, false);
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", true, true);
        CreatePurchInvoiceWithPricesIncludingVAT(PurchaseLine, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup());

        ERMVATToolHelper.RunVATRateChangeTool();

        ExpectedUnitPrice := PurchaseLine."Direct Unit Cost";
        PurchaseLine.Find();
        PurchaseLine.TestField("Direct Unit Cost", ExpectedUnitPrice);

        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceUpdateForItemChargeLineWhenPricesIncludingVATEnabled()
    var
        PurchaseLine: Record "Purchase Line";
        ExpectedUnitPrice: Decimal;
    begin
        // [FEATURE] [Prices Including VAT]
        // [SCENARIO 361066] A unit price of purchase line with "Prices Including VAT" and type "Charge (Item)" updates on "VAT Product Posting Group" change
        // [SCENARIO 361066] if "Update Unit Price For G/L Acc." is enabled in VAT Rate Change Setup

        Initialize();

        ERMVATToolHelper.CreatePostingGroups(false);
        ERMVATToolHelper.UpdateUnitPricesInclVATSetup(false, true, false);
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", true, true);
        CreatePurchInvoiceWithPricesIncludingVAT(PurchaseLine, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo());

        ERMVATToolHelper.RunVATRateChangeTool();

        ExpectedUnitPrice := CalcChangedUnitPriceGivenDiffVATPostingSetup(PurchaseLine);
        PurchaseLine.Find();
        PurchaseLine.TestField("Direct Unit Cost", ExpectedUnitPrice);

        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceDoesNotUpdateForItemChargeLineWhenPricesIncludingVATEnabled()
    var
        PurchaseLine: Record "Purchase Line";
        ExpectedUnitPrice: Decimal;
    begin
        // [FEATURE] [Prices Including VAT]
        // [SCENARIO 361066] A unit price of purchase line with "Prices Including VAT" and type "Charge (Item)" does not update on "VAT Product Posting Group" change
        // [SCENARIO 361066] if "Update Unit Price For G/L Acc." is disabled in VAT Rate Change Setup

        Initialize();

        ERMVATToolHelper.CreatePostingGroups(false);
        ERMVATToolHelper.UpdateUnitPricesInclVATSetup(false, false, false);
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", true, true);
        CreatePurchInvoiceWithPricesIncludingVAT(PurchaseLine, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo());

        ERMVATToolHelper.RunVATRateChangeTool();

        ExpectedUnitPrice := PurchaseLine."Direct Unit Cost";
        PurchaseLine.Find();
        PurchaseLine.TestField("Direct Unit Cost", ExpectedUnitPrice);

        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceUpdateForFixedAssetLineWhenPricesIncludingVATEnabled()
    var
        FixedAsset: Record "Fixed Asset";
        PurchaseLine: Record "Purchase Line";
        ExpectedUnitPrice: Decimal;
    begin
        // [FEATURE] [Prices Including VAT] [Fixed Asset]
        // [SCENARIO 361066] A unit price of purchase line with "Prices Including VAT" and type "Fixed Asset" updates on "VAT Product Posting Group" change
        // [SCENARIO 361066] if "Update Unit Price For G/L Acc." is enabled in VAT Rate Change Setup

        Initialize();

        ERMVATToolHelper.CreatePostingGroups(false);
        ERMVATToolHelper.UpdateUnitPricesInclVATSetup(false, false, true);
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", true, true);
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        CreatePurchInvoiceWithPricesIncludingVAT(PurchaseLine, PurchaseLine.Type::"Fixed Asset", FixedAsset."No.");

        ERMVATToolHelper.RunVATRateChangeTool();

        ExpectedUnitPrice := CalcChangedUnitPriceGivenDiffVATPostingSetup(PurchaseLine);
        PurchaseLine.Find();
        PurchaseLine.TestField("Direct Unit Cost", ExpectedUnitPrice);

        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceDoesNotUpdateForFixedAssetLineWhenPricesIncludingVATEnabled()
    var
        FixedAsset: Record "Fixed Asset";
        PurchaseLine: Record "Purchase Line";
        ExpectedUnitPrice: Decimal;
    begin
        // [FEATURE] [Prices Including VAT] [Fixed Asset]
        // [SCENARIO 361066] A unit price of purchase line with "Prices Including VAT" and type "Fixed Asset" does not update on "VAT Product Posting Group" change
        // [SCENARIO 361066] if "Update Unit Price For G/L Acc." is disabled in VAT Rate Change Setup

        Initialize();

        ERMVATToolHelper.CreatePostingGroups(false);
        ERMVATToolHelper.UpdateUnitPricesInclVATSetup(false, false, false);
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", true, true);
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        CreatePurchInvoiceWithPricesIncludingVAT(PurchaseLine, PurchaseLine.Type::"Fixed Asset", FixedAsset."No.");

        ERMVATToolHelper.RunVATRateChangeTool();

        ExpectedUnitPrice := PurchaseLine."Direct Unit Cost";
        PurchaseLine.Find();
        PurchaseLine.TestField("Direct Unit Cost", ExpectedUnitPrice);

        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConvertPartiallyReceivedOrderWithBlankQtyToReceive()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempRecRef: RecordRef;
    begin
        // [SCENARIO 362310] Stan can convert a VAT group of the Purchase Order that was partially received and "Default Qty. to Receive" is enabled in Purchase & Payables setup

        Initialize();
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate(
          "Default Qty. to Receive", PurchasesPayablesSetup."Default Qty. to Receive"::Blank);
        PurchasesPayablesSetup.Modify(true);

        ERMVATToolHelper.CreatePostingGroups(false);

        ERMVATToolHelper.CreatePurchaseDocumentWithRef(PurchaseHeader, TempRecRef, PurchaseHeader."Document Type"::Order, '', 1);
        ERMVATToolHelper.UpdateQtyToReceive(PurchaseHeader);
        ERMVATToolHelper.CreateLinesRefPurchase(TempRecRef, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ERMVATToolHelper.UpdateQtyToReceive(PurchaseHeader);
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", true, true);
        GetPurchaseLine(PurchaseHeader, PurchaseLine);

        ERMVATToolHelper.RunVATRateChangeTool();

        VerifyLineConverted(PurchaseHeader, PurchaseLine."Quantity Received", PurchaseLine.Quantity - PurchaseLine."Quantity Received");
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentVATFieldsUpdate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GenProdPostingGroupCode: Code[20];
        VATProductPostingGroupCode: Code[20];
    begin
        // [FEATURE] [Prepayment]
        // [SCENARIO 364192] Prepayment VAT fields are updated during the conversion

        Initialize();

        // [GIVEN] Setup two general posting setup "A" and "B". Each of this general posting setup has the Prepayment Account with the VAT Posting Setup, either "X" or "Z"
        ERMVATToolHelper.CreatePostingGroupsPrepmtVAT(false);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, ERMVATToolHelper.CreateVendor());
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(5, 10));
        PurchaseHeader.Modify(true);
        ERMVATToolHelper.CreatePurchaseLines(PurchaseHeader, '', 1);

        // [GIVEN] Setup conversion from "A" to "B" and from "X" to "Z"
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::Both, true, true);
        GetPurchaseLine(PurchaseHeader, PurchaseLine);

        // [WHEN] Run VAT Rate Change Tool
        ERMVATToolHelper.RunVATRateChangeTool();

        // [THEN] Prepayment VAT % and "Prepayment VAT Identifier" matches the "Z" VAT Posting Setup
        PurchaseLine.Find();
        ERMVATToolHelper.GetGroupsAfter(VATProductPostingGroupCode, GenProdPostingGroupCode, DATABASE::"Purchase Line");
        VATPostingSetup.Get(PurchaseHeader."VAT Bus. Posting Group", VATProductPostingGroupCode);
        PurchaseLine.TestField("Prepayment VAT %", VATPostingSetup."VAT %");
        PurchaseLine.TestField("Prepayment VAT Identifier", VATPostingSetup."VAT Identifier");

        // Tear down
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolAdjustExtTextsAttachedToLineNo()
    var
        VATProdPostingGroup: array[2] of Record "VAT Product Posting Group";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchOrderHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchOrderLine: Record "Purchase Line";
        VATRateChangeConv: Record "VAT Rate Change Conversion";
        BlanketPurchOrderPage: TestPage "Blanket Purchase Order";
        PurchDocumentType: Enum "Purchase Document Type";
        PurchLineType: Enum "Purchase Line Type";
        PurchOrderDocNo: Code[20];
        VendorNo: Code[20];
        SecondPurchLineNo: Integer;
    begin
        // [FEATURE] [Extended Text]
        // [SCENARIO 377264] VAT Rate Change tool adjusts Extended Text line "Attached to Line No." field
        Initialize();

        // [GIVEN] VAT Prod. Posting Group 'VPPG1' and 'VPPG2'
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup[1]);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup[2]);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup[1].Code);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup[2].Code);

        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusPostingGroup.Code);

        // [GIVEN] Item with VAT Prod. Posting Group = 'VPPG1' and enabled Automatic Ext. Texts with one line Ext. Text
        LibraryInventory.CreateItem(Item);
        Item.VALIDATE("VAT Prod. Posting Group", VATProdPostingGroup[1].Code);
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify(true);
        LibraryInventory.CreateExtendedTextForItem(Item."No.");

        // [GIVEN] Blanket Purchase Order with line of type Item, Qty = 10 and one Ext. Text line
        // VAT Prod. Posting Group of Purchase Line = 'VPPG1'
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchDocumentType::"Blanket Order", VendorNo);
        BlanketPurchOrderPage.OpenEdit();
        BlanketPurchOrderPage.Filter.SetFilter("No.", PurchHeader."No.");
        BlanketPurchOrderPage.PurchLines.Type.SetValue(PurchLineType::Item);
        BlanketPurchOrderPage.PurchLines."No.".SetValue(Item."No.");
        BlanketPurchOrderPage.PurchLines.Quantity.SetValue(10);
        BlanketPurchOrderPage.Close();
        Commit();

        // [GIVEN] Purchase Order made out of Purchase Blanket Order
        PurchOrderDocNo := LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchHeader);

        PurchOrderHeader.GET(PurchDocumentType::Order, PurchOrderDocNo);
        LibraryPurchase.FindFirstPurchLine(PurchOrderLine, PurchOrderHeader);

        // [GIVEN] Purchase Order posted with Quanitity = 8.
        PurchOrderLine.Validate(Quantity, 8);
        PurchOrderLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchOrderHeader, true, true);

        // [WHEN] Run VAT Change Tool with option to convert 'VPPG1' into 'VPPG2' for Purchase documents
        ERMVATToolHelper.SetupToolConvGroups(
            VATRateChangeConv.Type::"VAT Prod. Posting Group", VATProdPostingGroup[1].Code, VATProdPostingGroup[2].Code);
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", true, false);
        ERMVATToolHelper.RunVATRateChangeTool();

        // [THEN] Blanket Purchase Order has 3 lines. Extended text line is attached to Purchase Line with 'VPPG2' VAT Posting Group
        LibraryPurchase.FindFirstPurchLine(PurchLine, PurchHeader);

        PurchLine.TestField(Quantity, 8);
        PurchLine.TestField("VAT Prod. Posting Group", VATProdPostingGroup[1].Code);
        PurchLine.Next();
        PurchLine.TestField(Quantity, 2);
        PurchLine.TestField("VAT Prod. Posting Group", VATProdPostingGroup[2].Code);
        SecondPurchLineNo := PurchLine."Line No.";

        PurchLine.Next();
        PurchLine.TestField("Attached to Line No.", SecondPurchLineNo);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    procedure BlanketOrderAndOrderWithReceipt()
    var
        VATProdPostingGroup: array[2] of Record "VAT Product Posting Group";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
        PurchaseHeaderBlanketOrder: Record "Purchase Header";
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineBlanketOrder: Record "Purchase Line";
        PurchaseLineOrder: Record "Purchase Line";
        VATRateChangeConv: Record "VAT Rate Change Conversion";
        PurchaseOrderDocNo: Code[20];
        VendorNo: Code[20];
        BlanketOrderQuantity: Decimal;
    begin
        // [FEATURE] [Blanket Order] [Order] [Partial Receipt] [Receipt]
        // [SCENARIO 385191] Partially or fully received line in a Purchase Order created from a Blanket Order does not change reference to a source Blanket Order's line after running the VAT Rate Change Tool
        Initialize();

        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup[1]);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup[2]);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup[1].Code);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup[2].Code);

        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusPostingGroup.Code);

        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup[1].Code);
        Item.Modify(true);

        BlanketOrderQuantity := LibraryRandom.RandIntInRange(10, 20) * 3;

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeaderBlanketOrder, PurchaseHeaderBlanketOrder."Document Type"::"Blanket Order", VendorNo);
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLineBlanketOrder, PurchaseHeaderBlanketOrder,
            PurchaseLineBlanketOrder.Type::Item, Item."No.", BlanketOrderQuantity);
        PurchaseLineBlanketOrder.Validate("Qty. to Receive", Round(BlanketOrderQuantity / 3));
        PurchaseLineBlanketOrder.Modify(true);

        PurchaseOrderDocNo := LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeaderBlanketOrder);

        PurchaseHeaderOrder.Get(PurchaseHeaderOrder."Document Type"::Order, PurchaseOrderDocNo);
        LibraryPurchase.FindFirstPurchLine(PurchaseLineOrder, PurchaseHeaderOrder);
        PurchaseLineOrder.Validate("Qty. to Invoice", 0);
        PurchaseLineOrder.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        ERMVATToolHelper.SetupToolConvGroups(
            VATRateChangeConv.Type::"VAT Prod. Posting Group", VATProdPostingGroup[1].Code, VATProdPostingGroup[2].Code);
        SetupToolPurch(VATRateChangeSetup2."Update Sales Documents"::"VAT Prod. Posting Group", true, false);
        ERMVATToolHelper.RunVATRateChangeTool();

        PurchaseLineOrder.Reset();
        PurchaseLineOrder.SetRange("Document Type", PurchaseHeaderOrder."Document Type");
        PurchaseLineOrder.SetRange("Document No.", PurchaseHeaderOrder."No.");
        Assert.RecordCount(PurchaseLineOrder, 1);

        PurchaseLineOrder.FindFirst();
        PurchaseLineOrder.TestField("VAT Prod. Posting Group", VATProdPostingGroup[1].Code);
        PurchaseLineOrder.TestField("Blanket Order No.", PurchaseHeaderBlanketOrder."No.");
        PurchaseLineOrder.TestField("Blanket Order Line No.", PurchaseLineBlanketOrder."Line No.");

        PurchaseLineBlanketOrder.SetRange("Document Type", PurchaseHeaderBlanketOrder."Document Type");
        PurchaseLineBlanketOrder.SetRange("Document No.", PurchaseHeaderBlanketOrder."No.");
        Assert.RecordCount(PurchaseLineBlanketOrder, 2);

        PurchaseLineBlanketOrder.FindFirst();
        VerifyQuantitiesOnPurchaseLine(
            PurchaseLineBlanketOrder, Round(BlanketOrderQuantity / 3),
            Round(BlanketOrderQuantity / 3), 0, 0, Round(BlanketOrderQuantity / 3),
            VATProdPostingGroup[1].Code);

        PurchaseLineBlanketOrder.Next();
        VerifyQuantitiesOnPurchaseLine(
            PurchaseLineBlanketOrder, Round(BlanketOrderQuantity * 2 / 3),
            Round(BlanketOrderQuantity * 2 / 3), 0, Round(BlanketOrderQuantity * 2 / 3), 0,
            VATProdPostingGroup[2].Code);

        PurchaseLineOrder.Validate("Qty. to Invoice", PurchaseLineOrder.Quantity);
        PurchaseLineOrder.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, true);

        PurchaseLineBlanketOrder.FindFirst();
        VerifyQuantitiesOnPurchaseLine(
            PurchaseLineBlanketOrder, Round(BlanketOrderQuantity / 3),
            0, Round(BlanketOrderQuantity / 3), 0, Round(BlanketOrderQuantity / 3),
            VATProdPostingGroup[1].Code);

        PurchaseLineBlanketOrder.Next();
        VerifyQuantitiesOnPurchaseLine(
            PurchaseLineBlanketOrder, Round(BlanketOrderQuantity * 2 / 3),
            Round(BlanketOrderQuantity * 2 / 3), 0, Round(BlanketOrderQuantity * 2 / 3), 0,
            VATProdPostingGroup[2].Code);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure VATToolMakePurchOrder(FieldOption: Option; DocumentType: Enum "Purchase Document Type"; Partial: Boolean; MultipleLines: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderHeader: Record "Purchase Header";
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        ERMVATToolHelper.CreatePurchaseDocumentWithRef(PurchaseHeader, TempRecRef, DocumentType, '', GetLineCount(MultipleLines));

        // SETUP: Update Qty. To Receive
        if Partial then
            ERMVATToolHelper.UpdateQtyToReceive(PurchaseHeader);

        // SETUP: Make Order and Create Reference Lines.
        ERMVATToolHelper.MakeOrderPurchase(PurchaseHeader, PurchaseOrderHeader);
        if DocumentType = PurchaseHeader."Document Type"::"Blanket Order" then
            ERMVATToolHelper.CreateLinesRefPurchase(TempRecRef, PurchaseHeader) // Update Reference after Make
        else
            TempRecRef.DeleteAll(false); // Quote Deleted after Make
        ERMVATToolHelper.CreateLinesRefPurchase(TempRecRef, PurchaseOrderHeader);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(FieldOption, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Blanket Order & Purchase Order.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyLogEntries(TempRecRef);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolMakePurchaseOrderMake(FieldOption: Option; DocumentType: Enum "Purchase Document Type"; MultipleLines: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderHeader: Record "Purchase Header";
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        ERMVATToolHelper.CreatePurchaseDocumentWithRef(PurchaseHeader, TempRecRef, DocumentType, '', GetLineCount(MultipleLines));

        // SETUP: Update Qty. To Receive
        ERMVATToolHelper.UpdateQtyToReceive(PurchaseHeader);

        // SETUP: Make Order
        ERMVATToolHelper.MakeOrderPurchase(PurchaseHeader, PurchaseOrderHeader);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(FieldOption, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Make Order is Successful
        PurchaseHeader.Find();
        // SETUP: Update Qty. To Receive
        ERMVATToolHelper.UpdateQtyToReceive(PurchaseHeader);

        ERMVATToolHelper.MakeOrderPurchase(PurchaseHeader, PurchaseOrderHeader);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolMakePurchOrderRcv(FieldOption: Option; Partial: Boolean; MultipleLines: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderHeader: Record "Purchase Header";
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        ERMVATToolHelper.CreatePurchaseDocumentWithRef(PurchaseHeader, TempRecRef, PurchaseHeader."Document Type"::"Blanket Order", '',
          GetLineCount(MultipleLines));

        // SETUP: Make Order and Create Reference Lines.
        ERMVATToolHelper.MakeOrderPurchase(PurchaseHeader, PurchaseOrderHeader);
        ERMVATToolHelper.CreateLinesRefPurchase(TempRecRef, PurchaseHeader);

        // SETUP: Receive Purchase Order.
        if Partial then
            ERMVATToolHelper.UpdateQtyToReceive(PurchaseOrderHeader);
        ERMVATToolHelper.CreateLinesRefPurchase(TempRecRef, PurchaseOrderHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseOrderHeader, true, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(FieldOption, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Blanket Order & Purchase Order.
        if Partial then begin
            VerifyPurchaseLnPartReceived(TempRecRef);
            ERMVATToolHelper.VerifyDocumentSplitLogEntries(TempRecRef);
        end else begin
            ERMVATToolHelper.VerifyUpdate(TempRecRef, false);
            ERMVATToolHelper.VerifyErrorLogEntries(TempRecRef, true);
        end;

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolMakePurchOrderRcvPost(FieldOption: Option; Partial: Boolean; MultipleLines: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderHeader: Record "Purchase Header";
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        ERMVATToolHelper.CreatePurchaseDocumentWithRef(PurchaseHeader, TempRecRef, PurchaseHeader."Document Type"::"Blanket Order", '',
          GetLineCount(MultipleLines));

        // SETUP: Make Order and Create Reference Lines.
        ERMVATToolHelper.MakeOrderPurchase(PurchaseHeader, PurchaseOrderHeader);

        // SETUP: Receive Purchase Order.
        if Partial then
            ERMVATToolHelper.UpdateQtyToReceive(PurchaseOrderHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseOrderHeader, true, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(FieldOption, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Purchase Order is Posted Successfully.
        PurchaseOrderHeader.Find();
        LibraryPurchase.PostPurchaseDocument(PurchaseOrderHeader, true, true);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolPurchaseLnPartRec(FieldOption: Option; DocumentType: Enum "Purchase Document Type"; AutoInsertDefault: Boolean; MultipleLines: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(AutoInsertDefault);

        // SETUP: Create and save data to update in a temporary table.
        ERMVATToolHelper.CreatePurchaseDocumentWithRef(PurchaseHeader, TempRecRef, DocumentType, '',
          GetLineCount(MultipleLines));

        // SETUP: Receive (Partially).
        PostPartialReceiptPurchHeader(PurchaseHeader, TempRecRef);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(FieldOption, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then begin
            VerifyPurchaseLnPartReceived(TempRecRef);
            ERMVATToolHelper.VerifyDocumentSplitLogEntries(TempRecRef);
        end else begin
            ERMVATToolHelper.VerifyUpdate(TempRecRef, false);
            ERMVATToolHelper.VerifyErrorLogEntries(TempRecRef, false);
        end;

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolPurchaseLine(FieldOption: Option; IgnoreStatus: Boolean; DocumentType: Enum "Purchase Document Type"; Release: Boolean; Receive: Boolean; MultipleLines: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        TempRecRef: RecordRef;
        Update: Boolean;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        ERMVATToolHelper.CreatePurchaseDocumentWithRef(PurchaseHeader, TempRecRef, DocumentType, '', GetLineCount(MultipleLines));

        // SETUP: Release.
        if Release then
            LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // SETUP: Receive (Fully).
        if Receive then
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(FieldOption, true, IgnoreStatus);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        Update := ExpectUpdate(DocumentType, Receive, Release, IgnoreStatus);
        ERMVATToolHelper.VerifyUpdate(TempRecRef, Update);

        // Verify: Log Entries
        if Update then
            ERMVATToolHelper.VerifyLogEntries(TempRecRef)
        else
            ERMVATToolHelper.VerifyErrorLogEntries(TempRecRef, ExpectLogEntries(DocumentType, Release, IgnoreStatus));

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolPurchaseLineAmount(DocumentType: Enum "Purchase Document Type"; PartialShip: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purchase Order with one partially shipped and released line, update VAT group and ignore header status. Verify Amount.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        ERMVATToolHelper.CreatePurchaseHeader(PurchaseHeader, DocumentType, ERMVATToolHelper.CreateVendor());
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);
        ERMVATToolHelper.CreatePurchaseLines(PurchaseHeader, '', GetLineCount(true));

        // SETUP: Ship (Partially).
        if PartialShip then begin
            ERMVATToolHelper.UpdateQtyToReceive(PurchaseHeader);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        end;

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::"VAT Prod. Posting Group", true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check VAT%, Unit Price and Line Amount Including VAT.
        VerifyPurchaseDocAmount(PurchaseHeader);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolPurchLineReserve(FieldOption: Option)
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        PreparePurchDocWithReservation();

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(FieldOption, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        VerifyPurchDocWithReservation(false);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolPurchaseLineWhse(FieldOption: Option; LineCount: Integer; Receive: Boolean)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        ERMVATToolHelper.CreateWarehouseDocument(TempRecRef, DATABASE::"Purchase Line", LineCount, Receive);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(FieldOption, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, not Receive);

        // Verify: Log Entries
        if not Receive then
            ERMVATToolHelper.VerifyLogEntries(TempRecRef)
        else
            ERMVATToolHelper.VerifyErrorLogEntries(TempRecRef, true);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolPurchOrderItemChrgDiffDoc(Ship: Boolean; Invoice: Boolean)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        PreparePurchaseDocItemCharge(TempRecRef, Ship, Invoice);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::Both, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, not Ship);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolPurchOrderItemChrgSameDoc(Receive: Boolean; Invoice: Boolean)
    var
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        PreparePurchDocItemChargeSameDoc(TempRecRef, Receive, Invoice);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::Both, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        if not Receive then
            VerifyItemChrgAssignmentPurch(TempRecRef)
        else
            ERMVATToolHelper.VerifyUpdate(TempRecRef, false);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolPurchLineWithNegativeQty(Receive: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        ERMVATToolHelper.CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', 1);
        AddLineWithNegativeQty(PurchaseHeader);
        TempRecRef.Open(DATABASE::"Purchase Line", true);
        ERMVATToolHelper.CreateLinesRefPurchase(TempRecRef, PurchaseHeader);

        // SETUP: Receive
        if Receive then begin
            ERMVATToolHelper.UpdateQtyToReceive(PurchaseHeader);
            ERMVATToolHelper.CreateLinesRefPurchase(TempRecRef, PurchaseHeader);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        end;

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolPurch(VATRateChangeSetup2."Update Purchase Documents"::Both, true, true);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        if Receive then
            VerifyPurchaseLnPartReceived(TempRecRef)
        else
            ERMVATToolHelper.VerifyUpdate(TempRecRef, true);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure AddDimensionsForPurchLines(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionSetID: Integer;
    begin
        PurchaseLine.SetFilter("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        if PurchaseLine.FindSet() then
            repeat
                DimensionSetID := PurchaseLine."Dimension Set ID";
                LibraryDimension.FindDimension(Dimension);
                LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
                DimensionSetID := LibraryDimension.CreateDimSet(DimensionSetID, DimensionValue."Dimension Code", DimensionValue.Code);
                PurchaseLine.Validate("Dimension Set ID", DimensionSetID);
                PurchaseLine.Modify(true);
            until PurchaseLine.Next() = 0;
    end;

    local procedure AddLineWithNegativeQty(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLine3: Record "Purchase Line";
    begin
        GetPurchaseLine(PurchaseHeader, PurchaseLine3);
        ERMVATToolHelper.CreatePurchaseLine(PurchaseLine, PurchaseHeader, '', PurchaseLine3."No.", -PurchaseLine3.Quantity);
    end;

    local procedure AddLineWithNextLineNo(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLine3: Record "Purchase Line";
    begin
        GetPurchaseLine(PurchaseHeader, PurchaseLine3);
        PurchaseLine3.FindLast();

        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine.Validate("Line No.", PurchaseLine3."Line No." + 1);
        PurchaseLine.Insert(true);

        PurchaseLine.Validate(Type, PurchaseLine3.Type);
        PurchaseLine.Validate("No.", PurchaseLine3."No.");
        PurchaseLine.Validate(Quantity, PurchaseLine3.Quantity);
        PurchaseLine.Modify(true);
    end;

    local procedure CopyPurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PurchaseLine3: Record "Purchase Line")
    begin
        ERMVATToolHelper.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine3."Location Code", PurchaseLine3."No.", PurchaseLine3.Quantity);
        PurchaseLine.Validate("VAT Prod. Posting Group", PurchaseLine3."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseItemChargeLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    var
        ItemCharge: Record "Item Charge";
        VATProdPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
    begin
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroupCode, GenProdPostingGroupCode);
        ERMVATToolHelper.CreateItemCharge(ItemCharge);
        // Create Purchase Line with Quantity > 1 to be able to partially receive it
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)",
          ItemCharge."No.", ERMVATToolHelper.GetQuantity());
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Location Code", '');
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchInvoiceWithPricesIncludingVAT(var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandInt(10));
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        PurchaseLine.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure GetLineCount(MultipleLines: Boolean) "Count": Integer
    begin
        if MultipleLines then
            Count := LibraryRandom.RandInt(2) + 1
        else
            Count := 1;
    end;

    local procedure GetPurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseHeader.Find();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
    end;

    local procedure GetPurchReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseHeader: Record "Purchase Header")
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptHeader.FindFirst();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.FindFirst();
    end;

    local procedure GetReceiptLineForPurchInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure GetVatProdPostingGroupFromPurchLine(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        exit(PurchaseLine."VAT Prod. Posting Group");
    end;

    local procedure CalcChangedUnitPriceGivenDiffVATPostingSetup(PurchaseLine: Record "Purchase Line"): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenProdPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        ERMVATToolHelper.GetGroupsAfter(VATProdPostingGroup, GenProdPostingGroup, DATABASE::"Purchase Line");
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", VATProdPostingGroup);
        exit(
          Round(
            PurchaseLine."Direct Unit Cost" * (100 + VATPostingSetup."VAT %") / (100 + PurchaseLine."VAT %"),
            LibraryERM.GetUnitAmountRoundingPrecision()));
    end;

    local procedure ExpectLogEntries(DocumentType: Enum "Purchase Document Type"; Release: Boolean; IgnoreStatus: Boolean): Boolean
    var
        Update: Boolean;
    begin
        Update := true;

        if (not IgnoreStatus) and Release then
            Update := false;

        if (DocumentType = PurchaseHeader2."Document Type"::"Credit Memo") or
           (DocumentType = PurchaseHeader2."Document Type"::"Return Order")
        then
            Update := false;

        exit(Update);
    end;

    local procedure ExpectUpdate(DocumentType: Enum "Purchase Document Type"; Receive: Boolean; Release: Boolean; IgnoreStatus: Boolean): Boolean
    var
        Update: Boolean;
    begin
        Update := true;

        if (not IgnoreStatus) and Release then
            Update := false;

        if Receive then
            Update := false;

        if (DocumentType = PurchaseHeader2."Document Type"::"Credit Memo") or
           (DocumentType = PurchaseHeader2."Document Type"::"Return Order")
        then
            Update := false;

        exit(Update);
    end;

    local procedure PreparePurchaseDocItemCharge(var TempRecRef: RecordRef; Receive: Boolean; Invoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        RecRef: RecordRef;
    begin
        ERMVATToolHelper.CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        GetPurchReceiptLine(PurchRcptLine, PurchaseHeader);

        ERMVATToolHelper.CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order,
          PurchaseHeader."Buy-from Vendor No.");
        CreatePurchaseItemChargeLine(PurchaseLine, PurchaseHeader);
        LibraryInventory.CreateItemChargeAssignPurchase(ItemChargeAssignmentPurch,
              PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt, PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.");
        RecRef.GetTable(PurchaseLine);
        TempRecRef.Open(DATABASE::"Purchase Line", true);
        ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);

        if Receive then begin
            ERMVATToolHelper.UpdateQtyToReceive(PurchaseHeader);
            ERMVATToolHelper.UpdateQtyToAssignPurchase(ItemChargeAssignmentPurch, PurchaseLine);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice);
        end;
    end;

    local procedure PreparePurchDocItemChargeSameDoc(var TempRecRef: RecordRef; Receive: Boolean; Invoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine3: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        RecRef: RecordRef;
    begin
        ERMVATToolHelper.CreatePurchaseDocumentWithRef(PurchaseHeader, TempRecRef, PurchaseHeader."Document Type"::Order, '', 1);
        CreatePurchaseItemChargeLine(PurchaseLine, PurchaseHeader);
        PurchaseLine3.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine3.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine3.FindFirst();
        LibraryInventory.CreateItemChargeAssignPurchase(ItemChargeAssignmentPurch,
              PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Order, PurchaseLine3."Document No.", PurchaseLine3."Line No.", PurchaseLine3."No.");

        PurchaseLine.Find();
        RecRef.GetTable(PurchaseLine);
        ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);

        ERMVATToolHelper.UpdateQtyToReceive(PurchaseHeader);

        // If Item Charge should not be received, change Qty. to Receive to 0.
        if not Receive then begin
            PurchaseLine.Find();
            PurchaseLine.Validate("Qty. to Receive", 0);
            PurchaseLine.Modify(true);
        end;

        // If Item Charge should be invoiced, Qty. to Assign should be equal Qty. to Invoice.
        if Invoice then
            ERMVATToolHelper.UpdateQtyToAssignPurchase(ItemChargeAssignmentPurch, PurchaseLine);

        // Line with Item is only split, if Item Charge is not partially received.
        if not Receive then
            ERMVATToolHelper.CreateLinesRefPurchase(TempRecRef, PurchaseHeader);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice);
    end;

    local procedure PreparePurchInvoiceForReceipt(var TempRecRef: RecordRef)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        ERMVATToolHelper.CreatePurchaseDocumentWithRef(PurchaseHeader, TempRecRef, PurchaseHeader."Document Type"::Order, '', 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        GetPurchReceiptLine(PurchRcptLine, PurchaseHeader);

        ERMVATToolHelper.CreatePurchaseHeader(PurchaseHeader2, PurchaseHeader."Document Type"::Invoice,
          PurchaseHeader."Buy-from Vendor No.");
        GetReceiptLineForPurchInvoice(PurchaseHeader2, PurchRcptLine);
        ERMVATToolHelper.CreateLinesRefPurchase(TempRecRef, PurchaseHeader2);
    end;

    local procedure PreparePurchDocItemTracking()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // Create Item with tracking
        ERMVATToolHelper.CreateItemWithTracking(Item, false);

        // Create Purchase Order with Item with tracking
        ERMVATToolHelper.CreatePurchaseHeader(PurchHeader, PurchHeader."Document Type"::Order, ERMVATToolHelper.CreateVendor());
        ERMVATToolHelper.CreatePurchaseLine(PurchLine, PurchHeader, '', Item."No.", ERMVATToolHelper.GetQuantity());

        // Assign Serial Nos
        PurchLine.OpenItemTrackingLines();

        // Partially Receive Order and Update Qty. to Handle in Item Tracking
        ERMVATToolHelper.UpdateQtyToReceive(PurchHeader);
        ERMVATToolHelper.UpdateQtyToHandlePurchase(PurchHeader);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);
    end;

    local procedure PreparePurchDocWithReservation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Qty: Integer;
    begin
        ERMVATToolHelper.CreateItem(Item);
        ERMVATToolHelper.CreateInventorySetup(Item."Inventory Posting Group", '');
        Qty := ERMVATToolHelper.GetQuantity();

        // Create Purchase Order
        ERMVATToolHelper.CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order,
          ERMVATToolHelper.CreateVendor());
        ERMVATToolHelper.CreatePurchaseLine(PurchaseLine, PurchaseHeader, '', Item."No.", Qty);
        PurchaseLine.Validate("Expected Receipt Date", WorkDate());
        PurchaseLine.Modify(true);
        ERMVATToolHelper.UpdateQtyToReceive(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Create Sales Order with Shipment Date after Expected Receipt Date or Purchase Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, ERMVATToolHelper.CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
        SalesLine.Validate("Shipment Date", CalcDate('<' + Format(LibraryRandom.RandInt(2) + 1) + 'D>', WorkDate()));
        SalesLine.Modify(true);

        // Reserve items from Purchase Order
        ERMVATToolHelper.AddReservationLinesForSales(SalesHeader);
    end;

    local procedure PostPartialReceiptPurchHeader(var PurchaseHeader: Record "Purchase Header"; var TempRecRef: RecordRef)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetFilter("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();

        repeat
            ERMVATToolHelper.UpdateLineQtyToReceive(PurchaseLine);
        until PurchaseLine.Next() = 0;

        ERMVATToolHelper.CreateLinesRefPurchase(TempRecRef, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure PostPurchasePrepayment(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Mandatory field for IT
        PurchaseHeader.Validate("Prepayment Due Date", WorkDate());
        PurchaseHeader.Modify(true);
        GetPurchaseLine(PurchaseHeader, PurchaseLine);

        repeat
            UpdatePurchaseLinePrepayment(PurchaseLine);
        until PurchaseLine.Next() = 0;

        ERMVATToolHelper.PostPurchasePrepaymentInvoice(PurchaseHeader);
    end;

    local procedure SetTempTablePurch(TempRecRef: RecordRef; var TempPurchLn: Record "Purchase Line" temporary)
    begin
        // SETTABLE call required for each record of the temporary table.
        TempRecRef.Reset();
        if TempRecRef.FindSet() then begin
            TempPurchLn.SetView(TempRecRef.GetView());
            repeat
                TempRecRef.SetTable(TempPurchLn);
                TempPurchLn.Insert(false);
            until TempRecRef.Next() = 0;
        end;
    end;

    local procedure SetupToolPurch(FieldOption: Option; PerformConversion: Boolean; IgnoreStatus: Boolean)
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
    begin
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup.FieldNo("Update Purchase Documents"), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup.FieldNo("Ignore Status on Purch. Docs."), IgnoreStatus);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup.FieldNo("Perform Conversion"), PerformConversion);
    end;

    local procedure UpdatePurchaseLinePrepayment(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Prepayment %", LibraryRandom.RandInt(20));
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateQtyBlanketOrder(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        QtyReceived: Integer;
    begin
        GetPurchaseLine(PurchaseHeader, PurchaseLine);
        QtyReceived := PurchaseLine."Qty. Rcd. Not Invoiced";
        PurchaseLine.Next();
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity - QtyReceived);
        PurchaseLine.Modify(true);
    end;

    local procedure VerifyQuantitiesOnPurchaseLine(PurchaseLine: Record "Purchase Line"; ExpectedQuantity: Decimal; ExpectedQuantityToInvoice: Decimal; ExpectedQuantityInvoiced: Decimal; ExpectedQuantityToReceive: Decimal; ExpectedQuantityReceived: Decimal; VATProductPostingGroupCode: Code[20])
    begin
        PurchaseLine.TestField("VAT Prod. Posting Group", VATProductPostingGroupCode);
        PurchaseLine.TestField(Quantity, ExpectedQuantity);
        PurchaseLine.TestField("Quantity Invoiced", ExpectedQuantityInvoiced);
        PurchaseLine.TestField("Qty. to Invoice", ExpectedQuantityToInvoice);
        PurchaseLine.TestField("Quantity Received", ExpectedQuantityReceived);
        PurchaseLine.TestField("Qty. to Receive", ExpectedQuantityToReceive);
    end;

    local procedure VerifyItemChrgAssignmentPurch(TempRecRef: RecordRef)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        TempPurchLn: Record "Purchase Line" temporary;
        QtyItemCharge: Integer;
        QtyItem: Integer;
        QtyReceivedItem: Integer;
    begin
        SetTempTablePurch(TempRecRef, TempPurchLn);
        TempPurchLn.SetRange(Type, TempPurchLn.Type::"Charge (Item)");
        TempPurchLn.FindFirst();
        QtyItemCharge := TempPurchLn.Quantity;
        TempPurchLn.SetRange(Type, TempPurchLn.Type::Item);
        TempPurchLn.FindSet();
        QtyItem := TempPurchLn.Quantity;
        QtyReceivedItem := TempPurchLn."Qty. to Receive";
        TempPurchLn.Next();
        QtyItem += TempPurchLn.Quantity;

        ItemChargeAssignmentPurch.SetRange("Document Type", TempPurchLn."Document Type");
        ItemChargeAssignmentPurch.SetFilter("Document No.", TempPurchLn."Document No.");
        ItemChargeAssignmentPurch.FindSet();
        Assert.AreEqual(2, ItemChargeAssignmentPurch.Count, ERMVATToolHelper.GetItemChargeErrorCount());
        Assert.AreNearlyEqual(
          QtyReceivedItem / QtyItem * QtyItemCharge, ItemChargeAssignmentPurch."Qty. to Assign", 0.01, ERMVATToolHelper.GetItemChargeErrorCount());
        ItemChargeAssignmentPurch.Next();
        Assert.AreNearlyEqual(
          (QtyItem - QtyReceivedItem) / QtyItem * QtyItemCharge, ItemChargeAssignmentPurch."Qty. to Assign", 0.01, ERMVATToolHelper.GetItemChargeErrorCount());
    end;

    local procedure VerifyPurchDocWithReservation(Tracking: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
    begin
        ERMVATToolHelper.GetGroupsAfter(VATProdPostingGroup, GenProdPostingGroup, DATABASE::"Purchase Line");

        PurchaseLine.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        PurchaseLine.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        PurchaseLine.FindSet();

        repeat
            ERMVATToolHelper.GetReservationEntryPurchase(ReservationEntry, PurchaseLine);
            if Tracking then
                Assert.AreEqual(PurchaseLine.Quantity, ReservationEntry.Count, ERMVATToolHelper.GetConversionErrorUpdate())
            else
                Assert.AreEqual(1, ReservationEntry.Count, ERMVATToolHelper.GetConversionErrorUpdate());
        until PurchaseLine.Next() = 0;

        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);

        PurchaseLine.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        PurchaseLine.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        PurchaseLine.FindSet();

        repeat
            ERMVATToolHelper.GetReservationEntryPurchase(ReservationEntry, PurchaseLine);
            Assert.AreEqual(0, ReservationEntry.Count, ERMVATToolHelper.GetConversionErrorUpdate());
        until PurchaseLine.Next() = 0;
    end;

    local procedure VerifyPurchaseLnPartReceived(TempRecRef: RecordRef)
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
        TempPurchLn: Record "Purchase Line" temporary;
        PurchLn: Record "Purchase Line";
        VATProdPostingGroupOld: Code[20];
        GenProdPostingGroupOld: Code[20];
        VATProdPostingGroupNew: Code[20];
        GenProdPostingGroupNew: Code[20];
    begin
        VATRateChangeSetup.Get();
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroupOld, GenProdPostingGroupOld);
        ERMVATToolHelper.GetGroupsAfter(VATProdPostingGroupNew, GenProdPostingGroupNew, TempRecRef.Number);

        PurchLn.Reset();
        PurchLn.SetFilter("VAT Prod. Posting Group", StrSubstNo(GroupFilter, VATProdPostingGroupOld, VATProdPostingGroupNew));
        PurchLn.SetFilter("Gen. Prod. Posting Group", StrSubstNo(GroupFilter, GenProdPostingGroupOld, GenProdPostingGroupNew));
        PurchLn.FindSet();

        // Compare Number of lines.
        Assert.AreEqual(TempRecRef.Count, PurchLn.Count, StrSubstNo(ERMVATToolHelper.GetConversionErrorCount(), PurchLn.GetFilters));

        TempRecRef.Reset();
        SetTempTablePurch(TempRecRef, TempPurchLn);
        TempPurchLn.FindSet();

        repeat
            if TempPurchLn."Description 2" = Format(TempPurchLn."Line No.") then
                VerifySplitNewLinePurch(TempPurchLn, PurchLn, VATProdPostingGroupNew, GenProdPostingGroupNew)
            else
                VerifySplitOldLinePurch(TempPurchLn, PurchLn);
            PurchLn.Next();
        until TempPurchLn.Next() = 0;
    end;

    local procedure VerifyPurchaseDocAmount(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseHeader3: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine3: Record "Purchase Line";
    begin
        GetPurchaseLine(PurchaseHeader, PurchaseLine);
        ERMVATToolHelper.CreatePurchaseHeader(
          PurchaseHeader3, PurchaseHeader3."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader3.Validate("Prices Including VAT", true);
        PurchaseHeader3.Modify(true);
        repeat
            CopyPurchaseLine(PurchaseHeader3, PurchaseLine3, PurchaseLine);
            VerifyPurchaseLineAmount(PurchaseLine, PurchaseLine3);
        until PurchaseLine.Next() = 0;
    end;

    local procedure VerifyPurchaseLineAmount(PurchaseLine: Record "Purchase Line"; PurchaseLine3: Record "Purchase Line")
    begin
        PurchaseLine.TestField("VAT %", PurchaseLine3."VAT %");
        PurchaseLine.TestField("Direct Unit Cost", PurchaseLine3."Direct Unit Cost");
        PurchaseLine.TestField("Line Amount", PurchaseLine3."Line Amount");
    end;

    local procedure VerifySplitOldLinePurch(var PurchLn1: Record "Purchase Line"; PurchLn2: Record "Purchase Line")
    begin
        // Splitted Line should have Quantity = Quantity to Ship/Receive of the Original Line and old Product Posting Groups.
        PurchLn2.TestField("Line No.", PurchLn1."Line No.");
        case PurchLn2."Document Type" of
            PurchLn2."Document Type"::Order:
                PurchLn2.TestField(Quantity, PurchLn1."Qty. to Receive");
            PurchLn2."Document Type"::"Return Order":
                PurchLn2.TestField(Quantity, PurchLn1."Return Qty. to Ship");
        end;
        PurchLn2.TestField("Qty. to Receive", 0);
        PurchLn2.TestField("Return Qty. to Ship", 0);
        PurchLn2.TestField("Quantity Received", PurchLn1."Qty. to Receive");
        PurchLn2.TestField("Return Qty. Shipped", PurchLn1."Return Qty. to Ship");
        PurchLn2.TestField("Blanket Order No.", PurchLn1."Blanket Order No.");
        PurchLn2.TestField("Blanket Order Line No.", PurchLn1."Blanket Order Line No.");
        PurchLn2.TestField("VAT Prod. Posting Group", PurchLn1."VAT Prod. Posting Group");
        PurchLn2.TestField("Gen. Prod. Posting Group", PurchLn1."Gen. Prod. Posting Group");
    end;

    local procedure VerifySplitNewLinePurch(var PurchLn1: Record "Purchase Line"; PurchLn2: Record "Purchase Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    begin
        // Line should have Quantity = Original Quantity - Quantity Shipped/Received,
        // Quantity Shipped/Received = 0 and new Posting Groups.
        PurchLn2.TestField(Quantity, PurchLn1.Quantity);
        if PurchLn2."Document Type" = PurchLn2."Document Type"::"Blanket Order" then
            PurchLn2.TestField("Qty. to Receive", 0)
        else
            PurchLn2.TestField("Qty. to Receive", PurchLn1."Qty. to Receive");
        PurchLn2.TestField("Return Qty. to Ship", PurchLn1."Return Qty. to Ship");
        PurchLn2.TestField("Dimension Set ID", PurchLn1."Dimension Set ID");
        PurchLn2.TestField("Blanket Order No.", PurchLn1."Blanket Order No.");
        PurchLn2.TestField("Blanket Order Line No.", PurchLn1."Blanket Order Line No.");
        PurchLn2.TestField("VAT Prod. Posting Group", VATProdPostingGroup);
        PurchLn2.TestField("Gen. Prod. Posting Group", GenProdPostingGroup);
    end;

    local procedure VerifyLineConverted(PurchaseHeader: Record "Purchase Header"; QtyReceived: Decimal; QtyToBeConverted: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        VATProdPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
    begin
        GetPurchaseLine(PurchaseHeader, PurchaseLine);
        PurchaseLine.TestField(Quantity, QtyReceived);
        PurchaseLine.TestField("Quantity Received", QtyReceived);
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroupCode, GenProdPostingGroupCode);
        PurchaseLine.TestField("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        PurchaseLine.TestField("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Assert.AreEqual(1, PurchaseLine.Next(), 'No second line has been generated');
        PurchaseLine.TestField(Quantity, QtyToBeConverted);
        PurchaseLine.TestField("Quantity Received", 0);
        ERMVATToolHelper.GetGroupsAfter(VATProdPostingGroupCode, GenProdPostingGroupCode, DATABASE::"Purchase Line");
        PurchaseLine.TestField("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        PurchaseLine.TestField("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Assert.AreEqual(0, PurchaseLine.Next(), 'The third line has been generated');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Serial No.".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;
}

