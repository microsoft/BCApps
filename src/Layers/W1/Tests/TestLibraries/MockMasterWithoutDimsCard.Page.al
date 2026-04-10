page 134487 "Mock Master Without Dims Card"
{
    PageType = Card;
    SourceTable = "Mock Master Table";

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; "No.")
                {
                    ApplicationArea = All;
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Action8)
            {
                Caption = 'Dimensions';
                Image = Dimensions;
                action(Dimensions)
                {
                    ApplicationArea = All;
                    Caption = 'Dimensions-Single';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';

                    trigger OnAction()
                    var
                        DefaultDimension: Record "Default Dimension";
                    begin
                        DefaultDimension.SetRange("Table ID", DATABASE::"Mock Master Table");
                        DefaultDimension.SetRange("No.", "No.");
                        PAGE.RunModal(PAGE::"Default Dimensions", DefaultDimension);
                    end;
                }
            }
        }
    }
}

