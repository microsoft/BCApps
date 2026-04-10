table 130060 "Reference data - field list"
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
            Error(Text001, FieldName("Table ID"));
        if "Field ID" = 0 then
            Error(Text001, FieldName("Field ID"));
    end;
}

