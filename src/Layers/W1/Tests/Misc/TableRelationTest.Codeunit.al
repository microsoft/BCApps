codeunit 134926 "Table Relation Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Table Relations Metadata] [Max Field Length]
    end;

    var
        InvalidTableRelationErr: Label 'The type of Table %1 in Field %2 is incompatible with Table %3 Field %4.';

    [Test]
    [Scope('OnPrem')]
    procedure ValidateFieldRelationCompatibility()
    var
        TempTableRelationsMetadata: Record "Table Relations Metadata" temporary;
        CurrentTableID: Integer;
        CurrentFieldID: Integer;
    begin
        CreateTemporaryTablerelations(TempTableRelationsMetadata);
        ExcludeKnownInvalidTableRelationsFromBeingChecked(TempTableRelationsMetadata);

        TempTableRelationsMetadata.FindSet();
        repeat
            if (TempTableRelationsMetadata."Table ID" <> CurrentTableID) or (TempTableRelationsMetadata."Field No." <> CurrentFieldID) then
                if not ValidateFieldRelation(TempTableRelationsMetadata) then
                    Error(InvalidTableRelationErr,
                      TempTableRelationsMetadata."Table ID", TempTableRelationsMetadata."Field No.",
                      TempTableRelationsMetadata."Related Table ID", TempTableRelationsMetadata."Related Field No.");
            CurrentTableID := TempTableRelationsMetadata."Table ID";
            CurrentFieldID := TempTableRelationsMetadata."Field No.";
        until TempTableRelationsMetadata.Next() = 0;
    end;

    local procedure ValidateFieldRelation(var TempTableRelationsMetadata: Record "Table Relations Metadata" temporary): Boolean
    var
        TempTableRelationsMetadataBufferIter: Record "Table Relations Metadata" temporary;
        "Field": Record "Field";
        RelatedField: Record "Field";
        MaxRelatedFieldLength: Integer;
        RequiredFieldType: Text;
        MustHaveTableRelation: Boolean;
    begin
        // <Summary> Fields must have the exact length of the largest field they relate to.
        // <Summary> Fields must have the same type as the fields they relate to. Exception: if it relates to both Code and Text it must be Text
        if not (TempTableRelationsMetadata."Test Table Relation" and TempTableRelationsMetadata."Validate Table Relation") then
            exit(true);

        // Loop through all relations this field has to find its required length and type
        TempTableRelationsMetadataBufferIter.Copy(TempTableRelationsMetadata, true);
        TempTableRelationsMetadataBufferIter.SetRange("Table ID", TempTableRelationsMetadata."Table ID");
        TempTableRelationsMetadataBufferIter.SetRange("Field No.", TempTableRelationsMetadata."Field No.");
        TempTableRelationsMetadataBufferIter.FindSet();
        repeat
            RelatedField.Get(TempTableRelationsMetadataBufferIter."Related Table ID",
              TempTableRelationsMetadataBufferIter."Related Field No.");
            MaxRelatedFieldLength := MaxInt(MaxRelatedFieldLength, RelatedField.Len);
            RequiredFieldType := FindRequiredFieldType(RequiredFieldType, Format(RelatedField.Type));
            if TempTableRelationsMetadataBufferIter."Condition Field No." = 0 then
                MustHaveTableRelation := true;
        until TempTableRelationsMetadataBufferIter.Next() = 0;

        // Verify this field has correct length and type
        Field.Get(TempTableRelationsMetadata."Table ID", TempTableRelationsMetadata."Field No.");

        if not MustHaveTableRelation then begin
            // There may be conditions without a table relation, only validate that table relations can be stored in this field.

            if Field.Len < MaxRelatedFieldLength then
                exit(false);

            if (RequiredFieldType = 'Code') and (Field.Type in [Field.Type::Text, Field.Type::Code]) then
                exit(true);

            exit(Format(Field.Type) = RequiredFieldType);
        end;

        if Field.Len <> MaxRelatedFieldLength then
            exit(false);

        exit(Format(Field.Type) = RequiredFieldType);
    end;

    local procedure MaxInt(Value1: Integer; Value2: Integer): Integer
    begin
        if Value1 > Value2 then
            exit(Value1);
        exit(Value2);
    end;

    local procedure FindRequiredFieldType(RequiredFieldType: Text; RelatedFieldType: Text): Text
    begin
        if RequiredFieldType = '' then
            exit(RelatedFieldType);

        if RequiredFieldType = RelatedFieldType then
            exit(RequiredFieldType);

        if (RequiredFieldType in ['Text', 'Code']) and (RelatedFieldType in ['Text', 'Code']) then
            exit('Text'); // Only a text field will be able to refer to both a text and code field.

        exit('Invalid Relation');
    end;

    local procedure ExcludeKnownInvalidTableRelationsFromBeingChecked(var TableRelationsMetadata: Record "Table Relations Metadata" temporary)
    begin
        RemoveTableRelation(TableRelationsMetadata, 0, 0, 17359, 1);
        OnAfterRemoveTableRelation(TableRelationsMetadata);
        TableRelationsMetadata.Reset();
    end;

    procedure RemoveTableRelation(var TableRelationsMetadata: Record "Table Relations Metadata" temporary; TableID: Integer; FieldID: Integer; RelatedTableID: Integer; RelatedFieldID: Integer)
    begin
        TableRelationsMetadata.Reset();
        if TableID <> 0 then
            TableRelationsMetadata.SetRange("Table ID", TableID);
        if FieldID <> 0 then
            TableRelationsMetadata.SetRange("Field No.", FieldID);
        if RelatedTableID <> 0 then
            TableRelationsMetadata.SetRange("Related Table ID", RelatedTableID);
        if RelatedFieldID <> 0 then
            TableRelationsMetadata.SetRange("Related Field No.", RelatedFieldID);
        TableRelationsMetadata.DeleteAll();
    end;

    local procedure CreateTemporaryTablerelations(var TempTableRelationsMetadata: Record "Table Relations Metadata" temporary)
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
    begin
        TableRelationsMetadata.SetRange("Table ID", 1, 1999999999);
        TableRelationsMetadata.FindSet();

        repeat
            TempTableRelationsMetadata := TableRelationsMetadata;
            TempTableRelationsMetadata.Insert();
        until TableRelationsMetadata.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRemoveTableRelation(var TableRelationsMetadata: Record "Table Relations Metadata" temporary)
    begin
    end;
}

