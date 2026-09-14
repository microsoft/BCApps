namespace Microsoft.FabricExport;

using System.Fabric;

page 48502 "Fabric API Tables"
{
    PageType = API;
    Caption = 'Fabric API Tables';
    APIPublisher = 'microsoft';
    APIGroup = 'fabric';
    APIVersion = 'v1.0';
    EntityName = 'fabricTable';
    EntitySetName = 'fabricTables';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    SourceTable = "Tenant Fabric Tables";
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
                field(tableId; Rec."Table ID")
                {
                    Caption = 'Table Id';
                    Editable = false;
                }
                field(tableName; Rec."Table Name")
                {
                    Caption = 'Table Name';
                    Editable = false;
                }
                field(perCompany; Rec."Per Company")
                {
                    Caption = 'Per Company';
                    Editable = false;
                }
                field(fabricEntityName; Rec."Fabric Entity Name") { Caption = 'Fabric Entity Name'; }
                field(fabricSchemaType; Rec."Fabric Schema Type") { Caption = 'Fabric Schema Type'; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date';
                    Editable = false;
                }
            }
        }
    }

    [ServiceEnabled]
    [Caption('Add a table to Fabric export')]
    [Scope('Cloud')]
    procedure addtable(NewTableId: Integer; var ActionContext: WebServiceActionContext)
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        FabricPlatformMgt.AddTable(NewTableId);
        TenantFabricTables.Get(NewTableId);
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Fabric API Tables");
        ActionContext.AddEntityKey(TenantFabricTables.FieldNo(SystemId), TenantFabricTables.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Created);
    end;
}
