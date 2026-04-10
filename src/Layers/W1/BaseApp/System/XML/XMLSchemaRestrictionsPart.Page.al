namespace System.Xml;

page 9611 "XML Schema Restrictions Part"
{
    Caption = 'XML Schema Restrictions Part';
    Editable = false;
    PageType = ListPart;
    SourceTable = "XML Schema Restriction";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Value; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the imported record.';
                }
            }
        }
    }

    actions
    {
    }
}

