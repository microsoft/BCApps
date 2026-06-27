// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;

report 10151 "Physical Inventory Count"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/PhysicalInventoryCount.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Physical Inventory Count';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Item Journal Template"; "Item Journal Template")
        {
            DataItemTableView = sorting(Name);
            column(Item_Journal_Template_Name; Name)
            {
            }
            dataitem("Item Journal Batch"; "Item Journal Batch")
            {
                DataItemTableView = sorting("Journal Template Name", Name);
                PrintOnlyIfDetail = true;
                column(CompanyInformation_Name; CompanyInformation.Name)
                {
                }
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(USERID; UserId)
                {
                }
                column(TIME; Time)
                {
                }
                column(Item_Journal_Template__TABLECAPTION__________ItemJnlTemplateFilter; "Item Journal Template".TableCaption + ': ' + ItemJnlTemplateFilter)
                {
                }
                column(Item_Journal_Batch__TABLECAPTION__________ItemJnlBatchFilter; "Item Journal Batch".TableCaption + ': ' + ItemJnlBatchFilter)
                {
                }
                column(Item_Journal_Line__TABLECAPTION__________ItemJnlLineFilter; "Item Journal Line".TableCaption + ': ' + ItemJnlLineFilter)
                {
                }
                column(ItemJnlTemplateFilter; ItemJnlTemplateFilter)
                {
                }
                column(ItemJnlBatchFilter; ItemJnlBatchFilter)
                {
                }
                column(ItemJnlLineFilter; ItemJnlLineFilter)
                {
                }
                column(Item_Journal_Batch_Journal_Template_Name; "Journal Template Name")
                {
                }
                column(Item_Journal_Batch_Name; Name)
                {
                }
                column(Physical_Inventory_Count_SheetCaption; Physical_Inventory_Count_SheetCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Shelf_Bin_No_Caption; Shelf_Bin_No_CaptionLbl)
                {
                }
                column(Item_Journal_Line__Item_No__Caption; "Item Journal Line".FieldCaption("Item No."))
                {
                }
                column(Item_Journal_Line_DescriptionCaption; "Item Journal Line".FieldCaption(Description))
                {
                }
                column(Unit_of_MeasureCaption; Unit_of_MeasureCaptionLbl)
                {
                }
                column(EmptyStringCaption; EmptyStringCaptionLbl)
                {
                }
                dataitem("Item Journal Line"; "Item Journal Line")
                {
                    DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                    DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
                    RequestFilterFields = "Journal Template Name", "Journal Batch Name", "Item No.", "Location Code";
                    column(EmptyString; '')
                    {
                    }
                    column(Item__Base_Unit_of_Measure_; Item."Base Unit of Measure")
                    {
                    }
                    column(Item_Journal_Line_Description; Description)
                    {
                    }
                    column(Item_Journal_Line__Item_No__; "Item No.")
                    {
                    }
                    column(Item__Shelf_No__; Item."Shelf No.")
                    {
                    }
                    column(Item_Journal_Line_Journal_Template_Name; "Journal Template Name")
                    {
                    }
                    column(Item_Journal_Line_Journal_Batch_Name; "Journal Batch Name")
                    {
                    }
                    column(Item_Journal_Line_Line_No_; "Line No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if "Item No." <> '' then begin
                            Item.Get("Item No.");
                            if SKU.Get("Location Code", "Item No.", "Variant Code") then begin
                                Item."Shelf No." := SKU."Shelf No.";
                                Item.Description := SKU.Description;
                            end;
                        end else
                            Clear(Item);
                    end;
                }

                trigger OnPreDataItem()
                begin
                    SetRange("Journal Template Name", "Item Journal Template".Name);
                    if ItemJnlLineBatchFilter <> '' then
                        SetFilter(Name, ItemJnlLineBatchFilter);
                end;
            }

            trigger OnPreDataItem()
            begin
                if ItemJnlLineTemplateFilter <> '' then
                    SetFilter(Name, ItemJnlLineTemplateFilter);
            end;
        }
    }

    requestpage
    {

        layout
        {
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
        CompanyInformation.Get();

        ItemJnlLineTemplateFilter := "Item Journal Line".GetFilter("Journal Template Name");
        ItemJnlLineBatchFilter := "Item Journal Line".GetFilter("Journal Batch Name");
        if ItemJnlLineTemplateFilter <> '' then begin
            "Item Journal Line".SetRange("Journal Template Name");
            "Item Journal Template".SetFilter(Name, ItemJnlLineTemplateFilter);
        end;
        if ItemJnlLineBatchFilter <> '' then begin
            "Item Journal Line".SetRange("Journal Batch Name");
            "Item Journal Batch".SetFilter(Name, ItemJnlLineBatchFilter);
        end;

        ItemJnlLineFilter := "Item Journal Line".GetFilters();
        ItemJnlBatchFilter := "Item Journal Batch".GetFilters();
        ItemJnlTemplateFilter := "Item Journal Template".GetFilter(Name);
    end;

    var
        CompanyInformation: Record "Company Information";
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        ItemJnlLineTemplateFilter: Text;
        ItemJnlLineBatchFilter: Text;
        ItemJnlLineFilter: Text;
        ItemJnlBatchFilter: Text;
        ItemJnlTemplateFilter: Text;
        Physical_Inventory_Count_SheetCaptionLbl: Label 'Physical Inventory Count Sheet';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Shelf_Bin_No_CaptionLbl: Label 'Shelf/Bin No.';
        Unit_of_MeasureCaptionLbl: Label 'Unit of Measure';
        EmptyStringCaptionLbl: Label 'Physical Count';
}

