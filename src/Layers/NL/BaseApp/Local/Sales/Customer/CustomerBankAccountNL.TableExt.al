// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Payment;
using Microsoft.Foundation.Address;
using Microsoft.Utilities;

/// <summary>
/// Extends the Customer Bank Account table with NL-specific account holder and telebanking fields.
/// Adds telebanking update logic to existing W1 fields via modify() blocks.
/// </summary>
tableextension 11463 "Customer Bank Account NL" extends "Customer Bank Account"
{
    fields
    {
        /// <summary>
        /// Specifies the bank account owner's name.
        /// </summary>
        field(11000000; "Account Holder Name"; Text[100])
        {
            Caption = 'Account Holder Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        /// <summary>
        /// Specifies the bank account owner's street address.
        /// </summary>
        field(11000001; "Account Holder Address"; Text[100])
        {
            Caption = 'Account Holder Address';
            DataClassification = EndUserIdentifiableInformation;
        }
        /// <summary>
        /// Specifies the bank account owner's postal code.
        /// </summary>
        field(11000002; "Account Holder Post Code"; Code[20])
        {
            Caption = 'Account Holder Post Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Acc. Hold. Country/Region Code" = const('')) "Post Code"
            else
            if ("Acc. Hold. Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Acc. Hold. Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                PostCode: Record "Post Code";
            begin
                PostCode.ValidatePostCode("Account Holder City", "Account Holder Post Code", County, "Acc. Hold. Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        /// <summary>
        /// Specifies the bank account owner's city.
        /// </summary>
        field(11000003; "Account Holder City"; Text[30])
        {
            Caption = 'Account Holder City';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Acc. Hold. Country/Region Code" = const('')) "Post Code".City
            else
            if ("Acc. Hold. Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Acc. Hold. Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                PostCode: Record "Post Code";
            begin
                PostCode.ValidateCity("Account Holder City", "Account Holder Post Code", County, "Acc. Hold. Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        /// <summary>
        /// Specifies the country or region of the bank account holder.
        /// </summary>
        field(11000004; "Acc. Hold. Country/Region Code"; Code[10])
        {
            Caption = 'Acc. Hold. Country/Region Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Specifies the national bank code for this bank account.
        /// </summary>
        field(11000005; "National Bank Code"; Code[10])
        {
            Caption = 'National Bank Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        /// <summary>
        /// Specifies an abbreviated national bank code for this bank account.
        /// </summary>
        field(11000007; "Abbrev. National Bank Code"; Code[3])
        {
            Caption = 'Abbrev. National Bank Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        /// <summary>
        /// Specifies the direct debit mandate used for collecting payments from this bank account.
        /// </summary>
        field(11000008; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            DataClassification = CustomerContent;
            TableRelation = "SEPA Direct Debit Mandate" where("Customer No." = field("Customer No."),
                                                               "Customer Bank Account Code" = field(Code));

            trigger OnValidate()
            begin
                UpdateMandateID();
            end;
        }
        modify("Bank Account No.")
        {
            trigger OnAfterValidate()
            var
                LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
            begin
                if not LocalFunctionalityMgt.CheckBankAccNo("Bank Account No.", "Country/Region Code", "Bank Account No.") then
                    Message(BankAccNoMayBeIncorrectMsg, "Bank Account No.");
                UpdateBankAccountNo();
            end;
        }

        modify(IBAN)
        {
            trigger OnAfterValidate()
            begin
                UpdateIBAN();
            end;
        }

        modify("SWIFT Code")
        {
            trigger OnAfterValidate()
            begin
                UpdateSWIFT();
            end;
        }

    }

    trigger OnInsert()
    var
        Customer: Record Customer;
    begin
        Customer.SetLoadFields("Name", "Address", "Post Code", City, "Country/Region Code");
        Customer.Get("Customer No.");
        "Account Holder Name" := Customer.Name;
        "Account Holder Address" := Customer.Address;
        "Account Holder Post Code" := Customer."Post Code";
        "Account Holder City" := Customer.City;
        "Acc. Hold. Country/Region Code" := Customer."Country/Region Code";
    end;

    var
        BankAccNoMayBeIncorrectMsg: Label 'Bank Account No. %1 may be incorrect.', Comment = '%1 = Bank Account No.';

    local procedure UpdateMandateID()
    var
        ProposalLine: Record "Proposal Line";
    begin
        if FindProposalLines(ProposalLine) then
            ProposalLine.ModifyAll("Direct Debit Mandate ID", "Direct Debit Mandate ID");
    end;

    local procedure UpdateIBAN()
    var
        ProposalLine: Record "Proposal Line";
    begin
        if FindProposalLines(ProposalLine) then
            ProposalLine.ModifyAll(IBAN, IBAN);
    end;

    local procedure UpdateSWIFT()
    var
        ProposalLine: Record "Proposal Line";
    begin
        if FindProposalLines(ProposalLine) then
            ProposalLine.ModifyAll("SWIFT Code", "SWIFT Code");
    end;

    local procedure UpdateBankAccountNo()
    var
        ProposalLine: Record "Proposal Line";
    begin
        if FindProposalLines(ProposalLine) then
            ProposalLine.ModifyAll("Bank Account No.", "Bank Account No.");
    end;

    local procedure FindProposalLines(var ProposalLine: Record "Proposal Line"): Boolean
    begin
        ProposalLine.SetRange("Account Type", ProposalLine."Account Type"::Customer);
        ProposalLine.SetRange("Account No.", "Customer No.");
        ProposalLine.SetRange(Bank, Code);
        exit(not ProposalLine.IsEmpty());
    end;
}
