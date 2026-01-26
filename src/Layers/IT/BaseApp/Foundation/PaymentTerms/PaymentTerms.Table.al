// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.EServices.EDocument;
using Microsoft.Integration.Dataverse;
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
            NotBlank = true;
        }
        field(2; "Due Date Calculation"; DateFormula)
        {
            Caption = 'Due Date Calculation';
            Enabled = false;
        }
        field(3; "Discount Date Calculation"; DateFormula)
        {
            Caption = 'Discount Date Calculation';
            Enabled = false;
        }
        field(4; "Discount %"; Decimal)
        {
            Caption = 'Discount %';
            DecimalPlaces = 0 : 5;
            Enabled = false;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; "Calc. Pmt. Disc. on Cr. Memos"; Boolean)
        {
            Caption = 'Calc. Pmt. Disc. on Cr. Memos';
        }
        field(8; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
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
            CalcFormula = sum("Payment Lines"."Payment %" where("Sales/Purchase" = const(" "),
                                                                 Type = const("Payment Terms"),
                                                                 Code = field(Code)));
            Caption = 'Payment %';
            Editable = false;
            FieldClass = FlowField;
        }
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
    begin
        PaymentTermsTranslation.SetRange("Payment Term", Code);
        PaymentTermsTranslation.DeleteAll();
        FilterPaymentLines();
        if PaymentTermsLine.Find('-') then
            PaymentTermsLine.DeleteAll(true);
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
        FilterPaymentLines();
        if PaymentTermsLine.Find('-') then
            Error(Text000, Code);
        CRMSyncHelper.UpdateCDSOptionMapping(xRec.RecordId(), RecordId());
    end;

    var
        PaymentTermsLine: Record "Payment Lines";
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

    [Scope('OnPrem')]
    procedure FilterPaymentLines()
    begin
        PaymentTermsLine.Reset();
        PaymentTermsLine.SetRange(PaymentTermsLine."Sales/Purchase", 0);
        PaymentTermsLine.SetRange(PaymentTermsLine.Type, PaymentTermsLine.Type::"Payment Terms");
        PaymentTermsLine.SetRange(PaymentTermsLine.Code, Code);
    end;

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
        PaymentLines: Record "Payment Lines";
    begin
        PaymentLines.SetFilter("Discount %", '<>%1', 0);

        exit(not PaymentLines.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure GetDueDateCalculation(var DueDateCalculation: DateFormula)
    var
        PaymentLines: Record "Payment Lines";
    begin
        PaymentLines.SetRange("Sales/Purchase", PaymentLines."Sales/Purchase"::" ");
        PaymentLines.SetRange(Type, PaymentLines.Type::"Payment Terms");
        PaymentLines.SetRange(Code, Code);
        if PaymentLines.FindFirst() then
            DueDateCalculation := PaymentLines."Due Date Calculation"
        else
            Evaluate(DueDateCalculation, '<0D>');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTranslateDescription(var PaymentTerms: Record "Payment Terms"; Language: Code[10])
    begin
    end;
}
