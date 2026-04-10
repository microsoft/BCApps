#pragma warning disable AA0247
table 17312 "Tax Calc. Term Formula"
{
    Caption = 'Tax Calc. Term Formula';
    LookupPageID = "Tax Calc. Term Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Term Code"; Code[20])
        {
            Caption = 'Term Code';
            NotBlank = true;
            TableRelation = "Tax Calc. Term"."Term Code";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            NotBlank = true;
        }
        field(3; "Expression Type"; Option)
        {
            CalcFormula = lookup("Tax Calc. Term"."Expression Type" where("Term Code" = field("Term Code")));
            Caption = 'Expression Type';
            FieldClass = FlowField;
            OptionCaption = 'Plus/Minus,Multiply/Divide,Compare';
            OptionMembers = "Plus/Minus","Multiply/Divide",Compare;
        }
        field(4; Operation; Option)
        {
            Caption = 'Operation';
            OptionCaption = '+,-,*,/,Less 0,Equ 0,Grate 0';
            OptionMembers = "+","-","*","/","Less 0","Equ 0","Grate 0";

            trigger OnValidate()
            begin
                CalcFields("Expression Type");
                if ("Expression Type" = "Expression Type"::"Plus/Minus") and
                   not (Operation = Operation::"+") and not (Operation = Operation::"-")
                then
                    Error(Text000);

                if ("Expression Type" = "Expression Type"::"Multiply/Divide") and
                   not (Operation = Operation::"*") and not (Operation = Operation::"/")
                then
                    Error(Text001);

                if ("Expression Type" = "Expression Type"::Compare) and
                   not (Operation = Operation::"Less 0") and not (Operation = Operation::"Equ 0") and
                   not (Operation = Operation::"Grate 0")
                then
                    Error(Text002);
                if Operation <> xRec.Operation then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                end;
            end;
        }
        field(5; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'Constant,GL Acc,Termin,Net Change,Norm';
            OptionMembers = Constant,"GL Acc",Termin,"Net Change",Norm;

            trigger OnValidate()
            begin
                CalcFields("Expression Type");
                if "Expression Type" = "Expression Type"::Compare then
                    "Account Type" := "Account Type"::Termin
                else begin
                    "Account No." := '';
                    "Bal. Account No." := '';
                    "Amount Type" := "Amount Type"::Debit
                end;
                if "Account Type" <> xRec."Account Type" then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                end;
            end;
        }
        field(6; "Account No."; Code[100])
        {
            Caption = 'Account No.';
            TableRelation = if ("Expression Type" = filter(<> Compare),
                                "Account Type" = const("GL Acc")) "G/L Account"."No."
            else
            if ("Expression Type" = filter(<> Compare),
                                         "Account Type" = const("Net Change")) "G/L Account"."No."
            else
            if ("Account Type" = const(Termin)) "Tax Calc. Term"."Term Code"
            else
            if ("Account Type" = const(Norm)) "Tax Register Norm Group".Code where("Norm Jurisdiction Code" = field("Norm Jurisdiction Code"),
                                                                                                                    "Has Details" = const(true));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                CalcFields("Expression Type");
                if "Expression Type" = "Expression Type"::Compare then begin
                    TaxCalcTermFormula.Reset();
                    TaxCalcTermFormula.SetRange("Section Code", "Section Code");
                    TaxCalcTermFormula.SetRange("Term Code", "Term Code");
                    TaxCalcTermFormula.SetFilter("Line No.", '<>%1', "Line No.");
                    TaxCalcTermFormula.ModifyAll("Account No.", "Account No.", false);
                    TaxCalcTermFormula.Reset();
                end;
                if "Account No." <> xRec."Account No." then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                end;
            end;
        }
        field(7; "Amount Type"; Option)
        {
            Caption = 'Amount Type';
            OptionCaption = ' ,Net Change,Debit,Credit';
            OptionMembers = " ","Net Change",Debit,Credit;

            trigger OnValidate()
            begin
                if "Account Type" = "Account Type"::"Net Change" then begin
                    if "Amount Type" = "Amount Type"::"Net Change" then
                        "Amount Type" := "Amount Type"::Debit;
                    if not ("Amount Type" in ["Amount Type"::Debit, "Amount Type"::Credit]) then
                        FieldError("Amount Type",
                          StrSubstNo(Text003, "Amount Type", "Account Type"));
                end else
                    if "Account Type" <> "Account Type"::"GL Acc" then
                        TestField("Amount Type", "Amount Type"::" ")
                    else
                        TestField("Amount Type");
                if "Amount Type" <> xRec."Amount Type" then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                end;
            end;
        }
        field(8; "Bal. Account No."; Code[100])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Expression Type" = const(Compare),
                                "Account Type" = const(Termin)) "Tax Calc. Selection Setup"."Register No."
            else
            if ("Account Type" = const("Net Change")) "G/L Account"."No.";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                CalcFields("Expression Type");
                if ("Account Type" = "Account Type"::"Net Change") or
                   ("Expression Type" = "Expression Type"::Compare)
                then
                    TestField("Bal. Account No.");
                if "Bal. Account No." <> xRec."Bal. Account No." then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                end;
            end;
        }
        field(9; "Process Sign"; Option)
        {
            Caption = 'Process Sign';
            OptionCaption = ' ,Skip Negative,Skip Positive,Always Positve,Always Negative';
            OptionMembers = " ","Skip Negative","Skip Positive","Always Positve","Always Negative";

            trigger OnValidate()
            begin
                if "Process Sign" <> xRec."Process Sign" then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                end;
            end;
        }
        field(10; "Process Division by Zero"; Option)
        {
            Caption = 'Process Division by Zero';
            OptionCaption = 'Zero,One';
            OptionMembers = Zero,One;
        }
        field(13; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
            NotBlank = true;
            TableRelation = "Tax Calc. Section";
        }
        field(14; "Norm Jurisdiction Code"; Code[10])
        {
            CalcFormula = lookup("Tax Calc. Section"."Norm Jurisdiction Code" where(Code = field("Section Code")));
            Caption = 'Norm Jurisdiction Code';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Section Code", "Term Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TaxCalcSection.Get("Section Code");
        TaxCalcSection.ValidateChange();
    end;

    trigger OnInsert()
    begin
        TaxCalcSection.Get("Section Code");
        TaxCalcSection.ValidateChange();
    end;

    trigger OnModify()
    begin
        TaxCalcSection.Get("Section Code");
        TaxCalcSection.ValidateChange();
    end;

    var
        TaxCalcTermFormula: Record "Tax Calc. Term Formula";
#pragma warning disable AA0074
        Text000: Label 'Operation must be + or -.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text001: Label 'Operation must be * or /.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text002: Label 'Operation must be Compare.';
#pragma warning restore AA0074
        TaxCalcSection: Record "Tax Calc. Section";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'cannot be %1 if Account Type is %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

