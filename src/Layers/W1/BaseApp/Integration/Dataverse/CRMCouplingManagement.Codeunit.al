// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.SyncEngine;

codeunit 5331 "CRM Coupling Management"
{

    trigger OnRun()
    begin
    end;

    var
        IntegrationRecordNotFoundErr: Label 'The integration record for record %1 was not found.', Comment = '%1 = record ID';

    procedure IsRecordCoupledToCRM(RecordID: RecordID): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        exit(CRMIntegrationRecord.IsRecordCoupled(RecordID));
    end;

    procedure IsRecordCoupledToNAV(CRMID: Guid; NAVTableID: Integer): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        NAVRecordID: RecordID;
    begin
        exit(CRMIntegrationRecord.FindRecordIDFromID(CRMID, NAVTableID, NAVRecordID));
    end;

    local procedure AssertTableIsMapped(TableID: Integer)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Table ID", TableID);
        IntegrationTableMapping.FindFirst();
    end;

    procedure DefineOptionMapping(RecordId: RecordID; var CRMOptionId: Integer; var CreateNew: Boolean; var Synchronize: Boolean; var Direction: Option): Boolean
    var
        CouplingRecordBuffer: Record "Coupling Record Buffer";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMCouplingRecord: Page "CRM Coupling Record";
    begin
        AssertTableIsMapped(RecordId.TableNo);
        CRMCouplingRecord.SetSourceRecordID(RecordId, true);
        if CRMCouplingRecord.RunModal() = Action::OK then begin
            CRMCouplingRecord.GetRecord(CouplingRecordBuffer);
            if CouplingRecordBuffer."Create New" then
                CreateNew := true
            else
                if CouplingRecordBuffer."CRM Option Id" <> 0 then begin
                    CRMOptionId := CouplingRecordBuffer."CRM Option Id";
                    CRMIntegrationManagement.CreateOptionMapping(RecordID, CouplingRecordBuffer."CRM Option Id", CouplingRecordBuffer."CRM Name");
                    if CouplingRecordBuffer.GetPerformInitialSynchronization() then begin
                        Synchronize := true;
                        Direction := CouplingRecordBuffer.GetInitialSynchronizationDirection();
                    end;
                end else
                    exit(false);
            exit(true);
        end;
        exit(false);
    end;

    procedure DefineCoupling(RecordID: RecordID; var CRMID: Guid; var CreateNew: Boolean; var Synchronize: Boolean; var Direction: Option): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CouplingRecordBuffer: Record "Coupling Record Buffer";
        CRMCouplingRecord: Page "CRM Coupling Record";
    begin
        AssertTableIsMapped(RecordID.TableNo);
        CRMCouplingRecord.SetSourceRecordID(RecordID);
        if CRMCouplingRecord.RunModal() = ACTION::OK then begin
            CRMCouplingRecord.GetRecord(CouplingRecordBuffer);
            if CouplingRecordBuffer."Create New" then
                CreateNew := true
            else
                if not IsNullGuid(CouplingRecordBuffer."CRM ID") then begin
                    CRMID := CouplingRecordBuffer."CRM ID";
                    CRMIntegrationRecord.CoupleRecordIdToCRMID(RecordID, CouplingRecordBuffer."CRM ID");
                    if CouplingRecordBuffer.GetPerformInitialSynchronization() then begin
                        Synchronize := true;
                        Direction := CouplingRecordBuffer.GetInitialSynchronizationDirection();
                    end;
                end else
                    exit(false);
            exit(true);
        end;
        exit(false);
    end;

    procedure RemoveCoupling(var RecRef: RecordRef)
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationManagement.RemoveCoupling(RecRef);
    end;

    procedure RemoveCoupling(RecordID: RecordID)
    var
        TempCRMIntegrationRecord: Record "CRM Integration Record" temporary;
    begin
        RemoveCouplingWithTracking(RecordID, TempCRMIntegrationRecord);
    end;

    procedure RemoveCoupling(TableID: Integer; CRMTableID: Integer; CRMID: Guid)
    var
        TempCRMIntegrationRecord: Record "CRM Integration Record" temporary;
    begin
        RemoveCouplingWithTracking(TableID, CRMTableID, CRMID, TempCRMIntegrationRecord);
    end;

    procedure RemoveCouplingWithTracking(RecordID: RecordID; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary)
    begin
        RemoveSingleCoupling(RecordID, TempCRMIntegrationRecord);
    end;

    procedure RemoveCouplingWithTracking(TableID: Integer; CRMTableID: Integer; CRMID: Guid; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary)
    begin
        RemoveSingleCoupling(TableID, CRMTableID, CRMID, TempCRMIntegrationRecord);
    end;

    local procedure RemoveSingleCoupling(RecordID: RecordID; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if not CRMIntegrationRecord.FindByRecordID(RecordID) then
            Error(IntegrationRecordNotFoundErr, Format(RecordID, 0, 1));

        CRMIntegrationManagement.RemoveCoupling(RecordId);

        TempCRMIntegrationRecord := CRMIntegrationRecord;
        TempCRMIntegrationRecord.Skipped := false;
        if TempCRMIntegrationRecord.Insert() then;
    end;

    local procedure RemoveSingleCoupling(TableID: Integer; CRMTableID: Integer; CRMID: Guid; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if not CRMIntegrationRecord.FindByCRMID(CRMID) then
            Error(IntegrationRecordNotFoundErr, CRMID);

        CRMIntegrationManagement.RemoveCoupling(TableID, CRMTableID, CRMID);

        TempCRMIntegrationRecord := CRMIntegrationRecord;
        TempCRMIntegrationRecord.Skipped := false;
        if TempCRMIntegrationRecord.Insert() then;
    end;
}

