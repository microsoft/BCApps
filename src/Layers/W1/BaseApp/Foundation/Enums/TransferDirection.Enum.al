// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Enums;

enum 5400 "Transfer Direction"
{
    Extensible = false;
    AssignmentCompatibility = true;

    value(0; "Outbound") { Caption = 'Outbound'; }
    value(1; "Inbound") { Caption = 'Inbound'; }
}
