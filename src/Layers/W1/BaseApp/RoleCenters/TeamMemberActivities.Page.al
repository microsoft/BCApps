// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Projects.TimeSheet;
using System;
using System.Environment.Configuration;
#if not CLEAN28
using System.Feedback;
#endif
using System.Telemetry;

page 9042 "Team Member Activities"
{
    Caption = 'Self-Service';
    PageType = CardPart;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "Team Member Cue";

    layout
    {
        area(content)
        {
            cuegroup("Current Time Sheet")
            {
                Caption = 'Current Time Sheet';
                actions
                {
                    action(OpenCurrentTimeSheet)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Open My Current Time Sheet';
                        Image = TileBrickCalendar;
                        ToolTip = 'Open the time sheet for the current period. Current period is based on work date set in my settings.';

                        trigger OnAction()
                        var
                            TimeSheetHeader: Record "Time Sheet Header";
                            TimeSheetManagement: Codeunit "Time Sheet Management";
                            FeatureTelemetry: Codeunit "Feature Telemetry";
                            TimeSheetCard: Page "Time Sheet Card";
                            TimeSheetList: Page "Time Sheet List";
                        begin
                            TimeSheetManagement.FilterTimeSheets(TimeSheetHeader, TimeSheetHeader.FieldNo("Owner User ID"), true);
                            TimeSheetCard.SetTableView(TimeSheetHeader);
                            if TimeSheetHeader.Get(TimeSheetHeader.FindCurrentTimeSheetNo(TimeSheetHeader.FieldNo("Owner User ID"))) then begin
                                TimeSheetCard.SetRecord(TimeSheetHeader);
                                TimeSheetCard.Run();
                            end else begin
                                TimeSheetHeader.Reset();
                                TimeSheetManagement.FilterTimeSheets(TimeSheetHeader, TimeSheetHeader.FieldNo("Owner User ID"), true);
                                TimeSheetList.SetTableView(TimeSheetHeader);
                                TimeSheetList.SetRecord(TimeSheetHeader);
                                TimeSheetList.Run();
                            end;
                            FeatureTelemetry.LogUsage('0000JQU', 'NewTimeSheetExperience', 'Current Time Sheet opened from Self-Service part of the Role Center');
                        end;
                    }
                }
            }
            cuegroup("Time Sheets")
            {
                Caption = 'Time Sheets';
                field("New Time Sheets"; Rec."New Time Sheets")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Time Sheet List";
                    ToolTip = 'Specifies the number of time sheets that are currently assigned to you, without lines.';
                }
                field("Open Time Sheets"; Rec.CountTimeSheetsInStatus(UserFilterOption::Owner, "Time Sheet Status"::Open))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Time Sheets In progress';
                    ToolTip = 'Specifies the number of time sheets that are currently assigned to you, have open lines and not submitted for approval.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownToTimeSheetList(UserFilterOption::Owner, "Time Sheet Status"::Open);
                    end;
                }
            }
            cuegroup("Pending Time Sheets")
            {
                Caption = 'Pending Time Sheets';
                field("Submitted Time Sheets"; Rec.CountTimeSheetsInStatus(UserFilterOption::Owner, "Time Sheet Status"::Submitted))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Submitted Time Sheets';
                    ToolTip = 'Specifies the number of time sheets that you have submitted for approval but are not yet approved.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownToTimeSheetList(UserFilterOption::Owner, "Time Sheet Status"::Submitted);
                    end;
                }
                field("Rejected Time Sheets"; Rec.CountTimeSheetsInStatus(UserFilterOption::Owner, "Time Sheet Status"::Rejected))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rejected Time Sheets';
                    ToolTip = 'Specifies the number of time sheets that you submitted for approval but were rejected.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownToTimeSheetList(UserFilterOption::Owner, "Time Sheet Status"::Rejected);
                    end;
                }
                field("Approved Time Sheets"; Rec.CountTimeSheetsInStatus(UserFilterOption::Owner, "Time Sheet Status"::Approved))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approved Time Sheets';
                    ToolTip = 'Specifies the number of time sheets that have been approved.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownToTimeSheetList(UserFilterOption::Owner, "Time Sheet Status"::Approved);
                    end;
                }
            }
            cuegroup(Approvals)
            {
                Caption = 'Approvals';
                field("Time Sheets to Approve"; Rec.CountTimeSheetsInStatus(UserFilterOption::Approver, "Time Sheet Status"::Submitted))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Time Sheets to Approve';
                    ToolTip = 'Specifies the number of time sheets that need to be approved.';
                    Visible = ShowTimeSheetsToApprove;

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownToTimeSheetList(UserFilterOption::Approver, "Time Sheet Status"::Submitted);
                    end;
                }
            }
#if not CLEAN28
            usercontrol(SATAsyncLoader; SatisfactionSurveyAsync)
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
                ObsoleteReason = 'The Satisfaction Survey feature will be removed in a future release.';
                ObsoleteState = Pending;
                ObsoleteTag = '28.0';
            }
#endif
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        Rec.Initialize();

        Rec.SetDefaultFilters(ShowTimeSheetsToApprove);

        RoleCenterNotificationMgt.ShowNotifications();
        ConfPersonalizationMgt.RaiseOnOpenRoleCenterEvent();

        if PageNotifier.IsAvailable() then begin
            PageNotifier := PageNotifier.Create();
            PageNotifier.NotifyPageReady();
        end;
    end;

    var
        [RunOnClient]
        [WithEvents]
        PageNotifier: DotNet PageNotifier;
        ShowTimeSheetsToApprove: Boolean;
        UserFilterOption: Option Owner,Approver;
}

