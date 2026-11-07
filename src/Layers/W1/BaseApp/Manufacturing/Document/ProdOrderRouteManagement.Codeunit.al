// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

codeunit 99000772 "Prod. Order Route Management"
{

    trigger OnRun()
    begin
    end;

    var
        CannotCalculateRoutingNumberErr: Label 'Cannot calculate routing number %3 %4 in %1 production order %2, because sequence number %5 is higher than the maximum sequence number, %6.', Comment = '%1: Status Text; %2: Field(Prod. Order No.); %3: Field(Routing No.); %4: Direction Text; %5: Field(Actual Sequence); %6: Field (Max. Sequences)';
#pragma warning disable AA0074
        Text001: Label 'Back';
        Text002: Label 'back';
#pragma warning disable AA0470
        Text003: Label 'Actual number of termination processes in prod. order %1 route %2  is %3. They should be 1. Check %4.';
        Text004: Label 'Actual Number of start processes in prod. order %1 route %2 is %3. They should be 1. Check %4.';
        Text005: Label 'Not all routing lines are sequenced backwards on routing %1. Check %2.';
        Text006: Label 'Not all routing lines are sequenced forward on routing %1. Check %2.';
        Text007: Label 'Previous operations for %1 cannot be found.';
        Text008: Label 'Next operations for %1 cannot be found.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ErrList: Text[50];
#pragma warning disable AA0074
        Text009: Label 'This change may have caused bin codes on some production order component lines to be different from those on the production order routing line. Do you want to automatically align all of these unmatched bin codes?';
#pragma warning restore AA0074

    procedure NeedsCalculation(ProductionOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20]; RoutingRefNo: Integer; RoutingNo: Code[20]): Boolean
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        SetRoutingFilter(ProdOrderRtngLine, ProductionOrderStatus, ProdOrderNo, RoutingNo, RoutingRefNo);
        ProdOrderRtngLine.SetRange(Recalculate, true);
        ProdOrderRtngLine.SetFilter("Routing Status", '<>%1', ProdOrderRtngLine."Routing Status"::Finished);
        OnNeedsCalculationOnBeforeFindProdOrderRtngLine(ProdOrderRtngLine);

        exit(ProdOrderRtngLine.FindFirst());
    end;

    local procedure ErrorInRouting(Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; RoutingNo: Code[20]; Direction: Text[20]; ActualSequence: Integer; MaxSequences: Integer)
    begin
        Error(
          CannotCalculateRoutingNumberErr,
          Status,
          ProdOrderNo,
          RoutingNo,
          Direction,
          ActualSequence,
          MaxSequences);
    end;

    local procedure InsertInErrList(ProdOrderRtngLine: Record "Prod. Order Routing Line")
    begin
        if (StrLen(ErrList) + StrLen(ProdOrderRtngLine."Operation No.") + 1) > MaxStrLen(ErrList) then
            exit;

        if StrLen(ErrList) > 0 then
            ErrList := ErrList + ',' + ProdOrderRtngLine."Operation No."
        else
            ErrList := ProdOrderRtngLine."Operation No.";
    end;

    procedure SetNextOperations(ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderRtngLine2: Record "Prod. Order Routing Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetNextOperations(ProdOrderLine, IsHandled);
        if IsHandled then
            exit;

        SetRoutingFilter(
          ProdOrderRtngLine, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.",
          ProdOrderLine."Routing No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRtngLine.ModifyAll("Next Operation No.", '');

        if ProdOrderRtngLine.Find('-') then
            repeat
                ProdOrderRtngLine2 := ProdOrderRtngLine;
                ProdOrderRtngLine2.SetRange(Status, ProdOrderLine.Status);
                ProdOrderRtngLine2.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
                ProdOrderRtngLine2.SetRange("Routing No.", ProdOrderLine."Routing No.");
                ProdOrderRtngLine2.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
                if ProdOrderRtngLine2.Find('>') then begin
                    ProdOrderRtngLine."Next Operation No." := ProdOrderRtngLine2."Operation No.";
                    ProdOrderRtngLine.Modify();
                end;
            until ProdOrderRtngLine.Next() = 0;
    end;

    local procedure CalcPreviousOperations(ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderRtngLine2: Record "Prod. Order Routing Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcPreviousOperations(ProdOrderLine, IsHandled);
        if IsHandled then
            exit;

        SetRoutingFilter(
          ProdOrderRtngLine, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.",
          ProdOrderLine."Routing No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRtngLine.ModifyAll("Previous Operation No.", '');

        if ProdOrderRtngLine.Find('-') then
            repeat
                if ProdOrderRtngLine."Next Operation No." <> '' then begin
                    SetRoutingFilter(
                      ProdOrderRtngLine2, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.",
                      ProdOrderLine."Routing No.", ProdOrderLine."Routing Reference No.");
                    ProdOrderRtngLine2.SetFilter("Operation No.", ProdOrderRtngLine."Next Operation No.");
                    if ProdOrderRtngLine2.Find('-') then
                        repeat
                            if ProdOrderRtngLine2."Previous Operation No." <> '' then
                                ProdOrderRtngLine2."Previous Operation No." :=
                                  ProdOrderRtngLine2."Previous Operation No." + '|';
                            ProdOrderRtngLine2."Previous Operation No." :=
                              ProdOrderRtngLine2."Previous Operation No." +
                              ProdOrderRtngLine."Operation No.";
                            ProdOrderRtngLine2.Modify();
                        until ProdOrderRtngLine2.Next() = 0;
                end;
            until ProdOrderRtngLine.Next() = 0;
    end;

    local procedure SetRtngLineSequenceBack(RoutingType: Option Serial,Parallel; ProdOrderRtngLine: Record "Prod. Order Routing Line"; Maxsequences: Integer; Actsequences: Integer; TotalCalculation: Boolean)
    var
        ProdOrderRtngLine2: Record "Prod. Order Routing Line";
        SequenceNo: Integer;
    begin
        if RoutingType = RoutingType::Parallel then begin
            if (Actsequences - 1) > Maxsequences then
                ErrorInRouting(
                  ProdOrderRtngLine.Status,
                  ProdOrderRtngLine."Prod. Order No.",
                  ProdOrderRtngLine."Routing No.",
                  Text001,
                  Actsequences,
                  Maxsequences);

            if TotalCalculation then
                ProdOrderRtngLine."Sequence No. (Backward)" := 1
            else
                ProdOrderRtngLine."Sequence No. (Actual)" := 1;

            SetRoutingFilter(
              ProdOrderRtngLine2, ProdOrderRtngLine.Status, ProdOrderRtngLine."Prod. Order No.",
              ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
            if ProdOrderRtngLine."Next Operation No." <> '' then begin
                ProdOrderRtngLine2.SetFilter("Operation No.", ProdOrderRtngLine."Next Operation No.");
                if ProdOrderRtngLine2.Find('-') then
                    repeat
                        if TotalCalculation then begin
                            if (ProdOrderRtngLine2."Sequence No. (Backward)" + 1) > ProdOrderRtngLine."Sequence No. (Backward)" then
                                ProdOrderRtngLine."Sequence No. (Backward)" := ProdOrderRtngLine2."Sequence No. (Backward)" + 1;
                        end else
                            if (ProdOrderRtngLine2."Sequence No. (Actual)" + 1) > ProdOrderRtngLine."Sequence No. (Actual)" then
                                ProdOrderRtngLine."Sequence No. (Actual)" := ProdOrderRtngLine2."Sequence No. (Actual)" + 1;
                    until ProdOrderRtngLine2.Next() = 0;
            end;
            ProdOrderRtngLine.Modify();

            if ProdOrderRtngLine."Previous Operation No." <> '' then begin
                ProdOrderRtngLine2.SetFilter("Operation No.", ProdOrderRtngLine."Previous Operation No.");
                if ProdOrderRtngLine2.Find('-') then
                    repeat
                        SetRtngLineSequenceBack(
                          RoutingType,
                          ProdOrderRtngLine2,
                          Maxsequences,
                          Actsequences + 1,
                          TotalCalculation);
                    until ProdOrderRtngLine2.Next() = 0;
            end;
        end else begin
            SequenceNo := 1;
            ProdOrderRtngLine2 := ProdOrderRtngLine;
            SetRoutingFilter(
              ProdOrderRtngLine2, ProdOrderRtngLine.Status, ProdOrderRtngLine."Prod. Order No.",
              ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
            if ProdOrderRtngLine2.Find() then
                repeat
                    if TotalCalculation then
                        ProdOrderRtngLine2."Sequence No. (Backward)" := SequenceNo
                    else
                        ProdOrderRtngLine2."Sequence No. (Actual)" := SequenceNo;
                    ProdOrderRtngLine2.Modify();
                    SequenceNo := SequenceNo + 1;
                until ProdOrderRtngLine2.Next(-1) = 0;
        end;
    end;

    local procedure SetRtngLineSequenceForward(RoutingType: Option Serial,Parallel; ProdOrderRtngLine: Record "Prod. Order Routing Line"; MaxSequences: Integer; ActSequences: Integer; TotalCalculation: Boolean)
    var
        ProdOrderRtngLine2: Record "Prod. Order Routing Line";
        SequenceNo: Integer;
    begin
        if RoutingType = RoutingType::Parallel then begin
            if ActSequences > MaxSequences then
                ErrorInRouting(
                  ProdOrderRtngLine.Status,
                  ProdOrderRtngLine."Prod. Order No.",
                  ProdOrderRtngLine."Routing No.",
                  Text002,
                  ActSequences,
                  MaxSequences);

            if TotalCalculation then
                ProdOrderRtngLine."Sequence No. (Forward)" := 1
            else
                ProdOrderRtngLine."Sequence No. (Actual)" := 1;

            SetRoutingFilter(
              ProdOrderRtngLine2, ProdOrderRtngLine.Status, ProdOrderRtngLine."Prod. Order No.",
              ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
            if ProdOrderRtngLine."Previous Operation No." <> '' then begin
                ProdOrderRtngLine2.SetFilter("Operation No.", ProdOrderRtngLine."Previous Operation No.");
                if ProdOrderRtngLine2.Find('-') then
                    repeat
                        if TotalCalculation then begin
                            if (ProdOrderRtngLine2."Sequence No. (Forward)" + 1) > ProdOrderRtngLine."Sequence No. (Forward)" then
                                ProdOrderRtngLine."Sequence No. (Forward)" := ProdOrderRtngLine2."Sequence No. (Forward)" + 1;
                        end else
                            if (ProdOrderRtngLine2."Sequence No. (Actual)" + 1) > ProdOrderRtngLine."Sequence No. (Actual)" then
                                ProdOrderRtngLine."Sequence No. (Actual)" :=
                                  ProdOrderRtngLine."Sequence No. (Actual)" + 1;
                    until ProdOrderRtngLine2.Next() = 0;
            end;
            ProdOrderRtngLine.Modify();

            if ProdOrderRtngLine."Next Operation No." <> '' then begin
                ProdOrderRtngLine2.SetFilter("Operation No.", ProdOrderRtngLine."Next Operation No.");
                if ProdOrderRtngLine2.Find('-') then
                    repeat
                        SetRtngLineSequenceForward(
                          RoutingType,
                          ProdOrderRtngLine2,
                          MaxSequences,
                          ActSequences + 1,
                          TotalCalculation);
                    until ProdOrderRtngLine2.Next() = 0;
            end;
        end else begin
            SequenceNo := 1;
            ProdOrderRtngLine2 := ProdOrderRtngLine;
            SetRoutingFilter(
              ProdOrderRtngLine2, ProdOrderRtngLine.Status, ProdOrderRtngLine."Prod. Order No.",
              ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
            if ProdOrderRtngLine2.Find() then
                repeat
                    if TotalCalculation then
                        ProdOrderRtngLine2."Sequence No. (Forward)" := SequenceNo
                    else
                        ProdOrderRtngLine2."Sequence No. (Actual)" := SequenceNo;
                    ProdOrderRtngLine2.Modify();
                    SequenceNo := SequenceNo + 1;
                until ProdOrderRtngLine2.Next() = 0;
        end;
    end;

    local procedure CalcSequenceBack(ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        MaxSeq: Integer;
    begin
        SetRoutingFilter(
          ProdOrderRtngLine, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.",
          ProdOrderLine."Routing No.", ProdOrderLine."Routing Reference No.");

        if ProdOrderRtngLine.Find('-') then
            repeat
                ProdOrderRtngLine."Sequence No. (Backward)" := 0;
                ProdOrderRtngLine."Fixed Scrap Qty. (Accum.)" := 0;
                ProdOrderRtngLine."Scrap Factor % (Accumulated)" := 0;
                ProdOrderRtngLine.Modify();
            until ProdOrderRtngLine.Next() = 0;

        MaxSeq := ProdOrderRtngLine.Count();

        ProdOrderRtngLine.SetFilter("Next Operation No.", '%1', '');
        ProdOrderRtngLine.Find('-');
        SetRtngLineSequenceBack(ProdOrderLine."Routing Type", ProdOrderRtngLine, MaxSeq, 1, true);
    end;

    local procedure CalcSequenceForward(ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        MaxSeq: Integer;
    begin
        SetRoutingFilter(
          ProdOrderRtngLine, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.",
          ProdOrderLine."Routing No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRtngLine.ModifyAll("Sequence No. (Forward)", 0);

        MaxSeq := ProdOrderRtngLine.Count();

        ProdOrderRtngLine.SetFilter("Previous Operation No.", '%1', '');
        ProdOrderRtngLine.FindFirst();
        SetRtngLineSequenceForward(ProdOrderLine."Routing Type", ProdOrderRtngLine, MaxSeq, 1, true);
    end;

    procedure CalcSequenceFromActual(ProdOrderRtngLine: Record "Prod. Order Routing Line"; Direction: Option Forward,Backward)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine2: Record "Prod. Order Routing Line";
        MaxSeq: Integer;
    begin
        if NeedsCalculation(
             ProdOrderRtngLine.Status,
             ProdOrderRtngLine."Prod. Order No.",
             ProdOrderRtngLine."Routing Reference No.",
             ProdOrderRtngLine."Routing No.")
        then begin
            SetOrderLineRoutingFilter(
              ProdOrderLine, ProdOrderRtngLine.Status, ProdOrderRtngLine."Prod. Order No.",
              ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
            ProdOrderLine.FindFirst();

            Calculate(ProdOrderLine);
        end;
        SetRoutingFilter(
          ProdOrderRtngLine2, ProdOrderRtngLine.Status, ProdOrderRtngLine."Prod. Order No.",
          ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
        ProdOrderRtngLine2.ModifyAll("Sequence No. (Actual)", 0);

        MaxSeq := ProdOrderRtngLine2.Count();
        ProdOrderRtngLine.Get(ProdOrderRtngLine.Status, ProdOrderRtngLine."Prod. Order No.", ProdOrderRtngLine."Routing Reference No.", ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Operation No.");

        case Direction of
            Direction::Forward:
                SetRtngLineSequenceForward(ProdOrderLine."Routing Type", ProdOrderRtngLine, MaxSeq, 1, false);
            Direction::Backward:
                SetRtngLineSequenceBack(ProdOrderLine."Routing Type", ProdOrderRtngLine, MaxSeq, 1, false);
        end;
    end;

    procedure Calculate(ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderRtngLine2: Record "Prod. Order Routing Line";
        CalcScrapFactor: Decimal;
        CalcScrapQty: Decimal;
        ScrapFactorThis: Decimal;
        ScrapQtyThis: Decimal;
        IsHandled: Boolean;
    begin
        if ProdOrderLine."Routing Type" = ProdOrderLine."Routing Type"::Serial then
            SetNextOperations(ProdOrderLine);

        CalcPreviousOperations(ProdOrderLine);
        CalcSequenceBack(ProdOrderLine);
        CalcSequenceForward(ProdOrderLine);

        ProdOrderRtngLine.SetCurrentKey(
          Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Sequence No. (Backward)");
        SetRoutingFilter(
          ProdOrderRtngLine, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.",
          ProdOrderLine."Routing No.", ProdOrderLine."Routing Reference No.");

        if ProdOrderRtngLine.Find('-') then
            repeat
                if ProdOrderRtngLine."Next Operation No." <> '' then begin
                    SetRoutingFilter(
                      ProdOrderRtngLine2, ProdOrderRtngLine.Status, ProdOrderRtngLine."Prod. Order No.",
                      ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
                    ProdOrderRtngLine2.SetFilter("Operation No.", ProdOrderRtngLine."Next Operation No.");
                    CalcScrapFactor := 0;
                    CalcScrapQty := 0;
                    if ProdOrderRtngLine2.Find('-') then
                        repeat
                            ScrapFactorThis := ProdOrderRtngLine2."Scrap Factor % (Accumulated)";
                            ScrapQtyThis := ProdOrderRtngLine2."Fixed Scrap Qty. (Accum.)";
                            if CalcScrapFactor < ScrapFactorThis then
                                CalcScrapFactor := ScrapFactorThis;
                            if CalcScrapQty < ScrapQtyThis then
                                CalcScrapQty := ScrapQtyThis;
                        until ProdOrderRtngLine2.Next() = 0;
                end;
                if CalcScrapFactor <> 0 then begin
                    if ProdOrderRtngLine."Scrap Factor %" <> 0 then
                        CalcScrapFactor :=
                          Round(
                            (1 + CalcScrapFactor) *
                            (1 + ProdOrderRtngLine."Scrap Factor %" / 100), 0.00001) - 1;
                end else
                    CalcScrapFactor := Round(1 + ProdOrderRtngLine."Scrap Factor %" / 100, 0.00001) - 1;
                CalcScrapQty := CalcScrapQty * (1 + ProdOrderRtngLine."Scrap Factor %" / 100) + ProdOrderRtngLine."Fixed Scrap Quantity";
                OnCalculateOnAfterCalcScrapQtyAndFactor(ProdOrderRtngLine, CalcScrapQty, CalcScrapFactor);
                ProdOrderRtngLine."Fixed Scrap Qty. (Accum.)" := CalcScrapQty;
                ProdOrderRtngLine."Scrap Factor % (Accumulated)" := CalcScrapFactor;
                ProdOrderRtngLine.Modify();
            until ProdOrderRtngLine.Next() = 0;

        if ProdOrderRtngLine.FindSet(true) then
            repeat
                IsHandled := false;
                OnCalculateOnBeforeProdOrderRtngLineLoopIteration(ProdOrderRtngLine, ProdOrderLine, IsHandled);
                if not IsHandled then begin
                    ProdOrderRtngLine.Recalculate := false;
                    ProdOrderRtngLine.UpdateComponentsBin(1); // modify option                        
                    ProdOrderRtngLine.Modify(false);
                end;
            until ProdOrderRtngLine.Next() = 0;

        CheckProdOrderLine(ProdOrderLine);
    end;

    local procedure CheckProdOrderLine(var ProdOrderLine: Record "Prod. Order Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProdOrderLine(ProdOrderLine, IsHandled);
        if IsHandled then
            exit;

        Check(ProdOrderLine);
    end;

    procedure Check(ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderRtngLine2: Record "Prod. Order Routing Line";
        NoOfProcesses: Integer;
    begin
        SetRoutingFilter(
          ProdOrderRtngLine, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.",
          ProdOrderLine."Routing No.", ProdOrderLine."Routing Reference No.");

        ProdOrderRtngLine.SetFilter("Next Operation No.", '%1', '');

        NoOfProcesses := ProdOrderRtngLine.Count();
        if NoOfProcesses <> 1 then begin
            repeat
                InsertInErrList(ProdOrderRtngLine);
            until ProdOrderRtngLine.Next() = 0;
            Error(
              Text003,
              ProdOrderLine."Prod. Order No.",
              ProdOrderLine."Routing No.",
              NoOfProcesses,
              ErrList);
        end;

        ProdOrderRtngLine.SetFilter("Previous Operation No.", '%1', '');
        ProdOrderRtngLine.SetRange("Next Operation No.");
        NoOfProcesses := ProdOrderRtngLine.Count();
        if NoOfProcesses <> 1 then begin
            repeat
                InsertInErrList(ProdOrderRtngLine);
            until ProdOrderRtngLine.Next() = 0;
            Error(
              Text004,
              ProdOrderLine."Prod. Order No.",
              ProdOrderLine."Routing No.",
              NoOfProcesses,
              ErrList);
        end;
        ProdOrderRtngLine.SetRange("Previous Operation No.");

        ProdOrderRtngLine.SetRange("Sequence No. (Backward)", 0);
        if ProdOrderRtngLine.Find('-') then begin
            repeat
                InsertInErrList(ProdOrderRtngLine);
            until ProdOrderRtngLine.Next() = 0;
            Error(
              Text005,
              ProdOrderRtngLine."Routing No.",
              ErrList);
        end;
        ProdOrderRtngLine.SetRange("Sequence No. (Backward)");

        ProdOrderRtngLine.SetRange("Sequence No. (Forward)", 0);
        if ProdOrderRtngLine.Find('-') then begin
            repeat
                InsertInErrList(ProdOrderRtngLine);
            until ProdOrderRtngLine.Next() = 0;
            Error(
              Text006,
              ProdOrderRtngLine."Routing No.",
              ErrList);
        end;
        ProdOrderRtngLine.SetRange("Sequence No. (Forward)");

        ProdOrderRtngLine.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.",
          "Routing No.", "Sequence No. (Backward)");
        ProdOrderRtngLine.SetFilter("Previous Operation No.", '<>%1', '');

        if ProdOrderRtngLine.Find('-') then
            repeat
                SetRoutingFilter(
                  ProdOrderRtngLine2, ProdOrderRtngLine.Status, ProdOrderRtngLine."Prod. Order No.",
                  ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
                ProdOrderRtngLine2.SetFilter("Operation No.", ProdOrderRtngLine."Previous Operation No.");
                if ProdOrderRtngLine2.IsEmpty() then
                    Error(
                      Text007,
                      ProdOrderRtngLine."Routing No.");
            until ProdOrderRtngLine.Next() = 0;

        ProdOrderRtngLine.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.",
          "Routing No.", "Sequence No. (Forward)");
        ProdOrderRtngLine.SetFilter("Next Operation No.", '<>%1', '');
        ProdOrderRtngLine.SetRange("Operation No.");

        if ProdOrderRtngLine.Find('-') then
            repeat
                SetRoutingFilter(
                  ProdOrderRtngLine2, ProdOrderRtngLine.Status, ProdOrderRtngLine."Prod. Order No.",
                  ProdOrderRtngLine."Routing No.", ProdOrderRtngLine."Routing Reference No.");
                ProdOrderRtngLine2.SetFilter("Operation No.", ProdOrderRtngLine."Next Operation No.");
                if ProdOrderRtngLine2.IsEmpty() then
                    Error(Text008, ProdOrderRtngLine."Routing No.");
            until ProdOrderRtngLine.Next() = 0;
    end;

    procedure UpdateComponentsBin(var FilteredProdOrderRtngLineSet: Record "Prod. Order Routing Line"; IgnoreErrors: Boolean): Boolean
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        BinCode: Code[20];
        AutoUpdateCompBinCode: Boolean;
        ErrorOccured: Boolean;
        SkipUpdate: Boolean;
    begin
        OnBeforeUpdateComponentsBin(FilteredProdOrderRtngLineSet, SkipUpdate, ErrorOccured, AutoUpdateCompBinCode);
        if SkipUpdate then
            exit(not ErrorOccured);

        if not FilteredProdOrderRtngLineSet.FindFirst() then
            exit;
        SetOrderLineRoutingFilter(ProdOrderLine, FilteredProdOrderRtngLineSet.Status, FilteredProdOrderRtngLineSet."Prod. Order No.", FilteredProdOrderRtngLineSet."Routing No.", FilteredProdOrderRtngLineSet."Routing Reference No.");
        if ProdOrderLine.FindSet(false) then
            repeat
                SetProdOrderComponentFilter(ProdOrderComponent, ProdOrderLine, FilteredProdOrderRtngLineSet);
                if ProdOrderComponent.FindSet(true) then
                    repeat
                        if IgnoreErrors then
                            ProdOrderComponent.SetIgnoreErrors();
                        BinCode := ProdOrderComponent.GetDefaultConsumptionBin(FilteredProdOrderRtngLineSet);
                        if BinCode <> ProdOrderComponent."Bin Code" then begin
                            if not AutoUpdateCompBinCode then
                                if Confirm(Text009, false) then
                                    AutoUpdateCompBinCode := true
                                else
                                    exit;
                            ProdOrderComponent.Validate("Bin Code", BinCode);
                            ProdOrderComponent.Modify();
                            if ProdOrderComponent.HasErrorOccured() then
                                ErrorOccured := true;
                        end;
                    until ProdOrderComponent.Next() = 0;
            until ProdOrderLine.Next() = 0;
        exit(not ErrorOccured);
    end;

    local procedure SetProdOrderComponentFilter(var ProdOrderComponent: Record "Prod. Order Component"; var ProdOrderLine: Record "Prod. Order Line"; var FilteredProdOrderRtngLineSet: Record "Prod. Order Routing Line")
    begin
        ProdOrderComponent.SetCurrentKey(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.");
        ProdOrderComponent.SetRange(Status, FilteredProdOrderRtngLineSet.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", FilteredProdOrderRtngLineSet."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComponent.SetRange("Location Code", ProdOrderLine."Location Code");
    end;

    local procedure SetRoutingFilter(var ProdOrderRtngLine: Record "Prod. Order Routing Line"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; RoutingNo: Code[20]; RoutingRefNo: Integer)
    begin
        ProdOrderRtngLine.SetRange(Status, Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRtngLine.SetRange("Routing Reference No.", RoutingRefNo);
        ProdOrderRtngLine.SetRange("Routing No.", RoutingNo);
    end;

    local procedure SetOrderLineRoutingFilter(var ProdOrderLine: Record "Prod. Order Line"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; RoutingNo: Code[20]; RoutingRefNo: Integer)
    begin
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.SetRange("Routing Reference No.", RoutingRefNo);
        ProdOrderLine.SetRange("Routing No.", RoutingNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPreviousOperations(ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetNextOperations(ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateComponentsBin(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var SkipUpdate: Boolean; var ErrorOccured: Boolean; var AutoUpdateCompBinCode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnAfterCalcScrapQtyAndFactor(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ScrapQty: Decimal; var ScrapFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnBeforeProdOrderRtngLineLoopIteration(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNeedsCalculationOnBeforeFindProdOrderRtngLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;
}

