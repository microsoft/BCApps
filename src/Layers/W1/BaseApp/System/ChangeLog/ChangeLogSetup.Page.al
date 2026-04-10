namespace System.Diagnostics;

using System.DataAdministration;
using System.Environment;
using System.Utilities;

page 592 "Change Log Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Change Log Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Change Log Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                grid(GeneralGrid)
                {
                    group(GeneralColumn)
                    {
                        ShowCaption = false;
                        field("Change Log Activated"; Rec."Change Log Activated")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies that the change log is active.';
                            Caption = 'Change Log Activated';

                            trigger OnValidate()
                            begin
                                ConfirmActivationOfChangeLog();
                                ChangeLogSettingsUpdated := true;
                            end;
                        }
                        label(ChangeLogWarning)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'IMPORTANT';
                            Style = Strong;
                        }
                        label(ChangeLogWarningDescription)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Tracking changes can impact performance, which can cost you time, and increase the size of your database, which might cost you money. To reduce those costs, consider the following:';
                        }
                        label(ChangeLogWarningDescPt1)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = '- Use caution when choosing the tables and operations.';
                        }
                        label(ChangeLogWarningDescPt2)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = '- Do not add ledger entries and posted documents. Instead, prioritize system fields such as Created By and Created Date.';
                        }
                        label(ChangeLogWarningDescPt3)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = '- Do not use the All Fields tracking type. Instead, choose Some Fields and track only the most important fields.';
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Setup")
            {
                Caption = '&Setup';
                Image = Setup;
                action(Tables)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tables';
                    Image = "Table";
                    ToolTip = 'View what must be logged for each table.';

                    trigger OnAction()
                    var
                        ChangeLogSetupList: Page "Change Log Setup (Table) List";
                    begin
                        ChangeLogSetupList.SetSource();
                        ChangeLogSetupList.RunModal();
                        ChangeLogSettingsUpdated := ChangeLogSetupList.IsChangeLogSettingsUpdated();
                    end;
                }
                action(RetentionPolicy)
                {
                    ApplicationArea = All;
                    Caption = 'Retention Policy';
                    Tooltip = 'View or Edit the retention policy.';
                    Image = Delete;
                    RunObject = Page "Retention Policy Setup Card";
                    RunPageLink = "Table Id" = filter(405); // Database::"Change Log Entry";
                    AccessByPermission = tabledata "Retention Policy Setup" = R;
                    RunPageMode = View;
                    Ellipsis = true;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Setup', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Tables_Promoted; Tables)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    trigger OnClosePage()
    begin
        if ChangeLogSettingsUpdated then
            if Confirm(RestartSessionQst) then
                RestartSession();
    end;

    var
        ActivateChangeLogQst: Label 'Turning on the Change Log might slow things down, especially if you are monitoring entities that often change. Do you want to log changes?';
        RestartSessionQst: Label 'Changes are displayed on the Change Log Entries page after the user''s session has restarted. Do you want to restart the session now?';
        ChangeLogSettingsUpdated: Boolean;

    local procedure ConfirmActivationOfChangeLog()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not Rec."Change Log Activated" then
            exit;
        if not EnvironmentInfo.IsSaaS() then
            exit;
        if not ConfirmManagement.GetResponseOrDefault(ActivateChangeLogQst, true) then
            Error('');
    end;

    local procedure RestartSession()
    var
        SessionSetting: SessionSettings;
    begin
        SessionSetting.Init();
        SessionSetting.RequestSessionUpdate(false);
    end;

}

