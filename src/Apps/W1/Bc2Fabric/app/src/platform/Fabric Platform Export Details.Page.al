namespace Microsoft.Bc2Fabric;

using System.Fabric;

page 150002 "Fabric Platform Export Details"
{
    Caption = 'Fabric Platform Export Details';
    PageType = List;
    SourceTable = "Tenant Fabric Export Details";
    UsageCategory = History;
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
}
