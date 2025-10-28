// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template;

using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;

/// <summary>
/// Generic text template editor.
/// </summary>
page 20440 "Qlty. Inspection Template Edit"
{
    PageType = Card;
    Caption = 'Quality Inspection Template Edit';
    UsageCategory = None;
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    Extensible = true;

    layout
    {
        area(Content)
        {
            group(SettingsForRawHtml)
            {
                ShowCaption = false;
                Caption = ' ';
                Visible = not IsHTMLFormatted;

                field(htmlContent; HtmlContentText)
                {
                    Caption = 'Text';
                    ShowCaption = false;
                    ApplicationArea = All;
                    ToolTip = 'Edit the text template.';
                    MultiLine = true;
                }
            }
            group(SettingsForTestExpressionWithATest)
            {
                Caption = 'Test expression with an existing Quality Inspection Test';
                Visible = ShowAddFieldFromTest;
                field(ChooseTestRecordId; Format(ChooseTestRecordId))
                {
                    ApplicationArea = All;
                    Caption = 'Choose test';
                    ToolTip = 'Specifies an existing test to test the expression with.';
                    Editable = false;

                    trigger OnAssistEdit()
                    var
                        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
                        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
                        QltyTests: Page "Qlty. Inspection Test List";
                    begin
                        QltyInspectionTestHeader.Ascending(false);

                        if QltyInspectionTestHeader.Get(ChooseTestRecordId) then begin
                            QltyTests.SetRecord(QltyInspectionTestHeader);
                            QltyInspectionTestHeader.SetRecFilter();
                            if QltyInspectionTestHeader.FindSet() then;
                            QltyInspectionTestHeader.SetRange("No.");
                        end;
                        if LimitedToTemplateCode <> '' then
                            QltyInspectionTestHeader.SetRange("Template Code", LimitedToTemplateCode);

                        QltyTests.SetTableView(QltyInspectionTestHeader);

                        QltyTests.LookupMode(true);
                        if QltyTests.RunModal() in [Action::LookupOK, Action::OK] then begin
                            QltyTests.GetRecord(QltyInspectionTestHeader);
                            ChooseTestRecordId := QltyInspectionTestHeader.RecordId();
                            Clear(ChooseTestLineChooseTestRecordId);
                            QltyInspectionTestLine.SetRange("Test No.", QltyInspectionTestHeader."No.");
                            QltyInspectionTestLine.SetRange("Retest No.", QltyInspectionTestHeader."Retest No.");
                            if QltyInspectionTestLine.FindFirst() then
                                ChooseTestLineChooseTestRecordId := QltyInspectionTestLine.RecordId();

                            LimitedToTemplateCode := QltyInspectionTestHeader."Template Code";
                        end;
                    end;
                }
                field(ChooseTestLineRecordId; Format(ChooseTestLineChooseTestRecordId))
                {
                    ApplicationArea = All;
                    Caption = 'Choose test line';
                    ToolTip = 'Specifies an existing test line to test the expression with.';
                    Editable = false;

                    trigger OnAssistEdit()
                    var
                        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
                        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
                        LinesQltyTestValues: Page "Qlty. Inspection Test Lines";
                    begin
                        QltyInspectionTestLine.Ascending(false);
                        if not QltyInspectionTestHeader.Get(ChooseTestRecordId) then
                            Error(ChooseAValidTestFirstBeforeChoosingLineErr);
                        QltyInspectionTestLine.SetRange("Test No.", QltyInspectionTestHeader."No.");
                        QltyInspectionTestLine.SetRange("Retest No.", QltyInspectionTestHeader."Retest No.");
                        if QltyInspectionTestLine.Get(ChooseTestLineChooseTestRecordId) then begin
                            LinesQltyTestValues.SetRecord(QltyInspectionTestLine);
                            QltyInspectionTestLine.SetRecFilter();
                            if QltyInspectionTestLine.FindSet() then;
                            QltyInspectionTestLine.SetRange("Field Code");
                            QltyInspectionTestLine.SetRange("Line No.");
                        end;
                        if LimitedToTemplateCode <> '' then
                            QltyInspectionTestLine.SetRange("Template Code", LimitedToTemplateCode);

                        LinesQltyTestValues.SetTableView(QltyInspectionTestLine);

                        LinesQltyTestValues.LookupMode(true);
                        if LinesQltyTestValues.RunModal() in [Action::LookupOK, Action::OK] then begin
                            LinesQltyTestValues.GetRecord(QltyInspectionTestLine);
                            ChooseTestLineChooseTestRecordId := QltyInspectionTestLine.RecordId();
                        end;
                    end;
                }
                field(ChooseClickToTest; 'Click to test expression.')
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    Caption = ' ';
                    Tooltip = ' ';

                    trigger OnDrillDown()
                    var
                        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
                        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
                    begin
                        OutputResult := '';
                        if not QltyInspectionTestHeader.Get(ChooseTestRecordId) then
                            Error(ChooseAValidTestFirstBeforeTestingErr);
                        if not QltyInspectionTestLine.Get(ChooseTestLineChooseTestRecordId) then
                            Clear(QltyInspectionTestLine);
                        OutputResult := QltyExpressionMgmt.EvaluateTextExpression(HtmlContentText, QltyInspectionTestHeader, QltyInspectionTestLine, ShowEmbeddedFormula);
                    end;
                }
                field(ChooseResult; OutputResult)
                {
                    ApplicationArea = All;
                    Caption = 'Output:';
                    ToolTip = 'Specifies the result.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddInspectionField)
            {
                ApplicationArea = All;
                Caption = 'Add Inspection Field';
                Image = TaskQualityMeasure;
                ToolTip = 'Click here to use a Quality Inspection field in this expression.';
                AboutTitle = 'Add inspection field';
                AboutText = 'Click here to use a Quality Inspection field in this expression.';
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    HandleOnAddQltyInspectionField();
                end;
            }
            action(AddField)
            {
                ApplicationArea = All;
                Caption = 'Add Table Field';
                Image = Add;
                ToolTip = 'Click here to insert additional Fields into the template.';
                AboutTitle = 'Add a field from a table.';
                AboutText = 'Click here to insert additional Fields into the template.';
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Visible = ShowAddFieldFromAnyTable;

                trigger OnAction()
                begin
                    HandleOnAddFieldFromTable();
                end;
            }
            action(AddFieldFromTest)
            {
                ApplicationArea = All;
                Caption = 'Add Test Information';
                Image = Add;
                ToolTip = 'Click here to insert additional test fields into the template.';
                AboutTitle = 'Add a field from a quality inspection test.';
                AboutText = 'Click here to insert additional Fields into the template.';
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Visible = ShowAddFieldFromTest;

                trigger OnAction()
                begin
                    HandleOnAddFieldFromTable();
                end;
            }
        }
    }

    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
        ChooseTestRecordId: RecordId;
        ChooseTestLineChooseTestRecordId: RecordId;
        IsHTMLFormatted: Boolean;
        HtmlContentText: Text[500];
        LimitedToTemplateCode: Code[20];
        OptionalNameFilter: Text;
        TableNo: Integer;
        ShowEmbeddedFormula: Boolean;
        ShowAddFieldFromTest: Boolean;
        ShowAddFieldFromAnyTable: Boolean;
        OutputResult: Text;
        ChooseAValidTestFirstBeforeChoosingLineErr: Label 'Please choose a valid existing test before choosing a line.';
        ChooseAValidTestFirstBeforeTestingErr: Label 'Please choose a valid existing test before testing this expression.';

    local procedure HandleOnAddFieldFromTable()
    var
        RecordRefToLookup: RecordRef;
        FieldRefToAdd: FieldRef;
        FieldNo: Integer;
    begin
        FieldNo := QltyFilterHelpers.RunModalLookupAnyField(TableNo, 0, OptionalNameFilter);
        if FieldNo > 0 then begin
            RecordRefToLookup.Open(TableNo);
            FieldRefToAdd := RecordRefToLookup.Field(FieldNo);
            HtmlContentText += '[' + FieldRefToAdd.Name + ']';
        end;
    end;

    procedure RunModalWith(TableNo2: Integer; OptionalNameFilter2: Text; var ExistingTemplate: Text) ResultAction: Action
    begin
        TableNo := TableNo2;
        if TableNo = Database::"Qlty. Inspection Test Header" then
            ShowAddFieldFromTest := true;

        ShowAddFieldFromAnyTable := not ShowAddFieldFromTest;
        OptionalNameFilter := OptionalNameFilter2;
        HtmlContentText := CopyStr(QltyExpressionMgmt.ConvertHTMLBRsToCarriageReturns(ExistingTemplate), 1, MaxStrLen(HtmlContentText));
        ResultAction := CurrPage.RunModal();
        if ResultAction in [ResultAction::OK, ResultAction::LookupOK, ResultAction::Yes] then
            ExistingTemplate := QltyExpressionMgmt.ConvertCarriageReturnsToHTMLBRs(HtmlContentText);
    end;

    local procedure HandleOnAddQltyInspectionField()
    begin
        if LimitedToTemplateCode = '' then
            LookupAnyQltyInspectionField()
        else
            LookupOnlyFieldsInTemplate();
    end;

    local procedure LookupAnyQltyInspectionField()
    var
        QltyField: Record "Qlty. Field";
        QltyFieldLookup: Page "Qlty. Field Lookup";
    begin
        QltyFieldLookup.LookupMode(true);
        QltyFieldLookup.SetRecord(QltyField);
        if QltyFieldLookup.RunModal() in [Action::OK, Action::LookupOK] then begin
            QltyFieldLookup.GetRecord(QltyField);
            HtmlContentText += '[' + QltyField.Code + ']';
        end;
    end;

    local procedure LookupOnlyFieldsInTemplate()
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyField: Record "Qlty. Field";
        QltyFieldLookup: Page "Qlty. Field Lookup";
        FieldFilter: Text;
    begin
        QltyInspectionTemplateLine.SetRange("Template Code", LimitedToTemplateCode);
        if QltyInspectionTemplateLine.FindSet() then
            repeat
                if QltyInspectionTemplateLine."Field Code" <> '' then begin
                    if StrLen(FieldFilter) > 1 then
                        FieldFilter += '|';
                    FieldFilter += QltyInspectionTemplateLine."Field Code";
                end;
            until QltyInspectionTemplateLine.Next() = 0;

        if FieldFilter <> '' then
            QltyField.SetFilter(Code, FieldFilter);
        QltyFieldLookup.LookupMode(true);
        QltyFieldLookup.SetTableView(QltyField);
        QltyFieldLookup.SetRecord(QltyField);
        if QltyFieldLookup.RunModal() in [Action::OK, Action::LookupOK] then begin
            QltyFieldLookup.GetRecord(QltyField);
            HtmlContentText += '[' + QltyField.Code + ']';
        end;
    end;

    procedure RestrictFieldsToThoseOnTemplate(TemplateCode: Code[20])
    begin
        LimitedToTemplateCode := TemplateCode;
    end;
}
