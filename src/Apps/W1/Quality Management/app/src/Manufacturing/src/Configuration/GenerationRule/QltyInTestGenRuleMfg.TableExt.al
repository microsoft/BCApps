// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.GenerationRule;

using Microsoft.QualityManagement.Integration.Manufacturing;
using Microsoft.QualityManagement.Utilities;
using Microsoft.QualityManagement.Integration.Assembly;
tableextension 20401 "Qlty. In Test Gen. Rule - Mfg." extends "Qlty. In. Test Generation Rule"
{
    fields
    {
        field(26; "Production Trigger"; Enum "Qlty. Production Trigger")
        {
            Caption = 'Production Trigger';
            ToolTip = 'Specifies whether the generation rule should be used to automatically create tests based on a production trigger.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
            begin
                Rec.ConfirmUpdateManualTriggerStatus();
                if (Rec."Activation Trigger" = Rec."Activation Trigger"::Disabled) and (Rec."Template Code" <> '') and (Rec."Production Trigger" <> Rec."Production Trigger"::NoTrigger) and GuiAllowed() then
                    QltyNotificationMgmt.Notify(StrSubstNo(RuleCurrentlyDisabledMfgLbl, Rec."Sort Order", Rec."Template Code", Rec."Production Trigger"));
            end;
        }
        field(27; "Assembly Trigger"; Enum "Qlty. Assembly Trigger")
        {
            Caption = 'Assembly Trigger';
            ToolTip = 'Specifies whether the generation rule should be used to automatically create tests based on an assembly trigger.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
            begin
                ConfirmUpdateManualTriggerStatus();
                if (Rec."Activation Trigger" = Rec."Activation Trigger"::Disabled) and (Rec."Template Code" <> '') and (Rec."Assembly Trigger" <> Rec."Assembly Trigger"::NoTrigger) and GuiAllowed() then
                    QltyNotificationMgmt.Notify(StrSubstNo(RuleCurrentlyDisabledMfgLbl, Rec."Sort Order", Rec."Template Code", Rec."Assembly Trigger"));
            end;
        }
    }

    var
        RuleCurrentlyDisabledMfgLbl: Label 'The generation rule Sort Order %1, Template Code %2 is currently disabled. It will need to have an activation trigger of "Automatic Only" or "Manual or Automatic" before it will be triggered by "%3"', Comment = '%1=generation rule sort order,%2=generation rule template code,%3=auto trigger';
}