// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Bank.Payment;

tableextension 11300 "Vendor NL" extends Vendor
{
    fields
    {
        field(11000000; "Transaction Mode Code"; Code[20])
        {
            Caption = 'Transaction Mode Code';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Mode".Code where("Account Type" = const(Vendor));

            trigger OnValidate()
            var
                TransactionMode: Record "Transaction Mode";
            begin
                if "Transaction Mode Code" <> '' then begin
                    TransactionMode.Get(TransactionMode."Account Type"::Vendor, "Transaction Mode Code");
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
                UpdateVendorBankAccounts(FieldCaption(Name));
            end;
        }

        modify(Address)
        {
            trigger OnAfterValidate()
            begin
                UpdateVendorBankAccounts(FieldCaption(Address));
            end;
        }

        modify(City)
        {
            trigger OnAfterValidate()
            begin
                UpdateVendorBankAccounts(FieldCaption(City));
            end;
        }

        modify("Country/Region Code")
        {
            trigger OnAfterValidate()
            begin
                UpdateVendorBankAccounts(FieldCaption("Country/Region Code"));
            end;
        }

        modify("Post Code")
        {
            trigger OnAfterValidate()
            begin
                UpdateVendorBankAccounts(FieldCaption("Post Code"));
            end;
        }

        modify("Partner Type")
        {
            trigger OnAfterValidate()
            var
                TransactionMode: Record "Transaction Mode";
                AccountType: Option Customer,Vendor,Employee;
            begin
                if not TransactionMode.CheckTransactionModePartnerType(AccountType::Vendor, "Transaction Mode Code", "Partner Type") then
                    if not Confirm(PartnerTypeMismatchMsg, false) then
                        Error('');
            end;
        }
    }

    var
        UpdateBankAccountsQst: Label 'Do you want to update the bank accounts for this vendor to reflect the new value of %1?', Comment = '%1 = Field Caption';
        PartnerTypeMismatchMsg: Label 'The Partner Type does not match the Partner Type defined in Transaction Mode. Do you still want to change the Partner Type?';

    [Scope('OnPrem')]
    procedure UpdateVendorBankAccounts(UseFieldCaption: Text[250])
    var
        VendBankAcc: Record "Vendor Bank Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateVendorBankAccounts(Rec, IsHandled, VendBankAcc);
        if (not GuiAllowed) or IsHandled then
            exit;

        VendBankAcc.SetRange("Vendor No.", "No.");
        if VendBankAcc.FindSet() then begin
            IsHandled := false;
            OnUpdateVendorBankAccountsOnBeforeConfirm(Rec, IsHandled);
            if not IsHandled then
                if not Confirm(StrSubstNo(UpdateBankAccountsQst, UseFieldCaption)) then
                    exit;
            repeat
                VendBankAcc."Account Holder Name" := Name;
                VendBankAcc."Account Holder Address" := Address;
                VendBankAcc."Account Holder Post Code" := "Post Code";
                VendBankAcc."Account Holder City" := City;
                VendBankAcc."Acc. Hold. Country/Region Code" := "Country/Region Code";
                VendBankAcc.Modify();
            until VendBankAcc.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVendorBankAccountsOnBeforeConfirm(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateVendorBankAccounts(var Vendor: Record Vendor; var IsHandled: Boolean; var VendorBankAccount: Record "Vendor Bank Account")
    begin
    end;
}
