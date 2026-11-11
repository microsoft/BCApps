#pragma warning disable AS0103, PTE0004 // Accepted: this test-only table is intentionally not exposed through production permission sets. Tracked by AB#640773.
table 130060 "Reference data - field list"
#pragma warning restore AS0103, PTE0004
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Ref. file name"; Text[30])
        {
            NotBlank = true;
        }

        field(2; "Table ID"; Integer)
        {
            TableRelation = AllObj."Object ID" where("Object Type" = const(Table));
        }
        field(3; "Table name"; Text[30])
        {
            CalcFormula = lookup(AllObj."Object Name" where("Object Type" = const(Table),
                                                             "Object ID" = field("Table ID")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Field ID"; Integer)
        {
            TableRelation = Field."No." where(TableNo = field("Table ID"));
        }
        field(5; "Field name"; Text[30])
        {
            CalcFormula = lookup(Field.FieldName where(TableNo = field("Table ID"),
                                                        "No." = field("Field ID")));
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Ref. file name", "Table ID", "Field ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        CheckForZeroValues();
    end;

    trigger OnModify()
    begin
        // CheckForZeroValues;
    end;

    var
        Text001: Label 'A value of ''0'' is not allowed for field ''%1''.';

    local procedure CheckForZeroValues()
    begin
        if "Table ID" = 0 then
            Error(Text001, FieldCaption("Table ID"));
        if "Field ID" = 0 then
            Error(Text001, FieldCaption("Field ID"));
    end;
}

