page 103303 "Whse. Testscript Results"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    Caption = 'Whse. Testscript Results';
    DataCaptionExpression = Rec.Caption();
    Editable = false;
    PageType = Card;
    SourceTable = "Whse. Testscript Result";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Project Code";"Project Code")
                {
                }
                field("No.";"No.")
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
                    Visible = false;
                }
                field(Date;Date)
                {
                    Visible = false;
                }
                field(Time;Time)
                {
                }
                field("Use Case No.";"Use Case No.")
                {
                }
                field("Test Case No.";"Test Case No.")
                {
                }
                field("Iteration No.";"Iteration No.")
                {
                }
                field("Entry No.";"Entry No.")
                {
                }
                field(TableID;TableID)
                {
                }
            }
        }
    }

    actions
    {
    }
}

