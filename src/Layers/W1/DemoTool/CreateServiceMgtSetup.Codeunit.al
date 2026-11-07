codeunit 117012 "Create Service Mgt. Setup"
{

    trigger OnRun()
    begin
        InsertData(
            '', ServiceMgtSetup."Fault Reporting Level"::"Fault+Symptom+Area (IRIS)",
            true, false, 100, 100, false, XSTART, true, '', '', '', '');
        ModifyData1(
          Xperson1, Xperson2, Xperson3, 16, 8, 2,
          ServiceMgtSetup."Next Service Calc. Method"::Planned, false, ServiceMgtSetup."Service Zones Option"::"Code Shown",
          false, false, ServiceMgtSetup."Resource Skills Option"::"Code Shown", false, false, false, 365, 0D, false);
        ModifyData2(
          false, 24, '<1Y>', XSMdashINV, XSMdashINVPLUS,
          XSMdashINVdashCON, XSMdashITEM, XSMdashORDER, XSMdashCONTRAC, XSMdashCNTTEMP, XSMdashTROUBLE, XSMdashPREPAID,
          XSMdashLOANER, XSERVICE, ServiceMgtSetup."Contract Value Calc. Method"::"Based on Unit Price", 15, XSMdashQUOTE);
        ModifyData3(XSERVICE, XSMdashCRdashCON, XSMdashCR, XSMdashCRPLUS, XSMdashSHIPPLUS,
          ServiceMgtSetup."Logo Position on Documents"::"No Logo", true, true, true);
    end;

    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        XSTART: Label 'START';
        XSMdashINV: Label 'SM-INV';
        XSMdashINVPLUS: Label 'SM-INV+';
        XSMdashINVdashCON: Label 'SM-INV-CON';
        XSMdashITEM: Label 'SM-ITEM';
        XSMdashORDER: Label 'SM-ORDER';
        XSMdashCONTRAC: Label 'SM-CONTRAC';
        XSMdashCNTTEMP: Label 'SM-CNTTEMP';
        XSMdashTROUBLE: Label 'SM-TROUBLE';
        XSMdashPREPAID: Label 'SM-PREPAID';
        XSMdashLOANER: Label 'SM-LOANER';
        XSERVICE: Label 'SERVICE';
        XSMdashQUOTE: Label 'SM-QUOTE';
        XSMdashCRdashCON: Label 'SM-CR-CON';
        XSMdashCR: Label 'SM-CR';
        XSMdashCRPLUS: Label 'SM-CR+';
        XSMdashSHIPPLUS: Label 'SM-SHIP+';
        Xperson1: Label 'david.alexander@cronus.com';
        Xperson2: Label 'steve.winfield@cronus.com';
        Xperson3: Label 'mickey.monaghan@cronus.com';

    procedure InsertData("Primary Key": Text[250]; "Fault Reporting Level": Option; "Link Service to Service Item": Boolean; "Salesperson Mandatory": Boolean; "Warranty Disc. % (Parts)": Decimal; "Warranty Disc. % (Labor)": Decimal; "Contract Rsp. Time Mandatory": Boolean; "Service Order Starting Fee": Text[250]; "Register Contract Changes": Boolean; "Contract Inv. Line Text Code": Text[250]; "Contract Line Inv. Text Code": Text[250]; "Contract Inv. Period Text Code": Text[250]; "Contract Credit Line Text Code": Text[250])
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Init();
        ServiceMgtSetup.Validate("Primary Key", "Primary Key");
        ServiceMgtSetup.Validate("Fault Reporting Level", "Fault Reporting Level");
        ServiceMgtSetup.Validate("Link Service to Service Item", "Link Service to Service Item");
        ServiceMgtSetup.Validate("Salesperson Mandatory", "Salesperson Mandatory");
        ServiceMgtSetup.Validate("Warranty Disc. % (Parts)", 0);
        ServiceMgtSetup.Validate("Warranty Disc. % (Labor)", 0);
        ServiceMgtSetup.Validate("Contract Rsp. Time Mandatory", "Contract Rsp. Time Mandatory");
        ServiceMgtSetup.Validate("Service Order Starting Fee", "Service Order Starting Fee");
        ServiceMgtSetup.Validate("Register Contract Changes", "Register Contract Changes");
        ServiceMgtSetup.Validate("Contract Inv. Line Text Code", "Contract Inv. Line Text Code");
        ServiceMgtSetup.Validate("Contract Line Inv. Text Code", "Contract Line Inv. Text Code");
        ServiceMgtSetup.Validate("Contract Inv. Period Text Code", "Contract Inv. Period Text Code");
        ServiceMgtSetup.Validate("Contract Credit Line Text Code", "Contract Credit Line Text Code");
        ServiceMgtSetup.Modify();
    end;

    procedure ModifyData1("Send First Warning To": Text[250]; "Send Second Warning To": Text[250]; "Send Third Warning To": Text[250]; "First Warning Within (Hours)": Decimal; "Second Warning Within (Hours)": Decimal; "Third Warning Within (Hours)": Decimal; "Next Service Calc. Method": Option; "Service Order Type Mandatory": Boolean; "Service Zones Option": Option; "Service Order Start Mandatory": Boolean; "Service Order Finish Mandatory": Boolean; "Resource Skills Option": Option; "One Service Item Line/Order": Boolean; "Unit of Measure Mandatory": Boolean; "Fault Reason Code Mandatory": Boolean; "Contract Serv. Ord.  Max. Days": Integer; "Last Contract Service Date": Date; "Work Type Code Mandatory": Boolean)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Send First Warning To", "Send First Warning To");
        ServiceMgtSetup.Validate("Send Second Warning To", "Send Second Warning To");
        ServiceMgtSetup.Validate("Send Third Warning To", "Send Third Warning To");
        ServiceMgtSetup.Validate("First Warning Within (Hours)", "First Warning Within (Hours)");
        ServiceMgtSetup.Validate("Second Warning Within (Hours)", "Second Warning Within (Hours)");
        ServiceMgtSetup.Validate("Third Warning Within (Hours)", "Third Warning Within (Hours)");
        ServiceMgtSetup.Validate("Next Service Calc. Method", "Next Service Calc. Method");
        ServiceMgtSetup.Validate("Service Order Type Mandatory", "Service Order Type Mandatory");
        ServiceMgtSetup.Validate("Service Zones Option", "Service Zones Option");
        ServiceMgtSetup.Validate("Service Order Start Mandatory", "Service Order Start Mandatory");
        ServiceMgtSetup.Validate("Service Order Finish Mandatory", "Service Order Finish Mandatory");
        ServiceMgtSetup.Validate("Resource Skills Option", "Resource Skills Option");
        ServiceMgtSetup.Validate("One Service Item Line/Order", "One Service Item Line/Order");
        ServiceMgtSetup.Validate("Unit of Measure Mandatory", "Unit of Measure Mandatory");
        ServiceMgtSetup.Validate("Fault Reason Code Mandatory", "Fault Reason Code Mandatory");
        ServiceMgtSetup.Validate("Contract Serv. Ord.  Max. Days", "Contract Serv. Ord.  Max. Days");
        ServiceMgtSetup.Validate("Last Contract Service Date", "Last Contract Service Date");
        ServiceMgtSetup.Validate("Work Type Code Mandatory", "Work Type Code Mandatory");
        ServiceMgtSetup.Modify();
    end;

    procedure ModifyData2("Use Contract Cancel Reason": Boolean; "Default Response Time (Hours)": Decimal; "Default Warranty Duration": Text[250]; "Service Invoice Nos.": Text[250]; "Posted Service Invoice Nos.": Text[250]; "Contract Invoice Nos.": Text[250]; "Service Item Nos.": Text[250]; "Service Order Nos.": Text[250]; "Service Contract Nos.": Text[250]; "Contract Template Nos.": Text[250]; "Troubleshooting Nos.": Text[250]; "Prepaid Posting Document Nos.": Text[250]; "Loaner Nos.": Text[250]; "Serv. Job Responsibility Code": Text[250]; "Contract Value Calc. Method": Option; "Contract Value %": Decimal; "Service Quote Nos.": Text[250])
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Use Contract Cancel Reason", "Use Contract Cancel Reason");
        ServiceMgtSetup.Validate("Default Response Time (Hours)", "Default Response Time (Hours)");
        Evaluate(ServiceMgtSetup."Default Warranty Duration", "Default Warranty Duration");
        ServiceMgtSetup.Validate("Default Warranty Duration");
        ServiceMgtSetup.Validate("Service Invoice Nos.", "Service Invoice Nos.");
        ServiceMgtSetup.Validate("Posted Service Invoice Nos.", "Posted Service Invoice Nos.");
        ServiceMgtSetup.Validate("Contract Invoice Nos.", "Contract Invoice Nos.");
        ServiceMgtSetup.Validate("Service Item Nos.", "Service Item Nos.");
        ServiceMgtSetup.Validate("Service Order Nos.", "Service Order Nos.");
        ServiceMgtSetup.Validate("Service Contract Nos.", "Service Contract Nos.");
        ServiceMgtSetup.Validate("Contract Template Nos.", "Contract Template Nos.");
        ServiceMgtSetup.Validate("Troubleshooting Nos.", "Troubleshooting Nos.");
        ServiceMgtSetup.Validate("Prepaid Posting Document Nos.", "Prepaid Posting Document Nos.");
        ServiceMgtSetup.Validate("Loaner Nos.", "Loaner Nos.");
        ServiceMgtSetup.Validate("Serv. Job Responsibility Code", "Serv. Job Responsibility Code");
        ServiceMgtSetup.Validate("Contract Value Calc. Method", "Contract Value Calc. Method");
        ServiceMgtSetup.Validate("Contract Value %", "Contract Value %");
        ServiceMgtSetup.Validate("Service Quote Nos.", "Service Quote Nos.");
        ServiceMgtSetup.Modify();
    end;

    procedure ModifyData3("Base Calendar Code": Text[250]; "Contract Credit Memo Nos.": Text[250]; "Service Credit Memo Nos.": Text[250]; "Posted Serv. Credit Memo Nos.": Text[250]; "Posted Service Shipment Nos.": Text[250]; "Logo Position on Documents": Option "No Logo",Left,Center,Right; "Shipment on Invoice": Boolean; "Copy Comments Order to Invoice": Boolean; "Copy Comments Order to Shpt.": Boolean)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Base Calendar Code", "Base Calendar Code");
        ServiceMgtSetup.Validate("Contract Credit Memo Nos.", "Contract Credit Memo Nos.");
        ServiceMgtSetup.Validate("Service Credit Memo Nos.", "Service Credit Memo Nos.");
        ServiceMgtSetup.Validate("Posted Serv. Credit Memo Nos.", "Posted Serv. Credit Memo Nos.");
        ServiceMgtSetup.Validate("Posted Service Shipment Nos.", "Posted Service Shipment Nos.");
        ServiceMgtSetup.Validate("Logo Position on Documents", "Logo Position on Documents");
        ServiceMgtSetup.Validate("Shipment on Invoice", "Shipment on Invoice");
        ServiceMgtSetup.Validate("Copy Comments Order to Invoice", "Copy Comments Order to Invoice");
        ServiceMgtSetup.Validate("Copy Comments Order to Shpt.", "Copy Comments Order to Shpt.");
        ServiceMgtSetup.Modify();
    end;
}

