// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Text;

using System.Text;

codeunit 135044 "IDA 1D Code39 Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TestCode39Encoding();
    var
        GenericBarcodeTestHelper: Codeunit "Generic Barcode Test Helper";
    begin
        // [Scenario] Encoding a valid text using Code39 symbology yields the correct result

        GenericBarcodeTestHelper.EncodeFontSuccessTest(/* input */'1234', Enum::"Barcode Symbology"::Code39, /* expected result */'(1234)');
    end;

    [Test]
    procedure TestCode39EncodingWithChecksum();
    var
        TempBarcodeEncodeSettings: Record "Barcode Encode Settings";
        GenericBarcodeTestHelper: Codeunit "Generic Barcode Test Helper";
    begin
        // [Scenario] Encoding a valid text with checksum enabled using Code39 symbology yields the correct result

        TempBarcodeEncodeSettings."Enable Checksum" := true;

        GenericBarcodeTestHelper.EncodeFontSuccessTest(/* input */'1234', Enum::"Barcode Symbology"::Code39, TempBarcodeEncodeSettings, /* expected result */'(1234A) ');
    end;

    [Test]
    procedure TestCode39EncodingWithExtCharSet();
    var
        TempBarcodeEncodeSettings: Record "Barcode Encode Settings";
        GenericBarcodeTestHelper: Codeunit "Generic Barcode Test Helper";
    begin
        // [Scenario] Encoding a valid text using Code39 symbology with "Allow Extended Charset" yields the correct result

        TempBarcodeEncodeSettings."Allow Extended Charset" := true;

        GenericBarcodeTestHelper.EncodeFontSuccessTest(/* input */'>abcd<', Enum::"Barcode Symbology"::Code39, TempBarcodeEncodeSettings, /* expected result */'(%I+A+B+C+D%G)');
    end;

    [Test]
    procedure TestCode39EncodingWithChecksumAndExtCharSet();
    var
        TempBarcodeEncodeSettings: Record "Barcode Encode Settings";
        GenericBarcodeTestHelper: Codeunit "Generic Barcode Test Helper";
    begin
        // [Scenario] Encoding a valid text with checksum enabled using Code39 symbology with "Allow Extended Charset" yields the correct result

        TempBarcodeEncodeSettings."Allow Extended Charset" := true;
        TempBarcodeEncodeSettings."Enable Checksum" := true;

        GenericBarcodeTestHelper.EncodeFontSuccessTest(/* input */'>abcd<', Enum::"Barcode Symbology"::Code39, TempBarcodeEncodeSettings, /* expected result */'(%I+A+B+C+D%GR) ');
    end;

    [Test]
    procedure TestCode39ValidationWithEmptyString();
    var
        GenericBarcodeTestHelper: Codeunit "Generic Barcode Test Helper";
    begin
        // [Scenario] Validating an empty text using Code39 symbology yeilds an error

        GenericBarcodeTestHelper.ValidateFontFailureTest(/* input */'', Enum::"Barcode Symbology"::Code39, /* expected error */'Input text  contains invalid characters for the chosen provider IDAutomation 1D Barcode Provider and encoding symbology Code-39');
    end;

    [Test]
    procedure TestCode39ValidationWithNormalString();
    var
        GenericBarcodeTestHelper: Codeunit "Generic Barcode Test Helper";
    begin
        // [Scenario] Validating a correctly formatted text using Code39 symbology doesn't yield an error

        GenericBarcodeTestHelper.ValidateFontSuccessTest(/* input */'1234', Enum::"Barcode Symbology"::Code39);
    end;

    [Test]
    procedure TestCode39ValidationWithNormalStringExtCharSet();
    var
        TempBarcodeEncodeSettings: Record "Barcode Encode Settings";
        GenericBarcodeTestHelper: Codeunit "Generic Barcode Test Helper";
    begin
        // [Scenario] Validating a correctly formatted text using Code39 symbology with "Allow Extended Charset" doesn't yield an error

        TempBarcodeEncodeSettings."Allow Extended Charset" := true;

        GenericBarcodeTestHelper.ValidateFontSuccessTest(/* input */'1234abcd', Enum::"Barcode Symbology"::Code39, TempBarcodeEncodeSettings);
    end;

    [Test]
    procedure TestCode39ValidationWithInvalidString();
    var
        GenericBarcodeTestHelper: Codeunit "Generic Barcode Test Helper";
    begin
        // [Scenario] Validating an invalid text using Code39 symbology yields an error

        GenericBarcodeTestHelper.ValidateFontFailureTest(/* input */'&&&&&&&', Enum::"Barcode Symbology"::Code39, /* expected error */'Input text &&&&&&& contains invalid characters for the chosen provider IDAutomation 1D Barcode Provider and encoding symbology Code-39');
    end;
}