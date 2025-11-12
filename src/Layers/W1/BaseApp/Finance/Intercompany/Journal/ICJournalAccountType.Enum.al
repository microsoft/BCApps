// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Journal;

enum 84 "IC Journal Account Type"
{
    Extensible = true;
    AssignmentCompatibility = true;
    value(0; "G/L Account") { Caption = 'G/L Account'; }
    value(1; "Bank Account") { Caption = 'Bank Account'; }
}
