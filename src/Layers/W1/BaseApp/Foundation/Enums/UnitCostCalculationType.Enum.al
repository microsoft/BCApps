// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Enums;

enum 5409 "Unit Cost Calculation Type"
{
    AssignmentCompatibility = true;
    Extensible = true;

    value(0; "Time") { Caption = 'Time'; }
    value(1; "Units") { Caption = 'Units'; }
}
