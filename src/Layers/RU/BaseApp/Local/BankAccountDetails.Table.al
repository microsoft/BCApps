#pragma warning disable AA0247
table 12436 "Bank Account Details"
{
    Caption = 'Bank Account Details';
    DrillDownPageID = "Bank Account Details";
    LookupPageID = "Bank Account Details";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(21; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            NotBlank = true;

            trigger OnValidate()
            begin
                CheckBankAccountDetails();
            end;
        }
        field(22; "Bank Account No."; Code[30])
        {
            Caption = 'Bank Account No.';
            NotBlank = true;

            trigger OnValidate()
            begin
                CheckBankAccountDetails();
            end;
        }
        field(23; "G/L Account"; Code[20])
        {
            Caption = 'G/L Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            var
                GLAccount: Record "G/L Account";
            begin
                TestField("G/L Account");
                if "G/L Account" <> xRec."G/L Account" then begin
                    GLAccount.Get("G/L Account");
                    "G/L Account Name" := GLAccount.Name;
                end;
            end;
        }
        field(24; "G/L Account Name"; Text[100])
        {
            Caption = 'G/L Account Name';
        }
        field(25; "Bank BIC"; Code[9])
        {
            Caption = 'Bank BIC';
            TableRelation = "Bank Directory".BIC;
        }
        field(26; "Transit No."; Text[20])
        {
            Caption = 'Transit No.';
        }
        field(27; "Bank City"; Text[20])
        {
            Caption = 'Bank City';
        }
        field(28; "Bank Name"; Text[100])
        {
            Caption = 'Bank Name';
        }
        field(29; "Shortcut Dimension Code 1"; Code[20])
        {
            Caption = 'Shortcut Dimension Code 1';
        }
        field(30; "Shortcut Dimension Code 2"; Code[20])
        {
            Caption = 'Shortcut Dimension Code 2';
        }
        field(31; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment,Refund';
            OptionMembers = " ",Payment,Refund;
        }
        field(32; "KPP Code"; Code[10])
        {
            Caption = 'KPP Code';

            trigger OnValidate()
            begin
                CheckBankAccountDetails();
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
    }

    trigger OnInsert()
    begin
        TestField("VAT Registration No.");
        TestField("Bank Account No.");
        TestField("G/L Account");
        CheckBankAccountDetails();
    end;

    var
        BankAccDetails: Record "Bank Account Details";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Bank Account Details with VAT Registration No. %1, KPP Code %2, Bank Account No. %3 already exist.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure CheckBankAccountDetails()
    begin
        BankAccDetails.SetRange("VAT Registration No.", "VAT Registration No.");
        BankAccDetails.SetRange("Bank Account No.", "VAT Registration No.");
        BankAccDetails.SetRange("KPP Code", "KPP Code");
        if not BankAccDetails.IsEmpty() then
            Error(Text001, "VAT Registration No.", "KPP Code", "Bank Account No.");
    end;
}

