// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Stores sales tax configuration and default account mappings for tax calculations.
/// Provides system-wide tax setup including automatic tax detail creation and account assignment.
/// </summary>
table 326 "Tax Setup"
{
    Caption = 'Tax Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "Tax Setup";
    LookupPageID = "Tax Setup";

    fields
    {
        /// <summary>
        /// Primary key field for the tax setup record.
        /// </summary>
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        /// <summary>
        /// Controls whether tax details are automatically created when new tax jurisdictions are defined.
        /// </summary>
        field(2; "Auto. Create Tax Details"; Boolean)
        {
            Caption = 'Auto. Create Tax Details';
            ToolTip = 'Specifies that the required tax information is created automatically.';
        }
        /// <summary>
        /// Default tax group code for non-taxable items and transactions.
        /// </summary>
        field(3; "Non-Taxable Tax Group Code"; Code[20])
        {
            Caption = 'Non-Taxable Tax Group Code';
            ToolTip = 'Specifies the group code for non-taxable sales.';
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// G/L account for posting sales tax amounts on sales transactions.
        /// </summary>
        field(6; "Tax Account (Sales)"; Code[20])
        {
            Caption = 'Tax Account (Sales)';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// G/L account for posting sales tax amounts on purchase transactions.
        /// </summary>
        field(7; "Tax Account (Purchases)"; Code[20])
        {
            Caption = 'Tax Account (Purchases)';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// G/L account for unrealized tax amounts on sales transactions.
        /// </summary>
        field(8; "Unreal. Tax Acc. (Sales)"; Code[20])
        {
            Caption = 'Unreal. Tax Acc. (Sales)';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// G/L account for unrealized tax amounts on purchase transactions.
        /// </summary>
        field(9; "Unreal. Tax Acc. (Purchases)"; Code[20])
        {
            Caption = 'Unreal. Tax Acc. (Purchases)';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// G/L account for reverse charge amounts on purchase transactions.
        /// </summary>
        field(10; "Reverse Charge (Purchases)"; Code[20])
        {
            Caption = 'Reverse Charge (Purchases)';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// G/L account for unrealized reverse charge amounts on purchase transactions.
        /// </summary>
        field(11; "Unreal. Rev. Charge (Purch.)"; Code[20])
        {
            Caption = 'Unreal. Rev. Charge (Purch.)';
            TableRelation = "G/L Account";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

