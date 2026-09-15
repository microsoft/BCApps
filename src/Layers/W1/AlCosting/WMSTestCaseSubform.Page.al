page 103221 "WMS Test Case Subform"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    Caption = 'WMS Test Case Subform';
    PageType = ListPart;
    SourceTable = "Whse. Test Case";

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

