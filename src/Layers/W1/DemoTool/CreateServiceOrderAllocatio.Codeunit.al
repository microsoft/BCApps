codeunit 117051 "Create Service Order Allocatio"
{

    trigger OnRun()
    begin
        InsertData(1, ServiceOrderAllocation.Status::Active, XSO000001, 19030109D, XKatherine, '', 10000, 4, 0T, 0T, '', '', '7', false, 'AS764789', false, ServiceOrderAllocation."Document Type"::Order
  );
        InsertData(2, ServiceOrderAllocation.Status::Nonactive, XSO000002, 0D, '', '', 10000, 0, 0T, 0T, '', '', '', false, '', false, ServiceOrderAllocation."Document Type"::Order);
    end;

    var
        ServiceOrderAllocation: Record "Service Order Allocation";
        XSO000001: Label 'SO000001';
        XSO000002: Label 'SO000002';
        XKatherine: Label 'Katherine';
        MakeAdjustments: Codeunit "Make Adjustments";

    procedure InsertData("Entry No.": Integer; Status: Option; "Document No.": Text[250]; "Allocation Date": Date; "Resource No.": Text[250]; "Resource Group No.": Text[250]; "Service Item Line No.": Integer; "Allocated Hours": Decimal; "Starting Time": Time; "Finishing Time": Time; Description: Text[250]; "Reason Code": Text[250]; "Service Item No.": Text[250]; Posted: Boolean; "Service Item Serial No.": Text[250]; "Service Started": Boolean; "Document Type": Enum "Service Document Type")
    var
        ServiceOrderAllocation: Record "Service Order Allocation";
    begin
        ServiceOrderAllocation.Init();

        ServiceOrderAllocation.SetHideDialog(true);

        ServiceOrderAllocation.Validate("Entry No.", "Entry No.");
        ServiceOrderAllocation.Validate("Document Type", "Document Type");
        ServiceOrderAllocation.Validate("Document No.", "Document No.");
        ServiceOrderAllocation.Validate("Service Item Line No.", "Service Item Line No.");
        ServiceOrderAllocation.Insert(true);

        ServiceOrderAllocation.Validate(Status, Status);
        ServiceOrderAllocation."Allocation Date" := MakeAdjustments.AdjustDate("Allocation Date");
        ServiceOrderAllocation.Validate("Resource No.", "Resource No.");
        ServiceOrderAllocation.Validate("Resource Group No.", "Resource Group No.");
        ServiceOrderAllocation.Validate("Allocated Hours", "Allocated Hours");
        ServiceOrderAllocation.Validate("Starting Time", "Starting Time");
        ServiceOrderAllocation.Validate("Finishing Time", "Finishing Time");
        ServiceOrderAllocation.Validate(Description, Description);
        ServiceOrderAllocation.Validate("Reason Code", "Reason Code");
        ServiceOrderAllocation.Validate("Service Item No.", "Service Item No.");
        ServiceOrderAllocation.Validate(Posted, Posted);
        ServiceOrderAllocation.Validate("Service Item Serial No.", "Service Item Serial No.");
        ServiceOrderAllocation.Validate("Service Started", "Service Started");
        ServiceOrderAllocation.Modify(true);
    end;
}

