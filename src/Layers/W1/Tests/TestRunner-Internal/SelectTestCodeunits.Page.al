page 130022 "Select Test Codeunits"
{
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
                field("Object ID"; "Object ID")
                {
                    ApplicationArea = All;
                }
                field("Object Name"; "Object Name")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

