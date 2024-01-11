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
        TempNoSeriesLine: Record "No. Series Line" temporary;
    begin
        GetNoSeriesLine(TempNoSeriesLine, NoSeriesCode, UsageDate);
        exit(PeekNextNo(TempNoSeriesLine, UsageDate));
    end;

    procedure PeekNextNo(TempNoSeriesLine: Record "No. Series Line" temporary; UsageDate: Date): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        SetInitialState(TempNoSeriesLine);
        exit(NoSeries.PeekNextNo(TempGlobalNoSeriesLine, UsageDate));
    end;

    procedure GetNextNo(NoSeriesCode: Code[20]; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    var
        TempNoSeriesLine: Record "No. Series Line" temporary;
    begin
        GetNoSeriesLine(TempNoSeriesLine, NoSeriesCode, UsageDate);
        exit(GetNextNo(TempNoSeriesLine, UsageDate, HideErrorsAndWarnings));
    end;

    procedure GetNextNo(TempNoSeriesLine: Record "No. Series Line" temporary; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        SetInitialState(TempNoSeriesLine);
        LockedNoSeriesLine.LockTable();
        exit(NoSeries.GetNextNo(TempGlobalNoSeriesLine, UsageDate, HideErrorsAndWarnings));
    end;

    procedure SimulateGetNextNo(NoSeriesCode: Code[20]; UsageDate: Date; PrevDocumentNo: Code[20]): Code[20]
    var
        TempNoSeriesLine: Record "No. Series Line" temporary;
        NoSeriesStatelessImpl: Codeunit "No. Series - Stateless Impl.";
    begin
        if NoSeriesCode = '' then
            exit(IncStr(PrevDocumentNo));

        SetSimulationMode();

        GetNoSeriesLine(TempNoSeriesLine, NoSeriesCode, UsageDate);
        TempNoSeriesLine."Last No. Used" := PrevDocumentNo;
        if not NoSeriesStatelessImpl.EnsureLastNoUsedIsWithinValidRange(TempNoSeriesLine, true) then
            exit(IncStr(PrevDocumentNo));

        TempNoSeriesLine.Modify(false);
        exit(GetNextNo(TempNoSeriesLine, UsageDate, false));
    end;

    procedure GetLastNoUsed(NoSeriesCode: Code[20]): Code[20]
    var
        TempNoSeriesLine: Record "No. Series Line" temporary;
        NoSeries: Codeunit "No. Series";
    begin
        GetNoSeriesLine(TempNoSeriesLine, NoSeriesCode, WorkDate());
        exit(NoSeries.GetLastNoUsed(TempGlobalNoSeriesLine));
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

    procedure GetNoSeriesLine(var NoSeriesLine: Record "No. Series Line" temporary; NoSeriesCode: Code[20]; UsageDate: Date)
    var
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        if NoSeriesCodeunit.GetNoSeriesLine(TempGlobalNoSeriesLine, NoSeriesCode, UsageDate, true) then begin
            NoSeriesLine.Copy(TempGlobalNoSeriesLine, true);
            exit;
        end;

        GetNoSeriesLines(NoSeriesCode);

        NoSeriesCodeunit.GetNoSeriesLine(TempGlobalNoSeriesLine, NoSeriesCode, UsageDate, false);
        NoSeriesLine.Copy(TempGlobalNoSeriesLine, true);
    end;

    local procedure GetNoSeriesLines(NoSeriesCode: Code[20])
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.SetRange(Open, true);
        if NoSeriesLine.FindSet() then
            repeat
                TempGlobalNoSeriesLine := NoSeriesLine;
                TempGlobalNoSeriesLine.Insert();
            until NoSeriesLine.Next() = 0;
    end;
}