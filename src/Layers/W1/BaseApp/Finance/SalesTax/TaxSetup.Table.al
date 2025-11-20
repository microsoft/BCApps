// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.GeneralLedger.Account;

table 326 "Tax Setup"
{
    Caption = 'Tax Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "Tax Setup";
    LookupPageID = "Tax Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Auto. Create Tax Details"; Boolean)
        {
            Caption = 'Auto. Create Tax Details';
        }
        field(3; "Non-Taxable Tax Group Code"; Code[20])
        {
            Caption = 'Non-Taxable Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(6; "Tax Account (Sales)"; Code[20])
        {
            Caption = 'Tax Account (Sales)';
            TableRelation = "G/L Account";
        }
        field(7; "Tax Account (Purchases)"; Code[20])
        {
            Caption = 'Tax Account (Purchases)';
            TableRelation = "G/L Account";
        }
        field(8; "Unreal. Tax Acc. (Sales)"; Code[20])
        {
            Caption = 'Unreal. Tax Acc. (Sales)';
            TableRelation = "G/L Account";
        }
        field(9; "Unreal. Tax Acc. (Purchases)"; Code[20])
        {
            Caption = 'Unreal. Tax Acc. (Purchases)';
            TableRelation = "G/L Account";
        }
        field(10; "Reverse Charge (Purchases)"; Code[20])
        {
            Caption = 'Reverse Charge (Purchases)';
            TableRelation = "G/L Account";
        }
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

