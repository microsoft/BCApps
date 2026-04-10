#pragma warning disable AA0247
page 26554 "Report Table Columns"
{
    AutoSplitKey = true;
    Caption = 'Report Table Columns';
    DataCaptionFields = "Table Code";
    PageType = List;
    SourceTable = "Stat. Report Table Column";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Column Header"; Rec."Column Header")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the column header associated with the statutory report table column.';
                }
                field("Column No."; Rec."Column No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number for the column in the view.';
                }
                field("Excel Column Name"; Rec."Excel Column Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Microsoft Excel column name associated with the statutory report table column.';
                }
                field("Vert. Table Row Shift"; Rec."Vert. Table Row Shift")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vertical table row shift associated with the statutory report table column.';
                }
            }
        }
    }

    actions
    {
    }
}

