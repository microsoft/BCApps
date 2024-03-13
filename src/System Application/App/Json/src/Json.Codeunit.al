// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Json;

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
        JsonImpl.InitializeCollection(JSONString);
    end;

    /// <summary>
    /// Initializes the JSON object with the specified JSON string.
    /// </summary>
    /// <param name="JSONString">The Json string</param>
    procedure InitializeObject(JSONString: Text)
    begin
        JsonImpl.InitializeObject(JSONString);
    end;

    /// <summary>
    /// Returns the number of elements in the JSON array.
    /// </summary>
    procedure GetCollectionCount(): Integer
    begin
        exit(JsonImpl.GetCollectionCount());
    end;

    /// <summary>
    /// Returns the JSON object at the specified index in the JSON array.
    /// </summary>
    /// <param name="Index">The index of the JSON object</param>
    /// <param name="JsonObjectTxt">The JSON object in text format</param>
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
    procedure GetValueAndSetToRecFieldNo(RecordRef: RecordRef; PropertyPath: Text; FieldNo: Integer): Boolean
    begin
        exit(JsonImpl.GetValueAndSetToRecFieldNo(RecordRef, PropertyPath, FieldNo));
    end;

    /// <summary>
    /// Gets the value at the specified property path in the JSON object.
    /// </summary>
    /// <param name="PropertyPath">The property path</param>
    /// <param name="Value">The value</param>
    procedure GetPropertyValueByName(propertyName: Text; var value: Variant): Boolean
    begin
        exit(JsonImpl.GetPropertyValueByName(propertyName, value));
    end;

    /// <summary>
    /// Gets the text value at the specified property path in the JSON object.
    /// </summary>
    /// <param name="PropertyPath">The property path</param>
    /// <param name="Value">The value</param>
    procedure GetStringPropertyValueByName(propertyName: Text; var value: Text): Boolean
    begin
        exit(JsonImpl.GetStringPropertyValueByName(propertyName, value));
    end;

    /// <summary>
    /// Gets the option value at the specified property path in the JSON object.
    /// </summary>
    /// <param name="PropertyPath">The property path</param>
    /// <param name="Value">The value</param>
    procedure GetEnumPropertyValueFromJObjectByName(propertyName: Text; var value: Option): Boolean
    begin
        exit(JsonImpl.GetEnumPropertyValueFromJObjectByName(propertyName, value));
    end;

    /// <summary>
    /// Gets the boolean value at the specified property path in the JSON object.
    /// </summary>
    /// <param name="PropertyPath">The property path</param>
    /// <param name="Value">The value</param>
    procedure GetBoolPropertyValueFromJObjectByName(propertyName: Text; var value: Boolean): Boolean
    begin
        exit(JsonImpl.GetBoolPropertyValueFromJObjectByName(propertyName, value));
    end;

    /// <summary>
    /// Gets the decimal value at the specified property path in the JSON object.
    /// </summary>
    /// <param name="PropertyPath">The property path</param>
    /// <param name="Value">The value</param>
    procedure GetDecimalPropertyValueFromJObjectByName(propertyName: Text; var value: Decimal): Boolean
    begin
        exit(JsonImpl.GetDecimalPropertyValueFromJObjectByName(propertyName, value));
    end;

    /// <summary>
    /// Gets the integer value at the specified property path in the JSON object.
    /// </summary>
    /// <param name="PropertyPath">The property path</param>
    /// <param name="Value">The value</param>
    procedure GetIntegerPropertyValueFromJObjectByName(propertyName: Text; var value: Integer): Boolean
    begin
        exit(JsonImpl.GetIntegerPropertyValueFromJObjectByName(propertyName, value));
    end;

    /// <summary>
    /// Gets the Guid value at the specified property path in the JSON object.
    /// </summary>
    /// <param name="PropertyPath">The property path</param>
    /// <param name="Value">The value</param>
    procedure GetGuidPropertyValueFromJObjectByName(propertyName: Text; var value: Guid): Boolean
    begin
        exit(JsonImpl.GetGuidPropertyValueFromJObjectByName(propertyName, value));
    end;
}
