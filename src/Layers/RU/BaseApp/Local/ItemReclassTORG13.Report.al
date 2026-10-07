#pragma warning disable AA0247
report 12477 "Item Reclass. TORG-13"
{
    Caption = 'Item Reclass. TORG-13';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Item Journal Line"; "Item Journal Line")
        {

            trigger OnAfterGetRecord()
            begin
                if not HeaderPrinted then begin
                    TORG13Helper.FillHeader(
                      "No.", Format("Posting Date"),
                      StdRepMgt.GetEmpDepartment(ReleasedBy),
                      StdRepMgt.GetEmpDepartment(ReceivedBy));
                    TORG13Helper.FillPageHeader();
                    HeaderPrinted := true;
                end;

                Item.Get("Item No.");
                GrossWeight := Quantity * Item."Gross Weight";
                NetWeight := Quantity * Item."Net Weight";
                TotalCost := Quantity * Item."Unit Cost";

                TransferLineValues();
            end;

            trigger OnPostDataItem()
            var
                FooterDetails: array[4] of Text;
            begin
                FooterDetails[1] := StdRepMgt.GetEmpDepartment(ReleasedBy);
                FooterDetails[2] := StdRepMgt.GetEmpName(ReleasedBy);
                FooterDetails[3] := StdRepMgt.GetEmpDepartment(ReceivedBy);
                FooterDetails[4] := StdRepMgt.GetEmpName(ReceivedBy);

                TORG13Helper.FillFooter(FooterDetails);
            end;

            trigger OnPreDataItem()
            begin
                HeaderPrinted := false;
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
                    field(ReleasedBy; ReleasedBy)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Supplier (employee)';
                        TableRelation = Employee;
                        ToolTip = 'Specifies the name of the employee who released the item.';
                    }
                    field(ReceivedBy; ReceivedBy)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Receiver (employee)';
                        TableRelation = Employee;
                        ToolTip = 'Specifies the name of the employee who received the item.';
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
        StdRepMgt: Codeunit "Local Report Management";
        TORG13Helper: Codeunit "TORG-13 Report Helper";
        GrossWeight: Decimal;
        NetWeight: Decimal;
        TotalCost: Decimal;
        ReleasedBy: Code[10];
        ReceivedBy: Code[10];
        FileName: Text;
        HeaderPrinted: Boolean;

    [Scope('OnPrem')]
    procedure TransferLineValues()
    var
        AmountValues: array[4] of Decimal;
        BodyDetails: array[6] of Text;
    begin
        AmountValues[1] := TotalCost;
        AmountValues[2] := "Item Journal Line".Quantity;
        AmountValues[3] := GrossWeight;
        AmountValues[4] := NetWeight;

        BodyDetails[1] := "Item Journal Line".Description;
        BodyDetails[2] := "Item Journal Line"."Item No.";
        BodyDetails[3] := StdRepMgt.GetUoMDesc("Item Journal Line"."Unit of Measure Code");
        BodyDetails[4] := "Item Journal Line"."Unit of Measure Code";
        BodyDetails[5] := Format(Item."Units per Parcel");
        BodyDetails[6] := Format(Item."Unit Cost");

        TORG13Helper.FillLine(BodyDetails, AmountValues);
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

