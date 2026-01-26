#if not CLEANSCHEMA30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Bank.BankAccount;

table 12135 "Periodic Settlement VAT Entry"
{
    Caption = 'Periodic Settlement VAT Entry';
    DataClassification = CustomerContent;
    ObsoleteReason = 'Adding a new field to the key. Use table 12102 "Periodic Settl. VAT Entry" instead.';
#if not CLEAN27
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '30.0';
#endif

    fields
    {
        field(2; "VAT Period"; Code[10])
        {
            Caption = 'VAT Period';
            NotBlank = true;

            trigger OnValidate()
            begin
                if (StrLen("VAT Period") <> 7) and (StrLen("VAT Period") <> 0) then
                    Error(InvalidVATPeriodErr);
                Evaluate(Month, CopyStr("VAT Period", 6, 2));
                if (Month < 1) or (Month > 12) then
                    Error(InvalidMonthErr);
            end;
        }
        field(3; "VAT Settlement"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Settlement';
        }
        field(4; "Add-Curr. VAT Settlement"; Decimal)
        {
            Caption = 'Add-Curr. VAT Settlement';
        }
        field(5; "Prior Period Input VAT"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Prior Period Input VAT';
        }
        field(6; "Prior Period Output VAT"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Prior Period Output VAT';
        }
        field(7; "Add Curr. Prior Per. Inp. VAT"; Decimal)
        {
            Caption = 'Add Curr. Prior Per. Inp. VAT';
        }
        field(8; "Add Curr. Prior Per. Out VAT"; Decimal)
        {
            Caption = 'Add-Curr. Prior Per. Out VAT';
        }
        field(10; "Paid Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Paid Amount';
        }
        field(11; "Advanced Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Advanced Amount';
        }
        field(12; "Add-Curr. Paid. Amount"; Decimal)
        {
            Caption = 'Add-Curr. Paid. Amount';
        }
        field(13; "Add-Curr. Advanced Amount"; Decimal)
        {
            Caption = 'Add-Curr. Advanced Amount';
        }
        field(20; "Bank Code"; Code[20])
        {
            Caption = 'Bank Code';
            TableRelation = "Bank Account";
        }
        field(21; "Paid Date"; Date)
        {
            Caption = 'Paid Date';
        }
        field(22; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(40; "VAT Period Closed"; Boolean)
        {
            Caption = 'VAT Period Closed';
        }
        field(50; "Prior Year Input VAT"; Decimal)
        {
            Caption = 'Prior Year Input VAT';
        }
        field(51; "Prior Year Output VAT"; Decimal)
        {
            Caption = 'Prior Year Output VAT';
        }
        field(52; "Add Curr.Prior Year Inp. VAT"; Decimal)
        {
            Caption = 'Add Curr.Prior Year Inp. VAT';
        }
        field(53; "Add Curr.Prior Year Out. VAT"; Decimal)
        {
            Caption = 'Add Curr.Prior Year Out. VAT';
        }
        field(60; "Payable VAT Variation"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Payable VAT Variation';
        }
        field(61; "Deductible VAT Variation"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Deductible VAT Variation';
        }
        field(62; "Tax Debit Variation"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Tax Debit Variation';
        }
        field(63; "Tax Credit Variation"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Tax Credit Variation';
        }
        field(64; "Unpaid VAT Previous Periods"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Unpaid VAT Previous Periods';
        }
        field(65; "Tax Debit Variation Interest"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Tax Debit Variation Interest';
        }
        field(66; "Omit VAT Payable Interest"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Omit VAT Payable Interest';
        }
        field(70; "Credit VAT Compensation"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Credit VAT Compensation';
        }
        field(71; "Special Credit"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Special Credit';
        }
    }

    keys
    {
        key(Key1; "VAT Period")
        {
            Clustered = true;
            SumIndexFields = "VAT Settlement", "Add-Curr. VAT Settlement", "Prior Period Input VAT", "Prior Period Output VAT", "Add Curr. Prior Per. Inp. VAT", "Add Curr. Prior Per. Out VAT", "Advanced Amount", "Add-Curr. Paid. Amount", "Paid Amount", "Add-Curr. Advanced Amount", "Payable VAT Variation", "Deductible VAT Variation", "Tax Debit Variation", "Tax Credit Variation", "Unpaid VAT Previous Periods", "Tax Debit Variation Interest", "Omit VAT Payable Interest", "Credit VAT Compensation", "Special Credit";
        }
        key(Key2; "VAT Period Closed")
        {
            SumIndexFields = "VAT Settlement", "Add-Curr. VAT Settlement", "Prior Period Input VAT", "Prior Period Output VAT", "Add Curr. Prior Per. Inp. VAT", "Add Curr. Prior Per. Out VAT", "Advanced Amount", "Add-Curr. Paid. Amount", "Paid Amount", "Add-Curr. Advanced Amount", "Payable VAT Variation", "Deductible VAT Variation", "Tax Debit Variation", "Tax Credit Variation", "Unpaid VAT Previous Periods", "Tax Debit Variation Interest", "Omit VAT Payable Interest", "Credit VAT Compensation", "Special Credit";
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
    begin
        PeriodicSettlementVATEntry.SetFilter("VAT Period", '<%1', "VAT Period");
        if PeriodicSettlementVATEntry.FindLast() then begin
            "Prior Period Input VAT" := PeriodicSettlementVATEntry."Prior Period Input VAT";
            "Prior Period Output VAT" := PeriodicSettlementVATEntry."Prior Period Output VAT";
        end;
    end;

    var
        Month: Integer;
        InvalidVATPeriodErr: Label 'The VAT Period must contain seven characters, for example, YYYY/MM.';
        InvalidMonthErr: Label 'Check that the month number is correct.';
}
#endif