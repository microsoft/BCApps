#pragma warning disable AA0247
page 26591 "Acc. Sched. Formula Drill-Down"
{
    Caption = 'Acc. Sched. Formula Drill-Down';
    DeleteAllowed = false;
    PageType = Worksheet;
    SourceTable = "Acc. Sched. Expression Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            field(Formula; Formula)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Formula';
                Editable = false;
            }
            repeater(Control1470000)
            {
                Editable = false;
                ShowCaption = false;
                field("Row No."; Rec."Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that identifies the line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Totaling Type"; Rec."Totaling Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'This field is used internally.';
                }
                field(Totaling; Rec.Totaling)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'This field is used internally.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount.';

                    trigger OnDrillDown()
                    var
                        GLAcc: Record "G/L Account";
                        GLAccAnalysisView: Record "G/L Account (Analysis View)";
                        AccSchedLine: Record "Acc. Schedule Line";
                        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
                        GLCorrespondenceEntries: Page "G/L Correspondence Entries";
                        ChartofAccAnalysisView: Page "Chart of Accs. (Analysis View)";
                        FormulaDrillDown: Page "Acc. Sched. Formula Drill-Down";
                    begin
                        AccSchedName.Get(SourceAccScheduleLine."Schedule Name");
                        AccSchedLine.Get(Rec."Schedule Name", Rec."Acc. Schedule Line No.");
                        AccSchedLine.CopyFilters(SourceAccScheduleLine);
                        StartDate := AccSchedLine.GetRangeMin("Date Filter");
                        EndDate := AccSchedLine.GetRangeMax("Date Filter");

                        AccSchedManagement.SetDateParameters(StartDate, EndDate);

                        if SourceColumnLayout."Column Type" = SourceColumnLayout."Column Type"::Formula then
                            Message(Text001, SourceColumnLayout.Formula)
                        else
                            if (SourceColumnLayout."Ledger Entry Type" = SourceColumnLayout."Ledger Entry Type"::"Corr. Entries") and
                               (Rec."Totaling Type" <> Rec."Totaling Type"::Formula)
                            then begin
                                GLCorrespondenceEntry.SetFilter("Debit Account No.", AccSchedLine.Totaling);
                                GLCorrespondenceEntry.SetFilter("Credit Account No.", AccSchedLine."Corr. Totaling");
                                AccSchedLine.CopyFilter("Dimension 1 Filter", GLCorrespondenceEntry."Debit Global Dimension 1 Code");
                                AccSchedLine.CopyFilter("Dimension 2 Filter", GLCorrespondenceEntry."Debit Global Dimension 2 Code");
                                AccSchedLine.CopyFilter("Corr. Dimension 1 Filter", GLCorrespondenceEntry."Credit Global Dimension 1 Code");
                                AccSchedLine.CopyFilter("Corr. Dimension 2 Filter", GLCorrespondenceEntry."Credit Global Dimension 2 Code");
                                GLCorrespondenceEntry.FilterGroup(2);
                                GLCorrespondenceEntry.SetFilter(
                                  "Debit Global Dimension 1 Code",
                                  AccSchedManagement.GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Totaling"));
                                GLCorrespondenceEntry.SetFilter(
                                  "Debit Global Dimension 2 Code",
                                  AccSchedManagement.GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Totaling"));
                                GLCorrespondenceEntry.SetFilter(
                                  "Credit Global Dimension 1 Code",
                                  AccSchedManagement.GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Corr. Totaling"));
                                GLCorrespondenceEntry.SetFilter(
                                  "Credit Global Dimension 2 Code",
                                  AccSchedManagement.GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Corr. Totaling"));
                                GLCorrespondenceEntry.FilterGroup(6);
                                GLCorrespondenceEntry.SetFilter(
                                  "Debit Global Dimension 1 Code",
                                  AccSchedManagement.GetDimTotalingFilter(1, SourceColumnLayout."Dimension 1 Totaling"));
                                GLCorrespondenceEntry.SetFilter(
                                  "Debit Global Dimension 2 Code",
                                  AccSchedManagement.GetDimTotalingFilter(2, SourceColumnLayout."Dimension 2 Totaling"));
                                GLCorrespondenceEntry.SetFilter(
                                  "Credit Global Dimension 1 Code",
                                  AccSchedManagement.GetDimTotalingFilter(1, SourceColumnLayout."Dimension 1 Corr. Totaling"));
                                GLCorrespondenceEntry.SetFilter(
                                  "Credit Global Dimension 2 Code",
                                  AccSchedManagement.GetDimTotalingFilter(2, SourceColumnLayout."Dimension 2 Corr. Totaling"));
                                GLCorrespondenceEntry.FilterGroup(0);

                                GLCorrespondenceEntry.SetFilter("Posting Date",
                                  AccSchedManagement.GetPostingDateFilter(AccSchedLine, SourceColumnLayout));
                                GLCorrespondenceEntries.SetTableView(GLCorrespondenceEntry);
                                GLCorrespondenceEntries.Run();
                            end else
                                case Rec."Totaling Type" of
                                    Rec."Totaling Type"::Constant:
                                        Message(Text003, Rec.Totaling);
                                    Rec."Totaling Type"::Formula:
                                        begin
                                            FormulaDrillDown.InitParameters(AccSchedLine, SourceColumnLayout, AccSchedCellValue);
                                            FormulaDrillDown.Run();
                                        end;
                                    Rec."Totaling Type"::Custom:
                                        AccSchedExtensionManagement.DrillDownAmount(
                                          AccSchedLine,
                                          SourceColumnLayout,
                                          Rec.Totaling,
                                          StartDate,
                                          EndDate);
                                    Rec."Totaling Type"::"Set Base For Percent":
                                        Message(Text002, Rec.Totaling);
                                    else
                                        if Rec.Totaling <> '' then begin
                                            AccSchedLine.CopyFilter("Business Unit Filter", GLAcc."Business Unit Filter");
                                            AccSchedLine.CopyFilter("G/L Budget Filter", GLAcc."Budget Filter");
                                            AccSchedManagement.SetGLAccRowFilters(GLAcc, AccSchedLine);
                                            AccSchedManagement.SetGLAccColumnFilters(GLAcc, AccSchedLine, SourceColumnLayout);
                                            if AccSchedName."Analysis View Name" = '' then begin
                                                AccSchedLine.CopyFilter("Dimension 1 Filter", GLAcc."Global Dimension 1 Filter");
                                                AccSchedLine.CopyFilter("Dimension 2 Filter", GLAcc."Global Dimension 2 Filter");
                                                AccSchedLine.CopyFilter("Business Unit Filter", GLAcc."Business Unit Filter");
                                                GLAcc.FilterGroup(2);
                                                GLAcc.SetFilter("Global Dimension 1 Filter",
                                                  AccSchedManagement.GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Totaling"));
                                                GLAcc.SetFilter("Global Dimension 2 Filter",
                                                  AccSchedManagement.GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Totaling"));
                                                GLAcc.FilterGroup(6);
                                                GLAcc.SetFilter(
                                                  "Global Dimension 1 Filter",
                                                  AccSchedManagement.GetDimTotalingFilter(1, SourceColumnLayout."Dimension 1 Totaling"));
                                                GLAcc.SetFilter(
                                                  "Global Dimension 2 Filter",
                                                  AccSchedManagement.GetDimTotalingFilter(2, SourceColumnLayout."Dimension 2 Totaling"));
                                                GLAcc.SetFilter("Business Unit Filter", SourceColumnLayout."Business Unit Totaling");
                                                GLAcc.FilterGroup(0);
                                                PAGE.Run(PAGE::"Chart of Accounts (G/L)", GLAcc)
                                            end else begin
                                                GLAcc.CopyFilter("Date Filter", GLAccAnalysisView."Date Filter");
                                                GLAcc.CopyFilter("Budget Filter", GLAccAnalysisView."Budget Filter");
                                                GLAcc.CopyFilter("Business Unit Filter", GLAccAnalysisView."Business Unit Filter");
                                                GLAccAnalysisView.SetRange("Analysis View Filter", AccSchedName."Analysis View Name");
                                                AccSchedLine.CopyFilter("Dimension 1 Filter", GLAccAnalysisView."Dimension 1 Filter");
                                                AccSchedLine.CopyFilter("Dimension 2 Filter", GLAccAnalysisView."Dimension 2 Filter");
                                                AccSchedLine.CopyFilter("Dimension 3 Filter", GLAccAnalysisView."Dimension 3 Filter");
                                                AccSchedLine.CopyFilter("Dimension 4 Filter", GLAccAnalysisView."Dimension 4 Filter");
                                                GLAccAnalysisView.FilterGroup(2);
                                                GLAccAnalysisView.SetFilter(
                                                  "Dimension 1 Filter",
                                                  AccSchedManagement.GetDimTotalingFilter(1, AccSchedLine."Dimension 1 Totaling"));
                                                GLAccAnalysisView.SetFilter(
                                                  "Dimension 2 Filter",
                                                  AccSchedManagement.GetDimTotalingFilter(2, AccSchedLine."Dimension 2 Totaling"));
                                                GLAccAnalysisView.SetFilter(
                                                  "Dimension 3 Filter",
                                                  AccSchedManagement.GetDimTotalingFilter(3, AccSchedLine."Dimension 3 Totaling"));
                                                GLAccAnalysisView.SetFilter(
                                                  "Dimension 4 Filter",
                                                  AccSchedManagement.GetDimTotalingFilter(4, AccSchedLine."Dimension 4 Totaling"));
                                                GLAccAnalysisView.FilterGroup(6);
                                                GLAccAnalysisView.SetFilter(
                                                  "Dimension 1 Filter",
                                                  AccSchedManagement.GetDimTotalingFilter(1, SourceColumnLayout."Dimension 1 Totaling"));
                                                GLAccAnalysisView.SetFilter(
                                                  "Dimension 2 Filter",
                                                  AccSchedManagement.GetDimTotalingFilter(2, SourceColumnLayout."Dimension 2 Totaling"));
                                                GLAccAnalysisView.SetFilter(
                                                  "Dimension 3 Filter",
                                                  AccSchedManagement.GetDimTotalingFilter(3, SourceColumnLayout."Dimension 3 Totaling"));
                                                GLAccAnalysisView.SetFilter(
                                                  "Dimension 4 Filter",
                                                  AccSchedManagement.GetDimTotalingFilter(4, SourceColumnLayout."Dimension 4 Totaling"));
                                                GLAccAnalysisView.SetFilter("Business Unit Filter", SourceColumnLayout."Business Unit Totaling");
                                                GLAccAnalysisView.FilterGroup(0);
                                                Clear(ChartofAccAnalysisView);
                                                ChartofAccAnalysisView.InsertTempGLAccAnalysisViews(GLAcc);
                                                ChartofAccAnalysisView.SetTableView(GLAccAnalysisView);
                                                ChartofAccAnalysisView.Run();
                                            end;
                                        end;
                                end;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    var
        GLSetup: Record "General Ledger Setup";
        AccSchedName: Record "Acc. Schedule Name";
        SourceAccScheduleLine: Record "Acc. Schedule Line";
        SourceColumnLayout: Record "Column Layout";
        AccSchedCellValue: Record "Acc. Sched. Cell Value" temporary;
        AccSchedManagement: Codeunit AccSchedManagement;
        AccSchedExtensionManagement: Codeunit AccSchedExtensionManagement;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Column formula: %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'Row formula: %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'Row constant: %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Formula: Text[250];
        StartDate: Date;
        EndDate: Date;
        EntryNo: Integer;

    [Scope('OnPrem')]
    procedure InitParameters(var AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"; var Buffer: Record "Acc. Sched. Cell Value")
    begin
        SourceAccScheduleLine.Copy(AccSchedLine);
        AccSchedLine.TestField("Totaling Type", AccSchedLine."Totaling Type"::Formula);
        SourceColumnLayout := ColumnLayout;
        Formula := AccSchedLine.Totaling;

        if Buffer.FindSet() then
            repeat
                AccSchedCellValue.TransferFields(Buffer);
                if AccSchedCellValue.Insert() then;
            until Buffer.Next() = 0;

        EvaluateExpression(true, AccSchedLine.Totaling, AccSchedLine, SourceColumnLayout);
    end;

    local procedure EvaluateExpression(IsAccSchedLineExpression: Boolean; Expression: Text[250]; AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"): Decimal
    var
        Result: Decimal;
        Parantheses: Integer;
        Operator: Char;
        LeftOperand: Text[250];
        RightOperand: Text[250];
        LeftResult: Decimal;
        RightResult: Decimal;
        i: Integer;
        IsExpression: Boolean;
        IsFilter: Boolean;
        Operators: Text[8];
        OperatorNo: Integer;
        AccSchedLineID: Integer;
    begin
        Result := 0;

        GLSetup.Get();

        Expression := DelChr(Expression, '<>', ' ');
        if StrLen(Expression) > 0 then begin
            Parantheses := 0;
            IsExpression := false;
            Operators := '+-*/^%';
            OperatorNo := 1;
            repeat
                i := StrLen(Expression);
                repeat
                    if Expression[i] = '(' then
                        Parantheses := Parantheses + 1
                    else
                        if Expression[i] = ')' then
                            Parantheses := Parantheses - 1;
                    if (Parantheses = 0) and (Expression[i] = Operators[OperatorNo]) then
                        IsExpression := true
                    else
                        i := i - 1;
                until IsExpression or (i <= 0);
                if not IsExpression then
                    OperatorNo := OperatorNo + 1;
            until (OperatorNo > StrLen(Operators)) or IsExpression;
            if IsExpression then begin
                if i > 1 then
                    LeftOperand := CopyStr(Expression, 1, i - 1)
                else
                    LeftOperand := '';
                if i < StrLen(Expression) then
                    RightOperand := CopyStr(Expression, i + 1)
                else
                    RightOperand := '';
                Operator := Expression[i];
                LeftResult :=
                  EvaluateExpression(
                    IsAccSchedLineExpression, LeftOperand, AccSchedLine, ColumnLayout);
                RightResult :=
                  EvaluateExpression(
                    IsAccSchedLineExpression, RightOperand, AccSchedLine, ColumnLayout);
                case Operator of
                    '^':
                        Result := Power(LeftResult, RightResult);
                    '%':
                        if RightResult = 0 then
                            Result := 0
                        else
                            Result := 100 * LeftResult / RightResult;
                    '*':
                        Result := LeftResult * RightResult;
                    '/':
                        if RightResult = 0 then
                            Result := 0
                        else
                            Result := LeftResult / RightResult;
                    '+':
                        Result := LeftResult + RightResult;
                    '-':
                        Result := LeftResult - RightResult;
                end;
            end else
                if (Expression[1] = '(') and (Expression[StrLen(Expression)] = ')') then
                    Result :=
                      EvaluateExpression(
                        IsAccSchedLineExpression, CopyStr(Expression, 2, StrLen(Expression) - 2),
                        AccSchedLine, ColumnLayout)
                else begin
                    IsFilter :=
                      (StrPos(Expression, '..') +
                       StrPos(Expression, '|') +
                       StrPos(Expression, '<') +
                       StrPos(Expression, '>') +
                       StrPos(Expression, '&') +
                       StrPos(Expression, '=') > 0);
                    if (StrLen(Expression) > 20) and (not IsFilter) then
                        Evaluate(Result, Expression)
                    else
                        if IsAccSchedLineExpression then begin
                            AccSchedLine.SetRange("Schedule Name", AccSchedLine."Schedule Name");
                            AccSchedLine.SetFilter("Row No.", Expression);
                            AccSchedLineID := AccSchedLine."Line No.";
                            if AccSchedLine.FindSet() then
                                repeat
                                    if AccSchedLine."Line No." <> AccSchedLineID then
                                        Result := Result + CalcCellValue(AccSchedLine, ColumnLayout);
                                until AccSchedLine.Next() = 0
                            else begin
                                AccSchedLine.SetRange("Schedule Name", GLSetup."Shared Account Schedule");
                                if AccSchedLine.FindFirst() then
                                    repeat
                                        Result := Result + CalcCellValue(AccSchedLine, ColumnLayout);
                                    until AccSchedLine.Next() = 0;
                            end
                        end else begin
                            ColumnLayout.SetRange("Column Layout Name", ColumnLayout."Column Layout Name");
                            ColumnLayout.SetFilter("Column No.", Expression);
                            AccSchedLineID := ColumnLayout."Line No.";
                            if ColumnLayout.FindSet() then
                                repeat
                                    if ColumnLayout."Line No." <> AccSchedLineID then
                                        Result := Result + CalcCellValue(AccSchedLine, ColumnLayout);
                                until ColumnLayout.Next() = 0
                        end;
                end;
        end;
        exit(Result);
    end;

    local procedure CalcCellValue(AccSchedLine: Record "Acc. Schedule Line"; ColumnLayout: Record "Column Layout"): Decimal
    var
        Result: Decimal;
    begin
        Result := 0;
        if AccSchedCellValue.Get(AccSchedLine."Schedule Name", AccSchedLine."Line No.", ColumnLayout."Line No.") then
            Result := AccSchedCellValue.Value;

        AddFormulasExpression(AccSchedLine, Result);
        exit(Result);
    end;

    [Scope('OnPrem')]
    procedure AddFormulasExpression(AccSchedLine: Record "Acc. Schedule Line"; Result: Decimal)
    begin
        EntryNo += 1;

        Rec.Init();
        Rec."Entry No." := EntryNo;
        Rec.Totaling := AccSchedLine.Totaling;
        Rec.Amount := Result;
        Rec."Row No." := AccSchedLine."Row No.";
        Rec."Totaling Type" := AccSchedLine."Totaling Type";
        Rec."Schedule Name" := AccSchedLine."Schedule Name";
        Rec."Acc. Schedule Line No." := AccSchedLine."Line No.";
        Rec.Insert();
    end;
}

