#pragma warning disable AA0247
table 17307 "Tax Calc. Section"
{
    Caption = 'Tax Calc. Section';
    LookupPageID = "Tax Calc. Section List";
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
                        "Page ID" := PAGE::"Tax Calc. Accumulation";
                    else
                        Error('');
                end;
            end;
        }
        field(10; "Norm Jurisdiction Code"; Code[10])
        {
            Caption = 'Norm Jurisdiction Code';
            TableRelation = "Tax Register Norm Jurisdiction".Code;
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
                        Error(Text1004, FieldCaption("Ending Date"), FieldCaption("Starting Date"));
                    if ("Ending Date" <> xRec."Ending Date") and ("Ending Date" < LastDateEntries()) then
                        Error(Text1004, FieldCaption("Ending Date"), LastDateEntries());
                    if CalcDate('<CY>', "Ending Date") <> CalcDate('<CY>', "Starting Date") then
                        Error(Text1010, FieldCaption("Ending Date"), FieldCaption("Starting Date"));
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
            OptionCaption = 'Open,Statement,Blocked,Closed';
            OptionMembers = Open,Statement,Blocked,Closed;

            trigger OnValidate()
            begin
                if Status <> Status::Blocked then
                    TestField("Starting Date");

                case Status of
                    Status::Statement:
                        begin
                            if not Confirm(Text1002, false) then
                                Error('');

                            SectionReset();
                        end;
                    Status::Closed:
                        begin
                            TestField("Ending Date");
                            if xRec.Status <> xRec.Status::Statement then
                                Error(Text1006, FieldCaption(Status), Status);
                            if TaxCalcMgt.GetNextAvailableBeginDate(Code, DATABASE::"Tax Calc. Accumulation", true) <> 0D then
                                Error(Text1006, FieldCaption(Status), Status);
                        end;
                end;
            end;
        }
        field(34; "No G/L Entries Date"; Date)
        {
            Caption = 'No G/L Entries Date';
            Editable = false;
        }
        field(36; "No Item Entries Date"; Date)
        {
            Caption = 'No Item Entries Date';
            Editable = false;
        }
        field(37; "No FA Entries Date"; Date)
        {
            Caption = 'No FA Entries Date';
            Editable = false;
        }
        field(40; "Last G/L Entries Date"; Date)
        {
            Caption = 'Last G/L Entries Date';
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
        TaxCalcHeader.Reset();
        TaxCalcHeader.SetRange("Section Code", Code);
        TaxCalcHeader.DeleteAll(true);

        TaxCalcTerm.SetRange("Section Code", Code);
        TaxCalcTerm.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        Status := Status::Blocked;
        Validate("Page ID");
    end;

    var
        TaxCalcHeader: Record "Tax Calc. Header";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1001: Label 'You cannot use the same dimension twice in the same %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1002: Label 'If you change the section declaration, the entries will be deleted.\You will have to update again.\\Do you want to change the section declaration?';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1004: Label '%1 cannot be less then %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1005: Label 'You cannot change Engind Date if Status is %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1006: Label '%1 cannot be set %2 if not ending build registers.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1008: Label 'You cannot change the value if Status is %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1009: Label 'You cannot delete section if Status is %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TaxCalcTerm: Record "Tax Calc. Term";
        TaxCalcMgt: Codeunit "Tax Calc. Mgt.";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1010: Label '%1 and %2 are in different year';
#pragma warning restore AA0470
#pragma warning restore AA0074
        FileMgt: Codeunit "File Management";
        FileName: Text[250];
#pragma warning disable AA0074
        Text1015: Label 'Select a filename to export settings to.';
#pragma warning restore AA0074

    local procedure CheckUseDimCode(FieldNumber: Integer; xRecDimCode: Code[20]; DimCode: Code[20])
    begin
        if xRecDimCode = DimCode then
            exit;
        if Status <> Status::Open then
            Error(Text1008, Status);

        if DimCode <> '' then
            if ((1 <> FieldNumber) and (DimCode = "Dimension 1 Code")) or
               ((2 <> FieldNumber) and (DimCode = "Dimension 2 Code")) or
               ((3 <> FieldNumber) and (DimCode = "Dimension 3 Code")) or
               ((4 <> FieldNumber) and (DimCode = "Dimension 4 Code"))
            then
                Error(Text1001, TableCaption);

        if xRecDimCode <> '' then
            CheckChange();
    end;

    [Scope('OnPrem')]
    procedure SectionReset()
    var
        TaxCalcGLCorrEntry: Record "Tax Calc. G/L Corr. Entry";
        TaxCalcAccumulation: Record "Tax Calc. Accumulation";
        TaxCalcGLEntry: Record "Tax Calc. G/L Entry";
        TaxCalcItemEntry: Record "Tax Calc. Item Entry";
        TaxCalcFAEntry: Record "Tax Calc. FA Entry";
    begin
        TaxCalcAccumulation.SetRange("Section Code", Code);
        TaxCalcAccumulation.DeleteAll(true);

        TaxCalcGLEntry.SetRange("Section Code", Code);
        TaxCalcGLEntry.DeleteAll(true);

        TaxCalcFAEntry.SetRange("Section Code", Code);
        TaxCalcFAEntry.DeleteAll(true);

        TaxCalcItemEntry.SetRange("Section Code", Code);
        TaxCalcItemEntry.DeleteAll(true);

        TaxCalcGLCorrEntry.SetRange("Section Code", Code);
        TaxCalcGLCorrEntry.DeleteAll(true);

        "Last Date Updated" := 0D;
        "No G/L Entries Date" := 0D;
        "No Item Entries Date" := 0D;
        "No FA Entries Date" := 0D;
        "Last G/L Entries Date" := 0D;
        "Last Item Entries Date" := 0D;
        "Last FA Entries Date" := 0D;
    end;

    [Scope('OnPrem')]
    procedure ValidateChange()
    begin
        if LastDateEntries() <> 0D then begin
            if not Confirm(Text1002, false) then
                Error('');
            SectionReset();
            Status := Status::Blocked;
            Modify();
        end;
    end;

    local procedure CheckChange()
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
        if (LastDate = 0D) or (LastDate > "Last G/L Entries Date") and ("Last G/L Entries Date" <> 0D) then
            LastDate := "Last G/L Entries Date";

        if (LastDate = 0D) or ((LastDate > "Last Item Entries Date") and ("Last Item Entries Date" <> 0D)) then
            LastDate := "Last Item Entries Date";

        if (LastDate = 0D) or ((LastDate > "Last FA Entries Date") and ("Last FA Entries Date" <> 0D)) then
            LastDate := "Last FA Entries Date";
    end;

    [Scope('OnPrem')]
    procedure ExportSettings(var TaxCalcSection: Record "Tax Calc. Section")
    var
        TaxDiffRegisters: XMLport "Tax Differences Registers";
        OutputFile: File;
        OutStr: OutStream;
    begin
        FileName := FileMgt.ServerTempFileName('xml');
        OutputFile.Create(FileName);
        OutputFile.CreateOutStream(OutStr);
        TaxDiffRegisters.SetDestination(OutStr);
        TaxDiffRegisters.SetData(TaxCalcSection);
        TaxDiffRegisters.Export();
        OutputFile.Close();
        Clear(OutStr);
        Download(FileName, Text1015, '', '', FileName);
    end;

    [Scope('OnPrem')]
    procedure ImportSettings(FileName2: Text[250])
    var
        TaxDiffRegisters: XMLport "Tax Differences Registers";
        InStr: InStream;
        ImportFile: File;
    begin
        ImportFile.Open(FileName2);
        ImportFile.CreateInStream(InStr);

        TaxDiffRegisters.SetSource(InStr);
        TaxDiffRegisters.Import();
        TaxDiffRegisters.ImportData();
        Clear(InStr);
        ImportFile.Close();
    end;

    [Scope('OnPrem')]
    procedure PromptImportSettings()
    begin
        ImportSettings('');
    end;
}

