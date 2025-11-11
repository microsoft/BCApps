// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.GenerationRule;

using Microsoft.QualityManagement.Configuration.GenerationRule.JobQueue;
using Microsoft.QualityManagement.Integration.Receiving;
using Microsoft.QualityManagement.Integration.Warehouse;
using Microsoft.QualityManagement.Setup.Setup;

page 20405 "Qlty. In. Test Generat. Rules"
{
    Caption = 'Quality Inspection Test Generation Rules';
    DataCaptionExpression = GetDataCaptionExpression();
    PageType = List;
    SourceTable = "Qlty. In. Test Generation Rule";
    PopulateAllFields = true;
    SourceTableView = sorting("Sort Order", Intent);
    AdditionalSearchTerms = 'Assignments, Test Generation Parameters, Test Creation Criteria, Inspection Template Test Conditions, Quality Control Test Specification, Test Generation Guidelines, Test Triggering Parameters,Test Generation Rules';
    UsageCategory = Lists;
    ApplicationArea = QualityManagement;
    AboutTitle = 'Quality Inspection Test Generation Rule';
    AboutText = 'A Quality Inspection Test generation rule defines when you want to ask a set of questions or other data that you want to collect that is defined in a template. You connect a template to a source table, and set the criteria to use that template with the table filter. When these filter criteria is met, then it will choose that template. When there are multiple matches, it will use the first template that it finds, based on the sort order.';

    layout
    {
        area(Content)
        {
            repeater(Repeater)
            {
                ShowCaption = false;
                field("Sort Order"; Rec."Sort Order")
                {
                    Visible = ShowSortAndTemplate;
                }
                field("Template Code"; Rec."Template Code")
                {
                    Visible = ShowSortAndTemplate;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Description; Rec.Description)
                {
                }
                field(Intent; Rec.Intent)
                {
                }
                field("Source Table No."; Rec."Source Table No.")
                {
                    Visible = false;

                    trigger OnAssistEdit()
                    begin
                        Rec.HandleOnLookupSourceTable();
                        CurrPage.Update();
                    end;
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    AssistEdit = true;
                    ShowMandatory = true;

                    trigger OnAssistEdit()
                    begin
                        if IsNullGuid(Rec.SystemId) then begin
                            if Rec.Insert(true) then;
                            Commit();
                        end;
                        Rec.HandleOnLookupSourceTable();
                        if xRec."Entry No." = Rec."Entry No." then
                            CurrPage.Update(true);
                    end;
                }
                field("Condition Filter"; Rec."Condition Filter")
                {
                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditConditionTableFilter();
                        Rec.SetIntentAndDefaultTriggerValuesFromSetup();
                        if xRec."Entry No." = Rec."Entry No." then
                            CurrPage.Update(true);
                    end;
                }
                field("Item Filter"; Rec."Item Filter")
                {
                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditConditionItemFilter();
                    end;
                }
                field("Item Attribute Filter"; Rec."Item Attribute Filter")
                {
                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditConditionAttributeFilter();
                    end;
                }
                field("Activation Trigger"; Rec."Activation Trigger")
                {
                }
                field("Assembly Trigger"; Rec."Assembly Trigger")
                {
                    Visible = ShowAssemblyTrigger;
                    Editable = EditAssemblyTrigger;
                    StyleExpr = AssemblyStyle;
                }
                field("Purchase Trigger"; Rec."Purchase Trigger")
                {
                    Visible = ShowPurchaseTrigger;
                    Editable = EditPurchaseTrigger;
                    StyleExpr = PurchaseStyle;
                }
                field("Sales Return Trigger"; Rec."Sales Return Trigger")
                {
                    Visible = ShowSalesReturnTrigger;
                    Editable = EditSalesReturnTrigger;
                    StyleExpr = SalesReturnStyle;
                }
                field("Transfer Trigger"; Rec."Transfer Trigger")
                {
                    Visible = ShowTransferTrigger;
                    Editable = EditTransferTrigger;
                    StyleExpr = TransferStyle;
                }
                field("Warehouse Receive Trigger"; Rec."Warehouse Receive Trigger")
                {
                    Visible = ShowWarehouseReceiveTrigger;
                    Editable = EditWarehouseReceiveTrigger;
                    StyleExpr = WhseReceiveStyle;
                }
                field("Warehouse Movement Trigger"; Rec."Warehouse Movement Trigger")
                {
                    Visible = ShowWarehouseMovementTrigger;
                    Editable = EditWarehouseMovementTrigger;
                    StyleExpr = WhseMovementStyle;
                }
                field("Schedule Group"; Rec."Schedule Group")
                {
                }
            }
        }
        area(FactBoxes)
        {
            systempart(RecordLinks; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(RecordNotes; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref(CreateNewGenerationRuleForRecWizard_Promoted; CreateNewGenerationRuleForRecWizard)
            {
            }
            actionref(CreateNewGenerationRuleForWhseWizard_Promoted; CreateNewGenerationRuleForWhseWizard)
            {
            }
        }
        area(Processing)
        {
            action(CreateNewGenerationRuleForRecWizard)
            {
                Caption = 'Create Receiving Rule';
                ToolTip = 'Specifies to create a rule for receiving.';
                Image = Receipt;
                ApplicationArea = All;

                trigger OnAction()
                var
                    QltyRecGenRuleWizard: Page "Qlty. Rec. Gen. Rule Wizard";
                begin
                    QltyRecGenRuleWizard.RunModalWithGenerationRule(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(EditGenerationRuleForRecWizard)
            {
                ApplicationArea = All;
                Caption = 'Edit Receiving Rule';
                ToolTip = 'Edit a Rule for receiving.';
                Image = Receipt;
                Scope = Repeater;
                Visible = ShowEditWizardReceivingRule;

                trigger OnAction()
                var
                    QltyRecGenRuleWizard: Page "Qlty. Rec. Gen. Rule Wizard";
                    PreviousEntryNo: Integer;
                begin
                    PreviousEntryNo := Rec."Entry No.";
                    QltyRecGenRuleWizard.RunModalWithGenerationRule(Rec);

                    CurrPage.Update(false);
                    Rec.Reset();
                    Rec.SetRange("Entry No.", PreviousEntryNo);
                    if Rec.FindSet() then;
                    Rec.SetRange("Entry No.");
                end;
            }
            action(CreateNewGenerationRuleForWhseWizard)
            {
                Caption = 'Create Bin Movement Rule';
                ToolTip = 'Specifies to create a rule for a bin movement.';
                Image = CreatePutawayPick;
                ApplicationArea = Warehouse;

                trigger OnAction()
                var
                    RecQltyWhseGenRuleWizard: Page "Qlty. Whse. Gen. Rule Wizard";
                begin
                    RecQltyWhseGenRuleWizard.RunModalWithGenerationRule(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(EditGenerationRuleForWhseWizard)
            {
                ApplicationArea = Warehouse;
                Caption = 'Edit Bin Movement Rule';
                ToolTip = 'Edit a rule for a bin movement.';
                Image = InventoryPick;
                Scope = Repeater;
                Visible = ShowEditWizardMovementRule;

                trigger OnAction()
                var
                    QltyWhseGenRuleWizard: Page "Qlty. Whse. Gen. Rule Wizard";
                    PreviousEntryNo: Integer;
                begin
                    PreviousEntryNo := Rec."Entry No.";
                    QltyWhseGenRuleWizard.RunModalWithGenerationRule(Rec);

                    CurrPage.Update(false);
                    Rec.Reset();
                    Rec.SetRange("Entry No.", PreviousEntryNo);
                    if Rec.FindSet() then;
                    Rec.SetRange("Entry No.");
                end;
            }
            action(JobQueueEntries)
            {
                ApplicationArea = All;
                Caption = 'Job Queue Entries';
                ToolTip = 'Display related job queue entries.';
                Image = Timeline;
                Scope = Repeater;
                Visible = ShowJobQueueEntries;

                trigger OnAction()
                var
                    QltyJobQueueManagement: Codeunit "Qlty. Job Queue Management";
                begin
                    QltyJobQueueManagement.RunPageLookupJobQueueEntriesForScheduleGroup(Rec."Schedule Group");
                end;
            }
            action(CreateAnotherJobQueue)
            {
                ApplicationArea = All;
                Caption = 'Create a Job Queue Entry';
                ToolTip = 'Creates another job queue entry.';
                Image = Timeline;
                Scope = Repeater;
                Visible = ShowJobQueueEntries;

                trigger OnAction()
                var
                    QltyJobQueueManagement: Codeunit "Qlty. Job Queue Management";
                begin
                    QltyJobQueueManagement.PromptCreateJobQueueEntry(Rec."Schedule Group");
                end;
            }
        }
    }

    views
    {
        view(viewAll)
        {
            Caption = 'All';
            OrderBy = descending("Sort Order");
        }
        view(viewEnabled)
        {
            Caption = 'Enabled';
            Filters = where("Activation Trigger" = filter("Manual only" | "Manual or Automatic" | "Automatic only"));
            OrderBy = descending("Sort Order");
        }
        view(viewDisabled)
        {
            Caption = 'Disabled';
            Filters = where("Activation Trigger" = filter(Disabled));
            OrderBy = descending("Sort Order");
        }
    }

    var
        ShowSortAndTemplate: Boolean;
        ShowEditWizardMovementRule: Boolean;
        ShowEditWizardReceivingRule: Boolean;
        //ShowEditWizardProductionRule: Boolean;
        ShowEditWizardAssemblyRule: Boolean;
        TemplateCode: Code[20];
        ShowAssemblyTrigger: Boolean;
        ShowPurchaseTrigger: Boolean;
        ShowSalesReturnTrigger: Boolean;
        ShowTransferTrigger: Boolean;
        ShowWarehouseReceiveTrigger: Boolean;
        ShowWarehouseMovementTrigger: Boolean;
        EditAssemblyTrigger: Boolean;
        EditPurchaseTrigger: Boolean;
        EditSalesReturnTrigger: Boolean;
        EditTransferTrigger: Boolean;
        EditWarehouseReceiveTrigger: Boolean;
        EditWarehouseMovementTrigger: Boolean;
        ShowJobQueueEntries: Boolean;
        AssemblyStyle: Text;
        PurchaseStyle: Text;
        SalesReturnStyle: Text;
        WhseReceiveStyle: Text;
        WhseMovementStyle: Text;
        TransferStyle: Text;
        RowStyle: Option None,Standard,StandardAccent,Strong,StrongAccent,Attention,AttentionAccent,Favorable,Unfavorable,Ambiguous,Subordinate;
        GenerationRulesCaptionLbl: Label 'Quality Inspection Test Generation Rules';
        GenerationRulesCaptionForTemplateLbl: Label 'Quality Inspection Test Generation Rules for %1', Comment = '%1=the template';

    trigger OnInit()
    begin
        ShowSortAndTemplate := true;
        Rec.UpdateSortOrder();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        IdentifyIfPageStartedWithATemplate();
        SetTriggerColumnVisibleState();
        exit(Rec.Find(Which));
    end;

    trigger OnOpenPage()
    var
        QltyGenerationRuleMgmt: Codeunit "Qlty. Generation Rule Mgmt.";
    begin
        Rec.SetFilter("Table ID Filter", QltyGenerationRuleMgmt.GetFilterForAvailableConfigurations());
        AttemptUpdateUnknownIntents();
        IdentifyIfPageStartedWithATemplate();
        SetTriggerColumnVisibleState();
        CurrPage.Update(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        SourceTableFilter: Text;
    begin
        Rec.SetEntryNo();
        Rec.UpdateSortOrder();
        IdentifyIfPageStartedWithATemplate();
        if xRec."Source Table No." <> 0 then
            Rec."Source Table No." := xRec."Source Table No.";
        SourceTableFilter := Rec.GetFilter("Source Table No.");
        if SourceTableFilter.IndexOf('|') > 0 then
            Rec."Source Table No." := Rec.GetRangeMin("Source Table No.");
        Rec.CalcFields("Table Caption");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControls();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
    end;

    local procedure UpdateControls()
    var
        KnownOrInferredIntent: Enum "Qlty. Gen. Rule Intent";
        Certainty: Enum "Qlty. Certainty";
    begin
        KnownOrInferredIntent := Rec.Intent;

        ShowJobQueueEntries := Rec."Schedule Group" <> '';

        ClearRowSpecificVisibleAndEditFlags();
        if KnownOrInferredIntent = KnownOrInferredIntent::Unknown then begin
            Rec.InferGenerationRuleIntent(KnownOrInferredIntent, Certainty);

            if Certainty = Certainty::Maybe then begin
                //ShowEditWizardProductionRule := true;
                ShowEditWizardAssemblyRule := true;
                ShowEditWizardReceivingRule := true;
                ShowEditWizardMovementRule := true;
                EditAssemblyTrigger := true;
                EditPurchaseTrigger := true;
                EditSalesReturnTrigger := true;
                EditTransferTrigger := true;
                EditWarehouseMovementTrigger := true;
                EditWarehouseReceiveTrigger := true;

                AssemblyStyle := Format(RowStyle::Ambiguous);
                PurchaseStyle := Format(RowStyle::Ambiguous);
                SalesReturnStyle := Format(RowStyle::Ambiguous);
                WhseReceiveStyle := Format(RowStyle::Ambiguous);
                WhseMovementStyle := Format(RowStyle::Ambiguous);
                TransferStyle := Format(RowStyle::Ambiguous);
            end;
        end;

        case KnownOrInferredIntent of
            Rec.Intent::Assembly:
                begin
                    ShowEditWizardAssemblyRule := true;
                    EditAssemblyTrigger := true;
                    AssemblyStyle := Format(RowStyle::Standard);
                end;
            // Production-specific logic handled by Manufacturing app extension
            Rec.Intent::Purchase:
                begin
                    ShowEditWizardReceivingRule := true;
                    EditPurchaseTrigger := true;
                    PurchaseStyle := Format(RowStyle::Standard);
                end;
            Rec.Intent::"Sales Return":
                begin
                    ShowEditWizardReceivingRule := true;
                    EditSalesReturnTrigger := true;
                    SalesReturnStyle := Format(RowStyle::Standard);
                end;
            Rec.Intent::Transfer:
                begin
                    ShowEditWizardReceivingRule := true;
                    EditTransferTrigger := true;
                    TransferStyle := Format(RowStyle::Standard);
                end;
            Rec.Intent::"Warehouse Receipt":
                begin
                    ShowEditWizardReceivingRule := true;
                    EditWarehouseReceiveTrigger := true;
                    WhseReceiveStyle := Format(RowStyle::Standard);
                end;
            Rec.Intent::"Warehouse Movement":
                begin
                    ShowEditWizardMovementRule := true;
                    EditWarehouseMovementTrigger := true;
                    WhseMovementStyle := Format(RowStyle::Standard);
                end;
        end;
    end;

    local procedure ClearRowSpecificVisibleAndEditFlags()
    begin
        ShowEditWizardReceivingRule := false;
        //ShowEditWizardProductionRule := false;
        ShowEditWizardMovementRule := false;
        EditAssemblyTrigger := false;
        EditPurchaseTrigger := false;
        EditSalesReturnTrigger := false;
        EditTransferTrigger := false;
        EditWarehouseReceiveTrigger := false;
        EditWarehouseMovementTrigger := false;

        AssemblyStyle := Format(RowStyle::Subordinate);
        PurchaseStyle := Format(RowStyle::Subordinate);
        SalesReturnStyle := Format(RowStyle::Subordinate);
        WhseReceiveStyle := Format(RowStyle::Subordinate);
        WhseMovementStyle := Format(RowStyle::Subordinate);
        TransferStyle := Format(RowStyle::Subordinate);
    end;

    local procedure IdentifyIfPageStartedWithATemplate()
    begin
        TemplateCode := Rec.GetTemplateCodeFromRecordOrFilter(true);
        ShowSortAndTemplate := (TemplateCode = '');
    end;

    local procedure GetDataCaptionExpression(): Text
    begin
        exit((TemplateCode = '') ? GenerationRulesCaptionLbl : StrSubstNo(GenerationRulesCaptionForTemplateLbl, TemplateCode));
    end;

    local procedure SetTriggerColumnVisibleState()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        ShowAssemblyTrigger := false;
        ShowPurchaseTrigger := false;
        ShowSalesReturnTrigger := false;
        ShowTransferTrigger := false;
        ShowWarehouseReceiveTrigger := false;
        ShowWarehouseMovementTrigger := false;

        QltyInTestGenerationRule.CopyFilters(Rec);
        QltyInTestGenerationRule.SetLoadFields(Intent);
        QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::Assembly);
        if not QltyInTestGenerationRule.IsEmpty() then
            ShowAssemblyTrigger := true;

        QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::Purchase);
        if not QltyInTestGenerationRule.IsEmpty() then
            ShowPurchaseTrigger := true;

        QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::"Sales Return");
        if not QltyInTestGenerationRule.IsEmpty() then
            ShowSalesReturnTrigger := true;

        QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::Transfer);
        if not QltyInTestGenerationRule.IsEmpty() then
            ShowTransferTrigger := true;

        QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::"Warehouse Receipt");
        if not QltyInTestGenerationRule.IsEmpty() then
            ShowWarehouseReceiveTrigger := true;

        QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::"Warehouse Movement");
        if not QltyInTestGenerationRule.IsEmpty() then
            ShowWarehouseMovementTrigger := true;

        QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::Unknown);
        if not QltyInTestGenerationRule.IsEmpty() then begin
            ShowAssemblyTrigger := true;
            ShowPurchaseTrigger := true;
            ShowSalesReturnTrigger := true;
            ShowTransferTrigger := true;
            ShowWarehouseReceiveTrigger := true;
            ShowWarehouseMovementTrigger := true;
        end;

        if not QltyManagementSetup.Get() then
            exit;
        if QltyManagementSetup."Assembly Trigger" <> QltyManagementSetup."Assembly Trigger"::NoTrigger then
            ShowAssemblyTrigger := true;
        if QltyManagementSetup."Purchase Trigger" <> QltyManagementSetup."Purchase Trigger"::NoTrigger then
            ShowPurchaseTrigger := true;
        if QltyManagementSetup."Sales Return Trigger" <> QltyManagementSetup."Sales Return Trigger"::NoTrigger then
            ShowSalesReturnTrigger := true;
        if QltyManagementSetup."Transfer Trigger" <> QltyManagementSetup."Transfer Trigger"::NoTrigger then
            ShowTransferTrigger := true;
        if QltyManagementSetup."Warehouse Receive Trigger" <> QltyManagementSetup."Warehouse Receive Trigger"::NoTrigger then
            ShowWarehouseReceiveTrigger := true;
        if QltyManagementSetup."Warehouse Trigger" <> QltyManagementSetup."Warehouse Trigger"::NoTrigger then
            ShowWarehouseMovementTrigger := true;
    end;

    local procedure AttemptUpdateUnknownIntents()
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        if not QltyInTestGenerationRule.WritePermission() then
            exit;

        QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::Unknown);
        if not QltyInTestGenerationRule.IsEmpty() then
            if QltyInTestGenerationRule.FindSet() then
                repeat
                    QltyInTestGenerationRule.SetIntentAndDefaultTriggerValuesFromSetup();
                    if QltyInTestGenerationRule.Modify() then;
                until QltyInTestGenerationRule.Next() = 0;
    end;
}
