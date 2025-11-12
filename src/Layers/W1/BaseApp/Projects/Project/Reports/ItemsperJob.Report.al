// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using System.Utilities;

report 1013 "Items per Job"
{
    AdditionalSearchTerms = 'Items per Job';
    DefaultLayout = RDLC;
    RDLCLayout = './Projects/Project/Reports/ItemsperJob.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Items per Project';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Job; Job)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Posting Date Filter";
            column(TodayFormatted; Format(Today))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(JobTableCaptionJobFilter; TableCaption + ': ' + JobFilter)
            {
            }
            column(JobFilter; JobFilter)
            {
            }
            column(ItemTableCaptItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(No_Job; "No.")
            {
            }
            column(Description_Job; Description)
            {
            }
            column(Amount3_JobBuffer; TempJobBuffer."Amount 3")
            {
            }
            column(Amount1_JobBuffer; TempJobBuffer."Amount 2")
            {
            }
            column(ItemsperJobCaption; ItemsperJobCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(AllamountsareinLCYCaption; AllamountsareinLCYCaptionLbl)
            {
            }
            column(JobBufferLineAmountCaption; JobBufferLineAmountCaptionLbl)
            {
            }
            column(JobBufferTotalCostCaption; JobBufferTotalCostCaptionLbl)
            {
            }
            column(JobBuffeUOMCaption; JobBuffeUOMCaptionLbl)
            {
            }
            column(JobBufferQuantityCaption; JobBufferQuantityCaptionLbl)
            {
            }
            column(JobBufferDescriptionCaption; JobBufferDescriptionCaptionLbl)
            {
            }
            column(ItemNoCaption; ItemNoCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(ActNo1_JobBuffer; TempJobBuffer."Account No. 1")
                {
                }
                column(Description_JobBuffer; TempJobBuffer.Description)
                {
                }
                column(ActNo2_JobBuffer; TempJobBuffer."Account No. 2")
                {
                }
                column(Amount2_JobBuffer; TempJobBuffer."Amount 1")
                {
                    DecimalPlaces = 0 : 5;
                }
                column(TableCaptionJobNo; TotalForTxt + ' ' + Job.TableCaption + ' ' + Job."No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then begin
                        if not TempJobBuffer.Find('-') then
                            CurrReport.Break();
                    end else
                        if TempJobBuffer.Next() = 0 then
                            CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TempJobBuffer2.ReportJobItem(Job, Item, TempJobBuffer);
            end;
        }
        dataitem(Item2; Item)
        {
            RequestFilterFields = "No.";

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Items per Project';
        AboutText = 'Get an overview of the items you use in your project.';

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
        Item.CopyFilters(Item2);
        JobFilter := Job.GetFilters();
        ItemFilter := Item.GetFilters();
    end;

    var
        Item: Record Item;
        JobFilter: Text;
        ItemFilter: Text;
        ItemsperJobCaptionLbl: Label 'Items per Project';
        CurrReportPageNoCaptionLbl: Label 'Page';
        AllamountsareinLCYCaptionLbl: Label 'All amounts are in LCY';
        JobBufferLineAmountCaptionLbl: Label 'Line Amount';
        JobBufferTotalCostCaptionLbl: Label 'Total Cost';
        JobBuffeUOMCaptionLbl: Label 'Unit of Measure';
        JobBufferQuantityCaptionLbl: Label 'Quantity';
        JobBufferDescriptionCaptionLbl: Label 'Description';
        ItemNoCaptionLbl: Label 'Item No.';
        TotalCaptionLbl: Label 'Total';

        TotalForTxt: Label 'Total for';

    protected var
        TempJobBuffer2: Record "Job Buffer" temporary;
        TempJobBuffer: Record "Job Buffer" temporary;
}

