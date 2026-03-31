// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Interfaces;

interface IPrepareDraftGuard
{
    /// <summary>
    /// Returns true to skip AL-based prepare draft logic.
    /// When true, the caller (e.g., an agent) is responsible for all draft preparation
    /// including vendor resolution, line matching, UOM resolution, and deferral assignment.
    /// </summary>
    procedure SkipPrepareDraft(): Boolean;
}
