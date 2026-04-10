codeunit 117001 "Create Service Header"
{

    trigger OnRun()
    begin
        InsertData(ServiceHeader."Document Type"::Order, XSO000001, ServiceHeader.Priority::High, '10000', '', '10000', '', '', 19030106D, 142150T, 0D, 19030106D,
            143017T, 19030106D, 143031T);
        InsertData(ServiceHeader."Document Type"::Order, XSO000002, ServiceHeader.Priority::Low, '50000', '', '50000', '', '', 19030109D, 174712T, 0D, 19040521D,
            174712T, 0D, 0T);
    end;

    var
        ServiceHeader: Record "Service Header";
        XSO000001: Label 'SO000001';
        XSO000002: Label 'SO000002';
        MakeAdjustments: Codeunit "Make Adjustments";

    procedure InsertData("Document Type": Enum "Service Document Type"; "No.": Text[20]; Priority: Enum "Service Priority"; "Customer No.": Text[250]; "Responsibility Center": Text[250]; "Bill-to Customer No.": Text[250]; "Job No.": Text[250]; "Ship-to Code": Text[250]; "Order Date": Date; "Order Time": Time; "Expected Finishing Date": Date; "Starting Date": Date; "Starting Time": Time; "Finishing Date": Date; "Finishing Time": Time)
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Init();

        ServiceHeader.SetHideValidationDialog(true);

        ServiceHeader."Document Type" := "Document Type";
        ServiceHeader."No." := "No.";
        ServiceHeader.Insert(true);

        ServiceHeader.Validate(Priority, Priority);
        ServiceHeader.Validate("Customer No.", "Customer No.");
        ServiceHeader.Validate("Responsibility Center", "Responsibility Center");
        ServiceHeader.Validate("Bill-to Customer No.", "Bill-to Customer No.");
        ServiceHeader.Validate("Ship-to Code", "Ship-to Code");
        ServiceHeader.Validate("Order Date", MakeAdjustments.AdjustDate("Order Date"));
        ServiceHeader.Validate("Order Time", "Order Time");
        ServiceHeader.Validate("Expected Finishing Date", MakeAdjustments.AdjustDate("Expected Finishing Date"));
        ServiceHeader.Validate("Starting Date", MakeAdjustments.AdjustDate("Starting Date"));
        if "Starting Time" <> 0T then
            ServiceHeader.Validate("Starting Time", "Starting Time");
        ServiceHeader.Validate("Finishing Date", MakeAdjustments.AdjustDate("Finishing Date"));
        if "Finishing Time" <> 0T then
            ServiceHeader.Validate("Finishing Time", "Finishing Time");
        ServiceHeader.Modify(true);
    end;
}

