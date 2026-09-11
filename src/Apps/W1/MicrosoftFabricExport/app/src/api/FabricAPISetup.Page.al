namespace Microsoft.FabricExport;

using System.Fabric;

page 9107 "Fabric API Setup"
{
    PageType = API;
    Caption = 'Fabric API Setup';
    APIPublisher = 'microsoft';
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
                    Caption = 'Id';
                    Editable = false;
                }
                field(fabricWorkspaceId; Rec."Fabric Workspace ID") { Caption = 'Fabric Workspace Id'; }
                field(fabricWorkspaceName; Rec."Fabric Workspace Name") { Caption = 'Fabric Workspace Name'; }
                field(fabricLakehouseId; Rec."Fabric Lakehouse ID") { Caption = 'Fabric Lakehouse Id'; }
                field(fabricDataNamespace; Rec."Fabric Data Namespace") { Caption = 'Fabric Data Namespace'; }
                field(fabricLoggingNamespace; Rec."Fabric Logging Namespace") { Caption = 'Fabric Logging Namespace'; }
                field(minutesBetweenExports; Rec."Minutes Between Exports") { Caption = 'Minutes Between Exports'; }
                field(maxConsecutiveFailedRuns; Rec."Max Consecutive Failed Runs")
                {
                    Caption = 'Max Consecutive Failed Runs';
                    MinValue = 1;
                    MaxValue = 5;
                }
                field(setupComplete; Rec."Setup Complete")
                {
                    Caption = 'Setup Complete';
                    Editable = false;
                }
                field(exportEnabled; Rec."Export Enabled")
                {
                    Caption = 'Export Enabled';
                    Editable = false;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date';
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
