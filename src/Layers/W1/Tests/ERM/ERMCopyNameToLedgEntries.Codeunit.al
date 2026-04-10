codeunit 134985 "ERM Copy Name To Ledg. Entries"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Copy Name To Ledger Entries]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        CustNamesUpdateMsg: Label '%1 customer ledger entries with empty Customer Name field were found. Do you want to update these entries by inserting the name from the customer cards?', Comment = '%1 = number of entries';
        VendNamesUpdateMsg: Label '%1 vendor ledger entries with empty Vendor Name field were found. Do you want to update these entries by inserting the name from the vendor cards?', Comment = '%1 = number of entries';
        ItemDescrUpdateMsg: Label '%1 ledger entries with empty Description field were found. Do you want to update these entries by inserting the description from the item cards?', Comment = '%1 = number of entries';
        ItemDescriptionWarehouseEntriesUpdateMsg: Label '%1 warehouse entries with empty Description field were found. Do you want to update these entries by inserting the description from the item cards?', Comment = '%1 = number of entries, %2 - Table Caption';
        ParameterNotSupportedErr: Label 'The Parameter String field must contain 18 for ''Customer'', 23 for ''Vendor'', or 27 for ''Item''. The current value ''%1'' is not supported.', Comment = '%1 - any text value';
        CustomerJobQueueDescrTxt: Label 'Update customer name in customer ledger entries.';
        ItemJobQueueDescrTxt: Label 'Update item name in item ledger entries.';
        WarehouseDescriptionJobQueueTxt: Label 'Update item name in warehouse entries.';
        VendorJobQueueDescrTxt: Label 'Update vendor name in vendor ledger entries.';
        GlobalTaskID: Guid;

    [Test]
    [Scope('OnPrem')]
    procedure T001_RunUpdateUnsupportedType()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [UT]
        JobQueueEntry."Parameter String" := 'x';
        asserterror CODEUNIT.Run(CODEUNIT::"Update Name In Ledger Entries", JobQueueEntry);
        Assert.ExpectedError(StrSubstNo(ParameterNotSupportedErr, JobQueueEntry."Parameter String"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T100_PostIfCopyCustNameToLedgerEntriesIsNo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Posting]
        // [SCENARIO 303270] "Customer Name" is blank in customer ledger entry if "Copy Customer Name to Entries" is 'No'
        Initialize();

        // [GIVEN] Purchase setup field "Copy Customer Name to Entries" set to 'No' (default)
        SetCopyCustNameToLedgerEntriesSilent(false);

        // [GIVEN] Create new sales invoice
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");

        // [WHEN] Post sales invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Check that name in customer ledger entries is blank
        VerifyCustLedgEntryDescription(Customer."No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T101_PostIfCopyCustNameToLedgerEntriesIsYes()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Posting]
        // [SCENARIO 303270] "Customer Name" in customer ledger entry gets customer's name if "Copy Customer Name to Entries" is 'Yes'
        Initialize();

        // [GIVEN] Inventory setup field "Copy Customer Name Entries" set to 'Yes'
        SetCopyCustNameToLedgerEntriesSilent(true);

        // [GIVEN] Create new sales invoice for customer, where "Name" is 'X'
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");

        // [WHEN] Post sales invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Check that name in customer ledger entries is 'X'
        VerifyCustLedgEntryDescription(Customer."No.", Customer.Name);
    end;

    [Test]
    [HandlerFunctions('SentNotificationScheduleHandler,ScheduleAJobModalPageHandler')]
    [Scope('OnPrem')]
    procedure T150_UpdateCustNameToLedgerEntriesFromSetup()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesSetup: Record "Sales & Receivables Setup";
        ERMCopyNameToLedgEntries: Codeunit "ERM Copy Name To Ledg. Entries";
        ExpectedTaskID: Guid;
    begin
        // [FEATURE] [Sales] [Setup]
        // [SCENARIO 303270] Fill blank "Customer Name" in ledger entries if "Copy Customer Name Entries" changed to 'Yes'
        Initialize();

        // [GIVEN] Setup field "Copy Customer Name Entries" set to 'No'
        SetCopyCustNameToLedgerEntries(false);

        // [GIVEN] Posted 2 sales invoices for customer, which "Name" is 'X'
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Check that name in customer ledger entries is blank
        VerifyCustLedgEntryDescription(Customer."No.", '');

        // [WHEN] Setup field "Copy Customer Name Entries" set to 'Yes'
        ExpectedTaskID := MockJobScheduling(ERMCopyNameToLedgEntries);
        SetCopyCustNameToLedgerEntries(true);

        // [THEN] Notification: '2 customer ledger entry with empty Customer Name found.'
        Assert.ExpectedMessage(StrSubstNo(CustNamesUpdateMsg, 2), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);

        // [WHEN] Run action 'Schedule Update'
        // [THEN] Open modal page "Schedule a Report", where Description is not enabled, "Earliest Start Date/Time" is <blank> and editable
        VerifyScheduleAJobPage(CustomerJobQueueDescrTxt);
        // [WHEN] Push 'OK'
        // by ScheduleAJobModalPageHandler
        // [THEN] Job Queue Entry is executed
        Assert.IsTrue(RunJobQueueEntry(ExpectedTaskID), 'Job Queue Entry does not exist');
        LibraryVariableStorage.AssertEmpty();
        // [THEN] Check that name in customer ledger entries is 'X'
        VerifyCustLedgEntryDescription(Customer."No.", Customer.Name);
    end;

    [Test]
    [HandlerFunctions('SentNotificationScheduleHandler,OKScheduleAJobModalPageHandler')]
    [Scope('OnPrem')]
    procedure T155_UpdateCustNameToLedgerEntriesFromSetupSchedule()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesSetup: Record "Sales & Receivables Setup";
        ERMCopyNameToLedgEntries: Codeunit "ERM Copy Name To Ledg. Entries";
        ExpectedTaskID: Guid;
    begin
        // [FEATURE] [Sales] [Setup]
        // [SCENARIO 303270] Create job queue entry for filling blank "Customer Name" if "Copy Customer Name Entries" changed to 'Yes'
        Initialize();
        // [GIVEN] Setup field "Copy Customer Name Entries" set to 'No'
        SetCopyCustNameToLedgerEntries(false);

        // [GIVEN] Create new sales invoice for customer, where "Name" is 'X'
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");

        // [WHEN] Post sales invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Check that name in customer ledger entries is blank
        VerifyCustLedgEntryDescription(Customer."No.", '');

        // [WHEN] Setup field "Copy Customer Name Entries" set to 'Yes'
        ExpectedTaskID := MockJobScheduling(ERMCopyNameToLedgEntries);
        SetCopyCustNameToLedgerEntries(true);

        // [THEN] Notification: '1 customer ledger entry with empty Customer Name found.'
        Assert.ExpectedMessage(StrSubstNo(CustNamesUpdateMsg, 1), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        // [THEN] Check that name in customer ledger entries is still blank
        VerifyCustLedgEntryDescription(Customer."No.", '');

        // [WHEN] Run notification action 'Schedule'
        // by SentNotificationScheduleHandler

        // [THEN] Open modal page "Schedule a Report", where set "Earliest Start Date/Time" as '05.05.19 13:00' and push OK
        // [THEN] Job Queue Entry is executed,where "Object ID to Run" is Codeunit 104,
        // [THEN] "Parameter String" is '18', "Earliest Start Date/Time" is '05.05.19 13:00'
        VerifyScheduledJobQueueEntryPage(ExpectedTaskID, '18', CustomerJobQueueDescrTxt);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SentNotificationScheduleHandler,CancelScheduleAJobModalPageHandler')]
    [Scope('OnPrem')]
    procedure T156_UpdateCustNameToLedgerEntriesFromSetupCancelSchedule()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesSetup: Record "Sales & Receivables Setup";
        ERMCopyNameToLedgEntries: Codeunit "ERM Copy Name To Ledg. Entries";
        ExpectedTaskID: Guid;
    begin
        // [FEATURE] [Sales] [Setup]
        // [SCENARIO 303270] Job queue entry is not created if scheduling cancelled
        Initialize();
        // [GIVEN] Setup field "Copy Customer Name Entries" set to 'No'
        SetCopyCustNameToLedgerEntries(false);

        // [GIVEN] Create new sales invoice for customer, where "Name" is 'X'
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");

        // [WHEN] Post sales invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Check that name in customer ledger entries is blank
        VerifyCustLedgEntryDescription(Customer."No.", '');

        // [WHEN] Setup field "Copy Customer Name Entries" set to 'Yes'
        ExpectedTaskID := MockJobScheduling(ERMCopyNameToLedgEntries);
        SetCopyCustNameToLedgerEntries(true);

        // [THEN] Notification: '1 customer ledger entry with empty Customer Name found.'
        Assert.ExpectedMessage(StrSubstNo(CustNamesUpdateMsg, 1), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
        // [THEN] Check that name in customer ledger entries is still blank
        VerifyCustLedgEntryDescription(Customer."No.", '');

        // [WHEN] Run notification action 'Schedule' but then "Cancel" in "Schedule A Report" page
        // by SentNotificationScheduleHandler and CancelScheduleAJobModalPageHandler

        // [THEN] Job Queue Entry is not created
        Assert.IsFalse(RunJobQueueEntry(ExpectedTaskID), 'Job Queue Entry must not exist');
        LibraryVariableStorage.AssertEmpty();
        // [THEN] Check that name in customer ledger entries is blank
        VerifyCustLedgEntryDescription(Customer."No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T160_UpdateCustNameToLedgerEntriesFromSetupAllFilled()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Setup]
        // [SCENARIO 303270] "Copy Customer Name Entries" changed to 'Yes' does nothing if all "Customer Name" in ledger entries are filled
        Initialize();
        // [GIVEN] All ledger entries have "Customer Name"
        CustLedgerEntry.SetFilter("Customer No.", '<>''''');
        CustLedgerEntry.SetRange("Customer Name", '');
        Assert.RecordIsEmpty(CustLedgerEntry);

        // [WHEN] Setup field "Copy Customer Name Entries" set to 'Yes'
        SetCopyCustNameToLedgerEntries(true);

        // [THEN] Notification is not shown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T200_PostIfCopyVendNameToLedgerEntriesIsNo()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Posting]
        // [SCENARIO 303270] "Vendor Name" is blank in vendor ledger entry if "Copy Vendor Name to Entries" is 'No'
        Initialize();

        // [GIVEN] Purchase setup field "Copy Vendor Name to Entries" set to 'No' (default)
        SetCopyVendNameToLedgerEntriesSilent(false);

        // [GIVEN] Create new purchase invoice for vendor
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Check that description in vendor ledger entries is blank
        VerifyVendLedgEntryDescription(Vendor."No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T201_PostIfCopyVendNameToLedgerEntriesIsYes()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Posting]
        // [SCENARIO 303270] "Vendor Name" in vendor ledger entry gets vendor's name if "Copy Vendor Name to Entries" is 'Yes'
        Initialize();

        // [GIVEN] Inventory setup field "Copy Vendor Name Entries" set to 'Yes'
        SetCopyVendNameToLedgerEntriesSilent(true);

        // [GIVEN] Create new purchase invoice for vendor, where "Name" is 'X'
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Check that description in vendor ledger entries is 'X'
        VerifyVendLedgEntryDescription(Vendor."No.", Vendor.Name);
    end;

    [Test]
    [HandlerFunctions('SentNotificationScheduleHandler,ScheduleAJobModalPageHandler')]
    [Scope('OnPrem')]
    procedure T250_UpdateVendNameToLedgerEntriesFromSetup()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchSetup: Record "Purchases & Payables Setup";
        ERMCopyNameToLedgEntries: Codeunit "ERM Copy Name To Ledg. Entries";
        ExpectedTaskID: Guid;
    begin
        // [FEATURE] [Purchase] [Setup]
        // [SCENARIO 303270] Fill blank "Vendor Name" in ledger entries if "Copy Vendor Name Entries" changed to 'Yes'
        Initialize();
        // [GIVEN] Setup field "Copy Vendor Name Entries" set to 'No'
        SetCopyVendNameToLedgerEntries(false);

        // [GIVEN] Posted 2 purchase invoices for vendor, which "Name" is 'X'
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Check that name in vendor ledger entries is blank
        VerifyVendLedgEntryDescription(Vendor."No.", '');

        // [WHEN] Setup field "Copy Vendor Name Entries" set to 'Yes'
        ExpectedTaskID := MockJobScheduling(ERMCopyNameToLedgEntries);
        SetCopyVendNameToLedgerEntries(true);

        // [THEN] Notification: '2 vendor ledger entries with empty Vendor Name found.'
        Assert.ExpectedMessage(StrSubstNo(VendNamesUpdateMsg, 2), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);

        // [WHEN] Run action 'Schedule Update'
        // [THEN] Open modal page "Schedule a Report", where Description is not enabled, "Earliest Start Date/Time" is <blank> and editable
        VerifyScheduleAJobPage(VendorJobQueueDescrTxt);
        // [WHEN] Push 'OK'
        // by ScheduleAJobModalPageHandler
        // [THEN] Job Queue Entry is executed
        Assert.IsTrue(RunJobQueueEntry(ExpectedTaskID), 'Job Queue Entry does not exist');
        LibraryVariableStorage.AssertEmpty();
        // [THEN] Check that name in vendor ledger entries is 'X'
        VerifyVendLedgEntryDescription(Vendor."No.", Vendor.Name);
    end;

    [Test]
    [HandlerFunctions('SentNotificationScheduleHandler,OKScheduleAJobModalPageHandler')]
    [Scope('OnPrem')]
    procedure T255_UpdateVendNameToLedgerEntriesFromSetupSchedule()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchSetup: Record "Purchases & Payables Setup";
        ERMCopyNameToLedgEntries: Codeunit "ERM Copy Name To Ledg. Entries";
        ExpectedTaskID: Guid;
    begin
        // [FEATURE] [Purchase] [Setup]
        // [SCENARIO 303270] Create job queue entry for filling blank "Vendor Name" if "Copy Vendor Name Entries" changed to 'Yes'
        Initialize();
        // [GIVEN] Setup field "Copy Vendor Name Entries" set to 'No'
        SetCopyVendNameToLedgerEntries(false);

        // [GIVEN] Create new purchase invoice
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Check that name in vendor ledger entries is blank
        VerifyVendLedgEntryDescription(Vendor."No.", '');

        // [WHEN] Setup field "Copy Vendor Name Entries" set to 'Yes'
        ExpectedTaskID := MockJobScheduling(ERMCopyNameToLedgEntries);
        SetCopyVendNameToLedgerEntries(true);

        // [THEN] Notification: '1 vendor ledger entry with empty Vendor Name found.'
        Assert.ExpectedMessage(StrSubstNo(VendNamesUpdateMsg, 1), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
        // [THEN] Check that name in vendor ledger entries is still blank
        VerifyVendLedgEntryDescription(Vendor."No.", '');

        // [WHEN] Run notification action 'Schedule'
        // by SentNotificationScheduleHandler

        // [THEN] Open modal page "Schedule a Report", where set "Earliest Start Date/Time" as '05.05.19 13:00' and push OK
        // [THEN] Job Queue Entry is executed, where "Object ID to Run" is Codeunit 104,
        // [THEN] "Parameter String" is '23', "Earliest Start Date/Time" is '05.05.19 13:00'
        VerifyScheduledJobQueueEntryPage(ExpectedTaskID, '23', VendorJobQueueDescrTxt);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SentNotificationScheduleHandler,CancelScheduleAJobModalPageHandler')]
    [Scope('OnPrem')]
    procedure T256_UpdateVendNameToLedgerEntriesFromSetupCancelSchedule()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchSetup: Record "Purchases & Payables Setup";
        ERMCopyNameToLedgEntries: Codeunit "ERM Copy Name To Ledg. Entries";
        ExpectedTaskID: Guid;
    begin
        // [FEATURE] [Purchase] [Setup]
        // [SCENARIO 303270] Job queue entry is not created if scheduling cancelled
        Initialize();
        // [GIVEN] Setup field "Copy Vendor Name Entries" set to 'No'
        SetCopyVendNameToLedgerEntries(false);

        // [GIVEN] Create new purchase invoice
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Check that name in vendor ledger entries is blank
        VerifyVendLedgEntryDescription(Vendor."No.", '');

        // [WHEN] Setup field "Copy Vendor Name Entries" set to 'Yes'
        ExpectedTaskID := MockJobScheduling(ERMCopyNameToLedgEntries);
        SetCopyVendNameToLedgerEntries(true);

        // [THEN] Notification: '1 vendor ledger entry with empty Vendor Name found.'
        Assert.ExpectedMessage(StrSubstNo(VendNamesUpdateMsg, 1), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
        // [THEN] Check that name in vendor ledger entries is still blank
        VerifyVendLedgEntryDescription(Vendor."No.", '');

        // [WHEN] Run notification action 'Schedule' but then "Cancel" in "Schedule A Report" page
        // by SentNotificationScheduleHandler and CancelScheduleAJobModalPageHandler

        // [THEN] Job Queue Entry is not created
        Assert.IsFalse(RunJobQueueEntry(ExpectedTaskID), 'Job Queue Entry must not exist');
        LibraryVariableStorage.AssertEmpty();
        // [THEN] Check that name in vendor ledger entries is still blank
        VerifyVendLedgEntryDescription(Vendor."No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T260_UpdateVendNameToLedgerEntriesFromSetupAllFilled()
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Setup]
        // [SCENARIO 303270] "Copy Vendor Name Entries" changed to 'Yes' does nothing if all "Vendor Name" in ledger entries are filled
        Initialize();
        VendLedgerEntry.SetFilter("Vendor No.", '<>''''');
        VendLedgerEntry.SetRange("Vendor Name", '');
        Assert.RecordIsEmpty(VendLedgerEntry);

        // [WHEN] Setup field "Copy Vendor Name Entries" set to 'Yes'
        SetCopyVendNameToLedgerEntries(true);

        // [THEN] Notification is not shown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T300_PostIfCopyItemDescriptionToLedgerEntriesIsNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Inventory] [Posting]
        // [SCENARIO 303271] "Description" is blank in item ledger entry if "Copy Item Descr. to Entries" is 'No'

        Initialize();

        // [GIVEN] Inventory setup field "Copy Item Descr. to Entries" set to 'No'
        SetCopyItemDescrToLedgerEntriesSilent(false);

        // [GIVEN] Create purchase invoice with new item 'X'
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, '', Item."No.", 1, '', 0D);

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Check that description in item and value ledger entries is blank
        VerifyItemLedgEntryDescription(Item."No.", '', '');
        VerifyValueEntryDescription(Item."No.", '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T301_PostIfCopyItemDescriptionToLedgerEntriesIsYes()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Inventory] [Posting]
        // [SCENARIO 303271] "Description" in item ledger entry gets item's description if "Copy Item Descr. to Entries" is 'Yes'
        Initialize();

        // [GIVEN] Inventory setup field "Copy Item Descr. to Entries" set to 'Yes'
        SetCopyItemDescrToLedgerEntriesSilent(true);

        // [GIVEN] Create purchase invoice with new item 'X'
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, '', Item."No.", 1, '', 0D);

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Check that description in item and value ledger entries fro Item are 'X'
        VerifyItemLedgEntryDescription(Item."No.", '', Item.Description);
        VerifyValueEntryDescription(Item."No.", '', Item.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T302_PostIfCopyItemVariantDescriptionToLedgerEntriesIsYes()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Inventory] [Variant] [Posting]
        // [SCENARIO 303271] "Description" in item ledger entry gets item variant's description if "Copy Item Descr. to Entries" is 'Yes'
        Initialize();

        // [GIVEN] Inventory setup field "Copy Item Descr. to Entries" set to 'Yes'
        SetCopyItemDescrToLedgerEntriesSilent(true);

        // [GIVEN] Create purchase invoice with item variant 'Y' for item 'X'
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, '', Item."No.", 1, '', 0D);
        PurchaseLine.Validate("Variant Code", ItemVariant.Code);
        PurchaseLine.Modify(true);

        // [WHEN] Post purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Check that description in item and value ledger entries for Item Variant are 'Y'
        VerifyItemLedgEntryDescription(Item."No.", ItemVariant.Code, ItemVariant.Description);
        VerifyValueEntryDescription(Item."No.", ItemVariant.Code, ItemVariant.Description);
    end;

    [Test]
    [HandlerFunctions('SentNotificationScheduleHandler,ScheduleAJobModalPageHandler')]
    [Scope('OnPrem')]
    procedure T350_UpdateCopyItemDescrToLedgerEntriesFromSetup()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        ERMCopyNameToLedgEntries: Codeunit "ERM Copy Name To Ledg. Entries";
        ExpectedTaskID: Guid;
    begin
        // [FEATURE] [Inventory] [Setup]
        // [SCENARIO 303271] Fill blank "Description" in ledger entries if "Copy Item Descr. To Entries" changed to 'Yes'
        Initialize();
        // [GIVEN] Item 'X'
        // [GIVEN] There are Item Ledger Entries, Value Entries and Phys. Inv. Ledger Entries, where Description is <blank>
        CreateItemWithEntries(Item);

        // [WHEN] Inventory setup field "Copy Item Descr. to Entries" set to 'Yes'
        ExpectedTaskID := MockJobScheduling(ERMCopyNameToLedgEntries);
        SetCopyItemDescrToLedgerEntries(true);

        // [THEN] Notification: '6 ledger entries with empty description found.'
        Assert.ExpectedMessage(StrSubstNo(ItemDescrUpdateMsg, 6), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecord(InventorySetup);

        // [WHEN] Run action 'Schedule Update'
        // [THEN] Open modal page "Schedule a Report", where Description is not enabled, "Earliest Start Date/Time" is <blank> and editable
        VerifyScheduleAJobPage(ItemJobQueueDescrTxt);
        // [WHEN] Push 'OK'
        // by ScheduleAJobModalPageHandler
        // [THEN] Job Queue Entry is executed
        Assert.IsTrue(RunJobQueueEntry(ExpectedTaskID), 'Job Queue Entry does not exist');
        LibraryVariableStorage.AssertEmpty();
        // [THEN] Check that description in ledger entries is 'X'
        VerifyItemDescriptionInEntries(Item."No.", '', Item.Description);
    end;

    [Test]
    [HandlerFunctions('SentNotificationScheduleHandler,ScheduleAJobModalPageHandler')]
    [Scope('OnPrem')]
    procedure T351_UpdateCopyItemVariantDescrToLedgerEntriesFromSetup()
    var
        ItemVariant: Record "Item Variant";
        InventorySetup: Record "Inventory Setup";
        ERMCopyNameToLedgEntries: Codeunit "ERM Copy Name To Ledg. Entries";
        ExpectedTaskID: Guid;
    begin
        // [FEATURE] [Inventory] [Variant] [Setup]
        // [SCENARIO 303271] Fill blank "Description" in ledger entries if "Copy Item Descr. To Entries" changed to 'Yes'
        Initialize();
        // [GIVEN] Item Variant 'Y' for Item 'X'
        // [GIVEN] There are Item Ledger Entries, Value Entries and Phys. Inv. Ledger Entries, where Description is <blank>
        CreateItemVariantWithEntries(ItemVariant);

        // [WHEN] Inventory setup field "Copy Item Descr. to Entries" set to 'Yes'
        ExpectedTaskID := MockJobScheduling(ERMCopyNameToLedgEntries);
        SetCopyItemDescrToLedgerEntries(true);

        // [THEN] Notification: '6 ledger entries with empty description found.'
        Assert.ExpectedMessage(StrSubstNo(ItemDescrUpdateMsg, 6), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecord(InventorySetup);
        // [WHEN] Run action 'Schedule Update'

        // [THEN] Open modal page "Schedule a Report", where Description is not enabled, "Earliest Start Date/Time" is <blank> and editable
        VerifyScheduleAJobPage(ItemJobQueueDescrTxt);
        // [WHEN] Push 'OK'
        // by ScheduleAJobModalPageHandler
        // [THEN] Job Queue Entry is executed
        Assert.IsTrue(RunJobQueueEntry(ExpectedTaskID), 'Job Queue Entry does not exist');
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Check that description in ledger entries is 'Y'
        VerifyItemDescriptionInEntries(ItemVariant."Item No.", ItemVariant.Code, ItemVariant.Description);
    end;

    [Test]
    [HandlerFunctions('SentNotificationScheduleHandler,OKScheduleAJobModalPageHandler')]
    [Scope('OnPrem')]
    procedure T355_UpdateCopyItemDescrToLedgerEntriesFromSetupSchedule()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        ERMCopyNameToLedgEntries: Codeunit "ERM Copy Name To Ledg. Entries";
        ExpectedTaskID: Guid;
    begin
        // [FEATURE] [Inventory] [Setup]
        // [SCENARIO 303271] Create job queue entry for filling blank Descrioption if "Copy Item Descr. To Entries" changed to 'Yes'
        Initialize();
        // [GIVEN] Item 'X'
        // [GIVEN] There are Item Ledger Entries, Value Entries and Phys. Inv. Ledger Entries, where Description is <blank>
        CreateItemWithEntries(Item);

        // [WHEN] Inventory setup field "Copy Item Descr. to Entries" set to 'Yes'
        ExpectedTaskID := MockJobScheduling(ERMCopyNameToLedgEntries);
        SetCopyItemDescrToLedgerEntries(true);

        // [THEN] Notification: '6 ledger entries with empty description found.'
        Assert.ExpectedMessage(StrSubstNo(ItemDescrUpdateMsg, 6), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecord(InventorySetup);
        // [THEN] Check that description in ledger entries is still blank
        VerifyItemDescriptionInEntries(Item."No.", '', '');

        // [WHEN] Run notification action 'Schedule'
        // by SentNotificationScheduleHandler

        // [THEN] Open modal page "Schedule a Report", where set "Earliest Start Date/Time" as '05.05.19 13:00' and push OK
        // [THEN] Job Queue Entry is executed, where "Object ID to Run" is Codeunit 104,
        // [THEN] "Parameter String" is '27', "Earliest Start Date/Time" is '05.05.19 13:00'
        VerifyScheduledJobQueueEntryPage(ExpectedTaskID, '27', ItemJobQueueDescrTxt);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SentNotificationScheduleHandler,CancelScheduleAJobModalPageHandler')]
    [Scope('OnPrem')]
    procedure T356_UpdateCopyItemDescrToLedgerEntriesFromSetupCancelSchedule()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        ERMCopyNameToLedgEntries: Codeunit "ERM Copy Name To Ledg. Entries";
        ExpectedTaskID: Guid;
    begin
        // [FEATURE] [Inventory] [Setup]
        // [SCENARIO 303271] Create job queue entry for filling blank Descrioption if "Copy Item Descr. To Entries" changed to 'Yes'
        Initialize();
        // [GIVEN] Item 'X'
        // [GIVEN] There are Item Ledger Entries, Value Entries and Phys. Inv. Ledger Entries, where Description is <blank>
        CreateItemWithEntries(Item);

        // [WHEN] Inventory setup field "Copy Item Descr. to Entries" set to 'Yes'
        ExpectedTaskID := MockJobScheduling(ERMCopyNameToLedgEntries);
        SetCopyItemDescrToLedgerEntries(true);

        // [THEN] Notification: '6 ledger entries with empty description found.'
        Assert.ExpectedMessage(StrSubstNo(ItemDescrUpdateMsg, 6), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecord(InventorySetup);
        // [THEN] Check that description in ledger entries is still blank
        VerifyItemDescriptionInEntries(Item."No.", '', '');

        // [WHEN] Run notification action 'Schedule' but then "Cancel" in "Schedule A Report" page
        // by SentNotificationScheduleHandler and CancelScheduleAJobModalPageHandler

        // [THEN] Job Queue Entry is not created
        Assert.IsFalse(RunJobQueueEntry(ExpectedTaskID), 'Job Queue Entry must not exist');
        LibraryVariableStorage.AssertEmpty();
        // [THEN] Check that description in ledger entries is still blank
        VerifyItemDescriptionInEntries(Item."No.", '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T360_UpdateCopyItemDescrToLedgerEntriesFromSetupAllFilled()
    begin
        // [FEATURE] [Inventory] [Setup]
        // [SCENARIO 303271] "Copy Item Descr. To Entries" changed to 'Yes' does nothing if all "Description" in ledger entries are filled
        Initialize();

        // [WHEN] Inventory setup field "Copy Item Descr. to Entries" set to 'Yes'
        SetCopyItemDescrToLedgerEntries(true);

        // [THEN] Notification is not shown
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure PostIfCopyItemDescriptionToWarehouseEntriesIsNo()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        // [FEATURE] [Warehouse] [Posting]
        // [SCENARIO] "Description" is blank in warehouse entry if "Copy Item Descr. to Entries" is 'No'
        Initialize();

        // [GIVEN] Create Item and Location
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Warehouse setup field "Copy Item Descr. to Entries" set to 'No'
        SetCopyItemDescriptionToWarehouseEntriesSilent(false);

        // [GIVEN] Create journal with new item 'X'
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, Enum::"Warehouse Journal Template Type"::Item, Location.Code);
        LibraryWarehouse.CreateWhseJournalLine(
                WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, '', '', WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDecInRange(1, 5, 2)
        );

        // [WHEN] Post warehouse journal
        LibraryWarehouse.PostWhseJournalLine(WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, '');

        // [THEN] Check that description in warehouse entries is blank
        VerifyWarehouseEntryDescription(Item."No.", '', '');
    end;

    [Test]
    procedure PostIfCopyItemDescriptionToWarehouseEntriesIsYes()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        // [FEATURE] [Warehouse] [Posting]
        // [SCENARIO] "Description" in warehouse entry gets item's description if "Copy Item Descr. to Entries" is 'Yes'
        Initialize();

        // [GIVEN] Create Item and Location
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Warehouse setup field "Copy Item Descr. to Entries" set to 'Yes'
        SetCopyItemDescriptionToWarehouseEntriesSilent(true);

        // [GIVEN] Create journal with new item 'X'
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, Enum::"Warehouse Journal Template Type"::Item, Location.Code);
        LibraryWarehouse.CreateWhseJournalLine(
                WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, '', '', WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDecInRange(1, 5, 2)
        );

        // [WHEN] Post warehouse journal
        LibraryWarehouse.PostWhseJournalLine(WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, '');

        // [THEN] Check that description in warehouse entries is from Item
        VerifyWarehouseEntryDescription(Item."No.", '', Item.Description);
    end;

    [Test]
    procedure PostIfCopyItemVariantDescriptionToWarehouseEntriesIsYes()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Location: Record Location;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        // [FEATURE] [Warehouse] [Posting]
        // [SCENARIO] "Description" in warehouse entry gets item's description if "Copy Item Descr. to Entries" is 'Yes'
        Initialize();

        // [GIVEN] Create Item, Item Variant and Location
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Warehouse setup field "Copy Item Descr. to Entries" set to 'Yes'
        SetCopyItemDescriptionToWarehouseEntriesSilent(true);

        // [GIVEN] Create journal with new item 'X' and variant 'Y'
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, Enum::"Warehouse Journal Template Type"::Item, Location.Code);
        LibraryWarehouse.CreateWhseJournalLine(
                WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, '', '', WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDecInRange(1, 5, 2)
        );
        WarehouseJournalLine.Validate("Variant Code", ItemVariant.Code);
        WarehouseJournalLine.Modify();

        // [WHEN] Post warehouse journal
        LibraryWarehouse.PostWhseJournalLine(WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, '');

        // [THEN] Check that description in warehouse entries is from Item Variant
        VerifyWarehouseEntryDescription(Item."No.", ItemVariant.Code, ItemVariant.Description);
    end;

    [Test]
    [HandlerFunctions('SentNotificationScheduleHandler,ScheduleAJobModalPageHandler')]
    procedure UpdateCopyItemDescriptionToWarehouseEntriesFromSetup()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseSetup: Record "Warehouse Setup";
        ERMCopyNameToLedgEntries: Codeunit "ERM Copy Name To Ledg. Entries";
        ExpectedTaskID: Guid;
    begin
        // [FEATURE] [Warehouse] [Posting]
        // [SCENARIO] Fill blank "Description" in warehouse entries if "Copy Item Descr. To Entries" changed to 'Yes'
        Initialize();

        // [GIVEN] Item 'X'
        // [GIVEN] There are Warehouse Entries where Description is <blank>
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        CreateItemWithWarehouseEntries(Item, Location.Code);

        // [GIVEN] Warehouse setup field "Copy Item Descr. to Entries" set to 'Yes'
        ExpectedTaskID := MockJobScheduling(ERMCopyNameToLedgEntries);
        SetCopyItemDescriptionToWarehouseEntries(true);

        // [THEN] Notification: '2 warehouse entries with empty description found.'
        Assert.ExpectedMessage(StrSubstNo(ItemDescriptionWarehouseEntriesUpdateMsg, 2), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecord(WarehouseSetup);

        // [WHEN] Run action 'Schedule Update'

        // [THEN] Open modal page "Schedule a Report", where Description is not enabled, "Earliest Start Date/Time" is <blank> and editable
        VerifyScheduleAJobPage(WarehouseDescriptionJobQueueTxt);

        // [WHEN] Push 'OK'
        // by ScheduleAJobModalPageHandler

        // [THEN] Job Queue Entry is executed
        Assert.IsTrue(RunJobQueueEntry(ExpectedTaskID), 'Job Queue Entry does not exist');
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Check that description in warehouse entries is from Item
        VerifyWarehouseEntryDescription(Item."No.", '', Item.Description);
    end;

    [Test]
    [HandlerFunctions('SentNotificationScheduleHandler,ScheduleAJobModalPageHandler')]
    procedure UpdateCopyItemVariantDescriptionToWarehouseEntriesFromSetup()
    var
        ItemVariant: Record "Item Variant";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseSetup: Record "Warehouse Setup";
        ERMCopyNameToLedgEntries: Codeunit "ERM Copy Name To Ledg. Entries";
        ExpectedTaskID: Guid;
    begin
        // [FEATURE] [Warehouse] [Posting]
        // [SCENARIO] Fill blank "Description" in warehouse entries if "Copy Item Descr. To Entries" changed to 'Yes'
        Initialize();

        // [GIVEN] Item 'X' with variant 'Y'
        // [GIVEN] There are Warehouse Entries where Description is <blank>
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        CreateItemVariantWithWarehouseEntries(ItemVariant, Location.Code);

        // [GIVEN] Warehouse setup field "Copy Item Descr. to Entries" set to 'Yes'
        ExpectedTaskID := MockJobScheduling(ERMCopyNameToLedgEntries);
        SetCopyItemDescriptionToWarehouseEntries(true);

        // [THEN] Notification: '2 warehouse entries with empty description found.'
        Assert.ExpectedMessage(StrSubstNo(ItemDescriptionWarehouseEntriesUpdateMsg, 2), LibraryVariableStorage.DequeueText());
        LibraryNotificationMgt.RecallNotificationsForRecord(WarehouseSetup);

        // [WHEN] Run action 'Schedule Update'

        // [THEN] Open modal page "Schedule a Report", where Description is not enabled, "Earliest Start Date/Time" is <blank> and editable
        VerifyScheduleAJobPage(WarehouseDescriptionJobQueueTxt);

        // [WHEN] Push 'OK'
        // by ScheduleAJobModalPageHandler

        // [THEN] Job Queue Entry is executed
        Assert.IsTrue(RunJobQueueEntry(ExpectedTaskID), 'Job Queue Entry does not exist');
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Check that description in warehouse entries is from Item Variant
        VerifyWarehouseEntryDescription(ItemVariant."Item No.", ItemVariant.Code, ItemVariant.Description);
    end;

    [Test]
    procedure UpdateCopyItemDescriptionToWarehouseEntriesFromSetupAllFilled()
    begin
        // [FEATURE] [Warehouse] [Setup]
        // [SCENARIO] "Copy Item Descr. To Entries" changed to 'Yes' does nothing if all "Description" in warehouse entries are filled
        Initialize();

        // [WHEN] Warehouse setup field "Copy Item Descr. to Entries" set to 'Yes'
        SetCopyItemDescriptionToWarehouseEntries(true);

        // [THEN] Notification is not shown
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Copy Name To Ledg. Entries");
        LibraryVariableStorage.Clear();
        FillCVNames(false);
        FillItemDesciptions(false);

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Copy Name To Ledg. Entries");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        FillCVNames(true);
        FillItemDesciptions(true);
        SetCopyCustNameToLedgerEntriesSilent(false);
        SetCopyItemDescrToLedgerEntriesSilent(false);
        SetCopyVendNameToLedgerEntriesSilent(false);
        SetCopyItemDescriptionToWarehouseEntriesSilent(false);

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Copy Name To Ledg. Entries");
    end;

    local procedure AddBlankEntry(TableNo: Integer; EntryNoFieldNo: Integer)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        EntryNo: Integer;
    begin
        RecRef.Open(TableNo);
        if RecRef.FindLast() then begin
            FieldRef := RecRef.Field(EntryNoFieldNo);
            EntryNo := FieldRef.Value();
        end;
        RecRef.Init();
        FieldRef.Value(EntryNo + 1);
        RecRef.Insert();
        RecRef.Close();
    end;

    local procedure CreateItemWithEntries(var Item: Record Item)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
    begin
        LibraryInventory.CreateItem(Item);
        ItemLedgerEntry."Entry No." := GetNextEntryNo(32);
        ItemLedgerEntry."Item No." := Item."No.";
        ItemLedgerEntry.Insert();
        ItemLedgerEntry."Entry No." += 1;
        ItemLedgerEntry.Insert();

        ValueEntry."Entry No." := GetNextEntryNo(5802);
        ValueEntry."Item No." := Item."No.";
        ValueEntry.Insert();
        ValueEntry."Entry No." += 1;
        ValueEntry.Insert();

        PhysInventoryLedgerEntry."Entry No." := GetNextEntryNo(281);
        PhysInventoryLedgerEntry."Item No." := Item."No.";
        PhysInventoryLedgerEntry.Insert();
        PhysInventoryLedgerEntry."Entry No." += 1;
        PhysInventoryLedgerEntry.Insert();
    end;

    local procedure CreateItemWithWarehouseEntries(var Item: Record Item; LocationCode: Code[10])
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        LibraryInventory.CreateItem(Item);
        WarehouseEntry."Entry No." := GetNextEntryNo(Database::"Warehouse Entry");
        WarehouseEntry."Item No." := Item."No.";
        WarehouseEntry."Location Code" := LocationCode;
        WarehouseEntry.Insert();
        WarehouseEntry."Entry No." += 1;
        WarehouseEntry.Insert();
    end;

    local procedure CreateItemVariantWithEntries(var ItemVariant: Record "Item Variant")
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemLedgerEntry."Entry No." := GetNextEntryNo(32);
        ItemLedgerEntry."Item No." := Item."No.";
        ItemLedgerEntry."Variant Code" := ItemVariant.Code;
        ItemLedgerEntry.Insert();
        ItemLedgerEntry."Entry No." += 1;
        ItemLedgerEntry.Insert();

        ValueEntry."Entry No." := GetNextEntryNo(5802);
        ValueEntry."Item No." := Item."No.";
        ValueEntry."Variant Code" := ItemVariant.Code;
        ValueEntry.Insert();
        ValueEntry."Entry No." += 1;
        ValueEntry.Insert();

        PhysInventoryLedgerEntry."Entry No." := GetNextEntryNo(281);
        PhysInventoryLedgerEntry."Item No." := Item."No.";
        PhysInventoryLedgerEntry."Variant Code" := ItemVariant.Code;
        PhysInventoryLedgerEntry.Insert();
        PhysInventoryLedgerEntry."Entry No." += 1;
        PhysInventoryLedgerEntry.Insert();
    end;

    local procedure CreateItemVariantWithWarehouseEntries(var ItemVariant: Record "Item Variant"; LocationCode: Code[10])
    var
        Item: Record Item;
        WarehouseEntry: Record "Warehouse Entry";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateVariant(ItemVariant, Item);
        WarehouseEntry."Entry No." := GetNextEntryNo(Database::"Warehouse Entry");
        WarehouseEntry."Item No." := Item."No.";
        WarehouseEntry."Variant Code" := ItemVariant.Code;
        WarehouseEntry."Location Code" := LocationCode;
        WarehouseEntry.Insert();
        WarehouseEntry."Entry No." += 1;
        WarehouseEntry.Insert();
    end;

    local procedure FillCVNames(AddBlank: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        CustLedgerEntry.SetFilter("Customer No.", '<>''''');
        CustLedgerEntry.SetRange("Customer Name", '');
        CustLedgerEntry.ModifyAll("Customer Name", 'CustName');
        VendLedgerEntry.SetFilter("Vendor No.", '<>''''');
        VendLedgerEntry.SetRange("Vendor Name", '');
        VendLedgerEntry.ModifyAll("Vendor Name", 'VendName');

        if not AddBlank then
            exit;
        AddBlankEntry(DATABASE::"Cust. Ledger Entry", CustLedgerEntry.FieldNo("Entry No."));
        AddBlankEntry(DATABASE::"Vendor Ledger Entry", VendLedgerEntry.FieldNo("Entry No."));
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure FillItemDesciptions(AddBlank: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        ItemLedgerEntry.SetFilter("Item No.", '<>''''');
        ItemLedgerEntry.SetRange(Description, '');
        ItemLedgerEntry.ModifyAll(Description, 'item');

        ValueEntry.SetFilter("Item No.", '<>''''');
        ValueEntry.SetRange(Description, '');
        ValueEntry.ModifyAll(Description, 'item');

        PhysInventoryLedgerEntry.SetFilter("Item No.", '<>''''');
        PhysInventoryLedgerEntry.SetRange(Description, '');
        PhysInventoryLedgerEntry.ModifyAll(Description, 'item');

        WarehouseEntry.SetFilter("Item No.", '<>''''');
        WarehouseEntry.SetRange(Description, '');
        WarehouseEntry.ModifyAll(Description, 'item');

        if not AddBlank then
            exit;
        AddBlankEntry(DATABASE::"Phys. Inventory Ledger Entry", PhysInventoryLedgerEntry.FieldNo("Entry No."));
        AddBlankEntry(DATABASE::"Item Ledger Entry", ItemLedgerEntry.FieldNo("Entry No."));
        AddBlankEntry(DATABASE::"Value Entry", ValueEntry.FieldNo("Entry No."));
        AddBlankEntry(DATABASE::"Warehouse Entry", WarehouseEntry.FieldNo("Entry No."));
    end;

    local procedure GetNextEntryNo(TableNo: Integer) NextEntryNo: Integer
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        LastEntryNo: Integer;
    begin
        RecRef.Open(TableNo);
        if RecRef.FindLast() then begin
            FieldRef := RecRef.Field(1); // Entry No.
            LastEntryNo := FieldRef.Value();
        end;
        NextEntryNo := LastEntryNo + 1;
        RecRef.Close();
    end;

    local procedure MockJobScheduling(var ERMCopyNameToLedgEntries: Codeunit "ERM Copy Name To Ledg. Entries"): Guid
    begin
        BindSubscription(ERMCopyNameToLedgEntries);
        exit(ERMCopyNameToLedgEntries.SetTaskID());
    end;

    local procedure RunJobQueueEntry(TaskID: Guid): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("System Task ID", TaskID);
        if not JobQueueEntry.FindFirst() then
            exit(false);
        CODEUNIT.Run(CODEUNIT::"Update Name In Ledger Entries", JobQueueEntry);
        exit(true);
    end;

    local procedure SetCopyCustNameToLedgerEntries(SetCopy: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Copy Customer Name to Entries", SetCopy);
        SalesReceivablesSetup.Modify();
    end;

    local procedure SetCopyCustNameToLedgerEntriesSilent(SetCopy: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Copy Customer Name to Entries" := SetCopy;
        SalesReceivablesSetup.Modify();
    end;

    local procedure SetCopyVendNameToLedgerEntries(SetCopy: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Copy Vendor Name to Entries", SetCopy);
        PurchasesPayablesSetup.Modify();
    end;

    local procedure SetCopyVendNameToLedgerEntriesSilent(SetCopy: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Copy Vendor Name to Entries" := SetCopy;
        PurchasesPayablesSetup.Modify();
    end;

    local procedure SetCopyItemDescrToLedgerEntries(SetCopy: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Copy Item Descr. to Entries", SetCopy);
        InventorySetup.Modify();
    end;

    local procedure SetCopyItemDescrToLedgerEntriesSilent(SetCopy: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup."Copy Item Descr. to Entries" := SetCopy;
        InventorySetup.Modify();
    end;

    local procedure SetCopyItemDescriptionToWarehouseEntries(SetCopy: Boolean)
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Copy Item Descr. to Entries", SetCopy);
        WarehouseSetup.Modify();
    end;

    local procedure SetCopyItemDescriptionToWarehouseEntriesSilent(SetCopy: Boolean)
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        WarehouseSetup.Get();
        WarehouseSetup."Copy Item Descr. to Entries" := SetCopy;
        WarehouseSetup.Modify();
    end;

    local procedure VerifyCustLedgEntryDescription(CustNo: Code[20]; ExpectedDescription: Text[100])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustNo);
        CustLedgerEntry.SetFilter("Customer Name", '<>%1', ExpectedDescription);
        Assert.RecordIsEmpty(CustLedgerEntry);
    end;

    local procedure VerifyVendLedgEntryDescription(VendNo: Code[20]; ExpectedDescription: Text[100])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendNo);
        VendorLedgerEntry.SetFilter("Vendor Name", '<>%1', ExpectedDescription);
        Assert.RecordIsEmpty(VendorLedgerEntry);
    end;

    local procedure VerifyItemDescriptionInEntries(ItemNo: Code[20]; VariantCode: Code[10]; ExpectedDescription: Text[100])
    begin
        VerifyItemLedgEntryDescription(ItemNo, VariantCode, ExpectedDescription);
        VerifyPhysInvEntryDescription(ItemNo, VariantCode, ExpectedDescription);
        VerifyValueEntryDescription(ItemNo, VariantCode, ExpectedDescription);
    end;

    local procedure VerifyItemLedgEntryDescription(ItemNo: Code[20]; VariantCode: Code[10]; ExpectedDescription: Text[100])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Variant Code", VariantCode);
        ItemLedgerEntry.SetFilter(Description, '<>%1', ExpectedDescription);
        Assert.RecordIsEmpty(ItemLedgerEntry);
    end;

    local procedure VerifyWarehouseEntryDescription(ItemNo: Code[20]; VariantCode: Code[10]; ExpectedDescription: Text[100])
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Variant Code", VariantCode);
        WarehouseEntry.SetFilter(Description, '<>%1', ExpectedDescription);
        Assert.RecordIsEmpty(WarehouseEntry);
    end;

    local procedure VerifyPhysInvEntryDescription(ItemNo: Code[20]; VariantCode: Code[10]; ExpectedDescription: Text[100])
    var
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
    begin
        PhysInventoryLedgerEntry.SetRange("Item No.", ItemNo);
        PhysInventoryLedgerEntry.SetRange("Variant Code", VariantCode);
        PhysInventoryLedgerEntry.SetFilter(Description, '<>%1', ExpectedDescription);
        Assert.RecordIsEmpty(PhysInventoryLedgerEntry);
    end;

    local procedure VerifyValueEntryDescription(ItemNo: Code[20]; VariantCode: Code[10]; ExpectedDescription: Text[100])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Variant Code", VariantCode);
        ValueEntry.SetFilter(Description, '<>%1', ExpectedDescription);
        Assert.RecordIsEmpty(ValueEntry);
    end;

    local procedure VerifyScheduleAJobPage(Descr: Text)
    begin
        Assert.AreEqual(Descr, LibraryVariableStorage.DequeueText(), 'Description value');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Description enabled');
        Assert.AreEqual(0DT, LibraryVariableStorage.DequeueDateTime(), 'Earliest Start Date/Time value');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Earliest Start Date/Time enabled');
    end;

    local procedure VerifyScheduledJobQueueEntryPage(ExpectedTaskID: Guid; Param: Text; Descr: Text[250])
    var
        JobQueueEntry: Record "Job Queue Entry";
        ExpectedDateTime: DateTime;
    begin
        ExpectedDateTime := LibraryVariableStorage.DequeueDateTime(); // from OKScheduleAJobModalPageHandler
        JobQueueEntry.SetRange("System Task ID", ExpectedTaskID);
        JobQueueEntry.FindFirst();
        JobQueueEntry.TestField("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.TestField("Object ID to Run", CODEUNIT::"Update Name In Ledger Entries");
        JobQueueEntry.TestField("Earliest Start Date/Time", ExpectedDateTime);
        JobQueueEntry.TestField("Parameter String", Param);
        JobQueueEntry.TestField(Description, Descr);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SentNotificationScheduleHandler(var Notification: Notification): Boolean
    var
        UpdateNameInLedgerEntries: Codeunit "Update Name In Ledger Entries";
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
        UpdateNameInLedgerEntries.ScheduleUpdate(Notification); // simulate action "Schedule update"
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ScheduleAJobModalPageHandler(var ScheduleAJobPage: TestPage "Schedule a Job")
    begin
        LibraryVariableStorage.Enqueue(ScheduleAJobPage.Description.Value);
        LibraryVariableStorage.Enqueue(ScheduleAJobPage.Description.Enabled());
        LibraryVariableStorage.Enqueue(ScheduleAJobPage."Earliest Start Date/Time".AsDateTime());
        LibraryVariableStorage.Enqueue(ScheduleAJobPage."Earliest Start Date/Time".Enabled());
        ScheduleAJobPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OKScheduleAJobModalPageHandler(var ScheduleAJobPage: TestPage "Schedule a Job")
    begin
        ScheduleAJobPage."Earliest Start Date/Time".Value(Format(CreateDateTime(Today + 1, Time)));
        LibraryVariableStorage.Enqueue(ScheduleAJobPage."Earliest Start Date/Time".AsDateTime());
        ScheduleAJobPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CancelScheduleAJobModalPageHandler(var ScheduleAJobPage: TestPage "Schedule a Job")
    begin
        ScheduleAJobPage.Cancel().Invoke();
    end;

    [Scope('OnPrem')]
    procedure SetTaskID(): Guid
    begin
        GlobalTaskID := CreateGuid();
        exit(GlobalTaskID);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnBeforeScheduleTask', '', false, false)]
    local procedure OnBeforeScheduleTaskHandler(var JobQueueEntry: Record "Job Queue Entry"; var TaskGUID: Guid)
    begin
        TaskGUID := GlobalTaskID;
    end;
}

