#pragma warning disable AA0247
report 14986 "FA Movement FA-2"
{
    Caption = 'FA Movement FA-2';
    ProcessingOnly = true;

    dataset
    {
        dataitem("FA Document Header"; "FA Document Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Movement));
            dataitem("FA Document Line"; "FA Document Line")
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
                    FA2ReportHelper.FillBody("FA Document Line", LineNo);
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
                GetFAComments(Appendix, FAComment.Type::Appendix);
                CheckSignature(ReleasedBy, ReleasedBy."Employee Type"::ReleasedBy);
                CheckSignature(ReceivedBy, ReceivedBy."Employee Type"::ReceivedBy);

                FA2ReportHelper.FillHeader("FA Document Header");
            end;

            trigger OnPostDataItem()
            begin
                FA2ReportHelper.FillFooter(ReleasedBy, ReceivedBy, Appendix);
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
        ReceivedBy: Record "Document Signature";
        ReleasedBy: Record "Document Signature";
        FAComment: Record "FA Comment";
        DocSignMgt: Codeunit "Doc. Signature Management";
        FA2ReportHelper: Codeunit "FA-2 Report Helper";
        Appendix: array[5] of Text[80];
        FileName: Text;
        LineNo: Integer;

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

