namespace Microsoft.FabricExport;

using System.Fabric;
using System.Reflection;

page 9105 "Fabric Platform Tables"
{
    Caption = 'Fabric Table Configuration';
    PageType = List;
    SourceTable = "Tenant Fabric Tables";
    ApplicationArea = All;
    InsertAllowed = false;
    AboutTitle = 'Choose tables to synchronize';
    AboutText = 'Add the Business Central tables you want to send to Microsoft Fabric. You can select up to 500 tables.';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the ID of the Business Central table to export.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the name of the Business Central table to export.';
                }
                field("Per Company"; Rec."Per Company")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies whether the table stores data per company.';
                }
                field("Fabric Entity Name"; Rec."Fabric Entity Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the destination entity name used in Microsoft Fabric.';
                }
                field("Fabric Schema Type"; Rec."Fabric Schema Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the table is exported as data or logging.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddTable)
            {
                Caption = 'Add table';
                ApplicationArea = All;
                Image = New;
                ToolTip = 'Adds one or more Business Central tables to the export selection. A maximum of 500 tables can be selected.';

                trigger OnAction()
                var
                    AllObjWithCaption: Record AllObjWithCaption;
                    FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
                    ObjectsPage: Page Objects;
                begin
                    FabricPlatformMgt.CheckCanAddTable();

                    AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
                    ObjectsPage.SetTableView(AllObjWithCaption);
                    ObjectsPage.LookupMode(true);
                    if ObjectsPage.RunModal() <> Action::LookupOK then
                        exit;

                    ObjectsPage.SetSelectionFilter(AllObjWithCaption);
                    FabricPlatformMgt.AddTables(AllObjWithCaption);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(AddTable_Promoted; AddTable) { }
            }
        }
    }
}
