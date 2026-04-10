namespace System.IO;

page 8622 "Config. Related Fields"
{
    Caption = 'Config. Related Fields';
    PageType = List;
    SourceTable = "Config. Related Field";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Field ID"; Rec."Field ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the field in the related table.';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the field in the configuration table that is related to the relation table.';
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the caption of the field in the configuration table that is related to the relation table.';
                }
            }
        }
    }

    actions
    {
    }
}

