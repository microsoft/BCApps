codeunit 101579 "Create Marketing Setup"
{

    trigger OnRun()
    begin
        InsertBasisData();
        MarketingSetup.Get();
        MarketingSetup.Validate("Default Salesperson Code", '');
        MarketingSetup.Validate("Default Territory Code", '');
        MarketingSetup.Validate("Default Country/Region Code", '');
        MarketingSetup.Validate("Default Language Code", '');
        MarketingSetup.Validate("Default Sales Cycle Code", '');
        MarketingSetup.Validate("Def. Company Salutation Code", XCOMPANY);
        MarketingSetup.Validate("Default Person Salutation Code", XUNISEX);
        MarketingSetup.Validate("Attachment Storage Type", MarketingSetup."Attachment Storage Type"::Embedded);
        MarketingSetup.Validate("Attachment Storage Location", '');
        MarketingSetup.Validate("Autosearch for Duplicates", false);
        MarketingSetup.Validate("Search Hit %", 60);
        MarketingSetup.Validate("Maintain Dupl. Search Strings", true);
        MarketingSetup.Modify();
    end;

    var
        MarketingSetup: Record "Marketing Setup";
        CreateNoSeries: Codeunit "Create No. Series";
        XCUST: Label 'CUST';
        XVEND: Label 'VEND';
        XBANK: Label 'BANK';
        XCOMPANY: Label 'COMPANY';
        XUNISEX: Label 'UNISEX';
        XCONT: Label 'CONT';
        XContact: Label 'Contact';
        XCT000001: Label 'CT000001';
        XCT100000: Label 'CT100000';
        XCAMP: Label 'CAMP';
        XCampaign: Label 'Campaign';
        XCP0001: Label 'CP0001';
        XCP9999: Label 'CP9999';
        XSEGM: Label 'SEGM';
        XSegment: Label 'Segment';
        XSM00001: Label 'SM00001';
        XSM99999: Label 'SM99999';
        XTASK: Label 'TASK', Comment = 'Translate as Task';
        XTaskDescr: Label 'Task';
        XTD000001: Label 'TD000001';
        XTD999999: Label 'TD999999';
        XOPP: Label 'OPP';
        XOpportunity: Label 'Opportunity';
        XOP000001: Label 'OP000001';
        XOP999999: Label 'OP999999';
        XENU: Label 'ENU';
        XNEW: Label 'NEW';
        XEmp: Label 'EMP';

    procedure InsertMiniAppData()
    begin
        InsertBasisData();
        MarketingSetup.Get();
        MarketingSetup.Validate("Default Language Code", XENU);
        MarketingSetup.Validate("Default Correspondence Type", MarketingSetup."Default Correspondence Type"::Email);
        MarketingSetup.Validate("Default Sales Cycle Code", XNEW);
        MarketingSetup.Validate("Mergefield Language ID", 1033);
        MarketingSetup.Validate("Autosearch for Duplicates", true);
        MarketingSetup.Modify();
    end;

    local procedure InsertBasisData()
    begin
        MarketingSetup.Get();
        MarketingSetup.Validate("Bus. Rel. Code for Customers", XCUST);
        MarketingSetup.Validate("Bus. Rel. Code for Vendors", XVEND);
        MarketingSetup.Validate("Bus. Rel. Code for Bank Accs.", XBANK);
        MarketingSetup.Validate("Inherit Salesperson Code", true);
        MarketingSetup.Validate("Inherit Territory Code", true);
        MarketingSetup.Validate("Inherit Country/Region Code", true);
        MarketingSetup.Validate("Inherit Language Code", true);
        MarketingSetup.Validate("Inherit Address Details", true);
        MarketingSetup.Validate("Inherit Communication Details", true);
        CreateNoSeries.InitBaseSeries(MarketingSetup."Contact Nos.", XCONT, XContact, XCT000001, XCT100000, '', '', 1);
        CreateNoSeries.InitBaseSeries(MarketingSetup."Campaign Nos.", XCAMP, XCampaign, XCP0001, XCP9999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        CreateNoSeries.InitBaseSeries(MarketingSetup."Segment Nos.", XSEGM, XSegment, XSM00001, XSM99999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        CreateNoSeries.InitBaseSeries(MarketingSetup."To-do Nos.", XTASK, XTaskDescr, XTD000001, XTD999999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        CreateNoSeries.InitBaseSeries(MarketingSetup."Opportunity Nos.", XOPP, XOpportunity, XOP000001, XOP999999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        MarketingSetup.Validate("Bus. Rel. Code for Employees", XEmp);
        MarketingSetup.Modify();
    end;

    procedure CreateEvaluationData()
    begin
        MarketingSetup.Get();
        MarketingSetup.Validate("Attachment Storage Type", MarketingSetup."Attachment Storage Type"::Embedded);
        MarketingSetup.Validate("Search Hit %", 60);
        MarketingSetup.Validate("Maintain Dupl. Search Strings", true);
        MarketingSetup.Validate("Def. Company Salutation Code", XCOMPANY);
        MarketingSetup.Validate("Default Person Salutation Code", XUNISEX);
        MarketingSetup.Modify();
    end;
}

