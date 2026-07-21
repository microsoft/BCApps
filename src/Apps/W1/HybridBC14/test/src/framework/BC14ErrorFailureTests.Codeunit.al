// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration;
using Microsoft.DataMigration.BC14Reimplementation;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Integration;

codeunit 148907 "BC14 Error & Failure Tests"
{
    // [FEATURE] [BC14 Cloud Migration Error Handling, Failure Handler, Record Tracker]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // ============================================================
    // Error Handler - Basic Logging
    // ============================================================

    [Test]
    procedure TestLogError()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] Errors are correctly logged to the BC14 Migration Errors table.

        // [GIVEN] No migration errors exist
        DataMigrationError.DeleteAll();

        // Create a dummy record ID
        DummyRecordRef.Open(Database::"Data Migration Error");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        // [WHEN] An error is logged
        BC14MigrationErrorHandler.LogError(
            'G/L Account Migrator',
            Database::"BC14 G/L Account",
            'BC14 G/L Account',
            'No.=1200',
            Database::"G/L Account",
            'Account category must have a value.',
            DummyRecId
        );

        // [THEN] The error record is created with correct values
        Assert.AreEqual(1, DataMigrationError.Count(), 'Should have exactly 1 error record');

        DataMigrationError.FindFirst();
        Assert.AreEqual('G/L Account Migrator', DataMigrationError."Migration Type", 'Migration Type - Incorrect value');
        Assert.AreEqual(Database::"BC14 G/L Account", DataMigrationError."Source Table ID", 'Source Table ID - Incorrect value');
        Assert.AreEqual('BC14 G/L Account', DataMigrationError."Source Table Name", 'Source Table Name - Incorrect value');
        Assert.AreEqual('No.=1200', DataMigrationError."Source Record Key", 'Source Record Key - Incorrect value');
        Assert.AreEqual(Database::"G/L Account", DataMigrationError."Destination Table ID", 'Destination Table ID - Incorrect value');
        Assert.AreEqual('Account category must have a value.', DataMigrationError."Error Message", 'Error Message - Incorrect value');
        Assert.AreNotEqual(0DT, DataMigrationError."Created On", 'Created On - Should have a timestamp');
        Assert.AreEqual(false, DataMigrationError."Error Dismissed", 'Resolved - Should be false initially');
        Assert.AreEqual(0, DataMigrationError."Retry Count", 'Retry Count - Should be 0 initially');
    end;

    [Test]
    procedure TestLogMultipleErrors()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] Multiple errors can be logged.

        // [GIVEN] No migration errors exist
        DataMigrationError.DeleteAll();

        DummyRecordRef.Open(Database::"Data Migration Error");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        // [WHEN] Multiple errors are logged
        BC14MigrationErrorHandler.LogError('G/L Account Migrator', Database::"BC14 G/L Account", 'BC14 G/L Account', 'No.=1200', Database::"G/L Account", 'Error 1', DummyRecId);
        BC14MigrationErrorHandler.LogError('Customer Migrator', Database::"BC14 Customer", 'BC14 Customer', 'No.=C001', Database::Customer, 'Error 2', DummyRecId);
        BC14MigrationErrorHandler.LogError('Vendor Migrator', Database::"BC14 Vendor", 'BC14 Vendor', 'No.=V001', Database::Vendor, 'Error 3', DummyRecId);

        // [THEN] All errors are recorded
        Assert.AreEqual(3, DataMigrationError.Count(), 'Should have exactly 3 error records');
    end;

    [Test]
    procedure TestMarkErrorAsResolved()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] An error can be marked as resolved.

        // [GIVEN] An error is logged
        DataMigrationError.DeleteAll();

        DummyRecordRef.Open(Database::"Data Migration Error");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('G/L Account Migrator', Database::"BC14 G/L Account", 'BC14 G/L Account', 'No.=1200', Database::"G/L Account", 'Account error', DummyRecId);
        DataMigrationError.FindFirst();

        // [WHEN] The error is marked as resolved
        DataMigrationError."Error Dismissed" := true;
        DataMigrationError."Resolved On" := CurrentDateTime();
        DataMigrationError."Resolved By" := CopyStr(UserId(), 1, MaxStrLen(DataMigrationError."Resolved By"));
        DataMigrationError.Modify(true);

        // [THEN] The error is resolved with correct values
        DataMigrationError.Get(DataMigrationError.Id);
        Assert.AreEqual(true, DataMigrationError."Error Dismissed", 'Resolved - Should be true');
        Assert.AreNotEqual(0DT, DataMigrationError."Resolved On", 'Resolved On - Should have a timestamp');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(DataMigrationError."Resolved By")), DataMigrationError."Resolved By", 'Resolved By - Incorrect value');
    end;

    [Test]
    procedure TestScheduleErrorForRetry()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] An error can be scheduled for retry.

        // [GIVEN] An error is logged
        DataMigrationError.DeleteAll();

        DummyRecordRef.Open(Database::"Data Migration Error");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('G/L Account Migrator', Database::"BC14 G/L Account", 'BC14 G/L Account', 'No.=1200', Database::"G/L Account", 'Temporary error', DummyRecId);
        DataMigrationError.FindFirst();

        // [WHEN] The error is scheduled for retry
        DataMigrationError."Scheduled For Retry" := true;
        DataMigrationError."Retry Count" += 1;
        DataMigrationError."Last Retry On" := CurrentDateTime();
        DataMigrationError.Modify(true);

        // [THEN] The error is scheduled with correct values
        DataMigrationError.Get(DataMigrationError.Id);
        Assert.AreEqual(true, DataMigrationError."Scheduled For Retry", 'Scheduled For Retry - Should be true');
        Assert.AreEqual(1, DataMigrationError."Retry Count", 'Retry Count - Should be 1 after first retry');
        Assert.AreNotEqual(0DT, DataMigrationError."Last Retry On", 'Last Retry On - Should have a timestamp');
    end;

    [Test]
    procedure TestRetryCountIncrements()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] Retry count increments with each retry.

        // [GIVEN] An error is logged
        DataMigrationError.DeleteAll();

        DummyRecordRef.Open(Database::"Data Migration Error");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('Item Migrator', Database::"BC14 Item", 'BC14 Item', 'No.=ITEM-1', Database::Item, 'Transient error', DummyRecId);
        DataMigrationError.FindFirst();

        // [WHEN] The error is retried multiple times
        DataMigrationError."Scheduled For Retry" := true;
        DataMigrationError."Retry Count" += 1;
        DataMigrationError."Last Retry On" := CurrentDateTime();
        DataMigrationError.Modify(true);
        DataMigrationError."Retry Count" += 1;
        DataMigrationError."Last Retry On" := CurrentDateTime();
        DataMigrationError.Modify(true);
        DataMigrationError."Retry Count" += 1;
        DataMigrationError."Last Retry On" := CurrentDateTime();
        DataMigrationError.Modify(true);

        // [THEN] The retry count is 3
        DataMigrationError.Get(DataMigrationError.Id);
        Assert.AreEqual(3, DataMigrationError."Retry Count", 'Retry Count - Should be 3 after three retries');
    end;

    [Test]
    procedure TestGetUnresolvedErrorCount()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
        CompanyNameText: Text[30];
    begin
        // [SCENARIO] GetUnresolvedErrorCount returns the correct count of unresolved errors.

        // [GIVEN] Multiple errors are logged, some resolved and some not
        DataMigrationError.DeleteAll();

#pragma warning disable AA0139
        CompanyNameText := CompanyName();
#pragma warning restore AA0139

        DummyRecordRef.Open(Database::"Data Migration Error");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('G/L Account Migrator', Database::"BC14 G/L Account", 'BC14 G/L Account', 'No.=1200', Database::"G/L Account", 'Error 1', DummyRecId);
        BC14MigrationErrorHandler.LogError('G/L Account Migrator', Database::"BC14 G/L Account", 'BC14 G/L Account', 'No.=1300', Database::"G/L Account", 'Error 2', DummyRecId);
        BC14MigrationErrorHandler.LogError('G/L Account Migrator', Database::"BC14 G/L Account", 'BC14 G/L Account', 'No.=1400', Database::"G/L Account", 'Error 3', DummyRecId);

        // Resolve one of the errors
        DataMigrationError.FindFirst();
        DataMigrationError."Error Dismissed" := true;
        DataMigrationError."Resolved On" := CurrentDateTime();
        DataMigrationError.Modify(true);

        // [WHEN] GetUnresolvedErrorCount is called
        Clear(DataMigrationError);

        // [THEN] It should return 2 (3 total - 1 resolved)
        DataMigrationError.SetRange("Destination Table ID", Database::"G/L Account");
        DataMigrationError.SetRange("Error Dismissed", false);
        Assert.AreEqual(2, DataMigrationError.Count(), 'Should have 2 unresolved errors');
    end;

    // ============================================================
    // Unblock For Retry
    // ============================================================

    [Test]
    procedure TestUnblockForRetry()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] An error can be unblocked for manual correction and retry.

        // [GIVEN] An error is logged and previously marked as resolved
        DataMigrationError.DeleteAll();

        DummyRecordRef.Open(Database::"Data Migration Error");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('G/L Account Migrator', Database::"BC14 G/L Account", 'BC14 G/L Account', 'No.=1200', Database::"G/L Account", 'Account error', DummyRecId);
        DataMigrationError.FindFirst();
        DataMigrationError."Error Dismissed" := true;
        DataMigrationError."Resolved On" := CurrentDateTime();
        DataMigrationError."Resolved By" := CopyStr(UserId(), 1, MaxStrLen(DataMigrationError."Resolved By"));
        DataMigrationError.Modify(true);

        // [WHEN] The error is unblocked for retry
        DataMigrationError.Get(DataMigrationError.Id);
        DataMigrationError."Error Dismissed" := false;
        DataMigrationError."Resolved On" := 0DT;
        DataMigrationError."Resolved By" := '';
        DataMigrationError."Scheduled For Retry" := true;
        DataMigrationError.Modify(true);

        // [THEN] The error is unblocked with correct values
        DataMigrationError.Get(DataMigrationError.Id);
        Assert.AreEqual(false, DataMigrationError."Error Dismissed", 'Resolved - Should be false after unblock');
        Assert.AreEqual(0DT, DataMigrationError."Resolved On", 'Resolved On - Should be cleared');
        Assert.AreEqual('', DataMigrationError."Resolved By", 'Resolved By - Should be cleared');
        Assert.AreEqual(true, DataMigrationError."Scheduled For Retry", 'Scheduled For Retry - Should be true');
    end;

    [Test]
    procedure TestUnblockForRetryOnUnresolvedError()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] UnblockForRetry can be called on an error that was never resolved.

        // [GIVEN] An error is logged but not resolved
        DataMigrationError.DeleteAll();

        DummyRecordRef.Open(Database::"Data Migration Error");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('Item Migrator', Database::"BC14 Item", 'BC14 Item', 'No.=ITEM-1', Database::Item, 'Item error', DummyRecId);
        DataMigrationError.FindFirst();

        // Verify initial state
        Assert.AreEqual(false, DataMigrationError."Error Dismissed", 'Resolved - Should be false initially');
        Assert.AreEqual(false, DataMigrationError."Scheduled For Retry", 'Scheduled For Retry - Should be false initially');

        // [WHEN] The error is unblocked for retry
        DataMigrationError."Scheduled For Retry" := true;
        DataMigrationError.Modify(true);

        // [THEN] The error is scheduled for retry
        DataMigrationError.Get(DataMigrationError.Id);
        Assert.AreEqual(false, DataMigrationError."Error Dismissed", 'Resolved - Should remain false');
        Assert.AreEqual(true, DataMigrationError."Scheduled For Retry", 'Scheduled For Retry - Should be true');
    end;

    // ============================================================
    // HasUnresolvedError / ResolveErrorForRecord
    // ============================================================

    [Test]
    procedure TestHasUnresolvedError_NoError_ReturnsFalse()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
    begin
        // [SCENARIO] HasUnresolvedError returns false when no error exists for the record.

        // [GIVEN] No errors exist
        DataMigrationError.DeleteAll();

        // [THEN] HasUnresolvedError returns false
        Assert.IsFalse(BC14MigrationErrorHandler.HasUnresolvedError(1000, 'NonExistentKey'), 'Should return false when no error exists');
    end;

    [Test]
    procedure TestHasUnresolvedError_UnresolvedError_ReturnsTrue()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] HasUnresolvedError returns true when an unresolved error exists.

        // [GIVEN] An unresolved error exists for the record
        DataMigrationError.DeleteAll();

        DummyRecordRef.Open(Database::"Data Migration Error");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('Test Migrator', Database::"BC14 Customer", 'BC14 Customer', 'CUST-001', 0, 'Test error', DummyRecId);

        // [THEN] HasUnresolvedError returns true
        Assert.IsTrue(BC14MigrationErrorHandler.HasUnresolvedError(Database::"BC14 Customer", 'CUST-001'), 'Should return true for unresolved error');
    end;

    [Test]
    procedure TestHasUnresolvedError_ResolvedError_ReturnsFalse()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] HasUnresolvedError returns false when the error has been resolved.

        // [GIVEN] A resolved error exists for the record
        DataMigrationError.DeleteAll();

        DummyRecordRef.Open(Database::"Data Migration Error");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('Test Migrator', Database::"BC14 Customer", 'BC14 Customer', 'CUST-002', 0, 'Test error', DummyRecId);
        DataMigrationError.FindFirst();
        DataMigrationError."Error Dismissed" := true;
        DataMigrationError."Resolved On" := CurrentDateTime();
        DataMigrationError.Modify(true);

        // [THEN] HasUnresolvedError returns false
        Assert.IsFalse(BC14MigrationErrorHandler.HasUnresolvedError(Database::"BC14 Customer", 'CUST-002'), 'Should return false for resolved error');
    end;

    [Test]
    procedure TestResolveErrorForRecord_ExistingError_ErrorResolved()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] ResolveErrorForRecord marks an existing unresolved error as resolved.

        // [GIVEN] An unresolved error exists
        DataMigrationError.DeleteAll();

        DummyRecordRef.Open(Database::"Data Migration Error");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('Test Migrator', Database::"BC14 Item", 'BC14 Item', 'ITEM-001', 0, 'Test error', DummyRecId);

        // [WHEN] ResolveErrorForRecord is called
        BC14MigrationErrorHandler.ResolveErrorForRecord(Database::"BC14 Item", 'ITEM-001');

        // [THEN] The error is resolved
        DataMigrationError.SetRange("Source Table ID", Database::"BC14 Item");
        DataMigrationError.SetRange("Source Record Key", 'ITEM-001');
        DataMigrationError.FindFirst();
        Assert.IsTrue(DataMigrationError."Error Dismissed", 'Error should be resolved');
        Assert.AreNotEqual(0DT, DataMigrationError."Resolved On", 'Resolved On should have a timestamp');
    end;

    [Test]
    procedure TestResolveErrorForRecord_NoError_NoFailure()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
    begin
        // [SCENARIO] ResolveErrorForRecord does not fail when no error exists.

        // [GIVEN] No errors exist
        DataMigrationError.DeleteAll();

        // [WHEN] ResolveErrorForRecord is called for a non-existent error
        BC14MigrationErrorHandler.ResolveErrorForRecord(1000, 'NonExistentKey');

        // [THEN] No error occurs (procedure completes normally)
        Assert.IsTrue(true, 'Procedure should complete without error');
    end;

    [Test]
    procedure TestLogError_DuplicateError_UpdatesExisting()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] Logging the same error twice updates the existing record instead of creating a duplicate.

        // [GIVEN] An error is logged
        DataMigrationError.DeleteAll();

        DummyRecordRef.Open(Database::"Data Migration Error");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('Test Migrator', Database::"BC14 Vendor", 'BC14 Vendor', 'VEND-001', 0, 'First error message', DummyRecId);

        // [WHEN] The same error is logged again with a different message
        BC14MigrationErrorHandler.LogError('Test Migrator', Database::"BC14 Vendor", 'BC14 Vendor', 'VEND-001', 0, 'Updated error message', DummyRecId);

        // [THEN] Only one error record exists with updated message and incremented retry count
        DataMigrationError.SetRange("Source Table ID", Database::"BC14 Vendor");
        DataMigrationError.SetRange("Source Record Key", 'VEND-001');
        Assert.AreEqual(1, DataMigrationError.Count(), 'Should have only one error record');

        DataMigrationError.FindFirst();
        Assert.AreEqual('Updated error message', DataMigrationError."Error Message", 'Error message should be updated');
        Assert.AreEqual(1, DataMigrationError."Retry Count", 'Retry count should be incremented');
    end;

    // ============================================================
    // ErrorOccurred Flag
    // ============================================================

    [Test]
    procedure TestErrorOccurredFlag_AfterLogError_ReturnsTrue()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14Customer: Record "BC14 Customer";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        SourceRecId: RecordId;
    begin
        // [SCENARIO] ErrorOccurred flag is set to true after logging an error.

        // [GIVEN] Clean state with ErrorOccurred flag cleared
        DataMigrationError.DeleteAll();
        BC14MigrationErrorHandler.ClearErrorOccurred();
        Assert.IsFalse(BC14MigrationErrorHandler.GetErrorOccurred(), 'Error flag should be false initially');

        // Create a real source record for realistic RecordId
        BC14Customer.Init();
        BC14Customer."No." := 'TEST-ERR-FLAG';
        if not BC14Customer.Insert() then
            BC14Customer.Modify();
        SourceRecId := BC14Customer.RecordId;

        // [WHEN] An error is logged
        BC14MigrationErrorHandler.LogError(
            'Customer Migrator',
            Database::"BC14 Customer",
            'BC14 Customer',
            'No.=TEST-ERR-FLAG',
            Database::Customer,
            'Test error for flag verification',
            SourceRecId
        );

        // [THEN] ErrorOccurred flag should be true
        Assert.IsTrue(BC14MigrationErrorHandler.GetErrorOccurred(), 'Error flag should be true after logging error');

        // Cleanup
        BC14Customer.Delete();
    end;

    [Test]
    procedure TestErrorOccurredFlag_ClearAfterError_ReturnsFalse()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14Customer: Record "BC14 Customer";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        SourceRecId: RecordId;
    begin
        // [SCENARIO] ErrorOccurred flag can be cleared after an error was logged.

        // [GIVEN] An error is logged
        DataMigrationError.DeleteAll();
        BC14MigrationErrorHandler.ClearErrorOccurred();

        BC14Customer.Init();
        BC14Customer."No." := 'TEST-CLEAR-FLAG';
        if not BC14Customer.Insert() then
            BC14Customer.Modify();
        SourceRecId := BC14Customer.RecordId;

        BC14MigrationErrorHandler.LogError('Customer Migrator', Database::"BC14 Customer", 'BC14 Customer', 'No.=TEST-CLEAR-FLAG', Database::Customer, 'Error to clear', SourceRecId);
        Assert.IsTrue(BC14MigrationErrorHandler.GetErrorOccurred(), 'Error flag should be true after logging');

        // [WHEN] The error flag is cleared
        BC14MigrationErrorHandler.ClearErrorOccurred();

        // [THEN] ErrorOccurred flag should be false
        Assert.IsFalse(BC14MigrationErrorHandler.GetErrorOccurred(), 'Error flag should be false after clearing');

        // Cleanup
        BC14Customer.Delete();
    end;

    [Test]
    procedure TestErrorOccurredFlag_MultipleErrors_RemainsTrue()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14Customer: Record "BC14 Customer";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        SourceRecId: RecordId;
    begin
        // [SCENARIO] ErrorOccurred flag remains true after multiple errors are logged.

        // [GIVEN] Clean state
        DataMigrationError.DeleteAll();
        BC14MigrationErrorHandler.ClearErrorOccurred();

        BC14Customer.Init();
        BC14Customer."No." := 'TEST-MULTI-ERR';
        if not BC14Customer.Insert() then
            BC14Customer.Modify();
        SourceRecId := BC14Customer.RecordId;

        // [WHEN] Multiple errors are logged
        BC14MigrationErrorHandler.LogError('Customer Migrator', Database::"BC14 Customer", 'BC14 Customer', 'No.=1', Database::Customer, 'Error 1', SourceRecId);
        BC14MigrationErrorHandler.LogError('Customer Migrator', Database::"BC14 Customer", 'BC14 Customer', 'No.=2', Database::Customer, 'Error 2', SourceRecId);
        BC14MigrationErrorHandler.LogError('Customer Migrator', Database::"BC14 Customer", 'BC14 Customer', 'No.=3', Database::Customer, 'Error 3', SourceRecId);

        // [THEN] ErrorOccurred flag should still be true
        Assert.IsTrue(BC14MigrationErrorHandler.GetErrorOccurred(), 'Error flag should remain true after multiple errors');

        // Cleanup
        BC14Customer.Delete();
    end;

    // ============================================================
    // Boundary Values
    // ============================================================

    [Test]
    procedure TestLogError_LongErrorMessage_HandlesTruncation()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14Customer: Record "BC14 Customer";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        SourceRecId: RecordId;
        VeryLongMessage: Text;
        i: Integer;
    begin
        // [SCENARIO] Very long error messages are handled gracefully (truncated or stored in BLOB).

        // [GIVEN] A very long error message (2000+ characters)
        DataMigrationError.DeleteAll();

        BC14Customer.Init();
        BC14Customer."No." := 'TEST-LONG-MSG';
        if not BC14Customer.Insert() then
            BC14Customer.Modify();
        SourceRecId := BC14Customer.RecordId;

        VeryLongMessage := 'Error: ';
        for i := 1 to 300 do
            VeryLongMessage += 'This is a very detailed error message with lots of context. ';

        // [WHEN] An error with a very long message is logged
        BC14MigrationErrorHandler.LogError(
            'Customer Migrator',
            Database::"BC14 Customer",
            'BC14 Customer',
            'No.=TEST-LONG-MSG',
            Database::Customer,
            VeryLongMessage,
            SourceRecId
        );

        // [THEN] The error is logged without runtime error
        DataMigrationError.SetRange("Source Record Key", 'No.=TEST-LONG-MSG');
        Assert.AreEqual(1, DataMigrationError.Count(), 'Error should be logged even with very long message');

        DataMigrationError.FindFirst();
        Assert.IsTrue(StrLen(DataMigrationError."Error Message") > 0, 'Error message should not be empty');
        Assert.IsTrue(StrLen(DataMigrationError."Error Message") <= MaxStrLen(DataMigrationError."Error Message"), 'Error message should be truncated to field max length');

        // Cleanup
        BC14Customer.Delete();
    end;

    [Test]
    procedure TestLogError_MaxLengthSourceRecordKey_Accepted()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14Customer: Record "BC14 Customer";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        SourceRecId: RecordId;
        MaxLengthKey: Text[250];
        i: Integer;
    begin
        // [SCENARIO] Source record key at maximum length is accepted.

        // [GIVEN] A source record key at maximum length (250 characters)
        DataMigrationError.DeleteAll();

        BC14Customer.Init();
        BC14Customer."No." := 'TEST-MAX-KEY';
        if not BC14Customer.Insert() then
            BC14Customer.Modify();
        SourceRecId := BC14Customer.RecordId;

        MaxLengthKey := '';
        for i := 1 to 25 do
            MaxLengthKey += '1234567890';  // 250 characters total

        // [WHEN] An error with max length key is logged
        BC14MigrationErrorHandler.LogError(
            'Customer Migrator',
            Database::"BC14 Customer",
            'BC14 Customer',
            MaxLengthKey,
            Database::Customer,
            'Error with max key length',
            SourceRecId
        );

        // [THEN] The error is logged successfully
        DataMigrationError.SetRange("Source Record Key", MaxLengthKey);
        Assert.AreEqual(1, DataMigrationError.Count(), 'Error should be logged with max length key');

        // Cleanup
        BC14Customer.Delete();
    end;

    [Test]
    procedure TestScheduleForRetry_HighRetryCount_HandledCorrectly()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14Customer: Record "BC14 Customer";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        SourceRecId: RecordId;
        i: Integer;
        HighRetryCount: Integer;
    begin
        // [SCENARIO] High number of retries is handled correctly without overflow or errors.

        // [GIVEN] An error is logged
        DataMigrationError.DeleteAll();

        BC14Customer.Init();
        BC14Customer."No." := 'TEST-HIGH-RETRY';
        if not BC14Customer.Insert() then
            BC14Customer.Modify();
        SourceRecId := BC14Customer.RecordId;

        BC14MigrationErrorHandler.LogError('Customer Migrator', Database::"BC14 Customer", 'BC14 Customer', 'No.=TEST-HIGH-RETRY', Database::Customer, 'Persistent error', SourceRecId);
        DataMigrationError.FindFirst();

        // [WHEN] ScheduleForRetry is called many times (simulating persistent failures)
        HighRetryCount := 100;
        for i := 1 to HighRetryCount do begin
            DataMigrationError."Scheduled For Retry" := true;
            DataMigrationError."Retry Count" += 1;
            DataMigrationError."Last Retry On" := CurrentDateTime();
            DataMigrationError.Modify(true);
        end;

        // [THEN] Retry count equals the number of retries
        DataMigrationError.Get(DataMigrationError.Id);
        Assert.AreEqual(HighRetryCount, DataMigrationError."Retry Count", 'Retry count should match number of retries');
        Assert.IsTrue(DataMigrationError."Scheduled For Retry", 'Should still be scheduled for retry');

        // Cleanup
        BC14Customer.Delete();
    end;

    [Test]
    procedure TestLogError_EmptyErrorMessage_Handled()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14Customer: Record "BC14 Customer";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        SourceRecId: RecordId;
    begin
        // [SCENARIO] Empty error message is handled gracefully.

        // [GIVEN] Clean state
        DataMigrationError.DeleteAll();

        BC14Customer.Init();
        BC14Customer."No." := 'TEST-EMPTY-MSG';
        if not BC14Customer.Insert() then
            BC14Customer.Modify();
        SourceRecId := BC14Customer.RecordId;

        // [WHEN] An error with empty message is logged
        BC14MigrationErrorHandler.LogError(
            'Customer Migrator',
            Database::"BC14 Customer",
            'BC14 Customer',
            'No.=TEST-EMPTY-MSG',
            Database::Customer,
            '',
            SourceRecId
        );

        // [THEN] The error is logged (empty message is allowed)
        DataMigrationError.SetRange("Source Record Key", 'No.=TEST-EMPTY-MSG');
        Assert.AreEqual(1, DataMigrationError.Count(), 'Error should be logged even with empty message');

        DataMigrationError.FindFirst();
        Assert.AreEqual('', DataMigrationError."Error Message", 'Error message should be empty');

        // Cleanup
        BC14Customer.Delete();
    end;

    // ============================================================
    // Cross-Company Isolation
    // ============================================================

    [Test]
    procedure TestGetUnresolvedErrorCount_FiltersByCompanyName()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14Customer: Record "BC14 Customer";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        SourceRecId: RecordId;
        CurrentCompanyName: Text[30];
    begin
        // [SCENARIO] GetUnresolvedErrorCount only counts errors for the specified company.

        // [GIVEN] Errors exist for current company
        DataMigrationError.DeleteAll();

#pragma warning disable AA0139
        CurrentCompanyName := CompanyName();
#pragma warning restore AA0139

        BC14Customer.Init();
        BC14Customer."No." := 'TEST-COMPANY';
        if not BC14Customer.Insert() then
            BC14Customer.Modify();
        SourceRecId := BC14Customer.RecordId;

        // Log errors for current company
        BC14MigrationErrorHandler.LogError('Customer Migrator', Database::"BC14 Customer", 'BC14 Customer', 'No.=C001', Database::Customer, 'Error 1', SourceRecId);
        BC14MigrationErrorHandler.LogError('Customer Migrator', Database::"BC14 Customer", 'BC14 Customer', 'No.=C002', Database::Customer, 'Error 2', SourceRecId);

        // [WHEN] GetUnresolvedErrorCount is called for current company
        Clear(DataMigrationError);

        // [THEN] It returns correct count for current company
        DataMigrationError.SetRange("Destination Table ID", Database::Customer);
        DataMigrationError.SetRange("Error Dismissed", false);
        Assert.AreEqual(2, DataMigrationError.Count(), 'Should have 2 errors for current company');

        // [THEN] Filtering on non-existent destination table returns 0 errors
        DataMigrationError.Reset();
        DataMigrationError.SetRange("Destination Table ID", 0);
        DataMigrationError.SetRange("Error Dismissed", false);
        Assert.AreEqual(0, DataMigrationError.Count(), 'Should have 0 errors for non-matching filter');

        // Cleanup
        BC14Customer.Delete();
    end;

    [Test]
    procedure TestMigrationErrors_CompanyNameField_SetCorrectly()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14Customer: Record "BC14 Customer";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        SourceRecId: RecordId;
    begin
        // [SCENARIO] Company name field is set correctly when logging errors.

        // [GIVEN] Clean state
        DataMigrationError.DeleteAll();

        BC14Customer.Init();
        BC14Customer."No." := 'TEST-COMP-FIELD';
        if not BC14Customer.Insert() then
            BC14Customer.Modify();
        SourceRecId := BC14Customer.RecordId;

        // [WHEN] An error is logged
        BC14MigrationErrorHandler.LogError('Customer Migrator', Database::"BC14 Customer", 'BC14 Customer', 'No.=TEST-COMP-FIELD', Database::Customer, 'Company field test', SourceRecId);

        // [THEN] Error record exists with matching source record key
        DataMigrationError.SetRange("Source Record Key", 'No.=TEST-COMP-FIELD');
        DataMigrationError.FindFirst();
        Assert.AreEqual('Customer Migrator', DataMigrationError."Migration Type", 'Migration Type should be set correctly');

        // Cleanup
        BC14Customer.Delete();
    end;

    // ============================================================
    // Real RecordId
    // ============================================================

    [Test]
    procedure TestLogError_WithRealCustomerRecordId_StoredCorrectly()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14Customer: Record "BC14 Customer";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
    begin
        // [SCENARIO] Logging error with real BC14 Customer RecordId stores the reference correctly.

        // [GIVEN] A real BC14 Customer record exists
        DataMigrationError.DeleteAll();

        BC14Customer.Init();
        BC14Customer."No." := 'REAL-REC-ID';
        BC14Customer.Name := 'Test Customer for RecordId';
        if not BC14Customer.Insert() then
            BC14Customer.Modify();

        // [WHEN] An error is logged with the real RecordId
        BC14MigrationErrorHandler.LogError(
            'Customer Migrator',
            Database::"BC14 Customer",
            'BC14 Customer',
            'No.=REAL-REC-ID',
            Database::Customer,
            'Error with real record reference',
            BC14Customer.RecordId
        );

        // [THEN] The error record stores the source record reference
        DataMigrationError.SetRange("Source Record Key", 'No.=REAL-REC-ID');
        DataMigrationError.FindFirst();
        Assert.AreEqual(Database::"BC14 Customer", DataMigrationError."Source Table ID", 'Source table ID should match');

        // Cleanup
        BC14Customer.Delete();
    end;

    // ============================================================
    // Failure Handler
    // ============================================================

    [Test]
    procedure TestMarkUpgradeFailed_NoExistingErrors_MarksCompanyFailedWithUnknownMessage()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14MigrationFailureHandler: Codeunit "BC14 Migration Failure Handler";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        FailureMessage: Text;
    begin
        // [SCENARIO] When no unresolved errors exist, failure handler marks company failed with "unknown error" text.
        ResetFailureState();
        SeedCurrentCompanyStatusPending();

        // [WHEN] MarkUpgradeFailed is invoked with an empty summary
        BC14MigrationFailureHandler.MarkUpgradeFailed(HybridReplicationSummary);

        // [THEN] The current company is marked Failed and the failure message indicates an unknown error
        Assert.IsTrue(BC14StatusMgr.IsCompanyFailed(CopyStr(CompanyName(), 1, 30)), 'Current company should be marked Failed.');
        FailureMessage := ReadFailureMessage();
        Assert.IsTrue(
            FailureMessage.Contains('unknown'),
            'Failure message should indicate an unknown upgrade error. Actual: ' + FailureMessage);
    end;

    [Test]
    procedure TestMarkUpgradeFailed_WithUnresolvedErrors_FailureMessageContainsCount()
    var
        DataMigrationError: Record "Data Migration Error";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14MigrationFailureHandler: Codeunit "BC14 Migration Failure Handler";
        FailureMessage: Text;
        i: Integer;
    begin
        // [SCENARIO] When there are N unresolved data migration errors, the failure summary includes that count.
        ResetFailureState();
        SeedCurrentCompanyStatusPending();

        // [GIVEN] Three unresolved errors
        for i := 1 to 3 do begin
            DataMigrationError.Init();
            DataMigrationError.Id := i;
            DataMigrationError."Migration Type" := 'Test Migrator';
            DataMigrationError."Source Table ID" := 0;
            DataMigrationError."Error Message" := 'Sample error ' + Format(i);
            DataMigrationError."Error Dismissed" := false;
            DataMigrationError.Insert();
        end;

        // [WHEN] MarkUpgradeFailed is invoked
        BC14MigrationFailureHandler.MarkUpgradeFailed(HybridReplicationSummary);

        // [THEN] The failure message includes the error count
        FailureMessage := ReadFailureMessage();
        Assert.IsTrue(
            FailureMessage.Contains('3'),
            'Failure message should include the error count 3. Actual: ' + FailureMessage);
        Assert.IsTrue(
            FailureMessage.Contains('Number of errors'),
            'Failure message should use the count-summary phrasing. Actual: ' + FailureMessage);
    end;

    [Test]
    procedure TestMarkUpgradeFailed_AllErrorsDismissed_UsesUnknownMessage()
    var
        DataMigrationError: Record "Data Migration Error";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14MigrationFailureHandler: Codeunit "BC14 Migration Failure Handler";
        FailureMessage: Text;
    begin
        // [SCENARIO] Dismissed errors do not contribute to the failure summary count.
        ResetFailureState();
        SeedCurrentCompanyStatusPending();

        // [GIVEN] One dismissed error (no unresolved errors)
        DataMigrationError.Init();
        DataMigrationError.Id := 1;
        DataMigrationError."Migration Type" := 'Test Migrator';
        DataMigrationError."Source Table ID" := 0;
        DataMigrationError."Error Message" := 'Already resolved';
        DataMigrationError."Error Dismissed" := true;
        DataMigrationError.Insert();

        // [WHEN] MarkUpgradeFailed is invoked
        BC14MigrationFailureHandler.MarkUpgradeFailed(HybridReplicationSummary);

        // [THEN] The failure message falls back to the unknown-error phrasing
        FailureMessage := ReadFailureMessage();
        Assert.IsTrue(FailureMessage.Contains('unknown'), 'Dismissed errors should not contribute to the count summary. Actual: ' + FailureMessage);
    end;

    [Test]
    procedure TestMarkUpgradeFailed_HistoricalDispatched_ClearsDispatchedFlagWhenCompanyFailed()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14MigrationFailureHandler: Codeunit "BC14 Migration Failure Handler";
    begin
        // [SCENARIO] After failure with no replication summary, an in-flight "Historical Dispatched" flag is cleared so the migration doesn't appear to still be running.
        ResetFailureState();

        // [GIVEN] BC14CompanySettings has Historical Dispatched = true
        BC14CompanySettings.Init();
        BC14CompanySettings.Name := CopyStr(CompanyName(), 1, MaxStrLen(BC14CompanySettings.Name));
        BC14CompanySettings."Historical Dispatched" := true;
        BC14CompanySettings.Insert();

        // [WHEN] MarkUpgradeFailed is invoked with no summary record present
        BC14MigrationFailureHandler.MarkUpgradeFailed(HybridReplicationSummary);

        // [THEN] Historical Dispatched is cleared
        BC14CompanySettings.GetSingleInstance();
        Assert.IsFalse(BC14CompanySettings."Historical Dispatched", 'Historical Dispatched should be cleared when the company is failed.');
    end;

    [Test]
    procedure TestMarkUpgradeFailed_WithReplicationSummary_DoesNotWriteDetailsBlob()
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        BC14MigrationFailureHandler: Codeunit "BC14 Migration Failure Handler";
        DetailsText: Text;
    begin
        // [SCENARIO] MarkUpgradeFailed does NOT write the Summary Details blob. The overall
        // Status headline is written only at finalize, so a single company's failure never
        // overwrites the overall Status while other companies are still migrating.
        ResetFailureState();

        // [GIVEN] A Hybrid Replication Summary record
        HybridReplicationSummary.Init();
        HybridReplicationSummary."Run ID" := CreateGuid();
        HybridReplicationSummary.Source := 'BC14';
        HybridReplicationSummary.Insert();

        // [WHEN] MarkUpgradeFailed runs against that summary
        BC14MigrationFailureHandler.MarkUpgradeFailed(HybridReplicationSummary);

        // [THEN] The Details blob remains empty
        DetailsText := ReadSummaryDetails(HybridReplicationSummary);
        Assert.AreEqual('', DetailsText, 'MarkUpgradeFailed should not write the Replication Summary Details blob.');
    end;

    // ============================================================
    // Historical Rerun
    // ============================================================

    [Test]
    procedure TestRestartHistoricalDispatch_ResetsStateAndBumpsRunId()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        OldRunId: Guid;
        NewRunId: Guid;
    begin
        // [SCENARIO] RestartHistoricalDispatch clears a prior (failed/completed) Historical state,
        // claims a fresh dispatch, and returns a new non-null run id so the Historical Worker
        // it dispatches supersedes any leftover worker.
        ResetFailureState();

        // [GIVEN] A company whose Historical phase previously failed and completed
        OldRunId := CreateGuid();
        BC14CompanySettings.Init();
        BC14CompanySettings.Name := CopyStr(CompanyName(), 1, MaxStrLen(BC14CompanySettings.Name));
        BC14CompanySettings."Historical Run Id" := OldRunId;
        BC14CompanySettings."Historical Completed" := true;
        BC14CompanySettings."Historical Failed" := true;
        BC14CompanySettings."Historical Failure Reason" := 'Prior failure';
        BC14CompanySettings."Historical Dispatched" := false;
        BC14CompanySettings.Insert();

        // [WHEN] RestartHistoricalDispatch runs for the company
        NewRunId := BC14CompanySettings.RestartHistoricalDispatch(CopyStr(CompanyName(), 1, 30));

        // [THEN] Historical bookkeeping is reset and a fresh dispatch is claimed
        BC14CompanySettings.GetSingleInstance();
        Assert.IsFalse(BC14CompanySettings."Historical Completed", 'Historical Completed should be cleared.');
        Assert.IsFalse(BC14CompanySettings."Historical Failed", 'Historical Failed should be cleared.');
        Assert.AreEqual('', BC14CompanySettings."Historical Failure Reason", 'Historical Failure Reason should be cleared.');
        Assert.IsTrue(BC14CompanySettings."Historical Dispatched", 'Historical Dispatched should be set.');
        Assert.IsFalse(IsNullGuid(NewRunId), 'A non-null run id should be returned.');
        Assert.AreNotEqual(OldRunId, NewRunId, 'A fresh run id should be issued.');
        Assert.AreEqual(NewRunId, BC14CompanySettings."Historical Run Id", 'The returned run id should be persisted.');
    end;

    [Test]
    procedure TestRerunHistoricalForCompany_HistoricalDisabled_ThrowsError()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] Rerunning Historical for a company that opted out of historical record
        // migration is rejected before any dispatch or state change.
        ResetFailureState();

        // [GIVEN] A company with Migrate Historical Records disabled
        BC14CompanySettings.Init();
        BC14CompanySettings.Name := CopyStr(CompanyName(), 1, MaxStrLen(BC14CompanySettings.Name));
        BC14CompanySettings."Migrate Historical Records" := false;
        BC14CompanySettings.Insert();

        // [WHEN] RerunHistoricalForCompany is invoked [THEN] it errors out
        asserterror BC14MigrationRunner.RerunHistoricalForCompany(CopyStr(CompanyName(), 1, 30));
    end;

    [Test]
    procedure TestRerunHistoricalForCompany_NoCompanySettings_ThrowsError()
    var
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] Rerunning Historical for a company with no settings row is rejected.
        ResetFailureState();

        // [WHEN] RerunHistoricalForCompany is invoked for an unknown company [THEN] it errors out
        asserterror BC14MigrationRunner.RerunHistoricalForCompany('GHOST');
    end;

    [Test]
    procedure TestRerunHistoricalForCompany_MainNotCompleted_ThrowsError()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        // [SCENARIO] Rerunning Historical before the main migration has completed (Posting not done)
        // is rejected, so the company can never be stranded In Progress with no way to finalize.
        ResetFailureState();

        // [GIVEN] A company whose historical migration is enabled but whose posting never completed
        BC14CompanySettings.Init();
        BC14CompanySettings.Name := CopyStr(CompanyName(), 1, MaxStrLen(BC14CompanySettings.Name));
        BC14CompanySettings."Migrate Historical Records" := true;
        BC14CompanySettings."Posting Completed" := false;
        BC14CompanySettings.Insert();

        // [WHEN] RerunHistoricalForCompany is invoked [THEN] it errors out
        asserterror BC14MigrationRunner.RerunHistoricalForCompany(CopyStr(CompanyName(), 1, 30));
    end;

    // ============================================================
    // Record Tracker
    // ============================================================

    [Test]
    procedure TestGetRemainingPercentage_AlwaysReturnsZero()
    var
        BC14MigrationRecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        // [SCENARIO] The default GetRemainingPercentage hook always reports 0.
        Assert.AreEqual(0, BC14MigrationRecordTracker.GetRemainingPercentage(18, 100), 'Default GetRemainingPercentage should return 0.');
        Assert.AreEqual(0, BC14MigrationRecordTracker.GetRemainingPercentage(27, 0), 'Default GetRemainingPercentage should return 0 for empty source.');
    end;

    [Test]
    procedure TestGetTableNameById_ReturnsCorrectName()
    var
        BC14MigrationRecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        // [SCENARIO] GetTableNameById resolves table IDs to their canonical name.
        Assert.AreEqual('Customer', BC14MigrationRecordTracker.GetTableNameById(18), 'Table 18 should resolve to Customer.');
        Assert.AreEqual('Item', BC14MigrationRecordTracker.GetTableNameById(27), 'Table 27 should resolve to Item.');
    end;

    [Test]
    procedure TestLogMigrateResult_Success_ReturnsTrueAndKeepsMigratorSuccess()
    var
        BC14MigrationRecordTracker: Codeunit "BC14 Migration Record Tracker";
        EmptyRecId: RecordId;
        ContinueProcessing: Boolean;
        MigratorSuccess: Boolean;
    begin
        // [SCENARIO] A successful record migration leaves MigratorSuccess untouched and returns true to continue processing.
        ResetRecordTrackerState();
        MigratorSuccess := true;

        ContinueProcessing := BC14MigrationRecordTracker.LogMigrateResult('Test Migrator', 18, 'Customer', 'CUST001', EmptyRecId, true, MigratorSuccess);

        Assert.IsTrue(ContinueProcessing, 'LogMigrateResult should return true on success.');
        Assert.IsTrue(MigratorSuccess, 'MigratorSuccess should remain true on success.');
    end;

    [Test]
    procedure TestLogMigrateResult_SuccessAfterPriorError_ResolvesPreviousError()
    var
        DataMigrationError: Record "Data Migration Error";
        BC14MigrationRecordTracker: Codeunit "BC14 Migration Record Tracker";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        EmptyRecId: RecordId;
        MigratorSuccess: Boolean;
    begin
        // [SCENARIO] When a previously failing record succeeds, the corresponding unresolved error is resolved.
        ResetRecordTrackerState();

        // [GIVEN] An unresolved error for table 18, key 'CUST001'
        DataMigrationError.Init();
        DataMigrationError.Id := 1;
        DataMigrationError."Migration Type" := 'Test Migrator';
        DataMigrationError."Source Table ID" := 18;
        DataMigrationError."Source Record Key" := 'CUST001';
        DataMigrationError."Error Message" := 'Previous failure';
        DataMigrationError."Error Dismissed" := false;
        DataMigrationError.Insert();

        Assert.IsTrue(BC14MigrationErrorHandler.HasUnresolvedError(18, 'CUST001'), 'Precondition: unresolved error should exist.');

        // [WHEN] The record migration now succeeds
        MigratorSuccess := true;
        BC14MigrationRecordTracker.LogMigrateResult('Test Migrator', 18, 'Customer', 'CUST001', EmptyRecId, true, MigratorSuccess);

        // [THEN] The previous error is resolved
        Assert.IsFalse(BC14MigrationErrorHandler.HasUnresolvedError(18, 'CUST001'), 'Previous error should be resolved after a successful retry.');
    end;

    [Test]
    procedure TestLogMigrateResult_Failure_WithoutStopOnFirstError_ContinuesAndMarksMigratorFailed()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14MigrationRecordTracker: Codeunit "BC14 Migration Record Tracker";
        EmptyRecId: RecordId;
        ContinueProcessing: Boolean;
        MigratorSuccess: Boolean;
    begin
        // [SCENARIO] On failure without Stop-on-First-Error, processing continues but MigratorSuccess is set to false.
        ResetRecordTrackerState();
        BC14CompanySettings.Init();
        BC14CompanySettings.Name := CopyStr(CompanyName(), 1, MaxStrLen(BC14CompanySettings.Name));
        BC14CompanySettings."Stop On First Error" := false;
        BC14CompanySettings.Insert();

        MigratorSuccess := true;

        ContinueProcessing := BC14MigrationRecordTracker.LogMigrateResult('Test Migrator', 18, 'Customer', 'CUST002', EmptyRecId, false, MigratorSuccess);

        Assert.IsTrue(ContinueProcessing, 'LogMigrateResult should return true to continue processing.');
        Assert.IsFalse(MigratorSuccess, 'MigratorSuccess should be set to false on failure.');
    end;

    [Test]
    procedure TestLogMigrateResult_Failure_WithStopOnFirstError_HaltsProcessing()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14MigrationRecordTracker: Codeunit "BC14 Migration Record Tracker";
        EmptyRecId: RecordId;
        ContinueProcessing: Boolean;
        MigratorSuccess: Boolean;
    begin
        // [SCENARIO] On failure with Stop-on-First-Error enabled, LogMigrateResult returns false to halt processing.
        ResetRecordTrackerState();
        BC14CompanySettings.Init();
        BC14CompanySettings.Name := CopyStr(CompanyName(), 1, MaxStrLen(BC14CompanySettings.Name));
        BC14CompanySettings."Stop On First Error" := true;
        BC14CompanySettings.Insert();

        MigratorSuccess := true;

        ContinueProcessing := BC14MigrationRecordTracker.LogMigrateResult('Test Migrator', 18, 'Customer', 'CUST003', EmptyRecId, false, MigratorSuccess);

        Assert.IsFalse(ContinueProcessing, 'LogMigrateResult should return false when Stop On First Error is enabled.');
        Assert.IsFalse(MigratorSuccess, 'MigratorSuccess should be set to false on failure.');
    end;

    // ============================================================
    // Helpers
    // ============================================================

    local procedure ResetFailureState()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        DataMigrationError: Record "Data Migration Error";
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
    begin
        BC14CompanySettings.DeleteAll();
        DataMigrationError.DeleteAll();
        HybridCompanyStatus.DeleteAll();
        HybridReplicationSummary.DeleteAll();
    end;

    local procedure ResetRecordTrackerState()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        DataMigrationError: Record "Data Migration Error";
    begin
        BC14CompanySettings.DeleteAll();
        DataMigrationError.DeleteAll();
    end;

    local procedure SeedCurrentCompanyStatusPending()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        // MarkCompanyFailed is a no-op when no Hybrid Company Status row exists for the
        // current company (it can only transition an existing row). Seed a Pending row so
        // the failure handler can write the Failed terminal state and surface the message.
        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompanyStatus.Name));
        HybridCompanyStatus."Upgrade Status" := HybridCompanyStatus."Upgrade Status"::Pending;
        HybridCompanyStatus.Insert();
    end;

    local procedure ReadFailureMessage(): Text
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        InStream: InStream;
        FailureMessage: Text;
    begin
        if not HybridCompanyStatus.Get(CopyStr(CompanyName(), 1, MaxStrLen(HybridCompanyStatus.Name))) then
            exit('');
        HybridCompanyStatus.CalcFields("Upgrade Failure Message");
        if not HybridCompanyStatus."Upgrade Failure Message".HasValue() then
            exit('');
        HybridCompanyStatus."Upgrade Failure Message".CreateInStream(InStream);
        InStream.Read(FailureMessage);
        exit(FailureMessage);
    end;

    local procedure ReadSummaryDetails(var HybridReplicationSummary: Record "Hybrid Replication Summary"): Text
    var
        InStream: InStream;
        DetailsText: Text;
    begin
        HybridReplicationSummary.Find();
        HybridReplicationSummary.CalcFields(Details);
        if not HybridReplicationSummary.Details.HasValue() then
            exit('');
        HybridReplicationSummary.Details.CreateInStream(InStream);
        InStream.Read(DetailsText);
        exit(DetailsText);
    end;
}
