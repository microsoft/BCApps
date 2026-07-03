// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

enum 5771 "Warehouse Request Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Inbound") { Caption = 'Inbound'; }
    value(1; "Outbound") { Caption = 'Outbound'; }
}
