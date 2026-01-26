// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Foundation.Navigate;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Telemetry;

table 12116 "Withholding Tax"
{
    Caption = 'Withholding Tax';
    DrillDownPageID = "Withholding Tax List";
    LookupPageID = "Withholding Tax List";
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
            Editable = false;
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
                ValorizzaRitenute();
            end;
        }
        field(10; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(20; "Total Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Amount';

            trigger OnValidate()
            begin
                ValorizzaRitenute();
            end;
        }
        field(21; "Base - Excluded Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Base - Excluded Amount';

            trigger OnValidate()
            begin
                if "Base - Excluded Amount" > ("Total Amount" - "Non Taxable Amount By Treaty") then
                    Error(InvalidBaseExcludedAmountErr, "Total Amount" - "Non Taxable Amount By Treaty");

                if "Base - Excluded Amount" > "Total Amount" then
                    Error(BaseExcludedAmtGreaterThanTotalErr);

                ValorizzaRitenute();
            end;
        }
        field(22; "Non Taxable Amount By Treaty"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Non Taxable Amount By Treaty';

            trigger OnValidate()
            begin
                if "Non Taxable Amount By Treaty" > ("Total Amount" - "Base - Excluded Amount") then
                    Error(InvalidNonTaxableAmountByTreatyErr, "Total Amount" - "Base - Excluded Amount");

                ValorizzaRitenute();
            end;
        }
        field(23; "Non Taxable Amount %"; Decimal)
        {
            Caption = 'Non Taxable Amount %';
            DecimalPlaces = 0 : 3;
        }
        field(30; "Non Taxable Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Non Taxable Amount';
        }
        field(31; "Taxable Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Taxable Base';
        }
        field(33; "Withholding Tax Code"; Code[20])
        {
            Caption = 'Withholding Tax Code';
            TableRelation = "Withhold Code";

            trigger OnValidate()
            begin
                ValorizzaRitenute();
            end;
        }
        field(35; "Tax Code"; Text[4])
        {
            Caption = 'Tax Code';
            Editable = false;
        }
        field(36; "Withholding Tax %"; Decimal)
        {
            Caption = 'Withholding Tax %';
            DecimalPlaces = 0 : 3;
        }
        field(37; "Withholding Tax Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Withholding Tax Amount';
        }
        field(40; "Source-Withholding Tax"; Boolean)
        {
            Caption = 'Source-Withholding Tax';
        }
        field(41; "Recipient May Report Income"; Boolean)
        {
            Caption = 'Recipient May Report Income';
        }
        field(50; Reported; Boolean)
        {
            Caption = 'Reported';
        }
        field(51; Paid; Boolean)
        {
            Caption = 'Paid';
        }
        field(52; Reason; Enum "Withholding Tax Reason")
        {
            Caption = 'Reason';
        }
        field(53; "Non-Taxable Income Type"; Enum "Non-Taxable Income Type")
        {
            Caption = 'Non-Taxable Income Type';

            trigger OnValidate()
            begin
                ClearRelatedNonTaxableLines();
            end;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Tax Code", "Vendor No.")
        {
        }
        key(Key3; "Vendor No.", "Source-Withholding Tax", "Recipient May Report Income", "Withholding Tax Code", "Withholding Tax %")
        {
        }
        key(Key4; "Vendor No.", "Document Date", "Document No.")
        {
        }
        key(Key5; "Vendor No.", Reason, "Non-Taxable Income Type")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if not Reported and
           not Paid
        then
            if not Confirm(DeductionWarningQst) then
                Error(OperationCanceledErr);

        if Paid and
           not Reported
        then
            Error(Text1036);

        if not Paid and
           Reported
        then
            Error(Text1037);
    end;

    trigger OnInsert()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ITTaxTok: Label 'IT Withholding Tax', Locked = true;
    begin
        FeatureTelemetry.LogUptake('1000HQ3', ITTaxTok, Enum::"Feature Uptake Status"::"Set up");
        WithholdingTax.LockTable();
        WithholdingTax.Reset();
        if WithholdingTax.FindLast() then
            "Entry No." := WithholdingTax."Entry No." + 1
        else
            "Entry No." := 1;
    end;

    trigger OnModify()
    begin
        if Reported or
           Paid
        then
            Error(Text1033);
    end;

    var
        Text1033: Label 'Paid and/or certified withholding taxes cannot be modified.';
        DeductionWarningQst: Label 'Warning: This deduction was not certified. Do you want to continue?';
        OperationCanceledErr: Label 'Operation canceled.';
        Text1036: Label 'Paid and certified withholding taxes cannot be deleted.';
        Text1037: Label 'Certified and not paid withholding taxes cannot be deleted.';
        InvalidBaseExcludedAmountErr: Label 'The Base - Excluded Amount must not be greater than %1.';
        WithholdCode: Record "Withhold Code";
        WithholdCodeLine: Record "Withhold Code Line";
        WithholdingTax: Record "Withholding Tax";
        Vend: Record Vendor;
        WithholdingSocSecMgt: Codeunit "Withholding - Contribution";
        BaseExcludedAmtGreaterThanTotalErr: Label 'The Base - Excluded Amount must not be greater than Total Amount.';
        InvalidNonTaxableAmountByTreatyErr: Label 'The Non Taxable Amount By Treaty must not be greater than %1.';
        WithholdingTaxEntryAlreadyExistsErr: Label 'Withholding Tax Entry %1 already exists for vendor ledger entry Document No.: %2 ,Posting Date: %3.', Comment = 'Parameter 1 - entry no, 2 - document no., 3- posting date';
        WithholdingTaxCreateQst: Label 'The program will create the withhold entry for entry %1 based on the Withholding Tax Code %2.\Do you want to create the withhold entry?', Comment = 'Parameter 1 - entry number, 2 - withholding tax code';
        WithholdingTaxCreatedMsg: Label 'Withholding tax with entry number %1 has been created.';

    procedure ValorizzaRitenute()
    begin
        WithholdCode.Get("Withholding Tax Code");

        WithholdingSocSecMgt.WithholdLineFilter(WithholdCodeLine, "Withholding Tax Code", "Payment Date");

        "Withholding Tax %" := WithholdCodeLine."Withholding Tax %";
        "Non Taxable Amount %" := 100 - WithholdCodeLine."Taxable Base %";
        "Taxable Base" := "Total Amount" - "Base - Excluded Amount" - "Non Taxable Amount By Treaty";
        "Non Taxable Amount" := "Taxable Base" -
          Round(("Taxable Base" * WithholdCodeLine."Taxable Base %") / 100);

        "Taxable Base" := "Taxable Base" - "Non Taxable Amount";
        "Withholding Tax Amount" := Round("Taxable Base" * "Withholding Tax %" / 100);
        "Tax Code" := WithholdCode."Tax Code";

        "Source-Withholding Tax" := WithholdCode."Source-Withholding Tax";
        OnValorizzaRitenuteOnAfterAssignSourceWithholdingTax(Rec);

        ClearRelatedNonTaxableLines();
    end;

    [Scope('OnPrem')]
    procedure Navigate()
    var
        NavigateForm: Page Navigate;
    begin
        NavigateForm.SetDoc("Posting Date", "Document No.");
        NavigateForm.Run();
    end;

    [Scope('OnPrem')]
    procedure InsertWithholdTax(VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        Vend.Get(VendLedgEntry."Vendor No.");
        Vend.TestField("Withholding Tax Code");
        if not Confirm(WithholdingTaxCreateQst, false, VendLedgEntry."Entry No.", Vend."Withholding Tax Code") then
            exit;
        Init();
        "Posting Date" := VendLedgEntry."Posting Date";
        "Vendor No." := VendLedgEntry."Vendor No.";
        "Document No." := VendLedgEntry."Document No.";
        "External Document No." := VendLedgEntry."External Document No.";
        "Document Date" := VendLedgEntry."Document Date";
        Validate("Withholding Tax Code", Vend."Withholding Tax Code");
        Validate("Payment Date", VendLedgEntry."Posting Date");
        Validate("Total Amount", VendLedgEntry.Amount);
        Insert(true);
        Message(WithholdingTaxCreatedMsg, "Entry No.");
    end;

    [Scope('OnPrem')]
    procedure CheckWithhEntryExist(VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        Reset();
        SetRange("Document No.", VendLedgEntry."Document No.");
        SetRange("Posting Date", VendLedgEntry."Posting Date");
        if FindFirst() then
            Error(WithholdingTaxEntryAlreadyExistsErr, "Entry No.", "Document No.", "Posting Date");
    end;

    procedure GetNonTaxableIncomeTypeNumber(): Text
    begin
        exit(Rec."Non-Taxable Income Type".Names.Get(Rec."Non-Taxable Income Type".AsInteger() + 1));
    end;

    local procedure ClearRelatedNonTaxableLines()
    var
        WithholdingTaxLine: Record "Withholding Tax Line";
    begin
        WithholdingTaxLine.SetRange("Withholding Tax Entry No.", "Entry No.");
        WithholdingTaxLine.DeleteAll(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValorizzaRitenuteOnAfterAssignSourceWithholdingTax(var WithholdingTax: Record "Withholding Tax")
    begin
    end;
}
