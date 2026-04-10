namespace System.Automation;

page 6415 "Flow Service Configuration"
{
    Caption = 'Power Automate Service Configuration';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = NavigatePage;
    Permissions = TableData "Flow Service Configuration" = rimd;
    SourceTable = "Flow Service Configuration";

    layout
    {
        area(content)
        {
            field("Flow Service"; Rec."Flow Service")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Power Automate Service';
                ToolTip = 'Specifies the Power Automate service configuration: Production Service, Testing Service (TIP 1), or Testing Service (TIP 2).';
            }
        }
    }

    actions
    {
    }

    trigger OnModifyRecord(): Boolean
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
    begin
        if FlowUserEnvironmentConfig.Get(UserSecurityId()) then
            FlowUserEnvironmentConfig.Delete();
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

