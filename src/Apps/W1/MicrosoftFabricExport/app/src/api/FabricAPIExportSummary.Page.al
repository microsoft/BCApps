namespace Microsoft.FabricExport;

using System.Fabric;

page 9105 "Fabric API Export Summary"
{
    PageType = API;
    Caption = 'Fabric API Export Summary';
    APIPublisher = 'microsoft';
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
                field(runId; Rec."Run ID") { Caption = 'Run Id'; }
                field(runType; Rec."Type") { Caption = 'Run Type'; }
                field(state; Rec.State) { Caption = 'State'; }
                field(startTime; Rec."Start Time") { Caption = 'Start Time'; }
                field(endTime; Rec."End Time") { Caption = 'End Time'; }
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
