// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.AccessControl;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using System.Utilities;

report 20400 "Qlty. Create Inspection Test"
{
    Caption = 'Create Quality Inspection Test';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    Permissions =
        tabledata "Qlty. Inspection Test Header" = Rim,
        tabledata "Qlty. Inspection Test Line" = Rim;

    dataset
    {
        dataitem(CurrentProcessing; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                CreateQltyInspectionTest();
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(DidYouKnow)
                {
                    Caption = 'Did you know';
                    InstructionalText = 'Did you know that you can create tests from many subforms in Business Central already? You can create tests from the output journal, production order routing lines, consumption journal, purchase order sub form, sales return subform, and item tracking lines. You can also use power automate or easily extend existing pages to create tests.';
                }
                group(Parameters)
                {
                    Caption = 'Parameters';
                    field(ChooseQITemplateCode; QltInspectionTemplateToCreate)
                    {
                        ApplicationArea = All;
                        Caption = 'Template Code';
                        Tooltip = 'Specifies which Quality Inspection Template to create.';
                        ShowMandatory = true;
                        trigger OnLookup(var Text: Text): Boolean
                        var
                            QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
                        begin
                            if Page.RunModal(0, QltyInspectionTemplateHdr) = Action::LookupOK then
                                QltInspectionTemplateToCreate := QltyInspectionTemplateHdr.Code;
                        end;
                    }
                    field(ChooseSource; SourceTable)
                    {
                        ApplicationArea = All;
                        Caption = 'Source';
                        ToolTip = 'Specifies a reference to which source should be used.';
                        ShowMandatory = true;
                        trigger OnLookup(var Text: Text): Boolean
                        var
                            QltyInspectSourceConfigList: Page "Qlty. Ins. Source Config. List";
                            OldTableNo: Integer;
                        begin
                            OldTableNo := QltyInspectSourceConfig."From Table No.";
                            QltyInspectSourceConfig.Reset();
                            QltyInspectSourceConfig.FilterGroup(20);
                            QltyInspectSourceConfig.SetFilter(Code, '<>%1', '');
                            QltyInspectSourceConfig.SetRange(Enabled, true);
                            QltyInspectSourceConfig.FilterGroup(0);
                            QltyGenerationRuleMgmt.SetFilterToApplicableTemplates(QltInspectionTemplateToCreate, QltyInspectSourceConfig);
                            QltyInspectSourceConfigList.LookupMode(true);
                            QltyInspectSourceConfigList.SetTableView(QltyInspectSourceConfig);
                            if QltyInspectSourceConfigList.RunModal() = Action::LookupOK then begin
                                QltyInspectSourceConfigList.GetRecord(QltyInspectSourceConfig);
                                SourceTable := QltyInspectSourceConfig.Code;
                                if QltyInspectSourceConfig."From Table No." <> OldTableNo then
                                    ClearParameters();
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            ClearParameters();
                        end;
                    }
                    field(ChooseTableNo; QltyInspectSourceConfig."From Table No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Table No.';
                        Tooltip = 'Specifies which table this references.';
                        Editable = false;
                        Visible = false;
                        Importance = Additional;
                    }
                    field(ChooseGetRecord; Format(Target))
                    {
                        ApplicationArea = All;
                        Caption = 'Choose Record';
                        Tooltip = 'Specifies which record you want to create a Quality Inspection Test for.';
                        Visible = VisibleGetRecord;
                        ShowMandatory = true;
                        AssistEdit = true;

                        trigger OnAssistEdit()
                        begin
                            AssistEditChooseRecord();
                        end;
                    }
                    field(ChooseItemNo; TempQltyInspectionTestHeader."Source Item No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Item No.';
                        ToolTip = 'Specifies the Item No.';
                        Editable = false;
                    }
                    field(ChooseSerialNo; TempQltyInspectionTestHeader."Source Serial No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Serial No.';
                        ToolTip = 'Specifies the Serial No.';
                        Editable = EditSerialNo;
                        Visible = VisibleSerialNo;

                        trigger OnAssistEdit()
                        begin
                            TempQltyInspectionTestHeader.AssistEditSerialNo();
                        end;
                    }
                    field(ChooseLotNo; TempQltyInspectionTestHeader."Source Lot No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Lot No.';
                        ToolTip = 'Specifies the Lot No.';
                        Editable = EditLotNo;
                        Visible = VisibleLotNo;

                        trigger OnAssistEdit()
                        begin
                            TempQltyInspectionTestHeader.AssistEditLotNo();
                        end;
                    }
                    field(ChoosePackageNo; TempQltyInspectionTestHeader."Source Package No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Package No.';
                        ToolTip = 'Specifies the Package No.';
                        Editable = EditPackageNo;
                        Visible = VisiblePackageNo;

                        trigger OnAssistEdit()
                        begin
                            TempQltyInspectionTestHeader.AssistEditPackageNo();
                        end;
                    }
                    field(ChooseSourceQuantity; TempQltyInspectionTestHeader."Source Quantity (Base)")
                    {
                        ApplicationArea = All;
                        Caption = 'Source Quantity (base)';
                        ToolTip = 'Specifies the lot size used to create the test with.';
                        AutoFormatType = 0;
                        DecimalPlaces = 0 : 5;
                        Editable = EditSourceQuantity;
                        Visible = VisibleSourceQuantity;

                        trigger OnValidate()
                        begin
                            DidChangeSourceQuantity := true;
                        end;
                    }
                }
            }
        }

        trigger OnInit()
        begin
            SetRequestPageControlVisibility();
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        var
            QltInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
            NullCheckRecordId: RecordId;
        begin
            if CloseAction = CloseAction::OK then begin
                if not QltInspectionTemplateHdr.Get(QltInspectionTemplateToCreate) then
                    Error(NotAValidQltyInspectionTemplateErr, QltInspectionTemplateToCreate);

                if (NullCheckRecordId = Target) or (Target.TableNo = 0) then
                    Error(PleaseChooseARecordFirstErr);
            end;
        end;
    }

    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        QltyGenerationRuleMgmt: Codeunit "Qlty. Generation Rule Mgmt.";
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
        Target: RecordId;
        TargetRecordRef: RecordRef;
        QltInspectionTemplateToCreate: Code[20];
        VariantForRecordRef: Variant;
        SourceTable: Code[20];
        CustomFilter: Text;
        VisibleSerialNo: Boolean;
        VisibleLotNo: Boolean;
        VisiblePackageNo: Boolean;
        VisibleGetRecord: Boolean;
        EditSerialNo: Boolean;
        EditLotNo: Boolean;
        EditPackageNo: Boolean;
        EditSourceQuantity: Boolean;
        VisibleSourceQuantity: Boolean;
        DidChangeSourceQuantity: Boolean;
        NotAValidQltyInspectionTemplateErr: Label '''%1'' is not a valid Quality Inspection Template. Please re-configure the available Quality Inspection Templates.', Comment = '%1=The template that was expected';
        PleaseChooseARecordFirstErr: Label 'Choose which record you want to create a Quality Inspection Test for, then try again.';

    trigger OnPreReport()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
    begin
        if not QltyInspectionTemplateHdr.Get(QltInspectionTemplateToCreate) then
            Error(NotAValidQltyInspectionTemplateErr, QltInspectionTemplateToCreate);
    end;

    /// <summary>
    /// InitializeReportParameters can be used to specify a specific desired quality inspection template code
    /// to create the test from.
    /// Use this if you're using this report to let the user decide what kind of test they want, and just want 
    /// to express a preference.   This will not limit them to this template, it just sets the default.
    /// This will also fire OnAfterInitializeCreateTestReportParameters
    /// </summary>
    /// <param name="QltyInspectionTemplateCode">Code[20]. The quality inspection template code to default to.</param>
    procedure InitializeReportParameters(QltyInspectionTemplateCode: Code[20])
    var
        TempCompatibleQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary;
    begin
        QltInspectionTemplateToCreate := QltyInspectionTemplateCode;
        OnAfterInitializeCreateTestReportParameters(QltInspectionTemplateToCreate, SourceTable, CustomFilter, Target, TargetRecordRef, TempQltyInspectionTestHeader);

        if (QltyInspectionTemplateCode <> '') and (SourceTable = '') then begin
            QltyInspectSourceConfig.Reset();
            if QltyGenerationRuleMgmt.FindAllCompatibleGenerationRules(QltInspectionTemplateToCreate, TempCompatibleQltyInTestGenerationRule) then begin
                QltyInspectSourceConfig.SetRange("To Type", QltyInspectSourceConfig."To Type"::Test);
                QltyInspectSourceConfig.SetRange(Enabled, true);
                if TempCompatibleQltyInTestGenerationRule.FindSet() then
                    repeat
                        QltyInspectSourceConfig.SetRange("From Table No.", TempCompatibleQltyInTestGenerationRule."Source Table No.");
                        if QltyInspectSourceConfig.FindFirst() then
                            SourceTable := QltyInspectSourceConfig.Code;
                    until (TempCompatibleQltyInTestGenerationRule.Next() = 0) or (SourceTable <> '');

                if SourceTable = '' then begin
                    QltyInspectSourceConfig.Reset();
                    QltyGenerationRuleMgmt.SetFilterToApplicableTemplates(QltInspectionTemplateToCreate, QltyInspectSourceConfig);
                    QltyInspectSourceConfig.SetRange(Enabled, true);
                    if QltyInspectSourceConfig.FindFirst() then
                        SourceTable := QltyInspectSourceConfig.Code;
                end;
            end;
        end;
        SetRequestPageControlVisibility();
    end;

    local procedure ClearParameters()
    begin
        Clear(TempQltyInspectionTestHeader);
        Clear(CustomFilter);
        Clear(Target);
    end;

    local procedure ClearVariables()
    begin
        Clear(TargetRecordRef);
        Clear(VariantForRecordRef);
    end;

    local procedure SetRequestPageControlVisibility()
    begin
        VisibleSerialNo := true;
        VisibleLotNo := true;
        VisiblePackageNo := true;
        VisibleGetRecord := true;
    end;

    local procedure CreateQltyInspectionTest()
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        NullCheckRecordId: RecordId;
        Dummy3Variant: Variant;
        Dummy4Variant: Variant;
    begin
        if ((NullCheckRecordId = Target) or (Target.TableNo = 0)) then
            Error(PleaseChooseARecordFirstErr);

        TargetRecordRef := Target.GetRecord();

        TargetRecordRef.SetRecFilter();
        TargetRecordRef.FindFirst();

        TempTrackingSpecification."Entry No." := 1;
        TempTrackingSpecification."Item No." := TempQltyInspectionTestHeader."Source Item No.";
        TempTrackingSpecification."Variant Code" := TempQltyInspectionTestHeader."Source Variant Code";
        TempTrackingSpecification."Lot No." := TempQltyInspectionTestHeader."Source Lot No.";
        TempTrackingSpecification."Serial No." := TempQltyInspectionTestHeader."Source Serial No.";
        TempTrackingSpecification."Package No." := TempQltyInspectionTestHeader."Source Package No.";
        if DidChangeSourceQuantity then begin
            TempTrackingSpecification."Quantity (Base)" := TempQltyInspectionTestHeader."Source Quantity (Base)";
            TempTrackingSpecification."Qty. to Handle (Base)" := TempQltyInspectionTestHeader."Source Quantity (Base)";
            TempTrackingSpecification."Qty. to Handle" := TempQltyInspectionTestHeader."Source Quantity (Base)";
        end;

        TempTrackingSpecification.Insert(false);

        QltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(TargetRecordRef, TempTrackingSpecification, Dummy3Variant, Dummy4Variant, true, QltInspectionTemplateToCreate);
    end;

    local procedure AssistEditChooseRecord()
    var
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
        QltyTraversal: Codeunit "Qlty. Traversal";
    begin
        if QltyInspectSourceConfig."From Table No." <> 0 then begin
            ClearVariables();

            TargetRecordRef.Open(QltyInspectSourceConfig."From Table No.");
            TargetRecordRef.SetView(QltyInspectSourceConfig."From Table Filter");
            VariantForRecordRef := TargetRecordRef;

            if Page.RunModal(0, VariantForRecordRef) = Action::LookupOK then begin
                ClearParameters();
                TargetRecordRef := VariantForRecordRef;
                Target := TargetRecordRef.RecordId();

                TempQltyInspectionTestHeader.SetIsCreating(true);
                if not QltyTraversal.ApplySourceFields(TargetRecordRef, TempQltyInspectionTestHeader, false, false) then
                    Clear(TempQltyInspectionTestHeader);

                TempItemTrackingSetup."Lot No. Required" := true;
                TempItemTrackingSetup."Serial No. Required" := true;
                TempItemTrackingSetup."Package No. Required" := true;
                TempQltyInspectionTestHeader.IsItemTrackingUsed(TempItemTrackingSetup);
                EditLotNo := TempItemTrackingSetup."Lot No. Required";
                EditSerialNo := TempItemTrackingSetup."Serial No. Required";
                EditPackageNo := TempItemTrackingSetup."Package No. Required";
            end;
            EditSourceQuantity := QltyPermissionMgmt.CanChangeSourceQuantity();
            VisibleSourceQuantity := TempQltyInspectionTestHeader."Source Quantity (Base)" <> 0;

            TargetRecordRef.Close();
            ClearVariables();
        end;
    end;

    /// <summary>
    /// Provides an opportunity to create defaults in the Create Test report page.
    /// </summary>
    /// <param name="QltyInspectionTemplateCode">var Code[20].</param>
    /// <param name="SourceTable">var Code[20].</param>
    /// <param name="CustomFilter">var Text.</param>
    /// <param name="Target">var RecordId.</param>
    /// <param name="TargetRecordRef">var RecordRef.</param>
    /// <param name="TempQltyInspectionTestHeader">var Record "Qlty. Inspection Test Header" temporary.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeCreateTestReportParameters(var QltyInspectionTemplateCode: Code[20]; var SourceTable: Code[20]; var CustomFilter: Text; var Target: RecordId; var TargetRecordRef: RecordRef; var TempQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary)
    begin
    end;
}
