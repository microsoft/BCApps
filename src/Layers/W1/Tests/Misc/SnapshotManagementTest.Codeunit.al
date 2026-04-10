codeunit 132534 "Snapshot Management Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Test Framework] [Snapshot Management]
    end;

    var
        SnapshotManagement: Codeunit "Snapshot Management";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        isInitialized: Boolean;

    local procedure Initialize()
    begin
        SnapshotManagement.SetEnabled(true);
        SnapshotManagement.Clear();

        if isInitialized then
            exit;

        isInitialized := true;
        Commit();
    end;

    local procedure Teardown()
    begin
        SnapshotManagement.SetEnabled(false);
        SnapshotManagement.Clear();
    end;

    [Normal]
    local procedure IncrementalSnapshotRestore(IncrementalRollback: Boolean; FirstName: Code[10]; SecondName: Code[10])
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        SnapshotNo1: Integer;
        SnapshotNo2: Integer;
        CustomerNo: Code[20];
        VendorNo: Code[20];
    begin
        SnapshotNo1 := SnapshotManagement.InitSnapshot(FirstName, true);
        Evaluate(CustomerNo, LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer));
        Evaluate(VendorNo, LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor));

        Customer.Init();
        Customer.Validate("No.", CustomerNo);
        Customer.Insert(true);

        SnapshotNo2 := SnapshotManagement.InitSnapshot(SecondName, true);
        Vendor.Init();
        Vendor.Validate("No.", VendorNo);
        Vendor.Insert(true);

        // Roll-back step-by-step
        if not IncrementalRollback then begin
            SnapshotManagement.RestoreSnapshot(SnapshotNo2);
            Assert.IsTrue(SnapshotManagement.SnapshotNoExists(SnapshotNo1), 'First incremental snapshot should be unaffected.');
            Assert.IsTrue(SnapshotManagement.SnapshotNoExists(SnapshotNo2), 'Second incremental snapshot should remain.');
            Assert.IsTrue(Customer.Get(Customer."No."), 'Customer should exist after first snapshot restore.');
            Assert.IsFalse(Vendor.Get(Vendor."No."), 'Vendor should not exist after first snapshot restore.');
        end;

        SnapshotManagement.RestoreSnapshot(SnapshotNo1);
        Assert.IsTrue(SnapshotManagement.SnapshotNoExists(SnapshotNo1), 'First incremental snapshot should remain.');
        Assert.IsFalse(
          SnapshotManagement.SnapshotNoExists(SnapshotNo2), 'Second incremental snapshot should be deleted when restoring first.');
        Assert.IsFalse(Customer.Get(Customer."No."), 'Customer should not exist after first snapshot restore.');
        Assert.IsFalse(Vendor.Get(Vendor."No."), 'Vendor should not exist after first snapshot restore.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IncrementalSnapshotRestoreOneStep()
    begin
        Initialize();
        IncrementalSnapshotRestore(true, 'S1', 'S2');
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IncrementalSnapshotRestoreMultiStep()
    begin
        Initialize();
        IncrementalSnapshotRestore(false, 'S1', 'S2');
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IncrementalSnapshotRestoreRepeatably()
    begin
        Initialize();
        IncrementalSnapshotRestore(true, 'S1', 'S2');
        IncrementalSnapshotRestore(false, 'S2', 'S3');
        IncrementalSnapshotRestore(true, 'S3', 'S4');
        IncrementalSnapshotRestore(false, 'S4', 'S5');
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MixingSnapshots()
    begin
        Initialize();
        SnapshotManagement.InitSnapshot('S1', false);
        asserterror SnapshotManagement.InitSnapshot('S2', true);

        SnapshotManagement.Clear();

        SnapshotManagement.InitSnapshot('S1', true);
        asserterror SnapshotManagement.InitSnapshot('S2', false);
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSingleSnapshot()
    var
        Customer: Record Customer;
        SnapshotNo: Integer;
        CustomerNo: Code[20];
    begin
        Initialize();

        SnapshotNo := SnapshotManagement.InitSnapshot('S1', false);

        Evaluate(CustomerNo, LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer));
        Customer.Init();
        Customer."No." := CustomerNo;
        Customer.Insert();

        SnapshotManagement.RestoreSnapshot(SnapshotNo);

        Assert.IsFalse(Customer.Get(CustomerNo), StrSubstNo('Customer with %1 should not exist after snapshot restore.', CustomerNo));

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMultiSnapshot()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        SnapshotNo: Integer;
        SnapshotNo2: Integer;
        CustomerNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        SnapshotNo := SnapshotManagement.InitSnapshot('S1', false);

        Evaluate(CustomerNo, LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer));
        Customer.Init();
        Customer."No." := CustomerNo;
        Customer.Insert();

        SnapshotNo2 := SnapshotManagement.InitSnapshot('S2', false);

        Evaluate(VendorNo, LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor));
        Vendor.Init();
        Vendor."No." := VendorNo;
        Vendor.Insert();

        SnapshotManagement.RestoreSnapshot(SnapshotNo2);

        Assert.IsTrue(Customer.Get(CustomerNo), StrSubstNo('Customer %1 should exist after snapshot 1 restore.', CustomerNo));
        Assert.IsFalse(Vendor.Get(VendorNo), StrSubstNo('Vendor %1 should not exist after snapshot 1 restore.', VendorNo));

        SnapshotManagement.RestoreSnapshot(SnapshotNo);

        Assert.IsFalse(Customer.Get(CustomerNo), StrSubstNo('Customer %1 should not exist after snapshot 2 restore.', CustomerNo));
        Assert.IsFalse(Vendor.Get(VendorNo), StrSubstNo('Vendor %1 should not exist after snapshot 2 restore.', VendorNo));

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImplicitDirty()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        SnapshotNo: Integer;
        SnapshotNo2: Integer;
        CustomerNo: Code[20];
        VendorNo: Code[20];
    begin
        Initialize();

        SnapshotNo := SnapshotManagement.InitSnapshot('S1', false);

        Evaluate(CustomerNo, LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer));
        Customer.Init();
        Customer."No." := CustomerNo;
        Customer.Insert();

        SnapshotNo2 := SnapshotManagement.InitSnapshot('S2', false);

        Evaluate(VendorNo, LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor));
        Vendor.Init();
        Vendor."No." := VendorNo;
        Vendor.Insert();

        SnapshotManagement.RestoreSnapshot(SnapshotNo);

        // Check that customer table is implicitly tainted
        VerifyImplicitTaint(SnapshotNo2, DATABASE::Customer, true);

        Evaluate(CustomerNo, LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer));
        Customer.Init();
        Customer."No." := CustomerNo;
        Customer.Insert();

        // Check that customer table is no longer implicitly tainted
        VerifyImplicitTaint(SnapshotNo2, DATABASE::Customer, false);

        TearDown();
    end;

    [Normal]
    local procedure VerifyImplicitTaint(SnapshotNo: Integer; TableNo: Integer; Implicit: Boolean)
    var
        TempTaintedTable: Record "Tainted Table" temporary;
    begin
        SnapshotManagement.ListTables(TempTaintedTable);

        TempTaintedTable.Get(SnapshotNo, TableNo);
        Assert.AreEqual(Implicit, TempTaintedTable."Implicit Taint", 'Expected Customer table to be implicitly tainted');
    end;
}

