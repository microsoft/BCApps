// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

table 680 "Payment Period Header"
{
    Caption = 'Payment Period Header';
    DataClassification = CustomerContent;
    LookupPageId = "Payment Period List";
    DrillDownPageId = "Payment Period List";

    fields
    {
        field(1; "Code"; Code[20])
        {
            NotBlank = true;
            ToolTip = 'Specifies the code of the payment period template.';
        }
        field(2; Description; Text[250])
        {
            ToolTip = 'Specifies the description of the payment period template.';
        }
        field(3; "Reporting Scheme"; Enum "Paym. Prac. Reporting Scheme")
        {
            ToolTip = 'Specifies the reporting scheme this payment period template belongs to.';
        }
        field(4; Default; Boolean)
        {
            ToolTip = 'Specifies whether this is the default payment period template for the reporting scheme.';

            trigger OnValidate()
            var
                PaymentPeriodHeader: Record "Payment Period Header";
            begin
                if not Default then
                    exit;

                PaymentPeriodHeader.SetRange("Reporting Scheme", "Reporting Scheme");
                PaymentPeriodHeader.SetRange(Default, true);
                PaymentPeriodHeader.SetFilter(Code, '<>%1', Code);
                PaymentPeriodHeader.ModifyAll(Default, false);
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        PaymentPeriodLine: Record "Payment Period Line";
        PaymentPracticeHeader: Record "Payment Practice Header";
    begin
        PaymentPracticeHeader.SetRange("Payment Period Code", Code);
        if not PaymentPracticeHeader.IsEmpty() then
            Error(CannotDeleteReferencedErr, Code);

        PaymentPeriodLine.SetRange("Period Header Code", Code);
        PaymentPeriodLine.DeleteAll();
    end;

    var
        CannotDeleteReferencedErr: Label 'Cannot delete Payment Period Header %1 because it is referenced by one or more Payment Practice Headers.', Comment = '%1 = Payment Period Header Code';
}
