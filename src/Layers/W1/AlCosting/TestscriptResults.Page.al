page 103001 "Testscript Results"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DataCaptionExpression = Rec.Caption();
    PageType = Card;
    SourceTable = "Testscript Result";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Entry No.";"Entry No.")
                {
                }
                field(Name;Name)
                {
                }
                field(Value;Value)
                {
                }
                field("Expected Value";"Expected Value")
                {
                }
                field("Is Equal";"Is Equal")
                {
                }
                field("Codeunit ID";"Codeunit ID")
                {
                }
            }
        }
    }

    actions
    {
    }
}

