namespace System.Security.AccessControl;

using System.Reflection;
using System.Telemetry;

report 9802 "Copy Permission Set"
{
    Caption = 'Copy Permission Set';
    Permissions = TableData "Permission Set Link" = i;
    ProcessingOnly = true;

    dataset
    {
        dataitem(SourceAggregatePermissionSet; "Aggregate Permission Set")
        {
            DataItemTableView = sorting(Scope, "App ID", "Role ID");

            trigger OnAfterGetRecord()
            var
                PermissionSetLink: Record "Permission Set Link";
                AuditLog: Codeunit "Audit Log";
                PermissionManager: Codeunit "Permission Manager";
                PermissionSetRelation: Codeunit "Permission Set Relation";
                PermissionSetCopiedLbl: Label 'The permission set %1 has been copied by UserSecurityId %2.', Locked = true;
            begin
                PermissionSetRelation.CopyPermissionSet(InputRoleID, Name, "Role ID", "App ID", Scope, InputCopyType);

                if Scope = Scope::System then
                    if CreateLink then begin
                        PermissionSetLink.Init();
                        PermissionSetLink."Permission Set ID" := "Role ID";
                        PermissionSetLink."Linked Permission Set ID" := InputRoleID;
                        PermissionSetLink."Source Hash" := PermissionManager.GenerateHashForPermissionSet("Role ID");
                        PermissionSetLink.Insert();
                    end;
                AuditLog.LogAuditMessage(StrSubstNo(PermissionSetCopiedLbl, "App ID", UserSecurityId()), SecurityOperationResult::Success, AuditCategory::UserManagement, 2, 0);
            end;


            trigger OnPreDataItem()
            begin
                AssertTargetPermissionSetRoleIDNotEmpty(InputRoleID);
                AssertTargetPermissionSetRoleIDNotExisting(InputRoleID);
                AssertSourcePermissionSetRoleIDExists(SourceAggregatePermissionSet);
                AssertSourcePermissionSetRoleIDOnlyOne(SourceAggregatePermissionSet);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewPermissionSet; InputRoleID)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Permission Set';
                        NotBlank = true;
                        ToolTip = 'Specifies the name of the new permission set after copying.';
                    }
                    field(CopyType; InputCopyType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Copy operation';
                        ToolTip = 'Specifies the type of copy to perform.';
                    }
                    field(CreateLink; CreateLink)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Notify on Changed Permission Set';
                        Enabled = IsCreateLinkEnabled;
                        ToolTip = 'Specifies if you want to be notified when the original System permission set is changed. Note: This option is only enabled if the related notification is enabled.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            TypeHelper: Codeunit "Type Helper";
            PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
            RecordRef: RecordRef;
            FieldRef: FieldRef;
            IsScopeSystem: Boolean;
        begin
            RecordRef.GetTable(SourceAggregatePermissionSet);
            FieldRef := RecordRef.Field(SourceAggregatePermissionSet.FieldNo(Scope));
            IsScopeSystem :=
              TypeHelper.GetOptionNo(SourceAggregatePermissionSet.GetFilter(Scope), FieldRef.OptionMembers) =
              SourceAggregatePermissionSet.Scope::System;
            IsCreateLinkEnabled := IsScopeSystem and PermissionPagesMgt.AppDbPermissionChangedNotificationEnabled();
            // defaulting value of flag
            CreateLink := IsCreateLinkEnabled;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
    begin
        Message(CopySuccessMsg, InputRoleID);
    end;

    trigger OnPreReport()
    var
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();
    end;

    var
        InputRoleID: Code[20];
        InputCopyType: Enum "Permission Set Copy Type";
#pragma warning disable AA0470
        CopySuccessMsg: Label 'New permission set, %1, has been created.', Comment = 'New permission set, D365 Basic Set, has been created.';
#pragma warning restore AA0470
        MissingSourceErr: Label 'There is no permission set to copy from.';
        MultipleSourcesErr: Label 'You can only copy one permission set at a time.';
        TargetExistsErr: Label 'The new permission set already exists.';
        TargetNameMissingErr: Label 'You must specify a name for the new permission set.';
        CreateLink: Boolean;
        IsCreateLinkEnabled: Boolean;

    procedure GetNewRoleID(): Code[20]
    begin
        exit(InputRoleID);
    end;

    local procedure AssertTargetPermissionSetRoleIDNotEmpty(TargetPermissionSetRoleID: Code[20])
    begin
        if TargetPermissionSetRoleID = '' then
            Error(TargetNameMissingErr);
    end;

    local procedure AssertTargetPermissionSetRoleIDNotExisting(TargetPermissionSetRoleID: Code[20])
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AggregatePermissionSet.SetRange("Role ID", TargetPermissionSetRoleID);
        if not AggregatePermissionSet.IsEmpty() then
            Error(TargetExistsErr);
    end;

    local procedure AssertSourcePermissionSetRoleIDExists(var FromAggregatePermissionSet: Record "Aggregate Permission Set")
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AggregatePermissionSet.CopyFilters(FromAggregatePermissionSet);
        if AggregatePermissionSet.IsEmpty() then
            Error(MissingSourceErr);
    end;

    local procedure AssertSourcePermissionSetRoleIDOnlyOne(var FromAggregatePermissionSet: Record "Aggregate Permission Set")
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AggregatePermissionSet.CopyFilters(FromAggregatePermissionSet);
        if AggregatePermissionSet.Count > 1 then
            Error(MultipleSourcesErr);
    end;
}

