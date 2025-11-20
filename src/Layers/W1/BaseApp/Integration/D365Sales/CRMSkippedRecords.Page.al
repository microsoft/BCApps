// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.SyncEngine;

page 5333 "CRM Skipped Records"
{
    AccessByPermission = TableData "CRM Integration Record" = R;
    ApplicationArea = Suite;
    Caption = 'Coupled Data Synchronization Errors';
    Editable = false;
    PageType = List;
    SourceTable = "CRM Synch. Conflict Buffer";
    SourceTableTemporary = true;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID of the table that holds the record.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the table that holds the record.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the description of the table that holds the record.';

                    trigger OnDrillDown()
                    begin
                        CRMSynchHelper.ShowPage(Rec."Record ID");
                    end;
                }
                field("Record Exists"; Rec."Record Exists")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the coupled record exists in Business Central.';
                }
                field("Int. Description"; Rec."Int. Description")
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled To';
                    ToolTip = 'Specifies the coupled entity in Dynamics 365 Sales ';

                    trigger OnDrillDown()
                    begin
                        CRMSynchHelper.ShowPage(Rec."Int. Record ID");
                    end;
                }
                field("Int. Record Exists"; Rec."Int. Record Exists")
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled Record Exists';
                    ToolTip = 'Specifies if a coupled entity exists in Dynamics 365 Sales';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies why the record was could not be synchronized.';
                }
                field("Failed On"; Rec."Failed On")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when the synchronization failed.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Restore)
            {
                AccessByPermission = TableData "CRM Integration Record" = IM;
                ApplicationArea = Suite;
                Caption = 'Retry';
                Enabled = AreRecordsExist and ShowRetryOrSync;
                Image = ResetStatus;
                ToolTip = 'Restore selected records so they can be synchronized.';

                trigger OnAction()
                var
                    CRMIntegrationRecord: Record "CRM Integration Record";
                    CRMOptionMapping: Record "CRM Option Mapping";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    SetCurrentSelectionFilter(CRMIntegrationRecord, CRMOptionMapping);
                    CRMIntegrationManagement.UpdateSkippedNow(CRMIntegrationRecord, CRMOptionMapping);
                    Refresh(CRMIntegrationRecord, CRMOptionMapping);
                end;
            }
            action(RestoreAll)
            {
                AccessByPermission = TableData "CRM Integration Record" = IM;
                ApplicationArea = Suite;
                Caption = 'Retry All';
                Enabled = true;
                Image = RefreshLines;
                ToolTip = 'Restore all records so they can be synchronized.';

                trigger OnAction()
                var
                    CRMIntegrationRecord: Record "CRM Integration Record";
                    CRMOptionMapping: Record "CRM Option Mapping";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    if Rec.IsEmpty() then
                        exit;
                    CRMIntegrationManagement.UpdateAllSkippedNow();
                    Refresh(CRMIntegrationRecord, CRMOptionMapping);
                    Session.LogMessage('0000CUG', UserRetriedAllTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                end;
            }
            action(CRMSynchronizeNow)
            {
                ApplicationArea = Suite;
                Caption = 'Synchronize';
                Enabled = AreRecordsExist and ShowRetryOrSync;
                Image = Refresh;
                ToolTip = 'Send or get updated data to or from Dynamics 365 Sales.';

                trigger OnAction()
                var
                    CRMIntegrationRecord: Record "CRM Integration Record";
                    CRMOptionMapping: Record "CRM Option Mapping";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    SetCurrentSelectionFilter(CRMIntegrationRecord, CRMOptionMapping);
                    CRMIntegrationManagement.UpdateSkippedNow(CRMIntegrationRecord, CRMOptionMapping, true);
                    Refresh(CRMIntegrationRecord, CRMOptionMapping);
                    if not CRMIntegrationRecord.IsEmpty() then
                        CRMIntegrationManagement.UpdateMultipleNow(CRMIntegrationRecord);
                    if not CRMOptionMapping.IsEmpty() then
                        CRMIntegrationManagement.UpdateMultipleNow(CRMOptionMapping, true);
                    Refresh(CRMIntegrationRecord, CRMOptionMapping);
                end;
            }
            action(ShowLog)
            {
                ApplicationArea = Suite;
                Caption = 'Synchronization Log';
                Enabled = AreRecordsExist and Rec."Record Exists";
                Image = Log;
                ToolTip = 'View integration synchronization jobs for the skipped record.';

                trigger OnAction()
                var
                    CRMIntegrationRecord: Record "CRM Integration Record";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    RecId: RecordId;
                begin
                    CRMIntegrationRecord."Table ID" := Rec."Table ID";
                    CRMIntegrationRecord."Integration ID" := Rec."Integration ID";
                    CRMIntegrationRecord.FindRecordId(RecId);
                    if Rec."CRM Option Id" = 0 then
                        CRMIntegrationManagement.ShowLog(RecId)
                    else
                        CRMIntegrationManagement.ShowOptionLog(RecId);
                end;
            }
            action(ManageCRMCoupling)
            {
                ApplicationArea = Suite;
                Caption = 'Set Up Coupling';
                Enabled = AreRecordsExist and Rec."Record Exists";
                Image = LinkAccount;
                ToolTip = 'Create or modify the coupling to a Dynamics 365 Sales entity.';

                trigger OnAction()
                var
                    CRMIntegrationRecord: Record "CRM Integration Record";
                    CRMOptionMapping: Record "CRM Option Mapping";
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    RecId: RecordId;
                begin
                    CRMIntegrationRecord."Table ID" := Rec."Table ID";
                    CRMIntegrationRecord."Integration ID" := Rec."Integration ID";
                    CRMIntegrationRecord.FindRecordId(RecId);
                    if CRMIntegrationRecord.FindByRecordID(RecId) then
                        if CRMIntegrationManagement.DefineCoupling(RecId) then begin
                            CRMIntegrationRecord.SetRecFilter();
                            Refresh(CRMIntegrationRecord, CRMOptionMapping);
                        end;
                end;
            }
            action(ShowUncouplingLog)
            {
                ApplicationArea = Suite;
                Caption = 'Uncoupling Log';
                Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
                Image = Log;
                ToolTip = 'View the status of jobs for uncoupling records, for example, in integrations with Dynamics 365 Sales or Dataverse. The jobs were run either from the job queue, or manually, in Business Central.';

                trigger OnAction()
                var
                    IntegrationSynchJob: Record "Integration Synch. Job";
                begin
                    IntegrationSynchJob.SetCurrentKey("Start Date/Time", ID);
                    IntegrationSynchJob.Ascending := false;
                    IntegrationSynchJob.SetRange(Type, IntegrationSynchJob.Type::Uncoupling);
                    if IntegrationSynchJob.FindFirst() then;
                    Page.Run(PAGE::"Integration Synch. Job List", IntegrationSynchJob);
                end;
            }
            action(DeleteCRMCoupling)
            {
                AccessByPermission = TableData "CRM Integration Record" = D;
                ApplicationArea = Suite;
                Caption = 'Delete Couplings';
                Enabled = AreRecordsExist;
                Image = UnLinkAccount;
                ToolTip = 'Delete couplings between the selected Business Central records and Dynamics 365 Sales entities.';

                trigger OnAction()
                var
                    TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
                begin
                    TempCRMSynchConflictBuffer.Copy(Rec, true);
                    CurrPage.SetSelectionFilter(TempCRMSynchConflictBuffer);
                    TempCRMSynchConflictBuffer.DeleteCouplings();
                    AreRecordsExist := false;
                end;
            }
            action(FindMore)
            {
                AccessByPermission = TableData "CRM Integration Record" = IM;
                ApplicationArea = Suite;
                Caption = 'Find for Deleted';
                Enabled = true;
                Image = RefreshLines;
                ToolTip = 'Find couplings that were broken when one or more entities were deleted in Business Central. This might take several minutes.';

                trigger OnAction()
                begin
                    if not Confirm(FindMoreQst) then
                        exit;
                    CRMIntegrationManagement.MarkLocalDeletedAsSkipped();
                    Reload();
                end;
            }
            action(RestoreDeletedRec)
            {
                ApplicationArea = Suite;
                Caption = 'Restore Records';
                Enabled = AreRecordsExist and ShowRestoreOrDelete;
                Image = CreateMovement;
                ToolTip = 'Restore the deleted coupled entity in Dynamics 365 Sales. A synchronization job is run to achieve this.';

                trigger OnAction()
                var
                    TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
                begin
                    TempCRMSynchConflictBuffer.Copy(Rec, true);
                    CurrPage.SetSelectionFilter(TempCRMSynchConflictBuffer);
                    TempCRMSynchConflictBuffer.RestoreDeletedRecords();
                end;
            }
            action(DeleteCoupledRec)
            {
                ApplicationArea = Suite;
                Caption = 'Delete Records';
                Enabled = AreRecordsExist and ShowRestoreOrDelete;
                Image = CancelLine;
                ToolTip = 'Delete the coupled entity in Dynamics 365 Sales.';

                trigger OnAction()
                var
                    TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
                begin
                    TempCRMSynchConflictBuffer.Copy(Rec, true);
                    CurrPage.SetSelectionFilter(TempCRMSynchConflictBuffer);
                    TempCRMSynchConflictBuffer.DeleteCoupledRecords();
                end;
            }
            action(LoadMoreErrors)
            {
                ApplicationArea = Suite;
                Caption = 'Load More Errors';
                Image = RefreshLines;
                ToolTip = 'Reload the error list.';

                trigger OnAction()
                begin
                    Reload();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(LoadMoreErrors_Promoted; LoadMoreErrors)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Synchronization', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Restore_Promoted; Restore)
                {
                }
                actionref(RestoreAll_Promoted; RestoreAll)
                {
                }
                actionref(CRMSynchronizeNow_Promoted; CRMSynchronizeNow)
                {
                }
                actionref(ShowUncouplingLog_Promoted; ShowUncouplingLog)
                {
                }
                actionref(ShowLog_Promoted; ShowLog)
                {
                }
                actionref(ManageCRMCoupling_Promoted; ManageCRMCoupling)
                {
                }
                actionref(DeleteCRMCoupling_Promoted; DeleteCRMCoupling)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Broken Couplings', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(FindMore_Promoted; FindMore)
                {
                }
                actionref(RestoreDeletedRec_Promoted; RestoreDeletedRec)
                {
                }
                actionref(DeleteCoupledRec_Promoted; DeleteCoupledRec)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
    begin
        AreRecordsExist := true;
        IsOneOfRecordsDeleted := Rec.IsOneRecordDeleted();
        DoBothOfRecordsExist := Rec.DoBothRecordsExist();

        TempCRMSynchConflictBuffer.Copy(Rec, true);
        CurrPage.SetSelectionFilter(TempCRMSynchConflictBuffer);
        if TempCRMSynchConflictBuffer.Count() > 1 then begin
            if ShowRestoreOrDelete then
                if DoBothOfRecordsExist then
                    ShowRestoreOrDelete := false;
            if ShowRetryOrSync then
                if IsOneOfRecordsDeleted then
                    ShowRetryOrSync := false;
        end else begin
            ShowRestoreOrDelete := IsOneOfRecordsDeleted;
            ShowRetryOrSync := DoBothOfRecordsExist
        end;
    end;

    trigger OnOpenPage()
    begin
        LoadData(InitialTableDataFilter);
    end;

    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        TooManyErrorsNotification: Notification;
        CRMIntegrationEnabled: Boolean;
        CDSIntegrationEnabled: Boolean;
        AreRecordsExist: Boolean;
        IsOneOfRecordsDeleted: Boolean;
        DoBothOfRecordsExist: Boolean;
        ShowRestoreOrDelete: Boolean;
        ShowRetryOrSync: Boolean;
        SetOutside: Boolean;
        TooManyErrorsNotificationTxt: Label 'Only 100 coupled record synchronization errors are loaded. When you have resolved them, choose the Load More Errors action to load more.';
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        UserRetriedAllTxt: Label 'User invoked the Retry All function to set the Skipped flag to false on all records.', Locked = true;
        FindMoreQst: Label 'Do you want to find couplings that were broken after one or more entities were deleted in Business Central?';
        InitialTableDataFilter: Text;

    internal procedure SetInitialTableDataFilter(InputInitialTableDataFilter: Text)
    begin
        InitialTableDataFilter := InputInitialTableDataFilter;
    end;

    local procedure LoadData(TableIdFilter: Text);
    begin
        Rec.Reset();
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
        if not SetOutside and (CRMIntegrationEnabled or CDSIntegrationEnabled) then
            CollectSkippedCRMIntegrationRecords(TableIdFilter);
    end;

    local procedure CollectSkippedCRMIntegrationRecords(TableIdFilter: Text)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        if TableIdFilter <> '' then begin
            CRMIntegrationRecord.SetFilter("Table ID", TableIdFilter);
            CRMOptionMapping.SetFilter("Table ID", TableIdFilter);
        end;
        CRMIntegrationRecord.SetRange(Skipped, true);
        CRMOptionMapping.SetRange(Skipped, true);
        SetRecords(CRMIntegrationRecord, CRMOptionMapping);
    end;

    local procedure SetCurrentSelectionFilter(var CRMIntegrationRecord: Record "CRM Integration Record"; var CRMOptionMapping: Record "CRM Option Mapping")
    var
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
    begin
        TempCRMSynchConflictBuffer.Copy(Rec, true);
        CurrPage.SetSelectionFilter(TempCRMSynchConflictBuffer);
        TempCRMSynchConflictBuffer.SetSelectionFilter(CRMIntegrationRecord, CRMOptionMapping);
    end;

    procedure SetRecords(var CRMIntegrationRecord: Record "CRM Integration Record"; var CRMOptionMapping: Record "CRM Option Mapping")
    var
        cnt: Integer;
    begin
        cnt := Rec.Fill(CRMIntegrationRecord, CRMOptionMapping);
        SetOutside := true;
        if cnt >= 100 then begin
            TooManyErrorsNotification.Id(GetTooManyErrorsNotificationId());
            TooManyErrorsNotification.Message(TooManyErrorsNotificationTxt);
            TooManyErrorsNotification.Send();
        end;
    end;

    procedure SetRecords(var CRMIntegrationRecord: Record "CRM Integration Record")
    var
        TempCRMOptionMapping: Record "CRM Option Mapping" temporary;
    begin
        SetRecords(CRMIntegrationRecord, TempCRMOptionMapping);
    end;

    local procedure GetTooManyErrorsNotificationId(): Guid;
    begin
        exit('2d60b73e-8879-40b8-a16d-1edffad711cd');
    end;

    local procedure Refresh(var CRMIntegrationRecord: Record "CRM Integration Record"; var CRMOptionMapping: Record "CRM Option Mapping")
    begin
        Rec.UpdateSourceTable(CRMIntegrationRecord, CRMOptionMapping);
        AreRecordsExist := false;
    end;

    local procedure Reload()
    var
        CurrView: Text;
        TableIdFilter: Text;
    begin
        if TooManyErrorsNotification.Recall() then;
        SetOutside := false;

        CurrView := Rec.GetView();
        TableIdFilter := Rec.GetFilter("Table ID");

        LoadData(TableIdFilter);
        Rec.SetView(CurrView);
        CurrPage.Update();
    end;
}

