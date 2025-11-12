// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Task;

using System.Environment;
using System.Environment.Configuration;

page 1164 "User Task List Part"
{
    // // Supports 3 modes. Default mode is NONE.
    // // NONE :- All pending tasks assigned to logged in user or their groups.
    // // TODAY :- All pending tasks assigned to logged in user or their groups due today.
    // // THIS_WEEK :- All pending tasks assigned to logged in user or their groups due this week.

    Caption = 'User Task List Part';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "User Task";

    layout
    {
        area(content)
        {
            repeater(Control12)
            {
                ShowCaption = false;
                field(Title; Rec.Title)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the task.';

                    trigger OnDrillDown()
                    var
                        Company: Record Company;
                        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
                        HyperLinkUrl: Text[500];
                    begin
                        Company.Get(CompanyName);
                        if Company."Evaluation Company" then
                            HyperLinkUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 1171, Rec)
                            + '&' + ConfPersonalizationMgt.GetProfileUrlParameterForEvaluationCompany()
                            + '&mode=Edit'
                        else
                            HyperLinkUrl := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 1171, Rec)
                            + '&mode=Edit';
                        HyperLink(HyperLinkUrl);
                    end;
                }
                field("Due DateTime"; Rec."Due DateTime")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies when the task must be completed.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the priority of the task compared to other tasks. Enter any number.';
                }
                field("Percent Complete"; Rec."Percent Complete")
                {
                    ApplicationArea = All;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies how much of the task has been completed.';
                }
                field("Assigned To User Name"; Rec."Assigned To User Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies who performs the task.';
                }
                field("Created DateTime"; Rec."Created DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the task was created.';
                }
                field("User Task Group Assigned To"; Rec."User Task Group Assigned To")
                {
                    ApplicationArea = All;
                    Caption = 'User Task Group';
                    ToolTip = 'Specifies the group that the task belongs to.';
                }
                field("Completed DateTime"; Rec."Completed DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the task was completed.';
                    Visible = false;
                }
                field("Start DateTime"; Rec."Start DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the task was started.';
                    Visible = false;
                }
                field("Created By User Name"; Rec."Created By User Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies who created the task.';
                    Visible = false;
                }
                field("Completed By User Name"; Rec."Completed By User Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies who completed the task.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        StyleTxt := Rec.SetStyle();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        SetFilterBasedOnMode();
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        SetFilterBasedOnMode();
        exit(Rec.Next(Steps));
    end;

    var
        UserTaskManagement: Codeunit "User Task Management";
        StyleTxt: Text;
        PageMode: Integer;
        DueDateFilterOptions: Option "NONE",TODAY,THIS_WEEK;

    procedure SetFilterForPendingTasks()
    begin
        // Sets filter to show all pending tasks assigned to logged in user or their groups.
        PageMode := DueDateFilterOptions::NONE;
        CurrPage.Update(false);
    end;

    procedure SetFilterForTasksDueToday()
    begin
        // Sets filter to show all pending tasks assigned to logged in user or their groups that are due today.
        PageMode := DueDateFilterOptions::TODAY;
        CurrPage.Update(false);
    end;

    procedure SetFilterForTasksDueThisWeek()
    begin
        // Sets filter to show all pending tasks assigned to logged in user or their groups that are due this week.
        PageMode := DueDateFilterOptions::THIS_WEEK;
        CurrPage.Update(false);
    end;

    local procedure SetFilterBasedOnMode()
    begin
        case PageMode of
            DueDateFilterOptions::NONE:
                UserTaskManagement.SetFiltersToShowMyUserTasks(Rec, DueDateFilterOptions::NONE);
            DueDateFilterOptions::THIS_WEEK:
                UserTaskManagement.SetFiltersToShowMyUserTasks(Rec, DueDateFilterOptions::THIS_WEEK);
            DueDateFilterOptions::TODAY:
                UserTaskManagement.SetFiltersToShowMyUserTasks(Rec, DueDateFilterOptions::TODAY);
        end;
    end;
}

