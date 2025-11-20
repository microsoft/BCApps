// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

codeunit 484 "Change Global Dim. Log Mgt."
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TempChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry" temporary;

    procedure AreAllCompleted(): Boolean
    begin
        TempChangeGlobalDimLogEntry.Reset();
        TempChangeGlobalDimLogEntry.SetFilter(Status, '<>%1', TempChangeGlobalDimLogEntry.Status::Completed);
        exit(TempChangeGlobalDimLogEntry.IsEmpty);
    end;

    procedure ClearBuffer()
    begin
        TempChangeGlobalDimLogEntry.Reset();
        TempChangeGlobalDimLogEntry.DeleteAll();
    end;

    procedure IsBufferClear(): Boolean
    begin
        TempChangeGlobalDimLogEntry.Reset();
        exit(TempChangeGlobalDimLogEntry.IsEmpty);
    end;

    procedure IsStarted(): Boolean
    begin
        TempChangeGlobalDimLogEntry.Reset();
        TempChangeGlobalDimLogEntry.SetFilter(Status, '<>%1', TempChangeGlobalDimLogEntry.Status::" ");
        exit(not TempChangeGlobalDimLogEntry.IsEmpty);
    end;

    procedure ExcludeTable(TableId: Integer)
    begin
        if TempChangeGlobalDimLogEntry.Get(TableId) then
            TempChangeGlobalDimLogEntry.Delete();
        if AreAllCompleted() then
            ClearBuffer();
    end;

    procedure FindChildTables(ParentTableID: Integer; var TempChildChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry" temporary): Boolean;
    begin
        TempChildChangeGlobalDimLogEntry.Copy(TempChangeGlobalDimLogEntry, true);
        TempChildChangeGlobalDimLogEntry.SetRange("Parent Table ID", ParentTableID);
        exit(TempChildChangeGlobalDimLogEntry.FindSet());
    end;

    procedure FillBuffer(): Boolean
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        ClearBuffer();
        if ChangeGlobalDimLogEntry.IsEmpty() then
            exit(false);
        ChangeGlobalDimLogEntry.FindSet();
        repeat
            TempChangeGlobalDimLogEntry := ChangeGlobalDimLogEntry;
            TempChangeGlobalDimLogEntry.Insert();
        until ChangeGlobalDimLogEntry.Next() = 0;
        TempChangeGlobalDimLogEntry.SetRange("Total Records", 0);
        TempChangeGlobalDimLogEntry.DeleteAll();
        exit(not IsBufferClear());
    end;
}

