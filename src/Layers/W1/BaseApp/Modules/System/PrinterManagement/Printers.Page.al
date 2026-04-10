namespace System.Device;

page 356 Printers
{
    Caption = 'Printers';
    Editable = false;
    PageType = List;
    SourceTable = Printer;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID that applies.';
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
    }
}

