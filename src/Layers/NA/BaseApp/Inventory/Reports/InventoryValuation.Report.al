// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using System.Utilities;

report 10139 "Inventory Valuation"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/InventoryValuation.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Valuation';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = where(Type = const(Inventory));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Inventory Posting Group", "Costing Method", "Location Filter", "Variant Filter";

            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(STRSUBSTNO_Text003_AsOfDate_; StrSubstNo(EndDatePrefixLbl, EndDate))
            {
            }
            column(ShowVariants; ShowVariants)
            {
            }
            column(ShowLocations; ShowLocations)
            {
            }
            column(ShowACY; ShowACY)
            {
            }
            column(STRSUBSTNO_Text006_Currency_Description_; StrSubstNo(CurrencyCodePrefixLbl, Currency.Description))
            {
            }
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption() + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(STRSUBSTNO_Text004_InvPostingGroup_TABLECAPTION_InvPostingGroup_Code_InvPostingGroup_Description_; StrSubstNo(InvoicePostingGroupLbl, InvPostingGroup.TableCaption(), InvPostingGroup.Code, InvPostingGroup.Description))
            {
            }
            column(Item__Inventory_Posting_Group_; "Inventory Posting Group")
            {
            }
            column(Grouping; Grouping)
            {
            }
            column(Item__No__; "No.")
            {
                IncludeCaption = true;
            }
            column(Item_Description; Description)
            {
                IncludeCaption = true;
            }
            column(Item__Base_Unit_of_Measure_; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            column(Item__Costing_Method_; "Costing Method")
            {
                IncludeCaption = true;
            }
            column(STRSUBSTNO_Text005_InvPostingGroup_TABLECAPTION_InvPostingGroup_Code_InvPostingGroup_Description_; StrSubstNo(InvoicePostingGroupTotalLbl, InvPostingGroup.TableCaption(), InvPostingGroup.Code, InvPostingGroup.Description))
            {
            }
            column(Inventory_ValuationCaption; Inventory_ValuationCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(InventoryValue_Control34Caption; InventoryValue_Control34CaptionLbl)
            {
            }
            column(Item_Ledger_Entry__Remaining_Quantity_Caption; "Item Ledger Entry".FieldCaption("Remaining Quantity"))
            {
            }
            column(UnitCost_Control33Caption; UnitCost_Control33CaptionLbl)
            {
            }
            column(Total_Inventory_ValueCaption; Total_Inventory_ValueCaptionLbl)
            {
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Location Code" = field("Location Filter"), "Variant Code" = field("Variant Filter");
                DataItemTableView = sorting("Item No.", "Variant Code", "Location Code", "Posting Date");

                trigger OnAfterGetRecord()
                begin
                    AdjustItemLedgEntryToAsOfDate("Item Ledger Entry");
                    UpdateBuffer("Item Ledger Entry");
                    CurrReport.Skip();
                end;

                trigger OnPostDataItem()
                begin
                    UpdateTempEntryBuffer();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Posting Date", 0D, EndDate);
                end;
            }
            dataitem(BufferLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(RowLabel; TempEntryBuffer.Label)
                {
                }
                column(RemainingQty; TempEntryBuffer."Remaining Quantity")
                {
                }
                column(InventoryValue; TempEntryBuffer.Value1)
                {
                }
                column(VariantCode; TempEntryBuffer."Variant Code")
                {
                }
                column(LocationCode; TempEntryBuffer."Location Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if TempEntryBuffer.Next() <> 1 then
                        CurrReport.Break();
                end;

                trigger OnPreDataItem()
                begin
                    Clear(TempEntryBuffer);
                    TempEntryBuffer.SetFilter("Item No.", '%1', Item."No.");
                    if Item."Location Filter" <> '' then
                        TempEntryBuffer.SetFilter("Location Code", '%1', Item."Location Filter");

                    if Item."Variant Filter" <> '' then
                        TempEntryBuffer.SetFilter("Variant Code", '%1', Item."Variant Filter");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not InvPostingGroup.Get("Inventory Posting Group") then
                    Clear(InvPostingGroup);
                TempEntryBuffer.Reset();
                TempEntryBuffer.DeleteAll();
                Progress.Update(1, Format("No."));
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Date Filter", 0D, EndDate);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory Valuation';
        AboutText = 'Reconcile your inventory subledger to the inventory account(s) in the general ledger at the end of each period. Include Expected Costs and Apply Location Filters to ensure that the Ending Date Value, Cost Posted to G/L and the Balance in the related Inventory or Inventory (Interim) Account are all in balance.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AsOfDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'As Of Date';
                        ToolTip = 'Specifies the valuation date.';
                        ShowMandatory = true;
                    }
                    field(BreakdownByVariants; ShowVariants)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Breakdown by Variants';
                        ToolTip = 'Specifies the item variants that you want the report to consider.';
                    }
                    field(BreakdownByLocation; ShowLocations)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Breakdown by Location';
                        ToolTip = 'Specifies the breakdown report data by locations.';
                    }
                    field(UseAdditionalReportingCurrency; ShowACY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Additional Reporting Currency';
                        ToolTip = 'Specifies if you want all amounts to be printed by using the additional reporting currency. If you do not select the check box, then all amounts will be printed in US dollars.';
                    }
                }
            }
        }
        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Progress.Close();
    end;

    trigger OnPreReport()
    begin
        Grouping := (Item.FieldCaption("Inventory Posting Group") = Item.CurrentKey);

        if EndDate = 0D then
            Error(EndDateErr);

        if ShowLocations and (not ShowVariants) then
            if not "Item Ledger Entry".SetCurrentKey("Item No.", "Location Code") then
                Error(ShowLocationAndVariantsErr, "Item Ledger Entry".TableCaption(), "Item Ledger Entry".FieldCaption("Item No."), "Item Ledger Entry".FieldCaption("Location Code"));

        if Item.GetFilter("Date Filter") <> '' then
            Error(EndDateFilterErr, Item.FieldCaption("Date Filter"), Item.TableCaption());

        CompanyInformation.Get();
        ItemFilter := Item.GetFilters();
        GLSetup.Get();

        Currency.SetLoadFields(Description, "Amount Rounding Precision", "Unit-Amount Rounding Precision");

        if GLSetup."Additional Reporting Currency" = '' then
            ShowACY := false
        else begin
            Currency.Get(GLSetup."Additional Reporting Currency");
            Currency.TestField("Amount Rounding Precision");
            Currency.TestField("Unit-Amount Rounding Precision");
        end;

        Progress.Open(Item.TableCaption() + '  #1############');
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInformation: Record "Company Information";
        InvPostingGroup: Record "Inventory Posting Group";
        Currency: Record Currency;
        TempEntryBuffer: Record "Item Location Variant Buffer" temporary;
        ItemFilter: Text;
        ShowVariants: Boolean;
        ShowLocations: Boolean;
        ShowACY: Boolean;
        LastItemNo: Code[20];
        LastLocationCode: Code[10];
        LastVariantCode: Code[10];
        VariantLabel: Text[250];
        LocationLabel: Text[250];
        IsCollecting: Boolean;
        Progress: Dialog;
        Grouping: Boolean;
        EndDateErr: Label 'You must enter an As Of Date.';
        ShowLocationAndVariantsErr: Label 'If you want to show Locations without also showing Variants, you must add a new key to the %1 table which starts with the %2 and %3 fields.', Comment = '%1 = Item Ledger Entry table Caption; %2 = Item No. field Caption; %3 = Location Code field Caption';
        EndDateFilterErr: Label 'Do not set a %1 on the %2.  Use the As Of Date on the Option tab instead.', Comment = '%1 = Date Filter field Caption; %2 = Item table Caption';
        EndDatePrefixLbl: Label 'Quantities and Values As Of %1', Comment = '%1 = As Of Date prefix';
        InvoicePostingGroupLbl: Label '%1 %2 (%3)', Comment = '%1 = Invoice Posting Group table Caption; %2 = Invoice Posting Group''s Code; %3 = Invoice Posting Group''s Description';
        InvoicePostingGroupTotalLbl: Label '%1 %2 (%3) Total', Comment = '%1 = Invoice Posting Group table Caption; %2 = Invoice Posting Group''s Code; %3 = Invoice Posting Group''s Description';
        CurrencyCodePrefixLbl: Label 'All Inventory Values are shown in %1.', Comment = '%1 = Curreny Code';
        NoVariantLbl: Label 'No Variant';
        NoLocationLbl: Label 'No Location';
        Inventory_ValuationCaptionLbl: Label 'Inventory Valuation';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        InventoryValue_Control34CaptionLbl: Label 'Inventory Value';
        UnitCost_Control33CaptionLbl: Label 'Unit Cost';
        Total_Inventory_ValueCaptionLbl: Label 'Total Inventory Value';

    protected var
        EndDate: Date;

    local procedure AdjustItemLedgEntryToAsOfDate(var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemApplicationEntry: Record "Item Application Entry";
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry2: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry."Remaining Quantity" := ItemLedgerEntry.Quantity;

        ItemLedgerEntry2.SetLoadFields("Posting Date");
        ItemApplicationEntry.SetLoadFields("Posting Date", "Outbound Item Entry No.", "Inbound Item Entry No.", "Item Ledger Entry No.", Quantity, "Cost Application", "Transferred-from Entry No.");

        if ItemLedgerEntry.Positive then begin
            ItemApplicationEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.", "Cost Application");
            ItemApplicationEntry.SetRange("Inbound Item Entry No.", ItemLedgerEntry."Entry No.");
            ItemApplicationEntry.SetRange("Posting Date", 0D, EndDate);
            ItemApplicationEntry.SetFilter("Outbound Item Entry No.", '<>%1', 0);
            ItemApplicationEntry.SetFilter("Item Ledger Entry No.", '<>%1', ItemLedgerEntry."Entry No.");
            ItemApplicationEntry.CalcSums(Quantity);
            ItemLedgerEntry."Remaining Quantity" += ItemApplicationEntry.Quantity;
        end else begin
            ItemApplicationEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application", "Transferred-from Entry No.");
            ItemApplicationEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
            ItemApplicationEntry.SetRange("Outbound Item Entry No.", ItemLedgerEntry."Entry No.");
            ItemApplicationEntry.SetRange("Posting Date", 0D, EndDate);
            if ItemApplicationEntry.Find('-') then
                repeat
                    if ItemLedgerEntry2.Get(ItemApplicationEntry."Inbound Item Entry No.") and (ItemLedgerEntry2."Posting Date" <= EndDate) then
                        ItemLedgerEntry."Remaining Quantity" := ItemLedgerEntry."Remaining Quantity" - ItemApplicationEntry.Quantity;
                until ItemApplicationEntry.Next() = 0;
        end;

        // calculate adjusted cost of entry
        ValueEntry.SetLoadFields("Item Ledger Entry No.", "Posting Date", "Cost Amount (Expected)", "Cost Amount (Actual)", "Cost Amount (Expected) (ACY)", "Cost Amount (Actual) (ACY)");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.SetRange("Posting Date", 0D, EndDate);

        if ShowACY then begin
            ValueEntry.CalcSums("Cost Amount (Actual) (ACY)", "Cost Amount (Expected) (ACY)");
            ItemLedgerEntry."Cost Amount (Actual) (ACY)" := Round(ValueEntry."Cost Amount (Actual) (ACY)" + ValueEntry."Cost Amount (Expected) (ACY)", Currency."Amount Rounding Precision")
        end else begin
            ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
            ItemLedgerEntry."Cost Amount (Actual)" := Round(ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)");
        end;
    end;

    procedure UpdateBuffer(var ItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemVariant: Record "Item Variant";
        Location: Record Location;
        NewRow: Boolean;
    begin
        if ItemLedgEntry."Item No." <> LastItemNo then begin
            ClearLastEntry();
            LastItemNo := ItemLedgEntry."Item No.";
            NewRow := true
        end;

        if ShowVariants or ShowLocations then begin
            if ItemLedgEntry."Variant Code" <> LastVariantCode then begin
                NewRow := true;
                LastVariantCode := ItemLedgEntry."Variant Code";
                ItemVariant.SetLoadFields(Description);

                if ShowVariants then
                    if (ItemLedgEntry."Variant Code" = '') or (not ItemVariant.Get(ItemLedgEntry."Item No.", ItemLedgEntry."Variant Code")) then
                        VariantLabel := NoVariantLbl
                    else
                        VariantLabel := ItemVariant.TableCaption() + ' ' + ItemLedgEntry."Variant Code" + '(' + ItemVariant.Description + ')'
                else
                    VariantLabel := ''
            end;

            if ItemLedgEntry."Location Code" <> LastLocationCode then begin
                NewRow := true;
                LastLocationCode := ItemLedgEntry."Location Code";
                Location.SetLoadFields(Name);

                if ShowLocations then begin
                    if (ItemLedgEntry."Location Code" = '') or not Location.Get(ItemLedgEntry."Location Code") then
                        LocationLabel := NoLocationLbl
                    else
                        LocationLabel := Location.TableCaption() + ' ' + ItemLedgEntry."Location Code" + '(' + Location.Name + ')';
                end
                else
                    LocationLabel := '';
            end
        end;

        if NewRow then
            UpdateTempEntryBuffer();

        TempEntryBuffer."Remaining Quantity" += ItemLedgEntry."Remaining Quantity";

        if ShowACY then
            TempEntryBuffer.Value1 += ItemLedgEntry."Cost Amount (Actual) (ACY)"
        else
            TempEntryBuffer.Value1 += ItemLedgEntry."Cost Amount (Actual)";

        TempEntryBuffer."Item No." := ItemLedgEntry."Item No.";
        TempEntryBuffer."Variant Code" := LastVariantCode;
        TempEntryBuffer."Location Code" := LastLocationCode;
        TempEntryBuffer.Label := CopyStr(VariantLabel + ' ' + LocationLabel, 1, MaxStrLen(TempEntryBuffer.Label));

        IsCollecting := true;
    end;

    procedure ClearLastEntry()
    begin
        LastItemNo := '@@@';
        LastLocationCode := '@@@';
        LastVariantCode := '@@@';
    end;

    procedure UpdateTempEntryBuffer()
    begin
        if IsCollecting and ((TempEntryBuffer."Remaining Quantity" <> 0) or (TempEntryBuffer.Value1 <> 0)) then
            TempEntryBuffer.Insert();

        IsCollecting := false;
        Clear(TempEntryBuffer);
    end;
}
