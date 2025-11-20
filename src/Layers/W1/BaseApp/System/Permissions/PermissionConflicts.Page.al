namespace System.Security.AccessControl;

page 5557 "Permission Conflicts"
{
    PageType = List;
    Caption = 'Permission Conflicts';
    DeleteAllowed = false;
    InsertAllowed = false;
    Extensible = false;
    SourceTable = "Permission Conflicts";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            field("License"; EntitlementId)
            {
                ApplicationArea = All;
                Caption = 'License';
                ToolTip = 'Specifies the name of the license.';

                trigger OnValidate()
                begin
                    EffectivePermissionsMgt.PopulatePermissionConflictsTable(EntitlementId, PermissionSetId, Rec);
                    CurrPage.Update(false);
                end;
            }
            field("Permission Set ID"; PermissionSetId)
            {
                ApplicationArea = All;
                TableRelation = "Aggregate Permission Set"."Role ID";
                Caption = 'Permission Set ID';
                ToolTip = 'Specifies the identifier for the permission set.';

                trigger OnValidate()
                begin
                    EffectivePermissionsMgt.PopulatePermissionConflictsTable(EntitlementId, PermissionSetId, Rec);
                    CurrPage.Update(false);
                end;
            }
            repeater(GroupName)
            {
                Editable = false;

                field("Table ID"; Rec."Object ID")
                {
                    ApplicationArea = All;
                    Caption = 'Table ID';
                    ToolTip = 'Table ID';
                }
                field("Table Name"; Rec."Object Name")
                {
                    ApplicationArea = All;
                    Caption = 'Table Name';
                    ToolTip = 'Table Name';
                }
                field("Read Permission"; ReadPermissionsTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Read Permission';
                    ToolTip = 'Specifies the permission assigned to the access type, or whether it is in conflict with the product license. For details about a conflict, click the word Conflict.';

                    trigger OnDrillDown()
                    begin
                        EffectivePermissionsMgt.ShowPermissionConflict(Rec."Read Permission", Rec."Entitlement Read Permission", false);
                    end;
                }
                field("Insert Permission"; InsertPermissionsTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Insert Permission';
                    ToolTip = 'Specifies the permission assigned to the access type, or whether it is in conflict with the product license. For details about a conflict, click the word Conflict.';

                    trigger OnDrillDown()
                    begin
                        EffectivePermissionsMgt.ShowPermissionConflict(Rec."Insert Permission", Rec."Entitlement Insert Permission", false);
                    end;
                }
                field("Modify Permission"; ModifyPermissionsTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Modify Permission';
                    ToolTip = 'Specifies the permission assigned to the access type, or whether it is in conflict with the product license. For details about a conflict, click the word Conflict.';

                    trigger OnDrillDown()
                    begin
                        EffectivePermissionsMgt.ShowPermissionConflict(Rec."Modify Permission", Rec."Entitlement Modify Permission", false);
                    end;
                }
                field("Delete Permission"; DeletePermissionsTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Delete Permission';
                    ToolTip = 'Specifies the permission assigned to the access type, or whether it is in conflict with the product license. For details about a conflict, click the word Conflict.';

                    trigger OnDrillDown()
                    begin
                        EffectivePermissionsMgt.ShowPermissionConflict(Rec."Delete Permission", Rec."Entitlement Delete Permission", false);
                    end;
                }
                field("Execute Permission"; ExecutePermissionsTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Execute Permission';
                    ToolTip = 'Specifies the permission assigned to the access type, or whether it is in conflict with the product license. For details about a conflict, click the word Conflict.';

                    trigger OnDrillDown()
                    begin
                        EffectivePermissionsMgt.ShowPermissionConflict(Rec."Execute Permission", Rec."Entitlement Execute Permission", false);
                    end;
                }
            }
        }
    }

    var
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
        ReadPermissionsTxt: Text;
        InsertPermissionsTxt: Text;
        ModifyPermissionsTxt: Text;
        DeletePermissionsTxt: Text;
        ExecutePermissionsTxt: Text;
        PermissionSetId: Code[20];
        EntitlementId: Enum Licenses;

    trigger OnOpenPage()
    begin
        if PermissionSetId <> '' then
            EffectivePermissionsMgt.PopulatePermissionConflictsTable(EntitlementId, PermissionSetId, Rec);
    end;

    trigger OnAfterGetRecord()
    begin
        RefreshDisplayTexts();
    end;

    internal procedure SetPermissionSetId(PermissionSet: Code[20])
    begin
        PermissionSetId := PermissionSet;
    end;

    internal procedure SetEntitlementId(Entitlement: Enum Licenses)
    begin
        EntitlementId := Entitlement;
    end;

    local procedure RefreshDisplayTexts()
    begin
        ReadPermissionsTxt := EffectivePermissionsMgt.GetPermissionStatus(Rec."Read Permission", Rec."Entitlement Read Permission", false);
        InsertPermissionsTxt := EffectivePermissionsMgt.GetPermissionStatus(Rec."Insert Permission", Rec."Entitlement Insert Permission", false);
        ModifyPermissionsTxt := EffectivePermissionsMgt.GetPermissionStatus(Rec."Modify Permission", Rec."Entitlement Modify Permission", false);
        DeletePermissionsTxt := EffectivePermissionsMgt.GetPermissionStatus(Rec."Delete Permission", Rec."Entitlement Delete Permission", false);
        ExecutePermissionsTxt := EffectivePermissionsMgt.GetPermissionStatus(Rec."Execute Permission", Rec."Entitlement Execute Permission", false);

        CurrPage.Update(false);
    end;
}