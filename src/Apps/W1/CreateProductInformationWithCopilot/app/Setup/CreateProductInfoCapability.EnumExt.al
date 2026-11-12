// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Substitution;

using System.AI;

enumextension 7330 "Create Product Info Capability" extends "Copilot Capability"
{
    // Kept so that install and upgrade code can unregister the discontinued capability.
    value(7330; "Create Product Information")
    {
        Caption = 'Create product information';
    }
}