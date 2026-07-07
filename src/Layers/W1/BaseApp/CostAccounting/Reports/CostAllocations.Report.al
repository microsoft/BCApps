// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.costaccounting.Reports;

using Microsoft.CostAccounting.Allocation;

report 1129 "Cost Allocations"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CostAccounting/Reports/CostAllocations.rdlc';
    ApplicationArea = CostAccounting;
    Caption = 'Cost Allocations';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Cost Allocation Source"; "Cost Allocation Source")
        {
            RequestFilterFields = ID, Level, "Valid From", "Valid To", Variant;
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column("Filter"; Text000 + GetFilters)
            {
            }
            column(Level_CostAllocSource; Level)
            {
                IncludeCaption = true;
            }
            column(ValidFrom_CostAllocSource; Format("Valid From"))
            {
            }
            column(ValidTo_CostAllocSource; Format("Valid To"))
            {
            }
            column(SourceID_CostAllocSource; ID)
            {
                IncludeCaption = true;
            }
            column(CostTypeRange_CostAllocSource; "Cost Type Range")
            {
                IncludeCaption = true;
            }
            column(CrToCostType_CostAllocSource; "Credit to Cost Type")
            {
                IncludeCaption = true;
            }
            column(TotalShare_CostAllocSource; "Total Share")
            {
                IncludeCaption = true;
            }
            column(Blocked_CostAllocSource; Format(Blocked))
            {
            }
            column(LastDateModified_CostAllocSource; "Last Date Modified")
            {
                IncludeCaption = true;
            }
            column(CostObjCode_CostAllocSource; "Cost Object Code")
            {
                IncludeCaption = true;
            }
            column(CostCenterCode_CostAllocSource; "Cost Center Code")
            {
                IncludeCaption = true;
            }
            column(AllocationsCaption; AllocationsCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(CostAllocationSourceValidFromCaption; CostAllocationSourceValidFromCaptionLbl)
            {
            }
            column(SourceCaption; SourceCaptionLbl)
            {
            }
            column(BlockedCaption; BlockedCaptionLbl)
            {
            }
            dataitem("Cost Allocation Target"; "Cost Allocation Target")
            {
                DataItemLink = ID = field(ID);
                DataItemTableView = sorting(ID, "Line No.");
                RequestFilterFields = "Target Cost Type", "Target Cost Center", "Target Cost Object", "Allocation Target Type", "Share Updated on";
                column(TargetCostType_CostAllocTarget; "Target Cost Type")
                {
                    IncludeCaption = true;
                }
                column(TargetCostCenter_CostAllocTarget; "Target Cost Center")
                {
                    IncludeCaption = true;
                }
                column(TargetCostObject_CostAllocTarget; "Target Cost Object")
                {
                    IncludeCaption = true;
                }
                column(AllocType_CostAllocTarget; "Allocation Target Type")
                {
                    IncludeCaption = true;
                }
                column(PercentperShare_CostAllocTarget; "Percent per Share")
                {
                    IncludeCaption = true;
                }
                column(AmtperShare_CostAllocTarget; "Amount per Share")
                {
                    IncludeCaption = true;
                }
                column(Base_CostAllocTarget; Base)
                {
                    IncludeCaption = true;
                }
                column(CostCenterFilter_CostAllocTarget; "Cost Center Filter")
                {
                    IncludeCaption = true;
                }
                column(CostObjFilter_CostAllocTarget; "Cost Object Filter")
                {
                    IncludeCaption = true;
                }
                column(DateFilterCode_CostAllocTarget; "Date Filter Code")
                {
                    IncludeCaption = true;
                }
                column(GroupFilter_CostAllocTarget; "Group Filter")
                {
                    IncludeCaption = true;
                }
                column(Share_CostAllocTarget; Share)
                {
                    IncludeCaption = true;
                }
            }

            trigger OnAfterGetRecord()
            var
                CostAllocationTarget: Record "Cost Allocation Target";
            begin
                if GlobalPrintOnlyIfDetail then begin
                    CostAllocationTarget.SetView("Cost Allocation Target".GetView());
                    CostAllocationTarget.SetRange(ID, ID);

                    if CostAllocationTarget.IsEmpty() then
                        CurrReport.Skip();
                end;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Cost Allocations';
        AboutText = 'The **Cost Allocations** report shows how costs are distributed across cost centers, cost objects, or dimensions using predefined allocation rules. Use it for analyzing how expenses are assigned across different areas to support cost control and ensure alignment with allocation strategies.';

        layout
        {
            area(content)
            {
                field(SkipalocSourceswithoutaloctgt; GlobalPrintOnlyIfDetail)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Skip allocation sources without allocation targets in the filter.';
                    ToolTip = 'Specifies that you want to skip allocation sources without allocation targets in the filter.';
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

    var
#pragma warning disable AA0074
        Text000: Label 'Filter: ';
#pragma warning restore AA0074
        GlobalPrintOnlyIfDetail: Boolean;
        AllocationsCaptionLbl: Label 'Cost Allocations';
        PageCaptionLbl: Label 'Page';
        CostAllocationSourceValidFromCaptionLbl: Label 'Valid From';
        SourceCaptionLbl: Label 'Source';
        BlockedCaptionLbl: Label 'Blocked';

    procedure InitializeRequest(var CostAllocationSource: Record "Cost Allocation Source"; var CostAllocationTarget: Record "Cost Allocation Target"; PrintOnlyIfDetailNew: Boolean)
    begin
        "Cost Allocation Source".CopyFilters(CostAllocationSource);
        "Cost Allocation Target".CopyFilters(CostAllocationTarget);
        GlobalPrintOnlyIfDetail := PrintOnlyIfDetailNew;
    end;
}

