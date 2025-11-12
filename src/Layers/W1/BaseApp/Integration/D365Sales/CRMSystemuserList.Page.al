// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.CRM.Team;
using Microsoft.Integration.Dataverse;

page 5340 "CRM Systemuser List"
{
    Caption = 'Users - Dataverse';
    AdditionalSearchTerms = 'Users CDS, Users Common Data Service';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "CRM Systemuser";
    SourceTableView = sorting(FullName) where(IsIntegrationUser = const(false), IsDisabled = const(false), IsLicensed = const(true));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(FullName; Rec.FullName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Name';
                    Editable = false;
                    StyleExpr = FirstColumnStyle;
                    ToolTip = 'Specifies data from a corresponding field in a Dataverse entity. For more information about Dataverse, see Dataverse Help Center.';
                }
                field(InternalEMailAddress; Rec.InternalEMailAddress)
                {
                    ApplicationArea = Suite;
                    Caption = 'Email Address';
                    Editable = false;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address.';
                }
                field(MobilePhone; Rec.MobilePhone)
                {
                    ApplicationArea = Suite;
                    Caption = 'Mobile Phone';
                    Editable = false;
                    ToolTip = 'Specifies data from a corresponding field in a Dataverse entity. For more information about Dataverse, see Dataverse Help Center.';
                }
                field(Coupled; Coupled)
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled';
                    Editable = false;
                    OptionCaption = 'Yes,No,Current';
                    ToolTip = 'Specifies if the Dataverse record is coupled to Business Central.';
                }
                field(SalespersonPurchaserCode; TempCRMSystemuser.FirstName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Salesperson/Purchaser Code';
                    Enabled = ShowCouplingControls;
                    TableRelation = "Salesperson/Purchaser".Code;
                    ToolTip = 'Specifies the code for the salesperson or purchaser.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        SalespersonPurchaser: Record "Salesperson/Purchaser";
                        SalespersonsPurchasers: Page "Salespersons/Purchasers";
                    begin
                        SalespersonsPurchasers.LookupMode(true);
                        if SalespersonsPurchasers.RunModal() = ACTION::LookupOK then begin
                            SalespersonsPurchasers.GetRecord(SalespersonPurchaser);
                            InsertUpdateTempCRMSystemUser(SalespersonPurchaser.Code, true);
                            CleanDuplicateSalespersonRecords(SalespersonPurchaser.Code, Rec.SystemUserId);
                        end;
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    var
                        SalespersonPurchaser: Record "Salesperson/Purchaser";
                    begin
                        if TempCRMSystemuser.FirstName <> '' then begin
                            SalespersonPurchaser.Get(TempCRMSystemuser.FirstName);
                            InsertUpdateTempCRMSystemUser(SalespersonPurchaser.Code, true);
                            CleanDuplicateSalespersonRecords(SalespersonPurchaser.Code, Rec.SystemUserId);
                        end else
                            if (TempCRMSystemuser.FirstName = '') and (Coupled = Coupled::Yes) then
                                InsertUpdateTempCRMSystemUser('', true);
                        CurrPage.Update(false);
                    end;
                }
                field(TeamMember; TeamMember)
                {
                    ApplicationArea = Suite;
                    Caption = 'Default Team Member';
                    OptionCaption = 'No,Yes';
                    Visible = IsCDSIntegrationEnabled;
                    Editable = false;
                    ToolTip = 'Specifies whether the user is associated with the default team in Dataverse.';
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action(CreateFromCRM)
            {
                ApplicationArea = Suite;
                Caption = 'Create Salesperson in Business Central';
                Image = NewCustomer;
                ToolTip = 'Create the Dataverse user as a salesperson in Business Central.';

                trigger OnAction()
                var
                    CRMSystemuser: Record "CRM Systemuser";
                begin
                    CurrPage.SetSelectionFilter(CRMSystemuser);
                    if not CRMIntegrationManagement.HasUncoupledSelectedUsers(CRMSystemuser) then
                        exit;

                    CRMIntegrationManagement.CreateNewRecordsFromSelectedCRMRecords(CRMSystemuser);
                    HasCoupled := true;

                    if IsCDSIntegrationEnabled then
                        exit;

                    if Confirm(AddScheduledCoupledUsersToTeamQst) then
                        AddUsersToDefaultOwningTeam(CRMSystemuser, false);
                end;
            }
            action(Couple)
            {
                ApplicationArea = Suite;
                Caption = 'Couple';
                Image = LinkAccount;
                ToolTip = 'Link the user in Dataverse to a salesperson in Business Central.';
                Visible = ShowCouplingControls;

                trigger OnAction()
                var
                    TempSelectedCRMSystemuser: Record "CRM Systemuser" temporary;
                begin
                    if IsCDSIntegrationEnabled then
                        GetNotInTeamCoupledUsers(TempSelectedCRMSystemuser, true);

                    LinkUsersToSalespersons();

                    if IsCDSIntegrationEnabled then
                        if not TempSelectedCRMSystemuser.IsEmpty() then
                            if Confirm(AddRecentlyCoupledUsersToTeamQst) then
                                AddUsersToDefaultOwningTeam(TempSelectedCRMSystemuser, true);
                end;
            }
            action(DeleteCDSCoupling)
            {
                AccessByPermission = TableData "CRM Integration Record" = D;
                ApplicationArea = Suite;
                Caption = 'Uncouple';
                Image = UnLinkAccount;
                ToolTip = 'Delete the coupling between the user in Dataverse and salesperson in Business Central.';
                Visible = ShowCouplingControls;

                trigger OnAction()
                var
                    CRMSystemuser: Record "CRM Systemuser";
                    CRMIntegrationRecord: Record "CRM Integration Record";
                    SalesPersonRecordID: RecordId;
                    SelectedNotCoupledUsersFullNameList: Text;
                    TextLength: Integer;
                begin
                    CurrPage.SetSelectionFilter(CRMSystemuser);
                    if not CRMSystemuser.FindSet() then
                        Error(NoSelectedUserErr);
                    repeat
                        if not CRMIntegrationRecord.FindRecordIDFromID(CRMSystemuser.SystemUserId, DATABASE::"Salesperson/Purchaser", SalesPersonRecordID) then
                            SelectedNotCoupledUsersFullNameList := SelectedNotCoupledUsersFullNameList + CRMSystemuser.FullName + ', '
                        else
                            CRMIntegrationManagement.RemoveCoupling(SalesPersonRecordID, false);
                    until CRMSystemuser.Next() = 0;

                    TextLength := StrLen(SelectedNotCoupledUsersFullNameList);
                    if TextLength > 0 then
                        Message(StrSubstNo(UserIsNotCoupledErr, CopyStr(SelectedNotCoupledUsersFullNameList, 1, TextLength - 2) + ' '));
                    Commit();
                end;
            }
            action(AddCoupledUsersToTeam)
            {
                ApplicationArea = Suite;
                Caption = 'Add coupled users to team';
                Image = LinkAccount;
                Visible = IsCDSIntegrationEnabled;
                ToolTip = 'Add the coupled Dataverse users to the default owning team.';

                trigger OnAction()
                var
                    CRMSystemuser: Record "CRM Systemuser";
                begin
                    CurrPage.SetSelectionFilter(CRMSystemuser);
                    AddUsersToDefaultOwningTeam(CRMSystemuser, true);
                end;
            }
            action(ShowOnlyUncoupled)
            {
                ApplicationArea = Suite;
                Caption = 'Hide Coupled Users';
                Image = FilterLines;
                ToolTip = 'Do not show coupled users.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(true);
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = Suite;
                Caption = 'Show Coupled Users';
                Image = ClearFilter;
                ToolTip = 'Show coupled users.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CreateFromCRM_Promoted; CreateFromCRM)
                {
                }
                actionref(Couple_Promoted; Couple)
                {
                }
                actionref(DeleteCDSCoupling_Promoted; DeleteCDSCoupling)
                {
                }
                actionref(AddCoupledUsersToTeam_Promoted; AddCoupledUsersToTeam)
                {
                }
                actionref(ShowOnlyUncoupled_Promoted; ShowOnlyUncoupled)
                {
                }
                actionref(ShowAll_Promoted; ShowAll)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        RecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(Rec.SystemUserId, DATABASE::"Salesperson/Purchaser", RecordID) then begin
            if SalespersonPurchaser.Get(RecordID) then
                InsertUpdateTempCRMSystemUser(SalespersonPurchaser.Code, false)
            else
                InsertUpdateTempCRMSystemUser('', false);
            if CurrentlyCoupledCRMSystemuser.SystemUserId = Rec.SystemUserId then begin
                Coupled := Coupled::Current;
                FirstColumnStyle := 'Strong';
                Rec.Mark(true);
            end else begin
                Coupled := Coupled::Yes;
                FirstColumnStyle := 'Subordinate';
                Rec.Mark(false);
            end
        end else begin
            InsertUpdateTempCRMSystemUser('', false);
            Coupled := Coupled::No;
            FirstColumnStyle := 'None';
            Rec.Mark(true);
        end;
        if IsCDSIntegrationEnabled then begin
            TempCDSTeammembership.SetRange(SystemUserId, Rec.SystemUserId);
            if not TempCDSTeammembership.IsEmpty() then
                TeamMember := TeamMember::Yes
            else
                TeamMember := TeamMember::No;
        end;
    end;

    trigger OnInit()
    begin
        Coupled := Coupled::No;
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");

        if CDSConnectionSetup.Get() then begin
            IsCDSIntegrationEnabled := CDSConnectionSetup."Is Enabled";
            if IsCDSIntegrationEnabled then
                CDSIntegrationImpl.GetDefaultOwningTeamMembership(CDSConnectionSetup, TempCDSTeammembership);
        end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TempSelectedCRMSystemuser: Record "CRM Systemuser" temporary;
        CloseWithoutAskingAboutUncoupledUsers: Boolean;
    begin
        if not (CloseAction in [CloseAction::LookupOK, CloseAction::LookupCancel]) then begin
            if HasCoupled then
                CloseWithoutAskingAboutUncoupledUsers := true
            else
                CloseWithoutAskingAboutUncoupledUsers := not HasUncoupled();

            if CloseWithoutAskingAboutUncoupledUsers then begin
                if not IsCDSIntegrationEnabled then
                    exit(true);

                if not HasCoupledNotInTeam() then
                    exit(true);

                if Confirm(ClosePageCoupledUserNotInTeamTxt, true) then begin
                    GetNotInTeamCoupledUsers(TempSelectedCRMSystemuser, false);
                    AddUsersToDefaultOwningTeam(TempSelectedCRMSystemuser, true);
                end;

                exit(true);
            end;

            if Confirm(ClosePageUncoupledUserTxt, true) then
                exit(true);

            exit(false);
        end;
        exit(true);
    end;

    var
        CurrentlyCoupledCRMSystemuser: Record "CRM Systemuser";
        TempCRMSystemuser: Record "CRM Systemuser" temporary;
        TempCDSTeammembership: Record "CDS Teammembership" temporary;
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        IsCDSIntegrationEnabled: Boolean;
        TeamMember: Option No,Yes;
        Coupled: Option Yes,No,Current;
        FirstColumnStyle: Text;
        AddScheduledCoupledUsersToTeamQst: Label 'New salespeople are scheduled to be coupled.\\Do you want to add the users they are coupled with in Dataverse to the default owning team so that they can access the synchronized data?';
        AddRecentlyCoupledUsersToTeamQst: Label 'Users in Dataverse were linked to salespeople.\\ Do you want to add them to the default owning team so that they can access the synchronized data?';
        ClosePageCoupledUserNotInTeamTxt: Label 'Some coupled users are not added to the default owning team in Dataverse and might not have access to synchronized data.\\Do you want to add them now?';
        ClosePageUncoupledUserTxt: Label 'No Salespeople were scheduled for coupling.\\Are you sure you want to exit?';
        NoSelectedUserErr: Label 'No record has been selected for uncoupling.';
        UserIsNotCoupledErr: Label 'The user/s %1is/are not coupled. The uncoupling action for those users will be skipped.', Comment = '%1- A list of CRMSystemuser full names';
        ShowCouplingControls: Boolean;
        HasCoupled: Boolean;

    procedure SetCurrentlyCoupledCRMSystemuser(CRMSystemuser: Record "CRM Systemuser")
    begin
        CurrentlyCoupledCRMSystemuser := CRMSystemuser;
    end;

    local procedure LinkUsersToSalespersons(): Integer
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        OldRecordId: RecordID;
        Synchronize: Boolean;
        Direction: Option;
    begin
        TempCRMSystemuser.Reset();
        TempCRMSystemuser.SetRange(IsSyncWithDirectory, true);
        if TempCRMSystemuser.FindSet() then begin
            HasCoupled := true;
            repeat
                if TempCRMSystemuser.FirstName <> '' then begin
                    SalespersonPurchaser.Get(TempCRMSystemuser.FirstName);
                    CRMIntegrationManagement.CoupleCRMEntity(
                      SalespersonPurchaser.RecordId, TempCRMSystemuser.SystemUserId, Synchronize, Direction);
                end else begin
                    CRMIntegrationRecord.FindRecordIDFromID(
                      TempCRMSystemuser.SystemUserId, DATABASE::"Salesperson/Purchaser", OldRecordId);
                    CRMCouplingManagement.RemoveCoupling(OldRecordId);
                end;
            until TempCRMSystemuser.Next() = 0;
        end;
        TempCRMSystemuser.ModifyAll(IsSyncWithDirectory, false);
        TempCRMSystemuser.ModifyAll(IsDisabled, false);
    end;

    local procedure GetNotInTeamCoupledUsers(var TempSelectedCRMSystemuser: Record "CRM Systemuser" temporary; NewlyCoupledOnly: Boolean)
    begin
        TempCRMSystemuser.Reset();
        if NewlyCoupledOnly then
            TempCRMSystemuser.SetRange(IsSyncWithDirectory, true);
        TempCRMSystemuser.SetFilter(FirstName, '<>%1', '');
        if TempCRMSystemuser.FindSet() then
            repeat
                TempCDSTeammembership.SetRange(SystemUserId, TempCRMSystemuser.SystemUserId);
                if TempCDSTeammembership.IsEmpty() then begin
                    TempSelectedCRMSystemuser.Init();
                    TempSelectedCRMSystemuser.TransferFields(TempCRMSystemuser);
                    TempSelectedCRMSystemuser.Insert();
                end;
            until TempCRMSystemuser.Next() = 0;
    end;

    local procedure AddUsersToDefaultOwningTeam(var CRMSystemuser: Record "CRM Systemuser"; CoupledOnly: Boolean): Integer
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        TempSelectedCRMSystemuser: Record "CRM Systemuser" temporary;
        UserId: Guid;
        Selected: Integer;
        IsCoupled: Boolean;
        Skip: Boolean;
    begin
        if not CDSConnectionSetup.Get() then
            exit;

        if not CRMSystemuser.FindSet() then
            exit;

        CRMIntegrationRecord.SetRange("Table ID", Database::"Salesperson/Purchaser");

        repeat
            UserId := CRMSystemuser.SystemUserId;
            TempCDSTeammembership.SetRange(SystemUserId, UserId);
            if TempCDSTeammembership.IsEmpty() then begin
                if CoupledOnly then begin
                    CRMIntegrationRecord.SetRange("CRM ID", UserId);
                    IsCoupled := not CRMIntegrationRecord.IsEmpty();
                end;
                Skip := (not CoupledOnly) or (CoupledOnly and (not IsCoupled));
                if not Skip then begin
                    TempSelectedCRMSystemuser.Init();
                    TempSelectedCRMSystemuser.TransferFields(CRMSystemuser);
                    TempSelectedCRMSystemuser.Insert();
                    Selected += 1;
                end;
            end;
        until CRMSystemuser.Next() = 0;

        if Selected > 0 then begin
            CDSIntegrationImpl.AddUsersToDefaultOwningTeam(CDSConnectionSetup, TempSelectedCRMSystemuser);
            CDSIntegrationImpl.GetDefaultOwningTeamMembership(CDSConnectionSetup, TempCDSTeammembership);
        end;

        exit(Selected);
    end;

    local procedure InsertUpdateTempCRMSystemUser(SalespersonCode: Code[20]; SyncNeeded: Boolean)
    begin
        // FirstName is used to store coupled/ready to couple Salesperson
        // IsSyncWithDirectory is used to mark CRM User for coupling
        if TempCRMSystemuser.Get(Rec.SystemUserId) then begin
            if not TempCRMSystemuser.IsDisabled or SyncNeeded then begin
                TempCRMSystemuser.FirstName := SalespersonCode;
                TempCRMSystemuser.IsSyncWithDirectory := SyncNeeded;
                TempCRMSystemuser.IsDisabled := SyncNeeded;
                TempCRMSystemuser.Modify();
            end
        end else begin
            TempCRMSystemuser.SystemUserId := Rec.SystemUserId;
            TempCRMSystemuser.FirstName := SalespersonCode;
            TempCRMSystemuser.IsSyncWithDirectory := SyncNeeded;
            TempCRMSystemuser.IsDisabled := SyncNeeded;
            TempCRMSystemuser.Insert();
        end;
    end;

    local procedure CleanDuplicateSalespersonRecords(SalesPersonCode: Code[20]; CRMUserId: Guid)
    begin
        TempCRMSystemuser.Reset();
        TempCRMSystemuser.SetRange(FirstName, SalesPersonCode);
        TempCRMSystemuser.SetFilter(SystemUserId, '<>' + Format(CRMUserId));
        if TempCRMSystemuser.FindFirst() then begin
            TempCRMSystemuser.IsDisabled := true;
            TempCRMSystemuser.FirstName := '';
            TempCRMSystemuser.Modify();
        end;
    end;

    local procedure HasUncoupled(): Boolean
    begin
        exit(HasUncoupled(TempCRMSystemuser));
    end;

    local procedure HasUncoupled(var SelectedCRMSystemuser: Record "CRM Systemuser"): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordID: RecordID;
    begin
        SelectedCRMSystemuser.Reset();
        if SelectedCRMSystemuser.FindSet() then
            repeat
                if not CRMIntegrationRecord.FindRecordIDFromID(SelectedCRMSystemuser.SystemUserId, Database::"Salesperson/Purchaser", RecordID) then
                    exit(true);
            until SelectedCRMSystemuser.Next() = 0;
        exit(false);
    end;

    local procedure HasCoupledNotInTeam(): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        UserId: Guid;
    begin
        TempCRMSystemuser.Reset();
        if TempCRMSystemuser.FindSet() then begin
            CRMIntegrationRecord.SetRange("Table ID", Database::"Salesperson/Purchaser");
            repeat
                UserId := TempCRMSystemuser.SystemUserId;
                TempCDSTeammembership.SetRange(SystemUserId, UserId);
                if TempCDSTeammembership.IsEmpty() then begin
                    CRMIntegrationRecord.SetRange("CRM ID", UserId);
                    if not CRMIntegrationRecord.IsEmpty() then
                        exit(true);
                end;
            until TempCRMSystemuser.Next() = 0;
        end;
        exit(false);
    end;

    procedure Initialize(NewShowCouplingControls: Boolean)
    begin
        ShowCouplingControls := NewShowCouplingControls;
    end;
}

