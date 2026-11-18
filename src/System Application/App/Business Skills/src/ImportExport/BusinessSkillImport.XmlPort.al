// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

/// <summary>
/// Reads portable skill descriptions and instructions.
/// Delegates reference validation and creation to the port codeunit so each imported skill is a new, independent, active manual skill.
/// </summary>
xmlport 4161 "Business Skill Import"
{
    Direction = Import;
    Format = Xml;
    UseDefaultNamespace = false;
    PreserveWhiteSpace = true;
    DefaultFieldsValidation = false;
    Encoding = UTF8;
    InherentEntitlements = X;
    InherentPermissions = X;

    schema
    {
        textelement(BusinessSkill)
        {
            textelement(Skills)
            {
                tableelement(TempSkill; "Business Skill")
                {
                    UseTemporary = true;
                    AutoSave = false;
                    XmlName = 'Skill';
                    MinOccurs = Zero;
                    fieldelement(Reference; TempSkill.ID) { }
                    fieldelement(Title; TempSkill.Title) { }
                    fieldelement(SkillDescription; TempSkill.Description)
                    {
                        XmlName = 'Description';
                        MinOccurs = Zero;
                    }
                    fieldelement(SkillVersion; TempSkill.Version) { XmlName = 'Version'; MinOccurs = Zero; }
                    textelement(SkillText) { TextType = BigText; }
                    trigger OnBeforeInsertRecord()
                    begin
                        Port.ImportSkillElement(TempSkill, GetImportContent());
                        Clear(TempSkill.Description);
                        Clear(TempSkill.Version);
                        Clear(SkillText);
                    end;
                }
            }
        }
    }

    internal procedure SetPort(PortCodeunit: Codeunit "Business Skill Port")
    begin
        Port := PortCodeunit;
    end;

    [NonDebuggable]
    local procedure GetImportContent(): SecretText
    var
        Value: Text;
    begin
        SkillText.GetSubText(Value, 1, SkillText.Length());
        exit(Value);
    end;

    var
        Port: Codeunit "Business Skill Port";
}
