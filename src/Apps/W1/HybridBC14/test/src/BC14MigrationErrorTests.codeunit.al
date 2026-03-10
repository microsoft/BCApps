// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Sales.Customer;
using Microsoft.Purchases.Vendor;
using Microsoft.Inventory.Item;

codeunit 148143 "BC14 Migration Error Tests"
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
}
