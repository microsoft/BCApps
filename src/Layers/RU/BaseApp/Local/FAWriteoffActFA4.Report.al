#pragma warning disable AA0247
report 12493 "FA Write-off Act FA-4"
{
    Caption = 'FA Write-off Act FA-4';
    ProcessingOnly = true;

    dataset
    {
        dataitem("FA Document Header"; "FA Document Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Writeoff));
            RequestFilterFields = "No.";
            dataitem("FA Document Line"; "FA Document Line")
            {
                DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.");
                RequestFilterFields = "Line No.";
                dataitem("Part 2"; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 1;
                    dataitem("Main Asset Component"; "Main Asset Component")
                    {
                        DataItemLink = "Main Asset No." = field("FA No.");
                        DataItemLinkReference = "FA Document Line";
                        DataItemTableView = sorting("Main Asset No.", "FA No.");

                        trigger OnAfterGetRecord()
                        begin
                            FA4Helper.FillAssetLine(
                              Description, StdRepMgt.FormatReportValue(Quantity, 2), '', '', '', '', '');
                        end;

                        trigger OnPreDataItem()
                        begin
                            FA4Helper.FillAssetHeader();
                        end;
                    }
                    dataitem("Item/FA Precious Metal"; "Item/FA Precious Metal")
                    {
                        DataItemLink = "No." = field("FA No.");
                        DataItemLinkReference = "FA Document Line";
                        DataItemTableView = sorting("Item Type", "No.", "Precious Metals Code");

                        trigger OnAfterGetRecord()
                        begin
                            FA4Helper.FillAssetLine(
                              '', '', Name, "Precious Metals Code", StdRepMgt.GetUoMDesc("Unit of Measure Code"),
                              StdRepMgt.FormatReportValue(Quantity, 2), StdRepMgt.FormatReportValue(Mass, 2));
                        end;
                    }

                    trigger OnPostDataItem()
                    begin
                        FA4Helper.FillAssetPageFooter();
                    end;

                    trigger OnPreDataItem()
                    begin
                        FA4Helper.SetAssetSheet();
                    end;
                }
                dataitem("Part 3"; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 1;
                    dataitem("Invt. Document Line"; "Invt. Document Line")
                    {
                        DataItemLink = "Document No." = field("Item Receipt No.");
                        DataItemLinkReference = "FA Document Line";
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.") where("Document Type" = const(Receipt));

                        trigger OnAfterGetRecord()
                        begin
                            FA4Helper.FillConclusionLine(
                              "Document No.", Description, "Item No.", "Unit of Measure Code",
                              StdRepMgt.FormatReportValue(Quantity, 2), StdRepMgt.FormatReportValue("Unit Amount", 2), Amount);
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("Document No.", "FA Document Line"."Item Receipt No.");
                        end;
                    }

                    trigger OnPostDataItem()
                    begin
                        FA4Helper.FillConclusionPageFooter();
                    end;

                    trigger OnPreDataItem()
                    begin
                        FA4Helper.FillConclusionHeader(
                          Conclusion[1], Conclusion[2], Appendix[1], Appendix[2],
                          Chairman."Employee Job Title", Chairman."Employee Name",
                          Member1."Employee Job Title", Member1."Employee Name",
                          Member2."Employee Job Title", Member2."Employee Name");
                    end;
                }
                dataitem(Footer; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 1;

                    trigger OnPreDataItem()
                    begin
                        FA4Helper.FillReportFooter(Result[1]);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    FA.Get("FA No.");
                    FADepreciationBook.Get("FA No.", "Depreciation Book Code");
                    FADepreciationBook.CalcFields("Acquisition Cost", Depreciation, "Book Value");

                    if FASetup."FA Location Mandatory" then
                        TestField("FA Location Code");
                    if FASetup."Employee No. Mandatory" then
                        TestField("FA Employee No.");

                    FactYears := LocMgt.GetPeriodDate(FA."Initial Release Date", "FA Document Header"."Posting Date", 2);

                    GetFAComments(Reason, FAComment.Type::Reason);
                    GetFAComments(Conclusion, FAComment.Type::Conclusion);
                    GetFAComments(Appendix, FAComment.Type::Appendix);
                    GetFAComments(Result, FAComment.Type::Result);

                    FA4Helper.SetDocSheet();
                    if not IsHeaderPrinted then begin
                        FA4Helper.FillHeader(
                          StdRepMgt.GetEmpDepartment("FA Employee No."), StdRepMgt.GetEmpName("FA Employee No."),
                          Reason[1], Format("FA Document Header"."FA Posting Date"), "FA Document Header"."Reason Document No.",
                          Format("FA Document Header"."Reason Document Date"), "FA Employee No.",
                          DirectorPosition, "FA Document Header"."No.", Format("FA Document Header"."Posting Date"),
                          "FA Document Header"."Posting Description");
                        FA4Helper.FillStatePageHeader();
                        IsHeaderPrinted := true;
                    end;

                    FA4Helper.FillStateLine(
                      Description, FA."Inventory Number", FA."Factory No.", FA."Manufacturing Year", Format(FA."Initial Release Date"),
                      FactYears, StdRepMgt.FormatReportValue(FADepreciationBook."Acquisition Cost", 2),
                      StdRepMgt.FormatReportValue(Abs(FADepreciationBook.Depreciation), 2),
                      StdRepMgt.FormatReportValue(FADepreciationBook."Book Value", 2));
                end;

                trigger OnPreDataItem()
                begin
                    IsHeaderPrinted := false;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FASetup.Get();

                CheckSignature(Chairman, Chairman."Employee Type"::Chairman);
                CheckSignature(Member1, Member1."Employee Type"::Member1);
                CheckSignature(Member2, Member2."Employee Type"::Member2);
            end;

            trigger OnPostDataItem()
            begin
                FA4Helper.SetDocSheet();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        Employee: Record Employee;
    begin
        CompanyInfo.Get();
        FASetup.Get();
        if Employee.Get(CompanyInfo."Director No.") then
            DirectorPosition := Employee.GetJobTitleName();
    end;

    trigger OnPostReport()
    begin
        if FileName = '' then
            FA4Helper.ExportData()
        else
            FA4Helper.ExportDataFile(FileName);
    end;

    trigger OnPreReport()
    begin
        FA4Helper.InitReportTemplate(REPORT::"FA Write-off Act FA-4");
    end;

    var
        CompanyInfo: Record "Company Information";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FA: Record "Fixed Asset";
        FAComment: Record "FA Comment";
        Chairman: Record "Document Signature";
        Member1: Record "Document Signature";
        Member2: Record "Document Signature";
        LocMgt: Codeunit "Localisation Management";
        DocSignMgt: Codeunit "Doc. Signature Management";
        StdRepMgt: Codeunit "Local Report Management";
        FA4Helper: Codeunit "FA-4 Report Helper";
        Reason: array[5] of Text[80];
        Conclusion: array[5] of Text[80];
        Appendix: array[5] of Text[80];
        Result: array[5] of Text[80];
        FactYears: Text[30];
        DirectorPosition: Text[80];
        FileName: Text;
        IsHeaderPrinted: Boolean;

    [Scope('OnPrem')]
    procedure CheckSignature(var DocSign: Record "Document Signature"; EmpType: Integer)
    begin
        DocSignMgt.GetDocSign(
          DocSign, DATABASE::"FA Document Header",
          "FA Document Header"."Document Type", "FA Document Header"."No.", EmpType, true);
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

