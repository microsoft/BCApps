// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.WithholdingTax;
using Microsoft.Foundation.Navigate;
using Microsoft.Purchases.Vendor;

table 12117 Contributions
{
    Caption = 'Contributions';
    DrillDownPageID = "Contribution List";
    LookupPageID = "Contribution List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; Month; Integer)
        {
            Caption = 'Month';
            Editable = false;
        }
        field(3; Year; Integer)
        {
            Caption = 'Year';
            Editable = false;
        }
        field(4; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(6; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(7; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(8; "Related Date"; Date)
        {
            Caption = 'Related Date';
        }
        field(9; "Payment Date"; Date)
        {
            Caption = 'Payment Date';

            trigger OnValidate()
            begin
                TestField("Payment Date");
                Year := Date2DMY("Payment Date", 3);
                Month := Date2DMY("Payment Date", 2);
                if "Social Security Code" <> '' then
                    ValorizzaINPS();
                if "INAIL Code" <> '' then
                    ValorizzaINAIL();
            end;
        }
        field(15; "Gross Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Gross Amount';

            trigger OnValidate()
            begin
                ValorizzaINPS();
            end;
        }
        field(16; "Non Taxable Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Non Taxable Amount';

            trigger OnValidate()
            begin
                "Contribution Base" := "Gross Amount" - "Non Taxable Amount";
                "Total Social Security Amount" := Round("Contribution Base" * "Social Security %" / 100);
                Validate("Free-Lance Amount", Round("Total Social Security Amount" * "Free-Lance Amount %" / 100));
            end;
        }
        field(17; "Contribution Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Contribution Base';
        }
        field(18; "Social Security Code"; Code[20])
        {
            Caption = 'Social Security Code';
            TableRelation = "Contribution Code".Code where("Contribution Type" = filter(INPS));

            trigger OnValidate()
            begin
                ValorizzaINPS();
            end;
        }
        field(25; "Social Security %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Social Security %';
            DecimalPlaces = 0 : 4;
        }
        field(26; "Total Social Security Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Total Social Security Amount';
        }
        field(27; "Free-Lance Amount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Free-Lance Amount %';
            DecimalPlaces = 0 : 4;
        }
        field(28; "Free-Lance Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Free-Lance Amount';

            trigger OnValidate()
            begin
                "Company Amount" := "Total Social Security Amount" - "Free-Lance Amount";
            end;
        }
        field(29; "Company Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Company Amount';
        }
        field(50; Reported; Boolean)
        {
            Caption = 'Reported';
            Editable = false;
        }
        field(51; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(52; "INPS Paid"; Boolean)
        {
            Caption = 'INPS Paid';
            Editable = false;
        }
        field(55; "INAIL Gross Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'INAIL Gross Amount';

            trigger OnValidate()
            begin
                ValorizzaINAIL();
            end;
        }
        field(56; "INAIL Non Taxable Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'INAIL Non Taxable Amount';

            trigger OnValidate()
            begin
                "INAIL Contribution Base" := "INAIL Gross Amount" - "INAIL Non Taxable Amount";
                "INAIL Total Amount" := Round("INAIL Contribution Base" * "INAIL Per Mil" / 1000);
                Validate("INAIL Free-Lance Amount", Round("INAIL Total Amount" * "INAIL Free-Lance %" / 1000));
            end;
        }
        field(57; "INAIL Contribution Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'INAIL Contribution Base';
        }
        field(58; "INAIL Code"; Code[20])
        {
            Caption = 'INAIL Code';
            TableRelation = "Contribution Code".Code where("Contribution Type" = filter(INAIL));

            trigger OnValidate()
            begin
                ValorizzaINAIL();
            end;
        }
        field(59; "INAIL Per Mil"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'INAIL Per Mil';
            DecimalPlaces = 0 : 4;
        }
        field(60; "INAIL Total Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'INAIL Total Amount';
        }
        field(61; "INAIL Free-Lance %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'INAIL Free-Lance %';
            DecimalPlaces = 0 : 4;
        }
        field(62; "INAIL Free-Lance Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'INAIL Free-Lance Amount';

            trigger OnValidate()
            begin
                "INAIL Company Amount" := "INAIL Total Amount" - "INAIL Free-Lance Amount";
            end;
        }
        field(63; "INAIL Company Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'INAIL Company Amount';
        }
        field(64; "INAIL Paid"; Boolean)
        {
            Caption = 'INAIL Paid';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Social Security Code", "Vendor No.")
        {
        }
        key(Key3; "Vendor No.", "Social Security Code", "Social Security %")
        {
        }
        key(Key4; "Vendor No.", "Payment Date", "Social Security Code")
        {
            SumIndexFields = "Gross Amount";
        }
        key(Key5; "Vendor No.", "Payment Date", "INAIL Code")
        {
            SumIndexFields = "INAIL Gross Amount", "INAIL Company Amount";
        }
        key(Key6; "INAIL Code", "Vendor No.")
        {
        }
        key(Key7; "Vendor No.", "INAIL Code", "INAIL Per Mil")
        {
        }
        key(Key8; "Vendor No.", "Document Date", "Document No.")
        {
        }
        key(Key9; "Vendor No.", "Related Date")
        {
            SumIndexFields = "Gross Amount";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if not Reported and
           not "INPS Paid"
        then
            if not Confirm(NotCertifiedQst) then
                Error(OperationCancelledErr);

        if "INPS Paid" and not Reported then
            Error(PaidNotCertifiedErr);

        if not "INPS Paid" and Reported then
            Error(CertifiedNotPaidErr);
    end;

    trigger OnInsert()
    begin
        Contributions.LockTable();
        Contributions.Reset();
        if Contributions.FindLast() then
            "Entry No." := Contributions."Entry No." + 1
        else
            "Entry No." := 1;
    end;

    trigger OnModify()
    begin
        if Reported or
           "INPS Paid"
        then
            Error(PaidAndOrCertifiedErr);
    end;

    var
        ContributionCodeLine: Record "Contribution Code Line";
        Contributions: Record Contributions;
        WithholdingSocSecMgt: Codeunit "Withholding - Contribution";
        PaidAndOrCertifiedErr: Label 'Paid and/or certified Social Security taxes cannot be modified.';
        NotCertifiedQst: Label 'Caution, this contribution was not certified. Continue anyway?';
        OperationCancelledErr: Label 'Operation cancelled.';
        PaidNotCertifiedErr: Label 'Paid and not certified Social Security taxes cannot be deleted.';
        CertifiedNotPaidErr: Label 'Certified and not paid Social Security taxes cannot be deleted.';

    procedure ValorizzaINPS()
    begin
        WithholdingSocSecMgt.SetSocSecLineFilters(
            ContributionCodeLine, "Social Security Code", "Payment Date", ContributionCodeLine."Contribution Type"::INPS);

        "Social Security %" := ContributionCodeLine."Social Security %";
        "Free-Lance Amount %" := ContributionCodeLine."Free-Lance Amount %";

        Validate("Non Taxable Amount");
    end;

    procedure Navigate()
    var
        NavigateForm: Page Navigate;
    begin
        NavigateForm.SetDoc("Posting Date", "Document No.");
        NavigateForm.Run();
    end;

    procedure ValorizzaINAIL()
    begin
        WithholdingSocSecMgt.SetSocSecLineFilters(
            ContributionCodeLine, "INAIL Code", "Payment Date", ContributionCodeLine."Contribution Type"::INAIL);

        "INAIL Per Mil" := ContributionCodeLine."Social Security %";
        "INAIL Free-Lance %" := ContributionCodeLine."Free-Lance Amount %";

        Validate("INAIL Non Taxable Amount");
    end;
}

