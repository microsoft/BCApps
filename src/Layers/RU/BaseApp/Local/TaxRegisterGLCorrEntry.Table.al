#pragma warning disable AA0247
table 17203 "Tax Register G/L Corr. Entry"
{
    Caption = 'Tax Register G/L Corr. Entry';
    LookupPageID = "Tax Register G/L Corr. Entries";
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
        field(3; "Register Type"; Option)
        {
            Caption = 'Register Type';
            OptionCaption = ' ,Item,Payroll';
            OptionMembers = " ",Item,Payroll;
        }
        field(4; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
            NotBlank = true;
            TableRelation = "Tax Register Section";
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
        TaxRegDimCorrFilter.SetRange("Section Code", "Section Code");
        TaxRegDimCorrFilter.SetRange("G/L Corr. Entry No.", "Entry No.");
        TaxRegDimCorrFilter.DeleteAll();
    end;

    trigger OnInsert()
    begin
        TaxRegGLCorrEntry.Reset();
        TaxRegGLCorrEntry.SetCurrentKey("Section Code", "Entry No.");
        TaxRegGLCorrEntry.SetRange("Section Code", "Section Code");
        if TaxRegGLCorrEntry.FindLast() then
            "Entry No." := TaxRegGLCorrEntry."Entry No." + 1
        else
            "Entry No." := 1;
    end;

    var
        TaxRegGLCorrEntry: Record "Tax Register G/L Corr. Entry";
        TaxRegDimCorrFilter: Record "Tax Register Dim. Corr. Filter";

    [Scope('OnPrem')]
    procedure GetTaxRegName() Result: Text[150]
    var
        TaxReg: Record "Tax Register";
    begin
        if "Where Used Register IDs" <> '' then begin
            TaxReg.SetRange("Section Code", "Section Code");
            TaxReg.SetFilter("Register ID", ConvertStr(DelChr("Where Used Register IDs", '<>', '~'), '~', '|'));
            if TaxReg.FindSet() then begin
                Result := TaxReg."No.";
                while TaxReg.Next() <> 0 do
                    Result := CopyStr(StrSubstNo('%1, %2', Result, TaxReg."No."), 1, MaxStrLen(Result));
                if Result = TaxReg."No." then
                    Result := CopyStr(TaxReg.Description, 1, MaxStrLen(Result));
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure LookupTaxRegName()
    var
        TaxReg: Record "Tax Register";
    begin
        TaxReg.FilterGroup(2);
        TaxReg.SetRange("Section Code", "Section Code");
        TaxReg.SetFilter("Register ID", ConvertStr(DelChr("Where Used Register IDs", '<>', '~'), '~', '|'));
        TaxReg.FilterGroup(0);
        if ACTION::OK = PAGE.RunModal(0, TaxReg) then;
    end;

    [Scope('OnPrem')]
    procedure DrillDownTaxRegName()
    var
        TaxRegGLCorresDimFilters: Page "Tax Reg G/L Corres Dim Filters";
    begin
        Clear(TaxRegGLCorresDimFilters);
        TaxRegGLCorresDimFilters.SetTaxRegGLCorr("Section Code", "Entry No.");
        TaxRegGLCorresDimFilters.RunModal();
    end;
}

