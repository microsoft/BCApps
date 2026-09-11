namespace Microsoft.FabricExport;

using System.Fabric;

page 150014 "Fabric API Export Details"
{
    PageType = API;
    Caption = 'Fabric API Export Details', Locked = true;
    APIPublisher = 'bc2fabric';
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
                field(tableName; Rec."Table Name") { Caption = 'tableName'; }
                field(fabricEntityName; Rec."Fabric Entity Name") { Caption = 'fabricEntityName'; }
                field(state; Rec.State) { Caption = 'state'; }
                field(exportType; Rec."Export Type") { Caption = 'exportType'; }
                field(recordsUpdated; Rec."Records Updated") { Caption = 'recordsUpdated'; }
                field(recordsInserted; Rec."Records Inserted") { Caption = 'recordsInserted'; }
                field(recordsDeleted; Rec."Records Deleted") { Caption = 'recordsDeleted'; }
                field(startWatermark; Rec."Start Watermark") { Caption = 'startWatermark'; }
                field(endWatermark; Rec."End Watermark") { Caption = 'endWatermark'; }
                field(errorMessage; Rec."Error Message") { Caption = 'errorMessage'; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'lastModifiedDateTime';
                    Editable = false;
                }
            }
        }
    }
}
