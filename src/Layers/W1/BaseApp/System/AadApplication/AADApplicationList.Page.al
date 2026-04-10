namespace System.Environment.Configuration;

using System.Security.AccessControl;

page 9860 "AAD Application List"
{
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    Caption = 'Microsoft Entra Applications';
    CardPageId = "AAD Application Card";
    PageType = List;
    PopulateAllFields = true;
    Editable = false;
    SourceTable = "AAD Application";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Client ID"; Rec."Client Id")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    Caption = 'Client ID';
                    ToolTip = 'Specifies the client ID of the app that the entry is for.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the app that the entry is for.';
                }
                field(State; Rec.State)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'State';
                    ToolTip = 'Specifies if the app is enabled or disabled.';
                }
                field("User Telemetry Id"; TelemetryUserId)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Telemetry ID';
                    ToolTip = 'Specifies a telemetry ID assigned to the app which can be used for troubleshooting purposes.';
                    Visible = false;
                }
            }
        }
    }
    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        User: Record User;
        UserProperty: Record "User Property";
    begin
        Clear(TelemetryUserId);
        if User.Get(Rec."User Id") then
            if UserProperty.Get(User."User Security ID") then
                TelemetryUserId := UserProperty."Telemetry User ID"
    end;

    var
        TelemetryUserId: Guid;
}