// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Format;

using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;
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
        Result: Enum "Structure Received E-Doc.";
    begin
        Result := "Structure Received E-Doc."::MLLM;
#if not CLEAN29
#pragma warning disable AL0432
        OnAfterSetIStructureReceivedEDocumentForPdf(Result);
#pragma warning restore AL0432
#endif
        exit(Result);
    end;

    /// <summary>
    /// Allows subscribers to override which structure data implementation is used for PDF processing.
    /// This is specifically used by the Payables Agent to force MLLM processing on, regardless of the experiment setting.
    /// </summary>
#if not CLEAN29
    [IntegrationEvent(false, false)]
    [Obsolete('The MLLM Payables Agent feature is fully rolled out; the override event used to roll it out is no longer needed.', '29.0')]
    local procedure OnAfterSetIStructureReceivedEDocumentForPdf(var Result: Enum "Structure Received E-Doc.")
    begin
    end;
#endif

    procedure FileExtension(): Text
    begin
        exit('pdf');
    end;
}
