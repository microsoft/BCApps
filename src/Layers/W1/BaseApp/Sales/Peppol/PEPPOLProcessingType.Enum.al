// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Peppol;

enum 1610 "PEPPOL Processing Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Sale") { Caption = 'Sale'; }
    value(1; "Service") { Caption = 'Service'; }
}
