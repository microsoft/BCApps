// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 6933 "Expense Agent Status"
{
    Access = Internal;
    Extensible = false;
    ReplicateData = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = rimdX;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            ToolTip = 'Specifies the primary key of the agent status record.';
        }
        field(2; "Agent Task ID"; Guid)
        {
            Caption = 'Agent Task ID';
            ToolTip = 'Specifies the unique identifier of the scheduled agent task.';
            DataClassification = SystemMetadata;
        }
        field(3; "Agent Recovery Task ID"; Guid)
        {
            Caption = 'Agent Recovery Task ID';
            ToolTip = 'Specifies the unique identifier of the scheduled recovery task.';
            DataClassification = SystemMetadata;
        }
        field(4; "Earliest Sync At"; DateTime)
        {
            Caption = 'Earliest Sync At';
            ToolTip = 'Specifies the earliest date and time when the agent processes emails.';
            DataClassification = SystemMetadata;
        }
        field(5; "Last Sync At"; DateTime)
        {
            Caption = 'Last Sync At';
            ToolTip = 'Specifies the date and time the agent last processed emails.';
            DataClassification = SystemMetadata;
        }
        field(6; "Last Notif. Run At"; DateTime)
        {
            Caption = 'Last Notification Run At';
            ToolTip = 'Specifies the date and time when open report notifications were last sent.';
            DataClassification = SystemMetadata;
        }
        field(10; "EA Scheduler Task ID"; BigInteger)
        {
            Caption = 'Scheduler Task ID';
            ToolTip = 'Specifies the currently or last running scheduler task.';
            DataClassification = SystemMetadata;
        }
        field(11; "Scheduler Task Status"; Option)
        {
            Caption = 'Scheduler Task Status';
            ToolTip = 'Specifies the Status of the currently or last running scheduler task.';
            OptionMembers = "In Progress",Succeeded,Failed;
            OptionCaption = 'In Progress,Succeeded,Failed', Comment = 'In Progress = task is running, Succeeded = task completed successfully, Failed = something went wrong. See error message';
            FieldClass = FlowField;
            CalcFormula = lookup("EA Scheduler Task".Status where(ID = field("EA Scheduler Task ID")));
        }
        field(12; "Scheduler Task Error Message"; Text[1000])
        {
            Caption = 'Scheduler Task Error Message';
            ToolTip = 'Specifies the error message from the currently or last running scheduler task.';
            FieldClass = FlowField;
            CalcFormula = lookup("EA Scheduler Task"."Error Message" where(ID = field("EA Scheduler Task ID")));
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    internal procedure GetOrCreate()
    begin
        LockTable();
        if not Get() then begin
            Init();
            Insert();
        end;
    end;
}
