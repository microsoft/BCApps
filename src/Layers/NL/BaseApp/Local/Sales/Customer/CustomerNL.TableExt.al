// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Bank.Payment;

/// <summary>
/// Extends the Customer table with NL-specific telebanking fields.
/// Propagates customer address changes to CustomerBankAccount holder fields via modify() blocks.
/// </summary>
tableextension 11462 "Customer NL" extends Customer
{
    fields
    {
        /// <summary>
        /// Specifies the transaction mode commonly used in telebanking for this customer.
        /// </summary>
        field(11000000; "Transaction Mode Code"; Code[20])
        {
            Caption = 'Transaction Mode Code';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Mode".Code where("Account Type" = const(Customer));

            trigger OnValidate()
            var
                TransactionMode: Record "Transaction Mode";
            begin
                if "Transaction Mode Code" <> '' then begin
                    TransactionMode.Get(TransactionMode."Account Type"::Customer, "Transaction Mode Code");
                    if TransactionMode."Payment Method Code" <> '' then
                        "Payment Method Code" := TransactionMode."Payment Method Code";
                    if TransactionMode."Payment Terms Code" <> '' then
                        "Payment Terms Code" := TransactionMode."Payment Terms Code";
                end;
            end;
        }
        modify(Name)
        {
            trigger OnAfterValidate()
            begin
                UpdateCustomerBankAccounts(FieldCaption(Name));
            end;
        }
        modify(Address)
        {
            trigger OnAfterValidate()
            begin
                UpdateCustomerBankAccounts(FieldCaption(Address));
            end;
        }
        modify(City)
        {
            trigger OnAfterValidate()
            begin
                UpdateCustomerBankAccounts(FieldCaption(City));
            end;
        }
        modify("Country/Region Code")
        {
            trigger OnAfterValidate()
            begin
                UpdateCustomerBankAccounts(FieldCaption("Country/Region Code"));
            end;
        }
        modify("Post Code")
        {
            trigger OnAfterValidate()
            begin
                UpdateCustomerBankAccounts(FieldCaption("Post Code"));
            end;
        }
        modify("Partner Type")
        {
            trigger OnAfterValidate()
            var
                TransactionMode: Record "Transaction Mode";
                AccountType: Option Customer,Vendor,Employee;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePartnerType(IsHandled);
                if IsHandled then
                    exit;

                if not TransactionMode.CheckTransactionModePartnerType(AccountType::Customer, "Transaction Mode Code", "Partner Type") then
                    if not Confirm(PartnerTypeMismatchQst, false) then
                        Error('')
            end;
        }
    }

    var
        UpdateBankAccountsQst: Label 'Do you want to update the bank accounts for this customer to reflect the new value of %1?', Comment = '%1 = Field Caption';
        PartnerTypeMismatchQst: Label 'The Partner Type does not match the Partner Type defined in Transaction Mode. Do you still want to change the Partner Type?';

    [Scope('OnPrem')]
    procedure UpdateCustomerBankAccounts(UseFieldCaption: Text[250])
    var
        CustBankAcc: Record "Customer Bank Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCustomerBankAccounts(Rec, IsHandled);
        if (not GuiAllowed) or IsHandled then
            exit;
        CustBankAcc.SetRange("Customer No.", "No.");
        if CustBankAcc.FindSet() then begin
            if not Confirm(StrSubstNo(UpdateBankAccountsQst, UseFieldCaption)) then
                exit;
            repeat
                CustBankAcc."Account Holder Name" := Name;
                CustBankAcc."Account Holder Address" := Address;
                CustBankAcc."Account Holder Post Code" := "Post Code";
                CustBankAcc."Account Holder City" := City;
                CustBankAcc."Acc. Hold. Country/Region Code" := "Country/Region Code";
                CustBankAcc.Modify();
            until CustBankAcc.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCustomerBankAccounts(var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidatePartnerType(var IsHandled: Boolean)
    begin
    end;
}

