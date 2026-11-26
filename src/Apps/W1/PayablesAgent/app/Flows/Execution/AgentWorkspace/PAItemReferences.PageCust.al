// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Inventory.Item.Catalog;

// Read-only for the agent: an editable list lets the agent client open a second, edit-mode instance it cannot close.
pagecustomization "PA Item References" customizes "Item References"
{
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;
}
