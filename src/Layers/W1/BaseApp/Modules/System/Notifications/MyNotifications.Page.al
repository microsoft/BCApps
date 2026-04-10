namespace System.Environment.Configuration;

page 1518 "My Notifications"
{
    ApplicationArea = All;
    Caption = 'My Notifications';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    Permissions = TableData "My Notifications" = rimd;
    SourceTable = "My Notifications";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the short name of the notification. To see a description of the notification, choose the name.';

                    trigger OnDrillDown()
                    begin
                        Message(Rec.GetDescription());
                    end;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that notifications are enabled.';

                    trigger OnValidate()
                    begin
                        if Rec.Enabled <> xRec.Enabled then begin
                            Filters := Rec.GetFiltersAsDisplayText();
                            CurrPage.Update();
                        end;
                    end;
                }
                field(Filters; Filters)
                {
                    ApplicationArea = All;
                    Caption = 'Conditions';
                    Editable = false;
                    ToolTip = 'Specifies the conditions under which I get notifications. ';

                    trigger OnDrillDown()
                    begin
                        if Rec.OpenFilterSettings() then begin
                            Filters := Rec.GetFiltersAsDisplayText();
                            CurrPage.Update();
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Filters := Rec.GetFiltersAsDisplayText();
    end;

    trigger OnOpenPage()
    begin
        OnInitializingNotificationWithDefaultState();
        Rec.SetRange("User Id", UserId);
    end;

    var
        Filters: Text;

    procedure InitializeNotificationsWithDefaultState()
    begin
        OnInitializingNotificationWithDefaultState();
        OnAfterInitializingNotificationWithDefaultState();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitializingNotificationWithDefaultState()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializingNotificationWithDefaultState()
    begin
    end;
}

