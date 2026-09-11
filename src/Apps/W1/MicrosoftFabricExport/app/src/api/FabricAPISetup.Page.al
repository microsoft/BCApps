namespace Microsoft.FabricExport;

using System.Fabric;

page 150015 "Fabric API Setup"
{
    PageType = API;
    Caption = 'Fabric API Setup';
    APIPublisher = 'Microsoft';
    APIGroup = 'fabric';
    APIVersion = 'v1.0';
    EntityName = 'fabricSetup';
    EntitySetName = 'fabricSetups';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    SourceTable = "Tenant Fabric Setup";

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
                field(fabricWorkspaceId; Rec."Fabric Workspace ID") { Caption = 'fabricWorkspaceId'; }
                field(fabricWorkspaceName; Rec."Fabric Workspace Name") { Caption = 'fabricWorkspaceName'; }
                field(fabricLakehouseId; Rec."Fabric Lakehouse ID") { Caption = 'fabricLakehouseId'; }
                field(fabricDataNamespace; Rec."Fabric Data Namespace") { Caption = 'fabricDataNamespace'; }
                field(fabricLoggingNamespace; Rec."Fabric Logging Namespace") { Caption = 'fabricLoggingNamespace'; }
                field(minutesBetweenExports; Rec."Minutes Between Exports") { Caption = 'minutesBetweenExports'; }
                field(maxConsecutiveFailedRuns; Rec."Max Consecutive Failed Runs")
                {
                    Caption = 'maxConsecutiveFailedRuns';
                    MinValue = 1;
                    MaxValue = 5;
                }
                field(setupComplete; Rec."Setup Complete")
                {
                    Caption = 'setupComplete';
                    Editable = false;
                }
                field(exportEnabled; Rec."Export Enabled")
                {
                    Caption = 'exportEnabled';
                    Editable = false;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'lastModifiedDateTime';
                    Editable = false;
                }
            }
        }
    }

    [ServiceEnabled]
    [Caption('Enable the Fabric export')]
    [Scope('Cloud')]
    procedure enableexport(var ActionContext: WebServiceActionContext)
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        FabricPlatformMgt.EnableExport();
        SetActionResponse(ActionContext);
    end;

    [ServiceEnabled]
    [Caption('Start the Fabric export')]
    [Scope('Cloud')]
    procedure startexport(var ActionContext: WebServiceActionContext)
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        FabricPlatformMgt.StartExport();
        SetActionResponse(ActionContext);
    end;

    [ServiceEnabled]
    [Caption('Stop the Fabric export')]
    [Scope('Cloud')]
    procedure stopexport(var ActionContext: WebServiceActionContext)
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        FabricPlatformMgt.StopExport();
        SetActionResponse(ActionContext);
    end;

    [ServiceEnabled]
    [Caption('Disable the Fabric export')]
    [Scope('Cloud')]
    procedure disableexport(var ActionContext: WebServiceActionContext)
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        FabricPlatformMgt.DisableExport();
        SetActionResponse(ActionContext);
    end;

    local procedure SetActionResponse(var ActionContext: WebServiceActionContext)
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Fabric API Setup");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
