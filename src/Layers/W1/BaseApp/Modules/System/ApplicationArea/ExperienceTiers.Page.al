namespace System.Environment.Configuration;

page 9195 "Experience Tiers"
{
    Caption = 'Experience Tiers';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Experience Tier Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Experience Tier"; Rec."Experience Tier")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the scope of the application functionality for which fields and actions are shown. Fields and action for non-selected application areas are hidden to simplify the user interface.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        if CloseAction = ACTION::LookupOK then
            exit(ApplicationAreaMgmtFacade.IsValidExperienceTierSelected(Rec."Experience Tier"));

        exit(true);
    end;
}

