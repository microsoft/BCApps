namespace System.DataAdministration;

tableextension 3999 "Reten. Pol. Setup Line Ext." extends "Retention Policy Setup Line"
{
    fields
    {
        field(3999; "Keep Last Version"; Boolean)
        {
            Caption = 'Keep Last Document Version';
            DataClassification = CustomerContent;
            InitValue = false;
        }
    }
}