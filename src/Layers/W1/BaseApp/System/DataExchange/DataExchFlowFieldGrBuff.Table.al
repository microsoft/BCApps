namespace System.IO;

table 1239 "Data Exch. FlowField Gr. Buff."
{
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Record ID"; RecordId)
        {
            Caption = 'Record ID';
        }
        field(2; "Field ID"; Integer)
        {
            Caption = 'Field ID';
        }
        field(3; "Value"; Decimal)
        {
            Caption = 'Value';
        }
    }

    keys
    {
        key(Key1; "Record ID", "Field ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
