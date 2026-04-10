#pragma warning disable AA0247
report 14977 "Transfer Receipt TORG-13"
{
    Caption = 'Transfer Receipt TORG-13';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Transfer Receipt Header"; "Transfer Receipt Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            dataitem("Transfer Receipt Line"; "Transfer Receipt Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document No.", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    Item.Get("Item No.");
                    GrossWeight := Quantity * Item."Gross Weight";
                    NetWeight := Quantity * Item."Net Weight";
                    TotalCost := Quantity * Item."Unit Cost";

                    TransferLineValues();
                end;

                trigger OnPostDataItem()
                begin
                    TransferFooterValues();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CheckSignature(ReleasedBy, ReleasedBy."Employee Type"::ReleasedBy);
                CheckSignature(ReceivedBy, ReceivedBy."Employee Type"::ReceivedBy);

                TORG13Helper.FillHeader("No.", Format("Posting Date"),
                  ReleasedBy."Employee Org. Unit", ReceivedBy."Employee Org. Unit");
                TORG13Helper.FillPageHeader();
            end;
        }
    }

    requestpage
    {

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
        OnBeforeExport(FileName);

        if FileName = '' then
            TORG13Helper.ExportData()
        else
            TORG13Helper.ExportDataToClientFile(FileName);
    end;

    trigger OnPreReport()
    begin
        TORG13Helper.InitReportTemplate();
    end;

    var
        Item: Record Item;
        ReleasedBy: Record "Posted Document Signature";
        ReceivedBy: Record "Posted Document Signature";
        DocSignMgt: Codeunit "Doc. Signature Management";
        TORG13Helper: Codeunit "TORG-13 Report Helper";
        StdRepMgt: Codeunit "Local Report Management";
        GrossWeight: Decimal;
        NetWeight: Decimal;
        TotalCost: Decimal;
        FileName: Text;

    [Scope('OnPrem')]
    procedure CheckSignature(var PostedDocSign: Record "Posted Document Signature"; EmpType: Integer)
    begin
        DocSignMgt.GetPostedDocSign(
          PostedDocSign, DATABASE::"Transfer Receipt Header",
          0, "Transfer Receipt Header"."No.", EmpType, false);
    end;

    [Scope('OnPrem')]
    procedure TransferLineValues()
    var
        BodyDetails: array[6] of Text;
        AmountValues: array[4] of Decimal;
    begin
        AmountValues[1] := TotalCost;
        AmountValues[2] := "Transfer Receipt Line".Quantity;
        AmountValues[3] := GrossWeight;
        AmountValues[4] := NetWeight;

        BodyDetails[1] := "Transfer Receipt Line".Description;
        BodyDetails[2] := "Transfer Receipt Line"."Item No.";
        BodyDetails[3] := StdRepMgt.GetUoMDesc("Transfer Receipt Line"."Unit of Measure Code");
        BodyDetails[4] := "Transfer Receipt Line"."Unit of Measure Code";
        BodyDetails[5] := Format(Item."Units per Parcel");
        BodyDetails[6] := Format(Item."Unit Cost");

        TORG13Helper.FillLine(BodyDetails, AmountValues);
    end;

    [Scope('OnPrem')]
    procedure TransferFooterValues()
    var
        FooterDetails: array[4] of Text;
    begin
        FooterDetails[1] := ReleasedBy."Employee Job Title";
        FooterDetails[2] := ReleasedBy."Employee Name";
        FooterDetails[3] := ReceivedBy."Employee Job Title";
        FooterDetails[4] := ReceivedBy."Employee Name";

        TORG13Helper.FillFooter(FooterDetails);
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExport(var FileName: Text)
    begin
    end;
}

