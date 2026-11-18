// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

/// <summary>Provides skill text and portable text-stream access without persisting records or granting data permissions.</summary>
codeunit 4164 "Business Skill Text"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>Loads and returns the stored text of the skill.</summary>
    procedure GetSkillText(var Skill: Record "Business Skill"): SecretText
    begin
        exit(Impl.GetSkillText(Skill));
    end;

    /// <summary>Returns skill text, optionally loading it from the database first.</summary>
    procedure GetSkillText(var Skill: Record "Business Skill"; LoadFromDatabase: Boolean): SecretText
    begin
        exit(Impl.GetSkillText(Skill, LoadFromDatabase));
    end;

    /// <summary>Returns the encoding used by skill, history and portable text streams.</summary>
    procedure GetEncoding(): TextEncoding
    begin
        exit(Impl.GetEncoding());
    end;

    /// <summary>Reads a text stream line by line, inserting separators only between returned lines.</summary>
    procedure ReadText(Input: InStream): SecretText
    begin
        exit(Impl.ReadText(Input));
    end;

    /// <summary>Sets text and applies version rules without saving the record.</summary>
    internal procedure SetSkillText(var Skill: Record "Business Skill"; Value: SecretText)
    begin
        Impl.SetSkillText(Skill, Value);
    end;

    /// <summary>Returns the maximum supported skill text length.</summary>
    procedure GetMaxLength(): Integer
    begin
        exit(Impl.GetMaxLength());
    end;

    /// <summary>Validates the persistent skill text limit.</summary>
    internal procedure ValidateLength(Value: SecretText)
    begin
        Impl.ValidateLength(Value);
    end;

    /// <summary>Encodes text for HTML attributes and content.</summary>
    internal procedure EncodeContent(Value: SecretText): SecretText
    begin
        exit(Impl.EncodeContent(Value));
    end;

    /// <summary>Writes protected content to a stream without exposing a plaintext return value.</summary>
    internal procedure WriteText(Output: OutStream; Value: SecretText)
    begin
        Impl.WriteText(Output, Value);
    end;

    /// <summary>Compares content inside a non-debuggable boundary.</summary>
    internal procedure ContentEquals(Value: SecretText; Other: SecretText): Boolean
    begin
        exit(Impl.ContentEquals(Value, Other));
    end;

    /// <summary>Returns whether the content contains only whitespace.</summary>
    internal procedure IsBlank(Value: SecretText): Boolean
    begin
        exit(Impl.IsBlank(Value));
    end;

    var
        Impl: Codeunit "Business Skill Text Impl.";
}
