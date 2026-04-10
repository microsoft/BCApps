#pragma warning disable AA0247
table 17319 "Tax Calc. G/L Corr. Entry"
{
    Caption = 'Tax Calc. G/L Corr. Entry';
    LookupPageID = "Tax Calc. Corresp. Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Debit Account No."; Code[20])
        {
            Caption = 'Debit Account No.';
            TableRelation = "G/L Account";
        }
        field(2; "Credit Account No."; Code[20])
        {
            Caption = 'Credit Account No.';
            TableRelation = "G/L Account";
        }
#pragma warning disable AS0044
        field(3; "Register Type"; Option)
        {
            Caption = 'Register Type';
            OptionCaption = ' ,Item';
            OptionMembers = " ",Item;
        }
#pragma warning restore AS0044
        field(4; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
            NotBlank = true;
            TableRelation = "Tax Calc. Section";
        }
        field(5; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
        }
        field(6; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(7; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
        }
        field(10; "Tax Register ID Totaling"; Code[61])
        {
            Caption = 'Tax Register ID Totaling';
        }
        field(11; "Where Used Register IDs"; Code[61])
        {
            Caption = 'Where Used Register IDs';
        }
        field(21; "Debit Account Name"; Text[50])
        {
            CalcFormula = lookup("G/L Account".Name where("No." = field("Debit Account No.")));
            Caption = 'Debit Account Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(22; "Credit Account Name"; Text[50])
        {
            CalcFormula = lookup("G/L Account".Name where("No." = field("Credit Account No.")));
            Caption = 'Credit Account Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Section Code", "Debit Account No.", "Credit Account No.", "Register Type")
        {
            Clustered = true;
        }
        key(Key2; "Section Code", "Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TaxCalcDimCorrFilter.SetRange("Section Code", "Section Code");
        TaxCalcDimCorrFilter.SetRange("Corresp. Entry No.", "Entry No.");
        TaxCalcDimCorrFilter.DeleteAll();
    end;

    trigger OnInsert()
    begin
        TaxCalcGLCorrEntry.SetCurrentKey("Section Code", "Entry No.");
        TaxCalcGLCorrEntry.SetRange("Section Code", "Section Code");
        if TaxCalcGLCorrEntry.FindLast() then
            "Entry No." := TaxCalcGLCorrEntry."Entry No." + 1
        else
            "Entry No." := 1;
    end;

    var
        TaxCalcGLCorrEntry: Record "Tax Calc. G/L Corr. Entry";
        TaxCalcDimCorrFilter: Record "Tax Calc. Dim. Corr. Filter";

    [Scope('OnPrem')]
    procedure TaxCalcName() Result: Text[150]
    var
        TaxCalcHeader: Record "Tax Calc. Header";
    begin
        if "Where Used Register IDs" <> '' then begin
            TaxCalcHeader.SetRange("Section Code", "Section Code");
            TaxCalcHeader.SetFilter("Register ID", ConvertStr(DelChr("Where Used Register IDs", '<>', '~'), '~', '|'));
            if TaxCalcHeader.FindSet() then begin
                Result := TaxCalcHeader."No.";
                while TaxCalcHeader.Next() <> 0 do
                    Result := CopyStr(StrSubstNo('%1, %2', Result, TaxCalcHeader."No."), 1, MaxStrLen(Result));
                if Result = TaxCalcHeader."No." then
                    Result := CopyStr(TaxCalcHeader.Description, 1, MaxStrLen(Result));
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure LookupTaxCalcHeader()
    var
        TaxCalcHeader: Record "Tax Calc. Header";
    begin
        TaxCalcHeader.FilterGroup(2);
        TaxCalcHeader.SetRange("Section Code", "Section Code");
        TaxCalcHeader.SetFilter("Register ID", ConvertStr(DelChr("Where Used Register IDs", '<>', '~'), '~', '|'));
        TaxCalcHeader.FilterGroup(0);
        if ACTION::OK = PAGE.RunModal(0, TaxCalcHeader) then;
    end;

    [Scope('OnPrem')]
    procedure DrillDownTaxCalcHeader()
    var
        TaxCalcDimCorFilters: Page "Tax Calc. Cor. Dim. Filters";
    begin
        Clear(TaxCalcDimCorFilters);
        TaxCalcDimCorFilters.SetTemplateCorresp("Section Code", "Entry No.");
        TaxCalcDimCorFilters.RunModal();
    end;
}

