// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Ledger;

enum 5631 "FA Ledger Posting Category"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Disposal") { Caption = 'Disposal'; }
    value(2; "Bal. Disposal") { Caption = 'Bal. Disposal'; }
}