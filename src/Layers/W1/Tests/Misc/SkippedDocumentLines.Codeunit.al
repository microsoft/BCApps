codeunit 134346 "Skipped Document Lines"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Copy Document] [Skipped Lines]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryResource: Codeunit "Library - Resource";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        LineType: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)";
        NotificationMsg: Label 'An error or warning occured during operation %1.';
        IsBlockedErr: Label '%1 %2 is blocked.', Comment = '%1 - type of entity, e.g. Item; %2 - entity''s No.';
        IsSalesBlockedItemErr: Label 'You cannot sell %1 %2 because the %3 check box is selected on the %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Entity Code, %3 - Field Caption';
        IsPurchBlockedItemErr: Label 'You cannot purchase %1 %2 because the %3 check box is selected on the %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Entity Code, %3 - Field Caption';
        FAIsInactiveErr: Label 'Fixed asset %1 is inactive.', Comment = '%1 - fixed asset no.';
        DirectPostingErr: Label 'G/L account %1 does not allow direct posting.', Comment = '%1 - g/l account no.';
        SalesErrorContextMsg: Label 'Copying sales document %1', Comment = '%1- document no.';
        PurchErrorContextMsg: Label 'Copying purchase document %1', Comment = '%1 - document no.';
        ItemItemVariantLbl: Label '%1 %2', Comment = '%1 - Item No., %2 - Variant Code';

    [Test]
    [Scope('OnPrem')]
    procedure T020_IsEntityBlockedYesForBlockedItem()
    var
        Item: Record Item;
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [Item] [UT]
        Initialize();
        // [GIVEN] Item 'X' is Blocked
        LibraryInventory.CreateItem(Item);
        Item.Blocked := true;
        Item.Modify();

        // [THEN] IsEntityBlocked() returns 'Yes', error message 'Item is blocked' is logged
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsTrue(CopyDocumentMgt.IsEntityBlocked(Database::"Sales Line", false, LineType::Item, Item."No.", ''), 'line should be skipped');
        Assert.AreEqual(1, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message not found');
        Assert.AreEqual(StrSubstNo(IsBlockedErr, 'Item', Item."No."), ActualErrorMgs, 'wrong error message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T021_IsEntityBlockedNoForNotBlockedItem()
    var
        Item: Record Item;
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [Item] [UT]
        Initialize();
        // [GIVEN] Item 'X' is not Blocked
        LibraryInventory.CreateItem(Item);
        Item.TestField(Blocked, false);

        // [THEN] IsEntityBlocked() returns 'No'
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsFalse(CopyDocumentMgt.IsEntityBlocked(Database::"Sales Line", false, LineType::Item, Item."No.", ''), 'line should not be skipped');
        Assert.AreEqual(0, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message should not be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T022_IsEntityBlockedYesForBlockedItemVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [Sales] [Item] [UT]
        Initialize();

        // [GIVEN] Item Variant 'X' is "Blocked"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant.Blocked := true;
        ItemVariant.Modify();

        // [THEN] IsEntityBlocked() returns 'Yes', error message 'Item Variant is blocked' is logged
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsTrue(CopyDocumentMgt.IsEntityBlocked(Database::"Sales Line", false, LineType::Item, Item."No.", ItemVariant.Code), 'line should be skipped');
        Assert.AreEqual(1, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message not found');
        Assert.ExpectedMessage(StrSubstNo(IsBlockedErr, ItemVariant.TableCaption(), StrSubstNo(ItemItemVariantLbl, ItemVariant."Item No.", ItemVariant.Code)), ActualErrorMgs);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T021_IsEntityBlockedNoForNotBlockedItemVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [Item] [UT]
        Initialize();

        // [GIVEN] Item Variant 'X' is not Blocked
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant.TestField(Blocked, false);

        // [THEN] IsEntityBlocked() returns 'No'
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsFalse(CopyDocumentMgt.IsEntityBlocked(Database::"Sales Line", false, LineType::Item, Item."No.", ItemVariant.Code), 'line should not be skipped');
        Assert.AreEqual(0, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message should not be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T022_IsEntityBlockedYesForSalesBlockedItem()
    var
        Item: Record Item;
        TempErrorMessage: Record "Error Message" temporary;
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // [FEATURE] [Sales] [Item] [UT]
        Initialize();
        // [GIVEN] Item 'X' is "Sales Blocked"
        LibraryInventory.CreateItem(Item);
        Item."Sales Blocked" := true;
        Item.Modify();

        // [THEN] IsEntityBlocked() returns 'Yes', error message 'Item is blocked' for the field "Sales Blocked" is logged
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsTrue(CopyDocumentMgt.IsEntityBlocked(Database::"Sales Line", false, LineType::Item, Item."No.", ''), 'line should be skipped');
        Assert.IsTrue(ErrorMessageMgt.GetErrors(TempErrorMessage), 'not found errors');
        TempErrorMessage.TestField("Field Number", Item.FieldNo("Sales Blocked"));
        Assert.ExpectedMessage(StrSubstNo(IsSalesBlockedItemErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Sales Blocked")), TempErrorMessage."Message");
        TempErrorMessage.TestField("Support Url");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T023_IsEntityBlockedNoForNotSalesBlockedItem()
    var
        Item: Record Item;
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [Sales] [Item] [UT]
        Initialize();
        // [GIVEN] Item 'X' is not "Sales Blocked"
        LibraryInventory.CreateItem(Item);
        Item.TestField("Sales Blocked", false);

        // [THEN] IsEntityBlocked() returns 'No'
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsFalse(CopyDocumentMgt.IsEntityBlocked(Database::"Sales Line", false, LineType::Item, Item."No.", ''), 'line should not be skipped');
        Assert.AreEqual(0, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message should not be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T022_IsEntityBlockedYesForSalesBlockedItemVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        TempErrorMessage: Record "Error Message" temporary;
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // [FEATURE] [Sales] [Item] [UT]
        Initialize();

        // [GIVEN] Item Variant 'X' is "Sales Blocked"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant."Sales Blocked" := true;
        ItemVariant.Modify();

        // [THEN] IsEntityBlocked() returns 'Yes', error message 'Item Variant is blocked' for the field "Sales Blocked" is logged
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsTrue(CopyDocumentMgt.IsEntityBlocked(Database::"Sales Line", false, LineType::Item, Item."No.", ItemVariant.Code), 'line should be skipped');
        Assert.IsTrue(ErrorMessageMgt.GetErrors(TempErrorMessage), 'not found errors');
        TempErrorMessage.TestField("Field Number", ItemVariant.FieldNo("Sales Blocked"));
        Assert.ExpectedMessage(StrSubstNo(IsSalesBlockedItemErr, ItemVariant.TableCaption(), StrSubstNo(ItemItemVariantLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption("Sales Blocked")), TempErrorMessage."Message");
        TempErrorMessage.TestField("Support Url");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T023_IsEntityBlockedNoForNotSalesBlockedItemVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [Sales] [Item] [UT]
        Initialize();

        // [GIVEN] Item Variant 'X' is not "Sales Blocked"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant.TestField("Sales Blocked", false);

        // [THEN] IsEntityBlocked() returns 'No'
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsFalse(CopyDocumentMgt.IsEntityBlocked(Database::"Sales Line", false, LineType::Item, Item."No.", ItemVariant.Code), 'line should not be skipped');
        Assert.AreEqual(0, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message should not be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T024_IsEntityBlockedYesForPurchBlockedItem()
    var
        Item: Record Item;
        TempErrorMessage: Record "Error Message" temporary;
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // [FEATURE] [Purchase] [Item] [UT]
        Initialize();
        // [GIVEN] Item 'X' is "Purchasing Blocked"
        LibraryInventory.CreateItem(Item);
        Item."Purchasing Blocked" := true;
        Item.Modify();

        // [THEN] IsEntityBlocked() returns 'Yes', error message 'Item is blocked' for the field "Purchasing Blocked" is logged
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsTrue(CopyDocumentMgt.IsEntityBlocked(Database::"Purchase Line", false, LineType::Item, Item."No.", ''), 'line should be skipped');
        Assert.IsTrue(ErrorMessageMgt.GetErrors(TempErrorMessage), 'not found errors');
        TempErrorMessage.TestField("Field Number", Item.FieldNo("Purchasing Blocked"));
        Assert.ExpectedMessage(StrSubstNo(IsPurchBlockedItemErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Purchasing Blocked")), TempErrorMessage."Message");
        TempErrorMessage.TestField("Support Url");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T025_IsEntityBlockedNoForNotPurchBlockedItem()
    var
        Item: Record Item;
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [Purchase] [Item] [UT]
        Initialize();
        // [GIVEN] Item 'X' is not "Purchasing Blocked"
        LibraryInventory.CreateItem(Item);
        Item.TestField("Purchasing Blocked", false);

        // [THEN] IsEntityBlocked() returns 'No'
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsFalse(CopyDocumentMgt.IsEntityBlocked(Database::"Purchase Line", false, LineType::Item, Item."No.", ''), 'line should not be skipped');
        Assert.AreEqual(0, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message should not be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T024_IsEntityBlockedYesForPurchBlockedItemVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        TempErrorMessage: Record "Error Message" temporary;
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // [FEATURE] [Purchase] [Item] [UT]
        Initialize();

        // [GIVEN] Item Variant 'X' is "Purchasing Blocked"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant."Purchasing Blocked" := true;
        ItemVariant.Modify();

        // [THEN] IsEntityBlocked() returns 'Yes', error message 'Item is blocked' for the field "Purchasing Blocked" is logged
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsTrue(CopyDocumentMgt.IsEntityBlocked(Database::"Purchase Line", false, LineType::Item, Item."No.", ItemVariant.Code), 'line should be skipped');
        Assert.IsTrue(ErrorMessageMgt.GetErrors(TempErrorMessage), 'not found errors');
        TempErrorMessage.TestField("Field Number", Item.FieldNo("Purchasing Blocked"));
        Assert.ExpectedMessage(StrSubstNo(IsPurchBlockedItemErr, ItemVariant.TableCaption(), StrSubstNo(ItemItemVariantLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption("Purchasing Blocked")), TempErrorMessage."Message");
        TempErrorMessage.TestField("Support Url");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T025_IsEntityBlockedNoForNotPurchBlockedItemVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [Purchase] [Item] [UT]
        Initialize();

        // [GIVEN] Item Variant 'X' is not "Purchasing Blocked"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant.TestField("Purchasing Blocked", false);

        // [THEN] IsEntityBlocked() returns 'No'
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsFalse(CopyDocumentMgt.IsEntityBlocked(Database::"Purchase Line", false, LineType::Item, Item."No.", ItemVariant.Code), 'line should not be skipped');
        Assert.AreEqual(0, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message should not be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T028_IsEntityBlockedYesForBlockedResource()
    var
        Resource: Record Resource;
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [Resource] [UT]
        Initialize();
        // [GIVEN] Resource 'X' is Blocked
        LibraryResource.CreateResource(Resource, '');
        Resource.Blocked := true;
        Resource.Modify();

        // [THEN] IsEntityBlocked() returns 'Yes', error message 'Resource is blocked' is logged
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsTrue(CopyDocumentMgt.IsEntityBlocked(0, false, LineType::Resource, Resource."No.", ''), 'line should be skipped');
        Assert.AreEqual(1, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message not found');
        Assert.AreEqual(StrSubstNo(IsBlockedErr, 'Resource', Resource."No."), ActualErrorMgs, 'wrong error message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T029_IsEntityBlockedNoForNotBlockedResource()
    var
        Resource: Record Resource;
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [Resource] [UT]
        Initialize();
        // [GIVEN] Resource 'X' is not Blocked
        LibraryResource.CreateResource(Resource, '');
        Resource.TestField(Blocked, false);

        // [THEN] IsEntityBlocked() returns 'No'
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsFalse(CopyDocumentMgt.IsEntityBlocked(0, false, LineType::Resource, Resource."No.", ''), 'line should not be skipped');
        Assert.AreEqual(0, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message should not be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T030_IsEntityBlockedYesForBlockedGLAcc()
    var
        GLAccount: Record "G/L Account";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [G/L Account] [UT]
        Initialize();
        // [GIVEN] G/L Account 'X', where "Blocked" is 'Yes'
        GLAccount."No." := LibraryERM.CreateGLAccountNoWithDirectPosting();
        GLAccount.Blocked := true;
        GLAccount.Modify();

        // [THEN] IsEntityBlocked() returns 'Yes', error message 'G/L Account is blocked' is logged
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsTrue(CopyDocumentMgt.IsEntityBlocked(0, false, LineType::"G/L Account", GLAccount."No.", ''), 'line should be skipped');
        Assert.AreEqual(1, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message not found');
        Assert.AreEqual(StrSubstNo(IsBlockedErr, 'G/L Account', GLAccount."No."), ActualErrorMgs, 'wrong error message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T031_IsEntityBlockedNoForNotBlockedGLAcc()
    var
        GLAccount: Record "G/L Account";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [G/L Account] [UT]
        Initialize();
        // [GIVEN] G/L Account 'X', where "Blocked" is 'No'
        GLAccount."No." := LibraryERM.CreateGLAccountNoWithDirectPosting();

        // [THEN] IsEntityBlocked() returns 'No'
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsFalse(CopyDocumentMgt.IsEntityBlocked(0, false, LineType::"G/L Account", GLAccount."No.", ''), 'line should not be skipped');
        Assert.AreEqual(0, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message should not be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T032_IsEntityBlockedYesForNotDirectPostingGLAcc()
    var
        GLAccount: Record "G/L Account";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [G/L Account] [UT]
        Initialize();
        // [GIVEN] G/L Account 'X', where "Direct Posting" is 'No'
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Direct Posting" := false;
        GLAccount.Modify();

        // [THEN] IsEntityBlocked() returns 'Yes', error message 'G/L Account does not allow direct posting' is logged
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsTrue(CopyDocumentMgt.IsEntityBlocked(0, false, LineType::"G/L Account", GLAccount."No.", ''), 'line should be skipped');
        Assert.AreEqual(1, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message not found');
        Assert.AreEqual(StrSubstNo(DirectPostingErr, GLAccount."No."), ActualErrorMgs, 'wrong error message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T033_IsEntityBlockedNoForDirectPostingGLAcc()
    var
        GLAccount: Record "G/L Account";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [G/L Account] [UT]
        Initialize();
        // [GIVEN] G/L Account 'X', where "Direct Posting" is 'Yes'
        GLAccount."No." := LibraryERM.CreateGLAccountNoWithDirectPosting();

        // [THEN] IsEntityBlocked() returns 'No'
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsFalse(CopyDocumentMgt.IsEntityBlocked(0, false, LineType::"G/L Account", GLAccount."No.", ''), 'line should not be skipped');
        Assert.AreEqual(0, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message should not be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T035_IsEntityBlockedYesForBlockedFA()
    var
        FixedAsset: Record "Fixed Asset";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [Fixed Asset] [UT]
        Initialize();
        // [GIVEN] Fixed Asset 'X' is Blocked
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.Blocked := true;
        FixedAsset.Modify();

        // [THEN] IsEntityBlocked() returns 'Yes', error message 'Fixed Asset is blocked' is logged
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsTrue(CopyDocumentMgt.IsEntityBlocked(0, false, LineType::"Fixed Asset", FixedAsset."No.", ''), 'line should be skipped');
        Assert.AreEqual(1, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message not found');
        Assert.AreEqual(StrSubstNo(IsBlockedErr, 'Fixed Asset', FixedAsset."No."), ActualErrorMgs, 'wrong error message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T036_IsEntityBlockedNoForNotBlockedFA()
    var
        FixedAsset: Record "Fixed Asset";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [Fixed Asset] [UT]
        Initialize();
        // [GIVEN] Fixed Asset 'X' is not Blocked
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.TestField(Blocked, false);

        // [THEN] IsEntityBlocked() returns 'No'
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsFalse(CopyDocumentMgt.IsEntityBlocked(0, false, LineType::"Fixed Asset", FixedAsset."No.", ''), 'line should not be skipped');
        Assert.AreEqual(0, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message should not be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T037_IsEntityBlockedYesForInactiveFA()
    var
        FixedAsset: Record "Fixed Asset";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [Fixed Asset] [UT]
        Initialize();
        // [GIVEN] Fixed Asset 'X' is Inactive
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.Inactive := true;
        FixedAsset.Modify();

        // [THEN] IsEntityBlocked() returns 'Yes', error message 'Fixed Asset is inactive' is logged
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsTrue(CopyDocumentMgt.IsEntityBlocked(0, false, LineType::"Fixed Asset", FixedAsset."No.", ''), 'line should be skipped');
        Assert.AreEqual(1, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message not found');
        Assert.AreEqual(StrSubstNo(FAIsInactiveErr, FixedAsset."No."), ActualErrorMgs, 'wrong error message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T038_IsEntityBlockedNoForActiveFA()
    var
        FixedAsset: Record "Fixed Asset";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [Fixed Asset] [UT]
        Initialize();
        // [GIVEN] Fixed Asset 'X' is not Inactive
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.TestField(Inactive, false);

        // [THEN] IsEntityBlocked() returns 'No'
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsFalse(CopyDocumentMgt.IsEntityBlocked(0, false, LineType::"Fixed Asset", FixedAsset."No.", ''), 'line should not be skipped');
        Assert.AreEqual(0, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message should not be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T040_IsEntityBlockedNoForSalesBlockedItemInReturnDoc()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Item] [UT]
        Initialize();
        // [GIVEN] Item 'X' is "Sales Blocked"
        LibraryInventory.CreateItem(Item);
        Item."Sales Blocked" := true;
        Item.Modify();
        // [GIVEN] Copy to Sales Line, where "Document Type is 'Credit Memo'
        SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";

        // [THEN] IsEntityBlocked() returns 'No', if document type is 'Credit Memo'
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsFalse(
            CopyDocumentMgt.IsEntityBlocked(Database::"Sales Line", SalesLine.IsCreditDocType(), LineType::Item, Item."No.", ''),
            'line should not be skipped');
        Assert.AreEqual(0, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message should not be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T041_IsEntityBlockedNoForPurchBlockedItemInReturnDoc()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [Purchase] [Return Order] [Item] [UT]
        Initialize();
        // [GIVEN] Item 'X' is "Purchasing Blocked"
        LibraryInventory.CreateItem(Item);
        Item."Purchasing Blocked" := true;
        Item.Modify();
        // [GIVEN] Copy to Purchase Line, where "Document Type is 'Return Order'
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::"Return Order";

        // [THEN] IsEntityBlocked() returns 'No'
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsFalse(
            CopyDocumentMgt.IsEntityBlocked(Database::"Purchase Line", PurchaseLine.IsCreditDocType(), LineType::Item, Item."No.", ''),
            'line should not be skipped');
        Assert.AreEqual(0, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message should not be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T040_IsEntityBlockedNoForSalesBlockedItemVariantInReturnDoc()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        SalesLine: Record "Sales Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Item] [UT]
        Initialize();

        // [GIVEN] Item Variant 'X' is "Sales Blocked"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant."Sales Blocked" := true;
        ItemVariant.Modify();

        // [GIVEN] Copy to Sales Line, where "Document Type is 'Credit Memo'
        SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";

        // [THEN] IsEntityBlocked() returns 'No', if document type is 'Credit Memo'
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsFalse(CopyDocumentMgt.IsEntityBlocked(Database::"Sales Line", SalesLine.IsCreditDocType(), LineType::Item, Item."No.", ItemVariant.Code), 'line should not be skipped');
        Assert.AreEqual(0, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message should not be found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T041_IsEntityBlockedNoForPurchBlockedItemVariantInReturnDoc()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PurchaseLine: Record "Purchase Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ActualErrorMgs: Text[250];
    begin
        // [FEATURE] [Purchase] [Return Order] [Item] [UT]
        Initialize();

        // [GIVEN] Item Variant 'X' is "Purchasing Blocked"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant."Purchasing Blocked" := true;
        ItemVariant.Modify();

        // [GIVEN] Copy to Purchase Line, where "Document Type is 'Return Order'
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::"Return Order";

        // [THEN] IsEntityBlocked() returns 'No'
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        Assert.IsFalse(CopyDocumentMgt.IsEntityBlocked(Database::"Purchase Line", PurchaseLine.IsCreditDocType(), LineType::Item, Item."No.", ItemVariant.Code), 'line should not be skipped');
        Assert.AreEqual(0, ErrorMessageMgt.GetLastError(ActualErrorMgs), 'error message should not be found');
    end;


    [Test]
    [HandlerFunctions('ShowErrorsNotificationHandler')]
    [Scope('OnPrem')]
    procedure T100_CopySalesDocWithBlockedItem()
    var
        Customer: Record Customer;
        ErrorMessageRegister: Record "Error Message Register";
        Item: Record Item;
        FromSalesHeader: Record "Sales Header";
        ToSalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessagesPage: TestPage "Error Messages";
        RegisterID: Guid;
    begin
        // [FEATURE] [Sales] [Item]
        // [SCENARIO] "Copy Document" skips document lines, where the item is blocked
        Initialize();

        // [GIVEN] Item 'X' is created
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        item.get(LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));

        // [GIVEN] Sales Quote is created
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateSalesQuoteHeaderWithLines(FromSalesHeader, Customer, Item, 1, 1);

        // [GIVEN] Destination Sales Order '1001' is created
        LibrarySales.CreateSalesHeader(ToSalesHeader, "Sales Document Type From"::Order, Customer."No.");

        // [GIVEN] Item's Attribute "Blocked" is changed to TRUE
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [WHEN] Copy Sales Document
        ErrorMessagesPage.Trap();
        CopyDocumentMgt.SetProperties(true, false, false, false, false, false, false);
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::Quote, FromSalesHeader."No.", ToSalesHeader);

        // [THEN] Notification: "An error or warning occured during operation Copying sales document."
        Assert.AreEqual(
          StrSubstNo(NotificationMsg, StrSubstNo(SalesErrorContextMsg, FromSalesHeader."No.")),
          LibraryVariableStorage.DequeueText(), 'wrong notification message');
        Assert.IsTrue(Evaluate(RegisterID, LibraryVariableStorage.DequeueText()), 'register id evaluation');
        Assert.IsFalse(IsNullGuid(RegisterID), 'register id is null');
        // [THEN] On action 'Show skipped lines' see the Error Messages list with one item 'X'
        ErrorMessagesPage.Source.AssertEquals(Item.RecordId);
        Assert.IsFalse(ErrorMessagesPage.Next(), 'should be one line in the item list');
        // [THEN] Adedd line to Error Message Register, where "Description" is 'Copying sales document 1001', "Errors" is 0, "Warnings" is 1.
        ErrorMessageRegister.Get(RegisterID);
        ErrorMessageRegister.CalcFields(Errors, Warnings);
        ErrorMessageRegister.TestField(Errors, 0);
        ErrorMessageRegister.TestField(Warnings, 1);
        Assert.AreEqual(StrSubstNo(SalesErrorContextMsg, FromSalesHeader."No."), ErrorMessageRegister."Message", 'Register.Description');

        LibraryNotificationMgt.RecallNotificationsForRecord(ToSalesHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ShowErrorsNotificationHandler')]
    [Scope('OnPrem')]
    procedure T110_CopySalesDocWithBlockedResource()
    var
        Customer: Record Customer;
        Resource: Record Resource;
        FromSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ToSalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessagesPage: TestPage "Error Messages";
        RegisterID: Guid;
    begin
        // [FEATURE] [Sales] [Resource]
        // [SCENARIO] "Copy Document" skips document lines, where the resource is blocked
        Initialize();

        // [GIVEN] Resource 'X' is created
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryResource.CreateResource(Resource, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Sales Quote is created
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateSalesQuoteHeader(FromSalesHeader, Customer);
        LibrarySales.CreateSalesLine(SalesLine, FromSalesHeader, SalesLine.Type::Resource, Resource."No.", 1);

        // [GIVEN] Destination Sales Order is created
        LibrarySales.CreateSalesHeader(ToSalesHeader, "Sales Document Type From"::Order, Customer."No.");

        // [GIVEN] Resource's Attribute "Blocked" is changed to TRUE
        Resource.Validate(Blocked, true);
        Resource.Modify(true);

        // [WHEN] Copy Sales Document
        ErrorMessagesPage.Trap();
        CopyDocumentMgt.SetProperties(true, false, false, false, false, false, false);
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::Quote, FromSalesHeader."No.", ToSalesHeader);

        // [THEN] Notification: "An error or warning occured during operation Copying sales document."
        Assert.AreEqual(
          StrSubstNo(NotificationMsg, StrSubstNo(SalesErrorContextMsg, FromSalesHeader."No.")), LibraryVariableStorage.DequeueText(),
          'wrong notification message');
        Assert.IsTrue(Evaluate(RegisterID, LibraryVariableStorage.DequeueText()), 'register id evaluation');
        Assert.IsFalse(IsNullGuid(RegisterID), 'register id is null');
        // [THEN] On action 'Show skipped resources' see the Item List with one resource 'X'
        ErrorMessagesPage.Source.AssertEquals(Resource.RecordId);
        Assert.IsFalse(ErrorMessagesPage.Next(), 'should be one line in the item list');

        LibraryNotificationMgt.RecallNotificationsForRecord(ToSalesHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ShowErrorsNotificationHandler')]
    [Scope('OnPrem')]
    procedure T200_CopyPurchaseDocWithBlockedItem()
    var
        Item: Record Item;
        ErrorMessageRegister: Record "Error Message Register";
        FromPurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ToPurchaseHeader: Record "Purchase Header";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ErrorMessagesPage: TestPage "Error Messages";
        RegisterID: Guid;
    begin
        // [FEATURE] [Purchase] [Item]
        // [SCENARIO] "Copy Document" skips document lines, where the item is blocked
        Initialize();

        // [GIVEN] An Item 'X' is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Purchase Quote is created
        LibraryPurchase.CreatePurchaseQuote(FromPurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, FromPurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);

        // [GIVEN] Targer Purchase Order '1001' is created
        LibraryPurchase.CreatePurchaseOrder(ToPurchaseHeader);

        // [GIVEN] Item's Attribute "Blocked" is changed to TRUE
        Item.Validate(Blocked, true);
        Item.Modify(true);

        // [WHEN] Copy Purchase Document
        ErrorMessagesPage.Trap();
        CopyDocumentMgt.SetProperties(true, false, false, false, false, false, false);
        CopyDocumentMgt.CopyPurchDoc("Sales Document Type From"::Quote, FromPurchaseHeader."No.", ToPurchaseHeader);

        // [THEN] Notification: "An error or warning occured during operation Copying purchase document."
        Assert.AreEqual(
          StrSubstNo(NotificationMsg, StrSubstNo(PurchErrorContextMsg, FromPurchaseHeader."No.")),
          LibraryVariableStorage.DequeueText(), 'wrong notification message');
        Assert.IsTrue(Evaluate(RegisterID, LibraryVariableStorage.DequeueText()), 'register id evaluation');
        Assert.IsFalse(IsNullGuid(RegisterID), 'register id is null');
        // [THEN] On action 'Show skipped items' see the Item List with one item 'X'
        ErrorMessagesPage.Source.AssertEquals(Item.RecordId);
        Assert.IsFalse(ErrorMessagesPage.Next(), 'should be one line in the item list');
        // [THEN] Adedd line to Error Message Register, where "Description" is 'Copying purchase document 1001', "Errors" is 0, "Warnings" is 1.
        ErrorMessageRegister.Get(RegisterID);
        ErrorMessageRegister.CalcFields(Errors, Warnings);
        ErrorMessageRegister.TestField(Errors, 0);
        ErrorMessageRegister.TestField(Warnings, 1);
        Assert.AreEqual(
          StrSubstNo(PurchErrorContextMsg, FromPurchaseHeader."No."), ErrorMessageRegister."Message", 'Register.Description');

        LibraryNotificationMgt.RecallNotificationsForRecord(ToPurchaseHeader);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Scope('OnPrem')]
    procedure Initialize()
    var
        NamedForwardLink: Record "Named Forward Link";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Skipped Document Lines");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Skipped Document Lines");

        NamedForwardLink.Load();
        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Skipped Document Lines");
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure ShowErrorsNotificationHandler(var SentNotification: Notification): Boolean
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        LibraryVariableStorage.Enqueue(SentNotification.Message);
        LibraryVariableStorage.Enqueue(SentNotification.GetData('RegisterID'));
        ErrorMessageMgt.ShowErrors(SentNotification);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

