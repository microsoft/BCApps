// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149046 "AIT Test Suite Language Lookup"
{
    Caption = 'Languages';
    PageType = List;
    SourceTable = "AIT Test Suite Language";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Language ID"; Rec."Language ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Windows Language ID.';
                    Visible = false;
                }
                field("Language Name"; Language)
                {
                    ApplicationArea = All;
                    Caption = 'Language';
                    ToolTip = 'Specifies the language name.';
                }
                field("Language Tag"; Rec."Language Tag")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the language tag.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        AITTestSuiteLanguage: Codeunit "AIT Test Suite Language";
    begin
        Language := AITTestSuiteLanguage.GetLanguageDisplayName(Rec."Language ID");
    end;

    procedure SetRecords(var TempAITTestSuiteLanguage: Record "AIT Test Suite Language" temporary)
    begin
        if TempAITTestSuiteLanguage.FindSet() then
            repeat
                Rec.TransferFields(TempAITTestSuiteLanguage);
                Rec.Insert();
            until TempAITTestSuiteLanguage.Next() = 0;
    end;

    var
        Language: Text;
}
