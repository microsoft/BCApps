codeunit 134851 "Purchase Over Receipt"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Over Receipt] [Purchase Order] [Warehouse Receipt]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        OverReceiptFeatureIsEnabled: Boolean;
        IsInitialized: Boolean;
        QuantityAfterOverReceiptErr: Label 'Quantity is wrong after over receipt.';
        OverReceiptNotificationTxt: Label 'An over-receipt quantity is recorded on purchase order %1.', Comment = '%1: Purchase order number';
        QtyToReceiveOverReceiptErr: Label 'Validation error for Field: Qty. to Receive,  Message = ''Qty. to Receive isn''t valid.''';
        WarehouseRcvRequiredErr: Label 'Warehouse Receive is required for this line. The entered information may be disregarded by warehouse activities.';

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderSubformControlVisibilityFeatureEnabled()
    var
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: testPage "Purchase Order";
    begin
        Initialize();
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [WHEN] Open purchase order
        PurchaseOrder.Trap();
        PurchaseOrder.OpenView();
        PurchaseOrder.First();
        // [THEN] "Over Receipt" controls are visible
        Assert.IsTrue(PurchaseOrder.PurchLines."Over-Receipt Code".Visible(), 'Over receipt controls should be visible.');
        Assert.IsTrue(PurchaseOrder.PurchLines."Over-Receipt Quantity".Visible(), 'Over receipt controls should be visible.');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderSubformControlVisibilityFeatureDisabled()
    var
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: testPage "Purchase Order";
    begin
        Initialize();
        // [GIVEN] "Over Receipt" feature is disabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(false);
        BindSubscription(PurchaseOverReceipt);
        // [WHEN] Open purchase order
        PurchaseOrder.Trap();
        PurchaseOrder.OpenView();
        PurchaseOrder.First();
        // [THEN] "Over Receipt" controls are not visible
        Assert.IsFalse(PurchaseOrder.PurchLines."Over-Receipt Code".Visible(), 'Over receipt controls should not be visible.');
        Assert.IsFalse(PurchaseOrder.PurchLines."Over-Receipt Quantity".Visible(), 'Over receipt controls should not be visible.');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQuantityIncreaseValue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        Initialize();
        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order, "Q" = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        // [WHEN] Validate "ORQ" = 3
        PurchaseLine.Validate("Over-Receipt Quantity", 3);
        // [THEN] "Q" = 13
        Assert.IsTrue(PurchaseLine.Quantity = 13, QuantityAfterOverReceiptErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQuantityIncreaseValueTwoTimes()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        Initialize();
        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order, "Q" = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        // [WHEN] Validate "ORQ" = 3
        PurchaseLine.Validate("Over-Receipt Quantity", 3);
        // [WHEN] Validate "ORQ" = 5
        PurchaseLine.Validate("Over-Receipt Quantity", 5);
        // [THEN] "Q" = 15
        Assert.IsTrue(PurchaseLine.Quantity = 15, QuantityAfterOverReceiptErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQuantityIncreaseValueDecreaseValue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        Initialize();
        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order, "Q" = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        // [WHEN] Validate "ORQ" = 3
        PurchaseLine.Validate("Over-Receipt Quantity", 3);
        // [WHEN] Validate "ORQ" = 2
        PurchaseLine.Validate("Over-Receipt Quantity", 2);
        // [THEN] "Q" = 12
        Assert.IsTrue(PurchaseLine.Quantity = 12, QuantityAfterOverReceiptErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQuantityDecreaseValue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        Initialize();
        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order, "Q" = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        // [WHEN] Validate "ORQ" = -3
        PurchaseLine.Validate("Over-Receipt Quantity", -3);
        // [THEN] "Q" = 7
        Assert.IsTrue(PurchaseLine.Quantity = 7, QuantityAfterOverReceiptErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQuantityDecreaseValueTwoTimes()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        Initialize();
        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order, "Q" = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        // [WHEN] Validate "ORQ" = -3
        PurchaseLine.Validate("Over-Receipt Quantity", -3);
        // [WHEN] Validate "ORQ" = -5
        PurchaseLine.Validate("Over-Receipt Quantity", -5);
        // [THEN] "Q" = 5
        Assert.IsTrue(PurchaseLine.Quantity = 5, QuantityAfterOverReceiptErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQuantityDecreaseValueIncreaseValue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        Initialize();
        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order, "Q" = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        // [WHEN] Validate "ORQ" = -3
        PurchaseLine.Validate("Over-Receipt Quantity", -3);
        // [WHEN] Validate "ORQ" = -2
        PurchaseLine.Validate("Over-Receipt Quantity", -2);
        // [THEN] "Q" = 8
        Assert.IsTrue(PurchaseLine.Quantity = 8, QuantityAfterOverReceiptErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQuantitySameValue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        Initialize();
        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order, "Q" = 10, "ORQ" = 5
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseLine."Over-Receipt Quantity" := 5;
        PurchaseLine.Modify(true);
        // [WHEN] Validate "ORQ" = 5, the same value
        PurchaseLine.Validate("Over-Receipt Quantity", 5);
        // [THEN] "Q" = 10, not changed
        Assert.IsTrue(PurchaseLine.Quantity = 10, QuantityAfterOverReceiptErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQuantityZeroValue()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        Initialize();
        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order, "Q" = 10, "ORQ" = 7
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseLine."Over-Receipt Quantity" := 7;
        PurchaseLine.Modify(true);
        // [WHEN] Validate "ORQ" = 0
        PurchaseLine.Validate("Over-Receipt Quantity", 0);
        // [THEN] "Q" = 3, like as before over receipt
        Assert.IsTrue(PurchaseLine.Quantity = 3, QuantityAfterOverReceiptErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithOverReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PstdRcptDocNo: Code[20];
    begin
        Initialize();
        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order, "Q" = 10, "ORQ" = 7
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Over-Receipt Quantity", 7);
        PurchaseLine.Modify(true);
        // [WHEN] Post purchase order
        PstdRcptDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        // [THEN] Purchase receipt line "Q" = purchase line "Q" = 17
        // [THEN] Purchase receipt line "ORQ" = purchase line "ORQ" = 7
        // [THEN] Purchase receipt line "Over-Receipt Code" = purchase line "Over-Receipt Code"
        PurchRcptLine.SetRange("Document No.", PstdRcptDocNo);
        PurchRcptLine.FindFirst();
        Assert.IsTrue(PurchRcptLine.Quantity = PurchaseLine.Quantity, 'Quantity is wrong in purchase receipt line.');
        Assert.IsTrue(PurchRcptLine."Over-Receipt Quantity" = PurchaseLine."Over-Receipt Quantity", 'Over Receipt Quantity is wrong in purchase receipt line.');
        Assert.IsTrue(PurchRcptLine."Over-Receipt Code 2" = PurchaseLine."Over-Receipt Code", 'Over Receipt Code is wrong in purchase receipt line.');
        Assert.IsTrue(PurchRcptLine."Over-Receipt Code 2" <> '', '2');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithOverReceiptWithApproval()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OverReceiptCode: Record "Over-Receipt Code";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        Initialize();
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order
        // [GIVEN] Over-Receipt code with approval and default
        CreateOverReceiptCodeExtended(OverReceiptCode, true, true);
        CreatePurchaseOrderWithoutOverReceipt(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Over-Receipt Quantity", 7);
        PurchaseLine.Modify(true);
        // [WHEN] Post purchase order
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [THEN] Order is not posted, error message about approval is appeared
        Assert.ExpectedError('There are lines with over-receipt required for approval.');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('OverReceiptNotificationHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderNotification()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order with over-receipt
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Over-Receipt Quantity", 7);
        PurchaseLine.Modify(true);
        // [WHEN] Open purchase order page
        PurchaseHeader.Find();
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(PurchaseHeader);
        // [THEN] Notification is shown
        Assert.AreEqual(StrSubstNo(OverReceiptNotificationTxt, PurchaseHeader."No."), LibraryVariableStorage.DequeueText(), 'Wrong notification');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateQtyToReceiveTwiceOverLimit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order with over-receipt = 100 % of quantity
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseHeader.Find();
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(PurchaseHeader);
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(20);
        // [WHEN] Validate "Qty. to Receive" = "Qty. to Receive" + 1 (over-receipt > 100 % of quantity)
        asserterror PurchaseOrder.PurchLines."Qty. to Receive".SetValue(21);
        // [THEN] Error is appeared
        Assert.ExpectedError(QtyToReceiveOverReceiptErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateQtyToReceiveTwiceWithinLimit()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order with over-receipt
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseHeader.Find();
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(PurchaseHeader);
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(15);
        // [WHEN] Validate "Qty. to Receive" = 19
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(19);
        // [THEN] "Qty. to Receive" = 19
        // [THEN] "Over-Receipt Quantity" = 9
        Assert.IsTrue(PurchaseOrder.PurchLines."Qty. to Receive".AsInteger() = 19, 'Wrong Qty. to Receive');
        Assert.IsTrue(PurchaseOrder.PurchLines."Over-Receipt Quantity".AsInteger() = 9, 'Wrong Over-Receipt Quantity');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateOverReceiptQuantityToZero()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);
        // [GIVEN] Released purchase order with over-receipt
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseHeader.Find();
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(PurchaseHeader);
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(15);
        // [WHEN] Validate "Over-Receipt Quantity" = 0
        PurchaseOrder.PurchLines."Over-Receipt Quantity".SetValue(0);
        // [THEN] "Qty. to Receive" = 10
        // [THEN] "Over-Receipt Quantity" = 0
        Assert.IsTrue(PurchaseOrder.PurchLines."Qty. to Receive".AsInteger() = 10, 'Wrong Qty. to Receive');
        Assert.IsTrue(PurchaseOrder.PurchLines."Over-Receipt Quantity".AsInteger() = 0, 'Wrong Over-Receipt Quantity');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    procedure ValidateDefaultOverReceiptCode()
    var
        OverReceiptCode: Record "Over-Receipt Code";
        OverReceiptCodes: TestPage "Over-Receipt Codes";
        OverReceiptCodeTxt: Code[20];
    begin
        Initialize();
        // [GIVEN] Three over-receipt codes
        CreateThreeOverReceiptCodes();

        // [WHEN] Invoke click on the "Default" field of over-receipt code (first record)
        OverReceiptCodes.OpenEdit();
        OverReceiptCodes.First();
        OverReceiptCodeTxt := CopyStr(OverReceiptCodes.Code.Value, 1, MaxStrLen(OverReceiptCodeTxt));
        OverReceiptCodes.Default.SetValue(true);
        OverReceiptCodes.Next();

        // [THEN] First over-receipt code has "Defaul" equal to true
        // [THEN] All other over-receipt codes have "Default" equal to false
        VerifyDefaultOverReceiptCode(OverReceiptCodeTxt);

        // [WHEN] Invoke click on the "Default" field of over-receipt code (last record)
        OverReceiptCodes.Last();
        OverReceiptCodeTxt := CopyStr(OverReceiptCodes.Code.Value, 1, MaxStrLen(OverReceiptCodeTxt));
        OverReceiptCodes.Default.SetValue(true);
        OverReceiptCodes.Previous();

        // [THEN] Last over-receipt code has "Defaul" equal to true
        // [THEN] All other over-receipt codes have "Default" equal to false
        VerifyDefaultOverReceiptCode(OverReceiptCodeTxt);

        // [WHEN]  Deselect "Default" field of over-receipt code (last record)
        OverReceiptCodes.Last();
        OverReceiptCodes.Default.SetValue(false);
        OverReceiptCodes.Previous();

        // [THEN] All over-receipt codes have "Default" equal to false
        OverReceiptCode.SetRange(Default, true);
        Assert.RecordIsEmpty(OverReceiptCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQuantityUndoReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        DocNo: Code[20];
    begin
        Initialize();
        // [FEATURE] [Undo Receipt]
        // [SCENARIO 344787] "Over-Receipt Quantity" returned back to it's value before posting after undo receipt

        // [GIVEN] "Quantity" - "Q"; "Over Receipt Qunatity" - "ORQ"
        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Posted purchase receipt, "Q" = 10, "ORQ" = 3
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Over-Receipt Quantity", 3);
        PurchaseLine.Modify();
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Undo posted purchase receipt
        PurchRcptLine.SetRange("Document No.", DocNo);
        PurchRcptLine.SetRange("Line No.", PurchaseLine."Line No.");
        Codeunit.Run(Codeunit::"Undo Purchase Receipt Line", PurchRcptLine);

        // [THEN] Purchase line "Q" = 13, "ORQ" = 3
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.IsTrue(PurchaseLine.Quantity = 13, 'Wrong quantity after undo receipt');
        Assert.IsTrue(PurchaseLine."Over-Receipt Quantity" = 3, 'Wrong over-receipt quantity after undo receipt');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('OverReceiptNotificationHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderOverReceiptQtyClearsAfterClearOverReceiptCode()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
        OverReceiptApprovalStatus: Enum "Over-Receipt Approval Status";
        OldQtyValue: Decimal;
    begin
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Released Purchase Order with Quantity = X
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        OldQtyValue := PurchaseLine.Quantity;

        // [GIVEN] Make Over-Receipt for Purchase Order, increase = Y., Over-Receipt Status = Pending
        PurchaseLine.Validate("Over-Receipt Quantity", 7);
        PurchaseLine.Validate("Over-Receipt Approval Status", OverReceiptApprovalStatus::Pending);
        PurchaseLine.Modify(true);

        // [WHEN] Open purchase order page
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [WHEN] Clear 'Over-Receipt Code' on Purchase Line
        PurchaseOrder.PurchLines.First();
        PurchaseOrder.PurchLines."Over-Receipt Code".SetValue('');

        // [THEN] 'Over-Receipt Quantity' = 0, Quantity = Qty. to Receive = Qty. To Invoice = Y. 
        PurchaseOrder.PurchLines."Over-Receipt Quantity".AssertEquals(0);
        PurchaseOrder.PurchLines.Quantity.AssertEquals(OldQtyValue);
        PurchaseOrder.PurchLines."Qty. to Receive".AssertEquals(OldQtyValue);
        PurchaseOrder.PurchLines."Qty. to Invoice".AssertEquals(OldQtyValue);
        PurchaseOrder.Close();

        // [THEN] 'Over Receipt Approval Status' = " ";
        PurchaseLine.Find();
        PurchaseLine.TestField("Over-Receipt Approval Status", OverReceiptApprovalStatus::" ");

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('OverReceiptNotificationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OverReceiptQuantityFieldWarnRequireReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record "Location";
        WarehouseEmployee: Record "Warehouse Employee";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
        MessageText: Text;
    begin
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Location "L" with Require Receipt = true
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Released Purchase Order with Item I, Quantity = X, Location Code = L
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        // [GIVEN] Purchase Order for release Purchaser Order opened
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines.First();

        // [WHEN] Set Over-Receipt Quantity = 1
        PurchaseOrder.PurchLines."Over-Receipt Quantity".SetValue(1);

        // [THEN] Message 'Warehouse Receive is required for this line. The entered information may be disregarded by warehouse activities.' appears  
        MessageText := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(WarehouseRcvRequiredErr, MessageText);
        PurchaseOrder.Close();

        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityDoesNotUpdatesWhenOverReceiptQuantityHasWrongValue_PurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 357686] Over receipt quantity increase every time when you insert a value
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Released purchase order with purchase line, quantity = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines."Quantity".AssertEquals(10);

        // [GIVEN] Over-receipt qty = 100% of quantity so quantity should be 20
        PurchaseOrder.PurchLines."Over-Receipt Quantity".SetValue(10);
        PurchaseOrder.PurchLines."Quantity".AssertEquals(20);
        Commit();

        // [GIVEN] "Over-Receipt Quantity" is validated with wrong value: "Over-Receipt Quantity" + 1 (over-receipt > 100% of quantity)
        asserterror PurchaseOrder.PurchLines."Over-Receipt Quantity".SetValue(11);
        PurchaseOrder.PurchLines."Quantity".AssertEquals(20);

        // [WHEN] Validate "Over-Receipt Quantity" with previous correct value
        PurchaseOrder.PurchLines."Over-Receipt Quantity".SetValue(10);

        // [THEN] Quantity still should be 20
        PurchaseOrder.PurchLines."Quantity".AssertEquals(20);
        PurchaseOrder.Close();
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityDoesNotUpdatesWhenOverReceiptQuantityHasWrongValue_WarehouseReceipt()
    var
        WarehouseSetup: Record "Warehouse Setup";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        WarehouseReceipt: TestPage "Warehouse Receipt";
    begin
        // [SCENARIO 357686] Over receipt quantity increase every time when you insert a value
        Initialize();
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Warehouse receipt with warehouse receipt line, quantity = 10
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);
        WarehouseReceipt.OpenEdit();
        WarehouseReceipt.Filter.SetFilter("No.", WarehouseReceiptHeader."No.");
        WarehouseReceipt.WhseReceiptLines."Quantity".AssertEquals(10);

        // [GIVEN] Over-receipt qty = 100% of quantity so quantity should be 20
        WarehouseReceipt.WhseReceiptLines."Over-Receipt Quantity".SetValue(10);
        WarehouseReceipt.WhseReceiptLines."Quantity".AssertEquals(20);
        Commit();

        // [GIVEN] "Over-Receipt Quantity" is validated with wrong value: "Over-Receipt Quantity" + 1 (over-receipt > 100% of quantity)
        asserterror WarehouseReceipt.WhseReceiptLines."Over-Receipt Quantity".SetValue(11);
        WarehouseReceipt.WhseReceiptLines."Quantity".AssertEquals(20);

        // [WHEN] Validate "Over-Receipt Quantity" with previous correct value
        WarehouseReceipt.WhseReceiptLines."Over-Receipt Quantity".SetValue(10);

        // [THEN] Quantity still should be 20
        WarehouseReceipt.WhseReceiptLines."Quantity".AssertEquals(20);
        WarehouseReceipt.Close();
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateOverReceiptQuantityOnWhseReceiptLineForSRO()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [FEATURE] [UT] [Sales Return Order]
        // [SCENARIO 362553] Setting "Over-Receipt Quantity" on Warehouse Receipt Line raises error for Sales Return Order
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);

        // [GIVEN] WarehouseReceiptLine is created for SRO
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);
        WarehouseReceiptLine.Validate("Source Document", WarehouseReceiptLine."Source Document"::"Sales Return Order");
        WarehouseReceiptLine.Modify(true);

        // [WHEN] Set "Over-Receipt Quantity"
        // [THEN] Error is raised: "Source Document must be Purchase Order.."
        asserterror WarehouseReceiptLine.Validate("Over-Receipt Quantity", LibraryRandom.RandInt(10));
        Assert.ExpectedTestFieldError(WarehouseReceiptLine.FieldCaption("Source Document"), Format(WarehouseReceiptLine."Source Document"::"Purchase Order"));
    end;

    [Test]
    [HandlerFunctions('OverReceiptNotificationHandler')]
    [Scope('OnPrem')]
    procedure SetQtyToReceiveWithOverRcptWhenDefQtyToRcptBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
        Qty: Decimal;
    begin
        // [SCENARIO] Set Qty to Receive with Over-Receipt tolerance when Default Qty. to Receive = blank
        Initialize();

        // [GIVEN] Default Qty. to Receive = Blank in Purchases & Payables Setup
        PurchSetup.Get();
        PurchSetup.Validate("Default Qty. to Receive", PurchSetup."Default Qty. to Receive"::Blank);
        PurchSetup.Modify();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Released Purchase Order with Quantity = X
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        Qty := PurchaseLine.Quantity;

        // [GIVEN] Open purchase order page
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [WHEN] Set 'Qty. to Receive' = X + 1
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(Qty + 1);
        PurchaseOrder.Close();

        // [THEN] Quantity = Qty. To Receive = X + 1, Over-Receipt Quantity = 1.
        PurchaseLine.Find();
        PurchaseLine.TestField(Quantity, Qty + 1);
        PurchaseLine.TestField("Qty. to Receive", Qty + 1);
        PurchaseLine.TestField("Over-Receipt Quantity", 1);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('OverReceiptNotificationHandler')]
    procedure ClearOverRcptValueWhenDefQtyToRcptBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
        Qty: Decimal;
    begin
        Initialize();

        // [GIVEN] Default Qty. to Receive = Blank in Purchases & Payables Setup
        PurchSetup.Get();
        PurchSetup.Validate("Default Qty. to Receive", PurchSetup."Default Qty. to Receive"::Blank);
        PurchSetup.Modify();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Released Purchase Order with Quantity = X
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        Qty := PurchaseLine.Quantity;

        // [GIVEN] Open purchase order page
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [GIVEN] 'Qty. to Receive' = X + 1 
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(Qty + 1);
        PurchaseOrder.PurchLines."Over-Receipt Quantity".AssertEquals(1);

        // [WHEN] Set 'Over-Reciept Quantity' = 0
        PurchaseOrder.PurchLines."Over-Receipt Quantity".SetValue(0);

        // [THEN] 'Qty. to Receive' = 0
        PurchaseOrder.PurchLines."Qty. to Receive".AssertEquals(0);
        PurchaseOrder.Close();
    end;

    [Test]
    [HandlerFunctions('OverReceiptNotificationHandler')]
    procedure SetPurchLineQtyToReceiveWithOverRcptWhenDeletedRevalidated()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        PurchaseOrder: TestPage "Purchase Order";
        Qty: Decimal;
    begin
        // [SCENARIO 385845] Set Qty to Receive with Over-Receipt tolerance on Purchase Line after clearing Qty. To Receive
        Initialize();

        // [GIVEN] Default Qty. to Receive = Blank in Purchases & Payables Setup
        PurchSetup.Get();
        PurchSetup.Validate("Default Qty. to Receive", PurchSetup."Default Qty. to Receive"::Remainder);
        PurchSetup.Modify();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Released Purchase Order with Quantity = X
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        Qty := PurchaseLine.Quantity;

        // [GIVEN] Open purchase order page
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [GIVEN] "Qty. to Receive" set to 0
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(0);

        // [WHEN] Set "Qty. to Receive" = X + 1
        PurchaseOrder.PurchLines."Qty. to Receive".SetValue(Qty + 1);
        PurchaseOrder.Close();

        // [THEN] Quantity = Qty. To Receive = X + 1, Over-Receipt Quantity = 1.
        PurchaseLine.Find();
        PurchaseLine.TestField(Quantity, Qty + 1);
        PurchaseLine.TestField("Qty. to Receive", Qty + 1);
        PurchaseLine.TestField("Over-Receipt Quantity", 1);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('OverReceiptNotificationHandler')]
    procedure SetWhseRcptQtyToReceiveWithOverRcptWhenDeletedRevalidated()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseSetup: Record "Warehouse Setup";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        WarehouseReceipt: TestPage "Warehouse Receipt";
        Qty: Decimal;
    begin
        // [SCENARIO 385845] Set Qty to Receive with Over-Receipt tolerance on Warehouse Receipt Line after clearing Qty. To Receive
        Initialize();
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        // [GIVEN] Default Qty. to Receive = Blank in Purchases & Payables Setup
        PurchSetup.Get();
        PurchSetup.Validate("Default Qty. to Receive", PurchSetup."Default Qty. to Receive"::Remainder);
        PurchSetup.Modify();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Released Purchase Order with Quantity = X
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);
        Qty := WarehouseReceiptLine.Quantity;

        // [GIVEN] Open Warehouse Receipt page
        WarehouseReceipt.OpenEdit();
        WarehouseReceipt.Filter.SetFilter("No.", WarehouseReceiptHeader."No.");

        // [GIVEN] "Qty. to Receive" set to 0
        WarehouseReceipt.WhseReceiptLines."Qty. to Receive".SetValue(0);

        // [WHEN] Set "Qty. to Receive" = X + 1
        WarehouseReceipt.WhseReceiptLines."Qty. to Receive".SetValue(Qty + 1);
        WarehouseReceipt.Close();

        // [THEN] Quantity = Qty. To Receive = X + 1, Over-Receipt Quantity = 1.
        WarehouseReceiptLine.Find();
        WarehouseReceiptLine.TestField(Quantity, Qty + 1);
        WarehouseReceiptLine.TestField("Qty. to Receive", Qty + 1);
        WarehouseReceiptLine.TestField("Over-Receipt Quantity", 1);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchaseLineQtyToReceiveUT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);

        // [WHEN] Validate "Qty. to Receive" = 13
        PurchaseLine.Validate("Qty. to Receive", 13);
        PurchaseLine.Modify();

        // [THEN] Quantity = 13
        PurchaseLine.TestField(Quantity, 13);
        // [THEN] "Qty. to Receive" = 13
        PurchaseLine.TestField("Qty. to Receive", 13);
        // [THEN] "Over-Receipt Quantity" = 3
        PurchaseLine.TestField("Over-Receipt Quantity", 3);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchaseLineQtyToReceiveSameValueUT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);

        // [GIVEN] Validate "Qty. to Receive" = 13
        PurchaseLine.Validate("Qty. to Receive", 13);
        PurchaseLine.Modify();

        // [WHEN] Validate "Qty. to Receive" = 13
        PurchaseLine.Validate("Qty. to Receive", 13);
        PurchaseLine.Modify();

        // [THEN] Quantity = 13
        PurchaseLine.TestField(Quantity, 13);
        // [THEN] "Qty. to Receive" = 13
        PurchaseLine.TestField("Qty. to Receive", 13);
        // [THEN] "Over-Receipt Quantity" = 3
        PurchaseLine.TestField("Over-Receipt Quantity", 3);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchaseLineOverReceiptQuantityNonZeroUT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);

        // [WHEN] Validate "Over-Receipt Quantity" = 7
        PurchaseLine.Validate("Over-Receipt Quantity", 7);
        PurchaseLine.Modify();

        // [THEN] Quantity = 17
        PurchaseLine.TestField(Quantity, 17);
        // [THEN] "Qty. to Receive" = 13
        PurchaseLine.TestField("Qty. to Receive", 17);
        // [THEN] "Over-Receipt Quantity" = 7
        PurchaseLine.TestField("Over-Receipt Quantity", 7);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchaseLineOverReceiptQuantityZeroUT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);

        // [GIVEN] "Over-Receipt Quantity" = 7
        PurchaseLine.Validate("Over-Receipt Quantity", 7);
        PurchaseLine.Modify();

        // [WHEN] Validate "Over-Receipt Quantity" = 0
        PurchaseLine.Validate("Over-Receipt Quantity", 0);
        PurchaseLine.Modify();

        // [THEN] Quantity = 10
        PurchaseLine.TestField(Quantity, 10);
        // [THEN] "Qty. to Receive" = 10
        PurchaseLine.TestField("Qty. to Receive", 10);
        // [THEN] "Over-Receipt Quantity" = 0
        PurchaseLine.TestField("Over-Receipt Quantity", 0);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchaseLineOverReceiptCodeEmptyValueUT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);

        // [GIVEN] "Over-Receipt Quantity" = 7
        PurchaseLine.Validate("Over-Receipt Quantity", 7);
        PurchaseLine.Modify();

        // [WHEN] Validate "Over-Receipt Code" = ''
        PurchaseLine.Validate("Over-Receipt Code", '');
        PurchaseLine.Modify();

        // [THEN] Quantity = 10
        PurchaseLine.TestField(Quantity, 10);
        // [THEN] "Qty. to Receive" = 10
        PurchaseLine.TestField("Qty. to Receive", 10);
        // [THEN] "Over-Receipt Quantity" = 0
        PurchaseLine.TestField("Over-Receipt Quantity", 0);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchaseLineQtyToReceiveTwoTimesUT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);

        // [GIVEN] "Qty. to Receive" = 13
        PurchaseLine.Validate("Qty. to Receive", 13);
        PurchaseLine.Modify();

        // [WHEN] Validate "Qty. to Receive" = 17
        PurchaseLine.Validate("Qty. to Receive", 17);
        PurchaseLine.Modify();

        // [THEN] Quantity = 17
        PurchaseLine.TestField(Quantity, 17);
        // [THEN] "Qty. to Receive" = 17
        PurchaseLine.TestField("Qty. to Receive", 17);
        // [THEN] "Over-Receipt Quantity" = 7
        PurchaseLine.TestField("Over-Receipt Quantity", 7);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchaseLineQtyToReceiveTwoTimesWithReceiveUT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10, "Qty. to Receive" = 2
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Qty. to Receive", 2);
        PurchaseLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] "Qty. to Receive" = 13
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Receive", 13);
        PurchaseLine.Modify();

        // [WHEN] Validate "Qty. to Receive" = 17
        PurchaseLine.Validate("Qty. to Receive", 17);
        PurchaseLine.Modify();

        // [THEN] Quantity = 19
        PurchaseLine.TestField(Quantity, 19);
        // [THEN] "Qty. to Receive" = 17
        PurchaseLine.TestField("Qty. to Receive", 17);
        // [THEN] "Over-Receipt Quantity" = 9
        PurchaseLine.TestField("Over-Receipt Quantity", 9);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWarehouseReceiptLineQtyToReceiveUT()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);

        // [WHEN] Validate "Qty. to Receive" = 13
        WarehouseReceiptLine.Validate("Qty. to Receive", 13);
        WarehouseReceiptLine.Modify();

        // [THEN] Quantity = 13
        WarehouseReceiptLine.TestField(Quantity, 13);
        // [THEN] "Qty. to Receive" = 13
        WarehouseReceiptLine.TestField("Qty. to Receive", 13);
        // [THEN] "Over-Receipt Quantity" = 3
        WarehouseReceiptLine.TestField("Over-Receipt Quantity", 3);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWarehouseReceiptLineQtyToReceiveSameValueUT()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);

        // [GIVEN] Validate "Qty. to Receive" = 13
        WarehouseReceiptLine.Validate("Qty. to Receive", 13);
        WarehouseReceiptLine.Modify();

        // [WHEN] Validate "Qty. to Receive" = 13
        WarehouseReceiptLine.Validate("Qty. to Receive", 13);
        WarehouseReceiptLine.Modify();

        // [THEN] Quantity = 13
        WarehouseReceiptLine.TestField(Quantity, 13);
        // [THEN] "Qty. to Receive" = 13
        WarehouseReceiptLine.TestField("Qty. to Receive", 13);
        // [THEN] "Over-Receipt Quantity" = 3
        WarehouseReceiptLine.TestField("Over-Receipt Quantity", 3);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWarehouseReceiptLineOverReceiptQuantityNonZeroUT()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);

        // [WHEN] Validate "Over-Receipt Quantity" = 7
        WarehouseReceiptLine.Validate("Over-Receipt Quantity", 7);
        WarehouseReceiptLine.Modify();

        // [THEN] Quantity = 17
        WarehouseReceiptLine.TestField(Quantity, 17);
        // [THEN] "Qty. to Receive" = 13
        WarehouseReceiptLine.TestField("Qty. to Receive", 17);
        // [THEN] "Over-Receipt Quantity" = 7
        WarehouseReceiptLine.TestField("Over-Receipt Quantity", 7);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWarehouseReceiptLineOverReceiptQuantityZeroUT()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);

        // [GIVEN] "Over-Receipt Quantity" = 7
        WarehouseReceiptLine.Validate("Over-Receipt Quantity", 7);
        WarehouseReceiptLine.Modify();

        // [WHEN] Validate "Over-Receipt Quantity" = 0
        WarehouseReceiptLine.Validate("Over-Receipt Quantity", 0);
        WarehouseReceiptLine.Modify();

        // [THEN] Quantity = 10
        WarehouseReceiptLine.TestField(Quantity, 10);
        // [THEN] "Qty. to Receive" = 10
        WarehouseReceiptLine.TestField("Qty. to Receive", 10);
        // [THEN] "Over-Receipt Quantity" = 0
        WarehouseReceiptLine.TestField("Over-Receipt Quantity", 0);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWarehouseReceiptLineOverReceiptCodeEmptyValueUT()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);

        // [GIVEN] "Over-Receipt Quantity" = 7
        WarehouseReceiptLine.Validate("Over-Receipt Quantity", 7);
        WarehouseReceiptLine.Modify();

        // [WHEN] Validate "Over-Receipt Code" = ''
        WarehouseReceiptLine.Validate("Over-Receipt Code", '');
        WarehouseReceiptLine.Modify();

        // [THEN] Quantity = 10
        WarehouseReceiptLine.TestField(Quantity, 10);
        // [THEN] "Qty. to Receive" = 10
        WarehouseReceiptLine.TestField("Qty. to Receive", 10);
        // [THEN] "Over-Receipt Quantity" = 0
        WarehouseReceiptLine.TestField("Over-Receipt Quantity", 0);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWarehouseReceiptLineQtyToReceiveTwoTimesUT()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);

        // [GIVEN] "Qty. to Receive" = 13
        WarehouseReceiptLine.Validate("Qty. to Receive", 13);
        WarehouseReceiptLine.Modify();

        // [WHEN] Validate "Qty. to Receive" = 17
        WarehouseReceiptLine.Validate("Qty. to Receive", 17);
        WarehouseReceiptLine.Modify();

        // [THEN] Quantity = 17
        WarehouseReceiptLine.TestField(Quantity, 17);
        // [THEN] "Qty. to Receive" = 17
        WarehouseReceiptLine.TestField("Qty. to Receive", 17);
        // [THEN] "Over-Receipt Quantity" = 7
        WarehouseReceiptLine.TestField("Over-Receipt Quantity", 7);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWarehouseReceiptLineQtyToReceiveTwoTimesWithReceiveUT()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [SCENARIO 388925] Make code UI independent
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10, "Qty. to Receive" = 2
        CreateWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine);
        WarehouseReceiptLine.Validate("Qty. to Receive", 2);
        WarehouseReceiptLine.Modify();
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [GIVEN] "Qty. to Receive" = 13
        WarehouseReceiptLine.Get(WarehouseReceiptLine."No.", WarehouseReceiptLine."Line No.");
        WarehouseReceiptLine.Validate("Qty. to Receive", 13);
        WarehouseReceiptLine.Modify();

        // [WHEN] Validate "Qty. to Receive" = 17
        WarehouseReceiptLine.Validate("Qty. to Receive", 17);
        WarehouseReceiptLine.Modify();

        // [THEN] Quantity = 19
        WarehouseReceiptLine.TestField(Quantity, 19);
        // [THEN] "Qty. to Receive" = 17
        WarehouseReceiptLine.TestField("Qty. to Receive", 17);
        // [THEN] "Over-Receipt Quantity" = 9
        WarehouseReceiptLine.TestField("Over-Receipt Quantity", 9);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverReceiptToleranceMoreThan100Pct()
    var
        OverReceiptCode: Record "Over-Receipt Code";
    begin
        // [SCENARIO 426728] Enter more than 100 % in "Over-Receipt Tolerance %"
        Initialize();

        // [GIVEN] Over receipt code
        OverReceiptCode.Get(CreateOverReceiptCode());

        // [WHEN] "Over-Receipt Tolerance %" = 101
        asserterror OverReceiptCode.Validate("Over-Receipt Tolerance %", 101);

        // [THEN] Error message is appeared
        Assert.ExpectedError('Over-Receipt Tolerance % must not be 101 in Over-Receipt Code');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverReceiptToleranceLessThanZeroPct()
    var
        OverReceiptCode: Record "Over-Receipt Code";
    begin
        // [SCENARIO 426728] Enter less than 0 % in "Over-Receipt Tolerance %"
        Initialize();

        // [GIVEN] Over receipt code
        OverReceiptCode.Get(CreateOverReceiptCode());

        // [WHEN] "Over-Receipt Tolerance %" = -1
        asserterror OverReceiptCode.Validate("Over-Receipt Tolerance %", -1);

        // [THEN] Error message is appeared
        Assert.ExpectedError('Over-Receipt Tolerance % must not be -1 in Over-Receipt Code');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ValidateOverReceiptQtyZero_WarehouseActivityLine()
    var
        WarehouseSetup: Record "Warehouse Setup";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [FEATURE] Over-receipt functionality for Inventory Put-away
        // [SCENARIO 360050] Setting Over-Receipt Quantity on Warehouse Activity Line correctly modifies the Quantity
        Initialize();
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreateWarehouseActivity(WarehouseActivityHeader, WarehouseActivityLine);
        WarehouseActivityLine.Validate("Quantity", 10);

        // [WHEN] Validate "Over-Receipt Quantity" = 0
        WarehouseActivityLine.Validate("Over-Receipt Quantity", 0);
        WarehouseActivityLine.Modify();

        // [THEN] Quantity = 10
        WarehouseActivityLine.TestField(Quantity, 10);

        // [THEN] Over-Receipt Quantity = 0
        WarehouseActivityLine.TestField("Over-Receipt Quantity", 0);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ValidateOverReceiptQtyValid_WarehouseActivityLine()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [FEATURE] Over-receipt functionality for Inventory Put-away
        // [SCENARIO 360050] Setting Over-Receipt Quantity on Warehouse Activity Line correctly modifies the Quantity
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreateWarehouseActivity(WarehouseActivityHeader, WarehouseActivityLine);
        WarehouseActivityLine.Validate("Quantity", 10);

        // [WHEN] Validate "Over-Receipt Quantity" = 1
        WarehouseActivityLine.Validate("Over-Receipt Quantity", 1);
        WarehouseActivityLine.Modify();

        // [THEN] Quantity = 11
        WarehouseActivityLine.TestField(Quantity, 11);

        // [THEN] Over-Receipt Code is not empty
        WarehouseActivityLine.TestField("Over-Receipt Code");

        // [WHEN] Validate "Over-Receipt Quantity" = 1 again
        WarehouseActivityLine.Validate("Over-Receipt Quantity", 1);
        WarehouseActivityLine.Modify();

        // [THEN] Quantity = 11 (the Over-Receipt Quanitty dose not add up)
        WarehouseActivityLine.TestField(Quantity, 11);

        // [THEN] Over-Receipt Code is not empty
        WarehouseActivityLine.TestField("Over-Receipt Code");

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ValidateOverReceiptQtyTooLarge_WarehouseActivityLine()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [FEATURE] Over-receipt functionality for Inventory Put-away
        // [SCENARIO 360050] Setting Over-Receipt Quantity on Warehouse Activity Line raises an error if its value is larger than the max value allowed by the default Over-Receipt Code
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);

        // [GIVEN] Purchase order, Quantity = 10, no Over-receipt Code
        CreateWarehouseActivity(WarehouseActivityHeader, WarehouseActivityLine);
        WarehouseActivityLine.Validate("Quantity", 10);

        // [WHEN] Validate "Over-Receipt Quantity" = 12
        // [THEN] Error: Cannot enter more than 10 in OR Qty (allowed value by the ORC)
        asserterror WarehouseActivityLine.Validate("Over-Receipt Quantity", 12);
        Assert.ExpectedError('The selected Over-Receipt Code - ' + WarehouseActivityLine."Over-Receipt Code" + ', allows you to receive up to 20 units.');

        // [THEN] Quantity = 10
        WarehouseActivityLine.TestField(Quantity, 10);

        // [THEN] Over-Receipt Quantity = 0
        WarehouseActivityLine.TestField("Over-Receipt Quantity", 0);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ValidateOverReceiptQtyValidWithCustomCode_WarehouseActivityLine()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [FEATURE] Over-receipt functionality for Inventory Put-away
        // [SCENARIO 360050] Setting Over-Receipt Quantity on Warehouse Activity Line correctly modifies the Quantity
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10, ORC allows ORQ 100% of Quantity
        CreateWarehouseActivity(WarehouseActivityHeader, WarehouseActivityLine);
        WarehouseActivityLine.Validate("Quantity", 10);
        WarehouseActivityLine.Validate("Over-Receipt Code", CreateOverReceiptCode(true));

        // [WHEN] Validate "Over-Receipt Quantity" = 10
        WarehouseActivityLine.Validate("Over-Receipt Quantity", 10);
        WarehouseActivityLine.Modify();

        // [THEN] Quantity = 20
        WarehouseActivityLine.TestField(Quantity, 20);

        // [THEN] Over-Receipt Quantity = 10
        WarehouseActivityLine.TestField("Over-Receipt Quantity", 10);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ValidateOverReceiptCodeEmpty_WarehouseActivityLine()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [FEATURE] Over-receipt functionality for Inventory Put-away
        // [SCENARIO 360050] Setting Over-Receipt Quantity on Warehouse Activity Line correctly modifies the Quantity
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        BindSubscription(PurchaseOverReceipt);

        // [GIVEN] Purchase order, Quantity = 10
        CreateWarehouseActivity(WarehouseActivityHeader, WarehouseActivityLine);
        WarehouseActivityLine.Validate("Quantity", 10);

        // [WHEN] Validate "Over-Receipt Quantity" = 1
        WarehouseActivityLine.Validate("Over-Receipt Quantity", 1);
        WarehouseActivityLine.Modify();

        // [THEN] Quantity = 11
        WarehouseActivityLine.TestField(Quantity, 11);

        // [WHEN] Reset Over-Receipt Code
        WarehouseActivityLine.Validate("Over-Receipt Code", '');
        WarehouseActivityLine.Modify();

        // [THEN] Quantity = 10
        WarehouseActivityLine.TestField(Quantity, 10);

        // [THEN] Over-Receipt Quantity = 0
        WarehouseActivityLine.TestField("Over-Receipt Quantity", 0);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ValidateOverReceiptQtyWrongSourceDocument1_WarehouseActivityLine()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [FEATURE] Over-receipt functionality for Inventory Put-away
        // [SCENARIO 360050] Setting Over-Receipt Quantity on Warehouse Activity Line raises an error if the source document is a Sales Return Order
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);

        // [GIVEN] WarehouseActvitiyLine is created for SRO
        CreateWarehouseActivity(WarehouseActivityHeader, WarehouseActivityLine);
        WarehouseActivityLine.Validate("Source Document", WarehouseActivityLine."Source Document"::"Sales Return Order");
        WarehouseActivityLine.Modify(true);

        // [WHEN] Set Over-Receipt Quantity
        // [THEN] Error is raised: "Source Document must be Purchase Order.."
        asserterror WarehouseActivityLine.Validate("Over-Receipt Quantity", LibraryRandom.RandInt(10));
        Assert.ExpectedTestFieldError(WarehouseActivityLine.FieldCaption("Source Document"), Format(WarehouseActivityLine."Source Document"::"Purchase Order"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ValidateOverReceiptQtyWrongSourceDocument2_WarehouseActivityLine()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [FEATURE] Over-receipt functionality for Inventory Put-away
        // [SCENARIO 360050] Setting Over-Receipt Quantity on Warehouse Activity Line raises an error if the source document is an Inbound Transfer Order
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);

        // [GIVEN] WarehouseActvitiyLine is created for SRO
        CreateWarehouseActivity(WarehouseActivityHeader, WarehouseActivityLine);
        WarehouseActivityLine.Validate("Source Document", WarehouseActivityLine."Source Document"::"Inbound Transfer");
        WarehouseActivityLine.Modify(true);

        // [WHEN] Set Over-Receipt Quantity
        // [THEN] Error is raised: "Source Document must be Purchase Order"
        asserterror WarehouseActivityLine.Validate("Over-Receipt Quantity", LibraryRandom.RandInt(10));
        Assert.ExpectedTestFieldError(WarehouseActivityLine.FieldCaption("Source Document"), Format(WarehouseActivityLine."Source Document"::"Purchase Order"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ValidateOverReceiptQtyWrongSourceDocument3_WarehouseActivityLine()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [FEATURE] Over-receipt functionality for Inventory Put-away
        // [SCENARIO 360050] Setting Over-Receipt Quantity on Warehouse Activity Line raises an error if the source document is an Outbound Transfer Order
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);

        // [GIVEN] WarehouseActvitiyLine is created for SRO
        CreateWarehouseActivity(WarehouseActivityHeader, WarehouseActivityLine);
        WarehouseActivityLine.Validate("Source Document", WarehouseActivityLine."Source Document"::"Outbound Transfer");
        WarehouseActivityLine.Modify(true);

        // [WHEN] Set Over-Receipt Quantity
        // [THEN] Error is raised: "Source Document must be Purchase Order"
        asserterror WarehouseActivityLine.Validate("Over-Receipt Quantity", LibraryRandom.RandInt(10));
        Assert.ExpectedTestFieldError(WarehouseActivityLine.FieldCaption("Source Document"), Format(WarehouseActivityLine."Source Document"::"Purchase Order"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ValidateOverReceiptQtyWithApprovalNeeded_WarehouseActivityLine()
    var
        OverReceiptCode: Record "Over-Receipt Code";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
    begin
        // [FEATURE] Over-receipt functionality for Inventory Put-away
        // [SCENARIO 360050] Setting Over-Receipt Quantity on Warehouse Activity Line raises an error if the document has not been approved yet, when the Over-Receipt code requires approval
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);

        // [GIVEN] Create Warehouse Activity Line with Over-Receipt Code requiring approval, Qty = 10
        CreateWarehouseActivity(PurchaseLine, WarehouseActivityHeader, WarehouseActivityLine);
        CreateOverReceiptCodeExtended(OverReceiptCode, true, true);
        WarehouseActivityLine.Validate("Over-Receipt Code", OverReceiptCode.Code);
        WarehouseActivityLine.Modify(true);

        // [GIVEN] Validate Over-Receipt Quantity
        WarehouseActivityLine.Validate("Over-Receipt Quantity", 1);
        WarehouseActivityLine.Modify(true);

        // [WHEN] Post
        asserterror LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Error: "There are lines with over-receipt required for approval."
        Assert.ExpectedError('There are lines with over-receipt required for approval.');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ValidateOverReceiptQtyWithApprovalNeeded2_WarehouseActivityLine()
    var
        OverReceiptCode: Record "Over-Receipt Code";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        OverReceiptApprovalStatus: Enum "Over-Receipt Approval Status";
    begin
        // [FEATURE] Over-receipt functionality for Inventory Put-away
        // [SCENARIO 360050] Setting Over-Receipt Quantity on Warehouse Activity Line raises an error if the document has not been approved yet, when the Over-Receipt code requires approval
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);

        // [GIVEN] Create Warehouse Activity Line with Over-Receipt Code requiring approval, Qty = 10
        CreateWarehouseActivity(PurchaseLine, WarehouseActivityHeader, WarehouseActivityLine);
        CreateOverReceiptCodeExtended(OverReceiptCode, true, true);
        WarehouseActivityLine.Validate("Over-Receipt Code", OverReceiptCode.Code);
        WarehouseActivityLine.Modify(true);

        // [GIVEN] Validate Over-Receipt Quantity
        WarehouseActivityLine.Validate("Over-Receipt Quantity", 1);
        WarehouseActivityLine.Modify(true);
        PurchaseLine.Validate("Over-Receipt Approval Status", OverReceiptApprovalStatus::Approved);
        PurchaseLine.Modify(true);

        // [WHEN] Post
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Quantity got updated
        WarehouseActivityLine.TestField(Quantity, 11);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OverReceiptCodeCorrectlyPropagatesFromSourcePurchaseLineToWarehouseActivityLine()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        OverReceiptCode: Code[20];
    begin
        // [FEATURE] Over-receipt functionality for Inventory Put-away
        // [SCENARIO 360050] The Over-Receipt Code that was set in a Purchase Line needs to appear in the corresponding new Warehouse Activity Line
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);

        // [GIVEN] A new Warehouse Activity Line is created from a Purchase Line that already has an Over-Receipt Code
        OverReceiptCode := CreateOverReceiptCode(true);
        CreateWarehouseActivityWithOverReceiptCode(WarehouseActivityHeader, WarehouseActivityLine, OverReceiptCode);

        // [THEN] Both lines have the same Over-Receipt Code
        Assert.AreEqual(WarehouseActivityLine."Over-Receipt Code", OverReceiptCode, 'The Over-Receipt Codes are not equal in source Purchase Line and new Warehouse Activity Line.');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverReceiptCodeCorrectlyPropagatesFromSourcePurchaseLineToWarehouseReceipt()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        OverReceiptCode: Code[20];
    begin
        // [FEATURE] Over-receipt functionality for Warehouse Receipt 
        // [SCENARIO 360050] The Over-Receipt Code that was set in a Purchase Line needs to appear in the corresponding new Warehouse Receipt
        Initialize();

        // [GIVEN] "Over Receipt" feature is enabled
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);

        // [WHEN] A new Warehouse Receipt is created from a Purchase Line that already has an Over-Receipt Code
        OverReceiptCode := CreateOverReceiptCode(true);
        CreateWarehouseReceiptWithOverReceiptCode(WarehouseReceiptHeader, WarehouseReceiptLine, OverReceiptCode);

        // [THEN] Both lines have the same Over-Receipt Code
        Assert.AreEqual(WarehouseReceiptLine."Over-Receipt Code", OverReceiptCode, 'The Over-Receipt Codes are not equal in source Purchase Line and new Warehouse Receipt.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OverReceiptQtyOnSplitInventoryPutawayLine()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseOverReceipt: Codeunit "Purchase Over Receipt";
        OverReceiptCode: Code[20];
        Qty: Decimal;
    begin
        // [SCENARIO 485104] Over-Receipt Quantity is properly synchronized to the purchase line on editing the over-receipt quantity on the split inventory put-away line.
        Initialize();

        // [GIVEN] Create purchase order for 100 pcs, release, create inventory put-away.
        PurchaseOverReceipt.SetOverReceiptFeatureEnabled(true);
        OverReceiptCode := CreateOverReceiptCode(true);
        CreateWarehouseActivityWithOverReceiptCode(WarehouseActivityHeader, WarehouseActivityLine, OverReceiptCode);

        // [GIVEN] Split the put-away line into two - for 80 pcs and 20 pcs.
        Qty := WarehouseActivityLine.Quantity;
        WarehouseActivityLine.Validate("Qty. to Handle", Qty * 0.8);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.SplitLine(WarehouseActivityLine);

        // [WHEN] Set "Over-Receipt Quantity" = 5 pcs on the first put-away line and 3 pcs on the second line.
        WarehouseActivityLine.Validate("Over-Receipt Quantity", 0.05 * Qty);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.Next();
        WarehouseActivityLine.TestField("Qty. to Handle", Qty * 0.2);
        WarehouseActivityLine.Validate("Over-Receipt Quantity", 0.03 * Qty);
        WarehouseActivityLine.Modify(true);

        // [THEN] The "Over-Receipt Quantity" on the purchase line is updated to 8 pcs.
        PurchaseLine.Get(WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.");
        PurchaseLine.TestField("Over-Receipt Quantity", 0.08 * Qty);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Purchase Over Receipt");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Purchase Over Receipt");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Purchase Over Receipt");
    end;

    procedure SetOverReceiptFeatureEnabled(Enabled: Boolean)
    begin
        OverReceiptFeatureIsEnabled := Enabled;
    end;

    local procedure CreateOverReceiptCode(): Code[20]
    var
        OverReceiptCode: Record "Over-Receipt Code";
    begin
        OverReceiptCode.Init();
        OverReceiptCode.Code := LibraryUtility.GenerateRandomCode20(OverReceiptCode.FieldNo(Code), Database::"Over-Receipt Code");
        OverReceiptCode.Description := OverReceiptCode.Code;
        OverReceiptCode."Over-Receipt Tolerance %" := 100;
        OverReceiptCode.Insert();

        exit(OverReceiptCode.Code);
    end;

    local procedure CreateOverReceiptCode(DeleteExisting: Boolean): Code[20]
    var
        OverReceiptCode: Record "Over-Receipt Code";
    begin
        if DeleteExisting then
            OverReceiptCode.DeleteAll();

        exit(CreateOverReceiptCode());
    end;

    local procedure CreateOverReceiptCodeExtended(var OverReceiptCode: Record "Over-Receipt Code"; Default: Boolean; RequireApproval: Boolean)
    begin
        OverReceiptCode.Get(CreateOverReceiptCode(true));
        OverReceiptCode.Default := Default;
        OverReceiptCode."Required Approval" := RequireApproval;
        OverReceiptCode.Modify();
    end;

    local procedure CreateThreeOverReceiptCodes()
    var
        i: Integer;
    begin
        for i := 1 to 3 do
            CreateOverReceiptCode();
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 10);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Validate("Over-Receipt Code", CreateOverReceiptCode(true));
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithoutOverReceipt(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 10);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateWarehouseReceipt(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 10);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine, PurchaseHeader);
        WarehouseReceiptLine.Validate("Over-Receipt Code", CreateOverReceiptCode(true));
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure FindWarehouseReceipt(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; PurchaseHeader: Record "Purchase Header")
    begin
        WarehouseReceiptHeader.Get(LibraryWarehouse.FindWhseReceiptNoBySourceDoc(Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure VerifyDefaultOverReceiptCode(OverReceiptCodeTxt: Code[20])
    var
        OverReceiptCode: Record "Over-Receipt Code";
    begin
        OverReceiptCode.SetRange(Default, true);
        Assert.RecordCount(OverReceiptCode, 1);
        OverReceiptCode.FindFirst();
        Assert.AreEqual(OverReceiptCodeTxt, OverReceiptCode.Code, 'Wrong over-receipt code with default');
    end;

    local procedure CreateWarehouseReceiptWithOverReceiptCode(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; OverReceiptCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 10);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Over-Receipt Code", OverReceiptCode);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceipt(WarehouseReceiptHeader, WarehouseReceiptLine, PurchaseHeader);
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure CreateWarehouseActivity(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 10);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateInvtPutPickPurchaseOrder(PurchaseHeader);

        FindWarehouseActivity(WarehouseActivityHeader, WarehouseActivityLine, PurchaseHeader);
        WarehouseActivityLine.Validate("Over-Receipt Code", CreateOverReceiptCode(true));
        WarehouseActivityLine.Modify(true);
    end;

    local procedure CreateWarehouseActivity(var PurchaseLine: Record "Purchase Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 10);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateInvtPutPickPurchaseOrder(PurchaseHeader);

        FindWarehouseActivity(WarehouseActivityHeader, WarehouseActivityLine, PurchaseHeader);
        WarehouseActivityLine.Validate("Over-Receipt Code", CreateOverReceiptCode(true));
        WarehouseActivityLine.Modify(true);
    end;

    local procedure CreateWarehouseActivityWithOverReceiptCode(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line"; OverReceiptCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 10);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Over-Receipt Code", OverReceiptCode);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateInvtPutPickPurchaseOrder(PurchaseHeader);

        FindWarehouseActivity(WarehouseActivityHeader, WarehouseActivityLine, PurchaseHeader);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure FindWarehouseActivity(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line"; PurchaseHeader: Record "Purchase Header")
    begin
        if WarehouseActivityHeader.Get("Warehouse Activity Type"::"Invt. Put-away", LibraryWarehouse.FindWhseActivityNoBySourceDoc(Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.")) then begin
            WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
            WarehouseActivityLine.FindFirst();
        end;
    end;

    [SendNotificationHandler]
    procedure OverReceiptNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Over-Receipt Mgt.", 'OnIsOverReceiptAllowed', '', false, false)]
    local procedure OnBeforeOverReceiptAllowed(var OverReceiptAllowed: Boolean)
    begin
        OverReceiptAllowed := OverReceiptFeatureIsEnabled;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

}