// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.eServices.EDocument;

page 27000 "Export Electr. Accounting"
{
    ApplicationArea = BasicMX;
    Caption = 'Export Electr. Accounting';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    ShowFilter = false;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(ExportType; ExportType)
            {
                ApplicationArea = BasicMX;
                Caption = 'Export Type';
                OptionCaption = 'Chart of Accounts,Trial Balance,Transactions,Auxiliary Accounts';
                ToolTip = 'Specifies which accounting information is exported, such as the trial balance or specific transactions.';

                trigger OnValidate()
                begin
                    EnableControls();
                end;
            }
            field(Year; Year)
            {
                ApplicationArea = BasicMX;
                Caption = 'Year';
                MaxValue = 2099;
                MinValue = 2000;
                ShowMandatory = true;
                ToolTip = 'Specifies for which year accounting information is exported. ';
            }
            field(Month; Month)
            {
                ApplicationArea = BasicMX;
                Caption = 'Month';
                Enabled = not ClosingBalanceSheet;
                MaxValue = 12;
                MinValue = 1;
                ShowMandatory = true;
                ToolTip = 'Specifies for which month accounting information is exported. ';
            }
            field(DeliveryType; DeliveryType)
            {
                ApplicationArea = BasicMX;
                Caption = 'Delivery Type';
                Enabled = EnableDeliveryType;
                OptionCaption = 'Normal,Complementary';
                ToolTip = 'Specifies if the exported accounting information will complement existing information. ';

                trigger OnValidate()
                begin
                    EnableControls();
                end;
            }
            field(UpdateDate; UpdateDate)
            {
                ApplicationArea = BasicMX;
                Caption = 'Update Date';
                Enabled = EnableUpdateDate;
                ShowMandatory = true;
                ToolTip = 'Specifies when the accounting information was last exported.';
            }
            field(RequestType; RequestType)
            {
                ApplicationArea = BasicMX;
                Caption = 'Request Type';
                Enabled = EnableRequestType;
                OptionCaption = 'AF,FC,DE,CO';
                ToolTip = 'Specifies the request type for the exported information.';

                trigger OnValidate()
                begin
                    EnableControls();
                end;
            }
            field(OrderNumber; OrderNumber)
            {
                ApplicationArea = BasicMX;
                Caption = 'Order Number';
                Enabled = EnableOrderNumber;
                ShowMandatory = true;
                ToolTip = 'Specifies the order number that will be assigned to the export.';
            }
            field(ProcessNumber; ProcessNumber)
            {
                ApplicationArea = BasicMX;
                Caption = 'Process Number';
                Enabled = EnableProcessNumber;
                ShowMandatory = true;
                ToolTip = 'Specifies the process number that will be assigned to the export.';
            }
            field(ClosingBalanceSheet; ClosingBalanceSheet)
            {
                ApplicationArea = BasicMX;
                Caption = 'Closing Balance Sheet';
                Enabled = EnableClosingBalanceSheet;
                ToolTip = 'Specifies if the exported trial balance will include closing balances.';
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Export)
            {
                ApplicationArea = BasicMX;
                Caption = 'Export...';
                Image = ExportFile;
                ToolTip = 'Export the specified accounting information.';

                trigger OnAction()
                begin
                    case ExportType of
                        ExportType::"Chart of Accounts":
                            ExportAccounts.ExportChartOfAccounts(Year, Month);
                        ExportType::"Trial Balance":
                            ExportAccounts.ExportBalanceSheet(Year, Month, DeliveryType, UpdateDate, ClosingBalanceSheet);
                        ExportType::Transactions:
                            ExportAccounts.ExportTransactions(Year, Month, RequestType, OrderNumber, ProcessNumber);
                        ExportType::"Auxiliary Accounts":
                            ExportAccounts.ExportAuxiliaryAccounts(Year, Month, RequestType, OrderNumber, ProcessNumber);
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Export', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Export_Promoted; Export)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Year := Date2DMY(WorkDate(), 3);
        Month := Date2DMY(WorkDate(), 2);
        EnableControls();
    end;

    var
        ExportAccounts: Codeunit "Export Accounts";
        ExportType: Option "Chart of Accounts","Trial Balance",Transactions,"Auxiliary Accounts";
        Month: Integer;
        Year: Integer;
        DeliveryType: Option Normal,Complementary;
        UpdateDate: Date;
        RequestType: Option AF,FC,DE,CO;
        OrderNumber: Text[13];
        ProcessNumber: Text[14];
        ClosingBalanceSheet: Boolean;
        EnableUpdateDate: Boolean;
        EnableDeliveryType: Boolean;
        EnableRequestType: Boolean;
        EnableOrderNumber: Boolean;
        EnableProcessNumber: Boolean;
        EnableClosingBalanceSheet: Boolean;

    local procedure EnableControls()
    begin
        ResetControls();

        case ExportType of
            ExportType::"Trial Balance":
                begin
                    EnableDeliveryType := true;
                    EnableClosingBalanceSheet := true;
                    if DeliveryType = DeliveryType::Complementary then begin
                        EnableUpdateDate := true;
                        UpdateDate := WorkDate();
                    end;
                end;
            ExportType::Transactions,
            ExportType::"Auxiliary Accounts":
                begin
                    EnableRequestType := true;
                    if RequestType in [RequestType::AF, RequestType::FC] then
                        EnableOrderNumber := true
                    else
                        EnableProcessNumber := true;
                end;
        end;
    end;

    local procedure ResetControls()
    begin
        EnableDeliveryType := false;
        EnableUpdateDate := false;
        EnableRequestType := false;
        EnableOrderNumber := false;
        EnableProcessNumber := false;
        EnableClosingBalanceSheet := false;

        UpdateDate := 0D;
    end;
}

