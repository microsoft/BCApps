#pragma warning disable AA0247
tableextension 6162 "E-Doc. Purch. Payables Setup" extends "Purchases & Payables Setup"
{
    fields
    {
#pragma warning disable AA0473
        field(6100; "E-Document Matching Difference"; Decimal)
#pragma warning restore AA0473
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'E-Document Matching Difference %';
            InitValue = 0;
            DecimalPlaces = 1;
            DataClassification = CustomerContent;
        }
#pragma warning disable AL0468
        field(6101; "E-Document Learn Copilot Matchings"; Boolean)
#pragma warning restore AL0468
        {
            Caption = 'E-Document Learn Copilot Matchings';
            DataClassification = SystemMetadata;
        }
        field(6102; "E-Doc. Def. Posting Date"; Enum "E-Doc. Purch.Def. Posting Date")
        {
            Caption = 'E-Document Default Posting Date';
            DataClassification = CustomerContent;
        }
        field(6103; "Apply VAT Diff. For Purch EDoc"; Boolean)
        {
            Caption = 'Apply VAT Diff. For Purch. E-Doc.';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(6104; "Resolve VAT Group Purch EDoc"; Boolean)
        {
            Caption = 'Resolve VAT Product Group for Purch. E-Doc.';
            DataClassification = CustomerContent;
            InitValue = true;
        }
    }
}
