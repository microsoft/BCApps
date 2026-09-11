namespace Microsoft.FabricExport;

using System.Fabric;

page 9102 "Fabric API Tables"
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
                field(tableId; Rec."Table ID") { Caption = 'Table Id'; }
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
}
