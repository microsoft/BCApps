// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// List page for viewing and selecting AI features (query schemas).
/// </summary>
page 149075 "AIT Query Schemas"
{
    Caption = 'AI Test Features';
    PageType = List;
    SourceTable = "AIT Query Schema";
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "AIT Query Schema Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Features)
            {
                field("Feature Code"; Rec."Feature Code")
                {
                    ToolTip = 'Specifies the unique identifier for the AI feature.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description of the AI feature.';
                }
                field("Default Codeunit ID"; Rec."Default Codeunit ID")
                {
                    ToolTip = 'Specifies the default test codeunit for this feature.';
                }
                field("Default Codeunit Name"; Rec."Default Codeunit Name")
                {
                    ToolTip = 'Specifies the name of the default test codeunit.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NewTestWizard)
            {
                Caption = 'Create Test';
                ToolTip = 'Opens the wizard to create a new test for this feature.';
                Image = NewDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction()
                var
                    AITDatasetWizard: Page "AIT Dataset Wizard";
                begin
                    AITDatasetWizard.SetFeature(Rec."Feature Code");
                    AITDatasetWizard.RunModal();
                end;
            }
        }
    }
}
