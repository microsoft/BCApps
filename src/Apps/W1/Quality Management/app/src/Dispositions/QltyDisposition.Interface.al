// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions;

using Microsoft.QualityManagement.Document;

/// <summary>
/// Defines the contract for disposition actions that can be performed from quality inspection.
/// Implementations of this interface handle different disposition strategies such as moving inventory,
/// changing item tracking, creating transfers, or adjusting quantities.
///
/// This interface allows custom implementation of disposition actions.
/// </summary>
interface "Qlty. Disposition"
{
    /// <summary>
    /// Executes the disposition action for a quality inspection.
    /// </summary>
    /// <param name="QltyInspectionHeader">The quality inspection header to perform disposition on</param>
    /// <param name="TempInstructionQltyDispositionBuffer">Temporary buffer containing disposition instructions and parameters</param>
    /// <returns>True if disposition was successful; False otherwise</returns>
    procedure PerformDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary): Boolean
}
