namespace System.Threading;

using System.Azure.Identity;
using System.Environment;

page 3845 "Scheduled Tasks"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Scheduled Task";
    Editable = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            group(Information)
            {
                field("Current Tenant ID"; Database.TenantId())
                {
                    ApplicationArea = All;
                    Caption = 'Current Tenant ID';
                    ToolTip = 'Specifies the tenant ID of the current environment.';
                }

                field("Current Company"; CompanyName())
                {
                    ApplicationArea = All;
                    Caption = 'Current Company Name';
                    ToolTip = 'Specifies the current company name.';
                }
            }

            repeater(General)
            {
                field(ID; Rec.ID)
                {
                    ApplicationArea = All;
                    Caption = 'ID';
                    Visible = false;
                    ToolTip = 'Specifies the ID of the scheduled task.';
                }
                field("Is Ready"; Rec."Is Ready")
                {
                    ApplicationArea = All;
                    Caption = 'Is Ready';
                    ToolTip = 'Specifies whether the task has been scheduled.';
                }
                field("User Name"; Rec."User Name")
                {
                    ApplicationArea = All;
                    Caption = 'User ID';
                    ToolTip = 'Specifies the username of the user who scheduled the task.';
                }
                field("Run Codeunit"; Rec."Run Codeunit")
                {
                    ApplicationArea = All;
                    Caption = 'Codeunit ID';
                    ToolTip = 'Specifies the ID of the codeunit to run.';
                }
                field("Failure Codeunit"; Rec."Failure Codeunit")
                {
                    ApplicationArea = All;
                    Caption = 'Failure Codeunit ID';
                    ToolTip = 'Specifies the ID of a backup codeunit to run if the codeunit specified for the task fails.';
                }
                field("Company Name"; Rec.Company)
                {
                    ApplicationArea = All;
                    Caption = 'Company Name';
                    ToolTip = 'Specifies the company name for which this task was scheduled.';
                }
                field("Is Tenant Specific"; ScheduledTasks.IsTenantSpecific(Rec))
                {
                    ApplicationArea = All;
                    Caption = 'Is Tenant Specific';
                    ToolTip = 'Specifies whether the scheduled task is only for the current tenant.';
                }
                field("Tenant ID"; Rec."Tenant ID")
                {
                    ApplicationArea = All;
                    Caption = 'Tenant ID';
                    ToolTip = 'Specifies the ID of the tenant for which this task was scheduled.';
                    Visible = false;
                }
            }
        }
        area(FactBoxes)
        {
            part("JQ Factbox"; "Scheduled Task JQ Factbox")
            {
                ApplicationArea = All;
                Caption = 'Job Queue';
                Editable = false;
                SubPageLink = "System Task ID" = field(ID);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Cancel Task")
            {
                ApplicationArea = All;
                Caption = 'Cancel Task';
                ToolTip = 'Cancel and delete the selected tasks. If the tasks are related to a job queue entry, the entry will be put on hold. ';
                Visible = IsAdmin;

                trigger OnAction()
                var
                    ScheduledTask: Record "Scheduled Task";
                begin
                    if not GetMarkedTasks(ScheduledTask) then
                        exit;

                    ScheduledTasks.CancelTasks(ScheduledTask);

                    CurrPage.Update();
                end;
            }

            action("Set Task Ready")
            {
                ApplicationArea = All;
                Caption = 'Set Task Ready';
                ToolTip = 'Set the task as ready to run. It will run according to its schedule. If the task is related to a job queue entry, the status of the entry will also change to Ready. ';
                Visible = IsAdmin;

                trigger OnAction()
                var
                    ScheduledTask: Record "Scheduled Task";
                begin
                    if not GetMarkedTasks(ScheduledTask) then
                        exit;

                    ScheduledTasks.SetTasksReady(ScheduledTask);

                    CurrPage.Update();
                end;
            }
        }
    }

    var
        ScheduledTasks: Codeunit "Scheduled Tasks";
        IsAdmin: Boolean;

    trigger OnOpenPage()
    var
        AzureUserMgt: Codeunit "Azure AD User Management";
        JobQueueManagement: Codeunit "Job Queue Management";
    begin
        IsAdmin := AzureUserMgt.IsUserTenantAdmin();
        JobQueueManagement.TooManyScheduledTasksNotification();
    end;

    local procedure GetMarkedTasks(var ScheduledTask: Record "Scheduled Task"): Boolean
    begin
        CurrPage.SetSelectionFilter(ScheduledTask);
        exit(ScheduledTask.FindSet());
    end;
}