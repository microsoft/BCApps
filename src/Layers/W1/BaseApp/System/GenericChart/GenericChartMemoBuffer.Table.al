namespace System.Visualization;

using System.Globalization;

table 9186 "Generic Chart Memo Buffer"
{
    Caption = 'Generic Chart Memo Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
            TableRelation = Language.Code;
        }
        field(4; "Language Name"; Text[50])
        {
            CalcFormula = lookup(Language.Name where(Code = field("Language Code")));
            Caption = 'Language Name';
            FieldClass = FlowField;
        }
        field(11; Memo1; Text[250])
        {
            Caption = 'Memo1';
            DataClassification = SystemMetadata;
        }
        field(12; Memo2; Text[250])
        {
            Caption = 'Memo2';
            DataClassification = SystemMetadata;
        }
        field(13; Memo3; Text[250])
        {
            Caption = 'Memo3';
            DataClassification = SystemMetadata;
        }
        field(14; Memo4; Text[250])
        {
            Caption = 'Memo4';
            DataClassification = SystemMetadata;
        }
        field(15; Memo5; Text[250])
        {
            Caption = 'Memo5';
            DataClassification = SystemMetadata;
        }
        field(16; Memo6; Text[250])
        {
            Caption = 'Memo6';
            DataClassification = SystemMetadata;
        }
        field(17; Memo7; Text[250])
        {
            Caption = 'Memo7';
            DataClassification = SystemMetadata;
        }
        field(18; Memo8; Text[250])
        {
            Caption = 'Memo8';
            DataClassification = SystemMetadata;
        }
        field(19; Memo9; Text[250])
        {
            Caption = 'Memo9';
            DataClassification = SystemMetadata;
        }
        field(20; Memo10; Text[250])
        {
            Caption = 'Memo10';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Code", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0470
        TextMemoToBeTruncatedMsg: Label 'The length of the text that you entered is %1. The maximum length is %2. The text has been truncated to this length.';
#pragma warning restore AA0470

    procedure GetMemo(CodeIn: Code[10]; LanguageCode: Code[10]): Text
    begin
        if Get(CodeIn, LanguageCode) then
            exit(GetMemoText());
    end;

    procedure SetMemo(CodeIn: Code[10]; LanguageCode: Code[10]; MemoIn: Text)
    begin
        if Get(CodeIn, LanguageCode) then begin
            SetMemoText(MemoIn);
            Modify();
        end else begin
            Code := CodeIn;
            "Language Code" := LanguageCode;
            SetMemoText(MemoIn);
            Insert();
        end
    end;

    procedure GetMemoText(): Text
    begin
        exit(Memo1 + Memo2 + Memo3 + Memo4 + Memo5 + Memo6 + Memo7 + Memo8 + Memo9 + Memo10)
    end;

    procedure SetMemoText(MemoIn: Text)
    begin
        if StrLen(MemoIn) > GetMaxMemoLength() then begin
            Message(TextMemoToBeTruncatedMsg, StrLen(MemoIn), GetMaxMemoLength());
            MemoIn := CopyStr(MemoIn, 1, GetMaxMemoLength());
        end;

        Memo1 := CopyStr(MemoIn, 1, 250);
        Memo2 := CopyStr(MemoIn, 251, 250);
        Memo3 := CopyStr(MemoIn, 501, 250);
        Memo4 := CopyStr(MemoIn, 751, 250);
        Memo5 := CopyStr(MemoIn, 1001, 250);
        Memo6 := CopyStr(MemoIn, 1251, 250);
        Memo7 := CopyStr(MemoIn, 1501, 250);
        Memo8 := CopyStr(MemoIn, 1751, 250);
        Memo9 := CopyStr(MemoIn, 2001, 250);
        Memo10 := CopyStr(MemoIn, 2251, 250)
    end;

    local procedure GetMaxMemoLength(): Integer
    begin
        exit(2500);
    end;
}

