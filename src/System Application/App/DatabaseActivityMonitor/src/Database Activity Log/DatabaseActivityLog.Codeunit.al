// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.Environment;

codeunit 6280 "Database Activity Log"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    SingleInstance = true;

    // TODO: Permissions

    var
        // IsMonitoring: Boolean; // TODO: Only read once!
        DatabaseActivityMonitor: Codeunit "Database Activity Monitor";
        OnDatabaseDeleteTok: Label 'Delete', Locked = true; // TODO: Enum instead
        OnDatabaseInsertTok: Label 'Insert', Locked = true;
        OnDatabaseModifyTok: Label 'Modify', Locked = true;
        OnDatabaseRenameTok: Label 'Rename', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure GetTriggers(TableId: Integer; var OnDatabaseDelete: Boolean; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseRename: Boolean)
    begin
        // TOOO: Make this an option
        //if CompanyName() = '' then
        //    exit;

        // TODO: I think we need to mprove this check this for performance reasons? But how do we then get logs for other sessions
        if not DatabaseActivityMonitor.IsMonitorActive() then
            exit;

        if IsTableExcluded(TableId) then
            exit;

        OnDatabaseDelete := true;
        OnDatabaseInsert := true;
        OnDatabaseModify := true;
        OnDatabaseRename := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseDelete', '', false, false)]
    local procedure GetCallStackOnDelete(RecRef: RecordRef)
    var
        CallerModuleInfo: ModuleInfo;
    begin
        if not IsValidRecord(RecRef) then
            exit;

        NavApp.GetCallerModuleInfo(CallerModuleInfo);

        LogTrace(OnDatabaseDeleteTok, RecRef, CallerModuleInfo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure GetCallStackOnInsert(RecRef: RecordRef)
    var
        CallerModuleInfo: ModuleInfo;
    begin
        if not IsValidRecord(RecRef) then
            exit;

        NavApp.GetCallerModuleInfo(CallerModuleInfo);

        LogTrace(OnDatabaseInsertTok, RecRef, CallerModuleInfo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseModify', '', false, false)]
    local procedure GetCallStackOnModify(RecRef: RecordRef)
    var
        CallerModuleInfo: ModuleInfo;
    begin
        if not IsValidRecord(RecRef) then
            exit;

        NavApp.GetCallerModuleInfo(CallerModuleInfo);

        LogTrace(OnDatabaseModifyTok, RecRef, CallerModuleInfo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseRename', '', false, false)]
    local procedure GetCallStackOnRename(RecRef: RecordRef)
    var
        CallerModuleInfo: ModuleInfo;
    begin
        if not IsValidRecord(RecRef) then
            exit;

        NavApp.GetCallerModuleInfo(CallerModuleInfo);

        LogTrace(OnDatabaseRenameTok, RecRef, CallerModuleInfo);
    end;

    local procedure IsValidRecord(var RecRef: RecordRef): Boolean
    begin
        if RecRef.IsTemporary() then
            exit(false);

        if not DatabaseActivityMonitor.IsMonitorActive() then // TODO: Is this needed?
            exit(false);

        if IsTableExcluded(RecRef.Number) then
            exit(false);

        exit(true);
    end;

    local procedure IsTableExcluded(TableId: Integer): Boolean // TODO: Fix this
    begin
        if TableId = Database::"Database Activity Log" then
            exit(true);

        if TableId = Database::"Database Act. Monitor Setup" then
            exit(true);

        if TableId = Database::"Database Act. Monitor Line" then
            exit(true);

        if not DatabaseActivityMonitor.IsMonitoringTable(TableId) then
            exit(true);

        exit(false);
    end;


    local procedure LogTrace(TriggerName: Text; var RecRef: RecordRef; CallerModuleInfo: ModuleInfo)
    var
        TelemetryDimensions: Dictionary of [Text, Text];
        Callstack: Text;
    begin
        Callstack := GetCallStack(RecRef, TriggerName);
        LogTraceToDatabase(TriggerName, CallerModuleInfo.Publisher, CallerModuleInfo.Name, RecRef, Callstack);
        TelemetryDimensions.Add('Category', 'PTETransactionDetect');
        TelemetryDimensions.Add('TriggerName', TriggerName);
        TelemetryDimensions.Add('TableID', FORMAT(RecRef.Number));
        TelemetryDimensions.Add('CallStack', Callstack);
        Session.LogMessage('TRD001', RecordChangedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

    local procedure GetCallStack(var RecRef: RecordRef; TriggerName: Text): Text
    var
        CallStack: Text;
        Index: Integer;
    begin
        if GetActivityCallStack(RecRef) then;
        CallStack := GetLastErrorCallStack();
        ClearLastError();

        // Trim callstack 
        // TODO: Better matching
        case TriggerName of
            OnDatabaseDeleteTok:
                Index := CallStack.IndexOf('OnDatabaseDelete(Event) line 2');
            OnDatabaseInsertTok:
                Index := CallStack.IndexOf('OnDatabaseInsert(Event) line 2');
            OnDatabaseModifyTok:
                Index := CallStack.IndexOf('OnDatabaseModify(Event) line 2');
            OnDatabaseRenameTok:
                Index := CallStack.IndexOf('OnDatabaseRename(Event) line 2');
        end;

        if Index > 0 then
            CallStack := CopyStr(CallStack, Index + 31, StrLen(CallStack)); // 31 is lenght of above strings

        exit(CallStack);


    end;

    [TryFunction]
    local procedure GetActivityCallStack(var RecRef: RecordRef)
    begin
#pragma warning disable AA0231
        Error('GetActivityCallStack. Table ID: ' + Format(RecRef.Number));
#pragma warning restore AA0231
    end;

    local procedure LogTraceToDatabase(TriggerName: Text; Publisher: Text; AppName: Text; var RecRef: RecordRef; Callstack: Text)
    var
        DatabaseActivityLog: Record "Database Activity Log";
    begin
        DatabaseActivityLog."Table ID" := RecRef.Number;
#pragma warning disable AA0139
        DatabaseActivityLog."Trigger Name" := TriggerName;
#pragma warning restore AA0139
#pragma warning disable AA0139
        DatabaseActivityLog."Table Name" := RecRef.Name;
#pragma warning restore AA0139
        DatabaseActivityLog."App Name" := CopyStr(AppName, 1, 250);
        DatabaseActivityLog."Publisher Name" := CopyStr(Publisher, 1, 250);
        DatabaseActivityLog."Call Stack" := CopyStr(Callstack, 1, 2048);
        DatabaseActivityLog.Insert(true);
    end;

    var
        RecordChangedMsg: Label 'Record changed';
}