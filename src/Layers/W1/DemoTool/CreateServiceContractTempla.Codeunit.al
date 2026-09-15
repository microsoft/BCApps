codeunit 117069 "Create Service Contract Templa"
{

    trigger OnRun()
    begin
        InsertData(
          XTEMPL0001, XPrepaidContractdashHardware, ServiceContractTemplate."Invoice Period"::Month, 0, true, true,
          '', '', 12, true, '<3M>', false, false, XSMdashCNTTEMP, XHARDWARE);
        InsertData(
          XTEMPL0002, XNonPrpaidCntrctdashHardware, ServiceContractTemplate."Invoice Period"::Month, 0, true, false,
          '', '', 12, true, '<1M-1D>', true, false, XSMdashCNTTEMP, XHARDWARE);
        InsertData(
          XTEMPL0003, XPrepaidContractdashSoftware, ServiceContractTemplate."Invoice Period"::Month, 0, true, true,
          '', '', 12, true, '<3M>', false, false, XSMdashCNTTEMP, XSOFTWARE);
        InsertData(
          XTEMPL0004, XNonPrpaidCntrctdashSoftware, ServiceContractTemplate."Invoice Period"::Month, 0, true, false,
          '', '', 12, true, '<1M-1D>', true, false, XSMdashCNTTEMP, XSOFTWARE);
    end;

    var
        ServiceContractTemplate: Record "Service Contract Template";
        XTEMPL0001: Label 'TEMPL0001';
        XTEMPL0002: Label 'TEMPL0002';
        XTEMPL0003: Label 'TEMPL0003';
        XTEMPL0004: Label 'TEMPL0004';
        XPrepaidContractdashHardware: Label 'Prepaid Contract - Hardware';
        XSMdashCNTTEMP: Label 'SM-CNTTEMP';
        XHARDWARE: Label 'HARDWARE';
        XNonPrpaidCntrctdashHardware: Label 'Non-Prepaid Contract - Hardware';
        XPrepaidContractdashSoftware: Label 'Prepaid Contract - Software';
        XNonPrpaidCntrctdashSoftware: Label 'Non-Prepaid Contract - Software';
        XSOFTWARE: Label 'SOFTWARE';

    procedure InsertData("No.": Text[250]; Description: Text[250]; "Invoice Period": Option; "Max. Labor Unit Price": Decimal; "Combine Invoices": Boolean; Prepaid: Boolean; "Service Zone Code": Text[250]; "Language Code": Text[250]; "Default Response Time (Hours)": Decimal; "Contract Lines on Invoice": Boolean; "Default Service Period": Text[250]; "Invoice after Service": Boolean; "Allow Unbalanced Amounts": Boolean; "No. Series": Text[250]; "Serv. Contract Acc. Gr. Code": Text[250])
    var
        ServiceContractTemplate: Record "Service Contract Template";
    begin
        ServiceContractTemplate.Init();
        ServiceContractTemplate.Validate("No.", "No.");
        ServiceContractTemplate.Validate(Description, Description);
        ServiceContractTemplate.Validate("Invoice Period", "Invoice Period");
        ServiceContractTemplate.Validate("Max. Labor Unit Price", "Max. Labor Unit Price");
        ServiceContractTemplate.Validate("Combine Invoices", "Combine Invoices");
        ServiceContractTemplate.Validate(Prepaid, Prepaid);
        ServiceContractTemplate.Validate("Service Zone Code", "Service Zone Code");
        ServiceContractTemplate.Validate("Language Code", "Language Code");
        ServiceContractTemplate.Validate("Default Response Time (Hours)", "Default Response Time (Hours)");
        ServiceContractTemplate.Validate("Contract Lines on Invoice", "Contract Lines on Invoice");
        Evaluate(ServiceContractTemplate."Default Service Period", "Default Service Period");
        ServiceContractTemplate.Validate("Default Service Period");
        ServiceContractTemplate.Validate("Allow Unbalanced Amounts", "Allow Unbalanced Amounts");
        ServiceContractTemplate.Validate("Invoice after Service", "Invoice after Service");
        ServiceContractTemplate.Validate("No. Series", "No. Series");
        ServiceContractTemplate.Validate("Serv. Contract Acc. Gr. Code", "Serv. Contract Acc. Gr. Code");
        ServiceContractTemplate.Insert(true);
    end;
}

