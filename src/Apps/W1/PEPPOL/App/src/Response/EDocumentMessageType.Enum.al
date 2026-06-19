// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.Response;

/// <summary>
/// Identifies the type of an E-Document message (e.g. a PEPPOL Order Response).
/// Extend this enum in a format-specific app to declare new message types.
/// </summary>
enum 37207 "E-Document Message Type"
{
    Extensible = true;

    value(37210; "PEPPOL Order Response")
    {
        Caption = 'PEPPOL Order Response';
    }
}
