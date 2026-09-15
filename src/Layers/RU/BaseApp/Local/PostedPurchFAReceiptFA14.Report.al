#pragma warning disable AA0247
report 14981 "Posted Purch. FA Receipt FA-14"
{
    Caption = 'Posted Purch. FA Receipt FA-14';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Purch. Inv. Header"; "Purch. Inv. Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            dataitem("Purch. Inv. Line"; "Purch. Inv. Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document No.", "Line No.") where(Type = const("Fixed Asset"));

                trigger OnAfterGetRecord()
                begin
                    FA14Helper.FillPostedReportBody("Purch. Inv. Line");
                end;

                trigger OnPreDataItem()
                begin
                    FA14Helper.AddPageHeader();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FirstPurchLine.SetRange("Document No.", "No.");
                FirstPurchLine.SetRange(Type, FirstPurchLine.Type::"Fixed Asset");
                if not FirstPurchLine.FindFirst() then
                    CurrReport.Break();

                FA14Helper.FillReportPostedHeader("Purch. Inv. Header", FirstPurchLine);
            end;

            trigger OnPostDataItem()
            begin
                FA14Helper.FillReportFooter();
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
        FA14Helper.InitReportTemplate();
    end;

    trigger OnPostReport()
    begin
        FA14Helper.ExportData(FileName);
    end;

    var
        FirstPurchLine: Record "Purch. Inv. Line";
        FA14Helper: Codeunit "FA-14 Helper";
        FileName: Text;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

