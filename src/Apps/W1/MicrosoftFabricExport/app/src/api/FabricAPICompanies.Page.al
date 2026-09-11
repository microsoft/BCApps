namespace Microsoft.FabricExport;

using System.Fabric;

page 9111 "Fabric API Companies"
{
    PageType = API;
    Caption = 'Fabric API Companies';
    APIPublisher = 'microsoft';
    APIGroup = 'fabric';
    APIVersion = 'v1.0';
    EntityName = 'fabricCompany';
    EntitySetName = 'fabricCompanies';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    SourceTable = "Tenant Fabric Companies";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(companyName; Rec."Company Name") { Caption = 'Company Name'; }
                field(enabled; Rec.Enabled) { Caption = 'Enabled'; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date';
                    Editable = false;
                }
            }
        }
    }
}
