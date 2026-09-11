namespace Microsoft.FabricExport;

page 150012 "Fabric API Config Packages"
{
    PageType = API;
    Caption = 'Fabric API Config Packages', Locked = true;
    APIPublisher = 'bc2fabric';
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
                    Caption = 'id';
                    Editable = false;
                }
                field(code; Rec."Code") { Caption = 'code'; }
                field(description; Rec.Description) { Caption = 'description'; }
                field(version; Rec.Version) { Caption = 'version'; }
                field(active; Rec.Active) { Caption = 'active'; }
                field(activatedOn; Rec."Activated On") { Caption = 'activatedOn'; }
                field(activatedBy; Rec."Activated By") { Caption = 'activatedBy'; }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'lastModifiedDateTime';
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
