codeunit 134768 "Test Posting Preview"
{
    Permissions = TableData "G/L Entry" = imd,
                  TableData "Cust. Ledger Entry" = imd,
                  TableData "Vendor Ledger Entry" = imd,
                  TableData "Item Ledger Entry" = imd,
                  TableData "VAT Entry" = imd,
                  TableData "Bank Account Ledger Entry" = imd,
                  TableData "Detailed Cust. Ledg. Entry" = imd,
                  TableData "Detailed Vendor Ledg. Entry" = imd,
                  TableData "Value Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Post Preview]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        AmountsNotEqualErr: Label 'The amount in the preview page was not expected.';
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        MessageNotEqualErr: Label 'The message to the recipient in the preview page was not expected.';

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryTest()
    var
        GLEntry: Record "G/L Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        GLEntriesPreview: TestPage "G/L Entries Preview";
    begin
        // [SCENARIO] G/L Entry is properly saved to temp tables and displayed in the preview page.
        GLEntry.Init();
        GLEntry.Amount := LibraryRandom.RandDec(1000, 2);
        LibraryPostPrevHandler.SetValueFieldNo(GLEntry.FieldNo(Amount));

        GLEntriesPreview.Trap();
        RunPreview(LibraryPostPrevHandler, GLEntry);

        GLEntriesPreview.First();
        Assert.AreEqual(GLEntry.Amount, GLEntriesPreview.Amount.AsDecimal(), 'Entry amounts were not equal.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryTest()
    var
        VATEntry: Record "VAT Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        VATEntriesPreview: TestPage "VAT Entries Preview";
    begin
        // [SCENARIO] VAT Entry is properly saved to temp tables and displayed in the preview page.
        VATEntry.Init();
        VATEntry.Amount := LibraryRandom.RandDec(1000, 2);
        LibraryPostPrevHandler.SetValueFieldNo(VATEntry.FieldNo(Amount));

        VATEntriesPreview.Trap();
        RunPreview(LibraryPostPrevHandler, VATEntry);

        VATEntriesPreview.First();
        Assert.AreEqual(VATEntry.Amount, VATEntriesPreview.Amount.AsDecimal(), AmountsNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValueEntryTest()
    var
        ValueEntry: Record "Value Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        ValueEntriesPreview: TestPage "Value Entries Preview";
    begin
        // [SCENARIO] Value Entry is properly saved to temp tables and displayed in the preview page.
        ValueEntry.Init();
        ValueEntry."Cost Amount (Actual)" := LibraryRandom.RandDec(1000, 2);
        LibraryPostPrevHandler.SetValueFieldNo(ValueEntry.FieldNo("Cost Amount (Actual)"));

        ValueEntriesPreview.Trap();
        RunPreview(LibraryPostPrevHandler, ValueEntry);

        ValueEntriesPreview.First();
        Assert.AreEqual(
          ValueEntry."Cost Amount (Actual)",
          ValueEntriesPreview."Cost Amount (Actual)".AsDecimal(),
          AmountsNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryTest()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        ItemLedgerEntriesPreview: TestPage "Item Ledger Entries Preview";
    begin
        // [SCENARIO] Item Ledger Entry is properly saved to temp tables and displayed in the preview page.
        ItemLedgerEntry.Init();
        ItemLedgerEntry.Quantity := LibraryRandom.RandDec(100, 2);
        LibraryPostPrevHandler.SetValueFieldNo(ItemLedgerEntry.FieldNo(Quantity));

        ItemLedgerEntriesPreview.Trap();
        RunPreview(LibraryPostPrevHandler, ItemLedgerEntry);

        ItemLedgerEntriesPreview.First();
        Assert.AreEqual(ItemLedgerEntry.Quantity, ItemLedgerEntriesPreview.Quantity.AsDecimal(), AmountsNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLedgerEntryTest()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        CustLedgEntriesPreview: TestPage "Cust. Ledg. Entries Preview";
    begin
        // [SCENARIO] Customer Ledger Entry is properly saved to temp tables and displayed in the preview page.
        CustLedgerEntry.Init();
        CustLedgerEntry."Max. Payment Tolerance" := LibraryRandom.RandDec(1000, 2);
        LibraryPostPrevHandler.SetValueFieldNo(CustLedgerEntry.FieldNo("Max. Payment Tolerance"));

        CustLedgEntriesPreview.Trap();
        RunPreview(LibraryPostPrevHandler, CustLedgerEntry);

        CustLedgEntriesPreview.First();
        Assert.AreEqual(
          CustLedgerEntry."Max. Payment Tolerance",
          CustLedgEntriesPreview."Max. Payment Tolerance".AsDecimal(),
          AmountsNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetailedCustLedgerEntryTest()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        DetCustLedgEntrPreview: TestPage "Det. Cust. Ledg. Entr. Preview";
    begin
        // [SCENARIO] Detailed Customer Ledger Entry is properly saved to temp tables and displayed in the preview page.
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry.Amount := LibraryRandom.RandDec(1000, 2);
        LibraryPostPrevHandler.SetValueFieldNo(DetailedCustLedgEntry.FieldNo(Amount));

        DetCustLedgEntrPreview.Trap();
        RunPreview(LibraryPostPrevHandler, DetailedCustLedgEntry);

        DetCustLedgEntrPreview.First();
        Assert.AreEqual(DetailedCustLedgEntry.Amount, DetCustLedgEntrPreview.Amount.AsDecimal(), AmountsNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryTest()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        VendLedgEntriesPreview: TestPage "Vend. Ledg. Entries Preview";
    begin
        // [SCENARIO] Vendor Ledger Entry is properly saved to temp tables and displayed in the preview page.
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Max. Payment Tolerance" := LibraryRandom.RandDec(1000, 2);
        LibraryPostPrevHandler.SetValueFieldNo(VendorLedgerEntry.FieldNo("Max. Payment Tolerance"));

        VendLedgEntriesPreview.Trap();
        RunPreview(LibraryPostPrevHandler, VendorLedgerEntry);

        VendLedgEntriesPreview.First();
        Assert.AreEqual(
          VendorLedgerEntry."Max. Payment Tolerance",
          VendLedgEntriesPreview."Max. Payment Tolerance".AsDecimal(),
          AmountsNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetailedVendorLedgerEntryTest()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        DetailedVendEntriesPreview: TestPage "Detailed Vend. Entries Preview";
    begin
        // [SCENARIO] Detailed Vendor Ledger Entry is properly saved to temp tables and displayed in the preview page.
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry.Amount := LibraryRandom.RandDec(1000, 2);
        LibraryPostPrevHandler.SetValueFieldNo(DetailedVendorLedgEntry.FieldNo(Amount));

        DetailedVendEntriesPreview.Trap();
        RunPreview(LibraryPostPrevHandler, DetailedVendorLedgEntry);

        DetailedVendEntriesPreview.First();
        Assert.AreEqual(DetailedVendorLedgEntry.Amount, DetailedVendEntriesPreview.Amount.AsDecimal(), AmountsNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeLedgerEntryTest()
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        EmplLedgerEntriesPreview: TestPage "Empl. Ledger Entries Preview";
    begin
        // [SCENARIO] Vendor Ledger Entry is properly saved to temp tables and displayed in the preview page.
        EmployeeLedgerEntry.Init();
        EmployeeLedgerEntry."Message to Recipient" := LibraryUtility.GenerateGUID();
        LibraryPostPrevHandler.SetValueFieldNo(EmployeeLedgerEntry.FieldNo("Message to Recipient"));

        EmplLedgerEntriesPreview.Trap();
        RunPreview(LibraryPostPrevHandler, EmployeeLedgerEntry);

        EmplLedgerEntriesPreview.First();
        Assert.AreEqual(
          EmployeeLedgerEntry."Message to Recipient",
          Format(EmplLedgerEntriesPreview."Message to Recipient"),
          MessageNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetailedEmployeeLedgerEntryTest()
    var
        DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        DetailedEmplEntriesPreview: TestPage "Detailed Empl. Entries Preview";
    begin
        // [SCENARIO] Detailed Vendor Ledger Entry is properly saved to temp tables and displayed in the preview page.
        DetailedEmployeeLedgerEntry.Init();
        DetailedEmployeeLedgerEntry.Amount := LibraryRandom.RandDec(1000, 2);
        LibraryPostPrevHandler.SetValueFieldNo(DetailedEmployeeLedgerEntry.FieldNo(Amount));

        DetailedEmplEntriesPreview.Trap();
        RunPreview(LibraryPostPrevHandler, DetailedEmployeeLedgerEntry);

        DetailedEmplEntriesPreview.First();
        Assert.AreEqual(DetailedEmployeeLedgerEntry.Amount, DetailedEmplEntriesPreview.Amount.AsDecimal(), AmountsNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FALedgerEntryTest()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        FALedgerEntriesPreview: TestPage "FA Ledger Entries Preview";
    begin
        // [SCENARIO] FA Ledger Entry is properly saved to temp tables and displayed in the preview page.
        LibraryLowerPermissions.SetOutsideO365Scope();
        FALedgerEntry.Init();
        FALedgerEntry.Amount := LibraryRandom.RandDec(1000, 2);
        LibraryPostPrevHandler.SetValueFieldNo(FALedgerEntry.FieldNo(Amount));

        FALedgerEntriesPreview.Trap();
        RunPreview(LibraryPostPrevHandler, FALedgerEntry);

        FALedgerEntriesPreview.First();
        Assert.AreEqual(FALedgerEntry.Amount, FALedgerEntriesPreview.Amount.AsDecimal(), AmountsNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountLedgerEntryTest()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        BankAccLedgEntrPreview: TestPage "Bank Acc. Ledg. Entr. Preview";
    begin
        // [SCENARIO] Bank Account Ledger Entry is properly saved to temp tables and displayed in the preview page.
        BankAccountLedgerEntry.Init();
        BankAccountLedgerEntry.Amount := LibraryRandom.RandDec(1000, 2);
        LibraryPostPrevHandler.SetValueFieldNo(BankAccountLedgerEntry.FieldNo(Amount));

        BankAccLedgEntrPreview.Trap();
        RunPreview(LibraryPostPrevHandler, BankAccountLedgerEntry);

        BankAccLedgEntrPreview.First();
        Assert.AreEqual(BankAccountLedgerEntry.Amount, BankAccLedgEntrPreview.Amount.AsDecimal(), AmountsNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResLedgerEntryTest()
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        ResourceLedgEntriesPreview: TestPage "Resource Ledg. Entries Preview";
    begin
        // [SCENARIO] Res. Ledger Entry is properly saved to temp tables and displayed in the preview page.
        LibraryLowerPermissions.SetOutsideO365Scope();
        ResLedgerEntry.Init();
        ResLedgerEntry.Quantity := LibraryRandom.RandInt(100);
        LibraryPostPrevHandler.SetValueFieldNo(ResLedgerEntry.FieldNo(Quantity));

        ResourceLedgEntriesPreview.Trap();
        RunPreview(LibraryPostPrevHandler, ResLedgerEntry);

        ResourceLedgEntriesPreview.First();
        Assert.AreEqual(ResLedgerEntry.Quantity, ResourceLedgEntriesPreview.Quantity.AsInteger(), AmountsNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLedgerEntryTest()
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        ServiceLedgerEntriesPreview: TestPage "Service Ledger Entries Preview";
    begin
        // [SCENARIO] Service Ledger Entry is properly saved to temp tables and displayed in the preview page.
        LibraryLowerPermissions.SetOutsideO365Scope();
        ServiceLedgerEntry.Init();
        ServiceLedgerEntry.Amount := LibraryRandom.RandDec(1000, 2);
        LibraryPostPrevHandler.SetValueFieldNo(ServiceLedgerEntry.FieldNo(Amount));

        ServiceLedgerEntriesPreview.Trap();
        RunPreview(LibraryPostPrevHandler, ServiceLedgerEntry);

        ServiceLedgerEntriesPreview.First();
        Assert.AreEqual(ServiceLedgerEntry.Amount, ServiceLedgerEntriesPreview.Amount.AsDecimal(), AmountsNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarrantyLedgerEntryTest()
    var
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        WarrantyLedgEntriesPreview: TestPage "Warranty Ledg. Entries Preview";
    begin
        // [SCENARIO] Warranty Ledger Entry is properly saved to temp tables and displayed in the preview page.
        WarrantyLedgerEntry.Init();
        WarrantyLedgerEntry.Amount := LibraryRandom.RandDec(1000, 2);
        LibraryPostPrevHandler.SetValueFieldNo(WarrantyLedgerEntry.FieldNo(Amount));

        WarrantyLedgEntriesPreview.Trap();
        RunPreview(LibraryPostPrevHandler, WarrantyLedgerEntry);

        WarrantyLedgEntriesPreview.First();
        Assert.AreEqual(WarrantyLedgerEntry.Amount, WarrantyLedgEntriesPreview.Amount.AsDecimal(), AmountsNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintenanceLedgerEntryTest()
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        MaintLedgEntriesPreview: TestPage "Maint. Ledg. Entries Preview";
    begin
        // [SCENARIO] Maintenance Ledger Entry is properly saved to temp tables and displayed in the preview page.
        LibraryLowerPermissions.SetOutsideO365Scope();
        MaintenanceLedgerEntry.Init();
        MaintenanceLedgerEntry.Amount := LibraryRandom.RandDec(1000, 2);
        LibraryPostPrevHandler.SetValueFieldNo(MaintenanceLedgerEntry.FieldNo(Amount));

        MaintLedgEntriesPreview.Trap();
        RunPreview(LibraryPostPrevHandler, MaintenanceLedgerEntry);

        MaintLedgEntriesPreview.First();
        Assert.AreEqual(MaintenanceLedgerEntry.Amount, MaintLedgEntriesPreview.Amount.AsDecimal(), AmountsNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobLedgerEntryTest()
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        JobLedgerEntriesPreview: TestPage "Job Ledger Entries Preview";
    begin
        // [SCENARIO] Job Ledger Entry is properly saved to temp tables and displayed in the preview page.
        LibraryLowerPermissions.SetOutsideO365Scope();
        JobLedgerEntry.Init();
        JobLedgerEntry."Line Amount" := LibraryRandom.RandDec(1000, 2);
        LibraryPostPrevHandler.SetValueFieldNo(JobLedgerEntry.FieldNo("Line Amount"));

        JobLedgerEntriesPreview.Trap();
        RunPreview(LibraryPostPrevHandler, JobLedgerEntry);

        JobLedgerEntriesPreview.First();
        Assert.AreEqual(
          JobLedgerEntry."Line Amount",
          JobLedgerEntriesPreview."Line Amount".AsDecimal(),
          AmountsNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreventCommit()
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
    begin
        // [SCENARIO] Throw inconsistent error when COMMIT called during posting preview
        JobLedgerEntry.Init();
        JobLedgerEntry."Line Amount" := LibraryRandom.RandDec(1000, 2);
        LibraryPostPrevHandler.SetValueFieldNo(JobLedgerEntry.FieldNo("Line Amount"));

        RunPreviewWithCommit(LibraryPostPrevHandler, JobLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BadSubscriberTypeUT()
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        // [SCENARIO] Throw error when passed Subscriber object is not CODEUNIT
        asserterror GenJnlPostPreview.Preview(JobLedgerEntry, JobLedgerEntry);

        Assert.ExpectedError('Invalid Subscriber type. The type must be CODEUNIT.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BadRecVarTypeUT()
    var
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        // [SCENARIO] Throw error when passed RecVar object is not RECORD
        asserterror GenJnlPostPreview.Preview(LibraryPostPrevHandler, LibraryPostPrevHandler);

        Assert.ExpectedError('Invalid RecVar type. The type must be RECORD.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreviewNegativeResultWithoutErrorUT()
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        // [SCENARIO] Throw error when Preview return false without error
        JobLedgerEntry.Init();
        asserterror GenJnlPostPreview.Preview(LibraryPostPrevHandler, JobLedgerEntry);
        Assert.ExpectedError('The posting preview has stopped because of a state that is not valid.');
    end;

    local procedure RunPreview(LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler"; RecVar: Variant)
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        GLPostingPreview: TestPage "G/L Posting Preview";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        GLPostingPreview.Trap();
        BindSubscription(LibraryPostPrevHandler);
        Assert.IsFalse(GenJnlPostPreview.IsActive(), 'GenJnlPostPreview.IsActive() before preview');
        asserterror GenJnlPostPreview.Preview(LibraryPostPrevHandler, RecVar);
        Assert.IsFalse(GenJnlPostPreview.IsActive(), 'GenJnlPostPreview.IsActive() after preview');
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(RecRef.Number));
        GLPostingPreview.Show.Invoke();
    end;

    local procedure RunPreviewWithCommit(LibraryPostPrevHandler: Codeunit "Library - Post. Prev. Handler"; RecVar: Variant)
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        BindSubscription(LibraryPostPrevHandler);
        LibraryPostPrevHandler.SetInvokeCommit(true);
        Assert.IsFalse(GenJnlPostPreview.IsActive(), 'GenJnlPostPreview.IsActive() before preview');
        ErrorMessagesPage.Trap();
        asserterror GenJnlPostPreview.Preview(LibraryPostPrevHandler, RecVar);
        Assert.ExpectedError('');
        Assert.IsFalse(GenJnlPostPreview.IsActive(), 'GenJnlPostPreview.IsActive() after preview');
        Assert.ExpectedMessage('Commit is prohibited in the current scope.', ErrorMessagesPage.Description.Value);
    end;
}

