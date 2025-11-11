// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Manufacturing;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Setup.Setup;

pageextension 20472 "Qlty. In Test Generat Rules" extends "Qlty. In. Test Generat. Rules"
{
    layout
    {
        addafter("Assembly Trigger")
        {
            field("Production Trigger"; Rec."Production Trigger")
            {
                Visible = ShowProductionTrigger;
                Editable = EditProductionTrigger;
                StyleExpr = ProductionStyle;
                ApplicationArea = Manufacturing;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(CreateNewGenerationRuleForProdWizard)
            {
                Caption = 'Create Production Rule';
                ToolTip = 'Specifies to create a rule for production.';
                Image = Receipt;
                ApplicationArea = Manufacturing;

                trigger OnAction()
                begin
                    OnEditGenerationRuleForProduction(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(EditGenerationRuleForProdWizard)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Edit Production Rule';
                ToolTip = 'Edit a Rule for production.';
                Image = Receipt;
                Scope = Repeater;
                Visible = ShowEditWizardProductionRule;

                trigger OnAction()
                var
                    PreviousEntryNo: Integer;
                begin
                    PreviousEntryNo := Rec."Entry No.";
                    OnEditGenerationRuleForProduction(Rec);
                    if PreviousEntryNo = Rec."Entry No." then
                        CurrPage.Update(false);
                end;
            }
        }
    }

    var
        ShowEditWizardProductionRule: Boolean;
        ShowProductionTrigger: Boolean;
        EditProductionTrigger: Boolean;
        ProductionStyle: Text;
        RowStyle: Option None,Standard,StandardAccent,Strong,StrongAccent,Attention,AttentionAccent,Favorable,Unfavorable,Ambiguous,Subordinate;

    trigger OnAfterGetCurrRecord()
    begin
        ShowEditWizardProductionRule := GetShowEditWizardProductionRule();
        SetProductionTriggerVisibility();
        UpdateProductionControls();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateProductionControls();
    end;

    local procedure UpdateProductionControls()
    var
        KnownOrInferredIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        // Clear Production-specific flags
        ShowEditWizardProductionRule := false;
        EditProductionTrigger := false;
        ProductionStyle := Format(RowStyle::Subordinate);

        KnownOrInferredIntent := Rec.Intent;

        // If intent is unknown, try to infer it
        if KnownOrInferredIntent = KnownOrInferredIntent::Unknown then begin
            Rec.InferGenerationRuleIntent(KnownOrInferredIntent, Certainty);

            if Certainty = Certainty::Maybe then begin
                ShowEditWizardProductionRule := true;
                EditProductionTrigger := true;
                ProductionStyle := Format(RowStyle::Ambiguous);
            end;
        end;

        // Handle Production intent specifically
        if KnownOrInferredIntent = KnownOrInferredIntent::Production then begin
            ShowEditWizardProductionRule := true;
            EditProductionTrigger := true;
            ProductionStyle := Format(RowStyle::Standard);
        end;
    end;

    local procedure SetProductionTriggerVisibility()
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyManagementSetup: Record "Qlty. Management Setup";
    begin
        ShowProductionTrigger := false;
        EditProductionTrigger := false;
        ProductionStyle := '';

        QltyInTestGenerationRule.CopyFilters(Rec);
        QltyInTestGenerationRule.SetLoadFields(Intent);
        QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::Production);
        if not QltyInTestGenerationRule.IsEmpty() then
            ShowProductionTrigger := true;

        if QltyManagementSetup.Get() then
            if QltyManagementSetup."Production Trigger" <> 0 then // NoTrigger
                ShowProductionTrigger := true;

        OnSetProductionTriggerVisibility(ShowProductionTrigger, EditProductionTrigger, ProductionStyle);
    end;

    local procedure GetShowEditWizardProductionRule(): Boolean
    var
        QltySourceConfig: Record "Qlty. Source Configuration";
    begin
        if not QltySourceConfig.Get(Rec."Source Table Configuration") then
            exit(false);
        exit(QltySourceConfig.SupportsProductionOutputSource());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEditGenerationRuleForProduction(var QltyInTestGeneratRule: Record "Qlty. In. Test Generat. Rule")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetProductionTriggerVisibility(var ShowProductionTrigger: Boolean; var EditProductionTrigger: Boolean; var ProductionStyle: Text)
    begin
    end;
}
