// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using System.Utilities;

/// <summary>
/// Inbound IO for an E-Document Message — parses wire bytes into the message row's fields
/// and resolves the parent E-Document reference. Pure read; does not mutate parent state.
/// State transitions go through "IEDocumentMessageType.ApplyMessage".
/// </summary>
interface IEDocumentMessageReader
{
    /// <summary>
    /// Reads the payload, populates "Status Code" / "Related E-Document No." / etc. on the message row.
    /// Returns false if parse failed or parent couldn't be resolved.
    /// </summary>
    procedure ParseMessage(var Msg: Record "E-Document Message"; TempBlob: Codeunit "Temp Blob"): Boolean;
}
