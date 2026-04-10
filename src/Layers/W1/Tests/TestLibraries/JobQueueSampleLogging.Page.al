page 132450 "Job Queue Sample Logging"
{
    PageType = List;
    SourceTable = "Job Queue Sample Logging";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; "No.")
                {
                }
                field("User ID"; "User ID")
                {
                }
                field("Session ID"; "Session ID")
                {
                }
                field(MessageToLog; MessageToLog)
                {
                }
            }
        }
        area(factboxes)
        {
            part(Control8; "My Job Queue")
            {
            }
        }
    }

    actions
    {
    }
}

