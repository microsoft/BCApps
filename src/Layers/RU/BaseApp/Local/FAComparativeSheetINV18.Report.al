#pragma warning disable AA0247
report 12485 "FA Comparative Sheet INV-18"
{
    Caption = 'FA Comparative Sheet INV-18';
    ProcessingOnly = true;

    dataset
    {
        dataitem("FA Journal Line"; "FA Journal Line")
        {
            RequestFilterFields = "Location Code", "Employee No.";

            trigger OnAfterGetRecord()
            begin
                if "Calc. Quantity" = "Actual Quantity" then
                    CurrReport.Skip();

                QtyPlus := 0;
                QtyMinus := 0;
                AmountPlus := 0;
                AmountMinus := 0;
                if "Calc. Quantity" > "Actual Quantity" then begin
                    AmountMinus := "Calc. Amount" - "Actual Amount";
                    QtyMinus := "Calc. Quantity" - "Actual Quantity";
                end else begin
                    AmountPlus := "Actual Amount" - "Calc. Amount";
                    QtyPlus := "Actual Quantity" - "Calc. Quantity";
                end;

                FixedAsset.Get("FA No.");

                if not IsHeaderPrinted then begin
                    INV18Helper.FillHeader(
                      Employee."No.", Format(Reason), DocumentNo, Format(DocumentDate), Format("Document No."), Format(BeginDate),
                      Format(EndDate), Format(CreatDate), UntilDate, Member1, Member2);
                    INV18Helper.FillPageHeader();
                    IsHeaderPrinted := true;
                end;

                INV18Helper.FillLine(
                  Format(LineNo), Description, FixedAsset."Manufacturing Year", FixedAsset."Inventory Number", FixedAsset."Factory No.",
                  FixedAsset."Passport No.", QtyPlus, AmountPlus, QtyMinus, AmountMinus);
                LineNo += 1;
            end;

            trigger OnPostDataItem()
            begin
                INV18Helper.FillPageFooter();
                INV18Helper.FillFooter(StdRepMgt.GetEmpPosition(Employee."No."), StdRepMgt.GetEmpName(Employee."No."));
            end;

            trigger OnPreDataItem()
            begin
                LineNo := 1;
                CompanyInf.Get();

                if FALocation.Get(GetFilter("Location Code")) then;

                if not Employee.Get(GetFilter("Employee No.")) then
                    if Employee.Get(FALocation."Employee No.") then;
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
                    field(Reason; Reason)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Inventorization Reason';
                        OptionCaption = 'Order,Resolution,Direction';
                    }
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the related document.';
                    }
                    field(DocumentDate; DocumentDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the creation date of the related document.';
                    }
                    field(BeginDate; BeginDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(CreatDate; CreatDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Document Creation Date';
                        ToolTip = 'Specifies the creation date of the related document.';
                    }
                    field(UntilDate; UntilDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Status as of Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                    }
                    field(Member1; Member1)
                    {
                        ApplicationArea = FixedAssets;
                        TableRelation = Employee;
                    }
                    field(Member2; Member2)
                    {
                        ApplicationArea = FixedAssets;
                        TableRelation = Employee;
                    }
                    label(Control1470000)
                    {
                        ApplicationArea = FixedAssets;
                        CaptionClass = Text19021143;
                        ShowCaption = false;
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
        if FileName = '' then
            INV18Helper.ExportData()
        else
            INV18Helper.ExportDataFile(FileName);
    end;

    trigger OnPreReport()
    begin
        INV18Helper.InitReportTemplate();
    end;

    var
        CompanyInf: Record "Company Information";
        FALocation: Record "FA Location";
        Employee: Record Employee;
        StdRepMgt: Codeunit "Local Report Management";
        INV18Helper: Codeunit "INV-18 Report Helper";
        Reason: Option "order",resolution,direction;
        BeginDate: Date;
        EndDate: Date;
        DocumentNo: Code[10];
        DocumentDate: Date;
        LineNo: Integer;
        CreatDate: Date;
        QtyPlus: Decimal;
        QtyMinus: Decimal;
        AmountPlus: Decimal;
        AmountMinus: Decimal;
        UntilDate: Date;
        FixedAsset: Record "Fixed Asset";
        Member1: Code[20];
        Member2: Code[20];
#pragma warning disable AA0074
        Text19021143: Label 'Commission Members';
#pragma warning restore AA0074
        FileName: Text;
        IsHeaderPrinted: Boolean;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

