// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

enum 5605 "FA Journal Line Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(2; "Invoice") { Caption = 'Invoice'; }
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
}
