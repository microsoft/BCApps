// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// The result of a fast prompt lookup.
/// </summary>
codeunit 7789 "AOAI Fast Prompt Response"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        FastPrompt: Boolean;
        Template: SecretText;
        ErrorCode: Text;
        ErrorMessage: Text;

    /// <summary>
    /// Whether a blob-backed fast prompt was resolved.
    /// </summary>
    /// <returns>True if a fast prompt was resolved.</returns>
    procedure IsFastPrompt(): Boolean
    begin
        exit(FastPrompt);
    end;

    /// <summary>
    /// Get the resolved prompt template.
    /// </summary>
    /// <returns>The prompt template text.</returns>
    procedure GetTemplate(): SecretText
    begin
        exit(Template);
    end;

    /// <summary>
    /// Get the machine-readable error code on failure.
    /// </summary>
    /// <returns>The error code.</returns>
    procedure GetErrorCode(): Text
    begin
        exit(ErrorCode);
    end;

    /// <summary>
    /// Get the human-readable error message on failure.
    /// </summary>
    /// <returns>The error message.</returns>
    procedure GetErrorMessage(): Text
    begin
        exit(ErrorMessage);
    end;

    internal procedure Set(NewIsFastPrompt: Boolean; NewTemplate: SecretText; NewErrorCode: Text; NewErrorMessage: Text)
    begin
        FastPrompt := NewIsFastPrompt;
        Template := NewTemplate;
        ErrorCode := NewErrorCode;
        ErrorMessage := NewErrorMessage;
    end;
}
