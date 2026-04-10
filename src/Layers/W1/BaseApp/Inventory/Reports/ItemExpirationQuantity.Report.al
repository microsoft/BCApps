// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
#if not CLEAN28
using System.Utilities;
#endif

report 5809 "Item Expiration - Quantity"
{
    ApplicationArea = ItemTracking;
    Caption = 'Item Expiration - Quantity';
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = Excel;

    dataset
    {
#if not CLEAN28
        dataitem(Header; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(0));
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ItemCaption; Item.TableCaption + ': ' + ItemFilter)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ItemFilter; ItemFilter = '')
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PeriodStartDate21; PeriodStartDate[2] + 1)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PeriodStartDate3; PeriodStartDate[3])
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PeriodStartDate31; PeriodStartDate[3] + 1)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PeriodStartDate4; PeriodStartDate[4])
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PeriodStartDate41; PeriodStartDate[4] + 1)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PeriodStartDate5; PeriodStartDate[5])
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
        }
#endif
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Inventory Posting Group", "Statistics Group", "Location Filter", "Item Tracking Code";
            column(No_Item; "No.")
            {
                IncludeCaption = true;
            }
            column(Description_Item; Description)
            {
                IncludeCaption = true;
            }
            column(InventoryPostingGroup_Item; "Inventory Posting Group")
            {
                IncludeCaption = true;
            }
            column(StatisticsGroup_Item; "Statistics Group")
            {
                IncludeCaption = true;
            }
            column(ItemTrackingCode_Item; "Item Tracking Code")
            {
                IncludeCaption = true;
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("No."), "Location Code" = field("Location Filter"), "Variant Code" = field("Variant Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
#pragma warning disable AL0254
                DataItemTableView = sorting("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date", "Expiration Date", "Lot No.", "Serial No.") where(Open = const(true));
#pragma warning restore AL0254
                column(InvtQty1; InvtQty[1])
                {
                    DecimalPlaces = 0 : 2;
                }
                column(InvtQty2; InvtQty[2])
                {
                    DecimalPlaces = 0 : 2;
                }
                column(InvtQty3; InvtQty[3])
                {
                    DecimalPlaces = 0 : 2;
                }
                column(InvtQty4; InvtQty[4])
                {
                    DecimalPlaces = 0 : 2;
                }
                column(InvtQty5; InvtQty[5])
                {
                    DecimalPlaces = 0 : 2;
                }
                column(TotalInvtQty; TotalInvtQty)
                {
                    DecimalPlaces = 0 : 2;
                }

                trigger OnAfterGetRecord()
                begin
                    for i := 1 to 5 do
                        InvtQty[i] := 0;

                    TotalInvtQty := "Remaining Quantity";
                    for i := 1 to 5 do
                        if ("Expiration Date" > PeriodStartDate[i]) and
                           ("Expiration Date" <= PeriodStartDate[i + 1])
                        then
                            InvtQty[i] := "Remaining Quantity";
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Expiration Date", '<>%1', 0D);
                    SetFilter("Remaining Quantity", '<>%1', 0);
                end;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Item Expiration – Quantity';
        AboutText = 'Shows current inventory levels for items with expiration date tracking enabled and highlight stock on hand that''''s expired or soon to be expired.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(EndingDate; PeriodStartDate[5])
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';

                        trigger OnValidate()
                        begin
                            if PeriodStartDate[5] = 0D then
                                Error(Text002);
                        end;
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the length of the three periods in the report.';

                        trigger OnValidate()
                        begin
                            if (CalcDate(PeriodLength) - Today < 1) or (Format(PeriodLength) = '') then
                                Error(Text003);
                        end;
                    }
                    field(RequestPeriod1Text; Period1Text)
                    {
                        ApplicationArea = All;
                        Caption = 'Period 1';
                        ToolTip = 'Specifies Period 1 on this report.';
                        Visible = false;
                    }
                    field(RequestPeriod2Text; Period2Text)
                    {
                        ApplicationArea = All;
                        Caption = 'Period 2';
                        ToolTip = 'Specifies Period 2 on this report.';
                        Visible = false;
                    }
                    field(RequestPeriod3Text; Period3Text)
                    {
                        ApplicationArea = All;
                        Caption = 'Period 3';
                        ToolTip = 'Specifies Period 3 on this report.';
                        Visible = false;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PeriodStartDate[5] = 0D then
                PeriodStartDate[5] := CalcDate('<CM>', WorkDate());
            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1M>');
        end;

        trigger OnClosePage()
        var
            NegPeriodLength: DateFormula;
        begin
            PeriodStartDate[6] := DMY2Date(31, 12, 9999);
            Evaluate(NegPeriodLength, StrSubstNo('-%1', Format(PeriodLength)));
            for i := 1 to 3 do
                PeriodStartDate[5 - i] := CalcDate(NegPeriodLength, PeriodStartDate[6 - i]);
            UpdateRequestPageFilterValues();
        end;
    }

    rendering
    {
        layout(Excel)
        {
            Caption = 'Item Expiration - Quantity Excel';
            Type = Excel;
            LayoutFile = './Inventory/Reports/ItemExpirationQuantity.xlsx';
            Summary = 'Built in layout for the Item Expiration - Quantity Excel report.';
        }
#if not CLEAN28
        layout(RDLC)
        {
            Caption = 'Item Expiration - Quantity RDLC (Obsolete)';
            Type = RDLC;
            LayoutFile = './Inventory/Reports/ItemExpirationQuantity.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel layout and will be removed in a future release.';
            ObsoleteTag = '28.0';
            Summary = 'Built in layout for the Item Expiration - Quantity RDLC (Obsolete) report.';
        }
#endif
    }

    labels
    {
        ItemExpirationQuantityLbl = 'Item Expiration - Quantity';
        ItemExpQuantityPrintLbl = 'Item Exp. - Quantity (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        ItemExpQuantityAnalysisLbl = 'Item Exp. - Quantity (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DataRetrievedLbl = 'Data retrieved:';
        BeforeLbl = '...before';
        AfterLbl = 'after...';
        Inventory2Lbl = 'Inventory for Period 2';
        Inventory3Lbl = 'Inventory for Period 3';
        Inventory4Lbl = 'Inventory for Period 4';
        InventoryLbl = 'Inventory';
        // About the report labels
        AboutTheReportLbl = 'About the report';
        EnvironmentLbl = 'Environment';
        CompanyLbl = 'Company';
        UserLbl = 'User';
        RunOnLbl = 'Run on';
        ReportNameLbl = 'Report name';
        DocumentationLbl = 'Documentation';
#if not CLEAN28
        ItemExpirationQutyCaption = 'Item Expiration - Quantity';
        PageCaption = 'Page';
        AfterCaption = 'After...';
        BeforeCaption = '...Before';
        TotalInvtQtyCaption = 'Inventory';
        DescriptionCaption = 'Description';
        ItemNoCaption = 'Item No.';
#endif
    }

    trigger OnPreReport()
    var
        NegPeriodLength: DateFormula;
    begin
        ItemFilter := Item.GetFilters();

        PeriodStartDate[6] := DMY2Date(31, 12, 9999);
        Evaluate(NegPeriodLength, StrSubstNo('-%1', Format(PeriodLength)));
        for i := 1 to 3 do
            PeriodStartDate[5 - i] := CalcDate(NegPeriodLength, PeriodStartDate[6 - i]);
        UpdateRequestPageFilterValues();
    end;

    var
        PeriodLength: DateFormula;
        ItemFilter: Text;
        InvtQty: array[6] of Decimal;
        PeriodStartDate: array[7] of Date;
        i: Integer;
        TotalInvtQty: Decimal;
        Period1Text: Text;
        Period2Text: Text;
        Period3Text: Text;
#pragma warning disable AA0074
        Text002: Label 'Enter the ending date.';
        Text003: Label 'The minimum permitted value is 1D.';
#pragma warning restore AA0074

    procedure InitializeRequest(NewPeriodStartDate: Date; NewPeriodLength: DateFormula)
    begin
        PeriodStartDate[5] := NewPeriodStartDate;
        PeriodLength := NewPeriodLength;
    end;

    local procedure UpdateRequestPageFilterValues()
    begin
        if (PeriodStartDate[2] <> 0D) and (PeriodStartDate[3] <> 0D) and (PeriodStartDate[4] <> 0D) then begin
            Period1Text := Format(PeriodStartDate[2] + 1) + '..' + Format(PeriodStartDate[3]);
            Period2Text := Format(PeriodStartDate[3] + 1) + '..' + Format(PeriodStartDate[4]);
            Period3Text := Format(PeriodStartDate[4] + 1) + '..' + Format(PeriodStartDate[5]);
        end;
    end;
}
