namespace Microsoft.Bc2Fabric;

using System.Fabric;

#if not PTE
page 150002 "Fabric Platform Export Details"
#else
page 50102 "Fabric Platform Export Details"
#endif
{
    Caption = 'Synchronization Details';
    PageType = List;
    SourceTable = "Tenant Fabric Export Details";
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    SourceTableView = sorting("Start Time") order(descending);
    AboutTitle = 'Track table-level synchronization';
    AboutText = 'See exactly which companies and tables were synchronized in each run, how many records changed, and any errors that occurred.';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date and time when the export run started.';
                }
                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date and time when the export run ended.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company for this export detail row.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the exported table.';
                }
                field("Fabric Entity Name"; Rec."Fabric Entity Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the destination entity name in Microsoft Fabric.';
                }
                field(State; Rec.State)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the state of this table/company export.';
                }
                field("Export Type"; Rec."Export Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the export was a snapshot or an incremental run.';
                }
                field("Records Updated"; Rec."Records Updated")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of updated rows exported.';
                }
                field("Records Inserted"; Rec."Records Inserted")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of inserted rows exported.';
                }
                field("Records Deleted"; Rec."Records Deleted")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of deleted rows exported.';
                }
                field("Start Watermark"; Rec."Start Watermark")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the change-tracking watermark at the start of the run.';
                }
                field("End Watermark"; Rec."End Watermark")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the change-tracking watermark at the end of the run.';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error message when this row failed.';
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
                Caption = 'Refresh';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Refreshes the page with the latest data.';

                trigger OnAction()
                begin
                    SelectLatestVersion();
                    if not Rec.Find() then;
                    ApplyRowFilter();
                    CurrPage.Update(false);
                end;
            }
            action(ShowZeroChangeRows)
            {
                Caption = 'Show Rows with No Changes';
                ApplicationArea = All;
                Image = ShowList;
                Visible = not ShowRowsWithNoChanges;
                ToolTip = 'Shows rows where no records were updated, inserted, or deleted.';

                trigger OnAction()
                begin
                    ShowRowsWithNoChanges := true;
                    ApplyRowFilter();
                    CurrPage.Update(false);
                end;
            }
            action(HideZeroChangeRows)
            {
                Caption = 'Hide Rows with No Changes';
                ApplicationArea = All;
                Image = Filter;
                Visible = ShowRowsWithNoChanges;
                ToolTip = 'Hides rows where no records were updated, inserted, or deleted.';

                trigger OnAction()
                begin
                    ShowRowsWithNoChanges := false;
                    ApplyRowFilter();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Refresh_Promoted; Refresh) { }
                actionref(ShowZeroChangeRows_Promoted; ShowZeroChangeRows) { }
                actionref(HideZeroChangeRows_Promoted; HideZeroChangeRows) { }
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

    trigger OnOpenPage()
    begin
        ApplyRowFilter();
    end;

    local procedure ApplyRowFilter()
    begin
        Rec.MarkedOnly(false);
        if not ShowRowsWithNoChanges then begin
            if Rec.FindSet() then
                repeat
                    if (Rec."Records Updated" <> 0) or (Rec."Records Inserted" <> 0) or (Rec."Records Deleted" <> 0) then
                        Rec.Mark(true);
                until Rec.Next() = 0;
            Rec.MarkedOnly(true);
        end;
        if not Rec.FindFirst() then;
    end;

    var
        ShowRowsWithNoChanges: Boolean;
}
