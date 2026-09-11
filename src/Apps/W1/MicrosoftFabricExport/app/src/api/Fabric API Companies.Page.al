namespace Microsoft.FabricExport;

using System.Fabric;

page 150011 "Fabric API Companies"
{
    PageType = API;
    Caption = 'Fabric API Companies', Locked = true;
    APIPublisher = 'bc2fabric';
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
                    Caption = 'id';
                    Editable = false;
                }
                field(companyName; Rec."Company Name") { Caption = 'companyName'; }
                field(enabled; Rec.Enabled) { Caption = 'enabled'; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'lastModifiedDateTime';
                    Editable = false;
                }
            }
        }
    }
}
