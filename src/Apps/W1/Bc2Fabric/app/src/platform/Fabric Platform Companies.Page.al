namespace Microsoft.Bc2Fabric;

using System.Fabric;

page 150001 "Fabric Platform Companies"
{
    Caption = 'Fabric Platform Companies';
    PageType = List;
    SourceTable = "Tenant Fabric Companies";
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
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
}
