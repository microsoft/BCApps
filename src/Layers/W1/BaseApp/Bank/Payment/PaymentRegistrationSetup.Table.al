// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Stores user-specific configuration settings for payment registration functionality.
/// This table manages default values and preferences for the payment registration process.
/// </summary>
table 980 "Payment Registration Setup"
{
    Caption = 'Payment Registration Setup';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the user ID for whom this payment registration setup applies.
        /// Each user can have their own personalized payment registration configuration.
        /// </summary>
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        /// <summary>
        /// Specifies the general journal template used for payment registration posting.
        /// Determines the template structure and defaults for payment journal entries.
        /// </summary>
        field(2; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template";

            trigger OnValidate()
            begin
                "Journal Batch Name" := '';
            end;
        }
        /// <summary>
        /// Specifies the general journal batch used for payment registration posting.
        /// Works in conjunction with the journal template to define posting behavior.
        /// </summary>
        field(3; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));

            trigger OnValidate()
            var
                GenJournalBatch: Record "Gen. Journal Batch";
            begin
                if not GenJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
                    exit;

                case GenJournalBatch."Bal. Account Type" of
                    GenJournalBatch."Bal. Account Type"::"G/L Account":
                        Validate("Bal. Account Type", "Bal. Account Type"::"G/L Account");
                    GenJournalBatch."Bal. Account Type"::"Bank Account":
                        Validate("Bal. Account Type", "Bal. Account Type"::"Bank Account");
                    else
                        Validate("Bal. Account Type", "Bal. Account Type"::" ");
                end;

                if GenJournalBatch."Bal. Account No." <> '' then
                    Validate("Bal. Account No.", GenJournalBatch."Bal. Account No.");
            end;
        }
        /// <summary>
        /// Specifies the type of balancing account used for payment registration entries.
        /// Determines whether payments are balanced against G/L accounts or bank accounts.
        /// </summary>
        field(4; "Bal. Account Type"; Option)
        {
            Caption = 'Bal. Account Type';
            OptionCaption = ' ,G/L Account,Bank Account';
            OptionMembers = " ","G/L Account","Bank Account";

            trigger OnValidate()
            begin
                "Bal. Account No." := '';
            end;
        }
        /// <summary>
        /// Specifies the number of the balancing account used for payment registration entries.
        /// Must correspond to an account of the type specified in the Bal. Account Type field.
        /// </summary>
        field(5; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account";
        }
        /// <summary>
        /// Specifies whether this account setup should be used as the default for payment registration.
        /// When enabled, the balancing account settings are automatically applied.
        /// </summary>
        field(6; "Use this Account as Def."; Boolean)
        {
            Caption = 'Use this Account as Def.';
            InitValue = true;
        }
        /// <summary>
        /// Specifies whether the Date Received field should be automatically filled during payment registration.
        /// When enabled, the current date is automatically inserted when marking payments as received.
        /// </summary>
        field(7; "Auto Fill Date Received"; Boolean)
        {
            Caption = 'Auto Fill Date Received';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnModify()
    begin
        ValidateMandatoryFields(true);
    end;

    /// <summary>
    /// Retrieves the corresponding general journal line balance account type for the setup.
    /// Converts the setup's balance account type to the format used in general journal lines.
    /// </summary>
    /// <returns>Integer value corresponding to the general journal line balance account type.</returns>
    procedure GetGLBalAccountType(): Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        TestField("Bal. Account Type");
        case "Bal. Account Type" of
            "Bal. Account Type"::"Bank Account":
                exit(GenJnlLine."Bal. Account Type"::"Bank Account".AsInteger());
            "Bal. Account Type"::"G/L Account":
                exit(GenJnlLine."Bal. Account Type"::"G/L Account".AsInteger());
        end;
    end;

    /// <summary>
    /// Validates that all mandatory fields for payment registration setup are populated.
    /// Ensures the setup is complete and ready for use in payment registration operations.
    /// </summary>
    /// <param name="ShowError">If true, shows error messages for missing fields; if false, returns validation status silently.</param>
    /// <returns>True if all mandatory fields are populated, false otherwise.</returns>
    procedure ValidateMandatoryFields(ShowError: Boolean): Boolean
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        Result: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateMandatoryFields(Rec, ShowError, Result, IsHandled);
        if IsHandled then
            exit(Result);
        if ShowError then begin
            TestField("Journal Template Name");
            TestField("Journal Batch Name");

            TestField("Bal. Account Type");
            TestField("Bal. Account No.");

            GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
            GenJnlBatch.TestField("No. Series");
            exit(true);
        end;

        if "Journal Template Name" = '' then
            exit(false);

        if "Journal Batch Name" = '' then
            exit(false);

        if "Bal. Account Type" = "Bal. Account Type"::" " then
            exit(false);

        if "Bal. Account No." = '' then
            exit(false);

        if not GenJnlBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
            exit(false);

        if GenJnlBatch."No. Series" = '' then
            exit(false);

        exit(true);
    end;

    /// <summary>
    /// Integration event that fires before validating mandatory fields in payment registration setup.
    /// Subscribers can handle the validation process themselves and set IsHandled to true to skip the standard validation.
    /// </summary>
    /// <param name="PaymentRegistrationSetup">The payment registration setup record being validated.</param>
    /// <param name="ShowError">If true, shows error messages for missing fields; if false, returns validation status silently.</param>
    /// <param name="Result">The result of the validation process, to be returned if IsHandled is true.</param>
    /// <param name="IsHandled">Set to true if the event has been handled and the standard validation should be skipped.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateMandatoryFields(var PaymentRegistrationSetup: Record "Payment Registration Setup"; ShowError: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}
