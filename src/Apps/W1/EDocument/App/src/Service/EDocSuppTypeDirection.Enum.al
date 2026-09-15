// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

/// <summary>
/// Direction in which a document type is permitted on an E-Document Service, used by "E-Doc. Service Supported Type" (table 6122).
/// Both is value 0 so that new/upgraded rows default to it without narrowing existing behavior.
/// </summary>
enum 6115 "E-Doc. Supp. Type Direction"
{
    Caption = 'E-Doc. Service Supported Type Direction';
    Extensible = false;

    value(0; Both)
    {
        Caption = 'Both';
    }
    value(1; Outgoing)
    {
        Caption = 'Outgoing';
    }
    value(2; Incoming)
    {
        Caption = 'Incoming';
    }
}