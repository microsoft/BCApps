codeunit 132215 "Library - Error Message"
{

    trigger OnRun()
    begin
    end;

    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeManagement: Codeunit "Data Type Management";
        Assert: Codeunit Assert;
        ErrorMessages: TestPage "Error Messages";
        IfEmptyErr: Label '''%1'' in ''%2'' must not be blank.', Comment = '%1=caption of a field, %2=key of record';
        IfLengthExceededErr: Label 'The maximum length of ''%1'' in ''%2'' is %3 characters. The actual length is %4.', Comment = '%1=caption of a field, %2=key of record, %3=integer, %4=integer';
        IfInvalidCharactersErr: Label '''%1'' in ''%2'' contains invalid characters.', Comment = '%1=caption of a field, %2=key of record';
        IfOutsideRangeErr: Label '''%1'' in ''%2'' is outside of the permitted range from %3 to %4.', Comment = '%1=caption of a field, %2=key of record, %3=integer, %4=integer';
        IfGreaterThanErr: Label '''%1'' in ''%2'' must be less or equal to %3.', Comment = '%1=caption of a field, %2=key of record, %3=integer';
        IfLessThanErr: Label '''%1'' in ''%2'' must be greater or equal to %3.', Comment = '%1=caption of a field, %2=key of record, %3=integer';
        IfEqualToErr: Label '''%1'' in ''%2'' must not be equal to %3.', Comment = '%1=caption of a field, %2=key of record, %3=integer';
        IfNotEqualToErr: Label '''%1'' in ''%2'' must be equal to %3.', Comment = '%1=caption of a field, %2=key of record, %3=integer';
        StringLengthCorrectErr: Label 'String length is correct even though it should not be.';
        ErrorMessageNotFoundTxt: Label 'Error message with description %1 and type %2 was not found.';
        NoValidRecordErr: Label 'No valid record was specified.';
        MissingAccountTxt: Label '%1 is missing in %2.', Comment = '%1 = Field caption, %2 = Table caption';

    procedure Clear()
    begin
        TempErrorMessage.Reset();
        TempErrorMessage.DeleteAll();
        SYSTEM.Clear(TempErrorMessage);
    end;

    procedure DrillDownOnContext()
    begin
        ErrorMessages.Context.DrillDown();
    end;

    procedure DrillDownOnSource()
    begin
        ErrorMessages.Source.DrillDown();
    end;

    procedure TrapErrorMessages()
    begin
        ErrorMessages.Trap();
    end;

    procedure LoadErrorMessages()
    begin
        if ErrorMessages.First() then
            repeat
                TempErrorMessage.Init();
                TempErrorMessage.ID += 1;
                Evaluate(TempErrorMessage."Message Type", ErrorMessages."Message Type".Value);
                TempErrorMessage."Message" := ErrorMessages.Description.Value();
                Evaluate(TempErrorMessage."Record ID", ErrorMessages.Source.Value, 9);
                TempErrorMessage.Validate("Record ID");
                TempErrorMessage.Validate("Field Number", GetFieldNo(TempErrorMessage."Table Number", ErrorMessages."Field Name".Value));
                Evaluate(TempErrorMessage."Context Record ID", ErrorMessages.Context.Value, 9);
                TempErrorMessage.Validate("Context Record ID");
                TempErrorMessage.Validate(
                  "Context Field Number", GetFieldNo(TempErrorMessage."Context Table Number", ErrorMessages."Context Field Name".Value));
                TempErrorMessage."Additional Information" := ErrorMessages."Additional Information".Value();
                TempErrorMessage."Support Url" := ErrorMessages."Support Url".Value();
                TempErrorMessage.SetErrorCallStack(ErrorMessages.CallStack.Value);
                TempErrorMessage.Insert();
            until not ErrorMessages.Next();
    end;

    procedure GetErrorMessages(var TempErrorMessageBuf: Record "Error Message" temporary)
    begin
        LoadErrorMessages();
        TempErrorMessageBuf.Copy(TempErrorMessage, true);
    end;

    local procedure GetFieldNo(TableNo: Integer; FieldName: Text): Integer
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, TableNo);
        Field.SetRange("Field Caption", FieldName);
        if Field.FindFirst() then
            exit(Field."No.");
    end;

    procedure GetTestPage(var ErrorMessagesPage: TestPage "Error Messages")
    begin
        ErrorMessagesPage := ErrorMessages;
    end;

    procedure AssertLogIfMessageExists(RecRelatedVariant: Variant; FieldNumber: Integer; ExpectedMessageType: Option)
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        ExpectedDescription: Text;
    begin
        AssertGetRecordRefAndFieldRef(RecRelatedVariant, FieldNumber, RecordRef, FieldRef);

        ExpectedDescription := StrSubstNo(IfEmptyErr, FieldRef.Caption, Format(RecordRef.RecordId));
        AssertMessageExists(ExpectedDescription, ExpectedMessageType);
    end;

    procedure AssertLogIfLengthExceededExists(RecRelatedVariant: Variant; FieldNumber: Integer; ExpectedMessageType: Option; MaxLength: Integer)
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        ExpectedDescription: Text;
        StringLength: Integer;
    begin
        AssertGetRecordRefAndFieldRef(RecRelatedVariant, FieldNumber, RecordRef, FieldRef);

        StringLength := StrLen(Format(FieldRef.Value));
        if StringLength <= MaxLength then
            Error(StringLengthCorrectErr);

        ExpectedDescription := StrSubstNo(IfLengthExceededErr, FieldRef.Caption, Format(RecordRef.RecordId), MaxLength, StringLength);

        AssertMessageExists(ExpectedDescription, ExpectedMessageType);
    end;

    procedure AssertLogIfInvalidCharactersExists(RecRelatedVariant: Variant; FieldNumber: Integer; MessageType: Option)
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        ExpectedDescription: Text;
    begin
        AssertGetRecordRefAndFieldRef(RecRelatedVariant, FieldNumber, RecordRef, FieldRef);

        ExpectedDescription := StrSubstNo(IfInvalidCharactersErr, FieldRef.Caption, Format(RecordRef.RecordId));
        AssertMessageExists(ExpectedDescription, MessageType);
    end;

    procedure AssertLogIfOutsideRangeExists(RecRelatedVariant: Variant; FieldNumber: Integer; MessageType: Option; LowerBound: Variant; UpperBound: Variant)
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        ExpectedDescription: Text;
    begin
        AssertGetRecordRefAndFieldRef(RecRelatedVariant, FieldNumber, RecordRef, FieldRef);

        ExpectedDescription := StrSubstNo(IfOutsideRangeErr, FieldRef.Caption, Format(RecordRef.RecordId), LowerBound, UpperBound);
        AssertMessageExists(ExpectedDescription, MessageType);
    end;

    procedure AssertLogIfGreaterThanExists(RecRelatedVariant: Variant; FieldNumber: Integer; MessageType: Option; LowerBound: Variant)
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        ExpectedDescription: Text;
    begin
        AssertGetRecordRefAndFieldRef(RecRelatedVariant, FieldNumber, RecordRef, FieldRef);

        ExpectedDescription := StrSubstNo(IfGreaterThanErr, FieldRef.Caption, Format(RecordRef.RecordId), LowerBound);
        AssertMessageExists(ExpectedDescription, MessageType);
    end;

    procedure AssertLogIfLessThanExists(RecRelatedVariant: Variant; FieldNumber: Integer; MessageType: Option; UpperBound: Variant)
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        ExpectedDescription: Text;
    begin
        AssertGetRecordRefAndFieldRef(RecRelatedVariant, FieldNumber, RecordRef, FieldRef);

        ExpectedDescription := StrSubstNo(IfLessThanErr, FieldRef.Caption, Format(RecordRef.RecordId), UpperBound);
        AssertMessageExists(ExpectedDescription, MessageType);
    end;

    procedure AssertLogIfEqualToExists(RecRelatedVariant: Variant; FieldNumber: Integer; MessageType: Option; ValueVariant: Variant)
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        ExpectedDescription: Text;
    begin
        AssertGetRecordRefAndFieldRef(RecRelatedVariant, FieldNumber, RecordRef, FieldRef);

        ExpectedDescription := StrSubstNo(IfEqualToErr, FieldRef.Caption, Format(RecordRef.RecordId), ValueVariant);
        AssertMessageExists(ExpectedDescription, MessageType);
    end;

    procedure AssertLogIfNotEqualToExists(RecRelatedVariant: Variant; FieldNumber: Integer; MessageType: Option; ValueVariant: Variant)
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        ExpectedDescription: Text;
    begin
        AssertGetRecordRefAndFieldRef(RecRelatedVariant, FieldNumber, RecordRef, FieldRef);

        ExpectedDescription := StrSubstNo(IfNotEqualToErr, FieldRef.Caption, Format(RecordRef.RecordId), ValueVariant);
        AssertMessageExists(ExpectedDescription, MessageType);
    end;

    procedure AssertLogSimpleMessageExists(MessageType: Option; ExpectedDescription: Text)
    begin
        AssertMessageExists(ExpectedDescription, MessageType);
    end;

    local procedure AssertMessageExists(ExpectedDescription: Text; MessageType: Option)
    begin
        TempErrorMessage.Reset();
        TempErrorMessage.SetRange("Message", ExpectedDescription);
        TempErrorMessage.SetRange("Message Type", MessageType);
        Assert.IsFalse(TempErrorMessage.IsEmpty,
          StrSubstNo(ErrorMessageNotFoundTxt,
            ExpectedDescription, MessageType));
    end;

    procedure GetMissingAccountErrorMessage(FieldCaption: Text; TableCaption: Text): Text
    begin
        exit(StrSubstNo(MissingAccountTxt, FieldCaption, TableCaption));
    end;

    procedure GetMissingAccountErrorMessage(FieldCaption: Text; VariantRec: Variant): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(VariantRec);
        RecRef.SetRecFilter();
        exit(StrSubstNo(MissingAccountTxt, FieldCaption, RecRef.Caption() + ' ' + RecRef.GetFilters()));
    end;

    local procedure AssertGetRecordRefAndFieldRef(RecRelatedVariant: Variant; FieldNumber: Integer; var RecordRef: RecordRef; var FieldRef: FieldRef)
    begin
        if not DataTypeManagement.GetRecordRefAndFieldRef(RecRelatedVariant, FieldNumber, RecordRef, FieldRef) then
            Error(NoValidRecordErr);
    end;
}

