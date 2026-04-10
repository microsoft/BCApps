#pragma warning disable AA0247
report 14990 "FA Writeoff Act FA-4a"
{
    Caption = 'FA Writeoff Act FA-4a';
    ProcessingOnly = true;

    dataset
    {
        dataitem("FA Document Header"; "FA Document Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Writeoff));
            dataitem("Part 3"; "FA Document Line")
            {
                DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.");
                dataitem("Item/FA Precious Metal"; "Item/FA Precious Metal")
                {
                    DataItemLink = "No." = field("FA No.");
                    DataItemLinkReference = "Part 3";
                    DataItemTableView = sorting("Item Type");

                    trigger OnAfterGetRecord()
                    begin
                        FA4Helper.FillAssetLine2(
                          '', '', '', '', '',
                          Name, "Precious Metals Code", StdRepMgt.GetUoMDesc("Unit of Measure Code"),
                          StdRepMgt.FormatReportValue(Quantity, 2), StdRepMgt.FormatReportValue(Mass, 2));
                    end;

                    trigger OnPostDataItem()
                    begin
                        FA4Helper.FillAssetFooter(
                          Characteristics, Conclusion, Appendix[1], Appendix[2],
                          Chairman."Employee Job Title", Chairman."Employee Name",
                          Member1."Employee Job Title", Member1."Employee Name",
                          Member2."Employee Job Title", Member2."Employee Name");
                    end;
                }
                dataitem("Part 4"; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    dataitem("Invt. Document Line"; "Invt. Document Line")
                    {
                        DataItemLink = "Document No." = field("Item Receipt No.");
                        DataItemLinkReference = "Part 3";
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.") where("Document Type" = const(Receipt));

                        trigger OnAfterGetRecord()
                        begin
                            ConsNo := IncStr(ConsNo);

                            FA4Helper.FillExpLine(
                              ConsNo, "Item No.", Description, "Unit of Measure Code",
                              StdRepMgt.FormatReportValue(Quantity, 2), StdRepMgt.FormatReportValue("Unit Amount", 2),
                              StdRepMgt.FormatReportValue(Amount, 2));
                        end;

                        trigger OnPreDataItem()
                        begin
                            ConsNo := '0';
                        end;
                    }

                    trigger OnPostDataItem()
                    begin
                        FA4Helper.FillExpFooter();
                    end;

                    trigger OnPreDataItem()
                    begin
                        FA4Helper.SetExpSheet();
                        FA4Helper.FillExpHeader();
                    end;
                }
                dataitem("Part 5"; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
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
                    FA.TestField("Vehicle Model");

                    if FASetup."FA Location Mandatory" then
                        TestField("FA Location Code");
                    if FASetup."Employee No. Mandatory" then
                        TestField("FA Employee No.");

                    FADepreciationBook.Get("FA No.", "Depreciation Book Code");
                    FADepreciationBook.CalcFields("Initial Acquisition Cost", Depreciation, "Book Value");
                    FAPostingGroup.Get("FA Posting Group");

                    GetFAComments(Reason, FAComment.Type::Reason);
                    GetFAComments(Conclusion, FAComment.Type::Conclusion);
                    GetFAComments(Appendix, FAComment.Type::Appendix);
                    GetFAComments(Result, FAComment.Type::Result);
                    GetFAComments(Characteristics, FAComment.Type::Characteristics);

                    FA4Helper.SetDocSheet();
                    if not IsHeaderPrinted then begin
                        FA4Helper.FillHeader2(
                          StdRepMgt.GetEmpDepartment("FA Employee No."),
                          Format("FA Document Header"."FA Posting Date"), FAPostingGroup."Acquisition Cost Account",
                          DirectorPosition, "FA Document Header"."No.", Format("FA Document Header"."Posting Date"),
                          FA."Factory No.", FA."Vehicle Reg. No.", FA."Inventory Number",
                          Description + ', ' + FA."Vehicle Model" + ', ' + FA."Vehicle Type",
                          "FA Document Header"."Posting Description", StdRepMgt.GetEmpPosition("FA Employee No."),
                          StdRepMgt.GetEmpName("FA Employee No."), "FA Employee No.");
                        FA4Helper.FillStatePageHeader();
                        IsHeaderPrinted := true;
                    end;

                    FA4Helper.FillStateLine2(
                      FA."Manufacturing Year", Format(FADepreciationBook."Acquisition Date", 0, '<Month,2>.<Year4>'),
                      Format(FADepreciationBook."G/L Acquisition Date"), Format(FA."Is Vehicle"),
                      Format(FA."Vehicle Writeoff Date"), Format(FA."Run after Release Date"), Format(FA."Run after Renovation Date"),
                      StdRepMgt.FormatReportValue(Abs(FADepreciationBook."Initial Acquisition Cost"), 2),
                      StdRepMgt.FormatReportValue(Abs(FADepreciationBook.Depreciation), 2),
                      StdRepMgt.FormatReportValue(FADepreciationBook."Book Value", 2));

                    FA4Helper.SetAssetSheet();
                    FA4Helper.FillAssetHeader();
                    FA4Helper.FillAssetLine2(
                      FA."Vehicle Reg. No.", FA."Vehicle Engine No.", FA."Vehicle Chassis No.",
                      StdRepMgt.FormatReportValue(FA."Vehicle Capacity", 2), StdRepMgt.FormatReportValue(FA."Vehicle Passport Weight", 2),
                      '', '', '', '', '');
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
        FA4Helper.InitReportTemplate(REPORT::"FA Writeoff Act FA-4a");
    end;

    var
        CompanyInfo: Record "Company Information";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FA: Record "Fixed Asset";
        FAComment: Record "FA Comment";
        Chairman: Record "Document Signature";
        Member1: Record "Document Signature";
        Member2: Record "Document Signature";
        DocSignMgt: Codeunit "Doc. Signature Management";
        StdRepMgt: Codeunit "Local Report Management";
        FA4Helper: Codeunit "FA-4 Report Helper";
        IsHeaderPrinted: Boolean;
        Characteristics: array[5] of Text[80];
        Reason: array[5] of Text[80];
        Conclusion: array[5] of Text[80];
        Appendix: array[5] of Text[80];
        Result: array[5] of Text[80];
        ConsNo: Code[10];
        FileName: Text;
        DirectorPosition: Text[80];

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    [Scope('OnPrem')]
    procedure CheckSignature(var DocSign: Record "Document Signature"; EmpType: Integer)
    begin
        DocSignMgt.GetDocSign(
          DocSign, DATABASE::"FA Document Header",
          "FA Document Header"."Document Type", "FA Document Header"."No.", EmpType, true);
    end;
}

