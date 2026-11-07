// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;

/// <summary>
/// Identifies the type of an E-Document message (e.g. a PEPPOL Order Response) and dispatches
/// to the codeunit that builds its payload.
/// Extend this enum in a format-specific app with a value bound to your IEDocMessageBuilder
/// implementation to provide a new message format.
/// </summary>
enum 6436 "E-Document Message Type" implements IEDocMessageBuilder
{
    Extensible = true;
    DefaultImplementation = IEDocMessageBuilder = "E-Doc. Unspecified Impl.";

    value(0; Unknown)
    {
        Caption = 'Unknown';
    }
    value(1; "PEPPOL Order Response")
    {
        Caption = 'PEPPOL Order Response';
        Implementation = IEDocMessageBuilder = "E-Doc. PEPPOL Msg. Builder";
    }
}
