#pragma warning disable AA0247
report 12423 "Calc. FA Inventory"
{
    Caption = 'Calc. FA Inventory';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            DataItemTableView = sorting("No.") where(Inactive = filter(false), Blocked = filter(false));
            RequestFilterFields = "FA Location Code", "Responsible Employee", "No.", "FA Type";

            trigger OnAfterGetRecord()
            var
                NumberOfMonths: Integer;
            begin
                Window.Update();

                FADepreciationBook.Reset();
                if FADepreciationBook.Get("No.", FADeprCode) then begin
                    FADepreciationBook.GetLocationAtDate("FA Location Code", "Responsible Employee", PostingDate);
                    if "FA Location Code" <> FALocation.Code then begin
                        if "FA Location Code" <> '' then
                            FALocation.Get("FA Location Code");
                        SetFAJournalBatch();
                    end;
                    FADepreciationBook.SetFilter("FA Posting Date Filter", '..%1', PostingDate);
                    if not ShowZeroBookValue then begin
                        FADepreciationBook.CalcFields("Book Value");
                        if FADepreciationBook."Book Value" = 0 then exit;
                    end;
                    FADepreciationBook.CalcFields("Acquisition Cost", Quantity);
                    FactAcquisitionCost := FADepreciationBook."Acquisition Cost";
                    FactQuantity := FADepreciationBook.Quantity;
                    if (FactAcquisitionCost > 0) and (FactQuantity = 0) then
                        FactQuantity := 1;

                    FADepreciationBook.SetFilter("FA Employee Filter", "Responsible Employee");
                    FADepreciationBook.SetFilter("FA Location Code Filter", FALocation.Code);
                    FADepreciationBook.CalcFields("Acquisition Cost", Quantity);
                    CalcAcquisitionCost := FADepreciationBook."Acquisition Cost";
                    CalcQuantity := FADepreciationBook.Quantity;
                    if (CalcAcquisitionCost > 0) and (CalcQuantity = 0) then
                        CalcQuantity := 1;

                    if (FactAcquisitionCost <> 0) or (CalcAcquisitionCost <> 0) then begin
                        LineNo := LineNo + 10000;
                        FAJournalLine.Init();
                        FAJournalLine."Journal Template Name" := FAJournalBatch."Journal Template Name";
                        FAJournalLine."Journal Batch Name" := FAJournalBatch.Name;
                        FAJournalLine."Line No." := LineNo;
                        FAJournalLine.Validate("FA No.", "No.");
                        FAJournalLine.Validate("Depreciation Book Code", FADeprCode);
                        FAJournalLine."FA Posting Date" := PostingDate;
                        FAJournalLine."Posting Date" := PostingDate;
                        FAJournalLine."Document Date" := DocumentDate;
                        FAJournalLine."Document No." := DocumentNo;
                        FAJournalLine.Validate(FAJournalLine."Location Code", FALocation.Code);
                        FAJournalLine.Validate(FAJournalLine."Employee No.", "Responsible Employee");
                        FAJournalLine."Calc. Quantity" := CalcQuantity;
                        FAJournalLine."Calc. Amount" := CalcAcquisitionCost;
                        FAJournalLine."Actual Quantity" := FactQuantity;
                        FAJournalLine."Actual Amount" := FactAcquisitionCost;
                        FAJournalLine."Phys. Inventory" := true;

                        if "FA Type" = "FA Type"::"Future Expense" then begin
                            FADepreciationBook.TestField("No. of Depreciation Months");
                            NumberOfMonths :=
                              Date2DMY(PostingDate, 2) - Date2DMY(FADepreciationBook."Acquisition Date", 2) +
                              (Date2DMY(PostingDate, 3) - Date2DMY(FADepreciationBook."Acquisition Date", 3)) * 12;
                            if NumberOfMonths = 0 then
                                NumberOfMonths := 1;
                            FAJournalLine."Actual  Remaining Amount" := Round(
                              FactAcquisitionCost - NumberOfMonths * FactAcquisitionCost / FADepreciationBook."No. of Depreciation Months", 0.01);
                            if FAJournalLine."Actual  Remaining Amount" < 0 then
                                FAJournalLine."Actual  Remaining Amount" := 0;
                        end;

                        FAJournalLine.Insert();
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                if PostingDate = 0D then
                    Error(Text002);

                if FATemp = '' then
                    Error(Text003);

                Window.Open(Text005, "No.");
                SetFAJournalBatch();
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
                    field(FATemp; FATemp)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'FA Journal Template';
                        TableRelation = "FA Journal Template";
                    }
                    field(FADeprCode; FADeprCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Depreciation Book Code';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the code for the depreciation book to be included in the report or batch job.';
                    }
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Document No.';
                    }
                    field(DocumentDate; DocumentDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the creation date of the related document.';
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date of the entries that you want to include in the report or batch job.';
                    }
                    field(ShowZeroBookValue; ShowZeroBookValue)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show FA with BookValue = 0 ';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PostingDate = 0D then
                PostingDate := WorkDate();
        end;
    }

    labels
    {
    }

    var
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        FALocation: Record "FA Location";
        FATemp: Code[20];
#pragma warning disable AA0074
        Text002: Label 'Please, enter posting date';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text003: Label 'Enter FA Journal Template.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label 'FA Processing #1##########';
#pragma warning restore AA0470
#pragma warning restore AA0074
        LineNo: Integer;
        PostingDate: Date;
        DocumentDate: Date;
        DocumentNo: Code[20];
        Window: Dialog;
        FactAcquisitionCost: Decimal;
        CalcAcquisitionCost: Decimal;
#pragma warning disable AA0074
        Text006: Label 'Phys. Inventory Journal ';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text007: Label 'DEFAULT';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text008: Label 'Phys. Inventory Journal DEFAULT';
#pragma warning restore AA0074
        FADepreciationBook: Record "FA Depreciation Book";
        FADeprCode: Code[20];
        FactQuantity: Integer;
        CalcQuantity: Integer;
        ShowZeroBookValue: Boolean;

    [Scope('OnPrem')]
    procedure SetFAJournalBatch()
    var
        BatchName: Code[10];
        BatchDescr: Text[50];
    begin
        FAJournalBatch.Reset();
        FAJournalBatch.SetRange("Journal Template Name", FATemp);
        if FALocation.Code <> '' then begin
            FAJournalBatch.SetRange(Name, FALocation.Code);
            BatchName := FALocation.Code;
            BatchDescr := Text006 + ' ' + FALocation.Code;
        end else begin
            FAJournalBatch.SetRange(Name, Text007);
            BatchName := Text007;
            BatchDescr := Text008;
        end;

        if not FAJournalBatch.Find('-') then begin
            FAJournalBatch.Init();
            FAJournalBatch."Journal Template Name" := FATemp;
            FAJournalBatch.Name := BatchName;
            FAJournalBatch.Validate(Description, BatchDescr);
            FAJournalBatch.Insert(true);
        end;

        FAJournalLine.Reset();
        FAJournalLine.SetRange("Journal Template Name", FAJournalBatch."Journal Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalBatch.Name);
        if FAJournalLine.Find('+') then
            LineNo := FAJournalLine."Line No."
        else
            LineNo := 0;
    end;
}

