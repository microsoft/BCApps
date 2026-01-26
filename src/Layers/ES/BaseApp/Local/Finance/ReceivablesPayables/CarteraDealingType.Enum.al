// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

enum 7000026 "Cartera Dealing Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Collection") { Caption = 'Collection'; }
    value(1; "Discount") { Caption = 'Discount'; }
}
