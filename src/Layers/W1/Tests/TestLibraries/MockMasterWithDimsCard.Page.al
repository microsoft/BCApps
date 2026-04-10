page 134482 "Mock Master With Dims Card"
{
    PageType = Card;
    SourceTable = "Table With Default Dim";

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
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = All;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
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
                        DefaultDimension.SetRange("Table ID", DATABASE::"Table With Default Dim");
                        DefaultDimension.SetRange("No.", "No.");
                        PAGE.RunModal(PAGE::"Default Dimensions", DefaultDimension);
                    end;
                }
            }
        }
    }
}

