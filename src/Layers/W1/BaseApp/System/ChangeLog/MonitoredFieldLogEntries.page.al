namespace System.Diagnostics;

using System.DataAdministration;

page 1367 "Monitored Field Log Entries"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    SourceTable = "Change Log Entry";
    SourceTableView = sorting("Entry No.")
                      order(descending)
                      where("Field Log Entry Feature" = filter("Monitor Sensitive Fields" | All));
    Editable = false;
    Extensible = false;
    AccessByPermission = tabledata "Field Monitoring Setup" = M;
    Caption = 'Monitored Field Log Entries';

    layout
    {
        area(Content)
        {
            repeater(group)
            {
                field("Change Timestamp"; Rec."Date and Time")
                {
                    ToolTip = 'Specifies the data and time when the change occurred.';
                    ApplicationArea = Basic, Suite;
                }
                field("Modified By"; Rec."User ID")
                {
                    ToolTip = 'Specifies the username of the person who changed the value in the monitored field.';
                    ApplicationArea = Basic, Suite;
                }
                field("Table No"; Rec."Table No.")
                {
                    ToolTip = 'Specifies the identifier of the table that includes the monitored field.';
                    ApplicationArea = Basic, Suite;
                    trigger OnDrillDown()
                    begin
                        MonitorSensitiveFieldData.OpenChangedRecordPage(Rec."Table No.", Rec."Field No.", Rec."Changed Record SystemId");
                    end;
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ToolTip = 'Specifies the name of the table that includes the monitored field.';
                    ApplicationArea = Basic, Suite;
                }
                field("Field No"; Rec."Field No.")
                {
                    ToolTip = 'Specifies the identifier of the field that is being monitored.';
                    ApplicationArea = Basic, Suite;
                    Enabled = false;
                    DrillDown = false;
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ToolTip = 'Specifies the name of the field that is being monitored.';
                    ApplicationArea = Basic, Suite;
                }
                field("Notification Status"; Rec."Notification Status")
                {
                    ToolTip = 'Specifies whether notification was sent, failed or was turned off';
                    ApplicationArea = Basic, Suite;
                }
                field("Type of Change"; Rec."Type of Change")
                {
                    ToolTip = 'Specifies type of change';
                    ApplicationArea = Basic, Suite;
                }
                field("Original Value"; Rec.GetLocalOldValue())
                {
                    Caption = 'Original Value';
                    ToolTip = 'Specifies the value that was changed. To see the new value, choose the line.';
                    ApplicationArea = Basic, Suite;
                }
                field("New Value"; Rec.GetLocalNewValue())
                {
                    Caption = 'New Value';
                    ToolTip = 'Specifies new value of the field';
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Show Monitoring Setup Entries")
            {
                ToolTip = 'Show entries for changes that were made to fields that you are monitoring.';
                ApplicationArea = Basic, Suite;
                Image = Start;
                Visible = not IsMonitoredFieldsEntriesShown;
                Caption = 'Show Monitored Field Entries';

                trigger OnAction()
                begin
                    Rec.SetFilter("Table No.", '');
                    IsMonitoredFieldsEntriesShown := true;
                end;
            }

            action("Hide Monitoring Setup Entries")
            {
                ToolTip = 'Hide entries for changes that were made to fields that you are monitoring.';
                ApplicationArea = Basic, Suite;
                Image = Start;
                Visible = IsMonitoredFieldsEntriesShown;
                Caption = 'Hide Monitored Field Entries';

                trigger OnAction()
                begin
                    Rec.SetFilter("Table No.", '<>%1', Database::"Change Log Setup (Field)");
                    IsMonitoredFieldsEntriesShown := false;
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

                actionref("Show Monitoring Setup Entries_Promoted"; "Show Monitoring Setup Entries")
                {
                }
                actionref("Hide Monitoring Setup Entries_Promoted"; "Hide Monitoring Setup Entries")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        MonitorSensitiveFieldData.ResetNotificationCount();
        Rec.SetFilter("Table No.", '<>%1', Database::"Change Log Setup (Field)");
        IsMonitoredFieldsEntriesShown := false;
    end;

    var
        MonitorSensitiveFieldData: Codeunit "Monitor Sensitive Field Data";
        IsMonitoredFieldsEntriesShown: Boolean;
}