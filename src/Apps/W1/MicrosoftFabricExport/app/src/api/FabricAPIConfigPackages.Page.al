namespace Microsoft.FabricExport;

page 9104 "Fabric API Config Packages"
{
    PageType = API;
    Caption = 'Fabric API Config Packages';
    APIPublisher = 'microsoft';
    APIGroup = 'fabric';
    APIVersion = 'v1.0';
    EntityName = 'fabricConfigPackage';
    EntitySetName = 'fabricConfigPackages';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    SourceTable = "Fabric Config Package";
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
                    Caption = 'Id';
                    Editable = false;
                }
                field(code; Rec."Code") { Caption = 'Code'; }
                field(description; Rec.Description) { Caption = 'Description'; }
                field(version; Rec.Version) { Caption = 'Version'; }
                field(active; Rec.Active) { Caption = 'Active'; }
                field(activatedOn; Rec."Activated On") { Caption = 'Activated On'; }
                field(activatedBy; Rec."Activated By") { Caption = 'Activated By'; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date';
                    Editable = false;
                }
            }
        }
    }

    [ServiceEnabled]
    [Caption('Activate the configuration package')]
    [Scope('Cloud')]
    procedure activate(var ActionContext: WebServiceActionContext)
    var
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
    begin
        FabricConfigPkgMgt.Activate(Rec);
        SetActionResponse(ActionContext);
    end;

    [ServiceEnabled]
    [Caption('Deactivate the configuration package')]
    [Scope('Cloud')]
    procedure deactivate(var ActionContext: WebServiceActionContext)
    var
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
    begin
        FabricConfigPkgMgt.Deactivate(Rec);
        SetActionResponse(ActionContext);
    end;

    [ServiceEnabled]
    [Caption('Reapply the configuration package')]
    [Scope('Cloud')]
    procedure reapply(var ActionContext: WebServiceActionContext)
    var
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
    begin
        FabricConfigPkgMgt.Reapply(Rec);
        SetActionResponse(ActionContext);
    end;

    local procedure SetActionResponse(var ActionContext: WebServiceActionContext)
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Fabric API Config Packages");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
