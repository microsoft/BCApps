// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using System.Reflection;

codeunit 9300 "Sync. Looping Helper"
{
    EventSubscriberInstance = Manual;

    var
        TempSkippedField: Record Field temporary;
        TableSynchronizationCategoryTok: Label 'Table Synchronization', Locked = true;
        FieldSyncAlreadyBoundTxt: Label 'Field Synchronization was already bound for table %1, Field %2.', Locked = true;

    procedure SkipFieldSynchronization(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; TableNo: Integer; FieldNo: Integer)
    begin
        if not BindSubscription(SyncLoopingHelper) then
            Session.LogMessage('0000MB8', StrSubstNo(FieldSyncAlreadyBoundTxt, TableNo, FieldNo), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TableSynchronizationCategoryTok);

        if TempSkippedField.Get(TableNo, FieldNo) then
            exit;

        TempSkippedField.Init();
        TempSkippedField.TableNo := TableNo;
        TempSkippedField."No." := FieldNo;
        TempSkippedField.Insert();
    end;

    procedure SkipFieldSynchronization(var SyncLoopingHelper: Codeunit "Sync. Looping Helper"; TableNo: Integer)
    begin
        SkipFieldSynchronization(SyncLoopingHelper, TableNo, 0);
    end;

    procedure RestoreFieldSynchronization(TableNo: Integer; FieldNo: Integer)
    begin
        if not TempSkippedField.Get(TableNo, FieldNo) then
            exit;

        TempSkippedField.Delete();
    end;

    procedure RestoreFieldSynchronization(TableNo: Integer)
    begin
        RestoreFieldSynchronization(TableNo, 0);
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnIsFieldSynchronizationSkipped(TableNo: Integer; FieldNo: Integer; var Skipped: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sync. Looping Helper", 'OnIsFieldSynchronizationSkipped', '', false, false)]
    local procedure CheckTableFieldOnIsFieldSynchronizationSkipped(TableNo: Integer; FieldNo: Integer; var Skipped: Boolean)
    begin
        Skipped := TempSkippedField.Get(TableNo, FieldNo);
    end;

    procedure IsFieldSynchronizationSkipped(TableNo: Integer; FieldNo: Integer): Boolean
    var
        Skipped: Boolean;
    begin
        OnIsFieldSynchronizationSkipped(TableNo, FieldNo, Skipped);
        exit(Skipped);
    end;

    procedure IsFieldSynchronizationSkipped(TableNo: Integer): Boolean
    begin
        exit(IsFieldSynchronizationSkipped(TableNo, 0));
    end;
}
