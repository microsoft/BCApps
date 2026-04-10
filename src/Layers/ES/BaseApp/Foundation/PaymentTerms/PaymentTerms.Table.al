// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Finance.ReceivablesPayables;
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
        field(10710; "Max. No. of Days till Due Date"; Integer)
        {
            BlankZero = true;
            Caption = 'Max. No. of Days till Due Date';

            trigger OnValidate()
            begin
                if "Max. No. of Days till Due Date" < 0 then
                    Error(Text10701);
            end;
        }
        field(7000000; "No. of Installments"; Integer)
        {
            BlankZero = true;
            CalcFormula = count(Installment where("Payment Terms Code" = field(Code)));
            Caption = 'No. of Installments';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000002; "VAT distribution"; Option)
        {
            Caption = 'VAT distribution';
            OptionCaption = 'First Installment,Last Installment,Proportional';
            OptionMembers = "First Installment","Last Installment",Proportional;
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
        Installment: Record Installment;
    begin
        PaymentTermsTranslation.SetRange("Payment Term", Code);
        PaymentTermsTranslation.DeleteAll();

        if Installment.WritePermission then begin
            Installment.SetRange("Payment Terms Code", Code);
            Installment.DeleteAll();
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
        CRMSyncHelper.UpdateCDSOptionMapping(xRec.RecordId(), RecordId());
    end;

    var
        Text10700: Label 'The %1 exceeds the %2 defined on the %3.', Comment = '%1 is fieldcaption,%2 is fieldcaption,%3 is tablecaption';
        Text10701: Label 'The value must be greater than or equal to 0.';

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

    procedure CalculateMaxDueDate(BaseDate: Date): Date
    var
        CalculatedDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateMaxDueDate(Rec, BaseDate, CalculatedDate, IsHandled);
        if IsHandled then
            exit(CalculatedDate);

        if "Max. No. of Days till Due Date" = 0 then
            exit(99991231D);
        exit(CalcDate(StrSubstNo('<%1D>', "Max. No. of Days till Due Date"), BaseDate));
    end;

    procedure VerifyMaxNoDaysTillDueDate(DueDate: Date; DocumentDate: Date; MessageFieldCaption: Text[50])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyMaxNoDaysTillDueDate(Rec, DueDate, DocumentDate, MessageFieldCaption, IsHandled);
        if IsHandled then
            exit;

        if (DueDate <> 0D) and ("Max. No. of Days till Due Date" > 0) then
            if DueDate - DocumentDate > "Max. No. of Days till Due Date" then
                Error(Text10700, MessageFieldCaption, FieldCaption("Max. No. of Days till Due Date"), TableCaption);
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
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.SetFilter("Discount %", '<>%1', 0);

        exit(not PaymentTerms.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure GetDueDateCalculation(var DueDateCalculation: DateFormula)
    begin
        DueDateCalculation := "Due Date Calculation";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTranslateDescription(var PaymentTerms: Record "Payment Terms"; Language: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateMaxDueDate(PaymentTerms: Record "Payment Terms"; BaseDate: Date; var CalculatedDate: Date; var IsHandled: boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyMaxNoDaysTillDueDate(PaymentTerms: Record "Payment Terms"; DueDate: Date; DocumentDate: Date; MessageFieldCaption: Text[50]; var IsHandled: boolean)
    begin
    end;
}
