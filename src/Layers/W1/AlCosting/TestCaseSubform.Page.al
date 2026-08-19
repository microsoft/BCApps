page 103102 "Test Case Subform"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    PageType = ListPart;
    SourceTable = "Test Case";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Test Case No.";"Test Case No.")
                {
                }
                field(Description;Description)
                {
                }
                field("Testscript Completed";"Testscript Completed")
                {
                }
            }
        }
    }

    actions
    {
    }
}

