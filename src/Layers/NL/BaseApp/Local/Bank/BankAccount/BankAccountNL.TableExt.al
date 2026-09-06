// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

using Microsoft.Bank.Payment;
using Microsoft.Foundation.Address;

tableextension 11343 "Bank Account NL" extends "Bank Account"
{
    fields
    {
        field(11000000; "Account Holder Name"; Text[100])
        {
            Caption = 'Account Holder Name';
        }
        field(11000001; "Account Holder Address"; Text[100])
        {
            Caption = 'Account Holder Address';
        }
        field(11000002; "Account Holder Post Code"; Code[20])
        {
            Caption = 'Account Holder Post Code';
            TableRelation = if ("Acc. Hold. Country/Region Code" = const('')) "Post Code"
            else
            if ("Acc. Hold. Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Acc. Hold. Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode("Account Holder City", "Account Holder Post Code", County, "Acc. Hold. Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(11000003; "Account Holder City"; Text[30])
        {
            Caption = 'Account Holder City';
            TableRelation = if ("Acc. Hold. Country/Region Code" = const('')) "Post Code".City
            else
            if ("Acc. Hold. Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Acc. Hold. Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidateCity("Account Holder City", "Account Holder Post Code", County, "Acc. Hold. Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(11000004; "Acc. Hold. Country/Region Code"; Code[10])
        {
            Caption = 'Acc. Hold. Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(11000005; Proposal; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Proposal Line".Amount where("Our Bank No." = field("No."),
                                                            Process = const(true)));
            Caption = 'Proposal';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11000006; "Payment History"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Payment History Line".Amount where("Our Bank" = field("No."),
                                                                   Status = filter(New | Transmitted | "Request for Cancellation")));
            Caption = 'Payment History';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11000007; "Creditor Identifier"; Code[19])
        {
            Caption = 'Creditor Identifier';
        }
    }

    procedure GetCreditLimit(): Decimal
    begin
        CalcFields(Balance, Proposal, "Payment History");
        exit(Balance - "Min. Balance" - Proposal - "Payment History");
    end;

    var
        PostCode: Record "Post Code";
}
