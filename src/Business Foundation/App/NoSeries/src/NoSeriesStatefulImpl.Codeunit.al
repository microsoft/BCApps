// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 310 "No. Series - Stateful Impl." implements "No. Series - Batch"
{
    Access = Internal;
    permissions = tabledata "No. Series Line" = rm;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        TempGlobalNoSeriesLine: Record "No. Series Line" temporary;

    procedure SetInitialState(TempNoSeriesLine: Record "No. Series Line" temporary);
    begin
        if IsSameNoSeriesLine(TempNoSeriesLine) then
            exit;

        if TempGlobalNoSeriesLine.Get(TempNoSeriesLine."Series Code", TempNoSeriesLine."Line No.") then
            exit;

        TempGlobalNoSeriesLine := TempNoSeriesLine;
        TempglobalNoSeriesLine.Insert();
    end;

    procedure PeekNextNo(TempNoSeriesLine: Record "No. Series Line" temporary): Code[20];
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        SetInitialState(TempNoSeriesLine);
        exit(NoSeriesImpl.PeekNextNo(TempGlobalNoSeriesLine));
    end;

    procedure GetNextNo(TempNoSeriesLine: Record "No. Series Line" temporary): Code[20];
    var
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        SetInitialState(TempNoSeriesLine);
        exit(NoSeriesImpl.GetNextNo(TempGlobalNoSeriesLine));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"No. Series Line", 'rm', InherentPermissionsScope::Both)]
    procedure SaveState(TempNoSeriesLine: Record "No. Series Line" temporary);
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        if not TempGlobalNoSeriesLine.Get(TempNoSeriesLine."Series Code", TempNoSeriesLine."Line No.") then
            exit;

        NoSeriesLine := TempGlobalNoSeriesLine;
#pragma warning disable AA0214
        NoSeriesLine.Modify(true);
#pragma warning restore AA0214
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"No. Series Line", 'rm', InherentPermissionsScope::Both)]
    procedure SaveState();
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        if TempGlobalNoSeriesLine.FindSet() then
            repeat
                NoSeriesLine := TempGlobalNoSeriesLine;
#pragma warning disable AA0214
                NoSeriesLine.Modify(true);
#pragma warning restore AA0214
            until TempGlobalNoSeriesLine.Next() = 0;
    end;

    local procedure IsSameNoSeriesLine(TempNoSeriesLine: Record "No. Series Line" temporary): Boolean;
    begin
        exit((TempGlobalNoSeriesLine."Series Code" = TempNoSeriesLine."Series Code") and
             (TempGlobalNoSeriesLine."Line No." = TempNoSeriesLine."Line No."));
    end;

    procedure GetNoSeriesLine(var NoSeriesLine: Record "No. Series Line" temporary; NoSeries: Record "No. Series"; UsageDate: Date)
    var
        NoSeriesLine2: Record "No. Series Line";
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        if NoSeriesImpl.GetNoSeriesLine(TempGlobalNoSeriesLine, NoSeries, UsageDate, true) then begin
            NoSeriesLine := TempGlobalNoSeriesLine;
            exit;
        end;

        if not NoSeriesImpl.GetNoSeriesLine(NoSeriesLine2, NoSeries, UsageDate, false) then
            exit;

        SetInitialState(NoSeriesLine2);
        NoSeriesLine := TempGlobalNoSeriesLine;
    end;
}