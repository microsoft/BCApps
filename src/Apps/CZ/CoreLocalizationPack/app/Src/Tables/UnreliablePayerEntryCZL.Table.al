// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Finance.VAT.Registration;

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
#if not CLEANSCHEMA33
        field(8; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No. (Obsolete)';
            TableRelation = Vendor;
#if not CLEAN30
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '33.0';
#endif
            ObsoleteReason = 'Unreliable payer entries are shared by VAT registration number and are no longer linked to a specific vendor.';
        }
#endif
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
            Caption = 'Unreliable Payer (Obsolete)';
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
            Caption = 'Entry Type (Obsolete)';
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
        }
#if not CLEANSCHEMA33
        field(61; "Bank Account No. Type"; Option)
        {
            Caption = 'Bank Account No. Type (Obsolete)';
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
#if not CLEAN30
        field(70; "Vendor Name"; Text[100])
        {
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
            Caption = 'Vendor Name (Obsolete)';
            FieldClass = FlowField;
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';
            ObsoleteReason = 'Unreliable payer entries are shared by VAT registration number and are no longer linked to a specific vendor.';
        }
#endif
    }
    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
#if not CLEAN30
        key(Key2; "Vendor No.", "Check Date")
        {
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';
            ObsoleteReason = 'The vendor-specific key is no longer needed. Entries are accessed by VAT registration number.';
        }
        key(Key3; "VAT Registration No.", "Vendor No.", "Check Date")
        {
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';
            ObsoleteReason = 'The vendor-specific key is no longer needed. Entries are accessed by VAT registration number.';
        }
        key(Key4; "Vendor No.", "Entry Type", "Full Bank Account No.", "End Public Date")
        {
            ObsoleteState = Pending;
            ObsoleteTag = '30.0';
            ObsoleteReason = 'The vendor-specific key is no longer needed. Entries are accessed by VAT registration number.';
        }
#endif
        key(Key5; "VAT Registration No.", "Type", "Check Date")
        {
        }
    }

#if not CLEAN30
    [Obsolete('Use CreateBankAccountCZL for creation without UI or CreateBankAccountWithDialogCZL for interactive creation.', '30.0')]
    procedure CreateVendorBankAccountCZL(UnreliablePayerNoCZL: Code[20]);
    var
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
            CreateBankAccountCZL(Enum::"Unrel. Payer Account Type CZL"::Vendor, UnreliablePayerNoCZL, VendorBankAccountCode, VendorBankAccountName, PreferredBankAccount);
        end;
    end;
#endif

    procedure CheckBankAccountCreationPossible()
    begin
        TestField(Type, Type::"Bank Account");
        TestField("Full Bank Account No.");
        TestField("VAT Registration No.");
    end;

    procedure CreateBankAccountCZL(AccountType: Enum "Unrel. Payer Account Type CZL"; AccountNo: Code[20]; BankAccountCode: Code[10]; BankAccountName: Text[100]; PreferredBankAccount: Boolean): RecordId
    var
        UnreliableAccountCZL: Interface "Unreliable Account CZL";
    begin
        UnreliableAccountCZL := AccountType;
        exit(UnreliableAccountCZL.CreateBankAccount(Rec, AccountNo, BankAccountCode, BankAccountName, PreferredBankAccount));
    end;

    procedure CreateBankAccountWithDialogCZL()
    var
        GetBankAccountCodeCZL: Page "Get Vend. Bank Acc. Code CZL";
        AccountType: Enum "Unrel. Payer Account Type CZL";
        AccountNo: Code[20];
        BankAccountCode: Code[10];
        BankAccountName: Text[100];
        PreferredBankAccount: Boolean;
    begin
        CheckBankAccountCreationPossible();
        GetBankAccountCodeCZL.SetVATRegistrationNo("VAT Registration No.");
        if GetBankAccountCodeCZL.RunModal() <> Action::OK then
            exit;
        GetBankAccountCodeCZL.GetAccount(AccountType, AccountNo);
        GetBankAccountCodeCZL.GetValue(BankAccountCode, BankAccountName, PreferredBankAccount);
        CreateBankAccountCZL(AccountType, AccountNo, BankAccountCode, BankAccountName, PreferredBankAccount);
    end;
}
