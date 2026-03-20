// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 148911 "BC14 Migration Error Tests"
{
    // [FEATURE] [BC14 Cloud Migration Error Handling]

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TestLogError()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] Errors are correctly logged to the BC14 Migration Errors table.

        // [GIVEN] No migration errors exist
        BC14MigrationErrors.DeleteAll();

        // Create a dummy record ID
        DummyRecordRef.Open(Database::"BC14 Migration Errors");
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
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        Assert.AreEqual(1, BC14MigrationErrors.Count(), 'Should have exactly 1 error record');

        BC14MigrationErrors.FindFirst();
        Assert.AreEqual('G/L Account Migrator', BC14MigrationErrors."Migration Type", 'Migration Type - Incorrect value');
        Assert.AreEqual(Database::"BC14 G/L Account", BC14MigrationErrors."Source Table ID", 'Source Table ID - Incorrect value');
        Assert.AreEqual('BC14 G/L Account', BC14MigrationErrors."Source Table Name", 'Source Table Name - Incorrect value');
        Assert.AreEqual('No.=1200', BC14MigrationErrors."Source Record Key", 'Source Record Key - Incorrect value');
        Assert.AreEqual(Database::"G/L Account", BC14MigrationErrors."Destination Table ID", 'Destination Table ID - Incorrect value');
        Assert.AreEqual('Account category must have a value.', BC14MigrationErrors."Error Message", 'Error Message - Incorrect value');
        Assert.AreNotEqual(0DT, BC14MigrationErrors."Created On", 'Created On - Should have a timestamp');
        Assert.AreEqual(false, BC14MigrationErrors."Resolved", 'Resolved - Should be false initially');
        Assert.AreEqual(0, BC14MigrationErrors."Retry Count", 'Retry Count - Should be 0 initially');
    end;

    [Test]
    procedure TestLogMultipleErrors()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] Multiple errors can be logged.

        // [GIVEN] No migration errors exist
        BC14MigrationErrors.DeleteAll();

        DummyRecordRef.Open(Database::"BC14 Migration Errors");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        // [WHEN] Multiple errors are logged
        BC14MigrationErrorHandler.LogError('G/L Account Migrator', Database::"BC14 G/L Account", 'BC14 G/L Account', 'No.=1200', Database::"G/L Account", 'Error 1', DummyRecId);
        BC14MigrationErrorHandler.LogError('Customer Migrator', Database::"BC14 Customer", 'BC14 Customer', 'No.=C001', Database::Customer, 'Error 2', DummyRecId);
        BC14MigrationErrorHandler.LogError('Vendor Migrator', Database::"BC14 Vendor", 'BC14 Vendor', 'No.=V001', Database::Vendor, 'Error 3', DummyRecId);

        // [THEN] All errors are recorded
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        Assert.AreEqual(3, BC14MigrationErrors.Count(), 'Should have exactly 3 error records');
    end;

    [Test]
    procedure TestMarkErrorAsResolved()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] An error can be marked as resolved.

        // [GIVEN] An error is logged
        BC14MigrationErrors.DeleteAll();

        DummyRecordRef.Open(Database::"BC14 Migration Errors");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('G/L Account Migrator', Database::"BC14 G/L Account", 'BC14 G/L Account', 'No.=1200', Database::"G/L Account", 'Account error', DummyRecId);
        BC14MigrationErrors.FindFirst();

        // [WHEN] The error is marked as resolved
        BC14MigrationErrors.MarkAsResolved('Fixed by manual adjustment');

        // [THEN] The error is resolved with correct values
        BC14MigrationErrors.Get(BC14MigrationErrors.Id);
        Assert.AreEqual(true, BC14MigrationErrors."Resolved", 'Resolved - Should be true');
        Assert.AreNotEqual(0DT, BC14MigrationErrors."Resolved On", 'Resolved On - Should have a timestamp');
        Assert.AreEqual('Fixed by manual adjustment', BC14MigrationErrors."Resolution Notes", 'Resolution Notes - Incorrect value');
    end;

    [Test]
    procedure TestScheduleErrorForRetry()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] An error can be scheduled for retry.

        // [GIVEN] An error is logged
        BC14MigrationErrors.DeleteAll();

        DummyRecordRef.Open(Database::"BC14 Migration Errors");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('G/L Account Migrator', Database::"BC14 G/L Account", 'BC14 G/L Account', 'No.=1200', Database::"G/L Account", 'Temporary error', DummyRecId);
        BC14MigrationErrors.FindFirst();

        // [WHEN] The error is scheduled for retry
        BC14MigrationErrors.ScheduleForRetry();

        // [THEN] The error is scheduled with correct values
        BC14MigrationErrors.Get(BC14MigrationErrors.Id);
        Assert.AreEqual(true, BC14MigrationErrors."Scheduled For Retry", 'Scheduled For Retry - Should be true');
        Assert.AreEqual(1, BC14MigrationErrors."Retry Count", 'Retry Count - Should be 1 after first retry');
        Assert.AreNotEqual(0DT, BC14MigrationErrors."Last Retry On", 'Last Retry On - Should have a timestamp');
    end;

    [Test]
    procedure TestRetryCountIncrements()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] Retry count increments with each retry.

        // [GIVEN] An error is logged
        BC14MigrationErrors.DeleteAll();

        DummyRecordRef.Open(Database::"BC14 Migration Errors");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('Item Migrator', Database::"BC14 Item", 'BC14 Item', 'No.=ITEM-1', Database::Item, 'Transient error', DummyRecId);
        BC14MigrationErrors.FindFirst();

        // [WHEN] The error is retried multiple times
        BC14MigrationErrors.ScheduleForRetry();
        BC14MigrationErrors.ScheduleForRetry();
        BC14MigrationErrors.ScheduleForRetry();

        // [THEN] The retry count is 3
        BC14MigrationErrors.Get(BC14MigrationErrors.Id);
        Assert.AreEqual(3, BC14MigrationErrors."Retry Count", 'Retry Count - Should be 3 after three retries');
    end;

    [Test]
    procedure TestGetUnresolvedErrorCount()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
        CompanyNameText: Text[30];
    begin
        // [SCENARIO] GetUnresolvedErrorCount returns the correct count of unresolved errors.

        // [GIVEN] Multiple errors are logged, some resolved and some not
        BC14MigrationErrors.DeleteAll();

#pragma warning disable AA0139
        CompanyNameText := CompanyName();
#pragma warning restore AA0139

        DummyRecordRef.Open(Database::"BC14 Migration Errors");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('G/L Account Migrator', Database::"BC14 G/L Account", 'BC14 G/L Account', 'No.=1200', Database::"G/L Account", 'Error 1', DummyRecId);
        BC14MigrationErrorHandler.LogError('G/L Account Migrator', Database::"BC14 G/L Account", 'BC14 G/L Account', 'No.=1300', Database::"G/L Account", 'Error 2', DummyRecId);
        BC14MigrationErrorHandler.LogError('G/L Account Migrator', Database::"BC14 G/L Account", 'BC14 G/L Account', 'No.=1400', Database::"G/L Account", 'Error 3', DummyRecId);

        // Resolve one of the errors
        BC14MigrationErrors.FindFirst();
        BC14MigrationErrors.MarkAsResolved('Fixed');

        // [WHEN] GetUnresolvedErrorCount is called
        Clear(BC14MigrationErrors);

        // [THEN] It should return 2 (3 total - 1 resolved)
        Assert.AreEqual(2, BC14MigrationErrors.GetUnresolvedErrorCount(Database::"G/L Account", CompanyNameText), 'Should have 2 unresolved errors');
    end;

    [Test]
    procedure TestErrorOccurredFlag()
    var
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
    begin
        // [SCENARIO] The ErrorOccurred flag can be cleared and queried.
        // Note: ErrorOccurred is set via event subscribers on the system "Data Migration Error" table,
        // not via LogError (which inserts into "BC14 Migration Errors"). The full flow is covered by E2E tests.

        // [GIVEN] The error occurred flag is cleared
        BC14MigrationErrorHandler.ClearErrorOccurred();

        // [THEN] GetErrorOccurred should return false
        Assert.AreEqual(false, BC14MigrationErrorHandler.GetErrorOccurred(), 'GetErrorOccurred - Should be false after clearing');
    end;

    [Test]
    procedure TestErrorOverviewIsCreated()
    var
        BC14MigrationErrorOverview: Record "BC14 Migration Error Overview";
    begin
        // [SCENARIO] Error Overview records can be created and read.

        // [GIVEN] No error overview records exist
        BC14MigrationErrorOverview.DeleteAll();

        // [WHEN] An error overview record is created
        BC14MigrationErrorOverview.Init();
        BC14MigrationErrorOverview.Id := 1;
        BC14MigrationErrorOverview."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(BC14MigrationErrorOverview."Company Name"));
        BC14MigrationErrorOverview."Migration Type" := 'G/L Account Migrator';
        BC14MigrationErrorOverview."Destination Table ID" := Database::"G/L Account";
        BC14MigrationErrorOverview."Error Message" := 'Test error message';
        BC14MigrationErrorOverview.Insert();

        // [THEN] The record can be read
        BC14MigrationErrorOverview.Get(1, CompanyName());
        Assert.AreEqual('G/L Account Migrator', BC14MigrationErrorOverview."Migration Type", 'Migration Type - Incorrect value');
        Assert.AreEqual('Test error message', BC14MigrationErrorOverview."Error Message", 'Error Message - Incorrect value');
    end;

    [Test]
    procedure TestErrorOverviewFullExceptionMessage()
    var
        BC14MigrationErrorOverview: Record "BC14 Migration Error Overview";
        TestMessage: Text;
    begin
        // [SCENARIO] Full exception message can be stored and retrieved from the BLOB field.

        // [GIVEN] An error overview record is created
        BC14MigrationErrorOverview.DeleteAll();

        BC14MigrationErrorOverview.Init();
        BC14MigrationErrorOverview.Id := 1;
        BC14MigrationErrorOverview."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(BC14MigrationErrorOverview."Company Name"));
        BC14MigrationErrorOverview."Migration Type" := 'Test Migrator';
        BC14MigrationErrorOverview."Error Message" := 'Short error';
        BC14MigrationErrorOverview.Insert();

        // [WHEN] A full exception message is set
        TestMessage := 'This is a long exception message with details about what went wrong during the migration process, including stack trace information and other debugging data.';
        BC14MigrationErrorOverview.SetFullExceptionMessage(TestMessage);

        // [THEN] The full exception message can be retrieved
        Clear(BC14MigrationErrorOverview);
        BC14MigrationErrorOverview.Get(1, CompanyName());
        Assert.AreEqual(TestMessage, BC14MigrationErrorOverview.GetFullExceptionMessage(), 'Full exception message should match');
    end;

    [Test]
    procedure TestErrorOverviewExceptionCallStack()
    var
        BC14MigrationErrorOverview: Record "BC14 Migration Error Overview";
        TestCallStack: Text;
    begin
        // [SCENARIO] Exception call stack can be stored and retrieved from the BLOB field.

        // [GIVEN] An error overview record is created
        BC14MigrationErrorOverview.DeleteAll();

        BC14MigrationErrorOverview.Init();
        BC14MigrationErrorOverview.Id := 1;
        BC14MigrationErrorOverview."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(BC14MigrationErrorOverview."Company Name"));
        BC14MigrationErrorOverview."Migration Type" := 'Test Migrator';
        BC14MigrationErrorOverview."Error Message" := 'Short error';
        BC14MigrationErrorOverview.Insert();

        // [WHEN] An exception call stack is set
        TestCallStack := 'Codeunit BC14 Cloud Migration(OnRun) line 42 - BC14ReimplementationTool by Microsoft\Codeunit BC14 Migration Runner(RunMigration) line 55';
        BC14MigrationErrorOverview.SetExceptionCallStack(TestCallStack);

        // [THEN] The exception call stack can be retrieved
        Clear(BC14MigrationErrorOverview);
        BC14MigrationErrorOverview.Get(1, CompanyName());
        Assert.AreEqual(TestCallStack, BC14MigrationErrorOverview.GetExceptionCallStack(), 'Exception call stack should match');
    end;

    [Test]
    procedure TestErrorOverviewRecordsUnderProcessingLog()
    var
        BC14MigrationErrorOverview: Record "BC14 Migration Error Overview";
        TestLog: Text;
    begin
        // [SCENARIO] Records under processing log can be stored and retrieved from the BLOB field.

        // [GIVEN] An error overview record is created
        BC14MigrationErrorOverview.DeleteAll();

        BC14MigrationErrorOverview.Init();
        BC14MigrationErrorOverview.Id := 1;
        BC14MigrationErrorOverview."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(BC14MigrationErrorOverview."Company Name"));
        BC14MigrationErrorOverview."Migration Type" := 'Test Migrator';
        BC14MigrationErrorOverview."Error Message" := 'Short error';
        BC14MigrationErrorOverview.Insert();

        // [WHEN] A records under processing log is set
        TestLog := 'Processing record: G/L Account No. 1200, Name: Cash Account';
        BC14MigrationErrorOverview.SetLastRecordUnderProcessingLog(TestLog);

        // [THEN] The log can be retrieved
        Clear(BC14MigrationErrorOverview);
        BC14MigrationErrorOverview.Get(1, CompanyName());
        Assert.AreEqual(TestLog, BC14MigrationErrorOverview.GetLastRecordsUnderProcessingLog(), 'Records under processing log should match');
    end;

    [Test]
    procedure TestErrorOverviewEmptyBlobFields()
    var
        BC14MigrationErrorOverview: Record "BC14 Migration Error Overview";
    begin
        // [SCENARIO] Empty BLOB fields return empty strings.

        // [GIVEN] An error overview record is created without setting BLOB fields
        BC14MigrationErrorOverview.DeleteAll();

        BC14MigrationErrorOverview.Init();
        BC14MigrationErrorOverview.Id := 1;
        BC14MigrationErrorOverview."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(BC14MigrationErrorOverview."Company Name"));
        BC14MigrationErrorOverview."Migration Type" := 'Test Migrator';
        BC14MigrationErrorOverview."Error Message" := 'Short error';
        BC14MigrationErrorOverview.Insert();

        // [THEN] All BLOB getters return empty strings
        Assert.AreEqual('', BC14MigrationErrorOverview.GetFullExceptionMessage(), 'GetFullExceptionMessage should return empty string for empty BLOB');
        Assert.AreEqual('', BC14MigrationErrorOverview.GetExceptionCallStack(), 'GetExceptionCallStack should return empty string for empty BLOB');
        Assert.AreEqual('', BC14MigrationErrorOverview.GetLastRecordsUnderProcessingLog(), 'GetLastRecordsUnderProcessingLog should return empty string for empty BLOB');
    end;

    [Test]
    procedure TestUnblockForRetry()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] An error can be unblocked for manual correction and retry.

        // [GIVEN] An error is logged and previously marked as resolved
        BC14MigrationErrors.DeleteAll();

        DummyRecordRef.Open(Database::"BC14 Migration Errors");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('G/L Account Migrator', Database::"BC14 G/L Account", 'BC14 G/L Account', 'No.=1200', Database::"G/L Account", 'Account error', DummyRecId);
        BC14MigrationErrors.FindFirst();
        BC14MigrationErrors.MarkAsResolved('Initially resolved');

        // [WHEN] The error is unblocked for retry with a note
        BC14MigrationErrors.Get(BC14MigrationErrors.Id);
        BC14MigrationErrors.UnblockForRetry('Unblocked for manual fix');

        // [THEN] The error is unblocked with correct values
        BC14MigrationErrors.Get(BC14MigrationErrors.Id);
        Assert.AreEqual(false, BC14MigrationErrors."Resolved", 'Resolved - Should be false after unblock');
        Assert.AreEqual(0DT, BC14MigrationErrors."Resolved On", 'Resolved On - Should be cleared');
        Assert.AreEqual('', BC14MigrationErrors."Resolved By", 'Resolved By - Should be cleared');
        Assert.AreEqual(true, BC14MigrationErrors."Scheduled For Retry", 'Scheduled For Retry - Should be true');
        Assert.AreEqual('Unblocked for manual fix', BC14MigrationErrors."Resolution Notes", 'Resolution Notes - Should contain unblock note');
    end;

    [Test]
    procedure TestUnblockForRetryWithEmptyNote()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] UnblockForRetry with empty note preserves existing resolution notes.

        // [GIVEN] An error is logged and previously marked as resolved with a note
        BC14MigrationErrors.DeleteAll();

        DummyRecordRef.Open(Database::"BC14 Migration Errors");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('Customer Migrator', Database::"BC14 Customer", 'BC14 Customer', 'No.=C001', Database::Customer, 'Customer error', DummyRecId);
        BC14MigrationErrors.FindFirst();
        BC14MigrationErrors.MarkAsResolved('Original resolution note');

        // [WHEN] The error is unblocked for retry with an empty note
        BC14MigrationErrors.Get(BC14MigrationErrors.Id);
        BC14MigrationErrors.UnblockForRetry('');

        // [THEN] The original resolution notes are preserved
        BC14MigrationErrors.Get(BC14MigrationErrors.Id);
        Assert.AreEqual(false, BC14MigrationErrors."Resolved", 'Resolved - Should be false after unblock');
        Assert.AreEqual(true, BC14MigrationErrors."Scheduled For Retry", 'Scheduled For Retry - Should be true');
        Assert.AreEqual('Original resolution note', BC14MigrationErrors."Resolution Notes", 'Resolution Notes - Should preserve original note when empty');
    end;

    [Test]
    procedure TestUnblockForRetryOnUnresolvedError()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] UnblockForRetry can be called on an error that was never resolved.

        // [GIVEN] An error is logged but not resolved
        BC14MigrationErrors.DeleteAll();

        DummyRecordRef.Open(Database::"BC14 Migration Errors");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('Item Migrator', Database::"BC14 Item", 'BC14 Item', 'No.=ITEM-1', Database::Item, 'Item error', DummyRecId);
        BC14MigrationErrors.FindFirst();

        // Verify initial state
        Assert.AreEqual(false, BC14MigrationErrors."Resolved", 'Resolved - Should be false initially');
        Assert.AreEqual(false, BC14MigrationErrors."Scheduled For Retry", 'Scheduled For Retry - Should be false initially');

        // [WHEN] The error is unblocked for retry
        BC14MigrationErrors.UnblockForRetry('Ready to retry');

        // [THEN] The error is scheduled for retry
        BC14MigrationErrors.Get(BC14MigrationErrors.Id);
        Assert.AreEqual(false, BC14MigrationErrors."Resolved", 'Resolved - Should remain false');
        Assert.AreEqual(true, BC14MigrationErrors."Scheduled For Retry", 'Scheduled For Retry - Should be true');
        Assert.AreEqual('Ready to retry', BC14MigrationErrors."Resolution Notes", 'Resolution Notes - Should contain unblock note');
    end;

    [Test]
    procedure TestHasUnresolvedError_NoError_ReturnsFalse()
    var
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14MigrationErrors: Record "BC14 Migration Errors";
    begin
        // [SCENARIO] HasUnresolvedError returns false when no error exists for the record.

        // [GIVEN] No errors exist
        BC14MigrationErrors.DeleteAll();

        // [THEN] HasUnresolvedError returns false
        Assert.IsFalse(BC14MigrationErrorHandler.HasUnresolvedError(1000, 'NonExistentKey'), 'Should return false when no error exists');
    end;

    [Test]
    procedure TestHasUnresolvedError_UnresolvedError_ReturnsTrue()
    var
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14MigrationErrors: Record "BC14 Migration Errors";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] HasUnresolvedError returns true when an unresolved error exists.

        // [GIVEN] An unresolved error exists for the record
        BC14MigrationErrors.DeleteAll();

        DummyRecordRef.Open(Database::"BC14 Migration Errors");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('Test Migrator', Database::"BC14 Customer", 'BC14 Customer', 'CUST-001', 0, 'Test error', DummyRecId);

        // [THEN] HasUnresolvedError returns true
        Assert.IsTrue(BC14MigrationErrorHandler.HasUnresolvedError(Database::"BC14 Customer", 'CUST-001'), 'Should return true for unresolved error');
    end;

    [Test]
    procedure TestHasUnresolvedError_ResolvedError_ReturnsFalse()
    var
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14MigrationErrors: Record "BC14 Migration Errors";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] HasUnresolvedError returns false when the error has been resolved.

        // [GIVEN] A resolved error exists for the record
        BC14MigrationErrors.DeleteAll();

        DummyRecordRef.Open(Database::"BC14 Migration Errors");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('Test Migrator', Database::"BC14 Customer", 'BC14 Customer', 'CUST-002', 0, 'Test error', DummyRecId);
        BC14MigrationErrors.FindFirst();
        BC14MigrationErrors.MarkAsResolved('Fixed');

        // [THEN] HasUnresolvedError returns false
        Assert.IsFalse(BC14MigrationErrorHandler.HasUnresolvedError(Database::"BC14 Customer", 'CUST-002'), 'Should return false for resolved error');
    end;

    [Test]
    procedure TestResolveErrorForRecord_ExistingError_ErrorResolved()
    var
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14MigrationErrors: Record "BC14 Migration Errors";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] ResolveErrorForRecord marks an existing unresolved error as resolved.

        // [GIVEN] An unresolved error exists
        BC14MigrationErrors.DeleteAll();

        DummyRecordRef.Open(Database::"BC14 Migration Errors");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('Test Migrator', Database::"BC14 Item", 'BC14 Item', 'ITEM-001', 0, 'Test error', DummyRecId);

        // [WHEN] ResolveErrorForRecord is called
        BC14MigrationErrorHandler.ResolveErrorForRecord(Database::"BC14 Item", 'ITEM-001');

        // [THEN] The error is resolved
        BC14MigrationErrors.SetRange("Source Table ID", Database::"BC14 Item");
        BC14MigrationErrors.SetRange("Source Record Key", 'ITEM-001');
        BC14MigrationErrors.FindFirst();
        Assert.IsTrue(BC14MigrationErrors."Resolved", 'Error should be resolved');
        Assert.AreNotEqual(0DT, BC14MigrationErrors."Resolved On", 'Resolved On should have a timestamp');
        Assert.IsTrue(BC14MigrationErrors."Resolution Notes".Contains('Auto-resolved'), 'Resolution notes should indicate auto-resolution');
    end;

    [Test]
    procedure TestResolveErrorForRecord_NoError_NoFailure()
    var
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14MigrationErrors: Record "BC14 Migration Errors";
    begin
        // [SCENARIO] ResolveErrorForRecord does not fail when no error exists.

        // [GIVEN] No errors exist
        BC14MigrationErrors.DeleteAll();

        // [WHEN] ResolveErrorForRecord is called for a non-existent error
        BC14MigrationErrorHandler.ResolveErrorForRecord(1000, 'NonExistentKey');

        // [THEN] No error occurs (procedure completes normally)
        Assert.IsTrue(True, 'Procedure should complete without error');
    end;

    [Test]
    procedure TestLogError_DuplicateError_UpdatesExisting()
    var
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14MigrationErrors: Record "BC14 Migration Errors";
        DummyRecordRef: RecordRef;
        DummyRecId: RecordId;
    begin
        // [SCENARIO] Logging the same error twice updates the existing record instead of creating a duplicate.

        // [GIVEN] An error is logged
        BC14MigrationErrors.DeleteAll();

        DummyRecordRef.Open(Database::"BC14 Migration Errors");
        DummyRecId := DummyRecordRef.RecordId;
        DummyRecordRef.Close();

        BC14MigrationErrorHandler.LogError('Test Migrator', Database::"BC14 Vendor", 'BC14 Vendor', 'VEND-001', 0, 'First error message', DummyRecId);

        // [WHEN] The same error is logged again with a different message
        BC14MigrationErrorHandler.LogError('Test Migrator', Database::"BC14 Vendor", 'BC14 Vendor', 'VEND-001', 0, 'Updated error message', DummyRecId);

        // [THEN] Only one error record exists with updated message and incremented retry count
        BC14MigrationErrors.SetRange("Source Table ID", Database::"BC14 Vendor");
        BC14MigrationErrors.SetRange("Source Record Key", 'VEND-001');
        Assert.AreEqual(1, BC14MigrationErrors.Count(), 'Should have only one error record');

        BC14MigrationErrors.FindFirst();
        Assert.AreEqual('Updated error message', BC14MigrationErrors."Error Message", 'Error message should be updated');
        Assert.AreEqual(1, BC14MigrationErrors."Retry Count", 'Retry count should be incremented');
    end;

    // ============================================================
    // BC14 Migration Record Status Tests
    // ============================================================

    [Test]
    procedure TestRecordStatus_IsMigrated_NotMigrated_ReturnsFalse()
    var
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
    begin
        // [SCENARIO] IsMigrated returns false for records not yet migrated.

        // [GIVEN] The migration record status table is empty
        BC14MigrationRecordStatus.DeleteAll();

        // [WHEN] IsMigrated is called for a non-existent record
        // [THEN] Returns false
        Assert.IsFalse(BC14MigrationRecordStatus.IsMigrated(1000, 'NonExistentKey'), 'IsMigrated should return false for non-migrated record');
    end;

    [Test]
    procedure TestRecordStatus_MarkAsMigrated_NewRecord_RecordCreated()
    var
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
    begin
        // [SCENARIO] MarkAsMigrated creates a new record in the status table.

        // [GIVEN] No migration status exists for the record
        BC14MigrationRecordStatus.DeleteAll();

        // [WHEN] MarkAsMigrated is called
        BC14MigrationRecordStatus.MarkAsMigrated(1000, 'TestKey');

        // [THEN] The record is created and IsMigrated returns true
        Assert.IsTrue(BC14MigrationRecordStatus.IsMigrated(1000, 'TestKey'), 'IsMigrated should return true after MarkAsMigrated');
    end;

    [Test]
    procedure TestRecordStatus_MarkAsMigrated_AlreadyMigrated_Idempotent()
    var
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
        FirstTimestamp: DateTime;
    begin
        // [SCENARIO] Calling MarkAsMigrated twice for the same record is idempotent.

        // [GIVEN] A record is marked as migrated
        BC14MigrationRecordStatus.DeleteAll();
        BC14MigrationRecordStatus.MarkAsMigrated(1000, 'IdempotentKey');

        BC14MigrationRecordStatus.Get(CompanyName(), 1000, 'IdempotentKey');
        FirstTimestamp := BC14MigrationRecordStatus."Migrated On";

        // [WHEN] MarkAsMigrated is called again
        BC14MigrationRecordStatus.MarkAsMigrated(1000, 'IdempotentKey');

        // [THEN] No error occurs and timestamp remains unchanged
        BC14MigrationRecordStatus.Get(CompanyName(), 1000, 'IdempotentKey');
        Assert.AreEqual(FirstTimestamp, BC14MigrationRecordStatus."Migrated On", 'Timestamp should not change on second call');
    end;

    [Test]
    procedure TestRecordStatus_ClearAllMigrationStatus_RecordsExist_AllDeleted()
    var
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
        BC14MigrationRecordStatusCheck: Record "BC14 Migration Record Status";
        DeletedCount: Integer;
    begin
        // [SCENARIO] ClearAllMigrationStatus deletes all status records for the current company.

        // [GIVEN] Multiple migration status records exist
        BC14MigrationRecordStatus.DeleteAll();
        BC14MigrationRecordStatus.MarkAsMigrated(1000, 'Key1');
        BC14MigrationRecordStatus.MarkAsMigrated(1000, 'Key2');
        BC14MigrationRecordStatus.MarkAsMigrated(2000, 'Key3');

        // [WHEN] ClearAllMigrationStatus is called
        DeletedCount := BC14MigrationRecordStatus.ClearAllMigrationStatus();

        // [THEN] All records are deleted (use fresh record to check after Commit)
        Assert.AreEqual(3, DeletedCount, 'Should have deleted 3 records');
        BC14MigrationRecordStatusCheck.SetRange("Company Name", CompanyName());
        Assert.AreEqual(0, BC14MigrationRecordStatusCheck.Count(), 'No records should remain after clear');
    end;

    [Test]
    procedure TestRecordStatus_MigratedOn_HasTimestamp_TimestampRecorded()
    var
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
        BC14MigrationRecordStatusCheck: Record "BC14 Migration Record Status";
        UniqueKey: Text[250];
    begin
        // [SCENARIO] Migrated On timestamp is recorded when marking a record as migrated.

        // [GIVEN] A unique key to avoid collision with committed data from previous tests
        UniqueKey := CopyStr('TimestampKey-' + Format(CreateGuid()), 1, 250);

        // [WHEN] MarkAsMigrated is called
        BC14MigrationRecordStatus.MarkAsMigrated(1000, UniqueKey);

        // [THEN] The timestamp is set (non-zero)
        BC14MigrationRecordStatusCheck.Get(CompanyName(), 1000, UniqueKey);
        Assert.IsTrue(BC14MigrationRecordStatusCheck."Migrated On" > 0DT, 'Timestamp should be set');
    end;

    [Test]
    procedure TestRecordStatus_MultipleTableIds_TrackedSeparately()
    var
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
    begin
        // [SCENARIO] Records from different source tables are tracked separately.

        // [GIVEN] Records with same key but different table IDs
        BC14MigrationRecordStatus.DeleteAll();
        BC14MigrationRecordStatus.MarkAsMigrated(1000, 'SameKey');
        BC14MigrationRecordStatus.MarkAsMigrated(2000, 'SameKey');

        // [THEN] Both records exist independently
        Assert.IsTrue(BC14MigrationRecordStatus.IsMigrated(1000, 'SameKey'), 'Table 1000 record should be migrated');
        Assert.IsTrue(BC14MigrationRecordStatus.IsMigrated(2000, 'SameKey'), 'Table 2000 record should be migrated');
        Assert.IsFalse(BC14MigrationRecordStatus.IsMigrated(3000, 'SameKey'), 'Table 3000 record should NOT be migrated');
    end;

    // ============================================================
    // ErrorOccurred Flag Tests 
    // ============================================================

    [Test]
    procedure TestErrorOccurredFlag_AfterLogError_ReturnsTrue()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14Customer: Record "BC14 Customer";
        SourceRecId: RecordId;
    begin
        // [SCENARIO] ErrorOccurred flag is set to true after logging an error.

        // [GIVEN] Clean state with ErrorOccurred flag cleared
        BC14MigrationErrors.DeleteAll();
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
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14Customer: Record "BC14 Customer";
        SourceRecId: RecordId;
    begin
        // [SCENARIO] ErrorOccurred flag can be cleared after an error was logged.

        // [GIVEN] An error is logged
        BC14MigrationErrors.DeleteAll();
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
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14Customer: Record "BC14 Customer";
        SourceRecId: RecordId;
    begin
        // [SCENARIO] ErrorOccurred flag remains true after multiple errors are logged.

        // [GIVEN] Clean state
        BC14MigrationErrors.DeleteAll();
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
    // Boundary Value Tests
    // ============================================================

    [Test]
    procedure TestLogError_LongErrorMessage_HandlesTruncation()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14Customer: Record "BC14 Customer";
        SourceRecId: RecordId;
        VeryLongMessage: Text;
        i: Integer;
    begin
        // [SCENARIO] Very long error messages are handled gracefully (truncated or stored in BLOB).

        // [GIVEN] A very long error message (2000+ characters)
        BC14MigrationErrors.DeleteAll();

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
        BC14MigrationErrors.SetRange("Source Record Key", 'No.=TEST-LONG-MSG');
        Assert.AreEqual(1, BC14MigrationErrors.Count(), 'Error should be logged even with very long message');

        BC14MigrationErrors.FindFirst();
        // Error message field should contain truncated message (first MaxStrLen characters)
        Assert.IsTrue(StrLen(BC14MigrationErrors."Error Message") > 0, 'Error message should not be empty');
        Assert.IsTrue(StrLen(BC14MigrationErrors."Error Message") <= MaxStrLen(BC14MigrationErrors."Error Message"), 'Error message should be truncated to field max length');

        // Cleanup
        BC14Customer.Delete();
    end;

    [Test]
    procedure TestLogError_MaxLengthSourceRecordKey_Accepted()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14Customer: Record "BC14 Customer";
        SourceRecId: RecordId;
        MaxLengthKey: Text[250];
        i: Integer;
    begin
        // [SCENARIO] Source record key at maximum length is accepted.

        // [GIVEN] A source record key at maximum length (250 characters)
        BC14MigrationErrors.DeleteAll();

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
        BC14MigrationErrors.SetRange("Source Record Key", MaxLengthKey);
        Assert.AreEqual(1, BC14MigrationErrors.Count(), 'Error should be logged with max length key');

        // Cleanup
        BC14Customer.Delete();
    end;

    [Test]
    procedure TestScheduleForRetry_HighRetryCount_HandledCorrectly()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14Customer: Record "BC14 Customer";
        SourceRecId: RecordId;
        i: Integer;
        HighRetryCount: Integer;
    begin
        // [SCENARIO] High number of retries is handled correctly without overflow or errors.

        // [GIVEN] An error is logged
        BC14MigrationErrors.DeleteAll();

        BC14Customer.Init();
        BC14Customer."No." := 'TEST-HIGH-RETRY';
        if not BC14Customer.Insert() then
            BC14Customer.Modify();
        SourceRecId := BC14Customer.RecordId;

        BC14MigrationErrorHandler.LogError('Customer Migrator', Database::"BC14 Customer", 'BC14 Customer', 'No.=TEST-HIGH-RETRY', Database::Customer, 'Persistent error', SourceRecId);
        BC14MigrationErrors.FindFirst();

        // [WHEN] ScheduleForRetry is called many times (simulating persistent failures)
        HighRetryCount := 100;
        for i := 1 to HighRetryCount do
            BC14MigrationErrors.ScheduleForRetry();

        // [THEN] Retry count equals the number of retries
        BC14MigrationErrors.Get(BC14MigrationErrors.Id);
        Assert.AreEqual(HighRetryCount, BC14MigrationErrors."Retry Count", 'Retry count should match number of retries');
        Assert.IsTrue(BC14MigrationErrors."Scheduled For Retry", 'Should still be scheduled for retry');

        // Cleanup
        BC14Customer.Delete();
    end;

    [Test]
    procedure TestLogError_EmptyErrorMessage_Handled()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14Customer: Record "BC14 Customer";
        SourceRecId: RecordId;
    begin
        // [SCENARIO] Empty error message is handled gracefully.

        // [GIVEN] Clean state
        BC14MigrationErrors.DeleteAll();

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
        BC14MigrationErrors.SetRange("Source Record Key", 'No.=TEST-EMPTY-MSG');
        Assert.AreEqual(1, BC14MigrationErrors.Count(), 'Error should be logged even with empty message');

        BC14MigrationErrors.FindFirst();
        Assert.AreEqual('', BC14MigrationErrors."Error Message", 'Error message should be empty');

        // Cleanup
        BC14Customer.Delete();
    end;

    // ============================================================
    // Cross-Company Isolation Tests
    // ============================================================

    [Test]
    procedure TestGetUnresolvedErrorCount_FiltersByCompanyName()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14Customer: Record "BC14 Customer";
        SourceRecId: RecordId;
        CurrentCompanyName: Text[30];
    begin
        // [SCENARIO] GetUnresolvedErrorCount only counts errors for the specified company.

        // [GIVEN] Errors exist for current company
        BC14MigrationErrors.DeleteAll();

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
        Clear(BC14MigrationErrors);

        // [THEN] It returns correct count for current company
        Assert.AreEqual(2, BC14MigrationErrors.GetUnresolvedErrorCount(Database::Customer, CurrentCompanyName), 'Should have 2 errors for current company');

        // [THEN] It returns 0 for a non-existent company
        Assert.AreEqual(0, BC14MigrationErrors.GetUnresolvedErrorCount(Database::Customer, 'Non-Existent Company'), 'Should have 0 errors for non-existent company');

        // Cleanup
        BC14Customer.Delete();
    end;

    [Test]
    procedure TestMigrationErrors_CompanyNameField_SetCorrectly()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14Customer: Record "BC14 Customer";
        SourceRecId: RecordId;
    begin
        // [SCENARIO] Company name field is set correctly when logging errors.

        // [GIVEN] Clean state
        BC14MigrationErrors.DeleteAll();

        BC14Customer.Init();
        BC14Customer."No." := 'TEST-COMP-FIELD';
        if not BC14Customer.Insert() then
            BC14Customer.Modify();
        SourceRecId := BC14Customer.RecordId;

        // [WHEN] An error is logged
        BC14MigrationErrorHandler.LogError('Customer Migrator', Database::"BC14 Customer", 'BC14 Customer', 'No.=TEST-COMP-FIELD', Database::Customer, 'Company field test', SourceRecId);

        // [THEN] Company name is set to current company
        BC14MigrationErrors.SetRange("Source Record Key", 'No.=TEST-COMP-FIELD');
        BC14MigrationErrors.FindFirst();
        Assert.AreEqual(CompanyName(), BC14MigrationErrors."Company Name", 'Company name should be set to current company');

        // Cleanup
        BC14Customer.Delete();
    end;

    [Test]
    procedure TestMigrationRecordStatus_IsolatedByCompany()
    var
        BC14MigrationRecordStatus: Record "BC14 Migration Record Status";
    begin
        // [SCENARIO] Migration record status is isolated by company.

        // [GIVEN] A record is marked as migrated
        BC14MigrationRecordStatus.DeleteAll();
        BC14MigrationRecordStatus.MarkAsMigrated(1000, 'CompanyIsolatedKey');

        // [THEN] IsMigrated returns true for current company
        Assert.IsTrue(BC14MigrationRecordStatus.IsMigrated(1000, 'CompanyIsolatedKey'), 'Should be migrated in current company');

        // [THEN] Direct lookup with different company name should fail
        Assert.IsFalse(BC14MigrationRecordStatus.Get('DifferentCompany', 1000, 'CompanyIsolatedKey'), 'Should not exist for different company');
    end;

    // ============================================================
    // Real RecordId Tests 
    // ============================================================

    [Test]
    procedure TestLogError_WithRealCustomerRecordId_StoredCorrectly()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14Customer: Record "BC14 Customer";
    begin
        // [SCENARIO] Logging error with real BC14 Customer RecordId stores the reference correctly.

        // [GIVEN] A real BC14 Customer record exists
        BC14MigrationErrors.DeleteAll();

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
        BC14MigrationErrors.SetRange("Source Record Key", 'No.=REAL-REC-ID');
        BC14MigrationErrors.FindFirst();
        Assert.AreEqual(Database::"BC14 Customer", BC14MigrationErrors."Source Table ID", 'Source table ID should match');

        // Cleanup
        BC14Customer.Delete();
    end;

    [Test]
    procedure TestLogError_WithRealGLAccountRecordId_StoredCorrectly()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14GLAccount: Record "BC14 G/L Account";
    begin
        // [SCENARIO] Logging error with real BC14 G/L Account RecordId stores the reference correctly.

        // [GIVEN] A real BC14 G/L Account record exists
        BC14MigrationErrors.DeleteAll();

        BC14GLAccount.Init();
        BC14GLAccount."No." := 'GL-REAL-REC';
        BC14GLAccount.Name := 'Test G/L Account for RecordId';
        if not BC14GLAccount.Insert() then
            BC14GLAccount.Modify();

        // [WHEN] An error is logged with the real RecordId
        BC14MigrationErrorHandler.LogError(
            'G/L Account Migrator',
            Database::"BC14 G/L Account",
            'BC14 G/L Account',
            'No.=GL-REAL-REC',
            Database::"G/L Account",
            'Error with real G/L Account reference',
            BC14GLAccount.RecordId
        );

        // [THEN] The error record stores the source record reference
        BC14MigrationErrors.SetRange("Source Record Key", 'No.=GL-REAL-REC');
        BC14MigrationErrors.FindFirst();
        Assert.AreEqual(Database::"BC14 G/L Account", BC14MigrationErrors."Source Table ID", 'Source table ID should match');

        // Cleanup
        BC14GLAccount.Delete();
    end;

    [Test]
    procedure TestLogError_WithRealItemRecordId_StoredCorrectly()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14Item: Record "BC14 Item";
    begin
        // [SCENARIO] Logging error with real BC14 Item RecordId stores the reference correctly.

        // [GIVEN] A real BC14 Item record exists
        BC14MigrationErrors.DeleteAll();

        BC14Item.Init();
        BC14Item."No." := 'ITEM-REAL-REC';
        BC14Item.Description := 'Test Item for RecordId';
        if not BC14Item.Insert() then
            BC14Item.Modify();

        // [WHEN] An error is logged with the real RecordId
        BC14MigrationErrorHandler.LogError(
            'Item Migrator',
            Database::"BC14 Item",
            'BC14 Item',
            'No.=ITEM-REAL-REC',
            Database::Item,
            'Error with real Item reference',
            BC14Item.RecordId
        );

        // [THEN] The error record stores the source record reference
        BC14MigrationErrors.SetRange("Source Record Key", 'No.=ITEM-REAL-REC');
        BC14MigrationErrors.FindFirst();
        Assert.AreEqual(Database::"BC14 Item", BC14MigrationErrors."Source Table ID", 'Source table ID should match');

        // Cleanup
        BC14Item.Delete();
    end;

    [Test]
    procedure TestLogError_WithRealVendorRecordId_StoredCorrectly()
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14Vendor: Record "BC14 Vendor";
    begin
        // [SCENARIO] Logging error with real BC14 Vendor RecordId stores the reference correctly.

        // [GIVEN] A real BC14 Vendor record exists
        BC14MigrationErrors.DeleteAll();

        BC14Vendor.Init();
        BC14Vendor."No." := 'VEND-REAL-REC';
        BC14Vendor.Name := 'Test Vendor for RecordId';
        if not BC14Vendor.Insert() then
            BC14Vendor.Modify();

        // [WHEN] An error is logged with the real RecordId
        BC14MigrationErrorHandler.LogError(
            'Vendor Migrator',
            Database::"BC14 Vendor",
            'BC14 Vendor',
            'No.=VEND-REAL-REC',
            Database::Vendor,
            'Error with real Vendor reference',
            BC14Vendor.RecordId
        );

        // [THEN] The error record stores the source record reference
        BC14MigrationErrors.SetRange("Source Record Key", 'No.=VEND-REAL-REC');
        BC14MigrationErrors.FindFirst();
        Assert.AreEqual(Database::"BC14 Vendor", BC14MigrationErrors."Source Table ID", 'Source table ID should match');

        // Cleanup
        BC14Vendor.Delete();
    end;
}
