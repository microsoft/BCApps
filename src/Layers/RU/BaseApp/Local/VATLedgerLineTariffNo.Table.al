#pragma warning disable AA0247
table 12412 "VAT Ledger Line Tariff No."
{
    Caption = 'VAT Ledger Line Tariff No.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Purchase,Sales';
            OptionMembers = Purchase,Sales;
            TableRelation = "VAT Ledger".Type;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            TableRelation = "VAT Ledger".Code where(Type = field(Type));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Tariff No."; Code[20])
        {
            Caption = 'Tariff No.';
        }
    }

    keys
    {
        key(Key1; Type, "Code", "Line No.", "Tariff No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure SetFilterVATLedgerLine(VATLedgerLine: Record "VAT Ledger Line")
    begin
        SetRange(Type, VATLedgerLine.Type);
        SetRange(Code, VATLedgerLine.Code);
        SetRange("Line No.", VATLedgerLine."Line No.");
    end;
}

