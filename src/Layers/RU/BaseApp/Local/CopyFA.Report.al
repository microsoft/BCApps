#pragma warning disable AA0247
report 12487 "Copy FA"
{
    Caption = 'Copy FA';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {

            trigger OnAfterGetRecord()
            begin
                if not Confirm(Text001, false, CountCopy, "No.") then
                    CurrReport.Break();

                for i := 1 to CountCopy do begin
                    FA := "Fixed Asset";
                    FA."No." := '';
                    FA."FA Location Code" := '';
                    FA."Responsible Employee" := '';
                    FA."Last Date Modified" := 0D;
                    FA.Blocked := false;
                    FA.Inactive := false;
                    FA.Status := 0;
                    FA."Initial Release Date" := 0D;
                    FA."Status Document No." := '';
                    FA.Insured := false;
                    FA.Insert(true);

                    FABook2.Reset();
                    FABook2.SetRange("FA No.", FA."No.");
                    if FABook2.Find('-') then
                        FABook2.DeleteAll();

                    FABook.Reset();
                    FABook.SetRange("FA No.", "Fixed Asset"."No.");
                    if FABook.Find('-') then
                        repeat
                            FABook2."FA No." := FA."No.";
                            FABook2."Depreciation Book Code" := FABook."Depreciation Book Code";
                            FABook2."Depreciation Method" := FABook."Depreciation Method";
                            FABook2."Depreciation Starting Date" := 0D;
                            FABook2."Depreciation Ending Date" := 0D;
                            FABook2."Straight-Line %" := FABook2."Straight-Line %";
                            FABook2."No. of Depreciation Years" := FABook."No. of Depreciation Years";
                            FABook2."No. of Depreciation Months" := FABook."No. of Depreciation Months";
                            FABook2."Fixed Depr. Amount" := FABook."Fixed Depr. Amount";
                            FABook2."Declining-Balance %" := FABook."Declining-Balance %";
                            FABook2."Depreciation Table Code" := FABook."Depreciation Table Code";
                            FABook2."Final Rounding Amount" := FABook."Final Rounding Amount";
                            FABook2."Ending Book Value" := FABook."Ending Book Value";
                            FABook2."FA Posting Group" := FABook."FA Posting Group";
                            FABook2.Description := FABook.Description;
                            FABook2."Initial Acquisition" := false;
                            FABook2.Insert();
                        until FABook.Next() = 0;
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CountCopy; CountCopy)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Count Copy';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            CountCopy := 1;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Message(Text002, CountCopy);
    end;

    var
        FA: Record "Fixed Asset";
        FABook: Record "FA Depreciation Book";
        FABook2: Record "FA Depreciation Book";
        CountCopy: Integer;
        i: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Do you want to create %1 copies of fixed asset %2?';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'The operation finished successfully, created %1 copies.';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

