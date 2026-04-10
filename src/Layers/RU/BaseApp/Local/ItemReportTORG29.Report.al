#pragma warning disable AA0247
report 14919 "Item Report TORG-29"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Item Report TORG-29';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(ReceiptsHeader; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;

            trigger OnPreDataItem()
            begin
                ResponsibleEmployeeRec.Get(ResponsibleEmployee);
                ReportAcceptorEmployeeRec.Get(ReportAcceptorEmployee);
                ReceiptsTotal := 0;
                ShipmentTotal := 0;
                TORG29Helper.CreateTempReceipts(
                  TempValueEntryReceipts, ErrorBuffer, TempEntriesCount, ErrorsCount,
                  ResidOnstart, StartDate, EndDate, LocationCode,
                  AmountType, ReceiptsDetailing, SalesPriceType, SalesCode, ShowCostReceipts);
                TORG29Helper.CreateTempShipment(
                  TempValueEntryShipment, ErrorBuffer, TempEntriesCount, ErrorsCount,
                  StartDate, EndDate, LocationCode,
                  AmountType, ShipmentDetailing, SalesPriceType, SalesCode, ShowCostShipment);
                TORG29Helper.FillHeader(
                  Location.Name + ' ' + Location."Name 2", Format(OperationType),
                  ReportNo, Format(ReportDate), StartDate, Format(EndDate),
                  ResponsibleEmployeeRec.GetJobTitleName() + ' ' + ResponsibleEmployeeRec."Last Name" + ' ' +
                  ResponsibleEmployeeRec.Initials,
                  ResponsibleEmployee, LocRepMgt.FormatReportValue(ResidOnstart, 2));
            end;
        }
        dataitem(IntegerReceipts; "Integer")
        {
            DataItemTableView = sorting(Number);
            dataitem(PMReceipts; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;

                trigger OnAfterGetRecord()
                begin
                    PMReceiptsTotal :=
                      PMReceiptsTotal + TempValueEntryReceipts."Sales Amount (Actual)" -
                      TempValueEntryReceipts."Cost Amount (Actual)";

                    TORG29Helper.FillLine(
                      '', '', TNTxt,
                      LocRepMgt.FormatReportValue(TempValueEntryReceipts."Sales Amount (Actual)" - TempValueEntryReceipts."Cost Amount (Actual)", 2),
                      '', '', TORG29Helper.GetRcptType());
                end;

                trigger OnPreDataItem()
                begin
                    if not ShowCostReceipts then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    TempValueEntryReceipts.FindFirst()
                else
                    TempValueEntryReceipts.Next();
                ReceiptsTotal := ReceiptsTotal + TempValueEntryReceipts."Valued Quantity";

                TORG29Helper.FillLine(
                  TempValueEntryReceipts.Description, Format(TempValueEntryReceipts."Posting Date"),
                  TempValueEntryReceipts."Document No.", LocRepMgt.FormatReportValue(TempValueEntryReceipts."Valued Quantity", 2),
                  TempValueEntryReceipts."Job No.", TempValueEntryReceipts."Job Task No.", TORG29Helper.GetRcptType());
            end;

            trigger OnPreDataItem()
            begin
                TempValueEntryReceipts.Reset();
                if AmountType = AmountType::Price then
                    TempValueEntryReceipts.SetFilter("Item Ledger Entry Quantity", '<>0');
                SetRange(Number, 1, TempValueEntryReceipts.Count);
                ReceiptsTotal := 0;
            end;
        }
        dataitem(ReceiptsFooter; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;
            dataitem(PMReceiptsFooter; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;

                trigger OnPreDataItem()
                begin
                    if not ShowCostReceipts then
                        CurrReport.Break();
                end;
            }

            trigger OnPostDataItem()
            begin
                TORG29Helper.FillRcptPageFooter(
                  LocRepMgt.FormatReportValue(ReceiptsTotal, 2), LocRepMgt.FormatReportValue(PMReceiptsTotal, 2),
                  LocRepMgt.FormatReportValue(ReceiptsTotal + ResidOnstart + PMReceiptsTotal, 2));
            end;
        }
        dataitem(ShipmentHeader; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;

            trigger OnPreDataItem()
            begin
                if ShipmentDetailing = ShipmentDetailing::Sum then begin
                    if TempValueEntryShipment.Find('-') then
                        ShipmentTotal := TempValueEntryShipment."Valued Quantity";
                    ShipmentTotalHeader := Format(ShipmentTotal, 0, '<Sign><Integer Thousand><Decimals,3>');
                end;
                TORG29Helper.FillIssueHeader(ShipmentTotalHeader);
            end;
        }
        dataitem(IntegerShipment; "Integer")
        {
            DataItemTableView = sorting(Number);
            dataitem(PMShipment; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;

                trigger OnAfterGetRecord()
                begin
                    PMShipmentTotal :=
                      PMShipmentTotal + TempValueEntryShipment."Sales Amount (Actual)" -
                      TempValueEntryShipment."Cost Amount (Actual)";

                    TORG29Helper.FillLine(
                      '', '', TNTxt,
                      LocRepMgt.FormatReportValue(TempValueEntryShipment."Sales Amount (Actual)" - TempValueEntryShipment."Cost Amount (Actual)", 2),
                      '', '', TORG29Helper.GetShptType());
                end;

                trigger OnPreDataItem()
                begin
                    if not ShowCostShipment then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    TempValueEntryShipment.FindFirst()
                else
                    TempValueEntryShipment.Next();

                ShipmentTotal := ShipmentTotal + TempValueEntryShipment."Valued Quantity";
                TORG29Helper.FillLine(
                  TempValueEntryShipment.Description, Format(TempValueEntryShipment."Posting Date"),
                  TempValueEntryShipment."Document No.", LocRepMgt.FormatReportValue(TempValueEntryShipment."Valued Quantity", 2),
                  TempValueEntryShipment."Job No.", TempValueEntryShipment."Job Task No.",
                  TORG29Helper.GetShptType());
            end;

            trigger OnPreDataItem()
            begin
                if ShipmentDetailing = ShipmentDetailing::Sum then
                    CurrReport.Break();
                TempValueEntryShipment.Reset();
                if AmountType = AmountType::Price then
                    TempValueEntryShipment.SetFilter("Item Ledger Entry Quantity", '<>0');

                SetRange(Number, 1, TempValueEntryShipment.Count);

                ShipmentTotal := 0;
            end;
        }
        dataitem(ShipmentFooter; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;
            dataitem(PMShipmentFooter; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;

                trigger OnPreDataItem()
                begin
                    if not ShowCostShipment then
                        CurrReport.Break();
                end;
            }

            trigger OnPostDataItem()
            begin
                TORG29Helper.FillShptPageFooter(
                  EndDate, Format(ShipmentTotal),
                  LocRepMgt.FormatReportValue(ReceiptsTotal - ShipmentTotal + ResidOnstart + PMReceiptsTotal + PMShipmentTotal, 2),
                  Format(AttachesNo), ReportAcceptorEmployeeRec.GetJobTitleName(),
                  ReportAcceptorEmployeeRec."Last Name" + ' ' + ReportAcceptorEmployeeRec.Initials,
                  ResponsibleEmployeeRec.GetJobTitleName(),
                  ResponsibleEmployeeRec."Last Name" + ' ' + ResponsibleEmployeeRec.Initials);
            end;
        }
        dataitem(ErrorLog; "Integer")
        {
            DataItemTableView = sorting(Number);

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    ErrorBuffer.FindFirst()
                else
                    ErrorBuffer.Next();

                TORG29Helper.FillErrorLine(
                  Format(ErrorBuffer."Posting Date"), ErrorBuffer."Item No.", ErrorBuffer.Description);
            end;

            trigger OnPostDataItem()
            begin
                TORG29Helper.SetMainSheet();
            end;

            trigger OnPreDataItem()
            begin
                ErrorBuffer.Reset();
                SetRange(Number, 1, ErrorBuffer.Count);
                TORG29Helper.SetErrorsSheet();
                TORG29Helper.FillErrorReportHeader();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(LocationCode; LocationCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Location Code';
                        Lookup = true;
                        NotBlank = true;
                        TableRelation = Location;
                        ToolTip = 'Specifies the code for the location where the items are located.';

                        trigger OnValidate()
                        begin
                            LocationCodeOnAfterValidate();
                        end;
                    }
                    field(ReportNo; ReportNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report No.';
                        ToolTip = 'Specifies the number of times that the report has printed based on the value of the Last Goods Report No. field in the Location Card window.';
                    }
                    field(ResponsibleEmployee; ResponsibleEmployee)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Responsible Employee';
                        Lookup = true;
                        TableRelation = Employee;
                        ToolTip = 'Specifies the employee who is responsible for the validity of the data in the report.';
                    }
                    field(ReportAcceptorEmployee; ReportAcceptorEmployee)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Acceptor';
                        Lookup = true;
                        TableRelation = Employee;
                        ToolTip = 'Specifies the user who approved the report.';
                    }
                    field(ReportDate; ReportDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Date';
                        ToolTip = 'Specifies when the report was created.';
                    }
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'End Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(OperationType; OperationType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Operation Type';
                        ToolTip = 'Specifies the type of the related operation, for the purpose of VAT reporting.';
                    }
                    field(AttachesNo; AttachesNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Attaches No.';
                        MinValue = 0;
                        ToolTip = 'Specifies the number of attachments to the report.';
                    }
                    field(ReceiptsDetailing; ReceiptsDetailing)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Receipt Detailing';
                        DrillDown = false;
                        OptionCaption = 'Document,Item,Operation';
                        ToolTip = 'Specifies what the detailed information for each entry is based on. If you select Document, amounts are totaled for each document. If you select Item, the amount and quantity are totaled for each item. If you select Operation, the amount and quantity are included in a single transaction.';
                    }
                    field(ShipmentDetailing; ShipmentDetailing)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Shipment Detailing';
                        DrillDown = false;
                        OptionCaption = 'Total Amount,Document,Item,Operation';
                        ToolTip = 'Specifies what the detailed information for each entry is based on. If you select Total Amount, the report summarizes amounts in a single line. If you select Document, amounts are totaled for each document. If you select Item, the amount and quantity are totaled for each item. If you select Operation, the amount and quantity are included in a single transaction.';
                    }
                    field(AmountType; AmountType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amount Type';
                        DrillDown = false;
                        OptionCaption = 'Cost,Sales Price';
                        ToolTip = 'Specifies what the amounts are based on, cost or sales price. If you set this field to Sales Price, the Sales Type, Show Cost Amount for Receipts, and Show Cost Amount for Shipment fields become available.';

                        trigger OnValidate()
                        begin
                            PageUpdateControls();
                        end;
                    }
                    field(SalesTypeCtrl; SalesType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Type';
                        DrillDown = false;
                        Enabled = CtrlEnable;
                        NotBlank = true;
                        OptionCaption = 'Customer Price Group,All Customers,Campaign';
                        ToolTip = 'Specifies the type of price list. If you select Customer Price List or Campaign, you can select the price list in the Sales Code field. If you select All Customers, a unified price list is used.';

                        trigger OnValidate()
                        begin
                            PageUpdateControls();
                            SalesPriceType := GetSalesPriceType(SalesType);
                            SalesCode := '';
                        end;
                    }
                    field(SalesCodeCtrl; SalesCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Code';
                        Enabled = CtrlEnable;
                        Lookup = true;
                        ToolTip = 'Specifies the price list. Depending on the selection in the Sales Type field, you can specify either a customer price group or a campaign number.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            Clear(CustomerPriceGroupList);
                            Clear(CampaignList);
                            if SalesPriceType = SalesPriceType::Campaign then begin
                                CampaignList.LookupMode(true);
                                if CampaignList.RunModal() = ACTION::LookupOK then begin
                                    CampaignList.GetRecord(Campaign);
                                    Text := Campaign."No.";
                                    exit(true);
                                end;
                                exit(false);
                            end;
                            CustomerPriceGroupList.LookupMode(true);
                            if CustomerPriceGroupList.RunModal() = ACTION::LookupOK then begin
                                CustomerPriceGroupList.GetRecord(CustomerPriceGroup);
                                Text := CustomerPriceGroup.Code;
                                exit(true);
                            end;
                            exit(false);
                        end;
                    }
                    field(ReceiptsCost; ShowCostReceipts)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Cost Amount for Receipts';
                        Enabled = CtrlEnable;
                        ToolTip = 'Specifies if each receipt line must be divided into two lines. If selected, the first line for a receipt represents item cost, and the second line represents the sales margin.';
                    }
                    field(ShipmentCost; ShowCostShipment)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Cost Amount for Shipment';
                        Enabled = CtrlEnable;
                        ToolTip = 'Specifies if each shipment line must be divided into two lines. If selected, the first line for a receipt represents the item cost, and the second line represents the sales margin.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            CtrlEnable := true;
            ReportDate := WorkDate();
        end;

        trigger OnOpenPage()
        var
            LocationLookup: Record Location;
        begin
            PageUpdateControls();
            if LocationCode <> '' then
                if not LocationLookup.Get(LocationCode) then
                    LocationCode := ''
                else begin
                    ResponsibleEmployee := LocationLookup."Responsible Employee No.";

                    if LocationLookup."Last Goods Report No." < 2147483647 then
                        ReportNo := Format(LocationLookup."Last Goods Report No." + 1)
                    else
                        ReportNo := Format(LocationLookup."Last Goods Report No.");

                    if LocationLookup."Last Goods Report Date" <> 0D then begin
                        StartDate := CalcDate('<1D>', LocationLookup."Last Goods Report Date");
                        EndDate := StartDate;
                    end;
                end;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        ReportDate := WorkDate();
        CompanyInfo.Get();
    end;

    trigger OnPostReport()
    begin
        if not CurrReport.Preview then begin
            if Evaluate(Location."Last Goods Report No.", ReportNo) then;
            Location."Last Goods Report Date" := EndDate;
            Location.Modify();
        end;

        if FileName = '' then
            TORG29Helper.ExportData()
        else
            TORG29Helper.ExportDataFile(FileName);
    end;

    trigger OnPreReport()
    begin
        if LocationCode = '' then
            Error(Text006);
        Location.Get(LocationCode);
        if (StartDate > EndDate) or (StartDate = 0D) or (EndDate = 0D) then
            Error(Text005);
        if ResponsibleEmployee = '' then
            Error(Text008);
        if ReportAcceptorEmployee = '' then
            Error(Text007);

        TORG29Helper.InitReportTemplate();
        TORG29Helper.SetMainSheet();
    end;

    var
        CustomerPriceGroup: Record "Customer Price Group";
        Location: Record Location;
        CompanyInfo: Record "Company Information";
        Campaign: Record Campaign;
        ReportAcceptorEmployeeRec: Record Employee;
        ResponsibleEmployeeRec: Record Employee;
        TempValueEntryReceipts: Record "Value Entry" temporary;
        TempValueEntryShipment: Record "Value Entry" temporary;
        ErrorBuffer: Record "Value Entry" temporary;
        TORG29Helper: Codeunit "TORG-29 Helper";
        LocRepMgt: Codeunit "Local Report Management";
        CampaignList: Page "Campaign List";
        CustomerPriceGroupList: Page "Customer Price Groups";
        ResidOnstart: Decimal;
        ReceiptsTotal: Decimal;
        ShipmentTotal: Decimal;
        PMReceiptsTotal: Decimal;
        PMShipmentTotal: Decimal;
        ResponsibleEmployee: Code[20];
        ReportAcceptorEmployee: Code[20];
        SalesCode: Code[20];
        LocationCode: Code[20];
        AttachesNo: Integer;
        ErrorsCount: Integer;
        TempEntriesCount: Integer;
        ReceiptsDetailing: Option Document,Item,Operation;
        ShipmentDetailing: Option "Sum",Document,Item,Operation;
        AmountType: Option Cost,Price;
        SalesType: Option "Customer Price Group","All Customers",Campaign;
        SalesPriceType: Enum "Sales Price Type";
        ShowCostReceipts: Boolean;
        ShowCostShipment: Boolean;
        ReportDate: Date;
        StartDate: Date;
        EndDate: Date;
        OperationType: Text[30];
        ReportNo: Text[30];
        ShipmentTotalHeader: Text[30];
#pragma warning disable AA0074
        Text005: Label 'Report term is incorrect.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text006: Label 'Location Code is required.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text007: Label 'Employee Code for Report Acceptor should be entered.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text008: Label 'Employee Code for Responsible Employee should be entered.';
#pragma warning restore AA0074
        FileName: Text;
        CtrlEnable: Boolean;
        SalesCodeCtrlEnable: Boolean;
        TNTxt: Label 't.n.', Comment = 'Should be translated "Ô.¡."';

    local procedure LocationCodeOnAfterValidate()
    var
        LocationLookup: Record Location;
    begin
        LocationLookup.SetFilter(Code, LocationCode);
        LocationLookup.FindFirst();
        ResponsibleEmployee := LocationLookup."Responsible Employee No.";

        if LocationLookup."Last Goods Report No." < 2147483647 then
            ReportNo := Format(LocationLookup."Last Goods Report No." + 1)
        else
            ReportNo := Format(LocationLookup."Last Goods Report No.");

        if LocationLookup."Last Goods Report Date" <> 0D then begin
            StartDate := CalcDate('1D', LocationLookup."Last Goods Report Date");
            EndDate := StartDate;
        end;
    end;

    local procedure PageUpdateControls()
    begin
        CtrlEnable := AmountType <> AmountType::Cost;
        if CtrlEnable then
            SalesCode := '';

        if SalesPriceType = SalesPriceType::"All Customers" then begin
            SalesCodeCtrlEnable := false;
            SalesCode := '';
        end else
            SalesCodeCtrlEnable := CtrlEnable;
    end;

    local procedure GetSalesPriceType(SalesType: Option "Customer Price Group","All Customers",Campaign): Enum "Sales Price Type"
    begin
        case SalesType of
            SalesType::"All Customers":
                exit("Sales Price Type"::"All Customers");
            SalesType::"Customer Price Group":
                exit("Sales Price Type"::"Customer Price Group");
            SalesType::Campaign:
                exit("Sales Price Type"::Campaign);
        end
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewLocationCode: Code[10]; NewReportNo: Text[30]; NewResponsibleEmployee: Code[20]; NewReportAcceptorEmployee: Code[20]; NewStartDate: Date; NewEndDate: Date; NewOperationType: Text[30]; NewAttachesNo: Integer; NewReceiptsDetailing: Option; NewShipmentDetailing: Option; NewAmountType: Option; NewSalesType: Option "Customer Price Group","All Customers",Campaign; NewSalesCode: Code[20]; NewShowCostReceipts: Boolean; NewShowCostShipment: Boolean)
    begin
        LocationCode := NewLocationCode;
        ReportNo := NewReportNo;
        ResponsibleEmployee := NewResponsibleEmployee;
        ReportAcceptorEmployee := NewReportAcceptorEmployee;
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        OperationType := NewOperationType;
        AttachesNo := NewAttachesNo;
        ReceiptsDetailing := NewReceiptsDetailing;
        ShipmentDetailing := NewShipmentDetailing;
        AmountType := NewAmountType;
        SalesType := NewSalesType;
        SalesPriceType := GetSalesPriceType(SalesType);
        SalesCode := NewSalesCode;
        ShowCostReceipts := NewShowCostReceipts;
        ShowCostShipment := NewShowCostShipment;
    end;
}

