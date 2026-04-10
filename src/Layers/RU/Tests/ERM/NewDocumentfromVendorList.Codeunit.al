codeunit 134773 "New Document from Vendor List"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Vendor] [UI]
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseInvoiceFromVendor()
    var
        Vendor: Record Vendor;
        DummyPurchaseHeader: Record "Purchase Header";
        VendorList: TestPage "Vendor List";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // Setup
        Initialize();
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // Execute
        VendorList.OpenEdit();
        VendorList.GotoRecord(Vendor);

        PurchaseInvoice.Trap();
        VendorList.NewPurchaseInvoice.Invoke();

        // Verification
        VerifyBillToAddressOnPurchaseInvoiceIsVendorAddress(PurchaseInvoice, Vendor);

        PurchaseInvoice."Vendor Invoice No.".SetValue(
          LibraryUtility.GenerateRandomText(MaxStrLen(DummyPurchaseHeader."Vendor Invoice No.")));
        PurchaseInvoice.Close();

        // Execute
        PurchaseInvoice.Trap();
        VendorList.NewPurchaseInvoice.Invoke();

        // Verification
        VerifyBillToAddressOnPurchaseInvoiceIsVendorAddress(PurchaseInvoice, Vendor);
    end;

    local procedure VerifyBillToAddressOnPurchaseInvoiceIsVendorAddress(PurchaseInvoice: TestPage "Purchase Invoice"; Vendor: Record Vendor)
    begin
        PurchaseInvoice."Buy-from Vendor Name".AssertEquals(Vendor.Name);
        PurchaseInvoice."Buy-from Address".AssertEquals(Vendor.Address);
        PurchaseInvoice."Buy-from Post Code".AssertEquals(Vendor."Post Code");
        PurchaseInvoice."Buy-from Contact".AssertEquals(Vendor.Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseCreditMemoFromVendor()
    var
        Vendor: Record Vendor;
        DummyPurchaseHeader: Record "Purchase Header";
        VendorList: TestPage "Vendor List";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // Setup
        Initialize();
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // Execute
        VendorList.OpenEdit();
        VendorList.GotoRecord(Vendor);

        PurchaseCreditMemo.Trap();
        VendorList.NewPurchaseCrMemo.Invoke();

        // Verification
        VerifyBillToAddressOnPurchaseCreditMemoIsVendorAddress(PurchaseCreditMemo, Vendor);

        PurchaseCreditMemo."Vendor Cr. Memo No.".SetValue(
          LibraryUtility.GenerateRandomText(MaxStrLen(DummyPurchaseHeader."Vendor Cr. Memo No.")));
        PurchaseCreditMemo.Close();

        // Execute
        PurchaseCreditMemo.Trap();
        VendorList.NewPurchaseCrMemo.Invoke();

        // Verification
        VerifyBillToAddressOnPurchaseCreditMemoIsVendorAddress(PurchaseCreditMemo, Vendor);
    end;

    local procedure Initialize()
    var
        NoSeries: Record "No. Series";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"New Document from Vendor List");

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"New Document from Vendor List");

        NoSeries.Get('PUR-13');
        NoSeries."Manual Nos." := false;
        NoSeries.Modify();
        NoSeries.Get('PUR-16');
        NoSeries."Manual Nos." := false;
        NoSeries.Modify();

        Commit();
        isInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"New Document from Vendor List");
    end;

    local procedure VerifyBillToAddressOnPurchaseCreditMemoIsVendorAddress(PurchaseCreditMemo: TestPage "Purchase Credit Memo"; Vendor: Record Vendor)
    begin
        PurchaseCreditMemo."Buy-from Vendor Name".AssertEquals(Vendor.Name);
        PurchaseCreditMemo."Buy-from Address".AssertEquals(Vendor.Address);
        PurchaseCreditMemo."Buy-from Post Code".AssertEquals(Vendor."Post Code");
        PurchaseCreditMemo."Buy-from Contact".AssertEquals(Vendor.Contact);
    end;
}

