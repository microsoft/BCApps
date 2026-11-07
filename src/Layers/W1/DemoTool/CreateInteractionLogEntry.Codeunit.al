codeunit 101565 "Create Interaction Log Entry"
{

    trigger OnRun()
    begin
        if "Sales Shipment Header".Find('-') then
            repeat
                SegManagement.LogDocument(
                  5, "Sales Shipment Header"."No.", 0, 0, DATABASE::Customer, "Sales Shipment Header"."Bill-to Customer No.", "Sales Shipment Header"."Salesperson Code",
                  "Sales Shipment Header"."Campaign No.", "Sales Shipment Header"."Posting Description", '');
                InteractionLogEntry.FindLast();
                InteractionLogEntry.Date := "Sales Shipment Header"."Posting Date";
                InteractionLogEntry.Modify();
            until "Sales Shipment Header".Next() = 0;

        if "Sales Invoice Header".Find('-') then
            repeat
                SegManagement.LogDocument(
                  4, "Sales Invoice Header"."No.", 0, 0, DATABASE::Customer, "Sales Invoice Header"."Bill-to Customer No.", "Sales Invoice Header"."Salesperson Code",
                  "Sales Invoice Header"."Campaign No.", "Sales Invoice Header"."Posting Description", '');
                InteractionLogEntry.FindLast();
                InteractionLogEntry.Date := "Sales Invoice Header"."Posting Date";
                InteractionLogEntry.Modify();
            until "Sales Invoice Header".Next() = 0;

        if "Sales Cr.Memo Header".Find('-') then
            repeat
                SegManagement.LogDocument(
                  6, "Sales Cr.Memo Header"."No.", 0, 0, DATABASE::Customer, "Sales Cr.Memo Header"."Bill-to Customer No.", "Sales Cr.Memo Header"."Salesperson Code",
                  "Sales Cr.Memo Header"."Campaign No.", "Sales Cr.Memo Header"."Posting Description", '');
                InteractionLogEntry.FindLast();
                InteractionLogEntry.Date := "Sales Cr.Memo Header"."Posting Date";
                InteractionLogEntry.Modify();
            until "Sales Cr.Memo Header".Next() = 0;

        if "Purch. Rcpt. Header".Find('-') then
            repeat
                SegManagement.LogDocument(
                  15, "Purch. Rcpt. Header"."No.", 0, 0, DATABASE::Vendor, "Purch. Rcpt. Header"."Buy-from Vendor No.", "Purch. Rcpt. Header"."Purchaser Code",
                  '', "Purch. Rcpt. Header"."Posting Description", '');
                InteractionLogEntry.FindLast();
                InteractionLogEntry.Date := "Purch. Rcpt. Header"."Posting Date";
                InteractionLogEntry.Modify();
            until "Purch. Rcpt. Header".Next() = 0;
    end;

    var
        "Sales Shipment Header": Record "Sales Shipment Header";
        "Sales Invoice Header": Record "Sales Invoice Header";
        "Sales Cr.Memo Header": Record "Sales Cr.Memo Header";
        "Purch. Rcpt. Header": Record "Purch. Rcpt. Header";
        InteractionLogEntry: Record "Interaction Log Entry";
        SegManagement: Codeunit SegManagement;
        StatementLbl: Label 'Statement ';

    procedure CreateEvaluationData()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        Contact: Record Contact;
        Customer: Record Customer;
    begin
        SalesHeader.SetRange("Document Type", "Sales Document Type"::Order);
        if SalesHeader.FindSet() then
            repeat
                SegManagement.LogDocument(
                    3, SalesHeader."No.", 0, 0, Database::Customer, SalesHeader."Bill-to Customer No.", SalesHeader."Salesperson Code",
                    SalesHeader."Campaign No.", SalesHeader."Posting Description", '');
                InteractionLogEntry.FindLast();
                InteractionLogEntry.Date := SalesHeader."Posting Date";
                InteractionLogEntry.Modify();
            until SalesHeader.Next() = 0;

        SalesHeader.SetRange("Document Type", "Sales Document Type"::Quote);
        if SalesHeader.FindSet() then
            repeat
                SegManagement.LogDocument(
                    1, SalesHeader."No.", SalesHeader."Doc. No. Occurrence", SalesHeader."No. of Archived Versions", Database::Contact, SalesHeader."Bill-to Contact No.",
                    SalesHeader."Salesperson Code", SalesHeader."Campaign No.", SalesHeader."Posting Description", SalesHeader."Opportunity No.");
                InteractionLogEntry.FindLast();
                InteractionLogEntry.Date := SalesHeader."Posting Date";
                InteractionLogEntry.Modify();
            until SalesHeader.Next() = 0;

        PurchaseHeader.SetRange("Document Type", "Purchase Document Type"::Order);
        if PurchaseHeader.FindSet() then
            repeat
                SegManagement.LogDocument(
                    13, PurchaseHeader."No.", 0, 0, Database::Vendor, PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Purchaser Code",
                    PurchaseHeader."Campaign No.", PurchaseHeader."Posting Description", '');
                InteractionLogEntry.FindLast();
                InteractionLogEntry.Date := PurchaseHeader."Posting Date";
                InteractionLogEntry.Modify();
            until PurchaseHeader.Next() = 0;

        if Contact.FindSet() then
            repeat
                SegManagement.LogDocument(17, '', 0, 0, Database::Contact, Contact."No.", '', '', '', '');
                InteractionLogEntry.FindLast();
                InteractionLogEntry.Date := WorkDate();
                InteractionLogEntry.Modify();
            until Contact.Next() = 0;

        if Customer.FindSet() then
            repeat
                SegManagement.LogDocument(
                      7, Format(Customer."Last Statement No."), 0, 0, Database::Customer, Customer."No.",
                      Customer."Salesperson Code", '', StatementLbl, '');
                InteractionLogEntry.FindLast();
                InteractionLogEntry.Date := WorkDate();
                InteractionLogEntry.Modify();
            until Customer.Next() = 0;
    end;
}

