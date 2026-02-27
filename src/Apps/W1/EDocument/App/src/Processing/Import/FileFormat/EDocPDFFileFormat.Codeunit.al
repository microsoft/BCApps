// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Format;

using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using System.Config;
using System.Utilities;

codeunit 6191 "E-Doc. PDF File Format" implements IEDocFileFormat
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure PreviewContent(FileName: Text; TempBlob: Codeunit "Temp Blob")
    begin
        File.ViewFromStream(TempBlob.CreateInStream(), FileName, true)
    end;

    procedure PreferredStructureDataImplementation(): Enum "Structure Received E-Doc."
    var
        FeatureConfiguration: Codeunit "Feature Configuration";
        Result: Enum "Structure Received E-Doc.";
    begin
        Result := FeatureConfiguration.GetConfiguration(MLLMExperimentTok) = 'control' ? "Structure Received E-Doc."::ADI : "Structure Received E-Doc."::MLLM;
        OnAfterSetIStructureReceivedEDocumentForPdf(Result);
    end;

    /// <summary>
    /// Allows subscribers to override which structure data implementation is used for PDF processing.
    /// This is specifically used by the Payables Agent to force MLLM processing on, regardless of the experiment setting.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetIStructureReceivedEDocumentForPdf(var Result: Enum "Structure Received E-Doc.")
    begin
    end;

    procedure FileExtension(): Text
    begin
        exit('pdf');
    end;

    var
        MLLMExperimentTok: Label 'EDocMLLMExtraction', Locked = true;
}
