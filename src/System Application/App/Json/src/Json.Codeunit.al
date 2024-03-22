// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Text.Json;

codeunit 5460 Json
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        JsonImpl: Codeunit "Json Impl.";

    /// <summary>
    /// Initializes the JSON array with the specified JSON string.
    /// </summary>
    /// <param name="JSONString">The Json string</param>
    procedure InitializeCollection(JSONString: Text)
    begin
        JsonImpl.InitializeCollectionFromString(JSONString);
    end;

    /// <summary>
    /// Initializes the JSON object with the specified JSON string.
    /// </summary>
    /// <param name="JSONString">The Json string</param>
    procedure InitializeObject(JSONString: Text)
    begin
        JsonImpl.InitializeObjectFromString(JSONString);
    end;

    /// <summary>
    /// Returns the number of elements in the JSON array.
    /// </summary>
    /// <returns>The number of elements in the JSON array</returns>
    procedure GetCollectionCount(): Integer
    begin
        exit(JsonImpl.GetCollectionCount());
    end;

    /// <summary>
    /// Returns the JSON array in text format.
    /// </summary>
    /// <returns>The JSON array in text format</returns>
    procedure GetCollectionAsText(): Text
    begin
        exit(JsonImpl.GetCollectionAsText());
    end;

    /// <summary>
    /// Returns the JSON array.
    /// </summary>
    /// <returns>The JSON array</returns>
    procedure GetCollection(): JsonArray
    begin
        exit(JsonImpl.GetCollection());
    end;

    /// <summary>
    /// Returns the JSON object in text format.
    /// </summary>
    /// <returns>The JSON object in text format</returns>
    procedure GetObjectAsText(): Text
    begin
        exit(JsonImpl.GetObjectAsText());
    end;

    /// <summary>
    /// Returns the JSON object.
    /// </summary>
    /// <returns>The JSON object</returns>
    procedure GetObject(): JsonObject
    begin
        exit(JsonImpl.GetObject());
    end;

    /// <summary>
    /// Returns the JSON object at the specified index in the JSON array.
    /// </summary>
    /// <param name="Index">The index of the JSON object</param>
    /// <param name="JsonObjectTxt">The JSON object in text format</param>
    /// <returns>True if the JSON object is returned; otherwise, false</returns>
    procedure GetObjectFromCollectionByIndex(Index: Integer; var JsonObjectTxt: Text): Boolean
    begin
        exit(JsonImpl.GetObjectFromCollectionByIndex(Index, JsonObjectTxt));
    end;

    /// <summary>
    /// Gets the value at the specified property path in the JSON object and sets it to the specified record field.
    /// </summary>
    /// <param name="RecordRef">The record reference</param>
    /// <param name="PropertyPath">The property path</param>
    /// <param name="FieldNo">The field number</param>
    /// <returns>True if the value is set to the record field; otherwise, false</returns>
    /// <remarks>
    /// Next type of fields are supported: Integer, Decimal, Date, Boolean, GUID, Text, Code, Option, BLOB, RecordID
    /// Text values are trimmed to the Max Length of the field.
    /// </remarks>
    procedure GetValueAndSetToRecFieldNo(RecordRef: RecordRef; PropertyPath: Text; FieldNo: Integer): Boolean
    begin
        exit(JsonImpl.GetValueAndSetToRecFieldNo(RecordRef, PropertyPath, FieldNo));
    end;

    /// <summary>
    /// Gets the value at the specified property name in the JSON object.
    /// </summary>
    /// <param name="PropertyName">The property name</param>
    /// <param name="Value">The value</param>
    /// <returns>True if the value is returned; otherwise, false</returns>
    procedure GetPropertyValueByName(PropertyName: Text; var Value: Variant): Boolean
    begin
        exit(JsonImpl.GetPropertyValueFromJObjectByName(PropertyName, Value));
    end;

    /// <summary>
    /// Gets the text value at the specified property name in the JSON object.
    /// </summary>
    /// <param name="PropertyName">The property name</param>
    /// <param name="Value">The value</param>
    /// <returns>True if the value is returned; otherwise, false</returns>
    procedure GetStringPropertyValueByName(PropertyName: Text; var Value: Text): Boolean
    begin
        exit(JsonImpl.GetStringPropertyValueFromJObjectByName(PropertyName, Value));
    end;

    /// <summary>
    /// Gets the option value at the specified property name in the JSON object.
    /// </summary>
    /// <param name="PropertyName">The property name</param>
    /// <param name="Value">The value</param>
    /// <returns>True if the value is returned; otherwise, false</returns>
    procedure GetEnumPropertyValueFromJObjectByName(PropertyName: Text; var Value: Option): Boolean
    begin
        exit(JsonImpl.GetEnumPropertyValueFromJObjectByName(PropertyName, Value));
    end;

    /// <summary>
    /// Gets the boolean value at the specified property name in the JSON object.
    /// </summary>
    /// <param name="PropertyName">The property name</param>
    /// <param name="Value">The value</param>
    /// <returns>True if the value is returned; otherwise, false</returns>
    procedure GetBoolPropertyValueFromJObjectByName(PropertyName: Text; var Value: Boolean): Boolean
    begin
        exit(JsonImpl.GetBoolPropertyValueFromJObjectByName(PropertyName, Value));
    end;

    /// <summary>
    /// Gets the decimal value at the specified property name in the JSON object.
    /// </summary>
    /// <param name="PropertyName">The property name</param>
    /// <param name="Value">The value</param>
    /// <returns>True if the value is returned; otherwise, false</returns>
    procedure GetDecimalPropertyValueFromJObjectByName(PropertyName: Text; var Value: Decimal): Boolean
    begin
        exit(JsonImpl.GetDecimalPropertyValueFromJObjectByName(PropertyName, Value));
    end;

    /// <summary>
    /// Gets the integer value at the specified property name in the JSON object.
    /// </summary>
    /// <param name="PropertyName">The property name</param>
    /// <param name="Value">The value</param>
    /// <returns>True if the value is returned; otherwise, false</returns>
    procedure GetIntegerPropertyValueFromJObjectByName(PropertyName: Text; var Value: Integer): Boolean
    begin
        exit(JsonImpl.GetIntegerPropertyValueFromJObjectByName(PropertyName, Value));
    end;

    /// <summary>
    /// Gets the Guid value at the specified property name in the JSON object.
    /// </summary>
    /// <param name="PropertyName">The property name</param>
    /// <param name="Value">The value</param>
    /// <returns>True if the value is returned; otherwise, false</returns>
    procedure GetGuidPropertyValueFromJObjectByName(PropertyName: Text; var Value: Guid): Boolean
    begin
        exit(JsonImpl.GetGuidPropertyValueFromJObjectByName(PropertyName, Value));
    end;

    /// <summary>
    /// Replace or add the specified property in the JSON object.
    /// </summary>
    /// <param name="PropertyName">The property name</param>
    /// <param name="Value">The value</param>
    /// <returns>True if the property is replaced or added; otherwise, false</returns>
    procedure ReplaceOrAddJPropertyInJObject(PropertyName: Text; Value: Variant): Boolean
    begin
        exit(JsonImpl.ReplaceOrAddJPropertyInJObject(PropertyName, Value));
    end;

    /// <summary>
    /// Add the the JSON object to the JSON array.
    /// </summary>
    /// <param name="Value">The JSON object in text format</param>
    /// <returns>True if the JSON object is added; otherwise, false</returns>
    procedure AddJObjectToCollection(Value: Text): Boolean
    begin
        exit(JsonImpl.AddJObjectToCollection(Value));
    end;

    /// <summary>
    /// Remove the JSON object at the specified index in the JSON array.
    /// </summary>
    /// <param name="Index">The index of the JSON object</param>
    /// <returns>True if the JSON object is removed; otherwise, false</returns>
    procedure RemoveJObjectFromCollection(Index: Integer): Boolean
    begin
        exit(JsonImpl.RemoveJObjectFromCollection(Index));
    end;

    /// <summary>
    /// Replace the specified JSON object in the JSON array.
    /// </summary>
    /// <param name="Index">The index of the JSON object</param>
    /// <param name="Value">The JSON object in text format</param>
    /// <returns>True if the JSON object is replaced; otherwise, false</returns>
    procedure ReplaceJObjectInCollection(Index: Integer; Value: Text): Boolean
    begin
        exit(JsonImpl.ReplaceJObjectInCollection(Index, Value));
    end;

}
