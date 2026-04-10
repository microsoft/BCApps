// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Card page for managing dimension value combinations and their restrictions.
/// Provides interface for configuring which dimension value combinations are allowed or blocked in business operations.
/// </summary>
/// <remarks>
/// Used to set up dimension combination rules that enforce business logic constraints during posting operations.
/// Integrates with dimension validation processes to prevent invalid dimension combinations from being used.
/// </remarks>
page 539 "Dimension Value Combinations"
{
    Caption = 'Dimension Value Combinations';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Dimension Value";

    layout
    {
    }

    actions
    {
    }
}

