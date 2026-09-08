namespace Microsoft.Bc2Fabric;

using Microsoft.Foundation.Company;
using System.Environment;
using System.Fabric;

#if not PTE
page 150001 "Fabric Platform Companies"
#else
page 50101 "Fabric Platform Companies"
#endif
{
    Caption = 'Fabric Company Configuration';
    PageType = List;
    SourceTable = "Tenant Fabric Companies";
    ApplicationArea = All;
    InsertAllowed = false;
    AboutTitle = 'Choose companies to synchronize';
    AboutText = 'Add the companies whose data you want to send to Microsoft Fabric, and turn synchronization on or off for each one.';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    Editable = false;
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
            action(AddCompany)
            {
                Caption = 'Add company';
                ApplicationArea = All;
                Image = New;
                ToolTip = 'Adds a company to the Fabric export selection.';

                trigger OnAction()
                var
                    Company: Record Company;
                    FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
                    Companies: Page Companies;
                begin
                    Companies.LookupMode(true);
                    if Companies.RunModal() <> Action::LookupOK then
                        exit;

                    Companies.GetRecord(Company);
                    FabricPlatformMgt.AddCompany(Company.Name);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(AddCompany_Promoted; AddCompany) { }
            }
        }
    }
}
