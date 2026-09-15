#pragma warning disable AA0247
table 17200 "Tax Register"
{
    Caption = 'Tax Register';
    LookupPageID = "Tax Register Worksheet";
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
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                    "Costing Method" := "Costing Method"::" ";
                    if "Table ID" <> DATABASE::"Tax Register G/L Entry" then
                        TestField("G/L Corr. Analysis View Code", '');
                end;
                case "Table ID" of
                    DATABASE::"Tax Register G/L Entry",
                    DATABASE::"Tax Register CV Entry",
                    DATABASE::"Tax Register FA Entry",
                    DATABASE::"Tax Register Item Entry",
                    DATABASE::"Tax Register FE Entry":
                        Validate("Storing Method", "Storing Method"::"Build Entry");
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
                CalcFields("Page Name");
            end;
        }
        field(6; "Page Name"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Page),
                                                                           "Object ID" = field("Page ID")));
            Caption = 'Page Name';
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
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                    if "Storing Method" <> "Storing Method"::"Build Entry" then
                        TestField("G/L Corr. Analysis View Code", '');
                end;
            end;
        }
        field(12; "Costing Method"; Option)
        {
            Caption = 'Costing Method';
            OptionCaption = ' ,FIFO,LIFO,Average,FIFO+LIFO';
            OptionMembers = " ",FIFO,LIFO,"Average","FIFO+LIFO";

            trigger OnValidate()
            begin
                if "Costing Method" <> "Costing Method"::" " then
                    TestField("Table ID", DATABASE::"Tax Register Item Entry");
                if "Costing Method" <> xRec."Costing Method" then begin
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
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
            TableRelation = "Tax Register Section";
        }
        field(20; "Used in Statutory Report"; Boolean)
        {
            CalcFormula = exist("Stat. Report Table Mapping" where("Int. Source Type" = const("Tax Register"),
                                                                    "Int. Source Section Code" = field("Section Code"),
                                                                    "Int. Source No." = field("No.")));
            Caption = 'Used in Statutory Report';
            Editable = false;
            FieldClass = FlowField;
        }
        field(25; "G/L Corr. Analysis View Code"; Code[10])
        {
            Caption = 'G/L Corr. Analysis View Code';
            TableRelation = "G/L Corr. Analysis View";

            trigger OnValidate()
            var
                TaxRegGLCorrDimFilter: Record "Tax Reg. G/L Corr. Dim. Filter";
            begin
                if "G/L Corr. Analysis View Code" <> xRec."G/L Corr. Analysis View Code" then begin
                    if "G/L Corr. Analysis View Code" <> '' then begin
                        TestField("Table ID", DATABASE::"Tax Register G/L Entry");
                        TestField("Storing Method", "Storing Method"::"Build Entry");
                    end;
                    TaxRegGLCorrDimFilter.SetRange("Section Code", "Section Code");
                    TaxRegGLCorrDimFilter.SetRange("Tax Register No.", "No.");
                    if not TaxRegGLCorrDimFilter.IsEmpty() then
                        if Confirm(Text1002, true) then
                            TaxRegGLCorrDimFilter.DeleteAll()
                        else
                            Error('');
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Section Code", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description)
        {
        }
    }

    trigger OnDelete()
    begin
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();

        TaxRegLineSetup.SetRange("Section Code", "Section Code");
        TaxRegLineSetup.SetRange("Tax Register No.", "No.");
        TaxRegLineSetup.DeleteAll(true);

        TaxRegTemplate.SetRange("Section Code", "Section Code");
        TaxRegTemplate.SetRange(Code, "No.");
        TaxRegTemplate.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();
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
        TaxRegSection: Record "Tax Register Section";
        TaxRegLineSetup: Record "Tax Register Line Setup";
        TaxRegTemplate: Record "Tax Register Template";
        NotAllowedChar: Text[10];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1000: Label 'You cannot rename an %1.';
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
    procedure ShowDetails(TemplateLineNo: Integer)
    var
        TaxRegCVEntry: Record "Tax Register CV Entry";
        TaxRegItemEntry: Record "Tax Register Item Entry";
        TaxRegFEEntry: Record "Tax Register FE Entry";
        TaxRegTemplate: Record "Tax Register Template";
        TaxDimMgt: Codeunit "Tax Dimension Mgt.";
    begin
        case "Table ID" of
            DATABASE::"Tax Register CV Entry":
                begin
                    TaxRegCVEntry.Reset();
                    TaxRegCVEntry.SetCurrentKey("Section Code");
                    TaxRegCVEntry.FilterGroup(2);
                    TaxRegCVEntry.SetRange("Section Code", "Section Code");
                    TaxRegCVEntry.SetFilter("Where Used Register IDs", '*~' + "Register ID" + '~*');
                    TaxRegCVEntry.FilterGroup(0);
                    CopyFilter("Date Filter", "Date Filter");
                    PAGE.RunModal("Page ID", TaxRegCVEntry);
                end;
            DATABASE::"Tax Register Item Entry":
                begin
                    TaxRegItemEntry.Reset();
                    TaxRegItemEntry.SetCurrentKey("Section Code");
                    TaxRegItemEntry.CopyFilter("Date Filter", "Date Filter");
                    TaxRegItemEntry.FilterGroup(2);
                    TaxRegItemEntry.SetRange("Section Code", "Section Code");
                    TaxRegItemEntry.SetFilter("Where Used Register IDs", '*~' + "Register ID" + '~*');
                    TaxRegItemEntry.FilterGroup(0);
                    if TemplateLineNo <> 0 then begin
                        TaxRegTemplate.Get("Section Code", "No.", TemplateLineNo);
                        TaxRegItemEntry.SetTemplateFilter(TaxRegTemplate);
                        TaxDimMgt.SetDimFilters2TaxItemLine(TaxRegTemplate, TaxRegItemEntry);
                    end;
                    PAGE.RunModal("Page ID", TaxRegItemEntry);
                end;
            DATABASE::"Tax Register FA Entry":
                ShowFAEntriesDetails(TemplateLineNo);
            DATABASE::"Tax Register FE Entry":
                begin
                    TaxRegFEEntry.Reset();
                    TaxRegFEEntry.SetCurrentKey("Section Code");
                    TaxRegFEEntry.FilterGroup(2);
                    TaxRegFEEntry.SetRange("Section Code", "Section Code");
                    TaxRegFEEntry.SetFilter("Where Used Register IDs", '*~' + "Register ID" + '~*');
                    TaxRegFEEntry.FilterGroup(0);
                    TaxRegFEEntry.CopyFilter("Date Filter", "Date Filter");
                    PAGE.RunModal("Page ID", TaxRegFEEntry);
                end;
            DATABASE::"Tax Register G/L Entry":
                ShowGLEntriesDetails(TemplateLineNo);
        end;
    end;

    [Scope('OnPrem')]
    procedure PrintReport(DateTextFilter: Text[1024])
    var
        TaxRegister: Record "Tax Register";
        TaxRegRep: Report "Tax Register";
    begin
        TaxRegister := Rec;
        TaxRegister.SetRecFilter();
        TaxRegister.SetFilter("Date Filter", DateTextFilter);
        TaxRegRep.SetTableView(TaxRegister);
        TaxRegRep.RunModal();
    end;

    [Scope('OnPrem')]
    procedure ShowGLEntriesDetails(TemplateLineNo: Integer)
    var
        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
        TempGLCorrespondenceEntry: Record "G/L Correspondence Entry" temporary;
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
        GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
        TempGLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry" temporary;
        TaxRegTemplate: Record "Tax Register Template";
        TaxDimMgt: Codeunit "Tax Dimension Mgt.";
    begin
        TaxRegTemplate.Get("Section Code", "No.", TemplateLineNo);

        TaxRegLineSetup.SetRange("Section Code", "Section Code");
        TaxRegLineSetup.SetRange("Tax Register No.", "No.");
        if TaxRegTemplate."Term Line Code" <> '' then
            TaxRegLineSetup.SetRange("Line Code", TaxRegTemplate."Term Line Code");
        if FindSet() then
            repeat
                if "G/L Corr. Analysis View Code" <> '' then begin
                    GLCorrAnalysisView.Get("G/L Corr. Analysis View Code");
                    GLCorrAnalysisViewEntry.Reset();
                    TaxDimMgt.SetDimFilters2GLCorrAnViewEntry(
                      GLCorrAnalysisViewEntry,
                      GLCorrAnalysisView,
                      TaxRegTemplate,
                      TaxRegLineSetup);
                    CopyFilter("Date Filter", GLCorrAnalysisViewEntry."Posting Date");

                    case TaxRegLineSetup."Account Type" of
                        TaxRegLineSetup."Account Type"::Correspondence:
                            begin
                                if TaxRegLineSetup."Account No." <> '' then
                                    GLCorrAnalysisViewEntry.SetFilter("Debit Account No.", TaxRegLineSetup."Account No.");
                                if TaxRegLineSetup."Bal. Account No." <> '' then
                                    GLCorrAnalysisViewEntry.SetFilter("Credit Account No.", TaxRegLineSetup."Bal. Account No.");
                                AddGLCorrAnViewEntr2Buffer(GLCorrAnalysisViewEntry, TempGLCorrAnalysisViewEntry);
                            end;
                        TaxRegLineSetup."Account Type"::"G/L Account":
                            case TaxRegLineSetup."Amount Type" of
                                TaxRegLineSetup."Amount Type"::Debit:
                                    begin
                                        if TaxRegLineSetup."Account No." <> '' then
                                            GLCorrAnalysisViewEntry.SetFilter("Debit Account No.", TaxRegLineSetup."Account No.");
                                        AddGLCorrAnViewEntr2Buffer(GLCorrAnalysisViewEntry, TempGLCorrAnalysisViewEntry);
                                    end;
                                TaxRegLineSetup."Amount Type"::Credit:
                                    begin
                                        if TaxRegLineSetup."Account No." <> '' then
                                            GLCorrAnalysisViewEntry.SetFilter("Credit Account No.", TaxRegLineSetup."Account No.");
                                        AddGLCorrAnViewEntr2Buffer(GLCorrAnalysisViewEntry, TempGLCorrAnalysisViewEntry);
                                    end;
                                TaxRegLineSetup."Amount Type"::"Net Change":
                                    if TaxRegLineSetup."Account No." <> '' then begin
                                        GLCorrAnalysisViewEntry.SetFilter("Debit Account No.", TaxRegLineSetup."Account No.");
                                        AddGLCorrAnViewEntr2Buffer(GLCorrAnalysisViewEntry, TempGLCorrAnalysisViewEntry);
                                        GLCorrAnalysisViewEntry.SetRange("Debit Account No.");
                                        GLCorrAnalysisViewEntry.SetFilter("Credit Account No.", TaxRegLineSetup."Account No.");
                                        AddGLCorrAnViewEntr2Buffer(GLCorrAnalysisViewEntry, TempGLCorrAnalysisViewEntry);
                                    end;
                            end;
                    end;
                end else begin
                    CopyFilter("Date Filter", GLCorrespondenceEntry."Posting Date");
                    case TaxRegLineSetup."Account Type" of
                        TaxRegLineSetup."Account Type"::Correspondence:
                            begin
                                if TaxRegLineSetup."Account No." <> '' then
                                    GLCorrespondenceEntry.SetFilter("Debit Account No.", TaxRegLineSetup."Account No.");
                                if TaxRegLineSetup."Bal. Account No." <> '' then
                                    GLCorrespondenceEntry.SetFilter("Credit Account No.", TaxRegLineSetup."Bal. Account No.");
                                AddGLCorrEntries2Buffer(GLCorrespondenceEntry, TempGLCorrespondenceEntry);
                            end;
                        TaxRegLineSetup."Account Type"::"G/L Account":
                            begin
                                GLCorrespondenceEntry.Reset();
                                case TaxRegLineSetup."Amount Type" of
                                    TaxRegLineSetup."Amount Type"::Debit:
                                        begin
                                            if TaxRegLineSetup."Account No." <> '' then
                                                GLCorrespondenceEntry.SetFilter("Debit Account No.", TaxRegLineSetup."Account No.");
                                            AddGLCorrEntries2Buffer(GLCorrespondenceEntry, TempGLCorrespondenceEntry);
                                        end;
                                    TaxRegLineSetup."Amount Type"::Credit:
                                        begin
                                            if TaxRegLineSetup."Account No." <> '' then
                                                GLCorrespondenceEntry.SetFilter("Credit Account No.", TaxRegLineSetup."Account No.");
                                            AddGLCorrEntries2Buffer(GLCorrespondenceEntry, TempGLCorrespondenceEntry);
                                        end;
                                    TaxRegLineSetup."Amount Type"::"Net Change":
                                        if TaxRegLineSetup."Account No." <> '' then begin
                                            GLCorrespondenceEntry.SetFilter("Debit Account No.", TaxRegLineSetup."Account No.");
                                            AddGLCorrEntries2Buffer(GLCorrespondenceEntry, TempGLCorrespondenceEntry);
                                            GLCorrespondenceEntry.SetRange("Debit Account No.");
                                            GLCorrespondenceEntry.SetFilter("Credit Account No.", TaxRegLineSetup."Account No.");
                                            AddGLCorrEntries2Buffer(GLCorrespondenceEntry, TempGLCorrespondenceEntry);
                                        end;
                                end;
                            end;
                    end;
                end;
            until TaxRegLineSetup.Next() = 0;

        if "G/L Corr. Analysis View Code" <> '' then begin
            TempGLCorrAnalysisViewEntry.SetFilter("G/L Corr. Analysis View Code", "G/L Corr. Analysis View Code");
            PAGE.RunModal(PAGE::"G/L Corr. Analysis View Entr.", TempGLCorrAnalysisViewEntry)
        end else
            PAGE.RunModal(PAGE::"G/L Correspondence Entries", TempGLCorrespondenceEntry);
    end;

    [Scope('OnPrem')]
    procedure ShowFAEntriesDetails(TemplateLineNo: Integer)
    var
        FALedgEntry: Record "FA Ledger Entry";
        TaxRegTemplate: Record "Tax Register Template";
        CreateTaxRegisterFAEntry: Codeunit "Create Tax Register FA Entry";
        DateBegin: Date;
        DateEnd: Date;
    begin
        if TemplateLineNo <> 0 then begin
            DateBegin := GetRangeMin("Date Filter");
            DateEnd := GetRangeMax("Date Filter");
            TaxRegTemplate.Get("Section Code", "No.", TemplateLineNo);
            CreateTaxRegisterFAEntry.SetFALedgerEntryFilters(FALedgEntry, TaxRegTemplate, DateBegin, DateEnd, 1);
            PAGE.RunModal(0, FALedgEntry);
        end;
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

