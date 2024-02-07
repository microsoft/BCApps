// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 305 "No. Series - Setup Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure SetImplementation(var NoSeries: Record "No. Series"; Implementation: Enum "No. Series Implementation")
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", NoSeries.Code);
        NoSeriesLine.SetRange(Open, true);
        NoSeriesLine.ModifyAll(Implementation, Implementation, true);
    end;

    procedure DrillDown(var NoSeries: Record "No. Series")
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        SetNoSeriesCurrentLineFilters(NoSeries, NoSeriesLine, true);
        Page.RunModal(0, NoSeriesLine);
    end;

    procedure UpdateLine(var NoSeriesRec: Record "No. Series"; var StartDate: Date; var StartNo: Code[20]; var EndNo: Code[20]; var LastNoUsed: Code[20]; var WarningNo: Code[20]; var IncrementByNo: Integer; var LastDateUsed: Date; var Implementation: Enum "No. Series Implementation")
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesManagement: Codeunit NoSeriesManagement;
        IsHandled: Boolean;
#pragma warning restore AL0432        
#endif
    begin
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesManagement.OnBeforeUpdateLine(NoSeriesRec, StartDate, StartNo, EndNo, LastNoUsed, WarningNo, IncrementByNo, LastDateUsed, Implementation, IsHandled);
        if IsHandled then
            exit;
#pragma warning restore AL0432        
#endif
        SetNoSeriesCurrentLineFilters(NoSeriesRec, NoSeriesLine, false);

        StartDate := NoSeriesLine."Starting Date";
        StartNo := NoSeriesLine."Starting No.";
        EndNo := NoSeriesLine."Ending No.";
        LastNoUsed := NoSeries.GetLastNoUsed(NoSeriesLine."Series Code");
        WarningNo := NoSeriesLine."Warning No.";
        IncrementByNo := NoSeriesLine."Increment-by No.";
        LastDateUsed := NoSeriesLine."Last Date Used";
        Implementation := NoSeriesLine.Implementation;
    end;

    local procedure SetNoSeriesCurrentLineFilters(var NoSeriesRec: Record "No. Series"; var NoSeriesLine: Record "No. Series Line"; ResetForDrillDown: Boolean)
    var
        NoSeries: Codeunit "No. Series";
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesManagement: Codeunit NoSeriesManagement;
#pragma warning restore AL0432
#endif
    begin
        NoSeriesLine.Reset();
        NoSeriesLine.SetCurrentKey("Series Code", "Starting Date");
        NoSeriesLine.SetRange("Series Code", NoSeriesRec.Code);
        NoSeriesLine.SetRange("Starting Date", 0D, WorkDate());
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesManagement.RaiseObsoleteOnNoSeriesLineFilterOnBeforeFindLast(NoSeriesLine);
#pragma warning restore AL0432
#endif
        if NoSeriesLine.FindLast() then begin
            NoSeriesLine.SetRange("Starting Date", NoSeriesLine."Starting Date");
            NoSeriesLine.SetRange(Open, true);
        end;

        if not NoSeriesLine.FindLast() then begin
            NoSeriesLine.Reset();
            NoSeriesLine.SetRange("Series Code", NoSeriesRec.Code);
        end;

        if not NoSeriesLine.FindFirst() then
            NoSeriesLine.Init();

        if ResetForDrillDown then begin
            NoSeriesLine.SetRange("Starting Date");
            NoSeriesLine.SetRange(Open);
        end;

        NoSeries.OnAfterSetNoSeriesCurrentLineFilters(NoSeriesRec, NoSeriesLine, ResetForDrillDown);
    end;

    procedure MayProduceGaps(NoSeriesLine: Record "No. Series Line"): Boolean
    var
        NoSeriesSingle: Interface "No. Series - Single";
    begin
        NoSeriesSingle := NoSeriesLine.Implementation;
        exit(NoSeriesSingle.MayProduceGaps());
    end;

    procedure CalculateOpen(NoSeriesLine: Record "No. Series Line"): Boolean
    var
        NoSeries: Codeunit "No. Series";
        NoSeriesStatelessImpl: Codeunit "No. Series - Stateless Impl.";
        LastNoUsed, NextNo : Code[20];
    begin
        if NoSeriesLine."Ending No." = '' then
            exit(true);

        LastNoUsed := NoSeries.GetLastNoUsed(NoSeriesLine);

        if LastNoUsed = '' then
            exit(true);

        if LastNoUsed >= NoSeriesLine."Ending No." then
            exit(false);

        if StrLen(LastNoUsed) > StrLen(NoSeriesLine."Ending No.") then
            exit(false);

        if NoSeriesLine."Increment-by No." <> 1 then begin
            NextNo := NoSeriesStatelessImpl.IncrementNoText(LastNoUsed, NoSeriesLine."Increment-by No.", NoSeriesLine."Series Code");
            if NextNo > NoSeriesLine."Ending No." then
                exit(false);
            if StrLen(NextNo) > StrLen(NoSeriesLine."Ending No.") then
                exit(false);
        end;
        exit(true);
    end;
}