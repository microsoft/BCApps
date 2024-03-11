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
    /// <param name="Object">The JSON object</param>
    /// <param name="Index">The index of the JSON object</param>
    procedure GetObjectFromCollectionByIndex(var "Object": Text; Index: Integer): Boolean
    begin
        exit(JsonImpl.GetObjectFromCollectionByIndex("Object", Index));
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
}
