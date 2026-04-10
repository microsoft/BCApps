#pragma warning disable AA0247
table 14940 "G/L Corr. Analysis View"
{
    Caption = 'G/L Corr. Analysis View';
    DataCaptionFields = "Code", Name;
    LookupPageID = "G/L Corr. Analysis View List";
    Permissions = TableData "Analysis View Entry" = rimd,
                  TableData "Analysis View Budget Entry" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(4; "Last Entry No."; Integer)
        {
            Caption = 'Last Entry No.';
        }
        field(6; "Last Date Updated"; Date)
        {
            Caption = 'Last Date Updated';
        }
        field(7; "Update on G/L Corr. Creation"; Boolean)
        {
            Caption = 'Update on G/L Corr. Creation';
        }
        field(8; Blocked; Boolean)
        {
            Caption = 'Blocked';

            trigger OnValidate()
            begin
                if not Blocked then begin
                    ValidateDelete(FieldCaption(Blocked));
                    AnalysisViewReset();
                end;
            end;
        }
        field(10; "Business Unit Filter"; Code[250])
        {
            Caption = 'Business Unit Filter';
            TableRelation = "Business Unit";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
                BusUnit: Record "Business Unit";
                TempBusUnit: Record "Business Unit" temporary;
            begin
                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and (xRec."Business Unit Filter" = '') and
                   ("Business Unit Filter" <> xRec."Business Unit Filter")
                then begin
                    ValidateModify(FieldCaption("Business Unit Filter"));
                    if BusUnit.FindSet() then
                        repeat
                            TempBusUnit := BusUnit;
                            TempBusUnit.Insert();
                        until BusUnit.Next() = 0;
                    TempBusUnit.Init();
                    TempBusUnit.Code := '';
                    TempBusUnit.Insert();
                    TempBusUnit.SetFilter(Code, "Business Unit Filter");
                    TempBusUnit.DeleteAll();
                    TempBusUnit.SetRange(Code);
                    if TempBusUnit.FindSet() then
                        repeat
                            GLCorrAnalysisViewEntry.SetRange("G/L Corr. Analysis View Code", Code);
                            GLCorrAnalysisViewEntry.SetRange("Business Unit Code", TempBusUnit.Code);
                            GLCorrAnalysisViewEntry.DeleteAll();
                        until TempBusUnit.Next() = 0
                end;
                if ("Last Entry No." <> 0) and (xRec."Business Unit Filter" <> '') and
                   ("Business Unit Filter" <> xRec."Business Unit Filter")
                then begin
                    ValidateDelete(FieldCaption("Business Unit Filter"));
                    AnalysisViewReset();
                end;
            end;
        }
        field(11; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and ("Starting Date" <> xRec."Starting Date") then begin
                    ValidateDelete(FieldCaption("Starting Date"));
                    AnalysisViewReset();
                end;
            end;
        }
        field(12; "Debit Account Filter"; Code[250])
        {
            Caption = 'Debit Account Filter';
            TableRelation = "G/L Account";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
                GLAcc: Record "G/L Account";
            begin
                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and (xRec."Debit Account Filter" = '') and
                   ("Debit Account Filter" <> '')
                then begin
                    ValidateModify(FieldCaption("Debit Account Filter"));
                    GLAcc.SetFilter("No.", "Debit Account Filter");
                    if GLAcc.FindSet() then
                        repeat
                            GLAcc.Mark := true;
                        until GLAcc.Next() = 0;
                    GLAcc.SetRange("No.");
                    if GLAcc.FindSet() then
                        repeat
                            if not GLAcc.Mark() then begin
                                GLCorrAnalysisViewEntry.SetRange("G/L Corr. Analysis View Code", Code);
                                GLCorrAnalysisViewEntry.SetRange("Debit Account No.", GLAcc."No.");
                                GLCorrAnalysisViewEntry.DeleteAll();
                            end;
                        until GLAcc.Next() = 0;
                end;
                if ("Last Entry No." <> 0) and ("Debit Account Filter" <> xRec."Debit Account Filter") and
                   (xRec."Debit Account Filter" <> '')
                then begin
                    ValidateDelete(FieldCaption("Debit Account Filter"));
                    AnalysisViewReset();
                end;
            end;
        }
        field(13; "Credit Account Filter"; Code[250])
        {
            Caption = 'Credit Account Filter';
            TableRelation = "G/L Account";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
                GLAcc: Record "G/L Account";
            begin
                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and (xRec."Credit Account Filter" = '') and
                   ("Credit Account Filter" <> '')
                then begin
                    ValidateModify(FieldCaption("Credit Account Filter"));
                    GLAcc.SetFilter("No.", "Credit Account Filter");
                    if GLAcc.FindSet() then
                        repeat
                            GLAcc.Mark := true;
                        until GLAcc.Next() = 0;
                    GLAcc.SetRange("No.");
                    if GLAcc.FindSet() then
                        repeat
                            if not GLAcc.Mark() then begin
                                GLCorrAnalysisViewEntry.SetRange("G/L Corr. Analysis View Code", Code);
                                GLCorrAnalysisViewEntry.SetRange("Credit Account No.", GLAcc."No.");
                                GLCorrAnalysisViewEntry.DeleteAll();
                            end;
                        until GLAcc.Next() = 0;
                end;
                if ("Last Entry No." <> 0) and ("Credit Account Filter" <> xRec."Credit Account Filter") and
                   (xRec."Credit Account Filter" <> '')
                then begin
                    ValidateDelete(FieldCaption("Credit Account Filter"));
                    AnalysisViewReset();
                end;
            end;
        }
        field(15; "Date Compression"; Option)
        {
            Caption = 'Date Compression';
            InitValue = Day;
            OptionCaption = 'None,Day,Week,Month,Quarter,Year,Period';
            OptionMembers = "None",Day,Week,Month,Quarter,Year,Period;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and ("Date Compression" <> xRec."Date Compression") then begin
                    ValidateDelete(FieldCaption("Date Compression"));
                    AnalysisViewReset();
                end;
            end;
        }
        field(20; "Debit Dimension 1 Code"; Code[20])
        {
            Caption = 'Debit Dimension 1 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if CheckIfDimUsed("Debit Dimension 1 Code", 0, 1) then
                    Error(Text000);
                ModifyDim(FieldCaption("Debit Dimension 1 Code"), "Debit Dimension 1 Code", xRec."Debit Dimension 1 Code");
                Modify();
            end;
        }
        field(21; "Debit Dimension 2 Code"; Code[20])
        {
            Caption = 'Debit Dimension 2 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if CheckIfDimUsed("Debit Dimension 2 Code", 0, 2) then
                    Error(Text000);
                ModifyDim(FieldCaption("Debit Dimension 2 Code"), "Debit Dimension 2 Code", xRec."Debit Dimension 2 Code");
                Modify();
            end;
        }
        field(22; "Debit Dimension 3 Code"; Code[20])
        {
            Caption = 'Debit Dimension 3 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if CheckIfDimUsed("Debit Dimension 3 Code", 0, 3) then
                    Error(Text000);
                ModifyDim(FieldCaption("Debit Dimension 3 Code"), "Debit Dimension 3 Code", xRec."Debit Dimension 3 Code");
                Modify();
            end;
        }
        field(30; "Credit Dimension 1 Code"; Code[20])
        {
            Caption = 'Credit Dimension 1 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if CheckIfDimUsed("Credit Dimension 1 Code", 1, 1) then
                    Error(Text000);
                ModifyDim(FieldCaption("Credit Dimension 1 Code"), "Credit Dimension 1 Code", xRec."Credit Dimension 1 Code");
                Modify();
            end;
        }
        field(31; "Credit Dimension 2 Code"; Code[20])
        {
            Caption = 'Credit Dimension 2 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if CheckIfDimUsed("Credit Dimension 2 Code", 1, 2) then
                    Error(Text000);
                ModifyDim(FieldCaption("Credit Dimension 2 Code"), "Credit Dimension 2 Code", xRec."Credit Dimension 2 Code");
                Modify();
            end;
        }
        field(32; "Credit Dimension 3 Code"; Code[20])
        {
            Caption = 'Credit Dimension 3 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if CheckIfDimUsed("Credit Dimension 3 Code", 1, 3) then
                    Error(Text000);
                ModifyDim(FieldCaption("Credit Dimension 3 Code"), "Credit Dimension 3 Code", xRec."Credit Dimension 3 Code");
                Modify();
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        GLCorrAnalysisViewFilter: Record "G/L Corr. Analysis View Filter";
    begin
        AnalysisViewReset();
        GLCorrAnalysisViewFilter.SetRange("G/L Corr. Analysis View Code", Code);
        GLCorrAnalysisViewFilter.DeleteAll();
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'You cannot use the same dimension twice in the same dimension group.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text011: Label 'If you change the contents of the %1 field, the analysis view entries will be deleted.\You will have to update again.\\Do you want to enter a new value in the %1 field?';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text013: Label 'The update has been interrupted in response to the warning.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text014: Label 'If you change the contents of the %1 field, the analysis view entries will be changed as well.\\Do you want to enter a new value in the %1 field?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
        NewGLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";

    [Scope('OnPrem')]
    procedure ModifyDim(DimFieldName: Text[100]; DimValue: Code[20]; xDimValue: Code[20])
    begin
        if ("Last Entry No." <> 0) and (DimValue <> xDimValue) then begin
            if DimValue <> '' then begin
                ValidateDelete(DimFieldName);
                AnalysisViewReset();
            end;
            if DimValue = '' then begin
                ValidateModify(DimFieldName);
                case DimFieldName of
                    FieldCaption("Debit Dimension 1 Code"):
                        GLCorrAnalysisViewEntry.SetFilter("Debit Dimension 1 Value Code", '<>%1', '');
                    FieldCaption("Debit Dimension 2 Code"):
                        GLCorrAnalysisViewEntry.SetFilter("Debit Dimension 2 Value Code", '<>%1', '');
                    FieldCaption("Debit Dimension 3 Code"):
                        GLCorrAnalysisViewEntry.SetFilter("Debit Dimension 3 Value Code", '<>%1', '');
                    FieldCaption("Credit Dimension 1 Code"):
                        GLCorrAnalysisViewEntry.SetFilter("Credit Dimension 1 Value Code", '<>%1', '');
                    FieldCaption("Credit Dimension 2 Code"):
                        GLCorrAnalysisViewEntry.SetFilter("Credit Dimension 2 Value Code", '<>%1', '');
                    FieldCaption("Credit Dimension 3 Code"):
                        GLCorrAnalysisViewEntry.SetFilter("Credit Dimension 3 Value Code", '<>%1', '');
                end;
                GLCorrAnalysisViewEntry.SetRange("G/L Corr. Analysis View Code", Code);
                if GLCorrAnalysisViewEntry.FindSet() then
                    repeat
                        GLCorrAnalysisViewEntry.Delete();
                        NewGLCorrAnalysisViewEntry := GLCorrAnalysisViewEntry;
                        case DimFieldName of
                            FieldCaption("Debit Dimension 1 Code"):
                                NewGLCorrAnalysisViewEntry."Debit Dimension 1 Value Code" := '';
                            FieldCaption("Debit Dimension 2 Code"):
                                NewGLCorrAnalysisViewEntry."Debit Dimension 2 Value Code" := '';
                            FieldCaption("Debit Dimension 3 Code"):
                                NewGLCorrAnalysisViewEntry."Debit Dimension 3 Value Code" := '';
                            FieldCaption("Credit Dimension 1 Code"):
                                NewGLCorrAnalysisViewEntry."Credit Dimension 1 Value Code" := '';
                            FieldCaption("Credit Dimension 2 Code"):
                                NewGLCorrAnalysisViewEntry."Credit Dimension 2 Value Code" := '';
                            FieldCaption("Credit Dimension 3 Code"):
                                NewGLCorrAnalysisViewEntry."Credit Dimension 3 Value Code" := '';
                        end;
                        InsertAnalysisViewEntry();
                    until GLCorrAnalysisViewEntry.Next() = 0;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertAnalysisViewEntry()
    begin
        if not NewGLCorrAnalysisViewEntry.Insert() then begin
            NewGLCorrAnalysisViewEntry.Find();
            NewGLCorrAnalysisViewEntry.Amount := NewGLCorrAnalysisViewEntry.Amount + GLCorrAnalysisViewEntry.Amount;
            NewGLCorrAnalysisViewEntry."Amount (ACY)" :=
              NewGLCorrAnalysisViewEntry."Amount (ACY)" + GLCorrAnalysisViewEntry."Amount (ACY)";
            NewGLCorrAnalysisViewEntry.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure AnalysisViewReset()
    var
        GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
    begin
        GLCorrAnalysisViewEntry.SetRange("G/L Corr. Analysis View Code", Code);
        GLCorrAnalysisViewEntry.DeleteAll();
        "Last Entry No." := 0;
        "Last Date Updated" := 0D;
    end;

    [Scope('OnPrem')]
    procedure ValidateDelete(FieldName: Text[250])
    var
        Question: Text[250];
    begin
        Question := StrSubstNo(Text011, FieldName);
        if not DIALOG.Confirm(Question, true) then
            Error(Text013);
    end;

    [Scope('OnPrem')]
    procedure ValidateModify(FieldName: Text[250])
    var
        Question: Text[250];
    begin
        Question := StrSubstNo(Text014, FieldName);
        if not DIALOG.Confirm(Question, true) then
            Error(Text013);
    end;

    [Scope('OnPrem')]
    procedure CheckIfDimUsed(DimChecked: Code[20]; GroupChecked: Option Debit,Credit; DimTypeChecked: Option " ",Analysis1,Analysis2,Analysis3,Analysis4): Boolean
    var
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
    begin
        if DimChecked = '' then
            exit;

        GLCorrAnalysisView.SetRange(Code, Code);
        if GLCorrAnalysisView.FindSet() then
            repeat
                case GroupChecked of
                    GroupChecked::Debit:
                        begin
                            if (DimTypeChecked <> DimTypeChecked::Analysis1) and
                               (DimChecked = GLCorrAnalysisView."Debit Dimension 1 Code")
                            then
                                exit(true);
                            if (DimTypeChecked <> DimTypeChecked::Analysis2) and
                               (DimChecked = GLCorrAnalysisView."Debit Dimension 2 Code")
                            then
                                exit(true);
                            if (DimTypeChecked <> DimTypeChecked::Analysis3) and
                               (DimChecked = GLCorrAnalysisView."Debit Dimension 3 Code")
                            then
                                exit(true);
                        end;
                    GroupChecked::Credit:
                        begin
                            if (DimTypeChecked <> DimTypeChecked::Analysis1) and
                               (DimChecked = GLCorrAnalysisView."Credit Dimension 1 Code")
                            then
                                exit(true);
                            if (DimTypeChecked <> DimTypeChecked::Analysis2) and
                               (DimChecked = GLCorrAnalysisView."Credit Dimension 2 Code")
                            then
                                exit(true);
                            if (DimTypeChecked <> DimTypeChecked::Analysis3) and
                               (DimChecked = GLCorrAnalysisView."Credit Dimension 3 Code")
                            then
                                exit(true);
                        end;
                end;
            until GLCorrAnalysisView.Next() = 0;

        exit(false);
    end;
}

