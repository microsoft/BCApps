page 103201 "Whse. Use Case"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    Caption = 'Whse. Use Case';
    Editable = false;
    PageType = Card;
    SourceTable = "Whse. Use Case";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Project Code"; "Project Code")
                {
                }
                field("Use Case No."; "Use Case No.")
                {
                }
                field(Description; Description)
                {
                }
            }
            part(TestCases; "WMS Test Case Subform")
            {
                SubPageLink = "Project Code" = field("Project Code"),
                              "Use Case No." = field("Use Case No.");
                SubPageView = sorting("Project Code", "Use Case No.");
            }
        }
    }

    actions
    {
    }
}

