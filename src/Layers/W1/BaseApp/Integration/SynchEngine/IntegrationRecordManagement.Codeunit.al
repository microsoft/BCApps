// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using Microsoft.Integration.Dataverse;

codeunit 5338 "Integration Record Management"
{
    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0470
        UnsupportedTableConnectionTypeErr: Label '%1 is not a supported table connection type.';
#pragma warning restore AA0470

    procedure FindRecordIdByIntegrationTableUid(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; DestinationTableId: Integer; var DestinationRecordId: RecordID): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IsFound: Boolean;
        IsHandled: Boolean;
    begin
        OnFindRecordIdByIntegrationTableUid(IntegrationTableConnectionType, IntegrationTableUid, DestinationTableId, DestinationRecordId, IsFound, IsHandled);
        if IsHandled then
            exit(IsFound);

        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                exit(CRMIntegrationRecord.FindRecordIDFromID(IntegrationTableUid, DestinationTableId, DestinationRecordId));
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure FindIntegrationTableUIdByRecordId(IntegrationTableConnectionType: TableConnectionType; SourceRecordId: RecordID; var IntegrationTableUid: Variant): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IsFound: Boolean;
        IsHandled: Boolean;
    begin
        OnFindIntegrationTableUIdByRecordID(IntegrationTableConnectionType, SourceRecordId, IntegrationTableUid, IsFound, IsHandled);
        if IsHandled then
            exit(IsFound);

        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                exit(CRMIntegrationRecord.FindIDFromRecordID(SourceRecordId, IntegrationTableUid));
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure FindIntegrationTableUIdByRecordRef(IntegrationTableConnectionType: TableConnectionType; SourceRecordRef: RecordRef; var IntegrationTableUid: Variant): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IsFound: Boolean;
        IsHandled: Boolean;
    begin
        OnFindIntegrationTableUIdByRecordRef(IntegrationTableConnectionType, SourceRecordRef, IntegrationTableUid, IsFound, IsHandled);
        if IsHandled then
            exit(IsFound);

        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                exit(CRMIntegrationRecord.FindIDFromRecordRef(SourceRecordRef, IntegrationTableUid));
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure MarkLastSynchAsFailure(IntegrationTableConnectionType: TableConnectionType; SourceRecRef: RecordRef; DirectionToIntTable: Boolean; JobID: Guid)
    var
        MarkedAsSkipped: Boolean;
    begin
        MarkLastSynchAsFailure(IntegrationTableConnectionType, SourceRecRef, DirectionToIntTable, JobID, MarkedAsSkipped);
    end;

    procedure MarkLastSynchAsFailure(IntegrationTableConnectionType: TableConnectionType; SourceRecRef: RecordRef; DirectionToIntTable: Boolean; JobID: Guid; var MarkedAsSkipped: Boolean)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IsHandled: Boolean;
    begin
        OnMarkLastSynchAsFailure(IntegrationTableConnectionType, SourceRecRef, DirectionToIntTable, JobID, MarkedAsSkipped, IsHandled);
        if IsHandled then
            exit;

        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                CRMIntegrationRecord.SetLastSynchResultFailed(SourceRecRef, DirectionToIntTable, JobID, MarkedAsSkipped);
            TABLECONNECTIONTYPE::MicrosoftGraph,
          TABLECONNECTIONTYPE::ExternalSQL:
                ;
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure IsIntegrationRecordSkipped(IntegrationTableConnectionType: TableConnectionType; SourceRecRef: RecordRef; DirectionToIntTable: Boolean): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        Skipped: Boolean;
        IsHandled: Boolean;
    begin
        OnIsIntegrationRecordSkipped(IntegrationTableConnectionType, SourceRecRef, DirectionToIntTable, Skipped, IsHandled);
        if IsHandled then
            exit(Skipped);

        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                Skipped := CRMIntegrationRecord.IsSkipped(SourceRecRef, DirectionToIntTable);
            TABLECONNECTIONTYPE::MicrosoftGraph,
            TABLECONNECTIONTYPE::ExternalSQL:
                ;
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
        exit(Skipped);
    end;

    procedure UpdateIntegrationTableCoupling(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; RecordId: RecordID)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IsHandled: Boolean;
    begin
        OnUpdateIntegrationTableCouplingForRecordID(IntegrationTableConnectionType, IntegrationTableUid, RecordId, IsHandled);
        if IsHandled then
            exit;

        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                CRMIntegrationRecord.CoupleCRMIDToRecordID(IntegrationTableUid, RecordId);
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure UpdateIntegrationTableCoupling(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; RecordRef: RecordRef)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IsHandled: Boolean;
    begin
        OnUpdateIntegrationTableCouplingForRecordRef(IntegrationTableConnectionType, IntegrationTableUid, RecordRef, IsHandled);
        if IsHandled then
            exit;

        if RecordRef.Number() = 0 then
            exit;
        if IsNullGuid(RecordRef.Field(RecordRef.SystemIdNo()).Value()) then
            exit;
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                CRMIntegrationRecord.CoupleCRMIDToRecordRef(IntegrationTableUid, RecordRef);
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure RemoveIntegrationTableCoupling(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; DestinationTableID: Integer; RecordId: RecordID)
    var
        Removed: Boolean;
    begin
        RemoveIntegrationTableCoupling(IntegrationTableConnectionType, IntegrationTableUid, DestinationTableID, RecordId, Removed);
    end;

    procedure RemoveIntegrationTableCoupling(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; DestinationTableID: Integer; RecordRef: RecordRef)
    var
        Removed: Boolean;
    begin
        RemoveIntegrationTableCoupling(IntegrationTableConnectionType, IntegrationTableUid, DestinationTableID, RecordRef, Removed);
    end;

    internal procedure RemoveIntegrationTableCoupling(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; DestinationTableID: Integer; RecordId: RecordID; var Removed: Boolean)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IsHandled: Boolean;
    begin
        OnRemoveIntegrationTableCouplingForRecordID(IntegrationTableConnectionType, IntegrationTableUid, DestinationTableID, RecordId, Removed, IsHandled);
        if IsHandled then
            exit;

        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                if RecordId.TableNo() <> 0 then
                    Removed := CRMIntegrationRecord.RemoveCouplingToRecord(RecordId)
                else
                    Removed := CRMIntegrationRecord.RemoveCouplingToCRMID(IntegrationTableUid, DestinationTableID);
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    internal procedure RemoveIntegrationTableCoupling(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; DestinationTableID: Integer; RecordRef: RecordRef; var Removed: Boolean)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IsNotNull: Boolean;
        IsHandled: Boolean;
    begin
        OnRemoveIntegrationTableCouplingForRecordRef(IntegrationTableConnectionType, IntegrationTableUid, DestinationTableID, RecordRef, Removed, IsHandled);
        if IsHandled then
            exit;

        if RecordRef.Number() <> 0 then
            if not IsNullGuid(RecordRef.Field(RecordRef.SystemIdNo()).Value()) then
                IsNotNull := true;
        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                if IsNotNull then
                    Removed := CRMIntegrationRecord.RemoveCouplingToRecord(RecordRef)
                else
                    Removed := CRMIntegrationRecord.RemoveCouplingToCRMID(IntegrationTableUid, DestinationTableID);
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure UpdateIntegrationTableTimestamp(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; IntegrationTableModfiedOn: DateTime; TableID: Integer; ModifiedOn: DateTime; JobID: Guid; Direction: Option)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IsHandled: Boolean;
    begin
        OnUpdateIntegrationTableTimestamp(IntegrationTableConnectionType, IntegrationTableUid, TableID, IntegrationTableModfiedOn, ModifiedOn, JobID, Direction, IsHandled);
        if IsHandled then
            exit;

        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                CRMIntegrationRecord.SetLastSynchModifiedOns(
                  IntegrationTableUid, TableID, IntegrationTableModfiedOn, ModifiedOn, JobID, Direction);
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure IsModifiedAfterIntegrationTableRecordLastSynch(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; DestinationTableId: Integer; LastModifiedOn: DateTime): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IsHandled: Boolean;
        IsModified: Boolean;
    begin
        OnIsModifiedAfterIntegrationTableRecordLastSynch(IntegrationTableConnectionType, IntegrationTableUid, DestinationTableId, LastModifiedOn, IsModified, IsHandled);
        if IsHandled then
            exit(IsModified);

        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                exit(CRMIntegrationRecord.IsModifiedAfterLastSynchonizedCRMRecord(IntegrationTableUid, DestinationTableId, LastModifiedOn));
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure IsModifiedAfterRecordLastSynch(IntegrationTableConnectionType: TableConnectionType; SourceRecordID: RecordID; LastModifiedOn: DateTime): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IsHandled: Boolean;
        IsModified: Boolean;
    begin
        OnIsRecordModifiedAfterRecordLastSynch(IntegrationTableConnectionType, SourceRecordID, LastModifiedOn, IsModified, IsHandled);
        if IsHandled then
            exit(IsModified);

        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                exit(CRMIntegrationRecord.IsModifiedAfterLastSynchronizedRecord(SourceRecordID, LastModifiedOn));
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    procedure IsModifiedAfterRecordLastSynch(IntegrationTableConnectionType: TableConnectionType; SourceRecordRef: RecordRef; LastModifiedOn: DateTime): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IsHandled: Boolean;
        IsModified: Boolean;
    begin
        OnIsRecordRefModifiedAfterRecordLastSynch(IntegrationTableConnectionType, SourceRecordRef, LastModifiedOn, IsModified, IsHandled);
        if IsHandled then
            exit(IsModified);

        case IntegrationTableConnectionType of
            TABLECONNECTIONTYPE::CRM:
                exit(CRMIntegrationRecord.IsModifiedAfterLastSynchronizedRecord(SourceRecordRef, LastModifiedOn));
            else
                Error(UnsupportedTableConnectionTypeErr, Format(IntegrationTableConnectionType));
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsRecordRefModifiedAfterRecordLastSynch(IntegrationTableConnectionType: TableConnectionType; var SourceRecordRef: RecordRef; LastModifiedOn: DateTime; var IsModified: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsRecordModifiedAfterRecordLastSynch(IntegrationTableConnectionType: TableConnectionType; var SourceRecordId: RecordID; LastModifiedOn: DateTime; var IsModified: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsModifiedAfterIntegrationTableRecordLastSynch(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; DestinationTableId: Integer; LastModifiedOn: DateTime; var IsModified: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateIntegrationTableTimestamp(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; TableID: Integer; IntegrationTableModfiedOn: DateTime; ModifiedOn: DateTime; JobID: Guid; Direction: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRemoveIntegrationTableCouplingForRecordId(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; DestinationTableID: Integer; var RecordId: RecordID; var Removed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRemoveIntegrationTableCouplingForRecordRef(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; DestinationTableID: Integer; var RecordRef: RecordRef; var Removed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateIntegrationTableCouplingForRecordRef(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; RecordRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateIntegrationTableCouplingForRecordID(IntegrationTableConnectionType: TableConnectionType; IntegrationTableUid: Variant; RecordId: RecordID; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsIntegrationRecordSkipped(IntegrationTableConnectionType: TableConnectionType; var SourceRecRef: RecordRef; DirectionToIntTable: Boolean; var IsSkipped: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMarkLastSynchAsFailure(IntegrationTableConnectionType: TableConnectionType; var SourceRecRef: RecordRef; DirectionToIntTable: Boolean; JobID: Guid; var MarkedAsSkipped: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindIntegrationTableUIdByRecordRef(IntegrationTableConnectionType: TableConnectionType; var SourceRecordRef: RecordRef; var IntegrationTableUid: Variant; var IsFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindIntegrationTableUIdByRecordId(IntegrationTableConnectionType: TableConnectionType; var SourceRecordId: RecordID; var IntegrationTableUid: Variant; var IsFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRecordIdByIntegrationTableUid(IntegrationTableConnectionType: TableConnectionType; var IntegrationTableUid: Variant; DestinationTableId: Integer; var DestinationRecordId: RecordID; var IsFound: Boolean; var IsHandled: Boolean)
    begin
    end;

}

