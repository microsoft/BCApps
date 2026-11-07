table 134399 "Table With PK 16 Fields"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Field1; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = if (Field6 = const("1")) Customer
            else
            if (Field6 = const("2")) Contact
            else
            if (Field6 = const("3")) Vendor;
        }
        field(2; Field2; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(3; Field3; Text[30])
        {
            DataClassification = SystemMetadata;
        }
        field(4; Field4; Date)
        {
            DataClassification = SystemMetadata;
        }
        field(5; Field5; Decimal)
        {
            DataClassification = SystemMetadata;
            AutoFormatType = 0;
        }
        field(6; Field6; Option)
        {
            DataClassification = SystemMetadata;
            OptionMembers = "0","1","2","3";
        }
        field(7; Field7; DateTime)
        {
            DataClassification = SystemMetadata;
        }
        field(8; Field8; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(9; Field9; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(10; Field10; Duration)
        {
            DataClassification = SystemMetadata;
        }
        field(11; Field11; RecordID)
        {
            DataClassification = SystemMetadata;
        }
        field(12; Field12; Time)
        {
            DataClassification = SystemMetadata;
        }
        field(13; Field13; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(14; Field14; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(15; Field15; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(16; Field16; Code[10])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Field1, Field2, Field3, Field4, Field5, Field6, Field7, Field8, Field9, Field10, Field11, Field12, Field13, Field14, Field15)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        LibraryRandom: Codeunit "Library - Random";

    [Scope('OnPrem')]
    procedure Create(Type: Option; "Code": Code[20]; RecID: RecordID)
    begin
        Init();
        Field6 := Type;
        Field1 := Code;
        Field2 := LibraryRandom.RandInt(1000);
        Field3 := CopyStr(LibraryRandom.RandText(30), 1, 30);
        Field4 := Today;
        Field5 := LibraryRandom.RandDec(1000, 2);
        Field7 := CurrentDateTime;
        Field8 := CreateGuid();
        Field9 := true;
        Field10 := CurrentDateTime - Field7;
        Field11 := RecID;
        Field12 := Time;
        Field13 := CopyStr(LibraryRandom.RandText(10), 1, 10);
        Field14 := CopyStr(LibraryRandom.RandText(10), 1, 10);
        Field15 := CopyStr(LibraryRandom.RandText(10), 1, 10);
        Field16 := CopyStr(LibraryRandom.RandText(9), 1, 9);
        Insert();
    end;
}
