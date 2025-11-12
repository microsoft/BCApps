// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

enum 748 "Analysis Show Amount Field"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Amount") { Caption = 'Amount'; }
    value(1; "Debit Amount") { Caption = 'Debit Amount'; }
    value(2; "Credit Amount") { Caption = 'Credit Amount'; }
}
