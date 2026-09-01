#pragma warning disable AA0247
report 17304 "Create FE from Sold FA"
{
    ApplicationArea = FixedAssets;
    Caption = 'Create FE from Sold FA';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            DataItemTableView = sorting("FA Type") where("FA Type" = filter(<> "Future Expense"));
            RequestFilterFields = "No.";
            dataitem("Depreciation Book"; "Depreciation Book")
            {
                DataItemTableView = sorting(Code) where("Posting Book Type" = const("Tax Accounting"));
                dataitem("FA Depreciation Book"; "FA Depreciation Book")
                {
                    DataItemLink = "Depreciation Book Code" = field(Code);
                    DataItemTableView = sorting("FA No.", "Depreciation Book Code") where("Disposal Date" = filter(<> 0D));

                    trigger OnAfterGetRecord()
                    begin
                        CalcFields("Book Value", "Gain/Loss");
                        if ("Book Value" = 0) and ("Gain/Loss" > 0) then begin
                            GainLoss += "Gain/Loss";
                            TestField("Depreciation Ending Date");
                            if DisposalDate = 0D then begin
                                DisposalDate := "Disposal Date";
                                DepreciationEndingDate := "Depreciation Ending Date";
                            end else begin
                                TestField("Disposal Date", DisposalDate);
                                TestField("Depreciation Ending Date", DepreciationEndingDate)
                            end;
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("FA No.", "Fixed Asset"."No.");
                    end;
                }

                trigger OnPostDataItem()
                var
                    NoSeries: Codeunit "No. Series";
                begin
                    if GainLoss = 0 then
                        exit;

                    FE := FETemplate;
                    FE.Blocked := false;
                    FE.Inactive := false;
                    FE."No." := NoSeries.GetNextNo(NoSeriesCode, Today());
                    FE."No. Series" := NoSeriesCode;
                    FE."FA Type" := FE."FA Type"::"Future Expense";
                    FE."Created by FA No." := "Fixed Asset"."No.";
                    FE.Insert();
                    FE.Validate(Description, CopyStr(StrSubstNo(Text1000, "Fixed Asset"."No."), 1, MaxStrLen(FE.Description)));

                    FEDeprBook := FEDeprBookAccounting;
                    FEDeprBook."FA No." := FE."No.";
                    FEDeprBook.Description := FE.Description;
                    FEDeprBook.Insert(true);
                    FEDeprBook.Validate("Depreciation Starting Date", 0D);
                    FEDeprBook.Modify();

                    FEDeprBook := FEDeprBookTaxAccounting;
                    FEDeprBook."FA No." := FE."No.";
                    FEDeprBook.Description := FE.Description;
                    FEDeprBook.Insert(true);
                    FEDeprBook.Validate("Depreciation Starting Date", CalcDate('<CM+1D>', DisposalDate));
                    FEDeprBook.Validate("Depreciation Ending Date", FATaxDeprBook."Depreciation Ending Date");
                    FEDeprBook.Modify();

                    if not DeprBookAccounting."G/L Integration - Acq. Cost" then begin
                        FEJnlSetup.FAJnlName(DeprBookAccounting, FEJnlLineTmp, JnlNextLineNo);
                        FEJnlLineTmp."FA No." := FE."No.";
                        FEJnlLineTmp."FA Posting Type" := FEJnlLineTmp."FA Posting Type"::"Acquisition Cost";
                        FEJnlLineTmp."FA Posting Date" := DisposalDate;
                        FEJnlLineTmp.Amount := GainLoss;
                        FEJnlLineTmp."Line No." := FEJnlLineTmp."Line No." + 1;
                        FEJnlLineTmp."Depreciation Book Code" := FEDeprBookAccounting."Depreciation Book Code";
                        FEJnlLineTmp.Description := FE.Description;
                        FEJnlLineTmp.Insert();
                    end else begin
                        FEJnlSetup.GenJnlName(DeprBookAccounting, GenJnlLine, JnlNextLineNo);
                        GenJnlLineTmp."Account No." := FE."No.";
                        GenJnlLineTmp."FA Posting Date" := DisposalDate;
                        GenJnlLineTmp."Posting Date" := DisposalDate;
                        GenJnlLineTmp."FA Posting Type" := GenJnlLineTmp."FA Posting Type"::"Acquisition Cost";
                        GenJnlLineTmp.Amount := GainLoss;
                        GenJnlLineTmp."Line No." := GenJnlLineTmp."Line No." + 1;
                        GenJnlLineTmp."Depreciation Book Code" := FEDeprBookAccounting."Depreciation Book Code";
                        GenJnlLineTmp.Insert();
                    end;

                    if not DeprBookTaxAccounting."G/L Integration - Acq. Cost" then begin
                        FEJnlSetup.FAJnlName(DeprBookTaxAccounting, FEJnlLineTmp, JnlNextLineNo);
                        FEJnlLineTmp."FA No." := FE."No.";
                        FEJnlLineTmp."FA Posting Type" := FEJnlLineTmp."FA Posting Type"::"Acquisition Cost";
                        FEJnlLineTmp."FA Posting Date" := DisposalDate;
                        FEJnlLineTmp.Amount := FATaxDeprBook."Gain/Loss";
                        FEJnlLineTmp."Line No." := FEJnlLineTmp."Line No." + 1;
                        FEJnlLineTmp."Depreciation Book Code" := FEDeprBookTaxAccounting."Depreciation Book Code";
                        FEJnlLineTmp.Description := FE.Description;
                        FEJnlLineTmp.Insert();
                    end else begin
                        FEJnlSetup.GenJnlName(DeprBookTaxAccounting, GenJnlLine, JnlNextLineNo);
                        GenJnlLineTmp."Account No." := FE."No.";
                        GenJnlLineTmp."FA Posting Date" := DisposalDate;
                        GenJnlLineTmp."Posting Date" := DisposalDate;
                        GenJnlLineTmp."FA Posting Type" := GenJnlLineTmp."FA Posting Type"::"Acquisition Cost";
                        GenJnlLineTmp.Amount := FATaxDeprBook."Gain/Loss";
                        GenJnlLineTmp."Line No." := GenJnlLineTmp."Line No." + 1;
                        GenJnlLineTmp."Depreciation Book Code" := FEDeprBookTaxAccounting."Depreciation Book Code";
                        GenJnlLineTmp.Description := FE.Description;
                        GenJnlLineTmp.Insert();
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                GainLoss := 0;
                DisposalDate := 0D;
                DepreciationEndingDate := 0D;

                FE.Reset();
                FE.SetCurrentKey("Created by FA No.");
                FE.SetRange("Created by FA No.", "No.");
                if FE.FindFirst() then
                    CurrReport.Skip();

                FATaxDeprBook.SetRange("FA No.", "No.");
                if FATaxDeprBook.FindSet() then
                    repeat
                        DeprBook.Get(FATaxDeprBook."Depreciation Book Code");
                    until (FATaxDeprBook.Next() = 0) or (DeprBook."Posting Book Type" = DeprBook."Posting Book Type"::"Tax Accounting");
                FATaxDeprBook.CalcFields("Gain/Loss");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(FETemplateNo; FETemplateNo)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FE Template';
                        TableRelation = "Fixed Asset" where("FA Type" = const("Future Expense"),
                                                             Blocked = const(true),
                                                             Inactive = const(true));

                        trigger OnValidate()
                        begin
                            FETemplateNoOnAfterValidate();
                        end;
                    }
                    field(NoSeriesCode; NoSeriesCode)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FE No. Series';
                        TableRelation = "No. Series";

                        trigger OnValidate()
                        begin
                            NoSeriesCodeOnAfterValidate();
                        end;
                    }
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Document No';
                        ToolTip = 'Specifies the number of the related document.';
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

    trigger OnPostReport()
    begin
        FEJnlLineTmp.Reset();
        if FEJnlLineTmp.Find('-') then begin
            FEJnlLine.LockTable();
            repeat
                if (FEJnlLineTmp."Journal Template Name" <> FEJnlLine."Journal Template Name") or
                   (FEJnlLineTmp."Journal Batch Name" <> FEJnlLine."Journal Batch Name")
                then begin
                    DeprBook.Get(FEJnlLineTmp."Depreciation Book Code");
                    FEJnlSetup.FAJnlName(DeprBook, FEJnlLine, JnlNextLineNo);
                    PostingNoSeries := FEJnlSetup.GetFANoSeries(FEJnlLine);
                    if DocumentNo = '' then
                        DocumentNo2 := FEJnlSetup.GetFAJnlDocumentNo(FEJnlLine, FEJnlLineTmp."FA Posting Date", true)
                    else
                        DocumentNo2 := DocumentNo;
                end;
                FEJnlLine.Init();
                FEJnlSetup.SetFAJnlTrailCodes(FEJnlLine);
                FEJnlLine."FA Posting Date" := FEJnlLineTmp."FA Posting Date";
                FEJnlLine."Posting Date" := 0D;
                FEJnlLine."FA Posting Type" := FEJnlLineTmp."FA Posting Type";
                FEJnlLine.Validate("FA No.", FEJnlLineTmp."FA No.");
                FEJnlLine."Document No." := DocumentNo2;
                FEJnlLine."Posting No. Series" := PostingNoSeries;
                FEJnlLine.Description := FEJnlLineTmp.Description;
                FEJnlLine.Validate("Depreciation Book Code", FEJnlLineTmp."Depreciation Book Code");
                FEJnlLine.Validate(Amount, FEJnlLineTmp.Amount);
                FEJnlLine."No. of Depreciation Days" := FEJnlLineTmp."No. of Depreciation Days";
                JnlNextLineNo := JnlNextLineNo + 10000;
                FEJnlLine."Line No." := JnlNextLineNo;
                FEJnlLine."Depr. Period Starting Date" := FEJnlLineTmp."Depr. Period Starting Date";
                FEJnlLine.Insert(true);
                FEJnlLineTmp.Delete();
            until FEJnlLineTmp.Next() = 0;
        end;
    end;

    trigger OnPreReport()
    begin
        FETemplate.Get(FETemplateNo);

        FEDeprBook.SetRange("FA No.", FETemplateNo);
        FEDeprBookAccounting.FindFirst();
        repeat
            FEDeprBookAccounting := FEDeprBook;
            if not DeprBookAccounting.Get(FEDeprBook."Depreciation Book Code") then
                DeprBookAccounting.Init();
        until (FEDeprBook.Next(1) = 0) or
              (DeprBookAccounting."Posting Book Type" = DeprBookAccounting."Posting Book Type"::Accounting);

        if DeprBookAccounting."Posting Book Type" = DeprBookAccounting."Posting Book Type"::Accounting then begin
            FEDeprBookAccounting.TestField("Depreciation Method", FEDeprBookAccounting."Depreciation Method"::"Straight-Line");
            FEJnlSetup.FAJnlName(DeprBookAccounting, FEJnlLineTmp, JnlNextLineNo);
            FEJnlTemplate.Get(FEJnlLineTmp."Journal Template Name");
            FEJnlTemplate.TestField(Type, FEJnlTemplate.Type::"Future Expenses");
        end else begin
            DeprBookAccounting."Posting Book Type" := DeprBookAccounting."Posting Book Type"::Accounting;
            Error(Text1001,
              FETemplateNo,
              DeprBookAccounting.TableCaption(),
              DeprBookAccounting.FieldCaption("Posting Book Type"),
              DeprBookAccounting."Posting Book Type");
        end;

        FEDeprBook.Find('-');
        repeat
            FEDeprBookTaxAccounting := FEDeprBook;
            if not DeprBookTaxAccounting.Get(FEDeprBook."Depreciation Book Code") then
                DeprBookTaxAccounting.Init();
        until (FEDeprBook.Next(1) = 0) or
              (DeprBookTaxAccounting."Posting Book Type" = DeprBookTaxAccounting."Posting Book Type"::"Tax Accounting");

        if DeprBookTaxAccounting."Posting Book Type" = DeprBookTaxAccounting."Posting Book Type"::"Tax Accounting" then begin
            FEDeprBookTaxAccounting.TestField("Depreciation Method", FEDeprBookTaxAccounting."Depreciation Method"::"Straight-Line");
            FEJnlSetup.FAJnlName(DeprBookTaxAccounting, FEJnlLineTmp, JnlNextLineNo);
            FEJnlTemplate.Get(FEJnlLineTmp."Journal Template Name");
            FEJnlTemplate.TestField(Type, FEJnlTemplate.Type::"Future Expenses");
        end else begin
            DeprBookTaxAccounting."Posting Book Type" := DeprBookTaxAccounting."Posting Book Type"::"Tax Accounting";
            Error(Text1001,
              FETemplateNo,
              DeprBookTaxAccounting.TableCaption(),
              DeprBookTaxAccounting.FieldCaption("Posting Book Type"),
              DeprBookTaxAccounting."Posting Book Type");
        end;
    end;

    var
        FE: Record "Fixed Asset";
        FETemplate: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        DeprBookAccounting: Record "Depreciation Book";
        DeprBookTaxAccounting: Record "Depreciation Book";
        FEDeprBook: Record "FA Depreciation Book";
        FEDeprBookAccounting: Record "FA Depreciation Book";
        FEDeprBookTaxAccounting: Record "FA Depreciation Book";
        FATaxDeprBook: Record "FA Depreciation Book";
        FEJnlSetup: Record "FA Journal Setup";
        FEJnlTemplate: Record "FA Journal Template";
        FEJnlLine: Record "FA Journal Line";
        FEJnlLineTmp: Record "FA Journal Line" temporary;
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLineTmp: Record "Gen. Journal Line" temporary;
        NoSeries: Record "No. Series";
        FETemplateNo: Code[20];
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        NoSeriesCode: Code[20];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1000: Label 'FA %1 was disposed with loss';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1001: Label '%2 with %3 %4 is not defined for FE %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PostingNoSeries: Code[20];
        JnlNextLineNo: Integer;
        GainLoss: Decimal;
        DisposalDate: Date;
        DepreciationEndingDate: Date;

    local procedure FETemplateNoOnAfterValidate()
    begin
        if not FETemplate.Get(FETemplateNo) then
            FETemplate.Init();
    end;

    local procedure NoSeriesCodeOnAfterValidate()
    begin
        if not NoSeries.Get(NoSeriesCode) then
            NoSeries.Init();
    end;
}

