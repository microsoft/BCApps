// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.Response;

/// <summary>
/// Human-readable response type carried by an E-Document message (e.g. a PEPPOL Order Response).
/// UNCL4343 OrderResponseCode: AB = Acknowledged, AC = Accepted, RE = Rejected.
/// Extend this enum in a format-specific app to declare additional response types.
/// </summary>
enum 37208 "E-Doc. Response Type"
{
    Extensible = true;

    value(37223; Acknowledged)
    {
        Caption = 'Acknowledged';
    }
    value(37224; Accepted)
    {
        Caption = 'Accepted';
    }
    value(37225; Rejected)
    {
        Caption = 'Rejected';
    }
}
