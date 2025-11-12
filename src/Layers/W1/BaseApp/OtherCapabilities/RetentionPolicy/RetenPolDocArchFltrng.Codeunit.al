namespace System.DataAdministration;

using System.Reflection;
using Microsoft.Sales.Archive;
using Microsoft.Purchases.Archive;
using Microsoft.Projects.Project.Archive;

codeunit 3994 "Reten. Pol. Doc. Arch. Fltrng." implements "Reten. Pol. Filtering"
{
    Access = Internal;

    var
        NoRecordsToDeleteLbl: Label 'There are no records to delete for table ID %1, %2.', Comment = '%1 = a id of a table (integer), %2 = the caption of the table.';
        MinExpirationDateErr: Label 'The expiration date for table %1, %2 must be at least %3 days before the current date. Please update the retention policy.', Comment = '%1 = table number, %2 = table caption, %3 = integer';
        OldestRecordYoungerThanExpirationLbl: Label 'The oldest record in table ID %1, %2 is younger than the earliest expiration date. There are no records to delete.', Comment = '%1 = a id of a table (integer), %2 = the caption of the table.';
        RecordReferenceIndirectPermission: Interface "Record Reference";

    procedure HasReadPermission(TableId: Integer): Boolean
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open(TableId);
        exit(RecordRef.ReadPermission())
    end;

    procedure Count(RecordRef: RecordRef): Integer
    begin
        exit(RecordReferenceIndirectPermission.Count(RecordRef))
    end;

    procedure ApplyRetentionPolicyAllRecordFilters(RetentionPolicySetup: Record "Retention Policy Setup"; var RecRef: RecordRef; var RetenPolFilteringParam: Record "Reten. Pol. Filtering Param" temporary): Boolean
    begin
        // not used
    end;

    procedure ApplyRetentionPolicySubSetFilters(RetentionPolicySetup: Record "Retention Policy Setup"; var RecordRef: RecordRef; var RetenPolFilteringParam: Record "Reten. Pol. Filtering Param" temporary): Boolean
    var
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
        RetentionPolicyLog: Codeunit "Retention Policy Log";
        RecordReference: Codeunit "Record Reference";
        TotalRecords: Integer;
        YoungestExpirationDate, OldestRecordDate, CurrDate : Date;
        NumberOfDays, i : Integer;
    begin
        RecordRef.Open(RetentionPolicySetup."Table ID");
        RecordReference.Initialize(RecordRef, RecordReferenceIndirectPermission);

        RetentionPolicySetupLine.SetRange("Table ID", RetentionPolicySetup."Table Id");
        RetentionPolicySetupLine.SetRange(Enabled, true);
        if RetentionPolicySetupLine.IsEmpty then
            exit(false);

        YoungestExpirationDate := GetYoungestExpirationDate(RetentionPolicySetup);
        if YoungestExpirationDate >= Yesterday() then
            YoungestExpirationDate := Yesterday();
        OldestRecordDate := GetOldestRecordDate(RetentionPolicySetup);
        NumberOfDays := YoungestExpirationDate - OldestRecordDate;

        if NumberOfDays <= 0 then begin
            RetentionPolicyLog.LogInfo(LogCategory(), StrSubstNo(OldestRecordYoungerThanExpirationLbl, RetentionPolicySetup."Table Id", RetentionPolicySetup."Table Caption"));
            exit(false);
        end;

        CurrDate := OldestRecordDate;
        for i := 1 to NumberOfDays do begin
            CurrDate := CalcDate('<+1D>', CurrDate);
            RecordRef.MarkedOnly(false);

            // Pass 1: Mark Records to delete
            MarkRecordRefWithRecordsToDelete(RetentionPolicySetup, RecordRef, RetenPolFilteringParam, CurrDate);
            // Pass 2: UnMark Records to keep
            UnMarkRecordRefWithRecordsToKeep(RetentionPolicySetup, RecordRef, RetenPolFilteringParam, CurrDate);

            // if max records exceeded, exit loop
            RecordRef.MarkedOnly(true);
            TotalRecords := count(RecordRef);
            if TotalRecords >= MaxNumberOfRecordsToDelete() then begin
                RetenPolFilteringParam."Expired Record Expiration Date" := CurrDate;
                exit(true);
            end;
        end;
        RetenPolFilteringParam."Expired Record Expiration Date" := CurrDate;

        if not RecordReferenceIndirectPermission.IsEmpty(RecordRef) then
            exit(true);

        RetentionPolicyLog.LogInfo(LogCategory(), StrSubstNo(NoRecordsToDeleteLbl, RetentionPolicySetup."Table Id", RetentionPolicySetup."Table Caption"));
        exit(false);
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
    begin
        RecordRef.Open(RetentionPolicySetup."Table Id");
        RetentionPolicySetupLine.SetCurrentKey("Date Field No.");
        RetentionPolicySetupLine.SetRange("Table ID", RetentionPolicySetup."Table ID");
        RetentionPolicySetupLine.SetRange(Enabled, true);
        if RetentionPolicySetupLine.FindSet(false) then
            repeat
                if RetentionPolicySetupLine."Date Field No." <> PrevDateFieldNo then begin
                    RecordRef.SetView(StrSubstNo(ViewStringTxt, RetentionPolicySetupLine."Date Field No."));
                    RecordReferenceIndirectPermission.FindFirst(RecordRef);

                    FieldRef := RecordRef.Field(RetentionPolicySetupLine."Date Field No.");

                    if FieldRef.Type = FieldType::DateTime then
                        CurrDate := DT2Date(FieldRef.Value())
                    else
                        CurrDate := FieldRef.Value();

#pragma warning disable AA0205
                    if OldestDate = 0D then
#pragma warning restore AA0205
                        OldestDate := CurrDate;
                    if CurrDate < OldestDate then
                        OldestDate := CurrDate;
                end;
                PrevDateFieldNo := RetentionPolicySetupLine."Date Field No.";
            until RetentionPolicySetupLine.Next() = 0;
        exit(OldestDate);
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

    local procedure MarkRecordRefWithRecordsToDelete(RetentionPolicySetup: Record "Retention Policy Setup"; var RecordRef: RecordRef; var RetenPolFilteringParam: Record "Reten. Pol. Filtering Param" temporary; CurrDate: Date)
    begin
        SetMarksOnRecordRef(RetentionPolicySetup, RecordRef, true, RetenPolFilteringParam, CurrDate);
    end;

    local procedure UnMarkRecordRefWithRecordsToKeep(RetentionPolicySetup: Record "Retention Policy Setup"; RecordRef: RecordRef; var RetenPolFilteringParam: Record "Reten. Pol. Filtering Param" temporary; CurrDate: Date)
    begin
        SetMarksOnRecordRef(RetentionPolicySetup, RecordRef, false, RetenPolFilteringParam, CurrDate);
    end;

    local procedure SetMarksOnRecordRef(RetentionPolicySetup: Record "Retention Policy Setup"; RecordRef: RecordRef; MarkValue: boolean; var RetenPolFilteringParam: Record "Reten. Pol. Filtering Param" temporary; CurrDate: Date);
    var
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
        RetentionPeriod: Record "Retention Period";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
        ExpirationDate: Date;
        UsingKeepLastVersion: Boolean;
    begin
        UsingKeepLastVersion := UseKeepLastVersion(RetentionPolicySetup."Table ID");
        RetentionPolicySetupLine.SetRange("Table ID", RetentionPolicySetup."Table ID");
        RetentionPolicySetupLine.SetRange(Enabled, true);
        if RetentionPolicySetupLine.FindSet(false) then
            repeat
                if not RetentionPeriod.Get(RetentionPolicySetupLine."Retention Period") then
                    exit;
                ExpirationDate := CalculateExpirationDate(RetentionPeriod);
                RetentionPolicySetupLine.CalcFields("Table Caption");
                ValidateExpirationDate(ExpirationDate, RetentionPolicySetupLine."Table ID", RetentionPolicySetupLine."Table Caption");

                // set filter for Table Filter in filtergroup 10
                SetRetentionPolicyLineTableFilter(RetentionPolicySetupLine, RecordRef, 10);

                if MarkValue then begin
                    if (ExpirationDate < Yesterday()) and (CurrDate <= ExpirationDate) then
                        ExpirationDate := CurrDate;
                    // set filter for date in filtergroup 11
                    if MarkValue then
                        ApplyRetentionPolicy.SetWhereOlderExpirationDateFilter(RetentionPolicySetupLine."Date Field No.", ExpirationDate, RecordRef, 11, RetenPolFilteringParam."Null Date Replacement value");
                    ApplyRetentionPolicy.SetSingleDateExpirationDateFilter(RetentionPolicySetupLine."Date Field No.", ExpirationDate, RecordRef, 11, RetenPolFilteringParam."Null Date Replacement value");
                    SetMarks(RecordRef, UsingKeepLastVersion, RetentionPolicySetupLine."Keep Last Version", ExpirationDate, true);
                end else
                    if (ExpirationDate <= CurrDate) or (ExpirationDate >= yesterday()) then begin
                        // if ExpirationDate is >= today - 1, don't set filter and remove all records from temp
                        if ExpirationDate < Yesterday() then
                            // set filter for date in filtergroup 11
                            ApplyRetentionPolicy.SetWhereNewerExpirationDateFilter(RetentionPolicySetupLine."Date Field No.", ExpirationDate, RecordRef, 11, RetenPolFilteringParam."Null Date Replacement value");
                        SetMarks(RecordRef, UsingKeepLastVersion, RetentionPolicySetupLine."Keep Last Version", ExpirationDate, false);
                    end;

                ClearFilterGroupOnRecRef(RecordRef, 10);
                ClearFilterGroupOnRecRef(RecordRef, 11);
            until RetentionPolicySetupLine.Next() = 0;
    end;

    local procedure SetMarks(var RecordRef: RecordRef; UsingKeepLastVersion: Boolean; KeepLastVersion: Boolean; ExpirationDate: Date; MarkValue: boolean)
    begin
        if RecordReferenceIndirectPermission.FindSet(RecordRef, false, false, true) then
            repeat
                if MarkValue then begin
                    if KeepLastVersion then begin
                        if not IsMaxArchivedVersion(RecordRef) then
                            RecordRef.Mark := true
                    end else
                        RecordRef.Mark := true;
                end else begin
                    if ExpirationDate > Yesterday() then // if ExpirationDate is >= today - 1 remove all records from temp
                        RecordRef.Mark := false;
                    if UsingKeepLastVersion and (not KeepLastVersion) then begin
                        if IsMaxArchivedVersion(RecordRef) then
                            RecordRef.Mark := false;
                    end else
                        RecordRef.Mark := false;
                end;
            until RecordReferenceIndirectPermission.Next(RecordRef) = 0;
    end;

    local procedure UseKeepLastVersion(TableId: Integer): boolean
    var
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
    begin
        RetentionPolicySetupLine.SetRange("Table ID", TableId);
        RetentionPolicySetupLine.SetRange(Enabled, true);
        RetentionPolicySetupLine.SetRange("Keep Last Version", true);
        exit(not RetentionPolicySetupLine.IsEmpty())
    end;

    local procedure IsMaxArchivedVersion(RecRef: RecordRef): Boolean
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        JobArchive: Record "Job Archive";
        VersionFieldRef: FieldRef;
        MaxVersionFieldRef: FieldRef;
        MatchingTableFound: Boolean;
        Version: Integer;
        MaxVersion: Integer;
    begin
        case RecRef.Number of
            Database::"Sales Header Archive":
                begin
                    VersionFieldRef := RecRef.Field(SalesHeaderArchive.FieldNo("Version No."));
                    MaxVersionFieldRef := RecRef.Field(SalesHeaderArchive.FieldNo("No. of Archived Versions"));
                    MatchingTableFound := true;
                end;
            Database::"Purchase Header Archive":
                begin
                    VersionFieldRef := RecRef.Field(PurchaseHeaderArchive.FieldNo("Version No."));
                    MaxVersionFieldRef := RecRef.Field(PurchaseHeaderArchive.FieldNo("No. of Archived Versions"));
                    MatchingTableFound := true;
                end;
            Database::"Job Archive":
                begin
                    VersionFieldRef := RecRef.Field(JobArchive.FieldNo("Version No."));
                    MaxVersionFieldRef := RecRef.Field(JobArchive.FieldNo("No. of Archived Versions"));
                    MatchingTableFound := true;
                end;
            else
                OnIsMaxArchivedVersionOnCaseElse(RecRef, VersionFieldRef, MaxVersionFieldRef, MatchingTableFound);
        end;
        if not MatchingTableFound then
            exit(false);

        MaxVersionFieldRef.CalcField();
        Version := VersionFieldRef.Value();
        MaxVersion := MaxVersionFieldRef.Value();
        exit(Version = MaxVersion);
    end;

    local procedure SetRetentionPolicyLineTableFilter(var RetentionPolicySetupLine: Record "Retention Policy Setup Line"; var RecordRef: RecordRef; FilterGroup: Integer);
    begin
        RecordRef.FilterGroup := FilterGroup;
        RecordRef.SetView(RetentionPolicySetupLine.GetTableFilterView());
    end;

    local procedure ClearFilterGroupOnRecRef(var RecordRef: RecordRef; FilterGroup: Integer)
    begin
        RecordRef.FilterGroup := FilterGroup;
        RecordRef.SetView('');
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

    procedure MaxNumberOfRecordsToDelete(): Integer
    begin
        exit(250000)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsMaxArchivedVersionOnCaseElse(RecRef: RecordRef; var VersionFieldRef: FieldRef; var MaxVersionFieldRef: FieldRef; var MatchingTableFound: Boolean)
    begin
    end;
}