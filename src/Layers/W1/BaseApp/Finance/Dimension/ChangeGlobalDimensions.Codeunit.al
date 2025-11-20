// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Assembly.History;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.HumanResources.Payables;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Counting.History;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.History;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Warehouse.Ledger;
using System.Automation;
using System.Environment;
using System.Reflection;
using System.Utilities;

codeunit 483 "Change Global Dimensions"
{
    Permissions = TableData "G/L Entry" = rm,
                  TableData "VAT Entry" = rm,
                  TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "Item Ledger Entry" = rm,
                  Tabledata "Approval Entry" = rm,
                  TableData "Sales Shipment Header" = rm,
                  TableData "Sales Shipment Line" = rm,
                  TableData "Sales Invoice Header" = rm,
                  TableData "Sales Invoice Line" = rm,
                  TableData "Sales Cr.Memo Header" = rm,
                  TableData "Sales Cr.Memo Line" = rm,
                  TableData "Purch. Rcpt. Header" = rm,
                  TableData "Purch. Rcpt. Line" = rm,
                  TableData "Purch. Inv. Header" = rm,
                  TableData "Purch. Inv. Line" = rm,
                  TableData "Purch. Cr. Memo Hdr." = rm,
                  TableData "Purch. Cr. Memo Line" = rm,
                  TableData "Job Ledger Entry" = rm,
                  TableData "Res. Ledger Entry" = rm,
                  TableData "Bank Account Ledger Entry" = rm,
                  TableData "Phys. Inventory Ledger Entry" = rm,
                  TableData "Issued Reminder Header" = rm,
                  TableData "Issued Reminder Line" = rm,
                  TableData "Reminder/Fin. Charge Entry" = rm,
                  TableData "Issued Fin. Charge Memo Header" = rm,
                  TableData "Issued Fin. Charge Memo Line" = rm,
                  TableData "Detailed Cust. Ledg. Entry" = rm,
                  TableData "Detailed Vendor Ledg. Entry" = rm,
                  TableData "Posted Assembly Header" = rm,
                  TableData "Posted Assembly Line" = rm,
                  TableData "Job WIP G/L Entry" = rm,
                  TableData "Employee Ledger Entry" = rm,
                  TableData "Detailed Employee Ledger Entry" = rm,
#if not CLEAN28
                  TableData Microsoft.Manufacturing.Document."Production Order" = rm,
                  TableData Microsoft.Manufacturing.Document."Prod. Order Line" = rm,
                  TableData Microsoft.Manufacturing.Document."Prod. Order Component" = rm,
                  TableData Microsoft.Manufacturing.Document."Prod. Order Routing Line" = rm,
                  TableData Microsoft.Manufacturing.Document."Prod. Order Capacity Need" = rm,
                  TableData Microsoft.Manufacturing.Document."Prod. Order Routing Tool" = rm,
                  TableData Microsoft.Manufacturing.Document."Prod. Order Routing Personnel" = rm,
                  TableData Microsoft.Manufacturing.Document."Prod. Order Rtng Qlty Meas." = rm,
                  TableData Microsoft.Manufacturing.Document."Prod. Order Comment Line" = rm,
                  TableData Microsoft.Manufacturing.Document."Prod. Order Rtng Comment Line" = rm,
                  TableData Microsoft.Manufacturing.Document."Prod. Order Comp. Cmt Line" = rm,
#endif
                  TableData "Invt. Receipt Header" = rm,
                  TableData "Invt. Receipt Line" = rm,
                  TableData "Invt. Shipment Header" = rm,
                  TableData "Invt. Shipment Line" = rm,
                  TableData "FA Ledger Entry" = rm,
                  TableData "Maintenance Ledger Entry" = rm,
                  TableData "Ins. Coverage Ledger Entry" = rm,
                  TableData "Value Entry" = rm,
                  TableData Microsoft.Manufacturing.Capacity."Capacity Ledger Entry" = rm,
#if not CLEAN28
                  TableData Microsoft.Service.Document."Service Header" = rm,
                  TableData Microsoft.Service.Document."Service Item Line" = rm,
                  TableData Microsoft.Service.Document."Service Line" = rm,
                  TableData Microsoft.Service.Ledger."Service Ledger Entry" = rm,
                  TableData Microsoft.Service.Contract."Service Contract Header" = rm,
                  TableData Microsoft.Service.Contract."Service Contract Line" = rm,
                  TableData Microsoft.Service.History."Service Invoice Line" = rm,
                  tabledata Microsoft.Service.History."Service Cr.Memo Header" = rm,
                  tabledata Microsoft.Service.History."Service Cr.Memo Line" = rm,
                  tabledata Microsoft.Service.History."Service Invoice Header" = rm,
                  tabledata Microsoft.Service.History."Service Shipment Header" = rm,
                  tabledata Microsoft.Service.History."Service Shipment Line" = rm,
                  TableData Microsoft.Service.Contract."Filed Service Contract Header" = rm,
#endif
                  TableData "Phys. Invt. Order Header" = rm,
                  TableData "Phys. Invt. Order Line" = rm,
                  TableData "Pstd. Phys. Invt. Order Hdr" = rm,
                  TableData "Pstd. Phys. Invt. Order Line" = rm,
                  TableData "Return Shipment Header" = rm,
                  TableData "Return Shipment Line" = rm,
                  TableData "Return Receipt Header" = rm,
                  TableData "Return Receipt Line" = rm,
                  TableData "Warehouse Entry" = rm;
    TableNo = "Change Global Dim. Log Entry";

    trigger OnRun()
    begin
        if ChangeGlobalDimLogMgt.IsBufferClear() then
            ChangeGlobalDimLogMgt.FillBuffer();
        BindSubscription(ChangeGlobalDimLogMgt);
        if RunTask(Rec) then begin
            DeleteEntry(Rec);
            if ChangeGlobalDimLogMgt.IsBufferClear() then
                ResetState();
        end;
    end;

    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChangeGlobalDimLogMgt: Codeunit "Change Global Dim. Log Mgt.";
        DepRecNo: Dictionary of [Integer, List of [Integer]]; // [TableId, [RecRefIndex, StartFromRecNo, CurrRecNo]]
        Window: Dialog;
        CloseActiveSessionsMsg: Label 'Close all other active sessions.';
        CloseSessionNotificationTok: Label 'A2C57B69-B056-4B3B-8D0F-C0D997145EE7', Locked = true;
        CurrRecord: Integer;
        NoOfRecords: Integer;
        ProgressMsg: Label 'Updating #1#####\@2@@@@@@@@@@', Comment = '#1-Table Id and Name;#2 - progress bar.';
        IsWindowOpen: Boolean;
        TagCategoryTxt: Label 'Change Global Dimensions', Locked = true;
        StartTraceTagMsg: Label 'Change Global Dimensions is started, parallel processing is on.';
        SequentialStartTraceTagMsg: Label 'Change Global Dimensions is started, parallel processing is off.';
        FinishTraceTagMsg: Label 'Change Global Dimensions is finished.';
        SessionListActionTxt: Label 'Session List';
        SessionUpdateRequiredMsg: Label 'All records were successfully updated. To apply the updates, close the General Ledger Setup page.';

    procedure ResetIfAllCompleted()
    begin
        ChangeGlobalDimLogMgt.FillBuffer();
        if ChangeGlobalDimLogMgt.AreAllCompleted() then
            ResetState();
    end;

    local procedure GetDelayInScheduling(): Integer
    begin
        // duration in milliseconds between scheduled jobs
        exit(100);
    end;

    procedure Prepare()
    begin
        ChangeGlobalDimHeader.Get();
        if IsPrepareEnabled(ChangeGlobalDimHeader) and ChangeGlobalDimHeader."Parallel Processing" then
            if IsCurrentSessionActiveOnly() then
                PrepareTableList()
            else
                SendCloseSessionsNotification();
    end;

    local procedure PrepareTableList() IsListFilled: Boolean
    begin
        IsListFilled := InitTableList();
        if not IsListFilled then begin
            UpdateGLSetup();
            RefreshHeader();
        end;
    end;

    local procedure ProcessTableList()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        ChangeGlobalDimLogEntry.Reset();
        ChangeGlobalDimLogEntry.SetFilter("Table ID", '>0');
        ChangeGlobalDimLogEntry.SetRange("Parent Table ID", 0);
        if IsWindowOpen then begin
            CurrRecord := 0;
            ChangeGlobalDimLogEntry.CalcSums("Total Records");
            NoOfRecords := ChangeGlobalDimLogEntry."Total Records";
        end;
        if ChangeGlobalDimLogEntry.FindSet(true) then
            repeat
                if IsWindowOpen then
                    Window.Update(1, StrSubstNo('%1 %2', ChangeGlobalDimLogEntry."Table ID", ChangeGlobalDimLogEntry."Table Name"));
                if RunTask(ChangeGlobalDimLogEntry) then
                    DeleteEntry(ChangeGlobalDimLogEntry);
            until ChangeGlobalDimLogEntry.Next() = 0;
        ResetIfAllCompleted();
    end;

    procedure RemoveHeader()
    var
        ChangeGlobalDimHeader: Record "Change Global Dim. Header";
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        if ChangeGlobalDimLogEntry.IsEmpty() then
            ChangeGlobalDimHeader.DeleteAll();
    end;

    procedure ResetState()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        ChangeGlobalDimLogEntry.DeleteAll(true);
        ClearAll();
        ChangeGlobalDimLogMgt.ClearBuffer();
        RefreshHeader();
    end;

    procedure Rerun(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry")
    begin
        ChangeGlobalDimLogEntry.LockTable();
        ChangeGlobalDimLogEntry.UpdateStatus();
        if ChangeGlobalDimLogMgt.FillBuffer() then
            RerunEntry(ChangeGlobalDimLogEntry);
    end;

    local procedure RunTask(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry") Completed: Boolean
    begin
        ChangeGlobalDimLogEntry.SetSessionInProgress();
        if ChangeGlobalDimHeader."Parallel Processing" then
            Commit();
        Completed := ChangeDimsOnTable(ChangeGlobalDimLogEntry);
    end;

    procedure Start()
    begin
        ChangeGlobalDimHeader.Get();
        if IsStartEnabled() then begin
            SendTraceTagOn(StartTraceTagMsg);
            CompleteEmptyTables();
            UpdateGLSetup();
            ScheduleJobs(GetDelayInScheduling());
            RefreshHeader();
        end;
    end;

    procedure StartSequential()
    begin
        ChangeGlobalDimHeader.Get();
        if IsPrepareEnabled(ChangeGlobalDimHeader) and not ChangeGlobalDimHeader."Parallel Processing" then begin
            WindowOpen();
            if PrepareTableList() then begin
                SendTraceTagOn(SequentialStartTraceTagMsg);
                CompleteEmptyTables();
                UpdateGLSetup();
                ProcessTableList();
                RefreshHeader();
                SendTraceTagOn(FinishTraceTagMsg);
            end;
            WindowClose();
        end;
    end;

    local procedure CompleteEmptyTables()
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        RecRef: RecordRef;
    begin
        ChangeGlobalDimLogEntry.SetFilter("Table ID", '>0');
        ChangeGlobalDimLogEntry.SetRange("Total Records", 0);
        if ChangeGlobalDimLogEntry.FindSet(true) then
            repeat
                RecRef.Open(ChangeGlobalDimLogEntry."Table ID");
                RecRef.LockTable(true);
                ChangeGlobalDimLogEntry."Total Records" := RecRef.Count();
                if ChangeGlobalDimLogEntry."Total Records" = 0 then
                    DeleteEntry(ChangeGlobalDimLogEntry)
                else
                    ChangeGlobalDimLogEntry.Modify();
                RecRef.Close();
            until ChangeGlobalDimLogEntry.Next() = 0;
    end;

    procedure FillBuffer()
    begin
        ChangeGlobalDimLogMgt.FillBuffer();
    end;

    local procedure FindChildTables(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; var TempChildChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry" temporary): Boolean
    begin
        if ChangeGlobalDimLogEntry."Is Parent Table" then
            exit(ChangeGlobalDimLogMgt.FindChildTables(ChangeGlobalDimLogEntry."Table ID", TempChildChangeGlobalDimLogEntry));
    end;

    local procedure FindDependentTables(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; ParentChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; var DependentRecRef: array[7] of RecordRef): Boolean
    var
        TempChildChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry" temporary;
        RecRefIndex: Integer;
        TotalRecords: Integer;
    begin
        RecRefIndex := 0;
        if FindChildTables(ParentChangeGlobalDimLogEntry, TempChildChangeGlobalDimLogEntry) then
            repeat
                if ChangeGlobalDimLogEntry.Get(TempChildChangeGlobalDimLogEntry."Table ID") then begin
                    RecRefIndex += 1;
                    InitDependentRecNo(ChangeGlobalDimLogEntry."Table ID", RecRefIndex, ChangeGlobalDimLogEntry."Completed Records");
                    DependentRecRef[RecRefIndex].Open(ChangeGlobalDimLogEntry."Table ID");
                    DependentRecRef[RecRefIndex].LockTable(true);
                    ChangeGlobalDimLogEntry."Total Records" := DependentRecRef[RecRefIndex].Count();
                    ChangeGlobalDimLogEntry."Session ID" := SessionId();
                    ChangeGlobalDimLogEntry."Server Instance ID" := ServiceInstanceId();
                    ChangeGlobalDimLogEntry.Modify();
                    TotalRecords += ChangeGlobalDimLogEntry."Total Records";
                end;
            until TempChildChangeGlobalDimLogEntry.Next() = 0;
        if TotalRecords > 0 then begin
            ChangeGlobalDimLogEntry.Reset();
            ChangeGlobalDimLogEntry.SetRange("Parent Table ID", ChangeGlobalDimLogEntry."Parent Table ID");
            exit(ChangeGlobalDimLogEntry.Findset());
        end;
    end;

    procedure FindTablesForScheduling(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"): Boolean
    begin
        ChangeGlobalDimLogEntry.SetRange("Parent Table ID", 0);
        ChangeGlobalDimLogEntry.SetFilter("Total Records", '>0');
        exit(ChangeGlobalDimLogEntry.FindSet(true))
    end;

    local procedure GetMinCommitSize(): Integer
    begin
        // number of records that should be modified between COMMIT calls
        exit(10);
    end;

    local procedure CalcRecordsWithinCommit(TotalRecords: Integer) RecordsWithinCommit: Integer
    begin
        RecordsWithinCommit := Round(TotalRecords / 100, 1, '>');
        if RecordsWithinCommit < GetMinCommitSize() then
            RecordsWithinCommit := GetMinCommitSize();
    end;

    local procedure ChangeDimsOnTable(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry") Completed: Boolean
    var
        DependentChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        RecRef: RecordRef;
        DependentRecRef: array[7] of RecordRef;
        CurrentRecNo: Integer;
        DependentRecNo: Integer;
        RecordsWithinCommit: Integer;
        StartedFromRecord: Integer;
        HasDependentTable: Boolean;
        DependentEntryCompleted: Boolean;
    begin
        RecRef.Open(ChangeGlobalDimLogEntry."Table ID");
        RecRef.LockTable(true);
        if not RecRef.IsEmpty() then begin
            Clear(DepRecNo);
            CurrentRecNo := ChangeGlobalDimLogEntry."Completed Records";
            StartedFromRecord := CurrentRecNo;
            ChangeGlobalDimLogEntry."Total Records" := RecRef.Count();
            OnChangeDimsOnTableOnBeforeCalcRecordsWithinCommit(ChangeGlobalDimLogEntry, ChangeGlobalDimLogMgt, ChangeGlobalDimHeader, Completed, StartedFromRecord, RecRef);
            RecordsWithinCommit := CalcRecordsWithinCommit(ChangeGlobalDimLogEntry."Total Records");
            if RecRef.FindSet(true) then begin
                HasDependentTable := FindDependentTables(DependentChangeGlobalDimLogEntry, ChangeGlobalDimLogEntry, DependentRecRef);
                if HasDependentTable then
                    repeat
                        DependentChangeGlobalDimLogEntry."Earliest Start Date/Time" := CurrentDateTime;
                        DependentChangeGlobalDimLogEntry.SetSessionInProgress();
                    until DependentChangeGlobalDimLogEntry.Next() = 0;
                if ChangeGlobalDimLogEntry."Completed Records" > 0 then
                    RecRef.Next(ChangeGlobalDimLogEntry."Completed Records");
                ChangeGlobalDimLogEntry."Earliest Start Date/Time" := CurrentDateTime;
                repeat
                    ChangeDimsOnRecord(ChangeGlobalDimLogEntry, RecRef);
                    CurrentRecNo += 1;

                    if HasDependentTable then
                        if DependentChangeGlobalDimLogEntry.FindSet() then
                            repeat
                                if DependentChangeGlobalDimLogEntry."Total Records" > 0 then
                                    ChangeDependentRecords(
                                        ChangeGlobalDimLogEntry, DependentChangeGlobalDimLogEntry,
                                        RecRef, DependentRecRef[GetDependentRecNo(DependentChangeGlobalDimLogEntry."Table ID", 1)]);
                            until DependentChangeGlobalDimLogEntry.Next() = 0;

                    if CurrentRecNo >= (ChangeGlobalDimLogEntry."Completed Records" + RecordsWithinCommit) then begin
                        if HasDependentTable then
                            if DependentChangeGlobalDimLogEntry.FindSet() then
                                repeat
                                    DependentRecNo := GetDependentRecNo(DependentChangeGlobalDimLogEntry."Table ID", 3);
                                    DependentChangeGlobalDimLogEntry.Update(DependentRecNo, GetDependentRecNo(DependentChangeGlobalDimLogEntry."Table ID", 2));
                                    Completed := UpdateWithCommit(ChangeGlobalDimLogEntry, CurrentRecNo, StartedFromRecord);
                                    if DependentRecNo > 0 then
                                        DependentRecRef[GetDependentRecNo(DependentChangeGlobalDimLogEntry."Table ID", 1)].LockTable();
                                until DependentChangeGlobalDimLogEntry.Next() = 0;
                        RecRef.LockTable();
                    end;
                    if IsWindowOpen then begin
                        CurrRecord += 1;
                        if CurrRecord mod Round(NoOfRecords / 100, 1, '>') = 1 then
                            Window.Update(2, Round(CurrRecord / NoOfRecords * 10000, 1));
                    end;
                until RecRef.Next() = 0;
            end;
            if HasDependentTable then
                if DependentChangeGlobalDimLogEntry.FindSet() then
                    repeat
                        DependentRecNo := GetDependentRecNo(DependentChangeGlobalDimLogEntry."Table ID", 3);
                        if DependentRecNo > 0 then begin
                            DependentRecRef[GetDependentRecNo(DependentChangeGlobalDimLogEntry."Table ID", 1)].Close();
                            DependentChangeGlobalDimLogEntry.Update(DependentRecNo, GetDependentRecNo(DependentChangeGlobalDimLogEntry."Table ID", 2));
                            if DependentChangeGlobalDimLogEntry.Status = DependentChangeGlobalDimLogEntry.Status::Completed then
                                DependentEntryCompleted := DeleteEntry(DependentChangeGlobalDimLogEntry);
                            if not DependentEntryCompleted then begin
                                DependentChangeGlobalDimLogEntry.Update(0, 0);
                                CurrentRecNo := 0; // set the parent to Incomplete
                            end;
                        end;
                    until DependentChangeGlobalDimLogEntry.Next() = 0;
            Completed := UpdateWithCommit(ChangeGlobalDimLogEntry, CurrentRecNo, StartedFromRecord);
        end;
        RecRef.Close();
    end;

    local procedure GetDependentRecNo(TableId: Integer; Index: Integer) RecNo: Integer;
    var
        RecNoList: List of [Integer];
    begin
        RecNoList := DepRecNo.Get(TableID);
        RecNo := RecNoList.Get(Index);
    end;

    local procedure InitDependentRecNo(TableId: Integer; RecRefIndex: Integer; RecNo: Integer)
    var
        RecNoList: List of [Integer];
    begin
        RecNoList.Add(RecRefIndex);
        RecNoList.Add(RecNo);
        RecNoList.Add(RecNo);
        DepRecNo.Add(TableId, RecNoList);
    end;

    local procedure SetDependentRecNo(TableId: Integer; Index: Integer; RecNo: Integer)
    var
        RecNoList: List of [Integer];
    begin
        RecNoList := DepRecNo.Get(TableID);
        RecNoList.Set(Index, RecNo);
        DepRecNo.Set(TableID, RecNoList);
    end;

    local procedure ChangeDimsOnRecord(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; var RecRef: RecordRef) Success: Boolean
    var
        GlobalDimFieldRef: array[2] of FieldRef;
        OldDimValueCode: array[2] of Code[20];
        IsHandled: Boolean;
    begin
        if (ChangeGlobalDimLogEntry."Change Type 1" = ChangeGlobalDimLogEntry."Change Type 1"::None) and (ChangeGlobalDimLogEntry."Change Type 2" = ChangeGlobalDimLogEntry."Change Type 2"::None) then
            exit(false);

        OnChangeDimsOnRecord(ChangeGlobalDimLogEntry, RecRef, IsHandled, Success);
        if IsHandled then
            exit(Success);

        if (ChangeGlobalDimLogEntry."Change Type 1" = ChangeGlobalDimLogEntry."Change Type 1"::Replace) and (ChangeGlobalDimLogEntry."Global Dim.2 Field No." = 0) then
            ChangeGlobalDimLogEntry."Change Type 1" := ChangeGlobalDimLogEntry."Change Type 1"::New;
        if (ChangeGlobalDimLogEntry."Change Type 2" = ChangeGlobalDimLogEntry."Change Type 2"::Replace) and (ChangeGlobalDimLogEntry."Global Dim.1 Field No." = 0) then
            ChangeGlobalDimLogEntry."Change Type 2" := ChangeGlobalDimLogEntry."Change Type 2"::New;

        if ChangeGlobalDimLogEntry."Global Dim.1 Field No." = 0 then
            ChangeGlobalDimLogEntry."Change Type 1" := ChangeGlobalDimLogEntry."Change Type 1"::None;
        if ChangeGlobalDimLogEntry."Global Dim.2 Field No." = 0 then
            ChangeGlobalDimLogEntry."Change Type 2" := ChangeGlobalDimLogEntry."Change Type 2"::None;

        ChangeGlobalDimLogEntry.GetFieldRefValues(RecRef, GlobalDimFieldRef, OldDimValueCode);
        ChangeGlobalDimLogEntry.ChangeDimOnRecord(RecRef, 1, GlobalDimFieldRef[1], OldDimValueCode[2]);
        ChangeGlobalDimLogEntry.ChangeDimOnRecord(RecRef, 2, GlobalDimFieldRef[2], OldDimValueCode[1]);
        Success := RecRef.Modify();
    end;

    local procedure ChangeDependentRecords(ParentChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; ParentRecRef: RecordRef; var RecRef: RecordRef)
    var
        GlobalDimFieldRef: array[2] of FieldRef;
        ParentKeyFieldRef: FieldRef;
        ParentDimValueCode: array[2] of Code[20];
        DimValueCode: array[2] of Code[20];
        ParentKeyValue: Variant;
        CurrentRecNo: Integer;
        IsHandled: Boolean;
    begin
        CurrentRecNo := GetDependentRecNo(ChangeGlobalDimLogEntry."Table ID", 3);

        ParentChangeGlobalDimLogEntry.GetFieldRefValues(ParentRecRef, GlobalDimFieldRef, ParentDimValueCode);
        ChangeGlobalDimLogEntry.GetPrimaryKeyFieldRef(ParentRecRef, ParentKeyFieldRef);
        ParentKeyValue := ParentKeyFieldRef.Value();

        ParentKeyFieldRef := RecRef.Field(2);
        ParentKeyFieldRef.SetRange(ParentKeyValue);
        if RecRef.FindSet(true) then
            repeat
                OnChangeDependentRecords(ChangeGlobalDimLogEntry, RecRef, IsHandled);
                if not IsHandled then begin
                    ChangeGlobalDimLogEntry.GetFieldRefValues(RecRef, GlobalDimFieldRef, DimValueCode);
                    GlobalDimFieldRef[1].Value(ParentDimValueCode[1]);
                    GlobalDimFieldRef[2].Value(ParentDimValueCode[2]);
                    RecRef.Modify();
                    CurrentRecNo += 1;
                end;
            until RecRef.Next() = 0;

        SetDependentRecNo(ChangeGlobalDimLogEntry."Table ID", 3, CurrentRecNo);
    end;

    local procedure RerunEntry(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry")
    begin
        if ChangeGlobalDimLogEntry.Status in [ChangeGlobalDimLogEntry.Status::" ", ChangeGlobalDimLogEntry.Status::Incomplete, ChangeGlobalDimLogEntry.Status::Scheduled] then begin
            ChangeGlobalDimLogEntry.SendTraceTagOnRerun();
            if ChangeGlobalDimLogEntry."Parent Table ID" <> 0 then
                RescheduleParentTable(ChangeGlobalDimLogEntry."Parent Table ID")
            else
                ScheduleJobForTable(ChangeGlobalDimLogEntry, CurrentDateTime + 2000);
        end;
    end;

    local procedure RescheduleParentTable(ParentTableID: Integer)
    var
        ParentChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        ParentChangeGlobalDimLogEntry.Get(ParentTableID);
        ParentChangeGlobalDimLogEntry.Validate("Completed Records", 0);
        ScheduleJobForTable(ParentChangeGlobalDimLogEntry, CurrentDateTime + 100);
    end;

    local procedure ScheduleJobs(DeltaMsec: Integer)
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        StartTime: DateTime;
    begin
        if FindTablesForScheduling(ChangeGlobalDimLogEntry) then begin
            StartTime := CurrentDateTime + 1000;
            repeat
                StartTime += DeltaMsec;
                ScheduleJobForTable(ChangeGlobalDimLogEntry, StartTime);
            until ChangeGlobalDimLogEntry.Next() = 0;
        end;
    end;

    local procedure ScheduleJobForTable(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; StartNotBefore: DateTime)
    var
        DoNotScheduleTask: Boolean;
        TaskID: Guid;
    begin
        OnBeforeScheduleTask(ChangeGlobalDimLogEntry."Table ID", DoNotScheduleTask, TaskID);
        if DoNotScheduleTask then
            ChangeGlobalDimLogEntry."Task ID" := TaskID
        else begin
            ChangeGlobalDimLogEntry.CancelTask();
            ChangeGlobalDimLogEntry."Task ID" :=
              TASKSCHEDULER.CreateTask(
                CODEUNIT::"Change Global Dimensions", CODEUNIT::"Change Global Dim Err. Handler",
                true, CompanyName, StartNotBefore, ChangeGlobalDimLogEntry.RecordId);
        end;
        if IsNullGuid(ChangeGlobalDimLogEntry."Task ID") then
            ChangeGlobalDimLogEntry.Status := ChangeGlobalDimLogEntry.Status::" "
        else
            ChangeGlobalDimLogEntry.Status := ChangeGlobalDimLogEntry.Status::Scheduled;
        ChangeGlobalDimLogEntry."Earliest Start Date/Time" := StartNotBefore;
        ChangeGlobalDimLogEntry.Modify();
        ChangeGlobalDimLogEntry.SendTraceTagOnScheduling();
        if ChangeGlobalDimLogEntry."Is Parent Table" then
            ScheduleDependentTables(ChangeGlobalDimLogEntry);
    end;

    local procedure ScheduleDependentTables(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry")
    var
        DependentChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        DependentChangeGlobalDimLogEntry.SetRange("Parent Table ID", ChangeGlobalDimLogEntry."Table ID");
        if DependentChangeGlobalDimLogEntry.FindSet() then
            repeat
                DependentChangeGlobalDimLogEntry."Task ID" := ChangeGlobalDimLogEntry."Task ID";
                DependentChangeGlobalDimLogEntry.Validate("Completed Records", 0);
                DependentChangeGlobalDimLogEntry.Status := ChangeGlobalDimLogEntry.Status;
                DependentChangeGlobalDimLogEntry.Modify();
            until DependentChangeGlobalDimLogEntry.Next() = 0;
    end;

    local procedure IsCurrentSessionActiveOnly() Result: Boolean
    var
        ActiveSession: Record "Active Session";
    begin
        OnCountingActiveSessions(Result);
        if Result then
            exit(true);
        // Ignore session types: Web Service,Client Service,NAS,Management Client
        ActiveSession.SetFilter(
          "Client Type", '<>%1&<>%2&<>%3&<>%4',
          ActiveSession."Client Type"::"Web Service", ActiveSession."Client Type"::"Client Service",
          ActiveSession."Client Type"::NAS, ActiveSession."Client Type"::"Management Client");
        ActiveSession.SetFilter("Session ID", '<>%1', SessionId());
        ActiveSession.SetRange("Server Instance ID", ServiceInstanceId());
        exit(ActiveSession.IsEmpty);
    end;

    procedure IsDimCodeEnabled(): Boolean
    begin
        exit(ChangeGlobalDimLogMgt.IsBufferClear());
    end;

    procedure IsPrepareEnabled(var ChangeGlobalDimHeader: Record "Change Global Dim. Header"): Boolean
    begin
        exit(
              ((ChangeGlobalDimHeader."Change Type 1" <> ChangeGlobalDimHeader."Change Type 1"::None) or (ChangeGlobalDimHeader."Change Type 2" <> ChangeGlobalDimHeader."Change Type 2"::None)) and
              ChangeGlobalDimLogMgt.IsBufferClear());
    end;

    procedure IsStartEnabled(): Boolean
    begin
        if ChangeGlobalDimLogMgt.IsBufferClear() then
            exit(false);
        exit(not ChangeGlobalDimLogMgt.IsStarted());
    end;

    procedure RefreshHeader()
    begin
        if ChangeGlobalDimHeader.Get() then begin
            ChangeGlobalDimHeader.Refresh();
            ChangeGlobalDimHeader.Modify();
        end else begin
            ChangeGlobalDimHeader.Refresh();
            ChangeGlobalDimHeader.Insert();
        end
    end;

    procedure SetParallelProcessing(NewParallelProcessing: Boolean)
    begin
        ChangeGlobalDimHeader.Get();
        ChangeGlobalDimHeader."Parallel Processing" := NewParallelProcessing;
        ChangeGlobalDimHeader.Modify();
    end;

    procedure InitTableList(): Boolean
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
        TempAllObjWithCaption: Record AllObjWithCaption temporary;
        TempParentTableInteger: Record "Integer" temporary;
        TotalRecords: Integer;
    begin
        TotalRecords := 0;
        ChangeGlobalDimHeader.Get();
        ChangeGlobalDimLogEntry.LockTable();
        ChangeGlobalDimLogEntry.DeleteAll(true);
        if FindTablesWithDims(TempAllObjWithCaption) then begin
            OnInitTableListOnAfterFindTablesWithDims(ChangeGlobalDimHeader);
            repeat
                ChangeGlobalDimLogEntry.Init();
                ChangeGlobalDimLogEntry."Table ID" := TempAllObjWithCaption."Object ID";
                ChangeGlobalDimLogEntry."Table Name" := TempAllObjWithCaption."Object Name";
                ChangeGlobalDimLogEntry."Change Type 1" := ChangeGlobalDimHeader."Change Type 1";
                ChangeGlobalDimLogEntry."Change Type 2" := ChangeGlobalDimHeader."Change Type 2";
                FillTableData(ChangeGlobalDimLogEntry);
                TotalRecords += ChangeGlobalDimLogEntry."Total Records";
                TempParentTableInteger.Number := ChangeGlobalDimLogEntry."Parent Table ID";
                if TempParentTableInteger.Number <> 0 then
                    if TempParentTableInteger.Insert() then;
                OnInitTableListOnBeforeInsertChangeGlobalDimLogEntry(ChangeGlobalDimHeader, ChangeGlobalDimLogEntry);
                ChangeGlobalDimLogEntry.Insert();
            until TempAllObjWithCaption.Next() = 0;

            if TempParentTableInteger.FindSet() then
                repeat
                    if ChangeGlobalDimLogEntry.Get(TempParentTableInteger.Number) then begin
                        ChangeGlobalDimLogEntry."Is Parent Table" := true;
                        ChangeGlobalDimLogEntry.Modify();
                    end;
                until TempParentTableInteger.Next() = 0;
        end;
        if TotalRecords = 0 then
            ChangeGlobalDimLogEntry.DeleteAll(true);
        ChangeGlobalDimLogMgt.FillBuffer();
        exit(TotalRecords <> 0);
    end;

    local procedure TestDirectModifyPermission(var RecRef: RecordRef)
    var
        IsHandled: Boolean;
    begin
        OnBeforeTestDirectModifyPermission(RecRef, IsHandled);
        if IsHandled then
            exit;

        if RecRef.FindFirst() then
            RecRef.Modify();
    end;

    local procedure DeleteEntry(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"): Boolean
    begin
        if ChangeGlobalDimLogEntry.Delete() then begin
            ChangeGlobalDimLogMgt.ExcludeTable(ChangeGlobalDimLogEntry."Table ID");
            exit(true);
        end
    end;

    local procedure FillTableData(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry")
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(ChangeGlobalDimLogEntry."Table ID");
        TestDirectModifyPermission(RecRef);
        ChangeGlobalDimLogEntry.FillData(RecRef);
        RecRef.Close();
        OnAfterFillTableData(ChangeGlobalDimLogEntry);
    end;

    local procedure FindTablesWithDims(var TempAllObjWithCaption: Record AllObjWithCaption temporary): Boolean
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.DefaultDimObjectNoWithGlobalDimsList(TempAllObjWithCaption);
        DimensionManagement.GlobalDimObjectNoList(TempAllObjWithCaption);
        DimensionManagement.JobTaskDimObjectNoList(TempAllObjWithCaption);
        OnAfterGetObjectNoList(TempAllObjWithCaption);
        exit(TempAllObjWithCaption.FindSet());
    end;

    local procedure UpdateGLSetup()
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Global Dimension 1 Code", ChangeGlobalDimHeader."Global Dimension 1 Code");
        GeneralLedgerSetup.Validate("Global Dimension 2 Code", ChangeGlobalDimHeader."Global Dimension 2 Code");
        GeneralLedgerSetup.Modify(true);

        UpdateDimValues();
        if ChangeGlobalDimHeader."Parallel Processing" then
            Commit();
    end;

    local procedure UpdateDimValues()
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetCurrentKey(Code, "Global Dimension No.");
        DimensionValue.SetRange("Global Dimension No.", 1, 2);
        DimensionValue.ModifyAll("Global Dimension No.", 0);
        DimensionValue.Reset();
        if ChangeGlobalDimHeader."Global Dimension 1 Code" <> '' then begin
            DimensionValue.SetRange("Dimension Code", ChangeGlobalDimHeader."Global Dimension 1 Code");
            DimensionValue.ModifyAll("Global Dimension No.", 1);
        end;
        if ChangeGlobalDimHeader."Global Dimension 2 Code" <> '' then begin
            DimensionValue.SetRange("Dimension Code", ChangeGlobalDimHeader."Global Dimension 2 Code");
            DimensionValue.ModifyAll("Global Dimension No.", 2);
        end;
    end;

    procedure GetCloseSessionsNotificationID() Id: Guid
    begin
        Evaluate(Id, CloseSessionNotificationTok);
    end;

    local procedure PrepareNotification(var Notification: Notification; ID: Guid; Msg: Text)
    begin
        Notification.Id(ID);
        Notification.Recall();
        Notification.Message(Msg);
        Notification.Scope(NOTIFICATIONSCOPE::LocalScope);
    end;

    local procedure SendCloseSessionsNotification()
    var
        Notification: Notification;
    begin
        PrepareNotification(Notification, GetCloseSessionsNotificationID(), CloseActiveSessionsMsg);
        Notification.AddAction(SessionListActionTxt, CODEUNIT::"Change Global Dimensions", 'ShowActiveSessions');
        Notification.Send();
    end;

    local procedure SendTraceTagOn(TraceTagMessage: Text)
    begin
        Session.LogMessage('00001ZE', TraceTagMessage, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TagCategoryTxt);
    end;

    procedure ShowActiveSessions(BlockNotification: Notification)
    begin
        PAGE.Run(PAGE::"Concurrent Session List");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetObjectNoList(var TempAllObjWithCaption: Record AllObjWithCaption temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCountingActiveSessions(var IsCurrSessionActiveOnly: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeScheduleTask(TableNo: Integer; var DoNotScheduleTask: Boolean; var TaskID: Guid)
    begin
    end;

    local procedure UpdateWithCommit(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; CurrentRecNo: Integer; StartedFromRecord: Integer): Boolean
    begin
        if ChangeGlobalDimHeader."Parallel Processing" then
            exit(ChangeGlobalDimLogEntry.UpdateWithCommit(CurrentRecNo, StartedFromRecord));
        exit(ChangeGlobalDimLogEntry.UpdateWithoutCommit(CurrentRecNo, StartedFromRecord));
    end;

    local procedure WindowOpen()
    begin
        if GuiAllowed then begin
            Window.Open(ProgressMsg);
            IsWindowOpen := true;
        end;
    end;

    local procedure WindowClose()
    begin
        if IsWindowOpen then begin
            Window.Close();
            IsWindowOpen := false;

            Message(SessionUpdateRequiredMsg);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestDirectModifyPermission(var RecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeDependentRecords(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; var RecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeDimsOnRecord(ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; var RecRef: RecordRef; var IsHandled: Boolean; var Success: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillTableData(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeDimsOnTableOnBeforeCalcRecordsWithinCommit(var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry"; var ChangeGlobalDimLogMgt: Codeunit "Change Global Dim. Log Mgt."; var ChangeGlobalDimHeader: Record "Change Global Dim. Header"; var Completed: Boolean; var StartedFromRecord: Integer; var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitTableListOnAfterFindTablesWithDims(var ChangeGlobalDimHeader: Record "Change Global Dim. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitTableListOnBeforeInsertChangeGlobalDimLogEntry(var ChangeGlobalDimHeader: Record "Change Global Dim. Header"; var ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry")
    begin
    end;
}

