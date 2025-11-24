// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.GenerationRule;

using Microsoft.Manufacturing.Document;
using Microsoft.QualityManagement.Setup.Setup;
codeunit 20419 "Qlty. In Test Gen. Rule - Mfg."
{
    [EventSubscriber(ObjectType::Table, Database::"Qlty. In. Test Generation Rule", 'OnConfirmUpdateManualTriggerStatusOnBeforeOnCheckTriggerIsNoTrigger', '', false, false)]
    local procedure OnConfirmUpdateManualTriggerStatusOnBeforeOnCheckTriggerIsNoTrigger(var QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule"; var NoTrigger: Boolean)
    begin
        if NoTrigger then
            NoTrigger := NoTrigger and (QltyInTestGenerationRule."Production Trigger" = QltyInTestGenerationRule."Production Trigger"::NoTrigger) and (QltyInTestGenerationRule."Assembly Trigger" = QltyInTestGenerationRule."Assembly Trigger"::NoTrigger);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Qlty. In. Test Generation Rule", 'OnSetIntentAndDefaultTriggerValuesFromSetupElseCase', '', false, false)]
    local procedure OnSetIntentAndDefaultTriggerValuesFromSetupElseCase(var QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule"; var QltyManagementSetup: Record "Qlty. Management Setup"; InferredIntent: Enum "Qlty. Gen. Rule Intent")
    begin
        case InferredIntent of
            InferredIntent::Assembly:
                QltyInTestGenerationRule."Assembly Trigger" := QltyManagementSetup."Assembly Trigger";
            InferredIntent::Production:
                QltyInTestGenerationRule."Production Trigger" := QltyManagementSetup."Production Trigger";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Qlty. In. Test Generation Rule", 'OnAfterSetDefaultTriggerValuesToNoTrigger', '', false, false)]
    local procedure OnAfterSetDefaultTriggerValuesToNoTrigger(var QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule")
    begin
        QltyInTestGenerationRule."Assembly Trigger" := QltyInTestGenerationRule."Assembly Trigger"::NoTrigger;
        QltyInTestGenerationRule."Production Trigger" := QltyInTestGenerationRule."Production Trigger"::NoTrigger;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Qlty. In. Test Generation Rule", 'OnInferGenerationRuleIntentElseCase', '', false, false)]
    local procedure OnInferGenerationRuleIntentElseCase(var QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule"; var QltyGenRuleIntent: Enum "Qlty. Gen. Rule Intent"; var QltyCertainty: Enum "Qlty. Certainty")
    begin
        if QltyInTestGenerationRule."Source Table No." in [Database::"Prod. Order Routing Line", Database::"Prod. Order Line", Database::"Production Order"] then begin
            QltyGenRuleIntent := QltyGenRuleIntent::Production;
            QltyCertainty := QltyCertainty::Yes;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Qlty. In. Test Generation Rule", 'OnGetIsProductionIntentElseCase', '', false, false)]
    local procedure OnGetIsProductionIntentElseCase(SourceTableNo: Integer; ConditionFilter: Text[400]; var Result: Boolean)
    begin
        if SourceTableNo in [Database::"Prod. Order Routing Line", Database::"Prod. Order Line", Database::"Production Order"] then
            Result := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Qlty. In. Test Generation Rule", 'OnAfterGetIsOnlyAutoTriggerInSetup', '', false, false)]
    local procedure OnAfterGetIsOnlyAutoTriggerInSetup(var QltyManagementSetup: Record "Qlty. Management Setup"; IntentToCheck: Enum "Qlty. Gen. Rule Intent"; IntentSet: Boolean; TriggerCount: Integer)
    begin
        if QltyManagementSetup."Production Trigger" <> QltyManagementSetup."Production Trigger"::NoTrigger then begin
            TriggerCount += 1;
            if IntentToCheck = IntentToCheck::Production then
                IntentSet := true;
        end;

        if QltyManagementSetup."Assembly Trigger" <> QltyManagementSetup."Assembly Trigger"::NoTrigger then begin
            TriggerCount += 1;
            if IntentToCheck = IntentToCheck::Assembly then
                IntentSet := true;
        end;
    end;
}