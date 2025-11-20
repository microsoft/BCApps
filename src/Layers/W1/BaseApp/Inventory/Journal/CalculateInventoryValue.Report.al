// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Utilities;
using System.Utilities;

report 5899 "Calculate Inventory Value"
{
    Caption = 'Calculate Inventory Value';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.") where(Type = const(Inventory));
            RequestFilterFields = "No.", "Costing Method", "Location Filter", "Variant Filter";

            trigger OnAfterGetRecord()
            var
                ItemLedgerEntry: Record "Item Ledger Entry";
                SkipItem: Boolean;
                IncludeExpectedCost: Boolean;
                RemCost: Decimal;
            begin
                if ShowDialog then
                    Window.Update();

                SkipItem := false;
                OnBeforeOnAfterGetRecord(Item, SkipItem);
                if SkipItem then
                    CurrReport.Skip();

                if (CalculatePer = CalculatePer::Item) and ("Costing Method" = "Costing Method"::Average) then begin
                    CalendarPeriod."Period Start" := PostingDate;
                    AvgCostEntryPointHandler.GetValuationPeriod(CalendarPeriod, PostingDate);
                    if PostingDate <> CalendarPeriod."Period End" then
                        Error(Text011, "No.", PostingDate, CalendarPeriod."Period End");
                end;

                TempValJnlBuffer.Reset();
                TempValJnlBuffer.DeleteAll();
                IncludeExpectedCost := ("Costing Method" = "Costing Method"::Standard) and (CalculatePer = CalculatePer::Item);
                ItemLedgerEntry.SetCurrentKey("Item No.", Positive, "Location Code", "Variant Code");
                ItemLedgerEntry.SetRange("Item No.", "No.");
                ItemLedgerEntry.SetRange(Positive, true);
                CopyFilter("Location Filter", ItemLedgerEntry."Location Code");
                CopyFilter("Variant Filter", ItemLedgerEntry."Variant Code");
                OnItemAfterGetRecordOnAfterItemLedgEntrySetFilters(ItemLedgerEntry, Item);
                if ItemLedgerEntry.FindSet() then
                    repeat
                        if IncludeEntryInCalc(ItemLedgerEntry, PostingDate, IncludeExpectedCost) then begin
                            RemQty := ItemLedgerEntry.CalculateRemQuantity(ItemLedgerEntry."Entry No.", PostingDate);
                            RemCost := CalcRemainingCost(ItemLedgerEntry, RemQty, IncludeExpectedCost);
                            case CalculatePer of
                                CalculatePer::"Item Ledger Entry":
                                    begin
                                        OnAfterGetRecordItemOnBeforInsertItemJnlLine(ItemLedgerEntry, ItemJnlLine);
                                        InsertItemJnlLine(
                                          ItemLedgerEntry."Entry Type", ItemLedgerEntry."Item No.",
                                          ItemLedgerEntry."Variant Code", ItemLedgerEntry."Location Code", RemQty, RemCost, ItemLedgerEntry."Entry No.", 0, ItemLedgerEntry."Dimension Set ID");
                                    end;
                                CalculatePer::Item:
                                    InsertValJnlBuffer(
                                      ItemLedgerEntry."Item No.", ItemLedgerEntry."Variant Code", ItemLedgerEntry."Location Code", RemQty, RemCost);
                            end;
                        end;
                    until ItemLedgerEntry.Next() = 0;

                if CalculatePer = CalculatePer::Item then
                    if (GetFilter("Location Filter") <> '') or ByLocation then begin
                        ByLocation2 := true;
                        CopyFilter("Location Filter", Location.Code);
                        if Location.FindSet() then begin
                            Clear(TempValJnlBuffer);
                            TempValJnlBuffer.SetCurrentKey("Item No.", "Location Code", "Variant Code");
                            TempValJnlBuffer.SetRange("Item No.", "No.");
                            repeat
                                TempValJnlBuffer.SetRange("Location Code", Location.Code);
                                if (GetFilter("Variant Filter") <> '') or ByVariant then begin
                                    ByVariant2 := true;
                                    ItemVariant.SetRange("Item No.", "No.");
                                    CopyFilter("Variant Filter", ItemVariant.Code);
                                    if ItemVariant.FindSet() then
                                        repeat
                                            TempValJnlBuffer.SetRange("Variant Code", ItemVariant.Code);
                                            Calculate(Item, ItemVariant.Code, Location.Code);
                                        until ItemVariant.Next() = 0;
                                    TempValJnlBuffer.SetRange("Variant Code", '');
                                    Calculate(Item, '', Location.Code);
                                end else
                                    Calculate(Item, '', Location.Code);
                            until Location.Next() = 0;
                        end;
                        TempValJnlBuffer.SetRange("Location Code", '');
                        if ByVariant then begin
                            ItemVariant.SetRange("Item No.", "No.");
                            CopyFilter("Variant Filter", ItemVariant.Code);
                            if ItemVariant.FindSet() then
                                repeat
                                    TempValJnlBuffer.SetRange("Variant Code", ItemVariant.Code);
                                    Calculate(Item, ItemVariant.Code, '');
                                until ItemVariant.Next() = 0;
                            TempValJnlBuffer.SetRange("Variant Code", '');
                            Calculate(Item, '', '');
                        end else
                            Calculate(Item, '', '');
                    end else
                        if (GetFilter("Variant Filter") <> '') or ByVariant then begin
                            ByVariant2 := true;
                            ItemVariant.SetRange("Item No.", "No.");
                            CopyFilter("Variant Filter", ItemVariant.Code);
                            if ItemVariant.FindSet() then begin
                                TempValJnlBuffer.Reset();
                                TempValJnlBuffer.SetCurrentKey("Item No.", "Variant Code");
                                TempValJnlBuffer.SetRange("Item No.", "No.");
                                repeat
                                    TempValJnlBuffer.SetRange("Variant Code", ItemVariant.Code);
                                    Calculate(Item, ItemVariant.Code, '');
                                until ItemVariant.Next() = 0;
                            end;
                            TempValJnlBuffer.SetRange("Location Code");
                            TempValJnlBuffer.SetRange("Variant Code", '');
                            Calculate(Item, '', '');
                        end else begin
                            TempValJnlBuffer.Reset();
                            TempValJnlBuffer.SetCurrentKey("Item No.");
                            TempValJnlBuffer.SetRange("Item No.", "No.");
                            Calculate(Item, '', '');
                        end;
            end;

            trigger OnPostDataItem()
            var
                StockkeepingUnit: Record "Stockkeeping Unit";
                ItemCostManagement: Codeunit ItemCostManagement;
                IsHandled: Boolean;
            begin
                if not UpdStdCost then
                    exit;

                if ByLocation then
                    CopyFilter("Location Filter", StockkeepingUnit."Location Code");
                if ByVariant then
                    CopyFilter("Variant Filter", StockkeepingUnit."Variant Code");

                TempNewStdCostItem.CopyFilters(Item);
                if TempNewStdCostItem.FindSet() then
                    repeat
                        if not TempUpdatedStdCostSKU.Get('', TempNewStdCostItem."No.", '') then
                            ItemCostManagement.UpdateStdCostShares(TempNewStdCostItem);

                        StockkeepingUnit.SetRange("Item No.", TempNewStdCostItem."No.");
                        if StockkeepingUnit.FindSet() then
                            repeat
                                if not TempUpdatedStdCostSKU.Get(StockkeepingUnit."Location Code", TempNewStdCostItem."No.", StockkeepingUnit."Variant Code") then begin
                                    IsHandled := false;
                                    OnPostDataItemForItemOnBeforeValidateStandardCost(TempNewStdCostItem, StockkeepingUnit, IsHandled);
                                    if not IsHandled then
                                        StockkeepingUnit.Validate("Standard Cost", TempNewStdCostItem."Standard Cost");
                                    StockkeepingUnit.Modify();
                                end;
                            until StockkeepingUnit.Next() = 0;
                    until TempNewStdCostItem.Next() = 0;
            end;

            trigger OnPreDataItem()
            var
                TempErrorBuf: Record "Error Buffer" temporary;
            begin
                ItemJnlTemplate.Get(ItemJnlLine."Journal Template Name");
                ItemJnlTemplate.TestField(Type, ItemJnlTemplate.Type::Revaluation);

                ItemJnlBatch.Get(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
                if NextDocNo = '' then begin
                    if ItemJnlBatch."No. Series" <> '' then begin
                        ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
                        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
                        if not ItemJnlLine.FindFirst() then
                            NextDocNo := NoSeriesBatch.GetNextNo(ItemJnlBatch."No. Series", PostingDate);
                        ItemJnlLine.Init();
                    end;
                    if NextDocNo = '' then
                        Error(Text003);
                end;

                CalcInvtValCheck.SetParameters(PostingDate, CalculatePer, ByLocation, ByVariant, ShowDialog, false);
                CalcInvtValCheck.RunCheck(Item, TempErrorBuf);

                NextLineNo := 0;

                if ShowDialog then
                    Window.Open(Text010, "No.");

                GLSetup.Get();
                SourceCodeSetup.Get();

                case CalcBase of
                    CalcBase::"Standard Cost - Assembly List":
                        begin
                            CalculateAssemblyCost.SetProperties(PostingDate, true, false, '', true);
                            CalculateAssemblyCost.CalcItems(Item, TempNewStdCostItem);
                            Clear(CalculateAssemblyCost);
                        end;
                end;

                OnAfterOnPreDataItem(Item, CalcBase, PostingDate, TempNewStdCostItem);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date for the posting of this batch job. By default, the working date is entered, but you can change it.';
                    }
                    field(NextDocNo; NextDocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the document that is processed by the report or batch job.';
                    }
                    field(CalculatePer; CalculatePer)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calculate Per';
                        ToolTip = 'Specifies if you want to sum up the inventory value per item ledger entry or per item.';

                        trigger OnValidate()
                        begin
                            if CalculatePer = CalculatePer::Item then
                                ItemCalculatePerOnValidate();
                            if CalculatePer = CalculatePer::"Item Ledger Entry" then
                                ItemLedgerEntryCalculatePerOnV();
                        end;
                    }
                    field("By Location"; ByLocation)
                    {
                        ApplicationArea = Location;
                        Caption = 'By Location';
                        Enabled = ByLocationEnable;
                        ToolTip = 'Specifies whether to calculate inventory by location.';
                    }
                    field("By Variant"; ByVariant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'By Variant';
                        Enabled = ByVariantEnable;
                        ToolTip = 'Specifies the item variants that you want the batch job to consider.';
                    }
                    field(UpdStdCost; UpdStdCost)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Update Standard Cost';
                        Enabled = UpdStdCostEnable;
                        ToolTip = 'Specifies if you want the items'' standard cost to be updated according to the calculated inventory value. This option is available only if Item is chosen in the Calculate Per field.';
                    }
                    field(CalcBase; CalcBase)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calculation Base';
                        Enabled = CalcBaseEnable;
                        ToolTip = 'Specifies if the revaluation journal will suggest a new value for the Unit Cost (Revalued) field.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            UpdStdCostEnable := true;
            CalcBaseEnable := true;
            ByVariantEnable := true;
            ByLocationEnable := true;
        end;

        trigger OnOpenPage()
        begin
            if PostingDate = 0D then
                PostingDate := WorkDate();
            ValidatePostingDate();

            ValidateCalcLevel();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        OnBeforePreReport();
    end;

    var
        TempNewStdCostItem: Record Item temporary;
        TempUpdatedStdCostSKU: Record "Stockkeeping Unit" temporary;
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        TempValJnlBuffer: Record "Item Journal Buffer" temporary;
        ItemJnlTemplate: Record "Item Journal Template";
        GLSetup: Record "General Ledger Setup";
        SourceCodeSetup: Record "Source Code Setup";
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        CalendarPeriod: Record Date;
        CalcInvtValCheck: Codeunit "Calc. Inventory Value-Check";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        CalculateAssemblyCost: Codeunit Microsoft.Assembly.Costing."Calculate Assembly Cost";
        AvgCostEntryPointHandler: Codeunit "Avg. Cost Entry Point Handler";
        Window: Dialog;
        CalculatePer: Enum "Inventory Value Calc. Per";
        CalcBase: Enum "Inventory Value Calc. Base";
        NextDocNo: Code[20];
        AverageUnitCostLCY: Decimal;
        RemQty: Decimal;
        NextLineNo: Integer;
        NextLineNo2: Integer;
        ByLocation: Boolean;
        ByVariant: Boolean;
        UpdStdCost: Boolean;
        ShowDialog: Boolean;
        ByLocationEnable: Boolean;
        ByVariantEnable: Boolean;
        CalcBaseEnable: Boolean;
        UpdStdCostEnable: Boolean;
        DuplWarningQst: Label 'Duplicate Revaluation Journals will be generated.\Do you want to continue?';
        HideDuplWarning: Boolean;

#pragma warning disable AA0074
        Text003: Label 'You must enter a document number.';
#pragma warning disable AA0470
        Text010: Label 'Processing items #1##########';
        Text011: Label 'You cannot revalue by Calculate Per Item for item %1 using posting date %2. You can only use the posting date %3 for this period.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        ByLocation2: Boolean;
        ByVariant2: Boolean;
        PostingDate: Date;

    local procedure IncludeEntryInCalc(ItemLedgerEntry: Record "Item Ledger Entry"; PostingDate: Date; IncludeExpectedCost: Boolean)Result: Boolean
    var
        IsHandled: Boolean;        
    begin
        IsHandled := false;
        OnBeforeIncludeEntryInCalc(ItemLedgerEntry, PostingDate, IncludeExpectedCost, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if IncludeExpectedCost then
            exit(ItemLedgerEntry."Posting Date" in [0D .. PostingDate]);
        exit(ItemLedgerEntry."Completely Invoiced" and (ItemLedgerEntry."Last Invoice Date" in [0D .. PostingDate]));
    end;

    procedure SetItemJnlLine(var NewItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine := NewItemJnlLine;
    end;

    local procedure ValidatePostingDate()
    var
        NoSeries: Codeunit "No. Series";
    begin
        ItemJnlBatch.Get(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
        if ItemJnlBatch."No. Series" = '' then
            NextDocNo := ''
        else
            NextDocNo := NoSeries.PeekNextNo(ItemJnlBatch."No. Series", PostingDate);
    end;

    local procedure ValidateCalcLevel()
    begin
        PageValidateCalcLevel();
        exit;
    end;

    local procedure InsertValJnlBuffer(ItemNo2: Code[20]; VariantCode2: Code[10]; LocationCode2: Code[10]; Quantity2: Decimal; Amount2: Decimal)
    begin
        TempValJnlBuffer.Reset();
        TempValJnlBuffer.SetCurrentKey("Item No.", "Location Code", "Variant Code");
        TempValJnlBuffer.SetRange("Item No.", ItemNo2);
        TempValJnlBuffer.SetRange("Location Code", LocationCode2);
        TempValJnlBuffer.SetRange("Variant Code", VariantCode2);
        if TempValJnlBuffer.FindFirst() then begin
            TempValJnlBuffer.Quantity := TempValJnlBuffer.Quantity + Quantity2;
            TempValJnlBuffer."Inventory Value (Calculated)" :=
              TempValJnlBuffer."Inventory Value (Calculated)" + Amount2;
            TempValJnlBuffer.Modify();
        end else
            if Quantity2 <> 0 then begin
                NextLineNo2 := NextLineNo2 + 10000;
                TempValJnlBuffer.Init();
                TempValJnlBuffer."Line No." := NextLineNo2;
                TempValJnlBuffer."Item No." := ItemNo2;
                TempValJnlBuffer."Variant Code" := VariantCode2;
                TempValJnlBuffer."Location Code" := LocationCode2;
                TempValJnlBuffer.Quantity := Quantity2;
                TempValJnlBuffer."Inventory Value (Calculated)" := Amount2;
                TempValJnlBuffer.Insert();
            end;
    end;

    local procedure CalcAverageUnitCost(BufferQty: Decimal; var InvtValueCalc: Decimal; var AppliedAmount: Decimal)
    var
        ValueEntry: Record "Value Entry";
        AverageQty: Decimal;
        AverageCost: Decimal;
        NotComplInvQty: Decimal;
        NotComplInvValue: Decimal;
        IsHandled: Boolean;
    begin
        ValueEntry."Item No." := Item."No.";
        ValueEntry."Valuation Date" := PostingDate;
        if TempValJnlBuffer.GetFilter("Location Code") <> '' then
            ValueEntry."Location Code" := TempValJnlBuffer.GetRangeMin("Location Code");
        if TempValJnlBuffer.GetFilter("Variant Code") <> '' then
            ValueEntry."Variant Code" := TempValJnlBuffer.GetRangeMin("Variant Code");
        ValueEntry.SumCostsTillValuationDate(ValueEntry);
        AverageQty := ValueEntry."Invoiced Quantity";
        AverageCost := ValueEntry."Cost Amount (Actual)";

        CalcNotComplInvcdTransfer(NotComplInvQty, NotComplInvValue);
        AverageQty -= NotComplInvQty;
        AverageCost -= NotComplInvValue;

        ValueEntry.Reset();
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Valuation Date", 0D, PostingDate);
        ValueEntry.SetFilter("Location Code", TempValJnlBuffer.GetFilter("Location Code"));
        ValueEntry.SetFilter("Variant Code", TempValJnlBuffer.GetFilter("Variant Code"));
        ValueEntry.SetRange(Inventoriable, true);
        ValueEntry.SetRange("Item Charge No.", '');
        ValueEntry.SetFilter("Posting Date", '>%1', PostingDate);
        ValueEntry.SetFilter("Entry Type", '<>%1', ValueEntry."Entry Type"::Revaluation);
        ValueEntry.CalcSums("Invoiced Quantity", "Cost Amount (Actual)");
        AverageQty -= ValueEntry."Invoiced Quantity";
        AverageCost -= ValueEntry."Cost Amount (Actual)";

        if AverageQty <> 0 then begin
            AverageUnitCostLCY := AverageCost / AverageQty;
            IsHandled := false;
            OnCalcAverageUnitCostOnBeforeCheckNegCost(Item, AverageUnitCostLCY, IsHandled);
            if not IsHandled then
                if AverageUnitCostLCY < 0 then
                    AverageUnitCostLCY := 0;
        end else
            AverageUnitCostLCY := 0;

        AppliedAmount := InvtValueCalc;
        InvtValueCalc := BufferQty * AverageUnitCostLCY;
    end;

    local procedure CalcNotComplInvcdTransfer(var NotComplInvQty: Decimal; var NotComplInvValue: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        RemQty: Decimal;
        RemInvValue: Decimal;
        i: Integer;
    begin
        for i := 1 to 2 do begin
            ItemLedgerEntry.SetCurrentKey("Item No.", Positive, "Location Code", "Variant Code");
            ItemLedgerEntry.SetRange("Item No.", Item."No.");
            ItemLedgerEntry.SetRange(Positive, i = 1);
            ItemLedgerEntry.SetFilter("Location Code", TempValJnlBuffer.GetFilter("Location Code"));
            ItemLedgerEntry.SetFilter("Variant Code", TempValJnlBuffer.GetFilter("Variant Code"));
            if ItemLedgerEntry.FindSet() then
                repeat
                    if (ItemLedgerEntry.Quantity = ItemLedgerEntry."Invoiced Quantity") and
                       not ItemLedgerEntry."Completely Invoiced" and
                       (ItemLedgerEntry."Last Invoice Date" in [0D .. PostingDate]) and
                       (ItemLedgerEntry."Invoiced Quantity" <> 0)
                    then begin
                        RemQty := ItemLedgerEntry.Quantity;
                        RemInvValue := ItemLedgerEntry.CalculateRemInventoryValue(ItemLedgerEntry."Entry No.", ItemLedgerEntry.Quantity, ItemLedgerEntry.Quantity, false, 0D, PostingDate);
                        NotComplInvQty := NotComplInvQty + RemQty;
                        NotComplInvValue := NotComplInvValue + RemInvValue;
                    end;
                until ItemLedgerEntry.Next() = 0;
        end;
    end;

    local procedure InsertItemJnlLine(EntryType2: Enum "Item Ledger Entry Type"; ItemNo2: Code[20]; VariantCode2: Code[10]; LocationCode2: Code[10]; Quantity2: Decimal; Amount2: Decimal; ApplyToEntry2: Integer; AppliedAmount: Decimal; DimensionSetID: Integer)
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        if Quantity2 = 0 then
            exit;

        if not HideDuplWarning then
            if ItemJnlLineExists(ItemJnlLine, ItemNo2, VariantCode2, LocationCode2, ApplyToEntry2) then
                if Confirm(DuplWarningQst) then
                    HideDuplWarning := true
                else
                    Error('');

        InitItemJnlLine(ItemJnlLine, EntryType2, ItemNo2, VariantCode2, LocationCode2);

        ItemJnlLine.Validate("Unit Amount", 0);
        if ApplyToEntry2 <> 0 then
            ItemJnlLine."Inventory Value Per" := ItemJnlLine."Inventory Value Per"::" "
        else
            if ByLocation2 and ByVariant2 then
                ItemJnlLine."Inventory Value Per" := ItemJnlLine."Inventory Value Per"::"Location and Variant"
            else
                if ByLocation2 then
                    ItemJnlLine."Inventory Value Per" := ItemJnlLine."Inventory Value Per"::Location
                else
                    if ByVariant2 then
                        ItemJnlLine."Inventory Value Per" := ItemJnlLine."Inventory Value Per"::Variant
                    else
                        ItemJnlLine."Inventory Value Per" := ItemJnlLine."Inventory Value Per"::Item;
        if CalculatePer = CalculatePer::"Item Ledger Entry" then begin
            ItemJnlLine."Applies-to Entry" := ApplyToEntry2;
            ItemJnlLine.CopyDim(DimensionSetID);
        end;
        ItemJnlLine.Validate(Quantity, Quantity2);
        ItemJnlLine.Validate("Inventory Value (Calculated)", Round(Amount2, GLSetup."Amount Rounding Precision"));
        case CalcBase of
            CalcBase::" ":
                ItemJnlLine.Validate("Inventory Value (Revalued)", ItemJnlLine."Inventory Value (Calculated)");
            CalcBase::"Last Direct Unit Cost":
                if StockkeepingUnit.Get(ItemJnlLine."Location Code", ItemJnlLine."Item No.", ItemJnlLine."Variant Code") then
                    ItemJnlLine.Validate("Unit Cost (Revalued)", StockkeepingUnit."Last Direct Cost")
                else begin
                    Item.Get(ItemJnlLine."Item No.");
                    ItemJnlLine.Validate("Unit Cost (Revalued)", Item."Last Direct Cost");
                end;
            CalcBase::"Standard Cost - Assembly List",
            CalcBase::"Standard Cost - Manufacturing":
                if TempNewStdCostItem.Get(ItemNo2) then begin
                    ItemJnlLine.Validate("Unit Cost (Revalued)", TempNewStdCostItem."Standard Cost");
                    ItemJnlLine."Single-Level Material Cost" := TempNewStdCostItem."Single-Level Material Cost";
                    ItemJnlLine."Single-Level Capacity Cost" := TempNewStdCostItem."Single-Level Capacity Cost";
                    ItemJnlLine."Single-Level Subcontrd. Cost" := TempNewStdCostItem."Single-Level Subcontrd. Cost";
                    ItemJnlLine."Single-Level Cap. Ovhd Cost" := TempNewStdCostItem."Single-Level Cap. Ovhd Cost";
                    ItemJnlLine."Single-Level Mfg. Ovhd Cost" := TempNewStdCostItem."Single-Level Mfg. Ovhd Cost";
                    ItemJnlLine."Rolled-up Material Cost" := TempNewStdCostItem."Rolled-up Material Cost";
                    ItemJnlLine."Rolled-up Capacity Cost" := TempNewStdCostItem."Rolled-up Capacity Cost";
                    ItemJnlLine."Rolled-up Subcontracted Cost" := TempNewStdCostItem."Rolled-up Subcontracted Cost";
                    ItemJnlLine."Rolled-up Mfg. Ovhd Cost" := TempNewStdCostItem."Rolled-up Mfg. Ovhd Cost";
                    ItemJnlLine."Rolled-up Cap. Overhead Cost" := TempNewStdCostItem."Rolled-up Cap. Overhead Cost";
                    OnInsertItemJnlLineOnCaseCalcBaseOnStandardCostAssemblyOrManufacturing(ItemJnlLine, TempNewStdCostItem);
                    TempUpdatedStdCostSKU."Item No." := ItemNo2;
                    TempUpdatedStdCostSKU."Location Code" := LocationCode2;
                    TempUpdatedStdCostSKU."Variant Code" := VariantCode2;
                    if TempUpdatedStdCostSKU.Insert() then;
                end else
                    ItemJnlLine.Validate("Inventory Value (Revalued)", ItemJnlLine."Inventory Value (Calculated)");
            else
                OnInsertItemJnlLineOnCaseCalcBaseOnElse(ItemJnlLine, EntryType2, ItemNo2, VariantCode2, LocationCode2, Quantity2, Amount2, ApplyToEntry2, AppliedAmount, CalcBase, ByLocation2, ByVariant2, PostingDate);
        end;
        ItemJnlLine."Update Standard Cost" := UpdStdCost;
        ItemJnlLine."Partial Revaluation" := true;
        ItemJnlLine."Applied Amount" := AppliedAmount;
        ItemJnlLine.Insert();
        OnAfterInsertItemJnlLine(ItemJnlLine, EntryType2, ItemNo2, VariantCode2, LocationCode2, Quantity2, Amount2, ApplyToEntry2, AppliedAmount, CalcBase);
    end;

    local procedure InitItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; EntryType2: Enum "Item Ledger Entry Type"; ItemNo2: Code[20]; VariantCode2: Code[10]; LocationCode2: Code[10])
    begin
        if NextLineNo = 0 then begin
            ItemJournalLine.LockTable();
            ItemJournalLine.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
            ItemJournalLine.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
            if ItemJournalLine.FindLast() then
                NextLineNo := ItemJournalLine."Line No.";
        end;

        NextLineNo := NextLineNo + 10000;
        ItemJournalLine.Init();
        ItemJournalLine."Line No." := NextLineNo;
        ItemJournalLine."Value Entry Type" := ItemJournalLine."Value Entry Type"::Revaluation;

        OnInitItemJnlLineOnBeforeValidateFields(ItemJournalLine);

        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Validate("Entry Type", EntryType2);
        ItemJournalLine.Validate("Document No.", NextDocNo);
        ItemJournalLine.Validate("Item No.", ItemNo2);
        ItemJournalLine."Reason Code" := ItemJnlBatch."Reason Code";
        ItemJournalLine."Variant Code" := VariantCode2;
        ItemJournalLine.Validate("Location Code", LocationCode2);
        ItemJournalLine."Source Code" := SourceCodeSetup."Revaluation Journal";

        OnAfterInitItemJnlLine(ItemJournalLine, ItemJnlBatch);
    end;


    procedure SetParameters(NewPostingDate: Date; NewDocNo: Code[20]; NewHideDuplWarning: Boolean; NewCalculatePer: Enum "Inventory Value Calc. Per"; NewByLocation: Boolean; NewByVariant: Boolean; NewUpdStdCost: Boolean; NewCalcBase: Enum "Inventory Value Calc. Base"; NewShowDialog: Boolean)
    begin
        PostingDate := NewPostingDate;
        NextDocNo := NewDocNo;
        CalculatePer := NewCalculatePer;
        ByLocation := NewByLocation;
        ByVariant := NewByVariant;
        UpdStdCost := NewUpdStdCost;
        CalcBase := NewCalcBase;
        ShowDialog := NewShowDialog;
        HideDuplWarning := NewHideDuplWarning;
    end;

    local procedure PageValidateCalcLevel()
    begin
        UpdStdCostEnable := true;
        if CalculatePer = CalculatePer::"Item Ledger Entry" then begin
            ByLocation := false;
            ByVariant := false;
            CalcBase := CalcBase::" ";
            UpdStdCost := false;
            UpdStdCostEnable := false;
        end;
    end;

    local procedure ItemLedgerEntryCalculatePerOnV()
    begin
        ValidateCalcLevel();
    end;

    local procedure ItemCalculatePerOnValidate()
    begin
        ValidateCalcLevel();
    end;

    local procedure ItemJnlLineExists(ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; ApplyToEntry: Integer): Boolean
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.SetRange("Variant Code", VariantCode);
        ItemJournalLine.SetRange("Location Code", LocationCode);
        ItemJournalLine.SetRange("Applies-to Entry", ApplyToEntry);
        exit(not ItemJournalLine.IsEmpty());
    end;

    local procedure CalcRemainingCost(ItemLedgerEntry: Record "Item Ledger Entry"; RemainingQty: Decimal; IncludeExpCost: Boolean): Decimal
    var
        UntilValuationDate: Date;
        UntilPostingDate: Date;
    begin
        if ItemLedgerEntry."Entry Type" in [ItemLedgerEntry."Entry Type"::Output, ItemLedgerEntry."Entry Type"::"Assembly Output"] then
            UntilPostingDate := PostingDate
        else
            UntilValuationDate := PostingDate;

        case CalculatePer of
            CalculatePer::"Item Ledger Entry":
                exit(
                  ItemLedgerEntry.CalculateRemInventoryValue(
                    ItemLedgerEntry."Entry No.", ItemLedgerEntry.Quantity, RemainingQty, false, UntilValuationDate, UntilPostingDate));
            CalculatePer::Item:
                exit(
                  ItemLedgerEntry.CalculateRemInventoryValue(
                    ItemLedgerEntry."Entry No.", ItemLedgerEntry.Quantity, RemainingQty,
                    IncludeExpCost and not ItemLedgerEntry."Completely Invoiced", UntilValuationDate, UntilPostingDate));
        end;

        exit(0);
    end;

    local procedure Calculate(Item: Record Item; VariantCode: Code[10]; LocationCode: Code[10])
    var
        AppliedAmount: Decimal;
    begin
        TempValJnlBuffer.CalcSums(Quantity, "Inventory Value (Calculated)");
        if TempValJnlBuffer.Quantity <> 0 then begin
            AppliedAmount := 0;
            if Item."Costing Method" = Item."Costing Method"::Average then
                CalcAverageUnitCost(
                  TempValJnlBuffer.Quantity, TempValJnlBuffer."Inventory Value (Calculated)", AppliedAmount);
            InsertItemJnlLine(
                ItemJnlLine."Entry Type"::"Positive Adjmt.",
                Item."No.", VariantCode, LocationCode, TempValJnlBuffer.Quantity, TempValJnlBuffer."Inventory Value (Calculated)",
                0, AppliedAmount, 0);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ItemJnlBatch: Record "Item Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; EntryType2: Enum "Item Ledger Entry Type"; ItemNo2: Code[20]; VariantCode2: Code[10]; LocationCode2: Code[10]; Quantity2: Decimal; Amount2: Decimal; ApplyToEntry2: Integer; AppliedAmount: Decimal; CalcBase: Enum "Inventory Value Calc. Base")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnPreDataItem(var Item: Record Item; CalcBase: Enum "Inventory Value Calc. Base"; PostingDate: Date; var TempNewStdCostItem: Record Item temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnAfterGetRecord(var Item: Record Item; var SkipItem: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitItemJnlLineOnBeforeValidateFields(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemAfterGetRecordOnAfterItemLedgEntrySetFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemJnlLineOnCaseCalcBaseOnElse(var ItemJournalLine: Record "Item Journal Line"; EntryType2: Enum "Item Ledger Entry Type"; ItemNo2: Code[20]; VariantCode2: Code[10]; LocationCode2: Code[10]; Quantity2: Decimal; Amount2: Decimal; ApplyToEntry2: Integer; AppliedAmount: Decimal; CalcBase: Enum "Inventory Value Calc. Base"; ByLocation2: Boolean; ByVariant2: Boolean; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordItemOnBeforInsertItemJnlLine(ItemLedgerEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDataItemForItemOnBeforeValidateStandardCost(var TempNewStdCostItem: Record Item temporary; var StockkeepingUnit: Record "Stockkeeping Unit"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemJnlLineOnCaseCalcBaseOnStandardCostAssemblyOrManufacturing(var ItemJournalLine: Record "Item Journal Line"; var TempNewStdCostItem: Record Item temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAverageUnitCostOnBeforeCheckNegCost(var Item: Record Item; var AverageUnitCostLCY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIncludeEntryInCalc(var ItemLedgerEntry: Record "Item Ledger Entry"; var PostingDate: Date; var IncludeExpectedCost: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}
