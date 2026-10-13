// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.NoSeries;
using Microsoft.WithholdingTax.Employee;

table 6786 "Withholding Tax Posting Setup"
{
    Caption = 'Withholding Tax Posting Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Wthldg. Tax Bus. Post. Group"; Code[20])
        {
            Caption = 'Withholding Tax Bus. Post. Group';
            TableRelation = "Wthldg. Tax Bus. Post. Group";
        }
        field(2; "Wthldg. Tax Prod. Post. Group"; Code[20])
        {
            Caption = 'Withholding Tax Prod. Post. Group';
            TableRelation = "Wthldg. Tax Prod. Post. Group";
        }
        field(3; "Withholding Tax %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Withholding Tax %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(4; "Prepaid Wthldg. Tax Acc. Code"; Code[20])
        {
            Caption = 'Prepaid Withholding Tax Account Code';
            TableRelation = "G/L Account";
        }
        field(5; "Payable Wthldg. Tax Acc. Code"; Code[20])
        {
            Caption = 'Payable Withholding Tax Account Code';
            TableRelation = "G/L Account";
        }
        field(8; "Wthldg. Tax Rep Line No Series"; Code[20])
        {
            Caption = 'Withholding Tax Report Line No. Series';
            TableRelation = "No. Series";
        }
        field(9; "Revenue Type"; Code[10])
        {
            Caption = 'Revenue Type';
            TableRelation = "Withholding Tax Revenue Types";
        }
        field(10; "Bal. Prepaid Account Type"; Option)
        {
            Caption = 'Bal. Prepaid Account Type';
            OptionCaption = 'Bank Account,G/L Account';
            OptionMembers = "Bank Account","G/L Account";
        }
        field(11; "Bal. Prepaid Account No."; Code[20])
        {
            Caption = 'Bal. Prepaid Account No.';
            TableRelation = if ("Bal. Prepaid Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Bal. Prepaid Account Type" = const("G/L Account")) "G/L Account";
        }
        field(12; "Bal. Payable Account Type"; Option)
        {
            Caption = 'Bal. Payable Account Type';
            OptionCaption = 'Bank Account,G/L Account';
            OptionMembers = "Bank Account","G/L Account";
        }
        field(13; "Bal. Payable Account No."; Code[20])
        {
            Caption = 'Bal. Payable Account No.';
            TableRelation = if ("Bal. Payable Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Bal. Payable Account Type" = const("G/L Account")) "G/L Account";
        }
        field(20; "Purch. Wthldg. Tax Adj. Acc No"; Code[20])
        {
            Caption = 'Purch. Withholding Tax Adj. Account No.';
            TableRelation = "G/L Account";
        }
        field(21; "Sales Wthldg. Tax Adj. Acc No"; Code[20])
        {
            Caption = 'Sales Withholding Tax Adj. Account No.';
            TableRelation = "G/L Account";
        }
        field(22; Sequence; Integer)
        {
            Caption = 'Sequence';
        }
        field(23; "Realized Withholding Tax Type"; Option)
        {
            Caption = 'Realized Withholding Type';
            OptionCaption = ' ,Invoice,Payment,Earliest';
            OptionMembers = " ",Invoice,Payment,Earliest;
        }
        field(24; "Wthldg. Tax Min. Inv. Amount"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Withholding Threshold Amount';
        }
        field(25; "Wthldg. Tax Calculation Rule"; Option)
        {
            Caption = 'Withholding Threshold Type';
            OptionCaption = 'Less than,Less than or equal to,Equal to,Greater than,Greater than or equal to';
            OptionMembers = "Less than","Less than or equal to","Equal to","Greater than","Greater than or equal to";
        }
        field(100; "Calculation Base"; Enum "Withholding Calculation Base")
        {
            Caption = 'Calculation Base';

            trigger OnValidate()
            begin
                if "Calculation Base" <> "Calculation Base"::Gross then
                    TestEmployeeParty(FieldCaption("Calculation Base"));
            end;
        }
        field(101; "Calculation Method"; Enum "Withholding Calculation Method")
        {
            Caption = 'Calculation Method';

            trigger OnValidate()
            begin
                if "Calculation Method" <> "Calculation Method"::Simple then
                    TestEmployeeParty(FieldCaption("Calculation Method"));
            end;
        }
        field(102; "WHT Threshold Base"; Enum "Withholding Threshold Base")
        {
            Caption = 'Withholding Threshold Base';

            trigger OnValidate()
            begin
                if "WHT Threshold Base" <> "WHT Threshold Base"::Record then
                    TestEmployeeParty(FieldCaption("WHT Threshold Base"));

                if not ("WHT Threshold Base" in ["WHT Threshold Base"::"Category Period", "WHT Threshold Base"::"Total Period"]) then
                    "WHT Threshold Period" := "WHT Threshold Period"::" ";
            end;
        }
        field(103; "WHT Threshold Period"; Enum "WHT Threshold Period Type")
        {
            Caption = 'Withholding Threshold Period';

            trigger OnValidate()
            begin
                if "WHT Threshold Period" <> "WHT Threshold Period"::" " then
                    if not ("WHT Threshold Base" in ["WHT Threshold Base"::"Category Period", "WHT Threshold Base"::"Total Period"]) then
                        Error(ThresholdPeriodNotAllowedErr, FieldCaption("WHT Threshold Period"), FieldCaption("WHT Threshold Base"), Format("WHT Threshold Base"::"Category Period"), Format("WHT Threshold Base"::"Total Period"));
            end;
        }
    }

    keys
    {
        key(Key1; "Wthldg. Tax Bus. Post. Group", "Wthldg. Tax Prod. Post. Group")
        {
            Clustered = true;
        }
        key(Key2; "Wthldg. Tax Bus. Post. Group", Sequence)
        {
        }
    }

    fieldgroups
    {
    }

    var
        EmployeeOnlyOptionErr: Label 'The %1 option can be used only when the withholding tax is for employees.', Comment = '%1 = field caption';
        ThresholdPeriodNotAllowedErr: Label 'The %1 can be specified only when %2 is %3 or %4.', Comment = '%1 = Withholding Threshold Period field caption, %2 = Withholding Threshold Base field caption, %3 = Category in Period option, %4 = Total in Period option';

    local procedure TestEmployeeParty(FieldCaptionText: Text)
    var
        WthldgTaxBusPostGroup: Record "Wthldg. Tax Bus. Post. Group";
    begin
        if "Wthldg. Tax Bus. Post. Group" = '' then
            exit;

        if not WthldgTaxBusPostGroup.Get("Wthldg. Tax Bus. Post. Group") then
            exit;

        if WthldgTaxBusPostGroup."Party Applicability" <> WthldgTaxBusPostGroup."Party Applicability"::Employee then
            Error(EmployeeOnlyOptionErr, FieldCaptionText);
    end;

    procedure GetPrepaidWithholdingTaxAccount(): Code[20]
    begin
        TestField("Prepaid Wthldg. Tax Acc. Code");
        exit("Prepaid Wthldg. Tax Acc. Code");
    end;

    procedure GetPayableWithholdingTaxAccount(): Code[20]
    begin
        TestField("Payable Wthldg. Tax Acc. Code");
        exit("Payable Wthldg. Tax Acc. Code");
    end;
}

