// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Foundation.Enums;
using System.Security.AccessControl;

table 89 "Financial Report User Filters"
{
    Caption = 'Financial Report User Filters';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            TableRelation = User;
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(2; "Financial Report Name"; Code[10])
        {
            TableRelation = "Financial Report";
            DataClassification = SystemMetadata;
        }
        field(3; UseAmountsInAddCurrency; Boolean)
        {
            Caption = 'Use Amounts in Additional Currency';
            DataClassification = SystemMetadata;
        }
#if not CLEANSCHEMA30
        field(4; PeriodType; Enum "Analysis Period Type")
        {
            Caption = 'Period Type';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'This field has been replaced by the PeriodTypeDefault field.';
#if not CLEAN28
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#endif
        }
#endif
        field(5; ShowLinesWithShowNo; Boolean)
        {
            Caption = 'Show All Lines';
            DataClassification = SystemMetadata;
        }
        field(6; Dim1Filter; Text[2048])
        {
            Caption = 'Dimension 1 Filter';
            DataClassification = SystemMetadata;
        }
        field(7; Dim2Filter; Text[2048])
        {
            Caption = 'Dimension 2 Filter';
            DataClassification = SystemMetadata;
        }
        field(8; Dim3Filter; Text[2048])
        {
            Caption = 'Dimension 3 Filter';
            DataClassification = SystemMetadata;
        }
        field(9; Dim4Filter; Text[2048])
        {
            Caption = 'Dimension 4 Filter';
            DataClassification = SystemMetadata;
        }
        field(10; CostCenterFilter; Text[2048])
        {
            Caption = 'Cost Center Filter';
            DataClassification = SystemMetadata;
        }
        field(11; CostObjectFilter; Text[2048])
        {
            Caption = 'Cost Object Filter';
            DataClassification = SystemMetadata;
        }
        field(12; CashFlowFilter; Text[2048])
        {
            Caption = 'Cash Flow Filter';
            DataClassification = SystemMetadata;
        }
        field(13; GLBudgetFilter; Text[2048])
        {
            Caption = 'G/L Budget Filter';
            DataClassification = SystemMetadata;
        }
        field(14; CostBudgetFilter; Text[2048])
        {
            Caption = 'Cost Budget Filter';
            DataClassification = SystemMetadata;
        }
        field(15; DateFilter; Text[2048])
        {
            Caption = 'Date Filter';
            DataClassification = SystemMetadata;
        }
        field(16; "Excel Template Code"; Code[50])
        {
            Caption = 'Excel Template Code';
            DataClassification = SystemMetadata;
            TableRelation = "Fin. Report Excel Template"."Code" where("Financial Report Name" = field("Financial Report Name"));
        }
#if not CLEANSCHEMA30
        field(17; NegativeAmountFormat; Enum "Analysis Negative Format")
        {
            Caption = 'Negative Amount Format';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'This field has been replaced by the NegativeAmountFormatDefault field.';
#if not CLEAN28
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#endif
        }
#endif
        field(18; PeriodTypeDefault; Enum "Financial Report Period Type")
        {
            Caption = 'Period Type';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies by which period amounts are displayed.';
        }
        field(19; NegativeAmountFormatDefault; Enum "Fin. Report Negative Format")
        {
            Caption = 'Negative Amount Format';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the default negative amount format for this financial report.';
        }
        field(51; "Row Definition"; Code[10])
        {
            Caption = 'Row Definition';
            DataClassification = SystemMetadata;
        }
        field(52; "Column Definition"; Code[10])
        {
            Caption = 'Column Definition';
            DataClassification = SystemMetadata;
        }
        field(60; FinReportSheetDefName; Code[10])
        {
            Caption = 'Sheet Definition';
            DataClassification = SystemMetadata;
            TableRelation = "Sheet Definition Name";
        }
    }

    keys
    {
        key(Key1; "User ID", "Financial Report Name")
        {
            Clustered = true;
        }
    }
}
