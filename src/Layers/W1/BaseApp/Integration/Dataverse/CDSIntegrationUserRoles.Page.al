// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;

page 7205 "CDS Integration User Roles"
{
    Caption = 'Dataverse Integration User Roles', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
    DeleteAllowed = false;
    ModifyAllowed = false;
    InsertAllowed = false;
    Editable = false;
    PageType = List;
    SourceTable = "CRM Role";
    SourceTableTemporary = true;
    SourceTableView = sorting(Name);

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;

                field("Role Name"; Rec.Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Role Name';
                    Editable = false;
                    StyleExpr = StyleExpression;
                }
                field(Assigned; IsAssigned)
                {
                    ApplicationArea = Suite;
                    Caption = 'Assigned';
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if not RequiredRoles.ContainsKey(Rec.RoleId) then begin
            StyleExpression := '';
            exit;
        end;

        IsAssigned := not IsNullGuid(Rec.SolutionId);
        if IsAssigned then
            StyleExpression := 'Favorable'
        else
            StyleExpression := 'Unfavorable';
    end;

    trigger OnInit()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMSystemuserroles: Record "CRM Systemuserroles";
        CDSRole: Record "CRM Role";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CollectedRoles: Dictionary of [Guid, Boolean];
        RequiredRoleIdList: List of [Guid];
        IntegrationUserId: Guid;
        RequiredRoleId: Guid;
        TempConnectionName: Text;
    begin
        CDSConnectionSetup.Get();
        CDSIntegrationImpl.CheckConnectionRequiredFields(CDSConnectionSetup, false);

        IntegrationUserId := CDSIntegrationImpl.GetIntegrationUserId(CDSConnectionSetup);

        TempConnectionName := CDSIntegrationImpl.GetTempConnectionName();
        CDSIntegrationImpl.RegisterConnection(CDSConnectionSetup, TempConnectionName);
        SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName, true);

        if not IsNullGuid(IntegrationUserId) then begin
            CRMSystemuserroles.SetRange(SystemUserId, IntegrationUserId);
            if CRMSystemuserroles.FindSet() then
                repeat
                    CDSRole.SetRange(RoleId, CRMSystemuserroles.RoleId);
                    if CDSRole.FindFirst() then begin
                        Rec.Init();
                        Rec.TransferFields(CDSRole);
                        Rec.Insert();
                        CollectedRoles.Add(Rec.RoleId, true);
                    end;
                until CRMSystemuserroles.Next() = 0;
        end;

        CDSIntegrationImpl.GetIntegrationRequiredRoles(RequiredRoleIdList);
        foreach RequiredRoleId in RequiredRoleIdList do begin
            if not RequiredRoles.ContainsKey(RequiredRoleId) then
                RequiredRoles.Add(RequiredRoleId, true);
            if not CollectedRoles.ContainsKey(RequiredRoleId) then begin
                Rec.Init();
                CDSRole.SetRange(RoleId, RequiredRoleId);
                if CDSRole.FindFirst() then
                    Rec.Name := CDSRole.Name
                else
                    Rec.Name := Format(RequiredRoleId);
                Rec.RoleId := RequiredRoleId;
                Rec.Insert();
                CollectedRoles.Add(Rec.RoleId, true);
            end;
        end;

        UnregisterTableConnection(TABLECONNECTIONTYPE::CRM, TempConnectionName);
    end;

    var
        RequiredRoles: Dictionary of [Guid, Boolean];
        IsAssigned: Boolean;
        StyleExpression: Text;
}

