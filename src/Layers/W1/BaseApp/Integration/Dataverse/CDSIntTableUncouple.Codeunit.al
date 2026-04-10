// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;

codeunit 5337 "CDS Int. Table Uncouple"
{
    TableNo = "Integration Table Mapping";

    trigger OnRun()
    var
        ConnectionName: Text;
        Handled: Boolean;
    begin
        OnBeforeRun(Rec, Handled);
        if Handled then
            exit;

        ConnectionName := CRMIntegrationTableSynch.InitConnection();
        CRMIntegrationTableSynch.TestConnection();

        PerformScheduledUncoupling(Rec);

        CRMIntegrationTableSynch.CloseConnection(ConnectionName);
    end;

    var
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete,Uncouple;

    local procedure PerformScheduledUncoupling(var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        JobId: Guid;
    begin
        JobId := IntegrationTableSynch.BeginIntegrationUncoupleJob(TableConnectionType::CRM, IntegrationTableMapping, IntegrationTableMapping."Table ID");
        if not IsNullGuid(JobId) then begin
            UncoupleRecords(IntegrationTableMapping, IntegrationTableSynch);
            IntegrationTableSynch.EndIntegrationSynchJob();
        end;
    end;

    local procedure UncoupleRecords(var IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationTableSynch: Codeunit "Integration Table Synch.")
    var
        TempCRMIntegrationRecord: Record "CRM Integration Record" temporary;
        LocalTableFilter: Text;
        IntegrationTableFilter: Text;
        HasCouplings: Boolean;
    begin
        CRMIntegrationTableSynch.CreateCRMIntegrationRecordClone(IntegrationTableMapping."Table ID", TempCRMIntegrationRecord);
        HasCouplings := not TempCRMIntegrationRecord.IsEmpty();

        LocalTableFilter := IntegrationTableMapping.GetTableFilter();
        IntegrationTableFilter := IntegrationTableMapping.GetIntegrationTableFilter();

        if (LocalTableFilter = '') and (IntegrationTableFilter = '') then begin
            if HasCouplings then
                UncoupleAllCoupledRecords(IntegrationTableMapping, IntegrationTableSynch, TempCRMIntegrationRecord);
            ResetStuckCompanyId(IntegrationTableMapping, IntegrationTableSynch);
            exit;
        end;

        if not HasCouplings then
            exit;

        if LocalTableFilter <> '' then
            UncoupleFilteredLocalRecords(IntegrationTableMapping, IntegrationTableSynch, TempCRMIntegrationRecord)
        else
            UncoupleFilteredIntegrationRecords(IntegrationTableMapping, IntegrationTableSynch, TempCRMIntegrationRecord);
    end;

    local procedure UncoupleFilteredLocalRecords(var IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationTableSynch: Codeunit "Integration Table Synch."; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary)
    var
        LocalRecordRef: RecordRef;
        IntegrationRecordRef: RecordRef;
    begin
        LocalRecordRef.Open(IntegrationTableMapping."Table ID");
        IntegrationTableMapping.SetRecordRefFilter(LocalRecordRef);
        if LocalRecordRef.FindSet() then
            repeat
                if TempCRMIntegrationRecord.IsIntegrationIdCoupled(LocalRecordRef.Field(LocalRecordRef.SystemIdNo()).Value(), LocalRecordRef.Number) then begin
                    Clear(IntegrationRecordRef);
                    IntegrationTableSynch.Uncouple(LocalRecordRef, IntegrationRecordRef);
                end;
            until LocalRecordRef.Next() = 0;
    end;

    local procedure UncoupleFilteredIntegrationRecords(var IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationTableSynch: Codeunit "Integration Table Synch."; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary)
    var
        LocalRecordRef: RecordRef;
        IntegrationRecordRef: RecordRef;
    begin
        IntegrationRecordRef.Open(IntegrationTableMapping."Integration Table ID");
        IntegrationTableMapping.SetIntRecordRefFilter(IntegrationRecordRef);
        if IntegrationRecordRef.FindSet() then
            repeat
                if TempCRMIntegrationRecord.IsCRMRecordRefCoupled(IntegrationRecordRef) then begin
                    TempCRMIntegrationRecord.Delete();
                    Clear(LocalRecordRef);
                    IntegrationTableSynch.Uncouple(LocalRecordRef, IntegrationRecordRef);
                end;
            until IntegrationRecordRef.Next() = 0;
    end;

    local procedure UncoupleAllCoupledRecords(var IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationTableSynch: Codeunit "Integration Table Synch."; var TempCRMIntegrationRecord: Record "CRM Integration Record" temporary)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        LocalRecordRef: RecordRef;
        IntegrationRecordRef: RecordRef;
        LocalRecordFound: Boolean;
        IntegrationRecordFound: Boolean;
        TableId: Integer;
    begin
        if TempCRMIntegrationRecord.FindSet() then
            repeat
                TableId := TempCRMIntegrationRecord."Table ID";
                if TableId <> 0 then begin
                    Clear(LocalRecordRef);
                    LocalRecordRef.Open(TableId);
                    LocalRecordFound := LocalRecordRef.GetBySystemId(TempCRMIntegrationRecord."Integration ID");
                    if not LocalRecordFound then begin
                        Clear(IntegrationrecordRef);
                        IntegrationRecordRef.Open(IntegrationTableMapping."Integration Table ID");
                        IntegrationRecordFound := IntegrationTableMapping.GetRecordRef(TempCRMIntegrationRecord."CRM ID", IntegrationRecordRef);
                    end;
                    if LocalRecordFound or IntegrationRecordFound then
                        IntegrationTableSynch.Uncouple(LocalRecordRef, IntegrationRecordRef)
                    else
                        if CRMIntegrationRecord.Get(TempCRMIntegrationRecord."Integration ID", TempCRMIntegrationRecord."CRM ID") then
                            CRMIntegrationRecord.Delete();
                end;
            until TempCRMIntegrationRecord.Next() = 0;
    end;

    local procedure ResetStuckCompanyId(var IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationTableSynch: Codeunit "Integration Table Synch.")
    var
        OriginalIntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        LocalRecordRef: RecordRef;
        IntegrationRecordRef: RecordRef;
        CompanyIdFieldRef: FieldRef;
        IntegrationTableFilter: Text;
        FilterList: List of [Text];
    begin
        if not CDSIntegrationImpl.HasCompanyIdField(IntegrationTableMapping."Integration Table ID") then
            exit;

        OriginalIntegrationTableMapping.SetRange(Type, OriginalIntegrationTableMapping.Type::Dataverse);
        OriginalIntegrationTableMapping.SetRange("Uncouple Codeunit ID", Codeunit::"CDS Int. Table Uncouple");
        OriginalIntegrationTableMapping.SetRange("Table ID", IntegrationTableMapping."Table ID");
        OriginalIntegrationTableMapping.SetRange("Integration Table ID", IntegrationTableMapping."Integration Table ID");
        OriginalIntegrationTableMapping.SetRange("Delete After Synchronization", false);
        if not OriginalIntegrationTableMapping.FindFirst() then
            exit;

        IntegrationRecordRef.Open(IntegrationTableMapping."Integration Table ID");
        if not CDSIntegrationImpl.FindCompanyIdField(IntegrationRecordRef, CompanyIdFieldRef) then
            exit;

        if not CDSIntegrationImpl.TryGetCDSCompany(CDSCompany) then
            exit;

        IntegrationRecordSynch.SplitIntegrationTableFilter(OriginalIntegrationTableMapping, FilterList);
        foreach IntegrationTableFilter in FilterList do begin
            IntegrationRecordRef.SetView(IntegrationTableFilter);
            CompanyIdFieldRef.SetRange(CDSCompany.CompanyId);
            if IntegrationRecordRef.FindSet() then
                repeat
                    CDSIntegrationImpl.ResetCompanyId(IntegrationRecordRef);
                    if IntegrationRecordRef.IsDirty() then
                        if not IntegrationRecordRef.Modify(true) then
                            IntegrationTableSynch.LogSynchError(LocalRecordRef, IntegrationRecordRef, GetLastErrorText())
                        else
                            IntegrationTableSynch.IncrementSynchJobCounters(SynchActionType::Modify);
                until IntegrationRecordRef.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(IntegrationTableMapping: Record "Integration Table Mapping"; var Handled: Boolean)
    begin
    end;
}
