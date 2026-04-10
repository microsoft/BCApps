#pragma warning disable AA0247
table 17308 "Tax Calc. Header"
{
    Caption = 'Tax Calc. Header';
    LookupPageID = "Tax Calc. List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[10])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." = '' then
                    "Register ID" := ''
                else begin
                    NotAllowedChar := '~^';
                    if StrLen(DelChr(ConvertStr("No.", NotAllowedChar, '  '), '=', ' ')) <> StrLen("No.") then
                        Error(Text1001, FieldCaption("No."));
                    "Register ID" := ConvertStr("No.", '.', CopyStr(NotAllowedChar, 2))
                end;
            end;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(3; "Table ID"; Integer)
        {
            BlankZero = true;
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

            trigger OnValidate()
            begin
                if "Table ID" <> xRec."Table ID" then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                    if "Table ID" <> DATABASE::"Tax Calc. G/L Entry" then
                        TestField("G/L Corr. Analysis View Code", '');
                end;
                case "Table ID" of
                    DATABASE::"Tax Calc. G/L Entry",
                  DATABASE::"Tax Calc. Item Entry",
                  DATABASE::"Tax Calc. FA Entry":
                        "Storing Method" := "Storing Method"::"Build Entry";
                    DATABASE::"Tax Calc. Accumulation":
                        "Storing Method" := "Storing Method"::Calculation;
                    else begin
                        "Table ID" := DATABASE::"Tax Calc. G/L Entry";
                        "Storing Method" := "Storing Method"::"Build Entry";
                    end;
                end;
                CalcFields("Table Name");
            end;
        }
        field(4; "Table Name"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Table ID")));
            Caption = 'Table Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));

            trigger OnValidate()
            begin
                CalcFields("Form Name");
            end;
        }
        field(6; "Form Name"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Page),
                                                                           "Object ID" = field("Page ID")));
            Caption = 'Form Name';
            FieldClass = FlowField;
        }
        field(7; Check; Boolean)
        {
            Caption = 'Check';
        }
        field(8; Level; Integer)
        {
            Caption = 'Level';
        }
        field(10; "Register ID"; Code[10])
        {
            Caption = 'Register ID';
            Editable = false;
        }
        field(11; "Storing Method"; Option)
        {
            Caption = 'Storing Method';
            OptionCaption = 'Build Entry,Calculation';
            OptionMembers = "Build Entry",Calculation;

            trigger OnValidate()
            begin
                if "Storing Method" <> xRec."Storing Method" then begin
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                    if "Storing Method" <> "Storing Method"::"Build Entry" then
                        TestField("G/L Corr. Analysis View Code", '');
                end;
            end;
        }
        field(13; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(15; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
            NotBlank = true;
            TableRelation = "Tax Calc. Section";
        }
        field(19; "Tax Diff. Code"; Code[10])
        {
            Caption = 'Tax Diff. Code';
            TableRelation = "Tax Difference";
        }
        field(25; "G/L Corr. Analysis View Code"; Code[10])
        {
            Caption = 'G/L Corr. Analysis View Code';
            TableRelation = "G/L Corr. Analysis View";

            trigger OnValidate()
            var
                TaxDiffGLCorrDimFilter: Record "Tax Diff. Corr. Dim. Filter";
            begin
                if "G/L Corr. Analysis View Code" <> xRec."G/L Corr. Analysis View Code" then begin
                    if "G/L Corr. Analysis View Code" <> '' then begin
                        TestField("Table ID", DATABASE::"Tax Calc. G/L Entry");
                        TestField("Storing Method", "Storing Method"::"Build Entry");
                    end;
                    TaxDiffGLCorrDimFilter.SetRange("Section Code", "Section Code");
                    TaxDiffGLCorrDimFilter.SetRange("Tax Calc. No.", "No.");
                    if not TaxDiffGLCorrDimFilter.IsEmpty() then
                        if Confirm(Text1002, true) then
                            TaxDiffGLCorrDimFilter.DeleteAll()
                        else
                            Error('');
                    TaxCalcSection.Get("Section Code");
                    TaxCalcSection.ValidateChange();
                end;
            end;
        }
        field(30; "Used in Statutory Report"; Boolean)
        {
            CalcFormula = exist("Stat. Report Table Mapping" where("Int. Source Type" = const("Tax Difference"),
                                                                    "Int. Source Section Code" = field("Section Code"),
                                                                    "Int. Source No." = field("No.")));
            Caption = 'Used in Statutory Report';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Section Code", "No.")
        {
            Clustered = true;
        }
        key(Key2; "Section Code", "Tax Diff. Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Tax Diff. Code")
        {
        }
    }

    trigger OnDelete()
    begin
        TaxCalcSection.Get("Section Code");
        TaxCalcSection.ValidateChange();

        TaxCalcSelectionSetup.SetRange("Section Code", "Section Code");
        TaxCalcSelectionSetup.SetRange("Register No.", "No.");
        TaxCalcSelectionSetup.DeleteAll(true);

        TaxCalcLine.SetRange("Section Code", "Section Code");
        TaxCalcLine.SetRange(Code, "No.");
        TaxCalcLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        TaxCalcSection.Get("Section Code");
        TaxCalcSection.ValidateChange();
        TestField("Table ID");
        TestField("No.");
        Validate("No.");
    end;

    trigger OnModify()
    begin
        TestField("Table ID");
    end;

    trigger OnRename()
    begin
        Error(Text1000, TableCaption);
    end;

    var
        TaxCalcSection: Record "Tax Calc. Section";
        TaxCalcSelectionSetup: Record "Tax Calc. Selection Setup";
        TaxCalcLine: Record "Tax Calc. Line";
        NotAllowedChar: Text[10];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1000: Label 'You can''t rename an %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1001: Label 'The value %1 has illegal symbol.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1002: Label 'All related dimension filters will be deleted. Continue?';
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure ShowDetails(TaxCalcLineNo: Integer)
    var
        TaxCalcItemEntry: Record "Tax Calc. Item Entry";
        TaxCalcFAEntry: Record "Tax Calc. FA Entry";
        TaxCalcLine: Record "Tax Calc. Line";
        TaxCalcDimMgt: Codeunit "Tax Calc. Dim. Mgt.";
    begin
        case "Table ID" of
            DATABASE::"Tax Calc. G/L Entry":
                ShowGLEntriesDetails(TaxCalcLineNo);
            DATABASE::"Tax Calc. Item Entry":
                begin
                    TaxCalcItemEntry.Reset();
                    TaxCalcItemEntry.SetCurrentKey("Section Code");
                    CopyFilter("Date Filter", TaxCalcItemEntry."Date Filter");
                    TaxCalcItemEntry.FilterGroup(2);
                    TaxCalcItemEntry.SetRange("Section Code", "Section Code");
                    TaxCalcItemEntry.SetFilter("Where Used Register IDs", '*~' + "Register ID" + '~*');
                    TaxCalcItemEntry.FilterGroup(0);
                    if TaxCalcLineNo <> 0 then begin
                        TaxCalcLine.Get("Section Code", "No.", TaxCalcLineNo);
                        TaxCalcItemEntry.SetTaxCalcFilter(TaxCalcLine);
                        TaxCalcDimMgt.SetDimFilters2TaxCalcItemLine(TaxCalcLine, TaxCalcItemEntry);
                    end;
                    PAGE.Run("Page ID", TaxCalcItemEntry);
                end;
            DATABASE::"Tax Calc. FA Entry":
                begin
                    TaxCalcFAEntry.Reset();
                    TaxCalcFAEntry.SetCurrentKey("Section Code");
                    TaxCalcFAEntry.FilterGroup(2);
                    TaxCalcFAEntry.SetRange("Section Code", "Section Code");
                    TaxCalcFAEntry.SetFilter("Where Used Register IDs", '*~' + "Register ID" + '~*');
                    TaxCalcFAEntry.FilterGroup(0);
                    CopyFilter("Date Filter", TaxCalcFAEntry."Date Filter");
                    if TaxCalcLineNo <> 0 then begin
                        TaxCalcLine.Get("Section Code", "No.", TaxCalcLineNo);
                        if TaxCalcLine."Depreciation Group" <> '' then
                            TaxCalcFAEntry.SetFilter("Depreciation Group", TaxCalcLine."Depreciation Group");
                        if TaxCalcFAEntry.Disposed then
                            TaxCalcFAEntry.SetRange(Disposed, TaxCalcFAEntry.Disposed);
                        if TaxCalcLine."Belonging to Manufacturing" <> 0 then
                            TaxCalcFAEntry.SetRange("Belonging to Manufacturing", TaxCalcLine."Belonging to Manufacturing");
                        if TaxCalcLine."FA Type" <> 0 then
                            TaxCalcFAEntry.SetRange("FA Type", TaxCalcLine."FA Type" - 1);
                    end;
                    PAGE.Run("Page ID", TaxCalcFAEntry);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowGLEntriesDetails(TaxCalcLineNo: Integer)
    var
        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
        TempGLCorrespondenceEntry: Record "G/L Correspondence Entry" temporary;
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
        GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
        TempGLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry" temporary;
        TaxCalcSelectionSetup: Record "Tax Calc. Selection Setup";
        TaxCalcLine: Record "Tax Calc. Line";
        TaxDimMgt: Codeunit "Tax Calc. Dim. Mgt.";
    begin
        TaxCalcLine.Get("Section Code", "No.", TaxCalcLineNo);
        TaxCalcSelectionSetup.SetFilter("Section Code", "Section Code");
        TaxCalcSelectionSetup.SetRange("Register No.", "No.");
        if TaxCalcLine."Selection Line Code" <> '' then
            TaxCalcSelectionSetup.SetRange("Line Code", TaxCalcLine."Selection Line Code");
        if TaxCalcSelectionSetup.FindSet() then
            repeat
                if "G/L Corr. Analysis View Code" <> '' then begin
                    GLCorrAnalysisView.Get("G/L Corr. Analysis View Code");
                    GLCorrAnalysisViewEntry.Reset();
                    TaxDimMgt.SetDimFilters2GLCorrAnViewEntr(
                      GLCorrAnalysisViewEntry,
                      GLCorrAnalysisView,
                      TaxCalcSelectionSetup,
                      TaxCalcLine);
                    CopyFilter("Date Filter", GLCorrAnalysisViewEntry."Posting Date");

                    if TaxCalcSelectionSetup."Account No." <> '' then
                        GLCorrAnalysisViewEntry.SetFilter("Debit Account No.", TaxCalcSelectionSetup."Account No.");
                    if TaxCalcSelectionSetup."Bal. Account No." <> '' then
                        GLCorrAnalysisViewEntry.SetFilter("Credit Account No.", TaxCalcSelectionSetup."Bal. Account No.");
                    AddGLCorrAnViewEntr2Buffer(GLCorrAnalysisViewEntry, TempGLCorrAnalysisViewEntry);
                end else begin
                    CopyFilter("Date Filter", GLCorrespondenceEntry."Posting Date");
                    if TaxCalcSelectionSetup."Account No." <> '' then
                        GLCorrespondenceEntry.SetFilter("Debit Account No.", TaxCalcSelectionSetup."Account No.");
                    if TaxCalcSelectionSetup."Bal. Account No." <> '' then
                        GLCorrespondenceEntry.SetFilter("Credit Account No.", TaxCalcSelectionSetup."Bal. Account No.");
                    AddGLCorrEntries2Buffer(GLCorrespondenceEntry, TempGLCorrespondenceEntry);
                end;
            until TaxCalcSelectionSetup.Next() = 0;

        if "G/L Corr. Analysis View Code" <> '' then
            PAGE.RunModal(PAGE::"G/L Corr. Analysis View Entr.", TempGLCorrAnalysisViewEntry)
        else
            PAGE.RunModal(PAGE::"G/L Correspondence Entries", TempGLCorrespondenceEntry);
    end;

    [Scope('OnPrem')]
    procedure AddGLCorrEntries2Buffer(var GLCorrespondenceEntry: Record "G/L Correspondence Entry"; var TempGLCorrespondenceEntry: Record "G/L Correspondence Entry" temporary)
    begin
        if GLCorrespondenceEntry.FindSet() then
            repeat
                TempGLCorrespondenceEntry := GLCorrespondenceEntry;
                if not TempGLCorrespondenceEntry.Insert() then;
            until GLCorrespondenceEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure AddGLCorrAnViewEntr2Buffer(var GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry"; var TempGLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry" temporary)
    begin
        if GLCorrAnalysisViewEntry.FindSet() then
            repeat
                TempGLCorrAnalysisViewEntry := GLCorrAnalysisViewEntry;
                if not TempGLCorrAnalysisViewEntry.Insert() then;
            until GLCorrAnalysisViewEntry.Next() = 0;
    end;
}

