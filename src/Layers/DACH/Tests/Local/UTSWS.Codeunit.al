codeunit 142075 "UT SWS"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        DialogErr: Label 'Dialog';
        CopyItemErr: Label 'Filed "Created From Nonstock Item" should not be transfered';
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";

    [Test]
    [HandlerFunctions('CalculateInventoryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemWithQuantityCalculateInventory()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Purpose of the test is to validate the Item Ledger Entry - OnPreDataItem trigger of the Report ID: 790, Calculate Inventory without Zero Quantity for SWS27.
        // Setup.
        Initialize();
        OnPreDataItemCalculateInventory(false, false, ItemJournalLine."Entry Type"::Sale);  // Zero Quantity - FALSE.
    end;

    [Test]
    [HandlerFunctions('CalculateInventoryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemZeroQuantityCalculateInventory()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Purpose of the test is to validate the Item Ledger Entry - OnPreDataItem trigger of the Report ID: 790, Calculate Inventory with Zero Quantity for SWS27.
        // Setup.
        Initialize();
        OnPreDataItemCalculateInventory(true, true, ItemJournalLine."Entry Type"::"Positive Adjmt.");  // Zero Quantity - TRUE.
    end;

    local procedure OnPreDataItemCalculateInventory(ZeroQuantity: Boolean; IncludeItemWithoutTransactions: Boolean; EntryType: Enum "Item Ledger Entry Type")
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        CreateItem(Item);
        CreateItemJournalLine(ItemJournalLine, Item."No.");
        EnqueueCalculateInventoryRequestPageValues(WorkDate(), LibraryUTUtility.GetNewCode(), ZeroQuantity, IncludeItemWithoutTransactions);  // Posting Date as WORKDATE.

        // Exercise.
        RunCalculateInventoryReport(ItemJournalLine, Item."No.");

        // Verify: Verify the Calculated Phys. Inventory Quantity, Phys. Inventory Quantity as zero and Phys. Inventory on Phys. Inventory Item Journal Line.
        VerifyPhysInventoryItemJournalLine(ItemJournalLine."Item No.", 0, ZeroQuantity, EntryType);  // Phys. Inventory as True or False based on ZeroQuantity Boolean.
    end;

    [Test]
    [HandlerFunctions('CalculateInventoryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPostDataItemWithPhysInventoryCalculateInventory()
    begin
        // Purpose of the test is to validate the Item Ledger Entry - OnPostDataItem trigger of the Report ID: 790, Calculate Inventory for Item with Positive Phys. Inventory for SWS27.
        // Setup.
        Initialize();
        OnPostDataItemCalculatePhysInventory(LibraryRandom.RandDec(10, 2));  // Positive Quantity.
    end;

    [Test]
    [HandlerFunctions('CalculateInventoryRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPostDataItemNegPhysInventoryCalculateInventory()
    begin
        // Purpose of the test is to validate the Item Ledger Entry - OnPostDataItem trigger of the Report ID: 790, Calculate Inventory for Item with Negative Quantity for SWS27.
        // Setup.
        Initialize();
        OnPostDataItemCalculatePhysInventory(-LibraryRandom.RandDec(10, 2));  // Negative Quantity.
    end;

    local procedure OnPostDataItemCalculatePhysInventory(Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
    begin
        CreateItem(Item);
        CreateItemJournalLine(ItemJournalLine, Item."No.");
        CreateItemLedgerEntry(ItemLedgerEntry, Item."No.", Quantity);
        EnqueueCalculateInventoryRequestPageValues(WorkDate(), LibraryUTUtility.GetNewCode(), false, false);  // Posting Date as WorkDate(), Zero Quantity - FALSE.

        // Exercise.
        RunCalculateInventoryReport(ItemJournalLine, Item."No.");

        // Verify: Verify the Calculated Phys. Inventory Quantity and Phys. Inventory Quantity as negative on Phys. Inventory Item Journal Line.
        VerifyPhysInventoryItemJournalLine(Item."No.", ItemLedgerEntry.Quantity, true, ItemJournalLine."Entry Type"::"Positive Adjmt.");  // Phys. Inventory as TRUE.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAppliesToDocNumberGenJournalLineError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate the Applies-to Doc. No. - OnValidate trigger of the Table ID: 81, Gen Journal Line for Invoice Error.
        // Setup.
        Initialize();
        CreateGenJournalLine(GenJournalLine);

        // Exercise.
        asserterror UpdateAppliesToDocNoOnGenJournalLine(GenJournalLine);

        // Verify: Verify the Error Code, Actual Error - Invoice doesn't exist or is already closed.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetCustLedgerEntryGenJournalLineError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate GetCustLedgerEntry function of Table ID - 81 General Journal Line for SWS22.

        // Setup: Create General Journal Line with Applies to Doc No.
        Initialize();
        CreateGenJournalLine(GenJournalLine);
        ApplyPaymentToGenJournalLine(GenJournalLine);

        // Exercise.
        asserterror GenJournalLine.GetCustLedgerEntry();

        // Verify: Verify the Error Code, Actual Error - Invoice doesn't exist or is already closed.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFALSE')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetCustLedgerEntryGenJournalLineUpdateInterruptedError()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate GetCustLedgerEntry function of Table ID - 81 General Journal Line for SWS22.

        // Setup: Create General Journal Line with Applies to Doc No. and Cusomer Ledger Entry with different Currency than General Journal Line.
        Initialize();
        CreateGenJournalLine(GenJournalLine);
        ApplyPaymentToGenJournalLine(GenJournalLine);
        CreateCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Applies-to Doc. No.");

        // Exercise.
        asserterror GenJournalLine.GetCustLedgerEntry();

        // Verify: Verify the Error Code, Actual Error - The update has been interrupted to respect the warning.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListPageHandler,PaymentDiscountsWarningMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePostingDateGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Posting Date - OnValidate trigger of Table ID - 81 General Journal Line for SWS25.
        // Setup.
        Initialize();
        CreateGenJournalLineWithApplyEntries(GenJournalLine);
        CreateVendorLedgerEntry(GenJournalLine."Document No.", GenJournalLine."Applies-to Doc. No.");

        // Exercise: Validate Posting Date of General journal.
        UpdateGenJournalPostingDate(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        // Verify: Verify Change Posting Date Warning: This change may affect payment discounts. Please verify the payment discount amount in PaymentDiscountsWarningMessageHandler.
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CopyItemDoesNotTransferFieldCreatedfromNonstockToTargetItemWithBlankNo()
    var
        Item: Record Item;
    begin
        // [SCENARIO 361239.1] "Copy Item" with empty target Item's "No." sets "Created from Nonstock Item" to "No"
        Initialize();

        // [GIVEN] Item "X", created from Nonstock Item
        CreateNonStockItem(Item);

        // [WHEN] Copy Item "X" to Item "Y" with "No." = ''
        CopyItemToTargetItem(Item."No.", '');

        // [THEN] Created Item "Y", where field "Created from Nonstock Item" is FALSE
        Item.Get(GetTargetItemNo());
        Assert.AreEqual(Item."Created From Nonstock Item", false, CopyItemErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CopyItemDoesNotTransferFieldCreatedfromNonstockToTargetItemWithNotBlankNo()
    var
        Item: Record Item;
        TargetItemNo: Code[20];
    begin
        // [SCENARIO 361239.2] "Copy Item" with the specified target Item's "No." sets "Created from Nonstock Item" to "No"
        Initialize();

        // [GIVEN] Item "X", created from Nonstock Item
        CreateNonStockItem(Item);

        // [WHEN] Copy Item "X" to Item "Y" with specified "No."
        TargetItemNo := LibraryUTUtility.GetNewCode();
        CopyItemToTargetItem(Item."No.", TargetItemNo);

        // [THEN] Created Item "Y", where field "Created from Nonstock Item" is FALSE
        Item.Get(TargetItemNo);
        Assert.AreEqual(Item."Created From Nonstock Item", false, CopyItemErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item."Inventory Posting Group" := LibraryUTUtility.GetNewCode10();
        Item.Insert();
    end;

    local procedure CreateItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemLedgerEntry2: Record "Item Ledger Entry";
        Location: Record Location;
    begin
        Location.Init();
        Location.Code := LibraryUTUtility.GetNewCode10();
        Location.Insert();

        ItemLedgerEntry2.FindLast();
        ItemLedgerEntry."Entry No." := ItemLedgerEntry2."Entry No." + 1;
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry.Quantity := Quantity;
        ItemLedgerEntry."Location Code" := Location.Code;
        ItemLedgerEntry.Insert();
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        ItemJournalTemplate.Name := LibraryUTUtility.GetNewCode10();
        ItemJournalTemplate.Insert();
        ItemJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        ItemJournalBatch."Journal Template Name" := ItemJournalTemplate.Name;
        ItemJournalBatch.Insert();

        ItemJournalLine."Journal Template Name" := ItemJournalBatch."Journal Template Name";
        ItemJournalLine."Journal Batch Name" := ItemJournalBatch.Name;
        ItemJournalLine."Line No." := 1;
        ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::Sale;
        ItemJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        ItemJournalLine."Item No." := ItemNo;
        ItemJournalLine."Posting Date" := WorkDate();
        ItemJournalLine."Gen. Prod. Posting Group" := LibraryUTUtility.GetNewCode10();
        ItemJournalLine.Quantity := LibraryRandom.RandDec(10, 2);
        ItemJournalLine."Quantity (Base)" := ItemJournalLine.Quantity;
        ItemJournalLine."Value Entry Type" := ItemJournalLine."Value Entry Type"::"Direct Cost";
        ItemJournalLine.Insert();
    end;

    local procedure EnqueueCalculateInventoryRequestPageValues(PostingDate: Date; DocumentNo: Code[20]; ItemsNotOnInventory: Boolean; IncludeItemWithoutTransactions: Boolean)
    begin
        // Enqueue values for use in CalculateInventoryRequestPageHandler.
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(ItemsNotOnInventory);
        LibraryVariableStorage.Enqueue(IncludeItemWithoutTransactions);
    end;

    local procedure RunCalculateInventoryReport(ItemJournalLine: Record "Item Journal Line"; No: Code[20])
    var
        Item: Record Item;
        CalculateInventory: Report "Calculate Inventory";
    begin
        CalculateInventory.SetItemJnlLine(ItemJournalLine);
        Item.SetRange("No.", No);
        CalculateInventory.SetTableView(Item);
        CalculateInventory.Run();  // Invokes CalculateInventoryRequestPageHandler.
    end;

    local procedure CopyItem(No: Code[20])
    var
        ItemList: TestPage "Item List";
    begin
        ItemList.OpenEdit();
        ItemList.FILTER.SetFilter("No.", No);
        ItemList.CopyItem.Invoke();  // Invokes ItemListRequestPageHandler.
    end;

    local procedure CopyItemToTargetItem(ItemNo: Code[20]; TargetItemNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(TargetItemNo);
        CopyItem(ItemNo);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Journal Batch Name" := LibraryUTUtility.GetNewCode10();
        GenJournalLine."Line No." := 1;
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine.Insert();
    end;

    local procedure CreateGenJournalLineWithApplyEntries(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.Name := LibraryUTUtility.GetNewCode10();
        GenJournalTemplate."Page ID" := PAGE::"General Journal";
        GenJournalTemplate.Insert();
        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        GenJournalBatch.Insert();

        GenJournalLine."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Line No." := LibraryRandom.RandInt(10);
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode();
        GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::Payment;
        GenJournalLine."Applies-to Doc. No." := LibraryUTUtility.GetNewCode();
        GenJournalLine.Amount := -LibraryRandom.RandDec(10, 2);
        GenJournalLine.Insert();
    end;

    local procedure CreateNonStockItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Created From Nonstock Item", true);
        Item.Modify();
    end;

    local procedure CreateCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20])
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry2.FindLast();
        CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." := DocumentNo;
        CustLedgerEntry.Open := true;
        CustLedgerEntry."Currency Code" := LibraryUTUtility.GetNewCode10();
        CustLedgerEntry.Insert();
    end;

    local procedure CreateVendorLedgerEntry(DocumentNo: Code[20]; AppliesToDocNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry2.FindLast();
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry."Document No." := DocumentNo;
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Applies-to Doc. Type"::Payment;
        VendorLedgerEntry."Document No." := AppliesToDocNo;
        VendorLedgerEntry."Pmt. Disc. Tolerance Date" := WorkDate();
        VendorLedgerEntry."Remaining Pmt. Disc. Possible" := LibraryRandom.RandDec(10, 2);
        VendorLedgerEntry.Insert();
    end;

    local procedure GetTargetItemNo(): Code[20]
    var
        InventorySetup: Record "Inventory Setup";
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Record "No. Series";
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        InventorySetup.Get();
        NoSeries.Get(InventorySetup."Item Nos.");
        if NoSeriesCodeunit.GetNoSeriesLine(NoSeriesLine, InventorySetup."Item Nos.", 0D, true) then
            exit(NoSeriesLine."Last No. Used");
    end;

    local procedure UpdateGenJournalPostingDate(JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralJournal: TestPage "General Journal";
    begin
        GenJournalBatch.Get(JournalTemplateName, JournalBatchName);
        LibraryVariableStorage.Enqueue(JournalTemplateName);  // Required inside GeneralJournalTemplateListPageHandler.
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal.Amount.SetValue(LibraryRandom.RandDec(10, 2));
        GeneralJournal."Posting Date".SetValue(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Posting Date more than WORKDATE.
        GeneralJournal.OK().Invoke();
    end;

    local procedure UpdateAppliesToDocNoOnGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate("Applies-to Doc. No.", LibraryUTUtility.GetNewCode());
        GenJournalLine.Modify();
    end;

    local procedure ApplyPaymentToGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::Payment;
        GenJournalLine."Applies-to Doc. No." := LibraryUTUtility.GetNewCode();
        GenJournalLine.Modify();
    end;

    local procedure VerifyPhysInventoryItemJournalLine(ItemNo: Code[20]; QtyCalculated: Decimal; PhysInventory: Boolean; EntryType: Enum "Item Ledger Entry Type")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.SetRange("Entry Type", EntryType);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Qty. (Calculated)", QtyCalculated);
        ItemJournalLine.TestField("Qty. (Phys. Inventory)", QtyCalculated);
        ItemJournalLine.TestField("Phys. Inventory", PhysInventory);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateInventoryRequestPageHandler(var CalculateInventory: TestRequestPage "Calculate Inventory")
    var
        PostingDate: Date;
        DocumentNo: Text;
        ItemsNotOnInventory: Boolean;
        IncludeItemWithoutTransaction: Boolean;
    begin
        PostingDate := LibraryVariableStorage.DequeueDate();
        DocumentNo := LibraryVariableStorage.DequeueText();
        ItemsNotOnInventory := LibraryVariableStorage.DequeueBoolean();
        IncludeItemWithoutTransaction := LibraryVariableStorage.DequeueBoolean();

        CalculateInventory.PostingDate.SetValue(PostingDate);
        CalculateInventory.DocumentNo.SetValue(DocumentNo);
        CalculateInventory.ItemsNotOnInventory.SetValue(ItemsNotOnInventory);
        CalculateInventory.IncludeItemWithNoTransaction.SetValue(IncludeItemWithoutTransaction);
        CalculateInventory.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTemplateListPageHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    var
        Name: Variant;
    begin
        LibraryVariableStorage.Dequeue(Name);
        GeneralJournalTemplateList.FILTER.SetFilter(Name, Name);
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PaymentDiscountsWarningMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, 'This change may affect payment discounts. Please verify the payment discount amount') > 0, Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFALSE(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CopyItemPageHandler(var CopyItem: TestPage "Copy Item")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);

        CopyItem.TargetItemNo.SetValue(ItemNo);
        CopyItem.GeneralItemInformation.SetValue(true);
        CopyItem.OK().Invoke();
    end;
}

