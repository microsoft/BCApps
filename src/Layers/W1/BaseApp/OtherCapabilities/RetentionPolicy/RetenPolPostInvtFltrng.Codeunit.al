namespace System.DataAdministration;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.InventoryDocument;

codeunit 3992 "Reten. Pol. Post. Invt. Fltr." implements "Reten. Pol. Filtering"
{
    Access = Internal;
    Permissions = tabledata Location = r,
                  tabledata "Posted Invt. Pick Header" = r,
                  tabledata "Posted Invt. Put-away Header" = r;

    var
        LocationNotFoundErr: Label 'A location referenced by a posted inventory document was not found. The record was excluded from retention policy cleanup.';
        UnsupportedTableErr: Label 'Table %1 is not supported by posted inventory retention policy filtering.', Comment = '%1 = table ID';

    procedure HasReadPermission(TableId: Integer): Boolean
    var
        DefaultFiltering: Interface "Reten. Pol. Filtering";
    begin
        DefaultFiltering := "Reten. Pol. Filtering"::Default;
        exit(DefaultFiltering.HasReadPermission(TableId))
    end;

    procedure Count(RecordRef: RecordRef): Integer
    var
        DefaultFiltering: Interface "Reten. Pol. Filtering";
    begin
        DefaultFiltering := "Reten. Pol. Filtering"::Default;
        exit(DefaultFiltering.Count(RecordRef))
    end;

    procedure ApplyRetentionPolicyAllRecordFilters(RetentionPolicySetup: Record "Retention Policy Setup"; var RecordRef: RecordRef; var RetenPolFilteringParam: Record "Reten. Pol. Filtering Param" temporary): Boolean
    var
        DefaultFiltering: Interface "Reten. Pol. Filtering";
    begin
        DefaultFiltering := "Reten. Pol. Filtering"::Default;
        if not DefaultFiltering.ApplyRetentionPolicyAllRecordFilters(RetentionPolicySetup, RecordRef, RetenPolFilteringParam) then
            exit(false);

        MarkFilteredRecords(RecordRef);
        ExcludeProtectedRecords(RecordRef);
        exit(DefaultFiltering.Count(RecordRef) > 0)
    end;

    procedure ApplyRetentionPolicySubSetFilters(RetentionPolicySetup: Record "Retention Policy Setup"; var RecordRef: RecordRef; var RetenPolFilteringParam: Record "Reten. Pol. Filtering Param" temporary): Boolean
    var
        DefaultFiltering: Interface "Reten. Pol. Filtering";
    begin
        DefaultFiltering := "Reten. Pol. Filtering"::Default;
        if not DefaultFiltering.ApplyRetentionPolicySubSetFilters(RetentionPolicySetup, RecordRef, RetenPolFilteringParam) then
            exit(false);

        ExcludeProtectedRecords(RecordRef);
        exit(DefaultFiltering.Count(RecordRef) > 0)
    end;

    local procedure MarkFilteredRecords(var RecordRef: RecordRef)
    begin
        RecordRef.MarkedOnly(false);
        if RecordRef.FindSet() then
            repeat
                RecordRef.Mark(true);
            until RecordRef.Next() = 0;
        RecordRef.MarkedOnly(true);
    end;

    local procedure ExcludeProtectedRecords(var RecordRef: RecordRef)
    var
        Location: Record Location;
        PostedInvtPickHeader: Record "Posted Invt. Pick Header";
        PostedInvtPutawayHeader: Record "Posted Invt. Put-away Header";
        RetentionPolicyLog: Codeunit "Retention Policy Log";
        LocationCodeFieldRef: FieldRef;
        LocationBinMandatory: Dictionary of [Code[10], Boolean];
        LocationExists: Dictionary of [Code[10], Boolean];
        LocationCode: Code[10];
        LocationExistsForCode: Boolean;
    begin
        case RecordRef.Number of
            Database::"Posted Invt. Pick Header":
                begin
                    RecordRef.SetLoadFields(PostedInvtPickHeader.FieldNo("Location Code"));
                    LocationCodeFieldRef := RecordRef.Field(PostedInvtPickHeader.FieldNo("Location Code"));
                end;
            Database::"Posted Invt. Put-away Header":
                begin
                    RecordRef.SetLoadFields(PostedInvtPutawayHeader.FieldNo("Location Code"));
                    LocationCodeFieldRef := RecordRef.Field(PostedInvtPutawayHeader.FieldNo("Location Code"));
                end;
            else
                Error(UnsupportedTableErr, RecordRef.Number);
        end;

        Location.SetLoadFields("Bin Mandatory");
        if RecordRef.FindSet() then
            repeat
                LocationCode := LocationCodeFieldRef.Value;
                if LocationCode <> '' then begin
                    if not LocationExists.ContainsKey(LocationCode) then begin
                        LocationExistsForCode := Location.Get(LocationCode);
                        LocationExists.Add(LocationCode, LocationExistsForCode);
                        if LocationExistsForCode then
                            LocationBinMandatory.Add(LocationCode, Location."Bin Mandatory");
                    end else
                        LocationExistsForCode := LocationExists.Get(LocationCode);

                    if not LocationExistsForCode then begin
                        RecordRef.Mark(false);
                        RetentionPolicyLog.LogError(LogCategory(), LocationNotFoundErr, false);
                    end else
                        if LocationBinMandatory.Get(LocationCode) then
                            RecordRef.Mark(false);
                end else begin
                    RecordRef.Mark(false);
                    RetentionPolicyLog.LogError(LogCategory(), LocationNotFoundErr, false);
                end;
            until RecordRef.Next() = 0;

        RecordRef.SetLoadFields();
        RecordRef.MarkedOnly(true);
    end;

    local procedure LogCategory(): Enum "Retention Policy Log Category"
    var
        RetentionPolicyLogCategory: Enum "Retention Policy Log Category";
    begin
        exit(RetentionPolicyLogCategory::"Retention Policy - Apply");
    end;
}
