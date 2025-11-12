// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

#pragma warning disable AL0659
enum 1253 "Pmt. Appl. Related Party Name Matching"
#pragma warning restore AL0659
{
    Extensible = true;

    value(0; "String Nearness")
    {
        Caption = 'String Nearness';
    }

    value(1; "Exact Match with Permutations")
    {
        Caption = 'Exact match with Permutations';
    }

    value(2; Disabled)
    {
        Caption = 'Disabled';
    }
}
