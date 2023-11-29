// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 309 "No. Series - Batch Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "No. Series Line" = rm;

    var
        TempGlobalNoSeriesLine: Record "No. Series Line" temporary;
        LockedNoSeriesLine: Record "No. Series Line";
        SimulationMode: Boolean;

    procedure SetInitialState(TempNoSeriesLine: Record "No. Series Line" temporary)
    begin
        if IsSameNoSeriesLine(TempNoSeriesLine) then begin
            TempGlobalNoSeriesLine := TempNoSeriesLine;
            exit;
        end;

        if TempGlobalNoSeriesLine.Get(TempNoSeriesLine."Series Code", TempNoSeriesLine."Line No.") then
            exit;

        TempGlobalNoSeriesLine := TempNoSeriesLine;
        TempGlobalNoSeriesLine.Insert();
    end;

    local procedure IsSameNoSeriesLine(TempNoSeriesLine: Record "No. Series Line" temporary): Boolean
    begin
        exit((TempGlobalNoSeriesLine."Series Code" = TempNoSeriesLine."Series Code") and
             (TempGlobalNoSeriesLine."Line No." = TempNoSeriesLine."Line No."));
    end;

    procedure PeekNextNo(NoSeriesCode: Code[20]): Code[20]
    begin
        exit(PeekNextNo(NoSeriesCode, WorkDate()));
    end;

    procedure PeekNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Get(NoSeriesCode);
        exit(PeekNextNo(NoSeries, UsageDate));
    end;

    procedure PeekNextNo(NoSeries: Record "No. Series"): Code[20]
    begin
        exit(PeekNextNo(NoSeries, WorkDate()));
    end;

    procedure PeekNextNo(NoSeries: Record "No. Series"; UsageDate: Date): Code[20]
    var
        TempNoSeriesLine: Record "No. Series Line" temporary;
    begin
        GetNoSeriesLine(TempNoSeriesLine, NoSeries, UsageDate);
        exit(PeekNextNo(TempNoSeriesLine, UsageDate));
    end;

    procedure PeekNextNo(TempNoSeriesLine: Record "No. Series Line" temporary; UsageDate: Date): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        SetInitialState(TempNoSeriesLine);
        exit(NoSeries.PeekNextNo(TempGlobalNoSeriesLine, UsageDate));
    end;

    procedure GetNextNo(NoSeriesCode: Code[20]): Code[20]
    begin
        exit(GetNextNo(NoSeriesCode, WorkDate()));
    end;

    procedure GetNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Get(NoSeriesCode);
        exit(GetNextNo(NoSeries, UsageDate));
    end;

    procedure GetNextNo(NoSeries: Record "No. Series"): Code[20]
    begin
        exit(GetNextNo(NoSeries, WorkDate()));
    end;

    procedure GetNextNo(NoSeries: Record "No. Series"; UsageDate: Date): Code[20]
    var
        TempNoSeriesLine: Record "No. Series Line" temporary;
    begin
        GetNoSeriesLine(TempNoSeriesLine, NoSeries, UsageDate);
        exit(GetNextNo(TempNoSeriesLine, UsageDate));
    end;

    procedure GetNextNo(TempNoSeriesLine: Record "No. Series Line" temporary; UsageDate: Date): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        SetInitialState(TempNoSeriesLine);
        LockedNoSeriesLine.LockTable();
        exit(NoSeries.GetNextNo(TempGlobalNoSeriesLine, UsageDate, false));
    end;

    procedure SimulateGetNextNo(NoSeriesCode: Code[20]; UsageDate: Date; PrevDocumentNo: Code[20]): Code[20]
    var
        NoSeries: Record "No. Series";
        TempNoSeriesLine: Record "No. Series Line" temporary;
        NoSeriesMgtInternal: Codeunit NoSeriesMgtInternal;
    begin
        if NoSeriesCode = '' then
            exit(IncStr(PrevDocumentNo));

        SetSimulationMode();

        NoSeries.Get(NoSeriesCode);
        GetNoSeriesLine(TempNoSeriesLine, NoSeries, UsageDate);
        TempNoSeriesLine."Last No. Used" := PrevDocumentNo;
        if not NoSeriesMgtInternal.EnsureLastNoUsedIsWithinValidRange(TempNoSeriesLine, true) then
            exit(IncStr(PrevDocumentNo));

        TempNoSeriesLine.Modify(false);
        exit(GetNextNo(TempNoSeriesLine, UsageDate));
    end;

    procedure GetLastNoUsed(TempNoSeriesLine: Record "No. Series Line" temporary): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        SetInitialState(TempNoSeriesLine);
        exit(NoSeries.GetLastNoUsed(TempGlobalNoSeriesLine));
    end;

    procedure SetSimulationMode()
    begin
        SimulationMode := true;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"No. Series Line", 'rm', InherentPermissionsScope::Both)]
    procedure SaveState(TempNoSeriesLine: Record "No. Series Line" temporary)
    begin
        if SimulationMode then
            exit;
        if not TempGlobalNoSeriesLine.Get(TempNoSeriesLine."Series Code", TempNoSeriesLine."Line No.") then
            exit;
        UpdateNoSeriesLine(TempGlobalNoSeriesLine);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"No. Series Line", 'rm', InherentPermissionsScope::Both)]
    procedure SaveState();
    begin
        if SimulationMode then
            exit;
        if TempGlobalNoSeriesLine.FindSet() then
            repeat
                UpdateNoSeriesLine(TempGlobalNoSeriesLine);
            until TempGlobalNoSeriesLine.Next() = 0;
    end;

    local procedure UpdateNoSeriesLine(var TempNoSeriesLine: Record "No. Series Line" temporary)
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.Get(TempNoSeriesLine."Series Code", TempNoSeriesLine."Line No.");
        NoSeriesLine."Last No. Used" := TempNoSeriesLine."Last No. Used";
        NoSeriesLine."Last Date Used" := TempNoSeriesLine."Last Date Used";
        NoSeriesLine.Modify(true);
    end;

    procedure GetNoSeriesLine(var NoSeriesLine: Record "No. Series Line" temporary; NoSeries: Record "No. Series"; UsageDate: Date)
    var
        NoSeriesLine2: Record "No. Series Line";
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        if NoSeriesCodeunit.GetNoSeriesLine(TempGlobalNoSeriesLine, NoSeries.Code, UsageDate, true) then begin
            NoSeriesLine := TempGlobalNoSeriesLine;
            exit;
        end;

        if not NoSeriesCodeunit.GetNoSeriesLine(NoSeriesLine2, NoSeries.Code, UsageDate, false) then
            exit;

        SetInitialState(NoSeriesLine2);
        NoSeriesLine.Copy(TempGlobalNoSeriesLine, true);
    end;
}