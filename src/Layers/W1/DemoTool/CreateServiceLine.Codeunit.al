codeunit 117003 "Create Service Line"
{

    trigger OnRun()
    begin
        InsertData(ServiceLine."Document Type"::Order, XSO000001, 10000, 10000, '7', 'AS764789', ServiceLine.Type::Item, '80202', '', false, 1, 1, 45, true, 0,
  ServiceLine."Price Adjmt. Status"::" ");
        InsertData(ServiceLine."Document Type"::Order, XSO000001, 20000, 10000, '7', 'AS764789', ServiceLine.Type::Resource, XKatherine, '', false, 4, 4, 0, true, 0,
          ServiceLine."Price Adjmt. Status"::" ");
        InsertData(ServiceLine."Document Type"::Order, XSO000002, 10000, 10000, '', '', ServiceLine.Type::Resource, XMarty, '', false, 2, 2, 54, false, 0,
          ServiceLine."Price Adjmt. Status"::" ");
        InsertData(ServiceLine."Document Type"::Order, XSO000002, 20000, 10000, '', '', ServiceLine.Type::Item, '80022', '', false, 1, 1, 180, false, 0, ServiceLine."Price Adjmt. Status"
          ::" ");
    end;

    var
        ServiceLine: Record "Service Line";
        DemoDataSetup: Record "Demo Data Setup";
        XSO000001: Label 'SO000001';
        XSO000002: Label 'SO000002';
        XKatherine: Label 'Katherine';
        XMarty: Label 'Marty';

    procedure InsertData("Document Type": Enum "Service Document Type"; "Document No.": Text[250]; "Line No.": Integer; "Service Item Line No.": Integer; "Service Item No.": Text[250]; "Service Item Serial No.": Text[250]; Type: Enum "Service Line Type"; "No.": Text[250]; "Variant Code": Text[250]; Posted: Boolean; Quantity: Decimal; "Chargeable Qty.": Decimal; "Unit Price": Decimal; Chargeable: Boolean; "Apply to Service Entry": Integer; "Price Adjmt. Status": Option)
    var
        ServiceLine: Record "Service Line";
    begin
        DemoDataSetup.Get();

        ServiceLine.Init();

        ServiceLine.SetHideReplacementDialog(true);

        ServiceLine.Validate("Document Type", "Document Type");
        ServiceLine.Validate("Document No.", "Document No.");
        ServiceLine.Validate("Line No.", "Line No.");
        ServiceLine.Insert(true);

        ServiceLine.Validate("Service Item Line No.", "Service Item Line No.");
        ServiceLine.Validate("Service Item No.", "Service Item No.");
        ServiceLine.Validate("Service Item Serial No.", "Service Item Serial No.");
        ServiceLine.Validate(Type, Type);
        ServiceLine.Validate("No.", "No.");
        ServiceLine.Validate("Variant Code", "Variant Code");

        // MIM
        // ::june 1st 2005
        // ::change the logic here
        // ServiceInvoiceLine.VALIDATE(Posted,Posted);

        ServiceLine.Validate(Quantity, Quantity);

        // MIM
        // ::june 1st 2005
        // ::change the logic here
        // ServiceInvoiceLine.VALIDATE("Chargeable Qty.","Chargeable Qty.");

        ServiceLine."Unit Price" :=
          Round(
            "Unit Price" * DemoDataSetup."Local Currency Factor",
            1 * DemoDataSetup."Local Precision Factor");
        ServiceLine.Validate("Unit Price");

        // MIM
        // ::june 1st 2005
        // ::change the logic here
        // ServiceInvoiceLine.VALIDATE(Chargeable,Chargeable);

        ServiceLine.Validate("Appl.-to Service Entry", "Apply to Service Entry");
        ServiceLine.Validate("Price Adjmt. Status", "Price Adjmt. Status");
        ServiceLine.Modify(true);
    end;
}

