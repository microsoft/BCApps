// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Finance.Registration;
using Microsoft.Sales.Customer;
using Microsoft.Finance.VAT.Registration;

page 11752 "Get Vend. Bank Acc. Code CZL"
{
    Caption = 'Get Bank Account Code';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(AccountType; AccountType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Type';
                    ToolTip = 'Specifies whether to create a vendor or customer bank account.';
                    Visible = SelectAccount;

                    trigger OnValidate()
                    begin
                        CustomerAccount := AccountType = AccountType::Customer;
                        Clear(VendorNo);
                        CurrPage.Update(false);
                    end;
                }
                field(VendorNo; VendorNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor No.';
                    ToolTip = 'Specifies vendor for create bank account.';
                    Editable = SelectAccount;
                    Visible = not CustomerAccount;
                    TableRelation = Vendor."No.";

                    trigger OnValidate()
                    begin
                        CheckAccount();
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Vendor: Record Vendor;
                        VendorList: Page "Vendor List";
                    begin
                        Vendor.SetRange("VAT Registration No.", VATRegistrationNo);
                        VendorList.SetTableView(Vendor);
                        VendorList.LookupMode(true);
                        if VendorList.RunModal() <> Action::LookupOK then
                            exit(false);
                        VendorList.GetRecord(Vendor);
                        VendorNo := Vendor."No.";
                        CheckAccount();
                        exit(true);
                    end;
                }
                field(CustomerNo; VendorNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer No.';
                    ToolTip = 'Specifies the customer for whom the bank account will be created.';
                    Editable = SelectAccount;
                    Visible = CustomerAccount;
                    TableRelation = Customer."No.";

                    trigger OnValidate()
                    begin
                        CheckAccount();
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Customer: Record Customer;
                        CustomerList: Page "Customer List";
                    begin
                        Customer.SetRange("VAT Registration No.", VATRegistrationNo);
                        CustomerList.SetTableView(Customer);
                        CustomerList.LookupMode(true);
                        if CustomerList.RunModal() <> Action::LookupOK then
                            exit(false);
                        CustomerList.GetRecord(Customer);
                        VendorNo := Customer."No.";
                        CheckAccount();
                        exit(true);
                    end;
                }
                field(VendorBankAccCode; VendorBankAccCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account Code';
                    ToolTip = 'Specifies the code of the bank account to create.';
                }
                field(VendorBankAccName; VendorBankAccName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account Name';
                    ToolTip = 'Specifies the name of the bank account to create.';
                }
                field(PreferredBankAccount; PreferredBankAccount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Preferred Bank Account';
                    ToolTip = 'Specifies whether to set this bank account as the preferred bank account for the customer or vendor.';
                }
            }
        }
    }
    var
        VendorNo: Code[20];
        VendorBankAccCode: Code[10];
        VendorBankAccName: Text[100];
        PreferredBankAccount: Boolean;
        CustomerAccount: Boolean;
        SelectAccount: Boolean;
        AccountType: Enum "Unrel. Payer Account Type CZL";
        VATRegistrationNo: Code[20];

    procedure SetVATRegistrationNo(NewVATRegistrationNo: Code[20])
    begin
        VATRegistrationNo := NewVATRegistrationNo;
        SelectAccount := true;
        AccountType := AccountType::Vendor;
        CustomerAccount := false;
        Clear(VendorNo);
    end;

    procedure GetAccount(var NewAccountType: Enum "Unrel. Payer Account Type CZL"; var NewAccountNo: Code[20])
    begin
        CheckAccount();
        if CustomerAccount then
            NewAccountType := NewAccountType::Customer
        else
            NewAccountType := NewAccountType::Vendor;
        NewAccountNo := VendorNo;
    end;

    local procedure CheckAccount()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        UnreliablePayerMgtCZL: Codeunit "Unreliable Payer Mgt. CZL";
        AccountNoRequiredErr: Label 'Select a customer or vendor.';
        VATRegNoMismatchErr: Label 'The selected customer or vendor must have VAT registration number %1.', Comment = '%1 = Entry VAT registration number';
        AccountVATRegistrationNo: Code[20];
    begin
        if VendorNo = '' then
            Error(AccountNoRequiredErr);
        if CustomerAccount then begin
            Customer.Get(VendorNo);
            AccountVATRegistrationNo := Customer."VAT Registration No.";
        end else begin
            Vendor.Get(VendorNo);
            AccountVATRegistrationNo := Vendor."VAT Registration No.";
        end;
        if SelectAccount then
            if UnreliablePayerMgtCZL.GetLongVATRegNo(AccountVATRegistrationNo) <> UnreliablePayerMgtCZL.GetLongVATRegNo(VATRegistrationNo) then
                Error(VATRegNoMismatchErr, VATRegistrationNo);
    end;

    procedure SetValue(NewVendorNo: Code[20])
    begin
        VendorNo := NewVendorNo;
        CustomerAccount := false;
        SelectAccount := false;
    end;

    procedure SetCustomerValue(NewCustomerNo: Code[20])
    begin
        VendorNo := NewCustomerNo;
        CustomerAccount := true;
        SelectAccount := false;
    end;

    procedure GetValue(var NewVendorBankAccCode: Code[10]; var NewVendorBankAccName: Text[100]; var NewPreferredBankAccount: Boolean)
    begin
        NewVendorBankAccCode := VendorBankAccCode;
        NewVendorBankAccName := VendorBankAccName;
        NewPreferredBankAccount := PreferredBankAccount;
    end;
}
