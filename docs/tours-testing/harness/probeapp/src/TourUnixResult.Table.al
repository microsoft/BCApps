namespace Tour.UnixTimestamp;

table 50100 "Tour Unix Result"
{
    DataClassification = SystemMetadata;
    Caption = 'Tour Unix Result';

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; "Probe"; Text[50]) { }
        field(3; "Case Name"; Text[100]) { }
        field(4; "Input Ts"; BigInteger) { }
        field(5; "Tz Setting"; Text[180]) { }
        field(6; "Offset Ms"; BigInteger) { }
        field(7; "Offset Ok"; Boolean) { }
        field(10; "Old Result"; Text[100]) { }
        field(11; "Old Error"; Text[250]) { }
        field(12; "Manual Old Result"; Text[100]) { }
        field(13; "Manual Old Error"; Text[250]) { }
        field(20; "New Result"; Text[100]) { }
        field(21; "New Error"; Text[250]) { }
        field(30; "Round Trip Ts"; BigInteger) { }
        field(31; "Round Trip Error"; Text[250]) { }
        field(32; "Round Trip Ok"; Boolean) { }
        field(40; "Irs Epoch Ts"; BigInteger) { }
        field(41; "Irs Epoch Error"; Text[250]) { }
        field(50; "Note"; Text[250]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
