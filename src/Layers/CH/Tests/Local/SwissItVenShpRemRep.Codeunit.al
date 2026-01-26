codeunit 144021 "Swiss  It. Ven. Shp. Rem. Rep."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryCH: Codeunit "Library - CH";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('VendorShippingReminderReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorShippingReminderReportOnlyDueDates()
    begin
        TestItemVendorShippingReminderReport(true);
    end;

    [Test]
    [HandlerFunctions('VendorShippingReminderReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorShippingReminderReportNoDueDates()
    begin
        TestItemVendorShippingReminderReport(false);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorShippingReminderReportRequestPageHandler(var RequestPageHandler: TestRequestPage "SR Item Vendor Shipping Rem.")
    var
        OnlyDueEntries: Variant;
    begin
        LibraryVariableStorage.Dequeue(OnlyDueEntries);
        RequestPageHandler.KeyDate.SetValue(WorkDate());
        RequestPageHandler.OnlyDueEntries.SetValue(OnlyDueEntries);
        RequestPageHandler.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Swiss  It. Ven. Shp. Rem. Rep.");
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Swiss  It. Ven. Shp. Rem. Rep.");

        UpdatePurchasesPayablesSetup();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Swiss  It. Ven. Shp. Rem. Rep.");
    end;

    local procedure UpdatePurchasesPayablesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchasesPayablesSetup.Validate("Allow VAT Difference", true);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure TestItemVendorShippingReminderReport(OnlyDueEntries: Boolean)
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        VendorToFilter: Record Vendor;
    begin
        Initialize();

        LibraryVariableStorage.Enqueue(OnlyDueEntries);

        // Setup PostingSetup and VAT PostingSetup.
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // Create a new item.
        LibraryInventory.CreateItem(Item);

        // Create a new vendor
        LibraryCH.CreateVendor(Vendor, GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        // Create header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // Create line.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader,
          PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));

        // Make it old.
        if OnlyDueEntries then
            PurchaseLine.Validate("Expected Receipt Date", WorkDate() - 2);

        PurchaseLine.Modify(true);

        Commit();
        VendorToFilter.SetRange("No.", Vendor."No.");
        REPORT.Run(REPORT::"SR Item Vendor Shipping Rem.", true, false, VendorToFilter);

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals('No_Vendor', Vendor."No.");

        if OnlyDueEntries then
            LibraryReportDataset.AssertCurrentRowValueEquals('Due', '*');
    end;
}

