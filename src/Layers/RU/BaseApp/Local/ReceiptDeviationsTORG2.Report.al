#pragma warning disable AA0247
report 14925 "Receipt Deviations TORG-2"
{
    Caption = 'Receipt Deviations TORG-2';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Document Print Buffer"; "Document Print Buffer")
        {
            DataItemTableView = sorting("User ID");

            trigger OnPreDataItem()
            begin
                "Document Print Buffer".Get(UserId);
                ItemReportManagement.PrintTORG2("Document Print Buffer", OperationType, OrderNo, OrderDate, FileName);
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
                    field(OrderNo; OrderNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Order No.';
                        ToolTip = 'Specifies the number of the related order.';
                    }
                    field(OrderDate; OrderDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Order Date';
                        ToolTip = 'Specifies the creation date of the related order.';
                    }
                    field(OperationType; OperationType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Operation Type';
                        ToolTip = 'Specifies the type of the related operation, for the purpose of VAT reporting.';
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

    var
        ItemReportManagement: Codeunit "Item Report Management";
        OperationType: Text;
        OrderNo: Code[20];
        OrderDate: Date;
        FileName: Text;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewOrderNo: Text[20]; NewOrderDate: Date; NewOperationType: Text)
    begin
        OrderNo := NewOrderNo;
        OrderDate := NewOrderDate;
        OperationType := NewOperationType;
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

