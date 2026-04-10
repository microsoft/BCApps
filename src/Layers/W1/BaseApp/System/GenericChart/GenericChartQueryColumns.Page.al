namespace System.Visualization;

page 9186 "Generic Chart Query Columns"
{
    Caption = 'Generic Chart Query Columns';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Generic Chart Query Column";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Query No."; Rec."Query No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the query that is used to generate column data in the chart.';
                }
                field("Query Column No."; Rec."Query Column No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the query column that is used to generate column data in the chart.';
                }
                field("Column Name"; Rec."Column Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the query that is used to generate column data in the chart.';
                }
            }
        }
    }

    actions
    {
    }
}

