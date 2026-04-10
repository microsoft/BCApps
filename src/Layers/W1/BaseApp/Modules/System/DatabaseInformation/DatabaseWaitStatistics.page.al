namespace System.DataAdministration;

using System.Diagnostics;
using System.Telemetry;

page 9520 "Database Wait Statistics"
{
    Caption = 'Database Wait Statistics';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Database Wait Statistics";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Control2)
            {
                InstructionalText = 'This page shows a snapshot of wait time statistics on the tenant database. The statistics are aggregated since the time that the database was started and the different wait types are also aggregated into wait categories (see the documentation for the SQL Server dynamic management view sys.query_store_wait_stats for more information). See the documentation for system dynamic management views sys.dm_db_wait_stats (Azure SQL database) or sys.dm_os_wait_stats (SQL Server) for more information on wait statistics.';
                ShowCaption = false;
            }
            repeater(Group)
            {
                field("Wait Category"; Rec."Wait Category")
                {
                    ApplicationArea = All;
                    Caption = 'Wait Category';
                    ToolTip = 'Name of the wait category';
                }
                field("Waiting Tasks Count"; Rec."Waiting Tasks Count")
                {
                    ApplicationArea = All;
                    Caption = 'Waiting Tasks Count';
                    ToolTip = 'Number of waits on this wait type. This counter is incremented at the start of each wait.';
                }
                field("Wait Time in ms"; Rec."Wait Time in ms")
                {
                    ApplicationArea = All;
                    Caption = 'Wait Time in ms';
                    ToolTip = 'Total wait time for this wait type in milliseconds. This time is inclusive of signal_wait_time_ms.';
                }
                field("Max Wait Time in ms"; Rec."Max Wait Time in ms")
                {
                    ApplicationArea = All;
                    Caption = 'Max Wait Time in ms';
                    ToolTip = 'Maximum wait time in milliseconds on this wait type.';
                }
                field("Signal Wait Time in ms"; Rec."Signal Wait Time in ms")
                {
                    ApplicationArea = All;
                    Caption = 'Signal Wait Time in ms';
                    ToolTip = 'Sum of the differences between the time that the waiting thread was signaled and when it started running. Measured in milliseconds.';
                }
                field("Database start time"; Rec."Database start time")
                {
                    ApplicationArea = All;
                    Caption = 'Database start time';
                    ToolTip = 'The date and time that the database was started. All numbers shown for Database Wait Statistics are collected since this time.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EmitTelemetry)
            {
                ApplicationArea = all;
                Caption = '&Emit telemetry';
                Image = Log;
                RunObject = Codeunit "Emit Database Wait Statistics";
                ToolTip = 'Emit database wait statistics to telemetry';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(EmitTelemetry_Promoted; EmitTelemetry)
                {
                }
            }
        }
    }
}