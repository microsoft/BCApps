// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Enums;

enum 90 "Inventory Order Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { }
    value(1; "Production") { Caption = 'Production'; }
    value(2; "Transfer") { Caption = 'Transfer'; }
    value(3; "Service") { Caption = 'Service'; }
    value(4; "Assembly") { Caption = 'Assembly'; }
}
