#pragma warning disable AA0247
table 14925 "VAT Allocation Line"
{
    Caption = 'VAT Allocation Line';
    DrillDownPageID = "VAT Allocation";
    LookupPageID = "VAT Allocation";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "CV Ledger Entry No."; Integer)
        {
            Caption = 'CV Ledger Entry No.';
            Editable = false;
        }
        field(2; "VAT Entry No."; Integer)
        {
            Caption = 'VAT Entry No.';

            trigger OnValidate()
            var
                VATPostingSetup: Record "VAT Posting Setup";
            begin
                VATEntry.Get("VAT Entry No.");
                if VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Full VAT" then
                    VATEntry.TestField("Unrealized Amount")
                else
                    VATEntry.TestField("Unrealized Base");
                "CV Ledger Entry No." := VATEntry."CV Ledg. Entry No.";
                if VATEntry."Object Type" = VATEntry."Object Type"::"Fixed Asset" then
                    "VAT Settlement Type" := VATEntry."VAT Settlement Type";
                VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
                VATPostingSetup.TestField("Unrealized VAT Type");
                "VAT Bus. Posting Group" := VATEntry."VAT Bus. Posting Group";
                "VAT Prod. Posting Group" := VATEntry."VAT Prod. Posting Group";
                case VATEntry.Type of
                    VATEntry.Type::Purchase:
                        begin
                            VATPostingSetup.TestField("Purch. VAT Unreal. Account");
                            "VAT Unreal. Account No." := VATPostingSetup."Purch. VAT Unreal. Account";
                        end;
                    VATEntry.Type::Sale:
                        begin
                            VATPostingSetup.TestField("Sales VAT Unreal. Account");
                            "VAT Unreal. Account No." := VATPostingSetup."Sales VAT Unreal. Account";
                        end;
                end;
                Validate(Type);
            end;
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
                GenPostingSetup: Record "General Posting Setup";
                FA: Record "Fixed Asset";
                FASetup: Record "FA Setup";
                FADeprBook: Record "FA Depreciation Book";
                FAPostingGr: Record "FA Posting Group";
            begin
                HandleType();
                VATEntry.Get("VAT Entry No.");
                VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
                case Type of
                    Type::VAT:
                        if VATEntry.Type = VATEntry.Type::Purchase then begin
                            VATPostingSetup.TestField("Purchase VAT Account");
                            Validate("Account No.", VATPostingSetup."Purchase VAT Account");
                        end else
                            if VATEntry.Type = VATEntry.Type::Sale then begin
                                VATPostingSetup.TestField("Sales VAT Account");
                                Validate("Account No.", VATPostingSetup."Sales VAT Account");
                            end;
                    Type::WriteOff:
                        begin
                            VATPostingSetup.TestField("Write-Off VAT Account");
                            Validate("Account No.", VATPostingSetup."Write-Off VAT Account")
                        end;
                    Type::Charge:
                        case VATEntry."Object Type" of
                            VATEntry."Object Type"::"G/L Account":
                                Validate("Account No.", VATEntry."Object No.");
                            VATEntry."Object Type"::"Fixed Asset":
                                begin
                                    FASetup.Get();
                                    FA.Get(VATEntry."Object No.");
                                    if FA."Initial Release Date" <> 0D then begin // Released
                                        FASetup.TestField("Release Depr. Book");
                                        FADeprBook.Get(FA."No.", FASetup."Release Depr. Book");
                                        FAPostingGr.Get(FADeprBook."FA Posting Group");
                                        Validate("Account No.", FAPostingGr."Acquisition Cost Account");
                                    end else begin // Aquisition
                                        FASetup.TestField("Default Depr. Book");
                                        FADeprBook.Get(FA."No.", FA.GetDefDeprBook());
                                        FAPostingGr.Get(FADeprBook."FA Posting Group");
                                        Validate("Account No.", FAPostingGr."Acquisition Cost Account");
                                    end;
                                    "FA No." := FA."No.";
                                end;
                            VATEntry."Object Type"::Vendor:
                                begin
                                    GenPostingSetup.Get(VATEntry."Gen. Bus. Posting Group", VATEntry."Gen. Prod. Posting Group");
                                    if VATEntry.Type = VATEntry.Type::Purchase then begin
                                        GenPostingSetup.TestField("Purch. Account");
                                        Validate("Account No.", GenPostingSetup."Purch. Account");
                                    end;
                                end;
                            VATEntry."Object Type"::Customer:
                                begin
                                    GenPostingSetup.Get(VATEntry."Gen. Bus. Posting Group", VATEntry."Gen. Prod. Posting Group");
                                    if VATEntry.Type = VATEntry.Type::Sale then begin
                                        GenPostingSetup.TestField("Sales Account");
                                        Validate("Account No.", GenPostingSetup."Sales Account");
                                    end;
                                end;
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
        field(6; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Amount';
            Editable = false;
        }
        field(7; "Allocation %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Allocation %';
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                Amount := CalcRoundedAmount("Allocation %", "VAT Amount")
            end;
        }
        field(8; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';

            trigger OnValidate()
            var
                PostingDate: Date;
                CommonBase: Option;
            begin
                if FindCommonBase(CommonBase) then
                    TestField(Base, CommonBase);
                if Base = Base::Depreciation then
                    "VAT Amount" := GetFPEDeprAmount(PostingDate, "VAT Base Amount")
                else
                    "VAT Amount" := GetUnrealizedVATAmount(Base = Base::Remaining, "VAT Base Amount");

                "Allocation %" := 0;
                if Abs(Amount) > Abs("VAT Amount") then
                    Amount := "VAT Amount";

                if ("VAT Amount" * Amount) < 0 then begin
                    if Amount < 0 then
                        Error(Text001, FieldCaption(Amount));
                    Error(Text002, FieldCaption(Amount));
                end;
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
                PostingDate: Date;
                CommonBase: Option;
            begin
                if FindCommonBase(CommonBase) then
                    TestField(Base, CommonBase);
                if Base = Base::Depreciation then
                    "VAT Amount" := GetFPEDeprAmount(PostingDate, "VAT Base Amount")
                else
                    "VAT Amount" := GetUnrealizedVATAmount(Base = Base::Remaining, "VAT Base Amount");

                if "Allocation %" <> 0 then
                    Validate("Allocation %")
                else
                    Validate(Amount);
                CheckVATAllocation();
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
        field(15; "VAT Settlement Type"; Option)
        {
            Caption = 'VAT Settlement Type';
            OptionCaption = ' ,by Act,Future Expenses';
            OptionMembers = " ","by Act","Future Expenses";
        }
        field(16; "Posting Date Filter"; Date)
        {
            Caption = 'Posting Date Filter';
            FieldClass = FlowFilter;
        }
        field(17; "VAT Base Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'VAT Base Amount';
        }
        field(18; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(19; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(20; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            TableRelation = "Fixed Asset";
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
        key(Key1; "VAT Entry No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount;
        }
        key(Key2; "CV Ledger Entry No.", "VAT Settlement Type", "VAT Bus. Posting Group", "VAT Prod. Posting Group")
        {
            SumIndexFields = Amount;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        CommonBase: Option;
    begin
        LockTable();
        TestField("VAT Entry No.");
        VATEntry.Get("VAT Entry No.");
        VATEntry.TestField("Unrealized Base");

        FindCommonBase(CommonBase);
        Validate(Base, CommonBase);

        Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
    end;

    var
        GLAcc: Record "G/L Account";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 must be positive.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label '%1 must be negative.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        VATEntry: Record "VAT Entry";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'Sum of Amount must not be greater than %1 in VAT Allocation line field VAT Amount.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DimMgt: Codeunit DimensionManagement;
        SkipChecking: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'Sum of Amount must not be greater than Remaining Unrealized Amount in VAT Entry No. %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure UpdateAllocations(var GenJnlLine: Record "Gen. Journal Line"; ManualAmount: Boolean)
    var
        VATSettlementMgt: Codeunit "VAT Settlement Management";
        FromAllocations: Boolean;
    begin
        if GenJnlLine."Unrealized VAT Entry No." = 0 then
            exit;

        if "Line No." <> 0 then begin
            FromAllocations := true;
            Modify();
        end;

        VATSettlementMgt.CreateAllocation(GenJnlLine."Unrealized VAT Entry No.");
        if ManualAmount then
            VATSettlementMgt.CalculateAllocation(GenJnlLine."Unrealized VAT Entry No.", GenJnlLine.Amount, GenJnlLine."Posting Date")
        else
            VATSettlementMgt.RecalculateAllocation(GenJnlLine."Unrealized VAT Entry No.", GenJnlLine."Posting Date");

        if FromAllocations then
            Find();
    end;

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
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), "VAT Entry No.", "Line No."));
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure GetUnrealizedVATAmount(Remaining: Boolean; var VATBaseAmount: Decimal) Result: Decimal
    begin
        if VATEntry.Get("VAT Entry No.") then
            if Remaining then begin
                Result := VATEntry."Remaining Unrealized Amount";
                VATBaseAmount := VATEntry."Remaining Unrealized Base";
            end else begin
                Result := VATEntry."Unrealized Amount";
                VATBaseAmount := VATEntry."Unrealized Base";
            end;
    end;

    [Scope('OnPrem')]
    procedure GetFPEDeprAmount(PostingDate: Date; var VATBaseAmount: Decimal) Result: Decimal
    var
        FA: Record "Fixed Asset";
        FALedgEntry: Record "FA Ledger Entry";
        FAInsertLedgEntry: Codeunit "FA Insert Ledger Entry";
        FALedgEntryNo: Integer;
    begin
        Result := 0;
        VATEntry.Get("VAT Entry No.");
        VATEntry.TestField("VAT Settlement Type", VATEntry."VAT Settlement Type"::"Future Expenses");
        FA.Get(VATEntry."Object No.");
        FA.SetFilter("Date Filter", GetFilter("Posting Date Filter"));
        FALedgEntryNo := FAInsertLedgEntry.GetDeprEntryForVATSettlement(FA, PostingDate, "VAT Entry No.");
        if FALedgEntryNo <> 0 then begin
            FALedgEntry.Get(FALedgEntryNo);
            VATBaseAmount := -FALedgEntry.GetAmountToRealize("VAT Entry No.");
            Result := VATEntry.GetAmountOnBase(VATBaseAmount);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckVATAllocation()
    var
        VATAllocLine: Record "VAT Allocation Line";
        VATBaseAmount: Decimal;
        RemAmount: Decimal;
    begin
        if SkipChecking then
            exit;

        VATAllocLine.SetRange("VAT Entry No.", "VAT Entry No.");
        VATAllocLine.SetFilter("Line No.", '<>%1', "Line No.");
        VATAllocLine.CalcSums(Amount);
        if Abs(VATAllocLine.Amount + Amount) > Abs("VAT Amount") then
            Error(Text003, "VAT Amount");
        RemAmount := GetUnrealizedVATAmount(Base = Base::Remaining, VATBaseAmount);
        if Abs(VATAllocLine.Amount + Amount) > Abs(RemAmount) then
            Error(Text004, "VAT Entry No.");
    end;

    [Scope('OnPrem')]
    procedure SetTotalCheck(Value: Boolean)
    begin
        SkipChecking := not Value;
    end;

    [Scope('OnPrem')]
    procedure HandleType()
    var
        VATAllocLine: Record "VAT Allocation Line";
    begin
        if Type = Type::VAT then begin
            VATAllocLine.SetRange("VAT Entry No.", "VAT Entry No.");
            VATAllocLine.SetFilter("Line No.", '<>%1', "Line No.");
            VATAllocLine.SetRange(Type, Type::VAT);
            if not VATAllocLine.IsEmpty() then
                Type := Type::WriteOff;
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcRoundedAmount(NewAllocPercent: Decimal; NewVATAmount: Decimal): Decimal
    var
        VATAllocLine: Record "VAT Allocation Line";
        TotalAmount: Decimal;
        TotalAmountRnded: Decimal;
    begin
        VATAllocLine.SetRange("VAT Entry No.", "VAT Entry No.");
        if VATAllocLine.FindSet() then
            repeat
                if VATAllocLine."Line No." = "Line No." then begin
                    VATAllocLine."Allocation %" := NewAllocPercent;
                    VATAllocLine."VAT Amount" := NewVATAmount;
                end;
                if VATAllocLine."Allocation %" <> 0 then begin
                    TotalAmount := TotalAmount + VATAllocLine."VAT Amount" * VATAllocLine."Allocation %" / 100;
                    VATAllocLine.Amount := Round(TotalAmount) - TotalAmountRnded;
                    TotalAmountRnded := TotalAmountRnded + VATAllocLine.Amount;
                    if VATAllocLine."Line No." = "Line No." then
                        exit(VATAllocLine.Amount);
                end;
            until VATAllocLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure FindCommonBase(var NewBase: Option): Boolean
    var
        VATAllocLine: Record "VAT Allocation Line";
    begin
        VATAllocLine.SetRange("VAT Entry No.", "VAT Entry No.");
        VATAllocLine.SetFilter("Line No.", '<>%1', "Line No.");
        if VATAllocLine.FindFirst() then begin
            NewBase := VATAllocLine.Base;
            exit(true);
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ShowAllocationLines()
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        TestField(Type, Type::Charge);
        VATEntry.Get("VAT Entry No.");

        PurchInvLine.SetRange("Document No.", VATEntry."Document No.");
        PurchInvLine.SetRange("VAT Bus. Posting Group", VATEntry."VAT Bus. Posting Group");
        PurchInvLine.SetRange("VAT Prod. Posting Group", VATEntry."VAT Prod. Posting Group");
        PAGE.Run(0, PurchInvLine);
    end;
}

