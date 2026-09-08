namespace Microsoft.Bc2Fabric;

using System.Fabric;

#if not PTE
page 150016 "Fabric Companies FactBox"
#else
page 50116 "Fabric Companies FactBox"
#endif
{
    Caption = 'Companies to Sync';
    PageType = ListPart;
    SourceTable = "Tenant Fabric Companies";
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
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this company is exported. Disabled companies are skipped.';
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