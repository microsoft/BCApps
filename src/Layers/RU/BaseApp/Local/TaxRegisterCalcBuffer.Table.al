#pragma warning disable AA0247
table 17206 "Tax Register Calc. Buffer"
{
    Caption = 'Tax Register Calc. Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(3; "Term Type"; Option)
        {
            Caption = 'Term Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Plus/Minus,Multiply/Divide,Compare,None';
            OptionMembers = "Plus/Minus","Multiply/Divide",Compare,"None";
        }
        field(4; Operation; Option)
        {
            Caption = 'Operation';
            DataClassification = SystemMetadata;
            OptionCaption = '+,-,*,/,Negative,Zero,Positive,None';
            OptionMembers = "+","-","*","/",Negative,Zero,Positive,"None";
        }
        field(5; "Account Type"; Option)
        {
            Caption = 'Account Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Constant,G/L Account,Term,Correspondence,None';
            OptionMembers = Constant,"G/L Account",Term,Correspondence,"None";
        }
        field(6; "Account No."; Code[100])
        {
            Caption = 'Account No.';
            DataClassification = SystemMetadata;
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(7; "Amount Type"; Option)
        {
            Caption = 'Amount Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Net Change,Debit,Credit';
            OptionMembers = " ","Net Change",Debit,Credit;
        }
        field(8; "Bal. Account No."; Code[100])
        {
            Caption = 'Bal. Account No.';
            DataClassification = SystemMetadata;
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(9; "Process Sign"; Option)
        {
            Caption = 'Process Sign';
            DataClassification = SystemMetadata;
            OptionCaption = 'None,Skip Negative,Skip Positive,Always Positive,Always Negative';
            OptionMembers = "None","Skip Negative","Skip Positive","Always Positive","Always Negative";
        }
        field(10; "Template Line No."; Integer)
        {
            Caption = 'Template Line No.';
            DataClassification = SystemMetadata;
        }
        field(11; "Tax Register No."; Code[10])
        {
            Caption = 'Tax Register No.';
            DataClassification = SystemMetadata;
        }
        field(12; Description; Text[150])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(13; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Register Section";
        }
        field(16; "Line Code"; Code[10])
        {
            Caption = 'Line Code';
            DataClassification = SystemMetadata;
        }
        field(17; "Expression Type"; Option)
        {
            Caption = 'Expression Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Term,Link,Total,Header,SumField';
            OptionMembers = Term,Link,Total,Header,SumField;
        }
        field(18; Expression; Text[250])
        {
            Caption = 'Expression';
            DataClassification = SystemMetadata;
        }
        field(20; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(21; "Date Filter"; Text[30])
        {
            Caption = 'Date Filter';
            DataClassification = SystemMetadata;
        }
        field(22; "Term Line No."; Integer)
        {
            Caption = 'Term Line No.';
            DataClassification = SystemMetadata;
        }
        field(23; "Dimensions Filters"; Boolean)
        {
            CalcFormula = exist("Tax Register Dim. Filter" where("Section Code" = field("Section Code"),
                                                                  "Tax Register No." = field("Tax Register No."),
                                                                  Define = const(Template),
                                                                  "Line No." = field("Template Line No.")));
            Caption = 'Dimensions Filters';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0074
        Text1000: Label 'Filtering only by Global Dimensions.';
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure DrillDownAmount()
    var
        TaxRegTerm: Record "Tax Register Term";
        TaxRegTermFormula: Record "Tax Register Term Formula";
        GLEntry: Record "G/L Entry";
        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
        TaxRegAccumulation: Record "Tax Register Accumulation";
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempGLEntryGlobalDimFilter: Record "G/L Entry" temporary;
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
        NoGlobalDimFilterNeed: Boolean;
    begin
        if "Expression Type" = "Expression Type"::Term then
            if TaxRegTerm.Get("Section Code", Expression) then
                if (TaxRegTerm."Expression Type" <> TaxRegTerm."Expression Type"::Compare) and
                   ("Term Type" < "Term Type"::Compare)
                then
                    if TaxRegTermFormula.Get("Section Code", Expression, "Term Line No.") then begin
                        TaxRegTermMgt.CopyTemplateDimFilters(TempDimBuf, "Section Code", "Tax Register No.", "Template Line No.");
                        NoGlobalDimFilterNeed := TaxRegTermMgt.SetDimFilters2GLEntry(TempGLEntryGlobalDimFilter, TempDimBuf);
                        if NoGlobalDimFilterNeed then
                            Message(Text1000);
                        case TaxRegTermFormula."Account Type" of
                            TaxRegTermFormula."Account Type"::"G/L Account":
                                begin
                                    GLEntry.Reset();
                                    if TempGLEntryGlobalDimFilter.GetFilters = '' then begin
                                        GLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
                                        GLEntry.SetFilter("G/L Account No.", TaxRegTermFormula."Account No.");
                                        GLEntry.SetFilter("Posting Date", "Date Filter");
                                    end else begin
                                        GLEntry.SetCurrentKey(
                                          "G/L Account No.", "Business Unit Code",
                                          "Global Dimension 1 Code", "Global Dimension 2 Code");
                                        GLEntry.SetFilter("G/L Account No.", TaxRegTermFormula."Account No.");
                                        TempGLEntryGlobalDimFilter.CopyFilter(
                                          "Global Dimension 1 Code", GLEntry."Global Dimension 1 Code");
                                        TempGLEntryGlobalDimFilter.CopyFilter(
                                          "Global Dimension 2 Code", GLEntry."Global Dimension 2 Code");
                                    end;
                                    GLEntry.SetFilter("Posting Date", "Date Filter");
                                    if TaxRegTermFormula."Amount Type" = TaxRegTermFormula."Amount Type"::Debit then
                                        GLEntry.SetFilter("Debit Amount", '<>%1', 0);
                                    if TaxRegTermFormula."Amount Type" = TaxRegTermFormula."Amount Type"::Credit then
                                        GLEntry.SetFilter("Credit Amount", '<>%1', 0);
                                    PAGE.RunModal(0, GLEntry);
                                end;
                            TaxRegTermFormula."Account Type"::"Net Change":
                                begin
                                    GLCorrespondenceEntry.Reset();
                                    if TempGLEntryGlobalDimFilter.GetFilters = '' then begin
                                        GLCorrespondenceEntry.SetCurrentKey("Debit Account No.", "Credit Account No.");
                                        GLCorrespondenceEntry.SetFilter("Debit Account No.", TaxRegTermFormula."Account No.");
                                        GLCorrespondenceEntry.SetFilter("Credit Account No.", TaxRegTermFormula."Bal. Account No.");
                                    end else begin
                                        GLCorrespondenceEntry.SetCurrentKey(
                                          "Debit Account No.", "Credit Account No.",
                                          "Debit Global Dimension 1 Code", "Debit Global Dimension 2 Code",
                                          "Business Unit Code", "Posting Date");
                                        GLCorrespondenceEntry.SetFilter("Debit Account No.", TaxRegTermFormula."Account No.");
                                        GLCorrespondenceEntry.SetFilter("Credit Account No.", TaxRegTermFormula."Bal. Account No.");
                                        TempGLEntryGlobalDimFilter.CopyFilter(
                                          "Global Dimension 1 Code", GLCorrespondenceEntry."Debit Global Dimension 1 Code");
                                        TempGLEntryGlobalDimFilter.CopyFilter(
                                          "Global Dimension 2 Code", GLCorrespondenceEntry."Debit Global Dimension 2 Code");
                                    end;
                                    GLCorrespondenceEntry.SetFilter("Posting Date", "Date Filter");
                                    PAGE.RunModal(0, GLCorrespondenceEntry);
                                end;
                        end;
                    end;
        if "Expression Type" = "Expression Type"::Total then begin
            if StrPos("Date Filter", '..') > 0 then begin
                if not Evaluate(TaxRegAccumulation."Starting Date", CopyStr("Date Filter", 1, StrPos("Date Filter", '..') - 1)) then
                    exit;
                if not Evaluate(TaxRegAccumulation."Ending Date", CopyStr("Date Filter", StrPos("Date Filter", '..') + 2)) then
                    exit;
            end else begin
                if not Evaluate(TaxRegAccumulation."Ending Date", "Date Filter") then
                    exit;
                TaxRegAccumulation."Starting Date" := 0D;
            end;
            TaxRegAccumulation."Template Line No." := "Template Line No.";
            TaxRegAccumulation."Tax Register No." := "Tax Register No.";
            TaxRegAccumulation."Section Code" := "Section Code";
            TaxRegAccumulation.SetRange("Date Filter", TaxRegAccumulation."Starting Date", TaxRegAccumulation."Ending Date");
            TaxRegAccumulation.DrillDownAmount();
        end;
    end;
}

