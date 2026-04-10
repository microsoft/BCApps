namespace System.Reflection;

page 9629 "Available Field Selection Page"
{
    Caption = 'Select Field';
    Editable = false;
    PageType = List;
    SourceTable = "Field";

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the names of the available Windows languages.';
                }
            }
        }
    }

    actions
    {
    }
}

