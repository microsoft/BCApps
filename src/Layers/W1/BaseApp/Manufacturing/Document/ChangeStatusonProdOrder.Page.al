// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Manufacturing.Setup;

page 99000882 "Change Status on Prod. Order"
{
    Caption = 'Change Status on Prod. Order';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    InstructionalText = 'Do you want to change the status of this production order?';
    ModifyAllowed = false;
    PageType = ConfirmationDialog;

    layout
    {
        area(content)
        {
            field(FirmPlannedStatus; ProdOrderStatus.Status)
            {
                ApplicationArea = Manufacturing;
                Caption = 'New Status';
                ToolTip = 'Specifies the new status for the production order.';
                ValuesAllowed = "Firm Planned", Released, Finished;

                trigger OnValidate()
                begin
                    case ProdOrderStatus.Status of
                        ProdOrderStatus.Status::Finished:
                            CheckStatus(FinishedStatusEditable);
                        ProdOrderStatus.Status::Released:
                            CheckStatus(ReleasedStatusEditable);
                        ProdOrderStatus.Status::"Firm Planned":
                            CheckStatus(FirmPlannedStatusEditable);
                    end;

                    if ProdOrderStatus.Status <> ProdOrderStatus.Status::Finished then
                        FinishOrderWithoutOutput := false;

                    CurrPage.Update(true);
                end;
            }
            field(PostingDate; PostingDate)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Posting Date';
                Tooltip = 'Specifies the posting date used for automatic posting of consumption, output, or capacity, based on the Flushing method defined for components and routing lines.';
            }
            field(ReqUpdUnitCost; ReqUpdUnitCost)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Update Unit Cost';
                Tooltip = 'Specifies whether to update the unit cost of the produced item and any related production or sales orders.';
            }
            field("Finish Order without Output"; FinishOrderWithoutOutput)
            {
                Caption = 'Finish Order';
                Tooltip = 'Specifies that the status of orders with no output can be changed to finished, and the WIP will be written off to the Inventory Adjustment Account.';
                ApplicationArea = Manufacturing;
                Editable = FinishOrderWithoutOutputEditable;
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        FinishedStatusEditable := true;
        ReleasedStatusEditable := true;
        FirmPlannedStatusEditable := true;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetFinishOrderWithoutOutputEditable();
    end;

    trigger OnAfterGetRecord()
    begin
        SetFinishOrderWithoutOutputEditable();
    end;

    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ProdOrderStatus: Record "Production Order";
        PostingDate: Date;
        FirmPlannedStatusEditable: Boolean;
        ReleasedStatusEditable: Boolean;
        FinishedStatusEditable: Boolean;
        FinishOrderWithoutOutput: Boolean;
        FinishOrderWithoutOutputEditable: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text666: Label '%1 is not a valid selection.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        ReqUpdUnitCost: Boolean;

    procedure Set(ProdOrder: Record "Production Order")
    begin
        OnBeforeSet(ProdOrder);

        if ProdOrder.Status = ProdOrder.Status::Finished then
            ProdOrder.FieldError(Status);

        FirmPlannedStatusEditable := ProdOrder.Status.AsInteger() < ProdOrder.Status::"Firm Planned".AsInteger();
        ReleasedStatusEditable := ProdOrder.Status <> ProdOrder.Status::Released;
        FinishedStatusEditable := ProdOrder.Status = ProdOrder.Status::Released;
        OnSetOnAfterCalcEditable(ProdOrder, FirmPlannedStatusEditable, ReleasedStatusEditable, FinishedStatusEditable);
        if ProdOrder.Status.AsInteger() > ProdOrder.Status::Simulated.AsInteger() then
            ProdOrderStatus.Status := "Production Order Status".FromInteger(ProdOrder.Status.AsInteger() + 1)
        else
            ProdOrderStatus.Status := ProdOrderStatus.Status::"Firm Planned";

        PostingDate := WorkDate();

        OnAfterSet(ProdOrder, PostingDate, ReqUpdUnitCost, ProdOrderStatus, FirmPlannedStatusEditable, ReleasedStatusEditable, FinishedStatusEditable);
    end;

#if not CLEAN27
    [Obsolete('Replaced with namesake procedure with additional parameter.', '27.0')]
    procedure ReturnPostingInfo(var Status: Enum "Production Order Status"; var PostingDate2: Date; var UpdUnitCost: Boolean)
    var
        DummyFinishOrderWithoutOutput: Boolean;
    begin
        ReturnPostingInfo(Status, PostingDate2, UpdUnitCost, DummyFinishOrderWithoutOutput);
    end;
#endif

    procedure ReturnPostingInfo(var Status: Enum "Production Order Status"; var PostingDate2: Date; var UpdUnitCost: Boolean; var NewFinishOrderWithoutOutput: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReturnPostingInfo(Status, PostingDate2, UpdUnitCost, IsHandled, NewFinishOrderWithoutOutput);
        if IsHandled then
            exit;

        Status := ProdOrderStatus.Status;
        PostingDate2 := PostingDate;
        UpdUnitCost := ReqUpdUnitCost;
        NewFinishOrderWithoutOutput := FinishOrderWithoutOutput;
    end;

    local procedure CheckStatus(StatusEditable: Boolean)
    begin
        if not StatusEditable then
            Error(Text666, ProdOrderStatus.Status);
    end;

    local procedure SetFinishOrderWithoutOutputEditable()
    begin
        ManufacturingSetup.GetRecordOnce();

        FinishOrderWithoutOutputEditable := (ProdOrderStatus.Status = ProdOrderStatus.Status::Finished) and (ManufacturingSetup."Finish Order without Output");
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSet(ProdOrder: Record "Production Order"; var PostingDate: Date; var ReqUpdUnitCost: Boolean; var ProductionOrderStatus: Record "Production Order"; var FirmPlannedStatusEditable: Boolean; var ReleasedStatusEditable: Boolean; var FinishedStatusEditable: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReturnPostingInfo(var Status: Enum "Production Order Status"; var PostingDate2: Date; var UpdUnitCost: Boolean; var IsHandled: Boolean; var NewFinishOrderWithoutOutput: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetOnAfterCalcEditable(ProdOrder: Record "Production Order"; var FirmPlannedStatusEditable: Boolean; var ReleasedStatusEditable: Boolean; var FinishedStatusEditable: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSet(var ProdOrder: Record "Production Order")
    begin
    end;
}

