// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.GenerationRule;

using Microsoft.QualityManagement.Configuration.GenerationRule.JobQueue;
using Microsoft.QualityManagement.Integration.Manufacturing;
using Microsoft.QualityManagement.Integration.Receiving;
using Microsoft.QualityManagement.Integration.Warehouse;
using Microsoft.QualityManagement.Setup;

page 20405 "Qlty. Inspection Gen. Rules"
{
    Caption = 'Quality Inspection Generation Rules';
    DataCaptionExpression = GetDataCaptionExpression();
    PageType = List;
    SourceTable = "Qlty. Inspection Gen. Rule";
    PopulateAllFields = true;
    SourceTableView = sorting("Sort Order", Intent);
    UsageCategory = Lists;
    ApplicationArea = QualityManagement;
    AboutTitle = 'Quality Inspection Generation Rule';
    AboutText = 'A Quality Inspection generation rule defines when you want to ask a set of questions or other data that you want to collect that is defined in a template. You connect a template to a source table, and set the criteria to use that template with the table filter. When these filter criteria is met, then it will choose that template. When there are multiple matches, it will use the first template that it finds, based on the sort order.';

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
                        Rec.HandleOnAssistEditSourceTable();
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
                        Rec.HandleOnAssistEditSourceTable();
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
                field("Production Order Trigger"; Rec."Production Order Trigger")
                {
                    Visible = ShowProductionTrigger;
                    Editable = EditProductionTrigger;
                    StyleExpr = ProductionStyle;
                }
                field("Purchase Order Trigger"; Rec."Purchase Order Trigger")
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
                field("Transfer Order Trigger"; Rec."Transfer Order Trigger")
                {
                    Visible = ShowTransferTrigger;
                    Editable = EditTransferTrigger;
                    StyleExpr = TransferStyle;
                }
                field("Warehouse Receipt Trigger"; Rec."Warehouse Receipt Trigger")
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
                    trigger OnDrillDown()
                    var
                        QltyJobQueueManagement: Codeunit "Qlty. Job Queue Management";
                    begin
                        QltyJobQueueManagement.CheckIfGenerationRuleCanBeScheduled(Rec);
                        if GuiAllowed() then
                            if Rec."Schedule Group" = '' then begin
                                Rec."Schedule Group" := DefaultScheduleGroupLbl;
                                Rec.Modify(false);
                                QltyJobQueueManagement.PromptCreateJobQueueEntryIfMissing(Rec."Schedule Group");
                            end else
                                QltyJobQueueManagement.RunPageLookupJobQueueEntriesForScheduleGroup(Rec."Schedule Group")
                    end;
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
            actionref(CreateNewGenerationRuleForRecSetupGuide_Promoted; CreateNewGenerationRuleForRecSetupGuide)
            {
            }
            actionref(CreateNewGenerationRuleForWhseSGuide_Promoted; CreateNewGenerationRuleForWhseSGuide)
            {
            }
            actionref(CreateNewGenerationRuleForProdSGuide_Promoted; CreateNewGenerationRuleForProdSGuide)
            {
            }
            actionref(CreateNewGenerationRuleForAsmSGuide_Promoted; CreateNewGenerationRuleForAsmSGuide)
            {
            }
        }
        area(Processing)
        {
            action(CreateNewGenerationRuleForAsmSGuide)
            {
                Caption = 'Create Assembly Rule';
                ToolTip = 'Specifies to create a rule for assembly.';
                Image = AssemblyBOM;
                ApplicationArea = Assembly;

                trigger OnAction()
                var
                    NewQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
                    RecQltyAsmGenRuleSGuide: Page "Qlty. Asm. Gen. Rule S. Guide";
                begin
                    NewQltyInspectionGenRule.CopyFilters(Rec);
                    RecQltyAsmGenRuleSGuide.RunModalWithGenerationRule(NewQltyInspectionGenRule);
                    CurrPage.Update(false);
                end;
            }
            action(EditGenerationRuleForAsmSGuide)
            {
                ApplicationArea = Assembly;
                Caption = 'Edit Assembly Rule';
                ToolTip = 'Edit a Rule for assembly.';
                Image = EditLines;
                Scope = Repeater;
                Visible = ShowEditAssemblyRuleSetupGuide;

                trigger OnAction()
                var
                    QltyAsmGenRuleSGuide: Page "Qlty. Asm. Gen. Rule S. Guide";
                    PreviousEntryNo: Integer;
                begin
                    PreviousEntryNo := Rec."Entry No.";
                    QltyAsmGenRuleSGuide.RunModalWithGenerationRule(Rec);

                    CurrPage.Update(false);
                    Rec.Reset();
                    Rec.SetRange("Entry No.", PreviousEntryNo);
                    if Rec.FindSet() then;
                    Rec.SetRange("Entry No.");
                end;
            }
            action(CreateNewGenerationRuleForProdSGuide)
            {
                Caption = 'Create Production Rule';
                ToolTip = 'Specifies to create a rule for production.';
                Image = Production;
                ApplicationArea = Manufacturing;

                trigger OnAction()
                var
                    NewQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
                    RecQltyProdGenRuleSGuide: Page "Qlty. Prod. Gen. Rule S. Guide";
                begin
                    NewQltyInspectionGenRule.CopyFilters(Rec);
                    RecQltyProdGenRuleSGuide.RunModalWithGenerationRule(NewQltyInspectionGenRule);
                    CurrPage.Update(false);
                end;
            }
            action(EditGenerationRuleForProdSGuide)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Edit Production Rule';
                ToolTip = 'Edit a Rule for production.';
                Image = EditLines;
                Scope = Repeater;
                Visible = ShowEditProductionRuleSetupGuide;

                trigger OnAction()
                var
                    QltyProdGenRuleSGuide: Page "Qlty. Prod. Gen. Rule S. Guide";
                    PreviousEntryNo: Integer;
                begin
                    PreviousEntryNo := Rec."Entry No.";
                    QltyProdGenRuleSGuide.RunModalWithGenerationRule(Rec);

                    CurrPage.Update(false);
                    Rec.Reset();
                    Rec.SetRange("Entry No.", PreviousEntryNo);
                    if Rec.FindSet() then;
                    Rec.SetRange("Entry No.");
                end;
            }
            action(CreateNewGenerationRuleForRecSetupGuide)
            {
                Caption = 'Create Receiving Rule';
                ToolTip = 'Specifies to create a rule for receiving.';
                Image = Receipt;
                ApplicationArea = All;

                trigger OnAction()
                var
                    NewQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
                    QltyRecGenRuleSGuide: Page "Qlty. Rec. Gen. Rule S. Guide";
                begin
                    NewQltyInspectionGenRule.CopyFilters(Rec);
                    QltyRecGenRuleSGuide.RunModalWithGenerationRule(NewQltyInspectionGenRule);
                    CurrPage.Update(false);
                end;
            }
            action(EditGenerationRuleForRecSetupGuide)
            {
                ApplicationArea = All;
                Caption = 'Edit Receiving Rule';
                ToolTip = 'Edit a Rule for receiving.';
                Image = EditLines;
                Scope = Repeater;
                Visible = ShowEditReceivingRuleSetupGuide;

                trigger OnAction()
                var
                    QltyRecGenRuleSGuide: Page "Qlty. Rec. Gen. Rule S. Guide";
                    PreviousEntryNo: Integer;
                begin
                    PreviousEntryNo := Rec."Entry No.";
                    QltyRecGenRuleSGuide.RunModalWithGenerationRule(Rec);

                    CurrPage.Update(false);
                    Rec.Reset();
                    Rec.SetRange("Entry No.", PreviousEntryNo);
                    if Rec.FindSet() then;
                    Rec.SetRange("Entry No.");
                end;
            }
            action(CreateNewGenerationRuleForWhseSGuide)
            {
                Caption = 'Create Bin Movement Rule';
                ToolTip = 'Specifies to create a rule for a bin movement.';
                Image = CreateMovement;
                ApplicationArea = Warehouse;

                trigger OnAction()
                var
                    NewQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
                    QltyWhseGenRuleSGuide: Page "Qlty. Whse. Gen. Rule S. Guide";
                begin
                    NewQltyInspectionGenRule.CopyFilters(Rec);
                    QltyWhseGenRuleSGuide.RunModalWithGenerationRule(NewQltyInspectionGenRule);
                    CurrPage.Update(false);
                end;
            }
            action(EditGenerationRuleForWhseSGuide)
            {
                ApplicationArea = Warehouse;
                Caption = 'Edit Bin Movement Rule';
                ToolTip = 'Edit a rule for a bin movement.';
                Image = EditAdjustments;
                Scope = Repeater;
                Visible = ShowEditMovementRuleSetupGuide;

                trigger OnAction()
                var
                    QltyWhseGenRuleSGuide: Page "Qlty. Whse. Gen. Rule S. Guide";
                    PreviousEntryNo: Integer;
                begin
                    PreviousEntryNo := Rec."Entry No.";
                    QltyWhseGenRuleSGuide.RunModalWithGenerationRule(Rec);

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
                Image = EntriesList;
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
                Image = SelectEntries;
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
        view(viewEnabled)
        {
            Caption = 'Enabled';
            Filters = where("Activation Trigger" = filter("Manual only" | "Manual or Automatic" | "Automatic only"));
        }
        view(viewDisabled)
        {
            Caption = 'Disabled';
            Filters = where("Activation Trigger" = filter(Disabled));
        }
    }

    var
        ShowSortAndTemplate: Boolean;
        ShowEditMovementRuleSetupGuide: Boolean;
        ShowEditReceivingRuleSetupGuide: Boolean;
        ShowEditProductionRuleSetupGuide: Boolean;
        ShowEditAssemblyRuleSetupGuide: Boolean;
        TemplateCode: Code[20];
        ShowAssemblyTrigger: Boolean;
        ShowProductionTrigger: Boolean;
        ShowPurchaseTrigger: Boolean;
        ShowSalesReturnTrigger: Boolean;
        ShowTransferTrigger: Boolean;
        ShowWarehouseReceiveTrigger: Boolean;
        ShowWarehouseMovementTrigger: Boolean;
        EditAssemblyTrigger: Boolean;
        EditProductionTrigger: Boolean;
        EditPurchaseTrigger: Boolean;
        EditSalesReturnTrigger: Boolean;
        EditTransferTrigger: Boolean;
        EditWarehouseReceiveTrigger: Boolean;
        EditWarehouseMovementTrigger: Boolean;
        ShowJobQueueEntries: Boolean;
        AssemblyStyle: Text;
        ProductionStyle: Text;
        PurchaseStyle: Text;
        SalesReturnStyle: Text;
        WhseReceiveStyle: Text;
        WhseMovementStyle: Text;
        TransferStyle: Text;
        RowStyle: Option None,Standard,StandardAccent,Strong,StrongAccent,Attention,AttentionAccent,Favorable,Unfavorable,Ambiguous,Subordinate;
        GenerationRulesCaptionLbl: Label 'Quality Inspection Generation Rules';
        GenerationRulesCaptionForTemplateLbl: Label 'Quality Inspection Generation Rules for %1', Comment = '%1=the template';
        DefaultScheduleGroupLbl: Label 'QM', Locked = true;

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
        QltyInspecGenRuleMgmt: Codeunit "Qlty. Inspec. Gen. Rule Mgmt.";
    begin
        Rec.SetFilter("Table ID Filter", QltyInspecGenRuleMgmt.GetFilterForAvailableConfigurations());
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
                ShowEditProductionRuleSetupGuide := true;
                ShowEditReceivingRuleSetupGuide := true;
                ShowEditMovementRuleSetupGuide := true;
                ShowEditAssemblyRuleSetupGuide := true;
                EditAssemblyTrigger := true;
                EditProductionTrigger := true;
                EditPurchaseTrigger := true;
                EditSalesReturnTrigger := true;
                EditTransferTrigger := true;
                EditWarehouseMovementTrigger := true;
                EditWarehouseReceiveTrigger := true;

                AssemblyStyle := Format(RowStyle::Ambiguous);
                ProductionStyle := Format(RowStyle::Ambiguous);
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
                    ShowEditAssemblyRuleSetupGuide := true;
                    EditAssemblyTrigger := true;
                    AssemblyStyle := Format(RowStyle::Standard);
                end;
            Rec.Intent::Production:
                begin
                    ShowEditProductionRuleSetupGuide := true;
                    EditProductionTrigger := true;
                    ProductionStyle := Format(RowStyle::Standard);
                end;
            Rec.Intent::Purchase:
                begin
                    ShowEditReceivingRuleSetupGuide := true;
                    EditPurchaseTrigger := true;
                    PurchaseStyle := Format(RowStyle::Standard);
                end;
            Rec.Intent::"Sales Return":
                begin
                    ShowEditReceivingRuleSetupGuide := true;
                    EditSalesReturnTrigger := true;
                    SalesReturnStyle := Format(RowStyle::Standard);
                end;
            Rec.Intent::Transfer:
                begin
                    ShowEditReceivingRuleSetupGuide := true;
                    EditTransferTrigger := true;
                    TransferStyle := Format(RowStyle::Standard);
                end;
            Rec.Intent::"Warehouse Receipt":
                begin
                    ShowEditReceivingRuleSetupGuide := true;
                    EditWarehouseReceiveTrigger := true;
                    WhseReceiveStyle := Format(RowStyle::Standard);
                end;
            Rec.Intent::"Warehouse Movement":
                begin
                    ShowEditMovementRuleSetupGuide := true;
                    EditWarehouseMovementTrigger := true;
                    WhseMovementStyle := Format(RowStyle::Standard);
                end;
        end;
    end;

    local procedure ClearRowSpecificVisibleAndEditFlags()
    begin
        ShowEditReceivingRuleSetupGuide := false;
        ShowEditProductionRuleSetupGuide := false;
        ShowEditAssemblyRuleSetupGuide := false;
        ShowEditMovementRuleSetupGuide := false;
        EditProductionTrigger := false;
        EditAssemblyTrigger := false;
        EditPurchaseTrigger := false;
        EditSalesReturnTrigger := false;
        EditTransferTrigger := false;
        EditWarehouseReceiveTrigger := false;
        EditWarehouseMovementTrigger := false;

        AssemblyStyle := Format(RowStyle::Subordinate);
        ProductionStyle := Format(RowStyle::Subordinate);
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
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        ShowAssemblyTrigger := false;
        ShowProductionTrigger := false;
        ShowPurchaseTrigger := false;
        ShowSalesReturnTrigger := false;
        ShowTransferTrigger := false;
        ShowWarehouseReceiveTrigger := false;
        ShowWarehouseMovementTrigger := false;

        QltyInspectionGenRule.CopyFilters(Rec);
        QltyInspectionGenRule.SetLoadFields(Intent);
        QltyInspectionGenRule.SetRange(Intent, QltyInspectionGenRule.Intent::Assembly);
        if not QltyInspectionGenRule.IsEmpty() then
            ShowAssemblyTrigger := true;

        QltyInspectionGenRule.SetRange(Intent, QltyInspectionGenRule.Intent::Production);
        if not QltyInspectionGenRule.IsEmpty() then
            ShowProductionTrigger := true;

        QltyInspectionGenRule.SetRange(Intent, QltyInspectionGenRule.Intent::Purchase);
        if not QltyInspectionGenRule.IsEmpty() then
            ShowPurchaseTrigger := true;

        QltyInspectionGenRule.SetRange(Intent, QltyInspectionGenRule.Intent::"Sales Return");
        if not QltyInspectionGenRule.IsEmpty() then
            ShowSalesReturnTrigger := true;

        QltyInspectionGenRule.SetRange(Intent, QltyInspectionGenRule.Intent::Transfer);
        if not QltyInspectionGenRule.IsEmpty() then
            ShowTransferTrigger := true;

        QltyInspectionGenRule.SetRange(Intent, QltyInspectionGenRule.Intent::"Warehouse Receipt");
        if not QltyInspectionGenRule.IsEmpty() then
            ShowWarehouseReceiveTrigger := true;

        QltyInspectionGenRule.SetRange(Intent, QltyInspectionGenRule.Intent::"Warehouse Movement");
        if not QltyInspectionGenRule.IsEmpty() then
            ShowWarehouseMovementTrigger := true;

        QltyInspectionGenRule.SetRange(Intent, QltyInspectionGenRule.Intent::Unknown);
        if not QltyInspectionGenRule.IsEmpty() then begin
            ShowAssemblyTrigger := true;
            ShowProductionTrigger := true;
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
        if QltyManagementSetup."Production Order Trigger" <> QltyManagementSetup."Production Order Trigger"::NoTrigger then
            ShowProductionTrigger := true;
        if QltyManagementSetup."Purchase Order Trigger" <> QltyManagementSetup."Purchase Order Trigger"::NoTrigger then
            ShowPurchaseTrigger := true;
        if QltyManagementSetup."Sales Return Trigger" <> QltyManagementSetup."Sales Return Trigger"::NoTrigger then
            ShowSalesReturnTrigger := true;
        if QltyManagementSetup."Transfer Order Trigger" <> QltyManagementSetup."Transfer Order Trigger"::NoTrigger then
            ShowTransferTrigger := true;
        if QltyManagementSetup."Warehouse Receipt Trigger" <> QltyManagementSetup."Warehouse Receipt Trigger"::NoTrigger then
            ShowWarehouseReceiveTrigger := true;
        if QltyManagementSetup."Warehouse Trigger" <> QltyManagementSetup."Warehouse Trigger"::NoTrigger then
            ShowWarehouseMovementTrigger := true;
    end;

    local procedure AttemptUpdateUnknownIntents()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        if not QltyInspectionGenRule.WritePermission() then
            exit;

        QltyInspectionGenRule.SetRange(Intent, QltyInspectionGenRule.Intent::Unknown);
        if not QltyInspectionGenRule.IsEmpty() then
            if QltyInspectionGenRule.FindSet() then
                repeat
                    QltyInspectionGenRule.SetIntentAndDefaultTriggerValuesFromSetup();
                    QltyInspectionGenRule.Modify();
                until QltyInspectionGenRule.Next() = 0;
    end;
}