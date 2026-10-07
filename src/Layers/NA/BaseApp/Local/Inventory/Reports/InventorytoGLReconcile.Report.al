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

report 10138 "Inventory to G/L Reconcile"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/InventorytoGLReconcile.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory to G/L Reconcile';
    UsageCategory = ReportsAndAnalysis;

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
            column(STRSUBSTNO_Text003_AsOfDate_; StrSubstNo(Text003, AsOfDate))
            {
            }
            column(STRSUBSTNO_Text006_Currency_Description_; StrSubstNo(Text006, Currency.Description))
            {
            }
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption + ': ' + ItemFilter)
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
            column(ItemFilter; ItemFilter)
            {
            }
            column(STRSUBSTNO_Text004_InvPostingGroup_TABLECAPTION_InvPostingGroup_Code_InvPostingGroup_Description_; StrSubstNo(Text004, InvPostingGroup.TableCaption(), InvPostingGroup.Code, InvPostingGroup.Description))
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
            column(STRSUBSTNO_Text009_FIELDCAPTION__Costing_Method____Costing_Method__; StrSubstNo(Text009, FieldCaption("Costing Method"), "Costing Method"))
            {
            }
            column(Item_Description; Description)
            {
            }
            column(STRSUBSTNO_Text005_InvPostingGroup_TABLECAPTION_InvPostingGroup_Code_InvPostingGroup_Description_; StrSubstNo(Text005, InvPostingGroup.TableCaption(), InvPostingGroup.Code, InvPostingGroup.Description))
            {
            }
            column(Inventory_to_G_L_ReconciliationCaption; Inventory_to_G_L_ReconciliationCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(InventoryValueCaption; InventoryValue_Control34CaptionLbl)
            {
            }
            column(ReceivedNotInvoicedCaption; ReceivedNotInvoiced_Control1020000CaptionLbl)
            {
            }
            column(ShippedNotInvoicedCaption; ShippedNotInvoiced_Control1020002CaptionLbl)
            {
            }
            column(TotalExpectedCostCaption; TotalExpectedCost_Control1020004CaptionLbl)
            {
            }
            column(ReceivedNotInvoicedPostedCaption; ReceivedNotInvoicedPosted_Control1020006CaptionLbl)
            {
            }
            column(ShippedNotInvoicedPostedCaption; ShippedNotInvoicedPosted_Control1020008CaptionLbl)
            {
            }
            column(NetExpectedCostPostedCaption; NetExpectedCostPosted_Control1020010CaptionLbl)
            {
            }
            column(NetExpectedCostNotPostedCaption; NetExpectedCostNotPosted_Control1020012CaptionLbl)
            {
            }
            column(AdjustFlagEntryCaption; AdjustFlagEntryCaptionLbl)
            {
            }
            column(TotalInvoicedValueCaption; TotalInvoicedValue_Control1020016CaptionLbl)
            {
            }
            column(InvoicedValuePostedCaption; InvoicedValuePosted_Control1020018CaptionLbl)
            {
            }
            column(InvoicedValueNotPostedCaption; InvoicedValueNotPosted_Control1020020CaptionLbl)
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
                    if "Applied Entry to Adjust" then
                        AdjustFlagEntry := true;

                    AdjustItemLedgEntryToAsOfDate("Item Ledger Entry");
                    UpdateBuffer("Item Ledger Entry");
                end;

                trigger OnPostDataItem()
                begin
                    UpdateTempBuffer();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Posting Date", 0D, AsOfDate);
                end;
            }
            dataitem(BufferLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(RowLabel; TempBuffer.Label)
                {
                }
                column(RowLabelTotal; StrSubstNo(Text010, TempBuffer.Label))
                {
                }
                column(ItemTotalText; StrSubstNo(Text010, TempBuffer."Item No."))
                {
                }
                column(InventoryValue; TempBuffer.Value1)
                {
                    AutoFormatExpression = Currency.Code;
                    AutoFormatType = 1;
                }
                column(ReceivedNotInvoiced; TempBuffer.Value2)
                {
                    AutoFormatExpression = Currency.Code;
                    AutoFormatType = 1;
                }
                column(ShippedNotInvoiced; TempBuffer.Value3)
                {
                    AutoFormatExpression = Currency.Code;
                    AutoFormatType = 1;
                }
                column(TotalExpectedCost; TempBuffer.Value4)
                {
                    AutoFormatExpression = Currency.Code;
                    AutoFormatType = 1;
                }
                column(ReceivedNotInvoicedPosted; TempBuffer.Value5)
                {
                    AutoFormatExpression = Currency.Code;
                    AutoFormatType = 1;
                }
                column(ShippedNotInvoicedPosted; TempBuffer.Value6)
                {
                    AutoFormatExpression = Currency.Code;
                    AutoFormatType = 1;
                }
                column(NetExpectedCostPosted; TempBuffer.Value7)
                {
                    AutoFormatExpression = Currency.Code;
                    AutoFormatType = 1;
                }
                column(NetExpectedCostNotPosted; TempBuffer.Value8)
                {
                    AutoFormatExpression = Currency.Code;
                    AutoFormatType = 1;
                }
                column(TotalInvoicedValue; TempBuffer.Value9)
                {
                    AutoFormatExpression = Currency.Code;
                    AutoFormatType = 1;
                }
                column(InvoicedValuePosted; TempBuffer.Value10)
                {
                    AutoFormatExpression = Currency.Code;
                    AutoFormatType = 1;
                }
                column(InvoicedValueNotPosted; TempBuffer.Value11)
                {
                    AutoFormatExpression = Currency.Code;
                    AutoFormatType = 1;
                }
                column(ItemLedgerEntry_VariantCode; TempBuffer."Variant Code")
                {
                }
                column(ItemLedgerEntry_LocationCode; TempBuffer."Location Code")
                {
                }
                column(AdjustFlagEntry; Format(AdjustFlagEntry))
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        TempBuffer.Find('-')
                    else
                        TempBuffer.Next();
                end;

                trigger OnPostDataItem()
                begin
                    TempBuffer.DeleteAll();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, TempBuffer.Count);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not InvPostingGroup.Get("Inventory Posting Group") then
                    Clear(InvPostingGroup);
                Progress.Update(1, Format("No."));
                AdjustFlagEntry := false;
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Date Filter", 0D, AsOfDate);
            end;
        }
    }

    requestpage
    {
        Caption = 'Inventory to G/L Reconcile';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AsOfDate; AsOfDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'As Of Date';
                        ToolTip = 'Specifies the valuation date.';
                    }
                    field(BreakdownByVariants; ShowVariants)
                    {
                        Caption = 'Breakdown by Variants';
                        ToolTip = 'Specifies the item variants that you want the report to consider.';
                    }
                    field(BreakdownByLocation; ShowLocations)
                    {
                        Caption = 'Breakdown by Location';
                        ToolTip = 'Specifies the breakdown report data by locations.';
                    }
                    field(UseAdditionalReportingCurrency; ShowACY)
                    {
                        Caption = 'Use Additional Reporting Currency';
                        ToolTip = 'Specifies that you want all amounts to be printed by using the additional reporting currency. If this field is not selected, all amounts will be printed in U.S. dollars.';
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

        if AsOfDate = 0D then
            Error(Text000);
        if ShowLocations and not ShowVariants then
            if not "Item Ledger Entry".SetCurrentKey("Item No.", "Location Code") then
                Error(Text001,
                  "Item Ledger Entry".TableCaption(),
                  "Item Ledger Entry".FieldCaption("Item No."),
                  "Item Ledger Entry".FieldCaption("Location Code"));
        if Item.GetFilter("Date Filter") <> '' then
            Error(Text002, Item.FieldCaption("Date Filter"), Item.TableCaption());

        CompanyInformation.Get();
        ItemFilter := Item.GetFilters();
        GLSetup.Get();
        if GLSetup."Additional Reporting Currency" = '' then
            ShowACY := false
        else begin
            Currency.Get(GLSetup."Additional Reporting Currency");
            Currency.TestField("Amount Rounding Precision");
            Currency.TestField("Unit-Amount Rounding Precision");
        end;
        Progress.Open(Item.TableCaption + '  #1############');
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInformation: Record "Company Information";
        InvPostingGroup: Record "Inventory Posting Group";
        Currency: Record Currency;
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        TempBuffer: Record "Item Location Variant Buffer" temporary;
        ItemFilter: Text;
        ShowVariants: Boolean;
        ShowLocations: Boolean;
        ShowACY: Boolean;
        AsOfDate: Date;
        Text000: Label 'You must enter an As Of Date.';
        Text001: Label 'If you want to show Locations without also showing Variants, you must add a new key to the %1 table which starts with the %2 and %3 fields.';
        Text002: Label 'Do not set a %1 on the %2.  Use the As Of Date on the Option tab instead.';
        Text003: Label 'Values As Of %1';
        Text004: Label '%1 %2 (%3)';
        Text005: Label '%1 %2 (%3) Total';
        Text006: Label 'All Inventory Values are shown in %1.';
        Text007: Label 'No Variant';
        Text008: Label 'No Location';
        Text009: Label '%1: %2';
        Text010: Label '%1 Total';
        Grouping: Boolean;
        Inventory_to_G_L_ReconciliationCaptionLbl: Label 'Inventory to G/L Reconciliation';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        InventoryValue_Control34CaptionLbl: Label 'Inventory Valuation';
        ReceivedNotInvoiced_Control1020000CaptionLbl: Label 'Received Not Invoiced';
        ShippedNotInvoiced_Control1020002CaptionLbl: Label 'Shipped Not Invoiced';
        TotalExpectedCost_Control1020004CaptionLbl: Label 'Total Expected Cost';
        ReceivedNotInvoicedPosted_Control1020006CaptionLbl: Label 'Rec. Not Inv. Posted to G/L';
        ShippedNotInvoicedPosted_Control1020008CaptionLbl: Label 'Shp. Not Inv. Posted to G/L';
        NetExpectedCostPosted_Control1020010CaptionLbl: Label 'Expected Cost Posted to G/L';
        NetExpectedCostNotPosted_Control1020012CaptionLbl: Label 'Expected Cost to be Posted';
        AdjustFlagEntryCaptionLbl: Label 'Pending Adj.';
        TotalInvoicedValue_Control1020016CaptionLbl: Label 'Invoiced Value';
        InvoicedValuePosted_Control1020018CaptionLbl: Label 'Inv. Value Posted to G/L';
        InvoicedValueNotPosted_Control1020020CaptionLbl: Label 'Inv. Value to be Posted';
        Total_Inventory_ValueCaptionLbl: Label 'Total Inventory Value';
        InventoryValue: Decimal;
        ShippedNotInvoiced: Decimal;
        ReceivedNotInvoiced: Decimal;
        NetExpectedCostNotPosted: Decimal;
        ShippedNotInvoicedPosted: Decimal;
        ReceivedNotInvoicedPosted: Decimal;
        NetExpectedCostPosted: Decimal;
        TotalExpectedCost: Decimal;
        TotalInvoicedValue: Decimal;
        InvoicedValueNotPosted: Decimal;
        InvoicedValuePosted: Decimal;
        IsCollecting: Boolean;
        Progress: Dialog;
        LastItemNo: Code[20];
        LastLocationCode: Code[10];
        LastVariantCode: Code[10];
        NewRow: Boolean;
        VariantLabel: Text[250];
        LocationLabel: Text[250];
        AdjustFlagEntry: Boolean;

    local procedure AdjustItemLedgEntryToAsOfDate(var ItemLedgEntry: Record "Item Ledger Entry")
    var
        ValueEntry: Record "Value Entry";
        InvoicedValue: Decimal;
        InvoicedValueACY: Decimal;
        InvoicedPostedToGL: Decimal;
        InvoicedPostedToGLACY: Decimal;
        InvoicedQty: Decimal;
        ValuedQty: Decimal;
        ExpectedValue: Decimal;
        ExpectedValueACY: Decimal;
        ExpectedPostedToGL: Decimal;
        ExpectedPostedToGLACY: Decimal;
    begin
        InventoryValue := 0;
        ShippedNotInvoiced := 0;
        ReceivedNotInvoiced := 0;
        NetExpectedCostNotPosted := 0;
        ShippedNotInvoicedPosted := 0;
        ReceivedNotInvoicedPosted := 0;
        NetExpectedCostPosted := 0;
        TotalExpectedCost := 0;
        TotalInvoicedValue := 0;
        InvoicedValueNotPosted := 0;
        InvoicedValuePosted := 0;

        InvoicedValue := 0;
        InvoicedValueACY := 0;
        InvoicedPostedToGL := 0;
        InvoicedPostedToGLACY := 0;
        InvoicedQty := 0;
        ValuedQty := 0;
        ExpectedValue := 0;
        ExpectedValueACY := 0;
        ExpectedPostedToGL := 0;
        ExpectedPostedToGLACY := 0;

        // calculate adjusted cost of entry
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        ValueEntry.SetRange("Posting Date", 0D, AsOfDate);
        if ValueEntry.Find('-') then
            repeat
                ExpectedValue := ExpectedValue + ValueEntry."Cost Amount (Expected)";
                ExpectedValueACY := ExpectedValueACY + ValueEntry."Cost Amount (Expected) (ACY)";
                ExpectedPostedToGL := ExpectedPostedToGL + ValueEntry."Expected Cost Posted to G/L";
                ExpectedPostedToGLACY := ExpectedPostedToGLACY + ValueEntry."Exp. Cost Posted to G/L (ACY)";
                if ValueEntry."Expected Cost" and (ValuedQty = 0) then
                    ValuedQty := ValueEntry."Valued Quantity";
                InvoicedQty := InvoicedQty + ValueEntry."Invoiced Quantity";
                InvoicedValue := InvoicedValue + ValueEntry."Cost Amount (Actual)";
                InvoicedValueACY := InvoicedValueACY + ValueEntry."Cost Amount (Actual) (ACY)";
                InvoicedPostedToGL := InvoicedPostedToGL + ValueEntry."Cost Posted to G/L";
                InvoicedPostedToGLACY := InvoicedPostedToGLACY + ValueEntry."Cost Posted to G/L (ACY)";
            until ValueEntry.Next() = 0;

        if ValuedQty = 0 then
            ValuedQty := InvoicedQty
        else
            if ValuedQty > 0 then begin
                if ShowACY then begin
                    ReceivedNotInvoiced := ExpectedValueACY;
                    ReceivedNotInvoicedPosted := ExpectedPostedToGLACY;
                end else begin
                    ReceivedNotInvoiced := ExpectedValue;
                    ReceivedNotInvoicedPosted := ExpectedPostedToGL;
                end;
            end else
                if ValuedQty < 0 then
                    if ShowACY then begin
                        ShippedNotInvoiced := ExpectedValueACY;
                        ShippedNotInvoicedPosted := ExpectedPostedToGLACY;
                    end else begin
                        ShippedNotInvoiced := ExpectedValue;
                        ShippedNotInvoicedPosted := ExpectedPostedToGL;
                    end;
        TotalExpectedCost := ReceivedNotInvoiced + ShippedNotInvoiced;
        NetExpectedCostPosted := ReceivedNotInvoicedPosted + ShippedNotInvoicedPosted;
        NetExpectedCostNotPosted := TotalExpectedCost - NetExpectedCostPosted;
        if ShowACY then begin
            TotalInvoicedValue := InvoicedValueACY;
            InvoicedValuePosted := InvoicedPostedToGLACY;
        end else begin
            TotalInvoicedValue := InvoicedValue;
            InvoicedValuePosted := InvoicedPostedToGL;
        end;
        InvoicedValueNotPosted := TotalInvoicedValue - InvoicedValuePosted;
        InventoryValue := TotalInvoicedValue + TotalExpectedCost;
    end;

    local procedure UpdateBuffer(ItemLedgEntry: Record "Item Ledger Entry")
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
                if ShowVariants then begin
                    if (ItemLedgEntry."Variant Code" = '') or not ItemVariant.Get(ItemLedgEntry."Item No.", ItemLedgEntry."Variant Code") then
                        VariantLabel := Text007
                    else
                        VariantLabel := ItemVariant.TableCaption + ' ' + ItemLedgEntry."Variant Code" + '(' + ItemVariant.Description + ')';
                end else
                    VariantLabel := ''
            end;
            if ItemLedgEntry."Location Code" <> LastLocationCode then begin
                NewRow := true;
                LastLocationCode := ItemLedgEntry."Location Code";
                if ShowLocations then begin
                    if (ItemLedgEntry."Location Code" = '') or not Location.Get(ItemLedgEntry."Location Code") then
                        LocationLabel := Text008
                    else
                        LocationLabel := Location.TableCaption + ' ' + ItemLedgEntry."Location Code" + '(' + Location.Name + ')';
                end else
                    LocationLabel := '';
            end
        end;

        if NewRow then
            UpdateTempBuffer();

        if ShowACY then begin
            TempBuffer.Value1 += Round(InventoryValue, Currency."Amount Rounding Precision");
            TempBuffer.Value2 += Round(ReceivedNotInvoiced, Currency."Amount Rounding Precision");
            TempBuffer.Value3 += Round(ShippedNotInvoiced, Currency."Amount Rounding Precision");
            TempBuffer.Value4 += Round(TotalExpectedCost, Currency."Amount Rounding Precision");
            TempBuffer.Value5 += Round(ReceivedNotInvoicedPosted, Currency."Amount Rounding Precision");
            TempBuffer.Value6 += Round(ShippedNotInvoicedPosted, Currency."Amount Rounding Precision");
            TempBuffer.Value7 += Round(NetExpectedCostPosted, Currency."Amount Rounding Precision");
            TempBuffer.Value8 += Round(NetExpectedCostNotPosted, Currency."Amount Rounding Precision");
            TempBuffer.Value9 += Round(TotalInvoicedValue, Currency."Amount Rounding Precision");
            TempBuffer.Value10 += Round(InvoicedValuePosted, Currency."Amount Rounding Precision");
            TempBuffer.Value11 += Round(InvoicedValueNotPosted, Currency."Amount Rounding Precision");
        end else begin
            TempBuffer.Value1 += Round(InventoryValue);
            TempBuffer.Value2 += Round(ReceivedNotInvoiced);
            TempBuffer.Value3 += Round(ShippedNotInvoiced);
            TempBuffer.Value4 += Round(TotalExpectedCost);
            TempBuffer.Value5 += Round(ReceivedNotInvoicedPosted);
            TempBuffer.Value6 += Round(ShippedNotInvoicedPosted);
            TempBuffer.Value7 += Round(NetExpectedCostPosted);
            TempBuffer.Value8 += Round(NetExpectedCostNotPosted);
            TempBuffer.Value9 += Round(TotalInvoicedValue);
            TempBuffer.Value10 += Round(InvoicedValuePosted);
            TempBuffer.Value11 += Round(InvoicedValueNotPosted);
        end;

        TempBuffer."Item No." := ItemLedgEntry."Item No.";
        if ShowVariants then
            TempBuffer."Variant Code" := LastVariantCode;
        if ShowLocations then
            TempBuffer."Location Code" := LastLocationCode;
        TempBuffer.Label := CopyStr(VariantLabel + ' ' + LocationLabel, 1, MaxStrLen(TempBuffer.Label));

        IsCollecting := true;
    end;

    local procedure ClearLastEntry()
    begin
        LastItemNo := '@@@';
        LastLocationCode := '@@@';
        LastVariantCode := '@@@';
    end;

    local procedure UpdateTempBuffer()
    var
        AlreadyInsertedTempBuffer: Record "Item Location Variant Buffer" temporary;
    begin
        if IsCollecting then
            if not TempBuffer.Insert() then begin
                AlreadyInsertedTempBuffer.Copy(TempBuffer, true);
                AlreadyInsertedTempBuffer.Get(TempBuffer."Item No.", TempBuffer."Variant Code", TempBuffer."Location Code");
                AlreadyInsertedTempBuffer.Value1 += TempBuffer.Value1;
                AlreadyInsertedTempBuffer.Value2 += TempBuffer.Value2;
                AlreadyInsertedTempBuffer.Value3 += TempBuffer.Value3;
                AlreadyInsertedTempBuffer.Value4 += TempBuffer.Value4;
                AlreadyInsertedTempBuffer.Value5 += TempBuffer.Value5;
                AlreadyInsertedTempBuffer.Value6 += TempBuffer.Value6;
                AlreadyInsertedTempBuffer.Value7 += TempBuffer.Value7;
                AlreadyInsertedTempBuffer.Value8 += TempBuffer.Value8;
                AlreadyInsertedTempBuffer.Value9 += TempBuffer.Value9;
                AlreadyInsertedTempBuffer.Value10 += TempBuffer.Value10;
                AlreadyInsertedTempBuffer.Value11 += TempBuffer.Value11;
                AlreadyInsertedTempBuffer.Modify();
            end;

        IsCollecting := false;
        Clear(TempBuffer);
    end;
}

