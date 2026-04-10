// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Setup;

using Microsoft.CRM.Setup;
using Microsoft.CRM.Team;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.NoSeries;
using Microsoft.Service.Archive;
using Microsoft.Service.Contract;
using Microsoft.Service.Pricing;
using Microsoft.Utilities;

table 5911 "Service Mgt. Setup"
{
    Caption = 'Service Mgt. Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "Service Mgt. Setup";
    LookupPageID = "Service Mgt. Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(4; "Fault Reporting Level"; Option)
        {
            Caption = 'Fault Reporting Level';
            ToolTip = 'Specifies the level of fault reporting that your company uses in service management.';
            InitValue = Fault;
            OptionCaption = 'None,Fault,Fault+Symptom,Fault+Symptom+Area (IRIS)';
            OptionMembers = "None",Fault,"Fault+Symptom","Fault+Symptom+Area (IRIS)";
        }
        field(5; "Link Service to Service Item"; Boolean)
        {
            Caption = 'Link Service to Service Item';
            ToolTip = 'Specifies that service lines for resources and items must be linked to a service item line. The value that you specify is entered as the link when a service order is created, but you can change it on the order manually.';
        }
        field(7; "Salesperson Mandatory"; Boolean)
        {
            AccessByPermission = TableData "Salesperson/Purchaser" = R;
            Caption = 'Salesperson Mandatory';
            ToolTip = 'Specifies that you must fill in the Salesperson Code field on the headers of service orders, invoices, credit memos, and service contracts.';
        }
        field(8; "Warranty Disc. % (Parts)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Warranty Disc. % (Parts)';
            DecimalPlaces = 1 : 1;
            InitValue = 100;
            MaxValue = 100;
            MinValue = 0;
        }
        field(9; "Warranty Disc. % (Labor)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Warranty Disc. % (Labor)';
            DecimalPlaces = 1 : 1;
            InitValue = 100;
            MaxValue = 100;
            MinValue = 0;
        }
        field(11; "Contract Rsp. Time Mandatory"; Boolean)
        {
            Caption = 'Contract Rsp. Time Mandatory';
            ToolTip = 'Specifies that the Response Time (Hours) field must be filled on service contract lines before you can convert a quote to a contract.';
        }
        field(13; "Service Order Starting Fee"; Code[10])
        {
            Caption = 'Service Order Starting Fee';
            ToolTip = 'Specifies the code for a service order starting fee.';
            TableRelation = "Service Cost";
        }
        field(14; "Register Contract Changes"; Boolean)
        {
            Caption = 'Register Contract Changes';
            ToolTip = 'Specifies that you want the program to log changes to service contracts in the Contract Change Log table.';
        }
        field(15; "Contract Inv. Line Text Code"; Code[20])
        {
            Caption = 'Contract Inv. Line Text Code';
            ToolTip = 'Specifies the code for the standard text entered in the Description field on the line in a contract invoice.';
            TableRelation = "Standard Text";
        }
        field(16; "Contract Line Inv. Text Code"; Code[20])
        {
            Caption = 'Contract Line Inv. Text Code';
            ToolTip = 'Specifies the code for the standard text entered in the Description field on the line in a contract invoice.';
            TableRelation = "Standard Text";
        }
        field(19; "Contract Inv. Period Text Code"; Code[20])
        {
            Caption = 'Contract Inv. Period Text Code';
            ToolTip = 'Specifies the code for the standard text entered in the Description field on the line in a contract invoice.';
            TableRelation = "Standard Text";
        }
        field(20; "Contract Credit Line Text Code"; Code[20])
        {
            Caption = 'Contract Credit Line Text Code';
            ToolTip = 'Specifies the code for the standard text that entered in the Description field on the line in a contract credit memo.';
            TableRelation = "Standard Text";
        }
        field(23; "Send First Warning To"; Text[80])
        {
            Caption = 'Send First Warning To';
            ToolTip = 'Specifies the email address that will be used to send the first warning about the response time for a service order that is approaching.';
        }
        field(24; "Send Second Warning To"; Text[80])
        {
            Caption = 'Send Second Warning To';
            ToolTip = 'Specifies the email address that will be used to send the second warning about the response time for a service order that is approaching.';
        }
        field(25; "Send Third Warning To"; Text[80])
        {
            Caption = 'Send Third Warning To';
            ToolTip = 'Specifies the email address that will be used to send the third warning about the response time for a service order that is approaching.';
        }
        field(26; "First Warning Within (Hours)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'First Warning Within (Hours)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(27; "Second Warning Within (Hours)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Second Warning Within (Hours)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(28; "Third Warning Within (Hours)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Third Warning Within (Hours)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(29; "Next Service Calc. Method"; Option)
        {
            Caption = 'Next Service Calc. Method';
            ToolTip = 'Specifies how you want the program to recalculate the next planned service date for service items in service contracts. Planned: The next planned service date is recalculated by adding the value in the Service Period field for the service item to the previous next planned service date. Also, when the last service actually took place is disregarded. Actual: The next planned service date is recalculated by adding the service period for the service item to the value in the Posting Date field of the last posted service order that belongs to the service contract and includes that service item.';
            OptionCaption = 'Planned,Actual';
            OptionMembers = Planned,Actual;
        }
        field(30; "Service Order Type Mandatory"; Boolean)
        {
            Caption = 'Service Order Type Mandatory';
            ToolTip = 'Specifies that a service order must have a service order type assigned before the order can be posted.';
        }
        field(31; "Service Zones Option"; Option)
        {
            Caption = 'Service Zones Option';
            ToolTip = 'Specifies how to identify service zones in your company when you allocate resources to service items.';
            OptionCaption = 'Code Shown,Warning Displayed,Not Used';
            OptionMembers = "Code Shown","Warning Displayed","Not Used";
        }
        field(32; "Service Order Start Mandatory"; Boolean)
        {
            Caption = 'Service Order Start Mandatory';
            ToolTip = 'Specifies that the Starting Date and Starting Time fields on a service order must be filled in before you can post the service order.';
        }
        field(33; "Service Order Finish Mandatory"; Boolean)
        {
            Caption = 'Service Order Finish Mandatory';
            ToolTip = 'Specifies that the Finishing Date and Finishing Time fields on a service order must be filled in before you can post the service order.';
        }
        field(36; "Resource Skills Option"; Option)
        {
            Caption = 'Resource Skills Option';
            ToolTip = 'Specifies how to identify resource skills in your company when you allocate resources to service items.';
            OptionCaption = 'Code Shown,Warning Displayed,Not Used';
            OptionMembers = "Code Shown","Warning Displayed","Not Used";
        }
        field(37; "One Service Item Line/Order"; Boolean)
        {
            Caption = 'One Service Item Line/Order';
            ToolTip = 'Specifies that you can enter only one service item line for each service order.';
        }
        field(38; "Unit of Measure Mandatory"; Boolean)
        {
            Caption = 'Unit of Measure Mandatory';
            ToolTip = 'Specifies if you must select a unit of measure for all operations that deal with service items.';
        }
        field(39; "Fault Reason Code Mandatory"; Boolean)
        {
            Caption = 'Fault Reason Code Mandatory';
            ToolTip = 'Specifies that the Fault Reason Code field must be filled in before you can post the service order.';
        }
        field(40; "Contract Serv. Ord.  Max. Days"; Integer)
        {
            Caption = 'Contract Serv. Ord.  Max. Days';
            ToolTip = 'Specifies the maximum number of days you can use as the date range each time you run the Create Contract Service Orders batch job.';
            MinValue = 0;
        }
        field(41; "Last Contract Service Date"; Date)
        {
            Caption = 'Last Contract Service Date';
            Editable = false;
        }
        field(42; "Work Type Code Mandatory"; Boolean)
        {
            Caption = 'Work Type Code Mandatory';
            ToolTip = 'Specifies that the Work Type Code field with type Resource must be filled in before you can post the service order.';
        }
        field(43; "Logo Position on Documents"; Option)
        {
            Caption = 'Logo Position on Documents';
            ToolTip = 'Specifies the position of your company logo on your business letters and documents, such as service invoices and service shipments.';
            OptionCaption = 'No Logo,Left,Center,Right';
            OptionMembers = "No Logo",Left,Center,Right;
        }
        field(44; "Use Contract Cancel Reason"; Boolean)
        {
            Caption = 'Use Contract Cancel Reason';
            ToolTip = 'Specifies that a reason code is entered when you cancel a service contract.';
        }
        field(45; "Default Response Time (Hours)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Default Response Time (Hours)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(46; "Ext. Doc. No. Mandatory"; Boolean)
        {
            Caption = 'Ext. Doc. No. Mandatory';
            ToolTip = 'Specifies if it is mandatory to enter an external document number in the External Document No. field on a service header.';
        }
        field(52; "Default Warranty Duration"; DateFormula)
        {
            Caption = 'Default Warranty Duration';
            ToolTip = 'Specifies the default duration for warranty discounts on service items.';
        }
        field(54; "Service Invoice Nos."; Code[20])
        {
            Caption = 'Service Invoice Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to service invoices. To see the number series that have been set up in the No. Series table, click the field.';
            TableRelation = "No. Series";
        }
        field(55; "Contract Invoice Nos."; Code[20])
        {
            Caption = 'Contract Invoice Nos.';
            ToolTip = 'Specifies the number series code that will be used to assign numbers to invoices created for service contracts.';
            TableRelation = "No. Series";
        }
        field(56; "Service Item Nos."; Code[20])
        {
            Caption = 'Service Item Nos.';
            ToolTip = 'Specifies the number series code that will be used to assign numbers to service items.';
            TableRelation = "No. Series";
        }
        field(57; "Service Order Nos."; Code[20])
        {
            Caption = 'Service Order Nos.';
            ToolTip = 'Specifies the number series code that will be used to assign numbers to service orders.';
            TableRelation = "No. Series";
        }
        field(58; "Service Contract Nos."; Code[20])
        {
            AccessByPermission = TableData "Service Contract Line" = R;
            Caption = 'Service Contract Nos.';
            ToolTip = 'Specifies the number series code that will be used to assign numbers to service contracts.';
            TableRelation = "No. Series";
        }
        field(59; "Contract Template Nos."; Code[20])
        {
            AccessByPermission = TableData "Service Contract Line" = R;
            Caption = 'Contract Template Nos.';
            ToolTip = 'Specifies the number series code that will be used to assign numbers to contract templates.';
            TableRelation = "No. Series";
        }
        field(60; "Troubleshooting Nos."; Code[20])
        {
            Caption = 'Troubleshooting Nos.';
            ToolTip = 'Specifies the number series code that will be used to assign numbers to troubleshooting guidelines.';
            TableRelation = "No. Series";
        }
        field(61; "Prepaid Posting Document Nos."; Code[20])
        {
            Caption = 'Prepaid Posting Document Nos.';
            ToolTip = 'Specifies the number series code that will be used to assign a document number to the journal lines.';
            TableRelation = "No. Series";
        }
        field(62; "Loaner Nos."; Code[20])
        {
            Caption = 'Loaner Nos.';
            ToolTip = 'Specifies the number series code that will be used to assign numbers to loaners.';
            TableRelation = "No. Series";
        }
        field(63; "Serv. Job Responsibility Code"; Code[10])
        {
            Caption = 'Serv. Job Responsibility Code';
            ToolTip = 'Specifies the code for job responsibilities that is set up for service management work. When you assign customers to service orders, the program selects the contact with this job responsibility from among the contacts assigned to the customer.';
            TableRelation = "Job Responsibility".Code;
        }
        field(64; "Contract Value Calc. Method"; Option)
        {
            Caption = 'Contract Value Calc. Method';
            ToolTip = 'Specifies the method to use for calculating the default contract value of service items when they are created. None: A default value is not calculated. Based on Unit Price: Value = Sales Unit Price x Contract Value % divided by 100. Based on Unit Cost: Value = Sales Unit Cost x Contract Value % divided by 100.';
            OptionCaption = 'None,Based on Unit Price,Based on Unit Cost';
            OptionMembers = "None","Based on Unit Price","Based on Unit Cost";
        }
        field(65; "Contract Value %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Contract Value %';
            ToolTip = 'Specifies the percentage used to calculate the default contract value of a service item when it is created.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(66; "Service Quote Nos."; Code[20])
        {
            Caption = 'Service Quote Nos.';
            ToolTip = 'Specifies the number series code that will be used to assign numbers to service quotes.';
            TableRelation = "No. Series";
        }
        field(68; "Posted Service Invoice Nos."; Code[20])
        {
            Caption = 'Posted Service Invoice Nos.';
            ToolTip = 'Specifies the number series code that will be used to assign numbers to service invoices when they are posted.';
            TableRelation = "No. Series";
        }
        field(69; "Posted Serv. Credit Memo Nos."; Code[20])
        {
            Caption = 'Posted Serv. Credit Memo Nos.';
            ToolTip = 'Specifies the number series code that will be used to assign numbers to service credit memos when they are posted.';
            TableRelation = "No. Series";
        }
        field(70; "Posted Service Shipment Nos."; Code[20])
        {
            Caption = 'Posted Service Shipment Nos.';
            ToolTip = 'Specifies the number series code that will be used to assign numbers to shipments when they are posted.';
            TableRelation = "No. Series";
        }
        field(76; "Shipment on Invoice"; Boolean)
        {
            Caption = 'Shipment on Invoice';
            ToolTip = 'Specifies that if you post a manually created invoice, a posted shipment will be created in addition to a posted invoice.';
        }
        field(77; "Skip Manual Reservation"; Boolean)
        {
            Caption = 'Skip Manual Reservation';
            ToolTip = 'Specifies that the reservation confirmation message is not shown on service lines. This is useful to avoid noise when you are processing many lines.';
            DataClassification = SystemMetadata;
        }
        field(81; "Copy Comments Order to Invoice"; Boolean)
        {
            Caption = 'Copy Comments Order to Invoice';
            ToolTip = 'Specifies whether to copy comments from service orders to service invoices.';
            InitValue = true;
        }
        field(82; "Copy Comments Order to Shpt."; Boolean)
        {
            Caption = 'Copy Comments Order to Shpt.';
            ToolTip = 'Specifies whether to copy comments from service orders to shipments.';
            InitValue = true;
        }
        field(85; "Service Credit Memo Nos."; Code[20])
        {
            Caption = 'Service Credit Memo Nos.';
            ToolTip = 'Specifies the number series code that will be used to assign numbers to service credit memos.';
            TableRelation = "No. Series";
        }
        field(175; "Allow Multiple Posting Groups"; Boolean)
        {
            Caption = 'Allow Multiple Posting Groups';
            ToolTip = 'Specifies if multiple posting groups can be used for the same customer in sales documents.';
            DataClassification = SystemMetadata;
        }
        field(176; "Check Multiple Posting Groups"; enum "Posting Group Change Method")
        {
            Caption = 'Check Multiple Posting Groups';
            ToolTip = 'Specifies implementation method of checking which posting groups can be used for the customer.';
            DataClassification = SystemMetadata;
        }
        field(185; "Archive Quotes"; Enum "Archive Service Quotes")
        {
            Caption = 'Archive Quotes';
            ToolTip = 'Specifies if you want to automatically archive service quotes when: deleted, processed or printed.';
        }
        field(186; "Archive Orders"; Boolean)
        {
            Caption = 'Archive Orders';
            ToolTip = 'Specifies if you want to automatically archive service orders when: deleted, posted or printed.';
        }
        field(190; "Del. Filed Cont. w. main Cont."; Boolean)
        {
            Caption = 'Delete Filed Contracts with related main Contract';
            ToolTip = 'Specifies whether to automatically delete all Filed Contracts when related main Contract / Contract Quote is deleted.';
        }
        field(200; "Serv. Inv. Template Name"; Code[10])
        {
            Caption = 'Serv. Invoice Template Name';
            ToolTip = 'Specifies the name of the journal template to use for posting service invoices.';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
        }
        field(201; "Serv. Contr. Inv. Templ. Name"; Code[10])
        {
            Caption = 'Serv. Contract Invoice Template Name';
            ToolTip = 'Specifies the name of the journal template to use for posting service contract invoices.';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
        }
        field(202; "Serv. Contr. Cr.M. Templ. Name"; Code[10])
        {
            Caption = 'Serv. Contract Cr. Memo Template Name';
            ToolTip = 'Specifies the name of the journal template to use for posting service contract credit memos.';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
        }
        field(203; "Serv. Cr. Memo Templ. Name"; Code[10])
        {
            Caption = 'Serv. Cr. Memo Template Name';
            ToolTip = 'Specifies which general journal template to use for service credit memos.';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
        }
        field(210; "Copy Line Descr. to G/L Entry"; Boolean)
        {
            Caption = 'Copy Line Descr. to G/L Entry';
            ToolTip = 'Specifies that the description on document lines of type G/L Account will be carried to the resulting general ledger entries.';
            DataClassification = SystemMetadata;
        }
        field(950; "Copy Time Sheet to Order"; Boolean)
        {
            Caption = 'Copy Time Sheet to Order';
            ToolTip = 'Specifies if approved time sheet lines are copied to the related service order. Select this field to make sure that time usage registered on approved time sheet lines is posted with the related service order.';
        }
        field(7600; "Base Calendar Code"; Code[10])
        {
            Caption = 'Base Calendar Code';
            ToolTip = 'Specifies a customizable calendar for service planning that holds the service department''s working days and holidays. Choose the field to select another base calendars or to set up a customized calendar for your service department.';
            TableRelation = "Base Calendar";
        }
        field(7601; "Contract Credit Memo Nos."; Code[20])
        {
            AccessByPermission = TableData "Service Contract Line" = R;
            Caption = 'Contract Credit Memo Nos.';
            ToolTip = 'Specifies the number series code that will be used to assign numbers to credit memos for service contracts.';
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        RecordHasBeenRead: Boolean;

    trigger OnInsert()
    begin
        TestField("Primary Key", '');
    end;

    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;
}
