namespace System.Diagnostics;

using System.DataAdministration;
using System.Security.User;

page 595 "Change Log Entries"
{
    AdditionalSearchTerms = 'user log,user activity,track';
    ApplicationArea = Basic, Suite;
    Caption = 'Change Log Entries';
    Editable = false;
    PageType = List;
    AboutTitle = 'About Change Log Entries';
    AboutText = 'Track, review, and analyze all changes made to tables and fields in Business Central, including details of who made each change, when it occurred, the type of change, and the old and new values, to support efficient monitoring and auditing of system activity.';
    SourceTable = "Change Log Entry";
    SourceTableView = where("Field Log Entry Feature" = filter("Change Log" | All));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                    Visible = false;
                }
                field("Date and Time"; Rec."Date and Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time when this change log entry was created.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Table No."; Rec."Table No.")
                {
                    ApplicationArea = Basic, Suite;
                    Lookup = false;
                    ToolTip = 'Specifies the number of the table containing the changed field.';
                    Visible = false;
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the table containing the changed field.';

                    trigger OnDrillDown()
                    var
                        MonitorSensitiveFieldData: Codeunit "Monitor Sensitive Field Data";
                    begin
                        if not IsNullGuid(Rec."Changed Record SystemId") then
                            MonitorSensitiveFieldData.OpenChangedRecordPage(Rec."Table No.", Rec."Field No.", Rec."Changed Record SystemId");
                    end;
                }
                field("Primary Key"; Rec."Primary Key")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the primary key or keys of the changed field.';
                    Visible = false;
                }
                field("Primary Key Field 1 No."; Rec."Primary Key Field 1 No.")
                {
                    ApplicationArea = Basic, Suite;
                    Lookup = false;
                    ToolTip = 'Specifies the field number of the first primary key for the changed field.';
                    Visible = false;
                }
                field("Primary Key Field 1 Caption"; Rec."Primary Key Field 1 Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the field name of the first primary key for the changed field.';
                    Visible = false;
                }
                field("Primary Key Field 1 Value"; Rec."Primary Key Field 1 Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the first primary key for the changed field.';
                }
                field("Primary Key Field 2 No."; Rec."Primary Key Field 2 No.")
                {
                    ApplicationArea = Basic, Suite;
                    Lookup = false;
                    ToolTip = 'Specifies the field number of the second primary key for the changed field.';
                    Visible = false;
                }
                field("Primary Key Field 2 Caption"; Rec."Primary Key Field 2 Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the field name of the second primary key for the changed field.';
                    Visible = false;
                }
                field("Primary Key Field 2 Value"; Rec."Primary Key Field 2 Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the second primary key for the changed field.';
                }
                field("Primary Key Field 3 No."; Rec."Primary Key Field 3 No.")
                {
                    ApplicationArea = Basic, Suite;
                    Lookup = false;
                    ToolTip = 'Specifies the field number of the third primary key for the changed field.';
                    Visible = false;
                }
                field("Primary Key Field 3 Caption"; Rec."Primary Key Field 3 Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the field name of the third primary key for the changed field.';
                    Visible = false;
                }
                field("Primary Key Field 3 Value"; Rec."Primary Key Field 3 Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the third primary key for the changed field.';
                }
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = Basic, Suite;
                    Lookup = false;
                    ToolTip = 'Specifies the field number of the changed field.';
                    Visible = false;
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the field caption of the changed field.';
                }
                field("Type of Change"; Rec."Type of Change")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of change made to the field.';
                }
                field("Old Value"; Rec."Old Value")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Old Value Local"; Rec.GetLocalOldValue())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Old Value (Local)';
                    ToolTip = 'Specifies the value that the field had before a user made changes to the field.';
                }
                field("New Value"; Rec."New Value")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("New Value Local"; Rec.GetLocalNewValue())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New Value (Local)';
                    ToolTip = 'Specifies the value that the field had after a user made changes to the field.';
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
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    REPORT.Run(REPORT::"Change Log Entries", true, false, Rec);
                end;
            }
            action(Setup)
            {
                ApplicationArea = All;
                Caption = 'Setup';
                Image = Setup;
                RunObject = Page "Change Log Setup";
                ToolTip = 'Enable, disable or setup change logging.';
            }
            action(RetentionPolicy)
            {
                ApplicationArea = All;
                Caption = 'Retention Policy';
                Tooltip = 'View or Edit the retention policy.';
                Image = Delete;
                RunObject = Page "Retention Policy Setup Card";
                RunPageView = where("Table Id" = const(405)); // Database::"Change Log Entry";
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

                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref(Setup_Promoted; Setup)
                {
                }
            }
        }
    }
}

