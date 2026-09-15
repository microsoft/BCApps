// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;

report 10195 "Cost Breakdown"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Projects/Resources/Reports/CostBreakdown.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Cost Breakdown';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Resource; Resource)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", Type, "Unit of Measure Filter", "Date Filter";
            column(Resource_No_; "No.")
            {
            }
            column(Resource_Unit_of_Measure_Filter; "Unit of Measure Filter")
            {
            }
            column(Resource_Date_Filter; "Date Filter")
            {
            }
            dataitem("Res. Ledger Entry"; "Res. Ledger Entry")
            {
                DataItemLink = "Resource No." = field("No."), "Unit of Measure Code" = field("Unit of Measure Filter"), "Posting Date" = field("Date Filter");
                DataItemTableView = sorting("Entry Type", Chargeable, "Unit of Measure Code", "Resource No.", "Posting Date") where("Entry Type" = const(Usage));
                column(Cost_Breakdown_; 'Cost Breakdown')
                {
                }
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(TIME; Time)
                {
                }
                column(CompanyInformation_Name; CompanyInformation.Name)
                {
                }
                column(USERID; UserId)
                {
                }
                column(ResourceFilter; ResourceFilter)
                {
                }
                column(FIELDCAPTION__Resource_No______________Resource_No__; FieldCaption("Resource No.") + ': ' + "Resource No.")
                {
                }
                column(Resource_TABLECAPTION_________Resource_FIELDCAPTION_Name___________Resource_Name; Resource.TableCaption + ' ' + Resource.FieldCaption(Name) + ': ' + Resource.Name)
                {
                }
                column(Resource_TABLECAPTION__________ResourceFilter; Resource.TableCaption + ': ' + ResourceFilter)
                {
                }
                column(FIELDCAPTION__Unit_of_Measure_Code_____________Unit_of_Measure_Code_; FieldCaption("Unit of Measure Code") + ': ' + "Unit of Measure Code")
                {
                }
                column(Res__Ledger_Entry__Posting_Date_; "Posting Date")
                {
                }
                column(Res__Ledger_Entry_Description; Description)
                {
                }
                column(Res__Ledger_Entry__Work_Type_Code_; "Work Type Code")
                {
                }
                column(Res__Ledger_Entry_Quantity; Quantity)
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Res__Ledger_Entry__Direct_Unit_Cost_; "Direct Unit Cost")
                {
                }
                column(TotalDirectCost; TotalDirectCost)
                {
                }
                column(Res_Ledger_Entry__Chargeable; "Res. Ledger Entry".Chargeable)
                {
                }
                column(Total_for_____FIELDCAPTION__Unit_of_Measure_Code_____________Unit_of_Measure_Code_; 'Total for ' + FieldCaption("Unit of Measure Code") + ': ' + "Unit of Measure Code")
                {
                }
                column(Res__Ledger_Entry_Quantity_Control18; Quantity)
                {
                    DecimalPlaces = 2 : 5;
                }
                column(TotalDirectCost_Control19; TotalDirectCost)
                {
                }
                column(Res__Ledger_Entry_Quantity_Control21; Quantity)
                {
                    DecimalPlaces = 2 : 5;
                }
                column(TotalDirectCost_Control22; TotalDirectCost)
                {
                }
                column(Res__Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Res__Ledger_Entry_Unit_of_Measure_Code; "Unit of Measure Code")
                {
                }
                column(Res__Ledger_Entry_Resource_No_; "Resource No.")
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Res__Ledger_Entry__Posting_Date_Caption; FieldCaption("Posting Date"))
                {
                }
                column(Res__Ledger_Entry_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(Res__Ledger_Entry__Work_Type_Code_Caption; FieldCaption("Work Type Code"))
                {
                }
                column(Res__Ledger_Entry_QuantityCaption; FieldCaption(Quantity))
                {
                }
                column(Res__Ledger_Entry__Direct_Unit_Cost_Caption; FieldCaption("Direct Unit Cost"))
                {
                }
                column(TotalDirectCostCaption; TotalDirectCostCaptionLbl)
                {
                }
                column(Report_TotalCaption; Report_TotalCaptionLbl)
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
        ResourceFilter := Resource.GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        ResourceFilter: Text;
        TotalDirectCost: Decimal;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        TotalDirectCostCaptionLbl: Label 'Total Direct Cost';
        Report_TotalCaptionLbl: Label 'Report Total';
}

