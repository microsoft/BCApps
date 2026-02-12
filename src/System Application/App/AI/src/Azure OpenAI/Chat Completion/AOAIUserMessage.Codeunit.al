// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// Represents a user message with structured content parts for multimodal inputs.
/// Use AddTextPart and AddFilePart to build the message content, then pass this codeunit to AOAIChatMessages.AddUserMessage.
/// </summary>
codeunit 7783 "AOAI User Message"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AOAIUserMessageImpl: Codeunit "AOAI User Message Impl";

    /// <summary>
    /// Adds a text content part to the user message.
    /// </summary>
    /// <param name="TextContent">The text content to add.</param>
    procedure AddTextPart(TextContent: Text)
    begin
        AOAIUserMessageImpl.AddTextPart(TextContent);
    end;

    /// <summary>
    /// Adds a file content part to the user message.
    /// </summary>
    /// <param name="FileData">The file data to add (e.g. base64-encoded content).</param>
    procedure AddFilePart(FileData: Text)
    begin
        AOAIUserMessageImpl.AddFilePart(FileData);
    end;

    /// <summary>
    /// Gets the assembled content parts as a JsonArray.
    /// </summary>
    /// <returns>The content parts JsonArray.</returns>
    internal procedure GetContentParts(): JsonArray
    begin
        exit(AOAIUserMessageImpl.GetContentParts());
    end;
}
