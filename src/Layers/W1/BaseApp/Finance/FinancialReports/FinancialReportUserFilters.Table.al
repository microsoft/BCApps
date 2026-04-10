// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Foundation.Enums;
using System.Security.AccessControl;

/// <summary>
/// Stores user-specific filter preferences for financial reports.
/// Enables personalized report viewing with saved filter combinations and display options.
/// </summary>
table 89 "Financial Report User Filters"
{
    Caption = 'Financial Report User Filters';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// User identifier linking filter preferences to specific user account.
        /// </summary>
        field(1; "User ID"; Code[50])
        {
            TableRelation = User;
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        /// <summary>
        /// Financial report name for which filters are stored.
        /// </summary>
        field(2; "Financial Report Name"; Code[10])
        {
            TableRelation = "Financial Report";
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Controls whether report displays amounts in additional reporting currency.
        /// </summary>
        field(3; UseAmountsInAddCurrency; Boolean)
        {
            Caption = 'Use Amounts in Additional Currency';
            DataClassification = SystemMetadata;
        }
#if not CLEANSCHEMA30
        /// <summary>
        /// Period type for date calculations and report period determination.
        /// </summary>
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
        /// <summary>
        /// Controls whether report shows all lines or only lines with values.
        /// </summary>
        field(5; ShowLinesWithShowNo; Boolean)
        {
            Caption = 'Show All Lines';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Filter text for first dimension applied to financial report data.
        /// </summary>
        field(6; Dim1Filter; Text[2048])
        {
            Caption = 'Dimension 1 Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Filter text for second dimension applied to financial report data.
        /// </summary>
        field(7; Dim2Filter; Text[2048])
        {
            Caption = 'Dimension 2 Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Filter text for third dimension applied to financial report data.
        /// </summary>
        field(8; Dim3Filter; Text[2048])
        {
            Caption = 'Dimension 3 Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Filter text for fourth dimension applied to financial report data.
        /// </summary>
        field(9; Dim4Filter; Text[2048])
        {
            Caption = 'Dimension 4 Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Cost center filter for cost accounting data in financial reports.
        /// </summary>
        field(10; CostCenterFilter; Text[2048])
        {
            Caption = 'Cost Center Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Cost object filter for cost accounting data in financial reports.
        /// </summary>
        field(11; CostObjectFilter; Text[2048])
        {
            Caption = 'Cost Object Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Cash flow filter for cash flow account data in financial reports.
        /// </summary>
        field(12; CashFlowFilter; Text[2048])
        {
            Caption = 'Cash Flow Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// General ledger budget filter for budget data in financial reports.
        /// </summary>
        field(13; GLBudgetFilter; Text[2048])
        {
            Caption = 'G/L Budget Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Cost budget filter for cost budget data in financial reports.
        /// </summary>
        field(14; CostBudgetFilter; Text[2048])
        {
            Caption = 'Cost Budget Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Date filter applied to transactions and entries in financial reports.
        /// </summary>
        field(15; DateFilter; Text[2048])
        {
            Caption = 'Date Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Excel template code for financial report export formatting.
        /// </summary>
        field(16; "Excel Template Code"; Code[50])
        {
            Caption = 'Excel Template Code';
            DataClassification = SystemMetadata;
            TableRelation = "Fin. Report Excel Template"."Code" where("Financial Report Name" = field("Financial Report Name"));
        }
#if not CLEANSCHEMA30
        /// <summary>
        /// Format preference for displaying negative amounts in financial reports.
        /// </summary>
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
        /// <summary>
        /// Row definition code linked to financial report structure.
        /// </summary>
        field(51; "Row Definition"; Code[10])
        {
            Caption = 'Row Definition';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Column definition code linked to financial report structure.
        /// </summary>
        field(52; "Column Definition"; Code[10])
        {
            Caption = 'Column Definition';
            DataClassification = SystemMetadata;
        }
        field(60; FinReportDimPerspectiveName; Code[10])
        {
            Caption = 'Dimension Perspective';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Perspective Name";
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
