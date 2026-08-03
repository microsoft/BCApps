// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SpendRequest;

/// <summary>
/// Generic, extensible document type for spend requests.
/// Empty by default; consuming layers extend it with concrete types (for example, Travel).
/// </summary>
enum 6840 "Spend Request Type"
{
    Extensible = true;
    Caption = 'Spend Request Type';

    value(0; Expense)
    {
        Caption = 'Expense';
    }
}
