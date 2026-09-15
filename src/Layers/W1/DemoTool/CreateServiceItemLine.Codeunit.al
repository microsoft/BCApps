codeunit 117002 "Create Service Item Line"
{

    trigger OnRun()
    begin
        InsertData(ServiceItemLine."Document Type"::Order, XSO000001, 10000, '7', XFINISHED, '7', '5', '753', 'A', 8, 19030109D, 132150T, 19030106D, 143017T,
  19030106D, 153031T, '', '');
        InsertData(ServiceItemLine."Document Type"::Order, XSO000002, 10000, '', XINPROCESS, '', '', '', '', 12, 19030111D, 110000T, 19040521D, 174712T, 0D,
          0T, '', '');
    end;

    var
        ServiceItemLine: Record "Service Item Line";
        XSO000001: Label 'SO000001';
        XSO000002: Label 'SO000002';
        XFINISHED: Label 'FINISHED';
        XINPROCESS: Label 'IN PROCESS';
        MakeAdjustments: Codeunit "Make Adjustments";

    procedure InsertData("Document Type": Enum "Service Document Type"; "Document No.": Text[250]; "Line No.": Integer; "Service Item No.": Text[250]; "Repair Status Code": Text[250]; "Fault Area Code": Text[250]; "Symptom Code": Text[250]; "Fault Code": Text[250]; "Resolution Code": Text[250]; "Response Time (Hours)": Decimal; "Response Date": Date; "Response Time": Time; "Starting Date": Date; "Starting Time": Time; "Finishing Date": Date; "Finishing Time": Time; "Ship-to Code": Text[250]; "Customer No.": Text[250])
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceItemLine.Init();

        ServiceItemLine.SetHideDialogBox(true);

        ServiceItemLine.Validate("Document Type", "Document Type");
        ServiceItemLine.Validate("Document No.", "Document No.");
        ServiceItemLine.Validate("Line No.", "Line No.");
        ServiceItemLine.SetUpNewLine();
        ServiceItemLine.Insert(true);

        ServiceItemLine.Validate("Service Item No.", "Service Item No.");
        ServiceItemLine.Validate("Repair Status Code", "Repair Status Code");
        ServiceItemLine.Validate("Fault Area Code", "Fault Area Code");
        ServiceItemLine.Validate("Symptom Code", "Symptom Code");
        ServiceItemLine.Validate("Fault Code", "Fault Code");
        ServiceItemLine.Validate("Resolution Code", "Resolution Code");
        ServiceItemLine.Validate("Response Time (Hours)", "Response Time (Hours)");
        ServiceItemLine.Validate("Response Date", MakeAdjustments.AdjustDate("Response Date"));
        ServiceItemLine.Validate("Response Time", "Response Time");
        ServiceItemLine."Starting Date" := MakeAdjustments.AdjustDate("Starting Date");
        ServiceItemLine."Starting Time" := "Starting Time";
        ServiceItemLine."Finishing Date" := MakeAdjustments.AdjustDate("Finishing Date");
        ServiceItemLine."Finishing Time" := "Finishing Time";
        ServiceItemLine.Validate("Ship-to Code", "Ship-to Code");
        ServiceItemLine.Validate("Customer No.", "Customer No.");
        if ServiceItemLine."Service Item No." = '' then
            ServiceItemLine.Validate("Item No.", '80005');
        ServiceItemLine.Modify(true);
    end;
}

