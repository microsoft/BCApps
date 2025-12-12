// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.GenerationRule;

using Microsoft.QualityManagement.Integration.Manufacturing;
using Microsoft.QualityManagement.Setup.Setup;
pageextension 20421 "Qty. In Test Gen. Rules - Mfg." extends "Qlty. In. Test Generat. Rules"
{
    layout
    {
        addafter("Activation Trigger")
        {
            field("Assembly Trigger"; Rec."Assembly Trigger")
            {
                Visible = ShowAssemblyTrigger;
                Editable = EditAssemblyTrigger;
                StyleExpr = AssemblyStyle;
                ApplicationArea = Assembly;
            }
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
        addafter(CreateNewGenerationRuleForWhseWizard_Promoted)
        {
            actionref(CreateNewGenerationRuleForProdWizard_Promoted; CreateNewGenerationRuleForProdWizard)
            {
            }
        }

        addbefore(CreateNewGenerationRuleForRecWizard)
        {
            action(CreateNewGenerationRuleForProdWizard)
            {
                Caption = 'Create Production Rule';
                ToolTip = 'Specifies to create a rule for production.';
                Image = Receipt;
                ApplicationArea = Manufacturing;

                trigger OnAction()
                var
                    RecQltyProdGenRuleWizard: Page "Qlty. Prod. Gen. Rule Wizard";
                begin
                    RecQltyProdGenRuleWizard.RunModalWithGenerationRule(Rec);
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
                    QltyProdGenRuleWizard: Page "Qlty. Prod. Gen. Rule Wizard";
                    PreviousEntryNo: Integer;
                begin
                    PreviousEntryNo := Rec."Entry No.";
                    QltyProdGenRuleWizard.RunModalWithGenerationRule(Rec);

                    CurrPage.Update(false);
                    Rec.Reset();
                    Rec.SetRange("Entry No.", PreviousEntryNo);
                    if Rec.FindSet() then;
                    Rec.SetRange("Entry No.");
                end;
            }
        }

    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControls();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
    end;

    trigger OnOpenPage()
    begin
        SetTriggerColumnVisibleState();
        CurrPage.Update(false);
    end;

    local procedure UpdateControls()
    var
        KnownOrInferredIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        KnownOrInferredIntent := Rec.Intent;

        ClearRowSpecificVisibleAndEditFlags();
        if KnownOrInferredIntent = KnownOrInferredIntent::Unknown then begin
            Rec.InferGenerationRuleIntent(KnownOrInferredIntent, Certainty);

            if Certainty = Certainty::Maybe then begin
                ShowEditWizardProductionRule := true;
                EditAssemblyTrigger := true;
                EditProductionTrigger := true;
                AssemblyStyle := Format(RowStyle::Ambiguous);
                ProductionStyle := Format(RowStyle::Ambiguous);
            end;
        end;

        case KnownOrInferredIntent of
            Rec.Intent::Assembly:
                begin
                    ShowEditWizardProductionRule := true;
                    EditAssemblyTrigger := true;
                    AssemblyStyle := Format(RowStyle::Standard);
                end;
            Rec.Intent::Production:
                begin
                    ShowEditWizardProductionRule := true;
                    EditProductionTrigger := true;
                    ProductionStyle := Format(RowStyle::Standard);
                end;
        end;
    end;

    local procedure ClearRowSpecificVisibleAndEditFlags()
    begin
        ShowEditWizardProductionRule := false;
        EditAssemblyTrigger := false;
        EditProductionTrigger := false;
        AssemblyStyle := Format(RowStyle::Subordinate);
        ProductionStyle := Format(RowStyle::Subordinate);
    end;

    local procedure SetTriggerColumnVisibleState()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        ShowAssemblyTrigger := false;
        ShowProductionTrigger := false;

        QltyInTestGenerationRule.CopyFilters(Rec);
        QltyInTestGenerationRule.SetLoadFields(Intent);
        QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::Assembly);
        if not QltyInTestGenerationRule.IsEmpty() then
            ShowAssemblyTrigger := true;

        QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::Production);
        if not QltyInTestGenerationRule.IsEmpty() then
            ShowProductionTrigger := true;

        QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::Unknown);
        if not QltyInTestGenerationRule.IsEmpty() then begin
            ShowProductionTrigger := true;
            ShowAssemblyTrigger := true;
        end;

        if not QltyManagementSetup.Get() then
            exit;

        if QltyManagementSetup."Assembly Trigger" <> QltyManagementSetup."Assembly Trigger"::NoTrigger then
            ShowAssemblyTrigger := true;

        if QltyManagementSetup."Production Trigger" <> QltyManagementSetup."Production Trigger"::NoTrigger then
            ShowProductionTrigger := true;
    end;

    protected var
        ShowProductionTrigger, EditProductionTrigger : Boolean;
        ProductionStyle: Text;
        AssemblyStyle: Text;
        ShowEditWizardProductionRule: Boolean;
        EditAssemblyTrigger: Boolean;
        ShowAssemblyTrigger: Boolean;
}