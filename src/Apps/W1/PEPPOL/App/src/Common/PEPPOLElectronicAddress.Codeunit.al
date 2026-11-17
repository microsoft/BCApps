// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

/// <summary>
/// Checks Peppol electronic addresses (cbc:EndpointID) against the Peppol Electronic Address Scheme (EAS) code list.
/// </summary>
codeunit 37224 "PEPPOL Electronic Address"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Returns whether SchemeId is a code of the Peppol Electronic Address Scheme (EAS) code list, as cbc:EndpointID/@schemeID requires.
    /// The code must match a value name of the "PEPPOL Electronic Addr. Scheme" enum, including values added by enum extensions.
    /// </summary>
    /// <param name="SchemeId">The scheme identifier, e.g. 0088 for a GLN.</param>
    /// <returns>True when the scheme is in the EAS code list; otherwise false.</returns>
    procedure IsValidScheme(SchemeId: Text): Boolean
    begin
        if SchemeId = '' then
            exit(false);
        exit(Enum::"PEPPOL Electronic Addr. Scheme".Names().Contains(SchemeId));
    end;
}
