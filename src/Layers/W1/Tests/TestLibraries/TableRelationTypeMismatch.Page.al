page 130100 "Table Relation Type Mismatch"
{
    SourceTable = "Field";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control13)
            {
                ShowCaption = false;
                field(TableName; TableName)
                {
                    ApplicationArea = All;
                }
                field(FieldName; FieldName)
                {
                    ApplicationArea = All;
                }
                field(Type; Type)
                {
                    ApplicationArea = All;
                }
                field(RelationTableNo; RelationTableNo)
                {
                    ApplicationArea = All;
                }
                field(RelationFieldNo; RelationFieldNo)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
        TempTableRelationsMetadata: Record "Table Relations Metadata" temporary;
        "Field": Record "Field";
        TempField: Record "Field" temporary;
        KeepRelation: Boolean;
    begin
        TableRelationsMetadata.SetRange("Table ID", 1, 1999999999);
        TableRelationsMetadata.FindSet();

        repeat
            if not TempField.Get(TableRelationsMetadata."Table ID", TableRelationsMetadata."Field No.") then begin
                Field.Get(TableRelationsMetadata."Table ID", TableRelationsMetadata."Field No.");
                TempField.Copy(Field);
                TempField.Insert();
            end;
            TempTableRelationsMetadata := TableRelationsMetadata;
            TempTableRelationsMetadata.Insert();
        until TableRelationsMetadata.Next() = 0;

        TempField.FindSet();
        repeat
            TempTableRelationsMetadata.SetRange("Field No.", TempField."No.");
            TempTableRelationsMetadata.SetRange("Table ID", TempField.TableNo);
            TempTableRelationsMetadata.FindSet();
            KeepRelation := false;
            repeat
                Field.Get(TempTableRelationsMetadata."Related Table ID", TempTableRelationsMetadata."Related Field No.");
                if Field.Type <> TempField.Type then
                    KeepRelation := true;
            until TempTableRelationsMetadata.Next() = 0;
            if not KeepRelation then
                TempTableRelationsMetadata.DeleteAll();

            if KeepRelation then begin
                Copy(TempField);
                Insert();
            end;
        until TempField.Next() = 0;
        Reset();
        FindFirst();
    end;
}

