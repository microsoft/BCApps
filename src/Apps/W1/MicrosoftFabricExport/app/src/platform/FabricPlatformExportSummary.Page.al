namespace Microsoft.FabricExport;

using System.Fabric;

page 150003 "Fabric Platform Export Summary"
{
    Caption = 'Fabric Synchronization Overview';
    PageType = List;
    SourceTable = "Tenant Fabric Export Summary";
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    SourceTableView = sorting("Start Time") order(descending);
    AboutTitle = 'Track synchronization runs';
    AboutText = 'See the history of synchronization runs, including their status and any errors, so you can confirm your data reached Microsoft Fabric.';

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

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                Caption = 'Refresh page';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Refreshes the page with the latest data.';

                trigger OnAction()
                begin
                    SelectLatestVersion();
                    if not Rec.Find() then;
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(ExportDetails)
            {
                Caption = 'Details';
                ApplicationArea = All;
                Image = ViewDetails;
                RunObject = page "Fabric Platform Export Details";
                RunPageLink = "Run ID" = field("Run ID");
                ToolTip = 'Shows the table-level export details for the selected run.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Refresh_Promoted; Refresh) { }
            }
            group(Category_Navigation)
            {
                Caption = 'Navigate';

                actionref(ExportDetails_Promoted; ExportDetails) { }
            }
        }
    }

    views
    {
        view(Errors)
        {
            Caption = 'Errors';
            Filters = where("Error Message" = filter(<> ''));
        }
    }
}
