table 130062 "Reference Data Log"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry no."; Integer)
        {
            AutoIncrement = true;
        }
        field(2; "Test codeunit ID"; Integer)
        {
        }
        field(3; "Test method name"; Text[30])
        {
        }
        field(4; "Ref. file name"; Text[30])
        {
        }
        field(5; "Table ID"; Integer)
        {
        }
        field(6; "Table name"; Text[30])
        {
            FieldClass = Normal;
        }
        field(7; "Row no."; Integer)
        {
        }
        field(8; "Key"; RecordID)
        {
        }
        field(9; "Field ID"; Integer)
        {
        }
        field(10; "Field name"; Text[30])
        {
        }
        field(11; "Expected value"; Text[30])
        {
        }
        field(12; "Actual value"; Text[30])
        {

            trigger OnValidate()
            begin
                // remove space prefixes and compare
                if DelChr("Expected value", '<', ' ') = DelChr("Actual value", '<', ' ') then
                    Passed := true
                else
                    Passed := false;
            end;
        }
        field(13; Passed; Boolean)
        {
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry no.")
        {
            Clustered = true;
        }
        key(Key2; "Test codeunit ID", "Test method name", "Ref. file name")
        {
        }
        key(Key3; "Test codeunit ID", "Test method name", "Ref. file name", "Actual value")
        {
        }
        key(Key4; "Test codeunit ID", "Test method name")
        {
        }
    }

    fieldgroups
    {
    }
}

