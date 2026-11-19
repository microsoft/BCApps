codeunit 134836 "Test Vendor Lookup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Find Vendor] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryPurchase: Codeunit "Library - Purchase";
        isInitialized: Boolean;
        SelectVendErr: Label 'You must select an existing vendor.';
        PurchaseOrderChangedErr: Label 'Changing the vendor on one purchase order must not change the next order in the filtered view.';

    local procedure Initialize()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        InventorySetup: Record "Inventory Setup";
        PurchaseHeader: Record "Purchase Header";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Vendor Lookup");
        LibraryVariableStorage.Clear();

        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Vendor);
        ConfigTemplateHeader.DeleteAll(true);
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Vendor Lookup");

        LibraryERMCountryData.CreateVATData();

        InventorySetup.Get();
        InventorySetup."Automatic Cost Posting" := false;
        InventorySetup.Modify();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Vendor Lookup");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExistingVend()
    var
        Vend: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        Initialize();

        CreateVend(Vend);

        // Exercise: Select existing Vend.
        PurchaseQuote.OpenNew();
        PurchaseQuote."Buy-from Vendor Name".SetValue(Vend.Name);

        // Verify.
        VerifyPurchQuoteAgainstVend(PurchaseQuote, Vend);
        VerifyPurchQuoteAgainstBillToVend(PurchaseQuote, Vend);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UpdateVendNameWithExistingVendName()
    var
        Vend1: Record Vendor;
        Vend: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        Initialize();
        CreateVend(Vend);
        CreateVend(Vend1);

        // Exercise: Select existing Vend.
        PurchaseQuote.OpenNew();
        PurchaseQuote.PurchLines.First();
        PurchaseQuote."Buy-from Vendor Name".SetValue(Vend.Name);
        PurchaseQuote."Buy-from Vendor Name".SetValue(Vend1.Name);

        // Verify.
        VerifyPurchQuoteAgainstVend(PurchaseQuote, Vend1);
    end;

    [Test]
    [HandlerFunctions('VendorLookupPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ChangingVendorOnFilteredPurchaseOrderDoesNotChangeNextOrder()
    var
        OriginalVendor: Record Vendor;
        ReplacementVendor: Record Vendor;
        FirstPurchaseHeader: Record "Purchase Header";
        NextPurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();
        CreateVend(OriginalVendor);
        CreateVend(ReplacementVendor);
        LibraryPurchase.CreatePurchHeader(FirstPurchaseHeader, FirstPurchaseHeader."Document Type"::Order, OriginalVendor."No.");
        LibraryPurchase.CreatePurchHeader(NextPurchaseHeader, NextPurchaseHeader."Document Type"::Order, OriginalVendor."No.");

        // Exercise: Select a replacement vendor on the first order while the card is filtered to the original vendor.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("Buy-from Vendor No.", OriginalVendor."No.");
        PurchaseOrder.GotoRecord(FirstPurchaseHeader);
        LibraryVariableStorage.Enqueue(ReplacementVendor."No.");
        PurchaseOrder."Buy-from Vendor Name".Lookup();
        PurchaseOrder.Close();

        // Verify: The selected order changes vendor, but the next order remains with its original vendor.
        FirstPurchaseHeader.Get(FirstPurchaseHeader."Document Type"::Order, FirstPurchaseHeader."No.");
        NextPurchaseHeader.Get(NextPurchaseHeader."Document Type"::Order, NextPurchaseHeader."No.");
        Assert.AreEqual(ReplacementVendor."No.", FirstPurchaseHeader."Buy-from Vendor No.", PurchaseOrderChangedErr);
        Assert.AreEqual(ReplacementVendor."No.", FirstPurchaseHeader."Pay-to Vendor No.", PurchaseOrderChangedErr);
        Assert.AreEqual(OriginalVendor."No.", NextPurchaseHeader."Buy-from Vendor No.", PurchaseOrderChangedErr);
        Assert.AreEqual(OriginalVendor."No.", NextPurchaseHeader."Pay-to Vendor No.", PurchaseOrderChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewVendExpectError()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        PurchaseQuote: TestPage "Purchase Quote";
        VendName: Text[50];
    begin
        Initialize();

        LibrarySmallBusiness.CreateVendorTemplate(ConfigTemplateHeader);

        // Exercise.
        VendName := CopyStr(Format(CreateGuid()), 1, 50);

        PurchaseQuote.OpenNew();
        PurchaseQuote.PurchLines.First();

        // Verify
        asserterror PurchaseQuote."Buy-from Vendor Name".SetValue(VendName);
    end;

    [Test]
    [HandlerFunctions('VendListPageHandler')]
    [Scope('OnPrem')]
    procedure VendorsWithSameName()
    var
        Vend: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        Initialize();

        CreateTwoVendorsSameName(Vend);

        // Exercise: Select existing Vend - second one in the page handler
        LibraryVariableStorage.Enqueue(Vend.Name); // for the Vend list page handler
        PurchaseQuote.OpenNew();
        PurchaseQuote."Buy-from Vendor Name".SetValue(CopyStr(Vend.Name, 2, StrLen(Vend.Name) - 1));

        // Verify.
        VerifyPurchQuoteAgainstVend(PurchaseQuote, Vend);
    end;

    [Test]
    [HandlerFunctions('VendListCancelPageHandler')]
    [Scope('OnPrem')]
    procedure VendorsWithSameNameCancelSelect()
    var
        Vend: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        Initialize();

        CreateTwoVendorsSameName(Vend);

        // Exercise: Select existing Vend - second one in the page handler
        LibraryVariableStorage.Enqueue(Vend.Name); // for the Vend list page handler
        PurchaseQuote.OpenNew();
        asserterror PurchaseQuote."Buy-from Vendor Name".SetValue(CopyStr(Vend.Name, 2, StrLen(Vend.Name) - 1));
        Assert.ExpectedError(SelectVendErr);
    end;

    local procedure CreateTwoVendorsSameName(var Vend: Record Vendor)
    var
        Vend1: Record Vendor;
    begin
        CreateVend(Vend1);
        CreateVend(Vend);
        Vend.Validate(Name, Vend1.Name);
        Vend.Modify(true);
    end;

    local procedure VerifyPurchQuoteAgainstVend(PurchaseQuote: TestPage "Purchase Quote"; Vend: Record Vendor)
    begin
        PurchaseQuote."Buy-from Vendor Name".AssertEquals(Vend.Name);
        PurchaseQuote."Buy-from Address".AssertEquals(Vend.Address);
        PurchaseQuote."Buy-from City".AssertEquals(Vend.City);
        PurchaseQuote."Buy-from Post Code".AssertEquals(Vend."Post Code");
    end;

    local procedure VerifyPurchQuoteAgainstBillToVend(PurchaseQuote: TestPage "Purchase Quote"; Vend: Record Vendor)
    begin
        PurchaseQuote."Pay-to Name".AssertEquals(Vend.Name);
        PurchaseQuote."Pay-to Address".AssertEquals(Vend.Address);
        PurchaseQuote."Pay-to City".AssertEquals(Vend.City);
        PurchaseQuote."Pay-to Post Code".AssertEquals(Vend."Post Code");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendListPageHandler(var VendorList: TestPage "Vendor List")
    var
        VendName: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendName);
        VendorList.FILTER.SetFilter(Name, VendName);
        VendorList.Last();
        VendorList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorLookupPageHandler(var VendorLookup: TestPage "Vendor Lookup")
    begin
        VendorLookup.GotoKey(LibraryVariableStorage.DequeueText());
        VendorLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendListCancelPageHandler(var VendorList: TestPage "Vendor List")
    begin
        VendorList.Cancel().Invoke();
    end;

    local procedure CreateVend(var Vend: Record Vendor)
    begin
        LibrarySmallBusiness.CreateVendor(Vend);

        Vend.Validate(Name, LibraryUtility.GenerateRandomCode(Vend.FieldNo(Name), DATABASE::Vendor));
        Vend.Validate(City, LibraryUtility.GenerateRandomCode(Vend.FieldNo(City), DATABASE::Vendor));
        Vend.Validate(Address, LibraryUtility.GenerateRandomCode(Vend.FieldNo(Address), DATABASE::Vendor));
        Vend.Validate("Address 2", LibraryUtility.GenerateRandomCode(Vend.FieldNo("Address 2"), DATABASE::Vendor));
        Vend.Validate("Post Code", LibraryUtility.GenerateRandomCode(Vend.FieldNo("Post Code"), DATABASE::Vendor));
        Vend.Modify();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
