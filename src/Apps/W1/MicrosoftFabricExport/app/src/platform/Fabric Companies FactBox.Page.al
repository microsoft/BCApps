namespace Microsoft.FabricExport;

using System.Fabric;

page 150016 "Fabric Companies FactBox"
{
    Caption = 'Companies to Synchronize';
    PageType = ListPart;
    SourceTable = "Tenant Fabric Companies";
    SourceTableView = where(Enabled = const(true));
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
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company included in the Fabric export.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenCompanies)
            {
                Caption = 'Companies';
                ApplicationArea = All;
                Image = Company;
                RunObject = page "Fabric Platform Companies";
                ToolTip = 'Opens the full list of companies selected for the Fabric export.';
            }
        }
    }
}