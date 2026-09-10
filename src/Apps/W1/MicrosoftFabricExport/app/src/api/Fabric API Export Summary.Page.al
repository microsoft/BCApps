namespace Microsoft.FabricExport;

using System.Fabric;

#if not PTE
page 150013 "Fabric API Export Summary"
#else
page 50113 "Fabric API Export Summary"
#endif
{
    PageType = API;
    Caption = 'Fabric API Export Summary', Locked = true;
    APIPublisher = 'bc2fabric';
    APIGroup = 'fabric';
    APIVersion = 'v1.0';
    EntityName = 'fabricExportRun';
    EntitySetName = 'fabricExportRuns';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    SourceTable = "Tenant Fabric Export Summary";
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
                field(runId; Rec."Run ID") { Caption = 'runId'; }
                field(runType; Rec."Type") { Caption = 'runType'; }
                field(state; Rec.State) { Caption = 'state'; }
                field(startTime; Rec."Start Time") { Caption = 'startTime'; }
                field(endTime; Rec."End Time") { Caption = 'endTime'; }
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
