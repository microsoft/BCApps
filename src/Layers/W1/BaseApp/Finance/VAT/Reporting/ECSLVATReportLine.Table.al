// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Stores European Community Sales List (ECSL) VAT report line data for EU trade reporting.
/// Contains customer VAT registration numbers and supply values for cross-border EU transactions.
/// </summary>
table 362 "ECSL VAT Report Line"
{
    Caption = 'ECSL VAT Report Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Sequential line number for ordering ECSL report lines within a report.
        /// </summary>
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the unique identifier for the line.';
        }
        /// <summary>
        /// ECSL VAT report number that this line belongs to.
        /// </summary>
        field(2; "Report No."; Code[20])
        {
            Caption = 'Report No.';
            ToolTip = 'Specifies the unique identifier for the report.';
        }
        /// <summary>
        /// EU country code for the customer's VAT registration location.
        /// </summary>
        field(3; "Country Code"; Code[10])
        {
            Caption = 'Country Code';
            ToolTip = 'Specifies country code of the customer used for the line calculation.';
        }
        /// <summary>
        /// Customer's VAT registration number in the destination EU country.
        /// </summary>
        field(4; "Customer VAT Reg. No."; Text[20])
        {
            Caption = 'Customer VAT Reg. No.';
            ToolTip = 'Specifies VAT Registration Number of the customer.';
        }
        /// <summary>
        /// Total value of supplies provided to this customer during the reporting period.
        /// </summary>
        field(5; "Total Value Of Supplies"; Decimal)
        {
            Caption = 'Total Value Of Supplies';
            ToolTip = 'Specifies the total amount of the sold supplies.';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        /// <summary>
        /// Type of EU transaction indicating goods or services and delivery method.
        /// </summary>
        field(6; "Transaction Indicator"; Option)
        {
            Caption = 'Transaction Indicator';
            ToolTip = 'Specifies the transaction number.';
            OptionCaption = 'B2B Goods,,Triangulated Goods,B2B Services';
            OptionMembers = "B2B Goods",,"Triangulated Goods","B2B Services";
        }
    }

    keys
    {
        key(Key1; "Report No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Clears all ECSL report lines and related line relations for the specified VAT report.
    /// Used when regenerating ECSL data or resetting report content.
    /// </summary>
    /// <param name="VATReportHeader">VAT report header containing the ECSL report to clear</param>
    procedure ClearLines(VATReportHeader: Record "VAT Report Header")
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
    begin
        ECSLVATReportLineRelation.SetRange("ECSL Report No.", VATReportHeader."No.");
        ECSLVATReportLineRelation.DeleteAll();
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
        ECSLVATReportLine.DeleteAll();
    end;
}
