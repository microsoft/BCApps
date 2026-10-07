codeunit 103027 WMUtil
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure CreateWhseRcptFromPurchOrder(PurchHeader: Record "Purchase Header")
    var
        WhseRqst: Record "Warehouse Request";
        GetSourceDocuments: Report "Get Source Documents";
    begin
        PurchHeader.TestField(Status, PurchHeader.Status::Released);
        WhseRqst.SetRange(Type, WhseRqst.Type::Inbound);
        WhseRqst.SetRange("Source Type", DATABASE::"Purchase Line");
        WhseRqst.SetRange("Source Subtype", PurchHeader."Document Type");
        WhseRqst.SetRange("Source No.", PurchHeader."No.");
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);

        if WhseRqst.FindFirst() then begin
            GetSourceDocuments.SetHideDialog(true);
            GetSourceDocuments.UseRequestPage(false);
            GetSourceDocuments.SetTableView(WhseRqst);
            GetSourceDocuments.Run();
        end;
    end;

    [Scope('OnPrem')]
    procedure PostWhseRcpt(WhseRcptNo: Code[20])
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhsePostReceipt: Codeunit "Whse.-Post Receipt";
    begin
        WhseRcptLine.SetRange("No.", WhseRcptNo);
        WhseRcptLine.FindFirst();
        WhsePostReceipt.Run(WhseRcptLine);
    end;

    [Scope('OnPrem')]
    procedure PostWhsePutAway()
    var
        WhseActivLine: Record "Warehouse Activity Line";
        WhseActRegister: Codeunit "Whse.-Activity-Register";
    begin
        WhseActRegister.Run(WhseActivLine);
    end;

    [Scope('OnPrem')]
    procedure CreateWhseAssignFromSalesOrder(SalesHeader: Record "Sales Header")
    var
        WhseRqst: Record "Warehouse Request";
        GetSourceDocuments: Report "Get Source Documents";
    begin
        SalesHeader.TestField(Status, SalesHeader.Status::Released);
        WhseRqst.SetRange(Type, WhseRqst.Type::Outbound);
        WhseRqst.SetRange("Source Type", DATABASE::"Sales Line");
        WhseRqst.SetRange("Source Subtype", SalesHeader."Document Type");
        WhseRqst.SetRange("Source No.", SalesHeader."No.");
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);

        if WhseRqst.FindFirst() then begin
            GetSourceDocuments.SetHideDialog(true);
            GetSourceDocuments.UseRequestPage(false);
            GetSourceDocuments.SetTableView(WhseRqst);
            GetSourceDocuments.Run();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateWhsePick()
    var
        WhseActivLine: Record "Warehouse Activity Line";
        WhseActRegister: Codeunit "Whse.-Activity-Register";
    begin
        WhseActRegister.Run(WhseActivLine);
    end;

    [Scope('OnPrem')]
    procedure PostWhseShip()
    var
        WhseActivLine: Record "Warehouse Activity Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
        WhseActRegister: Codeunit "Whse.-Activity-Register";
    begin
        // remember to set filters
        WhseActRegister.Run(WhseActivLine);
        WhsePostShipment.Run(WhseShptLine);
    end;
}

