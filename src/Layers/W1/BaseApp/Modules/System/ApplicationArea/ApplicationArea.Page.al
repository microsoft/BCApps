namespace System.Environment.Configuration;

page 9179 "Application Area"
{
    ApplicationArea = All;
    Caption = 'Application Area';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Application Area Buffer";
    SourceTableTemporary = true;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Application Area"; Rec."Application Area")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the scope of the application functionality for which fields and actions are shown. Fields and action for non-selected application areas are hidden to simplify the user interface.';
                }
                field(Selected; Rec.Selected)
                {
                    ApplicationArea = All;
                    Caption = 'Show in User Interface';
                    ToolTip = 'Specifies that fields and actions for the application area are shown in the user interface.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnModifyRecord(): Boolean
    begin
        Modified := true;
    end;

    trigger OnOpenPage()
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        ApplicationAreaMgmt.GetApplicationAreaBuffer(Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if Modified then
            if TrySave() then
                Message(ReSignInMsg);
    end;

    var
        ReSignInMsg: Label 'You must sign out and then sign in again to have the changes take effect.', Comment = '"sign out" and "sign in" are the same terms as shown in the Business Central client.';
        Modified: Boolean;

    local procedure TrySave(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.TrySaveApplicationAreaCurrentCompany(Rec));
    end;
}

