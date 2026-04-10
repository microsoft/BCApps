#pragma warning disable AA0247
report 14980 "Purch. FA Receipt FA-14"
{
    Caption = 'Purch. FA Receipt FA-14';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = filter(Order | Invoice));
            RequestFilterFields = "No.";
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Expected Receipt Date") where(Type = const("Fixed Asset"));

                trigger OnAfterGetRecord()
                begin
                    FA14Helper.FillReportBody("Purchase Line");
                end;

                trigger OnPreDataItem()
                begin
                    FA14Helper.AddPageHeader();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FirstPurchLine.SetRange("Document Type", "Document Type");
                FirstPurchLine.SetRange("Document No.", "No.");
                FirstPurchLine.SetRange(Type, FirstPurchLine.Type::"Fixed Asset");
                if not FirstPurchLine.FindFirst() then
                    CurrReport.Break();

                FA14Helper.FillReportUnpostedHeader("Purchase Header", FirstPurchLine);
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
        FirstPurchLine: Record "Purchase Line";
        FA14Helper: Codeunit "FA-14 Helper";
        FileName: Text;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

