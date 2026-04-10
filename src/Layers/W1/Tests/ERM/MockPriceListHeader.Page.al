page 134118 "Mock Price List Header"
{
    PageType = List;
    SourceTable = "Price List Header";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field(Code; Rec.Code)
                {
                }
                field("Source Group"; "Source Group")
                {
                }
                field("Source Type"; "Source Type")
                {
                }
                field("Source No."; "Source No.")
                {
                }
                field("Price Type"; "Price Type")
                {
                }
                field("Amount Type"; "Amount Type")
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