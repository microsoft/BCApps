namespace Microsoft.FabricExport;

using System.Fabric;

page 48507 "Fabric API Setup"
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

    trigger OnOpenPage()
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        FabricPlatformMgt.EnsureSetup(Rec);
    end;

    [ServiceEnabled]
    [Caption('Enable Fabric mirroring')]
    [Scope('Cloud')]
    procedure EnableExport(var ActionContext: WebServiceActionContext)
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        FabricPlatformMgt.EnableExport();
        SetActionResponse(ActionContext);
    end;

    [ServiceEnabled]
    [Caption('Start Fabric mirroring')]
    [Scope('Cloud')]
    procedure StartExport(var ActionContext: WebServiceActionContext)
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        FabricPlatformMgt.StartExport();
        SetActionResponse(ActionContext);
    end;

    [ServiceEnabled]
    [Caption('Stop Fabric mirroring')]
    [Scope('Cloud')]
    procedure StopExport(var ActionContext: WebServiceActionContext)
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        FabricPlatformMgt.StopExport();
        SetActionResponse(ActionContext);
    end;

    [ServiceEnabled]
    [Caption('Disable Fabric mirroring')]
    [Scope('Cloud')]
    procedure DisableExport(var ActionContext: WebServiceActionContext)
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        FabricPlatformMgt.DisableExport();
        SetActionResponse(ActionContext);
    end;

    [ServiceEnabled]
    [Caption('Add a table to Fabric mirroring')]
    [Scope('Cloud')]
    procedure AddTable(NewTableId: Integer; var ActionContext: WebServiceActionContext)
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

    [ServiceEnabled]
    [Caption('Add a company to Fabric mirroring')]
    [Scope('Cloud')]
    procedure AddCompany(NewCompanyName: Text[30]; var ActionContext: WebServiceActionContext)
    var
        TenantFabricCompanies: Record "Tenant Fabric Companies";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        FabricPlatformMgt.AddCompany(NewCompanyName);
        TenantFabricCompanies.Get(NewCompanyName);
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Fabric API Companies");
        ActionContext.AddEntityKey(TenantFabricCompanies.FieldNo(SystemId), TenantFabricCompanies.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Created);
    end;

    local procedure SetActionResponse(var ActionContext: WebServiceActionContext)
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Fabric API Setup");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
