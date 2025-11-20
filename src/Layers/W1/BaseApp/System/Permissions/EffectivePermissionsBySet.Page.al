namespace System.Security.AccessControl;

page 9853 "Effective Permissions By Set"
{
    Caption = 'By Permission Set';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Permission Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control5)
            {
                ShowCaption = false;
                field("Permission Set"; Rec."Permission Set")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the permission set that gives the user permissions to the object chosen in the Permissions section.';

                    trigger OnDrillDown()
                    var
                        TenantPermission: Record "Tenant Permission";
                    begin
                        if Rec.Source in [Rec.Source::Entitlement, Rec.Source::Inherent] then
                            exit;
                        Rec.OpenPermissionsPage(true);
                        if Rec.Type = Rec.Type::"User-Defined" then
                            if TenantPermission.Get(Rec.GetAppID(), Rec."Permission Set", CurrObjectType, CurrObjectID) then begin
                                Rec."Read Permission" := TenantPermission."Read Permission";
                                Rec."Insert Permission" := TenantPermission."Insert Permission";
                                Rec."Modify Permission" := TenantPermission."Modify Permission";
                                Rec."Delete Permission" := TenantPermission."Delete Permission";
                                Rec."Execute Permission" := TenantPermission."Execute Permission";
                                Rec.Modify();
                                RefreshDisplayTexts();
                            end;
                    end;
                }
                field(Source; Rec.Source)
                {
                    ApplicationArea = All;
                    Enabled = false;
                    Style = Strong;
                    StyleExpr = Rec.Source = Rec.Source::Entitlement;
                    ToolTip = 'Specifies the origin of the permission set that gives the user permissions for the object chosen in the Permissions section. Note that rows with the type Entitlement originate from the subscription plan. The permission values of the entitlement overrule values that give increased permissions in other permission sets. In those cases, the permission level is Conflict.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    Enabled = false;
                    ToolTip = 'Specifies the type of the permission set that gives the user permissions for the object chosen in the Permissions section. Note that you can only edit permission sets of type User-Defined.';
                }
                field(ReadTxt; ReadPermissionsTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Read Permission';
                    Editable = false;
                    ToolTip = 'Specifies whether the permission set gives the user the Read permission.';

                    trigger OnDrillDown()
                    begin
                        EffectivePermissionsMgt.ShowPermissionConflict(ReadPermissions, ReadEntitlementPermissions, Rec.Source = Rec.Source::Entitlement);
                    end;
                }
                field(InsertTxt; InsertPermissionsTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Insert Permission';
                    Editable = false;
                    ToolTip = 'Specifies whether the permission set gives the user the Insert permission.';

                    trigger OnDrillDown()
                    begin
                        EffectivePermissionsMgt.ShowPermissionConflict(InsertPermissions, InsertEntitlementPermissions, Rec.Source = Rec.Source::Entitlement);
                    end;
                }
                field(ModifyTxt; ModifyPermissionsTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Modify Permission';
                    Editable = false;
                    ToolTip = 'Specifies whether the permission set gives the user the Modify permission.';

                    trigger OnDrillDown()
                    begin
                        EffectivePermissionsMgt.ShowPermissionConflict(ModifyPermissions, ModifyEntitlementPermissions, Rec.Source = Rec.Source::Entitlement);
                    end;
                }
                field(DeleteTxt; DeletePermissionsTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Delete Permission';
                    Editable = false;
                    ToolTip = 'Specifies whether the permission set gives the user the Delete permission.';

                    trigger OnDrillDown()
                    begin
                        EffectivePermissionsMgt.ShowPermissionConflict(DeletePermissions, DeleteEntitlementPermissions, Rec.Source = Rec.Source::Entitlement);
                    end;
                }
                field(ExecuteTxt; ExecutePermissionsTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Execute Permission';
                    Editable = false;
                    ToolTip = 'Specifies whether the permission set gives the user the Execute permission.';

                    trigger OnDrillDown()
                    var
                    begin
                        EffectivePermissionsMgt.ShowPermissionConflict(ExecutePermissions, ExecuteEntitlementPermissions, Rec.Source = Rec.Source::Entitlement);
                    end;
                }
                field("Security Filter"; Rec."Security Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Security Filter';
                    Editable = false;
                    ToolTip = 'Specifies a security filter that applies to this permission set to limit the access that this permission set has to the data contained in this table.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    trigger OnAfterGetRecord()
    begin
        RefreshDisplayTexts();
    end;

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey(Order, Type);
    end;

    var
        EntitlementPermissionBuffer: Record "Permission Buffer";
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
        ReadPermissionsTxt: Text;
        InsertPermissionsTxt: Text;
        ModifyPermissionsTxt: Text;
        DeletePermissionsTxt: Text;
        ExecutePermissionsTxt: Text;
        IsTableData: Boolean;
        CurrObjectType: Option;
        CurrObjectID: Integer;
        CurrUserID: Guid;
        ReadPermissions: Enum Permission;
        InsertPermissions: Enum Permission;
        ModifyPermissions: Enum Permission;
        DeletePermissions: Enum Permission;
        ExecutePermissions: Enum Permission;
        ReadEntitlementPermissions: Enum Permission;
        InsertEntitlementPermissions: Enum Permission;
        ModifyEntitlementPermissions: Enum Permission;
        DeleteEntitlementPermissions: Enum Permission;
        ExecuteEntitlementPermissions: Enum Permission;

    local procedure RefreshDisplayTexts()
    var
        IsSourceEntitlement: Boolean;
    begin
        ReadPermissions := EffectivePermissionsMgt.ConvertToPermission(Rec."Read Permission");
        InsertPermissions := EffectivePermissionsMgt.ConvertToPermission(Rec."Insert Permission");
        ModifyPermissions := EffectivePermissionsMgt.ConvertToPermission(Rec."Modify Permission");
        DeletePermissions := EffectivePermissionsMgt.ConvertToPermission(Rec."Delete Permission");
        ExecutePermissions := EffectivePermissionsMgt.ConvertToPermission(Rec."Execute Permission");

        ReadEntitlementPermissions := EffectivePermissionsMgt.ConvertToPermission(EntitlementPermissionBuffer."Read Permission");
        InsertEntitlementPermissions := EffectivePermissionsMgt.ConvertToPermission(EntitlementPermissionBuffer."Insert Permission");
        ModifyEntitlementPermissions := EffectivePermissionsMgt.ConvertToPermission(EntitlementPermissionBuffer."Modify Permission");
        DeleteEntitlementPermissions := EffectivePermissionsMgt.ConvertToPermission(EntitlementPermissionBuffer."Delete Permission");
        ExecuteEntitlementPermissions := EffectivePermissionsMgt.ConvertToPermission(EntitlementPermissionBuffer."Execute Permission");

        IsSourceEntitlement := (Rec.Source = Rec.Source::Entitlement);

        ReadPermissionsTxt := EffectivePermissionsMgt.GetPermissionStatus(ReadPermissions, ReadEntitlementPermissions, IsSourceEntitlement);
        InsertPermissionsTxt := EffectivePermissionsMgt.GetPermissionStatus(InsertPermissions, InsertEntitlementPermissions, IsSourceEntitlement);
        ModifyPermissionsTxt := EffectivePermissionsMgt.GetPermissionStatus(ModifyPermissions, ModifyEntitlementPermissions, IsSourceEntitlement);
        DeletePermissionsTxt := EffectivePermissionsMgt.GetPermissionStatus(DeletePermissions, DeleteEntitlementPermissions, IsSourceEntitlement);
        ExecutePermissionsTxt := EffectivePermissionsMgt.GetPermissionStatus(ExecutePermissions, ExecuteEntitlementPermissions, IsSourceEntitlement);

        CurrPage.Update(false);
    end;

    procedure SetRecordAndRefresh(PassedUserID: Guid; PassedCompanyName: Text[50]; CurrentObjectType: Option; CurrentObjectID: Integer)
    var
        TempPermissionBuffer: Record "Permission Buffer" temporary;
        Permission: Record Permission;
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
    begin
        EffectivePermissionsMgt.PopulatePermissionBuffer(TempPermissionBuffer, PassedUserID, PassedCompanyName,
          CurrentObjectType, CurrentObjectID);

        Rec.DeleteAll();

        if TempPermissionBuffer.FindSet() then
            repeat
                Rec := TempPermissionBuffer;
                Rec.Insert();
                if TempPermissionBuffer.Source = TempPermissionBuffer.Source::Entitlement then
                    EntitlementPermissionBuffer := TempPermissionBuffer;
            until TempPermissionBuffer.Next() = 0;

        CurrObjectType := CurrentObjectType;
        CurrObjectID := CurrentObjectID;
        CurrUserID := PassedUserID;
        IsTableData := CurrObjectType = Permission."Object Type"::"Table Data";

        CurrPage.Update(false);
    end;
}

