// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Sales.Receivables;
using System.Globalization;
using System.IO;

/// <summary>
/// Defines payment methods and their processing characteristics for transactions.
/// Supports various payment types including direct debit, bank transfers, and cash handling.
/// </summary>
/// <remarks>
/// Integrates with Sales/Purchase documents and Payment Processing. 
/// Supports balancing account assignment and direct debit configuration.
/// </remarks>
table 289 "Payment Method"
{
    Caption = 'Payment Method';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "Payment Methods";
    LookupPageID = "Payment Methods";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the payment method.
        /// </summary>
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name of the payment method for user identification.
        /// </summary>
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Type of balancing account for automatic posting (G/L Account or Bank Account).
        /// </summary>
        field(3; "Bal. Account Type"; enum "Payment Balance Account Type")
        {
            Caption = 'Bal. Account Type';

            trigger OnValidate()
            begin
                "Bal. Account No." := '';
            end;
        }
        /// <summary>
        /// Balancing account number for automatic posting of payment transactions.
        /// </summary>
        field(4; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account";

            trigger OnValidate()
            begin
                if "Bal. Account No." <> '' then
                    TestField("Direct Debit", false);
                if "Bal. Account Type" = "Bal. Account Type"::"G/L Account" then
                    CheckGLAcc("Bal. Account No.");
            end;
        }
        /// <summary>
        /// Indicates whether this payment method supports direct debit operations.
        /// </summary>
        field(6; "Direct Debit"; Boolean)
        {
            Caption = 'Direct Debit';

            trigger OnValidate()
            begin
                if not "Direct Debit" then
                    "Direct Debit Pmt. Terms Code" := '';
                if "Direct Debit" then
                    TestField("Bal. Account No.", '');
            end;
        }
        /// <summary>
        /// Payment terms code used specifically for direct debit payments.
        /// </summary>
        field(7; "Direct Debit Pmt. Terms Code"; Code[10])
        {
            Caption = 'Direct Debit Pmt. Terms Code';
            TableRelation = "Payment Terms";

            trigger OnValidate()
            begin
                if "Direct Debit Pmt. Terms Code" <> '' then
                    TestField("Direct Debit", true);
            end;
        }
        /// <summary>
        /// Data exchange line definition code used for payment export processing.
        /// </summary>
        field(8; "Pmt. Export Line Definition"; Code[20])
        {
            Caption = 'Pmt. Export Line Definition';

            trigger OnLookup()
            var
                DataExchLineDef: Record "Data Exch. Line Def";
                TempDataExchLineDef: Record "Data Exch. Line Def" temporary;
                DataExchDef: Record "Data Exch. Def";
            begin
                DataExchLineDef.SetFilter(Code, '<>%1', '');
                if DataExchLineDef.FindSet() then begin
                    repeat
                        DataExchDef.Get(DataExchLineDef."Data Exch. Def Code");
                        if DataExchDef.Type = DataExchDef.Type::"Payment Export" then begin
                            TempDataExchLineDef.Init();
                            TempDataExchLineDef.Code := DataExchLineDef.Code;
                            TempDataExchLineDef.Name := DataExchLineDef.Name;
                            if TempDataExchLineDef.Insert() then;
                        end;
                    until DataExchLineDef.Next() = 0;
                    if PAGE.RunModal(PAGE::"Pmt. Export Line Definitions", TempDataExchLineDef) = ACTION::LookupOK then
                        "Pmt. Export Line Definition" := TempDataExchLineDef.Code;
                end;
            end;
        }
        /// <summary>
        /// Timestamp indicating when this payment method record was last modified.
        /// </summary>
        field(11; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(10700; "SII Payment Method Code"; Option)
        {
            Caption = 'SII Payment Method Code';
            OptionCaption = ' ,01,02,03,04,05';
            OptionMembers = " ","01","02","03","04","05";
        }
        field(7000000; "Create Bills"; Boolean)
        {
            Caption = 'Create Bills';

            trigger OnValidate()
            begin
                if "Invoices to Cartera" and "Create Bills" then
                    Error(Text1100000, FieldCaption("Invoices to Cartera"));
            end;
        }
        field(7000001; "Collection Agent"; Option)
        {
            Caption = 'Collection Agent';
            OptionCaption = 'Direct,Bank';
            OptionMembers = Direct,Bank;
        }
        field(7000002; "Submit for Acceptance"; Boolean)
        {
            Caption = 'Submit for Acceptance';
        }
        field(7000003; "Bill Type"; Enum "ES Bill Type")
        {
            Caption = 'Bill Type';
        }
        field(7000004; "Invoices to Cartera"; Boolean)
        {
            Caption = 'Invoices to Cartera';

            trigger OnValidate()
            begin
                if "Create Bills" and "Invoices to Cartera" then
                    Error(Text1100000, FieldCaption("Create Bills"));
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

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description)
        {
        }
        fieldgroup(Brick; "Code", Description)
        {
        }
    }

    trigger OnDelete()
    var
        PaymentMethodTranslation: Record "Payment Method Translation";
    begin
        PaymentMethodTranslation.SetRange("Payment Method Code", Code);
        PaymentMethodTranslation.DeleteAll();
    end;

    trigger OnInsert()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    trigger OnRename()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    var
        Text1100000: Label '%1 must be set equal to False';

    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLAcc(Rec, CurrFieldNo, AccNo, IsHandled);
        if IsHandled then
            exit;

        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc();
            GLAcc.TestField("Direct Posting", true);
        end;
    end;

    /// <summary>
    /// Updates payment method description with translated text for specified language.
    /// </summary>
    /// <param name="Language">Language code for translation lookup</param>
    procedure TranslateDescription(Language: Code[10])
    var
        PaymentMethodTranslation: Record "Payment Method Translation";
    begin
        if PaymentMethodTranslation.Get(Code, Language) then
            Validate(Description, CopyStr(PaymentMethodTranslation.Description, 1, MaxStrLen(Description)));
    end;

    /// <summary>
    /// Retrieves payment method description in the current user's language.
    /// </summary>
    /// <returns>Translated description text or original description if translation not found</returns>
    procedure GetDescriptionInCurrentLanguage(): Text[100]
    var
        PaymentMethodTranslation: Record "Payment Method Translation";
        Language: Codeunit Language;
    begin
        if PaymentMethodTranslation.Get(Code, Language.GetUserLanguageCode()) then
            exit(PaymentMethodTranslation.Description);

        exit(Description);
    end;

    /// <summary>
    /// Integration event raised before validating G/L account for payment method.
    /// Enables custom validation logic for payment method account configuration.
    /// </summary>
    /// <param name="PaymentMethod">Payment method record being validated</param>
    /// <param name="CurrFieldNo">Current field number triggering validation</param>
    /// <param name="AccNo">Account number being validated</param>
    /// <param name="IsHandled">Set to true to skip standard G/L account validation</param>
    /// <remarks>
    /// Raised from account validation trigger before standard G/L account checking.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAcc(var PaymentMethod: Record "Payment Method"; CurrFieldNo: Integer; AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;
}