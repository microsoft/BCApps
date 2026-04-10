codeunit 131103 "Library - Report Selection"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        EventHandledName: Text;

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnBeforeSendEmailToCust', '', false, false)]
    local procedure HandleOnBeforeSendEmailToCust(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ShowDialog: Boolean; CustNo: Code[20]; var Handled: Boolean)
    begin
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnBeforeSendEmailToVendor', '', false, false)]
    local procedure HandleOnBeforeSendEmailToVendor(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ShowDialog: Boolean; VendorNo: Code[20]; var Handled: Boolean)
    begin
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Warehouse Document-Print", 'OnBeforePrintPickHeader', '', false, false)]
    local procedure HandleOnBeforePrintPickHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
        IsHandled := true;
        EventHandledName := 'HandleOnBeforePrintPickHeader';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Warehouse Document-Print", 'OnBeforePrintPutAwayHeader', '', false, false)]
    local procedure HandleOnBeforePrintPutAwayHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
        IsHandled := true;
        EventHandledName := 'HandleOnBeforePrintPutAwayHeader';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Warehouse Document-Print", 'OnBeforePrintMovementHeader', '', false, false)]
    local procedure HandleOnBeforePrintMovementHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
        IsHandled := true;
        EventHandledName := 'HandleOnBeforePrintMovementHeader';
    end;

    [Scope('OnPrem')]
    procedure GetEventHandledName(): Text
    begin
        exit(EventHandledName);
    end;

    procedure GetReportId(RecUsage: Enum "Report Selection Usage"; Sequence: Text) ReportId: Integer
    begin
        case RecUsage of
            RecUsage::"S.Quote":
                ReportId := Report::"Standard Sales - Quote";
            RecUsage::"S.Blanket":
                ReportId := Report::"Blanket Sales Order";
            RecUsage::"S.Order":
                ReportId := Report::"Standard Sales - Order Conf.";
            RecUsage::"S.Work Order":
                ReportId := Report::"Work Order";
            RecUsage::"S.Invoice":
                ReportId := Report::"Standard Sales - Invoice";
            RecUsage::"S.Return":
                ReportId := Report::"Return Order Confirmation";
            RecUsage::"S.Cr.Memo":
                ReportId := Report::"Standard Sales - Credit Memo";
            RecUsage::"S.Shipment":
                ReportId := Report::"Sales - Shipment";
            RecUsage::"S.Ret.Rcpt.":
                ReportId := Report::"Sales - Return Receipt";
            RecUsage::"S.Test":
                ReportId := Report::"Sales Document - Test";
            RecUsage::"P.Quote":
                ReportId := Report::"Purchase - Quote";
            RecUsage::"P.Blanket":
                ReportId := Report::"Blanket Purchase Order";
            RecUsage::"P.Order":
                ReportId := Report::Order;
            RecUsage::"P.Invoice":
                ReportId := Report::"Purchase - Invoice";
            RecUsage::"P.Return":
                ReportId := Report::"Return Order";
            RecUsage::"P.Cr.Memo":
                ReportId := Report::"Purchase - Credit Memo";
            RecUsage::"P.Receipt":
                ReportId := Report::"Purchase - Receipt";
            RecUsage::"P.Ret.Shpt.":
                ReportId := Report::"Purchase - Return Shipment";
            RecUsage::"P.Test":
                ReportId := Report::"Purchase Document - Test";
            RecUsage::"B.Stmt":
                ReportId := Report::"Bank Account Statement";
            RecUsage::"B.Recon.Test":
                ReportId := Report::"Bank Acc. Recon. - Test";
            RecUsage::"B.Check":
                ReportId := Report::Check;
            RecUsage::Reminder:
                ReportId := Report::Reminder;
            RecUsage::"Fin.Charge":
                ReportId := Report::"Finance Charge Memo";
            RecUsage::"Rem.Test":
                ReportId := Report::"Reminder - Test";
            RecUsage::"F.C.Test":
                ReportId := Report::"Finance Charge Memo - Test";
            RecUsage::Inv1:
                ReportId := Report::"Transfer Order";
            RecUsage::Inv2:
                ReportId := Report::"Transfer Shipment";
            RecUsage::Inv3:
                ReportId := Report::"Transfer Receipt";
            RecUsage::"Invt.Period Test":
                ReportId := Report::"Close Inventory Period - Test";
            RecUsage::"Prod.Order":
                ReportId := Report::"Prod. Order - Job Card";
            RecUsage::M1:
                ReportId := Report::"Prod. Order - Job Card";
            RecUsage::M2:
                ReportId := Report::"Prod. Order - Mat. Requisition";
            RecUsage::M3:
                ReportId := Report::"Prod. Order - Shortage List";
            RecUsage::"SM.Quote":
                ReportId := Report::"Service Quote";
            RecUsage::"SM.Order":
                ReportId := Report::"Service Order";
            RecUsage::"SM.Invoice":
                ReportId := Report::"Service - Invoice";
            RecUsage::"SM.Credit Memo":
                ReportId := Report::"Service - Credit Memo";
            RecUsage::"SM.Shipment":
                ReportId := Report::"Service - Shipment";
            RecUsage::"SM.Contract Quote":
                ReportId := Report::"Service Contract Quote";
            RecUsage::"SM.Contract":
                ReportId := Report::"Service Contract";
            RecUsage::"SM.Test":
                ReportId := Report::"Service Document - Test";
            RecUsage::"SM.Item Worksheet":
                ReportId := Report::"Service Item Worksheet";
            RecUsage::"Asm.Order":
                ReportId := Report::"Assembly Order";
            RecUsage::"P.Asm.Order":
                ReportId := Report::"Posted Assembly Order";
            RecUsage::"S.Test Prepmt.":
                ReportId := Report::"Sales Prepmt. Document Test";
            RecUsage::"P.Test Prepmt.":
                ReportId := Report::"Purchase Prepmt. Doc. - Test";
            RecUsage::"S.Arch.Quote":
                ReportId := Report::"Archived Sales Quote";
            RecUsage::"S.Arch.Order":
                ReportId := Report::"Archived Sales Order";
            RecUsage::"P.Arch.Quote":
                ReportId := Report::"Archived Purchase Quote";
            RecUsage::"P.Arch.Order":
                ReportId := Report::"Archived Purchase Order";
            RecUsage::"P.Arch.Return":
                ReportId := Report::"Arch.Purch. Return Order";
            RecUsage::"S.Arch.Return":
                ReportId := Report::"Arch. Sales Return Order";
            RecUsage::"S.Order Pick Instruction":
                ReportId := Report::"Pick Instruction";
            RecUsage::"C.Statement":
                ReportId := Report::"Standard Statement";
        end;

        OnAfterGetReportId(RecUsage, Sequence, ReportId);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetReportId(RecUsage: Enum "Report Selection Usage"; Sequence: Text; var ReportId: Integer)
    begin
    end;
}

