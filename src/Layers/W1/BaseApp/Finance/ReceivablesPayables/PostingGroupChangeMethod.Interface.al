// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

/// <summary>
/// Interface for implementing posting group change methods with validation and data migration support.
/// Defines contract for custom posting group change logic in customer and vendor management.
/// </summary>
/// <remarks>
/// Implemented by posting group change method enums to provide extensible posting group modification.
/// Supports validation of posting group changes and automated data migration scenarios.
/// Enables custom business logic for posting group change approval and processing.
/// </remarks>
interface "Posting Group Change Method"
{
    /// <summary>
    /// The method fills the Price Asset parameter with "Asset No." and other data from the asset defined in the implementation codeunit. 
    /// </summary>
    /// <param name="PriceAsset">the record gets filled with data</param>
    procedure ChangePostingGroup(OldPostingGroup: Code[20]; NewPostingGroupCode: Code[20]; SourceRecordVar: Variant)
}
