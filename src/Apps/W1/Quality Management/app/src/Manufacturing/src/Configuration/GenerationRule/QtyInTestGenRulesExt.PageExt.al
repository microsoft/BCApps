pageextension 20421 "Qty. In Test Gen. Rules - Mfg" extends "Qlty. In. Test Generat. Rules"
{
    layout
    {
        // Add changes to page layout here
        addafter("Assembly Trigger")
        {
            field("Production Trigger"; Rec."Production Trigger")
            {
                Visible = ShowProductionTrigger;
                Editable = EditProductionTrigger;
                StyleExpr = ProductionStyle;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
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
    var
        QltyGenerationRuleMgmt: Codeunit "Qlty. Generation Rule Mgmt.";
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
                EditProductionTrigger := true;
                ProductionStyle := Format(RowStyle::Ambiguous);
            end;
        end;

        if KnownOrInferredIntent = Rec.Intent::Production then begin
            ShowEditWizardProductionRule := true;
            EditProductionTrigger := true;
            ProductionStyle := Format(RowStyle::Standard);
        end;
    end;

    local procedure ClearRowSpecificVisibleAndEditFlags()
    begin
        ShowEditWizardProductionRule := false;
        EditProductionTrigger := false;
        ProductionStyle := Format(RowStyle::Subordinate);
    end;

    local procedure SetTriggerColumnVisibleState()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        ShowProductionTrigger := false;

        QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::Production);
        if not QltyInTestGenerationRule.IsEmpty() then
            ShowProductionTrigger := true;

        QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::Unknown);
        if not QltyInTestGenerationRule.IsEmpty() then
            ShowProductionTrigger := true;

        if not QltyManagementSetup.Get() then
            exit;
        if QltyManagementSetup."Production Trigger" <> QltyManagementSetup."Production Trigger"::NoTrigger then
            ShowProductionTrigger := true;
    end;

    protected var
        ShowProductionTrigger, EditProductionTrigger : Boolean;
        ProductionStyle: Text;
        ShowEditWizardProductionRule: Boolean;
}