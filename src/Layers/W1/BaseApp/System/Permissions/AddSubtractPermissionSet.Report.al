namespace System.Security.AccessControl;

using System.Text;

report 9000 "Add/Subtract Permission Set"
{
    Caption = 'Add/Subtract Permission Set';
    ProcessingOnly = true;

    dataset
    {
        dataitem(SourcePermissionSet; "Aggregate Permission Set")
        {
            DataItemTableView = sorting(Scope, "App ID", "Role ID") order(ascending);

            trigger OnAfterGetRecord()
            var
                Permission: Record Permission;
                TenantPermission: Record "Tenant Permission";
            begin
                if Scope = Scope::System then begin
                    Permission.SetRange("Role ID", "Role ID");
                    if Permission.FindSet() then
                        repeat
                            if DestinationAggregatePermissionSet.Scope = DestinationAggregatePermissionSet.Scope::System then
                                IncludeExcludePermissionInPermission(Permission)
                            else
                                IncludeExcludePermission(Permission);
                        until Permission.Next() = 0;
                end else begin
                    TenantPermission.SetRange("App ID", "App ID");
                    TenantPermission.SetRange("Role ID", "Role ID");
                    if TenantPermission.FindSet() then
                        repeat
                            if TenantPermission.Type <> TenantPermission.Type::Exclude then // This report does not suppport exclude permissions.
                                if DestinationAggregatePermissionSet.Scope = DestinationAggregatePermissionSet.Scope::System then
                                    IncludeExcludeTenantPermissionInPermission(TenantPermission)
                                else
                                    IncludeExcludeTenantPermission(TenantPermission);
                        until TenantPermission.Next() = 0;
                end;
            end;

            trigger OnPreDataItem()
            begin
                Copy(DummySourceAggregatePermissionSet);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(DstnAggregatePermissionSet; DestinationAggregatePermissionSet."Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Destination';
                    Editable = false;
                    TableRelation = "Aggregate Permission Set"."Role ID";
                    ToolTip = 'Specifies the permission set for which permission sets are included or excluded.';
                }
                field(SetOperation; SetOperation)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Operation';
                    OptionCaption = 'Include,Exclude';
                    ToolTip = 'Specifies if the batch job includes or excludes a permission set for the destination permission set.';
                }
                field(SourceAggregatePermissionSet; SelectedRoleIdFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source';
                    Editable = false;
                    ToolTip = 'Specifies which permission set is included or excluded for the destination permission set.';

                    trigger OnAssistEdit()
                    var
                        SelectionFilterManagement: Codeunit SelectionFilterManagement;
                        PermissionSetList: Page "Permission Set List";
                    begin
                        PermissionSetList.LookupMode := true;
                        if PermissionSetList.RunModal() = ACTION::LookupOK then begin
                            PermissionSetList.GetSelectionFilter(DummySourceAggregatePermissionSet);
                            SelectedRoleIdFilter := SelectionFilterManagement.GetSelectionFilterForAggregatePermissionSetRoleId(DummySourceAggregatePermissionSet);
                        end;
                    end;
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if DestinationAggregatePermissionSet."Role ID" = '' then
            Error(NoDestinationErr);
        if not DummySourceAggregatePermissionSet.FindSet() then
            Error(NoSourceErr);
        repeat
            if DestinationAggregatePermissionSet.RecordId = DummySourceAggregatePermissionSet.RecordId then
                Error(SameSrcDestnErr);
        until DummySourceAggregatePermissionSet.Next() = 0;
    end;

    var
        DestinationAggregatePermissionSet: Record "Aggregate Permission Set";
        DummySourceAggregatePermissionSet: Record "Aggregate Permission Set";
        SetOperation: Option Include,Exclude;
        NoDestinationErr: Label 'No destination permission set has been set.';
        NoSourceErr: Label 'You must select a source permission set.';
        SameSrcDestnErr: Label 'You cannot select permission set as both source and destination.';
        SelectedRoleIdFilter: Text;

    procedure SetDestination(NewDestinationAggregatePermissionSet: Record "Aggregate Permission Set")
    begin
        DestinationAggregatePermissionSet := NewDestinationAggregatePermissionSet;
    end;

    local procedure PermissionValueIsGreaterOrEqual(Left: Option " ",Yes,Indirect; Right: Option " ",Yes,Indirect): Boolean
    begin
        // Returns (Left >= Right)
        case Left of
            Left::" ":
                exit(Right = Right::" ");
            Left::Yes:
                exit(true);
            Left::Indirect:
                exit(Right <> Right::Yes);
        end;
    end;

    local procedure IncludeExcludePermission(SourcePermission: Record Permission)
    var
        DestinationTenantPermission: Record "Tenant Permission";
    begin
        case SetOperation of
            SetOperation::Include:
                if DestinationTenantPermission.Get(
                     DestinationAggregatePermissionSet."App ID", DestinationAggregatePermissionSet."Role ID",
                     SourcePermission."Object Type", SourcePermission."Object ID")
                then begin
                    if PermissionValueIsGreaterOrEqual(SourcePermission."Read Permission", DestinationTenantPermission."Read Permission") then
                        DestinationTenantPermission."Read Permission" := SourcePermission."Read Permission";
                    if PermissionValueIsGreaterOrEqual(SourcePermission."Insert Permission", DestinationTenantPermission."Insert Permission") then
                        DestinationTenantPermission."Insert Permission" := SourcePermission."Insert Permission";
                    if PermissionValueIsGreaterOrEqual(SourcePermission."Modify Permission", DestinationTenantPermission."Modify Permission") then
                        DestinationTenantPermission."Modify Permission" := SourcePermission."Modify Permission";
                    if PermissionValueIsGreaterOrEqual(SourcePermission."Delete Permission", DestinationTenantPermission."Delete Permission") then
                        DestinationTenantPermission."Delete Permission" := SourcePermission."Delete Permission";
                    if PermissionValueIsGreaterOrEqual(SourcePermission."Execute Permission", DestinationTenantPermission."Execute Permission") then
                        DestinationTenantPermission."Execute Permission" := SourcePermission."Execute Permission";
                    DestinationTenantPermission.Modify();
                end else begin
                    DestinationTenantPermission."Object ID" := SourcePermission."Object ID";
                    DestinationTenantPermission."Object Type" := SourcePermission."Object Type";
                    DestinationTenantPermission."Read Permission" := SourcePermission."Read Permission";
                    DestinationTenantPermission."Insert Permission" := SourcePermission."Insert Permission";
                    DestinationTenantPermission."Modify Permission" := SourcePermission."Modify Permission";
                    DestinationTenantPermission."Delete Permission" := SourcePermission."Delete Permission";
                    DestinationTenantPermission."Execute Permission" := SourcePermission."Execute Permission";
                    DestinationTenantPermission."Security Filter" := SourcePermission."Security Filter";
                    DestinationTenantPermission."Role ID" := DestinationAggregatePermissionSet."Role ID";
                    DestinationTenantPermission."App ID" := DestinationAggregatePermissionSet."App ID";
                    DestinationTenantPermission.Insert();
                end;
            SetOperation::Exclude:
                begin
                    DestinationTenantPermission.SetRange("App ID", DestinationAggregatePermissionSet."App ID");
                    DestinationTenantPermission.SetRange("Role ID", DestinationAggregatePermissionSet."Role ID");
                    DestinationTenantPermission.SetRange("Object Type", SourcePermission."Object Type");
                    if SourcePermission."Object ID" <> 0 then
                        DestinationTenantPermission.SetRange("Object ID", SourcePermission."Object ID");
                    if DestinationTenantPermission.FindSet() then
                        repeat
                            if PermissionValueIsGreaterOrEqual(SourcePermission."Read Permission", DestinationTenantPermission."Read Permission") then
                                DestinationTenantPermission."Read Permission" := SourcePermission."Read Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(SourcePermission."Insert Permission", DestinationTenantPermission."Insert Permission") then
                                DestinationTenantPermission."Insert Permission" := SourcePermission."Insert Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(SourcePermission."Modify Permission", DestinationTenantPermission."Modify Permission") then
                                DestinationTenantPermission."Modify Permission" := SourcePermission."Modify Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(SourcePermission."Delete Permission", DestinationTenantPermission."Delete Permission") then
                                DestinationTenantPermission."Delete Permission" := SourcePermission."Delete Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(
                                 SourcePermission."Execute Permission", DestinationTenantPermission."Execute Permission")
                            then
                                DestinationTenantPermission."Execute Permission" := SourcePermission."Execute Permission"::" ";
                            DestinationTenantPermission.Modify();
                            if (DestinationTenantPermission."Read Permission" = SourcePermission."Read Permission"::" ") and
                               (DestinationTenantPermission."Insert Permission" = SourcePermission."Read Permission"::" ") and
                               (DestinationTenantPermission."Modify Permission" = SourcePermission."Read Permission"::" ") and
                               (DestinationTenantPermission."Delete Permission" = SourcePermission."Read Permission"::" ") and
                               (DestinationTenantPermission."Execute Permission" = SourcePermission."Read Permission"::" ")
                            then
                                DestinationTenantPermission.Delete();
                        until DestinationTenantPermission.Next() = 0;
                end;
        end;
    end;

    local procedure IncludeExcludeTenantPermission(SourceTenantPermission: Record "Tenant Permission")
    var
        DestinationTenantPermission: Record "Tenant Permission";
    begin
        case SetOperation of
            SetOperation::Include:
                if DestinationTenantPermission.Get(
                     DestinationAggregatePermissionSet."App ID", DestinationAggregatePermissionSet."Role ID",
                     SourceTenantPermission."Object Type", SourceTenantPermission."Object ID")
                then begin
                    if PermissionValueIsGreaterOrEqual(SourceTenantPermission."Read Permission", DestinationTenantPermission."Read Permission") then
                        DestinationTenantPermission."Read Permission" := SourceTenantPermission."Read Permission";
                    if PermissionValueIsGreaterOrEqual(
                         SourceTenantPermission."Insert Permission", DestinationTenantPermission."Insert Permission")
                    then
                        DestinationTenantPermission."Insert Permission" := SourceTenantPermission."Insert Permission";
                    if PermissionValueIsGreaterOrEqual(
                         SourceTenantPermission."Modify Permission", DestinationTenantPermission."Modify Permission")
                    then
                        DestinationTenantPermission."Modify Permission" := SourceTenantPermission."Modify Permission";
                    if PermissionValueIsGreaterOrEqual(
                         SourceTenantPermission."Delete Permission", DestinationTenantPermission."Delete Permission")
                    then
                        DestinationTenantPermission."Delete Permission" := SourceTenantPermission."Delete Permission";
                    if PermissionValueIsGreaterOrEqual(
                         SourceTenantPermission."Execute Permission", DestinationTenantPermission."Execute Permission")
                    then
                        DestinationTenantPermission."Execute Permission" := SourceTenantPermission."Execute Permission";
                    DestinationTenantPermission.Modify();
                end else begin
                    DestinationTenantPermission := SourceTenantPermission;
                    DestinationTenantPermission."Role ID" := DestinationAggregatePermissionSet."Role ID";
                    DestinationTenantPermission."App ID" := DestinationAggregatePermissionSet."App ID";
                    DestinationTenantPermission.Insert();
                end;
            SetOperation::Exclude:
                begin
                    DestinationTenantPermission.SetRange("App ID", DestinationAggregatePermissionSet."App ID");
                    DestinationTenantPermission.SetRange("Role ID", DestinationAggregatePermissionSet."Role ID");
                    DestinationTenantPermission.SetRange("Object Type", SourceTenantPermission."Object Type");
                    if SourceTenantPermission."Object ID" <> 0 then
                        DestinationTenantPermission.SetRange("Object ID", SourceTenantPermission."Object ID");
                    if DestinationTenantPermission.FindSet() then
                        repeat
                            if PermissionValueIsGreaterOrEqual(
                                 SourceTenantPermission."Read Permission", DestinationTenantPermission."Read Permission")
                            then
                                DestinationTenantPermission."Read Permission" := SourceTenantPermission."Read Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(
                                 SourceTenantPermission."Insert Permission", DestinationTenantPermission."Insert Permission")
                            then
                                DestinationTenantPermission."Insert Permission" := SourceTenantPermission."Insert Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(
                                 SourceTenantPermission."Modify Permission", DestinationTenantPermission."Modify Permission")
                            then
                                DestinationTenantPermission."Modify Permission" := SourceTenantPermission."Modify Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(
                                 SourceTenantPermission."Delete Permission", DestinationTenantPermission."Delete Permission")
                            then
                                DestinationTenantPermission."Delete Permission" := SourceTenantPermission."Delete Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(
                                 SourceTenantPermission."Execute Permission", DestinationTenantPermission."Execute Permission")
                            then
                                DestinationTenantPermission."Execute Permission" := SourceTenantPermission."Execute Permission"::" ";
                            DestinationTenantPermission.Modify();
                            if (DestinationTenantPermission."Read Permission" = SourceTenantPermission."Read Permission"::" ") and
                               (DestinationTenantPermission."Insert Permission" = SourceTenantPermission."Read Permission"::" ") and
                               (DestinationTenantPermission."Modify Permission" = SourceTenantPermission."Read Permission"::" ") and
                               (DestinationTenantPermission."Delete Permission" = SourceTenantPermission."Read Permission"::" ") and
                               (DestinationTenantPermission."Execute Permission" = SourceTenantPermission."Read Permission"::" ")
                            then
                                DestinationTenantPermission.Delete();
                        until DestinationTenantPermission.Next() = 0;
                end;
        end;
    end;

    local procedure IncludeExcludePermissionInPermission(SourcePermission: Record Permission)
    var
        DestinationPermission: Record Permission;
    begin
        case SetOperation of
            SetOperation::Include:
                if DestinationPermission.Get(
                     DestinationAggregatePermissionSet."Role ID", SourcePermission."Object Type", SourcePermission."Object ID")
                then begin
                    if PermissionValueIsGreaterOrEqual(SourcePermission."Read Permission", DestinationPermission."Read Permission") then
                        DestinationPermission."Read Permission" := SourcePermission."Read Permission";
                    if PermissionValueIsGreaterOrEqual(SourcePermission."Insert Permission", DestinationPermission."Insert Permission") then
                        DestinationPermission."Insert Permission" := SourcePermission."Insert Permission";
                    if PermissionValueIsGreaterOrEqual(SourcePermission."Modify Permission", DestinationPermission."Modify Permission") then
                        DestinationPermission."Modify Permission" := SourcePermission."Modify Permission";
                    if PermissionValueIsGreaterOrEqual(SourcePermission."Delete Permission", DestinationPermission."Delete Permission") then
                        DestinationPermission."Delete Permission" := SourcePermission."Delete Permission";
                    if PermissionValueIsGreaterOrEqual(SourcePermission."Execute Permission", DestinationPermission."Execute Permission") then
                        DestinationPermission."Execute Permission" := SourcePermission."Execute Permission";
                    DestinationPermission.Modify();
                end else begin
                    DestinationPermission."Object ID" := SourcePermission."Object ID";
                    DestinationPermission."Object Type" := SourcePermission."Object Type";
                    DestinationPermission."Read Permission" := SourcePermission."Read Permission";
                    DestinationPermission."Insert Permission" := SourcePermission."Insert Permission";
                    DestinationPermission."Modify Permission" := SourcePermission."Modify Permission";
                    DestinationPermission."Delete Permission" := SourcePermission."Delete Permission";
                    DestinationPermission."Execute Permission" := SourcePermission."Execute Permission";
                    DestinationPermission."Security Filter" := SourcePermission."Security Filter";
                    DestinationPermission."Role ID" := DestinationAggregatePermissionSet."Role ID";
                    DestinationPermission.Insert();
                end;
            SetOperation::Exclude:
                begin
                    DestinationPermission.SetRange("Role ID", DestinationAggregatePermissionSet."Role ID");
                    DestinationPermission.SetRange("Object Type", SourcePermission."Object Type");
                    if SourcePermission."Object ID" <> 0 then
                        DestinationPermission.SetRange("Object ID", SourcePermission."Object ID");
                    if DestinationPermission.FindSet() then
                        repeat
                            if PermissionValueIsGreaterOrEqual(SourcePermission."Read Permission", DestinationPermission."Read Permission") then
                                DestinationPermission."Read Permission" := SourcePermission."Read Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(SourcePermission."Insert Permission", DestinationPermission."Insert Permission") then
                                DestinationPermission."Insert Permission" := SourcePermission."Insert Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(SourcePermission."Modify Permission", DestinationPermission."Modify Permission") then
                                DestinationPermission."Modify Permission" := SourcePermission."Modify Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(SourcePermission."Delete Permission", DestinationPermission."Delete Permission") then
                                DestinationPermission."Delete Permission" := SourcePermission."Delete Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(
                                 SourcePermission."Execute Permission", DestinationPermission."Execute Permission")
                            then
                                DestinationPermission."Execute Permission" := SourcePermission."Execute Permission"::" ";
                            DestinationPermission.Modify();
                            if (DestinationPermission."Read Permission" = SourcePermission."Read Permission"::" ") and
                               (DestinationPermission."Insert Permission" = SourcePermission."Read Permission"::" ") and
                               (DestinationPermission."Modify Permission" = SourcePermission."Read Permission"::" ") and
                               (DestinationPermission."Delete Permission" = SourcePermission."Read Permission"::" ") and
                               (DestinationPermission."Execute Permission" = SourcePermission."Read Permission"::" ")
                            then
                                DestinationPermission.Delete();
                        until DestinationPermission.Next() = 0;
                end;
        end;
    end;

    local procedure IncludeExcludeTenantPermissionInPermission(SourceTenantPermission: Record "Tenant Permission")
    var
        DestinationPermission: Record Permission;
    begin
        case SetOperation of
            SetOperation::Include:
                if DestinationPermission.Get(
                     DestinationAggregatePermissionSet."Role ID", SourceTenantPermission."Object Type", SourceTenantPermission."Object ID")
                then begin
                    if PermissionValueIsGreaterOrEqual(SourceTenantPermission."Read Permission", DestinationPermission."Read Permission") then
                        DestinationPermission."Read Permission" := SourceTenantPermission."Read Permission";
                    if PermissionValueIsGreaterOrEqual(
                         SourceTenantPermission."Insert Permission", DestinationPermission."Insert Permission")
                    then
                        DestinationPermission."Insert Permission" := SourceTenantPermission."Insert Permission";
                    if PermissionValueIsGreaterOrEqual(
                         SourceTenantPermission."Modify Permission", DestinationPermission."Modify Permission")
                    then
                        DestinationPermission."Modify Permission" := SourceTenantPermission."Modify Permission";
                    if PermissionValueIsGreaterOrEqual(
                         SourceTenantPermission."Delete Permission", DestinationPermission."Delete Permission")
                    then
                        DestinationPermission."Delete Permission" := SourceTenantPermission."Delete Permission";
                    if PermissionValueIsGreaterOrEqual(
                         SourceTenantPermission."Execute Permission", DestinationPermission."Execute Permission")
                    then
                        DestinationPermission."Execute Permission" := SourceTenantPermission."Execute Permission";
                    DestinationPermission.Modify();
                end else begin
                    DestinationPermission."Object ID" := SourceTenantPermission."Object ID";
                    DestinationPermission."Object Type" := SourceTenantPermission."Object Type";
                    DestinationPermission."Read Permission" := SourceTenantPermission."Read Permission";
                    DestinationPermission."Insert Permission" := SourceTenantPermission."Insert Permission";
                    DestinationPermission."Modify Permission" := SourceTenantPermission."Modify Permission";
                    DestinationPermission."Delete Permission" := SourceTenantPermission."Delete Permission";
                    DestinationPermission."Execute Permission" := SourceTenantPermission."Execute Permission";
                    DestinationPermission."Security Filter" := SourceTenantPermission."Security Filter";
                    DestinationPermission."Role ID" := DestinationAggregatePermissionSet."Role ID";
                    DestinationPermission.Insert();
                end;
            SetOperation::Exclude:
                begin
                    DestinationPermission.SetRange("Role ID", DestinationAggregatePermissionSet."Role ID");
                    DestinationPermission.SetRange("Object Type", SourceTenantPermission."Object Type");
                    if SourceTenantPermission."Object ID" <> 0 then
                        DestinationPermission.SetRange("Object ID", SourceTenantPermission."Object ID");
                    if DestinationPermission.FindSet() then
                        repeat
                            if PermissionValueIsGreaterOrEqual(
                                 SourceTenantPermission."Read Permission", DestinationPermission."Read Permission")
                            then
                                DestinationPermission."Read Permission" := SourceTenantPermission."Read Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(
                                 SourceTenantPermission."Insert Permission", DestinationPermission."Insert Permission")
                            then
                                DestinationPermission."Insert Permission" := SourceTenantPermission."Insert Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(
                                 SourceTenantPermission."Modify Permission", DestinationPermission."Modify Permission")
                            then
                                DestinationPermission."Modify Permission" := SourceTenantPermission."Modify Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(
                                 SourceTenantPermission."Delete Permission", DestinationPermission."Delete Permission")
                            then
                                DestinationPermission."Delete Permission" := SourceTenantPermission."Delete Permission"::" ";
                            if PermissionValueIsGreaterOrEqual(
                                 SourceTenantPermission."Execute Permission", DestinationPermission."Execute Permission")
                            then
                                DestinationPermission."Execute Permission" := SourceTenantPermission."Execute Permission"::" ";
                            DestinationPermission.Modify();
                            if (DestinationPermission."Read Permission" = SourceTenantPermission."Read Permission"::" ") and
                               (DestinationPermission."Insert Permission" = SourceTenantPermission."Read Permission"::" ") and
                               (DestinationPermission."Modify Permission" = SourceTenantPermission."Read Permission"::" ") and
                               (DestinationPermission."Delete Permission" = SourceTenantPermission."Read Permission"::" ") and
                               (DestinationPermission."Execute Permission" = SourceTenantPermission."Read Permission"::" ")
                            then
                                DestinationPermission.Delete();
                        until DestinationPermission.Next() = 0;
                end;
        end;
    end;
}

