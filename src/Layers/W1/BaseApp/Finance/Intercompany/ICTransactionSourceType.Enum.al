// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany;

enum 430 "IC Transaction Source Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Journal") { Caption = 'Journal'; }
    value(1; "Sales Document") { Caption = 'Sales Document'; }
    value(2; "Purchase Document") { Caption = 'Purchase Document'; }
}
