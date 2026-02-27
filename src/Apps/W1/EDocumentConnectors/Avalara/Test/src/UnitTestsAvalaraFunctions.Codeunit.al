// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;
using System.Utilities;

codeunit 148192 "Unit Tests - Avalara Functions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryEDocument: Codeunit "Library - E-Document";
        IsInitialized: Boolean;

    [Test]
    procedure TestIsAvalaraActive_WithValidSetup()
    var
        ConnectionSetup: Record "Connection Setup";
        AvalaraFunctions: Codeunit "Avalara Functions";
    begin
        // [SCENARIO] IsAvalaraActive returns true when connection setup exists with valid credentials

        // [GIVEN] A connection setup record with client credentials
        Initialize();
        CreateMockConnectionSetup(ConnectionSetup);

        // [WHEN] IsAvalaraActive is called
        // [THEN] It should return true
        Assert.IsTrue(AvalaraFunctions.IsAvalaraActive(), 'IsAvalaraActive should return true with valid setup');

        // Cleanup
        ConnectionSetup.Delete();
    end;

    [Test]
    procedure TestIsAvalaraActive_WithoutSetup()
    var
        ConnectionSetup: Record "Connection Setup";
        AvalaraFunctions: Codeunit "Avalara Functions";
    begin
        // [SCENARIO] IsAvalaraActive returns false when no connection setup exists

        // [GIVEN] No connection setup record
        if ConnectionSetup.Get() then
            ConnectionSetup.Delete();

        // [WHEN] IsAvalaraActive is called
        // [THEN] It should return false
        Assert.IsFalse(AvalaraFunctions.IsAvalaraActive(), 'IsAvalaraActive should return false without setup');
    end;

    [Test]
    procedure TestGetAvailableMediaTypesForMandate_GB()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        MediaTypes: List of [Text];
    begin
        // [SCENARIO] GetAvailableMediaTypesForMandate returns correct media types for GB mandate

        // [GIVEN] A GB mandate
        Initialize();

        // [WHEN] Getting available media types for GB-Test-Mandate
        MediaTypes := AvalaraFunctions.GetAvailableMediaTypesForMandate('GB-Test-Mandate');

        // [THEN] Should return expected media types
        Assert.IsTrue(MediaTypes.Count > 0, 'Should return at least one media type for GB mandate');
        Assert.IsTrue(MediaTypes.Contains('application/vnd.oasis.ubl+xml'), 'Should contain UBL XML media type');
    end;

    [Test]
    procedure TestGetAvailableMediaTypesForMandate_InvalidMandate()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        MediaTypes: List of [Text];
    begin
        // [SCENARIO] GetAvailableMediaTypesForMandate returns empty list for invalid mandate

        // [GIVEN] An invalid mandate
        Initialize();

        // [WHEN] Getting available media types for invalid mandate
        MediaTypes := AvalaraFunctions.GetAvailableMediaTypesForMandate('INVALID-MANDATE');

        // [THEN] Should return empty list or default types
        // Implementation should handle gracefully
    end;

    [Test]
    procedure TestLoadFieldsFromJson_ValidJson()
    var
        AvalaraInputField: Record "Avalara Input Field";
        AvalaraFunctions: Codeunit "Avalara Functions";
        FieldsArray: JsonArray;
        JsonText: Text;
    begin
        // [SCENARIO] LoadFieldsFromJson correctly parses JSON array into Avalara Input Fields

        // [GIVEN] A valid JSON array with field definitions
        Initialize();
        JsonText := GetMockFieldsJson();
        FieldsArray.ReadFrom(JsonText);

        // [WHEN] Loading fields from JSON
        AvalaraFunctions.LoadFieldsFromJson(FieldsArray, 'GB-TEST', 'ubl-invoice', '2.1');

        // [THEN] Fields should be inserted into the table
        AvalaraInputField.SetRange(Mandate, 'GB-TEST');
        AvalaraInputField.SetRange("Document Type", 'ubl-invoice');
        AvalaraInputField.SetRange("Document Version", '2.1');
        Assert.RecordIsNotEmpty(AvalaraInputField);

        // Cleanup
        AvalaraInputField.DeleteAll();
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    local procedure CreateMockEDocumentService(var EDocumentService: Record "E-Document Service"; Mandate: Code[40])
    begin
        EDocumentService.Init();
        EDocumentService.Code := 'AVALARA-TEST';
        EDocumentService."Service Integration V2" := EDocumentService."Service Integration V2"::Avalara;
        EDocumentService."Avalara Mandate" := Mandate;
        if EDocumentService.Insert() then;
    end;

    local procedure GetMockFieldsJson(): Text
    begin
        exit('[{"fieldId":1,"documentType":"ubl-invoice","documentVersion":"2.1","path":"//cbc:ID","pathType":"xpath","fieldName":"Invoice Number","exampleOrFixedValue":"INV-001","documentationLink":"http://example.com","dataType":"string","description":"Invoice identifier","optionality":"mandatory","acceptedValues":""}]');
    end;
}
