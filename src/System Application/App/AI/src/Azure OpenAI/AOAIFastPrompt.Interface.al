// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

interface "AOAI Fast Prompt"
{
    Access = Public;

    /// <summary>
    /// Resolve fast prompt settings for an ECS configuration key.
    /// </summary>
    /// <param name="EcsConfigKey">The ECS key to resolve.</param>
    /// <param name="IsFastPrompt">True when the response resolved a blob-backed fast prompt.</param>
    /// <param name="Template">The resolved prompt template.</param>
    /// <param name="Model">The resolved model identifier.</param>
    /// <param name="ErrorCode">A machine-readable error code on failure.</param>
    /// <param name="ErrorText">A human-readable error message on failure.</param>
    /// <returns>True if the fast prompt was resolved successfully.</returns>
    procedure TryGetFastPrompt(EcsConfigKey: Text; var IsFastPrompt: Boolean; var Template: Text; var Model: Text; var ErrorCode: Text; var ErrorText: Text): Boolean;
}
