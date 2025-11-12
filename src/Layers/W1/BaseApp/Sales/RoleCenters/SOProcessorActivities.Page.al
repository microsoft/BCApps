// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.RoleCenters;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Navigate;
using Microsoft.RoleCenters;
using Microsoft.Sales.Document;
using System;
using System.Environment;
using System.Environment.Configuration;
#if not CLEAN28
using System.Feedback;
#endif
using System.Visualization;

page 9060 "SO Processor Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Sales Cue";
    Permissions = tabledata "Sales Cue" = rm;

    layout
    {
        area(content)
        {
            cuegroup("For Release")
            {
                Caption = 'For Release';
                field("Sales Quotes - Open"; Rec."Sales Quotes - Open")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Sales Quotes";
                }
                field("Sales Orders - Open"; Rec."Sales Orders - Open")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Sales Order List";
                }
                field(SalesOrdersReservedFromStock; SalesOrdersReservedFromStock)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Completely Reserved from Stock';
                    ToolTip = 'Specifies the number of sales orders that are completely reserved from stock.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownNoOfReservedFromStockSalesOrders();
                    end;
                }

                actions
                {
                    action("New Sales Quote")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Sales Quote';
                        RunObject = Page "Sales Quote";
                        RunPageMode = Create;
                        ToolTip = 'Offer items or services to a customer.';
                    }
                    action("New Sales Order")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Sales Order';
                        RunObject = Page "Sales Order";
                        RunPageMode = Create;
                        ToolTip = 'Create a new sales order for items or services that require partial posting.';
                    }
                }
            }
            cuegroup("Sales Orders Released Not Shipped")
            {
                Caption = 'Sales Orders Released Not Shipped';
                field(ReadyToShip; ReadyToShip)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ready To Ship';
                    DrillDownPageID = "Sales Order List";
                    ToolTip = 'Specifies the number of sales documents that are ready to ship.';
                    StyleExpr = ReadyToShipStyle;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowOrders(Rec.FieldNo("Ready to Ship"));
                    end;
                }
                field(PartiallyShipped; PartiallyShipped)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Partially Shipped';
                    DrillDownPageID = "Sales Order List";
                    ToolTip = 'Specifies the number of sales documents that are partially shipped.';
                    StyleExpr = PartiallyShippedStyle;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowOrders(Rec.FieldNo("Partially Shipped"));
                    end;
                }
                field(DelayedOrders; DelayedOrders)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Delayed';
                    DrillDownPageID = "Sales Order List";
                    ToolTip = 'Specifies the number of sales documents where your delivery is delayed.';
                    StyleExpr = DelayedOrdersStyle;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowOrders(Rec.FieldNo(Delayed));
                    end;
                }
                field("Average Days Delayed"; AverageDaysDelayed)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Average Days Delayed';
                    DecimalPlaces = 0 : 1;
                    Image = Calendar;
                    ToolTip = 'Specifies the number of days that your order deliveries are delayed on average.';
                    StyleExpr = AverageDaysDelayedStyle;
                }

                actions
                {
                    action(Navigate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Find entries...';
                        RunObject = Page Navigate;
                        ShortCutKey = 'Ctrl+Alt+Q';
                        ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                    }
                }
            }
            cuegroup(Returns)
            {
                Caption = 'Returns';
                field("Sales Return Orders - Open"; Rec."Sales Return Orders - Open")
                {
                    ApplicationArea = SalesReturnOrder;
                    DrillDownPageID = "Sales Return Order List";
                }
                field("Sales Credit Memos - Open"; Rec."Sales Credit Memos - Open")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Sales Credit Memos";
                }

                actions
                {
                    action("New Sales Return Order")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'New Sales Return Order';
                        RunObject = Page "Sales Return Order";
                        RunPageMode = Create;
                        ToolTip = 'Process a return or refund that requires inventory handling by creating a new sales return order.';
                    }
                    action("New Sales Credit Memo")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Sales Credit Memo';
                        RunObject = Page "Sales Credit Memo";
                        RunPageMode = Create;
                        ToolTip = 'Process a return or refund by creating a new sales credit memo.';
                    }
                }
            }
            cuegroup("Document Exchange Service")
            {
                Caption = 'Document Exchange Service';
                Visible = ShowDocumentsPendingDodExchService;
                field("Sales Inv. - Pending Doc.Exch."; Rec."Sales Inv. - Pending Doc.Exch.")
                {
                    ApplicationArea = Suite;
                    Visible = ShowDocumentsPendingDodExchService;
                }
                field("Sales CrM. - Pending Doc.Exch."; Rec."Sales CrM. - Pending Doc.Exch.")
                {
                    ApplicationArea = Suite;
                    Visible = ShowDocumentsPendingDodExchService;
                }
            }
#if not CLEAN28
            usercontrol(SATAsyncLoader; SatisfactionSurveyAsync)
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
                ObsoleteReason = 'The Satisfaction Survey feature will be removed in a future release.';
                ObsoleteState = Pending;
                ObsoleteTag = '28.0';
            }
#endif
        }
    }

    actions
    {
        area(processing)
        {
            action("Set Up Cues")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Up Cues';
                Image = Setup;
                ToolTip = 'Set up the cues (status tiles) related to the role.';

                trigger OnAction()
                var
                    CueRecordRef: RecordRef;
                begin
                    CueRecordRef.GetTable(Rec);
                    CuesAndKpis.OpenCustomizePageForCurrentUser(CueRecordRef.Number);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        TaskParameters: Dictionary of [Text, Text];
    begin
        TaskParameters.Add('View', Rec.GetView());
        if CalcTaskId <> 0 then
            if CurrPage.CancelBackgroundTask(CalcTaskId) then;
        CurrPage.EnqueueBackgroundTask(CalcTaskId, Codeunit::"SO Activities Calculate", TaskParameters, 120000, PageBackgroundTaskErrorLevel::Warning);
    end;

    trigger OnAfterGetRecord()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        ShowDocumentsPendingDodExchService := false;
        DocExchServiceSetup.SetLoadFields("Enabled");
        if DocExchServiceSetup.Get() then
            ShowDocumentsPendingDodExchService := DocExchServiceSetup.Enabled;
    end;

    trigger OnOpenPage()
    var
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        Rec.SetRespCenterFilter();
        Rec.SetRange("Date Filter", 0D, WorkDate());
        Rec.SetFilter("Date Filter2", '>=%1', WorkDate());
        Rec.SetRange("User ID Filter", UserId());

        RoleCenterNotificationMgt.ShowNotifications();
        ConfPersonalizationMgt.RaiseOnOpenRoleCenterEvent();

        if PageNotifier.IsAvailable() then begin
            PageNotifier := PageNotifier.Create();
            PageNotifier.NotifyPageReady();
        end;
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        SOActivitiesCalculate: Codeunit "SO Activities Calculate";
        UIHelperTriggers: Codeunit "UI Helper Triggers";
        PrevUpdatedOn: DateTime;
        IsHandled: Boolean;
    begin
        OnBeforeOnPageBackgroundTaskCompleted(TaskId, CalcTaskId, Results, IsHandled);
        if IsHandled then
            exit;

        if TaskId <> CalcTaskId then
            exit;

        CalcTaskId := 0;

        if Rec.Get() then;
        PrevUpdatedOn := Rec."Avg. Days Delayed Updated On";
        SOActivitiesCalculate.EvaluateResults(Results, Rec);
        ReadyToShip := Rec."Ready to Ship";
        AverageDaysDelayed := Rec."Average Days Delayed";
        DelayedOrders := Rec.Delayed;
        PartiallyShipped := Rec."Partially Shipped";
        SalesOrdersReservedFromStock := Rec."S. Ord. - Reserved From Stock";

        UIHelperTriggers.GetCueStyle(Database::"Sales Cue", Rec.FieldNo("Ready to Ship"), ReadyToShip, ReadyToShipStyle);
        UIHelperTriggers.GetCueStyle(Database::"Sales Cue", Rec.FieldNo("Average Days Delayed"), AverageDaysDelayed, AverageDaysDelayedStyle);
        UIHelperTriggers.GetCueStyle(Database::"Sales Cue", Rec.FieldNo(Delayed), DelayedOrders, DelayedOrdersStyle);
        UIHelperTriggers.GetCueStyle(Database::"Sales Cue", Rec.FieldNo("Partially Shipped"), PartiallyShipped, PartiallyShippedStyle);

        if Rec.WritePermission() and (Rec."Avg. Days Delayed Updated On" > PrevUpdatedOn) then begin
            PrevUpdatedOn := Rec."Avg. Days Delayed Updated On";
            Rec.LockTable();
            Rec.Get();
            Rec."Avg. Days Delayed Updated On" := PrevUpdatedOn;
            Rec."Average Days Delayed" := AverageDaysDelayed;
            if Rec.Modify() then;
            Commit();
        end;

        CurrPage.Update();
    end;

    var
        CuesAndKpis: Codeunit "Cues And KPIs";
        [RunOnClient]
        [WithEvents]
        PageNotifier: DotNet PageNotifier;
        AverageDaysDelayed: Decimal;
        ReadyToShip: Integer;
        PartiallyShipped: Integer;
        DelayedOrders: Integer;
        CalcTaskId: Integer;
        SalesOrdersReservedFromStock: Integer;
        ShowDocumentsPendingDodExchService: Boolean;
        AverageDaysDelayedStyle: Text;
        ReadyToShipStyle: Text;
        PartiallyShippedStyle: Text;
        DelayedOrdersStyle: Text;

    [IntegrationEvent(true, false)]
    procedure OnBeforeOnPageBackgroundTaskCompleted(TaskId: Integer; CalcTaskId: Integer; var Results: Dictionary of [Text, Text]; var IsHandled: Boolean)
    begin
    end;
}

