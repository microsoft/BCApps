// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Projects.Resources.Ledger;
using System.Utilities;

report 1107 "Resource - Cost Breakdown"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Projects/Resources/Reports/ResourceCostBreakdown.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Resource - Cost Breakdown';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Resource; Resource)
        {
            RequestFilterFields = "No.";
            column(No_Resource; "No.")
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(CompanyName; COMPANYPROPERTY.DisplayName())
                {
                }
                column(ResTableCaptResFilter; Resource.TableCaption + ': ' + ResFilter)
                {
                }
                column(ResFilter; ResFilter)
                {
                }
                column(ResLedEntrytableCaptFilt; "Res. Ledger Entry".TableCaption + ': ' + ResLedgEntryFilter)
                {
                }
                column(ResLedgerEntryFilter; ResLedgEntryFilter)
                {
                }
                column(ResCostBreakdownCaption; ResCostBreakdownCaptionLbl)
                {
                }
                column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
                {
                }
                dataitem("Res. Ledger Entry"; "Res. Ledger Entry")
                {
                    DataItemLink = "Resource No." = field("No.");
                    DataItemLinkReference = Resource;
                    DataItemTableView = sorting("Entry Type", Chargeable, "Unit of Measure Code", "Resource No.", "Posting Date") where("Entry Type" = const(Usage));
                    RequestFilterFields = "Unit of Measure Code", "Posting Date";
                    column(Name_Resource; Resource.Name)
                    {
                    }
                    column(No1_Resource; Resource."No.")
                    {
                    }
                    column(UmoCost_ResLedgEntry; "Unit of Measure Code")
                    {
                        IncludeCaption = true;
                    }
                    column(Desc_ResLedgEntry; Description)
                    {
                        IncludeCaption = true;
                    }
                    column(WorkTypeCode_ResLedgEntry; "Work Type Code")
                    {
                        IncludeCaption = true;
                    }
                    column(Qty_ResLedgEntry; Quantity)
                    {
                        IncludeCaption = true;
                    }
                    column(DirectUnitCost_ResLedgEntry; "Direct Unit Cost")
                    {
                        IncludeCaption = true;
                    }
                    column(TotalDirectCost; TotalDirectCost)
                    {
                        AutoFormatType = 1;
                    }
                    column(UnitCost_ResLedgEntry; "Unit Cost")
                    {
                        IncludeCaption = true;
                    }
                    column(TotalCost_ResLedgEntry; "Total Cost")
                    {
                        IncludeCaption = true;
                    }
                    column(Chargeable_ResLedgEntry; Chargeable)
                    {
                    }
                    column(TotalDirectCostCaption; TotalDirectCostCaptionLbl)
                    {
                    }
                    column(TotalCaption; TotalCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TotalDirectCost := Quantity * "Direct Unit Cost";
                    end;

                    trigger OnPreDataItem()
                    begin
                        Clear(TotalDirectCost);
                        Clear(Quantity);
                    end;
                }
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Resource - Cost Breakdown';
        AboutText = 'View the direct unit costs and the total direct costs for each resource. Only usage postings are considered in this report. Resource usage can be posted in the resource journal or the project journal.';
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
        ResFilter := Resource.GetFilters();
        ResLedgEntryFilter := "Res. Ledger Entry".GetFilters();
    end;

    var
        TotalDirectCost: Decimal;
        ResFilter: Text;
        ResLedgEntryFilter: Text;
        ResCostBreakdownCaptionLbl: Label 'Resource - Cost Breakdown';
        CurrReportPageNoCaptionLbl: Label 'Page';
        TotalDirectCostCaptionLbl: Label 'Total Direct Cost';
        TotalCaptionLbl: Label 'Total';
}

