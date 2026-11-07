codeunit 163406 "Create FA Doc. Sign. Setup"
{

    trigger OnRun()
    begin
        DemoSetup.Get();
        DefaultSignSetup.DeleteAll();

        // Sales Order
        InsertData(
          DATABASE::"Sales Header", SalesHeader."Document Type"::Order.AsInteger(), DocSign."Employee Type"::Accountant,
          '', '', '', 0D, false);

        InsertData(
          DATABASE::"Sales Header", SalesHeader."Document Type"::Order.AsInteger(), DocSign."Employee Type"::PassedBy,
          XTD, XGivenByCEO, XD + '-0037', 20070101D, true);

        InsertData(
          DATABASE::"Sales Header", SalesHeader."Document Type"::Order.AsInteger(), DocSign."Employee Type"::ReleasedBy,
          XTD, XGivenByCEO, XD + '-0037', 20070101D, true);

        InsertData(
          DATABASE::"Sales Header", SalesHeader."Document Type"::Order.AsInteger(), DocSign."Employee Type"::Responsible,
          XJO, XGivenByCEO, XD + '-0021', 20060715D, true);

        // Sales Invoice
        InsertData(
          DATABASE::"Sales Header", SalesHeader."Document Type"::Invoice.AsInteger(), DocSign."Employee Type"::Accountant,
          '', '', '', 0D, false);

        InsertData(
          DATABASE::"Sales Header", SalesHeader."Document Type"::Invoice.AsInteger(), DocSign."Employee Type"::PassedBy,
          XTD, XGivenByCEO, XD + '-0037', 20070101D, true);

        InsertData(
          DATABASE::"Sales Header", SalesHeader."Document Type"::Invoice.AsInteger(), DocSign."Employee Type"::ReleasedBy,
          XTD, XGivenByCEO, XD + '-0037', 20070101D, true);

        InsertData(
          DATABASE::"Sales Header", SalesHeader."Document Type"::Invoice.AsInteger(), DocSign."Employee Type"::Responsible,
          XJO, XGivenByCEO, XD + '-0021', 20060715D, true);

        // Sales Credit Memo
        InsertData(
          DATABASE::"Sales Header", SalesHeader."Document Type"::"Credit Memo".AsInteger(), DocSign."Employee Type"::Accountant,
          '', '', '', 0D, false);

        // Purchase Order
        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::Order.AsInteger(), DocSign."Employee Type"::ReleasedBy,
          XTD, '', '', 0D, true);

        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::Order.AsInteger(), DocSign."Employee Type"::ReceivedBy,
          XLT, XGivenByCEO, XD + '-0035', 20070201D, true);

        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::Order.AsInteger(), DocSign."Employee Type"::Responsible,
          XMH, XGivenByCEO, XD + '-0028', 20060815D, true);

        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::Order.AsInteger(), DocSign."Employee Type"::Chairman,
          XMH, '', '', 0D, true);

        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::Order.AsInteger(), DocSign."Employee Type"::Member1,
          XJO, '', '', 0D, false);

        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::Order.AsInteger(), DocSign."Employee Type"::Member2,
          XRB, '', '', 0D, false);

        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::Order.AsInteger(), DocSign."Employee Type"::Member3,
          XTD, '', '', 0D, false);

        // Purchase Invoice
        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::Invoice.AsInteger(), DocSign."Employee Type"::ReleasedBy,
          XTD, '', '', 0D, true);

        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::Invoice.AsInteger(), DocSign."Employee Type"::ReceivedBy,
          XLT, XGivenByCEO, XD + '-0035', 20070201D, true);

        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::Invoice.AsInteger(), DocSign."Employee Type"::Responsible,
          XMH, XGivenByCEO, XD + '-0028', 20060815D, true);

        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::Invoice.AsInteger(), DocSign."Employee Type"::Chairman,
          XMH, '', '', 0D, true);

        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::Invoice.AsInteger(), DocSign."Employee Type"::Member1,
          XJO, '', '', 0D, false);

        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::Invoice.AsInteger(), DocSign."Employee Type"::Member2,
          XRB, '', '', 0D, false);

        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::Invoice.AsInteger(), DocSign."Employee Type"::Member3,
          XTD, '', '', 0D, false);

        // Purchase Credit Memo
        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::"Credit Memo".AsInteger(), DocSign."Employee Type"::Responsible,
          XMH, XGivenByCEO, XD + '-0028', 20060815D, true);

        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::"Credit Memo".AsInteger(), DocSign."Employee Type"::Chairman,
          XMH, '', '', 0D, true);

        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::"Credit Memo".AsInteger(), DocSign."Employee Type"::Member1,
          XJO, '', '', 0D, false);

        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::"Credit Memo".AsInteger(), DocSign."Employee Type"::Member2,
          XRB, '', '', 0D, false);

        InsertData(
          DATABASE::"Purchase Header", PurchHeader."Document Type"::"Credit Memo".AsInteger(), DocSign."Employee Type"::Member3,
          XTD, '', '', 0D, false);

        // Transfer Header
        InsertData(
          DATABASE::"Transfer Header", 0, DocSign."Employee Type"::ReleasedBy, XTD, '', '', 0D, true);

        InsertData(
          DATABASE::"Transfer Header", 0, DocSign."Employee Type"::ReceivedBy,
          XLT, XGivenByCEO, XD + '-0035', 20070201D, true);

        // Item Receipt
        InsertData(
          DATABASE::"Invt. Document Header", InvtDocHeader."Document Type"::Receipt.AsInteger(), DocSign."Employee Type"::Responsible,
          XMH, XGivenByCEO, XD + '-0028', 20060815D, true);

        InsertData(
          DATABASE::"Invt. Document Header", InvtDocHeader."Document Type"::Receipt.AsInteger(), DocSign."Employee Type"::Chairman,
          XMH, '', '', 0D, true);

        InsertData(
          DATABASE::"Invt. Document Header", InvtDocHeader."Document Type"::Receipt.AsInteger(), DocSign."Employee Type"::Member1,
          XJO, '', '', 0D, false);

        InsertData(
          DATABASE::"Invt. Document Header", InvtDocHeader."Document Type"::Receipt.AsInteger(), DocSign."Employee Type"::Member2,
          XRB, '', '', 0D, false);

        InsertData(
          DATABASE::"Invt. Document Header", InvtDocHeader."Document Type"::Receipt.AsInteger(), DocSign."Employee Type"::Member3,
          XTD, '', '', 0D, false);

        // Item Shipment
        InsertData(
          DATABASE::"Invt. Document Header", InvtDocHeader."Document Type"::Shipment.AsInteger(), DocSign."Employee Type"::Responsible,
          XJO, XGivenByCEO, XD + '-0021', 20060715D, true);

        InsertData(
          DATABASE::"Invt. Document Header", InvtDocHeader."Document Type"::Shipment.AsInteger(), DocSign."Employee Type"::Director,
          '', '', '', 0D, false);

        // FA Release
        InsertData(
          DATABASE::"FA Document Header", FADocHeader."Document Type"::Release, DocSign."Employee Type"::ReceivedBy,
          XLT, XGivenByCEO, XD + '-0035', 20070201D, true);

        InsertData(
          DATABASE::"FA Document Header", FADocHeader."Document Type"::Release, DocSign."Employee Type"::Chairman,
          XMH, '', '', 0D, true);

        InsertData(
          DATABASE::"FA Document Header", FADocHeader."Document Type"::Release, DocSign."Employee Type"::Member1,
          XJO, '', '', 0D, false);

        InsertData(
          DATABASE::"FA Document Header", FADocHeader."Document Type"::Release, DocSign."Employee Type"::Member2,
          XRB, '', '', 0D, false);

        InsertData(
          DATABASE::"FA Document Header", FADocHeader."Document Type"::Release, DocSign."Employee Type"::Member3,
          XTD, '', '', 0D, false);

        // FA Movement
        InsertData(
          DATABASE::"FA Document Header", FADocHeader."Document Type"::Movement, DocSign."Employee Type"::ReleasedBy,
          XEH, XGivenByCEO, XD + '-0035', 20070201D, true);

        InsertData(
          DATABASE::"FA Document Header", FADocHeader."Document Type"::Movement, DocSign."Employee Type"::ReceivedBy,
          XLT, XGivenByCEO, XD + '-0029', 20070101D, true);

        InsertData(
          DATABASE::"FA Document Header", FADocHeader."Document Type"::Movement, DocSign."Employee Type"::Responsible,
          XMH, '', '', 0D, true);

        InsertData(
          DATABASE::"FA Document Header", FADocHeader."Document Type"::Movement, DocSign."Employee Type"::Chairman,
          XMH, '', '', 0D, true);

        InsertData(
          DATABASE::"FA Document Header", FADocHeader."Document Type"::Movement, DocSign."Employee Type"::Member1,
          XJO, '', '', 0D, false);

        InsertData(
          DATABASE::"FA Document Header", FADocHeader."Document Type"::Movement, DocSign."Employee Type"::Member2,
          XRB, '', '', 0D, false);

        InsertData(
          DATABASE::"FA Document Header", FADocHeader."Document Type"::Movement, DocSign."Employee Type"::Member3,
          XTD, '', '', 0D, false);

        // FA WriteOff
        InsertData(
          DATABASE::"FA Document Header", FADocHeader."Document Type"::Writeoff, DocSign."Employee Type"::Responsible,
          XMH, '', '', 0D, true);

        InsertData(
          DATABASE::"FA Document Header", FADocHeader."Document Type"::Writeoff, DocSign."Employee Type"::Chairman,
          XMH, '', '', 0D, true);

        InsertData(
          DATABASE::"FA Document Header", FADocHeader."Document Type"::Writeoff, DocSign."Employee Type"::Member1,
          XJO, '', '', 0D, false);

        InsertData(
          DATABASE::"FA Document Header", FADocHeader."Document Type"::Writeoff, DocSign."Employee Type"::Member2,
          XRB, '', '', 0D, false);

        InsertData(
          DATABASE::"FA Document Header", FADocHeader."Document Type"::Writeoff, DocSign."Employee Type"::Member3,
          XTD, '', '', 0D, false);
    end;

    var
        DefaultSignSetup: Record "Default Signature Setup";
        DocSignMgt: Codeunit "Doc. Signature Management";
        FADocHeader: Record "FA Document Header";
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        DocSign: Record "Document Signature";
        XD: Label 'D';
        InvtDocHeader: Record "Invt. Document Header";
        XEH: Label 'EH';
        XJO: Label 'JO';
        XLT: Label 'LT';
        XRB: Label 'RB';
        XMH: Label 'MH';
        XTD: Label 'TD';
        DemoSetup: Record "Demo Data Setup";
        XGivenByCEO: Label 'Given by CEO';

    procedure InsertData(TableID: Integer; DocType: Integer; EmpType: Option Director,Accountant,Cashier,ApprovedBy,ReleasedBy,ReceivedBy,PassedBy,RequestedBy,Chairman,Comm1,Comm2,Comm3,StoredBy; EmpNo: Code[20]; WarrantDesc: Text[30]; WarrantNo: Text[20]; WarrantDate: Date; Mandatory2: Boolean)
    begin
        if DemoSetup."Skip creation of master data" then begin
            EmpNo := '';
            WarrantDesc := '';
            WarrantNo := '';
            WarrantDate := 0D;
        end;

        DocSignMgt.InsertDefault(
          TableID, DocType, EmpType, EmpNo, WarrantDesc, WarrantNo, WarrantDate, Mandatory2);
    end;
}

