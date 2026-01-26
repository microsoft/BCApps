// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

table 12210 "Withholding Tax Line"
{
    Caption = 'Withholding Tax Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Withholding Tax Entry No."; Integer)
        {
            Caption = 'Withholding Tax Entry No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Base - Excluded Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Base - Excluded Amount';
            NotBlank = true;
        }
        field(4; "Non-Taxable Income Type"; Enum "Non-Taxable Income Type")
        {
            Caption = 'Non-Taxable Income Type';
            NotBlank = true;
        }
    }

    keys
    {
        key(Key1; "Withholding Tax Entry No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure GetAmountForEntryNo(EntryNo: Integer): Decimal
    begin
        SetRange("Withholding Tax Entry No.", EntryNo);
        SetFilter("Non-Taxable Income Type", '<>%1', "Non-Taxable Income Type"::" ");
        CalcSums("Base - Excluded Amount");
        SetRange("Non-Taxable Income Type");
        exit("Base - Excluded Amount");
    end;

    procedure GetNonTaxableIncomeTypeNumber(): Text
    begin
        exit(Rec."Non-Taxable Income Type".Names.Get(Rec."Non-Taxable Income Type".AsInteger() + 1));
    end;

}

