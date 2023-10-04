// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 310 "No. Series - Stateful Impl." implements "No. Series - Batch"
{
    Access = Internal;

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
}