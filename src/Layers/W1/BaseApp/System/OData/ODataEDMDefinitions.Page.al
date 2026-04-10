namespace System.Integration;

page 6725 "OData EDM Definitions"
{
    Caption = 'OData EDM Definitions';
    CardPageID = "OData EDM Definition Card";
    PageType = List;
    SourceTable = "OData Edm Type";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Key"; Rec.Key)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the Open Data Protocol EDM definition.';
                }
            }
        }
    }

    actions
    {
    }
}

