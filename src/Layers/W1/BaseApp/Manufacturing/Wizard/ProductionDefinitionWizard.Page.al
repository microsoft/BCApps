// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Wizard;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using System.Environment;
using System.Utilities;

page 99001021 "Production Definition Wizard"
{
    ApplicationArea = Manufacturing;
    Caption = 'Production Definition Wizard';
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
                    Caption = 'Welcome to the Production Definition Wizard';
                    group(IntroductionGroup)
                    {
                        InstructionalText = 'This wizard helps you select and configure the BOM and Routing for your production. You can choose which BOM and Routing to use, and preview the components and operations before finishing.';
                        ShowCaption = false;
                    }
                }
                group(GeneralGroup)
                {
                    Caption = 'General';
                    field("No."; Rec."No.")
                    {
                        Caption = 'Item No.';
                        Editable = false;
                        ToolTip = 'Specifies the item number for which production is being defined.';
                    }
                    field(Description; Rec.Description)
                    {
                        Caption = 'Description';
                        Editable = false;
                        ToolTip = 'Specifies the description of the item.';
                    }
                    group(BomRoutingTransferGroup)
                    {
                        Caption = 'BOM / Routing Details';
                        field(BOMRtngFromSourceField; BOMRoutingFromSourceTxt)
                        {
                            Caption = 'Source';
                            Editable = false;
                            ToolTip = 'Specifies the source from which BOM and Routing data was retrieved.';
                        }
                        field(SaveBOMRoutingField; SaveBOMRouting)
                        {
                            Caption = 'Save';
                            ToolTip = 'Specifies whether to apply the selected BOM and Routing back to the source record.';

                            trigger OnValidate()
                            begin
                                if not SaveBOMRouting then begin
                                    Clear(BOMRoutingSaveTarget);
                                    exit;
                                end;

                                SetBOMRoutingSourceDependingOnSourceType();
                                if BOMRoutingSaveTarget = BOMRoutingSaveTarget::Empty then
                                    if BOMRoutingFromSource = BOMRoutingFromSource::StockkeepingUnit then
                                        BOMRoutingSaveTarget := BOMRoutingSaveTarget::StockkeepingUnit
                                    else
                                        BOMRoutingSaveTarget := BOMRoutingSaveTarget::Item;
                            end;
                        }
                        field(SaveBOMRtngToSourceField; BOMRoutingSaveTarget)
                        {
                            Caption = 'Save in';
                            Editable = SaveBOMRouting;
                            ToolTip = 'Specifies where to apply the BOM and Routing changes (Item or Stockkeeping Unit).';

                            trigger OnValidate()
                            var
                                GlobalSource: Enum "Prod. Definition Source";
                            begin
                                if SaveBOMRouting and (BOMRoutingSaveTarget = BOMRoutingSaveTarget::Empty) then
                                    Error(SaveBOMRtngSourceNotEmptyErr);
                                GlobalSource := TempData.GetGlobalSourceType();
                                if (GlobalSource = BOMRoutingFromSource::Item) and (BOMRoutingSaveTarget = BOMRoutingSaveTarget::StockkeepingUnit) then
                                    Error(SaveBOMRtngSKUNotAllowedErr);
                            end;
                        }
                    }
                }
                group(ShowEditOptionsGroup)
                {
                    Caption = 'Step Configuration';
                    Enabled = ShowEditOptionsEnabled;

                    field(BOMRoutingDisplayField; BOMRoutingDisplay)
                    {
                        Caption = 'BOM/Routing';
                        ToolTip = 'Specifies the display and editing behavior for BOM and Routing selection steps. Hide: Skip steps. Show: View only. Edit: Full editing.';

                        trigger OnValidate()
                        begin
                            SetBOMRoutingEditable();
                        end;
                    }
                    field(ProdCompDisplayField; ProdComponentDisplay)
                    {
                        Caption = 'Prod. Components/Prod. Operations';
                        ToolTip = 'Specifies the display and editing behavior for Production Order Components and Routing preview steps. Hide: Skip steps. Show: View only. Edit: Full editing.';
                    }
                }
            }
            // Step 2: BOM Selection
            group(BOMStep)
            {
                ShowCaption = false;
                Visible = BOMStepVisible;

                group(BOMSelectionGroup)
                {
                    Caption = 'Production BOM Selection';
                    InstructionalText = 'Select the Production BOM and version to use.';

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
                        field(CreateBOMVersionField; CreateBOMVersion)
                        {
                            Caption = 'Create New BOM Version';
                            ToolTip = 'Specifies whether to create a new version of the Production BOM with an automatically generated version number.';

                            trigger OnValidate()
                            begin
                                if CreateBOMVersion then begin
                                    SelectedBOMVersion := 'TEMP-VERSION-' + CopyStr(Format(CreateGuid()), 2, 7);
                                    ProdDefinitionVersionMgmt.ValidateBOMVersionNoSeries(SelectedBOMNo);
                                end else begin
                                    SelectedBOMVersion := '';
                                    LoadBOMLines();
                                end;
                                SetBOMRoutingEditable();
                                TempData.UpdateBOMVersionCode(SelectedBOMVersion);
                            end;
                        }
                    }
                    field(ProductionBOMNoField; SelectedBOMNo)
                    {
                        Caption = 'Production BOM No.';
                        Editable = false;
                        ToolTip = 'Specifies the Production BOM to use.';

                        trigger OnAssistEdit()
                        var
                            NewBOMNo: Code[20];
                        begin
                            NewBOMNo := SelectedBOMNo;
                            if ProdDefinitionVersionMgmt.ShowBOMSelection(NewBOMNo) then
                                if NewBOMNo <> SelectedBOMNo then begin
                                    SelectedBOMNo := NewBOMNo;
                                    SelectedBOMVersion := '';
                                    CreateBOMVersion := false;
                                    LoadBOMLines();
                                    SetBOMRoutingEditable();
                                end;
                        end;
                    }
                    field(SelectedBOMVersionField; SelectedBOMVersion)
                    {
                        Caption = 'Selected BOM Version';
                        Editable = false;
                        ToolTip = 'Specifies the version of the Production BOM to use.';

                        trigger OnAssistEdit()
                        begin
                            if ProdDefinitionVersionMgmt.ShowBOMVersionSelection(SelectedBOMNo, SelectedBOMVersion) then begin
                                CreateBOMVersion := false;
                                SetBOMRoutingEditable();
                                TempData.UpdateBOMVersionCode(SelectedBOMVersion);
                                LoadBOMLines();
                            end;
                        end;
                    }
                    part(BOMLinesPart; "Temp BOM Lines")
                    {
                        Caption = 'Production BOM Lines';
                        Enabled = EditBOMLines;

                    }
                }
            }
            // Step 3: Routing Selection
            group(RoutingStep)
            {
                ShowCaption = false;
                Visible = RoutingStepVisible;

                group(RoutingSelectionGroup)
                {
                    Caption = 'Routing Selection';
                    InstructionalText = 'Select the Routing and version to use.';

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
                        field(CreateRoutingVersionField; CreateRoutingVersion)
                        {
                            Caption = 'Create New Routing Version';
                            ToolTip = 'Specifies whether to create a new version of the Routing with an automatically generated version number.';

                            trigger OnValidate()
                            begin
                                if CreateRoutingVersion then begin
                                    SelectedRoutingVersion := 'TEMP-VER-' + CopyStr(Format(CreateGuid()), 2, 7);
                                    ProdDefinitionVersionMgmt.ValidateRoutingVersionNoSeries(SelectedRoutingNo);
                                end else begin
                                    SelectedRoutingVersion := '';
                                    LoadRoutingLines();
                                end;
                                SetBOMRoutingEditable();
                                TempData.UpdateRoutingVersionCode(SelectedRoutingVersion);
                            end;
                        }
                    }
                    field(RoutingNoField; SelectedRoutingNo)
                    {
                        Caption = 'Routing No.';
                        Editable = false;
                        ToolTip = 'Specifies the Routing to use.';

                        trigger OnAssistEdit()
                        var
                            NewRoutingNo: Code[20];
                        begin
                            NewRoutingNo := SelectedRoutingNo;
                            if ProdDefinitionVersionMgmt.ShowRoutingSelection(NewRoutingNo) then
                                if NewRoutingNo <> SelectedRoutingNo then begin
                                    SelectedRoutingNo := NewRoutingNo;
                                    SelectedRoutingVersion := '';
                                    CreateRoutingVersion := false;
                                    LoadRoutingLines();
                                    SetBOMRoutingEditable();
                                end;
                        end;
                    }
                    field(SelectedRoutingVersionField; SelectedRoutingVersion)
                    {
                        Caption = 'Selected Routing Version';
                        Editable = false;
                        ToolTip = 'Specifies the version of the Routing to use.';

                        trigger OnAssistEdit()
                        begin
                            if ProdDefinitionVersionMgmt.ShowRoutingVersionSelection(SelectedRoutingNo, SelectedRoutingVersion) then
                                LoadRoutingLines();
                        end;
                    }
                    part(RoutingLinesPart; "Temp Routing Lines")
                    {
                        Caption = 'Routing Lines';
                        Enabled = EditRoutingLines;
                    }
                }
            }
            // Step 4: Components Preview (CreateProductionOrder mode only)
            group(ComponentsStep)
            {
                ShowCaption = false;
                Visible = ComponentsStepVisible;

                group(ComponentsPreviewGroup)
                {
                    Caption = 'Components Preview';
                    InstructionalText = 'Review and edit the components that will be created for the production order.';

                    part(ComponentsPart; "Temp Prod. Order Comp. List")
                    {
                        Caption = 'Components';
                        Editable = ProdComponentDisplay = ProdComponentDisplay::Edit;
                    }
                }
            }
            // Step 5: Production Routing Preview (CreateProductionOrder mode only)
            group(ProdRoutingStep)
            {
                ShowCaption = false;
                Visible = ProdRoutingStepVisible;

                group(ProdRoutingPreviewGroup)
                {
                    Caption = 'Production Order Routing Preview';
                    InstructionalText = 'Review and edit the routing operations that will be created for the production order.';

                    part(ProdOrderRoutingPart; "Temp Prod. Ord. Rtng List")
                    {
                        Caption = 'Prod. Order Routing Lines';
                        Editable = ProdComponentDisplay = ProdComponentDisplay::Edit;
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
                    GoBack();
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
                    GoForward();
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
        BackActionEnabled: Boolean;
        FinishActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        ShowEditOptionsEnabled: Boolean;
        BOMStepVisible: Boolean;
        ComponentsStepVisible: Boolean;
        IntroStepVisible: Boolean;
        ProdRoutingStepVisible: Boolean;
        RoutingStepVisible: Boolean;
        TopBannerVisible: Boolean;
        CreateBOMVersion: Boolean;
        CreateRoutingVersion: Boolean;
        CreateBOMVersionVisible: Boolean;
        CreateRoutingVersionVisible: Boolean;
        EditBOMLines: Boolean;
        EditRoutingLines: Boolean;
        SaveBOMRouting: Boolean;
        SelectedBOMNo: Code[20];
        SelectedBOMVersion: Code[20];
        SelectedRoutingNo: Code[20];
        SelectedRoutingVersion: Code[20];
        BOMRoutingSaveTarget: Enum "Prod. Definition Save Target";
        BOMRoutingDisplay: Enum "Prod. Definition Display";
        ProdComponentDisplay: Enum "Prod. Definition Display";
        Step: Option Intro,BOM,Routing,Components,ProdRouting;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        TempData: Codeunit "Prod. Definition Temp Data";
        ProdDefinitionVersionMgmt: Codeunit "Prod. Definition Version Mgmt.";
        Finished: Boolean;
        BOMRoutingFromSource: Enum "Prod. Definition Source";
        BOMRoutingFromSourceTxt: Text;
        WizardMode: Enum "Prod. Definition Mode";
        NewVersionIntroductionLbl: Label 'Turn on "Create New Version" to make the lines below editable. Note that existing versions cannot be modified — the wizard always creates a new version. It assigns a temporary version code and lets you modify the lines freely. When you finish the wizard and the changes are saved, the temporary code is replaced by a number from the version number series and the version is certified automatically.';
        SaveBOMRtngSourceNotEmptyErr: Label 'Please select a valid source for saving BOM and Routing changes.';
        SaveBOMRtngSKUNotAllowedErr: Label 'Stockkeeping Unit is not allowed when the source is Item.';

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
    /// Sets the item record that the wizard operates on.
    /// </summary>
    /// <param name="Item">The item to bind the wizard page to.</param>
    internal procedure SetItem(Item: Record Item)
    begin
        Rec.Reset();
        Rec.DeleteAll();
        Rec := Item;
        Rec.Insert();
    end;

    /// <summary>
    /// Sets the display mode for the BOM and routing section of the wizard.
    /// </summary>
    /// <param name="DisplayType">The display type controlling which BOM/routing tab is shown.</param>
    internal procedure SetBOMRoutingDisplay(DisplayType: Enum "Prod. Definition Display")
    begin
        BOMRoutingDisplay := DisplayType;
    end;

    /// <summary>
    /// Sets the display mode for the production order components section of the wizard.
    /// </summary>
    /// <param name="DisplayType">The display type controlling which component tab is shown.</param>
    internal procedure SetProdCompDisplay(DisplayType: Enum "Prod. Definition Display")
    begin
        ProdComponentDisplay := DisplayType;
    end;

    /// <summary>
    /// Injects the temporary data codeunit that the wizard uses for BOM, routing, and production order data.
    /// </summary>
    /// <param name="NewTempData">The temporary data codeunit to use.</param>
    internal procedure SetTempData(var NewTempData: Codeunit "Prod. Definition Temp Data")
    begin
        TempData := NewTempData;
    end;

    /// <summary>
    /// Sets the operating mode of the wizard (e.g., define item structure or create production order).
    /// </summary>
    /// <param name="Mode">The wizard mode to apply.</param>
    internal procedure SetWizardMode(Mode: Enum "Prod. Definition Mode")
    begin
        WizardMode := Mode;
    end;

    /// <summary>
    /// Returns the user's choice for where to apply the BOM and routing changes.
    /// </summary>
    /// <returns>The source type selected by the user indicating where to save BOM/routing changes.</returns>
    internal procedure GetBOMRtngSaveTarget(): Enum "Prod. Definition Save Target"
    begin
        exit(BOMRoutingSaveTarget);
    end;

    /// <summary>
    /// Returns whether the wizard has been completed by the user.
    /// </summary>
    /// <returns>True if the user finished the wizard; otherwise false.</returns>
    internal procedure GetFinished(): Boolean
    begin
        exit(Finished);
    end;

    local procedure LoadBOMLines()
    begin
        if SelectedBOMNo = '' then
            exit;
        if not ProdDefinitionVersionMgmt.CheckBOMExists(SelectedBOMNo, SelectedBOMVersion) then
            exit;
        TempData.LoadBOMLines(SelectedBOMNo, SelectedBOMVersion);
    end;

    local procedure LoadRoutingLines()
    begin
        if SelectedRoutingNo = '' then
            exit;
        if not ProdDefinitionVersionMgmt.CheckRoutingExists(SelectedRoutingNo, SelectedRoutingVersion) then
            exit;
        TempData.LoadRoutingLines(SelectedRoutingNo, SelectedRoutingVersion);
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(CurrentClientType())) then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") then
                TopBannerVisible := MediaResourcesStandard."Media Reference".HasValue();
    end;

    local procedure SetBOMDataReference()
    var
        TempBOMLines: Record "Production BOM Line" temporary;
    begin
        TempData.GetGlobalBOMLines(TempBOMLines);
        CurrPage.BOMLinesPart.Page.SetTemporaryRecords(TempBOMLines);
        if TempBOMLines.FindFirst() then begin
            SelectedBOMNo := TempBOMLines."Production BOM No.";
            SelectedBOMVersion := TempBOMLines."Version Code";
        end;
    end;

    local procedure SetRoutingDataReference()
    var
        TempRoutingLine: Record "Routing Line" temporary;
    begin
        TempData.GetGlobalRoutingLines(TempRoutingLine);
        CurrPage.RoutingLinesPart.Page.SetTemporaryRecords(TempRoutingLine);
        if TempRoutingLine.FindFirst() then begin
            SelectedRoutingNo := TempRoutingLine."Routing No.";
            SelectedRoutingVersion := TempRoutingLine."Version Code";
        end;
    end;

    local procedure SetProdOrderDataReference()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
    begin
        TempData.GetGlobalProdOrderComponent(TempProdOrderComponent);
        CurrPage.ComponentsPart.Page.SetTempProdOrderComponent(TempProdOrderComponent);
        TempData.GetGlobalProdOrderRoutingLine(TempProdOrderRoutingLine);
        CurrPage.ProdOrderRoutingPart.Page.SetTempProdOrdRtngLine(TempProdOrderRoutingLine);
    end;

    local procedure SetBOMRoutingEditable()
    begin
        EditBOMLines := not ProdDefinitionVersionMgmt.CheckBOMExists(SelectedBOMNo, SelectedBOMVersion) and
                        (BOMRoutingDisplay = BOMRoutingDisplay::Edit);
        EditRoutingLines := not ProdDefinitionVersionMgmt.CheckRoutingExists(SelectedRoutingNo, SelectedRoutingVersion) and
                            (BOMRoutingDisplay = BOMRoutingDisplay::Edit);
        CreateBOMVersionVisible := ProdDefinitionVersionMgmt.CheckBOMExists(SelectedBOMNo, '') and
                                   (BOMRoutingDisplay = BOMRoutingDisplay::Edit);
        CreateRoutingVersionVisible := ProdDefinitionVersionMgmt.CheckRoutingExists(SelectedRoutingNo, '') and
                                       (BOMRoutingDisplay = BOMRoutingDisplay::Edit);
    end;

    local procedure SetShowEditOptionsEnabled()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.SetLoadFields("Allow Edit UI Selection");
        ManufacturingSetup.Get();
        ShowEditOptionsEnabled := ManufacturingSetup."Allow Edit UI Selection";
    end;

    local procedure IsCreateProductionOrderMode(): Boolean
    begin
        exit(WizardMode = WizardMode::CreateProductionOrder);
    end;

    local procedure GoBack()
    begin
        NextStep(true);
    end;

    local procedure GoForward()
    begin
        NextStep(false);
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        repeat
            if Backwards then
                Step := Step - 1
            else
                Step := Step + 1;

            if Step < Step::Intro then begin
                Step := Step::Intro;
                break;
            end;
            if Step > Step::ProdRouting then begin
                Step := Step::ProdRouting;
                break;
            end;
        until not IsStepHidden(Step);

        if not Backwards and (Step = Step::Components) then
            TempData.BuildTemporaryStructureFromBOMRouting();

        EnableControls();
    end;

    local procedure IsStepHidden(CurrentStep: Option): Boolean
    begin
        case CurrentStep of
            Step::BOM, Step::Routing:
                exit(BOMRoutingDisplay = BOMRoutingDisplay::Hide);
            Step::Components, Step::ProdRouting:
                exit((ProdComponentDisplay = ProdComponentDisplay::Hide) or not IsCreateProductionOrderMode());
        end;
        exit(false);
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
        if (BOMRoutingDisplay = BOMRoutingDisplay::Hide) and
           (not IsCreateProductionOrderMode() or (ProdComponentDisplay = ProdComponentDisplay::Hide)) then begin
            NextActionEnabled := false;
            FinishActionEnabled := true;
        end;
    end;

    local procedure ShowBOMStep()
    begin
        BOMStepVisible := true;
    end;

    local procedure ShowRoutingStep()
    begin
        RoutingStepVisible := true;
        if not IsCreateProductionOrderMode() or (ProdComponentDisplay = ProdComponentDisplay::Hide) then begin
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
    var
        SaveTargetRequiredErr: Label 'Please select a target for saving BOM and Routing changes (Item or Stockkeeping Unit) before finishing.';
    begin
        if SaveBOMRouting and (BOMRoutingSaveTarget = BOMRoutingSaveTarget::Empty) then
            Error(SaveTargetRequiredErr);
        Finished := true;
        CurrPage.Close();
    end;

    local procedure InitBomRoutingSource()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        GlobalSource: Enum "Prod. Definition Source";
    begin
        BOMRoutingFromSource := TempData.GetRtngBOMSourceType();
        if BOMRoutingFromSource = BOMRoutingFromSource::Empty then
            BOMRoutingFromSourceTxt := ManufacturingSetup.TableCaption()
        else
            BOMRoutingFromSourceTxt := Format(BOMRoutingFromSource);

        GlobalSource := TempData.GetGlobalSourceType();
        case GlobalSource of
            GlobalSource::Item:
                begin
                    SaveBOMRouting := true;
                    BOMRoutingSaveTarget := BOMRoutingSaveTarget::Item;
                end;
            GlobalSource::StockkeepingUnit:
                begin
                    SaveBOMRouting := true;
                    BOMRoutingSaveTarget := BOMRoutingSaveTarget::StockkeepingUnit;
                end;
        end;
    end;

    local procedure SetBOMRoutingSourceDependingOnSourceType()
    var
        GlobalSource: Enum "Prod. Definition Source";
    begin
        GlobalSource := TempData.GetGlobalSourceType();
        case GlobalSource of
            GlobalSource::Item:
                BOMRoutingSaveTarget := BOMRoutingSaveTarget::Item;
            GlobalSource::StockkeepingUnit:
                BOMRoutingSaveTarget := BOMRoutingSaveTarget::StockkeepingUnit;
        end;
    end;
}