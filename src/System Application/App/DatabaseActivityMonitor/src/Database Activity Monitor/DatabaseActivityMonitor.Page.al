// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// Database Activity Monitor
/// </summary>
page 6281 "Database Activity Monitor"
{
    Caption = 'Database Activity Monitor';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    AboutTitle = ''; // TODO: Add
    AboutText = ''; // TODO: Add

    layout
    {
        area(Content)
        {
            group(MonitorInactive)
            {
                ShowCaption = false;
                Visible = not (IsDataPresent or IsMonitorActive);

                group(Info)
                {
                    ShowCaption = false;

                    label("Troubleshoot")
                    {
                        ApplicationArea = All;
                        Caption = 'Troubleshoot database activity';
                        Style = Strong;
                    }
                    label("Use Start and Stop")
                    {
                        ApplicationArea = All;
                        Caption = 'Use the Start and Stop buttons to record database activities. The activity log will show details.';
                    }
                }
            }
            group(MonitorActive)
            {
                Visible = IsMonitorActive;
                ShowCaption = false;

                group(MonitorIsRunning)
                {
                    ShowCaption = false;

                    label("Monitor is running")
                    {
                        ApplicationArea = All;
                        Caption = 'The database activity monitor is now running';
                        Style = Strong;
                    }
                    label(Instructions)
                    {
                        ApplicationArea = All;
                        Caption = 'Use the Stop button to stop monitoring. The monitor will automatically stop monitoring after the specified recording time.';
                    }
                }
            }

            group(MonitorCompleted)
            {
                Visible = IsDataPresent and not IsMonitorActive;
                ShowCaption = false;

                group(MonitorIsDone)
                {
                    ShowCaption = false;

                    label("Monitor completed")
                    {
                        ApplicationArea = All;
                        Caption = 'The database activity monitor has completed. ';
                        Style = Strong;
                    }
                    label("Instructions Completed")
                    {
                        ApplicationArea = All;
                        Caption = 'Download the log to analyze the activities. Use the Clear button to clear the log and start a new recording.';
                    }
                }
            }

            part("Database Activity Log"; "Database Activity Log")
            {
                ApplicationArea = All;
                Caption = 'Database Activities';
                Editable = false;
                Visible = IsMonitorActive or IsDataPresent;
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Start)
            {
                ApplicationArea = All;
                Image = Start;
                Enabled = IsStartEnabled;
                Caption = 'Start';
                ToolTip = 'Start the database activity monitor.';
                AboutTitle = 'Starting the recording';
                AboutText = 'The most convenient way of interacting with the performance profiler is by having it in a separate browser window next to your main Business Central browser window. Once your windows are conveniently docked, you can start the performance profiler recording.';

                trigger OnAction()
                begin
                    // TODO: Log uptake
                    DatabaseActivityMonitor.Start();
                    UpdateControls();
                end;
            }
            action(Stop)
            {
                ApplicationArea = All;
                Image = Stop;
                Enabled = IsMonitorActive;
                Caption = 'Stop';
                ToolTip = 'Stop the performance profiler recording.';
                AboutTitle = 'Stopping the recording';
                AboutText = 'After you have run the scenario, stop the recording. The page is updated with information about which apps were taking time during the process. Use this information to reach out to the relevant extension publisher for help with your performance issue, for example.';

                trigger OnAction()
                begin
                    DatabaseActivityMonitor.Stop();
                    UpdateControls();
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Image = Refresh;
                Enabled = IsRefreshEnabled;
                Caption = 'Refresh';
                ToolTip = 'Refresh page.';

                trigger OnAction()
                begin
                    UpdateControls();
                    CurrPage.Update();
                end;
            }
            action(Clear)
            {
                ApplicationArea = All;
                Image = ClearLog;
                Enabled = IsClearEnabled;
                Caption = 'Clear';
                ToolTip = 'Clear the log of activities.';

                trigger OnAction()
                begin
                    DatabaseActivityMonitor.ClearLog();
                    UpdateControls();
                end;
            }
            action(DownloadAsExcel)
            {
                ApplicationArea = All;
                Image = Download;
                Enabled = IsDownloadEnabled;
                Caption = 'Download';
                ToolTip = 'Download the list as Excel.';
                trigger OnAction()
                begin
                    Report.Run(Report::"Database Activity Log");
                end;
            }
            action(Settings)
            {
                ApplicationArea = All;
                Image = Setup;
                Enabled = IsStartEnabled;
                Caption = 'Settings';
                ToolTip = 'Specify the configuration of the database monitoring.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Database Act. Monitor Setup");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Start_Promoted; Start)
                {
                }
                actionref(Stop_Promoted; Stop)
                {
                }
                actionref(Clear_Promoted; Clear)
                {
                }
                actionref(DownloadAsExcel_Promoted; DownloadAsExcel)
                {
                }
                actionref(Refresh_Promoted; Refresh)
                {
                }
                actionref(Settings_Promoted; Settings)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        UpdateControls();
    end;

    local procedure UpdateControls()
    begin
        // TODO: log uptake

        IsDataPresent := DatabaseActivityMonitor.IsInitialized();
        IsMonitorActive := DatabaseActivityMonitor.IsMonitorActive();
        IsStartEnabled := not (IsDataPresent or IsMonitorActive);
        IsRefreshEnabled := IsMonitorActive;
        IsClearEnabled := IsDataPresent and not IsMonitorActive;
        IsDownloadEnabled := IsDataPresent and not IsMonitorActive;
    end;

    var
        DatabaseActivityMonitor: Codeunit "Database Activity Monitor";
        IsDataPresent: Boolean;
        IsStartEnabled: Boolean;
        IsMonitorActive: Boolean;
        IsClearEnabled: Boolean;
        IsDownloadEnabled: Boolean;
        IsRefreshEnabled: Boolean;
}