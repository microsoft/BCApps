// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using System.Environment;
using System.Utilities;

page 99001505 "Subc. PurchProvisionWizard"
{
    ApplicationArea = Manufacturing;
    Caption = 'Purchase Provision Wizard';
    PageType = NavigatePage;
    SourceTable = Item;
    SourceTableTemporary = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(StandardBanner)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible;
                field(MediaResourcesStandardBanner; MediaResourcesStandard."Media Reference")
                {
                    Editable = false;
                    ShowCaption = false;
                }
            }
            // Step 1: Introduction
            group(IntroStep)
            {
                ShowCaption = false;
                Visible = IntroStepVisible;

                group(WelcomeGroup)
                {
                    Caption = 'Welcome to Purchase Provision Setup';

                    group(IntroductionGroup)
                    {
                        InstructionalText = 'This wizard helps you select and configure the BOM and Routing for your production order. You can select which BOM and Routing to use, and preview the components and operations before creating the production order.';
                        ShowCaption = false;
                    }
                }
                group(General)
                {
                    Caption = 'General';
                    field("No."; Rec."No.")
                    {
                        Caption = 'Item No.';
                        Editable = false;
                        ToolTip = 'Specifies the item number for which the purchase provision is being set up.';
                    }
                    field(Description; Rec.Description)
                    {
                        Caption = 'Description';
                        Editable = false;
                        ToolTip = 'Specifies the description of the item for which the purchase provision is being set up.';
                    }
                    group(BomRoutingTransfer)
                    {
                        Caption = 'BOM/Routing Transfer';
                        field(BomRtngFromSource; BomRtngFromSourceTxt)
                        {
                            Caption = 'Source';
                            Editable = false;
                            ToolTip = 'Specifies the source where BOM and Routing data was retrieved from.';
                        }
                        field(SaveBOMRouting; SaveBOMRouting)
                        {
                            Caption = 'Save';
                            ToolTip = 'Specifies whether to apply the selected BOM and Routing to the specified source.';

                            trigger OnValidate()
                            begin
                                if SaveBOMRouting then begin
                                    SaveBomRtngToSource := BomRtngFromSource;
                                    if SaveBomRtngToSource = SaveBomRtngToSource::Empty then
                                        SaveBomRtngToSource := SaveBomRtngToSource::Item
                                end else
                                    Clear(SaveBomRtngToSource);
                            end;
                        }
                        field(SaveBomRtngToSource; SaveBomRtngToSource)
                        {
                            Caption = 'Save in';
                            Editable = SaveBOMRouting;
                            ToolTip = 'Specifies where to apply the BOM and Routing changes.';
                            trigger OnValidate()
                            var
                                SaveBOMRtngSourceNotEmptyErr: Label 'Please select a valid source for saving BOM and Routing changes.';
                            begin
                                if SaveBOMRouting and (SaveBomRtngToSource = SaveBomRtngToSource::Empty) then
                                    Error(SaveBOMRtngSourceNotEmptyErr);
                            end;
                        }
                    }
                }
                group(ShowEditOptions)
                {
                    Caption = 'Show/Edit Options';
                    Enabled = ShowEditOptionsEnabled;

                    field(BOMRoutingShowEditTypeField; BOMRoutingShowEditType)
                    {
                        Caption = 'BOM/Routing';
                        ToolTip = 'Specifies the display and editing behavior for BOM and Routing selection steps in the wizard. Hide: Skip BOM/Routing selection steps entirely. Show: Show BOM/Routing selection with version choice but no editing. Edit: Show BOM/Routing selection with full editing capabilities including version creation and line modifications.';
                        trigger OnValidate()
                        begin
                            SetBOMRoutingEditable();
                        end;
                    }
                    field(ProdCompRoutingShowEditTypeField; ProdCompRoutingShowEditType)
                    {
                        Caption = 'Prod. Components/Prod. Operations';
                        ToolTip = 'Specifies the display and editing behavior for Production Order Components and Routing-Operations preview steps in the wizard. Hide: Skip component and routing preview steps, use generated data directly. Show: Show component and routing preview for review but no editing allowed. Edit: Show component and routing preview with full editing capabilities allowing modifications before production order creation.';
                    }
                }
            }
            // Step 2: BOM Selection
            group(BOMStep)
            {
                ShowCaption = false;
                Visible = BOMStepVisible;

                group(BOMSelection)
                {
                    Caption = 'Production BOM Selection';
                    InstructionalText = 'Select the Production BOM and version to use for the production order.';

                    group(BOMCreationGroup)
                    {
                        ShowCaption = false;
                        Visible = CreateBOMVersionVisible;
                        field(BOMIntroductionText; NewVersionIntroductionLbl)
                        {
                            Editable = false;
                            MultiLine = true;
                            ShowCaption = false;
                            Style = StandardAccent;
                        }
                        field(CreateBOMVersion; CreateBOMVersion)
                        {
                            Caption = 'Create New BOM Version';
                            ToolTip = 'Specifies whether to create a new version of the Production BOM with an automatically generated version number.';

                            trigger OnValidate()
                            begin
                                if CreateBOMVersion then begin
                                    SelectedBOMVersion := 'TEMP-VERSION-' + CopyStr(Format(CreateGuid()), 2, 7);
                                    SubcVersionMgmt.GetBOMVersionNoSeries(SelectedBOMNo)
                                end else begin
                                    SelectedBOMVersion := '';
                                    LoadBOMLines();
                                end;
                                SetBOMRoutingEditable();
                                SubcTempDataInitializer.UpdateBOMVersionCode(SelectedBOMVersion);
                            end;
                        }
                    }
                    field("Production BOM No."; SelectedBOMNo)
                    {
                        Caption = 'Production BOM No.';
                        Editable = false;
                        ToolTip = 'Specifies the Production BOM to use for the production order.';

                        trigger OnAssistEdit()
                        var
                            NewBOMNo: Code[20];
                        begin
                            NewBOMNo := SelectedBOMNo;
                            if SubcVersionMgmt.ShowBOMSelection(NewBOMNo) then
                                if NewBOMNo <> SelectedBOMNo then begin
                                    SelectedBOMNo := NewBOMNo;
                                    SelectedBOMVersion := '';
                                    LoadBOMLines();
                                    SetBOMRoutingEditable();
                                end;
                        end;
                    }
                    field(SelectedBOMVersion; SelectedBOMVersion)
                    {
                        Caption = 'Selected BOM Version';
                        Editable = false;
                        ToolTip = 'Specifies the version of the Production BOM to use for the production order.';

                        trigger OnAssistEdit()
                        begin
                            if SubcVersionMgmt.ShowBOMVersionSelection(SelectedBOMNo, SelectedBOMVersion) then
                                LoadBOMLines();
                        end;
                    }
                    part(BOMLinesPart; "Subc. Temp BOM Lines")
                    {
                        Caption = 'Production BOM Lines';
                        Editable = EditBOMLines;
                    }
                }
            }
            // Step 3: Routing Selection
            group(RoutingStep)
            {
                ShowCaption = false;
                Visible = RoutingStepVisible;

                group(RoutingSelection)
                {
                    Caption = 'Routing Selection';
                    InstructionalText = 'Select the Routing and version to use for the production order.';

                    group(RoutingCreationGroup)
                    {
                        ShowCaption = false;
                        Visible = CreateRoutingVersionVisible;
                        field(RoutingIntroductionText; NewVersionIntroductionLbl)
                        {
                            Editable = false;
                            MultiLine = true;
                            ShowCaption = false;
                            Style = StandardAccent;
                        }
                        field(CreateRoutingVersion; CreateRoutingVersion)
                        {
                            Caption = 'Create New Routing Version';
                            ToolTip = 'Specifies whether to create a new version of the Routing with an automatically generated version number.';

                            trigger OnValidate()
                            begin
                                if CreateRoutingVersion then begin
                                    SelectedRoutingVersion := 'TEMP-VER-' + CopyStr(Format(CreateGuid()), 2, 7);
                                    SubcVersionMgmt.GetRoutingVersionNoSeries(SelectedRoutingNo)
                                end else begin
                                    SelectedRoutingVersion := '';
                                    LoadRoutingLines();
                                end;
                                SetBOMRoutingEditable();
                                SubcTempDataInitializer.UpdateRoutingVersionCode(SelectedRoutingVersion);
                            end;
                        }
                    }
                    field("Routing No."; SelectedRoutingNo)
                    {
                        Caption = 'Routing No.';
                        Editable = false;
                        ToolTip = 'Specifies the Routing to use for the production order.';

                        trigger OnAssistEdit()
                        var
                            NewRoutingNo: Code[20];
                        begin
                            NewRoutingNo := SelectedRoutingNo;
                            if SubcVersionMgmt.ShowRoutingSelection(NewRoutingNo) then
                                if NewRoutingNo <> SelectedRoutingNo then begin
                                    SelectedRoutingNo := NewRoutingNo;
                                    SelectedRoutingVersion := '';
                                    LoadRoutingLines();
                                    SetBOMRoutingEditable();
                                end;
                        end;
                    }
                    field(SelectedRoutingVersion; SelectedRoutingVersion)
                    {
                        Caption = 'Selected Routing Version';
                        Editable = false;
                        ToolTip = 'Specifies the version of the Routing to use for the production order.';

                        trigger OnAssistEdit()
                        begin
                            if SubcVersionMgmt.ShowRoutingVersionSelection(SelectedRoutingNo, SelectedRoutingVersion) then
                                LoadRoutingLines();
                        end;
                    }
                    part(RoutingLinesPart; "Subc. Temp Routing Lines")
                    {
                        Caption = 'Routing Lines';
                        Editable = EditRoutingLines;
                    }
                }
            }
            // Step 4: Components Preview
            group(ComponentsStep)
            {
                ShowCaption = false;
                Visible = ComponentsStepVisible;

                group(ComponentsPreview)
                {
                    Caption = 'Components Preview';
                    InstructionalText = 'Review and edit the components that will be created for the production order.';

                    part(ComponentsPart; "Subc. Temp Prod Order Comp")
                    {
                        Caption = 'Components';
                        Editable = ProdCompRoutingShowEditType = ProdCompRoutingShowEditType::Edit;
                    }
                }
            }
            // Step 5: Production Order Routing Preview
            group(ProdRoutingStep)
            {
                ShowCaption = false;
                Visible = ProdRoutingStepVisible;

                group(ProdRoutingPreview)
                {
                    Caption = 'Production Order Routing Preview';
                    InstructionalText = 'Review and edit the routing operations that will be created for the production order.';

                    part(ProdOrderRoutingPart; "Subc. TempProdOrdRtngLines")
                    {
                        Caption = 'Prod. Order Routing Lines';
                        Editable = ProdCompRoutingShowEditType = ProdCompRoutingShowEditType::Edit;
                    }
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    FinishAction();
                end;
            }
        }
    }
    protected var
        BackActionEnabled, FinishActionEnabled, NextActionEnabled, ShowEditOptionsEnabled : Boolean;
        BOMStepVisible, ComponentsStepVisible, IntroStepVisible, ProdRoutingStepVisible, RoutingStepVisible, TopBannerVisible : Boolean;
        CreateBOMVersion, CreateRoutingVersion : Boolean;
        CreateBOMVersionVisible, CreateRoutingVersionVisible : Boolean;
        EditBOMLines, EditRoutingLines : Boolean;
        SaveBOMRouting: Boolean;
        SelectedBOMNo, SelectedBOMVersion, SelectedRoutingNo, SelectedRoutingVersion : Code[20];
        SaveBomRtngToSource: Enum "Subc. RtngBOMSourceType";
        BOMRoutingShowEditType, ProdCompRoutingShowEditType : Enum "Subc. Show/Edit Type";
        Step: Option Intro,BOM,Routing,Components,ProdRouting;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        SubcTempDataInitializer: Codeunit "Subc. Temp Data Initializer";
        SubcVersionMgmt: Codeunit "Subc. Version Mgmt.";
        Finished: Boolean;
        BomRtngFromSource: Enum "Subc. RtngBOMSourceType";
        BomRtngFromSourceTxt: Text;
        NewVersionIntroductionLbl: Label 'To edit lines directly, activate "Create New Version". This generates a temporary version code (replaced by a number series upon saving). Without this, existing master data is used, and editing is disabled for this step.';

    trigger OnInit()
    begin
        LoadTopBanners();
    end;

    trigger OnOpenPage()
    begin
        SetBOMDataReference();
        SetRoutingDataReference();
        SetProdOrderDataReference();

        InitBomRoutingSource();

        Step := Step::Intro;
        EnableControls();

        SetBOMRoutingEditable();
        SetShowEditOptionsEnabled();

        if Rec.FindFirst() then;
    end;

    /// <summary>
    /// Sets the item for which the production order will be created.
    /// </summary>
    /// <param name="Item">The item record to use for production order creation.</param>
    procedure SetItem(Item: Record Item)
    begin
        Rec := Item;
        Rec.Insert();
    end;

    /// <summary>
    /// Sets the display and editing behavior for BOM and Routing selection steps.
    /// </summary>
    /// <param name="SubcShowEditType">The show/edit type to control BOM and Routing step behavior.</param>
    procedure SetBOMRoutingShowEditType(SubcShowEditType: Enum "Subc. Show/Edit Type")
    begin
        BOMRoutingShowEditType := SubcShowEditType;
    end;

    /// <summary>
    /// Sets the display and editing behavior for Production Order Components and Routing preview steps.
    /// </summary>
    /// <param name="SubcShowEditType">The show/edit type to control component and routing preview behavior.</param>
    procedure SetProdCompRoutingShowEditType(SubcShowEditType: Enum "Subc. Show/Edit Type")
    begin
        ProdCompRoutingShowEditType := SubcShowEditType;
    end;

    /// <summary>
    /// Sets the temporary data initializer codeunit for managing temporary production order data.
    /// </summary>
    /// <param name="NewSubcTempDataInitializer">The temporary data initializer codeunit to use.</param>
    procedure SetTempDataInitializer(var NewSubcTempDataInitializer: Codeunit "Subc. Temp Data Initializer")
    begin
        SubcTempDataInitializer := NewSubcTempDataInitializer;
    end;

    /// <summary>
    /// Gets the source where BOM and Routing changes should be applied.
    /// </summary>
    /// <returns>The source type for applying BOM and Routing changes.</returns>
    procedure GetApplyBomRtngToSource(): Enum "Subc. RtngBOMSourceType"
    begin
        exit(SaveBomRtngToSource);
    end;

    /// <summary>
    /// Checks if changes were made to the production order components.
    /// </summary>
    /// <returns>True if components were modified, false otherwise.</returns>
    procedure GetApplyChangesComponents(): Boolean
    begin
        exit(CurrPage.ComponentsPart.Page.GetLinesChanged());
    end;

    /// <summary>
    /// Checks if changes were made to the production order routing.
    /// </summary>
    /// <returns>True if routing was modified, false otherwise.</returns>
    procedure GetApplyChangesProdRouting(): Boolean
    begin
        exit(CurrPage.ProdOrderRoutingPart.Page.GetLinesChanged());
    end;

    /// <summary>
    /// Gets the completion status of the wizard.
    /// </summary>
    /// <returns>True if the wizard was completed successfully, false otherwise.</returns>
    procedure GetFinished(): Boolean
    begin
        exit(Finished);
    end;

    local procedure LoadBOMLines()
    begin
        if SelectedBOMNo = '' then
            exit;

        if not SubcVersionMgmt.CheckBOMExists(SelectedBOMNo, SelectedBOMVersion) then
            exit;

        SubcTempDataInitializer.LoadBOMLines(SelectedBOMNo, SelectedBOMVersion);
    end;

    local procedure LoadRoutingLines()
    begin
        if SelectedRoutingNo = '' then
            exit;

        if not SubcVersionMgmt.CheckRoutingExists(SelectedRoutingNo, SelectedRoutingVersion) then
            exit;

        SubcTempDataInitializer.LoadRoutingLines(SelectedRoutingNo, SelectedRoutingVersion);
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(CurrentClientType())) then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") then
                TopBannerVisible := MediaResourcesStandard."Media Reference".HasValue();
    end;

    local procedure SetBOMDataReference()
    var
        TempProductionBOMLine: Record "Production BOM Line" temporary;
    begin
        SubcTempDataInitializer.GetGlobalBOMLines(TempProductionBOMLine);
        CurrPage.BOMLinesPart.Page.SetTemporaryRecords(TempProductionBOMLine);

        SelectedBOMNo := TempProductionBOMLine."Production BOM No.";
        SelectedBOMVersion := TempProductionBOMLine."Version Code";
    end;

    local procedure SetRoutingDataReference()
    var
        TempRoutingLine: Record "Routing Line" temporary;
    begin
        SubcTempDataInitializer.GetGlobalRoutingLines(TempRoutingLine);
        CurrPage.RoutingLinesPart.Page.SetTemporaryRecords(TempRoutingLine);

        SelectedRoutingNo := TempRoutingLine."Routing No.";
        SelectedRoutingVersion := TempRoutingLine."Version Code";
    end;

    local procedure SetProdOrderDataReference()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
    begin
        SubcTempDataInitializer.GetGlobalProdOrderComponent(TempProdOrderComponent);
        CurrPage.ComponentsPart.Page.SetTemporaryRecords(TempProdOrderComponent);
        SubcTempDataInitializer.GetGlobalProdOrderRoutingLine(TempProdOrderRoutingLine);
        CurrPage.ProdOrderRoutingPart.Page.SetTemporaryRecords(TempProdOrderRoutingLine);
    end;

    local procedure SetBOMRoutingEditable()
    begin
        EditBOMLines := not SubcVersionMgmt.CheckBOMExists(SelectedBOMNo, SelectedBOMVersion) and (BOMRoutingShowEditType = BOMRoutingShowEditType::Edit);
        EditRoutingLines := not SubcVersionMgmt.CheckRoutingExists(SelectedRoutingNo, SelectedRoutingVersion) and (BOMRoutingShowEditType = BOMRoutingShowEditType::Edit);

        CreateBOMVersionVisible := SubcVersionMgmt.CheckBOMExists(SelectedBOMNo, '') and (BOMRoutingShowEditType = BOMRoutingShowEditType::Edit);
        CreateRoutingVersionVisible := SubcVersionMgmt.CheckRoutingExists(SelectedRoutingNo, '') and (BOMRoutingShowEditType = BOMRoutingShowEditType::Edit);
    end;

    local procedure SetShowEditOptionsEnabled()
    var
        SubcManagementSetup: Record "Subc. Management Setup";
    begin
        SubcManagementSetup.SetLoadFields(AllowEditUISelection);
        SubcManagementSetup.Get();
        ShowEditOptionsEnabled := SubcManagementSetup.AllowEditUISelection;
    end;

    local procedure SetProdOrderPresetValuesInSubpages()
    var
        PresetBOMValues, PresetRoutingValues : Boolean;
    begin
        PresetBOMValues := not SubcVersionMgmt.CheckBOMExists(SelectedBOMNo, '');
        PresetRoutingValues := not SubcVersionMgmt.CheckRoutingExists(SelectedRoutingNo, '');
        CurrPage.ComponentsPart.Page.SetPresetSubValues(PresetBOMValues);
        CurrPage.ProdOrderRoutingPart.Page.SetPresetSubValues(PresetRoutingValues);
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then begin
            Step := Step - 1;

            if (Step = Step::ProdRouting) and (ProdCompRoutingShowEditType = ProdCompRoutingShowEditType::Hide) then
                Step := Step::Routing;
            if (Step = Step::Components) and (ProdCompRoutingShowEditType = ProdCompRoutingShowEditType::Hide) then
                Step := Step::Routing;
            if (Step = Step::Routing) and (BOMRoutingShowEditType = BOMRoutingShowEditType::Hide) then
                Step := Step::Intro;
            if (Step = Step::BOM) and (BOMRoutingShowEditType = BOMRoutingShowEditType::Hide) then
                Step := Step::Intro;

        end else begin
            Step := Step + 1;

            if (Step = Step::BOM) and (BOMRoutingShowEditType = BOMRoutingShowEditType::Hide) then
                Step := Step::Components;
            if (Step = Step::Routing) and (BOMRoutingShowEditType = BOMRoutingShowEditType::Hide) then
                Step := Step::Components;

            case Step of
                Step::Components:
                    begin
                        SubcTempDataInitializer.BuildTemporaryStructureFromBOMRouting();
                        SetProdOrderPresetValuesInSubpages();
                    end;
            end;
        end;

        if Step < Step::Intro then
            Step := Step::Intro;
        if Step > Step::ProdRouting then
            Step := Step::ProdRouting;

        EnableControls();
    end;

    local procedure EnableControls()
    begin
        ResetControls();

        case Step of
            Step::Intro:
                ShowIntroStep();
            Step::BOM:
                ShowBOMStep();
            Step::Routing:
                ShowRoutingStep();
            Step::Components:
                ShowComponentsStep();
            Step::ProdRouting:
                ShowProdRoutingStep();
        end;
    end;

    local procedure ResetControls()
    begin
        IntroStepVisible := false;
        BOMStepVisible := false;
        RoutingStepVisible := false;
        ComponentsStepVisible := false;
        ProdRoutingStepVisible := false;

        BackActionEnabled := true;
        NextActionEnabled := true;
        FinishActionEnabled := false;
    end;

    local procedure ShowIntroStep()
    begin
        IntroStepVisible := true;
        BackActionEnabled := false;
    end;

    local procedure ShowBOMStep()
    begin
        BOMStepVisible := true;
    end;

    local procedure ShowRoutingStep()
    begin
        RoutingStepVisible := true;
        if (ProdCompRoutingShowEditType = ProdCompRoutingShowEditType::Hide) then begin
            NextActionEnabled := false;
            FinishActionEnabled := true;
        end;
    end;

    local procedure ShowComponentsStep()
    begin
        ComponentsStepVisible := true;
    end;

    local procedure ShowProdRoutingStep()
    begin
        ProdRoutingStepVisible := true;
        NextActionEnabled := false;
        FinishActionEnabled := true;
    end;

    local procedure FinishAction()
    begin
        Finished := true;
        CurrPage.SetSelectionFilter(Rec);
        CurrPage.Close();
    end;

    local procedure InitBomRoutingSource()
    var
        SetupSourceLbl: Label 'Subcontracting Management Setup';
    begin
        BomRtngFromSource := SubcTempDataInitializer.GetRtngBOMSourceType();
        case BomRtngFromSource of
            "Subc. RtngBOMSourceType"::Empty:
                BomRtngFromSourceTxt := SetupSourceLbl;
            else
                BomRtngFromSourceTxt := Format(BomRtngFromSource);
        end;
    end;
}
