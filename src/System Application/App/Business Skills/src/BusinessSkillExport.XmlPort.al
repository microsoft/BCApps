// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

/// <summary>
/// Serializes prepared manual skill buffers as portable UTF-8 XML.
/// Uses document-local skill references and reads complete instruction text from the stored skill. The file carries no skill ID or owner.
/// </summary>
xmlport 4160 "Business Skill Export"
{
    Direction = Export;
    Format = Xml;
    UseDefaultNamespace = false;
    Encoding = UTF8;
    InherentEntitlements = X;
    InherentPermissions = X;

    schema
    {
        textelement(BusinessSkill)
        {
            textelement(Skills)
            {
                tableelement(Skill; "Business Skill")
                {
                    UseTemporary = true;
                    XmlName = 'Skill';
                    MinOccurs = Zero;
                    fieldelement(Reference; Skill.ID) { }
                    fieldelement(Title; Skill.Title) { }
                    fieldelement(SkillDescription; Skill.Description) { XmlName = 'Description'; }
                    fieldelement(SkillVersion; Skill.Version) { XmlName = 'Version'; }
                    textelement(SkillText)
                    {
                        TextType = BigText;
                        trigger OnBeforePassVariable()
                        var
                            PersistedSkill: Record "Business Skill";
                            SkillManagement: Codeunit "Business Skill Management";
                            TextHelper: Codeunit "Business Skill Text";
                        begin
                            Clear(SkillText);
                            PersistedSkill.Get(Skill.ID);
                            if not SkillManagement.IsManualSkill(PersistedSkill) then
                                Error(ManualSkillsOnlyErr);
                            SkillText.AddText(TextHelper.GetSkillText(PersistedSkill));
                        end;

                    }
                }
            }
        }
    }

    internal procedure SetBuffer(var TempSkill: Record "Business Skill" temporary)
    begin
        Skill.Copy(TempSkill, true);
    end;

    var
        ManualSkillsOnlyErr: Label 'Only manually owned skills can be exported.';
}
