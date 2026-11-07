#pragma warning disable AA0247
codeunit 17200 "Tax Register Term Mgt."
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        ErrorText1: Label '\\Following value has been calculated in the report\Line No.=%1, Column No.=%2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        ErrorText2: Label '\\Error in calculation of value in\No.=%3, Line No.=%4.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        WinTestText: Label 'Check cycle reference in Terms\';
#pragma warning restore AA0074
#pragma warning disable AA0074
        ReportTest1: Label 'Check completed. Cycle reference not found.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        ReportTest2: Label 'Check completed. Cycle reference has been found for %1 items.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        ErrorConst: Label 'Section %1 Term %2\Wrong constant %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        ErrorType: Label 'Section %1 Term %2\G/L Account must be set with Type = %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        ErrorInvolve: Label 'Navision cannot calculate the formula due to cycle reference.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        ErrorValue: Label 'Wrong value or line number does not exist.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        ErrorDateFilter: Label 'Wrong value in Date Filter = %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        GenTemplateProfile: Record "Gen. Template Profile";
        GenTermProfile: Record "Gen. Term Profile";
        TaxRegValueBuffer: Record "Drop Shpt. Post. Buffer" temporary;
        TempTaxRegCalcBuf: Record "Tax Register Calc. Buffer" temporary;
        LinkTableRecordRef: RecordRef;
        Window: Dialog;
        RecurcLevel: Integer;
        CreateCalcBuf: Boolean;
        DecimalsSymbols: Text[2];
        GlobalSectionCode: Code[10];
        GlobalTemplateCode: Code[10];
        GlobalTemplateLineNo: Integer;
        GlobalDateFilter: Text;
#pragma warning disable AA0074
        Text17200: Label 'IF TERM(%1) < 0 THEN ', Locked = true;
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text17201: Label ' elseIF TERM(%1) = 0 THEN ', Locked = true;
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text17202: Label ' elseIF TERM(%1) > 0 THEN ', Locked = true;
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text17203: Label 'Equal,Account,Term,CorrAcc,Norm,5,6,7,8,9,10';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text17204: Label 'DB-CR,DB,CR,4,5,6,7,8,9,10';
#pragma warning restore AA0074
#pragma warning disable AA0074
        InvalidSymbol: Label '@#^&*/-+(){}[]<>|\!:', Locked = true;
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        ErrorMassage: Label 'The line should not contains following special symbols %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure CalcTermValue(var TermNameRecordRef: RecordRef; var TempDimBuf: Record "Dimension Buffer" temporary) Output: Decimal
    var
        GLEntry: Record "G/L Entry";
        GLCorrespondEntry: Record "G/L Correspondence Entry";
        TempGLEntryGlobalDimFilter: Record "G/L Entry" temporary;
        TaxRegNormGroup: Record "Tax Register Norm Group";
        TaxRegNormDetail: Record "Tax Register Norm Detail";
        TermLineRecordRef: RecordRef;
        RecurciveTermRecordRef: RecordRef;
        TermFieldRef: FieldRef;
        TermLineFieldRef: FieldRef;
        RecurciveTermFieldRef: FieldRef;
        Operand: Decimal;
        ExitCycle: Boolean;
        NoGlobalDimFilterNeed: Boolean;
        FindUniqueRecursiveTerm: Boolean;
        SectionCode: Code[20];
        TermCode: Code[20];
        ExpressionType: Option "Plus/Minus","Multiply/Divide",Compare;
        TermLineAccountType: Option Constant,"GL Acc",Termin,"Net Change",Norm;
        TermLineAmountType: Option " ","Net Change",Debit,Credit;
        ValidateSign: Option " ","Skip Negative","Skip Positive","Always Positve","Always Negative";
        LineOperation: Option "+","-","*","/","Less 0","Equ 0","Grate 0";
        ResultOfZeroDivided: Option Zero,One;
        RoundingPrecision: Decimal;
    begin
        GenTermProfile.TestField("Expression Type (Hdr)");
        FieldRefValue(TermFieldRef, TermNameRecordRef, GenTermProfile."Expression Type (Hdr)");

        ExpressionType := TermFieldRef.Value();
        if ExpressionType = ExpressionType::"Multiply/Divide" then
            Output := 1
        else
            Output := 0;

        ExitCycle := false;

        TermLineRecordRef.Open(GenTemplateProfile."Term Line Table No.");

        GenTermProfile.TestField("Section Code (Hdr)");
        FieldRefValue(TermFieldRef, TermNameRecordRef, GenTermProfile."Section Code (Hdr)");
        SectionCode := TermFieldRef.Value();

        GenTermProfile.TestField("Section Code (Line)");
        FieldRefValue(TermLineFieldRef, TermLineRecordRef, GenTermProfile."Section Code (Line)");
        TermLineFieldRef.SetRange(SectionCode);

        GenTermProfile.TestField("Term Code (Hdr)");
        FieldRefValue(TermFieldRef, TermNameRecordRef, GenTermProfile."Term Code (Hdr)");
        TermCode := TermFieldRef.Value();

        GenTermProfile.TestField("Term Code (Line)");
        FieldRefValue(TermLineFieldRef, TermLineRecordRef, GenTermProfile."Term Code (Line)");
        TermLineFieldRef.SetRange(TermCode);

        GenTermProfile.TestField("Account Type (Line)");
        GenTermProfile.TestField("Account No. (Line)");
        GenTermProfile.TestField("Amount Type (Line)");
        GenTermProfile.TestField("Date Filter (Hdr)");

        if TermLineRecordRef.FindSet() then
            repeat
                FieldRefValue(TermLineFieldRef, TermLineRecordRef, GenTermProfile."Account Type (Line)");
                TermLineAccountType := TermLineFieldRef.Value();

                if TermLineAccountType in [
                                           TermLineAccountType::"GL Acc",
                                           TermLineAccountType::"Net Change"]
                then
                    NoGlobalDimFilterNeed := SetDimFilters2GLEntry(TempGLEntryGlobalDimFilter, TempDimBuf);

                FieldRefValue(TermLineFieldRef, TermLineRecordRef, GenTermProfile."Account No. (Line)");

                case TermLineAccountType of
                    TermLineAccountType::Constant:
                        if not EvaluateDecimal(Operand, Format(TermLineFieldRef.Value)) then begin
                            Operand := 0;
                            Message(ErrorConst, SectionCode, TermCode, TermLineFieldRef.Value);
                        end;
                    TermLineAccountType::"Net Change":
                        begin
                            if TempGLEntryGlobalDimFilter.GetFilters = '' then begin
                                GLCorrespondEntry.SetCurrentKey("Debit Account No.", "Credit Account No.", "Posting Date");
                                GLCorrespondEntry.SetFilter("Debit Account No.", Format(TermLineFieldRef.Value));
                            end else begin
                                GLCorrespondEntry.SetCurrentKey(
                                  "Debit Account No.", "Credit Account No.",
                                  "Debit Global Dimension 1 Code", "Debit Global Dimension 2 Code",
                                  "Business Unit Code", "Posting Date");
                                GLCorrespondEntry.SetFilter("Debit Account No.", Format(TermLineFieldRef.Value));
                                TempGLEntryGlobalDimFilter.CopyFilter("Global Dimension 1 Code", GLCorrespondEntry."Debit Global Dimension 1 Code");
                                TempGLEntryGlobalDimFilter.CopyFilter("Global Dimension 2 Code", GLCorrespondEntry."Debit Global Dimension 2 Code");
                            end;

                            GenTermProfile.TestField("Bal. Account No. (Line)");
                            FieldRefValue(TermLineFieldRef, TermLineRecordRef, GenTermProfile."Bal. Account No. (Line)");
                            GLCorrespondEntry.SetFilter("Credit Account No.", Format(TermLineFieldRef.Value));

                            FieldRefValue(TermFieldRef, TermNameRecordRef, GenTermProfile."Date Filter (Hdr)");
                            if TermFieldRef.Class = FieldClass::FlowFilter then
                                GLCorrespondEntry.SetFilter("Posting Date", TermFieldRef.GetFilter)
                            else
                                GLCorrespondEntry.SetFilter("Posting Date", Format(TermFieldRef.Value));

                            if NoGlobalDimFilterNeed then begin
                                Operand := 0;
                                if GLCorrespondEntry.FindSet() then
                                    repeat
                                        if ValidateGLEntryDimFilters(GLCorrespondEntry."Debit Dimension Set ID", TempDimBuf) then
                                            Operand += GLCorrespondEntry.Amount;
                                    until GLCorrespondEntry.Next(1) = 0;
                            end else begin
                                GLCorrespondEntry.CalcSums(Amount);
                                Operand := GLCorrespondEntry.Amount;
                            end;
                        end;
                    TermLineAccountType::"GL Acc":
                        begin
                            if TempGLEntryGlobalDimFilter.GetFilters = '' then begin
                                GLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
                                GLEntry.SetFilter("G/L Account No.", Format(TermLineFieldRef.Value));
                            end else begin
                                GLEntry.SetCurrentKey(
                                  "G/L Account No.", "Business Unit Code",
                                  "Global Dimension 1 Code", "Global Dimension 2 Code");
                                GLEntry.SetFilter("G/L Account No.", Format(TermLineFieldRef.Value));
                                TempGLEntryGlobalDimFilter.CopyFilter("Global Dimension 1 Code", GLEntry."Global Dimension 1 Code");
                                TempGLEntryGlobalDimFilter.CopyFilter("Global Dimension 2 Code", GLEntry."Global Dimension 2 Code");
                            end;

                            FieldRefValue(TermFieldRef, TermNameRecordRef, GenTermProfile."Date Filter (Hdr)");
                            if TermFieldRef.Class = FieldClass::FlowFilter then
                                GLEntry.SetFilter("Posting Date", TermFieldRef.GetFilter)
                            else
                                GLEntry.SetFilter("Posting Date", Format(TermFieldRef.Value));

                            FieldRefValue(TermLineFieldRef, TermLineRecordRef, GenTermProfile."Amount Type (Line)");
                            TermLineAmountType := TermLineFieldRef.Value();
                            if NoGlobalDimFilterNeed then begin
                                case TermLineAmountType of
                                    TermLineAmountType::"Net Change":
                                        GLEntry.SetFilter(Amount, '<>0');
                                    TermLineAmountType::Debit:
                                        GLEntry.SetFilter("Debit Amount", '<>0');
                                    TermLineAmountType::Credit:
                                        GLEntry.SetFilter("Credit Amount", '<>0');
                                    else
                                        Error(ErrorType, SectionCode, TermCode, TermLineFieldRef.Value);
                                end;
                                Operand := 0;
                                if GLEntry.FindSet() then
                                    repeat
                                        if ValidateGLEntryDimFilters(GLEntry."Dimension Set ID", TempDimBuf) then
                                            case TermLineAmountType of
                                                TermLineAmountType::"Net Change":
                                                    Operand += GLEntry.Amount;
                                                TermLineAmountType::Debit:
                                                    Operand += GLEntry."Debit Amount";
                                                TermLineAmountType::Credit:
                                                    Operand += GLEntry."Credit Amount";
                                            end;
                                    until GLEntry.Next(1) = 0;
                            end else
                                case TermLineAmountType of
                                    TermLineAmountType::"Net Change":
                                        begin
                                            GLEntry.CalcSums(Amount);
                                            Operand := GLEntry.Amount;
                                        end;
                                    TermLineAmountType::Debit:
                                        begin
                                            GLEntry.CalcSums("Debit Amount");
                                            Operand := GLEntry."Debit Amount";
                                        end;
                                    TermLineAmountType::Credit:
                                        begin
                                            GLEntry.CalcSums("Credit Amount");
                                            Operand := GLEntry."Credit Amount";
                                        end;
                                    else
                                        Error(ErrorType, SectionCode, TermCode, TermLineFieldRef.Value);
                                end;
                        end;
                    TermLineAccountType::Norm:
                        begin
                            GenTermProfile.TestField("Norm Jurisd. Code (Line)");
                            TaxRegNormDetail.SetRange("Norm Type", TaxRegNormDetail."Norm Type"::Amount);
                            TaxRegNormGroup.Code := Format(TermLineFieldRef.Value);
                            TaxRegNormDetail.SetRange("Norm Group Code", TaxRegNormGroup.Code);
                            FieldRefValue(TermLineFieldRef, TermLineRecordRef, GenTermProfile."Norm Jurisd. Code (Line)");
                            TaxRegNormGroup."Norm Jurisdiction Code" := Format(TermLineFieldRef.Value);
                            TaxRegNormDetail.SetRange("Norm Jurisdiction Code", TaxRegNormGroup."Norm Jurisdiction Code");
                            FieldRefValue(TermFieldRef, TermNameRecordRef, GenTermProfile."Date Filter (Hdr)");
                            if TermFieldRef.Class = FieldClass::FlowFilter then
                                TaxRegNormDetail.SetFilter("Effective Date", TermFieldRef.GetFilter)
                            else
                                TaxRegNormDetail.SetFilter("Effective Date", Format(TermFieldRef.Value));
                            TaxRegNormGroup.Find();
                            if TaxRegNormGroup."Search Detail" = TaxRegNormGroup."Search Detail"::"To Date" then begin
                                TaxRegNormDetail.SetFilter("Effective Date", '..%1', TaxRegNormDetail.GetRangeMax("Effective Date"));
                                if TaxRegNormDetail.FindLast() then
                                    Operand := TaxRegNormDetail.Norm;
                            end else begin
                                TaxRegNormDetail.SetRange("Effective Date", TaxRegNormDetail.GetRangeMax("Effective Date"));
                                TaxRegNormDetail.FindLast();
                                Operand := TaxRegNormDetail.Norm;
                            end;
                        end;
                    TermLineAccountType::Termin:
                        begin
                            RecurciveTermRecordRef.Close();
                            RecurciveTermRecordRef.Open(TermNameRecordRef.Number);
                            RecurciveTermFieldRef := RecurciveTermRecordRef.Field(GenTermProfile."Section Code (Hdr)");
                            RecurciveTermFieldRef.SetRange(SectionCode);
                            RecurciveTermFieldRef := RecurciveTermRecordRef.Field(GenTermProfile."Term Code (Hdr)");
                            RecurciveTermFieldRef.SetRange(TermLineFieldRef.Value);
                            FindUniqueRecursiveTerm := RecurciveTermRecordRef.FindFirst();
                            if FindUniqueRecursiveTerm then
                                FindUniqueRecursiveTerm := RecurciveTermRecordRef.Next(1) = 0;
                            if FindUniqueRecursiveTerm then begin
                                RecurciveTermRecordRef.SetView(TermNameRecordRef.GetView(false));
                                Operand := CalcTermValue(RecurciveTermRecordRef, TempDimBuf);
                            end else
                                Operand := 0;
                        end;
                end;
                if TermLineAccountType <> TermLineAccountType::Termin then
                    if GenTermProfile."Process Sign (Line)" <> 0 then begin
                        FieldRefValue(TermLineFieldRef, TermLineRecordRef, GenTermProfile."Process Sign (Line)");
                        ValidateSign := TermLineFieldRef.Value();
                        case ValidateSign of
                            ValidateSign::"Skip Negative":
                                if Operand < 0 then
                                    Operand := 0;
                            ValidateSign::"Skip Positive":
                                if Operand > 0 then
                                    Operand := 0;
                            ValidateSign::"Always Negative":
                                Operand := -Abs(Operand);
                            ValidateSign::"Always Positve":
                                Operand := Abs(Operand);
                        end;
                    end;

                if CreateCalcBuf then begin
                    if GenTermProfile."Expression Type (Hdr)" <> 0 then begin
                        FieldRefValue(TermFieldRef, TermNameRecordRef, GenTermProfile."Expression Type (Hdr)");
                        TempTaxRegCalcBuf."Term Type" := TermFieldRef.Value();
                    end;
                    if GenTermProfile."Operation (Line)" <> 0 then begin
                        FieldRefValue(TermLineFieldRef, TermLineRecordRef, GenTermProfile."Operation (Line)");
                        TempTaxRegCalcBuf.Operation := TermLineFieldRef.Value();
                    end;
                    if GenTermProfile."Account Type (Line)" <> 0 then begin
                        FieldRefValue(TermLineFieldRef, TermLineRecordRef, GenTermProfile."Account Type (Line)");
                        TempTaxRegCalcBuf."Account Type" := TermLineFieldRef.Value();
                    end;
                    if GenTermProfile."Account No. (Line)" <> 0 then begin
                        FieldRefValue(TermLineFieldRef, TermLineRecordRef, GenTermProfile."Account No. (Line)");
                        TempTaxRegCalcBuf."Account No." := TermLineFieldRef.Value();
                    end;
                    if GenTermProfile."Amount Type (Line)" <> 0 then begin
                        FieldRefValue(TermLineFieldRef, TermLineRecordRef, GenTermProfile."Amount Type (Line)");
                        TempTaxRegCalcBuf."Amount Type" := TermLineFieldRef.Value();
                    end;
                    if GenTermProfile."Bal. Account No. (Line)" <> 0 then begin
                        FieldRefValue(TermLineFieldRef, TermLineRecordRef, GenTermProfile."Bal. Account No. (Line)");
                        TempTaxRegCalcBuf."Bal. Account No." := TermLineFieldRef.Value();
                    end;
                    if GenTermProfile."Process Sign (Line)" <> 0 then begin
                        FieldRefValue(TermLineFieldRef, TermLineRecordRef, GenTermProfile."Process Sign (Line)");
                        TempTaxRegCalcBuf."Process Sign" := TermLineFieldRef.Value();
                    end;
                    if GenTermProfile."Line No. (Line)" <> 0 then begin
                        FieldRefValue(TermLineFieldRef, TermLineRecordRef, GenTermProfile."Line No. (Line)");
                        TempTaxRegCalcBuf."Term Line No." := TermLineFieldRef.Value();
                    end;
                    if GenTermProfile."Description (Hdr)" <> 0 then begin
                        FieldRefValue(TermFieldRef, TermNameRecordRef, GenTermProfile."Description (Hdr)");
                        TempTaxRegCalcBuf.Description := TermFieldRef.Value();
                    end;
                    if GenTermProfile."Term Code (Hdr)" <> 0 then begin
                        FieldRefValue(TermFieldRef, TermNameRecordRef, GenTermProfile."Term Code (Hdr)");
                        TempTaxRegCalcBuf.Expression := TermFieldRef.Value();
                    end;
                    TempTaxRegCalcBuf."Line Code" := '';
                    TempTaxRegCalcBuf."Section Code" := GlobalSectionCode;
                    TempTaxRegCalcBuf."Tax Register No." := GlobalTemplateCode;
                    TempTaxRegCalcBuf."Template Line No." := GlobalTemplateLineNo;
                    TempTaxRegCalcBuf."Date Filter" := CopyStr(GlobalDateFilter, 1, MaxStrLen(TempTaxRegCalcBuf."Date Filter"));
                    TempTaxRegCalcBuf."Expression Type" := TempTaxRegCalcBuf."Expression Type"::Term;
                    TempTaxRegCalcBuf.Amount := Operand;
                    TempTaxRegCalcBuf."Entry No." += 1;
                    TempTaxRegCalcBuf.Insert();
                end;

                GenTermProfile.TestField("Operation (Line)");
                FieldRefValue(TermLineFieldRef, TermLineRecordRef, GenTermProfile."Operation (Line)");
                LineOperation := TermLineFieldRef.Value();
                case LineOperation of
                    LineOperation::"+":
                        Output := Output + Operand;
                    LineOperation::"-":
                        Output := Output - Operand;
                    LineOperation::"*":
                        Output := Output * Operand;
                    LineOperation::"/":
                        if Operand <> 0 then
                            Output := Output / Operand
                        else
                            if GenTermProfile."Process Division by Zero(Line)" <> 0 then begin
                                FieldRefValue(TermLineFieldRef, TermLineRecordRef, GenTermProfile."Process Division by Zero(Line)");
                                ResultOfZeroDivided := TermLineFieldRef.Value();
                                case ResultOfZeroDivided of
                                    ResultOfZeroDivided::Zero:
                                        Output := 0;
                                    ResultOfZeroDivided::One:
                                        Output := 1;
                                    else
                                        Output := 0;
                                end;
                            end;
                    LineOperation::"Less 0",
                    LineOperation::"Equ 0",
                    LineOperation::"Grate 0":
                        begin
                            GenTermProfile.TestField("Line No. (Line)");
                            TermLineFieldRef := TermLineRecordRef.Field(GenTermProfile."Line No. (Line)");
                            if Operand < 0 then
                                TermLineFieldRef.SetRange(10000)
                            else
                                if Operand = 0 then
                                    TermLineFieldRef.SetRange(20000)
                                else
                                    TermLineFieldRef.SetRange(30000);
                            FindUniqueRecursiveTerm := TermLineRecordRef.FindFirst();
                            if FindUniqueRecursiveTerm then
                                FindUniqueRecursiveTerm := TermLineRecordRef.Next(1) = 0;
                            if FindUniqueRecursiveTerm then begin
                                RecurciveTermRecordRef.Open(TermNameRecordRef.Number);
                                RecurciveTermFieldRef := RecurciveTermRecordRef.Field(GenTermProfile."Section Code (Hdr)");
                                RecurciveTermFieldRef.SetRange(SectionCode);
                                RecurciveTermFieldRef := RecurciveTermRecordRef.Field(GenTermProfile."Term Code (Hdr)");
                                GenTermProfile.TestField("Bal. Account No. (Line)");
                                FieldRefValue(TermLineFieldRef, TermLineRecordRef, GenTermProfile."Bal. Account No. (Line)");
                                RecurciveTermFieldRef.SetRange(TermLineFieldRef.Value);
                                FindUniqueRecursiveTerm := RecurciveTermRecordRef.FindFirst();
                                if FindUniqueRecursiveTerm then
                                    FindUniqueRecursiveTerm := RecurciveTermRecordRef.Next(1) = 0;
                            end;
                            if FindUniqueRecursiveTerm then begin
                                RecurciveTermRecordRef.SetView(TermNameRecordRef.GetView(false));
                                Output := CalcTermValue(RecurciveTermRecordRef, TempDimBuf);
                            end else
                                Operand := 0;

                            ExitCycle := true;
                        end;
                end;
                if not ExitCycle then
                    ExitCycle := TermLineRecordRef.Next(1) = 0;
            until ExitCycle;

        if GenTermProfile."Process Sign (Hdr)" <> 0 then begin
            FieldRefValue(TermFieldRef, TermNameRecordRef, GenTermProfile."Process Sign (Hdr)");
            ValidateSign := TermFieldRef.Value();
            case ValidateSign of
                ValidateSign::"Skip Negative":
                    if Output < 0 then
                        Output := 0;
                ValidateSign::"Skip Positive":
                    if Output > 0 then
                        Output := 0;
                ValidateSign::"Always Negative":
                    Output := -Abs(Output);
                ValidateSign::"Always Positve":
                    Output := Abs(Output);
            end;
        end;

        if GenTermProfile."Rounding Precision (Hdr)" <> 0 then begin
            FieldRefValue(TermFieldRef, TermNameRecordRef, GenTermProfile."Rounding Precision (Hdr)");
            RoundingPrecision := TermFieldRef.Value();
            if RoundingPrecision <> 0 then
                Output := Round(Output, RoundingPrecision);
        end;
    end;

    local procedure CalcExpressionValue(var TemplateRecordRef: RecordRef): Decimal
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        TaxRegNormGroup: Record "Tax Register Norm Group";
        TaxRegNormDetail: Record "Tax Register Norm Detail";
        TermNameRecordRef: RecordRef;
        TermNameFieldRef: FieldRef;
        TemplateFieldRef: FieldRef;
        LinkTableFieldRef: FieldRef;
        TemplateCode: Code[10];
        TemplateLine: Integer;
        Expression: Text[250];
        ExpressionType: Option Term,Link,Total,Header,SumField,Norm;
        FindUniqueTerm: Boolean;
        RoundingPrecision: Decimal;
    begin
        GenTemplateProfile.TestField(Code);
        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile.Code);
        TemplateCode := TemplateFieldRef.Value();
        GenTemplateProfile.TestField("Line No.");
        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Line No.");
        TemplateLine := TemplateFieldRef.Value();
        if not TaxRegValueBuffer.Get(TemplateCode, TemplateLine) then begin
            TaxRegValueBuffer.Quantity := 0;
            GenTemplateProfile.TestField("Expression Type");
            FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Expression Type");
            ExpressionType := TemplateFieldRef.Value();
            GenTemplateProfile.TestField(Expression);
            FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile.Expression);
            Expression := TemplateFieldRef.Value();
            if Expression <> '' then begin
                case ExpressionType of
                    ExpressionType::Norm:
                        begin
                            TaxRegNormDetail.SetRange("Norm Type", TaxRegNormDetail."Norm Type"::Amount);
                            TaxRegNormDetail.SetRange("Norm Group Code", Expression);
                            GenTemplateProfile.TestField("Norm Jurisd. Code (Line)");
                            FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Norm Jurisd. Code (Line)");
                            TaxRegNormGroup."Norm Jurisdiction Code" := Format(TemplateFieldRef.Value);
                            TaxRegNormDetail.SetRange("Norm Jurisdiction Code", TaxRegNormGroup."Norm Jurisdiction Code");
                            GenTemplateProfile.TestField("Date Filter");
                            FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Date Filter");
                            if TemplateFieldRef.Class = FieldClass::FlowFilter then
                                TaxRegNormDetail.SetFilter("Effective Date", TemplateFieldRef.GetFilter)
                            else
                                TaxRegNormDetail.SetFilter("Effective Date", Format(TemplateFieldRef.Value));
                            TaxRegNormGroup.Code := CopyStr(Expression, 1, MaxStrLen(TaxRegNormGroup.Code));
                            TaxRegNormGroup.Find();
                            if TaxRegNormGroup."Search Detail" = TaxRegNormGroup."Search Detail"::"To Date" then begin
                                TaxRegNormDetail.SetFilter("Effective Date", '..%1', TaxRegNormDetail.GetRangeMax("Effective Date"));
                                if TaxRegNormDetail.FindLast() then
                                    TaxRegValueBuffer.Quantity := TaxRegNormDetail.Norm;
                            end else begin
                                TaxRegNormDetail.SetRange("Effective Date", TaxRegNormDetail.GetRangeMax("Effective Date"));
                                if TaxRegNormDetail.FindLast() then
                                    TaxRegValueBuffer.Quantity := TaxRegNormDetail.Norm;
                            end;
                        end;
                    ExpressionType::Term:
                        begin
                            CopyTemplateDimFilters(TempDimBuf, Format(TemplateFieldRef.Value), TemplateCode, TemplateLine);
                            TermNameRecordRef.Open(GenTemplateProfile."Term Header Table No.");
                            GenTemplateProfile.TestField("Section Code");
                            FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Section Code");
                            GenTermProfile.TestField("Section Code (Hdr)");
                            TermNameFieldRef := TermNameRecordRef.Field(GenTermProfile."Section Code (Hdr)");
                            TermNameFieldRef.SetRange(Format(TemplateFieldRef.Value));
                            GenTermProfile.TestField("Term Code (Hdr)");
                            TermNameFieldRef := TermNameRecordRef.Field(GenTermProfile."Term Code (Hdr)");
                            TermNameFieldRef.SetRange(Expression);
                            FindUniqueTerm := TermNameRecordRef.FindFirst();
                            if FindUniqueTerm then
                                FindUniqueTerm := TermNameRecordRef.Next(1) = 0;
                            if FindUniqueTerm then begin
                                GenTermProfile.TestField("Date Filter (Hdr)");
                                TermNameFieldRef := TermNameRecordRef.Field(GenTermProfile."Date Filter (Hdr)");
                                GenTemplateProfile.TestField("Date Filter");
                                FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Date Filter");
                                if TemplateFieldRef.Class = FieldClass::FlowFilter then
                                    TermNameFieldRef.SetFilter(TemplateFieldRef.GetFilter)
                                else
                                    TermNameFieldRef.SetFilter(Format(TemplateFieldRef.Value));
                                TaxRegValueBuffer.Quantity := CalcTermValue(TermNameRecordRef, TempDimBuf);
                            end;
                        end;
                    ExpressionType::Link:
                        if GenTemplateProfile."Value (Link)" <> 0 then begin
                            GenTemplateProfile.TestField(Code);
                            FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Link Code");
                            LinkTableFieldRef := LinkTableRecordRef.Field(GenTemplateProfile."Header Code (Link)");
                            LinkTableFieldRef.SetRange(TemplateFieldRef.Value);
                            LinkTableFieldRef := LinkTableRecordRef.Field(GenTemplateProfile."Line Code (Link)");
                            LinkTableFieldRef.SetRange(Expression);
                            if LinkTableRecordRef.FindFirst() then begin
                                FieldRefValue(LinkTableFieldRef, LinkTableRecordRef, GenTemplateProfile."Value (Link)");
                                TaxRegValueBuffer.Quantity := LinkTableFieldRef.Value();
                            end;
                        end;
                    ExpressionType::Total:
                        TaxRegValueBuffer.Quantity := CalcTotalValue(Expression, TemplateCode, TemplateLine);
                end;
                if GenTemplateProfile."Rounding Precision" <> 0 then begin
                    FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Rounding Precision");
                    RoundingPrecision := TemplateFieldRef.Value();
                    if RoundingPrecision <> 0 then
                        TaxRegValueBuffer.Quantity := Round(TaxRegValueBuffer.Quantity, RoundingPrecision);
                end;
            end;
            TaxRegValueBuffer."Order No." := TemplateCode;
            TaxRegValueBuffer."Order Line No." := TemplateLine;
            TaxRegValueBuffer.Insert();

            if CreateCalcBuf and (ExpressionType = ExpressionType::Total) then begin
                TempTaxRegCalcBuf."Term Type" := TempTaxRegCalcBuf."Term Type"::None;
                TempTaxRegCalcBuf.Operation := TempTaxRegCalcBuf.Operation::None;
                TempTaxRegCalcBuf."Account Type" := TempTaxRegCalcBuf."Account Type"::None;
                TempTaxRegCalcBuf."Account No." := '';
                TempTaxRegCalcBuf."Amount Type" := TempTaxRegCalcBuf."Amount Type"::" ";
                TempTaxRegCalcBuf."Bal. Account No." := '';
                TempTaxRegCalcBuf."Process Sign" := TempTaxRegCalcBuf."Process Sign"::None;
                TempTaxRegCalcBuf."Tax Register No." := TemplateCode;
                TempTaxRegCalcBuf."Template Line No." := TemplateLine;
                TempTaxRegCalcBuf."Term Line No." := 0;
                TempTaxRegCalcBuf."Date Filter" := CopyStr(GlobalDateFilter, 1, MaxStrLen(TempTaxRegCalcBuf."Date Filter"));
                if GenTemplateProfile.Description <> 0 then begin
                    FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile.Description);
                    TempTaxRegCalcBuf.Description := TemplateFieldRef.Value();
                end;
                if GenTemplateProfile."Line Code (Line)" <> 0 then begin
                    FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Line Code (Line)");
                    TempTaxRegCalcBuf."Line Code" := TemplateFieldRef.Value();
                end;
                TempTaxRegCalcBuf."Section Code" := GlobalSectionCode;
                TempTaxRegCalcBuf."Expression Type" := ExpressionType;
                TempTaxRegCalcBuf.Expression := Expression;
                TempTaxRegCalcBuf.Amount := TaxRegValueBuffer.Quantity;
                TempTaxRegCalcBuf."Entry No." += 1;
                TempTaxRegCalcBuf.Insert();
            end;
        end;
        exit(TaxRegValueBuffer.Quantity);
    end;

    local procedure CalcTotalValue(Expression: Text[150]; TemplateCode: Code[10]; TemplateLineNo: Integer) Output: Decimal
    var
        TemplateRecordRef: RecordRef;
        TemplateFieldRef: FieldRef;
        Brackets: Integer;
        Operator: Char;
        LeftOperand: Text[80];
        RightOperand: Text[80];
        LeftCalcValue: Decimal;
        RightCalcValue: Decimal;
        idx: Integer;
        HasExpression: Boolean;
        Operators: Text[8];
        OperatorNo: Integer;
        FigureBrackets: Integer;
        AngleBrackets: Integer;
    begin
        Output := 0;

        RecurcLevel := RecurcLevel + 1;

        if RecurcLevel > 25 then
            ShowError(ErrorInvolve, TemplateCode, TemplateLineNo);

        Expression := DelChr(Expression, '<>', ' ');
        if StrLen(Expression) > 0 then begin
            Brackets := 0;
            HasExpression := false;
            Operators := '+-*/^?';
            OperatorNo := 1;
            repeat
                idx := StrLen(Expression);
                repeat
                    if Expression[idx] = '(' then
                        Brackets := Brackets + 1
                    else
                        if Expression[idx] = ')' then
                            Brackets := Brackets - 1
                        else
                            if Expression[idx] = '{' then
                                FigureBrackets := FigureBrackets + 1
                            else
                                if Expression[idx] = '}' then
                                    FigureBrackets := FigureBrackets - 1
                                else
                                    if Expression[idx] = '<' then
                                        AngleBrackets := AngleBrackets + 1
                                    else
                                        if Expression[idx] = '>' then
                                            AngleBrackets := AngleBrackets - 1;
                    if (AngleBrackets = 0) and
                       (FigureBrackets = 0) and
                       (Brackets = 0) and
                       (Expression[idx] = Operators[OperatorNo])
                    then
                        HasExpression := true
                    else
                        idx -= 1;
                until HasExpression or (idx <= 0);
                if not HasExpression then
                    OperatorNo := OperatorNo + 1;
            until (OperatorNo > StrLen(Operators)) or HasExpression;
            if HasExpression then begin
                if idx > 1 then
                    LeftOperand := CopyStr(Expression, 1, idx - 1)
                else
                    LeftOperand := '';
                if idx < StrLen(Expression) then
                    RightOperand := CopyStr(Expression, idx + 1)
                else
                    RightOperand := '';
                Operator := Expression[idx];
                LeftCalcValue := CalcTotalValue(LeftOperand, TemplateCode, TemplateLineNo);
                RightCalcValue := CalcTotalValue(RightOperand, TemplateCode, TemplateLineNo);
                case Operator of
                    '^':
                        if LeftCalcValue < RightCalcValue then
                            Output := RightCalcValue
                        else
                            Output := LeftCalcValue;
                    '?':
                        if LeftCalcValue > RightCalcValue then
                            Output := RightCalcValue
                        else
                            Output := LeftCalcValue;
                    '*':
                        Output := LeftCalcValue * RightCalcValue;
                    '/':
                        if RightCalcValue = 0 then
                            Output := 0
                        else
                            Output := LeftCalcValue / RightCalcValue;
                    '+':
                        Output := LeftCalcValue + RightCalcValue;
                    '-':
                        Output := LeftCalcValue - RightCalcValue;
                end;
            end else
                if ((Expression[1] = '(') and (Expression[StrLen(Expression)] = ')')) or
                   ((Expression[1] = '<') and (Expression[StrLen(Expression)] = '>')) or
                   ((Expression[1] = '{') and (Expression[StrLen(Expression)] = '}'))
                then begin
                    Output :=
                      CalcTotalValue(
                        CopyStr(Expression, 2, StrLen(Expression) - 2),
                        TemplateCode, TemplateLineNo);
                    if Expression[1] = '<' then
                        Output := Abs(Output)
                    else
                        if (Expression[1] = '{') and (Output < 0) then
                            Output := 0;
                end else begin
                    TemplateRecordRef.Open(GenTemplateProfile."Template Line Table No.");
                    GenTemplateProfile.TestField("Line Code (Line)");
                    TemplateFieldRef := TemplateRecordRef.Field(GenTemplateProfile."Line Code (Line)");
                    if StrLen(Expression) > TemplateFieldRef.Length then begin
                        if not EvaluateDecimal(Output, Expression) then
                            ShowError(ErrorValue, TemplateCode, TemplateLineNo);
                    end else begin
                        GenTemplateProfile.TestField("Section Code");
                        TemplateFieldRef := TemplateRecordRef.Field(GenTemplateProfile."Section Code");
                        TemplateFieldRef.SetRange(GlobalSectionCode);
                        GenTemplateProfile.TestField(Code);
                        TemplateFieldRef := TemplateRecordRef.Field(GenTemplateProfile.Code);
                        TemplateFieldRef.SetRange(TemplateCode);
                        GenTemplateProfile.TestField("Line Code (Line)");
                        TemplateFieldRef := TemplateRecordRef.Field(GenTemplateProfile."Line Code (Line)");
                        TemplateFieldRef.SetFilter(Expression);
                        if TemplateRecordRef.FindFirst() then begin
                            GenTemplateProfile.TestField("Date Filter");
                            TemplateFieldRef := TemplateRecordRef.Field(GenTemplateProfile."Date Filter");
                            TemplateFieldRef.SetFilter(GlobalDateFilter);
                            Output := CalcExpressionValue(TemplateRecordRef)
                        end else
                            if not EvaluateDecimal(Output, Expression) then
                                ShowError(ErrorValue, TemplateCode, TemplateLineNo);
                    end;

                    if CreateCalcBuf then begin
                        TempTaxRegCalcBuf."Term Type" := TempTaxRegCalcBuf."Term Type"::None;
                        TempTaxRegCalcBuf.Operation := TempTaxRegCalcBuf.Operation::None;
                        TempTaxRegCalcBuf."Account Type" := TempTaxRegCalcBuf."Account Type"::None;
                        TempTaxRegCalcBuf."Account No." := '';
                        TempTaxRegCalcBuf."Amount Type" := TempTaxRegCalcBuf."Amount Type"::" ";
                        TempTaxRegCalcBuf."Bal. Account No." := '';
                        TempTaxRegCalcBuf."Process Sign" := TempTaxRegCalcBuf."Process Sign"::None;
                        TempTaxRegCalcBuf."Template Line No." := TemplateLineNo;
                        TempTaxRegCalcBuf."Tax Register No." := TemplateCode;
                        TempTaxRegCalcBuf."Date Filter" := CopyStr(GlobalDateFilter, 1, MaxStrLen(TempTaxRegCalcBuf."Date Filter"));
                        TempTaxRegCalcBuf.Description := '';
                        TempTaxRegCalcBuf."Line Code" := '';
                        TempTaxRegCalcBuf."Section Code" := GlobalSectionCode;
                        TempTaxRegCalcBuf."Term Line No." := 0;
                        TempTaxRegCalcBuf."Expression Type" := TempTaxRegCalcBuf."Expression Type"::Total;
                        TempTaxRegCalcBuf.Expression := Expression;
                        TempTaxRegCalcBuf.Amount := Output;
                        TempTaxRegCalcBuf."Entry No." += 1;
                        TempTaxRegCalcBuf.Insert();
                    end;
                end;
        end;
        RecurcLevel := RecurcLevel - 1;
        exit(Output);
    end;

    local procedure ShowError(MessageString: Text[100]; LineNo: Code[10]; ColumnNo: Integer)
    begin
        Error(MessageString + ErrorText1 + ErrorText2,
          GlobalTemplateCode, GlobalTemplateLineNo,
          LineNo, ColumnNo);
    end;

    local procedure EvaluateDecimal(var Dec: Decimal; Text: Text[30]) Bool: Boolean
    begin
        Bool := Evaluate(Dec, Text);
        if not Bool then begin
            if DecimalsSymbols = '' then
                DecimalsSymbols := PadStr('', 2, CopyStr(Format(0.0, 0, '<Integer><Decimals,3>'), 2, 1));
            Text := ConvertStr(Text, '.,', DecimalsSymbols);
            Bool := Evaluate(Dec, Text);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckTaxRegTerm(ErrorCycleLink: Boolean; SectionCode: Code[10]; TermNameTableNo: Integer; TermLineTableNo: Integer)
    var
        GenTermProfile: Record "Gen. Term Profile";
        TermNameRecordRef: RecordRef;
        TermNameRecordRef1: RecordRef;
        TermLineRecordRef: RecordRef;
        TermNameFieldRef: FieldRef;
        TermNameFieldRef1: FieldRef;
        TermLineFieldRef: FieldRef;
        AnythingChange: Boolean;
        FoundTerm: Boolean;
        Total: Integer;
        Progressing: Integer;
        AccountType: Option Constant,"GL Acc",Termin,"Net Change",Norm;
        LineOperation: Option "+","-","*","/",Negative,Zero,Positive;
    begin
        GenTermProfile.Get(TermNameTableNo);
        TermNameRecordRef.Open(TermNameTableNo);
        TermNameFieldRef := TermNameRecordRef.Field(GenTermProfile."Section Code (Hdr)");
        TermNameFieldRef.SetRange(SectionCode);
        if not TermNameRecordRef.FindFirst() then begin
            TermNameRecordRef.Close();
            exit;
        end;

        Total := TermNameRecordRef.Count();
        Progressing := 0;
        Window.Open(WinTestText + '@1@@@@@@@@@@@@@@@@@@@@@@@@@');

        TermNameFieldRef := TermNameRecordRef.Field(GenTermProfile."Check (Hdr)");
        repeat
            TermNameFieldRef.Value := true;
            TermNameRecordRef.Modify();
        until TermNameRecordRef.Next(1) = 0;

        TermLineRecordRef.Open(TermLineTableNo);
        TermLineFieldRef := TermLineRecordRef.Field(GenTermProfile."Section Code (Line)");
        TermLineFieldRef.SetRange(SectionCode);

        TermNameRecordRef1.Open(TermNameTableNo);

        TermNameFieldRef.SetRange(true);
        repeat
            AnythingChange := false;
            if TermNameRecordRef.FindSet() then
                repeat
                    FoundTerm := false;
                    TermNameFieldRef := TermNameRecordRef.Field(GenTermProfile."Term Code (Hdr)");
                    TermLineFieldRef := TermLineRecordRef.Field(GenTermProfile."Term Code (Line)");
                    TermLineFieldRef.SetRange(Format(TermNameFieldRef.Value));
                    if TermLineRecordRef.FindSet() then
                        repeat
                            TermLineFieldRef := TermLineRecordRef.Field(GenTermProfile."Account Type (Line)");
                            AccountType := TermLineFieldRef.Value();
                            if AccountType = AccountType::Termin then begin
                                TermNameFieldRef1 := TermNameRecordRef1.Field(GenTermProfile."Section Code (Hdr)");
                                TermNameFieldRef1.SetRange(SectionCode);
                                TermNameFieldRef1 := TermNameRecordRef1.Field(GenTermProfile."Term Code (Hdr)");
                                TermLineFieldRef := TermLineRecordRef.Field(GenTermProfile."Account No. (Line)");
                                TermNameFieldRef1.SetRange(Format(TermLineFieldRef.Value));
                                if TermNameRecordRef1.FindFirst() then begin
                                    TermNameFieldRef1 := TermNameRecordRef1.Field(GenTermProfile."Check (Hdr)");
                                    Evaluate(FoundTerm, Format(TermNameFieldRef1.Value));
                                end;
                            end;
                            if not FoundTerm then begin
                                TermLineFieldRef := TermLineRecordRef.Field(GenTermProfile."Operation (Line)");
                                LineOperation := TermLineFieldRef.Value();
                                if LineOperation in [LineOperation::Negative .. LineOperation::Positive] then begin
                                    TermNameFieldRef1 := TermNameRecordRef1.Field(GenTermProfile."Section Code (Hdr)");
                                    TermNameFieldRef1.SetRange(SectionCode);
                                    TermNameFieldRef1 := TermNameRecordRef1.Field(GenTermProfile."Term Code (Hdr)");
                                    TermLineFieldRef := TermLineRecordRef.Field(GenTermProfile."Bal. Account No. (Line)");
                                    TermNameFieldRef1.SetRange(Format(TermLineFieldRef.Value));
                                    if TermNameRecordRef1.FindFirst() then begin
                                        TermNameFieldRef1 := TermNameRecordRef1.Field(GenTermProfile."Check (Hdr)");
                                        Evaluate(FoundTerm, Format(TermNameFieldRef1.Value));
                                    end;
                                end;
                            end;
                        until not FoundTerm or (TermLineRecordRef.Next() = 0);
                    if not FoundTerm then begin
                        AnythingChange := true;
                        TermNameRecordRef1 := TermNameRecordRef.Duplicate();
                        TermNameFieldRef1 := TermNameRecordRef1.Field(GenTermProfile."Check (Hdr)");
                        TermNameFieldRef1.Value := false;
                        TermNameRecordRef1.Modify();
                        Progressing := Progressing + 1;
                        Window.Update(1, Round((Progressing * 10000) / Total, 1, '='));
                    end;
                until TermNameRecordRef.Next(1) = 0;
        until not AnythingChange;

        Window.Close();

        if ErrorCycleLink then begin
            if TermNameRecordRef.FindFirst() then
                Error(ReportTest2, TermNameRecordRef.Count);
        end else
            if not TermNameRecordRef.FindFirst() then
                Message(ReportTest1)
            else
                Message(ReportTest2, TermNameRecordRef.Count);
    end;

    [Scope('OnPrem')]
    procedure CheckTaxRegLink(ErrorCycleLink: Boolean; SectionCode: Code[10]; TableNo: Integer)
    var
        TemplateProfile: Record "Gen. Template Profile";
        TemplateHeaderRecordRef: RecordRef;
        TemplateHeaderRecordRef1: RecordRef;
        TemplateLineRecordRef: RecordRef;
        TemplateHeaderFieldRef: FieldRef;
        TemplateHeaderFieldRef1: FieldRef;
        TemplateLineFieldRef: FieldRef;
        AnythingChange: Boolean;
        FoundLink: Boolean;
        Total: Integer;
        Progressing: Integer;
        LinkLevel: Integer;
        FoundLevel: Integer;
        ExpressionType: Option Term,Link,Total,Header,SumField,Norm;
    begin
        TemplateProfile.Get(TableNo);
        TemplateHeaderRecordRef.Open(TemplateProfile."Template Header Table No.");
        TemplateHeaderFieldRef := TemplateHeaderRecordRef.Field(TemplateProfile."Section Code (Hdr)");
        TemplateHeaderFieldRef.SetRange(SectionCode);
        if not TemplateHeaderRecordRef.FindFirst() then begin
            TemplateHeaderRecordRef.Close();
            exit;
        end;

        Total := TemplateHeaderRecordRef.Count();
        Progressing := 0;
        Window.Open(WinTestText + '@1@@@@@@@@@@@@@@@@@@@@@@@@@');

        TemplateHeaderFieldRef := TemplateHeaderRecordRef.Field(TemplateProfile."Check (Hdr)");
        TemplateHeaderFieldRef1 := TemplateHeaderRecordRef.Field(TemplateProfile."Level (Hdr)");
        repeat
            TemplateHeaderFieldRef.Value := true;
            TemplateHeaderFieldRef1.Value := 0;
            TemplateHeaderRecordRef.Modify();
        until TemplateHeaderRecordRef.Next(1) = 0;

        TemplateLineRecordRef.Open(TemplateProfile."Template Line Table No.");
        TemplateLineFieldRef := TemplateLineRecordRef.Field(TemplateProfile."Section Code");
        TemplateLineFieldRef.SetRange(SectionCode);

        TemplateHeaderFieldRef.SetRange(true);

        if TemplateProfile."Storing Method (Hdr)" <> 0 then begin
            TemplateHeaderFieldRef := TemplateHeaderRecordRef.Field(TemplateProfile."Storing Method (Hdr)");
            TemplateHeaderFieldRef.SetRange(1);
        end;

        TemplateHeaderRecordRef1.Open(TemplateProfile."Template Header Table No.");
        TemplateHeaderFieldRef1 := TemplateHeaderRecordRef1.Field(TemplateProfile."Section Code (Hdr)");
        TemplateHeaderFieldRef1.SetRange(SectionCode);

        LinkLevel := 0;
        repeat
            AnythingChange := false;
            LinkLevel += 1;
            if TemplateHeaderRecordRef.FindSet() then
                repeat
                    FoundLink := false;
                    FieldRefValue(TemplateHeaderFieldRef, TemplateHeaderRecordRef, TemplateProfile."Code (Hdr)");
                    TemplateLineFieldRef := TemplateLineRecordRef.Field(TemplateProfile.Code);
                    TemplateLineFieldRef.SetRange(Format(TemplateHeaderFieldRef.Value));
                    TemplateLineFieldRef := TemplateLineRecordRef.Field(TemplateProfile."Expression Type");
                    TemplateLineFieldRef.SetRange(ExpressionType::Link);
                    if TemplateLineRecordRef.FindSet() then
                        repeat
                            FieldRefValue(TemplateLineFieldRef, TemplateLineRecordRef, TemplateProfile."Link Code");
                            TemplateHeaderFieldRef1 := TemplateHeaderRecordRef1.Field(TemplateProfile."Code (Hdr)");
                            TemplateHeaderFieldRef1.SetRange(Format(TemplateLineFieldRef.Value));
                            if TemplateProfile."Storing Method (Hdr)" <> 0 then begin
                                TemplateHeaderFieldRef1 := TemplateHeaderRecordRef1.Field(TemplateProfile."Storing Method (Hdr)");
                                TemplateHeaderFieldRef1.SetRange(1);
                            end;
                            if TemplateHeaderRecordRef1.FindFirst() then begin
                                FieldRefValue(TemplateHeaderFieldRef1, TemplateHeaderRecordRef1, TemplateProfile."Check (Hdr)");
                                Evaluate(FoundLink, Format(TemplateHeaderFieldRef1.Value));
                                if not FoundLink then begin
                                    FieldRefValue(TemplateHeaderFieldRef1, TemplateHeaderRecordRef1, TemplateProfile."Level (Hdr)");
                                    Evaluate(FoundLevel, Format(TemplateHeaderFieldRef1.Value));
                                    FoundLink := LinkLevel = FoundLevel;
                                end;
                            end;
                        until FoundLink or (TemplateLineRecordRef.Next(1) = 0);
                    if not FoundLink then begin
                        AnythingChange := true;
                        TemplateHeaderRecordRef1 := TemplateHeaderRecordRef.Duplicate();
                        TemplateHeaderFieldRef1 := TemplateHeaderRecordRef1.Field(TemplateProfile."Check (Hdr)");
                        TemplateHeaderFieldRef1.Value := false;
                        TemplateHeaderFieldRef1 := TemplateHeaderRecordRef1.Field(TemplateProfile."Level (Hdr)");
                        TemplateHeaderFieldRef1.Value := LinkLevel;
                        TemplateHeaderRecordRef1.Modify();
                        Progressing := Progressing + 1;
                        Window.Update(1, Round((Progressing * 10000) / Total, 1, '='));
                    end;
                until TemplateHeaderRecordRef.Next(1) = 0;
        until not AnythingChange;

        Window.Close();

        if ErrorCycleLink then begin
            if TemplateHeaderRecordRef.FindFirst() then
                Error(ReportTest2, TemplateHeaderRecordRef.Count);
        end else
            if not TemplateHeaderRecordRef.FindFirst() then
                Message(ReportTest1)
            else
                Message(ReportTest2, TemplateHeaderRecordRef.Count);
    end;

    [Scope('OnPrem')]
    procedure AccumulateTaxRegTemplate(var TemplateRecordRef: RecordRef; var EntryNoAmountBuffer: Record "Entry No. Amount Buffer"; var LinlkAccumulateRecordRef: RecordRef)
    var
        TemplateRecordRef1: RecordRef;
        TemplateFieldRef: FieldRef;
        TemplatePeriod: Text[250];
        MinRangeDateFilter: Date;
        MaxRangeDateFilter: Date;
    begin
        GenTemplateProfile.Get(TemplateRecordRef.Number);
        GenTermProfile.Get(GenTemplateProfile."Term Header Table No.");

        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Section Code");
        GlobalSectionCode := TemplateFieldRef.Value();
        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile.Code);
        GlobalTemplateCode := TemplateFieldRef.Value();
        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Line No.");
        GlobalTemplateLineNo := TemplateFieldRef.Value();
        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Date Filter");
        GlobalDateFilter := TemplateFieldRef.GetFilter;

        TemplateRecordRef1 := TemplateRecordRef.Duplicate();
        TemplateFieldRef := TemplateRecordRef1.Field(GenTemplateProfile."Section Code");
        TemplateFieldRef.SetRange(GlobalSectionCode);
        TemplateFieldRef := TemplateRecordRef1.Field(GenTemplateProfile.Code);
        TemplateFieldRef.SetRange(GlobalTemplateCode);

        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Date Filter");
        Evaluate(MinRangeDateFilter, Format(TemplateFieldRef.GetRangeMin));
        Evaluate(MaxRangeDateFilter, Format(TemplateFieldRef.GetRangeMax));

        TaxRegValueBuffer.Reset();
        TaxRegValueBuffer.DeleteAll();

        if GenTemplateProfile."Value (Link)" <> 0 then begin
            LinkTableRecordRef := LinlkAccumulateRecordRef.Duplicate();
            LinkTableRecordRef.SetView(LinlkAccumulateRecordRef.GetView(false));
        end;

        if TemplateRecordRef1.FindSet() then
            repeat
                FieldRefValue(TemplateFieldRef, TemplateRecordRef1, GenTemplateProfile.Period);
                TemplatePeriod := TemplateFieldRef.Value();
                GlobalDateFilter :=
                  CalcIntervalDate(MinRangeDateFilter, MaxRangeDateFilter, TemplatePeriod);

                RecurcLevel := 0;

                EntryNoAmountBuffer.Amount := CalcExpressionValue(TemplateRecordRef1);
                FieldRefValue(TemplateFieldRef, TemplateRecordRef1, GenTemplateProfile."Line No.");
                Evaluate(EntryNoAmountBuffer."Entry No.", Format(TemplateFieldRef.Value));
                EntryNoAmountBuffer.Insert();

            until TemplateRecordRef1.Next(1) = 0;
    end;

    [Scope('OnPrem')]
    procedure CalculateTemplateEntry(var TemplateRecordRef: RecordRef; var EntryNoAmountBuffer: Record "Entry No. Amount Buffer"; var LinlkAccumulateRecordRef: RecordRef; var TmpEntryValueBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        TemplateRecordRef1: RecordRef;
        TemplateFieldRef: FieldRef;
        TemplatePeriod: Text[250];
        MinRangeDateFilter: Date;
        MaxRangeDateFilter: Date;
    begin
        GenTemplateProfile.Get(TemplateRecordRef.Number);
        GenTermProfile.Get(GenTemplateProfile."Term Header Table No.");

        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Section Code");
        GlobalSectionCode := TemplateFieldRef.Value();
        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile.Code);
        GlobalTemplateCode := TemplateFieldRef.Value();
        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Line No.");
        GlobalTemplateLineNo := TemplateFieldRef.Value();
        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Date Filter");
        GlobalDateFilter := TemplateFieldRef.GetFilter;

        TemplateRecordRef1 := TemplateRecordRef.Duplicate();
        TemplateFieldRef := TemplateRecordRef1.Field(GenTemplateProfile."Section Code");
        TemplateFieldRef.SetRange(GlobalSectionCode);
        TemplateFieldRef := TemplateRecordRef1.Field(GenTemplateProfile.Code);
        TemplateFieldRef.SetRange(GlobalTemplateCode);

        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Date Filter");
        Evaluate(MinRangeDateFilter, Format(TemplateFieldRef.GetRangeMin));
        Evaluate(MaxRangeDateFilter, Format(TemplateFieldRef.GetRangeMax));

        TaxRegValueBuffer.Reset();
        TaxRegValueBuffer.DeleteAll();
        if TmpEntryValueBuffer.FindSet() then
            repeat
                TaxRegValueBuffer := TmpEntryValueBuffer;
                TaxRegValueBuffer.Insert();
            until TmpEntryValueBuffer.Next(1) = 0;

        if GenTemplateProfile."Value (Link)" <> 0 then begin
            LinkTableRecordRef := LinlkAccumulateRecordRef.Duplicate();
            LinkTableRecordRef.SetView(LinlkAccumulateRecordRef.GetView(false));
        end;

        if TemplateRecordRef1.FindSet() then
            repeat
                FieldRefValue(TemplateFieldRef, TemplateRecordRef1, GenTemplateProfile.Period);
                TemplatePeriod := TemplateFieldRef.Value();
                GlobalDateFilter :=
                  CalcIntervalDate(MinRangeDateFilter, MaxRangeDateFilter, TemplatePeriod);

                RecurcLevel := 0;

                EntryNoAmountBuffer.Amount := CalcExpressionValue(TemplateRecordRef1);
                FieldRefValue(TemplateFieldRef, TemplateRecordRef1, GenTemplateProfile."Line No.");
                Evaluate(EntryNoAmountBuffer."Entry No.", Format(TemplateFieldRef.Value));
                EntryNoAmountBuffer.Insert();

            until TemplateRecordRef1.Next(1) = 0;
    end;

    [Scope('OnPrem')]
    procedure ShowExpressionValue(var TemplateRecordRef: RecordRef; var TaxRegCalcBuffer: Record "Tax Register Calc. Buffer"; var LinlkAccumulateRecordRef: RecordRef)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        TaxRegNormGroup: Record "Tax Register Norm Group";
        TaxRegNormDetail: Record "Tax Register Norm Detail";
        TemplateRecordRef1: RecordRef;
        TemplateFieldRef: FieldRef;
        TermNameRecordRef: RecordRef;
        TermNameFieldRef: FieldRef;
        TemplatePeriod: Text[250];
        MinRangeDateFilter: Date;
        MaxRangeDateFilter: Date;
        Expression: Text[1024];
        ExpressionType: Option Term,Link,Total,Header,SumField,Norm;
        FindUniqueTerm: Boolean;
    begin
        GenTemplateProfile.Get(TemplateRecordRef.Number);
        GenTermProfile.Get(GenTemplateProfile."Term Header Table No.");

        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Section Code");
        GlobalSectionCode := TemplateFieldRef.Value();
        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile.Code);
        GlobalTemplateCode := TemplateFieldRef.Value();
        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Line No.");
        GlobalTemplateLineNo := TemplateFieldRef.Value();
        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile.Period);
        TemplatePeriod := TemplateFieldRef.Value();
        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Date Filter");
        Evaluate(MinRangeDateFilter, Format(TemplateFieldRef.GetRangeMin));
        Evaluate(MaxRangeDateFilter, Format(TemplateFieldRef.GetRangeMax));
        GlobalDateFilter :=
          CalcIntervalDate(MinRangeDateFilter, MaxRangeDateFilter, TemplatePeriod);

        TempTaxRegCalcBuf.Reset();
        TempTaxRegCalcBuf.DeleteAll();
        CreateCalcBuf := true;
        RecurcLevel := 0;

        TemplateRecordRef1 := TemplateRecordRef.Duplicate();
        TemplateFieldRef := TemplateRecordRef1.Field(GenTemplateProfile."Section Code");
        TemplateFieldRef.SetRange(GlobalSectionCode);
        TemplateFieldRef := TemplateRecordRef1.Field(GenTemplateProfile.Code);
        TemplateFieldRef.SetRange(GlobalTemplateCode);
        TemplateFieldRef := TemplateRecordRef1.Field(GenTemplateProfile."Date Filter");
        TemplateFieldRef.SetFilter(GlobalDateFilter);

        if GenTemplateProfile."Value (Link)" <> 0 then begin
            LinkTableRecordRef := LinlkAccumulateRecordRef.Duplicate();
            LinkTableRecordRef.SetView(LinlkAccumulateRecordRef.GetView(false));
        end;

        TempTaxRegCalcBuf.Amount := 0;
        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Expression Type");
        ExpressionType := TemplateFieldRef.Value();
        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile.Expression);
        Expression := TemplateFieldRef.Value();
        if Expression <> '' then
            case ExpressionType of
                ExpressionType::Norm:
                    begin
                        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Norm Jurisd. Code (Line)");
                        TaxRegNormGroup."Norm Jurisdiction Code" := Format(TemplateFieldRef.Value);
                        TaxRegNormDetail.SetRange("Norm Jurisdiction Code", TaxRegNormGroup."Norm Jurisdiction Code");
                        TaxRegNormDetail.SetRange("Norm Group Code", Expression);
                        TaxRegNormDetail.SetRange("Norm Type", TaxRegNormDetail."Norm Type"::Amount);
                        TaxRegNormDetail.SetFilter("Effective Date", GlobalDateFilter);
                        TaxRegNormGroup.Code := CopyStr(Expression, 1, MaxStrLen(TaxRegNormGroup.Code));
                        TaxRegNormGroup.Find();
                        if TaxRegNormGroup."Search Detail" = TaxRegNormGroup."Search Detail"::"To Date" then begin
                            TaxRegNormDetail.SetFilter("Effective Date", '..%1', TaxRegNormDetail.GetRangeMax("Effective Date"));
                            if TaxRegNormDetail.FindLast() then
                                TempTaxRegCalcBuf.Amount := TaxRegNormDetail.Norm;
                        end else begin
                            TaxRegNormDetail.SetRange("Effective Date", TaxRegNormDetail.GetRangeMax("Effective Date"));
                            TaxRegNormDetail.FindLast();
                            TempTaxRegCalcBuf.Amount := TaxRegNormDetail.Norm;
                        end;
                    end;
                ExpressionType::Term:
                    begin
                        TermNameRecordRef.Open(GenTemplateProfile."Term Header Table No.");
                        GenTermProfile.TestField("Section Code (Hdr)");
                        TermNameFieldRef := TermNameRecordRef.Field(GenTermProfile."Section Code (Hdr)");
                        TermNameFieldRef.SetRange(Format(GlobalSectionCode));
                        GenTermProfile.TestField("Term Code (Hdr)");
                        TermNameFieldRef := TermNameRecordRef.Field(GenTermProfile."Term Code (Hdr)");
                        TermNameFieldRef.SetRange(Expression);
                        FindUniqueTerm := TermNameRecordRef.FindFirst();
                        if FindUniqueTerm then
                            FindUniqueTerm := TermNameRecordRef.Next(1) = 0;
                        if FindUniqueTerm then begin
                            GenTermProfile.TestField("Date Filter (Hdr)");
                            TermNameFieldRef := TermNameRecordRef.Field(GenTermProfile."Date Filter (Hdr)");
                            TermNameFieldRef.SetFilter(GlobalDateFilter);
                            CopyTemplateDimFilters(TempDimBuf, GlobalSectionCode, GlobalTemplateCode, GlobalTemplateLineNo);
                            TempTaxRegCalcBuf.Amount := CalcTermValue(TermNameRecordRef, TempDimBuf);
                        end;
                    end;
                ExpressionType::Total:
                    TempTaxRegCalcBuf.Amount := CalcTotalValue(Expression, GlobalTemplateCode, GlobalTemplateLineNo);
            end;
        TempTaxRegCalcBuf."Term Type" := TempTaxRegCalcBuf."Term Type"::None;
        TempTaxRegCalcBuf.Operation := TempTaxRegCalcBuf.Operation::None;
        TempTaxRegCalcBuf."Account Type" := TempTaxRegCalcBuf."Account Type"::None;
        TempTaxRegCalcBuf."Account No." := '';
        TempTaxRegCalcBuf."Amount Type" := TempTaxRegCalcBuf."Amount Type"::" ";
        TempTaxRegCalcBuf."Bal. Account No." := '';
        TempTaxRegCalcBuf."Process Sign" := TempTaxRegCalcBuf."Process Sign"::None;
        TempTaxRegCalcBuf."Template Line No." := GlobalTemplateLineNo;
        TempTaxRegCalcBuf."Term Line No." := 0;
        TempTaxRegCalcBuf."Tax Register No." := GlobalTemplateCode;
        TempTaxRegCalcBuf."Date Filter" := CopyStr(GlobalDateFilter, 1, MaxStrLen(TempTaxRegCalcBuf."Date Filter"));
        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile.Description);
        TempTaxRegCalcBuf.Description := TemplateFieldRef.Value();
        FieldRefValue(TemplateFieldRef, TemplateRecordRef, GenTemplateProfile."Line Code (Line)");
        TempTaxRegCalcBuf."Line Code" := TemplateFieldRef.Value();
        TempTaxRegCalcBuf."Section Code" := GlobalSectionCode;
        TempTaxRegCalcBuf."Expression Type" := ExpressionType;
        TempTaxRegCalcBuf.Expression := Expression;
        TempTaxRegCalcBuf."Entry No." += 1;
        TempTaxRegCalcBuf.Insert();

        CreateCalcBuf := false;
        TaxRegCalcBuffer.Reset();
        TaxRegCalcBuffer.DeleteAll();

        TempTaxRegCalcBuf.Reset();
        if TempTaxRegCalcBuf.FindSet() then
            repeat
                TaxRegCalcBuffer := TempTaxRegCalcBuf;
                TaxRegCalcBuffer.Insert();
            until TempTaxRegCalcBuf.Next(1) = 0;
    end;

    [Scope('OnPrem')]
    procedure CalcIntervalDate(PeriodStart: Date; PeriodEnd: Date; DateFilter: Text[250]): Text[30]
    var
        Position: Integer;
        LengthDateFilter: Integer;
    begin
        LengthDateFilter := StrLen(DateFilter);
        DateFilter := UpperCase(DateFilter);
        Position := StrPos(DateFilter, '..');

        case true of
            Position in [1, 3]:
                case CopyStr(DateFilter, 1, 4) of
                    '..CP':
                        if PeriodEnd <> 0D then
                            if LengthDateFilter > 4 then
                                exit(
                                  StrSubstNo(
                                    '%2..%1',
                                    CalcDate(CopyStr(DateFilter, 5), PeriodEnd),
                                    CalcDate('<-CY-1Y>', PeriodEnd)))
                            else
                                exit(StrSubstNo('..%1', CalcDate('<-CY-1D>', PeriodEnd)))
                        else
                            exit(
                              StrSubstNo(
                                '%2..%1',
                                WorkDate(),
                                CalcDate('<-CY>', WorkDate())));
                    '..BD':
                        if PeriodStart <> 0D then
                            if LengthDateFilter > 4 then
                                exit(
                                  StrSubstNo(
                                    '..%1',
                                    CalcDate(CopyStr(DateFilter, 5), CalcDate('<-1D>', PeriodStart))))
                            else
                                exit(StrSubstNo('..%1', CalcDate('<-1D>', PeriodStart)))
                        else
                            exit(StrSubstNo('..%1', CalcDate('<-1D>', WorkDate())));
                    '..ED':
                        if PeriodEnd <> 0D then
                            if LengthDateFilter > 4 then
                                exit(StrSubstNo('..%1', CalcDate(CopyStr(DateFilter, 5), PeriodEnd)))
                            else
                                exit(StrSubstNo('..%1', PeriodEnd))
                        else
                            exit(StrSubstNo('..%1', CalcDate('<1D>', WorkDate())));
                    'BD..':
                        if PeriodStart <> 0D then
                            if LengthDateFilter > 4 then
                                exit(StrSubstNo('%1..', CalcDate(CopyStr(DateFilter, 5), PeriodStart)))
                            else
                                exit(StrSubstNo('%1..', PeriodStart))
                        else
                            exit(StrSubstNo('%1..', WorkDate()));
                    'ED..':
                        if PeriodEnd <> 0D then
                            if LengthDateFilter > 4 then
                                exit(StrSubstNo('%1..', CalcDate(CopyStr(DateFilter, 5), CalcDate('<+1D>', PeriodEnd))))
                            else
                                exit(StrSubstNo('%1..', CalcDate('<+1D>', PeriodEnd)))
                        else
                            exit(StrSubstNo('%1..', CalcDate('<+1D>', WorkDate())));
                    'CP..':
                        if LengthDateFilter = 4 then begin
                            if PeriodStart <> 0D then
                                exit(StrSubstNo('%1..', CalcDate('<-CY>', PeriodStart)));
                            if PeriodEnd <> 0D then
                                exit(StrSubstNo('%1..', CalcDate('<-CY>', PeriodEnd)));
                        end else
                            if (CopyStr(DateFilter, 5, 2) = 'BD') and (PeriodStart <> 0D) then
                                if LengthDateFilter > 6 then
                                    exit(StrSubstNo('%1..%2', CalcDate('<-CY>', PeriodStart), CalcDate(CopyStr(DateFilter, 7), PeriodStart - 1)))
                                else
                                    exit(StrSubstNo('%1..%2', CalcDate('<-CY>', PeriodStart), PeriodStart - 1))
                            else
                                if (CopyStr(DateFilter, 5, 2) = 'ED') and (PeriodEnd <> 0D) then
                                    if LengthDateFilter > 6 then
                                        exit(StrSubstNo('%1..%2', CalcDate('<-CY>', PeriodStart), CalcDate(CopyStr(DateFilter, 7), PeriodEnd)))
                                    else
                                        exit(StrSubstNo('%1..%2', CalcDate('<-CY>', PeriodEnd), PeriodEnd));
                end;
            Position = 0:
                case CopyStr(DateFilter, 1, 2) of
                    'CP', '':
                        if LengthDateFilter > 2 then
                            if (PeriodStart <> 0D) and (PeriodEnd <> 0D) then
                                exit(
                                  StrSubstNo(
                                    '%1..%2',
                                    CalcDate(CopyStr(DateFilter, 3), PeriodStart),
                                    CalcDate(CopyStr(DateFilter, 3), PeriodEnd)))
                            else
                                if PeriodEnd <> 0D then
                                    exit(
                                      StrSubstNo(
                                        '..%1',
                                        CalcDate(CopyStr(DateFilter, 3), PeriodEnd)))
                                else
                                    if PeriodStart <> 0D then
                                        exit(
                                          StrSubstNo(
                                            '%1',
                                            CalcDate(CopyStr(DateFilter, 3), PeriodStart)))
                                    else
                                        exit(
                                          StrSubstNo(
                                            '..%1',
                                            CalcDate(CopyStr(DateFilter, 3), WorkDate())))
                        else
                            if (PeriodStart <> 0D) and (PeriodEnd <> 0D) then
                                exit(StrSubstNo('%1..%2', PeriodStart, PeriodEnd))
                            else
                                if PeriodEnd <> 0D then
                                    exit(StrSubstNo('..%1', PeriodEnd))
                                else
                                    if PeriodStart <> 0D then
                                        exit(StrSubstNo('%1', PeriodStart))
                                    else
                                        exit(StrSubstNo('..%1', WorkDate()));
                    'BD':
                        if PeriodStart <> 0D then
                            if LengthDateFilter > 2 then
                                exit(StrSubstNo('%1', CalcDate(CopyStr(DateFilter, 3), PeriodStart)))
                            else
                                exit(StrSubstNo('%1', PeriodStart))
                        else
                            if LengthDateFilter > 2 then
                                exit(StrSubstNo('%1', CalcDate(CopyStr(DateFilter, 3), WorkDate())))
                            else
                                exit(StrSubstNo('%1', WorkDate()));
                    'ED':
                        if PeriodEnd <> 0D then
                            if LengthDateFilter > 2 then
                                exit(StrSubstNo('%1', CalcDate(CopyStr(DateFilter, 3), PeriodEnd)))
                            else
                                exit(StrSubstNo('%1', PeriodEnd));
                    else
                        if LengthDateFilter > 2 then
                            exit(StrSubstNo('%1', CalcDate(CopyStr(DateFilter, 3), WorkDate())))
                        else
                            exit(StrSubstNo('%1', WorkDate()));
                end;
        end;

        Error(ErrorDateFilter, DateFilter);
    end;

    [Scope('OnPrem')]
    procedure MakeTermExpressionText(TermCode: Code[20]; SectionCode: Code[10]; TermNameTableNo: Integer; TermLineTableNo: Integer) ExpressionText: Text[250]
    var
        TermProfile: Record "Gen. Term Profile";
        TermLineRecordRef: RecordRef;
        TermLineFieldRef: FieldRef;
        Operation: Text[30];
        ElementType: Text[30];
        Property: Text[30];
        ExpressionLength: Integer;
        OperationCaption: array[10] of Text[30];
        ElementTypeCaption: Text[1024];
        AmountTypeCaption: Text[1024];
        AmountType: Integer;
        LineOperation: Integer;
        AccountType: Option Constant,"GL Acc",Term,"Net Change",Norm;
        ExpressionType: Option "Plus/Minus","Multiply/Divide",Compare;
        AccountNo: Code[250];
        BalAccountNo: Code[250];
    begin
        ExpressionText := '';
        TermProfile.Get(TermNameTableNo);
        TermLineRecordRef.Open(TermLineTableNo);
        TermLineFieldRef := TermLineRecordRef.Field(TermProfile."Section Code (Line)");
        TermLineFieldRef.SetRange(SectionCode);
        TermLineFieldRef := TermLineRecordRef.Field(TermProfile."Term Code (Line)");
        TermLineFieldRef.SetRange(TermCode);
        ExpressionLength := 0;
        if TermLineRecordRef.FindSet() then
            repeat
                OperationCaption[1] := '+';
                OperationCaption[2] := '-';
                OperationCaption[3] := '*';
                OperationCaption[4] := '/';
                OperationCaption[5] := Text17200;
                OperationCaption[6] := Text17201;
                OperationCaption[7] := Text17202;
                ElementTypeCaption := Text17203;
                AmountTypeCaption := Text17204;

                TermLineFieldRef := TermLineRecordRef.Field(TermProfile."Operation (Line)");
                LineOperation := GetStringNoInOptionString(Format(TermLineFieldRef.Value), TermLineFieldRef.OptionMembers);
                Operation := OperationCaption[LineOperation + 1];

                TermLineFieldRef := TermLineRecordRef.Field(TermProfile."Account Type (Line)");
                Evaluate(AccountType, Format(TermLineFieldRef.Value));
                ElementType := SelectStr(AccountType + 1, ElementTypeCaption);
                TermLineFieldRef := TermLineRecordRef.Field(TermProfile."Amount Type (Line)");

                AmountType := GetStringNoInOptionString(Format(TermLineFieldRef.Value), TermLineFieldRef.OptionMembers);
                if AmountType > 0 then
                    Property := SelectStr(AmountType, AmountTypeCaption);
                FieldRefValue(TermLineFieldRef, TermLineRecordRef, TermProfile."Expression Type (Line)");
                Evaluate(ExpressionType, Format(TermLineFieldRef.Value));
                FieldRefValue(TermLineFieldRef, TermLineRecordRef, TermProfile."Account No. (Line)");
                Evaluate(AccountNo, Format(TermLineFieldRef.Value));
                FieldRefValue(TermLineFieldRef, TermLineRecordRef, TermProfile."Bal. Account No. (Line)");
                Evaluate(BalAccountNo, Format(TermLineFieldRef.Value));
                case AccountType of
                    AccountType::Constant,
                  AccountType::Norm,
                  AccountType::Term:
                        if not (ExpressionType = ExpressionType::Compare) then begin
                            AddExprText(ExpressionText, StrSubstNo(Operation, AccountNo));
                            AddExprText(ExpressionText, ElementType);
                            AddExprText(ExpressionText, '(');
                            AddExprText(ExpressionText, BalAccountNo);
                            AddExprText(ExpressionText, ')');
                        end else begin
                            AddExprText(ExpressionText, ElementType);
                            AddExprText(ExpressionText, '(');
                            AddExprText(ExpressionText, AccountNo);
                            AddExprText(ExpressionText, ')');
                            AddExprText(ExpressionText, Operation);
                            AddExprText(ExpressionText, ' ');
                            AddExprText(ExpressionText, Property);
                            AddExprText(ExpressionText, '(');
                            AddExprText(ExpressionText, BalAccountNo);
                            AddExprText(ExpressionText, ')');
                        end;
                    AccountType::"GL Acc":
                        begin
                            AddExprText(ExpressionText, Operation);
                            AddExprText(ExpressionText, ElementType);
                            AddExprText(ExpressionText, '(');
                            AddExprText(ExpressionText, AccountNo);
                            AddExprText(ExpressionText, ',');
                            AddExprText(ExpressionText, Property);
                            AddExprText(ExpressionText, ')');
                        end;
                    AccountType::"Net Change":
                        begin
                            AddExprText(ExpressionText, Operation);
                            AddExprText(ExpressionText, ElementType);
                            AddExprText(ExpressionText, '(');
                            AddExprText(ExpressionText, AccountNo);
                            AddExprText(ExpressionText, ',');
                            AddExprText(ExpressionText, BalAccountNo);
                            AddExprText(ExpressionText, ')');
                        end;
                end;
            until (TermLineRecordRef.Next() = 0) or (ExpressionLength >= MaxStrLen(ExpressionText));
    end;

    local procedure FieldRefValue(var NewFieldRef: FieldRef; RecRef: RecordRef; FieldNo: Integer)
    begin
        NewFieldRef := RecRef.Field(FieldNo);
        if NewFieldRef.Class = FieldClass::FlowField then
            NewFieldRef.CalcField();
    end;

    [Scope('OnPrem')]
    procedure SetDimFilters2GLEntry(var GLEntry: Record "G/L Entry"; var TempDimBuf: Record "Dimension Buffer" temporary): Boolean
    var
        GLSetup: Record "General Ledger Setup";
    begin
        TempDimBuf.Reset();
        TempDimBuf.SetRange("Entry No.", 0);
        if TempDimBuf.FindSet() then begin
            GLSetup.Get();
            repeat
                if TempDimBuf."Dimension Code" = GLSetup."Global Dimension 1 Code" then
                    GLEntry.SetFilter("Global Dimension 1 Code", TempDimBuf."Dimension Value Code")
                else
                    if TempDimBuf."Dimension Code" = GLSetup."Global Dimension 2 Code" then
                        GLEntry.SetFilter("Global Dimension 2 Code", TempDimBuf."Dimension Value Code");
            until TempDimBuf.Next(1) = 0;
        end;
        TempDimBuf.SetRange("Entry No.", 1);
        exit(TempDimBuf.FindFirst())
    end;

    local procedure ValidateGLEntryDimFilters(DimSetID: Integer; var TempDimBuf: Record "Dimension Buffer" temporary): Boolean
    var
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        TempDimBuf.Reset();
        TempDimBuf.SetRange("Entry No.", 1);
        if TempDimBuf.FindSet() then
            repeat
                if DimensionSetEntry.Get(DimSetID, TempDimBuf."Dimension Code") then begin
                    DimensionValue."Dimension Code" := TempDimBuf."Dimension Code";
                    DimensionValue.Code := DimensionSetEntry."Dimension Value Code";
                    DimensionValue.SetRange("Dimension Code", TempDimBuf."Dimension Code");
                    DimensionValue.SetFilter(Code, TempDimBuf."Dimension Value Code");
                    if not DimensionValue.Find() then
                        exit(false);
                end;
            until TempDimBuf.Next(1) = 0;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CopyTemplateDimFilters(var TempDimBuf: Record "Dimension Buffer" temporary; SectionCode: Code[10]; TemplateCode: Code[20]; TemplateLineNo: Integer)
    var
        GLSetup: Record "General Ledger Setup";
        DimFilterRecordRef: RecordRef;
        DimFilterFieldRef: FieldRef;
        DimensionCode: Code[20];
    begin
        TempDimBuf.Reset();
        TempDimBuf.DeleteAll();
        if GenTemplateProfile."Dim. Filter Table No." = 0 then
            exit;
        DimFilterRecordRef.Open(GenTemplateProfile."Dim. Filter Table No.");
        DimFilterFieldRef := DimFilterRecordRef.Field(GenTemplateProfile."Section Code (Dim)");
        DimFilterFieldRef.SetRange(SectionCode);
        DimFilterFieldRef := DimFilterRecordRef.Field(GenTemplateProfile."Tax Register No. (Dim)");
        DimFilterFieldRef.SetRange(TemplateCode);
        if GenTemplateProfile."Define (Dim)" <> 0 then begin
            DimFilterFieldRef := DimFilterRecordRef.Field(GenTemplateProfile."Define (Dim)");
            DimFilterFieldRef.SetRange(0);
        end;
        DimFilterFieldRef := DimFilterRecordRef.Field(GenTemplateProfile."Line No. (Dim)");
        DimFilterFieldRef.SetRange(TemplateLineNo);
        if DimFilterRecordRef.FindSet() then begin
            GLSetup.Get();
            repeat
                FieldRefValue(DimFilterFieldRef, DimFilterRecordRef, GenTemplateProfile."Dimension Code (Dim)");
                DimensionCode := DimFilterFieldRef.Value();
                if DimensionCode in [GLSetup."Global Dimension 1 Code", GLSetup."Global Dimension 2 Code"] then
                    TempDimBuf."Entry No." := 0
                else
                    TempDimBuf."Entry No." := 1;
                TempDimBuf."Dimension Code" := DimensionCode;
                FieldRefValue(DimFilterFieldRef, DimFilterRecordRef, GenTemplateProfile."Dimension Value Filter (Dim)");
                TempDimBuf."Dimension Value Code" := DimFilterFieldRef.Value();
                TempDimBuf.Insert();
            until DimFilterRecordRef.Next(1) = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateLineCode(LineCode: Code[10]; ErrorLevel: Option Error,ReturnCode): Boolean
    begin
        if StrLen(LineCode) <> StrLen(DelChr(LineCode, '=', InvalidSymbol)) then begin
            if ErrorLevel = ErrorLevel::Error then
                Error(ErrorMassage, InvalidSymbol);
            exit(false);
        end;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetStringNoInOptionString(Element: Text[30]; OptionString: Text[30]) ElementNo: Integer
    var
        I: Integer;
    begin
        if OptionString = '' then
            exit(0);

        if Element = '' then
            exit(0);

        for I := 1 to StrPos(OptionString, Element) do
            if OptionString[I] = ',' then
                ElementNo += 1;

        exit(ElementNo)
    end;

    local procedure AddExprText(var ExprText: Text[250]; AddText: Text[250])
    begin
        ExprText := ExprText + CopyStr(AddText, 1, MaxStrLen(ExprText) - StrLen(ExprText));
    end;
}

