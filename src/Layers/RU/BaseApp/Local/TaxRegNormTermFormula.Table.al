#pragma warning disable AA0247
table 17241 "Tax Reg. Norm Term Formula"
{
    Caption = 'Tax Reg. Norm Term Formula';
    LookupPageID = "Tax Reg. Norm Term Formula";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Norm Jurisdiction Code"; Code[10])
        {
            Caption = 'Norm Jurisdiction Code';
            NotBlank = true;
            TableRelation = "Tax Register Norm Jurisdiction";
        }
        field(2; "Term Code"; Code[20])
        {
            Caption = 'Term Code';
            NotBlank = true;
            TableRelation = "Tax Reg. Norm Term"."Term Code";
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            NotBlank = true;
        }
        field(4; "Expression Type"; Option)
        {
            CalcFormula = lookup("Tax Reg. Norm Term"."Expression Type" where("Term Code" = field("Term Code")));
            Caption = 'Expression Type';
            FieldClass = FlowField;
            OptionCaption = 'Plus/Minus,Multiply/Divide,Compare';
            OptionMembers = "Plus/Minus","Multiply/Divide",Compare;
        }
        field(5; Operation; Option)
        {
            Caption = 'Operation';
            OptionCaption = '+,-,*,/,Negative,Zero,Positive';
            OptionMembers = "+","-","*","/",Negative,Zero,Positive;

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
                   not (Operation = Operation::Negative) and not (Operation = Operation::Zero) and
                   not (Operation = Operation::Positive)
                then
                    Error(Text002);
                ValidateChangeDeclaration(Operation <> xRec.Operation);
            end;
        }
        field(6; "Account Type"; Option)
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
                    if "Account Type" = "Account Type"::Norm then
                        "Jurisdiction Code" := "Norm Jurisdiction Code"
                    else
                        "Jurisdiction Code" := '';
                end;
                ValidateChangeDeclaration("Account Type" <> xRec."Account Type");
            end;
        }
        field(7; "Account No."; Code[100])
        {
            Caption = 'Account No.';
            TableRelation = if ("Expression Type" = filter(<> Compare),
                                "Account Type" = const("GL Acc")) "G/L Account"."No."
            else
            if ("Expression Type" = filter(<> Compare),
                                         "Account Type" = const("Net Change")) "G/L Account"."No."
            else
            if ("Account Type" = const(Termin)) "Tax Reg. Norm Term"."Term Code"
            else
            if ("Account Type" = const(Norm)) "Tax Register Norm Group".Code where("Norm Jurisdiction Code" = field("Jurisdiction Code"),
                                                                                                                    "Has Details" = const(true));
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                TaxRegNormTermFormula: Record "Tax Reg. Norm Term Formula";
            begin
                CalcFields("Expression Type");
                if "Expression Type" = "Expression Type"::Compare then begin
                    TaxRegNormTermFormula.Reset();
                    TaxRegNormTermFormula.SetRange("Norm Jurisdiction Code", "Norm Jurisdiction Code");
                    TaxRegNormTermFormula.SetRange("Term Code", "Term Code");
                    TaxRegNormTermFormula.SetFilter("Line No.", '<>%1', "Line No.");
                    TaxRegNormTermFormula.ModifyAll("Account No.", "Account No.", false);
                    TaxRegNormTermFormula.Reset();
                end;
                if "Account Type" = "Account Type"::Norm then
                    TestField("Jurisdiction Code");
                ValidateChangeDeclaration("Account No." <> xRec."Account No.");
            end;
        }
        field(8; "Amount Type"; Option)
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
                ValidateChangeDeclaration("Amount Type" <> xRec."Amount Type");
            end;
        }
        field(9; "Bal. Account No."; Code[100])
        {
            Caption = 'Bal. Account No.';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;

            trigger OnValidate()
            begin
                CalcFields("Expression Type");
                if ("Account Type" = "Account Type"::"Net Change") or
                   ("Expression Type" = "Expression Type"::Compare)
                then
                    TestField("Bal. Account No.");
                ValidateChangeDeclaration("Bal. Account No." <> xRec."Bal. Account No.");
            end;
        }
        field(10; "Jurisdiction Code"; Code[10])
        {
            Caption = 'Jurisdiction Code';

            trigger OnValidate()
            begin
                ValidateChangeDeclaration("Jurisdiction Code" <> xRec."Jurisdiction Code");
                if "Jurisdiction Code" <> xRec."Jurisdiction Code" then
                    "Account No." := '';
                if "Jurisdiction Code" <> '' then
                    TestField("Account Type", "Account Type"::Norm);
            end;
        }
        field(11; "Process Sign"; Option)
        {
            Caption = 'Process Sign';
            OptionCaption = ' ,Skip Negative,Skip Positive,Always Positive,Always Negative';
            OptionMembers = " ","Skip Negative","Skip Positive","Always Positive","Always Negative";

            trigger OnValidate()
            begin
                ValidateChangeDeclaration("Process Sign" <> xRec."Process Sign");
            end;
        }
        field(12; "Process Division by Zero"; Option)
        {
            Caption = 'Process Division by Zero';
            OptionCaption = 'Zero,One';
            OptionMembers = Zero,One;
        }
    }

    keys
    {
        key(Key1; "Norm Jurisdiction Code", "Term Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ValidateChangeDeclaration(true);
    end;

    trigger OnInsert()
    begin
        ValidateChangeDeclaration(true);
    end;

    trigger OnModify()
    begin
        ValidateChangeDeclaration(true);
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Operation must be + or -.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text001: Label 'Operation must be * or /.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text002: Label 'Operation must be Compare.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'cannot be %1 if Account Type is %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure ValidateChangeDeclaration(Incident: Boolean)
    var
        TaxRegNormJurisdiction: Record "Tax Register Norm Jurisdiction";
    begin
        if not Incident then
            exit;

        TaxRegNormJurisdiction.Get("Norm Jurisdiction Code");
    end;
}

