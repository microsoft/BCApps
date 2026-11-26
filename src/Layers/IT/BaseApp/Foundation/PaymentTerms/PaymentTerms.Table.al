// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.EServices.EDocument;
using Microsoft.Integration.Dataverse;
using System.Environment.Configuration;
using System.Globalization;

table 3 "Payment Terms"
{
    Caption = 'Payment Terms';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Payment Terms";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code to identify this set of payment terms.';
            NotBlank = true;
        }
        field(2; "Due Date Calculation"; DateFormula)
        {
            Caption = 'Due Date Calculation';
            ToolTip = 'Specifies a formula that determines how to calculate the due date, for example, when you create an invoice.';
        }
        field(3; "Discount Date Calculation"; DateFormula)
        {
            Caption = 'Discount Date Calculation';
            ToolTip = 'Specifies the date formula if the payment terms include a possible payment discount.';
        }
        field(4; "Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Discount %';
            ToolTip = 'Specifies the percentage of the invoice amount (amount including VAT is the default setting) that will constitute a possible payment discount.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies an explanation of the payment terms.';
        }
        field(6; "Calc. Pmt. Disc. on Cr. Memos"; Boolean)
        {
            Caption = 'Calc. Pmt. Disc. on Cr. Memos';
            ToolTip = 'Specifies that a payment discount, cash discount, cash discount date, and due date are calculated on credit memos with these payment terms.';
        }
        field(8; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(9; "Has Installments"; Boolean)
        {
            Caption = 'Has Installments';
            ToolTip = 'Specifies whether global installment rules are set up for these payment terms. Supported standalone sales invoices post one receivable per installment.';
            FieldClass = FlowField;
            CalcFormula = exist("Payment Term Installment" where("Payment Terms Code" = field(Code)));
            Editable = false;
        }
#if not CLEANSCHEMA26
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dataverse';
            Editable = false;
            ObsoleteReason = 'Replaced by page control Coupled to Dataverse';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
#if not CLEAN30
        field(12170; "Payment Nos."; Integer)
        {
            CalcFormula = count("Payment Lines" where("Sales/Purchase" = const(" "),
                                                       Type = const("Payment Terms"),
                                                       Code = field(Code)));
            Caption = 'Payment Nos.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12171; "Payment %"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Payment Lines"."Payment %" where("Sales/Purchase" = const(" "),
                                                                 Type = const("Payment Terms"),
                                                                 Code = field(Code)));
            Caption = 'Payment %';
            Editable = false;
            FieldClass = FlowField;
        }
#endif
        field(12172; "Fattura Payment Terms Code"; Code[4])
        {
            Caption = 'Fattura Payment Terms Code';
            TableRelation = "Fattura Code".Code where(Type = filter("Payment Terms"));
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Due Date Calculation")
        {
        }
        fieldgroup(Brick; "Code", Description, "Due Date Calculation")
        {
        }
    }

    trigger OnDelete()
    var
        PaymentTermsTranslation: Record "Payment Term Translation";
        PaymentTermInstallment: Record "Payment Term Installment";
    begin
        PaymentTermsTranslation.SetRange("Payment Term", Code);
        PaymentTermsTranslation.DeleteAll();
        if not IsTemporary() then begin
            PaymentTermInstallment.SetRange("Payment Terms Code", Code);
            PaymentTermInstallment.DeleteAll();
        end;
    end;

    trigger OnInsert()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnModify()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnRename()
    var
        CRMSyncHelper: Codeunit "CRM Synch. Helper";
    begin
        SetLastModifiedDateTime();
#if not CLEAN30
        if not FeatureKeyManagement.IsPaymentInstallmentsEnabled() then begin
            FilterPaymentLines();
            if PaymentTermsLine.Find('-') then
                Error(Text000, Code);
        end;
#endif
        CRMSyncHelper.UpdateCDSOptionMapping(xRec.RecordId(), RecordId());
    end;

    var
#if not CLEAN30
        PaymentTermsLine: Record "Payment Lines";
        FeatureKeyManagement: Codeunit "Feature Key Management";
#endif
        Text000: Label 'Impossible to rename %1 because there are payment lines associated with it.';

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    procedure TranslateDescription(var PaymentTerms: Record "Payment Terms"; Language: Code[10])
    var
        PaymentTermsTranslation: Record "Payment Term Translation";
    begin
        if PaymentTermsTranslation.Get(PaymentTerms.Code, Language) then
            PaymentTerms.Description := PaymentTermsTranslation.Description;
        OnAfterTranslateDescription(PaymentTerms, Language);
    end;

#if not CLEAN30
    [Obsolete('Replaced by global Payment Installments feature.', '30.0')]
    [Scope('OnPrem')]
    procedure FilterPaymentLines()
    begin
        PaymentTermsLine.Reset();
        PaymentTermsLine.SetRange(PaymentTermsLine."Sales/Purchase", 0);
        PaymentTermsLine.SetRange(PaymentTermsLine.Type, PaymentTermsLine.Type::"Payment Terms");
        PaymentTermsLine.SetRange(PaymentTermsLine.Code, Code);
    end;
#endif

    procedure GetDescriptionInCurrentLanguageFullLength(): Text[100]
    var
        PaymentTermTranslation: Record "Payment Term Translation";
        Language: Codeunit Language;
    begin
        if PaymentTermTranslation.Get(Code, Language.GetUserLanguageCode()) then
            exit(PaymentTermTranslation.Description);

        exit(Description);
    end;

    procedure UsePaymentDiscount(): Boolean
    var
#if not CLEAN30
        PaymentLines: Record "Payment Lines";
#endif
        PaymentTerms: Record "Payment Terms";
    begin
#if not CLEAN30
        if not FeatureKeyManagement.IsPaymentInstallmentsEnabled() then begin
            PaymentLines.SetFilter("Discount %", '<>%1', 0);

            exit(not PaymentLines.IsEmpty);
        end;
#endif
        PaymentTerms.SetFilter("Discount %", '<>%1', 0);

        exit(not PaymentTerms.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure GetDueDateCalculation(var DueDateCalculation: DateFormula)
#if not CLEAN30
    var
        PaymentLines: Record "Payment Lines";
#endif
    begin
#if not CLEAN30
        if not FeatureKeyManagement.IsPaymentInstallmentsEnabled() then begin
            PaymentLines.SetRange("Sales/Purchase", PaymentLines."Sales/Purchase"::" ");
            PaymentLines.SetRange(Type, PaymentLines.Type::"Payment Terms");
            PaymentLines.SetRange(Code, Code);
            if PaymentLines.FindFirst() then
                DueDateCalculation := PaymentLines."Due Date Calculation"
            else
                Evaluate(DueDateCalculation, '<0D>');
            exit;
        end;
#endif
        DueDateCalculation := "Due Date Calculation";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTranslateDescription(var PaymentTerms: Record "Payment Terms"; Language: Code[10])
    begin
    end;

#if not CLEAN30
    internal procedure SetPrepaymentFilter()
    begin
        if not FeatureKeyManagement.IsPaymentInstallmentsEnabled() then
            SetRange("Payment Nos.", 1);
    end;

    internal procedure CheckPrepaymentPaymentTerms()
    begin
        if not FeatureKeyManagement.IsPaymentInstallmentsEnabled() then begin
            CalcFields("Payment Nos.");
            TestField("Payment Nos.", 1);
        end;
    end;
#endif
}