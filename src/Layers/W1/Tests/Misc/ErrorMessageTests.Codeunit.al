codeunit 135000 "Error Message Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Error Message]
    end;

    var
        GenericErrorDescriptionTxt: Label 'The field must be a multiple of 4';
        AdditionalInformationTxt: Label 'Additional Information';
        AdditionalInformation2Txt: Label 'Further information about the error message';
        SupportUrlTxt: Label 'www.bing.com';
        GLBCustomerContext: Record Customer;
        GLBVendorContext: Record Vendor;
        Assert: Codeunit Assert;
        SupportUrl2Txt: Label 'www.microsoft.com';
        IfEmptyErr: Label '''%1'' in ''%2'' must not be blank.', Comment = '%1=caption of a field, %2=key of record';
        IfLengthExceededErr: Label 'The maximum length of ''%1'' in ''%2'' is %3 characters. The actual length is %4.', Comment = '%1=caption of a field, %2=key of record, %3=integer, %4=integer';
        IfInvalidCharactersErr: Label '''%1'' in ''%2'' contains characters that are not valid.', Comment = '%1=caption of a field, %2=key of record';
        IfOutsideRangeErr: Label '''%1'' in ''%2'' is outside of the permitted range from %3 to %4.', Comment = '%1=caption of a field, %2=key of record, %3=integer, %4=integer';
        IfGreaterThanErr: Label '''%1'' in ''%2'' must be less than or equal to %3.', Comment = '%1=caption of a field, %2=key of record, %3=integer';
        IfLessThanErr: Label '''%1'' in ''%2'' must be greater than or equal to %3.', Comment = '%1=caption of a field, %2=key of record, %3=integer';
        IfEqualToErr: Label '''%1'' in ''%2'' must not be equal to %3.', Comment = '%1=caption of a field, %2=key of record, %3=integer';
        IfNotEqualToErr: Label '''%1'' in ''%2'' must be equal to %3.', Comment = '%1=caption of a field, %2=key of record, %3=integer';
        InvalidErrorMessageDataErr: Label 'Invalid data in Error Message table.';
        ErrorLoggedForValidDataErr: Label 'An error was logged for valid data.';
        FieldMustNotBeErr: Label '%1 must not be %2', Comment = '%1 - field name, %2 - field value';
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        DevMsgNotTemporaryErr: Label 'This function can only be used when the record is temporary.';
        DrillDownErr: Label 'The NavDrilldownAction method is not supported.';

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLogSimpleMessage()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ID: Integer;
    begin
        // [SCENARIO] The user can log a simple Error Message without a link to a Record
        Initialize();

        // [WHEN] A generic message without relation to a record is logged
        // [THEN] ID to a new entry is returned
        ID := TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);

        // [THEN] The new entry contains the specified information
        VerifyErrorMessage(TempErrorMessage, ID, 0, TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLogSimpleMessageAndSetContext()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ID: Integer;
    begin
        // [SCENARIO] The user can log a simple Error Message without a link to a Record
        Initialize();

        // [WHEN] A generic message without relation to a record is logged
        // [THEN] ID to a new entry is returned
        TempErrorMessage.SetContext(GLBCustomerContext);
        ID := TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);

        // [THEN] The new entry contains the specified information
        VerifyPersistentErrorMessage(TempErrorMessage, ID, GLBCustomerContext.RecordId, 0,
          TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLogSimpleMessagePersistent()
    var
        ErrorMessage: Record "Error Message";
        ID: Integer;
    begin
        // [SCENARIO] The user can log a simple Error Message without a link to a Record
        Initialize();

        // [WHEN] A generic message without relation to a record is logged
        // [THEN] ID to a new entry is returned
        ErrorMessage.SetContext(GLBCustomerContext);
        ID := ErrorMessage.LogSimpleMessage(ErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);

        // [THEN] The new entry contains the specified information
        VerifyPersistentErrorMessage(ErrorMessage, ID, GLBCustomerContext.RecordId, 0,
          ErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLogMessage()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        ID: Integer;
    begin
        // [SCENARIO] The user can log an Error Message with a link to a Record
        Initialize();

        // [WHEN] A generic message is logged
        // [THEN] ID to a new entry is returned
        ID := TempErrorMessage.LogMessage(DataTypeBuffer, DataTypeBuffer.FieldNo(ID),
            TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);

        // [THEN] The new entry contains the specified information
        VerifyErrorMessage(
          TempErrorMessage, ID, DataTypeBuffer.FieldNo(ID), TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLogDetailedMessage()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        ID: Integer;
    begin
        // [SCENARIO] The user can log a detailed Error Message with a link to a Record
        Initialize();

        // [WHEN] A generic detailed message is logged
        // [THEN] ID to a new entry is returned
        ID := TempErrorMessage.LogDetailedMessage(DataTypeBuffer, DataTypeBuffer.FieldNo(ID),
            TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt, AdditionalInformationTxt, SupportUrlTxt);

        // [THEN] The new entry contains the specified information
        VerifyErrorMessage(
          TempErrorMessage, ID, DataTypeBuffer.FieldNo(ID), TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
        VerifyDetailedErrorMessage(TempErrorMessage, ID, AdditionalInformationTxt, SupportUrlTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageAddDetailsToMessage()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        ID: Integer;
    begin
        // [SCENARIO] The user can add details to an existing Error Message
        Initialize();

        // [GIVEN] The ID of an Error Message with no additional information nor support url
        ID := TempErrorMessage.LogMessage(DataTypeBuffer, DataTypeBuffer.FieldNo(ID),
            TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);

        // [WHEN] Message Details are added to the ID
        TempErrorMessage.AddMessageDetails(ID, AdditionalInformationTxt, SupportUrlTxt);

        // [THEN] The entry is updated to contain the new additional information and support url
        VerifyErrorMessage(
          TempErrorMessage, ID, DataTypeBuffer.FieldNo(ID), TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
        VerifyDetailedErrorMessage(TempErrorMessage, ID, AdditionalInformationTxt, SupportUrlTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageAddDetailsToDetailedMessage()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        ID: Integer;
    begin
        // [SCENARIO] The user can add details to an existing detailed Error Message (details are overwritten)
        Initialize();

        // [GIVEN] The ID of an Error Message with additional information and support url
        ID := TempErrorMessage.LogDetailedMessage(DataTypeBuffer, DataTypeBuffer.FieldNo(ID),
            TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt, AdditionalInformation2Txt, SupportUrl2Txt);

        // [WHEN] Message Details are added to the ID
        TempErrorMessage.AddMessageDetails(ID, AdditionalInformationTxt, SupportUrlTxt);

        // [THEN] The entry is updated to contain the new additional information and support url
        VerifyErrorMessage(
          TempErrorMessage, ID, DataTypeBuffer.FieldNo(ID), TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
        VerifyDetailedErrorMessage(TempErrorMessage, ID, AdditionalInformationTxt, SupportUrlTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageAddDetailsNonExistingMessage()
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [SCENARIO] The user cannot add details to a non-existing Error Message (ID <> 0 is provided)
        Initialize();

        // [WHEN] Message Details are added to a non-existing message ID
        // [THEN] An error is thrown
        asserterror TempErrorMessage.AddMessageDetails(1, AdditionalInformationTxt, SupportUrlTxt);

        // [THEN] The exception is "The Error Message does not exist."
        Assert.ExpectedErrorCannotFind(Database::"Error Message");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageEmptyFieldLogError()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        FieldNo: Integer;
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is added when using LogIfIsEmpty function, if the provided field is empty
        Initialize();

        // [GIVEN] A record with an empty field
        DataTypeBuffer.Init();
        RecordRef.GetTable(DataTypeBuffer);
        for FieldNo := 1 to RecordRef.FieldCount do begin
            // [GIVEN] Field is of type [Option, Boolean,Text,Code,Date,Decimal,Integer,BigInteger,Time,DateTime,Duration,GUID,DateFormula].
            FieldRef := RecordRef.FieldIndex(FieldNo);

            // [WHEN] LogIfEmpty is called with relation to the empty field.
            // [THEN] ID to a new entry is returned
            ID := TempErrorMessage.LogIfEmpty(RecordRef, FieldRef.Number, TempErrorMessage."Message Type"::Information);

            // [THEN] The new entry contains error message "You must specify '%1' in '%2'."
            // [THEN] The new entry has a link to the record and field number which were validated
            VerifyErrorMessage(TempErrorMessage, ID, FieldRef.Number, TempErrorMessage."Message Type"::Information,
              StrSubstNo(IfEmptyErr, FieldRef.Name, Format(RecordRef.RecordId)));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageEmptyFieldNoErrors()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        FieldNo: Integer;
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is not added when using LogIfIsEmpty function, if the provided field is not empty
        Initialize();

        // [GIVEN] A record with a non-empty field
        // [GIVEN] Field is of type [Option, Boolean,Text,Code,Date,Decimal,Integer,BigInteger,Time,DateTime,Duration,GUID,DateFormula].
        FillDataTypeTestTableWithValidData(DataTypeBuffer);

        RecordRef.GetTable(DataTypeBuffer);
        for FieldNo := 1 to RecordRef.FieldCount do begin
            FieldRef := RecordRef.FieldIndex(FieldNo);

            // [WHEN] LogIfEmpty is called with relation to the non-empty field.
            ID := TempErrorMessage.LogIfEmpty(RecordRef, FieldRef.Number, TempErrorMessage."Message Type"::Information);

            // [THEN] The id returned is 0
            // [THEN] No entries has been created
            Assert.AreEqual(0, ID, ErrorLoggedForValidDataErr);
            Assert.AreEqual(0, TempErrorMessage.Count, ErrorLoggedForValidDataErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLengthExceededOutsideLimitsText()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        RecordRef: RecordRef;
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is added when using LogIfLengthExceeded function, if the provided field is Text and exceeds the maximum length
        Initialize();

        // [GIVEN] A record with a text field with 6 characters
        DataTypeBuffer.Init();
        DataTypeBuffer.Text := '123456';
        DataTypeBuffer.Insert();

        // [WHEN] LogIfLengthExceeded is called with relation to the empty field and MaxLength = 5
        ID := TempErrorMessage.LogIfLengthExceeded(DataTypeBuffer, DataTypeBuffer.FieldNo(Text),
            TempErrorMessage."Message Type"::Error, 5);

        // [THEN] ID to a new entry is returned
        // [THEN] The new entry contains error message "Maximum length of '%1' in '%2' is %3 characters (actual length: %4)."
        // [THEN] The new entry has a link to the record and field number which were validated
        RecordRef.GetTable(DataTypeBuffer);
        VerifyErrorMessage(TempErrorMessage, ID, DataTypeBuffer.FieldNo(Text), TempErrorMessage."Message Type"::Error,
          StrSubstNo(IfLengthExceededErr, DataTypeBuffer.FieldName(Text), Format(RecordRef.RecordId), 5, 6));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLengthExceededOutsideLimitsCode()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        RecordRef: RecordRef;
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is added when using LogIfLengthExceeded function, if the provided field is Code and exceeds the maximum length
        Initialize();

        // [GIVEN] A record with a code field with 6 characters
        DataTypeBuffer.Init();
        DataTypeBuffer.Code := '123456';
        DataTypeBuffer.Insert();

        // [WHEN] LogIfLengthExceeded is called with relation to the empty field and MaxLength = 5
        ID := TempErrorMessage.LogIfLengthExceeded(DataTypeBuffer, DataTypeBuffer.FieldNo(Code),
            TempErrorMessage."Message Type"::Error, 5);

        // [THEN] ID to a new entry is returned
        // [THEN] The new entry contains error message "Maximum length of '%1' in '%2' is %3 characters (actual length: %4)."
        // [THEN] The new entry has a link to the record and field number which were validated
        RecordRef.GetTable(DataTypeBuffer);
        VerifyErrorMessage(TempErrorMessage, ID, DataTypeBuffer.FieldNo(Code), TempErrorMessage."Message Type"::Error,
          StrSubstNo(IfLengthExceededErr, DataTypeBuffer.FieldName(Code), Format(RecordRef.RecordId), 5, 6));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLengthExceededOutsideLimitsInteger()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        RecordRef: RecordRef;
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is added when using LogIfLengthExceeded function, if the provided field is Integer and exceeds the maximum length
        Initialize();

        // [GIVEN] A record with a integer field with 6 numbers
        DataTypeBuffer.Init();
        DataTypeBuffer.ID := 123456;
        DataTypeBuffer.Insert();

        // [WHEN] LogIfLengthExceeded is called with relation to the empty field and MaxLength = 5
        ID := TempErrorMessage.LogIfLengthExceeded(DataTypeBuffer, DataTypeBuffer.FieldNo(ID),
            TempErrorMessage."Message Type"::Error, 5);

        // [THEN] ID to a new entry is returned
        // [THEN] The new entry contains error message "Maximum length of '%1' in '%2' is %3 characters (actual length: %4)."
        // [THEN] The new entry has a link to the record and field number which were validated
        RecordRef.GetTable(DataTypeBuffer);
        VerifyErrorMessage(TempErrorMessage, ID, DataTypeBuffer.FieldNo(ID), TempErrorMessage."Message Type"::Error,
          StrSubstNo(IfLengthExceededErr, DataTypeBuffer.FieldName(ID), Format(RecordRef.RecordId), 5, 6));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLengthExceededOutsideLimitsDecimal()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        RecordRef: RecordRef;
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is added when using LogIfLengthExceeded function, if the provided field is Decimal and exceeds the maximum length
        Initialize();

        // [GIVEN] A record with a decimal field with 6 numbers(including comma)
        DataTypeBuffer.Init();
        DataTypeBuffer.Decimal := 123.56;
        DataTypeBuffer.Insert();

        // [WHEN] LogIfLengthExceeded is called with relation to the empty field and MaxLength = 5
        ID := TempErrorMessage.LogIfLengthExceeded(DataTypeBuffer, DataTypeBuffer.FieldNo(Decimal),
            TempErrorMessage."Message Type"::Error, 5);

        // [THEN] ID to a new entry is returned
        // [THEN] The new entry contains error message "Maximum length of '%1' in '%2' is %3 characters (actual length: %4)."
        // [THEN] The new entry has a link to the record and field number which were validated
        RecordRef.GetTable(DataTypeBuffer);
        VerifyErrorMessage(TempErrorMessage, ID, DataTypeBuffer.FieldNo(Decimal), TempErrorMessage."Message Type"::Error,
          StrSubstNo(IfLengthExceededErr, DataTypeBuffer.FieldName(Decimal), Format(RecordRef.RecordId), 5, 6));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLengthExceededWithinLimitsText()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is not added when using LogIfLengthExceeded function, if the provided field is Text and is within maximum length
        Initialize();

        // [GIVEN] A record with a text field with 5 characters
        DataTypeBuffer.Init();
        DataTypeBuffer.Text := '12345';
        DataTypeBuffer.Insert();

        // [WHEN] LogIfLengthExceeded is called with relation to the empty field and MaxLength = 5
        ID := TempErrorMessage.LogIfLengthExceeded(DataTypeBuffer, DataTypeBuffer.FieldNo(Text),
            TempErrorMessage."Message Type"::Error, 5);

        // [THEN] The id returned is 0
        // [THEN] No entries has been created
        Assert.AreEqual(0, ID, ErrorLoggedForValidDataErr);
        Assert.AreEqual(0, TempErrorMessage.Count, ErrorLoggedForValidDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLengthExceededWithinLimitsCode()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is not added when using LogIfLengthExceeded function, if the provided field is Code and is within maximum length
        Initialize();

        // [GIVEN] A record with a code field with 5 characters
        DataTypeBuffer.Init();
        DataTypeBuffer.Code := '12345';
        DataTypeBuffer.Insert();

        // [WHEN] LogIfLengthExceeded is called with relation to the empty field and MaxLength = 5
        ID := TempErrorMessage.LogIfLengthExceeded(DataTypeBuffer, DataTypeBuffer.FieldNo(Code),
            TempErrorMessage."Message Type"::Error, 5);

        // [THEN] The id returned is 0
        // [THEN] No entries has been created
        Assert.AreEqual(0, ID, ErrorLoggedForValidDataErr);
        Assert.AreEqual(0, TempErrorMessage.Count, ErrorLoggedForValidDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLengthExceededWithinLimitsInteger()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is not added when using LogIfLengthExceeded function, if the provided field is Integer and is within maximum length
        Initialize();

        // [GIVEN] A record with an integer field with 5 characters
        DataTypeBuffer.Init();
        DataTypeBuffer.ID := 12345;
        DataTypeBuffer.Insert();

        // [WHEN] LogIfLengthExceeded is called with relation to the empty field and MaxLength = 5
        ID := TempErrorMessage.LogIfLengthExceeded(DataTypeBuffer, DataTypeBuffer.FieldNo(ID),
            TempErrorMessage."Message Type"::Error, 5);

        // [THEN] The id returned is 0
        // [THEN] No entries has been created
        Assert.AreEqual(0, ID, ErrorLoggedForValidDataErr);
        Assert.AreEqual(0, TempErrorMessage.Count, ErrorLoggedForValidDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLengthExceededWithinLimitsDecimal()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is not added when using LogIfLengthExceeded function, if the provided field is Decimal and is within maximum length
        Initialize();

        // [GIVEN] A record with a decimal field with 5 characters
        DataTypeBuffer.Init();
        DataTypeBuffer.Decimal := 12.45;
        DataTypeBuffer.Insert();

        // [WHEN] LogIfLengthExceeded is called with relation to the empty field and MaxLength = 5
        ID := TempErrorMessage.LogIfLengthExceeded(DataTypeBuffer, DataTypeBuffer.FieldNo(Decimal),
            TempErrorMessage."Message Type"::Error, 5);

        // [THEN] The id returned is 0
        // [THEN] No entries has been created
        Assert.AreEqual(0, ID, ErrorLoggedForValidDataErr);
        Assert.AreEqual(0, TempErrorMessage.Count, ErrorLoggedForValidDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageInvalidCharactersLogError()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        RecordRef: RecordRef;
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is added when using LogIfInvalidCharacters function, if the provided field contains invalid characters
        Initialize();

        // [GIVEN] A record with a text field containing Copenhagen1
        DataTypeBuffer.Init();
        DataTypeBuffer.Text := 'Copenhagen1';
        DataTypeBuffer.Insert();

        // [GIVEN] Only characters are valid
        // [WHEN] LogIfInvalidCharacters is called with relation to the specified field and valid characters.
        ID := TempErrorMessage.LogIfInvalidCharacters(DataTypeBuffer, DataTypeBuffer.FieldNo(Text),
            TempErrorMessage."Message Type"::Error, 'abcdefghjijklmnopqrstuvwxyzABC');

        // [THEN] ID to a new entry is returned
        // [THEN] The new entry contains error message "Maximum length of '%1' in '%2' is %3 characters (actual length: %4)."
        // [THEN] The new entry has a link to the record and field number which were validated
        RecordRef.GetTable(DataTypeBuffer);
        VerifyErrorMessage(TempErrorMessage, ID, DataTypeBuffer.FieldNo(Text), TempErrorMessage."Message Type"::Error,
          StrSubstNo(IfInvalidCharactersErr, DataTypeBuffer.FieldName(Text), Format(RecordRef.RecordId)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageInvalidCharactersNoErrors()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is not added when using LogIfInvalidCharacters function, if the provided field does not contain invalid characters
        Initialize();

        // [GIVEN] A record with a text field containing Copenhagen
        DataTypeBuffer.Init();
        DataTypeBuffer.Text := 'Copenhagen';
        DataTypeBuffer.Insert();

        // [GIVEN] Only characters are valid
        // [WHEN] LogIfInvalidCharacters is called with relation to the specified field and valid characters.
        ID := TempErrorMessage.LogIfInvalidCharacters(DataTypeBuffer, DataTypeBuffer.FieldNo(Text),
            TempErrorMessage."Message Type"::Error, 'abcdefghjijklmnopqrstuvwxyzABC');

        // [THEN] The id returned is 0
        // [THEN] No entries has been created
        Assert.AreEqual(0, ID, ErrorLoggedForValidDataErr);
        Assert.AreEqual(0, TempErrorMessage.Count, ErrorLoggedForValidDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLogIfOutsideRangeLogError()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        RecordRef: RecordRef;
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is added when using LogIfOutsideRange function, if the provided field is outside the supplied range
        Initialize();

        // [GIVEN] A record with an integer value = 5
        DataTypeBuffer.Init();
        DataTypeBuffer.ID := 5;
        DataTypeBuffer.Insert();

        // [WHEN] LogIfOutsideRange is called with relation to the specified field and range 1-4.
        ID := TempErrorMessage.LogIfOutsideRange(DataTypeBuffer, DataTypeBuffer.FieldNo(ID),
            TempErrorMessage."Message Type"::Error, 1, 4);

        // [THEN] ID to a new entry is returned
        // [THEN] The new entry contains error message "'%1' in '%2' is outside of the permitted range from %3 to %4."
        // [THEN] The new entry has a link to the record and field number which were validated
        RecordRef.GetTable(DataTypeBuffer);
        VerifyErrorMessage(TempErrorMessage, ID, DataTypeBuffer.FieldNo(ID), TempErrorMessage."Message Type"::Error,
          StrSubstNo(IfOutsideRangeErr, DataTypeBuffer.FieldName(ID), Format(RecordRef.RecordId), 1, 4));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLogIfOutsideRangeNoErrors()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is not added when using LogIfOutsideRange function, if the provided field is within the supplied range
        Initialize();

        // [GIVEN] A record with an integer value = 4
        DataTypeBuffer.Init();
        DataTypeBuffer.ID := 4;
        DataTypeBuffer.Insert();

        // [WHEN] LogIfOutsideRange is called with relation to the specified field and range 4-4.
        ID := TempErrorMessage.LogIfOutsideRange(DataTypeBuffer, DataTypeBuffer.FieldNo(ID),
            TempErrorMessage."Message Type"::Error, 4, 4);

        // [THEN] The id returned is 0
        // [THEN] No entries has been created
        Assert.AreEqual(0, ID, ErrorLoggedForValidDataErr);
        Assert.AreEqual(0, TempErrorMessage.Count, ErrorLoggedForValidDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLogIfGreaterThanLogError()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        RecordRef: RecordRef;
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is added when using LogIfGreaterThan function, if the provided field is greater than the maximum value
        Initialize();

        // [GIVEN] A record with an integer value = 5
        DataTypeBuffer.Init();
        DataTypeBuffer.ID := 5;
        DataTypeBuffer.Insert();

        // [WHEN] LogIfGreaterThan is called with relation to the specified field and max value = 4.
        ID := TempErrorMessage.LogIfGreaterThan(DataTypeBuffer, DataTypeBuffer.FieldNo(ID),
            TempErrorMessage."Message Type"::Error, 4);

        // [THEN] ID to a new entry is returned
        // [THEN] The new entry contains error message '%1' in '%2' must be less or equal to %3.
        // [THEN] The new entry has a link to the record and field number which were validated
        RecordRef.GetTable(DataTypeBuffer);
        VerifyErrorMessage(TempErrorMessage, ID, DataTypeBuffer.FieldNo(ID), TempErrorMessage."Message Type"::Error,
          StrSubstNo(IfGreaterThanErr, DataTypeBuffer.FieldName(ID), Format(RecordRef.RecordId), 4));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLogIfGreaterThanNoErrors()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is not added when using LogIfGreaterThan function, if the provided field is equal to or less than the maximum value
        Initialize();

        // [GIVEN] A record with an integer value = 5
        DataTypeBuffer.Init();
        DataTypeBuffer.ID := 5;
        DataTypeBuffer.Insert();

        // [WHEN] LogIfGreaterThan is called with relation to the specified field and max value = 5.
        ID := TempErrorMessage.LogIfGreaterThan(DataTypeBuffer, DataTypeBuffer.FieldNo(ID),
            TempErrorMessage."Message Type"::Error, 5);

        // [THEN] The id returned is 0
        // [THEN] No entries has been created
        Assert.AreEqual(0, ID, ErrorLoggedForValidDataErr);
        Assert.AreEqual(0, TempErrorMessage.Count, ErrorLoggedForValidDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLogIfLessThanLogError()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        RecordRef: RecordRef;
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is added when using LogIfLessThan function, if the provided field is less than the minimum value
        Initialize();

        // [GIVEN] A record with an integer value = 5
        DataTypeBuffer.Init();
        DataTypeBuffer.ID := 5;
        DataTypeBuffer.Insert();

        // [WHEN] LogIfLessThan is called with relation to the specified field and min value = 6.
        ID := TempErrorMessage.LogIfLessThan(DataTypeBuffer, DataTypeBuffer.FieldNo(ID),
            TempErrorMessage."Message Type"::Error, 6);

        // [THEN] ID to a new entry is returned
        // [THEN] The new entry contains error message '%1' in '%2' must be greater or equal to %3.
        // [THEN] The new entry has a link to the record and field number which were validated
        RecordRef.GetTable(DataTypeBuffer);
        VerifyErrorMessage(TempErrorMessage, ID, DataTypeBuffer.FieldNo(ID), TempErrorMessage."Message Type"::Error,
          StrSubstNo(IfLessThanErr, DataTypeBuffer.FieldName(ID), Format(RecordRef.RecordId), 6));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLogIfLessThanNoErrors()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is not added when using LogIfLessThan function, if the provided field is equal to or greater than the minimum value
        Initialize();

        // [GIVEN] A record with an integer value = 5
        DataTypeBuffer.Init();
        DataTypeBuffer.ID := 5;
        DataTypeBuffer.Insert();

        // [WHEN] LogIfLessThan is called with relation to the specified field and min value = 5.
        ID := TempErrorMessage.LogIfLessThan(DataTypeBuffer, DataTypeBuffer.FieldNo(ID),
            TempErrorMessage."Message Type"::Error, 5);

        // [THEN] The id returned is 0
        // [THEN] No entries has been created
        Assert.AreEqual(0, ID, ErrorLoggedForValidDataErr);
        Assert.AreEqual(0, TempErrorMessage.Count, ErrorLoggedForValidDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLogIfEqualToLogError()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        RecordRef: RecordRef;
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is added when using LogIfEqualTo function, if the provided field is equal to the invalid value
        Initialize();

        // [GIVEN] A record with an integer value = 5
        DataTypeBuffer.Init();
        DataTypeBuffer.ID := 5;
        DataTypeBuffer.Insert();

        // [WHEN] LogIfEqualTo is called with relation to the specified field and must be equal to 5.
        ID := TempErrorMessage.LogIfEqualTo(DataTypeBuffer, DataTypeBuffer.FieldNo(ID),
            TempErrorMessage."Message Type"::Error, '5');

        // [THEN] ID to a new entry is returned
        // [THEN] The new entry contains error message '%1' in '%2' must not be equal to %3.
        // [THEN] The new entry has a link to the record and field number which were validated
        RecordRef.GetTable(DataTypeBuffer);
        VerifyErrorMessage(TempErrorMessage, ID, DataTypeBuffer.FieldNo(ID), TempErrorMessage."Message Type"::Error,
          StrSubstNo(IfEqualToErr, DataTypeBuffer.FieldName(ID), Format(RecordRef.RecordId), 5));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLogIfEqualToFilterStringLogError()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        RecordRef: RecordRef;
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is added when using LogIfEqualTo function, if the provided field is equal to the invalid value (containing filter string characters)
        Initialize();

        // [GIVEN] A record with an integer value = 5
        DataTypeBuffer.Init();
        DataTypeBuffer.Text := '(5)|@2';
        DataTypeBuffer.Insert();

        // [WHEN] LogIfEqualTo is called with relation to the specified field and must be equal to 5.
        ID := TempErrorMessage.LogIfEqualTo(DataTypeBuffer, DataTypeBuffer.FieldNo(Text),
            TempErrorMessage."Message Type"::Error, '(5)|@2');

        // [THEN] ID to a new entry is returned
        // [THEN] The new entry contains error message '%1' in '%2' must not be equal to %3.
        // [THEN] The new entry has a link to the record and field number which were validated
        RecordRef.GetTable(DataTypeBuffer);
        VerifyErrorMessage(TempErrorMessage, ID, DataTypeBuffer.FieldNo(Text), TempErrorMessage."Message Type"::Error,
          StrSubstNo(IfEqualToErr, DataTypeBuffer.FieldName(Text), Format(RecordRef.RecordId), '(5)|@2'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLogIfEqualToNoErrors()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is not added when using LogIfEqualTo function, if the provided field is different from the invalid value
        Initialize();

        // [GIVEN] A record with an integer value = 5
        DataTypeBuffer.Init();
        DataTypeBuffer.ID := 5;
        DataTypeBuffer.Insert();

        // [WHEN] LogIfEqualTo is called with relation to the specified field and must be equal to 1.
        ID := TempErrorMessage.LogIfEqualTo(DataTypeBuffer, DataTypeBuffer.FieldNo(ID),
            TempErrorMessage."Message Type"::Error, 1);

        // [THEN] The id returned is 0
        // [THEN] No entries has been created
        Assert.AreEqual(0, ID, ErrorLoggedForValidDataErr);
        Assert.AreEqual(0, TempErrorMessage.Count, ErrorLoggedForValidDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLogIfNotEqualToLogError()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        RecordRef: RecordRef;
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is added when using LogIfNotEqualTo function, if the provided field is equal to the valid value
        Initialize();

        // [GIVEN] A record with an integer value = 5
        DataTypeBuffer.Init();
        DataTypeBuffer.ID := 5;
        DataTypeBuffer.Insert();

        // [WHEN] LogIfNotEqualTo is called with relation to the specified field and must not be equal to 4.
        ID := TempErrorMessage.LogIfNotEqualTo(DataTypeBuffer, DataTypeBuffer.FieldNo(ID),
            TempErrorMessage."Message Type"::Error, 4);

        // [THEN] ID to a new entry is returned
        // [THEN] The new entry contains error message '%1' in '%2' must be equal to %3.
        // [THEN] The new entry has a link to the record and field number which were validated
        RecordRef.GetTable(DataTypeBuffer);
        VerifyErrorMessage(TempErrorMessage, ID, DataTypeBuffer.FieldNo(ID), TempErrorMessage."Message Type"::Error,
          StrSubstNo(IfNotEqualToErr, DataTypeBuffer.FieldName(ID), Format(RecordRef.RecordId), 4));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLogIfNotEqualToNoErrors()
    var
        TempErrorMessage: Record "Error Message" temporary;
        DataTypeBuffer: Record "Data Type Buffer";
        ID: Integer;
    begin
        // [SCENARIO] An Error Message is not added when using LogIfNotEqualTo function, if the provided field is different from the valid value
        Initialize();

        // [GIVEN] A record with an integer value = 5
        DataTypeBuffer.Init();
        DataTypeBuffer.ID := 5;
        DataTypeBuffer.Insert();

        // [WHEN] LogIfNotEqualTo is called with relation to the specified field and must not be equal to 5.
        ID := TempErrorMessage.LogIfNotEqualTo(DataTypeBuffer, DataTypeBuffer.FieldNo(ID),
            TempErrorMessage."Message Type"::Error, 5);

        // [THEN] The id returned is 0
        // [THEN] No entries has been created
        Assert.AreEqual(0, ID, ErrorLoggedForValidDataErr);
        Assert.AreEqual(0, TempErrorMessage.Count, ErrorLoggedForValidDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageClearLog()
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [SCENARIO] All Error Messages are cleared when using ClearLog function, regardless of the current filter
        Initialize();
        // [GIVEN] A record in the error message table
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
        Assert.AreEqual(1, TempErrorMessage.Count, ErrorLoggedForValidDataErr);
        // [GIVEN] The error message table has a filter
        TempErrorMessage.SetRange("Message Type", TempErrorMessage."Message Type"::Warning);
        // [WHEN] ClearLog is called
        TempErrorMessage.ClearLog();
        // [THEN] No entries exists in the error message table
        TempErrorMessage.Reset();
        Assert.AreEqual(0, TempErrorMessage.Count, ErrorLoggedForValidDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessagesTempAndPersistent()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessage: Record "Error Message";
    begin
        // [SCENARIO] All Error Messages are cleared when using ClearLog function, regardless of the current filter
        Initialize();

        // Exercise
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
        TempErrorMessage.SetContext(GLBCustomerContext.RecordId);
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
        ErrorMessage.SetContext(GLBCustomerContext);
        ErrorMessage.LogSimpleMessage(ErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);

        // verify
        Assert.AreEqual(2, TempErrorMessage.Count, ErrorLoggedForValidDataErr);
        Assert.AreEqual(1, ErrorMessage.Count, ErrorLoggedForValidDataErr);

        TempErrorMessage.ClearLog();
        Assert.AreEqual(0, TempErrorMessage.Count, ErrorLoggedForValidDataErr);

        ErrorMessage.SetContext(0);
        asserterror ErrorMessage.ClearLog();
        Assert.ExpectedError(DevMsgNotTemporaryErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageHasErrorMessagesRelatedToHasRecord()
    var
        TempErrorMessage: Record "Error Message" temporary;
        Customer: Record Customer;
    begin
        // [SCENARIO] The HasErrorMessagesRelatedTo function returns TRUE if a message has been logged for the supplied record.
        Initialize();

        // [GIVEN] An error has been logged for a record
        LibrarySales.CreateCustomer(Customer);
        TempErrorMessage.LogMessage(Customer, Customer.FieldNo(Name),
          TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
        Assert.AreEqual(1, TempErrorMessage.Count, ErrorLoggedForValidDataErr);

        // [WHEN] HasErrorMessagesRelatedTo is called for that record
        // [THEN] HasErrorMessagesRelatedTo returns TRUE
        Assert.IsTrue(TempErrorMessage.HasErrorMessagesRelatedTo(Customer), ErrorLoggedForValidDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageHasErrorMessagesRelatedToNoRecords()
    var
        TempErrorMessage: Record "Error Message" temporary;
        Customer: Record Customer;
    begin
        // [SCENARIO] The HasErrorMessagesRelatedTo function returns FALSE if no messages have been logged for the supplied record.
        Initialize();

        // [GIVEN] An error has been logged for a record
        Customer.Find('-');
        TempErrorMessage.LogMessage(Customer, Customer.FieldNo(Name),
          TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
        Assert.AreEqual(1, TempErrorMessage.Count, ErrorLoggedForValidDataErr);

        // [WHEN] HasErrorMessagesRelatedTo is called for another record in the same table
        // [THEN] HasErrorMessagesRelatedTo returns FALSE
        Customer.Next();
        Assert.IsFalse(TempErrorMessage.HasErrorMessagesRelatedTo(Customer), ErrorLoggedForValidDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageErrorMessageCount()
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [SCENARIO] The ErrorMessageCount function returns the number of messages that have been logged with the provided Lowest Severity Message Type
        Initialize();
        // [GIVEN] An error has been logged for each message type, error, warning and message
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Warning, GenericErrorDescriptionTxt);
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Information, GenericErrorDescriptionTxt);
        // [WHEN] ErrorMessageCount is called for Warning Level
        // [THEN] HasErrorMessagesRelatedTo reports that 2 entries exists
        Assert.AreEqual(2, TempErrorMessage.ErrorMessageCount(TempErrorMessage."Message Type"::Warning), ErrorLoggedForValidDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageErrorMessageCountPerContext()
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [SCENARIO] The ErrorMessageCount function returns the number of messages that have been logged with the provided Lowest Severity Message Type
        Initialize();
        // [GIVEN] An error has been logged for each message type, error, warning and message
        TempErrorMessage.SetContext(GLBCustomerContext);
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Warning, GenericErrorDescriptionTxt);
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Information, GenericErrorDescriptionTxt);
        TempErrorMessage.SetContext(GLBVendorContext);
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
        // [WHEN] ErrorMessageCount is called for Warning Level
        // [THEN] HasErrorMessagesRelatedTo reports that 2 entries exists for one context and 1 for the second context
        TempErrorMessage.SetContext(GLBCustomerContext);
        Assert.AreEqual(2, TempErrorMessage.ErrorMessageCount(TempErrorMessage."Message Type"::Warning), ErrorLoggedForValidDataErr);
        TempErrorMessage.SetContext(GLBVendorContext);
        Assert.AreEqual(1, TempErrorMessage.ErrorMessageCount(TempErrorMessage."Message Type"::Warning), ErrorLoggedForValidDataErr);
    end;

    [Test]
    [HandlerFunctions('HasErrorsMessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorMessageHasErrorsWithErrors()
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [SCENARIO] The HasErrors function reports returns TRUE and shows a message if an error has been logged and ShowMessage = TRUE
        Initialize();
        // [GIVEN] An error and a warning message type has been logged
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Warning, GenericErrorDescriptionTxt);
        // [WHEN] HasErrors is called and set to display error message
        // [THEN] HasErrors returns TRUE
        // [THEN] A message is shown
        Assert.IsTrue(TempErrorMessage.HasErrors(true), ErrorLoggedForValidDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageHasErrorsWithErrorsNoMessage()
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [SCENARIO] The HasErrors function reports returns TRUE and does not show a message if an error has been logged and ShowMessage = FALSE
        Initialize();
        // [GIVEN] An error and a warning message type has been logged
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Warning, GenericErrorDescriptionTxt);
        // [WHEN] HasErrors is called and set to NOT display error message
        // [THEN] HasErrors returns TRUE
        // [THEN] No messages are shown
        Assert.IsTrue(TempErrorMessage.HasErrors(false), ErrorLoggedForValidDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageHasErrorsWithoutErrors()
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [SCENARIO] The HasErrors function reports returns FALSE and does not show a message if no error has been logged and ShowMessage = TRUE
        Initialize();
        // [GIVEN] A Message and a warning message type has been logged
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Information, GenericErrorDescriptionTxt);
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Warning, GenericErrorDescriptionTxt);
        // [WHEN] HasErrors is called and set to display error message
        // [THEN] HasErrors returns FALSE
        // [THEN] No messages are shown
        Assert.IsFalse(TempErrorMessage.HasErrors(true), ErrorLoggedForValidDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageToString()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessage: Text;
    begin
        // [SCENARIO] The ToString function returns a Text representation of the current errors, with Message Type and Description
        Initialize();
        // [GIVEN] An error and a warning message type has been logged
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Warning, GenericErrorDescriptionTxt);
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
        // [WHEN] ToString is called
        ErrorMessage := TempErrorMessage.ToString();
        // [THEN] A string is returned that contains information about the two logged messages
        Assert.AreEqual(StrSubstNo('Error: %1\Warning: %1', GenericErrorDescriptionTxt), ErrorMessage, ErrorLoggedForValidDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageThrowErrorWithError()
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [SCENARIO] The function ThrowError will throw an error if a message has been logged with "Message Type" = Error
        Initialize();
        // [GIVEN] An error message has been logged
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
        // [WHEN] ThrowError is called
        // [THEN] An error is thrown
        asserterror TempErrorMessage.ThrowError();
        // [THEN] The thrown error contains the logged error message
        Assert.ExpectedError(StrSubstNo('Error: %1', GenericErrorDescriptionTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageThrowErrorNoError()
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [SCENARIO] The function ThrowError will not throw an error if no messages has been logged with "Message Type" = Error
        Initialize();
        // [GIVEN] Only a warning message has been logged
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Warning, GenericErrorDescriptionTxt);
        // [WHEN] ThrowError is called
        // [THEN] Nothing happens
        TempErrorMessage.ThrowError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageShowError()
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessages: TestPage "Error Messages";
    begin
        // [SCENARIO] The function ThrowError will not throw an error if no messages has been logged with "Message Type" = Error
        Initialize();
        // [GIVEN] Only a warning message has been logged
        ErrorMessage.SetContext(GLBCustomerContext);
        ErrorMessage.LogSimpleMessage(ErrorMessage."Message Type"::Warning, GenericErrorDescriptionTxt);
        ErrorMessage.SetContext(GLBVendorContext);
        ErrorMessage.LogSimpleMessage(ErrorMessage."Message Type"::Warning, GenericErrorDescriptionTxt);
        TempErrorMessage.LogSimpleMessage(ErrorMessage."Message Type"::Warning, GenericErrorDescriptionTxt);
        // Exercise
        ErrorMessages.Trap();
        ErrorMessage.SetContext(GLBCustomerContext);
        ErrorMessage.ShowErrorMessages(false);
        // Verify - only persistent message corresponding to one context will be displayed
        ErrorMessages.First();
        Assert.AreEqual(ErrorMessages.Description.Value, Format(GenericErrorDescriptionTxt), '');
        Assert.IsFalse(ErrorMessages.Next(), 'Records are not filtered to proper context.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageGetLastIDWithContext()
    var
        ErrorMessage: Record "Error Message";
    begin
        // [SCENARIO] GetLastID returns the last ID regardless of "Message Type" and keeps Context unchanged.
        Initialize();
        ErrorMessage.SetContext(GLBCustomerContext);
        ErrorMessage.LogSimpleMessage(ErrorMessage."Message Type"::Information, GenericErrorDescriptionTxt);

        ErrorMessage.TestField("Context Table Number", DATABASE::Customer);
        Assert.AreEqual(1, ErrorMessage.GetLastID(), 'GetLastID#1');

        ErrorMessage.LogSimpleMessage(ErrorMessage."Message Type"::Error, GenericErrorDescriptionTxt);
        ErrorMessage.TestField("Context Table Number", DATABASE::Customer);
        Assert.AreEqual(2, ErrorMessage.GetLastID(), 'GetLastID#2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLogContextFieldError()
    var
        ErrorMessage: Record "Error Message";
    begin
        // [SCENARIO] LogContextFieldError adds Error record not checking for uniqueness.
        Initialize();
        // [WHEN] Add two identical error messages with Context as Customer 'A' for field number 90,
        // [WHEN] Source as Vendor 'B' for field number 86; "Support URL" is 'Link'
        ErrorMessage.SetContext(GLBCustomerContext);
        ErrorMessage.LogContextFieldError(
          GLBCustomerContext.FieldNo(GLN), GenericErrorDescriptionTxt,
          GLBVendorContext, GLBVendorContext.FieldNo("VAT Registration No."), 'Link');

        ErrorMessage.LogContextFieldError(
          GLBCustomerContext.FieldNo(GLN), GenericErrorDescriptionTxt,
          GLBVendorContext, GLBVendorContext.FieldNo("VAT Registration No."), 'Link');

        // [THEN] 2 records added, where "Message Type" is 'Error', "Support URL" is 'Link'
        Assert.RecordCount(ErrorMessage, 2);
        ErrorMessage.TestField("Message Type", ErrorMessage."Message Type"::Error);
        ErrorMessage.TestField("Message", GenericErrorDescriptionTxt);
        ErrorMessage.TestField("Support Url", 'Link');
        // [THEN] Context record is Customer 'A', "Context Table Number" is Customer, "Context Field Number" is 90
        ErrorMessage.TestField("Context Record ID", GLBCustomerContext.RecordId);
        ErrorMessage.TestField("Context Table Number", DATABASE::Customer);
        ErrorMessage.TestField("Context Field Number", GLBCustomerContext.FieldNo(GLN));
        // [THEN] Source record is Vendor 'B', "Table Number" is Vendor, "Field Number" is 86
        ErrorMessage.TestField("Record ID", GLBVendorContext.RecordId);
        ErrorMessage.TestField("Table Number", DATABASE::Vendor);
        ErrorMessage.TestField("Field Number", GLBVendorContext.FieldNo("VAT Registration No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageLogContextFieldErrorSourceIsInteger()
    var
        ErrorMessage: Record "Error Message";
        DummyRecID: RecordID;
    begin
        // [SCENARIO] LogContextFieldError accepts a table number instead of Record ID as the source.
        Initialize();
        // [WHEN] Add two identical error messages with Context as Customer 'A' for field number 90,
        // [WHEN] Source as Table 'Vendor' for field number 86
        ErrorMessage.SetContext(GLBCustomerContext);
        ErrorMessage.LogContextFieldError(
          GLBCustomerContext.FieldNo(GLN), GenericErrorDescriptionTxt,
          DATABASE::Vendor, GLBVendorContext.FieldNo("VAT Registration No."), '');

        // [THEN] Records added, where Source is <blank>, Source table number is 'Vendor', "Field Number" is 86
        ErrorMessage.TestField("Record ID", DummyRecID);
        ErrorMessage.TestField("Table Number", DATABASE::Vendor);
        ErrorMessage.TestField("Field Number", GLBVendorContext.FieldNo("VAT Registration No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageFieldNameShowsContextField()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Field Name" shows context field caption if "Context Feild Number" is defined
        Initialize();

        // [GIVEN] Error context is set
        TempErrorMessage.SetContext(GLBCustomerContext);
        // [GIVEN] LogContextFieldError, where Context Field is 'GLN', Source Field is 'VAT Registration No.'
        TempErrorMessage.LogContextFieldError(
          GLBCustomerContext.FieldNo(GLN), GenericErrorDescriptionTxt,
          GLBVendorContext, GLBVendorContext.FieldNo("VAT Registration No."), '');

        // [WHEN] Open "Error Messages" page
        ErrorMessagesPage.Trap();
        TempErrorMessage.ShowErrors();

        // [THEN] Context "Field Name" is 'GLN', Source "Field Name" is 'VAT Registration No.'
        ErrorMessagesPage."Context Field Name".AssertEquals(GLBCustomerContext.FieldCaption(GLN));
        ErrorMessagesPage."Field Name".AssertEquals(GLBVendorContext.FieldCaption("VAT Registration No."));
        // [THEN] No drilldown on "Field Name" columns.
        asserterror ErrorMessagesPage."Context Field Name".DrillDown();
        Assert.ExpectedError(DrillDownErr);
        asserterror ErrorMessagesPage."Field Name".DrillDown();
        Assert.ExpectedError(DrillDownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageFieldNameShowsSourceFieldIfContextFieldBlank()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Field Name" shows source field caption if "Context Feild Number" is blank
        Initialize();

        // [GIVEN] Error context is not set
        // [GIVEN] LogContextFieldError, where Context Field is 'GLN', Source Field is 'VAT Registration No.'
        TempErrorMessage.LogContextFieldError(
          GLBCustomerContext.FieldNo(GLN), GenericErrorDescriptionTxt,
          GLBVendorContext, GLBVendorContext.FieldNo("VAT Registration No."), '');

        // [WHEN] Open "Error Messages" page
        ErrorMessagesPage.Trap();
        TempErrorMessage.ShowErrors();
        // [THEN] Context "Field Name" is <blank>, Source "Field Name" is 'VAT Registration No.'
        ErrorMessagesPage."Context Field Name".AssertEquals('');
        ErrorMessagesPage."Field Name".AssertEquals(GLBVendorContext.FieldCaption("VAT Registration No."));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HasErrorsMessageHandler')]
    procedure ErrorCallStackFromErrorOutsideOfErrorProcessingViaJobQueue()
    var
        SalesHeader: Record "Sales Header";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        SalesPostviaJobQueue: Codeunit "Sales Post via Job Queue";
    begin
        // [FEATURE] [Job Queue]
        // [SCENARIO 361491] "Error Call Stack" should be filled in while posting a document via job queue and the error is outside of the error processing feature
        Initialize();

        // [GIVEN] Setup to post sales document via job queue
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Sales invoice with empty "Posting Date" in order to get error from testfield
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader."Posting Date" := 0D;
        SalesHeader.Modify(false);

        // [WHEN] Post sales invoice via job queue
        JobQueueEntry.DeleteAll();
        SalesPostViaJobQueue.EnqueueSalesDoc(SalesHeader);
        JobQueueEntry.FindFirst();
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader.RecordId, true);

        // [THEN] Job queue log entry has Status = "Eror"
        // [THEN] Job queue log entry has non-empty "Error Call Stack"
        JobQueueLogEntry.SetRange(ID, JobQueueEntry.ID);
        JobQueueLogEntry.FindFirst();
        Assert.IsTrue(JobQueueLogEntry.Status = JobQueueLogEntry.Status::Error, 'Job Queue status should be "Error"');
        Assert.IsTrue(JobQueueLogEntry.GetErrorCallStack() <> '', '"Error Call Stack" should not be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LogTestFieldEmptyValue()
    var
        DummySalesHeader: Record "Sales Header";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391579] LogTestField for option field without value parameter logs error 
        Initialize();

        // [GIVEN] Activate error handling
        ErrorMessageMgt.Activate(ErrorMessageHandler);

        // [WHEN] Run LogTestField for Sales Header "Document Type"
        ErrorMessageMgt.LogTestField(DummySalesHeader, DummySalesHeader.FieldNo("Document Type"));

        // [THEN] Error "Document Type must not be Quote" logged 
        ErrorMessageHandler.AppendTo(TempErrorMessage);
        TempErrorMessage.FindFirst();
        Assert.AreEqual(
            StrSubstNo(FieldMustNotBeErr, DummySalesHeader.FieldCaption("Document Type"), DummySalesHeader."Document Type"),
            TempErrorMessage."Message",
            'Invalid error message');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LogTestFieldEmptyValueCheckContextFieldNo()
    var
        DummySalesHeader: Record "Sales Header";
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorContextElement: Codeunit "Error Context Element";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391579] LogTestField for option field without value parameter logs error with Context Field No.
        Initialize();

        // [GIVEN] Activate error handling with Gen. Journal Line context 
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        LibrarySales.CreateCustomer(Customer);
        ErrorMessageMgt.PushContext(ErrorContextElement, Customer.RecordId, Customer.FieldNo(Name), '');

        // [WHEN] Run LogTestField for Sales Header "Document Type" 
        ErrorMessageMgt.LogTestField(DummySalesHeader, DummySalesHeader.FieldNo("Document Type"));

        // [THEN] Error message has "Source Field Number" = 1 (Document Type), "Context Field Number" = 2 (Name)
        ErrorMessageHandler.AppendTo(TempErrorMessage);
        TempErrorMessage.FindFirst();
        TempErrorMessage.TestField("Field Number", DummySalesHeader.FieldNo("Document Type"));
        TempErrorMessage.TestField("Context Field Number", Customer.FieldNo(Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LogTestFieldCheckContextFieldNo()
    var
        DummySalesHeader: Record "Sales Header";
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorContextElement: Codeunit "Error Context Element";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391579] LogTestField for option field with value parameter logs error with Context Field No.
        Initialize();

        // [GIVEN] Activate error handling with Gen. Journal Line context 
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        LibrarySales.CreateCustomer(Customer);
        ErrorMessageMgt.PushContext(ErrorContextElement, Customer.RecordId, Customer.FieldNo(Name), '');

        // [WHEN] Run LogTestField for Sales Header "Document Type" 
        ErrorMessageMgt.LogTestField(DummySalesHeader, DummySalesHeader.FieldNo("Document Type"), DummySalesHeader."Document Type"::"Return Order");

        // [THEN] Error message has "Source Field Number" = 1 (Document Type), "Context Field Number" = 2 (Name)
        ErrorMessageHandler.AppendTo(TempErrorMessage);
        TempErrorMessage.FindFirst();
        TempErrorMessage.TestField("Field Number", DummySalesHeader.FieldNo("Document Type"));
        TempErrorMessage.TestField("Context Field Number", Customer.FieldNo(Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LogFieldErrorCheckContextFieldNo()
    var
        DummySalesHeader: Record "Sales Header";
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorContextElement: Codeunit "Error Context Element";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391579] LogFieldError for option field logs error with Context Field No.
        Initialize();

        // [GIVEN] Activate error handling with Gen. Journal Line context 
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        LibrarySales.CreateCustomer(Customer);
        ErrorMessageMgt.PushContext(ErrorContextElement, Customer.RecordId, Customer.FieldNo(Name), '');

        // [WHEN] Run LogFieldError for Sales Header "Document Type" 
        ErrorMessageMgt.LogFieldError(DummySalesHeader, DummySalesHeader.FieldNo("Document Type"), '');

        // [THEN] Error message has "Source Field Number" = 1 (Document Type), "Context Field Number" = 2 (Name)
        ErrorMessageHandler.AppendTo(TempErrorMessage);
        TempErrorMessage.FindFirst();
        TempErrorMessage.TestField("Field Number", DummySalesHeader.FieldNo("Document Type"));
        TempErrorMessage.TestField("Context Field Number", Customer.FieldNo(Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTGetFieldNo()
    var
        TableWithFieldCaption: Record TableWithFieldCaption;
        TempErrorMessage: Record "Error Message" temporary;
        TempErrorMessageActual: Record "Error Message" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessages: Page "Error Messages";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391579] Function GetFieldNo of LibraryErrorMessage codeunit uses field caption to find a field
        Initialize();

        // [GIVEN] Activate error handling 
        ErrorMessageMgt.Activate(ErrorMessageHandler);

        // [GIVEN] Run LogFieldError for MyField TableWithFieldCaption (Field Number = 2)
        ErrorMessageMgt.LogFieldError(TableWithFieldCaption, TableWithFieldCaption.FieldNo(MyField), '');
        ErrorMessageHandler.AppendTo(TempErrorMessage);
        TempErrorMessage.FindFirst();
        // [GIVEN] Set created error message to the Error Messages page
        ErrorMessages.SetRecords(TempErrorMessage);

        // [GIVEN] TrapErrorMessages for LibraryErrorMessage
        LibraryErrorMessage.TrapErrorMessages();
        ErrorMessages.Run();

        // [WHEN] Run LibraryErrorMessage.GetErrorMessages
        LibraryErrorMessage.GetErrorMessages(TempErrorMessageActual);

        // [THEN] Error message has "Source Field Number" = 2 (MyField)
        TempErrorMessageActual.FindFirst();
        TempErrorMessageActual.TestField("Field Number", TableWithFieldCaption.FieldNo(MyField));
    end;

    local procedure Initialize()
    var
        DataTypeBuffer: Record "Data Type Buffer";
        ErrorMessage: Record "Error Message";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Error Message Tests");
        LibraryErrorMessage.Clear();
        DataTypeBuffer.DeleteAll();
        ErrorMessage.DeleteAll();

        GLBCustomerContext.FindFirst();
        GLBVendorContext.FindFirst();
    end;

    local procedure VerifyErrorMessage(var TempErrorMessage: Record "Error Message" temporary; ID: Integer; FieldNumber: Integer; ErrorType: Option; Description: Text)
    begin
        TempErrorMessage.Get(ID);
        Assert.AreEqual(FieldNumber, TempErrorMessage."Field Number", InvalidErrorMessageDataErr);
        Assert.AreEqual(ErrorType, TempErrorMessage."Message Type", InvalidErrorMessageDataErr);
        Assert.AreEqual(Description, TempErrorMessage."Message", InvalidErrorMessageDataErr);
    end;

    local procedure VerifyPersistentErrorMessage(var TempErrorMessage: Record "Error Message" temporary; ID: Integer; ContextRecordID: RecordID; FieldNumber: Integer; ErrorType: Option; Description: Text)
    begin
        TempErrorMessage.Get(ID);
        Assert.AreEqual(ContextRecordID, TempErrorMessage."Context Record ID", InvalidErrorMessageDataErr);
        Assert.AreEqual(FieldNumber, TempErrorMessage."Field Number", InvalidErrorMessageDataErr);
        Assert.AreEqual(ErrorType, TempErrorMessage."Message Type", InvalidErrorMessageDataErr);
        Assert.AreEqual(Description, TempErrorMessage."Message", InvalidErrorMessageDataErr);
    end;

    local procedure VerifyDetailedErrorMessage(var TempErrorMessage: Record "Error Message" temporary; ID: Integer; AdditionalInformation: Text[250]; SupportUrl: Text[250])
    begin
        TempErrorMessage.Get(ID);
        Assert.AreEqual(AdditionalInformation, TempErrorMessage."Additional Information", InvalidErrorMessageDataErr);
        Assert.AreEqual(SupportUrl, TempErrorMessage."Support Url", InvalidErrorMessageDataErr);
    end;

    local procedure FillDataTypeTestTableWithValidData(var DataTypeBuffer: Record "Data Type Buffer")
    var
        CurrencyRecordRef: RecordRef;
        OutStream: OutStream;
    begin
        CurrencyRecordRef.Open(DATABASE::Currency);
        CurrencyRecordRef.FindFirst();
        DataTypeBuffer.Init();
        DataTypeBuffer.ID := LibraryRandom.RandIntInRange(1, 100);
        DataTypeBuffer.BLOB.CreateOutStream(OutStream);
        OutStream.WriteText(LibraryUtility.GenerateRandomText(100));
        DataTypeBuffer.BigInteger := LibraryRandom.RandIntInRange(1, 10000000);
        DataTypeBuffer.Boolean := true;
        DataTypeBuffer.Code := LibraryUtility.GenerateRandomCode(DataTypeBuffer.FieldNo(Code), DATABASE::"Data Type Buffer");
        DataTypeBuffer.Date := LibraryUtility.GenerateRandomDate(DMY2Date(1, 1, 2001), DMY2Date(31, 12, 2020));
        Evaluate(DataTypeBuffer.DateFormula, '<1W>');
        DataTypeBuffer.DateTime := CurrentDateTime;
        DataTypeBuffer.Decimal := LibraryRandom.RandDecInRange(1, 1000, 2);
        DataTypeBuffer.Duration :=
          LibraryUtility.GenerateRandomDate(DMY2Date(1, 1, 2005), DMY2Date(31, 12, 2020)) -
          LibraryUtility.GenerateRandomDate(DMY2Date(1, 1, 2001), DMY2Date(31, 12, 2004));
        DataTypeBuffer.GUID := CreateGuid();
        DataTypeBuffer.Option := LibraryRandom.RandIntInRange(1, 2);
        DataTypeBuffer.RecordID := CurrencyRecordRef.RecordId;
        DataTypeBuffer.Text := CopyStr(LibraryUtility.GenerateRandomText(30), 1, MaxStrLen(DataTypeBuffer.Text));
        DataTypeBuffer.Time := 070000T;
        DataTypeBuffer.Insert(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure HasErrorsMessageHandler(Message: Text[1024])
    begin
    end;
}

