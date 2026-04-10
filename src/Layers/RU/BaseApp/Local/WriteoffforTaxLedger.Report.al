#pragma warning disable AA0247
report 14934 "Write-off for Tax Ledger"
{
    Caption = 'Write-off for Tax Ledger';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Posted FA Doc. Header"; "Posted FA Doc. Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Writeoff));
            dataitem("Posted FA Doc. Line"; "Posted FA Doc. Line")
            {
                DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                trigger OnAfterGetRecord()
                var
                    FixedAsset: Record "Fixed Asset";
                    GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
                    FAJnlPostLine: Codeunit "FA Jnl.-Post Line";
                    DimMgt: Codeunit DimensionManagement;
                    BookValue: Decimal;
                    DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
                begin
                    FixedAsset.Get("FA No.");
                    Window.Update(1, "FA No.");

                    FADeprBook.Get("FA No.", DeprBookCode);
                    FADeprBook.SetFilter("FA Posting Date Filter", '..%1', PostingDate);
                    FADeprBook.CalcFields("Book Value");
                    if FADeprBook."Book Value" = 0 then
                        CurrReport.Skip();

                    if not DeprBook."G/L Integration - Disposal" or FixedAsset."Budgeted Asset" then begin
                        FAJnlLine.LockTable();
                        FAJnlSetup.FAJnlName(DeprBook, FAJnlLine, FAJnlNextLineNo);
                        FAJnlLine.Init();
                        FAJnlSetup.SetFAJnlTrailCodes(FAJnlLine);
                        FAJnlNextLineNo := FAJnlNextLineNo + 10000;
                        FAJnlLine."Line No." := FAJnlNextLineNo;
                        FAJnlLine."Posting Date" := PostingDate;
                        FAJnlLine."FA Posting Date" := PostingDate;
                        if FAJnlLine."Posting Date" = FAJnlLine."FA Posting Date" then
                            FAJnlLine."Posting Date" := 0D;
                        FAJnlLine.Validate("FA Posting Type", FAJnlLine."FA Posting Type"::Disposal);
                        FAJnlLine.Validate("FA No.", FixedAsset."No.");
                        FAJnlLine."Document No." := "Posted FA Doc. Header"."No.";
                        FAJnlLine.Validate("Depreciation Book Code", DeprBookCode);
                        FAJnlLine.Validate("Depr. until FA Posting Date", not DeprBook."G/L Integration - Depreciation");
                        FAJnlLine.Validate(Amount, BookValue);
                        FAJnlLine."Location Code" := FixedAsset."FA Location Code";
                        FAJnlLine."Employee No." := FixedAsset."Responsible Employee";
                        FAJnlLine.CreateDimFromDefaultDim();
                        if Post then
                            FAJnlPostLine.FAJnlPostLine(FAJnlLine, true)
                        else
                            FAJnlLine.Insert(true);
                    end else begin
                        GenJnlLine.LockTable();
                        FAJnlSetup.GenJnlName(DeprBook, GenJnlLine, GenJnlNextLineNo);

                        GenJnlLine.Init();
                        FAJnlSetup.SetGenJnlTrailCodes(GenJnlLine);
                        GenJnlNextLineNo := GenJnlNextLineNo + 1000;
                        GenJnlLine."Line No." := GenJnlNextLineNo;
                        GenJnlLine."Posting Date" := PostingDate;
                        GenJnlLine."FA Posting Date" := PostingDate;
                        if GenJnlLine."Posting Date" = GenJnlLine."FA Posting Date" then
                            GenJnlLine."FA Posting Date" := 0D;
                        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
                        GenJnlLine.Validate("FA Posting Type", GenJnlLine."FA Posting Type"::Disposal);
                        GenJnlLine.Validate("Account No.", FixedAsset."No.");
                        GenJnlLine."Document No." := "Posted FA Doc. Header"."No.";
                        GenJnlLine.Validate("Depreciation Book Code", DeprBookCode);
                        GenJnlLine.Validate(Amount, BookValue);
                        GenJnlLine."Employee No." := FixedAsset."Responsible Employee";
                        GenJnlLine."FA Location Code" := FixedAsset."FA Location Code";
                        DimMgt.AddDimSource(DefaultDimSource, DimMgt.TypeToTableID1(GenJnlLine."Account Type".AsInteger()), GenJnlLine."Account No.");
                        GenJnlLine.CreateDim(DefaultDimSource);
                        if Post then
                            GenJnlPostLine.RunWithCheck(GenJnlLine)
                        else
                            GenJnlLine.Insert(true);
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if UseNewPostDate then
                    PostingDate := NewPostingDate
                else
                    PostingDate := "Posting Date";
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Control1210001)
                {
                    ShowCaption = false;
                    field(UseNewPostDate; UseNewPostDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use New Posting Date';

                        trigger OnValidate()
                        begin
                            if not UseNewPostDate then
                                NewPostingDate := 0D;
                        end;
                    }
                    field(NewPostingDate; NewPostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Posting Date';
                        Editable = UseNewPostDate;
                    }
                    field(Post; Post)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        TaxRegisterSetup.Get();
        TaxRegisterSetup.TestField("Tax Depreciation Book");
        DeprBookCode := TaxRegisterSetup."Tax Depreciation Book";
        DeprBook.Get(DeprBookCode);

        if UseNewPostDate then
            if NewPostingDate = 0D then
                Error(Text000);

        Window.Open(
          Text001 +
          Text002);
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        FAJnlLine: Record "FA Journal Line";
        FAJnlSetup: Record "FA Journal Setup";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        TaxRegisterSetup: Record "Tax Register Setup";
        Window: Dialog;
        NewPostingDate: Date;
        PostingDate: Date;
        DeprBookCode: Code[10];
        UseNewPostDate: Boolean;
        Post: Boolean;
        FAJnlNextLineNo: Integer;
        GenJnlNextLineNo: Integer;
#pragma warning disable AA0074
        Text000: Label 'You must specify New Posting Date.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text001: Label 'Processing';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'Fixed Asset #1##########';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure InitializeRequest(UseNewPostDate2: Boolean; NewPostingDate2: Date; Post2: Boolean)
    begin
        ClearAll();
        UseNewPostDate := UseNewPostDate2;
        NewPostingDate := NewPostingDate2;
        Post := Post2;
    end;
}

