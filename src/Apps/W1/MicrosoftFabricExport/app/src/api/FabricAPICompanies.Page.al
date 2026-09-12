namespace Microsoft.FabricExport;

using System.Fabric;

page 48503 "Fabric API Companies"
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
    InsertAllowed = false;
    DeleteAllowed = false;

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

    [ServiceEnabled]
    [Caption('Add a company to Fabric export')]
    [Scope('Cloud')]
    procedure addcompany(CompanyName: Text[30]; var ActionContext: WebServiceActionContext)
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        TenantFabricCompanies: Record "Tenant Fabric Companies";
    begin
        FabricPlatformMgt.AddCompany(CompanyName);
        TenantFabricCompanies.Get(CompanyName);
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Fabric API Companies");
        ActionContext.AddEntityKey(TenantFabricCompanies.FieldNo(SystemId), TenantFabricCompanies.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Created);
    end;
}
