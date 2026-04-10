#pragma warning disable AA0247
page 26579 "Select Excel Sheet Name"
{
    Caption = 'Select Excel Sheet Name';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Stat. Report Excel Sheet";
    SourceTableView = sorting("Report Code", "Table Code", "Report Data No.", "Sequence No.");

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Sheet Name"; Rec."Sheet Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the statutory report Excel sheet.';
                }
                field("Page Number Excel Cell Name"; Rec."Page Number Excel Cell Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Page Number Horiz. Cells Qty"; Rec."Page Number Horiz. Cells Qty")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Page Number Vertical Cells Qty"; Rec."Page Number Vertical Cells Qty")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

