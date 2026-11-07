codeunit 101050 "Create Accounting Period"
{

    trigger OnRun()
    begin
        InsertData(CA.AdjustDate(19010101D), CA.AdjustDate(19041201D));
    end;

    var
        "Accounting Period": Record "Accounting Period";
        CA: Codeunit "Make Adjustments";

    procedure InsertData("Starting Date": Date; "Ending Date": Date)
    begin
        while "Starting Date" <= "Ending Date" do begin
            "Accounting Period".Init();
            "Accounting Period".Validate("Starting Date", "Starting Date");
            if (Date2DMY("Starting Date", 1) = 1) and
               (Date2DMY("Starting Date", 2) = 1)
            then begin
                "Accounting Period"."New Fiscal Year" := true;
                "Accounting Period"."Average Cost Calc. Type" := "Accounting Period"."Average Cost Calc. Type"::"Item & Location & Variant";
                "Accounting Period"."Average Cost Period" := "Accounting Period"."Average Cost Period"::Day;
                if "Starting Date" = CA.AdjustDate(19010101D) then
                    "Accounting Period"."Date Locked" := true;
                if "Starting Date" = CA.AdjustDate(19020101D) then
                    "Accounting Period"."Date Locked" := true;
            end;
            "Accounting Period".Insert();
            "Starting Date" := CalcDate('<1M>', "Starting Date");
        end;
    end;
}

