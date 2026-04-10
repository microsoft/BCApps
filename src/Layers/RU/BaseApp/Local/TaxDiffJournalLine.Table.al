#pragma warning disable AA0247
table 17305 "Tax Diff. Journal Line"
{
    Caption = 'Tax Diff. Journal Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                SearchTaxFactor();
            end;
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(6; "Tax Diff. Type"; Option)
        {
            Caption = 'Tax Diff. Type';
            OptionCaption = 'Constant,Temporary';
            OptionMembers = Constant,"Temporary";

            trigger OnValidate()
            begin
                if "Tax Diff. Type" = "Tax Diff. Type"::Constant then
                    TestField("Partial Disposal", false);
            end;
        }
        field(7; "Tax Diff. Code"; Code[10])
        {
            Caption = 'Tax Diff. Code';
            TableRelation = "Tax Difference";

            trigger OnValidate()
            begin
                if "Tax Diff. Code" = '' then begin
                    "Jurisdiction Code" := '';
                    "Norm Code" := '';
                    "Tax Diff. Posting Group" := '';
                    "YTD Amount (Base)" := 0;
                    "YTD Amount (Tax)" := 0;
                    "YTD Difference" := 0;
                    "Amount (Base)" := 0;
                    "Amount (Tax)" := 0;
                    Difference := 0;
                    "Tax Amount" := 0;
                    "Asset Tax Amount" := 0;
                    "Liability Tax Amount" := 0;
                    "Disposal Tax Amount" := 0;
                    "DTA Starting Balance" := 0;
                    "DTL Starting Balance" := 0;
                    "DTA Ending Balance" := 0;
                    "DTL Ending Balance" := 0;
                end else begin
                    TaxDiff.Get("Tax Diff. Code");
                    "Tax Diff. Type" := TaxDiff.Type;
                    "Tax Diff. Category" := TaxDiff.Category;
                    "Jurisdiction Code" := TaxDiff."Norm Jurisdiction Code";
                    "Norm Code" := TaxDiff."Norm Code";
                    "Tax Diff. Posting Group" := TaxDiff."Posting Group";
                    Validate("Norm Code");
                end;
            end;
        }
        field(8; "Tax Diff. Category"; Option)
        {
            Caption = 'Tax Diff. Category';
            OptionCaption = 'Expense,Income';
            OptionMembers = Expense,Income;

            trigger OnValidate()
            begin
                if Difference <> 0 then
                    UpdateAmount()
                else
                    UpdateByNetChange();
            end;
        }
        field(9; "Jurisdiction Code"; Code[10])
        {
            Caption = 'Jurisdiction Code';
            TableRelation = "Tax Register Norm Jurisdiction";

            trigger OnValidate()
            begin
                if "Jurisdiction Code" <> xRec."Jurisdiction Code" then
                    Validate("Norm Code", '');
            end;
        }
        field(10; "Norm Code"; Code[10])
        {
            Caption = 'Norm Code';
            TableRelation = "Tax Register Norm Group".Code where("Norm Jurisdiction Code" = field("Jurisdiction Code"));

            trigger OnValidate()
            begin
                SearchTaxFactor();
            end;
        }
        field(11; "Tax Factor"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Tax Factor';

            trigger OnValidate()
            begin
                if Difference <> 0 then
                    UpdateAmount()
                else
                    UpdateByNetChange();
            end;
        }
        field(12; "Tax Diff. Posting Group"; Code[20])
        {
            Caption = 'Tax Diff. Posting Group';
            TableRelation = "Tax Diff. Posting Group";
        }
        field(13; "Amount (Base)"; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Amount (Base)';

            trigger OnValidate()
            begin
                Validate(Difference, "Amount (Base)" - "Amount (Tax)");
            end;
        }
        field(14; "Amount (Tax)"; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Amount (Tax)';

            trigger OnValidate()
            begin
                Validate(Difference, "Amount (Base)" - "Amount (Tax)");
            end;
        }
        field(15; Difference; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Difference';

            trigger OnValidate()
            begin
                if Difference <> ("Amount (Base)" - "Amount (Tax)") then
                    case true of
                        ("Amount (Base)" = 0) and ("Amount (Base)" > Difference):
                            "Amount (Tax)" := "Amount (Base)" - Difference;
                        ("Amount (Tax)" = 0) and ("Amount (Tax)" > -Difference):
                            "Amount (Base)" := "Amount (Tax)" + Difference;
                        "Amount (Base)" = 0:
                            FieldError("Amount (Base)", Text1000);
                        "Amount (Tax)" = 0:
                            FieldError("Amount (Tax)", Text1000);
                        else
                            Error(Text1001, Difference, "Amount (Base)", "Amount (Tax)");
                    end;
                UpdateAmount();
            end;
        }
        field(16; "Tax Amount"; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Tax Amount';
            Editable = false;
        }
        field(17; "Asset Tax Amount"; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Asset Tax Amount';
            Editable = false;
        }
        field(18; "Liability Tax Amount"; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Liability Tax Amount';
            Editable = false;
        }
        field(19; "Disposal Tax Amount"; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Disposal Tax Amount';
            Editable = false;
        }
        field(20; "DTA Starting Balance"; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'DTA Starting Balance';
            Editable = false;
        }
        field(21; "DTL Starting Balance"; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'DTL Starting Balance';
            Editable = false;
        }
        field(22; "Disposal Date"; Date)
        {
            Caption = 'Disposal Date';
        }
        field(23; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(24; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(25; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(26; "Disposal Mode"; Option)
        {
            Caption = 'Disposal Mode';
            OptionCaption = ' ,Write Down,Transform';
            OptionMembers = " ","Write Down",Transform;

            trigger OnValidate()
            begin
                if "Disposal Mode" <> "Disposal Mode"::" " then
                    TestField("Tax Diff. Type", "Tax Diff. Type"::"Temporary");
                Validate("Tax Factor");
            end;
        }
        field(27; "DTA Ending Balance"; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'DTA Ending Balance';
            Editable = false;
        }
        field(28; "DTL Ending Balance"; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'DTL Ending Balance';
            Editable = false;
        }
        field(29; "YTD Amount (Base)"; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'YTD Amount (Base)';

            trigger OnValidate()
            begin
                Validate("YTD Difference", "YTD Amount (Base)" - "YTD Amount (Tax)");
            end;
        }
        field(30; "YTD Amount (Tax)"; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'YTD Amount (Tax)';

            trigger OnValidate()
            begin
                Validate("YTD Difference", "YTD Amount (Base)" - "YTD Amount (Tax)");
            end;
        }
        field(31; "YTD Difference"; Decimal)
        {
            AutoFormatType = 0;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'YTD Difference';

            trigger OnValidate()
            begin
                TestField("Partial Disposal", false);
                if "YTD Difference" <> ("YTD Amount (Base)" - "YTD Amount (Tax)") then
                    case true of
                        ("YTD Amount (Base)" = 0) and ("YTD Amount (Base)" > "YTD Difference"):
                            "Amount (Tax)" := "Amount (Base)" - "YTD Difference";
                        ("YTD Amount (Tax)" = 0) and ("YTD Amount (Tax)" > -"YTD Difference"):
                            "YTD Amount (Base)" := "YTD Amount (Tax)" + "YTD Difference";
                        "YTD Amount (Base)" = 0:
                            FieldError("YTD Amount (Base)", Text1000);
                        "YTD Amount (Tax)" = 0:
                            FieldError("YTD Amount (Tax)", Text1000);
                        else
                            Error(Text1001, "YTD Difference", "YTD Amount (Base)", "YTD Amount (Tax)");
                    end;

                UpdateByNetChange();
            end;
        }
        field(32; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Future Expense,Fixed Asset,Intangible Asset';
            OptionMembers = " ","Future Expense","Fixed Asset","Intangible Asset";

            trigger OnValidate()
            begin
                if "Source Type" <> xRec."Source Type" then
                    Validate("Source No.", '');
            end;
        }
        field(33; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const("Future Expense")) "Fixed Asset"."No." where("FA Type" = const("Future Expense"))
            else
            if ("Source Type" = const("Fixed Asset")) "Fixed Asset"."No." where("FA Type" = const("Fixed Assets"))
            else
            if ("Source Type" = const("Intangible Asset")) "Fixed Asset"."No." where("FA Type" = const("Intangible Asset"));

            trigger OnValidate()
            begin
                if "Source No." <> xRec."Source No." then begin
                    "Tax Diff. Code" := '';

                    if "Source No." <> '' then
                        case "Source Type" of
                            "Source Type"::"Future Expense",
                            "Source Type"::"Fixed Asset",
                            "Source Type"::"Intangible Asset":
                                begin
                                    FA.Get("Source No.");
                                    FA.TestField("Tax Difference Code");
                                    "Tax Diff. Code" := FA."Tax Difference Code";
                                end;
                            "Source Type"::" ":
                                FieldError("Source Type");
                        end;
                    Validate("Tax Diff. Code");
                end;
            end;
        }
        field(34; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(35; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(36; "Partial Disposal"; Boolean)
        {
            Caption = 'Partial Disposal';

            trigger OnValidate()
            begin
                if "Partial Disposal" then
                    TestField("Tax Diff. Type", "Tax Diff. Type"::"Temporary");
                UpdateAmount();
            end;
        }
        field(37; "Tax Diff. Calc. Mode"; Option)
        {
            Caption = 'Tax Diff. Calc. Mode';
            OptionCaption = ' ,Balance';
            OptionMembers = " ",Balance;

            trigger OnValidate()
            begin
                if "Tax Diff. Calc. Mode" = "Tax Diff. Calc. Mode"::Balance then
                    UpdateByNetChange()
                else
                    Validate("Tax Factor");
            end;
        }
        field(45; "Depr. Bonus Recovery"; Boolean)
        {
            Caption = 'Depr. Bonus Recovery';
        }
        field(46; "Source Entry Type"; Option)
        {
            Caption = 'Source Entry Type';
            OptionCaption = ' ,FA,Depr. Bonus,Disposed FA';
            OptionMembers = " ",FA,"Depr. Bonus","Disposed FA";
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
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        LockTable();

        Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
    end;

    var
        TaxDiff: Record "Tax Difference";
        FA: Record "Fixed Asset";
        DimMgt: Codeunit DimensionManagement;
#pragma warning disable AA0074
        Text1000: Label ' cannot be negative';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1001: Label '%1 can be defined than %2=0 and %3=0 only.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure UpdateAmount()
    begin
        "YTD Amount (Base)" := 0;
        "YTD Amount (Tax)" := 0;
        "YTD Difference" := 0;
        "Tax Amount" := 0;
        "Asset Tax Amount" := 0;
        "Liability Tax Amount" := 0;
        "Disposal Tax Amount" := 0;
        "DTA Starting Balance" := 0;
        "DTL Starting Balance" := 0;
        "DTA Ending Balance" := 0;
        "DTL Ending Balance" := 0;
        case "Tax Diff. Type" of
            "Tax Diff. Type"::Constant:
                begin
                    TestField("Partial Disposal", false);
                    case true of
                        ("Tax Diff. Category" = "Tax Diff. Category"::Expense) and (Difference > 0),
                      ("Tax Diff. Category" = "Tax Diff. Category"::Income) and (Difference < 0):
                            "Liability Tax Amount" := GetTaxAmount(Difference);
                        ("Tax Diff. Category" = "Tax Diff. Category"::Expense) and (Difference < 0),
                      ("Tax Diff. Category" = "Tax Diff. Category"::Income) and (Difference > 0):
                            "Asset Tax Amount" := GetTaxAmount(Difference);
                    end;
                end;
            "Tax Diff. Type"::"Temporary":
                if "Partial Disposal" then begin
                    "Disposal Tax Amount" := GetTaxAmount(Difference);
                    if Difference < 0 then
                        "Disposal Tax Amount" := -"Disposal Tax Amount";
                end else
                    if GetStartingAmount() then begin
                        case true of
                            ("Tax Diff. Category" = "Tax Diff. Category"::Expense) and (Difference > 0),
                            ("Tax Diff. Category" = "Tax Diff. Category"::Income) and (Difference < 0):
                                begin
                                    "Asset Tax Amount" := GetTaxAmount(Difference);
                                    if "DTL Starting Balance" <> 0 then begin
                                        if "Asset Tax Amount" > "DTL Starting Balance" then
                                            "Liability Tax Amount" := -"DTL Starting Balance"
                                        else
                                            "Liability Tax Amount" := -"Asset Tax Amount";
                                        "Asset Tax Amount" += "Liability Tax Amount";
                                    end;
                                end;
                            ("Tax Diff. Category" = "Tax Diff. Category"::Expense) and (Difference < 0),
                            ("Tax Diff. Category" = "Tax Diff. Category"::Income) and (Difference > 0):
                                begin
                                    "Liability Tax Amount" := GetTaxAmount(Difference);
                                    if "DTA Starting Balance" <> 0 then begin
                                        if "Liability Tax Amount" > "DTA Starting Balance" then
                                            "Asset Tax Amount" := -"DTA Starting Balance"
                                        else
                                            "Asset Tax Amount" := -"Liability Tax Amount";
                                        "Liability Tax Amount" += "Asset Tax Amount";
                                    end;
                                end;
                        end;
                        "DTA Ending Balance" := "DTA Starting Balance" + "Asset Tax Amount";
                        "DTL Ending Balance" := "DTL Starting Balance" + "Liability Tax Amount";
                        if "Disposal Mode" <> "Disposal Mode"::" " then begin
                            "Disposal Tax Amount" := "DTA Ending Balance" - "DTL Ending Balance";
                            "DTA Ending Balance" := 0;
                            "DTL Ending Balance" := 0;
                        end;
                    end;
        end;
        "Tax Amount" := "Asset Tax Amount" - "Liability Tax Amount" - "Disposal Tax Amount";
    end;

    local procedure UpdateByNetChange()
    begin
        "Amount (Base)" := 0;
        "Amount (Tax)" := 0;
        Difference := 0;
        "Tax Amount" := 0;
        "Asset Tax Amount" := 0;
        "Liability Tax Amount" := 0;
        "Disposal Tax Amount" := 0;
        "DTA Starting Balance" := 0;
        "DTL Starting Balance" := 0;
        "DTA Ending Balance" := 0;
        "DTL Ending Balance" := 0;
        if "Partial Disposal" then
            exit;
        if GetStartingAmount() then begin
            if "Tax Diff. Type" <> "Tax Diff. Type"::"Temporary" then
                exit;
            if ("Tax Diff. Calc. Mode" <> "Tax Diff. Calc. Mode"::Balance) and ("YTD Difference" = 0) then
                exit;
            case true of
                ("Tax Diff. Category" = "Tax Diff. Category"::Expense) and ("YTD Difference" > 0),
                ("Tax Diff. Category" = "Tax Diff. Category"::Income) and ("YTD Difference" < 0):
                    begin
                        "DTA Ending Balance" := GetTaxAmount("YTD Difference");
                        "Asset Tax Amount" := "DTA Ending Balance" - "DTA Starting Balance";
                        if "DTL Starting Balance" <> 0 then
                            if "Asset Tax Amount" > "DTL Starting Balance" then
                                "Liability Tax Amount" := -"DTL Starting Balance"
                            else
                                "Liability Tax Amount" := -"Asset Tax Amount";
                    end;
                ("Tax Diff. Category" = "Tax Diff. Category"::Expense) and ("YTD Difference" < 0),
                ("Tax Diff. Category" = "Tax Diff. Category"::Income) and ("YTD Difference" > 0):
                    begin
                        "DTL Ending Balance" := GetTaxAmount("YTD Difference");
                        "Liability Tax Amount" := "DTL Ending Balance" - "DTL Starting Balance";
                        if "DTA Starting Balance" <> 0 then
                            if "Liability Tax Amount" > "DTA Starting Balance" then
                                "Asset Tax Amount" := -"DTA Starting Balance"
                            else
                                "Asset Tax Amount" := -"Liability Tax Amount";
                    end;
                "YTD Difference" = 0:
                    if "DTA Starting Balance" <> 0 then
                        "Asset Tax Amount" := -"DTA Starting Balance"
                    else
                        if "DTL Starting Balance" <> 0 then
                            "Liability Tax Amount" := -"DTL Starting Balance";
            end;
            if "Disposal Mode" <> "Disposal Mode"::" " then begin
                "Disposal Tax Amount" := "DTA Ending Balance" - "DTL Ending Balance";
                "DTA Ending Balance" := 0;
                "DTL Ending Balance" := 0;
            end;
            "Tax Amount" := "Asset Tax Amount" - "Liability Tax Amount" - "Disposal Tax Amount";
        end;
    end;

    local procedure GetTaxAmount(NetAmount: Decimal): Decimal
    begin
        exit(Round(Abs(NetAmount) * "Tax Factor"));
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
    end;

    [Scope('OnPrem')]
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure GetStartingAmount(): Boolean
    var
        TaxDiffLedgEntry: Record "Tax Diff. Ledger Entry";
    begin
        if "Tax Diff. Type" = "Tax Diff. Type"::"Temporary" then begin
            if ("Source Type" = "Source Type"::"Future Expense") and ("Source No." <> '') then begin
                FA.Get("Source No.");
                FA.TestField("Tax Difference Code");
                TestField("Tax Diff. Code", FA."Tax Difference Code");
            end;
            if "Tax Diff. Code" <> '' then begin
                TaxDiff.Get("Tax Diff. Code");
                TestField("Posting Date");
                TaxDiffLedgEntry.Reset();
                TaxDiffLedgEntry.SetCurrentKey("Tax Diff. Code", "Source Type", "Source No.", "Posting Date");
                TaxDiffLedgEntry.SetRange("Tax Diff. Code", "Tax Diff. Code");
                TaxDiffLedgEntry.SetRange("Source Type", "Source Type");
                TaxDiffLedgEntry.SetRange("Source No.", "Source No.");
                TaxDiffLedgEntry.SetFilter("Posting Date", '..%1', "Posting Date");
                TaxDiffLedgEntry.CalcSums("Tax Amount");
                if TaxDiffLedgEntry."Tax Amount" > 0 then
                    "DTA Starting Balance" := TaxDiffLedgEntry."Tax Amount";
                if TaxDiffLedgEntry."Tax Amount" < 0 then
                    "DTL Starting Balance" := -TaxDiffLedgEntry."Tax Amount";
                exit(true);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetUpNewLine(LastTaxDiffJnlLine: Record "Tax Diff. Journal Line")
    var
        TaxDiffJnlTemplate: Record "Tax Diff. Journal Template";
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        NoSeries: Codeunit "No. Series";
    begin
        TaxDiffJnlTemplate.Get("Journal Template Name");
        TaxDiffJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        TaxDiffJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        TaxDiffJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if TaxDiffJnlLine.FindFirst() then begin
            "Posting Date" := LastTaxDiffJnlLine."Posting Date";
            "Document No." := LastTaxDiffJnlLine."Document No.";
        end else begin
            "Posting Date" := WorkDate();
            if TaxDiffJnlBatch."No. Series" <> '' then
                "Document No." := NoSeries.PeekNextNo(TaxDiffJnlBatch."No. Series", "Posting Date");
        end;
        "Source Code" := TaxDiffJnlTemplate."Source Code";
        "Reason Code" := TaxDiffJnlBatch."Reason Code";
        Description := '';
    end;

    local procedure SearchTaxFactor()
    var
        TaxRegNormGroup: Record "Tax Register Norm Group";
        TaxRegNormDetail: Record "Tax Register Norm Detail";
    begin
        "Tax Factor" := 0;
        if Rec."Posting Date" <> 0D then
            if TaxRegNormGroup.Get("Jurisdiction Code", "Norm Code") then begin
                TaxRegNormDetail.Reset();
                TaxRegNormDetail.SetRange("Norm Jurisdiction Code", "Jurisdiction Code");
                TaxRegNormDetail.SetRange("Norm Group Code", "Norm Code");
                if TaxRegNormGroup."Search Detail" = TaxRegNormGroup."Search Detail"::"To Date" then
                    TaxRegNormDetail.SetFilter("Effective Date", '..%1', "Posting Date")
                else
                    TaxRegNormDetail.SetRange("Effective Date", "Posting Date");
                if TaxRegNormDetail.FindLast() then
                    "Tax Factor" := TaxRegNormDetail.Norm;
            end;
        Validate("Tax Factor");
    end;
}

