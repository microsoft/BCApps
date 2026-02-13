// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;

codeunit 139616 "Shpfy Log Entries Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        Assert: Codeunit "Library Assert";
        Any: Codeunit Any;
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        Codeunit.Run(Codeunit::"Shpfy Initialize Test");
        IsInitialized := true;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TestDeleteEntriesOlderThan7Days()
    var
        LogEntry: Record "Shpfy Log Entry";
        ShpfyLogEntries: Codeunit "Shpfy Log Entries";
        OldEntryNo: BigInteger;
        RecentEntryNo: BigInteger;
    begin
        // [SCENARIO] Delete log entries older than 7 days should only delete old entries
        Initialize();

        // [GIVEN] A log entry older than 7 days
        OldEntryNo := CreateLogEntry(CreateDateTime(Today - 10, 0T), '200', 'https://test.myshopify.com/admin/api/2025-07/graphql.json');

        // [GIVEN] A recent log entry
        RecentEntryNo := CreateLogEntry(CreateDateTime(Today - 1, 0T), '200', 'https://test.myshopify.com/admin/api/2025-07/graphql.json');

        // [WHEN] DeleteEntries is called with 7 days
        ShpfyLogEntries.DeleteEntries(LogEntry, 7);

        // [THEN] Old entry should be deleted
        LogEntry.SetRange("Entry No.", OldEntryNo);
        Assert.RecordIsEmpty(LogEntry);

        // [THEN] Recent entry should still exist
        LogEntry.SetRange("Entry No.", RecentEntryNo);
        Assert.RecordIsNotEmpty(LogEntry);

        // Cleanup
        LogEntry.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TestDeleteAllEntries()
    var
        LogEntry: Record "Shpfy Log Entry";
        ShpfyLogEntries: Codeunit "Shpfy Log Entries";
        EntryNo1: BigInteger;
        EntryNo2: BigInteger;
    begin
        // [SCENARIO] Delete all log entries when DaysOld is 0
        Initialize();

        // [GIVEN] Multiple log entries
        EntryNo1 := CreateLogEntry(CreateDateTime(Today - 10, 0T), '200', 'https://test.myshopify.com/admin/api/2025-07/graphql.json');
        EntryNo2 := CreateLogEntry(CreateDateTime(Today - 1, 0T), '200', 'https://test.myshopify.com/admin/api/2025-07/graphql.json');

        // [WHEN] DeleteEntries is called with 0 days
        LogEntry.SetFilter("Entry No.", '%1|%2', EntryNo1, EntryNo2);
        ShpfyLogEntries.DeleteEntries(LogEntry, 0);

        // [THEN] All entries should be deleted
        LogEntry.SetFilter("Entry No.", '%1|%2', EntryNo1, EntryNo2);
        Assert.RecordIsEmpty(LogEntry);

        // Cleanup
        LogEntry.DeleteAll();
    end;

    [Test]
    procedure TestCanEscalateFor500Error()
    var
        LogEntry: Record "Shpfy Log Entry";
        ShpfyLogEntries: Codeunit "Shpfy Log Entries";
    begin
        // [SCENARIO] Log entry with status code 500 and within 14 days should be eligible for escalation
        Initialize();

        // [GIVEN] A log entry with 500 status code created today
        CreateLogEntry(CreateDateTime(Today, Time), '500', 'https://test.myshopify.com/admin/api/2025-07/graphql.json');
        LogEntry.FindLast();

        // [THEN] Entry should be eligible for escalation
        Assert.IsTrue(ShpfyLogEntries.CanEscalate(LogEntry), 'Entry with 500 status within 14 days should be eligible for escalation');

        // Cleanup
        LogEntry.DeleteAll();
    end;

    [Test]
    procedure TestCannotEscalateForNon500Error()
    var
        LogEntry: Record "Shpfy Log Entry";
        ShpfyLogEntries: Codeunit "Shpfy Log Entries";
    begin
        // [SCENARIO] Log entry with non-500 status code should not be eligible for escalation
        Initialize();

        // [GIVEN] A log entry with 200 status code
        CreateLogEntry(CreateDateTime(Today, Time), '200', 'https://test.myshopify.com/admin/api/2025-07/graphql.json');
        LogEntry.FindLast();

        // [THEN] Entry should not be eligible for escalation
        Assert.IsFalse(ShpfyLogEntries.CanEscalate(LogEntry), 'Entry with non-500 status should not be eligible for escalation');

        // Cleanup
        LogEntry.DeleteAll();
    end;

    [Test]
    procedure TestCannotEscalateForOldEntry()
    var
        LogEntry: Record "Shpfy Log Entry";
        ShpfyLogEntries: Codeunit "Shpfy Log Entries";
    begin
        // [SCENARIO] Log entry older than 14 days should not be eligible for escalation
        Initialize();

        // [GIVEN] A log entry with 500 status code older than 14 days
        CreateLogEntry(CreateDateTime(Today - 20, Time), '500', 'https://test.myshopify.com/admin/api/2025-07/graphql.json');
        LogEntry.FindLast();

        // [THEN] Entry should not be eligible for escalation
        Assert.IsFalse(ShpfyLogEntries.CanEscalate(LogEntry), 'Entry older than 14 days should not be eligible for escalation');

        // Cleanup
        LogEntry.DeleteAll();
    end;

    [Test]
    procedure TestGetRequestFromLogEntry()
    var
        LogEntry: Record "Shpfy Log Entry";
        RequestData: Text;
        ExpectedRequest: Text;
    begin
        // [SCENARIO] GetRequest should return the request data stored in the log entry
        Initialize();

        // [GIVEN] A log entry with request data
        ExpectedRequest := '{"query":"query { app { id } }"}';
        CreateLogEntryWithRequestResponse(CreateDateTime(Today, Time), '200', 'https://test.myshopify.com/admin/api/2025-07/graphql.json', ExpectedRequest, '');
        LogEntry.FindLast();

        // [WHEN] GetRequest is called
        RequestData := LogEntry.GetRequest();

        // [THEN] Request data should match
        Assert.AreEqual(ExpectedRequest, RequestData, 'Request data should match');

        // Cleanup
        LogEntry.DeleteAll();
    end;

    [Test]
    procedure TestGetResponseFromLogEntry()
    var
        LogEntry: Record "Shpfy Log Entry";
        ResponseData: Text;
        ExpectedResponse: Text;
    begin
        // [SCENARIO] GetResponse should return the response data stored in the log entry
        Initialize();

        // [GIVEN] A log entry with response data
        ExpectedResponse := '{"data":{"app":{"id":"gid://shopify/App/123"}}}';
        CreateLogEntryWithRequestResponse(CreateDateTime(Today, Time), '200', 'https://test.myshopify.com/admin/api/2025-07/graphql.json', '', ExpectedResponse);
        LogEntry.FindLast();

        // [WHEN] GetResponse is called
        ResponseData := LogEntry.GetResponse();

        // [THEN] Response data should match
        Assert.AreEqual(ExpectedResponse, ResponseData, 'Response data should match');

        // Cleanup
        LogEntry.DeleteAll();
    end;

    local procedure CreateLogEntry(DateTimeValue: DateTime; StatusCode: Code[10]; Url: Text[500]): BigInteger
    var
        LogEntry: Record "Shpfy Log Entry";
    begin
        LogEntry.Init();
        LogEntry."Date and Time" := DateTimeValue;
        LogEntry."Status Code" := StatusCode;
        LogEntry.URL := Url;
        LogEntry."Shpfy Request Id" := CopyStr(Any.AlphanumericText(50), 1, 100);
        LogEntry.Insert(true);
        exit(LogEntry."Entry No.");
    end;

    local procedure CreateLogEntryWithRequestResponse(DateTimeValue: DateTime; StatusCode: Code[10]; Url: Text[500]; RequestData: Text; ResponseData: Text): BigInteger
    var
        LogEntry: Record "Shpfy Log Entry";
    begin
        LogEntry.Init();
        LogEntry."Date and Time" := DateTimeValue;
        LogEntry."Status Code" := StatusCode;
        LogEntry.URL := Url;
        LogEntry."Shpfy Request Id" := CopyStr(Any.AlphanumericText(50), 1, 100);
        LogEntry.Insert(true);
        if RequestData <> '' then
            LogEntry.SetRequest(RequestData);
        if ResponseData <> '' then
            LogEntry.SetResponse(ResponseData);
        exit(LogEntry."Entry No.");
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
