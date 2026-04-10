#pragma warning disable AA0247
table 14926 "Default VAT Allocation Line"
{
    Caption = 'Default VAT Allocation Line';
    DrillDownPageID = "Default VAT Allocation";
    LookupPageID = "Default VAT Allocation";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(2; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'VAT,Write-Off,Charge';
            OptionMembers = VAT,WriteOff,Charge;

            trigger OnValidate()
            var
                VATPostingSetup: Record "VAT Posting Setup";
            begin
                HandleType();
                if VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                    case Type of
                        Type::VAT:
                            if VATPostingSetup."Purchase VAT Account" <> '' then
                                Validate("Account No.", VATPostingSetup."Purchase VAT Account")
                            else
                                if VATPostingSetup."Sales VAT Account" <> '' then
                                    Validate("Account No.", VATPostingSetup."Sales VAT Account");
                        Type::WriteOff:
                            begin
                                VATPostingSetup.TestField("Write-Off VAT Account");
                                Validate("Account No.", VATPostingSetup."Write-Off VAT Account")
                            end;
                    end;
            end;
        }
        field(5; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            NotBlank = true;
            TableRelation = "G/L Account";

            trigger OnValidate()
            var
                GLAcc: Record "G/L Account";
                DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
            begin
                if "Account No." = '' then
                    GLAcc.Init()
                else begin
                    GLAcc.Get("Account No.");
                    GLAcc.CheckGLAcc();
                end;
                Description := GLAcc.Name;

                DimMgt.AddDimSource(DefaultDimSource, Database::"G/L Account", "Account No.");
                CreateDim(DefaultDimSource);
            end;
        }
        field(7; "Allocation %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Allocation %';
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                Amount := 0;
                CheckVATAllocation();
            end;
        }
        field(8; Amount; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            Caption = 'Amount';

            trigger OnValidate()
            begin
                "Allocation %" := 0;
            end;
        }
        field(9; "VAT Unreal. Account No."; Code[20])
        {
            Caption = 'VAT Unreal. Account No.';
            Editable = false;
        }
        field(10; Base; Option)
        {
            Caption = 'Base';
            OptionCaption = 'Remaining,Full,Depreciation';
            OptionMembers = Remaining,Full,Depreciation;

            trigger OnValidate()
            var
                CommonBase: Option;
            begin
                if FindCommonBase(CommonBase) then
                    Base := CommonBase;
            end;
        }
        field(11; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
                Modify();
            end;
        }
        field(12; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
                Modify();
            end;
        }
        field(13; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(14; "Recurring Frequency"; DateFormula)
        {
            Caption = 'Recurring Frequency';

            trigger OnValidate()
            begin
                if WorkDate() > CalcDate("Recurring Frequency", WorkDate()) then
                    FieldError("Recurring Frequency");
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Line No.")
        {
            Clustered = true;
            SumIndexFields = "Allocation %";
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        Validate(Type);
        Validate(Base);

        Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
    end;

    var
        DimMgt: Codeunit DimensionManagement;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'The maximum permitted value for total %1 is 100.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetDefaultDimID(
            DefaultDimSource, SourceCodeSetup."VAT Settlement",
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    [Scope('OnPrem')]
    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        Rec.ValidateShortcutDimCode(FieldNumber, ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2 %3', "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Line No."));
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure HandleType()
    var
        DefaultVATAllocationLine: Record "Default VAT Allocation Line";
    begin
        if Type = Type::VAT then begin
            DefaultVATAllocationLine := Rec;
            SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
            SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
            SetFilter("Line No.", '<>%1', "Line No.");
            SetRange(Type, Type::VAT);
            if not IsEmpty() then begin
                Rec := DefaultVATAllocationLine;
                Type := Type::WriteOff;
            end else
                Rec := DefaultVATAllocationLine;
            SetRange("Line No.");
            SetRange(Type);
        end;
    end;

    [Scope('OnPrem')]
    procedure FindCommonBase(var NewBase: Option) Result: Boolean
    var
        DefaultVATAllocationLine: Record "Default VAT Allocation Line";
    begin
        DefaultVATAllocationLine := Rec;
        Result := false;
        SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
        SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
        SetFilter("Line No.", '<>%1', "Line No.");
        if FindFirst() then begin
            NewBase := Base;
            Result := true;
        end;
        SetRange("Line No.");
        Rec := DefaultVATAllocationLine;
    end;

    [Scope('OnPrem')]
    procedure CheckVATAllocation()
    var
        DefaultVATAllocationLine: Record "Default VAT Allocation Line";
        TotalAllocPercent: Decimal;
    begin
        DefaultVATAllocationLine := Rec;
        TotalAllocPercent := "Allocation %";
        SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
        SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
        SetFilter("Line No.", '<>%1', "Line No.");
        CalcSums("Allocation %");
        TotalAllocPercent := TotalAllocPercent + "Allocation %";
        SetRange("Line No.");
        Rec := DefaultVATAllocationLine;
        if TotalAllocPercent > 100 then
            Error(Text001, FieldCaption("Allocation %"));
    end;
}

