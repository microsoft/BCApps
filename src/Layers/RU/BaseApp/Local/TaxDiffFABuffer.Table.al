#pragma warning disable AA0247
table 17324 "Tax Diff. FA Buffer"
{
    Caption = 'Tax Diff. FA Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            DataClassification = SystemMetadata;
            TableRelation = "Fixed Asset";
        }
        field(2; "Tax Difference Code"; Code[10])
        {
            Caption = 'Tax Difference Code';
            DataClassification = SystemMetadata;
        }
        field(3; Description; Text[80])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(4; Difference; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            Caption = 'Difference';
            DataClassification = SystemMetadata;
        }
        field(5; "Amount (Base)"; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            Caption = 'Amount (Base)';
            DataClassification = SystemMetadata;
        }
        field(6; "Amount (Tax)"; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            Caption = 'Amount (Tax)';
            DataClassification = SystemMetadata;
        }
        field(7; "Tax Amount"; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            Caption = 'Tax Amount';
            DataClassification = SystemMetadata;
        }
        field(8; "FA Type"; Option)
        {
            Caption = 'FA Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Fixed Assets,Intangible Asset,Future Expense';
            OptionMembers = "Fixed Assets","Intangible Asset","Future Expense";
        }
    }

    keys
    {
        key(Key1; "FA No.", "Tax Difference Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        FixedAsset: Record "Fixed Asset";

    [Scope('OnPrem')]
    procedure DrillDownAmount()
    var
        TaxDiffLedgerEntry: Record "Tax Diff. Ledger Entry";
    begin
        TaxDiffLedgerEntry.SetCurrentKey("Tax Diff. Code", "Source Type", "Source No.", "Posting Date");
        FixedAsset.Get("FA No.");
        TaxDiffLedgerEntry.FilterGroup(2);
        TaxDiffLedgerEntry.SetRange("Source Type", FixedAsset.GetTDESourceType());
        TaxDiffLedgerEntry.SetRange("Source No.", "FA No.");
        TaxDiffLedgerEntry.SetRange("Tax Diff. Code", "Tax Difference Code");
        TaxDiffLedgerEntry.FilterGroup(0);
        PAGE.RunModal(0, TaxDiffLedgerEntry);
    end;
}

