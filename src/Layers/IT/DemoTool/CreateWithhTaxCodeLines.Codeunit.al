codeunit 161305 "Create Withh. Tax Code Lines"
{

    trigger OnRun()
    begin
        InsertData(XxADMINISTRATORS, (19000101D), 20, 50);
        InsertData(XxCOLLCOORD, (19000101D), 20, 100);
        InsertData(XxOCCAS, (19000101D), 20, 100);
        InsertData(XxPROFESS, (19000101D), 20, 100);
        InsertData(XxPROFFINPS, (19000101D), 20, 100);
        InsertData(XSoleAgComm20PERC, (19000101D), 20, 20);
        InsertData(XSoleAgComm50PERC, (19000101D), 20, 50);
        InsertData(XAgentComm20PERC, (19000101D), 20, 20);
        InsertData(XAgentComm50PERC, (19000101D), 20, 50);
    end;

    var
        XxADMINISTRATORS: Label 'ADMINISTRATORS';
        XxCOLLCOORD: Label 'COLL COORD';
        XxOCCAS: Label 'OCCAS';
        XxPROFESS: Label 'PROFESS';
        XxPROFFINPS: Label 'PROFF INPS';
        XSoleAgComm20PERC: Label 'SOLE AG. COMM. - 20%';
        XSoleAgComm50PERC: Label 'SOLE AG. COMM. - 50%';
        XAgentComm20PERC: Label 'AGENT COMM. - 20%';
        XAgentComm50PERC: Label 'AGENT COMM. - 50%';
        CA: Codeunit "Make Adjustments";

    procedure InsertData("Withhold Code": Code[20]; "Starting Date": Date; "Withholding Tax %": Decimal; "Taxable Base %": Decimal)
    var
        "Withhold Code Line": Record "Withhold Code Line";
    begin
        "Withhold Code Line".Init();
        "Withhold Code Line".Validate("Withhold Code", "Withhold Code");
        "Withhold Code Line".Validate("Starting Date", CA.AdjustDate("Starting Date"));
        "Withhold Code Line".Validate("Withholding Tax %", "Withholding Tax %");
        "Withhold Code Line".Validate("Taxable Base %", "Taxable Base %");
        "Withhold Code Line".Insert();
    end;
}

