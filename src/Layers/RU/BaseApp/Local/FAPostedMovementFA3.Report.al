#pragma warning disable AA0247
report 14989 "FA Posted Movement FA-3"
{
    Caption = 'FA Posted Movement FA-3';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Posted FA Doc. Header"; "Posted FA Doc. Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Movement));
            dataitem("Posted FA Doc. Line"; "Posted FA Doc. Line")
            {
                DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    FixedAsset.Get("FA No.");
                    TestField("Depreciation Book Code");
                    TestField("FA Posting Group");

                    if FASetup."FA Location Mandatory" then
                        TestField("FA Location Code");
                    if FASetup."Employee No. Mandatory" then
                        TestField("FA Employee No.");

                    ActualUse := LocMgt.GetPeriodDate(FixedAsset."Initial Release Date", "Posting Date", 2);
                    ConsNo := IncStr(ConsNo);

                    FA3Helper.FillLine(
                      ConsNo, Description, FixedAsset."Inventory Number", FixedAsset."Passport No.",
                      FixedAsset."Factory No.", Format(Amount), ActualUse);
                end;

                trigger OnPostDataItem()
                begin
                    FA3Helper.FillExpFooter();
                end;

                trigger OnPreDataItem()
                begin
                    FA3Helper.FillPageHeader();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FASetup.Get();

                GetFAComments(Conclusion, PostedFAComment.Type::Conclusion);
                GetFAComments(Appendix, PostedFAComment.Type::Appendix);

                CheckSignature(ReleasedBy, ReleasedBy."Employee Type"::ReleasedBy);
                CheckSignature(ReceivedBy, ReceivedBy."Employee Type"::ReceivedBy);
                CheckSignature(Chairman, Chairman."Employee Type"::Chairman);
                CheckSignature(Member1, Member1."Employee Type"::Member1);
                CheckSignature(Member2, Member2."Employee Type"::Member2);

                ConsNo := '0';

                FA3Helper.FillHeader(
                  FALocation.GetName("New FA Location Code"), FALocation.GetName("FA Location Code"),
                  "No.", Format("Posting Date"), DirectorPosition);
            end;

            trigger OnPostDataItem()
            begin
                FA3Helper.FillReportFooter(
                  Conclusion[1], Conclusion[2], Appendix,
                  Chairman."Employee Job Title", Chairman."Employee Name",
                  Member1."Employee Job Title", Member1."Employee Name",
                  Member2."Employee Job Title", Member2."Employee Name",
                  ReleasedBy."Employee Job Title", ReleasedBy."Employee Name",
                  ReceivedBy."Employee Job Title", ReceivedBy."Employee Name");
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
        if Employee.Get(CompanyInfo."Director No.") then
            DirectorPosition := Employee.GetJobTitleName();
    end;

    trigger OnPostReport()
    begin
        if FileName = '' then
            FA3Helper.ExportData()
        else
            FA3Helper.ExportDataFile(FileName);
    end;

    trigger OnPreReport()
    begin
        FA3Helper.InitReportTemplate();
    end;

    var
        FASetup: Record "FA Setup";
        CompanyInfo: Record "Company Information";
        FixedAsset: Record "Fixed Asset";
        FALocation: Record "FA Location";
        ReceivedBy: Record "Posted Document Signature";
        ReleasedBy: Record "Posted Document Signature";
        Chairman: Record "Posted Document Signature";
        Member1: Record "Posted Document Signature";
        Member2: Record "Posted Document Signature";
        PostedFAComment: Record "Posted FA Comment";
        LocMgt: Codeunit "Localisation Management";
        DocSignMgt: Codeunit "Doc. Signature Management";
        FA3Helper: Codeunit "FA-3 Report Helper";
        Appendix: array[5] of Text[80];
        Conclusion: array[5] of Text[80];
        ActualUse: Text[30];
        FileName: Text;
        ConsNo: Code[10];
        DirectorPosition: Text[80];

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    [Scope('OnPrem')]
    procedure CheckSignature(var PostedDocSign: Record "Posted Document Signature"; EmpType: Integer)
    begin
        DocSignMgt.GetPostedDocSign(
          PostedDocSign, DATABASE::"Posted FA Doc. Header",
          "Posted FA Doc. Header"."Document Type", "Posted FA Doc. Header"."No.", EmpType, false);
    end;
}

