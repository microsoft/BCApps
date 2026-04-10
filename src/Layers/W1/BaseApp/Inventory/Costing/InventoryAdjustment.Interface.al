// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;

interface "Inventory Adjustment"
{
    /// <summary>
    /// The method set filters for items for inventory cost adjustments codeunit. 
    /// </summary>
    /// <param name="NewItem">the record gets filtered</param>
    procedure SetFilterItem(var NewItem: Record Item)

    /// <summary>
    /// The method set skip job cost update parameter for inventory cost adjustment codeunit. 
    /// </summary>
    /// <param name="SkipUpdateJobItemCost">define if Job Item Cost update should be skipped</param>
    procedure SetJobUpdateProperties(SkipUpdateJobItemCost: Boolean)

    /// <summary>
    /// The method set properties for inventory cost adjustment codeunit. 
    /// </summary>
    /// <param name="NewIsOnlineAdjmt">set Online Adjmt paramater for inventory cost adjustment codeunit</param>
    /// <param name="NewIsOnlineAdjmt">set Post to G/L paramater for inventory cost adjustment codeunit</param>
    procedure SetProperties(NewIsOnlineAdjmt: Boolean; NewPostToGL: Boolean)

    /// <summary>
    /// The method run inventory cost adjustment codeunit. 
    /// </summary>
    procedure MakeMultiLevelAdjmt()
}
