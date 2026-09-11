namespace Microsoft.FabricExport;

using System.Fabric;

page 9114 "Fabric API Export Details"
{
    PageType = API;
    Caption = 'Fabric API Export Details';
    APIPublisher = 'microsoft';
    APIGroup = 'fabric';
    APIVersion = 'v1.0';
    EntityName = 'fabricExportDetail';
    EntitySetName = 'fabricExportDetails';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    SourceTable = "Tenant Fabric Export Details";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DataAccessIntent = ReadOnly;

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
                field(tableName; Rec."Table Name") { Caption = 'Table Name'; }
                field(fabricEntityName; Rec."Fabric Entity Name") { Caption = 'Fabric Entity Name'; }
                field(state; Rec.State) { Caption = 'State'; }
                field(exportType; Rec."Export Type") { Caption = 'Export Type'; }
                field(recordsUpdated; Rec."Records Updated") { Caption = 'Records Updated'; }
                field(recordsInserted; Rec."Records Inserted") { Caption = 'Records Inserted'; }
                field(recordsDeleted; Rec."Records Deleted") { Caption = 'Records Deleted'; }
                field(startWatermark; Rec."Start Watermark") { Caption = 'Start Watermark'; }
                field(endWatermark; Rec."End Watermark") { Caption = 'End Watermark'; }
                field(errorMessage; Rec."Error Message") { Caption = 'Error Message'; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date';
                    Editable = false;
                }
            }
        }
    }
}
