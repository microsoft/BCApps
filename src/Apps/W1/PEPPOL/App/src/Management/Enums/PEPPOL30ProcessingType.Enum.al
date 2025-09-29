// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

/// <summary>
/// Enum representing different PEPPOL30 processing types for electronic document exports.
/// </summary>
enum 37201 "PEPPOL30 Processing Type" implements "PEPPOL30 Export Management"
{
    Extensible = true;

    value(0; "Sale")
    {
        Caption = 'Sale';
        Implementation = "PEPPOL30 Export Management" = "Sales Export PEPPOL30 Mgmt.";
    }
    value(1; "Service")
    {
        Caption = 'Service';
        Implementation = "PEPPOL30 Export Management" = "Services Export PEPPOL30 Mgmt.";
    }
}
