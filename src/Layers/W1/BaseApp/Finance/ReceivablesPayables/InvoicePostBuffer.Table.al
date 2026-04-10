#if not CLEANSCHEMA26
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Posting;
using Microsoft.Foundation.Enums;
using Microsoft.Projects.Project.Job;

/// <summary>
/// Buffer table for accumulating invoice posting line data before posting operations.
/// Stores temporary line information for invoice creation and G/L posting with comprehensive VAT, dimension, and fixed asset support.
/// </summary>
table 49 "Invoice Post. Buffer"
{
    Caption = 'Invoice Post. Buffer';
    ReplicateData = false;
#pragma warning disable AS0074
    TableType = Temporary;
    ObsoleteReason = 'This table will be replaced by table Invoice Posting Buffer in new Invoice Posting implementation.';
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';
#pragma warning restore AS0074
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Type of invoice posting line for categorization and processing logic.
        /// </summary>
        field(1; Type; Enum "Invoice Posting Line Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// G/L account number for posting the invoice line amount.
        /// </summary>
        field(2; "G/L Account"; Code[20])
        {
            Caption = 'G/L Account';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// Global dimension 1 code for analytical reporting and posting allocation.
        /// </summary>
        field(4; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        /// <summary>
        /// Global dimension 2 code for analytical reporting and posting allocation.
        /// </summary>
        field(5; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        /// <summary>
        /// Project number for project-related invoice line tracking and allocation.
        /// </summary>
        field(6; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            DataClassification = SystemMetadata;
            TableRelation = Job;
        }
        /// <summary>
        /// Invoice line amount in local currency for posting.
        /// </summary>
        field(7; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT amount calculated for the invoice line.
        /// </summary>
        field(8; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'VAT Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// General business posting group for posting and VAT determination.
        /// </summary>
        field(10; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// General product posting group for posting and VAT determination.
        /// </summary>
        field(11; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Product Posting Group";
        }
        /// <summary>
        /// VAT calculation type used for tax calculation on the invoice line.
        /// </summary>
        field(12; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT base amount for tax calculation on the invoice line.
        /// </summary>
        field(14; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates if the entry was created automatically by the system.
        /// </summary>
        field(17; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Tax area code for sales tax calculation.
        /// </summary>
        field(18; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates if the line is subject to sales tax.
        /// </summary>
        field(19; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Tax group code for sales tax calculation.
        /// </summary>
        field(20; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Quantity associated with the invoice line for unit-based calculations.
        /// </summary>
        field(21; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 1 : 5;
        }
        /// <summary>
        /// Indicates if use tax calculation applies to the line.
        /// </summary>
        field(22; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT business posting group for VAT calculation.
        /// </summary>
        field(23; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// VAT product posting group for VAT calculation.
        /// </summary>
        field(24; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// Invoice line amount in additional reporting currency.
        /// </summary>
        field(25; "Amount (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount (ACY)';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT amount in additional reporting currency.
        /// </summary>
        field(26; "VAT Amount (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Amount (ACY)';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT base amount in additional reporting currency.
        /// </summary>
        field(29; "VAT Base Amount (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Base Amount (ACY)';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT difference amount for manual VAT adjustments.
        /// </summary>
        field(31; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// VAT percentage rate for tax calculation.
        /// </summary>
        field(32; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            DataClassification = SystemMetadata;
            DecimalPlaces = 1 : 1;
        }
        /// <summary>
        /// VAT base amount before payment discount application.
        /// </summary>
        field(35; "VAT Base Before Pmt. Disc."; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'VAT Base Before Pmt. Disc.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Description text for the invoice posting entry.
        /// </summary>
        field(215; "Entry Description"; Text[100])
        {
            Caption = 'Entry Description';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Dimension set ID for multi-dimensional analysis and reporting.
        /// </summary>
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        /// <summary>
        /// Additional identifier for grouping related invoice lines during posting.
        /// </summary>
        field(1000; "Additional Grouping Identifier"; Code[20])
        {
            Caption = 'Additional Grouping Identifier';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Deferral template code for revenue or expense deferral processing.
        /// </summary>
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            DataClassification = SystemMetadata;
            TableRelation = "Deferral Template"."Deferral Code";
        }
        /// <summary>
        /// Deferral line number for linking to specific deferral schedule entries.
        /// </summary>
        field(1701; "Deferral Line No."; Integer)
        {
            Caption = 'Deferral Line No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Fixed asset posting date for asset-related transaction processing.
        /// </summary>
        field(5600; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Fixed asset posting type determining the nature of the FA transaction.
        /// </summary>
        field(5601; "FA Posting Type"; Enum "Purchase FA Posting Type")
        {
            Caption = 'FA Posting Type';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Depreciation book code for fixed asset depreciation calculations and posting.
        /// </summary>
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            DataClassification = SystemMetadata;
            TableRelation = "Depreciation Book";
        }
        /// <summary>
        /// Salvage value amount for fixed asset depreciation calculations.
        /// </summary>
        field(5603; "Salvage Value"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Salvage Value';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Calculates depreciation until the fixed asset posting date.
        /// </summary>
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            Caption = 'Depr. until FA Posting Date';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Depreciates acquisition cost for fixed asset transactions.
        /// </summary>
        field(5606; "Depr. Acquisition Cost"; Boolean)
        {
            Caption = 'Depr. Acquisition Cost';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Maintenance code for fixed asset maintenance transactions.
        /// </summary>
        field(5609; "Maintenance Code"; Code[10])
        {
            Caption = 'Maintenance Code';
            DataClassification = SystemMetadata;
            TableRelation = Maintenance;
        }
        /// <summary>
        /// Insurance number for fixed asset insurance coverage tracking.
        /// </summary>
        field(5610; "Insurance No."; Code[20])
        {
            Caption = 'Insurance No.';
            DataClassification = SystemMetadata;
            TableRelation = Insurance;
        }
        /// <summary>
        /// Budgeted fixed asset number for budget tracking and analysis.
        /// </summary>
        field(5611; "Budgeted FA No."; Code[20])
        {
            Caption = 'Budgeted FA No.';
            DataClassification = SystemMetadata;
            TableRelation = "Fixed Asset";
        }
        /// <summary>
        /// Depreciation book for creating duplicate fixed asset entries.
        /// </summary>
        field(5612; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            DataClassification = SystemMetadata;
            TableRelation = "Depreciation Book";
        }
        /// <summary>
        /// Uses duplication list for creating multiple fixed asset ledger entries.
        /// </summary>
        field(5613; "Use Duplication List"; Boolean)
        {
            Caption = 'Use Duplication List';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Line number for fixed asset transactions in document processing.
        /// </summary>
        field(5614; "Fixed Asset Line No."; Integer)
        {
            Caption = 'Fixed Asset Line No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Non-deductible VAT percentage for partial VAT deduction calculations.
        /// </summary>
        field(6200; "Non-Deductible VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Non-Deductible VAT %';
            DecimalPlaces = 0 : 5;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Non-deductible VAT base amount for partial VAT deduction calculations.
        /// </summary>
        field(6201; "Non-Deductible VAT Base"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Base';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Non-deductible VAT amount for partial VAT deduction calculations.
        /// </summary>
        field(6202; "Non-Deductible VAT Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Amount';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Non-deductible VAT base amount in additional reporting currency.
        /// </summary>
        field(6203; "Non-Deductible VAT Base ACY"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Base ACY';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Non-deductible VAT amount in additional reporting currency.
        /// </summary>
        field(6204; "Non-Deductible VAT Amount ACY"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Amount ACY';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Non-deductible VAT difference amount for variance tracking.
        /// </summary>
        field(6205; "Non-Deductible VAT Diff."; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Difference';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; Type, "G/L Account", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Area Code", "Tax Group Code", "Tax Liable", "Use Tax", "Dimension Set ID", "Job No.", "Fixed Asset Line No.", "Deferral Code", "Additional Grouping Identifier")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    protected var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralLedgerSetupRead: Boolean;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    begin
        if not GeneralLedgerSetupRead then begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetupRead := true;
        end;
        exit(GeneralLedgerSetup."Additional Reporting Currency")
    end;


#pragma warning restore AS0072
}
#endif
