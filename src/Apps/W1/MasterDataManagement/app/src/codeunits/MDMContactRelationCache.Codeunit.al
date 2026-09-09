namespace Microsoft.Integration.MDM;

using Microsoft.CRM.BusinessRelation;
using Microsoft.Integration.SyncEngine;

/// <summary>
/// Resolves source contact business relations cross-environment for the contact auto-create/primary-contact logic.
/// During a synchronization run it prefetches all of a link type's relations in a single call and answers lookups
/// from memory, turning the otherwise O(N) per-contact over-the-wire reads into O(1) per link type. Outside a run
/// (a one-off customer/vendor insert), or when the source reports the set is too large to serve in bulk, it reads
/// the single requested relation over the wire instead. Single instance so the prefetched snapshot survives across
/// the many record inserts of a run; the snapshot is reset at each run boundary.
/// </summary>
codeunit 7234 "MDM Contact Relation Cache"
{
    Access = Internal;
    SingleInstance = true;

    var
        ContactNoByRelation: Dictionary of [Text, Code[20]];
        RelationNoByContact: Dictionary of [Text, Code[20]];
        BulkAttempted: Dictionary of [Integer, Boolean];
        Degraded: Dictionary of [Integer, Boolean];
        InSyncRun: Boolean;

    /// <summary>Resolves the source contact number linked to a customer/vendor/bank account relation.</summary>
    procedure TryGetSourceContactNo(LinkToTable: Enum "Contact Business Relation Link To Table"; RelationNo: Code[20]; var SourceContactNo: Code[20]): Boolean
    begin
        if UseBulk(LinkToTable) then
            exit(ContactNoByRelation.Get(RelationKey(LinkToTable, RelationNo), SourceContactNo) and (SourceContactNo <> ''));
        exit(ReadSingleContactNo(LinkToTable, RelationNo, SourceContactNo));
    end;

    /// <summary>Resolves the source relation number (customer/vendor No.) linked to a source contact.</summary>
    procedure TryGetSourceRelationNo(LinkToTable: Enum "Contact Business Relation Link To Table"; SourceContactNo: Code[20]; var RelationNo: Code[20]): Boolean
    begin
        if UseBulk(LinkToTable) then
            exit(RelationNoByContact.Get(ContactKey(LinkToTable, SourceContactNo), RelationNo) and (RelationNo <> ''));
        exit(ReadSingleRelationNo(LinkToTable, SourceContactNo, RelationNo));
    end;

    local procedure UseBulk(LinkToTable: Enum "Contact Business Relation Link To Table"): Boolean
    begin
        if not InSyncRun then
            exit(false);
        EnsureBulkLoaded(LinkToTable);
        exit(not Degraded.ContainsKey(LinkToTable.AsInteger()));
    end;

    local procedure EnsureBulkLoaded(LinkToTable: Enum "Contact Business Relation Link To Table")
    begin
        if BulkAttempted.ContainsKey(LinkToTable.AsInteger()) then
            exit;
        BulkAttempted.Add(LinkToTable.AsInteger(), true);
        LoadLinkType(LinkToTable);
    end;

    local procedure LoadLinkType(LinkToTable: Enum "Contact Business Relation Link To Table")
    var
        FilterContactBusinessRelation: Record "Contact Business Relation";
        CrossEnvDataSource: Codeunit "MDM Cross-Env Data Source";
        SourceRecordRef: RecordRef;
        NotIndexed: Boolean;
        RelationNo: Code[20];
        SourceContactNo: Code[20];
    begin
        FilterContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        if not CrossEnvDataSource.TryBulkGetSourceRecordsByFilter(Database::"Contact Business Relation", FilterContactBusinessRelation.GetView(), SourceRecordRef, NotIndexed) then begin
            // The source could not serve the whole set (too large to index, or a transient/consent issue): fall back
            // to reading the one requested relation per lookup, which preserves per-record error isolation.
            Degraded.Add(LinkToTable.AsInteger(), true);
            exit;
        end;
        if not SourceRecordRef.FindSet() then
            exit;
        repeat
            RelationNo := SourceRecordRef.Field(FilterContactBusinessRelation.FieldNo("No.")).Value();
            SourceContactNo := SourceRecordRef.Field(FilterContactBusinessRelation.FieldNo("Contact No.")).Value();
            if (RelationNo <> '') and (SourceContactNo <> '') then begin
                AddUnique(ContactNoByRelation, RelationKey(LinkToTable, RelationNo), SourceContactNo);
                AddUnique(RelationNoByContact, ContactKey(LinkToTable, SourceContactNo), RelationNo);
            end;
        until SourceRecordRef.Next() = 0;
    end;

    local procedure ReadSingleContactNo(LinkToTable: Enum "Contact Business Relation Link To Table"; RelationNo: Code[20]; var SourceContactNo: Code[20]): Boolean
    var
        SourceContactBusinessRelation: Record "Contact Business Relation";
        CrossEnvDataSource: Codeunit "MDM Cross-Env Data Source";
        SourceRecordRef: RecordRef;
    begin
        SourceContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        SourceContactBusinessRelation.SetRange("No.", RelationNo);
        if not CrossEnvDataSource.GetSourceRecordsByFilter(Database::"Contact Business Relation", SourceContactBusinessRelation.GetView(), SourceRecordRef) then
            exit(false);
        SourceContactNo := SourceRecordRef.Field(SourceContactBusinessRelation.FieldNo("Contact No.")).Value();
        exit(SourceContactNo <> '');
    end;

    local procedure ReadSingleRelationNo(LinkToTable: Enum "Contact Business Relation Link To Table"; SourceContactNo: Code[20]; var RelationNo: Code[20]): Boolean
    var
        SourceContactBusinessRelation: Record "Contact Business Relation";
        CrossEnvDataSource: Codeunit "MDM Cross-Env Data Source";
        SourceRecordRef: RecordRef;
    begin
        SourceContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        SourceContactBusinessRelation.SetRange("Contact No.", SourceContactNo);
        if not CrossEnvDataSource.GetSourceRecordsByFilter(Database::"Contact Business Relation", SourceContactBusinessRelation.GetView(), SourceRecordRef) then
            exit(false);
        RelationNo := SourceRecordRef.Field(SourceContactBusinessRelation.FieldNo("No.")).Value();
        exit(RelationNo <> '');
    end;

    local procedure AddUnique(var Cache: Dictionary of [Text, Code[20]]; KeyText: Text; Value: Code[20])
    begin
        if not Cache.ContainsKey(KeyText) then
            Cache.Add(KeyText, Value);
    end;

    local procedure RelationKey(LinkToTable: Enum "Contact Business Relation Link To Table"; RelationNo: Code[20]): Text
    begin
        exit(Format(LinkToTable.AsInteger()) + '|' + RelationNo);
    end;

    local procedure ContactKey(LinkToTable: Enum "Contact Business Relation Link To Table"; SourceContactNo: Code[20]): Text
    begin
        exit(Format(LinkToTable.AsInteger()) + '|' + SourceContactNo);
    end;

    local procedure ClearSnapshot()
    begin
        Clear(ContactNoByRelation);
        Clear(RelationNoByContact);
        Clear(BulkAttempted);
        Clear(Degraded);
    end;

    // The bulk path is used only within a synchronization run; the snapshot is dropped at both boundaries so it is
    // fresh per run. MDM sync runs in a background job-queue session, so this state stays isolated to that session.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Master Data Synch.", 'OnBeforeRun', '', false, false)]
    local procedure MarkSyncRunStart(IntegrationTableMapping: Record "Integration Table Mapping"; var IsHandled: Boolean)
    begin
        ClearSnapshot();
        InSyncRun := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Master Data Synch.", 'OnAfterRun', '', false, false)]
    local procedure MarkSyncRunEnd(IntegrationTableMapping: Record "Integration Table Mapping")
    begin
        ClearSnapshot();
        InSyncRun := false;
    end;
}
