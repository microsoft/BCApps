#pragma warning disable AA0247
report 14993 "Posted FA Movement FA-15"
{
    Caption = 'Posted FA Movement FA-15';
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
                    FixetAsset.Get("FA No.");
                    TestField("Depreciation Book Code");
                    TestField("FA Posting Group");

                    if FASetup."FA Location Mandatory" then
                        TestField("FA Location Code");
                    if FASetup."Employee No. Mandatory" then
                        TestField("FA Employee No.");

                    FA15ReportHelper.FillBody(
                      Description, FixetAsset."Factory No.", FixetAsset."Passport No.", Format("FA Posting Date"),
                      StdRepMgt.FormatReportValue(Quantity, 2), StdRepMgt.FormatReportValue("Book Value", 2), StdRepMgt.FormatReportValue(Amount, 2));
                end;

                trigger OnPostDataItem()
                begin
                    FA15ReportHelper.FillLastHeader(Result, Complect, Defect, Conclusion);
                    FA15ReportHelper.FillLastFooter(
                      ReleasedBy."Employee Job Title", ReleasedBy."Employee Name",
                      ReceivedBy."Employee Job Title", ReceivedBy."Employee Name",
                      StoredBy."Employee Job Title", StoredBy."Employee Name");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FASetup.Get();

                GetFAComments(Complect, PostedFAComment.Type::Complect);
                GetFAComments(Defect, PostedFAComment.Type::Defect);
                GetFAComments(Result, PostedFAComment.Type::Result);
                GetFAComments(Reason, PostedFAComment.Type::Reason);
                GetFAComments(Conclusion, PostedFAComment.Type::Conclusion);

                CheckSignature(ReleasedBy, ReleasedBy."Employee Type"::ReleasedBy);
                CheckSignature(ReceivedBy, ReceivedBy."Employee Type"::ReceivedBy);
                CheckSignature(StoredBy, StoredBy."Employee Type"::StoredBy);

                FA15ReportHelper.FillHeader(
                  FALocation.GetName("FA Location Code"), Reason[1], "Reason Document No.", Format("Reason Document Date"),
                  "No.", Format("Posting Date"), FALocation.GetName("New FA Location Code"));
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

    trigger OnPostReport()
    begin
        if FileName <> '' then
            FA15ReportHelper.ExportDataFile(FileName)
        else
            FA15ReportHelper.ExportData();
    end;

    trigger OnPreReport()
    begin
        FA15ReportHelper.InitReportTemplate();
    end;

    var
        FASetup: Record "FA Setup";
        FixetAsset: Record "Fixed Asset";
        ReceivedBy: Record "Posted Document Signature";
        ReleasedBy: Record "Posted Document Signature";
        StoredBy: Record "Posted Document Signature";
        PostedFAComment: Record "Posted FA Comment";
        FALocation: Record "FA Location";
        DocSignMgt: Codeunit "Doc. Signature Management";
        StdRepMgt: Codeunit "Local Report Management";
        FA15ReportHelper: Codeunit "FA-15 Report Helper";
        Result: array[5] of Text[80];
        Conclusion: array[5] of Text[80];
        Defect: array[5] of Text[80];
        Reason: array[5] of Text[80];
        Complect: array[5] of Text[80];
        FileName: Text;

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

