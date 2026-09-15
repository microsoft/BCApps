codeunit 132220 "Library - Utility OnPrem"
{
    var
        PropertyValueUndefinedError: Label 'Property value is not defined.';
        ControlForFieldNotFoundError: Label 'Control for field %1 does not exist in Page %2.';
        FieldNotFoundError: Label 'Field %1 does not exist in Table %2.';

    procedure CheckFileNotEmpty(FileName: Text): Boolean
    var
        File: File;
    begin
        // The parameter FileName should contain the full File Name including path.
        if FileName = '' then
            exit(false);
        if File.Open(FileName) then
            if File.Len > 0 then
                exit(true);
        exit(false);
    end;

    procedure FindControl(ObjectNo: Integer; FieldNo: Integer): Boolean
    var
        AppObjectMetadata: Record "Application Object Metadata";
        AllObj: Record AllObj;
        MetaDataInstream: InStream;
        TestString: Text[1024];
    begin
        TestString := '';

        AllObj.Get(AllObj."Object Type"::Page, ObjectNo);
        AppObjectMetadata.Get(AllObj."App Runtime Package ID", AppObjectMetadata."Object Type"::Page, ObjectNo);
        AppObjectMetadata.CalcFields(Metadata);
        if AppObjectMetadata.Metadata.HasValue() then
            AppObjectMetadata.Metadata.CreateInStream(MetaDataInstream);

        while not MetaDataInstream.EOS do begin
            MetaDataInstream.ReadText(TestString);
            if StrPos(TestString, 'DataColumnName="' + Format(FieldNo) + '"') <> 0 then
                exit(true);
        end;
        exit(false);
    end;

    procedure FindEditable(ObjectNo: Integer; FieldNo: Integer): Boolean
    var
        Editable: Text[30];
    begin
        // Find and return the Editable property for a page control. Generate an error if page control does not exists.
        Editable := GetPropertyValueForControl(ObjectNo, FieldNo, 'Editable="', true);
        if Editable = 'FALSE' then
            exit(false);
        if (Editable = '') or (Editable = 'TRUE') then
            exit(true);
    end;

    procedure FindMaxValueForField(ObjectNo: Integer; FieldNo: Integer) MaximumValue: Integer
    begin
        Evaluate(MaximumValue, GetPropertyValueForField(ObjectNo, FieldNo, 'MaxValue="', false));
        exit(MaximumValue);
    end;

    procedure FindMinValueForField(ObjectNo: Integer; FieldNo: Integer) MinimumValue: Integer
    begin
        Evaluate(MinimumValue, GetPropertyValueForField(ObjectNo, FieldNo, 'MinValue="', false));
        exit(MinimumValue);
    end;

    procedure FindVisible(ObjectNo: Integer; FieldNo: Integer): Boolean
    var
        Visible: Text[30];
    begin
        Visible := GetPropertyValueForControl(ObjectNo, FieldNo, 'Visible="', true);
        if Visible = 'FALSE' then
            exit(false);
        if (Visible = '') or (Visible = 'TRUE') then
            exit(true);
    end;

    procedure GetPropertyValueForControl(ObjectNo: Integer; FieldNo: Integer; PropertyName: Text[30]; SuppressError: Boolean): Text[30]
    var
        AppObjectMetadata: Record "Application Object Metadata";
    begin
        exit(GetPropertyValue(AppObjectMetadata."Object Type"::Page, ObjectNo, FieldNo, PropertyName, SuppressError));
    end;

    procedure GetPropertyValueForField(ObjectNo: Integer; FieldNo: Integer; PropertyName: Text[30]; SuppressError: Boolean): Text[30]
    var
        AppObjectMetadata: Record "Application Object Metadata";
    begin
        exit(GetPropertyValue(AppObjectMetadata."Object Type"::Table, ObjectNo, FieldNo, PropertyName, SuppressError));
    end;

    procedure GetInetRoot(): Text
    begin
        exit(ApplicationPath + '\..\..\');
    end;

    local procedure GetPropertyValue(ObjectType: Option; ObjectNo: Integer; FieldNo: Integer; PropertyName: Text[30]; SuppressError: Boolean): Text[30]
    var
        AppObjectMetadata: Record "Application Object Metadata";
        AllObj: Record AllObj;
        MetaDataInstream: InStream;
        ControlFound: Boolean;
        TestString: Text[1024];
    begin
        AllObj.Get(ObjectType, ObjectNo);
        AppObjectMetadata.Get(AllObj."App Runtime Package ID", ObjectType, ObjectNo);
        AppObjectMetadata.CalcFields(Metadata);
        if AppObjectMetadata.Metadata.HasValue() then
            AppObjectMetadata.Metadata.CreateInStream(MetaDataInstream);

        while not MetaDataInstream.EOS do begin
            MetaDataInstream.ReadText(TestString);
            if StrPos(TestString, GetTextValue(ObjectType) + Format(FieldNo) + '"') <> 0 then begin
                ControlFound := true;
                if StrPos(TestString, PropertyName) <> 0 then begin
                    TestString := CopyStr(TestString, StrPos(TestString, PropertyName) + StrLen(PropertyName), 10);
                    exit(CopyStr(TestString, 1, StrPos(TestString, '"') - 1));
                end;
                if (StrPos(TestString, '/>') <> 0) and not SuppressError then
                    Error(PropertyValueUndefinedError);
            end;
        end;
        if not ControlFound then begin
            if ObjectType = AppObjectMetadata."Object Type"::Page then
                Error(ControlForFieldNotFoundError, FieldNo, ObjectNo);
            Error(FieldNotFoundError, FieldNo, ObjectNo);
        end;
        exit('');
    end;

    local procedure GetTextValue(ObjectType: Option): Text[30]
    var
        AppObjectMetadata: Record "Application Object Metadata";
    begin
        if ObjectType = AppObjectMetadata."Object Type"::Page then
            exit('DataColumnName="');
        exit('Field ID="');
    end;
}