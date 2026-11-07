codeunit 139183 "CRM Integration Mapping"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Mapping]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryERM: Codeunit "Library - ERM";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTemplates: Codeunit "Library - Templates";
        LibraryRandom: Codeunit "Library - Random";
        SyncStartedMsg: Label 'The synchronization has been scheduled.';
        ExpectedRecordNotFoundErr: Label 'Expected record not found.';
        UnexpectedRecordFoundErr: Label 'Unexpected record found.';
        NoFieldMappingRowsErr: Label 'There are no field mapping rows for the Integration Table Mapping Name';
        InsertIsNotAllowedErr: Label 'New method failed because Insert is not allowed.';
        NotNullIsApplicableForGUIDErr: Label 'The Not Null value is applicable for GUID fields only.';

    [Test]
    [Scope('OnPrem')]
    procedure ListPageDoesntShowDeleteAfterSyncMapping()
    var
        IntegrationTableMapping: array[2] of Record "Integration Table Mapping";
        IntegrationTableMappingList: TestPage "Integration Table Mapping List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] List page should only show mappings, where "Delete After Synchronization" is 'No'.
        Initialize();

        // [GIVEN] Mapping 'Normal', where "Delete After Synchronization" is 'No'
        IntegrationTableMapping[1].Name := 'Normal';
        IntegrationTableMapping[1]."Delete After Synchronization" := false;
        IntegrationTableMapping[1].Insert();
        // [GIVEN] Mapping 'DelAfterSync', where "Delete After Synchronization" is 'Yes'
        IntegrationTableMapping[2].Name := 'DelAfterSync';
        IntegrationTableMapping[2]."Delete After Synchronization" := true;
        IntegrationTableMapping[2].Insert();

        // [WHEN] Open "Integration Table Mapping List" page
        IntegrationTableMappingList.Trap();
        PAGE.Run(PAGE::"Integration Table Mapping List");

        // [THEN] The List page shows just one record - 'Normal'
        Assert.IsTrue(IntegrationTableMappingList.First(), 'There should be at least one record in the list.');
        IntegrationTableMappingList.Name.AssertEquals(IntegrationTableMapping[1].Name);
        Assert.IsTrue(IntegrationTableMappingList.Last(), 'There should be just one record in the list.');
        IntegrationTableMappingList.Name.AssertEquals(IntegrationTableMapping[1].Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TempDescriptionShowsSourceDestTablesWithDirection()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] GetTempDescription returns a sting of format "TableName<->IntegrationTableName"
        // [GIVEN] Mapping for Item - CRM Product
        IntegrationTableMapping."Table ID" := DATABASE::Item;
        IntegrationTableMapping."Integration Table ID" := DATABASE::"CRM Product";
        // [THEN] GetTempDescription() returns 'Item<->CRM Product' for "Bidirectional" sync
        Assert.AreEqual('Item <-> CRM Product', IntegrationTableMapping.GetTempDescription(), Format(IntegrationTableMapping.Direction));
        // [THEN] GetTempDescription() returns 'Item->CRM Product' for "ToIntegrationTable" sync
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        Assert.AreEqual('Item -> CRM Product', IntegrationTableMapping.GetTempDescription(), Format(IntegrationTableMapping.Direction));
        // [THEN] GetTempDescription() returns 'Item<-CRM Product' for "FromIntegrationTable" sync
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        Assert.AreEqual('Item <- CRM Product', IntegrationTableMapping.GetTempDescription(), Format(IntegrationTableMapping.Direction));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FieldMappingListPageShownFromTableMapping()
    var
        CRMField: array[2] of Record "Field";
        NAVField: array[2] of Record "Field";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMappingList: TestPage "Integration Field Mapping List";
        IntegrationTableMappingList: TestPage "Integration Table Mapping List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Field Mapping list should show related field mapping records for active Table Mapping record
        IntegrationTableMapping.DeleteAll(true);
        // [GIVEN] Two pairs of NAV to CRM fields: 'N1' - 'C1', 'N2' - 'C2'
        FindFieldsToPair(NAVField, CRMField);
        // [GIVEN] Defined the Table Mapping 'X'
        CreateIntegrationTableMapping(IntegrationTableMapping, NAVField[1], CRMField[1]);
        // [GIVEN] Two Field Mapping records for 'X'
        CreateIntegrationFieldMapping(IntegrationFieldMapping, IntegrationTableMapping.Name, NAVField[1], CRMField[1]);

        // [GIVEN] Third field mapping defined for another table mapping
        IntegrationFieldMapping."No." := 0;
        IntegrationFieldMapping."Integration Table Mapping Name" := 'Y';
        IntegrationFieldMapping.Insert();

        CreateIntegrationFieldMapping(IntegrationFieldMapping, IntegrationTableMapping.Name, NAVField[2], CRMField[2]);

        // [GIVEN] Open 'Integration Table Mapping List' page
        IntegrationTableMappingList.OpenView();

        // [WHEN] Run action 'Fields Mapping'
        IntegrationFieldMappingList.Trap();
        IntegrationTableMappingList.FieldMapping.Invoke();

        // [THEN] not editable "Integration Field Mapping List" page is open showing two records
        Assert.IsFalse(IntegrationFieldMappingList.Editable(), 'Page.Editable');
        // [THEN] First record, where "Field No." is 'N1', "Integration Table Field No." is 'C1'
        IntegrationFieldMappingList."Field No.".AssertEquals(NAVField[1]."No.");
        IntegrationFieldMappingList."Integration Table Field No.".AssertEquals(CRMField[1]."No.");
        IntegrationFieldMappingList.FieldName.AssertEquals(NAVField[1]."Field Caption");
        IntegrationFieldMappingList.IntegrationFieldName.AssertEquals(CRMField[1]."Field Caption");
        IntegrationFieldMappingList.Last();
        // [THEN] Last record, where "Field No." is 'N2', "Integration Table Field No." is 'C2'
        IntegrationFieldMappingList."Field No.".AssertEquals(NAVField[2]."No.");
        IntegrationFieldMappingList."Integration Table Field No.".AssertEquals(CRMField[2]."No.");
        // [THEN] "Field Name" and "Integration Field Name" controls show fields' captions
        IntegrationFieldMappingList.FieldName.AssertEquals(NAVField[2]."Field Caption");
        IntegrationFieldMappingList.IntegrationFieldName.AssertEquals(CRMField[2]."Field Caption");
        IntegrationFieldMappingList.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FieldMappingListPageAllowsEditing()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMField: array[2] of Record "Field";
        NAVField: array[2] of Record "Field";
        IntegrationFieldMappingList: TestPage "Integration Field Mapping List";
    begin
        // [FEATURE] [UI]
        // [GIVEN] Defined the Table Mapping 'X' with a Field Mapping record
        FindFieldsToPair(NAVField, CRMField);
        CreateIntegrationTableMapping(IntegrationTableMapping, NAVField[1], CRMField[1]);
        CreateIntegrationFieldMapping(IntegrationFieldMapping, IntegrationTableMapping.Name, NAVField[1], CRMField[1]);

        // [WHEN] Open Integration Field Mapping List page
        IntegrationFieldMappingList.OpenEdit();

        // [THEN] Editable fields: Status, Direction, "Constant Value", "Validate Field", "Validate Integration Table Fld", "Clear Value on Failed Sync", "Not Null".
        Assert.IsTrue(IntegrationFieldMappingList.Status.Editable(), 'Status should be editable');
        Assert.IsTrue(IntegrationFieldMappingList.Direction.Editable(), 'Direction should be editable');
        Assert.IsTrue(IntegrationFieldMappingList."Not Null".Editable(), 'Not Null should be editable');
        Assert.IsTrue(IntegrationFieldMappingList."Constant Value".Editable(), 'Constant Value should be editable');
        Assert.IsTrue(IntegrationFieldMappingList."Validate Field".Editable(), 'Validate Field should be editable');
        Assert.IsTrue(
          IntegrationFieldMappingList."Validate Integration Table Fld".Editable(),
          'Validate Integration Table Fld should be editable');
        Assert.IsTrue(
          IntegrationFieldMappingList."Clear Value on Failed Sync".Editable(),
          'Clear Value on Failed Sync should be editable');
        // [THEN] Not editable fields: "Field No.", "Field Name", "Integration Table Field No.", "Integration Field Name".
        Assert.IsFalse(IntegrationFieldMappingList."Field No.".Editable(), 'Field No should not be editable');
        Assert.IsFalse(IntegrationFieldMappingList.FieldName.Editable(), 'NAVFieldName should not be editable');
        Assert.IsFalse(
          IntegrationFieldMappingList."Integration Table Field No.".Editable(),
          'Integration Table Field No should not be editable');
        Assert.IsFalse(IntegrationFieldMappingList.IntegrationFieldName.Editable(), 'CRMFieldName should not be editable');
        // [THEN] It is not allowed to add a new record
        asserterror IntegrationFieldMappingList.New();
        Assert.ExpectedError(InsertIsNotAllowedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldClearValueOnFailedSyncFailsOnNotNull()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        // [FEATURE] [Clear Value on Failed Sync] [Not Null] [UT]
        IntegrationFieldMapping."Not Null" := true;
        asserterror IntegrationFieldMapping.Validate("Clear Value on Failed Sync", true);
        Assert.ExpectedTestFieldError(IntegrationFieldMapping.FieldCaption("Not Null"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldNotNullFailsOnClearValueOnFailedSync()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        // [FEATURE] [Clear Value on Failed Sync] [Not Null] [UT]
        IntegrationFieldMapping."Clear Value on Failed Sync" := true;
        asserterror IntegrationFieldMapping.Validate("Not Null", true);
        Assert.ExpectedTestFieldError(IntegrationFieldMapping.FieldCaption("Clear Value on Failed Sync"), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldNotNullIsNotApplicableForGUIDsOnly()
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        IntegrationTableMapping: Record "Integration Table Mapping";
        "Field": array[2] of Record "Field";
    begin
        // [FEATURE] [Not Null] [UT]
        Field[1].Get(DATABASE::Contact, Contact.FieldNo("Salesperson Code"));
        Field[2].Get(DATABASE::"CRM Contact", CRMContact.FieldNo(OwnerId));
        IntegrationTableMapping.DeleteAll(true);
        CreateIntegrationTableMapping(IntegrationTableMapping, Field[1], Field[2]);
        IntegrationFieldMapping."Integration Table Mapping Name" := IntegrationTableMapping.Name;
        IntegrationFieldMapping."Integration Table Field No." := CRMContact.FieldNo(OwnerId);
        // [WHEN] Set "Not Null" for the GUID field
        IntegrationFieldMapping.Validate("Not Null", true);
        // [THEN] "Not Null" is 'Yes'
        IntegrationFieldMapping.TestField("Not Null");

        IntegrationFieldMapping."Integration Table Field No." := CRMContact.FieldNo(FullName);
        // [WHEN] Set "Not Null" for the text field
        asserterror IntegrationFieldMapping.Validate("Not Null", true);
        // [THEN] Error message: 'Not Null is applicable for GUID fields only'
        Assert.ExpectedError(NotNullIsApplicableForGUIDErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobLogForMappingSortedByStartDateTime()
    var
        IntegrationSynchJob: array[2] of Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableMappingList: TestPage "Integration Table Mapping List";
        IntegrationSynchJobList: TestPage "Integration Synch. Job List";
    begin
        // [FEATURE] [Integration Synch. Job] [UI]
        // [SCENARIO] Integration Synch. Job Log shows jobs related to the current mapping, sorted by descending "Start Date/Time"
        // [GIVEN] Integration Table Mapping 'Y'
        IntegrationTableMapping.DeleteAll(true);
        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := 'Y';
        IntegrationTableMapping."Table ID" := DATABASE::Customer;
        IntegrationTableMapping.Insert();
        // [GIVEN] Integration Sync Job for 'Y' and for 'X'
        IntegrationSynchJob[1].ID := CreateGuid();
        IntegrationSynchJob[1]."Integration Table Mapping Name" := IntegrationTableMapping.Name;
        IntegrationSynchJob[1].Insert();
        IntegrationSynchJob[2].ID := CreateGuid();
        IntegrationSynchJob[2]."Integration Table Mapping Name" := 'X';
        IntegrationSynchJob[2].Insert();

        // [WHEN] Run "View Integration Synch. Job Log" on the mapping list page
        IntegrationSynchJobList.Trap();
        IntegrationTableMappingList.OpenView();
        IntegrationTableMappingList."View Integration Synch. Job Log".Invoke();
        IntegrationTableMappingList.Close();

        // [THEN] Integration Synch. Job List shows one record, related to 'Y'
        Assert.IsTrue(IntegrationSynchJobList.GotoRecord(IntegrationSynchJob[1]), 'Cannot find the job.');
        Assert.IsFalse(IntegrationSynchJobList.GotoRecord(IntegrationSynchJob[2]), 'Should not be the job related to other mapping .');
        // [THEN] Jobs are sorted by descending "Start Date/Time"
        Assert.AreEqual('Start Date/Time,ID', IntegrationSynchJobList.FILTER.CurrentKey, 'Current key is wrong.');
        Assert.IsFalse(IntegrationSynchJobList.FILTER.Ascending, 'Descending order expected.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TableMappingDeletionRemovesRelatedFieldMapping()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationTableMapping.DeleteAll(true);
        // [GIVEN] the Table Mapping "Y" with 1 Field Mapping record
        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := 'Y';
        IntegrationTableMapping.Insert();

        IntegrationFieldMapping.Init();
        IntegrationFieldMapping."Integration Table Mapping Name" := IntegrationTableMapping.Name;
        IntegrationFieldMapping."No." := 0;
        IntegrationFieldMapping.Insert();

        // [GIVEN] the Table Mapping "X" with 1 Field Mapping record
        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := 'X';
        IntegrationTableMapping.Insert();

        IntegrationFieldMapping.Init();
        IntegrationFieldMapping."Integration Table Mapping Name" := IntegrationTableMapping.Name;
        IntegrationFieldMapping."No." := 0;
        IntegrationFieldMapping.Insert();

        // [WHEN] Delete the Table Mapping "X"
        IntegrationTableMapping.Get('X');
        IntegrationTableMapping.Delete(true);

        // [THEN] There is no related Field Mapping record for Table Mapping "X"
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'X');
        Assert.RecordIsEmpty(IntegrationFieldMapping);
        // [THEN] There is 1 Field Mapping record for Table Mapping "Y"
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'Y');
        Assert.RecordCount(IntegrationFieldMapping, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntTableUIDFieldTypeDefinedByUIDNoValidation()
    var
        "Field": Record "Field";
        IntegrationTableMapping: Record "Integration Table Mapping";
        GUIDFieldNo: Integer;
        OptionFieldNo: Integer;
    begin
        // [FEATURE] [UT]

        // [GIVEN] CRM Account table, where GUID field no. = '1', an Option field No. = '15'.
        Field.SetRange(TableNo, DATABASE::"CRM Account");
        Field.SetRange(Type, Field.Type::Option);
        Field.FindFirst();
        OptionFieldNo := Field."No.";
        Field.SetRange(Type, Field.Type::GUID);
        Field.FindFirst();
        GUIDFieldNo := Field."No.";

        // [GIVEN] The Table Mapping, where "Integration Table ID" := "CRM Account"
        IntegrationTableMapping.Init();
        IntegrationTableMapping."Integration Table ID" := DATABASE::"CRM Account";

        // [WHEN] Validate "Integration Table UID Fld. No." with an ID = '1'
        IntegrationTableMapping.Validate("Integration Table UID Fld. No.", GUIDFieldNo);
        // [THEN] "Int. Table UID Field Type" is 'GUID'
        IntegrationTableMapping.TestField("Int. Table UID Field Type", Field.Type::GUID);

        // [WHEN] Validate "Integration Table UID Fld. No." with an ID = '15'
        IntegrationTableMapping.Validate("Integration Table UID Fld. No.", OptionFieldNo);
        // [THEN] "Int. Table UID Field Type" is 'Option'
        IntegrationTableMapping.TestField("Int. Table UID Field Type", Field.Type::Option);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetIntRecordRefFilterIncludesLaterModifiedRec()
    var
        CRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecRef: RecordRef;
        CurrDT: DateTime;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] CRM table record modified after the last sync, defined just by "Synch. Int. Tbl. Mod. On Fltr.", should be all included into sync.
        Initialize();
        // [GIVEN] CRM Account 'A', where "Modified On" = '10:29' and CRM Account 'B', where "Modified On" = '10:31'
        CurrDT := CreateTwoCRMAccountsModifiedIn(CRMAccount, 200);

        // [GIVEN] the CRM Account mapping, where "Synch. Modified On Filter" is <blank> and "Synch. Int. Tbl. Mod. On Fltr." is '10:30'.
        IntegrationTableMapping.Init();
        IntegrationTableMapping."Integration Table ID" := DATABASE::"CRM Account";
        IntegrationTableMapping."Int. Tbl. Modified On Fld. No." := CRMAccount.FieldNo(ModifiedOn);
        IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." := CurrDT + 100;
        IntegrationTableMapping."Synch. Modified On Filter" := 0DT;

        // [WHEN] run SetIntRecordRefFilter()
        RecRef.Get(CRMAccount.RecordId);
        IntegrationTableMapping.SetIntRecordRefFilter(RecRef);

        // [THEN] the recordset includes both records
        Assert.AreEqual(2, RecRef.Count, 'the record set should include 2 record');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetIntRecordRefFilterIncludesLaterModifiedIntRec()
    var
        CRMAccount: Record "CRM Account";
        FoundCRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecRef: RecordRef;
        CurrDT: DateTime;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] CRM table record modified after the last int. table sync, defined by "Synch. Modified On Filter", should be included into sync.
        Initialize();
        // [GIVEN] CRM Account 'A', where "Modified On" = '10:29' and CRM Account 'B', where "Modified On" = '10:31'
        CurrDT := CreateTwoCRMAccountsModifiedIn(CRMAccount, 3000);

        // [GIVEN] the CRM Account mapping, where "Synch. Modified On Filter" is '10:30' and "Synch. Int. Tbl. Mod. On Fltr." is '10:28'.
        IntegrationTableMapping.Init();
        IntegrationTableMapping."Integration Table ID" := DATABASE::"CRM Account";
        IntegrationTableMapping."Int. Tbl. Modified On Fld. No." := CRMAccount.FieldNo(ModifiedOn);
        IntegrationTableMapping."Synch. Modified On Filter" := CurrDT + 2000;
        IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." := CurrDT - 2000;

        // [WHEN] run SetIntRecordRefFilter()
        RecRef.Get(CRMAccount.RecordId);
        IntegrationTableMapping.SetIntRecordRefFilter(RecRef);

        // [THEN] the recordset includes 1 record - CRM Account 'B'
        Assert.AreEqual(1, RecRef.Count, 'the record set should include 1 record');
        RecRef.SetTable(FoundCRMAccount);
        FoundCRMAccount.TestField(AccountId, CRMAccount.AccountId);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesPersonMappedToCRMSystemuser()
    var
        CRMSystemuser: Record "CRM Systemuser";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Salesperson]
        Initialize();

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Salesperson/Purchaser", DATABASE::"CRM Systemuser", CRMSystemuser.FieldNo(SystemUserId), 3, 2, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CustomerMappedToCRMAccount()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Customer]
        Initialize();

        VerifyMapping(
          IntegrationTableMapping, DATABASE::Customer, DATABASE::"CRM Account", CRMAccount.FieldNo(AccountId), 20, 0, false);
        VerifyFieldMapping(IntegrationTableMapping, Customer.FieldNo("Salesperson Code"), CRMAccount.FieldNo(OwnerId), true);
        VerifyFieldMapping(IntegrationTableMapping, Customer.FieldNo(County), CRMAccount.FieldNo(Address1_StateOrProvince), false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ContactMappedToCRMContact()
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Contact]
        Initialize();

        VerifyMapping(
          IntegrationTableMapping, DATABASE::Contact, DATABASE::"CRM Contact", CRMContact.FieldNo(ContactId), 20, 0, false);
        VerifyFieldMapping(IntegrationTableMapping, Contact.FieldNo("Salesperson Code"), CRMContact.FieldNo(OwnerId), true);
        VerifyFieldMapping(IntegrationTableMapping, Contact.FieldNo(County), CRMContact.FieldNo(Address1_StateOrProvince), false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CurrencyMappedToCRMTransactioncurrency()
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Currency]
        Initialize();

        VerifyMapping(
          IntegrationTableMapping, DATABASE::Currency, DATABASE::"CRM Transactioncurrency",
          CRMTransactioncurrency.FieldNo(TransactionCurrencyId), 3, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ItemMappedToCRMProduct()
    var
        CRMProduct: Record "CRM Product";
        Item: Record Item;
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Item]
        Initialize();

        VerifyMapping(
          IntegrationTableMapping, DATABASE::Item, DATABASE::"CRM Product",
          CRMProduct.FieldNo(ProductId), 11, IntegrationTableMapping.Direction::Bidirectional, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
        VerifyFieldMapping(IntegrationTableMapping, Item.FieldNo("Vendor No."), CRMProduct.FieldNo(VendorID), false);
        VerifyFieldMapping(IntegrationTableMapping, Item.FieldNo("Vendor Item No."), CRMProduct.FieldNo(VendorPartNumber), false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OpportunityMappedToCRMOpportunity()
    var
        Opportunity: Record Opportunity;
        CRMOpportunity: Record "CRM Opportunity";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Opportunity]
        Initialize();

        VerifyMapping(
          IntegrationTableMapping, DATABASE::Opportunity, DATABASE::"CRM Opportunity", CRMOpportunity.FieldNo(OpportunityId),
          7, IntegrationTableMapping.Direction::Bidirectional, false);
        VerifyFieldMapping(IntegrationTableMapping, Opportunity.FieldNo("Salesperson Code"), CRMOpportunity.FieldNo(OwnerId), true);
        VerifyJobQueueEntry(IntegrationTableMapping, 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ResourceMappedToCRMProduct()
    var
        CRMProduct: Record "CRM Product";
        Resource: Record Resource;
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Resource]
        Initialize();

        VerifyMapping(
          IntegrationTableMapping, DATABASE::Resource, DATABASE::"CRM Product",
          CRMProduct.FieldNo(ProductId), 7, IntegrationTableMapping.Direction::Bidirectional, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
        VerifyFieldMapping(IntegrationTableMapping, Resource.FieldNo("Vendor No."), CRMProduct.FieldNo(VendorID), false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesInvoiceHeaderMappedToCRMInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CRMInvoice: Record "CRM Invoice";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Sales] [Invoice]
        Initialize();

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Sales Invoice Header", DATABASE::"CRM Invoice", CRMInvoice.FieldNo(InvoiceId), 26, 1, false);
        VerifyFieldMapping(IntegrationTableMapping, SalesInvoiceHeader.FieldNo("Salesperson Code"), CRMInvoice.FieldNo(OwnerId), true);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesInvoiceLineMappedToCRMInvoicedetail()
    var
        CRMInvoicedetail: Record "CRM Invoicedetail";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Sales] [Invoice]
        Initialize();

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Sales Invoice Line", DATABASE::"CRM Invoicedetail",
          CRMInvoicedetail.FieldNo(InvoiceDetailId), 6, 1, false);
        VerifyNoJobQueueEntry(IntegrationTableMapping);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UnitOfMeasureMappedToCRMUomschedule()
    var
        CRMUomschedule: Record "CRM Uomschedule";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Unit of Measure]
        Initialize();

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Unit of Measure", DATABASE::"CRM Uomschedule", CRMUomschedule.FieldNo(UoMScheduleId), 1, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CustomerPriceGroupMappedToCRMPricelevel()
    var
        CRMPricelevel: Record "CRM Pricelevel";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Price List]
        Initialize();

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Customer Price Group", DATABASE::"CRM Pricelevel", CRMPricelevel.FieldNo(PriceLevelId), 1, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PriceListHeaderMappedToCRMPricelevel()
    var
        CRMPricelevel: Record "CRM Pricelevel";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Price List]
        Initialize(true, false);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Price List Header", DATABASE::"CRM Pricelevel", CRMPricelevel.FieldNo(PriceLevelId), 5, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UnitGroupMappedToCRMUomschedule()
    var
        CRMUomschedule: Record "CRM Uomschedule";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Unit Group]
        Initialize(false, true);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Unit Group", DATABASE::"CRM Uomschedule", CRMUomschedule.FieldNo(UoMScheduleId), 2, 1, true);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ItemUnitOfMeasureMappedToCRMUom()
    var
        CRMUom: Record "CRM Uom";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Item Unit of Measure]
        Initialize(false, true);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Item Unit of Measure", DATABASE::"CRM Uom", CRMUom.FieldNo(UoMId), 2, 1, true);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ResourceUnitOfMeasureMappedToCRMUom()
    var
        CRMUom: Record "CRM Uom";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Resource Unit of Measure]
        Initialize(false, true);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Resource Unit of Measure", DATABASE::"CRM Uom", CRMUom.FieldNo(UoMId), 2, 1, true);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesPriceMappedToCRMProductpricelevel()
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Price List]
        Initialize();

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Sales Price", DATABASE::"CRM Productpricelevel",
          CRMProductpricelevel.FieldNo(ProductPriceLevelId), 6, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PriceListLineMappedToCRMProductpricelevel()
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Price List]
        Initialize(true, false);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Price List Line", DATABASE::"CRM Productpricelevel",
          CRMProductpricelevel.FieldNo(ProductPriceLevelId), 7, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShippingAgentMappedToShippingMethodCodeEnum()
    var
        CRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Shipping Agent]
        // [SCENARIO] "Shipping Agent" is mapped to options of the field "CRM Account".Address1_ShippingMethodCodeEnum
        Initialize();

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Shipping Agent", DATABASE::"CRM Account",
          CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum), 1, 1, false);
        VerifyUIDFieldIsOpton(IntegrationTableMapping.Name);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShipmentMethodMappedToFreightTermsCodeEnum()
    var
        CRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Shipment Method]
        // [SCENARIO] "Shipment Method" is mapped to options of the field "CRM Account".Address1_FreightTermsCodeEnum
        Initialize();

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Shipment Method", DATABASE::"CRM Account", CRMAccount.FieldNo(Address1_FreightTermsCodeEnum), 1, 1, false);
        VerifyUIDFieldIsOpton(IntegrationTableMapping.Name);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PaymentTermsMappedToPaymentTermsCodeEnum()
    var
        CRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Payment Terms]
        // [SCENARIO] "Payment Terms" is mapped to options of the field "CRM Account".PaymentTermsCodeEnum
        Initialize();

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Payment Terms", DATABASE::"CRM Account", CRMAccount.FieldNo(PaymentTermsCodeEnum), 1, 1, false);
        VerifyUIDFieldIsOpton(IntegrationTableMapping.Name);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrioritizedMappingListOrder()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        "Field": Record "Field";
        IntegrationTableMapping: Record "Integration Table Mapping";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
    begin
        Initialize();
        CRMConnectionSetup.DeleteAll();
        // [GIVEN] No table mappings exists
        IntegrationTableMapping.DeleteAll(true);
        // [WHEN] Calling GetPrioritizedMappingList()
        // [THEN] An empty list is returned
        CRMSetupDefaults.GetPrioritizedMappingList(TempNameValueBuffer);
        Assert.AreEqual(0, TempNameValueBuffer.Count, 'Did not expect any mappings to be returned');

        TempNameValueBuffer.DeleteAll();
        IntegrationTableMapping.DeleteAll(true);
        // [GIVEN] Default mapping setup
        LibraryCRMIntegration.ConfigureCRM();
        ResetCRMConfiguration(false);
        // [GIVEN] the temp mappings for CUSTOMER/POSTEDSALESINV-INV are added, where "Delete After Synchronization" is 'Yes'
        AddTempTableMapping('CUSTOMER');
        AddTempTableMapping('POSTEDSALESINV-INV');

        // [WHEN] Calling GetPrioritizedMappingList()
        CRMSetupDefaults.GetPrioritizedMappingList(TempNameValueBuffer);

        // [THEN] A list with all the normal mappings to GUID fields are returned
        IntegrationTableMapping.Reset();
        IntegrationTableMapping.SetRange("Int. Table UID Field Type", Field.Type::GUID);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetFilter("Table ID", '<>113');
        Assert.AreEqual(
          IntegrationTableMapping.Count, TempNameValueBuffer.Count, 'Expected all mappings to be in the prioritized mapping');
        TempNameValueBuffer.Ascending(true);
        TempNameValueBuffer.FindSet();
        // [THEN] The prioritized list has salespeople as the first item
        Assert.AreEqual('1', TempNameValueBuffer.Name, 'Expected the first priority to be 1');
        Assert.AreEqual('SALESPEOPLE', TempNameValueBuffer.Value, 'Expected the first priority to be the SALESPEOPLE mapping');
        // [THEN] The prioritized list has currency as the second item
        TempNameValueBuffer.Next();
        Assert.AreEqual('2', TempNameValueBuffer.Name, 'Expected the second priority to be 2');
        Assert.AreEqual('CURRENCY', TempNameValueBuffer.Value, 'Expected the second priority to be the CURRENCY mapping');
        // [THEN] The prioritized list has unit of measure as the third item
        TempNameValueBuffer.Next();
        Assert.AreEqual('3', TempNameValueBuffer.Name, 'Expected the third priority to be 3');
        Assert.AreEqual('UNIT OF MEASURE', TempNameValueBuffer.Value, 'Expected the third priority to be the UNIT OF MEASURE mapping');
        // [THEN] The prioritized list has customer as the fourth item
        TempNameValueBuffer.Next();
        Assert.AreEqual('4', TempNameValueBuffer.Name, 'Expected the fourth priority to be 4');
        Assert.AreEqual('CUSTOMER', TempNameValueBuffer.Value, 'Expected the fourth priority to be the CUSTOMER mapping');
        // [THEN] The prioritized list has contact as the fifth item
        TempNameValueBuffer.Next();
        Assert.AreEqual('5', TempNameValueBuffer.Name, 'Expected the fifth priority to be 5');
        Assert.AreEqual('CONTACT', TempNameValueBuffer.Value, 'Expected the fifth priority to be the CONTACT mapping');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrioritizedMappingListOrderShouldSkipTablesMappedToOption()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        "Field": Record "Field";
        IntegrationTableMapping: Record "Integration Table Mapping";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        OptionCount: Integer;
        TotalCount: Integer;
    begin
        CRMConnectionSetup.DeleteAll();
        IntegrationTableMapping.DeleteAll(true);
        // [GIVEN] Default mapping setup, where are 14 mappings and 3 of them are for Options.
        LibraryCRMIntegration.ConfigureCRM();
        ResetCRMConfiguration(false);

        TotalCount := IntegrationTableMapping.Count();
        IntegrationTableMapping.SetRange("Int. Table UID Field Type", Field.Type::Option);
        OptionCount := IntegrationTableMapping.Count();

        // [WHEN] Calling GetPrioritizedMappingList()
        CRMSetupDefaults.GetPrioritizedMappingList(TempNameValueBuffer);

        // [THEN] The list contains 12 elements, because Options and Sales Invoice Lines are excluded
        TempNameValueBuffer.Reset();
        Assert.AreEqual(TotalCount - OptionCount - 1, TempNameValueBuffer.Count, 'Total count of the list');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncTableWithAllEnabledFields()
    var
        Currency: Record Currency;
    begin
        // [FEATURE] [Status] [UT]
        Initialize();
        // [GIVEN] Reset CRM Configuration
        ResetCRMConfiguration(false);
        // [GIVEN] Currency 'X'
        Currency.DeleteAll();
        LibraryERM.CreateCurrency(Currency);
        Currency.Description := LibraryUtility.GenerateGUID();
        Currency.Modify();
        LibraryERM.CreateExchangeRate(Currency.Code, Today, 1, 10);

        // [WHEN] Synchronize Currency 'X'
        SyncCurrency(Currency);

        // [THEN] new Transactioncurrency coupled to 'X', where ISOCurrencyCode, CurrencySymbol, and CurrencyName are in sync
        VerifyTransactionCurrency(Currency, CopyStr(Currency.Code, 1, 5), Currency.Symbol, Currency.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncTableWithAllDisabledFields()
    var
        Currency: Record Currency;
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        // [FEATURE] [Status] [UT]
        Initialize();
        // [GIVEN] Reset CRM Configuration
        ResetCRMConfiguration(false);
        // [GIVEN] Currency 'X'
        Currency.DeleteAll();
        LibraryERM.CreateCurrency(Currency);
        Currency.Description := LibraryUtility.GenerateGUID();
        Currency.Modify();
        LibraryERM.CreateExchangeRate(Currency.Code, Today, 1, 10);
        // [GIVEN] All fields in mapping are disabled
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'CURRENCY');
        IntegrationFieldMapping.ModifyAll(Status, IntegrationFieldMapping.Status::Disabled);

        // [WHEN] Synchronize Currency 'X'
        asserterror SyncCurrency(Currency);

        // [THEN] Error: "There are no field mapping rows..."
        Assert.ExpectedError(NoFieldMappingRowsErr);
        // [THEN] new Transactioncurrency in not created
        asserterror VerifyTransactionCurrency(Currency, '', '', '');
        Assert.ExpectedErrorCannotFind(Database::"CRM Transactioncurrency");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncTableWithPartiallyDisabledFields()
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Currency: Record Currency;
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        // [FEATURE] [Status] [UT]
        Initialize();
        // [GIVEN] Reset CRM Configuration
        ResetCRMConfiguration(false);
        // [GIVEN] Currency 'X'
        Currency.DeleteAll();
        LibraryERM.CreateCurrency(Currency);
        Currency.Description := LibraryUtility.GenerateGUID();
        Currency.Modify();
        LibraryERM.CreateExchangeRate(Currency.Code, Today, 1, 10);
        // [GIVEN] CurrencySymbol and CurrencyName in mapping are disabled, ISOCurrencyCode is enabled
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'CURRENCY');
        IntegrationFieldMapping.ModifyAll(Status, IntegrationFieldMapping.Status::Disabled);
        IntegrationFieldMapping.SetRange("Integration Table Field No.", CRMTransactioncurrency.FieldNo(ISOCurrencyCode));
        IntegrationFieldMapping.ModifyAll(Status, IntegrationFieldMapping.Status::Enabled);

        // [WHEN] Synchronize Currency 'X'
        SyncCurrency(Currency);

        // [THEN] new Transactioncurrency coupled to 'X' is created, where CurrencySymbol is <blank>
        VerifyTransactionCurrency(Currency, CopyStr(Currency.Code, 1, 5), '', '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CreateSOInNAVCopiesCRMOptionFields()
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
    begin
        // [FEATURE] [Sales] [Order] [UT]
        // [SCENARIO] Mapped option fields should be copied to NAV Order by "Create in NAV" action.
        Initialize();
        ResetCRMConfiguration(false);

        // [GIVEN]  CRM Salesorder, where defined "Payment Terms", "Shipping Agent", "Shipment Method"
        CreateCRMSalesorder(CRMSalesorder);
        FillSalesOrderOptionFields(CRMSalesorder);

        // [WHEN] Run 'Create in NAV'
        Assert.IsTrue(CRMSalesOrderToSalesOrder.CreateInNAV(CRMSalesorder, SalesHeader), 'CreateInNAV returned FALSE');

        // [THEN] CRM Sales Order is coupled with the NAV Sales Order
        Assert.IsTrue(
          CRMCouplingManagement.IsRecordCoupledToNAV(CRMSalesorder.SalesOrderId, DATABASE::"Sales Header"),
          'CRMSalesorder is not coupled to a Sales Header.');
        // [THEN] NAV Sales Order contains the same "Payment Terms", "Shipping Agent", "Shipment Method".
        VerifyCRMOptionFields(CRMSalesorder, SalesHeader);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CreateSOInNAVCopiesBillToFields()
    var
        Country: Record "Country/Region";
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
    begin
        // [FEATURE] [Sales] [Order] [UT]
        // [SCENARIO] Mapped "Bill-To" fields should be copied to NAV Order by "Create in NAV" action.
        Initialize();
        ResetCRMConfiguration(false);

        // [GIVEN]  CRM Salesorder, where defined "Bill-To" fields
        CreateCRMSalesorder(CRMSalesorder);
        CRMSalesorder.BillTo_Line1 :=
          Format(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(CRMSalesorder.BillTo_Line1), 1),
            MaxStrLen(CRMSalesorder.BillTo_Line1));
        CRMSalesorder.BillTo_Line2 :=
          Format(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(CRMSalesorder.BillTo_Line2), 1),
            MaxStrLen(CRMSalesorder.BillTo_Line2));
        CRMSalesorder.BillTo_City :=
          Format(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(CRMSalesorder.BillTo_City), 1),
            MaxStrLen(CRMSalesorder.BillTo_City));
        CRMSalesorder.BillTo_PostalCode :=
          Format(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(CRMSalesorder.BillTo_PostalCode), 1),
            MaxStrLen(CRMSalesorder.BillTo_PostalCode));
        CRMSalesorder.BillTo_StateOrProvince :=
          Format(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(CRMSalesorder.BillTo_StateOrProvince), 1),
            MaxStrLen(CRMSalesorder.BillTo_StateOrProvince));
        // [GIVEN] "BillTo_Country" field contains existing NAV Country code
        LibraryERM.CreateCountryRegion(Country);
        CRMSalesorder.BillTo_Country := Country.Code;
        CRMSalesorder.Modify();

        // [WHEN] Run 'Create in NAV'
        Assert.IsTrue(CRMSalesOrderToSalesOrder.CreateInNAV(CRMSalesorder, SalesHeader), 'CreateInNAV returned FALSE');

        // [THEN] CRM Sales Order is coupled with the NAV Sales Order
        Assert.IsTrue(
          CRMCouplingManagement.IsRecordCoupledToNAV(CRMSalesorder.SalesOrderId, DATABASE::"Sales Header"),
          'CRMSalesorder is not coupled to a Sales Header.');
        // [THEN] NAV Sales Order contains "Bill-To" values from CRM Order (cut to maximum length).
        SalesHeader.TestField("Bill-to Address", Format(CRMSalesorder.BillTo_Line1, MaxStrLen(SalesHeader."Bill-to Address")));
        SalesHeader.TestField("Bill-to Address 2", Format(CRMSalesorder.BillTo_Line2, MaxStrLen(SalesHeader."Bill-to Address 2")));
        SalesHeader.TestField("Bill-to City", Format(CRMSalesorder.BillTo_City, MaxStrLen(SalesHeader."Bill-to City")));
        SalesHeader.TestField("Bill-to Post Code", Format(CRMSalesorder.BillTo_PostalCode, MaxStrLen(SalesHeader."Bill-to Post Code")));
        SalesHeader.TestField("Bill-to County", Format(CRMSalesorder.BillTo_StateOrProvince, MaxStrLen(SalesHeader."Bill-to County")));
        SalesHeader.TestField("Bill-to Country/Region Code", Country.Code);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CreateSOInNAVCopiesShipToFields()
    var
        Country: Record "Country/Region";
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
    begin
        // [FEATURE] [Sales] [Order] [UT]
        // [SCENARIO] Mapped "Ship-To" fields should be copied to NAV Order by "Create in NAV" action.
        Initialize();
        ResetCRMConfiguration(false);

        // [GIVEN]  CRM Salesorder, where defined "Ship-To" fields
        CreateCRMSalesorder(CRMSalesorder);
        CRMSalesorder.ShipTo_Line1 :=
          Format(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(CRMSalesorder.ShipTo_Line1), 1),
            MaxStrLen(CRMSalesorder.ShipTo_Line1));
        CRMSalesorder.ShipTo_Line2 :=
          Format(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(CRMSalesorder.ShipTo_Line2), 1),
            MaxStrLen(CRMSalesorder.ShipTo_Line2));
        CRMSalesorder.ShipTo_City :=
          Format(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(CRMSalesorder.ShipTo_City), 1),
            MaxStrLen(CRMSalesorder.ShipTo_City));
        CRMSalesorder.ShipTo_PostalCode :=
          Format(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(CRMSalesorder.ShipTo_PostalCode), 1),
            MaxStrLen(CRMSalesorder.ShipTo_PostalCode));
        CRMSalesorder.ShipTo_StateOrProvince :=
          Format(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(CRMSalesorder.ShipTo_StateOrProvince), 1),
            MaxStrLen(CRMSalesorder.ShipTo_StateOrProvince));
        // [GIVEN] "ShipTo_Country" field contains existing NAV Country code
        LibraryERM.CreateCountryRegion(Country);
        CRMSalesorder.ShipTo_Country := Country.Code;
        CRMSalesorder.Modify();

        // [WHEN] Run 'Create in NAV'
        Assert.IsTrue(CRMSalesOrderToSalesOrder.CreateInNAV(CRMSalesorder, SalesHeader), 'CreateInNAV returned FALSE');

        // [THEN] CRM Sales Order is coupled with the NAV Sales Order
        Assert.IsTrue(
          CRMCouplingManagement.IsRecordCoupledToNAV(CRMSalesorder.SalesOrderId, DATABASE::"Sales Header"),
          'CRMSalesorder is not coupled to a Sales Header.');
        // [THEN] NAV Sales Order contains "Ship-To" values from CRM Order (cut to maximum length).
        SalesHeader.TestField("Ship-to Address", Format(CRMSalesorder.ShipTo_Line1, MaxStrLen(SalesHeader."Ship-to Address")));
        SalesHeader.TestField("Ship-to Address 2", Format(CRMSalesorder.ShipTo_Line2, MaxStrLen(SalesHeader."Ship-to Address 2")));
        SalesHeader.TestField("Ship-to City", Format(CRMSalesorder.ShipTo_City, MaxStrLen(SalesHeader."Ship-to City")));
        SalesHeader.TestField("Ship-to Post Code", Format(CRMSalesorder.ShipTo_PostalCode, MaxStrLen(SalesHeader."Ship-to Post Code")));
        SalesHeader.TestField("Ship-to County", Format(CRMSalesorder.ShipTo_StateOrProvince, MaxStrLen(SalesHeader."Ship-to County")));
        SalesHeader.TestField("Ship-to Country/Region Code", Country.Code);
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncCRMInvoiceUpdatesCRMOptions()
    var
        GLSetup: Record "General Ledger Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CRMOptionMapping: Record "CRM Option Mapping";
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMInvoice: Record "CRM Invoice";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Customer: Record Customer;
        FilteredSalesInvoiceHeader: Record "Sales Invoice Header";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        SalesInvoiceLine: Record "Sales Invoice Line";
        UnitOfMeasure: Record "Unit of Measure";
        CRMUom: Record "CRM Uom";
        CRMUomschedule: Record "CRM Uomschedule";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        LibraryInventory: Codeunit "Library - Inventory";
        CRMId: Guid;
        ExpectedShippingMethodCode: Option;
        ExpectedPaymentTermsCode: Option;
        JobQueueEntryID: Guid;
        NullGuid: Guid;
    begin
        // [FEATURE] [Sales] [Invoice] [Option Mapping]
        // [SCENARIO] Mapped option fields "Payment Terms", "Shipping Agent" should be copied to CRM Invoice.
        Initialize();
        ResetCRMConfiguration(false);

        // [GIVEN] Posted Sales Invoice, where "Payment Terms" = "Net30", "Shipping Agent" = "Airborne"
        ExpectedShippingMethodCode := CRMInvoice.ShippingMethodCodeEnum::Airborne.AsInteger();
        ExpectedPaymentTermsCode := CRMInvoice.PaymentTermsCodeEnum::Net30.AsInteger();

        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        SalesInvoiceHeader."Sell-to Customer No." := Customer."No.";
        GLSetup.Get();
        LibraryCRMIntegration.CreateCRMTransactionCurrency(CRMTransactioncurrency, CopyStr(GLSetup."LCY Code", 1, 5));
        CRMOptionMapping.FindRecordID(
          DATABASE::"CRM Account", CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum), ExpectedShippingMethodCode);
        SalesInvoiceHeader."Shipping Agent Code" :=
          CopyStr(CRMOptionMapping.GetRecordKeyValue(), 1, MaxStrLen(SalesInvoiceHeader."Shipping Agent Code"));
        CRMOptionMapping.FindRecordID(
          DATABASE::"CRM Account", CRMAccount.FieldNo(PaymentTermsCodeEnum), ExpectedPaymentTermsCode);
        SalesInvoiceHeader."Payment Terms Code" :=
          CopyStr(CRMOptionMapping.GetRecordKeyValue(), 1, MaxStrLen(SalesInvoiceHeader."Payment Terms Code"));
        LibraryCRMIntegration.CreateCoupledUnitOfMeasureAndUomSchedule(UnitOfMeasure, CRMUom, CRMUomschedule);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        Item.Modify();
        LibraryCRMIntegration.CreateCRMProduct(CRMProduct, CRMTransactioncurrency, CRMUom);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(Item.RecordId, CRMID);
        CRMIntegrationRecord.SetLastSynchModifiedOns(CRMID, Database::Item, CurrentDateTime() + 1000, CurrentDateTime(), NullGuid, 0);
        Item.Find();
        SalesInvoiceHeader.Insert();
        SalesInvoiceLine."Document No." := SalesInvoiceHeader."No.";
        SalesInvoiceLine."Line No." := 10000;
        SalesInvoiceLine.Type := SalesInvoiceLine.Type::Item;
        SalesInvoiceLine."No." := Item."No.";
        SalesInvoiceLine.Quantity := 1;
        SalesInvoiceLine."Unit Price" := 1;
        SalesInvoiceLine.Insert();

        // [WHEN] Create the new coupled CRM Invoice
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMIntegrationManagement.CreateNewRecordsInCRM(SalesInvoiceHeader.RecordId);
        FilteredSalesInvoiceHeader.SetRange(SystemId, SalesInvoiceHeader.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Sales Invoice Header", FilteredSalesInvoiceHeader.GetView(), IntegrationTableMapping);

        // [THEN] The coupled CRM Invoice is created, where "Payment Terms" = "Net30", "Shipping Agent" = "Airborne"
        Assert.IsTrue(CRMCouplingManagement.IsRecordCoupledToCRM(SalesInvoiceHeader.RecordId), 'Invoice is not coupled.');
        CRMIntegrationRecord.FindIDFromRecordID(SalesInvoiceHeader.RecordId, CRMId);
        CRMInvoice.Get(CRMId);
        CRMInvoice.TestField(ShippingMethodCodeEnum, ExpectedShippingMethodCode);
        CRMInvoice.TestField(PaymentTermsCodeEnum, ExpectedPaymentTermsCode);
        // [THEN] Notification "Syncronization is started." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] Job Queue Entry and Integration Table Mapping records are removed
        // [THEN] IntegrationSynchJob is created, where "Inserted" = 1, no errors.
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactCurrencyShouldGetCodeFromCoupledCurrency()
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Currency: Record Currency;
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
    begin
        // [SCENARIO] Modified TransactionCurrencyId should be synced as "Currency Code" in NAV table
        // [FEATURE] [Currency]
        Initialize();
        ResetCRMConfiguration(false);

        // [GIVEN] Coupled Contacts, where currency is blank
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact, CRMContact);
        // [GIVEN] Coupled Currency 'X'
        LibraryCRMIntegration.CreateCoupledCurrencyAndNotLCYTransactionCurrency(Currency, CRMTransactioncurrency);

        // [GIVEN] CRM Contact's "TransactionCurrencyId" set to 'X'
        CRMContact.TransactionCurrencyId := CRMTransactioncurrency.TransactionCurrencyId;
        CRMContact.Modify();

        // [WHEN] Transfer mapped fields 'CRM Contact-Contact'
        SourceRecordRef.GetTable(CRMContact);
        DestinationRecordRef.GetTable(Contact);
        AddTempIntegrationFieldMapping(
          TempIntegrationFieldMapping, 'CONTACT',
          CRMContact.FieldNo(TransactionCurrencyId), Contact.FieldNo("Currency Code"));
        Assert.IsTrue(
          TransferMappedFields(SourceRecordRef, DestinationRecordRef, TempIntegrationFieldMapping, true),
          'Fields should be modified on transfer');

        // [THEN] Contact is updated, where "Currency Code" is set to 'X'
        DestinationRecordRef.SetTable(Contact);
        Contact.TestField("Currency Code", Currency.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactCurrencyShouldBecomeBlankOnSyncToBlankGUID()
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Currency: Record Currency;
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
    begin
        // [SCENARIO] Modified TransactionCurrencyId to null GUID should be synced as LCY in NAV table
        // [FEATURE] [Currency]
        Initialize();
        ResetCRMConfiguration(false);

        // [GIVEN] Coupled Contacts, where currency is blank
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact, CRMContact);
        // [GIVEN] Coupled Currency 'X'
        LibraryCRMIntegration.CreateCoupledCurrencyAndNotLCYTransactionCurrency(Currency, CRMTransactioncurrency);

        // [GIVEN] CRM Contact, where TransactionCurrencyId is blank
        Clear(CRMTransactioncurrency);
        CRMContact.TransactionCurrencyId := CRMTransactioncurrency.TransactionCurrencyId;
        CRMContact.Modify();
        // [GIVEN] Contact, where Currency Code = 'X'
        Contact."Currency Code" := Currency.Code;
        Contact.Modify(true);

        // [WHEN] Transfer mapped fields 'CRM Contact-Contact'
        SourceRecordRef.GetTable(CRMContact);
        DestinationRecordRef.GetTable(Contact);
        AddTempIntegrationFieldMapping(
          TempIntegrationFieldMapping, 'CONTACT',
          CRMContact.FieldNo(TransactionCurrencyId), Contact.FieldNo("Currency Code"));
        Assert.IsTrue(
          TransferMappedFields(SourceRecordRef, DestinationRecordRef, TempIntegrationFieldMapping, true),
          'Fields should be modified on transfer');

        // [THEN] Contact is updated, where "Currency Code" is blank
        DestinationRecordRef.SetTable(Contact);
        Contact.TestField("Currency Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactCurrencyShouldBecomeBlankOnSyncToLCYGUID()
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Currency: Record Currency;
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
        LCYGUID: Guid;
    begin
        // [SCENARIO] Modified TransactionCurrencyId with code equal to NAV LCY code, should be synced as blank in NAV table
        // [FEATURE] [Currency]
        Initialize();
        ResetCRMConfiguration(false);

        // [GIVEN] Coupled Contacts, where currency is blank
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact, CRMContact);

        // [GIVEN] There is CRM Transaction Currency for NAV LCY
        LibraryCRMIntegration.CreateCRMOrganization();
        LCYGUID := CRMSynchHelper.GetCRMTransactioncurrency('');
        // [GIVEN] Coupled Currency 'X'
        LibraryCRMIntegration.CreateCoupledCurrencyAndNotLCYTransactionCurrency(Currency, CRMTransactioncurrency);

        // [GIVEN] CRM Contact, where TransactionCurrencyId = LCY
        CRMContact.TransactionCurrencyId := LCYGUID;
        CRMContact.Modify();
        // [GIVEN] Contact, where Currency Code = 'X'
        Contact."Currency Code" := Currency.Code;
        Contact.Modify(true);

        // [WHEN] Transfer mapped fields 'CRM Contact-Contact'
        SourceRecordRef.GetTable(CRMContact);
        DestinationRecordRef.GetTable(Contact);
        AddTempIntegrationFieldMapping(
          TempIntegrationFieldMapping, 'CONTACT',
          CRMContact.FieldNo(TransactionCurrencyId), Contact.FieldNo("Currency Code"));
        Assert.IsTrue(
          TransferMappedFields(SourceRecordRef, DestinationRecordRef, TempIntegrationFieldMapping, true),
          'Fields should be modified on transfer');

        // [THEN] Contact is updated, where "Currency Code" is blank
        DestinationRecordRef.SetTable(Contact);
        Contact.TestField("Currency Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMContactCurrencyTransfer()
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Currency: Record Currency;
        TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary;
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
    begin
        // [SCENARIO] Modified "Currency Code" should be synced as TransactionCurrencyId in CRM
        // [FEATURE] [Currency] [Mapping]
        Initialize();
        ResetCRMConfiguration(false);

        // [GIVEN] Coupled Contacts, where currency is blank
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact, CRMContact);

        // [GIVEN] Coupled Currency 'X'
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        // [GIVEN] Contact's "Currency Code" set to 'X'
        Contact.Validate("Currency Code", Currency.Code);
        Contact.Modify();

        // [WHEN] Transfer mapped fields 'Contact-CRM Contact'
        SourceRecordRef.GetTable(Contact);
        DestinationRecordRef.GetTable(CRMContact);
        AddTempIntegrationFieldMapping(
          TempIntegrationFieldMapping, 'CONTACT',
          Contact.FieldNo("Currency Code"), CRMContact.FieldNo(TransactionCurrencyId));
        Assert.IsTrue(
          TransferMappedFields(SourceRecordRef, DestinationRecordRef, TempIntegrationFieldMapping, true),
          'Fields should be modified on transfer');

        // [THEN] CRM Contact is updated, where CRMTransactioncurrency is set to 'X'
        DestinationRecordRef.SetTable(CRMContact);
        CRMContact.TestField(TransactionCurrencyId, CRMTransactioncurrency.TransactionCurrencyId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncContactCountyFromCRM()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        // [FEATURE] [Contact] [County]
        // [SCENARIO] Synchronizing a CRM Contact, where "Address1_StateOrProvince" is modified.
        Initialize();
        ResetCRMConfiguration(false);

        // [GIVEN] Coupled Contact and CRM Contact, where "Address1_StateOrProvince" set to 'Texas'
        CreateCoupledContactsWithParents(Contact, CRMContact);
        CRMContact.Address1_StateOrProvince := 'Texas';
        CRMContact.Modify();

        // [WHEN] Synchronize CRM Contact to Contact
        IntegrationTableMapping.Get('CONTACT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMContact.ContactId, true, false);

        // [THEN] Contact, where "County" = 'Texas'
        Contact.Find();
        Contact.TestField(County, CRMContact.Address1_StateOrProvince);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncContactCountyFromNAV()
    var

        IntegrationTableMapping: Record "Integration Table Mapping";
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        // [FEATURE] [Contact] [County] [Not Null]
        // [SCENARIO] Synchronizing a contact, where County is modified in NAV
        Initialize();
        ResetCRMConfiguration(false);

        // [GIVEN] Coupled CRM Contact and Contact, where "County" set to 'Texas'
        CreateCoupledContactsWithParents(Contact, CRMContact);
        Contact."Salesperson Code" := '';
        Contact.County := 'Texas';
        Contact.Modify(true);

        // [WHEN] Synchronize Contact to CRM Contact
        IntegrationTableMapping.Get('CONTACT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Contact.RecordId, true, false);

        // [THEN] CRM Contact, where "Address_StateOrProvince" = 'Texas'
        CRMContact.Get(CRMContact.ContactId);
        CRMContact.TestField(Address1_StateOrProvince, Contact.County);
        // [THEN] OwnerID is not null, though Salesperson Code is <blank>
        Contact.TestField("Salesperson Code", '');
        CRMContact.TestField(OwnerId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncCustomerCountyFromCRM()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        // [FEATURE] [Customer] [County]
        // [SCENARIO] Synchronizing a CRM Account, where "Address1_StateOrProvince" is modified.
        Initialize();
        ResetCRMConfiguration(false);

        // [GIVEN] Coupled Customer and CRM Account, where "Address1_StateOrProvince" set to 'Texas'
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMAccount.Address1_StateOrProvince := 'Texas';
        CRMAccount.Modify();

        // [WHEN] Synchronize CRM Account to Customer
        IntegrationTableMapping.Get('CUSTOMER');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMAccount.AccountId, true, false);

        // [THEN] Modified Customer, where "County" = 'Texas'
        Customer.Find();
        Customer.TestField(County, CRMAccount.Address1_StateOrProvince);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncCustomerCountyFromNAV()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        // [FEATURE] [Customer] [County]
        // [SCENARIO] Synchronizing a customer, where County is modified in NAV
        Initialize();
        ResetCRMConfiguration(false);

        // [GIVEN] Coupled CRM Account and Customer, where "County" set to 'Texas'
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        Customer.County := 'Texas';
        Customer.Modify();

        // [WHEN] Synchronizing the customer
        IntegrationTableMapping.Get('CUSTOMER');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);

        // [THEN] CRM Account, where "Address_StateOrProvince" = 'Texas'
        CRMAccount.Get(CRMAccount.AccountId);
        CRMAccount.TestField(Address1_StateOrProvince, Customer.County);
    end;

    [Test]
    //[TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CRMAccountListIntergationTableFilter()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMAccount: array[2] of Record "CRM Account";
        CRMAccountList: TestPage "CRM Account List";
        i: Integer;
    begin
        // [FEATURE] [Integration Table Filter]
        // [SCENARIO 253405] Integration Table Filter for CUSTOMER is applied to CRM Account page
        Initialize();

        // [GIVEN] CRM Accounts with Name=A and Name=B
        for i := 1 to 2 do begin
            LibraryCRMIntegration.CreateCRMAccount(CRMAccount[i]);
            CRMAccount[i].Name := Format(CreateGuid());
            CRMAccount[i].Modify();
        end;

        // [GIVEN] The CUSTOMER mapping, where "Integration Table Filter" is Name=A
        FindIntTableMapping(IntegrationTableMapping, DATABASE::Customer, DATABASE::"CRM Account");
        CRMAccount[1].SetRange(Name, CRMAccount[1].Name);
        SetIntTableFilter(IntegrationTableMapping, CRMAccount[1].GetView());

        // [WHEN] Page CRM Account List is being opened
        CRMAccountList.OpenView();

        // [THEN] Page contains CRM Account with Name=A
        Assert.IsTrue(CRMAccountList.GotoRecord(CRMAccount[1]), ExpectedRecordNotFoundErr);

        // [THEN] Page does not contain CRM Account with Name=B
        Assert.IsFalse(CRMAccountList.GotoRecord(CRMAccount[2]), UnexpectedRecordFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMContactListIntergationTableFilter()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMContact: array[2] of Record "CRM Contact";
        CRMContactList: TestPage "CRM Contact List";
        i: Integer;
    begin
        // [FEATURE] [Integration Table Filter]
        // [SCENARIO 253405] Integration Table Filter for CONTACT is applied to CRM Contact page
        Initialize();

        // [GIVEN] CRM Contacts with FullName=A and FullName=B
        for i := 1 to 2 do begin
            LibraryCRMIntegration.CreateCRMContact(CRMContact[i]);
            CRMContact[i].FullName := Format(CreateGuid());
            CRMContact[i].Modify();
        end;

        // [GIVEN] The CONTACT mapping, where "Integration Table Filter" is FullName=A
        FindIntTableMapping(IntegrationTableMapping, DATABASE::Contact, DATABASE::"CRM Contact");
        CRMContact[1].SetRange(FullName, CRMContact[1].FullName);
        SetIntTableFilter(IntegrationTableMapping, CRMContact[1].GetView());

        // [WHEN] Page CRM Contact List is being opened
        CRMContactList.OpenView();

        // [THEN] Page contains CRM Contact with FullName=A
        Assert.IsTrue(CRMContactList.GotoRecord(CRMContact[1]), ExpectedRecordNotFoundErr);

        // [THEN] Page does not contain CRM Contact with FullName=B
        Assert.IsFalse(CRMContactList.GotoRecord(CRMContact[2]), UnexpectedRecordFoundErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CRMOpportunityListIntergationTableFilter()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMOpportunity: array[2] of Record "CRM Opportunity";
        CRMOpportunityList: TestPage "CRM Opportunity List";
        i: Integer;
    begin
        // [FEATURE] [Integration Table Filter] [Opportunity]
        // [SCENARIO 253405] Integration Table Filter for OPPORTUNITY is applied to CRM Opportunity List page
        Initialize();

        // [GIVEN] CRM Opportunities with Name=A and Name=B
        for i := 1 to 2 do begin
            LibraryCRMIntegration.CreateCRMOpportunity(CRMOpportunity[i]);
            CRMOpportunity[i].Name := Format(CreateGuid());
            CRMOpportunity[i].Modify();
        end;

        // [GIVEN] The OPPORTUNITY mapping, where "Integration Table Filter" is Name=A
        FindIntTableMapping(IntegrationTableMapping, DATABASE::Opportunity, DATABASE::"CRM Opportunity");
        CRMOpportunity[1].SetRange(Name, CRMOpportunity[1].Name);
        SetIntTableFilter(IntegrationTableMapping, CRMOpportunity[1].GetView());

        // [WHEN] Page CRM Opportunity List is being opened
        CRMOpportunityList.OpenView();

        // [THEN] Page contains CRM Opportunity with Name=A
        Assert.IsTrue(CRMOpportunityList.GotoRecord(CRMOpportunity[1]), ExpectedRecordNotFoundErr);

        // [THEN] Page does not contain CRM Opportunity with Name=B
        Assert.IsFalse(CRMOpportunityList.GotoRecord(CRMOpportunity[2]), UnexpectedRecordFoundErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CRMProductListIntergationTableFilter()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMProduct: array[3] of Record "CRM Product";
        CRMProductList: TestPage "CRM Product List";
        i: Integer;
    begin
        // [FEATURE] [Integration Table Filter] [Item] [Resource]
        // [SCENARIO 253405] Common Integration Table Filter for ITEM-PRODUCT and RESOURCE-PRODUCT is applied to CRM Product List page
        Initialize();

        // [GIVEN] CRM Products with Name=A, Name=B and Name=C
        for i := 1 to 3 do begin
            CRMProduct[i].Init();
            CRMProduct[i].ProductId := CreateGuid();
            CRMProduct[i].Name := Format(CreateGuid());
            CRMProduct[i].Insert();
        end;

        // [GIVEN] The ITEM-PRODUCT mapping, where "Integration Table Filter" is Name=A
        FindIntTableMapping(IntegrationTableMapping, DATABASE::Item, DATABASE::"CRM Product");
        CRMProduct[1].SetRange(Name, CRMProduct[1].Name);
        SetIntTableFilter(IntegrationTableMapping, CRMProduct[1].GetView());

        // [GIVEN] The RESOURCE-PRODUCT mapping, where "Integration Table Filter" is Name=B
        FindIntTableMapping(IntegrationTableMapping, DATABASE::Resource, DATABASE::"CRM Product");
        CRMProduct[2].SetRange(Name, CRMProduct[2].Name);
        SetIntTableFilter(IntegrationTableMapping, CRMProduct[2].GetView());

        // [WHEN] Page CRM Product List is being opened
        CRMProductList.OpenView();

        // [THEN] Page contains CRM Product with Name=A
        Assert.IsTrue(CRMProductList.GotoRecord(CRMProduct[1]), ExpectedRecordNotFoundErr);

        // [THEN] Page contains CRM Product with Name=B
        Assert.IsTrue(CRMProductList.GotoRecord(CRMProduct[2]), ExpectedRecordNotFoundErr);

        // [THEN] Page does not contain CRM Product with Name=C
        Assert.IsFalse(CRMProductList.GotoRecord(CRMProduct[3]), UnexpectedRecordFoundErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CRMCurrencyListIntergationTableFilter()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMTransactioncurrency: array[2] of Record "CRM Transactioncurrency";
        CRMTransactionCurrencyList: TestPage "CRM TransactionCurrency List";
        i: Integer;
    begin
        // [FEATURE] [Integration Table Filter] [Currency]
        // [SCENARIO 253405] Integration Table Filter for CURRENCY is applied to CRM TransactionCurrency List page
        Initialize();

        // [GIVEN] CRM Transactioncurrencies with CurrencyName=A and CurrencyName=B
        for i := 1 to 2 do begin
            LibraryCRMIntegration.CreateCRMTransactionCurrency(CRMTransactioncurrency[i], 'USD');
            CRMTransactioncurrency[i].CurrencyName := Format(CreateGuid());
            CRMTransactioncurrency[i].Modify();
        end;

        // [GIVEN] The CURRENCY mapping, where "Integration Table Filter" is CurrencyName=A
        FindIntTableMapping(IntegrationTableMapping, DATABASE::Currency, DATABASE::"CRM Transactioncurrency");
        CRMTransactioncurrency[1].SetRange(CurrencyName, CRMTransactioncurrency[1].CurrencyName);
        SetIntTableFilter(IntegrationTableMapping, CRMTransactioncurrency[1].GetView());

        // [WHEN] Page CRM TransactionCurrency List is being opened
        CRMTransactionCurrencyList.OpenView();

        // [THEN] Page contains CRM Transactioncurrency with CurrencyName=A
        Assert.IsTrue(CRMTransactionCurrencyList.GotoRecord(CRMTransactioncurrency[1]), ExpectedRecordNotFoundErr);

        // [THEN] Page does not contain CRM Transactioncurrency with CurrencyName=B
        Assert.IsFalse(CRMTransactionCurrencyList.GotoRecord(CRMTransactioncurrency[2]), UnexpectedRecordFoundErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CRMUnitGroupListIntergationTableFilter()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMUomschedule: array[2] of Record "CRM Uomschedule";
        CRMUnitGroupList: TestPage "CRM UnitGroup List";
        i: Integer;
    begin
        // [FEATURE] [Integration Table Filter] [Unit of Measure]
        // [SCENARIO 253405] Integration Table Filter for UNIT OF MEASURE is applied to CRM UnitGroup List page
        Initialize();

        // [GIVEN] CRM Uomschedules with Name=A and Name=B
        for i := 1 to 2 do begin
            CRMUomschedule[i].Init();
            CRMUomschedule[i].UoMScheduleId := CreateGuid();
            CRMUomschedule[i].Name := Format(CreateGuid());
            CRMUomschedule[i].Insert();
        end;

        // [GIVEN] The UNIT OF MEASURE mapping, where "Integration Table Filter" is Name=AAAAA
        FindIntTableMapping(IntegrationTableMapping, DATABASE::"Unit of Measure", DATABASE::"CRM Uomschedule");
        CRMUomschedule[1].SetRange(Name, CRMUomschedule[1].Name);
        SetIntTableFilter(IntegrationTableMapping, CRMUomschedule[1].GetView());

        // [WHEN] Page CRM TransactionCurrency List is being opened
        CRMUnitGroupList.OpenView();

        // [THEN] Page contains CRM Uomschedule with Name=A
        Assert.IsTrue(CRMUnitGroupList.GotoRecord(CRMUomschedule[1]), ExpectedRecordNotFoundErr);

        // [THEN] Page does not contain CRM Uomschedule with Name=B
        Assert.IsFalse(CRMUnitGroupList.GotoRecord(CRMUomschedule[2]), UnexpectedRecordFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IntegrationTableFilterAssistEdit()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMConnectionSetup: Record "CRM Connection Setup";
        IntegrationTableMappingList: TestPage "Integration Table Mapping List";
    begin
        // [FEATURE] [Integration Table Filter]
        // [SCENARIO 264152] Assist edit works for Integration Table Filter when CRM Integration Enabled State is unknown
        Initialize();

        // [GIVEN] Integration table mapping for customer table
        LibraryCRMIntegration.CreateIntegrationTableMappingCustomer(IntegrationTableMapping);

        // [GIVEN] Mock unregistered connection
        CRMConnectionSetup.Get();
        CRMConnectionSetup.TestField("Is Enabled", true);
        CRMConnectionSetup.UnregisterConnection();
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM));

        // [GIVEN] Open Integration table mapping list
        IntegrationTableMappingList.OpenEdit();
        IntegrationTableMappingList.GotoRecord(IntegrationTableMapping);

        // [WHEN] Assist edit on Integration Table Filter field is being run
        IntegrationTableMappingList.IntegrationTableFilter.AssistEdit();

        // [THEN] Connection has been registered
        Assert.IsTrue(
          HasTableConnection(TABLECONNECTIONTYPE::CRM, GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM)),
          'HASTABLECONNECTION disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmYesHandler,HandleJobQueueuEntriesPage')]
    procedure ResetIntegrationTableMappingConfiguration()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMSystemUser: Record "CRM Systemuser";
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        CRMTransactionCurrency: Record "CRM Transactioncurrency";
        CRMProduct: Record "CRM Product";
        CRMOpportunity: Record "CRM Opportunity";
        CRMInvoice: Record "CRM Invoice";
        CRMInvoiceDetail: Record "CRM Invoicedetail";
        CRMUomschedule: Record "CRM Uomschedule";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProductPricelevel: Record "CRM Productpricelevel";
        IntegrationTableMappingList: TestPage "Integration Table Mapping List";
        IntegrationTableMappingsNo: Integer;
    begin
        // [FEATURE] [Use CRM/CDS Setup Defaults per Integration Table Mapping record]
        Initialize();

        // [WHEN] Reset CRM Configuration
        ResetCRMConfiguration(false);

        // [GIVEN] The number of Integration Table Mappings
        IntegrationTableMappingsNo := IntegrationTableMapping.Count();

        // [GIVEN] Open 'Integration Table Mapping List' page
        IntegrationTableMappingList.OpenEdit();

        // [GIVEN] All Integration Table Mappings are selected
        IntegrationTableMapping.Mark();

        // [WHEN] Custom configurations are done to the Integration Table Mappings
        ModifyIntegrationTableMappingDirection(DATABASE::"Salesperson/Purchaser", DATABASE::"CRM Systemuser");
        ModifyIntegrationTableMappingDirection(DATABASE::Customer, DATABASE::"CRM Account");
        ModifyIntegrationTableMappingDirection(DATABASE::Contact, DATABASE::"CRM Contact");
        ModifyIntegrationTableMappingDirection(DATABASE::Currency, DATABASE::"CRM Transactioncurrency");
        ModifyIntegrationTableMappingDirection(DATABASE::Item, DATABASE::"CRM Product");
        ModifyIntegrationTableMappingDirection(DATABASE::Opportunity, DATABASE::"CRM Opportunity");
        ModifyIntegrationTableMappingDirection(DATABASE::Resource, DATABASE::"CRM Product");
        ModifyIntegrationTableMappingDirection(DATABASE::"Sales Invoice Header", DATABASE::"CRM Invoice");
        ModifyIntegrationTableMappingDirection(DATABASE::"Sales Invoice Line", DATABASE::"CRM Invoicedetail");
        ModifyIntegrationTableMappingDirection(DATABASE::"Unit of Measure", DATABASE::"CRM Uomschedule");
        ModifyIntegrationTableMappingDirection(DATABASE::"Customer Price Group", DATABASE::"CRM Pricelevel");
        ModifyIntegrationTableMappingDirection(DATABASE::"Sales Price", DATABASE::"CRM Productpricelevel");
        ModifyIntegrationTableMappingDirection(DATABASE::"Shipping Agent", DATABASE::"CRM Account");
        ModifyIntegrationTableMappingDirection(DATABASE::"Shipment Method", DATABASE::"CRM Account");
        ModifyIntegrationTableMappingDirection(DATABASE::"Payment Terms", DATABASE::"CRM Account");

        // [WHEN] Run action 'Reset Configuration'
        IntegrationTableMappingList.ResetConfiguration.Invoke();

        // [THEN] Number of Integration Table Mappings created is equal to the previous number of Integration Table Mappings
        IntegrationTableMapping.Reset();
        Assert.AreEqual(IntegrationTableMappingsNo, IntegrationTableMapping.Count(), 'The number of integration table mappings after reset is not equal to the initial integration table mappings number.');

        // [THEN] All integration Table Mappings have been recreatd and the field mapping configuration resetted to default
        VerifyMapping(
              IntegrationTableMapping, DATABASE::"Salesperson/Purchaser", DATABASE::"CRM Systemuser", CRMSystemuser.FieldNo(SystemUserId), 3, 2, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::Customer, DATABASE::"CRM Account", CRMAccount.FieldNo(AccountId), 20, 0, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
            IntegrationTableMapping, DATABASE::Contact, DATABASE::"CRM Contact", CRMContact.FieldNo(ContactId), 20, 0, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
                  IntegrationTableMapping, DATABASE::Currency, DATABASE::"CRM Transactioncurrency",
                  CRMTransactioncurrency.FieldNo(TransactionCurrencyId), 3, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::Item, DATABASE::"CRM Product",
          CRMProduct.FieldNo(ProductId), 11, IntegrationTableMapping.Direction::Bidirectional, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
                  IntegrationTableMapping, DATABASE::Opportunity, DATABASE::"CRM Opportunity", CRMOpportunity.FieldNo(OpportunityId),
                  7, IntegrationTableMapping.Direction::Bidirectional, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 0);

        VerifyMapping(
                  IntegrationTableMapping, DATABASE::Resource, DATABASE::"CRM Product",
                  CRMProduct.FieldNo(ProductId), 7, IntegrationTableMapping.Direction::Bidirectional, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
                  IntegrationTableMapping, DATABASE::"Sales Invoice Header", DATABASE::"CRM Invoice", CRMInvoice.FieldNo(InvoiceId), 26, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Sales Invoice Line", DATABASE::"CRM Invoicedetail",
          CRMInvoicedetail.FieldNo(InvoiceDetailId), 6, 1, false);
        VerifyNoJobQueueEntry(IntegrationTableMapping);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Unit of Measure", DATABASE::"CRM Uomschedule", CRMUomschedule.FieldNo(UoMScheduleId), 1, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Customer Price Group", DATABASE::"CRM Pricelevel", CRMPricelevel.FieldNo(PriceLevelId), 1, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Sales Price", DATABASE::"CRM Productpricelevel",
          CRMProductpricelevel.FieldNo(ProductPriceLevelId), 6, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
                  IntegrationTableMapping, DATABASE::"Shipping Agent", DATABASE::"CRM Account",
                  CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum), 1, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
                  IntegrationTableMapping, DATABASE::"Shipment Method", DATABASE::"CRM Account", CRMAccount.FieldNo(Address1_FreightTermsCodeEnum), 1, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Payment Terms", DATABASE::"CRM Account", CRMAccount.FieldNo(PaymentTermsCodeEnum), 1, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure ResetIntegrationTableMappingConfigurationExtendedPrice()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMSystemUser: Record "CRM Systemuser";
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        CRMTransactionCurrency: Record "CRM Transactioncurrency";
        CRMProduct: Record "CRM Product";
        CRMOpportunity: Record "CRM Opportunity";
        CRMInvoice: Record "CRM Invoice";
        CRMInvoiceDetail: Record "CRM Invoicedetail";
        CRMUomschedule: Record "CRM Uomschedule";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProductPricelevel: Record "CRM Productpricelevel";
        IntegrationTableMappingList: TestPage "Integration Table Mapping List";
        IntegrationTableMappingsNo: Integer;
    begin
        // [FEATURE] [Use CRM/CDS Setup Defaults per Integration Table Mapping record]
        Initialize(true, false);

        // [WHEN] Reset CRM Configuration
        ResetCRMConfiguration(false);

        // [GIVEN] The number of Integration Table Mappings
        IntegrationTableMappingsNo := IntegrationTableMapping.Count();

        // [GIVEN] Open 'Integration Table Mapping List' page
        IntegrationTableMappingList.OpenEdit();

        // [GIVEN] All Integration Table Mappings are selected
        IntegrationTableMapping.Mark();

        // [WHEN] Custom configurations are done to the Integration Table Mappings
        ModifyIntegrationTableMappingDirection(DATABASE::"Salesperson/Purchaser", DATABASE::"CRM Systemuser");
        ModifyIntegrationTableMappingDirection(DATABASE::Customer, DATABASE::"CRM Account");
        ModifyIntegrationTableMappingDirection(DATABASE::Contact, DATABASE::"CRM Contact");
        ModifyIntegrationTableMappingDirection(DATABASE::Currency, DATABASE::"CRM Transactioncurrency");
        ModifyIntegrationTableMappingDirection(DATABASE::Item, DATABASE::"CRM Product");
        ModifyIntegrationTableMappingDirection(DATABASE::Opportunity, DATABASE::"CRM Opportunity");
        ModifyIntegrationTableMappingDirection(DATABASE::Resource, DATABASE::"CRM Product");
        ModifyIntegrationTableMappingDirection(DATABASE::"Sales Invoice Header", DATABASE::"CRM Invoice");
        ModifyIntegrationTableMappingDirection(DATABASE::"Sales Invoice Line", DATABASE::"CRM Invoicedetail");
        ModifyIntegrationTableMappingDirection(DATABASE::"Unit of Measure", DATABASE::"CRM Uomschedule");
        ModifyIntegrationTableMappingDirection(DATABASE::"Price List Header", DATABASE::"CRM Pricelevel");
        ModifyIntegrationTableMappingDirection(DATABASE::"Price List Line", DATABASE::"CRM Productpricelevel");
        ModifyIntegrationTableMappingDirection(DATABASE::"Shipping Agent", DATABASE::"CRM Account");
        ModifyIntegrationTableMappingDirection(DATABASE::"Shipment Method", DATABASE::"CRM Account");
        ModifyIntegrationTableMappingDirection(DATABASE::"Payment Terms", DATABASE::"CRM Account");

        // [WHEN] Run action 'Reset Configuration'
        IntegrationTableMappingList.ResetConfiguration.Invoke();

        // [THEN] Number of Integration Table Mappings created is equal to the previous number of Integration Table Mappings
        IntegrationTableMapping.Reset();
        Assert.AreEqual(IntegrationTableMappingsNo, IntegrationTableMapping.Count(), 'The number of integration table mappings after reset is not equal to the initial integration table mappings number.');

        // [THEN] All integration Table Mappings have been recreatd and the field mapping configuration resetted to default
        VerifyMapping(
              IntegrationTableMapping, DATABASE::"Salesperson/Purchaser", DATABASE::"CRM Systemuser", CRMSystemuser.FieldNo(SystemUserId), 3, 2, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::Customer, DATABASE::"CRM Account", CRMAccount.FieldNo(AccountId), 20, 0, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
            IntegrationTableMapping, DATABASE::Contact, DATABASE::"CRM Contact", CRMContact.FieldNo(ContactId), 20, 0, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
                  IntegrationTableMapping, DATABASE::Currency, DATABASE::"CRM Transactioncurrency",
                  CRMTransactioncurrency.FieldNo(TransactionCurrencyId), 3, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::Item, DATABASE::"CRM Product",
          CRMProduct.FieldNo(ProductId), 11, IntegrationTableMapping.Direction::Bidirectional, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
                  IntegrationTableMapping, DATABASE::Opportunity, DATABASE::"CRM Opportunity", CRMOpportunity.FieldNo(OpportunityId),
                  7, IntegrationTableMapping.Direction::Bidirectional, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 0);

        VerifyMapping(
                  IntegrationTableMapping, DATABASE::Resource, DATABASE::"CRM Product",
                  CRMProduct.FieldNo(ProductId), 7, IntegrationTableMapping.Direction::Bidirectional, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
                  IntegrationTableMapping, DATABASE::"Sales Invoice Header", DATABASE::"CRM Invoice", CRMInvoice.FieldNo(InvoiceId), 26, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Sales Invoice Line", DATABASE::"CRM Invoicedetail",
          CRMInvoicedetail.FieldNo(InvoiceDetailId), 6, 1, false);
        VerifyNoJobQueueEntry(IntegrationTableMapping);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Unit of Measure", DATABASE::"CRM Uomschedule", CRMUomschedule.FieldNo(UoMScheduleId), 1, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Price List Header", DATABASE::"CRM Pricelevel",
          CRMPricelevel.FieldNo(PriceLevelId), 5, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Price List Line", DATABASE::"CRM Productpricelevel",
          CRMProductpricelevel.FieldNo(ProductPriceLevelId), 7, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
                  IntegrationTableMapping, DATABASE::"Shipping Agent", DATABASE::"CRM Account",
                  CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum), 1, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
                  IntegrationTableMapping, DATABASE::"Shipment Method", DATABASE::"CRM Account", CRMAccount.FieldNo(Address1_FreightTermsCodeEnum), 1, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);

        VerifyMapping(
          IntegrationTableMapping, DATABASE::"Payment Terms", DATABASE::"CRM Account", CRMAccount.FieldNo(PaymentTermsCodeEnum), 1, 1, false);
        VerifyJobQueueEntry(IntegrationTableMapping, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CreateSOInNAVCopiesCustomerContactFields()
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
    begin
        // [FEATURE] [Sales] [Order] [UT]
        // [SCENARIO] Contact details for a customer should be added to the sales order.
        Initialize();
        ResetCRMConfiguration(false);

        // [GIVEN] A company (and its contact details).
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        ContBusRel.SetCurrentKey("Link to Table", "No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
        ContBusRel.SetRange("No.", Customer."No.");
        ContBusRel.FindFirst();

        Contact.Get(ContBusRel."Contact No.");
        Contact.Validate("E-Mail", 'test@test.com');
        Contact.Validate("Phone No.", '12345678');
        Contact.Modify(true);

        // [GIVEN] A CRM Salesorder.
        LibraryCRMIntegration.CreateCRMSalesOrder(CRMSalesorder);
        CRMSalesorder.OrderNumber := LibraryUtility.GenerateGUID();
        CRMSalesorder.StateCode := CRMSalesorder.StateCode::Submitted;
        CRMSalesorder.CustomerId := CRMAccount.AccountId;
        CRMSalesorder.CustomerIdType := CRMSalesorder.CustomerIdType::account;

        // [WHEN] Running 'Create in NAV'
        Assert.IsTrue(CRMSalesOrderToSalesOrder.CreateInNAV(CRMSalesorder, SalesHeader), 'CreateInNAV returned FALSE');

        // [THEN] NAV Sales Order contains contact details related to the customer.
        SalesHeader.TestField("Sell-to E-Mail", Contact."E-Mail");
        SalesHeader.TestField("Sell-to Phone No.", Contact."Phone No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertTableInManualIntegrationTableMapping()
    var
        ManIntegrationTableMapping: Record "Man. Integration Table Mapping";
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        // [FEATURE] [Manual Integration Table Mapping]
        // [SCENARIO] Insert a table ID in the Manual Integration Table Mapping
        Initialize();
        // [GIVEN] a random table ID
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetRange("Object Subtype", 'Normal');
        if AllObjWithCaption.FindFirst() then;

        // [WHEN] Inserting the table ID in the Manual Integration Table Mapping
        InsertIntegrationTableMapping(AllObjWithCaption."Object ID", 0);

        // [THEN] the table ID is inserted in the Manual Integration Table Mapping
        Assert.AreEqual(1, ManIntegrationTableMapping.Count, 'the record set should include 1 record');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InsertIntegrationTableInManualIntegrationTableMapping()
    var
        ManIntegrationTableMapping: Record "Man. Integration Table Mapping";
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        // [FEATURE] [Manual Integration Table Mapping]
        // [SCENARIO] Insert a IntegrationTable ID in the Manual Integration Table Mapping
        Initialize();
        // [GIVEN] a random integration table ID
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetRange("Object Subtype", 'CDS');
        if AllObjWithCaption.FindFirst() then;

        // [WHEN] Inserting the table ID in the Manual Integration Table Mapping
        InsertIntegrationTableMapping(0, AllObjWithCaption."Object ID");

        // [THEN] the table ID is inserted in the Manual Integration Table Mapping
        Assert.AreEqual(1, ManIntegrationTableMapping.Count, 'the record set should include 1 record');
    end;

    [Test]
    procedure IntegrationTableMappingTestIsEnabledForBidirectionalTableAndField()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        // [FEATURE] [Integration Table - Is Enabled]
        // [SCENARIO] IsMappingEnabled and IsFieldMappingEnabled return correct values for different combinations of requested direction and table/field direction
        Initialize();

        // [GIVEN] Integration table bidirectional mapping
        CreateIntegrationTableMappingWithFieldMapping(IntegrationTableMapping, IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::Bidirectional);

        // [WHEN] The IsMappingEnabled is called
        // [THEN] The mapping should be enabled
        Assert.IsTrue(IntegrationTableMapping.IsMappingEnabled(IntegrationTableMapping.Direction::Bidirectional), 'The mapping should be enabled');
        Assert.IsTrue(IntegrationTableMapping.IsMappingEnabled(IntegrationTableMapping.Direction::ToIntegrationTable), 'The mapping should be enabled');
        Assert.IsTrue(IntegrationTableMapping.IsMappingEnabled(IntegrationTableMapping.Direction::FromIntegrationTable), 'The mapping should be enabled');

        // [WHEN] The IsFieldMappingEnabled is called
        // [THEN] The mapping should be enabled
        Assert.IsTrue(IntegrationTableMapping.IsFieldMappingEnabled(Customer.FieldNo("No."), CRMAccount.FieldNo(AccountNumber), IntegrationTableMapping.Direction::Bidirectional), 'The mapping should be enabled');
        Assert.IsTrue(IntegrationTableMapping.IsFieldMappingEnabled(Customer.FieldNo("No."), CRMAccount.FieldNo(AccountNumber), IntegrationTableMapping.Direction::ToIntegrationTable), 'The mapping should be enabled');
        Assert.IsTrue(IntegrationTableMapping.IsFieldMappingEnabled(Customer.FieldNo("No."), CRMAccount.FieldNo(AccountNumber), IntegrationTableMapping.Direction::FromIntegrationTable), 'The mapping should be enabled');
    end;

    [Test]
    procedure IntegrationTableMappingTestIsEnabledForFromIntegrationTableAndField()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        // [FEATURE] [Integration Table - Is Enabled]
        // [SCENARIO] IsMappingEnabled and IsFieldMappingEnabled return correct values for different combinations of requested direction and table/field direction
        Initialize();

        // [GIVEN] Integration table bidirectional mapping
        CreateIntegrationTableMappingWithFieldMapping(IntegrationTableMapping, IntegrationTableMapping.Direction::FromIntegrationTable, IntegrationTableMapping.Direction::FromIntegrationTable);

        // [WHEN] The IsMappingEnabled is called
        // [THEN] The mapping should be enabled for FromIntegrationTable only
        Assert.IsFalse(IntegrationTableMapping.IsMappingEnabled(IntegrationTableMapping.Direction::Bidirectional), 'The mapping should not be enabled');
        Assert.IsFalse(IntegrationTableMapping.IsMappingEnabled(IntegrationTableMapping.Direction::ToIntegrationTable), 'The mapping should not be enabled');
        Assert.IsTrue(IntegrationTableMapping.IsMappingEnabled(IntegrationTableMapping.Direction::FromIntegrationTable), 'The mapping should be enabled');

        // [WHEN] The IsFieldMappingEnabled is called
        // [THEN] The mapping should be enabled for FromIntegrationTable only
        Assert.IsFalse(IntegrationTableMapping.IsFieldMappingEnabled(Customer.FieldNo("No."), CRMAccount.FieldNo(AccountNumber), IntegrationTableMapping.Direction::Bidirectional), 'The mapping should not be enabled');
        Assert.IsFalse(IntegrationTableMapping.IsFieldMappingEnabled(Customer.FieldNo("No."), CRMAccount.FieldNo(AccountNumber), IntegrationTableMapping.Direction::ToIntegrationTable), 'The mapping should not be enabled');
        Assert.IsTrue(IntegrationTableMapping.IsFieldMappingEnabled(Customer.FieldNo("No."), CRMAccount.FieldNo(AccountNumber), IntegrationTableMapping.Direction::FromIntegrationTable), 'The mapping should be enabled');
    end;

    [Test]
    procedure IntegrationTableMappingTestIsEnabledForToIntegrationTableAndField()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        // [FEATURE] [Integration Table - Is Enabled]
        // [SCENARIO] IsMappingEnabled and IsFieldMappingEnabled return correct values for different combinations of requested direction and table/field direction
        Initialize();

        // [GIVEN] Integration table bidirectional mapping
        CreateIntegrationTableMappingWithFieldMapping(IntegrationTableMapping, IntegrationTableMapping.Direction::ToIntegrationTable, IntegrationTableMapping.Direction::ToIntegrationTable);

        // [WHEN] The IsMappingEnabled is called
        // [THEN] The mapping should be enabled for ToIntegrationTable only
        Assert.IsFalse(IntegrationTableMapping.IsMappingEnabled(IntegrationTableMapping.Direction::Bidirectional), 'The mapping should not be enabled');
        Assert.IsTrue(IntegrationTableMapping.IsMappingEnabled(IntegrationTableMapping.Direction::ToIntegrationTable), 'The mapping should be enabled');
        Assert.IsFalse(IntegrationTableMapping.IsMappingEnabled(IntegrationTableMapping.Direction::FromIntegrationTable), 'The mapping should not be enabled');

        // [WHEN] The IsFieldMappingEnabled is called
        // [THEN] The mapping should be enabled for ToIntegrationTable only
        Assert.IsFalse(IntegrationTableMapping.IsFieldMappingEnabled(Customer.FieldNo("No."), CRMAccount.FieldNo(AccountNumber), IntegrationTableMapping.Direction::Bidirectional), 'The mapping should not be enabled');
        Assert.IsTrue(IntegrationTableMapping.IsFieldMappingEnabled(Customer.FieldNo("No."), CRMAccount.FieldNo(AccountNumber), IntegrationTableMapping.Direction::ToIntegrationTable), 'The mapping should be enabled');
        Assert.IsFalse(IntegrationTableMapping.IsFieldMappingEnabled(Customer.FieldNo("No."), CRMAccount.FieldNo(AccountNumber), IntegrationTableMapping.Direction::FromIntegrationTable), 'The mapping should not be enabled');
    end;

    [Test]
    procedure IntegrationTableMappingTestIsEnabledForToIntegrationTableAndBidirectionalField()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        // [FEATURE] [Integration Table - Is Enabled]
        // [SCENARIO] IsMappingEnabled and IsFieldMappingEnabled return correct values for different combinations of requested direction and table/field direction
        Initialize();

        // [GIVEN] Integration table bidirectional mapping
        CreateIntegrationTableMappingWithFieldMapping(IntegrationTableMapping, IntegrationTableMapping.Direction::ToIntegrationTable, IntegrationTableMapping.Direction::Bidirectional);

        // [WHEN] The IsMappingEnabled is called
        // [THEN] The mapping should be enabled for ToIntegrationTable only
        Assert.IsFalse(IntegrationTableMapping.IsMappingEnabled(IntegrationTableMapping.Direction::Bidirectional), 'The mapping should not be enabled');
        Assert.IsTrue(IntegrationTableMapping.IsMappingEnabled(IntegrationTableMapping.Direction::ToIntegrationTable), 'The mapping should be enabled');
        Assert.IsFalse(IntegrationTableMapping.IsMappingEnabled(IntegrationTableMapping.Direction::FromIntegrationTable), 'The mapping should not be enabled');

        // [WHEN] The IsFieldMappingEnabled is called
        // [THEN] The mapping should be enabled for ToIntegrationTable only
        Assert.IsFalse(IntegrationTableMapping.IsFieldMappingEnabled(Customer.FieldNo("No."), CRMAccount.FieldNo(AccountNumber), IntegrationTableMapping.Direction::Bidirectional), 'The mapping should not be enabled');
        Assert.IsTrue(IntegrationTableMapping.IsFieldMappingEnabled(Customer.FieldNo("No."), CRMAccount.FieldNo(AccountNumber), IntegrationTableMapping.Direction::ToIntegrationTable), 'The mapping should be enabled');
        Assert.IsFalse(IntegrationTableMapping.IsFieldMappingEnabled(Customer.FieldNo("No."), CRMAccount.FieldNo(AccountNumber), IntegrationTableMapping.Direction::FromIntegrationTable), 'The mapping should not be enabled');
    end;

    [Test]
    procedure IntegrationTableMappingTestIsEnabledForToIntegrationTableAndFromField()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        // [FEATURE] [Integration Table - Is Enabled]
        // [SCENARIO] IsMappingEnabled and IsFieldMappingEnabled return correct values for different combinations of requested direction and table/field direction
        Initialize();

        // [GIVEN] Integration table bidirectional mapping
        CreateIntegrationTableMappingWithFieldMapping(IntegrationTableMapping, IntegrationTableMapping.Direction::ToIntegrationTable, IntegrationTableMapping.Direction::FromIntegrationTable);

        // [WHEN] The IsMappingEnabled is called
        // [THEN] The mapping should not be enabled for any combination
        Assert.IsFalse(IntegrationTableMapping.IsMappingEnabled(IntegrationTableMapping.Direction::Bidirectional), 'The mapping should not be enabled');
        Assert.IsFalse(IntegrationTableMapping.IsMappingEnabled(IntegrationTableMapping.Direction::ToIntegrationTable), 'The mapping should not be enabled');
        Assert.IsFalse(IntegrationTableMapping.IsMappingEnabled(IntegrationTableMapping.Direction::FromIntegrationTable), 'The mapping should not be enabled');

        // [WHEN] The IsFieldMappingEnabled is called
        // [THEN] The mapping should not be enabled for any combination
        Assert.IsFalse(IntegrationTableMapping.IsFieldMappingEnabled(Customer.FieldNo("No."), CRMAccount.FieldNo(AccountNumber), IntegrationTableMapping.Direction::Bidirectional), 'The mapping should not be enabled');
        Assert.IsFalse(IntegrationTableMapping.IsFieldMappingEnabled(Customer.FieldNo("No."), CRMAccount.FieldNo(AccountNumber), IntegrationTableMapping.Direction::ToIntegrationTable), 'The mapping should not be enabled');
        Assert.IsFalse(IntegrationTableMapping.IsFieldMappingEnabled(Customer.FieldNo("No."), CRMAccount.FieldNo(AccountNumber), IntegrationTableMapping.Direction::FromIntegrationTable), 'The mapping should not be enabled');
    end;

    [Test]
    procedure TestGetRuntimeFieldsToCreate()
    var
        TempManIntFieldMapping: Record "Man. Int. Field Mapping" temporary;
        ManIntFieldMapping: Codeunit "Man. Int. Field Mapping";
        RuntimeFields: List of [Text];
    begin
        // [FEATURE] [Manual Integration Field Mapping]
        // [SCENARIO] Get runtime fields to create
        Initialize();

        // [GIVEN] Temporary Manual Integration Field Mapping table with both runtime and non-runtime fields
        CreateManIntFieldMapping(TempManIntFieldMapping, true, 'mockfield1');
        CreateManIntFieldMapping(TempManIntFieldMapping, false, '');

        // [WHEN] Getting runtime fields
        ManIntFieldMapping.GetRuntimeFieldsToCreate(TempManIntFieldMapping, RuntimeFields);

        // [THEN] Only runtime fields are returned
        Assert.AreEqual(1, RuntimeFields.Count(), 'The number of runtime fields is incorrect');
    end;

    [Test]
    procedure TestGetRuntimeFieldsToCreateDuplicates()
    var
        TempManIntFieldMapping: Record "Man. Int. Field Mapping" temporary;
        ManIntFieldMapping: Codeunit "Man. Int. Field Mapping";
        RuntimeFields: List of [Text];
    begin
        // [FEATURE] [Manual Integration Field Mapping]
        // [SCENARIO] Get duplicate runtime fields to create
        Initialize();

        // [GIVEN] Temporary Manual Integration Field Mapping table with duplicate runtime fields
        CreateManIntFieldMapping(TempManIntFieldMapping, true, 'mockfield1');
        CreateManIntFieldMapping(TempManIntFieldMapping, true, 'mockfield1');

        // [WHEN] Getting runtime fields
        ManIntFieldMapping.GetRuntimeFieldsToCreate(TempManIntFieldMapping, RuntimeFields);

        // [THEN] Only runtime fields are returned
        Assert.AreEqual(1, RuntimeFields.Count(), 'The number of runtime fields is incorrect');
    end;

    [Test]
    procedure TestCreateFieldMappingsForRuntimeFields()
    var
        TempManIntFieldMapping: Record "Man. Int. Field Mapping" temporary;
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CRMAccount: Record "CRM Account";
        ManIntFieldMapping: Codeunit "Man. Int. Field Mapping";
        FailedFields: Boolean;
        TableFieldNo1: Integer;
        TableFieldNo2: Integer;
    begin
        // [FEATURE] [Manual Integration Field Mapping]
        // [SCENARIO] Create field mappings for runtime fields
        Initialize();

        // [GIVEN] Temporary Manual Integration Field Mapping table with runtime fields built
        TableFieldNo1 := CreateManIntFieldMapping(TempManIntFieldMapping, true, 'address1_city');
        TableFieldNo2 := CreateManIntFieldMapping(TempManIntFieldMapping, true, 'address1_county');

        // [WHEN] Creating field mappings for runtime fields
        ManIntFieldMapping.CreateFieldMappingsForRuntimeFields(TempManIntFieldMapping, 'tablemapping1', Database::"CRM Account", true, FailedFields);

        // [THEN] No failed fields
        Assert.IsFalse(FailedFields, 'There should be no failed fields');
        // [THEN] Integration field mappings are created
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'tablemapping1');
        IntegrationFieldMapping.SetRange("Field No.", TableFieldNo1);
        Assert.IsTrue(IntegrationFieldMapping.FindFirst(), 'Field mapping for address1_city not found');
        Assert.AreEqual(IntegrationFieldMapping."Integration Table Field No.", CRMAccount.FieldNo(Address1_City), 'Field mapping for address1_city has incorrect field no.');
        Assert.AreEqual(IntegrationFieldMapping.Status, IntegrationFieldMapping.Status::Disabled, 'Field mapping for address1_city should be disabled.');
        IntegrationFieldMapping.SetRange("Field No.", TableFieldNo2);
        Assert.IsTrue(IntegrationFieldMapping.FindFirst(), 'Field mapping for address1_county not found');
        Assert.AreEqual(IntegrationFieldMapping."Integration Table Field No.", CRMAccount.FieldNo(Address1_County), 'Field mapping for address1_county has incorrect field no.');
        Assert.AreEqual(IntegrationFieldMapping.Status, IntegrationFieldMapping.Status::Disabled, 'Field mapping for address1_county should be disabled.');
    end;

    [Test]
    procedure TestCreateFieldMappingsForRuntimeFieldsFailed()
    var
        TempManIntFieldMapping: Record "Man. Int. Field Mapping" temporary;
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CRMAccount: Record "CRM Account";
        ManIntFieldMapping: Codeunit "Man. Int. Field Mapping";
        FailedFields: Boolean;
        TableFieldNo1: Integer;
        TableFieldNo2: Integer;
    begin
        // [FEATURE] [Manual Integration Field Mapping]
        // [SCENARIO] Create field mappings for runtime fields with failures
        Initialize();

        // [GIVEN] Temporary Manual Integration Field Mapping table with runtime fields built
        TableFieldNo1 := CreateManIntFieldMapping(TempManIntFieldMapping, true, 'address1_city');
        TableFieldNo2 := CreateManIntFieldMapping(TempManIntFieldMapping, true, 'nonexistingfield');

        // [WHEN] Creating field mappings for runtime fields
        ManIntFieldMapping.CreateFieldMappingsForRuntimeFields(TempManIntFieldMapping, 'tablemapping2', Database::"CRM Account", true, FailedFields);

        // [THEN] Failed fields
        Assert.IsTrue(FailedFields, 'There should be failed fields');
        // [THEN] Integration field mapping is not created for non-existing field
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", 'tablemapping2');
        IntegrationFieldMapping.SetRange("Field No.", TableFieldNo2);
        Assert.RecordIsEmpty(IntegrationFieldMapping);
        // [THEN] Integration field mapping is created for existing field
        IntegrationFieldMapping.SetRange("Field No.", TableFieldNo1);
        Assert.IsTrue(IntegrationFieldMapping.FindFirst(), 'Field mapping for address1_city not found');
        Assert.AreEqual(IntegrationFieldMapping."Integration Table Field No.", CRMAccount.FieldNo(Address1_City), 'Field mapping for address1_city has incorrect field no.');
    end;

    local procedure CreateManIntFieldMapping(var TempManIntFieldMapping: Record "Man. Int. Field Mapping" temporary; IsRuntimeField: Boolean; IntegrationTableFieldName: Text[50]): Integer
    begin
        TempManIntFieldMapping.Name := '';
        TempManIntFieldMapping."Table Field No." := LibraryRandom.RandIntInRange(1000000, 2000000);
        if not IsRuntimeField then
            TempManIntFieldMapping."Integration Table Field No." := LibraryRandom.RandIntInRange(1000000, 2000000)
        else
            TempManIntFieldMapping."Integration Table Field Name" := IntegrationTableFieldName;
        TempManIntFieldMapping.Insert();
        exit(TempManIntFieldMapping."Table Field No.");
    end;

    local procedure InsertIntegrationTableMapping(TableId: Integer; IntegrationTableId: Integer)
    var
        ManIntegrationTableMapping: Record "Man. Integration Table Mapping";
    begin
        ManIntegrationTableMapping.Init();
        ManIntegrationTableMapping.Name := 'Test';
        if TableId <> 0 then
            ManIntegrationTableMapping.Validate("Table ID", TableId);
        if IntegrationTableId <> 0 then
            ManIntegrationTableMapping.Validate("Integration Table ID", IntegrationTableId);
        ManIntegrationTableMapping.Insert();
    end;

    local procedure Initialize()
    begin
        Initialize(false, false);
    end;

    local procedure Initialize(EnableExtendedPrice: Boolean; EnableUnitGroupMapping: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        IntegrationTableMapping: Record "Integration Table Mapping";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"CRM Integration Mapping");

        LibraryPriceCalculation.DisableExtendedPriceCalculation();
        if EnableExtendedPrice then
            LibraryPriceCalculation.EnableExtendedPriceCalculation();

        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        LibraryTemplates.EnableTemplatesFeature();

        CRMConnectionSetup.DeleteAll();
        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, '');
        LibraryCRMIntegration.CreateCRMConnectionSetup('', '@@test@@', true);
        ResetCRMConfiguration(EnableUnitGroupMapping);
        CRMConnectionSetup.Get('');
        CRMConnectionSetup.RegisterConnection();

        IntegrationTableMapping.DeleteAll(true);
    end;

    local procedure AddTempIntegrationFieldMapping(var TempIntegrationFieldMapping: Record "Temp Integration Field Mapping"; IntegrationTableMappingName: Text[20]; SourceFieldNo: Integer; DestinationFieldNo: Integer)
    begin
        TempIntegrationFieldMapping."No." += 1;
        TempIntegrationFieldMapping."Integration Table Mapping Name" := IntegrationTableMappingName;
        TempIntegrationFieldMapping."Source Field No." := SourceFieldNo;
        TempIntegrationFieldMapping."Destination Field No." := DestinationFieldNo;
        TempIntegrationFieldMapping.Insert();
    end;

    local procedure AddTempTableMapping(MappingName: Code[20])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.Get(MappingName);
        IntegrationTableMapping."Parent Name" := IntegrationTableMapping.Name;
        IntegrationTableMapping.Name := LibraryUtility.GenerateGUID();
        IntegrationTableMapping."Delete After Synchronization" := true;
        IntegrationTableMapping.Insert();
    end;

    local procedure CreateCoupledContactsWithParents(var Contact: Record Contact; var CRMContact: Record "CRM Contact")
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CompanyContact: Record Contact;
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CustomerNo: Code[20];
    begin
        LibraryMarketing.CreatePersonContactWithCompanyNo(Contact);
        CompanyContact.Get(Contact."Company No.");
        CompanyContact.SetHideValidationDialog(true);
        CustomerNo := CompanyContact.CreateCustomerFromTemplate('');
        Customer.Get(CustomerNo);
        LibraryCRMIntegration.CreateCRMAccountWithCoupledOwner(CRMAccount);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(Customer.RecordId(), CRMAccount.AccountId);
        LibraryCRMIntegration.CreateCRMContactWithParentAccount(CRMContact, CRMAccount);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(Contact.RecordId(), CRMContact.ContactId);
        CRMContact.OwnerId := CRMAccount.OwnerId;
        CRMContact.OwnerIdType := CRMAccount.OwnerIdType;
        CRMContact.Modify();
        CRMIntegrationRecord.SetRange("CRM ID", CRMContact.OwnerId);
        CRMIntegrationRecord.FindFirst();
        SalespersonPurchaser.GetBySystemId(CRMIntegrationRecord."Integration ID");
        Contact."Salesperson Code" := SalespersonPurchaser.Code;
        Contact.Modify();
    end;

    local procedure CreateCRMSalesorder(var CRMSalesorder: Record "CRM Salesorder")
    var
        CRMAccount: Record "CRM Account";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Customer: Record Customer;
        GLSetup: Record "General Ledger Setup";
    begin
        LibraryCRMIntegration.CreateCRMSalesOrder(CRMSalesorder);
        CRMSalesorder.OrderNumber := LibraryUtility.GenerateGUID();
        CRMSalesorder.StateCode := CRMSalesorder.StateCode::Submitted;
        Clear(CRMSalesorder.LastBackofficeSubmit);
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMSalesorder.CustomerId := CRMAccount.AccountId;
        CRMSalesorder.CustomerIdType := CRMSalesorder.CustomerIdType::account;
        GLSetup.Get();
        LibraryCRMIntegration.CreateCRMTransactionCurrency(
          CRMTransactioncurrency, CopyStr(GLSetup."LCY Code", 1, 5));
        CRMSalesorder.TransactionCurrencyId := CRMTransactioncurrency.TransactionCurrencyId;
        CRMSalesorder.Modify();
    end;

    local procedure CreateIntegrationFieldMapping(var IntegrationFieldMapping: Record "Integration Field Mapping"; TableMappingName: Code[20]; NAVField: Record "Field"; CRMField: Record "Field")
    begin
        IntegrationFieldMapping.Init();
        IntegrationFieldMapping."Integration Table Mapping Name" := TableMappingName;
        IntegrationFieldMapping."No." := 0;
        IntegrationFieldMapping."Field No." := NAVField."No.";
        IntegrationFieldMapping."Integration Table Field No." := CRMField."No.";
        IntegrationFieldMapping.Insert();
    end;

    local procedure CreateIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; NAVField: Record "Field"; CRMField: Record "Field")
    begin
        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := LibraryUtility.GenerateGUID();
        IntegrationTableMapping."Table ID" := NAVField.TableNo;
        IntegrationTableMapping."Integration Table ID" := CRMField.TableNo;
        IntegrationTableMapping.Insert();
    end;

    local procedure CreateTwoCRMAccountsModifiedIn(var CRMAccount: Record "CRM Account"; Duration: Duration) FirstDT: DateTime
    begin
        CRMAccount.DeleteAll();
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);
        FirstDT := CRMAccount.ModifiedOn;
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);
        CRMAccount.ModifiedOn := FirstDT + Duration;
        CRMAccount.Modify();
    end;

    local procedure FillSalesOrderOptionFields(var CRMSalesorder: Record "CRM Salesorder")
    begin
        CRMSalesorder.ShippingMethodCodeEnum := CRMSalesorder.ShippingMethodCodeEnum::Airborne;
        CRMSalesorder.PaymentTermsCodeEnum := CRMSalesorder.PaymentTermsCodeEnum::Net30;
        CRMSalesorder.FreightTermsCodeEnum := CRMSalesorder.FreightTermsCodeEnum::FOB;
        CRMSalesorder.Modify();
    end;

    local procedure FindFieldsToPair(var CRMField: array[2] of Record "Field"; var NAVField: array[2] of Record "Field")
    begin
        NAVField[2].Find('-');
        NAVField[1] := NAVField[2];
        NAVField[2].Next();
        CRMField[2].Find('+');
        CRMField[1] := CRMField[2];
        CRMField[2].Next(-1);
    end;

    local procedure FindIntTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; TableID: Integer; CRMTableId: Integer)
    var
        "Field": Record "Field";
    begin
        IntegrationTableMapping.SetRange("Table ID", TableID);
        IntegrationTableMapping.SetRange("Integration Table ID", CRMTableId);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetRange("Int. Table UID Field Type", Field.Type::GUID);
        if not IntegrationTableMapping.FindFirst() then begin
            IntegrationTableMapping.Name := LibraryUtility.GenerateGUID();
            IntegrationTableMapping."Table ID" := TableID;
            IntegrationTableMapping."Integration Table ID" := CRMTableId;
            IntegrationTableMapping."Synch. Codeunit ID" := CODEUNIT::"CRM Integration Table Synch.";
            IntegrationTableMapping."Int. Table UID Field Type" := Field.Type::GUID;
            IntegrationTableMapping.Insert(true);
        end;
    end;

    local procedure GetCRMOptionCode(TableID: Integer; FieldID: Integer; OptionValue: Integer): Text
    var
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        Assert.IsTrue(CRMOptionMapping.FindRecordID(TableID, FieldID, OptionValue), 'Cannot find mapping');
        exit(CRMOptionMapping.GetRecordKeyValue());
    end;

    local procedure SetIntTableFilter(IntegrationTableMapping: Record "Integration Table Mapping"; "Filter": Text)
    begin
        IntegrationTableMapping.SetIntegrationTableFilter(Filter);
        IntegrationTableMapping.Modify(true);
    end;

    local procedure SyncCurrency(Currency: Record Currency)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
    begin
        IntegrationTableMapping.SetRange("Table ID", DATABASE::Currency);
        IntegrationTableMapping.FindFirst();
        SourceRecordRef.GetTable(Currency);
        IntegrationTableSynch.BeginIntegrationSynchJob(
          TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, IntegrationTableMapping."Table ID");
        IntegrationTableSynch.Synchronize(SourceRecordRef, DestinationRecordRef, false, true);
    end;

    local procedure VerifyCRMOptionFields(CRMSalesorder: Record "CRM Salesorder"; SalesHeader: Record "Sales Header")
    var
        CRMAccount: Record "CRM Account";
    begin
        SalesHeader.TestField(
          "Shipping Agent Code",
          GetCRMOptionCode(DATABASE::"CRM Account", CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum), CRMSalesorder.ShippingMethodCodeEnum.AsInteger()));
        SalesHeader.TestField(
          "Payment Terms Code",
          GetCRMOptionCode(DATABASE::"CRM Account", CRMAccount.FieldNo(PaymentTermsCodeEnum), CRMSalesorder.PaymentTermsCodeEnum.AsInteger()));
        SalesHeader.TestField(
          "Shipment Method Code",
          GetCRMOptionCode(DATABASE::"CRM Account", CRMAccount.FieldNo(Address1_FreightTermsCodeEnum), CRMSalesorder.FreightTermsCodeEnum.AsInteger()));
    end;

    local procedure VerifyFieldMapping(IntegrationTableMapping: Record "Integration Table Mapping"; FieldID: Integer; IntegrationFieldID: Integer; NotNull: Boolean)
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationFieldMapping.SetRange("Field No.", FieldID);
        IntegrationFieldMapping.SetRange("Integration Table Field No.", IntegrationFieldID);
        IntegrationFieldMapping.FindFirst();
        IntegrationFieldMapping.TestField("Not Null", NotNull);
    end;

    local procedure ModifyIntegrationTableMappingDirection(TableID: Integer; IntegrationTableID: Integer)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.SetRange("Table ID", TableID);
        IntegrationTableMapping.SetRange("Integration Table ID", IntegrationTableID);
        IntegrationTableMapping.FindFirst();
        IntegrationTableMapping.Direction := (IntegrationTableMapping.Direction + 1) mod 3;
    end;

    local procedure VerifyMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; TableID: Integer; IntegrationTableID: Integer; UIDFieldID: Integer; FieldCount: Integer; ExpectedDirection: Option; UnitGroupMappingEnabled: Boolean)
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        ResetCRMConfiguration(UnitGroupMappingEnabled);

        IntegrationTableMapping.SetRange("Table ID", TableID);
        IntegrationTableMapping.SetRange("Integration Table ID", IntegrationTableID);
        IntegrationTableMapping.FindFirst();
        IntegrationTableMapping.TestField("Integration Table UID Fld. No.", UIDFieldID);
        IntegrationTableMapping.TestField(Direction, ExpectedDirection);

        IntegrationFieldMapping.Init();
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationFieldMapping.SetRange(Status, IntegrationFieldMapping.Status::Enabled);
        Assert.RecordCount(IntegrationFieldMapping, FieldCount);

        // Insert one row that should be removed by ResetConfiguration
        IntegrationFieldMapping."Integration Table Mapping Name" := IntegrationTableMapping.Name;
        IntegrationFieldMapping."Field No." := 9999;
        IntegrationFieldMapping."Integration Table Field No." := 9999;
        IntegrationFieldMapping.Insert();

        Assert.RecordCount(IntegrationFieldMapping, FieldCount + 1);

        ResetCRMConfiguration(UnitGroupMappingEnabled);

        Assert.RecordCount(IntegrationFieldMapping, FieldCount);
    end;

    local procedure VerifyJobQueueEntry(IntegrationTableMapping: Record "Integration Table Mapping"; ExpectedCount: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init();
        JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId);
        Assert.RecordCount(JobQueueEntry, ExpectedCount);
        if JobQueueEntry.FindFirst() then begin
            Assert.AreEqual(
              JobQueueEntry."Object Type to Run"::Codeunit, JobQueueEntry."Object Type to Run",
              'Expected the object type to run to be codeunit');
            Assert.AreEqual(
              CODEUNIT::"Integration Synch. Job Runner", JobQueueEntry."Object ID to Run",
              'Expected the object ID to run to be the CRM Mapping codeunit');
        end;
    end;

    local procedure VerifyNoJobQueueEntry(IntegrationTableMapping: Record "Integration Table Mapping")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init();
        JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId);
        Assert.RecordIsEmpty(JobQueueEntry);
    end;

    local procedure VerifyTransactionCurrency(Currency: Record Currency; ISOCode: Code[5]; Symbol: Code[10]; Name: Text[100])
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        CRMIntegrationRecord.FindByRecordID(Currency.RecordId);
        CRMTransactioncurrency.Get(CRMIntegrationRecord."CRM ID");
        CRMTransactioncurrency.TestField(ISOCurrencyCode, ISOCode);
        CRMTransactioncurrency.TestField(CurrencySymbol, Symbol);
        CRMTransactioncurrency.TestField(CurrencyName, Name);
    end;

    local procedure VerifyUIDFieldIsOpton(MapName: Code[20])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        "Field": Record "Field";
    begin
        IntegrationTableMapping.Get(MapName);
        Field.Get(IntegrationTableMapping."Integration Table ID", IntegrationTableMapping."Integration Table UID Fld. No.");
        Assert.AreEqual(Field.Type::Option, Field.Type, 'UID Field type should be Option');
    end;

    local procedure ResetCRMConfiguration(EnableUnitGroupMapping: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMOrganization: Record "CRM Organization";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        ClientSecret: Text;
    begin
        CRMConnectionSetup.Get();
        CDSConnectionSetup.LoadConnectionStringElementsFromCRMConnectionSetup();
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Person;
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        ClientSecret := 'ClientSecret';
        CDSConnectionSetup.SetClientSecret(ClientSecret);
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        CDSConnectionSetup.Modify();
        LibraryCRMIntegration.CreateCRMOrganization();
        CRMOrganization.FindFirst();
        CRMConnectionSetup.BaseCurrencyId := CRMOrganization.BaseCurrencyId;
        CRMConnectionSetup."Is Enabled" := true;
        CRMConnectionSetup."Is S.Order Integration Enabled" := true;
        CRMConnectionSetup."Unit Group Mapping Enabled" := EnableUnitGroupMapping;
        CRMConnectionSetup.Modify();
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);
    end;

    local procedure TransferMappedFields(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var TempIntegrationFieldMapping: Record "Temp Integration Field Mapping" temporary; OnlyTransferModifiedFields: Boolean): Boolean
    var
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        CRMIntTableSubscriber: Codeunit "CRM Int. Table. Subscriber";
    begin
        Commit();
        CRMIntTableSubscriber.ClearCache();
        IntegrationRecordSynch.SetParameters(SourceRecordRef, DestinationRecordRef, OnlyTransferModifiedFields);
        IntegrationRecordSynch.SetFieldMapping(TempIntegrationFieldMapping);
        if IntegrationRecordSynch.Run() then
            exit(IntegrationRecordSynch.GetWasModified());
    end;

    procedure CreateIntegrationTableMappingWithFieldMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; TableDirection: Option Bidirectional,ToIntegrationTable,FromIntegrationTable; FieldDirection: Option Bidirectional,ToIntegrationTable,FromIntegrationTable)
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        IntegrationTableMapping.DeleteAll();
        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := LibraryUtility.GenerateGUID();
        IntegrationTableMapping."Table ID" := Database::Customer;
        IntegrationTableMapping."Integration Table ID" := Database::"CRM Account";
        IntegrationTableMapping."Integration Table UID Fld. No." := CRMAccount.FieldNo(AccountId);
        IntegrationTableMapping."Int. Tbl. Modified On Fld. No." := CRMAccount.FieldNo(ModifiedOn);
        IntegrationTableMapping."Synch. Codeunit ID" := Codeunit::"CRM Integration Table Synch.";
        IntegrationTableMapping.Direction := TableDirection;
        IntegrationTableMapping.Insert();

        IntegrationFieldMapping.DeleteAll();
        IntegrationFieldMapping.Init();
        IntegrationFieldMapping."No." := 0;
        IntegrationFieldMapping."Integration Table Mapping Name" := IntegrationTableMapping.Name;
        IntegrationFieldMapping."Field No." := Customer.FieldNo("No.");
        IntegrationFieldMapping."Integration Table Field No." := CRMAccount.FieldNo(AccountNumber);
        IntegrationFieldMapping.Direction := FieldDirection;
        IntegrationFieldMapping.Insert(true);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SyncStartedNotificationHandler(var SyncCompleteNotification: Notification): Boolean
    begin
        Assert.AreEqual(SyncStartedMsg, SyncCompleteNotification.Message, 'Unexpected notification.');
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure HandleJobQueueuEntriesPage(var JobQueueEntries: TestPage "Job Queue Entries")
    begin
        JobQueueEntries.Close();
    end;

}
