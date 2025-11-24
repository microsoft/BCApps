// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup.Setup;

using Microsoft.QualityManagement.Integration.Manufacturing;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Integration.Assembly;

tableextension 20400 "Qlty. Mgmt. Setup - Mfg" extends "Qlty. Management Setup"
{
    fields
    {
        field(10; "Production Trigger"; Enum "Qlty. Production Trigger")
        {
            Description = 'Optionally choose a production related trigger to try and create a test.';
            Caption = 'Production Trigger';
            ToolTip = 'Specifies a default production-related trigger value for Test Generation Rules to try and create a test.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
            begin
                if (Rec."Production Trigger" <> xRec."Production Trigger") and (xRec."Production Trigger" <> xRec."Production Trigger"::NoTrigger) then begin
                    QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::Production);
                    QltyInTestGenerationRule.SetRange("Production Trigger", xRec."Production Trigger");
                    if (not QltyInTestGenerationRule.IsEmpty()) and GuiAllowed() then
                        if Confirm(StrSubstNo(ConfirmExistingRulesMfgQst, QltyInTestGenerationRule.Count(), xRec."Production Trigger", Rec."Production Trigger")) then
                            QltyInTestGenerationRule.ModifyAll("Production Trigger", Rec."Production Trigger", false);
                end;
            end;
        }
        field(11; "Production Update Control"; Enum "Qlty. Update Source Behavior")
        {
            Description = 'Set to "Update when Source Changes" to alter source information as the source record changes (for example, such as when a Production Order changes status to Finished). Set to "Do Not Update" to prevent updating the original source that created the test.';
            InitValue = "Do not update";
            Caption = 'Production Update Control';
            ToolTip = 'Specifies whether to update when the source changes. Set to "Update when Source Changes" to alter source information as the source record changes (for example, such as when a Production Order changes status to Finished). Set to "Do Not Update" to prevent updating the original source that created the test.';
            DataClassification = CustomerContent;
        }
        field(92; "Auto Output Configuration"; Enum "Qlty. Auto. Production Trigger")
        {
            Caption = 'Auto Output Configuration';
            ToolTip = 'Specifies granular options for when a test should be created automatically during the production process.';
            DataClassification = CustomerContent;
        }
        field(101; "Assembly Trigger"; Enum "Qlty. Assembly Trigger")
        {
            Caption = 'Create Test On Assembly Trigger';
            Description = 'Provides automation to create a test when an assembly order creates output.';
            ToolTip = 'Specifies a default assembly-related trigger value for Test Generation Rules to try and create a test.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
            begin
                if (Rec."Assembly Trigger" <> xRec."Assembly Trigger") and (xRec."Assembly Trigger" <> xRec."Assembly Trigger"::NoTrigger) then begin
                    QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::Assembly);
                    QltyInTestGenerationRule.SetRange("Assembly Trigger", xRec."Assembly Trigger");
                    if (not QltyInTestGenerationRule.IsEmpty()) and GuiAllowed() then
                        if Confirm(StrSubstNo(ConfirmExistingRulesMfgQst, QltyInTestGenerationRule.Count(), xRec."Assembly Trigger", Rec."Assembly Trigger")) then
                            QltyInTestGenerationRule.ModifyAll("Assembly Trigger", Rec."Assembly Trigger", false);
                end;
            end;
        }

    }

    var
        ConfirmExistingRulesMfgQst: Label 'You have %1 existing generation rules that used the "%2" setting. Do you want to change those to be "%3"?', Comment = '%1=the count, %2=the old setting, %3=the new setting.';
}
