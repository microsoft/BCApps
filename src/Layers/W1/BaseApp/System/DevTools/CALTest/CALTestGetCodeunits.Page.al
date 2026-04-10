namespace System.TestTools.TestRunner;

using System.Reflection;

page 130403 "CAL Test Get Codeunits"
{
    Caption = 'CAL Test Get Codeunits';
    Editable = false;
    PageType = List;
    SourceTable = AllObjWithCaption;
    SourceTableView = where("Object Type" = const(Codeunit),
                            "Object Subtype" = const('Test'));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = All;
                }
                field("Object Name"; Rec."Object Name")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
    }
}

