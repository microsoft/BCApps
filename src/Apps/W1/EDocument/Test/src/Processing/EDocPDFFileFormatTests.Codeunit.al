// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument.Format;
using Microsoft.eServices.EDocument.Processing.Import;
using System.TestLibraries.Config;

codeunit 135648 "EDoc PDF File Format Tests"
{
    Subtype = Test;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";

    [Test]
    procedure PreferredImpl_ControlAllocation_ReturnsADI()
    var
        EDocPDFFileFormat: Codeunit "E-Doc. PDF File Format";
        FeatureConfigTestLib: Codeunit "Feature Config Test Lib.";
    begin
        // [SCENARIO] With control allocation, PreferredStructureDataImplementation returns ADI
        LibraryLowerPermission.SetOutsideO365Scope();

        FeatureConfigTestLib.UseControlAllocation();

        Assert.AreEqual(
            "Structure Received E-Doc."::ADI,
            EDocPDFFileFormat.PreferredStructureDataImplementation(),
            'Control allocation should return ADI');
    end;

    [Test]
    procedure PreferredImpl_TreatmentAllocation_ReturnsMLLM()
    var
        EDocPDFFileFormat: Codeunit "E-Doc. PDF File Format";
        FeatureConfigTestLib: Codeunit "Feature Config Test Lib.";
    begin
        // [SCENARIO] With treatment allocation, PreferredStructureDataImplementation returns MLLM
        LibraryLowerPermission.SetOutsideO365Scope();

        FeatureConfigTestLib.UseTreatmentAllocation();

        Assert.AreEqual(
            "Structure Received E-Doc."::MLLM,
            EDocPDFFileFormat.PreferredStructureDataImplementation(),
            'Treatment allocation should return MLLM');
    end;

    [Test]
    procedure PreferredImpl_EventOverride_TakesPrecedence()
    var
        EDocPDFFileFormat: Codeunit "E-Doc. PDF File Format";
        FeatureConfigTestLib: Codeunit "Feature Config Test Lib.";
        EDocPDFFileFormatTests: Codeunit "EDoc PDF File Format Tests";
    begin
        // [SCENARIO] An event subscriber can override the result regardless of experiment allocation
        LibraryLowerPermission.SetOutsideO365Scope();

        FeatureConfigTestLib.UseControlAllocation(); // Would normally return ADI
        BindSubscription(EDocPDFFileFormatTests);

        Assert.AreEqual(
            "Structure Received E-Doc."::MLLM,
            EDocPDFFileFormat.PreferredStructureDataImplementation(),
            'Event override should take precedence over experiment allocation');

        UnbindSubscription(EDocPDFFileFormatTests);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. PDF File Format", OnAfterSetIStructureReceivedEDocumentForPdf, '', false, false)]
    local procedure OverrideToMLLM(var Result: Enum "Structure Received E-Doc.")
    begin
        Result := "Structure Received E-Doc."::MLLM;
    end;
}
