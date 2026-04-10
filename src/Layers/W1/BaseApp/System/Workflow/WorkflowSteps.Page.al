namespace System.Automation;

page 1503 "Workflow Steps"
{
    Caption = 'Workflow Steps';
    Editable = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "Workflow Step Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                IndentationColumn = Rec.Indent;
                IndentationControls = "Event Description";
                field("Event Description"; Rec."Event Description")
                {
                    ApplicationArea = Suite;
                    Caption = 'When Event';
                    Lookup = false;
                    ToolTip = 'Specifies the workflow event that triggers the related workflow response.';
                }
                field("Response Description"; Rec."Response Description")
                {
                    ApplicationArea = Suite;
                    Caption = 'Then Response';
                    Lookup = false;
                    ToolTip = 'Specifies the workflow response that is that triggered by the related workflow event.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Rec.SetCurrentKey(Order);
        Rec.Ascending(true);

        exit(Rec.Find(Which));
    end;
}

