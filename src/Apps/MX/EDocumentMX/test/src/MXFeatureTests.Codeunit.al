// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura.Tests;

using Microsoft.EServices.EDocument.Interfactura;
using Microsoft.eServices.EDocument;
using System.Utilities;

codeunit 148760 "MX Feature Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        MXFeatureTestHelper: Codeunit "MX Feature Test Helper";

    [Test]
    procedure CFDIFormatCannotBeSelectedWhenFeatureIsDisabled()
    var
        EDocumentService: Record "E-Document Service";
    begin
        // [SCENARIO] The CFDI format cannot be selected when the feature is disabled
        Initialize();
        CreateService(EDocumentService);

        // [GIVEN] The feature is disabled
        MXFeatureTestHelper.DisableFeature();

        // [WHEN] The CFDI format is selected
        asserterror EDocumentService.Validate("Document Format", EDocumentService."Document Format"::CFDI);
        MXFeatureTestHelper.EnableFeature();

        // [THEN] The preview feature error is raised
        Assert.ExpectedError('E-Document for Mexico is in preview. It can only be used in sandbox environments where the feature is enabled in Feature Management.');
    end;

    [Test]
    [HandlerFunctions('FeatureDisabledModalPageHandler')]
    procedure InterfacturaIntegrationCannotBeSelectedWhenFeatureIsDisabled()
    var
        EDocumentService: Record "E-Document Service";
    begin
        // [SCENARIO] The Interfactura integration cannot be selected when the feature is disabled
        Initialize();
        CreateService(EDocumentService);

        // [GIVEN] The feature is disabled
        MXFeatureTestHelper.DisableFeature();

        // [WHEN] The Interfactura integration is selected
        asserterror EDocumentService.Validate("Service Integration V2", EDocumentService."Service Integration V2"::"Interfactura Service");
        MXFeatureTestHelper.EnableFeature();

        // [THEN] The preview feature error is raised
        Assert.ExpectedError('E-Document for Mexico is in preview. It can only be used in sandbox environments where the feature is enabled in Feature Management.');
    end;

    [Test]
    procedure CFDIExportFailsWhenFeatureIsDisabled()
    var
        EDocumentService: Record "E-Document Service";
        EDocument: Record "E-Document";
        EDocCFDIMX: Codeunit "EDoc CFDI MX";
        TempBlob: Codeunit "Temp Blob";
        SourceHeader: RecordRef;
        SourceLines: RecordRef;
    begin
        // [SCENARIO] No CFDI is created when the feature is disabled
        Initialize();

        // [GIVEN] The feature is disabled
        MXFeatureTestHelper.DisableFeature();

        // [WHEN] A CFDI is created
        asserterror EDocCFDIMX.Create(EDocumentService, EDocument, SourceHeader, SourceLines, TempBlob);
        MXFeatureTestHelper.EnableFeature();

        // [THEN] The preview feature error is raised
        Assert.ExpectedError('E-Document for Mexico is in preview. It can only be used in sandbox environments where the feature is enabled in Feature Management.');
    end;

    [Test]
    procedure CFDIFormatCanBeSelectedWhenFeatureIsEnabled()
    var
        EDocumentService: Record "E-Document Service";
    begin
        // [SCENARIO] The CFDI format can be selected when the feature is enabled
        Initialize();
        CreateService(EDocumentService);

        // [WHEN] The CFDI format is selected
        EDocumentService.Validate("Document Format", EDocumentService."Document Format"::CFDI);

        // [THEN] The format is set correctly
        Assert.AreEqual(EDocumentService."Document Format"::CFDI, EDocumentService."Document Format", 'The document format is incorrect.');
    end;

    local procedure Initialize()
    begin
        MXFeatureTestHelper.EnableFeature();
    end;

    local procedure CreateService(var EDocumentService: Record "E-Document Service")
    begin
        EDocumentService.Init();
        EDocumentService.Code := LibraryUtility.GenerateGUID();
        EDocumentService.Insert();
    end;

    [ModalPageHandler]
    procedure FeatureDisabledModalPageHandler(var FeatureDisabledPage: TestPage 1820)
    begin
        FeatureDisabledPage.Accept.Invoke();
    end;
}
