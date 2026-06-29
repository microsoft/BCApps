#pragma warning disable AA0247
table 17207 "Tax Register Section"
{
    Caption = 'Tax Register Section';
    LookupPageID = "Tax Register Sections";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            TableRelation = AllObj."Object ID" where("Object Type" = const(Page));

            trigger OnValidate()
            begin
                if "Page ID" = 0 then
                    Validate(Type);
                CalcFields("Page Name");
            end;
        }
        field(9; Type; Option)
        {
            Caption = 'Type';
            Editable = false;
            OptionCaption = 'Standard';
            OptionMembers = Standard;

            trigger OnValidate()
            begin
                case Type of
                    Type::Standard:
                        "Page ID" := PAGE::"Tax Register Accumulation";
                    else
                        Error('');
                end;
            end;
        }
        field(10; "Norm Jurisdiction Code"; Code[10])
        {
            Caption = 'Norm Jurisdiction Code';
            TableRelation = "Tax Register Norm Jurisdiction";

            trigger OnValidate()
            begin
                if "Norm Jurisdiction Code" <> xRec."Norm Jurisdiction Code" then begin
                    CheckChangeDeclaration();
                    TaxRegTemplate.Reset();
                    TaxRegTemplate.SetRange("Section Code", Code);
                    TaxRegTemplate.SetRange("Norm Jurisdiction Code", xRec."Norm Jurisdiction Code");
                    TaxRegTermFormula.Reset();
                    TaxRegTermFormula.SetRange("Section Code", Code);
                    TaxRegTermFormula.SetRange("Account Type", TaxRegTermFormula."Account Type"::Norm);
                    TaxRegTermFormula.SetRange("Norm Jurisdiction Code", xRec."Norm Jurisdiction Code");
                    if TaxRegTermFormula.FindFirst() or TaxRegTemplate.FindFirst() then
                        if Confirm(Text1013, true, "Norm Jurisdiction Code", FieldCaption("Norm Jurisdiction Code")) then
                            TaxRegTemplate.ModifyAll("Norm Jurisdiction Code", "Norm Jurisdiction Code", true);
                end;
            end;
        }
        field(11; "Dimension 1 Code"; Code[20])
        {
            Caption = 'Dimension 1 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                CheckUseDimCode(1, xRec."Dimension 1 Code", "Dimension 1 Code");
            end;
        }
        field(12; "Dimension 2 Code"; Code[20])
        {
            Caption = 'Dimension 2 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                CheckUseDimCode(2, xRec."Dimension 2 Code", "Dimension 2 Code");
            end;
        }
        field(13; "Dimension 3 Code"; Code[20])
        {
            Caption = 'Dimension 3 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                CheckUseDimCode(3, xRec."Dimension 3 Code", "Dimension 3 Code");
            end;
        }
        field(14; "Dimension 4 Code"; Code[20])
        {
            Caption = 'Dimension 4 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                CheckUseDimCode(4, xRec."Dimension 4 Code", "Dimension 4 Code");
            end;
        }
        field(16; "Page Name"; Text[80])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Page),
                                                                           "Object ID" = field("Page ID")));
            Caption = 'Page Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Last Register No."; Code[10])
        {
            Caption = 'Last Register No.';
            Editable = false;
        }
        field(18; "Last Date Filter"; Text[30])
        {
            Caption = 'Last Date Filter';
            Editable = false;
        }
        field(21; "Debit Balance Point 1"; DateFormula)
        {
            Caption = 'Debit Balance Point 1';

            trigger OnValidate()
            begin
                CheckUseBlncePoint(xRec."Debit Balance Point 1", "Debit Balance Point 1");
            end;
        }
        field(22; "Debit Balance Point 2"; DateFormula)
        {
            Caption = 'Debit Balance Point 2';

            trigger OnValidate()
            begin
                CheckUseBlncePoint(xRec."Debit Balance Point 2", "Debit Balance Point 2");
            end;
        }
        field(23; "Debit Balance Point 3"; DateFormula)
        {
            Caption = 'Debit Balance Point 3';

            trigger OnValidate()
            begin
                CheckUseBlncePoint(xRec."Debit Balance Point 3", "Debit Balance Point 3");
            end;
        }
        field(24; "Credit Balance Point 1"; DateFormula)
        {
            Caption = 'Credit Balance Point 1';

            trigger OnValidate()
            begin
                CheckUseBlncePoint(xRec."Credit Balance Point 1", "Credit Balance Point 1");
            end;
        }
        field(30; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Blocked);
                if not Confirm(Text1002, false) then
                    Error('');
                if "Starting Date" <> 0D then
                    "Starting Date" := CalcDate('<-CM>', "Starting Date");
                SectionReset();
            end;
        }
        field(31; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                if "Ending Date" = xRec."Ending Date" then
                    exit;
                if "Ending Date" <> 0D then begin
                    if Status > Status::Blocked then
                        Error(Text1005, Status);
                    TestField("Starting Date");
                    "Ending Date" := CalcDate('<CM>', "Ending Date");
                    if ("Ending Date" <> xRec."Ending Date") and ("Ending Date" < "Starting Date") then
                        Error(Text1004, "Starting Date");
                    if ("Ending Date" <> xRec."Ending Date") and ("Ending Date" < LastDateEntries()) then
                        Error(Text1004, LastDateEntries());
                    if CalcDate('<CY>', "Ending Date") <> CalcDate('<CY>', "Starting Date") then
                        Error(Text1010);
                end;
            end;
        }
        field(32; "Last Date Updated"; Date)
        {
            Caption = 'Last Date Updated';
            Editable = false;
        }
        field(33; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Open,Reporting,Blocked,Closed';
            OptionMembers = Open,Reporting,Blocked,Closed;

            trigger OnValidate()
            begin
                if Status <> Status::Blocked then
                    TestField("Starting Date");

                case Status of
                    Status::Reporting:
                        begin
                            if not Confirm(Text1002, false) then
                                Error('');
                            SectionReset();
                        end;
                    Status::Closed:
                        begin
                            TestField("Ending Date");
                            if xRec.Status <> xRec.Status::Reporting then
                                Error(Text1006, FieldCaption(Status), Status);
                            if TaxRegMgt.GetNextAvailableBeginDate(Code, DATABASE::"Tax Register Accumulation", true) <> 0D then
                                Error(Text1006, FieldCaption(Status), Status);
                        end;
                end;
            end;
        }
        field(34; "Absence GL Entries Date"; Date)
        {
            Caption = 'Absence GL Entries Date';
            Editable = false;
        }
        field(35; "Absence CV Entries Date"; Date)
        {
            Caption = 'Absence CV Entries Date';
            Editable = false;
        }
        field(36; "Absence Item Entries Date"; Date)
        {
            Caption = 'Absence Item Entries Date';
            Editable = false;
        }
        field(37; "Absence FA Entries Date"; Date)
        {
            Caption = 'Absence FA Entries Date';
            Editable = false;
        }
        field(38; "Absence FE Entries Date"; Date)
        {
            Caption = 'Absence FE Entries Date';
            Editable = false;
        }
        field(39; "Absence PR Entries Date"; Date)
        {
            Caption = 'Absence PR Entries Date';
            Editable = false;
        }
        field(40; "Last GL Entries Date"; Date)
        {
            Caption = 'Last GL Entries Date';
            Editable = false;

            trigger OnValidate()
            begin
                "Last Date Updated" := Today;
            end;
        }
        field(41; "Last CV Entries Date"; Date)
        {
            Caption = 'Last CV Entries Date';
            Editable = false;

            trigger OnValidate()
            begin
                "Last Date Updated" := Today;
            end;
        }
        field(42; "Last Item Entries Date"; Date)
        {
            Caption = 'Last Item Entries Date';
            Editable = false;

            trigger OnValidate()
            begin
                "Last Date Updated" := Today;
            end;
        }
        field(43; "Last FA Entries Date"; Date)
        {
            Caption = 'Last FA Entries Date';
            Editable = false;

            trigger OnValidate()
            begin
                "Last Date Updated" := Today;
            end;
        }
        field(44; "Last FE Entries Date"; Date)
        {
            Caption = 'Last FE Entries Date';
            Editable = false;

            trigger OnValidate()
            begin
                "Last Date Updated" := Today;
            end;
        }
        field(45; "Last PR Entries Date"; Date)
        {
            Caption = 'Last PR Entries Date';
            Editable = false;

            trigger OnValidate()
            begin
                "Last Date Updated" := Today;
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
        fieldgroup(DropDown; "Code", Description, Status)
        {
        }
    }

    trigger OnDelete()
    begin
        if Status = Status::Closed then
            Error(Text1009, Status);

        SectionReset();
        TaxReg.Reset();
        TaxReg.SetRange("Section Code", Code);
        TaxReg.DeleteAll(true);

        TaxRegTerm.SetRange("Section Code", Code);
        TaxRegTerm.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        Status := Status::Blocked;
        Validate("Page ID");
    end;

    var
        TaxReg: Record "Tax Register";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1001: Label 'You cannot use the same dimension twice in the same %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1002: Label 'If you change the section declaration, the tax statement entries will be deleted.\You will have to update again.\\Do you want to change the section declaration?';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1004: Label 'Ending Date cannot be less then %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1005: Label 'Ending Date cannot be changed if Status is %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1006: Label '%1 cannot be set %2 if not ending build registers.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1008: Label 'Value cannot change if %1 is %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1009: Label 'You cannot delete Tax Register Section because Status is %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegTerm: Record "Tax Register Term";
        TaxRegTermFormula: Record "Tax Register Term Formula";
        TaxRegMgt: Codeunit "Tax Register Mgt.";
#pragma warning disable AA0074
        Text1010: Label 'Starting Date and Ending Date are in different year.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1011: Label 'Value must be negative.';
#pragma warning restore AA0074
        FileMgt: Codeunit "File Management";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1013: Label 'Do you want to update the %2 field on the lines to reflect the new value of %1?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        FileName: Text[1024];
#pragma warning disable AA0074
        Text1015: Label 'Select a filename to export settings to.';
#pragma warning restore AA0074

    local procedure CheckUseDimCode(FieldNumber: Integer; xRecDimCode: Code[20]; DimCode: Code[20])
    begin
        if xRecDimCode = DimCode then
            exit;
        if Status <> Status::Open then
            Error(Text1008, FieldCaption(Status), Status);

        if DimCode <> '' then
            if ((1 <> FieldNumber) and (DimCode = "Dimension 1 Code")) or
               ((2 <> FieldNumber) and (DimCode = "Dimension 2 Code")) or
               ((3 <> FieldNumber) and (DimCode = "Dimension 3 Code")) or
               ((4 <> FieldNumber) and (DimCode = "Dimension 4 Code"))
            then
                Error(Text1001, TableCaption);

        if xRecDimCode <> '' then
            CheckChangeDeclaration();
    end;

    local procedure CheckUseBlncePoint(xRecBalancePint: DateFormula; BalancePint: DateFormula)
    begin
        if xRecBalancePint = BalancePint then
            exit;
        if Status <> Status::Open then
            Error(Text1008, FieldCaption(Status), Status);
        CheckChangeDeclaration();
        if CalcDate(BalancePint, Today) > Today then
            Error(Text1011);
    end;

    [Scope('OnPrem')]
    procedure SectionReset()
    var
        TaxRegGLCorrEntry: Record "Tax Register G/L Corr. Entry";
        TaxRegAccumulation: Record "Tax Register Accumulation";
        TaxRegGLEntry: Record "Tax Register G/L Entry";
        TaxRegCVEntry: Record "Tax Register CV Entry";
        TaxRegFAEntry: Record "Tax Register FA Entry";
        TaxRegItemEntry: Record "Tax Register Item Entry";
        TaxRegFEEntry: Record "Tax Register FE Entry";
    begin
        TaxRegAccumulation.SetCurrentKey("Section Code");
        TaxRegAccumulation.SetRange("Section Code", Code);
        TaxRegAccumulation.DeleteAll(true);

        TaxRegGLEntry.SetCurrentKey("Section Code");
        TaxRegGLEntry.SetRange("Section Code", Code);
        TaxRegGLEntry.DeleteAll(true);

        TaxRegCVEntry.SetCurrentKey("Section Code");
        TaxRegCVEntry.SetRange("Section Code", Code);
        TaxRegCVEntry.DeleteAll(true);

        TaxRegFAEntry.SetCurrentKey("Section Code");
        TaxRegFAEntry.SetRange("Section Code", Code);
        TaxRegFAEntry.DeleteAll(true);

        TaxRegItemEntry.SetCurrentKey("Section Code");
        TaxRegItemEntry.SetRange("Section Code", Code);
        TaxRegItemEntry.DeleteAll(true);

        TaxRegFEEntry.SetCurrentKey("Section Code");
        TaxRegFEEntry.SetRange("Section Code", Code);
        TaxRegFEEntry.DeleteAll(true);

        TaxRegGLCorrEntry.SetCurrentKey("Section Code");
        TaxRegGLCorrEntry.SetRange("Section Code", Code);
        TaxRegGLCorrEntry.DeleteAll(true);

        "Last Date Updated" := 0D;
        "Absence GL Entries Date" := 0D;
        "Absence CV Entries Date" := 0D;
        "Absence Item Entries Date" := 0D;
        "Absence FA Entries Date" := 0D;
        "Absence FE Entries Date" := 0D;
        "Absence PR Entries Date" := 0D;
        "Last GL Entries Date" := 0D;
        "Last CV Entries Date" := 0D;
        "Last Item Entries Date" := 0D;
        "Last FA Entries Date" := 0D;
        "Last FE Entries Date" := 0D;
        "Last PR Entries Date" := 0D;
    end;

    [Scope('OnPrem')]
    procedure ValidateChangeDeclaration()
    begin
        if LastDateEntries() <> 0D then begin
            if not Confirm(Text1002, false) then
                Error('');
            SectionReset();
            Status := Status::Blocked;
            Modify();
        end;
    end;

    local procedure CheckChangeDeclaration()
    begin
        if LastDateEntries() <> 0D then begin
            if not Confirm(Text1002, false) then
                Error('');
            SectionReset();
        end;
    end;

    [Scope('OnPrem')]
    procedure LastDateEntries() LastDate: Date
    begin
        if (LastDate = 0D) or (LastDate > "Last GL Entries Date") and ("Last GL Entries Date" <> 0D) then
            LastDate := "Last GL Entries Date";

        if (LastDate = 0D) or ((LastDate > "Last CV Entries Date") and ("Last CV Entries Date" <> 0D)) then
            LastDate := "Last CV Entries Date";

        if (LastDate = 0D) or ((LastDate > "Last Item Entries Date") and ("Last Item Entries Date" <> 0D)) then
            LastDate := "Last Item Entries Date";

        if (LastDate = 0D) or ((LastDate > "Last FA Entries Date") and ("Last FA Entries Date" <> 0D)) then
            LastDate := "Last FA Entries Date";

        if (LastDate = 0D) or ((LastDate > "Last FE Entries Date") and ("Last FE Entries Date" <> 0D)) then
            LastDate := "Last FE Entries Date";

        if (LastDate = 0D) or ((LastDate > "Last PR Entries Date") and ("Last PR Entries Date" <> 0D)) then
            LastDate := "Last PR Entries Date";
    end;

    [Scope('OnPrem')]
    procedure ExportSettings(var TaxRegisterSection: Record "Tax Register Section")
    var
        TaxRegisterSetup: XMLport "Tax Register Setup";
        OutputFile: File;
        OutStr: OutStream;
    begin
        FileName := FileMgt.ServerTempFileName('xml');
        OutputFile.Create(FileName);
        OutputFile.CreateOutStream(OutStr);
        TaxRegisterSetup.SetDestination(OutStr);
        TaxRegisterSetup.SetData(TaxRegisterSection);
        TaxRegisterSetup.Export();
        OutputFile.Close();
        Clear(OutStr);
        Download(FileName, Text1015, '', '', FileName);
    end;

    [Scope('OnPrem')]
    procedure ImportSettings(FileName2: Text[250])
    var
        TaxRegisterSetup: XMLport "Tax Register Setup";
        InStr: InStream;
        SettingsFile: File;
    begin
        SettingsFile.Open(FileName2);
        SettingsFile.CreateInStream(InStr);

        TaxRegisterSetup.SetSource(InStr);
        TaxRegisterSetup.Import();
        TaxRegisterSetup.ImportData();
        Clear(InStr);
        SettingsFile.Close();
    end;

    [Scope('OnPrem')]
    procedure PromptImportSettings()
    begin
        ImportSettings('');
    end;
}

