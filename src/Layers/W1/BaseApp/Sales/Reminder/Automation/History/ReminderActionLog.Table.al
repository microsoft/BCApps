// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Stores individual action execution records within a reminder automation run including results and descriptions.
/// </summary>
table 6752 "Reminder Action Log"
{
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the unique auto-incrementing identifier for this action log entry.
        /// </summary>
        field(1; Id; Integer)
        {
            AutoIncrement = true;
        }
        /// <summary>
        /// Specifies the automation run ID to which this action log belongs.
        /// </summary>
        field(2; "Run Id"; Integer)
        {
        }
        /// <summary>
        /// Specifies the reminder action group that was executed.
        /// </summary>
        field(3; "Reminder Action Group ID"; Code[50])
        {
        }
        /// <summary>
        /// Specifies the specific reminder action that was executed.
        /// </summary>
        field(4; "Reminder Action ID"; Code[50])
        {
            ToolTip = 'Specifies the reminder action that was performed.';
        }
        /// <summary>
        /// Specifies the total number of records processed by this action.
        /// </summary>
        field(5; "Total Records Processed"; Integer)
        {
        }
#if not CLEANSCHEMA29
        /// <summary>
        /// Contains the total number of errors encountered during this action.
        /// </summary>
        field(6; "Total Errors"; Integer)
        {
            ToolTip = 'Specifies the total number of errors that occurred during the action job.';
#if not CLEAN27
            ObsoleteState = Pending;
            ObsoleteReason = 'This field is obsolete and should not be used.';
#pragma warning disable AS0074
            ObsoleteTag = '27.0';
#pragma warning restore AS0074
#else
            ObsoleteState = Removed;
            ObsoleteReason = 'This field is obsolete and should not be used.';
            ObsoleteTag = '29.0';
#endif
        }
#endif
        /// <summary>
        /// Specifies the record ID of the last record processed by this action.
        /// </summary>
        field(7; "Last Record Processed"; RecordId)
        {
        }
        /// <summary>
        /// Specifies the current status of this action: running, completed, or failed.
        /// </summary>
        field(10; Status; Enum "Reminder Log Status")
        {
            ToolTip = 'Specifies the status of the action.';
        }
        /// <summary>
        /// Contains a summary description of the action status and results.
        /// </summary>
        field(11; "Status summary"; Text[1024])
        {
            ToolTip = 'Specifies the details of the last action job.';
        }
        /// <summary>
        /// Contains detailed information about the action execution.
        /// </summary>
        field(12; "Details"; Blob)
        {
        }
        /// <summary>
        /// Specifies the job queue entry ID associated with this action execution.
        /// </summary>
        field(13; JobQueueID; Guid)
        {
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }
}