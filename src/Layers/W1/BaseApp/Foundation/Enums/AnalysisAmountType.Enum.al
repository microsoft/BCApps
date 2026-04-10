// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Enums;

enum 363 "Analysis Amount Type"
{
    AssignmentCompatibility = true;
    Extensible = true;

    value(0; "Net Change") { Caption = 'Net Change'; }
    value(1; "Balance at Date") { Caption = 'Balance at Date'; }
}
