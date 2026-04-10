// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Setup;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Calendar;

page 5919 "Service Mgt. Setup"
{
    ApplicationArea = Service;
    Caption = 'Service Management Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Service Mgt. Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("First Warning Within (Hours)"; Rec."First Warning Within (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of hours before the program sends the first warning about the response time approaching for a service order. The working calendar and the default service hours are used to calculate when to send the warnings within the general service hours of your company.';
                }
                field("Send First Warning To"; Rec."Send First Warning To")
                {
                    ApplicationArea = Service;
                }
                field("Second Warning Within (Hours)"; Rec."Second Warning Within (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of hours before the program sends the second warning about the response time approaching for a service order.';
                }
                field("Send Second Warning To"; Rec."Send Second Warning To")
                {
                    ApplicationArea = Service;
                }
                field("Third Warning Within (Hours)"; Rec."Third Warning Within (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of hours before the program sends the third warning about the response time approaching for a service order.';
                }
                field("Send Third Warning To"; Rec."Send Third Warning To")
                {
                    ApplicationArea = Service;
                }
                field("Serv. Job Responsibility Code"; Rec."Serv. Job Responsibility Code")
                {
                    ApplicationArea = Service;
                }
                field("Next Service Calc. Method"; Rec."Next Service Calc. Method")
                {
                    ApplicationArea = Service;
                }
                field("Service Order Starting Fee"; Rec."Service Order Starting Fee")
                {
                    ApplicationArea = Service;
                }
                field("Shipment on Invoice"; Rec."Shipment on Invoice")
                {
                    ApplicationArea = Service;
                }
                field("One Service Item Line/Order"; Rec."One Service Item Line/Order")
                {
                    ApplicationArea = Service;
                }
                field("Link Service to Service Item"; Rec."Link Service to Service Item")
                {
                    ApplicationArea = Service;
                }
                field("Resource Skills Option"; Rec."Resource Skills Option")
                {
                    ApplicationArea = Service;
                }
                field("Service Zones Option"; Rec."Service Zones Option")
                {
                    ApplicationArea = Service;
                }
                field("Fault Reporting Level"; Rec."Fault Reporting Level")
                {
                    ApplicationArea = Service;
                }
                field("Base Calendar Code"; Rec."Base Calendar Code")
                {
                    ApplicationArea = Service;
                    DrillDown = true;

                    trigger OnDrillDown()
                    var
                        CalendarManagement: Codeunit "Calendar Management";
                    begin
                        CurrPage.SaveRecord();
                        Rec.TestField("Base Calendar Code");
                        CalendarManagement.ShowCustomizedCalendar(Rec);
                    end;
                }
                field("Copy Comments Order to Invoice"; Rec."Copy Comments Order to Invoice")
                {
                    ApplicationArea = Comments;
                }
                field("Copy Comments Order to Shpt."; Rec."Copy Comments Order to Shpt.")
                {
                    ApplicationArea = Comments;
                }
                field("Logo Position on Documents"; Rec."Logo Position on Documents")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                }
                field("Copy Time Sheet to Order"; Rec."Copy Time Sheet to Order")
                {
                    ApplicationArea = Service;
                }
                field("Skip Manual Reservation"; Rec."Skip Manual Reservation")
                {
                    ApplicationArea = Service;
                }
                field("Copy Line Descr. to G/L Entry"; Rec."Copy Line Descr. to G/L Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Allow Multiple Posting Groups"; Rec."Allow Multiple Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Check Multiple Posting Groups"; Rec."Check Multiple Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
            }
            group("Mandatory Fields")
            {
                Caption = 'Mandatory Fields';
                field("Service Order Type Mandatory"; Rec."Service Order Type Mandatory")
                {
                    ApplicationArea = Service;
                }
                field("Service Order Start Mandatory"; Rec."Service Order Start Mandatory")
                {
                    ApplicationArea = Service;
                }
                field("Service Order Finish Mandatory"; Rec."Service Order Finish Mandatory")
                {
                    ApplicationArea = Service;
                }
                field("Contract Rsp. Time Mandatory"; Rec."Contract Rsp. Time Mandatory")
                {
                    ApplicationArea = Service;
                }
                field("Unit of Measure Mandatory"; Rec."Unit of Measure Mandatory")
                {
                    ApplicationArea = Service;
                }
                field("Fault Reason Code Mandatory"; Rec."Fault Reason Code Mandatory")
                {
                    ApplicationArea = Service;
                }
                field("Work Type Code Mandatory"; Rec."Work Type Code Mandatory")
                {
                    ApplicationArea = Service;
                }
                field("Salesperson Mandatory"; Rec."Salesperson Mandatory")
                {
                    ApplicationArea = Service;
                }
                field("Ext. Doc. No. Mandatory"; Rec."Ext. Doc. No. Mandatory")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                }
            }
            group(Defaults)
            {
                Caption = 'Defaults';
                field("Default Response Time (Hours)"; Rec."Default Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the default response time, in hours, required to start service, either on a service order or on a service item line.';
                }
                field("Warranty Disc. % (Parts)"; Rec."Warranty Disc. % (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the default warranty discount percentage on spare parts. The program uses this value to set warranty discounts on parts on service item lines.';
                }
                field("Warranty Disc. % (Labor)"; Rec."Warranty Disc. % (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the default warranty discount percentage on labor. The program uses this value to set warranty discounts on labor on service item lines.';
                }
                field("Default Warranty Duration"; Rec."Default Warranty Duration")
                {
                    ApplicationArea = Service;
                }
            }
            group(Contracts)
            {
                Caption = 'Contracts';
                field("Contract Serv. Ord.  Max. Days"; Rec."Contract Serv. Ord.  Max. Days")
                {
                    ApplicationArea = Service;
                }
                field("Use Contract Cancel Reason"; Rec."Use Contract Cancel Reason")
                {
                    ApplicationArea = Service;
                }
                field("Register Contract Changes"; Rec."Register Contract Changes")
                {
                    ApplicationArea = Service;
                }
                field("Contract Inv. Line Text Code"; Rec."Contract Inv. Line Text Code")
                {
                    ApplicationArea = Service;
                }
                field("Contract Line Inv. Text Code"; Rec."Contract Line Inv. Text Code")
                {
                    ApplicationArea = Service;
                }
                field("Contract Inv. Period Text Code"; Rec."Contract Inv. Period Text Code")
                {
                    ApplicationArea = Service;
                }
                field("Contract Credit Line Text Code"; Rec."Contract Credit Line Text Code")
                {
                    ApplicationArea = Service;
                }
                field("Contract Value Calc. Method"; Rec."Contract Value Calc. Method")
                {
                    ApplicationArea = Service;
                }
                field("Contract Value %"; Rec."Contract Value %")
                {
                    ApplicationArea = Service;
                }
                field("Del. Filed Cont. w. main Cont."; Rec."Del. Filed Cont. w. main Cont.")
                {
                    ApplicationArea = Service;
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Service Item Nos."; Rec."Service Item Nos.")
                {
                    ApplicationArea = Service;
                }
                field("Service Quote Nos."; Rec."Service Quote Nos.")
                {
                    ApplicationArea = Service;
                }
                field("Service Order Nos."; Rec."Service Order Nos.")
                {
                    ApplicationArea = Service;
                }
                field("Service Invoice Nos."; Rec."Service Invoice Nos.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number series code that will be used to assign numbers to invoices.';
                }
                field("Posted Service Invoice Nos."; Rec."Posted Service Invoice Nos.")
                {
                    ApplicationArea = Service;
                }
                field("Service Credit Memo Nos."; Rec."Service Credit Memo Nos.")
                {
                    ApplicationArea = Service;
                }
                field("Posted Serv. Credit Memo Nos."; Rec."Posted Serv. Credit Memo Nos.")
                {
                    ApplicationArea = Service;
                }
                field("Posted Service Shipment Nos."; Rec."Posted Service Shipment Nos.")
                {
                    ApplicationArea = Service;
                }
                field("Loaner Nos."; Rec."Loaner Nos.")
                {
                    ApplicationArea = Service;
                }
                field("Troubleshooting Nos."; Rec."Troubleshooting Nos.")
                {
                    ApplicationArea = Service;
                }
                field("Service Contract Nos."; Rec."Service Contract Nos.")
                {
                    ApplicationArea = Service;
                }
                field("Contract Template Nos."; Rec."Contract Template Nos.")
                {
                    ApplicationArea = Service;
                }
                field("Contract Invoice Nos."; Rec."Contract Invoice Nos.")
                {
                    ApplicationArea = Service;
                }
                field("Contract Credit Memo Nos."; Rec."Contract Credit Memo Nos.")
                {
                    ApplicationArea = Service;
                }
                field("Prepaid Posting Document Nos."; Rec."Prepaid Posting Document Nos.")
                {
                    ApplicationArea = Service;
                }
            }
            group(Archiving)
            {
                Caption = 'Archiving';
                field("Archive Quotes"; Rec."Archive Quotes")
                {
                    ApplicationArea = Service;
                }
                field("Archive Orders"; Rec."Archive Orders")
                {
                    ApplicationArea = Service;
                }
            }
            group("Journal Templates")
            {
                Caption = 'Journal Templates';
                Visible = JnlTemplateNameVisible;

                field("Serv. Inv. Template Name"; Rec."Serv. Inv. Template Name")
                {
                    ApplicationArea = Service;
                }
                field("Serv. Cr. Memo Templ. Name"; Rec."Serv. Cr. Memo Templ. Name")
                {
                    ApplicationArea = Service;
                }
                field("Serv. Contr. Inv. Templ. Name"; Rec."Serv. Contr. Inv. Templ. Name")
                {
                    ApplicationArea = Service;
                }
                field("Serv. Contr. Cr.M. Templ. Name"; Rec."Serv. Contr. Cr.M. Templ. Name")
                {
                    ApplicationArea = Service;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        GeneralLedgerSetup.Get();
        JnlTemplateNameVisible := GeneralLedgerSetup."Journal Templ. Name Mandatory";
    end;

    var
        JnlTemplateNameVisible: Boolean;
}

