#pragma warning disable AA0247
table 2000043 "Transaction Coding"
{
    Caption = 'Transaction Coding';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
            ValidateTableRelation = false;
        }
        field(2; "Transaction Family"; Integer)
        {
            Caption = 'Transaction Family';
        }
        field(3; Transaction; Integer)
        {
            Caption = 'Transaction';
        }
        field(4; "Transaction Category"; Integer)
        {
            Caption = 'Transaction Category';
        }
        field(5; "Globalisation Code"; Option)
        {
            Caption = 'Globalisation Code';
            OptionCaption = 'Global,Detail';
            OptionMembers = Global,Detail;
        }
        field(6; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = ' ,G/L Account,Customer,Vendor,Bank Account';
            OptionMembers = " ","G/L Account",Customer,Vendor,"Bank Account";

            trigger OnValidate()
            begin
                "Account No." := '';
            end;
        }
        field(7; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const("Bank Account")) "Bank Account";
        }
        field(8; Description; Text[50])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Bank Account No.", "Transaction Family", Transaction, "Transaction Category")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if "Account Type" = 1 then begin
            TestField("Account No.");
            Validate("Account No.");
        end
    end;

    trigger OnModify()
    begin
        if "Account Type" = 1 then begin
            TestField("Account No.");
            Validate("Account No.");
        end
    end;
}

