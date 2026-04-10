namespace System.Diagnostics;

using System.DataAdministration;
using System.Email;

page 1366 "Field Monitoring Setup"
{
    PageType = Card;
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    SourceTable = "Field Monitoring Setup";
    DeleteAllowed = false;
    InsertAllowed = false;
    Extensible = false;
    AccessByPermission = tabledata "Field Monitoring Setup" = M;
    RefreshOnActivate = true;
    Caption = 'Field Monitoring Setup';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("User ID"; Rec."User Id")
                {
                    ToolTip = 'Specifies the user ID';
                    ApplicationArea = Basic, Suite;
                }
                group(Email)
                {
                    ShowCaption = false;
                    field("Email Account Name"; Rec."Email Account Name")
                    {
                        ToolTip = 'Specifies the email account that will send the notification email. Typically, this is a system account that is not associated with a user.';
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        Caption = 'Notification Email Account';

                        trigger OnAssistEdit()
                        var
                            TempEmailAccount: Record "Email Account" temporary;
                        begin
                            if Page.RunModal(Page::"Email Accounts", TempEmailAccount) = Action::LookupOK then begin
                                Rec."Email Account Id" := TempEmailAccount."Account Id";
                                Rec."Email Account Name" := TempEmailAccount.Name;
                                Rec."Email Connector" := TempEmailAccount.Connector;
                            end;
                        end;
                    }
                }

                field("Monitor Status"; Rec."Monitor Status")
                {
                    ToolTip = 'Specifies the monitor status';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Enabled = false;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Start")
            {
                ToolTip = 'Start monitoring fields for changes.';
                ApplicationArea = Basic, Suite;
                Image = Start;
                Enabled = not IsMonitorEnabled;

                trigger OnAction()
                begin
                    MonitorSensitiveField.EnableMonitor(true);
                end;
            }
            action("Stop")
            {
                ToolTip = 'Stop monitoring fields for changes.';
                ApplicationArea = Basic, Suite;
                Image = Stop;
                Enabled = IsMonitorEnabled;

                trigger OnAction()
                begin
                    MonitorSensitiveField.DisableMonitor();
                end;
            }
            action(RetentionPolicy)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Retention Policy';
                Tooltip = 'View or edit the retention policy.';
                Image = Delete;
                RunObject = Page "Retention Policy Setup Card";
                RunPageLink = "Table Id" = filter(405); // Database::"Change Log Entry";
                AccessByPermission = tabledata "Retention Policy Setup" = R;
                RunPageMode = View;
                Ellipsis = true;
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
            }
        }
    }

    var
        MonitorSensitiveField: Codeunit "Monitor Sensitive Field";
        IsMonitorEnabled: Boolean;

    trigger OnOpenPage()
    begin
        MonitorSensitiveField.GetSetupTable(Rec);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        IsMonitorEnabled := Rec."Monitor Status";
    end;
}