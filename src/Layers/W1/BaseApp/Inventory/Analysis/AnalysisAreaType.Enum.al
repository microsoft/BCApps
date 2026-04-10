// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

enum 7130 "Analysis Area Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Sales") { Caption = 'Sales'; }
    value(1; "Purchase") { Caption = 'Purchase'; }
    value(2; "Inventory") { Caption = 'Inventory'; }
}
