// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template;

using Microsoft.QualityManagement.Configuration.Template.Test;
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
            group(RawHtml)
            {
                ShowCaption = false;
                Caption = ' ';
                Visible = not IsHTMLFormatted;

                field(HtmlContent; HtmlContentText)
                {
                    Caption = 'Text';
                    ShowCaption = false;
                    ApplicationArea = All;
                    ToolTip = 'Edit the text template.';
                    MultiLine = true;
                }
            }
            group(TestExpressionWithAInspection)
            {
                Caption = 'Test expression with an existing Quality Inspection';
                Visible = ShowAddTestFromInspection;
                field(ChooseInspectionRecordId; Format(ChooseInspectionRecordId))
                {
                    ApplicationArea = All;
                    Caption = 'Choose inspection';
                    ToolTip = 'Specifies an existing inspection to test the expression with.';
                    Editable = false;

                    trigger OnAssistEdit()
                    var
                        QltyInspectionHeader: Record "Qlty. Inspection Header";
                        QltyInspectionLine: Record "Qlty. Inspection Line";
                        QltyInspectionList: Page "Qlty. Inspection List";
                    begin
                        QltyInspectionHeader.Ascending(false);

                        if QltyInspectionHeader.Get(ChooseInspectionRecordId) then begin
                            QltyInspectionList.SetRecord(QltyInspectionHeader);
                            QltyInspectionHeader.SetRecFilter();
                            if QltyInspectionHeader.FindSet() then;
                            QltyInspectionHeader.SetRange("No.");
                        end;
                        if LimitedToTemplateCode <> '' then
                            QltyInspectionHeader.SetRange("Template Code", LimitedToTemplateCode);

                        QltyInspectionList.SetTableView(QltyInspectionHeader);

                        QltyInspectionList.LookupMode(true);
                        if QltyInspectionList.RunModal() in [Action::LookupOK, Action::OK] then begin
                            QltyInspectionList.GetRecord(QltyInspectionHeader);
                            ChooseInspectionRecordId := QltyInspectionHeader.RecordId();
                            Clear(ChooseInspectionLineChooseInspectionRecordId);
                            QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
                            QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
                            if QltyInspectionLine.FindFirst() then
                                ChooseInspectionLineChooseInspectionRecordId := QltyInspectionLine.RecordId();

                            LimitedToTemplateCode := QltyInspectionHeader."Template Code";
                        end;
                    end;
                }
                field(ChooseInspectionLineRecordId; Format(ChooseInspectionLineChooseInspectionRecordId))
                {
                    ApplicationArea = All;
                    Caption = 'Choose inspection line';
                    ToolTip = 'Specifies an existing inspection line to test the expression with.';
                    Editable = false;

                    trigger OnAssistEdit()
                    var
                        QltyInspectionHeader: Record "Qlty. Inspection Header";
                        QltyInspectionLine: Record "Qlty. Inspection Line";
                        QltyInspectionLines: Page "Qlty. Inspection Lines";
                    begin
                        QltyInspectionLine.Ascending(false);
                        if not QltyInspectionHeader.Get(ChooseInspectionRecordId) then
                            Error(ChooseAValidInspectionFirstBeforeChoosingLineErr);
                        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
                        QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
                        if QltyInspectionLine.Get(ChooseInspectionLineChooseInspectionRecordId) then begin
                            QltyInspectionLines.SetRecord(QltyInspectionLine);
                            QltyInspectionLine.SetRecFilter();
                            if QltyInspectionLine.FindSet() then;
                            QltyInspectionLine.SetRange("Test Code");
                            QltyInspectionLine.SetRange("Line No.");
                        end;
                        if LimitedToTemplateCode <> '' then
                            QltyInspectionLine.SetRange("Template Code", LimitedToTemplateCode);

                        QltyInspectionLines.SetTableView(QltyInspectionLine);

                        QltyInspectionLines.LookupMode(true);
                        if QltyInspectionLines.RunModal() in [Action::LookupOK, Action::OK] then begin
                            QltyInspectionLines.GetRecord(QltyInspectionLine);
                            ChooseInspectionLineChooseInspectionRecordId := QltyInspectionLine.RecordId();
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
                        QltyInspectionHeader: Record "Qlty. Inspection Header";
                        QltyInspectionLine: Record "Qlty. Inspection Line";
                    begin
                        OutputResult := '';
                        if not QltyInspectionHeader.Get(ChooseInspectionRecordId) then
                            Error(ChooseAValidInspectionFirstBeforeTestingErr);
                        if not QltyInspectionLine.Get(ChooseInspectionLineChooseInspectionRecordId) then
                            Clear(QltyInspectionLine);
                        OutputResult := QltyExpressionMgmt.EvaluateTextExpression(HtmlContentText, QltyInspectionHeader, QltyInspectionLine, ShowEmbeddedFormula);
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
            action(AddInspectionTest)
            {
                ApplicationArea = All;
                Caption = 'Add Test';
                Image = CopyFromTask;
                ToolTip = 'Click here to use a Quality Inspection test in this expression.';
                AboutTitle = 'Add inspection test';
                AboutText = 'Click here to use a Quality Inspection test in this expression.';
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    HandleOnAddQltyInspectionTest();
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
            action(AddTestFromInspection)
            {
                ApplicationArea = All;
                Caption = 'Add Inspection Information';
                Image = Add;
                ToolTip = 'Click here to insert additional tests into the template.';
                AboutTitle = 'Add a test from a quality inspection.';
                AboutText = 'Click here to insert additional tests into the template.';
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Visible = ShowAddTestFromInspection;

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
        ChooseInspectionRecordId: RecordId;
        ChooseInspectionLineChooseInspectionRecordId: RecordId;
        IsHTMLFormatted: Boolean;
        HtmlContentText: Text[500];
        LimitedToTemplateCode: Code[20];
        OptionalNameFilter: Text;
        TableNo: Integer;
        ShowEmbeddedFormula: Boolean;
        ShowAddTestFromInspection: Boolean;
        ShowAddFieldFromAnyTable: Boolean;
        OutputResult: Text;
        ChooseAValidInspectionFirstBeforeChoosingLineErr: Label 'Please choose a valid existing inspection before choosing a line.';
        ChooseAValidInspectionFirstBeforeTestingErr: Label 'Please choose a valid existing inspection before testing this expression.';

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
        if TableNo = Database::"Qlty. Inspection Header" then
            ShowAddTestFromInspection := true;

        ShowAddFieldFromAnyTable := not ShowAddTestFromInspection;
        OptionalNameFilter := OptionalNameFilter2;
        HtmlContentText := CopyStr(QltyExpressionMgmt.ConvertHTMLBRsToCarriageReturns(ExistingTemplate), 1, MaxStrLen(HtmlContentText));
        ResultAction := CurrPage.RunModal();
        if ResultAction in [ResultAction::OK, ResultAction::LookupOK, ResultAction::Yes] then
            ExistingTemplate := QltyExpressionMgmt.ConvertCarriageReturnsToHTMLBRs(HtmlContentText);
    end;

    local procedure HandleOnAddQltyInspectionTest()
    begin
        if LimitedToTemplateCode = '' then
            LookupAnyQltyInspectionTest()
        else
            LookupOnlyTestsInTemplate();
    end;

    local procedure LookupAnyQltyInspectionTest()
    var
        QltyTest: Record "Qlty. Test";
        QltyTestLookup: Page "Qlty. Test Lookup";
    begin
        QltyTestLookup.LookupMode(true);
        QltyTestLookup.SetRecord(QltyTest);
        if QltyTestLookup.RunModal() in [Action::OK, Action::LookupOK] then begin
            QltyTestLookup.GetRecord(QltyTest);
            HtmlContentText += '[' + QltyTest.Code + ']';
        end;
    end;

    local procedure LookupOnlyTestsInTemplate()
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyTest: Record "Qlty. Test";
        QltyTestLookup: Page "Qlty. Test Lookup";
        FieldFilter: Text;
    begin
        QltyInspectionTemplateLine.SetRange("Template Code", LimitedToTemplateCode);
        if QltyInspectionTemplateLine.FindSet() then
            repeat
                if QltyInspectionTemplateLine."Test Code" <> '' then begin
                    if StrLen(FieldFilter) > 1 then
                        FieldFilter += '|';
                    FieldFilter += QltyInspectionTemplateLine."Test Code";
                end;
            until QltyInspectionTemplateLine.Next() = 0;

        if FieldFilter <> '' then
            QltyTest.SetFilter(Code, FieldFilter);
        QltyTestLookup.LookupMode(true);
        QltyTestLookup.SetTableView(QltyTest);
        QltyTestLookup.SetRecord(QltyTest);
        if QltyTestLookup.RunModal() in [Action::OK, Action::LookupOK] then begin
            QltyTestLookup.GetRecord(QltyTest);
            HtmlContentText += '[' + QltyTest.Code + ']';
        end;
    end;

    procedure RestrictTestsToThoseOnTemplate(TemplateCode: Code[20])
    begin
        LimitedToTemplateCode := TemplateCode;
    end;
}
