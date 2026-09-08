namespace Microsoft.Bc2Fabric;

using System.Fabric;

#if not PTE
page 150016 "Fabric Companies FactBox"
#else
page 50116 "Fabric Companies FactBox"
#endif
{
    Caption = 'Enabled Companies';
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