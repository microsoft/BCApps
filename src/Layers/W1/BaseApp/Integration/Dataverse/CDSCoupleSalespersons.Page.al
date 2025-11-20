// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.CRM.Team;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using System;

page 7209 "CDS Couple Salespersons"
{
    Caption = 'Couple Dataverse Users with Salespeople', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "CRM Systemuser";
    SourceTableView = sorting(FullName) where(IsIntegrationUser = const(false), IsDisabled = const(false), IsLicensed = const(true));

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
                    Caption = 'User Name Dataverse', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
                    Editable = false;
                    ToolTip = 'Specifies data from a corresponding column in a Dataverse table.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
                }
                field(InternalEMailAddress; Rec.InternalEMailAddress)
                {
                    ApplicationArea = Suite;
                    Caption = 'Email Address';
                    Editable = false;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address.';
                }
                field(SalespersonPurchaserCode; TempCRMSystemuser.FirstName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Salesperson (Business Central)';
                    Editable = HasPermissions;
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
                    Editable = false;
                    ToolTip = 'Specifies whether the user is associated with the default team in Dataverse.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Create)
            {

                Caption = 'Create Salesperson';

                action(CreateFromCDS)
                {
                    AccessByPermission = TableData "CRM Integration Record" = IM;
                    ApplicationArea = Suite;
                    Caption = 'Create Salesperson';
                    Image = NewCustomer;
                    Enabled = HasPermissions;
                    ToolTip = 'Create the Dataverse user as a salesperson in Business Central.';

                    trigger OnAction()
                    var
                        CRMSystemuser: Record "CRM Systemuser";
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CurrPage.SetSelectionFilter(CRMSystemuser);
                        if not CRMIntegrationManagement.HasUncoupledSelectedUsers(CRMSystemuser) then
                            exit;

                        CRMIntegrationManagement.CreateNewRecordsFromSelectedCRMRecords(CRMSystemuser);
                        AddUsersToDefaultOwningTeam(CRMSystemuser, true, false);
                    end;
                }

                action(DeleteCDSCoupling)
                {
                    AccessByPermission = TableData "CRM Integration Record" = D;
                    ApplicationArea = Suite;
                    Enabled = HasPermissions;
                    Caption = 'Delete Coupling';
                    Image = UnLinkAccount;
                    ToolTip = 'Delete the coupling between the user in Dataverse and salesperson in Business Central.';

                    trigger OnAction()
                    var
                        CRMSystemuser: Record "CRM Systemuser";
                        CRMIntegrationRecord: Record "CRM Integration Record";
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        SalesPersonRecordID: RecordId;
                    begin
                        CurrPage.SetSelectionFilter(CRMSystemuser);
                        if not CRMSystemuser.FindSet() then
                            exit;
                        repeat
                            if CRMIntegrationRecord.FindRecordIDFromID(CRMSystemuser.SystemUserId, DATABASE::"Salesperson/Purchaser", SalesPersonRecordID) then
                                CRMIntegrationManagement.RemoveCoupling(SalesPersonRecordID, false);
                        until CRMSystemuser.Next() = 0;

                        Commit();
                    end;
                }
                action(MatchBasedCoupling)
                {
                    ApplicationArea = Suite;
                    Caption = 'Match-Based Coupling';
                    Enabled = HasPermissions;
                    Image = LinkAccount;
                    ToolTip = 'Couple salespeople to users in Dataverse based on criteria.';

                    trigger OnAction()
                    var
                        IntegrationTableMapping: Record "Integration Table Mapping";
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        CountTotal: Integer;
                        CountCoupled: Integer;
                    begin
                        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
                        IntegrationTableMapping.SetRange("Table ID", Database::"Salesperson/Purchaser");
                        IntegrationtableMapping.SetRange("Delete After Synchronization", false);
                        if not IntegrationTableMapping.FindFirst() then
                            exit;

                        TempCRMSystemuser.Reset();
                        CountTotal := TempCRMSystemuser.Count();
                        CountCoupled := CountAlreadyCoupled();
                        if CountCoupled = CountTotal then begin
                            Message(AllCoupledTxt);
                            exit;
                        end;

                        if not Confirm(StartMatchBasedCouplingQst) then
                            exit;

                        CRMIntegrationManagement.MatchBasedCoupling(IntegrationTableMapping."Table ID", false, false, true);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'Create', Comment = 'Generated from the PromotedActionCategories property index 0.';
            }
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CreateFromCDS_Promoted; CreateFromCDS)
                {
                }
                actionref(DeleteCDSCoupling_Promoted; DeleteCDSCoupling)
                {
                }
                actionref(MatchBasedCoupling_Promoted; MatchBasedCoupling)
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
            end else begin
                Coupled := Coupled::Yes;
                FirstColumnStyle := 'Subordinate';
            end
        end else begin
            InsertUpdateTempCRMSystemUser('', false);
            Coupled := Coupled::No;
            FirstColumnStyle := 'None';
        end;
        TempCDSTeammembership.SetRange(SystemUserId, Rec.SystemUserId);
        if not TempCDSTeammembership.IsEmpty() then
            TeamMember := TeamMember::Yes
        else
            TeamMember := TeamMember::No;
    end;

    trigger OnInit()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        HasPermissions := CRMIntegrationRecord.ReadPermission();
        Coupled := Coupled::No;
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
        CDSIntegrationImpl.GetDefaultOwningTeamMembership(TempCDSTeammembership);
        Commit();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TempNewlyCoupledCRMSystemuser: Record "CRM Systemuser" temporary;
        UsersCount: Integer;
        UsersCoupledCount: Integer;
    begin
        if CloseAction in [CloseAction::LookupOK, CloseAction::Yes, CloseAction::OK] then begin
            GetNewlyCoupledUsers(TempNewlyCoupledCRMSystemuser);
            ScheduleSalespersonsCoupling();
            AddUsersToDefaultOwningTeam(TempNewlyCoupledCRMSystemuser, false, true);
            TempCRMSystemuser.Reset();
            UsersCount := TempCRMSystemuser.Count();
            UsersCoupledCount := CountAlreadyCoupled();

            if UsersCoupledCount = UsersCount then
                exit(true);

            if Confirm(StrSubstNo(ClosePageUncoupledUserTxt, UsersCoupledCount, UsersCount), true) then begin
                ScheduleUncoupledUsersSynch();
                exit(true);
            end;
            Rec.ClearMarks();
        end;
        exit(false);
    end;

    var
        CurrentlyCoupledCRMSystemuser: Record "CRM Systemuser";
        TempCRMSystemuser: Record "CRM Systemuser" temporary;
        TempCDSTeammembership: Record "CDS Teammembership" temporary;
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CrmHelper: DotNet CrmHelper;
        Initialized: Boolean;
        TeamMember: Option No,Yes;
        Coupled: Option Yes,No,Current;
        FirstColumnStyle: Text;
        ClosePageUncoupledUserTxt: Label '%1 out of %2 users are coupled. To prevent issues in initial synchronization Business Central will create salespeople for uncoupled users, couple them and add them to default team. Would you like to continue?', Comment = '%1=No. of users that were coupled, %2=Total no. of users.';
        AllCoupledTxt: Label 'All users are coupled.';
        HasPermissions: Boolean;
        StartMatchBasedCouplingQst: Label 'You are about to couple Business Central salespeople to Dataverse users based on criteria that you define.\Refresh this page to update the status of the couplings.\\Do you want to continue?';

    procedure SetCurrentlyCoupledCRMSystemuser(CRMSystemuser: Record "CRM Systemuser")
    begin
        CurrentlyCoupledCRMSystemuser := CRMSystemuser;
    end;

    [Scope('OnPrem')]
    procedure Initialize(var NewCrmHelper: DotNet CrmHelper)
    begin
        if IsNull(NewCrmHelper) then begin
            Initialized := false;
            exit;
        end;

        CrmHelper := NewCrmHelper;
        Initialized := true;
    end;

    local procedure GetNewlyCoupledUsers(var TempNewlyCoupledCRMSystemuser: Record "CRM Systemuser" temporary): Integer
    var
        UsersCoupledCount: Integer;
    begin
        TempCRMSystemuser.Reset();
        TempCRMSystemuser.SetRange(IsSyncWithDirectory, true);
        TempCRMSystemuser.SetFilter(FirstName, '<>%1', '');
        if TempCRMSystemuser.FindSet() then begin
            UsersCoupledCount := TempCRMSystemuser.Count();
            repeat
                TempCDSTeammembership.SetRange(SystemUserId, TempCRMSystemuser.SystemUserId);
                if TempCDSTeammembership.IsEmpty() then begin
                    TempNewlyCoupledCRMSystemuser.Init();
                    TempNewlyCoupledCRMSystemuser.TransferFields(TempCRMSystemuser);
                    TempNewlyCoupledCRMSystemuser.Insert();

                end;
            until TempCRMSystemuser.Next() = 0;
        end;
        exit(UsersCoupledCount);
    end;

    local procedure AddUsersToDefaultOwningTeam(var CRMSystemuser: Record "CRM Systemuser"; SkipCoupled: Boolean; SkipUncoupled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMIntegrationRecord: Record "CRM Integration Record";
        TempSelectedCRMSystemuser: Record "CRM Systemuser" temporary;
        Selected: Integer;
        IsCoupled: Boolean;
        Skip: Boolean;
    begin
        if not Initialized then
            exit;

        if not CDSConnectionSetup.Get() then
            exit;

        if not CRMSystemuser.FindSet() then
            exit;

        CRMIntegrationRecord.SetRange("Table ID", Database::"Salesperson/Purchaser");

        repeat
            TempCDSTeammembership.SetRange(SystemUserId, CRMSystemuser.SystemUserId);
            if TempCDSTeammembership.IsEmpty() then begin
                CRMIntegrationRecord.SetRange("CRM ID", CRMSystemuser.SystemUserId);
                IsCoupled := not CRMIntegrationRecord.IsEmpty();
                Skip := (SkipCoupled and IsCoupled) or (SkipUncoupled and (not IsCoupled));
                if not Skip then begin
                    TempSelectedCRMSystemuser.Init();
                    TempSelectedCRMSystemuser.TransferFields(CRMSystemuser);
                    TempSelectedCRMSystemuser.Insert();
                    Selected += 1;
                end;
            end;
        until CRMSystemuser.Next() = 0;

        if Selected > 0 then begin
            CDSIntegrationImpl.AddUsersToDefaultOwningTeam(CDSConnectionSetup, CrmHelper, TempSelectedCRMSystemuser);
            CDSIntegrationImpl.GetDefaultOwningTeamMembership(CDSConnectionSetup, TempCDSTeammembership);
        end;
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
            TempCRMSystemuser.Init();
            TempCRMSystemuser.SystemUserId := Rec.SystemUserId;
            TempCRMSystemuser.FirstName := SalespersonCode;
            TempCRMSystemuser.IsSyncWithDirectory := SyncNeeded;
            TempCRMSystemuser.IsDisabled := SyncNeeded;
            TempCRMSystemuser.Insert();
        end;
    end;

    local procedure CountAlreadyCoupled(): Integer
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordID: RecordID;
        CoupledUsersCount: Integer;
    begin
        TempCRMSystemuser.Reset();
        if TempCRMSystemuser.FindSet() then
            repeat
                if CRMIntegrationRecord.FindRecordIDFromID(TempCRMSystemuser.SystemUserId, Database::"Salesperson/Purchaser", RecordID) then
                    CoupledUsersCount := CoupledUsersCount + 1
                else begin
                    Rec.get(TempCRMSystemuser.SystemUserId);
                    Rec.Mark(true);
                end;
            until TempCRMSystemuser.Next() = 0;
        exit(CoupledUsersCount);
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

    local procedure ScheduleSalespersonsCoupling()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        OldRecordId: RecordID;
        Synchronize: Boolean;
        Direction: Option;
    begin
        TempCRMSystemuser.Reset();
        TempCRMSystemuser.SetRange(IsSyncWithDirectory, true);
        if TempCRMSystemuser.FindSet() then
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

        TempCRMSystemuser.ModifyAll(IsSyncWithDirectory, false);
        TempCRMSystemuser.ModifyAll(IsDisabled, false);
    end;

    local procedure ScheduleUncoupledUsersSynch()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        Rec.MarkedOnly();
        CRMIntegrationManagement.CreateNewRecordsFromSelectedCRMRecords(Rec);
        AddUsersToDefaultOwningTeam(Rec, true, false);
    end;
}
