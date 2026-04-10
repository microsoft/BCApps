page 134124 "Mock Price Worksheet Line"
{
    PageType = List;
    SourceTable = "Price Worksheet Line";
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field("Source Type"; "Source Type")
                {
                }
                field("Parent Source No."; "Parent Source No.")
                {
                }
                field("Source No."; "Source No.")
                {
                }
                field("Source ID"; "Source ID")
                {
                }
                field("Asset Type"; "Asset Type")
                {
                }
                field("Asset No."; "Asset No.")
                {
                }
                field("Variant Code"; "Variant Code")
                {
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                }
                field("Starting Date"; "Starting Date")
                {
                }
                field("Ending Date"; "Ending Date")
                {
                }
            }
        }
    }
}