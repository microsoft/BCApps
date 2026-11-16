// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

using System;

/// <summary>
/// Shares UTF-8 encoding, line-based stream reads, instruction-length validation, and HTML content encoding.
/// Reads and writes the instructions of a business skill, which the platform table cannot do itself.
/// These helpers never persist records or grant data permissions.
/// </summary>
codeunit 4165 "Business Skill Text Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>Returns the instructions of the skill, loaded from the database.</summary>
    procedure GetSkillText(var Skill: Record "Business Skill"): Text
    begin
        exit(GetSkillText(Skill, true));
    end;

    /// <summary>Returns the instructions of the skill. Without loading, the value already on the record is returned.</summary>
    procedure GetSkillText(var Skill: Record "Business Skill"; LoadFromDatabase: Boolean): Text
    var
        Input: InStream;
    begin
        if LoadFromDatabase then
            Skill.CalcFields("Skill Text");
        if not Skill."Skill Text".HasValue() then
            exit('');
        Skill."Skill Text".CreateInStream(Input, GetEncoding());
        exit(ReadText(Input));
    end;

    /// <summary>
    /// Sets the instructions of the skill without saving the record. A text change advances the version of a manual skill
    /// and requires a new version for a skill owned by an app.
    /// </summary>
    procedure SetSkillText(var Skill: Record "Business Skill"; Value: Text)
    var
        SkillManagement: Codeunit "Business Skill Management";
        Output: OutStream;
    begin
        ValidateLength(Value);
        SkillManagement.ValidateSkillTextChange(Skill, Value);
        Clear(Skill."Skill Text");
        Skill."Skill Text".CreateOutStream(Output, GetEncoding());
        Output.WriteText(Value);
    end;

    /// <summary>Returns the encoding used by skill, history and portable text streams.</summary>
    procedure GetEncoding(): TextEncoding
    begin
        exit(TextEncoding::UTF8);
    end;

    /// <summary>Reads the stream line by line, inserting separators only between returned lines.</summary>
    procedure ReadText(Input: InStream): Text
    var
        TextBuilder: TextBuilder;
        TextLine: Text;
        FirstLine: Boolean;
    begin
        FirstLine := true;
        while not Input.EOS() do begin
            Input.ReadText(TextLine);
            if not FirstLine then
                TextBuilder.AppendLine('');
            TextBuilder.Append(TextLine);
            FirstLine := false;
        end;
        exit(TextBuilder.ToText());
    end;

    procedure GetMaxLength(): Integer
    begin
        exit(100000);
    end;

    /// <summary>Checks the persistent skill text limit independently of the UI.</summary>
    procedure ValidateLength(Value: Text)
    begin
        if StrLen(Value) > GetMaxLength() then
            Error(TextTooLongErr, Format(GetMaxLength(), 0, 9));
    end;

    /// <summary>Encodes text for HTML attributes/content, not for JavaScript execution.</summary>
    procedure EncodeContent(Value: Text): Text
    var
        HttpUtility: DotNet HttpUtility;
    begin
        exit(HttpUtility.HtmlEncode(Value));
    end;

    var
        TextTooLongErr: Label 'Skill text must not exceed %1 characters.', Comment = '%1 = maximum text length';
}