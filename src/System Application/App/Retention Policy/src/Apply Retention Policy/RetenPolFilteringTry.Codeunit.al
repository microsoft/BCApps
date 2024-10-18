// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.DataAdministration;

using System.Reflection;

codeunit 3921 "Reten. Pol. Filtering Try" implements "Reten. Pol. Filtering"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Retention Policy Log Entry" = r; // read through RecRef

    var
        RetentionPolicySetupNotFoundLbl: Label 'The retention policy setup for table %1 was not found.', Comment = '%1 = a id of a table (integer)';
        FutureExpirationDateWarningLbl: Label 'The expiration date %1 for table %2, %3, must be at least two days before the current date.', Comment = '%1 = a date, %2 = a id of a table (integer),%3 = the caption of the table.';
        AllRecordsFilterInfoLbl: Label 'Applying filters: Table ID: %1, All Records, Expiration Date: %2.', Comment = '%1 = a id of a table (integer), %2 = a date';
        NoRecordsToDeleteLbl: Label 'There are no records to delete for table ID %1, %2.', Comment = '%1 = a id of a table (integer), %2 = the caption of the table.';
        OldestRecordYoungerThanExpirationLbl: Label 'The oldest record in table ID %1, %2 is younger than the earliest expiration date. There are no records to delete.', Comment = '%1 = a id of a table (integer), %2 = the caption of the table.';
        MinExpirationDateErr: Label 'The expiration date for table %1, %2 must be at least %3 days before the current date. Please update the retention policy.', Comment = '%1 = table number, %2 = table caption, %3 = integer';
        RecordReferenceIndirectPermission: Interface "Record Reference";

    procedure HasReadPermission(TableId: Integer): Boolean
    var
        RecordReference: Codeunit "Record Reference";
        RecordRef: RecordRef;
    begin
        RecordRef.Open(TableId);
        RecordReference.Initialize(RecordRef, RecordReferenceIndirectPermission);
        exit(RecordReferenceIndirectPermission.ReadPermission(RecordRef))
    end;

    procedure Count(RecordRef: RecordRef): Integer
    begin
        exit(RecordReferenceIndirectPermission.Count(RecordRef))
    end;

    procedure ApplyRetentionPolicyAllRecordFilters(RetentionPolicySetup: Record "Retention Policy Setup"; var RecordRef: RecordRef; var RetenPolFilteringParam: Record "Reten. Pol. Filtering Param" temporary): Boolean
    var
        RetentionPeriod: Record "Retention Period";
        RetentionPolicyLog: Codeunit "Retention Policy Log";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
        RecordReference: Codeunit "Record Reference";
        ExpirationDate: Date;
    begin
        if not RetentionPeriod.Get(RetentionPolicySetup."Retention Period") then begin
            RetentionPolicyLog.LogWarning(LogCategory(), StrSubstNo(RetentionPolicySetupNotFoundLbl, RetentionPolicySetup."Table Id"));
            exit(false);
        end;

        ExpirationDate := CalculateExpirationDate(RetentionPeriod);
        if ExpirationDate >= Yesterday() then begin
            RetentionPolicyLog.LogWarning(LogCategory(), StrSubstNo(FutureExpirationDateWarningLbl, Format(ExpirationDate, 0, 9), RetentionPolicySetup."Table Id", RetentionPolicySetup."Table Caption"));
            exit(false);
        end;
        ValidateExpirationDate(ExpirationDate, RetentionPolicySetup."Table Id", RetentionPolicySetup."Table Caption");
        RetentionPolicyLog.LogInfo(LogCategory(), StrSubstNo(AllRecordsFilterInfoLbl, RetentionPolicySetup."Table Id", Format(ExpirationDate, 0, 9)));

        RecordRef.Open(RetentionPolicySetup."Table Id");
        RecordReference.Initialize(RecordRef, RecordReferenceIndirectPermission);
        ApplyRetentionPolicy.SetWhereOlderExpirationDateFilter(RetentionPolicySetup."Date Field No.", ExpirationDate, RecordRef, 11, RetenPolFilteringParam."Null Date Replacement value");
        if not RecordReferenceIndirectPermission.IsEmpty(RecordRef) then
            exit(true);
        RetentionPolicyLog.LogInfo(LogCategory(), StrSubstNo(NoRecordsToDeleteLbl, RetentionPolicySetup."Table Id", RetentionPolicySetup."Table Caption"));
        exit(false);
    end;

    procedure ApplyRetentionPolicySubSetFilters(RetentionPolicySetup: Record "Retention Policy Setup"; var RecordRef: RecordRef; var RetenPolFilteringParam: Record "Reten. Pol. Filtering Param" temporary): Boolean
    var
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
        RetentionPolicyLog: Codeunit "Retention Policy Log";
        RecordReference: Codeunit "Record Reference";
        YoungestExpirationDate, OldestRecordDate : Date;
        NumberOfDays: Integer;
        RetentionPolicySetupLineTableFilters: Dictionary of [Guid, Text];
        filters: List of [Text];
    begin
        RecordRef.Open(RetentionPolicySetup."Table Id");
        RecordReference.Initialize(RecordRef, RecordReferenceIndirectPermission);

        RetentionPolicySetupLine.SetRange("Table ID", RetentionPolicySetup."Table Id");
        RetentionPolicySetupLine.SetRange(Enabled, true);
        if not RetentionPolicySetupLine.FindSet(false) then
            exit(false);

        repeat
            // prepare table filter views outside the main loop, as unpacking blobs takes a lot of time and memory
            RetentionPolicySetupLineTableFilters.Add(RetentionPolicySetupLine.SystemId, RetentionPolicySetupLine.GetTableFilterView());
        until RetentionPolicySetupLine.Next() = 0;

        YoungestExpirationDate := GetYoungestExpirationDate(RetentionPolicySetup);
        if YoungestExpirationDate >= Yesterday() then
            YoungestExpirationDate := Yesterday();
        OldestRecordDate := GetOldestRecordDate(RetentionPolicySetup);
        if OldestRecordDate = 0D then
            NumberOfDays := 0
        else
            NumberOfDays := YoungestExpirationDate - OldestRecordDate;

        if NumberOfDays <= 0 then begin
            RetentionPolicyLog.LogInfo(LogCategory(), StrSubstNo(OldestRecordYoungerThanExpirationLbl, RetentionPolicySetup."Table Id", RetentionPolicySetup."Table Caption"));
            exit(false);
        end;

        if RetentionPolicySetupLineTableFilters.Count() <> 2 then
            Error('Benchmarking for 2 liens only')
        else begin
            filters := RetentionPolicySetupLineTableFilters.Values();

            RecordRef.FilterGroup := -1;
            RecordRef.SetView(filters.Get(1));

            RecordRef.FilterGroup := 11;
            RecordRef.SetView(filters.Get(0));

            RecordRef.FilterGroup := 0;
        end;

        RetenPolFilteringParam."Expired Record Expiration Date" := OldestRecordDate;

        exit(true);
    end;

    local procedure GetYoungestExpirationDate(RetentionPolicySetup: Record "Retention Policy Setup") YoungestExpirationDate: Date
    var
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
        RetentionPeriod: Record "Retention Period";
        ExpirationDate: Date;
    begin
        RetentionPolicySetupLine.SetRange("Table ID", RetentionPolicySetup."Table Id");
        RetentionPolicySetupLine.SetRange(Enabled, true);
        if RetentionPolicySetupLine.FindSet(false) then
            repeat
                if RetentionPeriod.Get(RetentionPolicySetupLine."Retention Period") then
                    ExpirationDate := CalculateExpirationDate(RetentionPeriod);
                if ExpirationDate >= YoungestExpirationDate then
                    YoungestExpirationDate := ExpirationDate;
            until RetentionPolicySetupLine.Next() = 0;
    end;

    local procedure GetOldestRecordDate(RetentionPolicySetup: Record "Retention Policy Setup"): Date
    var
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        CurrDate, OldestDate : Date;
        ViewStringTxt: Label 'sorting (field%1) where(field%1=1(<>''''))', Locked = true;
        PrevDateFieldNo: Integer;
        IsOldestDateDefined: Boolean;
    begin
        RecordRef.Open(RetentionPolicySetup."Table Id");
        RetentionPolicySetupLine.SetCurrentKey("Date Field No.");
        RetentionPolicySetupLine.SetRange("Table ID", RetentionPolicySetup."Table Id");
        RetentionPolicySetupLine.SetRange(Enabled, true);
        OldestDate := Today();
        if RetentionPolicySetupLine.FindSet(false) then
            repeat
                if RetentionPolicySetupLine."Date Field No." <> PrevDateFieldNo then begin
                    RecordRef.SetView(StrSubstNo(ViewStringTxt, RetentionPolicySetupLine."Date Field No."));
                    if RecordReferenceIndirectPermission.FindFirst(RecordRef, true) then begin
                        FieldRef := RecordRef.Field(RetentionPolicySetupLine."Date Field No.");

                        if FieldRef.Type = FieldType::DateTime then
                            CurrDate := DT2Date(FieldRef.Value())
                        else
                            CurrDate := FieldRef.Value();

                        if CurrDate < OldestDate then begin
                            OldestDate := CurrDate;
                            IsOldestDateDefined := true;
                        end;
                    end;
                end;
                PrevDateFieldNo := RetentionPolicySetupLine."Date Field No.";
            until RetentionPolicySetupLine.Next() = 0;

        if IsOldestDateDefined then
            exit(OldestDate)
        else
            exit(0D);
    end;

    local procedure CalculateExpirationDate(RetentionPeriod: Record "Retention Period"): Date
    var
        RetentionPeriodInterface: Interface "Retention Period";
    begin
        RetentionPeriodInterface := RetentionPeriod."Retention Period";
        exit(RetentionPeriodInterface.CalculateExpirationDate(RetentionPeriod, Today()));
    end;

    local procedure ValidateExpirationDate(ExpirationDate: Date; TableId: Integer; TableCaption: Text)
    var
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        RetentionPolicyLog: Codeunit "Retention Policy Log";
        MinExpirationDate: Date;
    begin
        if ExpirationDate > Today() then // a future expiration date means keep forever
            exit;
        MinExpirationDate := RetenPolAllowedTables.CalcMinimumExpirationDate(TableId);
        if ExpirationDate > MinExpirationDate then
            RetentionPolicyLog.LogError(LogCategory(), StrSubstNo(MinExpirationDateErr, TableId, TableCaption, RetenPolAllowedTables.GetMandatoryMinimumRetentionDays(TableId)));
    end;

    local procedure LogCategory(): Enum "Retention Policy Log Category"
    var
        RetentionPolicyLogCategory: Enum "Retention Policy Log Category";
    begin
        exit(RetentionPolicyLogCategory::"Retention Policy - Apply");
    end;

    local procedure Yesterday(): Date
    begin
        exit(CalcDate('<-1D>', Today()))
    end;
}