namespace Microsoft.Bc2Fabric;

using System.Fabric;

#if not PTE
page 150003 "Fabric Platform Export Summary"
#else
page 50103 "Fabric Platform Export Summary"
#endif
{
    Caption = 'Fabric Platform Export Summary';
    PageType = List;
    SourceTable = "Tenant Fabric Export Summary";
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    SourceTableView = sorting("Start Time") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Run ID"; Rec."Run ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the correlation ID of the export run.';
                }
                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the kind of operation the run represents.';
                }
                field(State; Rec.State)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the terminal state of the run.';
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the run started.';
                }
                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the run ended.';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error message when the run failed.';
                }
            }
        }
    }
}
