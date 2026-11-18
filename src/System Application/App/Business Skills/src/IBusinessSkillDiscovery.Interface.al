// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

/// <summary>
/// Internal contract for consumers of the Business Skill knowledge layer. Lets callers look up the
/// skills that apply to a situation and retrieve skill detail without taking a hard
/// dependency on the internal management codeunit.
/// </summary>
interface IBusinessSkillDiscovery
{
    Access = Internal;

    /// <summary>
    /// Returns a serialized JSON array of active skills matching the query.
    /// Matching uses literal, case-insensitive text in skill titles and descriptions, not instruction text.
    /// </summary>
    /// <param name="Query">Literal text to match; blank includes all active skills.</param>
    /// <returns>A serialized JSON array containing matching canonical skill details.</returns>
    procedure GetRelevantSkills(Query: Text): SecretText;

    /// <summary>
    /// Returns a single active skill by id as protected serialized JSON.
    /// </summary>
    /// <param name="SkillId">Skill id.</param>
    procedure GetSkill(SkillId: BigInteger): SecretText;
}