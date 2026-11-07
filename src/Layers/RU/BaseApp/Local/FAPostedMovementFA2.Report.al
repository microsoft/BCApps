#pragma warning disable AA0247
report 14987 "FA Posted Movement FA-2"
{
    Caption = 'FA Posted Movement FA-2';
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
                    if FASetup."FA Location Mandatory" then
                        TestField("FA Location Code");
                    if FASetup."Employee No. Mandatory" then
                        TestField("FA Employee No.");

                    LineNo += 1;
                    FA2ReportHelper.FillBodyFromPostedDoc("Posted FA Doc. Line", LineNo);
                end;

                trigger OnPostDataItem()
                begin
                    FA2ReportHelper.FillPageFooter();
                end;

                trigger OnPreDataItem()
                begin
                    FA2ReportHelper.FillPageHeader();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FASetup.Get();
                GetFAComments(Appendix, PostedFAComment.Type::Appendix);
                CheckSignature(ReleasedBy, ReleasedBy."Employee Type"::ReleasedBy);
                CheckSignature(ReceivedBy, ReceivedBy."Employee Type"::ReceivedBy);

                FA2ReportHelper.FillHeaderFromPostedDoc("Posted FA Doc. Header");
            end;

            trigger OnPostDataItem()
            begin
                FA2ReportHelper.FillFooterFromPostedDoc(ReleasedBy, ReceivedBy, Appendix);
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
    begin
        FA2ReportHelper.InitReportTemplate();
    end;

    trigger OnPostReport()
    begin
        if FileName = '' then
            FA2ReportHelper.ExportData()
        else
            FA2ReportHelper.ExportDataFile(FileName);
    end;

    var
        FASetup: Record "FA Setup";
        ReceivedBy: Record "Posted Document Signature";
        ReleasedBy: Record "Posted Document Signature";
        PostedFAComment: Record "Posted FA Comment";
        DocSignMgt: Codeunit "Doc. Signature Management";
        FA2ReportHelper: Codeunit "FA-2 Report Helper";
        FileName: Text;
        Appendix: array[5] of Text[80];
        LineNo: Integer;

    [Scope('OnPrem')]
    procedure CheckSignature(var PostedDocSign: Record "Posted Document Signature"; EmpType: Integer)
    begin
        DocSignMgt.GetPostedDocSign(
          PostedDocSign, DATABASE::"Posted FA Doc. Header",
          "Posted FA Doc. Header"."Document Type", "Posted FA Doc. Header"."No.", EmpType, false);
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

