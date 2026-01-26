// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Sales.History;
using System.Telemetry;
using System.Utilities;

report 15000300 "Create Recurring Orders"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Create Recurring Orders';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const("Blanket Order"), "Recurring Group Code" = filter(<> ''));
            RequestFilterFields = "Recurring Group Code", "No.";
            dataitem(RecurringOrder; "Integer")
            {
                DataItemTableView = sorting(Number);

                trigger OnAfterGetRecord()
                begin
                    StoreOrderDate := "Sales Header"."Order Date";
                    BlanketOrderToOrder.Initialize(ProcessingDate, CreateLatest);
                    if HideError then
                        if BlanketOrderToOrder.Run("Sales Header") then
                            OrderCounter := OrderCounter + 1
                        else begin
                            ErrorCounter := ErrorCounter + 1;
                            "Sales Header".Mark(true);
                        end
                    else begin
                        BlanketOrderToOrder.Run("Sales Header");
                        OrderCounter := OrderCounter + 1;
                    end;

                    // Check if the order recurs
                    // Stop if the date is overwritten or if the order date is not moved (Date formula is for inst. 0D):
                    if ("Sales Header"."Order Date" > ProcessingDate) or (StoreOrderDate = "Sales Header"."Order Date") then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                // Select orders that don't recur
                RecurringGroup.Get("Recurring Group Code");
                if HideError then begin
                    if "Order Date" > ProcessingDate then
                        CurrReport.Skip();
                    if (RecurringGroup."Starting date" > ProcessingDate) or
                       ((RecurringGroup."Closing date" < ProcessingDate) and (RecurringGroup."Closing date" <> 0D))
                    then
                        CurrReport.Skip();
                    if "Deactivate recurrence" then
                        CurrReport.Skip();
                end;
            end;

            trigger OnPostDataItem()
            begin
                if ErrorCounter = 0 then
                    Message(Text002, OrderCounter)
                else
                    if Confirm(
                         Text003,
                         true, OrderCounter, ErrorCounter)
                    then begin
                        "Sales Header".MarkedOnly(true);
                        OrderOverview.SetTableView("Sales Header");
                        OrderOverview.RunModal();
                    end;
            end;

            trigger OnPreDataItem()
            begin
                if ProcessingDate = 0D then
                    Error(Text001);
                OrderCounter := 0;
                ErrorCounter := 0;
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
                    field(ProcessingDate; ProcessingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Processing Date';
                        ToolTip = 'Specifies the date to process the blanket orders.';
                    }
                    field(CreateLatest; CreateLatest)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create only latest';
                        ToolTip = 'Specifies if you only want to create the latest recurring order for the blanket orders processed. This option overrides the equivalent option for the recurring group.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            ProcessingDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        HideError := true;
    end;

    trigger OnPostReport()
    begin
        FeatureTelemetry.LogUptake('1000HV2', NORecurringOrderTok, Enum::"Feature Uptake Status"::"Used");
        FeatureTelemetry.LogUsage('1000HV3', NORecurringOrderTok, 'NO Recurring Order Created');
    end;

    var
        RecurringGroup: Record "Recurring Group";
        BlanketOrderToOrder: Codeunit "Repeating Order to Order";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        OrderOverview: Page "Recurring Orders Overview";
        NORecurringOrderTok: Label 'NO Recurring Order', Locked = true;
        OrderCounter: Integer;
        ErrorCounter: Integer;
        ProcessingDate: Date;
        CreateLatest: Boolean;
        HideError: Boolean;
        StoreOrderDate: Date;
        Text001: Label 'You must specify a processing date.';
        Text002: Label '%1 orders are created.';
        Text003: Label '%1 orders are created.\An error occured. %2 orders were not created.\\Do you want to view recurring orders?';

    [Scope('OnPrem')]
    procedure SetHiddenError(NewHiddenError: Boolean)
    begin
        HideError := NewHiddenError;
    end;

    [Scope('OnPrem')]
    procedure SetCreatingDate(NewProcessingDate: Date)
    begin
        ProcessingDate := NewProcessingDate;
    end;
}

