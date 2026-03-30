// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.EServices.EDocumentConnector.Avalara.Models;

codeunit 133630 "Unit Tests - Models"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    // Metadata.Codeunit Tests

    [Test]
    procedure TestMetadata_SetWorkflowId_SetsCorrectly()
    var
        Metadata: Codeunit Metadata;
        JsonText: Text;
    begin
        // [SCENARIO] Metadata SetWorkflowId method sets workflow ID correctly

        // [GIVEN] A metadata object
        Initialize();

        // [WHEN] Setting workflow ID
        Metadata.SetWorkflowId('partner-einvoicing');

        // [THEN] Should be included in JSON output
        JsonText := Metadata.ToString();
        Assert.IsTrue(StrPos(JsonText, 'partner-einvoicing') > 0,
            'JSON should contain workflow ID');
    end;

    [Test]
    procedure TestMetadata_SetDataFormat_SetsCorrectly()
    var
        Metadata: Codeunit Metadata;
        JsonText: Text;
    begin
        // [SCENARIO] Metadata SetDataFormat method sets format correctly

        // [GIVEN] A metadata object
        Initialize();

        // [WHEN] Setting data format
        Metadata.SetDataFormat('ubl-invoice');

        // [THEN] Should be included in JSON output
        JsonText := Metadata.ToString();
        Assert.IsTrue(StrPos(JsonText, 'ubl-invoice') > 0,
            'JSON should contain data format');
    end;

    [Test]
    procedure TestMetadata_SetDataFormatVersion_SetsCorrectly()
    var
        Metadata: Codeunit Metadata;
        JsonText: Text;
    begin
        // [SCENARIO] Metadata SetDataFormatVersion method sets version correctly

        // [GIVEN] A metadata object
        Initialize();

        // [WHEN] Setting format version
        Metadata.SetDataFormatVersion('2.1');

        // [THEN] Should be included in JSON output
        JsonText := Metadata.ToString();
        Assert.IsTrue(StrPos(JsonText, '2.1') > 0,
            'JSON should contain format version');
    end;

    [Test]
    procedure TestMetadata_SetCountry_SetsCorrectly()
    var
        Metadata: Codeunit Metadata;
        JsonText: Text;
    begin
        // [SCENARIO] Metadata SetCountry method sets country code correctly

        // [GIVEN] A metadata object
        Initialize();

        // [WHEN] Setting country code
        Metadata.SetCountry('GB');

        // [THEN] Should be included in JSON output
        JsonText := Metadata.ToString();
        Assert.IsTrue(StrPos(JsonText, 'GB') > 0,
            'JSON should contain country code');
    end;

    [Test]
    procedure TestMetadata_SetMandate_SetsCorrectly()
    var
        Metadata: Codeunit Metadata;
        JsonText: Text;
    begin
        // [SCENARIO] Metadata SetMandate method sets mandate correctly

        // [GIVEN] A metadata object
        Initialize();

        // [WHEN] Setting mandate
        Metadata.SetMandate('GB-PEPPOL-INVOICE');

        // [THEN] Should be included in JSON output
        JsonText := Metadata.ToString();
        Assert.IsTrue(StrPos(JsonText, 'GB-PEPPOL-INVOICE') > 0,
            'JSON should contain mandate');
    end;

    [Test]
    procedure TestMetadata_ChainedCalls_BuildsCompleteObject()
    var
        Metadata: Codeunit Metadata;
        JsonText: Text;
    begin
        // [SCENARIO] Metadata supports chained method calls

        // [GIVEN] A metadata object
        Initialize();

        // [WHEN] Chaining multiple setter calls
        Metadata
            .SetWorkflowId('partner-einvoicing')
            .SetDataFormat('ubl-invoice')
            .SetDataFormatVersion('2.1')
            .SetCountry('GB')
            .SetMandate('GB-PEPPOL-INVOICE');

        // [THEN] All values should be in JSON
        JsonText := Metadata.ToString();
        Assert.IsTrue(StrPos(JsonText, 'partner-einvoicing') > 0, 'Should contain workflow ID');
        Assert.IsTrue(StrPos(JsonText, 'ubl-invoice') > 0, 'Should contain data format');
        Assert.IsTrue(StrPos(JsonText, '2.1') > 0, 'Should contain version');
        Assert.IsTrue(StrPos(JsonText, 'GB') > 0, 'Should contain country');
        Assert.IsTrue(StrPos(JsonText, 'GB-PEPPOL-INVOICE') > 0, 'Should contain mandate');
    end;

    [Test]
    procedure TestMetadata_ToString_ReturnsValidJson()
    var
        Metadata: Codeunit Metadata;
        JsonObject: JsonObject;
        JsonText: Text;
    begin
        // [SCENARIO] Metadata ToString returns valid JSON

        // [GIVEN] A fully populated metadata object
        Initialize();
        Metadata
            .SetWorkflowId('partner-einvoicing')
            .SetDataFormat('ubl-invoice')
            .SetDataFormatVersion('2.1')
            .SetCountry('DE')
            .SetMandate('DE-XRECHNUNG');

        // [WHEN] Getting JSON string
        JsonText := Metadata.ToString();

        // [THEN] Should be valid parseable JSON
        Assert.IsTrue(JsonObject.ReadFrom(JsonText), 'Should be valid JSON');
    end;

    [Test]
    procedure TestMetadata_JsonStructure_HasCorrectFields()
    var
        Metadata: Codeunit Metadata;
        JsonObject: JsonObject;
        WorkflowToken: JsonToken;
        JsonText: Text;
    begin
        // [SCENARIO] Metadata JSON has correct field names

        // [GIVEN] A metadata object with data
        Initialize();
        Metadata
            .SetWorkflowId('test-workflow')
            .SetDataFormat('test-format')
            .SetCountry('US');

        // [WHEN] Parsing JSON
        JsonText := Metadata.ToString();
        JsonObject.ReadFrom(JsonText);

        // [THEN] Should have expected field names
        Assert.IsTrue(JsonObject.Get('workflowId', WorkflowToken), 'Should have workflowId field');
        Assert.IsTrue(JsonObject.Contains('dataFormat'), 'Should have dataFormat field');
        Assert.IsTrue(JsonObject.Contains('countryCode'), 'Should have countryCode field');
    end;

    // Mandate.Table Tests

    [Test]
    procedure TestMandate_Insert_StoresData()
    var
        Mandate: Record Mandate;
    begin
        // [SCENARIO] Mandate table stores mandate information

        // [GIVEN] A temporary mandate record
        Initialize();

        // [WHEN] Inserting mandate data
        Mandate.Init();
        Mandate."Country Mandate" := 'GB-PEPPOL-INVOICE';
        Mandate."Country Code" := 'GB';
        Mandate.Description := 'UK PEPPOL Invoice';
        Mandate."Invoice Format" := 'application/vnd.oasis.ubl+xml';
        Mandate.Insert();

        // [THEN] Data should be stored
        Mandate.Get('GB-PEPPOL-INVOICE');
        Assert.AreEqual('GB', Mandate."Country Code", 'Country code should match');
        Assert.AreEqual('UK PEPPOL Invoice', Mandate.Description, 'Description should match');

        // No cleanup needed for temporary table
    end;

    [Test]
    procedure TestMandate_MultipleFormats_Supported()
    var
        Mandate: Record Mandate;
    begin
        // [SCENARIO] Mandate supports multiple document formats

        // [GIVEN] A mandate with multiple formats
        Initialize();

        // [WHEN] Setting various format fields
        Mandate.Init();
        Mandate."Country Mandate" := 'DE-XRECHNUNG';
        Mandate."Invoice Format" := 'application/xml';
        Mandate."Credit Note Format" := 'application/xml';
        Mandate."ubl-order" := 'application/vnd.oasis.ubl+xml';
        Mandate.Insert();

        // [THEN] All formats should be stored
        Mandate.Get('DE-XRECHNUNG');
        Assert.AreEqual('application/xml', Mandate."Invoice Format", 'Invoice format should match');
        Assert.AreEqual('application/xml', Mandate."Credit Note Format", 'Credit note format should match');
        Assert.AreNotEqual('', Mandate."ubl-order", 'Order format should be set');

        // No cleanup needed for temporary table
    end;

    [Test]
    procedure TestMandate_FilterByCountry_Works()
    var
        Mandate1, Mandate2, Mandate3 : Record Mandate;
        FilteredMandates: Record Mandate;
    begin
        // [SCENARIO] Mandates can be filtered by country code

        // [GIVEN] Mandates for different countries
        Initialize();

        Mandate1.Init();
        Mandate1."Country Mandate" := 'GB-PEPPOL';
        Mandate1."Country Code" := 'GB';
        Mandate1.Insert();

        Mandate2.Init();
        Mandate2."Country Mandate" := 'DE-XRECHNUNG';
        Mandate2."Country Code" := 'DE';
        Mandate2.Insert();

        Mandate3.Init();
        Mandate3."Country Mandate" := 'GB-MTD';
        Mandate3."Country Code" := 'GB';
        Mandate3.Insert();

        // [WHEN] Filtering for GB mandates
        FilteredMandates.SetRange("Country Code", 'GB');

        // [THEN] Should find only GB mandates
        Assert.AreEqual(2, FilteredMandates.Count(), 'Should find 2 GB mandates');

        // No cleanup needed for temporary table
    end;

    [Test]
    procedure TestMandate_LongDescription_Truncated()
    var
        Mandate: Record Mandate;
        LongDescription: Text;
    begin
        // [SCENARIO] Long mandate descriptions are truncated to field length

        // [GIVEN] A very long description
        Initialize();
        LongDescription := PadStr('', 3000, 'X');  // Longer than field length

        // [WHEN] Inserting with long description
        Mandate.Init();
        Mandate."Country Mandate" := 'TEST-LONG';
        Mandate.Description := CopyStr(LongDescription, 1, MaxStrLen(Mandate.Description));
        Mandate.Insert();

        // [THEN] Should be truncated
        Mandate.Get('TEST-LONG');
        Assert.AreEqual(MaxStrLen(Mandate.Description), StrLen(Mandate.Description),
            'Description should be truncated to max length');

        // No cleanup needed for temporary table
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;
}
