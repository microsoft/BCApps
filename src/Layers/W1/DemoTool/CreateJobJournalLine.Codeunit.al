codeunit 101210 "Create Job Journal Line"
{

    trigger OnRun()
    begin
        InsertData(XDEERFIELD8WP, '1110', 19030115D, XW301, 0, XLina, XMeetingwiththeCustomer, 2, true);
        InsertData(XDEERFIELD8WP, '1120', 19030116D, XW301, 0, XLina, XSelectingFurnishings, 2, true);
        InsertData(XDEERFIELD8WP, '1130', 19030119D, XW301, 0, XLina, XMeetingApproval, 2.25, true);

        InsertData(XGUILDFORD10CR, '1110', 19030103D, XW101, 0, XLina, XMeetingwiththeCustomer, 4, true);
        InsertData(XGUILDFORD10CR, '1120', 19030108D, XW201, 0, XLina, XSpecifications, 10, true);
        InsertData(XGUILDFORD10CR, '1130', 19030112D, XW201, 0, XLina, XMeetingApproval, 3, true);

        InsertData(XGUILDFORD10CR, '1210', 19030103D, XW101, 1, '1920-S', '', 10, false);
        InsertData(XGUILDFORD10CR, '1210', 19030108D, XW201, 1, '1928-S', '', 10, false);
        InsertData(XGUILDFORD10CR, '1210', 19030112D, XW201, 1, '1964-S', '', 60, false);
        InsertData(XGUILDFORD10CR, '1210', 19030122D, XW401, 1, '1984-W', '', 10, false);

        InsertData(XGUILDFORD10CR, '1210', 19030122D, XW401, 0, XMarty, XDelivandAssembltheFurniture, 8, true);
        InsertData(XGUILDFORD10CR, '1210', 19030122D, XW401, 0, XLIFT, XLiftforFurniture, 8, true);
        InsertData(XGUILDFORD10CR, '1210', 19030123D, XW401, 0, XMarty, XDelivandAssembltheFurniture, 8, true);
        InsertData(XGUILDFORD10CR, '1210', 19030124D, XW401, 0, XMarty, XDelivandAssembltheFurniture, 8, true);
        InsertData(XGUILDFORD10CR, '1210', 19030125D, XW401, 0, XMarty, XDelivandAssembltheFurniture, 8, true);
        InsertData(XGUILDFORD10CR, '1210', 19030127D, XW401, 0, XMarty, XDelivandAssembltheFurniture, 8, true);
        InsertData(XGUILDFORD10CR, '1210', 19030129D, XW501, 0, XMarty, XDelivandAssembltheFurniture, 4, true);
        InsertData(XGUILDFORD10CR, '1210', 19030131D, XW501, 0, XMarty, XDelivandAssembltheFurniture, 3, true);
    end;

    var
        "Job Journal Batch": Record "Job Journal Batch";
        "Job Journal Line": Record "Job Journal Line";
        BlankJobJnlLine: Record "Job Journal Line";
        CA: Codeunit "Make Adjustments";
        "Line No.": Integer;
        XDEERFIELD8WP: Label 'DEERFIELD, 8 WP';
        XGUILDFORD10CR: Label 'GUILDFORD, 10 CR';
        XMeetingwiththeCustomer: Label 'Meeting with the Customer';
        XMeetingApproval: Label 'Meeting, Customer Approval';
        XSelectingFurnishings: Label 'Selecting Furnishings';
        XSpecifications: Label 'Specifications';
        XLina: Label 'Lina';
        XMarty: Label 'Marty';
        XLIFT: Label 'LIFT';
        XW101: Label 'W1-01';
        XW201: Label 'W2-01';
        XW301: Label 'W3-01';
        XW401: Label 'W4-01';
        XW501: Label 'W5-01';
        XDEFAULT: Label 'DEFAULT';
        XJOB: Label 'JOB';
        XDelivandAssembltheFurniture: Label 'Delivering and Assembling the Furniture';
        XLiftforFurniture: Label 'Lift for Furniture';

    procedure InsertData("Job No.": Code[20]; "Job Task": Code[20]; Date: Date; "Document No.": Code[20]; Type: Integer; "No.": Code[20]; Description: Text[50]; Quantity: Decimal; Chargeable: Boolean)
    begin
        Date := CA.AdjustDate(Date);
        InitJobJnlLine("Job Journal Line", XJOB, XDEFAULT);
        "Job Journal Line".Validate("Job No.", "Job No.");
        "Job Journal Line".Validate("Job Task No.", "Job Task");

        "Job Journal Line".Validate("Posting Date", Date);
        "Job Journal Line".Validate("Document No.", "Document No.");
        "Job Journal Line".Validate(Type, Type);
        "Job Journal Line".Validate("No.", "No.");
        if Description <> '' then
            "Job Journal Line".Validate(Description, Description);
        "Job Journal Line".Validate(Quantity, Quantity);
        "Job Journal Line".Validate(Chargeable, Chargeable);
        "Job Journal Line".Insert(true);
    end;

    procedure InitJobJnlLine(var "Job Journal Line": Record "Job Journal Line"; "Journal Template Name": Code[10]; "Journal Batch Name": Code[10])
    begin
        "Job Journal Line".Init();
        "Job Journal Line".Validate("Journal Template Name", "Journal Template Name");
        "Job Journal Line".Validate("Journal Batch Name", "Journal Batch Name");
        if ("Journal Template Name" <> "Job Journal Batch"."Journal Template Name") or
           ("Journal Batch Name" <> "Job Journal Batch".Name)
        then begin
            "Job Journal Batch".Get("Journal Template Name", "Journal Batch Name");
            if ("Job Journal Batch"."No. Series" <> '') or
               ("Job Journal Batch"."Posting No. Series" <> '')
            then begin
                "Job Journal Batch"."No. Series" := '';
                "Job Journal Batch"."Posting No. Series" := '';
                "Job Journal Batch".Modify();
            end;
        end;
        "Line No." := "Line No." + 10000;
        "Job Journal Line".Validate("Line No.", "Line No.");
        "Job Journal Line".SetUpNewLine(BlankJobJnlLine);
    end;
}

