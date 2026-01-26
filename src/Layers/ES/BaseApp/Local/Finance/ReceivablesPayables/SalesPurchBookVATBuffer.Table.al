// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;

table 10704 "Sales/Purch. Book VAT Buffer"
{
    Caption = 'Sales/Purch. Book VAT Buffer';
    LookupPageID = "VAT Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DataClassification = SystemMetadata;
        }
        field(2; "EC %"; Decimal)
        {
            Caption = 'EC %';
            DataClassification = SystemMetadata;
        }
        field(3; Base; Decimal)
        {
            Caption = 'Base';
            DataClassification = SystemMetadata;
        }
        field(4; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(5; "EC Amount"; Decimal)
        {
            Caption = 'EC Amount';
            DataClassification = SystemMetadata;
        }
        field(6; "Non-Deductible VAT %"; Decimal)
        {
            Caption = 'Non-Deductible VAT %';
            DataClassification = SystemMetadata;
        }
        field(7; "Non-Deductible VAT Base"; Decimal)
        {
            Caption = 'Non-Deductible VAT Base';
            DataClassification = SystemMetadata;
        }
        field(8; "Non-Deductible VAT Amount"; Decimal)
        {
            Caption = 'Non-Deductible VAT Amount';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "VAT %", "EC %")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        VATPostingSetup.Get("EC %", Base);
        "VAT %" := VATPostingSetup."VAT %";
        "EC %" := VATPostingSetup."EC %";
    end;

    var
        VATPostingSetup: Record "VAT Posting Setup";
}

