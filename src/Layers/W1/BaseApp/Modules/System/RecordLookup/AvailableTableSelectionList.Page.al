namespace System.Reflection;

page 9628 "Available Table Selection List"
{
    Caption = 'Select Table';
    Editable = false;
    PageType = List;
    SourceTable = "Table Metadata";

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
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

