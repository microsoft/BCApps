// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.HumanResources.Payables;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.History;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using System.Environment;
using System.Reflection;
using System.Threading;

/// <summary>
/// Logs the progress and status of the Change Global Dimensions background process.
/// Tracks table-by-table progress, error counts, and processing statistics for dimension restructuring operations.
/// </summary>
/// <remarks>
/// Used by the Change Global Dimensions functionality to monitor multi-table dimension updates.
/// Provides audit trail and progress tracking for critical dimension restructuring operations.
/// Integrates with session management and background task processing systems.
/// </remarks>
table 483 "Change Global Dim. Log Entry"
{
    Caption = 'Change Global Dim. Log Entry';
    Permissions = TableData "G/L Entry" = rm,
                  TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "Item Ledger Entry" = rm,
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
                  TableData "Issued Fin. Charge Memo Header" = rm,
                  TableData "Detailed Cust. Ledg. Entry" = rm,
                  TableData "Detailed Vendor Ledg. Entry" = rm,
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
                  TableData Microsoft.Service.Document."Service Line" = rm,
                  TableData Microsoft.Service.Document."Service Item Line" = rm,
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
                  TableData "Return Shipment Header" = rm,
                  TableData "Return Shipment Line" = rm,
                  TableData "Return Receipt Header" = rm,
                  TableData "Return Receipt Line" = rm;
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier of the table being processed during dimension change operation.
        /// </summary>
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        /// <summary>
        /// Name of the table being processed for display purposes.
        /// </summary>
        field(2; "Table Name"; Text[50])
        {
            Caption = 'Table Name';
        }
        /// <summary>
        /// Total number of records in the table that need to be processed.
        /// </summary>
        field(3; "Total Records"; Integer)
        {
            Caption = 'Total Records';
        }
        /// <summary>
        /// Number of records that have been successfully processed.
        /// </summary>
        field(4; "Completed Records"; Integer)
        {
            Caption = 'Completed Records';

            trigger OnValidate()
            begin
                CalcProgress();
            end;
        }
        /// <summary>
        /// Processing progress percentage for tracking completion status.
        /// </summary>
        field(5; Progress; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Progress';
            ExtendedDatatype = Ratio;
        }
        /// <summary>
        /// Current processing status of the table dimension change operation.
        /// </summary>
        field(6; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = ' ,Scheduled,In Progress,Completed,Incomplete';
            OptionMembers = " ",Scheduled,"In Progress",Completed,Incomplete;
        }
        /// <summary>
        /// Unique identifier of the scheduled task processing this table.
        /// </summary>
        field(7; "Task ID"; Guid)
        {
            Caption = 'Task ID';
        }
        /// <summary>
        /// Session identifier for tracking the processing session.
        /// </summary>
        field(8; "Session ID"; Integer)
        {
            Caption = 'Session ID';
        }
        /// <summary>
        /// Type of change operation for global dimension 1 (None, Blank, Replace, or New).
        /// </summary>
        field(9; "Change Type 1"; Option)
        {
            Caption = 'Change Type 1';
            OptionCaption = 'None,Blank,Replace,New';
            OptionMembers = "None",Blank,Replace,New;
        }
        /// <summary>
        /// Type of change operation for global dimension 2 (None, Blank, Replace, or New).
        /// </summary>
        field(10; "Change Type 2"; Option)
        {
            Caption = 'Change Type 2';
            OptionCaption = 'None,Blank,Replace,New';
            OptionMembers = "None",Blank,Replace,New;
        }
        /// <summary>
        /// Field number for global dimension 1 in this table.
        /// </summary>
        field(11; "Global Dim.1 Field No."; Integer)
        {
            Caption = 'Global Dim.1 Field No.';
        }
        /// <summary>
        /// Field number for global dimension 2 in this table.
        /// </summary>
        field(12; "Global Dim.2 Field No."; Integer)
        {
            Caption = 'Global Dim.2 Field No.';
        }
        /// <summary>
        /// Field number for dimension set ID in this table.
        /// </summary>
        field(13; "Dim. Set ID Field No."; Integer)
        {
            Caption = 'Dim. Set ID Field No.';
        }
        /// <summary>
        /// Field number of the primary key field used for record processing.
        /// </summary>
        field(14; "Primary Key Field No."; Integer)
        {
            Caption = 'Primary Key Field No.';
        }
        /// <summary>
        /// Table ID of the parent table when processing related tables in hierarchy.
        /// </summary>
        field(15; "Parent Table ID"; Integer)
        {
            Caption = 'Parent Table ID';
        }
        /// <summary>
        /// Indicates whether this table is a parent table in the processing hierarchy.
        /// </summary>
        field(16; "Is Parent Table"; Boolean)
        {
            Caption = 'Is Parent Table';
        }
        /// <summary>
        /// Earliest date and time when processing can start for this table.
        /// </summary>
        field(17; "Earliest Start Date/Time"; DateTime)
        {
            Caption = 'Earliest Start Date/Time';
            ToolTip = 'Specifies the earliest date and time when the job should be run.';
        }
        /// <summary>
        /// Estimated remaining time to complete processing this table.
        /// </summary>
        field(18; "Remaining Duration"; Duration)
        {
            Caption = 'Remaining Duration';
            ToolTip = 'Specifies the remaining duration of the job.';
        }
        /// <summary>
        /// Identifier of the server instance processing this table.
        /// </summary>
        field(19; "Server Instance ID"; Integer)
        {
            Caption = 'Server Instance ID';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Table ID")
        {
            Clustered = true;
        }
        key(Key2; Progress)
        {
        }
        key(Key3; "Parent Table ID")
        {
        }
    }

    fieldgroups
    {
    }

    var
        ErrorTraceTagMsg: Label 'Error on the task for table %1 (completed %2 of %3 records): %4.', Comment = '%1- table id; %2 ,%3 - integer values; %4 - error message';
        RerunTraceTagMsg: Label 'Rerun the task for table %1 (start from %2 of %3 records).', Comment = '%1- table id; %2 ,%3 - integer values';
        ScheduledTraceTagMsg: Label 'The task is scheduled for table %1 (%2 records) to start on %3.', Comment = '%1- table id; %2 - integer value; %3 - datetime';
        TagCategoryTxt: Label 'Change Global Dimensions';

    local procedure CalcProgress()
    begin
        Progress := 10000;
        if ("Total Records" <> 0) and ("Completed Records" <= "Total Records") then
            Progress := "Completed Records" / "Total Records" * 10000;
    end;

    /// <summary>
    /// Updates the progress of dimension change processing for this table entry.
    /// Returns true if the processing is complete, false if still in progress.
    /// </summary>
    /// <param name="CurrentRecNo">Current record number being processed</param>
    /// <param name="StartedFromRecord">Record number where processing started</param>
    /// <returns>True if processing is complete, false if still in progress</returns>
    procedure Update(CurrentRecNo: Integer; StartedFromRecord: Integer): Boolean
    begin
        if "Completed Records" = CurrentRecNo then
            exit(false);

        if CurrentRecNo >= "Total Records" then
            RecalculateTotalRecords();
        Validate("Completed Records", CurrentRecNo);
        case "Completed Records" of
            0:
                begin
                    Status := Status::Incomplete;
                    Clear("Remaining Duration");
                end;
            "Total Records":
                Status := Status::Completed;
            else
                if CurrentRecNo - StartedFromRecord <> 0 then
                    "Remaining Duration" :=
                      Round(
                        ("Total Records" - CurrentRecNo) / (CurrentRecNo - StartedFromRecord) *
                        (CurrentDateTime - "Earliest Start Date/Time"), 1);
        end;
        exit(Modify());
    end;

    /// <summary>
    /// Updates progress with automatic commit and returns completion status.
    /// </summary>
    /// <param name="CurrentRecNo">Current record number being processed</param>
    /// <param name="StartedFromRecord">Record number where processing started</param>
    /// <returns>True if processing is complete, false if still in progress</returns>
    procedure UpdateWithCommit(CurrentRecNo: Integer; StartedFromRecord: Integer) Completed: Boolean
    begin
        if Update(CurrentRecNo, StartedFromRecord) then
            Commit();
        Completed := Status = Status::Completed;
    end;

    /// <summary>
    /// Updates progress without committing transaction and returns completion status.
    /// </summary>
    /// <param name="CurrentRecNo">Current record number being processed</param>
    /// <param name="StartedFromRecord">Record number where processing started</param>
    /// <returns>True if processing is complete, false if still in progress</returns>
    procedure UpdateWithoutCommit(CurrentRecNo: Integer; StartedFromRecord: Integer) Completed: Boolean
    begin
        Update(CurrentRecNo, StartedFromRecord);
        Completed := Status = Status::Completed;
    end;

    /// <summary>
    /// Cancels the scheduled task associated with this dimension change operation.
    /// Clears the Task ID field after canceling the scheduled task.
    /// </summary>
    procedure CancelTask()
    var
        ScheduledTask: Record "Scheduled Task";
    begin
        if not IsNullGuid("Task ID") then begin
            if ScheduledTask.Get("Task ID") then
                TASKSCHEDULER.CancelTask("Task ID");
            Clear("Task ID");
        end;
    end;

    /// <summary>
    /// Changes the dimension value on a specific record field during dimension change processing.
    /// </summary>
    /// <param name="RecRef">Record reference to modify</param>
    /// <param name="DimNo">Dimension number (1 or 2)</param>
    /// <param name="GlobalDimFieldRef">Field reference for the global dimension field</param>
    /// <param name="OldDimValueCode">Previous dimension value code</param>
    procedure ChangeDimOnRecord(var RecRef: RecordRef; DimNo: Integer; GlobalDimFieldRef: FieldRef; OldDimValueCode: Code[20])
    var
        NewValue: Code[20];
    begin
        case GetChangeType(DimNo) of
            "Change Type 1"::New:
                NewValue := FindDimensionValueCode(RecRef, DimNo);
            "Change Type 1"::Blank:
                NewValue := '';
            "Change Type 1"::Replace:
                NewValue := OldDimValueCode;
            "Change Type 1"::None:
                exit;
        end;
        GlobalDimFieldRef.Value(NewValue);
    end;

    /// <summary>
    /// Retrieves field references and current dimension values for global dimension fields.
    /// </summary>
    /// <param name="RecRef">Record reference to examine</param>
    /// <param name="GlobalDimFieldRef">Array of field references for global dimensions</param>
    /// <param name="DimValueCode">Array of current dimension value codes</param>
    procedure GetFieldRefValues(RecRef: RecordRef; var GlobalDimFieldRef: array[2] of FieldRef; var DimValueCode: array[2] of Code[20])
    begin
        if "Global Dim.1 Field No." <> 0 then begin
            GlobalDimFieldRef[1] := RecRef.Field("Global Dim.1 Field No.");
            DimValueCode[1] := GlobalDimFieldRef[1].Value();
        end;
        if "Global Dim.2 Field No." <> 0 then begin
            GlobalDimFieldRef[2] := RecRef.Field("Global Dim.2 Field No.");
            DimValueCode[2] := GlobalDimFieldRef[2].Value();
        end;
    end;

    /// <summary>
    /// Locates and stores the field number for the Dimension Set ID field in the specified table.
    /// </summary>
    /// <param name="RecRef">Record reference to examine for dimension set ID field</param>
    /// <returns>True if dimension set ID field is found, false otherwise</returns>
    procedure FindDimensionSetIDField(RecRef: RecordRef): Boolean
    var
        "Field": Record "Field";
    begin
        if FindDefaultDimSetIDFieldNo(RecRef) then
            exit(true);
        Field.SetRange(TableNo, RecRef.Number);
        Field.SetRange(RelationTableNo, DATABASE::"Dimension Set Entry");
        Field.SetRange(FieldName, 'Dimension Set ID');
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        if Field.FindFirst() then begin
            "Dim. Set ID Field No." := Field."No.";
            exit(true);
        end;
    end;

    local procedure FindDefaultDimSetIDFieldNo(RecRef: RecordRef) Found: Boolean
    begin
        // W1 "Dimension Set ID" fields must have ID = 480
        if RecRef.FieldExist(480) then begin
            "Dim. Set ID Field No." := 480;
            Found := true;
        end;
        OnAfterFindDefaultDimSetIDFieldNo(RecRef, Found);
    end;

    /// <summary>
    /// Finds the dimension value code for a specific dimension on a given record.
    /// </summary>
    /// <param name="RecRef">Record reference to examine</param>
    /// <param name="DimNo">Dimension number (1 or 2) to find value for</param>
    /// <returns>Dimension value code for the specified dimension</returns>
    procedure FindDimensionValueCode(RecRef: RecordRef; DimNo: Integer): Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionCode: Code[20];
        DimensionValueCode: Code[20];
        IsHandled: Boolean;
    begin
        GeneralLedgerSetup.Get();
        case DimNo of
            1:
                DimensionCode := GeneralLedgerSetup."Global Dimension 1 Code";
            2:
                DimensionCode := GeneralLedgerSetup."Global Dimension 2 Code";
        end;
        if "Dim. Set ID Field No." = 0 then begin
            if RecRef.Number = DATABASE::"Job Task" then
                exit(FindJobTaskDimensionValueCode(RecRef, DimensionCode));
            IsHandled := false;
            OnBeforeFindDefaultDimensionValueCode(RecRef, DimensionCode, DimensionValueCode, IsHandled);
            if IsHandled then
                exit(DimensionValueCode);
            exit(FindDefaultDimensionValueCode(RecRef, DimensionCode));
        end;
        exit(FindDimSetDimensionValueCode(RecRef, DimensionCode));
    end;

    local procedure FindDefaultDimensionValueCode(RecRef: RecordRef; DimensionCode: Code[20]): Code[20]
    var
        DefaultDimension: Record "Default Dimension";
        PKFieldRef: FieldRef;
    begin
        PKFieldRef := RecRef.Field("Primary Key Field No.");
        if DefaultDimension.Get(RecRef.Number, Format(PKFieldRef.Value()), DimensionCode) then
            exit(DefaultDimension."Dimension Value Code");
        exit('');
    end;

    local procedure FindDimSetDimensionValueCode(RecRef: RecordRef; DimensionCode: Code[20]): Code[20]
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        DimSetIDFieldRef: FieldRef;
        DimSetID: Integer;
    begin
        DimSetIDFieldRef := RecRef.Field("Dim. Set ID Field No.");
        DimSetID := DimSetIDFieldRef.Value();
        if DimensionSetEntry.Get(DimSetID, DimensionCode) then
            exit(DimensionSetEntry."Dimension Value Code");
        exit('');
    end;

    local procedure FindJobTaskDimensionValueCode(RecRef: RecordRef; DimensionCode: Code[20]): Code[20]
    var
        JobTask: Record "Job Task";
        JobTaskDimension: Record "Job Task Dimension";
    begin
        RecRef.SetTable(JobTask);
        if JobTaskDimension.Get(JobTask."Job No.", JobTask."Job Task No.", DimensionCode) then
            exit(JobTaskDimension."Dimension Value Code");
        exit('');
    end;

    local procedure FindParentTable(RecRef: RecordRef): Integer
    var
        ParentKeyFieldRef: FieldRef;
    begin
        if RecRef.FieldExist(2) then begin // typical for Detailed Ledger Entry tables
            ParentKeyFieldRef := RecRef.Field(2);
            if ParentKeyFieldRef.Type = FieldType::Integer then
                exit(ParentKeyFieldRef.Relation);
        end;
    end;

    /// <summary>
    /// Initializes log entry data by analyzing the table structure and populating field numbers.
    /// </summary>
    /// <param name="RecRef">Record reference to analyze for dimension processing setup</param>
    procedure FillData(RecRef: RecordRef)
    var
        PKeyFieldRef: FieldRef;
    begin
        "Total Records" := RecRef.Count();
        if not FindDimensionSetIDField(RecRef) then begin
            GetPrimaryKeyFieldRef(RecRef, PKeyFieldRef);
            if PKeyFieldRef.Type = FieldType::Code then
                "Primary Key Field No." := PKeyFieldRef.Number
            else
                "Parent Table ID" := FindParentTable(RecRef);
        end;
        FindFieldIDs();
    end;

    local procedure FindFieldIDs()
    var
        "Field": Record "Field";
        DimensionManagement: Codeunit DimensionManagement;
    begin
        if DimensionManagement.FindDimFieldInTable("Table ID", 'Dimension 1 Code*|*Global Dim. 1', Field) then
            "Global Dim.1 Field No." := Field."No.";
        if DimensionManagement.FindDimFieldInTable("Table ID", 'Dimension 2 Code*|*Global Dim. 2', Field) then
            "Global Dim.2 Field No." := Field."No.";
    end;

    local procedure GetChangeType(DimNo: Integer): Integer
    begin
        if DimNo = 1 then
            exit("Change Type 1");
        exit("Change Type 2");
    end;

    /// <summary>
    /// Retrieves the primary key field reference for the table record.
    /// </summary>
    /// <param name="RecRef">Record reference to examine</param>
    /// <param name="PKeyFieldRef">Returns the primary key field reference</param>
    procedure GetPrimaryKeyFieldRef(RecRef: RecordRef; var PKeyFieldRef: FieldRef)
    var
        PKeyRef: KeyRef;
    begin
        PKeyRef := RecRef.KeyIndex(1);
        PKeyFieldRef := PKeyRef.FieldIndex(1);
    end;

    local procedure RecalculateTotalRecords()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open("Table ID");
        "Total Records" := RecRef.Count();
        RecRef.Close();
    end;

    /// <summary>
    /// Logs error trace information for dimension change processing failures.
    /// </summary>
    procedure SendTraceTagOnError()
    begin
        Session.LogMessage('00001ZB', StrSubstNo(ErrorTraceTagMsg, "Table ID", "Completed Records", "Total Records", GetLastErrorText), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TagCategoryTxt);
    end;

    /// <summary>
    /// Logs trace information when dimension change processing is rerun.
    /// </summary>
    procedure SendTraceTagOnRerun()
    begin
        Session.LogMessage('00001ZC', StrSubstNo(RerunTraceTagMsg, "Table ID", "Completed Records", "Total Records"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TagCategoryTxt);
    end;

    /// <summary>
    /// Logs trace information when dimension change processing is scheduled.
    /// </summary>
    procedure SendTraceTagOnScheduling()
    begin
        Session.LogMessage('00001ZD', StrSubstNo(ScheduledTraceTagMsg, "Table ID", "Total Records", Format("Earliest Start Date/Time", 0, 9)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TagCategoryTxt);
    end;

    /// <summary>
    /// Sets the session ID to track the current processing session.
    /// Marks the status as "In Progress" for active processing tracking.
    /// </summary>
    procedure SetSessionInProgress()
    begin
        "Session ID" := SessionId();
        "Server Instance ID" := ServiceInstanceId();
        Status := Status::"In Progress";
        Modify();
    end;

    /// <summary>
    /// Updates the processing status based on current task and session state.
    /// Returns the previous status value for comparison.
    /// </summary>
    /// <returns>Previous status value before the update</returns>
    procedure UpdateStatus() OldStatus: Integer
    begin
        OldStatus := Status;
        if IsNullGuid("Task ID") then
            Status := Status::" "
        else
            if "Completed Records" = "Total Records" then begin
                "Session ID" := -1; // to avoid match to real user sessions
                "Server Instance ID" := -1;
                Status := Status::Completed
            end else
                if "Session ID" = 0 then begin
                    if IsTaskScheduled() then
                        Status := Status::Scheduled
                    else
                        Status := Status::Incomplete;
                end else
                    if IsSessionActive() then
                        Status := Status::"In Progress"
                    else begin
                        Status := Status::Incomplete;
                        "Session ID" := -1;
                        "Server Instance ID" := -1;
                    end;
    end;

    /// <summary>
    /// Checks if the session associated with this log entry is currently active.
    /// Returns true if the session is running on the current server instance or another instance.
    /// </summary>
    /// <returns>True if the session is active, false if inactive or logged off</returns>
    local procedure IsSessionActive(): Boolean;
    var
        ActiveSession: Record "Active Session";
    begin
        if "Server Instance ID" = ServiceInstanceId() then
            exit(ActiveSession.Get("Server Instance ID", "Session ID"));
        if "Server Instance ID" <= 0 then
            exit(false);
        exit(not IsSessionLoggedOff());
    end;

    /// <summary>
    /// Checks if the session associated with this log entry has logged off.
    /// Searches session event records for logoff events after the earliest start date/time.
    /// </summary>
    /// <returns>True if the session has logged off, false if still active</returns>
    local procedure IsSessionLoggedOff(): Boolean;
    var
        SessionEvent: Record "Session Event";
    begin
        SessionEvent.SetRange("Server Instance ID", "Server Instance ID");
        SessionEvent.SetRange("Session ID", "Session ID");
        SessionEvent.SetRange("Event Type", SessionEvent."Event Type"::Logoff);
        SessionEvent.SetFilter("Event Datetime", '>%1', "Earliest Start Date/Time");
        SessionEvent.SetRange("User SID", UserSecurityId());
        exit(not SessionEvent.IsEmpty);
    end;

    /// <summary>
    /// Displays error details from job queue log entries for failed dimension change tasks.
    /// Opens the Job Queue Log Entries page filtered to show errors for this table.
    /// </summary>
    procedure ShowError()
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        if IsNullGuid("Task ID") then begin
            JobQueueLogEntry.SetRange("Object Type to Run", JobQueueLogEntry."Object Type to Run"::Codeunit);
            JobQueueLogEntry.SetRange("Object ID to Run", CODEUNIT::"Change Global Dim Err. Handler");
            JobQueueLogEntry.SetRange(Description, "Table Name");
        end else
            JobQueueLogEntry.SetRange(ID, "Task ID");
        JobQueueLogEntry.SetRange(Status, JobQueueLogEntry.Status::Error);
        PAGE.RunModal(PAGE::"Job Queue Log Entries", JobQueueLogEntry);
    end;

    local procedure IsTaskScheduled() TaskExists: Boolean
    var
        ScheduledTask: Record "Scheduled Task";
    begin
        OnFindingScheduledTask("Task ID", TaskExists);
        if not TaskExists then
            exit(ScheduledTask.Get("Task ID"));
    end;

    /// <summary>
    /// Integration event raised after attempting to find default dimension set ID field number.
    /// Enables extensions to provide custom logic for identifying dimension set ID fields.
    /// </summary>
    /// <param name="RecRef">Record reference being examined</param>
    /// <param name="Found">Indicates whether the field was found by standard logic</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterFindDefaultDimSetIDFieldNo(RecRef: RecordRef; var Found: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised when checking if a scheduled task exists.
    /// Enables extensions to provide custom task existence verification.
    /// </summary>
    /// <param name="TaskID">GUID of the task to check</param>
    /// <param name="IsTaskExist">Returns whether the task exists</param>
    [IntegrationEvent(false, false)]
    local procedure OnFindingScheduledTask(TaskID: Guid; var IsTaskExist: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before finding default dimension value code.
    /// Enables extensions to provide custom dimension value code lookup logic.
    /// </summary>
    /// <param name="RecRef">Record reference being examined</param>
    /// <param name="DimensionCode">Dimension code to find value for</param>
    /// <param name="DimensionValueCode">Returns the dimension value code</param>
    /// <param name="IsHandled">Set to true to skip standard lookup logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindDefaultDimensionValueCode(RecRef: RecordRef; DimensionCode: Code[20]; var DimensionValueCode: Code[20]; var IsHandled: Boolean)
    begin
    end;
}
