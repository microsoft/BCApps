namespace Microsoft.FabricExport;

using System.Fabric;

page 150010 "Fabric API Tables"
{
    PageType = API;
    Caption = 'Fabric API Tables';
    APIPublisher = 'Microsoft';
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
                    Caption = 'id';
                    Editable = false;
                }
                field(tableId; Rec."Table ID") { Caption = 'tableId'; }
                field(tableName; Rec."Table Name")
                {
                    Caption = 'tableName';
                    Editable = false;
                }
                field(perCompany; Rec."Per Company")
                {
                    Caption = 'perCompany';
                    Editable = false;
                }
                field(fabricEntityName; Rec."Fabric Entity Name") { Caption = 'fabricEntityName'; }
                field(fabricSchemaType; Rec."Fabric Schema Type") { Caption = 'fabricSchemaType'; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'lastModifiedDateTime';
                    Editable = false;
                }
            }
        }
    }
}
