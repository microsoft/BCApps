// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Reports;

using Microsoft.Inventory.Journal;

report 7321 "Inventory Movement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Warehouse/Reports/InventoryMovement.rdlc';
    Caption = 'Inventory Movement';
    WordMergeDataItem = "Item Journal Batch";

    dataset
    {
        dataitem("Item Journal Batch"; "Item Journal Batch")
        {
            DataItemTableView = sorting("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            column(JournalTempName_ItemJournalBatch; "Journal Template Name")
            {
            }
            column(Name_ItemJournalBatch; Name)
            {
            }
            column(InventoryMovementCaption; InventoryMovementCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(JournalTempNameFieldCaption; "Item Journal Line".FieldCaption("Journal Template Name"))
            {
            }
            column(JournalBatchNameFieldCaption; "Item Journal Line".FieldCaption("Journal Batch Name"))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(Time; Time)
            {
            }
            dataitem("Item Journal Line"; "Item Journal Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                RequestFilterFields = "Journal Template Name", "Journal Batch Name", "Location Code", "Bin Code", "Item No.", "Variant Code";
                column(JournalTempName_ItemJournalLine; "Journal Template Name")
                {
                }
                column(JournalBatchName_ItemJournalLine; "Journal Batch Name")
                {
                }
                column(ActivityType; ActivityType)
                {
                    OptionCaption = ' ,Put-away,Pick,Movement';
                }
                column(ItemJnlLineActTypeShowOutput; ActivityType <> ActivityType::" ")
                {
                }
                column(ItemJournalLineTableCaption; TableCaption + ': ' + ItemJnlLineFilter)
                {
                }
                column(ItemJnlLineFilter; ItemJnlLineFilter)
                {
                }
                column(ItemJnlLineHeader1ShowOutput; ShouldShowOutput(ItemJnlTemplate.Type))
                {
                }
                column(ItemJnlLineHeader2ShowOutput; ItemJnlTemplate.Type = ItemJnlTemplate.Type::Transfer)
                {
                }
                column(UOM_ItemJournalLine; "Unit of Measure Code")
                {
                }
                column(Qty_ItemJournalLine; Quantity)
                {
                }
                column(BinCode_ItemJournalLine; "Bin Code")
                {
                }
                column(LocationCode_ItemJournalLine; "Location Code")
                {
                }
                column(VariantCode_ItemJournalLine; "Variant Code")
                {
                }
                column(Description_ItemJournalLine; Description)
                {
                }
                column(ItemNo_ItemJournalLine; "Item No.")
                {
                }
                column(PostingDate_ItemJournalLine; Format("Posting Date"))
                {
                }
                column(EntryType_ItemJournalLine; "Entry Type")
                {
                }
                column(QuantityBase_ItemJournalLine; "Quantity (Base)")
                {
                }
                column(QuantityFormat; Quantity)
                {
                }
                column(NewBinCode_ItemJournalLine; "New Bin Code")
                {
                }
                column(NewLocationCode_ItemJournalLine; "New Location Code")
                {
                }
                column(QuantityBaseFormat; "Quantity (Base)")
                {
                }
                column(ActivityTypeCaption; ActivityTypeCaptionLbl)
                {
                }
                column(UOMFieldCaption; FieldCaption("Unit of Measure Code"))
                {
                }
                column(QtyFieldCaption; FieldCaption(Quantity))
                {
                }
                column(BinCodeFieldCaption; FieldCaption("Bin Code"))
                {
                }
                column(LocationCodeFieldCaption; FieldCaption("Location Code"))
                {
                }
                column(VariantCodeFieldCaption; FieldCaption("Variant Code"))
                {
                }
                column(DescriptionFieldCaption; FieldCaption(Description))
                {
                }
                column(ItemNoFieldCaption; FieldCaption("Item No."))
                {
                }
                column(PostingDateCaption; PostingDateCaptionLbl)
                {
                }
                column(EntryTypeFieldCaption; FieldCaption("Entry Type"))
                {
                }
                column(QuantityBaseFieldCaption; FieldCaption("Quantity (Base)"))
                {
                }
                column(NewBinCodeFieldCaption; FieldCaption("New Bin Code"))
                {
                }
                column(NewLocationCodeFieldCaption; FieldCaption("New Location Code"))
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if ("Entry Type" in ["Entry Type"::"Positive Adjmt.", "Entry Type"::Purchase, "Entry Type"::Output]) and
                       (Quantity > 0) and
                       (ActivityType in [ActivityType::Pick, ActivityType::Movement])
                    then
                        CurrReport.Skip();

                    if ("Entry Type" in ["Entry Type"::"Negative Adjmt.", "Entry Type"::Sale, "Entry Type"::Consumption]) and
                       (Quantity < 0) and
                       (ActivityType in [ActivityType::Pick, ActivityType::Movement])
                    then
                        CurrReport.Skip();

                    if ("Entry Type" in ["Entry Type"::"Positive Adjmt.", "Entry Type"::Purchase, "Entry Type"::Output]) and
                       (Quantity < 0) and
                       (ActivityType in [ActivityType::"Put-away", ActivityType::Movement])
                    then
                        CurrReport.Skip();

                    if ("Entry Type" in ["Entry Type"::"Negative Adjmt.", "Entry Type"::Sale, "Entry Type"::Consumption]) and
                       (Quantity > 0) and
                       (ActivityType in [ActivityType::"Put-away", ActivityType::Movement])
                    then
                        CurrReport.Skip();

                    if ("Entry Type" <> "Entry Type"::Transfer) and
                       (ActivityType = ActivityType::Movement)
                    then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    ItemJnlTemplate.Get("Item Journal Batch"."Journal Template Name");
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
                    field(ActivityType; ActivityType)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Activity Type';
                        OptionCaption = ' ,Put-away,Pick,Movement';
                        ToolTip = 'Specifies the inventory movement activity that a warehouse employee will follow to move items.';
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

    trigger OnPreReport()
    begin
        ItemJnlLineFilter := "Item Journal Line".GetFilters();
    end;

    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlLineFilter: Text;
        ActivityType: Option " ","Put-away",Pick,Movement;
        InventoryMovementCaptionLbl: Label 'Inventory Movement';
        PageCaptionLbl: Label 'Page';
        ActivityTypeCaptionLbl: Label 'Activity Type';
        PostingDateCaptionLbl: Label 'Posting Date';

    procedure InitializeRequest(NewActivityType: Option)
    begin
        ActivityType := NewActivityType;
    end;

    local procedure ShouldShowOutput(TemplateType: Enum "Item Journal Template Type") Result: Boolean
    begin
        OnShouldShowOutput(TemplateType, Result);
    end;

    [InternalEvent(false)]
    local procedure OnShouldShowOutput(TemplateType: Enum "Item Journal Template Type"; var Result: Boolean)
    begin
    end;
}
