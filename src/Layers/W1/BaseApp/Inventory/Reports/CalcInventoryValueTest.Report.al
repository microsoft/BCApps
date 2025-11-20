// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Costing;
using Microsoft.Utilities;
using System.Utilities;

report 5811 "Calc. Inventory Value - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/CalcInventoryValueTest.rdlc';
    Caption = 'Calc. Inventory Value - Test';

    dataset
    {
        dataitem(Integer; Integer)
        {
            DataItemTableView = where(Number = const(1));

            dataitem(Item; Item)
            {
                DataItemTableView = sorting("No.");
                RequestFilterFields = "No.";
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(STRSUBSTNO_Text000_FORMAT_PostingDate__; StrSubstNo(Text000, Format(PostingDate)))
                {
                }
                column(STRSUBSTNO___1___2__Item_TABLECAPTION_ItemFilter_; StrSubstNo('%1: %2', TableCaption(), ItemFilter))
                {
                }
                column(ItemFilter; ItemFilter)
                {
                }
                column(Standard_Cost_Revaluation___TestCaption; Standard_Cost_Revaluation___TestCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if GetFilter("Date Filter") <> '' then
                        Error(Text005, FieldCaption("Date Filter"));

                    if PostingDate = 0D then
                        Error(Text006);

                    if (CalculatePer = CalculatePer::Item) and (GetFilter("Bin Filter") <> '') then
                        Error(Text007, FieldCaption("Bin Filter"));

                    CheckCalcInvtVal.SetParameters(PostingDate, CalculatePer, ByLocation, ByVariant, true, true);
                    CheckCalcInvtVal.RunCheck(Item, TempErrorBuf);

                    OnPreDataItemOnCalcStdCost(Item, PostingDate, CalcBase);
                end;
            }
            dataitem(ItemLedgEntryErrBufLoop; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(ItemLedgEntryErrBuf__Document_Date_; Format(ItemLedgEntryErrBuf."Document Date"))
                {
                }
                column(ItemLedgEntryErrBuf__Entry_Type_; ItemLedgEntryErrBuf."Entry Type")
                {
                }
                column(ItemLedgEntryErrBuf_Description; ItemLedgEntryErrBuf.Description)
                {
                }
                column(ItemLedgEntryErrBuf__Document_No__; ItemLedgEntryErrBuf."Document No.")
                {
                }
                column(ItemLedgEntryErrBuf__Item_No__; ItemLedgEntryErrBuf."Item No.")
                {
                }
                column(ItemLedgEntryErrBuf_Error_Text; TempErrorBuf."Error Text")
                {
                }
                column(ItemLedgEntryErrBuf__Document_Date_Caption; ItemLedgEntryErrBuf__Document_Date_CaptionLbl)
                {
                }
                column(ItemLedgEntryErrBuf__Entry_Type_Caption; ItemLedgEntryErrBuf__Entry_Type_CaptionLbl)
                {
                }
                column(ItemLedgEntryErrBuf_DescriptionCaption; ItemLedgEntryErrBuf_DescriptionCaptionLbl)
                {
                }
                column(ItemLedgEntryErrBuf__Document_No__Caption; ItemLedgEntryErrBuf__Document_No__CaptionLbl)
                {
                }
                column(ItemLedgEntryErrBuf__Item_No__Caption; ItemLedgEntryErrBuf__Item_No__CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        OK := TempErrorBuf.FindSet()
                    else
                        OK := TempErrorBuf.Next() <> 0;
                    if not OK then
                        CurrReport.Break();

                    Clear(ItemLedgEntryErrBuf);
                    if TempErrorBuf."Source Table" = DATABASE::Item then begin
                        Item.Get(TempErrorBuf."Source No.");
                        ItemLedgEntryErrBuf."Item No." := Item."No.";
                        ItemLedgEntryErrBuf.Description := Item.Description;
                    end;

                    if TempErrorBuf."Source Table" = DATABASE::"Item Ledger Entry" then begin
                        ItemLedgEntryErrBuf.Get(TempErrorBuf."Source Ref. No.");
                        Item.Get(ItemLedgEntryErrBuf."Item No.");
                        ItemLedgEntryErrBuf.Description := Item.Description;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    TempErrorBuf.Reset();
                    TempErrorBuf.SetCurrentKey("Source Table", "Source No.", "Source Ref. No.");
                end;
            }
        }
    }

    requestpage
    {
        SaveValues = true;

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
            CalcBaseEnable := true;
            ByVariantEnable := true;
            ByLocationEnable := true;
        end;

        trigger OnOpenPage()
        begin
            if PostingDate = 0D then
                PostingDate := WorkDate();

            ValidateCalcLevel();
        end;
    }

    labels
    {
        ItemLedgEntryErrBuf_Error_Text_Caption = 'Error Text';
    }

    trigger OnPreReport()
    begin
        ItemFilter := Item.GetFilters();
    end;

    var
        ItemLedgEntryErrBuf: Record "Item Ledger Entry";
        CheckCalcInvtVal: Codeunit "Calc. Inventory Value-Check";
        ItemFilter: Text;
        OK: Boolean;
        ByLocationEnable: Boolean;
        ByVariantEnable: Boolean;
        CalcBaseEnable: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Posting Date of %1';
        Text005: Label 'You cannot enter a %1.';
#pragma warning restore AA0470
        Text006: Label 'You must enter a posting date.';
#pragma warning disable AA0470
        Text007: Label 'You cannot enter a %1, if Calculate Per is Item.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Standard_Cost_Revaluation___TestCaptionLbl: Label 'Standard Cost Revaluation - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        ItemLedgEntryErrBuf__Document_Date_CaptionLbl: Label 'Document Date';
        ItemLedgEntryErrBuf__Entry_Type_CaptionLbl: Label 'Entry Type';
        ItemLedgEntryErrBuf_DescriptionCaptionLbl: Label 'Description';
        ItemLedgEntryErrBuf__Document_No__CaptionLbl: Label 'Document No.';
        ItemLedgEntryErrBuf__Item_No__CaptionLbl: Label 'Item No.';

    protected var
        TempErrorBuf: Record "Error Buffer" temporary;
        CalcBase: Enum "Inventory Value Calc. Base";
        CalculatePer: Enum "Inventory Value Calc. Per";
        PostingDate: Date;
        ByLocation: Boolean;
        ByVariant: Boolean;

    local procedure ValidateCalcLevel()
    begin
        PageValidateCalcLevel();
        exit;
    end;

    local procedure PageValidateCalcLevel()
    begin
        if CalculatePer = CalculatePer::"Item Ledger Entry" then begin
            ByLocation := false;
            ByVariant := false;
            CalcBase := CalcBase::" ";
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


    procedure SetParameters(NewPostingDate: Date; NewCalculatePer: Enum "Inventory Value Calc. Per"; NewByLocation: Boolean; NewByVariant: Boolean; NewCalcBase: Enum "Inventory Value Calc. Base")
    begin
        PostingDate := NewPostingDate;
        CalculatePer := NewCalculatePer;
        ByLocation := NewByLocation;
        ByVariant := NewByVariant;
        CalcBase := NewCalcBase;
    end;

    [InternalEvent(true)]
    local procedure OnPreDataItemOnCalcStdCost(var Item: Record Item; PostingDate: Date; CalcBase: Enum "Inventory Value Calc. Base")
    begin
    end;
}
