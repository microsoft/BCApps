// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Interfaces;

using Microsoft.eServices.EDocument;

/// <summary>
/// Optional setup policy implemented through the E-Document Format enum.
/// Existing formats inherit the legacy participant prerequisite. New formats can
/// provide their own side-effect-free setup predicate without changing posting.
/// Outgoing supported types and the service export evaluator remain independent gates.
/// This policy is used for initiation, not for re-exporting existing documents.
/// Formats still validate their payload in E-Document.Check/Create and can use
/// E-Document Processing's self-billing source, reference and party helpers.
/// </summary>
/// <remarks>
/// Implement E-Document on a new format enum value, optionally bind this policy,
/// and explicitly register outgoing self-billed capabilities for its service.
/// RegisterDefaultSelfBillingTypes adds missing capabilities without overwriting
/// restrictions; it must not be used to mass-enable existing service setup.
/// Use CheckSelfBillingSource in directly callable serializers. Native posted
/// identity and the supplied mapped/temporary payload views are distinct.
/// Country validation, amounts, rendering and container selection remain format
/// responsibilities. This contract does not add batch support.
/// Core Tests' Self-Billing Format Mock demonstrates a non-UBL implementation.
/// </remarks>
interface ISelfBillingFormatPolicy
{
    /// <summary>
    /// Returns whether this service has the setup needed to initiate self-billing.
    /// Cannot override native source eligibility. Must not mutate source or setup.
    /// </summary>
    procedure HasRequiredSetup(EDocumentService: Record "E-Document Service"; SourceDocumentHeader: RecordRef; DocumentType: Enum "E-Document Type"): Boolean;
}
