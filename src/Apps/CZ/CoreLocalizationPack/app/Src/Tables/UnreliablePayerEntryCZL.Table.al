// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Finance.VAT.Registration;
using Microsoft.Sales.Customer;

table 11753 "Unreliable Payer Entry CZL"
{
    Caption = 'Unreliable Payer Entry';
    DrillDownPageId = "Unreliable Payer Entries CZL";
    LookupPageId = "Unreliable Payer Entries CZL";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
        }
        field(8; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(9; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(20; "Check Date"; Date)
        {
            Caption = 'Check Date';
        }
        field(21; "Public Date"; Date)
        {
            Caption = 'Public Date';
        }
        field(22; "End Public Date"; Date)
        {
            Caption = 'End Public Date';
        }
#if not CLEANSCHEMA33
        field(25; "Unreliable Payer"; Option)
        {
            Caption = 'Unreliable Payer';
            OptionCaption = ' ,NO,YES,NOTFOUND';
            OptionMembers = " ",NO,YES,NOTFOUND;
#if not CLEAN30
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '33.0';
#endif
            ObsoleteReason = 'Replaced by "Status" field.';
        }
#endif
        field(26; "Status"; Enum "Unreliable Payer Status CZL")
        {
            Caption = 'Status';
        }
#if not CLEANSCHEMA33
        field(30; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = 'Payer,Bank Account';
            OptionMembers = Payer,"Bank Account";
#if not CLEAN30
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '33.0';
#endif
            ObsoleteReason = 'Replaced by "Type" field.';
        }
#endif
        field(31; "Type"; Enum "Unrel. Payer Entry Type CZL")
        {
            Caption = 'Type';
        }
        field(40; "VAT Registration No."; Code[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(50; "Tax Office Number"; Code[10])
        {
            Caption = 'Tax Office Number';
        }
        field(60; "Full Bank Account No."; Code[50])
        {
            Caption = 'Full Bank Account No.';
            MaskType = Concealed;
        }
#if not CLEANSCHEMA33
        field(61; "Bank Account No. Type"; Option)
        {
            Caption = 'Bank Account No. Type';
            OptionCaption = 'Standard,Nonstandard';
            OptionMembers = Standard,"Not Standard";
#if not CLEAN30
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '33.0';
#endif
            ObsoleteReason = 'Replaced by "Bank Account Type" field.';
        }
#endif
        field(62; "Bank Account Type"; Enum "Unrel. Payer Bank Acc.Type CZL")
        {
            Caption = 'Bank Account Type';
        }
        field(70; "Vendor Name"; Text[100])
        {
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
            Caption = 'Vendor Name';
            FieldClass = FlowField;
            Editable = false;
        }
        field(71; "Customer Name"; Text[100])
        {
            CalcFormula = lookup(Customer.Name where("No." = field("Customer No.")));
            Caption = 'Customer Name';
            FieldClass = FlowField;
            Editable = false;
        }
    }
    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Vendor No.", "Check Date")
        {
        }
        key(Key3; "VAT Registration No.", "Vendor No.", "Check Date")
        {
        }
#if not CLEAN30
        key(Key4; "Vendor No.", "Entry Type", "Full Bank Account No.", "End Public Date")
        {
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';
            ObsoleteReason = 'The key contains the obsolete "Entry Type" field.';
        }
#endif
        key(Key5; "VAT Registration No.", "Type", "Check Date")
        {
        }
    }

    procedure CreateVendorBankAccountCZL(UnreliablePayerNoCZL: Code[20]);
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        GetVendBankAccCodeCZL: Page "Get Vend. Bank Acc. Code CZL";
        VendorBankAccountCode: Code[10];
        VendorBankAccountName: Text[100];
        PreferredBankAccount: Boolean;
        VendorBankAccountAlreadyExistsErr: Label '%1 %2 already exists.', Comment = '%1 = TableCaption, ;%2 = Bank Account No.';
        UnknownPayerNoErr: Label '%1 cannot be created because %2 is not specified.', Comment = '%1 = Vendor Bank Account TableCaption, %2 = Vendor No. FieldCaption';
    begin
        if UnreliablePayerNoCZL = '' then
            UnreliablePayerNoCZL := Rec."Vendor No.";
        if UnreliablePayerNoCZL = '' then
            Error(UnknownPayerNoErr, VendorBankAccount.TableCaption(), Rec.FieldCaption("Vendor No."));

        TestField("Type", "Type"::"Bank Account");
        TestField("Full Bank Account No.");
        VendorBankAccount.SetRange("Vendor No.", UnreliablePayerNoCZL);
        case "Bank Account Type" of
            "Bank Account Type"::Standard:
                VendorBankAccount.SetRange("Bank Account No.", "Full Bank Account No.");
            "Bank Account Type"::"Not Standard":
                VendorBankAccount.SetRange(IBAN, "Full Bank Account No.");
        end;
        if VendorBankAccount.FindFirst() then
            Error(VendorBankAccountAlreadyExistsErr, VendorBankAccount.TableCaption, VendorBankAccount.Code);

        GetVendBankAccCodeCZL.SetValue(UnreliablePayerNoCZL);
        if GetVendBankAccCodeCZL.RunModal() = Action::OK then begin
            GetVendBankAccCodeCZL.GetValue(VendorBankAccountCode, VendorBankAccountName, PreferredBankAccount);
            Clear(VendorBankAccount);
            VendorBankAccount.Validate("Vendor No.", UnreliablePayerNoCZL);
            VendorBankAccount.Validate(Code, VendorBankAccountCode);
            VendorBankAccount.TestField(Code);
            VendorBankAccount.Validate(Name, VendorBankAccountName);
            case "Bank Account Type" of
                "Bank Account Type"::Standard:
                    VendorBankAccount.Validate("Bank Account No.", "Full Bank Account No.");
                "Bank Account Type"::"Not Standard":
                    VendorBankAccount.Validate(IBAN, "Full Bank Account No.");
            end;
            VendorBankAccount.Insert(true);
            if PreferredBankAccount then
                if Vendor.Get(UnreliablePayerNoCZL) then begin
                    Vendor.Validate("Preferred Bank Account Code", VendorBankAccountCode);
                    Vendor.Modify(true);
                end;
        end;
    end;
}
