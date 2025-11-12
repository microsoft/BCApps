// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using System.Utilities;

report 5810 "Costing Errors Detection"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Costing/CostingErrorsDetection.rdlc';
    Caption = 'Costing Errors Detection';
    PreviewMode = PrintLayout;
    ApplicationArea = Basic, Suite;

    dataset
    {
        dataitem(ErrorGroup; "Integer")
        {
            DataItemTableView = sorting(Number);

            column(CompanyName; CompanyName())
            {
            }
            column(Today; Format(Today(), 0, 4))
            {
            }
            column(UserID; UserId())
            {
            }
            column(ShowCaption; ShowCaption())
            {
            }
            column(Number_ErrorGroup; Number)
            {
            }
            dataitem(Item; Item)
            {
                PrintOnlyIfDetail = true;
                RequestFilterFields = "No.";

                column(No_Item; "No.")
                {
                }
                column(Description_Item; Description)
                {
                    IncludeCaption = true;
                }
                dataitem(ItemCheck; Item)
                {
                    DataItemLink = "No." = field("No.");
                    DataItemTableView = sorting("No.");

                    dataitem(ItemErrors; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ErrorText_ItemErrors; ErrorText[Number])
                        {
                        }
                        column(Number_ItemErrors; Number)
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, CompressArray(ErrorText));
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        ClearErrorText();

                        case ErrorGroupIndex of
                            0:
                                CheckItem("No.");
                        end;

                        if CompressArray(ErrorText) = 0 then
                            CurrReport.Skip();
                    end;
                }
                dataitem("Item Ledger Entry"; "Item Ledger Entry")
                {
                    DataItemLink = "Item No." = field("No.");
                    DataItemTableView = sorting("Item No.");

                    column(EntryNo_ItemLedgerEntry; "Entry No.")
                    {
                        IncludeCaption = true;
                    }
                    column(EntryType_ItemLedgerEntry; "Entry Type")
                    {
                        IncludeCaption = true;
                    }
                    column(EntryTypeFormat_ItemLedgerEntry; Format("Entry Type"))
                    {
                    }
                    column(ItemNo_ItemLedgerEntry; "Item No.")
                    {
                        IncludeCaption = true;
                    }
                    column(Quantity_ItemLedgerEntry; Quantity)
                    {
                        IncludeCaption = true;
                    }
                    column(RemainingQuantity_ItemLedgerEntry; "Remaining Quantity")
                    {
                        IncludeCaption = true;
                    }
                    column(Positive_ItemLedgerEntry; Positive)
                    {
                        IncludeCaption = true;
                    }
                    column(Open_ItemLedgerEntry; Open)
                    {
                        IncludeCaption = true;
                    }
                    column(PostingDate_ItemLedgerEntry; "Posting Date")
                    {
                        IncludeCaption = true;
                    }
                    dataitem(Errors; "Integer")
                    {
                        DataItemTableView = sorting(Number);

                        column(ErrorText_Errors; ErrorText[Number])
                        {
                        }
                        column(Number_Errors; Number)
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, CompressArray(ErrorText))
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Window.Update(3, "Entry No.");
                        ClearErrorText();

                        case ErrorGroupIndex of
                            0:
                                CheckBasicData();
                            1:
                                CheckItemLedgEntryQty();
                            2:
                                CheckApplicationQty();
                            4:
                                CheckValuedByAverageCost();
                            5:
                                CheckValuationDate();
                            6:
                                CheckRemainingExpectedAmount();
                            7:
                                CheckOutputCompletelyInvdDate();
                        end;

                        if CompressArray(ErrorText) = 0 then
                            CurrReport.Skip();
                    end;

                    trigger OnPreDataItem()
                    begin
                        case ErrorGroupIndex of
                            0: // Basic Data Test
                                ;
                            1: // Qty. Check Item Entry <--> Item Appl. Entry
                                begin
                                    ItemApplEntry.Reset();
                                    ItemApplEntry.SetCurrentKey("Item Ledger Entry No.");
                                end;
                            2: // Application Qty. Check
                                begin
                                    SetRange(Positive, true);
                                    ItemApplEntry.Reset();
                                    ItemApplEntry.SetCurrentKey("Inbound Item Entry No.");
                                end;
                            3: // Check Related Inb. - Outb. Value Entry
                                begin
                                    SetRange(Positive, true);
                                    ItemApplEntry.Reset();
                                    ItemApplEntry.SetCurrentKey("Item Ledger Entry No.");
                                end;
                            4: // Check Valued By Average Cost
                                begin
                                    SetRange(Positive, false);
                                    ItemApplEntry.Reset();
                                    ItemApplEntry.SetCurrentKey("Item Ledger Entry No.");
                                end;
                            5: // Check Valuation Date
                                begin
                                    SetRange(Positive, true);
                                    ItemApplEntry.Reset();
                                    ItemApplEntry.SetCurrentKey("Inbound Item Entry No.");
                                end;
                            6: // Check remaining expected cost on closed item ledger entry
                                begin
                                    ItemApplEntry.Reset();
                                    ItemApplEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
                                end;
                            7: // Check Output Completely Invd. Date' in Table 339
                                ;
                        end;
                    end;
                }
                dataitem("Value Entry"; "Value Entry")
                {
                    DataItemLink = "Item No." = field("No.");
                    DataItemTableView = sorting("Item No.", "Posting Date", "Item Ledger Entry Type", "Entry Type", "Variance Type", "Item Charge No.", "Location Code", "Variant Code");

                    column(EntryNo_ValueEntry; "Entry No.")
                    {
                    }
                    column(ItemNo_ValueEntry; "Item No.")
                    {
                    }
                    column(ItemLedgerEntryType_ValueEntry; "Item Ledger Entry Type")
                    {
                    }
                    column(PostingDate_ValueEntry; "Posting Date")
                    {
                    }
                    column(ItemLedgerEntryQuantity_ValueEntry; "Item Ledger Entry Quantity")
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        ItemLedgEntry: Record "Item Ledger Entry";
                    begin
                        if ItemLedgEntry.Get("Item Ledger Entry No.") then
                            CurrReport.Skip();

                        if Item2.Get("Item No.") then begin
                            TempItem := Item2;
                            if TempItem.Insert() then;
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if (ErrorGroupIndex <> 8) or (Item."No." = '') then
                            CurrReport.Break();

                        if not CheckItemLedgEntryExists then
                            CurrReport.Break();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if Type <> Type::Inventory then
                        CurrReport.Skip();

                    Window.Update(2, "No.");
                end;

                trigger OnPreDataItem()
                begin
                    if ErrorGroupIndex in [3, 4] then begin
                        if CostingMethodFiltered then
                            CurrReport.Break()
                        else
                            SetRange("Costing Method", "Costing Method"::Average);
                    end else
                        SetRange("Costing Method");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ErrorGroupIndex := Number;
                case ErrorGroupIndex of
                    0:
                        if not BasicDataTest then
                            CurrReport.Skip()
                        else
                            Window.Update(1, BasicDataTestLbl);
                    1:
                        if not QtyCheckItemLedgEntry then
                            CurrReport.Skip()
                        else
                            Window.Update(1, ItemLedgEntryItemApplEntryCheckLbl);
                    2:
                        if not ApplicationQtyCheck then
                            CurrReport.Skip()
                        else
                            Window.Update(1, ApplicationQtyCheckLbl);
                    4:
                        if not ValuedByAverageCheck then
                            CurrReport.Skip()
                        else
                            Window.Update(1, CheckValuedByAverageCostLbl);
                    5:
                        if not ValuationDateCheck then
                            CurrReport.Skip()
                        else
                            Window.Update(1, CheckValuationDateLbl);
                    6:
                        if not RemExpectedOnClosedEntry then
                            CurrReport.Skip()
                        else
                            Window.Update(1, CheckExpectedCostOnClosedEntryLbl);
                    7:
                        if not OutputCompletelyInvd then
                            CurrReport.Skip()
                        else
                            Window.Update(1, CheckOutputCompletelyInvdDateLbl);
                    8:
                        if not CheckItemLedgEntryExists then
                            CurrReport.Skip()
                        else
                            Window.Update(1, ValueEntriesWithMissingILELbl);
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 0, 8);
            end;
        }
        dataitem(Summary; "Integer")
        {
            DataItemTableView = sorting(Number);

            column(ItemSummaryCaption; ItemSummaryLbl)
            {
            }
            column(No_Summary; TempItem."No.")
            {
            }
            column(Description_Summary; TempItem.Description)
            {
            }
            column(Number_Summary; Number)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    TempItem.FindFirst()
                else
                    TempItem.Next();
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, TempItem.Count());
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                field("Basic Item Test"; BasicDataTest)
                {
                    Caption = 'Check basic data';
                    ToolTip = 'Specifies if you want to check the correctness of the item ledger entries and the value entries.';
                }
                field("Qty. Check Item Ledger Entry"; QtyCheckItemLedgEntry)
                {
                    Caption = 'Check Item Ledger Entry vs Item Application Entry';
                    ToolTip = 'Specifies if you want to check the correctness of the item application entries.';
                }
                field("Application Qty. Check"; ApplicationQtyCheck)
                {
                    Caption = 'Check Item Application quantity';
                    ToolTip = 'Specifies if you want to check the correctness of the quantity between the item ledger entries and the item application entries.';
                }
                field("Valued by Average Check"; ValuedByAverageCheck)
                {
                    Caption = 'Check Valued By Average Cost';
                    ToolTip = 'Specifies if you want to check the correctness of the valued by average cost field in the value entries.';
                }
                field("Valuation Date Check"; ValuationDateCheck)
                {
                    Caption = 'Check Valuation Date';
                    ToolTip = 'Specifies if you want to check the correctness of the valuation date in the value entries.';
                }
                field("Rem. Expected On Closed Entry"; RemExpectedOnClosedEntry)
                {
                    Caption = 'Check Expected Cost on completely invoiced entries';
                    ToolTip = 'Specifies if you want to check the correctness of the expected cost.';
                }
                field("Check Item Ledg. Entry Exists"; CheckItemLedgEntryExists)
                {
                    Caption = 'Check Value Entries with missing Item Ledger Entry';
                    ToolTip = 'Specifies if you want to check if the item ledger entries exist for the value entries.';
                }
            }
        }
    }

    labels
    {
        ReportName = 'Costing_Errors_Detection';
        PageNoCaption = 'Page';
    }

    trigger OnPostReport()
    begin
        Window.Close();
    end;

    trigger OnPreReport()
    var
        DummyItem: Record Item;
    begin
        if not (BasicDataTest or QtyCheckItemLedgEntry or ApplicationQtyCheck or
                ValuedByAverageCheck or ValuationDateCheck or RemExpectedOnClosedEntry or
                OutputCompletelyInvd or CheckItemLedgEntryExists)
        then
            Error(NoChecksSelectedErr);

        if not "Item Ledger Entry".FindSet() then
            Error(NoItemLedgerEntriesToCheckErr);

        Window.Open(ProgressWindow1Lbl + ProgressWindow2Lbl + ProgressWindow3Lbl);

        DummyItem.SetRange("Costing Method", DummyItem."Costing Method"::Average);
        if Item.GetFilter("Costing Method") <> '' then
            if Item.GetFilter("Costing Method") <> DummyItem.GetFilter("Costing Method") then
                CostingMethodFiltered := true;
    end;

    var
        ItemApplEntry: Record "Item Application Entry";
        Item2: Record Item;
        TempItem: Record Item temporary;
        ErrorText: array[20] of Text;
        ErrorGroupIndex: Integer;
        ErrorIndex: Integer;
        BasicDataTest: Boolean;
        QtyCheckItemLedgEntry: Boolean;
        ApplicationQtyCheck: Boolean;
        ValuedByAverageCheck: Boolean;
        ValuationDateCheck: Boolean;
        RemExpectedOnClosedEntry: Boolean;
        OutputCompletelyInvd: Boolean;
        CheckItemLedgEntryExists: Boolean;
        CostingMethodFiltered: Boolean;
        Window: Dialog;
        ProgressWindow1Lbl: Label 'Function          #1##########################\', Comment = '%1: Function name';
        ProgressWindow2Lbl: Label 'Item              #2##########################\', Comment = '%1: Item No.';
        ProgressWindow3Lbl: Label 'Item Ledger Entry #3##########################', Comment = '%1: Entry No.';
        ItemSummaryLbl: Label 'Item Summary';
        BasicDataTestLbl: Label 'Check basic data';
        ItemLedgEntryItemApplEntryCheckLbl: Label 'Check Item Ledger Entry vs Item Application Entry';
        ApplicationQtyCheckLbl: Label 'Check Item Application quantity';
        CheckValuationDateLbl: Label 'Check Valuation Date';
        CheckValuedByAverageCostLbl: Label 'Check Valued By Average Cost';
        ValueEntriesWithMissingILELbl: Label 'Check Value Entries with missing Item Ledger Entry';
        CheckExpectedCostForInvoicedLbl: Label 'Check Expected Cost on completely invoiced entries';
        CheckCompletelyInvoicedDateLbl: Label 'Check Completely Invoiced date';
        CheckExpectedCostOnClosedEntryLbl: Label 'Check Expected Cost on a closed entry';
        CheckOutputCompletelyInvdDateLbl: Label 'Check output Completely Invoiced date';
        NoChecksSelectedErr: Label 'You must select one or more of the data checks.';
        NoItemLedgerEntriesToCheckErr: Label 'There are no Item Ledger Entries to check.';
        WrongValueEntryFieldValueErr: Label 'The value of the Valued by Average Cost field in the corresponding Value Entries is not correct.';
        ItemLedgerEntryQtyZeroErr: Label 'The quantity must not be 0 on Item Ledger Entry.';
        ItemLedgerEntryFieldValueErr: Label '%1 must be %2.', Comment = '%1, %2: Field values in Item Ledger Entry table';
        ValueEntryFieldValueErr: Label 'The linked Value Entries do not all have the same value of %1.', Comment = '%1: Field value in Value Entry table';
        NoValueEntryForILEErr: Label 'There are no Value Entries for this Item Ledger Entry.';
        NoItemApplEntryForILEErr: Label 'There are no Item Application Entries for this Item Ledger Entry.';
        BlankLastInvoicedDateErr: Label 'Blank Last Invoice Date on an Item Ledger Entry which has been invoiced.';
        ItemApplEntryExistsForNotAppliedILEErr: Label 'An Item Application Entry exists even though the Quantity and Remaining Quantity are the same in this negative Item Ledger Entry.';
        DuplicatedItemApplEntryErr: Label 'There is more than one Item Application Entry with the same combination of Item Ledger Entry No., Inbound Item Entry No., and Outbound Item Entry No.';
        RemQtyGreaterThanQtyErr: Label 'The Remaining Quantity is greater than the Quantity.';
        ItemApplEntryQtyNotMatchQtyMinusRemQtyErr: Label 'The summed Quantity of the linked Item Application Entries is not the same as the difference between Quantity and Remaining Quantity on Item Ledger Entry.';
        ItemApplEntryQtyNotMatchQtyErr: Label 'The summed Quantity of the linked Item Application Entries is not the same as the Quantity on Item Ledger Entry.';
        ItemApplEntryWrongSignErr: Label 'The sign of the Quantity in one or more of the linked Item Application Entries must be the opposite (positive must be negative or negative must be positive).';
        ItemApplEntryQtyNotMatchRemQtyErr: Label 'The summed Quantity of the linked Item Application Entries is different than the Remaining Quantity of the Item Ledger Entry.';
        EarlierValuationDateErr: Label 'The Valuation Date in Value Entries applied to this Item Ledger Entry is earlier than the Valuation Date in the Valuation Date for this Item Ledger Entry.';
        CostApplicationFieldValueErr: Label 'The value of the Cost Application field in the corresponding Item Application Entries is not correct.';
        WrongValuationDateForConsumptionErr: Label 'A linked Value Entry should not have the Valuation Date %1 for a positive entry with Entry Type = Consumption.', Comment = '%1: Valuation Date';
        ValuedByAvgCostForNonAvgEntryErr: Label 'Valued by Average Cost of Value Entries must not be Yes for any Costing Method other than Average.';
        PostingDateAndOutputComplInvdDateNotMatchErr: Label 'Posting Date is different to Output Completely Invd. Date on a linked Item Application Entry.';
        OutputCompletelyInvdDateMustBeBlankErr: Label 'Output Completely Invd. Date is specified on a linked Item Application Entry but the Item Ledger Entry is not completely invoiced.';
        OutputCompletelyInvdDateNotEqualToLastInvDateErr: Label 'Output Completely Invd. Date is not equal to Last Invoice Date on a linked Item Application Entry.';
        InvoicedQuantityDoNotMatchErr: Label 'The summed Invoiced Quantity of the linked Value Entries is not the same as the Invoiced Quantity on the Item Ledger Entry.';
        ExpectedCostPostedToGLNotZeroErr: Label 'Expected Cost Posted to G/L is not 0 on a linked Value Entry. However this could be because the report ''Post Inventory Cost to G/L'' has not been run yet.';
        InvoicedQuantityMustBeZeroErr: Label 'Invoiced Quantity must be 0 when Adjustment is true on Value Entry.';
        CostAmountExpectedNotZeroErr: Label 'Cost Amount (Expected) is not 0 on a completely invoiced Item Ledger Entry.';
        InvoicedQtyMustBeEqualToQtyForComplInvdErr: Label 'Invoiced Quantity must be equal to Quantity when Completely Invoiced is true.';
        QuantityMustBeZeroWhenAdjmtTrueErr: Label 'Quantity must be 0 on Item Ledger Entry %1 when Adjustment is true on a Value Entry.', Comment = '%1: Entry No.';
        ValuedByAverageCostMustBeFalseErr: Label 'Valued by Average Cost must be false when Valued Quantity > 0 and Costing Method is %1 on Value Entry %2.', Comment = '%1: Costing Method on Item, %2: Entry No. on Value Entry';
        ItemLedgerEntryTypeNotMatchEntryTypeErr: Label 'Item Ledger Entry Type on a Value Entry is not equal to Entry Type on Item Ledger Entry %1.', Comment = '%1: Entry No. on Item Ledger Entry';
        NegativeEntryNoOnILEErr: Label 'Entry No. on Item Ledger Entry must not be less or equal than zero.';
        ItemNoBlankErr: Label 'Item No. must not be blank.';

    local procedure ShowCaption(): Text
    begin
        case ErrorGroupIndex of
            0:
                exit(BasicDataTestLbl);
            1:
                exit(ItemLedgEntryItemApplEntryCheckLbl);
            2:
                exit(ApplicationQtyCheckLbl);
            4:
                exit(CheckValuedByAverageCostLbl);
            5:
                exit(CheckValuationDateLbl);
            6:
                exit(CheckExpectedCostForInvoicedLbl);
            7:
                exit(CheckCompletelyInvoicedDateLbl);
            8:
                exit(ValueEntriesWithMissingILELbl);
        end;
    end;

    local procedure ClearErrorText()
    begin
        if CompressArray(ErrorText) <> 0 then
            for ErrorIndex := 1 to CompressArray(ErrorText) do
                ErrorText[ErrorIndex] := '';
        ErrorIndex := 1;
    end;

    local procedure CheckBasicData()
    begin
        BasicCheckItemLedgEntry();
        BasicCheckValueEntry();
    end;

    local procedure BasicCheckItemLedgEntry()
    var
        ValueEntry: Record "Value Entry";
    begin
        if "Item Ledger Entry"."Entry No." <= 0 then
            AddError(NegativeEntryNoOnILEErr, "Item Ledger Entry"."Item No.");

        if "Item Ledger Entry".Quantity = 0 then
            AddError(ItemLedgerEntryQtyZeroErr, "Item Ledger Entry"."Item No.");
        if ("Item Ledger Entry".Quantity * "Item Ledger Entry"."Remaining Quantity") < 0 then
            AddError(RemQtyGreaterThanQtyErr, "Item Ledger Entry"."Item No.");
        if Abs("Item Ledger Entry"."Remaining Quantity") > Abs("Item Ledger Entry".Quantity) then
            AddError(RemQtyGreaterThanQtyErr, "Item Ledger Entry"."Item No.");
        if ("Item Ledger Entry".Quantity > 0) <> "Item Ledger Entry".Positive then
            AddError(StrSubstNo(ItemLedgerEntryFieldValueErr, "Item Ledger Entry".FieldCaption(Positive), not "Item Ledger Entry".Positive), "Item Ledger Entry"."Item No.");
        if ("Item Ledger Entry"."Remaining Quantity" = 0) = "Item Ledger Entry".Open then
            AddError(StrSubstNo(ItemLedgerEntryFieldValueErr, "Item Ledger Entry".FieldCaption(Open), not "Item Ledger Entry".Open), "Item Ledger Entry"."Item No.");

        if "Item Ledger Entry"."Completely Invoiced" then begin
            if "Item Ledger Entry"."Invoiced Quantity" <> "Item Ledger Entry".Quantity then
                AddError(InvoicedQtyMustBeEqualToQtyForComplInvdErr, "Item Ledger Entry"."Item No.");

            ValueEntry.SetCurrentKey("Item Ledger Entry No.");
            ValueEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
            ValueEntry.CalcSums("Invoiced Quantity");
            if "Item Ledger Entry"."Invoiced Quantity" <> ValueEntry."Invoiced Quantity" then
                AddError(InvoicedQuantityDoNotMatchErr, "Item Ledger Entry"."Item No.");
        end;
    end;

    local procedure BasicCheckValueEntry()
    var
        ValueEntry: Record "Value Entry";
        ValuationDate: Date;
        ConsumptionDate: Date;
        ValuedByAverageCost: Boolean;
        Continue: Boolean;
        Compare: Boolean;
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
        ValueEntry.SetRange(Inventoriable, true);
        if not ValueEntry.FindSet() then
            AddError(NoValueEntryForILEErr, "Item Ledger Entry"."Item No.")
        else begin
            ValuedByAverageCost := ValueEntry."Valued By Average Cost";
            repeat
                if ValueEntry.Adjustment then begin
                    if ValueEntry."Invoiced Quantity" <> 0 then begin
                        AddError(InvoicedQuantityMustBeZeroErr, "Item Ledger Entry"."Item No.");
                        Continue := true;
                    end;
                    if ValueEntry."Item Ledger Entry Quantity" <> 0 then
                        AddError(StrSubstNo(QuantityMustBeZeroWhenAdjmtTrueErr, "Item Ledger Entry"."Entry No."), "Item Ledger Entry"."Item No.");
                end;

                if ("Item Ledger Entry"."Entry Type" = "Item Ledger Entry"."Entry Type"::Consumption) and "Item Ledger Entry".Positive and
                   (ValueEntry."Valuation Date" = DMY2Date(31, 12, 9999))
                then begin
                    ConsumptionDate := DMY2Date(31, 12, 9999);
                    AddError(StrSubstNo(WrongValuationDateForConsumptionErr, ConsumptionDate), "Item Ledger Entry"."Item No.");
                    Continue := true;
                end else begin
                    if (not Compare) and (ValueEntry."Valuation Date" <> 0D) and
                       not (ValueEntry."Entry Type" in [ValueEntry."Entry Type"::Rounding, ValueEntry."Entry Type"::Revaluation])
                    then begin
                        ValuationDate := ValueEntry."Valuation Date";
                        Compare := true;
                    end;
                    if Compare then
                        if (ValueEntry."Valuation Date" <> ValuationDate) and (ValueEntry."Valuation Date" <> 0D) and
                           not (ValueEntry."Entry Type" in [ValueEntry."Entry Type"::Rounding, ValueEntry."Entry Type"::Revaluation])
                        then begin
                            AddError(StrSubstNo(ValueEntryFieldValueErr, ValueEntry.FieldCaption("Valuation Date")), "Item Ledger Entry"."Item No.");
                            Continue := true;
                        end;
                end;

                if (ValueEntry."Valued By Average Cost") and
                   (Item."Costing Method" <> Item."Costing Method"::Average)
                then begin
                    AddError(ValuedByAvgCostForNonAvgEntryErr, "Item Ledger Entry"."Item No.");
                    Continue := true;
                end else
                    if ValueEntry."Valued By Average Cost" <> ValuedByAverageCost then begin
                        AddError(StrSubstNo(ValueEntryFieldValueErr, ValueEntry.FieldCaption("Valued By Average Cost")), "Item Ledger Entry"."Item No.");
                        Continue := true;
                    end;

                if (ValueEntry."Valued By Average Cost") and
                   (Item."Costing Method" = Item."Costing Method"::Average) and
                   (not "Item Ledger Entry".Correction)
                 then
                    if ValueEntry."Valued Quantity" > 0 then
                        AddError(StrSubstNo(ValuedByAverageCostMustBeFalseErr, Format(Item."Costing Method"), ValueEntry."Entry No."), "Item Ledger Entry"."Item No.");

                if ValueEntry."Item Charge No." = '' then
                    if ValueEntry."Item Ledger Entry Type" <> "Item Ledger Entry"."Entry Type" then
                        AddError(StrSubstNo(ItemLedgerEntryTypeNotMatchEntryTypeErr, "Item Ledger Entry"."Entry No."), "Item Ledger Entry"."Item No.");
            until (ValueEntry.Next() = 0) or Continue;
        end;
    end;

    local procedure CheckItemLedgEntryQty()
    begin
        if (not "Item Ledger Entry".Positive) and "Item Ledger Entry".Open then
            CheckNegOpenILEQty()
        else
            CheckILEQty();
        SearchInbOutbCombination();
    end;

    local procedure CheckNegOpenILEQty()
    var
        ApplQty: Decimal;
    begin
        if "Item Ledger Entry".Quantity = "Item Ledger Entry"."Remaining Quantity" then begin
            ItemApplEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
            if not ItemApplEntry.IsEmpty() then
                AddError(ItemApplEntryExistsForNotAppliedILEErr, "Item Ledger Entry"."Item No.");
        end else begin
            ItemApplEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
            if not ItemApplEntry.IsEmpty() then begin
                ItemApplEntry.CalcSums(Quantity);
                ApplQty := ItemApplEntry.Quantity;
                if ApplQty <> ("Item Ledger Entry".Quantity - "Item Ledger Entry"."Remaining Quantity") then
                    AddError(ItemApplEntryQtyNotMatchQtyMinusRemQtyErr, "Item Ledger Entry"."Item No.");
            end;
        end;
    end;

    local procedure CheckILEQty()
    var
        ApplQty: Decimal;
    begin
        ItemApplEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
        if not ItemApplEntry.IsEmpty() then begin
            ItemApplEntry.CalcSums(Quantity);
            ApplQty := ItemApplEntry.Quantity;
            if ApplQty <> "Item Ledger Entry".Quantity then
                AddError(ItemApplEntryQtyNotMatchQtyErr, "Item Ledger Entry"."Item No.");
        end else
            AddError(NoItemApplEntryForILEErr, "Item Ledger Entry"."Item No.");
    end;

    local procedure SearchInbOutbCombination()
    var
        ItemApplEntry2: Record "Item Application Entry";
        Continue: Boolean;
    begin
        if ItemApplEntry.FindSet() then
            repeat
                ItemApplEntry2.SetCurrentKey(
                  "Item Ledger Entry No.", "Inbound Item Entry No.", "Outbound Item Entry No.");
                ItemApplEntry2.SetRange("Item Ledger Entry No.", ItemApplEntry."Item Ledger Entry No.");
                ItemApplEntry2.SetRange("Inbound Item Entry No.", ItemApplEntry."Inbound Item Entry No.");
                ItemApplEntry2.SetRange("Outbound Item Entry No.", ItemApplEntry."Outbound Item Entry No.");
                ItemApplEntry2.SetFilter("Entry No.", '<>%1', ItemApplEntry."Entry No.");
                if not ItemApplEntry2.IsEmpty() then begin
                    AddError(DuplicatedItemApplEntryErr, "Item Ledger Entry"."Item No.");
                    Continue := true;
                end;
            until (ItemApplEntry.Next() = 0) or Continue;
    end;

    local procedure CheckApplicationQty()
    var
        ApplQty: Decimal;
        Continue: Boolean;
    begin
        ItemApplEntry.SetRange("Inbound Item Entry No.", "Item Ledger Entry"."Entry No.");
        if ItemApplEntry.FindSet() then begin
            repeat
                if ((ItemApplEntry."Item Ledger Entry No." = ItemApplEntry."Inbound Item Entry No.") and
                    (ItemApplEntry.Quantity < 0)) or
                   ((ItemApplEntry."Item Ledger Entry No." <> ItemApplEntry."Inbound Item Entry No.") and
                    (ItemApplEntry.Quantity > 0)) or
                   ((ItemApplEntry."Item Ledger Entry No." <> ItemApplEntry."Outbound Item Entry No.") and
                    (ItemApplEntry.Quantity < 0))
                then begin
                    AddError(ItemApplEntryWrongSignErr, "Item Ledger Entry"."Item No.");
                    Continue := true;
                end;
            until Continue or (ItemApplEntry.Next() = 0);

            ItemApplEntry.CalcSums(Quantity);
            ApplQty := ItemApplEntry.Quantity;
            if ApplQty <> "Item Ledger Entry"."Remaining Quantity" then
                AddError(ItemApplEntryQtyNotMatchRemQtyErr, "Item Ledger Entry"."Item No.");
        end;
    end;

    local procedure CheckValuedByAverageCost()
    begin
        CheckVEValuedBySetting();
        CheckItemApplCostApplSetting();
    end;

    local procedure CheckVEValuedBySetting()
    var
        ValueEntry: Record "Value Entry";
        ValueEntry2: Record "Value Entry";
        Continue: Boolean;
    begin
        ValueEntry2.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry2.SetRange(Inventoriable, true);
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
        ValueEntry.SetRange(Inventoriable, true);
        ValueEntry.SetFilter("Item Ledger Entry Type", '<>%1', ValueEntry."Item Ledger Entry Type"::Output);
        if ValueEntry.FindSet() then
            repeat
                if "Item Ledger Entry"."Applies-to Entry" <> 0 then begin
                    ValueEntry2.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Applies-to Entry");
                    if ValueEntry2.FindFirst() then
                        if ValueEntry."Valued By Average Cost" <> ValueEntry2."Valued By Average Cost" then begin
                            AddError(WrongValueEntryFieldValueErr, "Item Ledger Entry"."Item No.");
                            Continue := true;
                        end;
                end else
                    if (not ValueEntry."Valued By Average Cost") and
                       (ValueEntry."Valuation Date" <> 0D) and
                       ("Item Ledger Entry"."Entry Type" <> "Item Ledger Entry"."Entry Type"::Transfer) and
                       ("Item Ledger Entry".Quantity < 0)
                    then begin
                        AddError(WrongValueEntryFieldValueErr, "Item Ledger Entry"."Item No.");
                        Continue := true;
                    end;
            until (ValueEntry.Next() = 0) or Continue;
    end;

    local procedure CheckItemApplCostApplSetting()
    var
        Continue: Boolean;
    begin
        ItemApplEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
        if ItemApplEntry.FindSet() then
            repeat
                if ItemApplEntry.Quantity > 0 then begin
                    if not ItemApplEntry."Cost Application" then begin
                        AddError(CostApplicationFieldValueErr, "Item Ledger Entry"."Item No.");
                        Continue := true;
                    end;
                end else
                    if "Item Ledger Entry"."Applies-to Entry" <> 0 then begin
                        if not ItemApplEntry."Cost Application" then begin
                            AddError(CostApplicationFieldValueErr, "Item Ledger Entry"."Item No.");
                            Continue := true;
                        end;
                    end else
                        if ItemApplEntry."Cost Application" and ("Item Ledger Entry"."Entry Type" <> "Item Ledger Entry"."Entry Type"::Transfer) then begin
                            AddError(CostApplicationFieldValueErr, "Item Ledger Entry"."Item No.");
                            Continue := true;
                        end;
            until (ItemApplEntry.Next() = 0) or Continue;
    end;

    local procedure CheckValuationDate()
    var
        ValueEntry: Record "Value Entry";
        ValuationDate: Date;
        Continue: Boolean;
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
        ValueEntry.SetRange(Inventoriable, true);
        ValueEntry.SetRange("Partial Revaluation", false);
        if ValueEntry.FindFirst() then begin
            ValuationDate := ValueEntry."Valuation Date";
            ItemApplEntry.SetRange("Inbound Item Entry No.", "Item Ledger Entry"."Entry No.");
            if ItemApplEntry.FindSet() then
                repeat
                    if ItemApplEntry.Quantity < 0 then begin
                        ValueEntry.SetRange("Item Ledger Entry No.", ItemApplEntry."Item Ledger Entry No.");
                        ValueEntry.SetFilter("Valuation Date", '<%1', ValuationDate);
                        if not ValueEntry.IsEmpty() then begin
                            AddError(EarlierValuationDateErr, "Item Ledger Entry"."Item No.");
                            Continue := true;
                        end;
                    end;
                until (ItemApplEntry.Next() = 0) or Continue;
        end;
    end;

    local procedure CheckRemainingExpectedAmount()
    var
        ValueEntry: Record "Value Entry";
    begin
        if not "Item Ledger Entry"."Completely Invoiced" then
            exit;

        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");

        "Item Ledger Entry".CalcFields("Cost Amount (Expected)", "Cost Amount (Expected) (ACY)");
        if ("Item Ledger Entry"."Cost Amount (Expected)" = 0) and
           ("Item Ledger Entry"."Cost Amount (Expected) (ACY)" = 0)
        then begin
            ValueEntry.CalcSums("Expected Cost Posted to G/L", "Exp. Cost Posted to G/L (ACY)");
            if (ValueEntry."Expected Cost Posted to G/L" = 0) and (ValueEntry."Exp. Cost Posted to G/L (ACY)" = 0) then
                exit;
        end;

        if ValueEntry.FindSet() then
            repeat
                if (ValueEntry."Expected Cost Posted to G/L" <> 0) or (ValueEntry."Exp. Cost Posted to G/L (ACY)" <> 0) then
                    AddError(ExpectedCostPostedToGLNotZeroErr, ValueEntry."Item No.");
            until ValueEntry.Next() = 0;

        if ErrorIndex > 0 then
            AddError(CostAmountExpectedNotZeroErr, "Item Ledger Entry"."Item No.");
    end;

    local procedure CheckOutputCompletelyInvdDate()
    var
        ItemApplicationEntry: Record "Item Application Entry";
        ZeroDateFound: Boolean;
    begin
        if "Item Ledger Entry"."Invoiced Quantity" <> 0 then
            if "Item Ledger Entry"."Last Invoice Date" = 0D then
                AddError(BlankLastInvoicedDateErr, "Item Ledger Entry"."Item No.");

        ItemApplicationEntry.SetCurrentKey("Item Ledger Entry No.", "Output Completely Invd. Date");
        ItemApplicationEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
        if ItemApplicationEntry.FindSet() then
            repeat
                if ItemApplicationEntry.Quantity > 0 then begin
                    if ItemApplicationEntry."Output Completely Invd. Date" <> ItemApplicationEntry."Posting Date" then begin
                        ZeroDateFound := true;
                        AddError(PostingDateAndOutputComplInvdDateNotMatchErr, "Item Ledger Entry"."Item No.");
                    end;
                end else
                    if "Item Ledger Entry".Quantity = "Item Ledger Entry"."Invoiced Quantity" then begin
                        if ItemApplicationEntry."Output Completely Invd. Date" <> "Item Ledger Entry"."Last Invoice Date" then begin
                            ZeroDateFound := true;
                            AddError(OutputCompletelyInvdDateNotEqualToLastInvDateErr, "Item Ledger Entry"."Item No.");
                        end;
                    end else
                        if ItemApplicationEntry."Output Completely Invd. Date" <> 0D then begin
                            ZeroDateFound := true;
                            AddError(OutputCompletelyInvdDateMustBeBlankErr, "Item Ledger Entry"."Item No.");

                        end;
            until ZeroDateFound or (ItemApplicationEntry.Next() = 0);
    end;

    local procedure CheckItem(ItemNo: Code[20])
    begin
        if ItemNo = '' then
            AddError(ItemNoBlankErr, ItemNo);
    end;

    local procedure AddError(ErrorMessage: Text; ItemNo: Code[20])
    begin
        ErrorText[ErrorIndex] := ErrorMessage;
        ErrorIndex := ErrorIndex + 1;

        if Item2.Get(ItemNo) then begin
            TempItem := Item2;
            if TempItem.Insert() then;
        end;
    end;
}

