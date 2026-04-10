// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Ledger;

#pragma warning disable AL0659
enum 5908 "Service Ledger Entry Entry Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Usage") { Caption = 'Usage'; }
    value(1; "Sale") { Caption = 'Sale'; }
    value(2; "Consume") { Caption = 'Consume'; }
    value(3; "Contract") { Caption = 'Contract'; }
}
