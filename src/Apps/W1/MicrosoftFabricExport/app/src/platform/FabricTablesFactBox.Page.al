namespace Microsoft.FabricExport;

using System.Fabric;

page 9118 "Fabric Tables FactBox"
{
    Caption = 'Tables to Synchronize';
    PageType = ListPart;
    SourceTable = "Tenant Fabric Tables";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of the Business Central table to export.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the Business Central table to export.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenTables)
            {
                Caption = 'Tables';
                ApplicationArea = All;
                Image = Table;
                RunObject = page "Fabric Platform Tables";
                ToolTip = 'Opens the full list of tables selected for the Fabric export.';
            }
        }
    }
}