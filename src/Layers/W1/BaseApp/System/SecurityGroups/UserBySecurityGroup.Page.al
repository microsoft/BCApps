// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;
using System.Agents;
using System.Security.User;
using System.Text;

page 9887 "User by Security Group"
{
    Caption = 'User by Security Group';
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = User;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    AboutTitle = 'About User by Security Group';
    AboutText = 'Get an overview of how users are assigned to your security groups, a user can be a member of multiple security groups at the same time. Security group membership can be managed in the M365 admin centre or the Azure portal.';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'Filters';
                field(SecurityGroupFilter; SecurityGroupFilter)
                {
                    Caption = 'Security Group';
                    ToolTip = 'Specifies the security group filter.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TempSecurityGroupBuffer: Record "Security Group Buffer";
                        SecurityGroups: Page "Security Groups";
                        RecRef: RecordRef;
                    begin
                        SecurityGroups.LookupMode(true);
                        if SecurityGroups.RunModal() = Action::LookupOK then begin
                            SecurityGroup.GetGroups(TempSecurityGroupBuffer, false);
                            SecurityGroups.GetSelectionFilter(TempSecurityGroupBuffer);
                            RecRef.GetTable(TempSecurityGroupBuffer);
                            Text := SelectionFilterMgt.GetSelectionFilter(RecRef, TempSecurityGroupBuffer.FieldNo(Code));
                            SecurityGroupFilter := Text;
                            LoadData(true);
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        LoadData(true);
                    end;
                }
                field(UserFilter; UserFilter)
                {
                    Caption = 'User';
                    ToolTip = 'Specifies the user filter.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        User: Record User;
                        Users: Page Users;
                        RecRef: RecordRef;
                    begin
                        Users.LookupMode(true);
                        if Users.RunModal() = Action::LookupOK then begin
                            Users.GetSelectionFilter(User);
                            RecRef.GetTable(User);
                            Text := SelectionFilterMgt.GetSelectionFilter(RecRef, User.FieldNo("User Name"));
                            UserFilter := Text;
                            Rec.SetFilter("User Name", UserFilter);
                            CurrPage.Update(false);
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        Rec.SetFilter("User Name", UserFilter);
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Users)
            {
                Editable = false;
                field("User Name"; Rec."User Name")
                {
                    ToolTip = 'Specifies the user''s name.';
                    trigger OnDrillDown()
                    begin
                        Page.Run(0, Rec);
                    end;
                }
                field(IsSecurityGroupMember1; IsSecurityGroupMember[1])
                {
                    CaptionClass = '3,' + SecurityGroupCodes[1];
                    Visible = IsColumn1Visible;
                    ToolTip = 'Specifies whether the user is a member of this security group.';
                }
                field(IsSecurityGroupMember2; IsSecurityGroupMember[2])
                {
                    CaptionClass = '3,' + SecurityGroupCodes[2];
                    Visible = IsColumn2Visible;
                    ToolTip = 'Specifies whether the user is a member of this security group.';
                }
                field(IsSecurityGroupMember3; IsSecurityGroupMember[3])
                {
                    CaptionClass = '3,' + SecurityGroupCodes[3];
                    Visible = IsColumn3Visible;
                    ToolTip = 'Specifies whether the user is a member of this security group.';
                }
                field(IsSecurityGroupMember4; IsSecurityGroupMember[4])
                {
                    CaptionClass = '3,' + SecurityGroupCodes[4];
                    Visible = IsColumn4Visible;
                    ToolTip = 'Specifies whether the user is a member of this security group.';
                }
                field(IsSecurityGroupMember5; IsSecurityGroupMember[5])
                {
                    CaptionClass = '3,' + SecurityGroupCodes[5];
                    Visible = IsColumn5Visible;
                    ToolTip = 'Specifies whether the user is a member of this security group.';
                }
                field(IsSecurityGroupMember6; IsSecurityGroupMember[6])
                {
                    CaptionClass = '3,' + SecurityGroupCodes[6];
                    Visible = IsColumn6Visible;
                    ToolTip = 'Specifies whether the user is a member of this security group.';
                }
                field(IsSecurityGroupMember7; IsSecurityGroupMember[7])
                {
                    CaptionClass = '3,' + SecurityGroupCodes[7];
                    Visible = IsColumn7Visible;
                    ToolTip = 'Specifies whether the user is a member of this security group.';
                }
                field(IsSecurityGroupMember8; IsSecurityGroupMember[8])
                {
                    CaptionClass = '3,' + SecurityGroupCodes[8];
                    Visible = IsColumn8Visible;
                    ToolTip = 'Specifies whether the user is a member of this security group.';
                }
                field(IsSecurityGroupMember9; IsSecurityGroupMember[9])
                {
                    CaptionClass = '3,' + SecurityGroupCodes[9];
                    Visible = IsColumn9Visible;
                    ToolTip = 'Specifies whether the user is a member of this security group.';
                }
                field(IsSecurityGroupMember10; IsSecurityGroupMember[10])
                {
                    CaptionClass = '3,' + SecurityGroupCodes[10];
                    Visible = IsColumn10Visible;
                    ToolTip = 'Specifies whether the user is a member of this security group.';
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(Refresh)
            {
                Caption = 'Refresh';
                ToolTip = 'Refresh the data on the page based on the current filters.';
                Image = Refresh;
                trigger OnAction()
                begin
                    LoadData(true);
                end;
            }
            action(PreviousSet)
            {
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';
                Enabled = PreviousSetEnabled;
                trigger OnAction()
                begin
                    ShiftColumn(-GetColumnCount(), true);
                end;
            }
            action(NextSet)
            {
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';
                Enabled = NextSetEnabled;
                trigger OnAction()
                begin
                    ShiftColumn(GetColumnCount(), true);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Refresh_Promoted; Refresh) { }
                actionref(PreviousSet_Promoted; PreviousSet) { }
                actionref(NextSet_Promoted; NextSet) { }
            }
        }
    }

    var
        TempSecurityGroupMemberBuffer: Record "Security Group Member Buffer";
        SecurityGroup: Codeunit "Security Group";
        SelectionFilterMgt: Codeunit SelectionFilterManagement;
        SecurityGroupCodeIndices: List of [Code[20]];
        SecurityGroupFilter, UserFilter : Text;
        SecurityGroupCodes: array[10] of Code[20];
        IsSecurityGroupMember: array[10] of Boolean;
        IsColumn1Visible, IsColumn2Visible, IsColumn3Visible, IsColumn4Visible, IsColumn5Visible, IsColumn6Visible, IsColumn7Visible, IsColumn8Visible, IsColumn9Visible, IsColumn10Visible : Boolean;
        NextSetEnabled, PreviousSetEnabled : Boolean;
        ColumnOffset: Integer;

    trigger OnOpenPage()
    var
        AgentUtilities: Codeunit "Agent Utilities";
        UserSelection: Codeunit "User Selection";
    begin
        AgentUtilities.BlockPageFromBeingOpenedByAgent();

        UserSelection.HideExternalUsers(Rec);
        LoadData(false);
    end;

    local procedure LoadData(Update: Boolean)
    var
        TempSecurityGroupBuffer: Record "Security Group Buffer";
    begin
        Clear(SecurityGroupCodeIndices);
        SecurityGroup.GetGroups(TempSecurityGroupBuffer, false);
        TempSecurityGroupBuffer.SetFilter(Code, SecurityGroupFilter);
        if TempSecurityGroupBuffer.FindSet() then
            repeat
                SecurityGroupCodeIndices.Add(TempSecurityGroupBuffer.Code);
            until TempSecurityGroupBuffer.Next() = 0;
        SecurityGroup.GetMembers(TempSecurityGroupMemberBuffer);
        ShiftColumn(0, Update);
    end;

    local procedure ShiftColumn(Steps: Integer; Update: Boolean)
    var
        NextOffset: Integer;
        ColumnVisible: Boolean;
        i: Integer;
    begin
        NextOffset := ColumnOffset + Steps;
        NextSetEnabled := NextOffset + GetColumnCount() < SecurityGroupCodeIndices.Count();
        PreviousSetEnabled := NextOffset > 0;
        case true of
            NextOffset < 0:
                ColumnOffset := 0;
            NextOffset >= SecurityGroupCodeIndices.Count():
                exit;
            else
                ColumnOffset := NextOffset;
        end;
        for i := 1 to GetColumnCount() do begin
            SecurityGroupCodes[i] := '';
            ColumnVisible := false;
            if SecurityGroupCodeIndices.Get(ColumnOffset + i, SecurityGroupCodes[i]) then
                ColumnVisible := true;
            case i of
                1:
                    IsColumn1Visible := ColumnVisible;
                2:
                    IsColumn2Visible := ColumnVisible;
                3:
                    IsColumn3Visible := ColumnVisible;
                4:
                    IsColumn4Visible := ColumnVisible;
                5:
                    IsColumn5Visible := ColumnVisible;
                6:
                    IsColumn6Visible := ColumnVisible;
                7:
                    IsColumn7Visible := ColumnVisible;
                8:
                    IsColumn8Visible := ColumnVisible;
                9:
                    IsColumn9Visible := ColumnVisible;
                10:
                    IsColumn10Visible := ColumnVisible;
            end;
        end;
        if Update then
            CurrPage.Update(false);
    end;

    trigger OnAfterGetRecord()
    var
        GroupCode: Code[20];
        i: Integer;
    begin
        for i := 1 to GetColumnCount() do
            if SecurityGroupCodeIndices.Get(ColumnOffset + i, GroupCode) then
                IsSecurityGroupMember[i] := TempSecurityGroupMemberBuffer.Get(GroupCode, Rec."User Security ID")
            else
                IsSecurityGroupMember[i] := false;
    end;

    procedure GetColumnCount(): Integer
    begin
        exit(ArrayLen(IsSecurityGroupMember));
    end;
}