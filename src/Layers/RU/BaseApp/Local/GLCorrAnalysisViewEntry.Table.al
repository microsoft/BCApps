#pragma warning disable AA0247
table 14942 "G/L Corr. Analysis View Entry"
{
    Caption = 'G/L Corr. Analysis View Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "G/L Corr. Analysis View Code"; Code[10])
        {
            Caption = 'G/L Corr. Analysis View Code';
            NotBlank = true;
            TableRelation = "G/L Corr. Analysis View";
        }
        field(2; "Business Unit Code"; Code[20])
        {
            Caption = 'Business Unit Code';
            TableRelation = "Business Unit";
        }
        field(3; "Debit Account No."; Code[20])
        {
            Caption = 'Debit Account No.';
            TableRelation = "G/L Account";
        }
        field(4; "Credit Account No."; Code[20])
        {
            Caption = 'Credit Account No.';
            TableRelation = "G/L Account";
        }
        field(8; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(9; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(10; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(11; "Amount (ACY)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Amount (ACY)';
        }
        field(20; "Debit Dimension 1 Value Code"; Code[20])
        {
            CaptionClass = GetDebitCaptionClass(1);
            Caption = 'Debit Dimension 1 Value Code';
        }
        field(21; "Debit Dimension 2 Value Code"; Code[20])
        {
            CaptionClass = GetDebitCaptionClass(2);
            Caption = 'Debit Dimension 2 Value Code';
        }
        field(22; "Debit Dimension 3 Value Code"; Code[20])
        {
            CaptionClass = GetDebitCaptionClass(3);
            Caption = 'Debit Dimension 3 Value Code';
        }
        field(30; "Credit Dimension 1 Value Code"; Code[20])
        {
            CaptionClass = GetCreditCaptionClass(1);
            Caption = 'Credit Dimension 1 Value Code';
        }
        field(31; "Credit Dimension 2 Value Code"; Code[20])
        {
            CaptionClass = GetCreditCaptionClass(2);
            Caption = 'Credit Dimension 2 Value Code';
        }
        field(32; "Credit Dimension 3 Value Code"; Code[20])
        {
            CaptionClass = GetCreditCaptionClass(3);
            Caption = 'Credit Dimension 3 Value Code';
        }
    }

    keys
    {
        key(Key1; "G/L Corr. Analysis View Code", "Debit Account No.", "Credit Account No.", "Debit Dimension 1 Value Code", "Debit Dimension 2 Value Code", "Debit Dimension 3 Value Code", "Credit Dimension 1 Value Code", "Credit Dimension 2 Value Code", "Credit Dimension 3 Value Code", "Business Unit Code", "Posting Date", "Entry No.")
        {
            Clustered = true;
            SumIndexFields = Amount, "Amount (ACY)";
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0074
        Text000: Label '1,5,,Debit Dimension 1 Value Code';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text001: Label '1,5,,Debit Dimension 2 Value Code';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text002: Label '1,5,,Debit Dimension 3 Value Code';
#pragma warning restore AA0074
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
#pragma warning disable AA0074
        Text003: Label '1,5,,Credit Dimension 1 Value Code';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text004: Label '1,5,,Credit Dimension 2 Value Code';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text005: Label '1,5,,Credit Dimension 3 Value Code';
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure GetDebitCaptionClass(AnalysisViewDimType: Integer): Text[250]
    begin
        if GLCorrAnalysisView.Code <> "G/L Corr. Analysis View Code" then
            GLCorrAnalysisView.Get("G/L Corr. Analysis View Code");
        case AnalysisViewDimType of
            1:
                begin
                    if GLCorrAnalysisView."Debit Dimension 1 Code" <> '' then
                        exit('1,5,' + GLCorrAnalysisView."Debit Dimension 1 Code");
                    exit(Text000);
                end;
            2:
                begin
                    if GLCorrAnalysisView."Debit Dimension 2 Code" <> '' then
                        exit('1,5,' + GLCorrAnalysisView."Debit Dimension 2 Code");
                    exit(Text001);
                end;
            3:
                begin
                    if GLCorrAnalysisView."Debit Dimension 3 Code" <> '' then
                        exit('1,5,' + GLCorrAnalysisView."Debit Dimension 3 Code");
                    exit(Text002);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCreditCaptionClass(AnalysisViewDimType: Integer): Text[250]
    begin
        if GLCorrAnalysisView.Code <> "G/L Corr. Analysis View Code" then
            GLCorrAnalysisView.Get("G/L Corr. Analysis View Code");
        case AnalysisViewDimType of
            1:
                begin
                    if GLCorrAnalysisView."Credit Dimension 1 Code" <> '' then
                        exit('1,5,' + GLCorrAnalysisView."Credit Dimension 1 Code");
                    exit(Text003);
                end;
            2:
                begin
                    if GLCorrAnalysisView."Credit Dimension 2 Code" <> '' then
                        exit('1,5,' + GLCorrAnalysisView."Credit Dimension 2 Code");
                    exit(Text004);
                end;
            3:
                begin
                    if GLCorrAnalysisView."Credit Dimension 3 Code" <> '' then
                        exit('1,5,' + GLCorrAnalysisView."Credit Dimension 3 Code");
                    exit(Text005);
                end;
        end;
    end;
}

