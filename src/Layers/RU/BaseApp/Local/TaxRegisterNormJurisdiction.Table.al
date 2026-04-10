#pragma warning disable AA0247
table 17220 "Tax Register Norm Jurisdiction"
{
    Caption = 'Tax Register Norm Jurisdiction';
    LookupPageID = "Tax Reg. Norm Jurisdictions";
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
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }

    trigger OnDelete()
    var
        TaxRegNormGroup: Record "Tax Register Norm Group";
        TaxRegNormTerm: Record "Tax Reg. Norm Term";
    begin
        TaxRegNormGroup.SetRange("Norm Jurisdiction Code", Code);
        TaxRegNormGroup.DeleteAll(true);

        TaxRegNormTerm.SetRange("Norm Jurisdiction Code", Code);
        TaxRegNormTerm.DeleteAll(true);
    end;

    var
        FileMgt: Codeunit "File Management";
        FileName: Text;
#pragma warning disable AA0074
        Text001: Label 'Import File';
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure ImportSettings(FileName: Text)
    var
        NormJurisdictionSettings: XMLport "Norm Jurisdiction";
        InputFile: File;
        InStr: InStream;
    begin
        InputFile.Open(FileName);
        InputFile.CreateInStream(InStr);
        NormJurisdictionSettings.SetSource(InStr);
        NormJurisdictionSettings.Import();
        NormJurisdictionSettings.ImportData();
        InputFile.Close();
        Clear(InStr);
    end;

    [Scope('OnPrem')]
    procedure PromptImportSettings()
    begin
        FileName := FileMgt.UploadFile(Text001, '');
        if FileName <> '' then
            ImportSettings(FileName);
    end;
}

