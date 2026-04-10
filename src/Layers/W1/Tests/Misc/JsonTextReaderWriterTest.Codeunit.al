codeunit 139211 "Json Text Reader/Writer Test"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [JSON] [UT]
    end;

    var
        Assert: Codeunit Assert;
        InvalidJsonValueTxt: Label 'Invalid Json Value for property %1';

    [Test]
    [Scope('OnPrem')]
    procedure TestWriter()
    var
        TempJSONBuffer: Record "JSON Buffer" temporary;
        JsonTextReaderWriter: Codeunit "Json Text Reader/Writer";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        Json: Text;
    begin
        // [SCENARIO] Write Json and verify read Json
        LibraryLowerPermissions.SetO365Basic();
        // [GIVEN] https://en.wikipedia.org/wiki/JSON
        // [WHEN] Writing
        JsonTextReaderWriter.WriteStartObject('');
        JsonTextReaderWriter.WriteStringProperty('firstName', 'John');
        JsonTextReaderWriter.WriteStringProperty('lastName', 'Smith');
        JsonTextReaderWriter.WriteBooleanProperty('isAlive', true);
        JsonTextReaderWriter.WriteNumberProperty('age', 27);
        JsonTextReaderWriter.WriteStartObject('address');
        JsonTextReaderWriter.WriteStringProperty('streetAddress', '21 2nd Street');
        JsonTextReaderWriter.WriteStringProperty('city', 'New York');
        JsonTextReaderWriter.WriteStringProperty('state', 'NY');
        JsonTextReaderWriter.WriteStringProperty('postalCode', '10021-3100');
        JsonTextReaderWriter.WriteEndObject();
        JsonTextReaderWriter.WriteStartArray('phoneNumbers');
        JsonTextReaderWriter.WriteStartObject('');
        JsonTextReaderWriter.WriteStringProperty('type', 'home');
        JsonTextReaderWriter.WriteStringProperty('number', '212 555-1234');
        JsonTextReaderWriter.WriteEndObject();
        JsonTextReaderWriter.WriteStartObject('');
        JsonTextReaderWriter.WriteStringProperty('type', 'office');
        JsonTextReaderWriter.WriteStringProperty('number', '646 555-4567');
        JsonTextReaderWriter.WriteEndObject();
        JsonTextReaderWriter.WriteStartObject('');
        JsonTextReaderWriter.WriteStringProperty('type', 'mobile');
        JsonTextReaderWriter.WriteStringProperty('number', '123 456-7890');
        JsonTextReaderWriter.WriteEndObject();
        JsonTextReaderWriter.WriteEndArray();
        JsonTextReaderWriter.WriteStartArray('children');
        JsonTextReaderWriter.WriteEndArray();
        JsonTextReaderWriter.WriteNullProperty('spouce');
        JsonTextReaderWriter.WriteEndObject();
        Json := JsonTextReaderWriter.GetJSonAsText();

        // [WHEN] Reading Json back into Json Buffer
        JsonTextReaderWriter.ReadJSonToJSonBuffer(Json, TempJSONBuffer);

        // [THEN] JsonBuffer content is identical to input values
        VerifyPropertyValue(TempJSONBuffer, 'firstName', 'John');
        VerifyPropertyValue(TempJSONBuffer, 'lastName', 'Smith');
        VerifyPropertyValue(TempJSONBuffer, 'isAlive', true);
        VerifyPropertyValue(TempJSONBuffer, 'age', 27);
        VerifyPropertyValue(TempJSONBuffer, 'streetAddress', '21 2nd Street');
        VerifyPropertyValue(TempJSONBuffer, 'city', 'New York');
        VerifyPropertyValue(TempJSONBuffer, 'state', 'NY');
        VerifyPropertyValue(TempJSONBuffer, 'postalCode', '10021-3100');
        VerifyPropertyValue(TempJSONBuffer, 'type', 'home');
        VerifyPropertyValue(TempJSONBuffer, 'number', '212 555-1234');
    end;

    local procedure VerifyPropertyValue(var TempJSONBuffer: Record "JSON Buffer" temporary; PropertyName: Text; PropertyValue: Variant)
    begin
        TempJSONBuffer.SetRange("Token type", TempJSONBuffer."Token type"::"Property Name");
        TempJSONBuffer.SetRange(Value, PropertyName);
        TempJSONBuffer.FindFirst();
        TempJSONBuffer.Reset();
        TempJSONBuffer.Next();
        case true of
            PropertyValue.IsText:
                begin
                    Assert.AreEqual(TempJSONBuffer."Token type"::String, TempJSONBuffer."Token type", StrSubstNo(InvalidJsonValueTxt, PropertyName));
                    Assert.AreEqual(PropertyValue, TempJSONBuffer.Value, StrSubstNo(InvalidJsonValueTxt, PropertyName));
                end;
            PropertyValue.IsInteger, PropertyValue.IsDecimal:
                begin
                    Assert.AreEqual(TempJSONBuffer."Token type"::Decimal, TempJSONBuffer."Token type", StrSubstNo(InvalidJsonValueTxt, PropertyName));
                    Assert.AreEqual(Format(PropertyValue, 0, 9), TempJSONBuffer.Value, StrSubstNo(InvalidJsonValueTxt, PropertyName));
                end;
            PropertyValue.IsBoolean:
                begin
                    Assert.AreEqual(TempJSONBuffer."Token type"::Boolean, TempJSONBuffer."Token type", StrSubstNo(InvalidJsonValueTxt, PropertyName));
                    Assert.AreEqual(Format(PropertyValue, 0, 9), Format(TempJSONBuffer.Value = 'Yes', 0, 9), StrSubstNo(InvalidJsonValueTxt, PropertyName));
                end;
        end;
    end;
}

