page 103101 "Use Case"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    PageType = Card;
    SourceTable = "Use Case";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Use Case No.";"Use Case No.")
                {
                }
                field(Description;Description)
                {
                }
            }
            part(TestCases;"Test Case Subform")
            {
                SubPageLink = "Use Case No."=FIELD("Use Case No.");
                SubPageView = sorting("Use Case No.","Test Case No.");
            }
        }
    }

    actions
    {
    }
}

