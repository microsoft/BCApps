codeunit 137000 "SCM WIP Posting"
{
    // 1. Verify Posted WIP Entry for Parent item after Post Inventory cost to G/L.
    // 2. Verify Posted WIP Entry for Child item after Post Inventory cost to G/L.
    // 
    // WI: 341770
    //  ---------------------------------------------------------------------------------------------
    //  Test Function Name                                                                TFS ID
    //  ---------------------------------------------------------------------------------------------
    // PostWIPEntryForChildItem                                                          151274
    // PostWIPEntryForParentItem                                                         151654

    Subtype = Test;
    Permissions = tabledata "G/L Entry" = r;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [WIP Posting]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM WIP Posting");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM WIP Posting");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM WIP Posting");
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLRequestPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure PostWIPEntryForParentItem()
    var
        GLEntry: Record "G/L Entry";
        ChildItemNo: Code[20];
        GLAccountNo: Code[20];
    begin
        Initialize();
        // [SCENARIO] Post WIP entry for parent item.
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Create Parent & Child item.
        ChildItemNo := CreateChildItem();

        // Excercise.
        GLAccountNo := PostWIPEntry(CreateParentItem(ChildItemNo), ChildItemNo);

        // [THEN] Verify Inventory Amount in Post Inventory cost to GL report with GL Entry for parent item.
        LibraryLowerPermissions.SetO365Basic();
        FindGLEntry(GLEntry, GLAccountNo);
        VerifyPostInvCostToGLReport(GLEntry."Document No.", -GLEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('PostInvtCostToGLRequestPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure PostWIPEntryForChildItem()
    var
        GLEntry: Record "G/L Entry";
        ChildItemNo: Code[20];
        GLAccountNo: Code[20];
    begin
        Initialize();
        // [SCENARIO] Post WIP entry for child item.
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Create Parent & Child item.
        ChildItemNo := CreateChildItem();
        CreateParentItem(ChildItemNo);

        // Excercise.
        GLAccountNo := PostWIPEntry(ChildItemNo, ChildItemNo);

        // [THEN] Verify Inventory Amount in Post Inventory cost to GL report with GL Entry for child item.
        LibraryLowerPermissions.SetO365Basic();
        FindGLEntry(GLEntry, GLAccountNo);
        VerifyPostInvCostToGLReport(GLEntry."Document No.", GLEntry.Amount);
    end;

    local procedure CalculateAndPostConsumptionJournal(ProductionOrderNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Consumption);
        LibraryManufacturing.CalculateConsumption(ProductionOrderNo, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(ItemNo: Code[20]): Code[20]
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandInt(10));  // Using Random Quantity.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);  // Using boolean parameter for: Forward,CalcLines,CalcRoutings,CalcComponents,CreateInbRqst.
        exit(ProductionOrder."No.");
    end;

    local procedure CreateInventoryPostingSetup(GLAccountNo: Code[20]): Code[10]
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup); // Blank for Description.
        LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, '', InventoryPostingGroup.Code); // Blank for Location Code.
        InventoryPostingSetup.Validate("WIP Account", GLAccountNo);
        InventoryPostingSetup.Validate("Inventory Account", GLAccountNo);
        InventoryPostingSetup.Modify(true);
        exit(InventoryPostingGroup.Code);
    end;

    local procedure CreateChildItem(): Code[20]
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryInventory.CreateItem(Item); // Create child item.
        Item.Validate("Inventory Posting Group", CreateInventoryPostingSetup(GLAccount."No."));
        Item.Validate("Unit Cost", LibraryRandom.RandInt(100)); // Using Random for Unit Cost.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateParentItem(ItemNo: Code[20]): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ItemNo, 1);
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    [Scope('OnPrem')]
    procedure PostWIPEntry(ItemNo: Code[20]; ChildItemNo: Code[20]): Code[20]
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        ProductionOrderNo: Code[20];
    begin
        // Post positive adjustment for parent & child item.
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.",
          ChildItemNo, LibraryRandom.RandInt(100));
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.",
          ItemNo, LibraryRandom.RandInt(100));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // Create Production Order and refresh, calculate and post consumption from consumption journal.
        ProductionOrderNo := CreateAndRefreshReleasedProductionOrder(ItemNo);
        CalculateAndPostConsumptionJournal(ProductionOrderNo);

        // Post inventory cost to GL
        PostValueEntryToGL.SetRange("Item No.", ChildItemNo);
        REPORT.Run(REPORT::"Post Inventory Cost to G/L", true, false, PostValueEntryToGL);  // Using boolean for : ReqWindow,SystemPrinter.
        InventoryPostingSetup.Get(ItemJournalLine."Location Code", ItemJournalLine."Inventory Posting Group");
        exit(InventoryPostingSetup."WIP Account");
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; Type: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure VerifyPostInvCostToGLReport(DocumentNo: Code[20]; Amount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemValueEntryDocumentNo', DocumentNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('InvtAmt', Amount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostInvtCostToGLRequestPageHandler(var PostInventoryCostToGL: TestRequestPage "Post Inventory Cost to G/L")
    var
        PostMethod: Option "per Posting Group","per Entry";
    begin
        PostInventoryCostToGL.PostMethod.SetValue(PostMethod::"per Entry"); // Post Method: per entry or per Posting Group.
        PostInventoryCostToGL.Post.SetValue(true);
        PostInventoryCostToGL.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ValueEntriesWerePostedTxt, Message);
    end;
}

