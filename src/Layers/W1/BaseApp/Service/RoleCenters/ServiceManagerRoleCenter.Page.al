// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.RoleCenters;

using Microsoft.CRM.Contact;
using Microsoft.Foundation.Navigate;
using Microsoft.Integration.D365Sales;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Sales.Customer;
using Microsoft.Service.Analysis;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Email;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Loaner;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Pricing;
using Microsoft.Service.Reports;
using Microsoft.Service.Resources;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
#if not CLEAN25
using Microsoft.Integration.FieldService;
using Microsoft.Integration.Dataverse;
#endif

page 8908 "Service Manager Role Center"
{
    Caption = 'Service Manager Role Center';
    PageType = RoleCenter;
    actions
    {
        area(Sections)
        {
            group("Group")
            {
                Caption = 'Contracts';
                action("Service Items")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Items';
                    RunObject = page "Service Item List";
                }
                action("Items")
                {
                    ApplicationArea = Service;
                    Caption = 'Items';
                    RunObject = page "Item List";
                }
                action("Contacts")
                {
                    ApplicationArea = Service;
                    Caption = 'Contacts';
                    RunObject = page "Contact List";
                }
                action("Customers")
                {
                    ApplicationArea = Service;
                    Caption = 'Customers';
                    RunObject = page "Customer List";
                }
                action("Contracts")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Contracts';
                    RunObject = page "Service Contracts";
                }
                action("Contract Quotes")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Contract Quotes';
                    RunObject = page "Service Contract Quotes";
                }
                action("Invoices")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Invoices';
                    RunObject = page "Service Invoices";
                }
                action("Credit Memos")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Credit Memos';
                    RunObject = page "Service Credit Memos";
                }
                action("Create Contract Orders")
                {
                    ApplicationArea = Service;
                    Caption = 'Create Contract Service Orders';
                    RunObject = report "Create Contract Service Orders";
                }
                action("Create Contract Invoices")
                {
                    ApplicationArea = Service;
                    Caption = 'Create Service Contract Invoices';
                    RunObject = report "Create Contract Invoices";
                }
                group("Group1")
                {
                    Caption = 'Contract Gain/Loss by';
                    action("Contract & Group")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contract Gain/Loss (Groups)';
                        RunObject = page "Contract Gain/Loss (Groups)";
                    }
                    action("Contracts1")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contract Gain/Loss (Contracts)';
                        RunObject = page "Contract Gain/Loss (Contracts)";
                    }
                    action("Customers1")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contract Gain/Loss (Customers)';
                        RunObject = page "Contract Gain/Loss (Customers)";
                    }
                    action("Reason Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contract Gain/Loss (Reasons)';
                        RunObject = page "Contract Gain/Loss (Reasons)";
                    }
                    action("Responsibility Center")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contract Gain/Loss (Resp.Ctr)';
                        RunObject = page "Contract Gain/Loss (Resp.Ctr)";
                    }
                }
                group("Group2")
                {
                    Caption = 'Reports';
                    action("Contract - Salesperson")
                    {
                        ApplicationArea = Service;
                        Caption = 'Serv. Contract - Salesperson';
                        RunObject = report "Serv. Contract - Salesperson";
                    }
                    action("Contr. GainLoss - Resp. Ctr.")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contr. Gain/Loss - Resp. Ctr.';
                        RunObject = report "Contr. Gain/Loss - Resp. Ctr.";
                    }
                    action("Contract - Customer")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Contract - Customer';
                        RunObject = report "Service Contract - Customer";
                    }
                    action("Maintenance Visit - Planning")
                    {
                        ApplicationArea = Service;
                        Caption = 'Maintenance Visit - Planning';
                        RunObject = report "Maintenance Visit - Planning";
                    }
                    action("Maintenance Performance")
                    {
                        ApplicationArea = Service;
                        Caption = 'Maintenance Performance';
                        RunObject = report "Maintenance Performance";
                    }
                    action("Contract GainLoss Entries")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contract Gain/Loss Entries';
                        RunObject = report "Contract Gain/Loss Entries";
                    }
                    action("Contract Quotes to Be Signed")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contract Quotes to Be Signed';
                        RunObject = report "Contract Quotes to Be Signed";
                    }
                    action("Profit (Contracts)")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Profit (Contracts)';
                        RunObject = report "Service Profit (Contracts)";
                    }
                    action("Service Items1")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Items';
                        RunObject = report "Service Items";
                    }
                    action("Service Items Out of Warranty")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Items Out of Warranty';
                        RunObject = report "Service Items Out of Warranty";
                    }
                    action("Service Item Line Labels")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Item Line Labels';
                        RunObject = report "Service Item Line Labels";
                    }
                }
            }
            group("Group3")
            {
                Caption = 'Planning & Dispatching';
                action("Service Tasks")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Tasks';
                    RunObject = page "Service Tasks";
                }
                action("Dispatch Board")
                {
                    ApplicationArea = Service;
                    Caption = 'Dispatch Board';
                    RunObject = page "Dispatch Board";
                }
                action("Demand Overview")
                {
                    ApplicationArea = Service;
                    Caption = 'Demand Overview';
                    RunObject = page "Demand Overview";
                }
                group("Group4")
                {
                    Caption = 'Reports';
                    action("Service Tasks1")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Tasks';
                        RunObject = report "Service Tasks";
                    }
                    action("Dispatch Board1")
                    {
                        ApplicationArea = Service;
                        Caption = 'Dispatch Board';
                        RunObject = report "Dispatch Board";
                    }
                    action("Load Level")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Load Level';
                        RunObject = report "Service Load Level";
                    }
                }
            }
            group("Group5")
            {
                Caption = 'Order Processing';
                action("Service Items2")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Items';
                    RunObject = page "Service Item List";
                }
                action("Items1")
                {
                    ApplicationArea = Service;
                    Caption = 'Items';
                    RunObject = page "Item List";
                }
                action("Nonstock Items")
                {
                    ApplicationArea = Service;
                    Caption = 'Nonstock Items';
                    RunObject = page "Catalog Item List";
                }
                action("Contacts1")
                {
                    ApplicationArea = Service;
                    Caption = 'Contacts';
                    RunObject = page "Contact List";
                }
                action("Customers2")
                {
                    ApplicationArea = Service;
                    Caption = 'Customers';
                    RunObject = page "Customer List";
                }
                action("Loaners")
                {
                    ApplicationArea = Service;
                    Caption = 'Loaners';
                    RunObject = page "Loaner List";
                }
                action("Quotes")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Quotes';
                    RunObject = page "Service Quotes";
                }
                action("Orders")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Orders';
                    RunObject = page "Service Orders";
                }
                action("Invoices1")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Invoices';
                    RunObject = page "Service Invoices";
                }
                action("Credit Memos1")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Credit Memos';
                    RunObject = page "Service Credit Memos";
                }
                action("Certificates of Supply")
                {
                    ApplicationArea = Service;
                    Caption = 'Certificates of Supply';
                    RunObject = page "Certificates of Supply";
                }
                action("Cases - Dynamics 365 for Customer Service")
                {
                    ApplicationArea = Service;
                    Caption = 'Cases - Dynamics 365 for Customer Service';
                    RunObject = page "CRM Case List";
                }
                group("Group6")
                {
                    Caption = 'Posted Documents';
                    action("Posted Credit Memos")
                    {
                        ApplicationArea = Service;
                        Caption = 'Posted Service Credit Memos';
                        RunObject = page "Posted Service Credit Memos";
                    }
                    action("Posted Invoices")
                    {
                        ApplicationArea = Service;
                        Caption = 'Posted Service Invoices';
                        RunObject = page "Posted Service Invoices";
                    }
                    action("Posted Orders")
                    {
                        ApplicationArea = Service;
                        Caption = 'Posted Service Shipments';
                        RunObject = page "Posted Service Shipments";
                    }
                    action("Navi&gate")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Find entries...';
                        Image = Navigate;
                        RunObject = Page Navigate;
                        ShortCutKey = 'Ctrl+Alt+Q';
                        ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                    }
                }
                group("Group7")
                {
                    Caption = 'Register/Entries';
                    action("Service Registers")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Registers';
                        RunObject = page "Service Register";
                    }
                    action("Service Ledger Entries")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Ledger Entries';
                        RunObject = page "Service Ledger Entries";
                    }
                    action("Warranty Ledger Entries")
                    {
                        ApplicationArea = Service;
                        Caption = 'Warranty Ledger Entries';
                        RunObject = page "Warranty Ledger Entries";
                    }
                    action("Loaner Entries")
                    {
                        ApplicationArea = Service;
                        Caption = 'Loaner Entries';
                        RunObject = page "Loaner Entries";
                    }
                }
                group("Group8")
                {
                    Caption = 'Logs';
                    action("Orders1")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Document Log';
                        RunObject = page "Service Document Log";
                    }
                    action("Service Items3")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Item Log';
                        RunObject = page "Service Item Log";
                    }
                    action("View Email Queue")
                    {
                        ApplicationArea = Service;
                        Caption = 'View Email Queue';
                        RunObject = page "Service Email Queue";
                    }
                }
                group("Group9")
                {
                    Caption = 'Reports';
                    action("Profit (Orders)")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Profit (Serv. Orders)';
                        RunObject = report "Service Profit (Serv. Orders)";
                    }
                    action("Profit (Resp. Centers)")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Profit (Resp. Centers)';
                        RunObject = report "Service Profit (Resp. Centers)";
                    }
                    action("Order - Response Time")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Order - Response Time';
                        RunObject = report "Service Order - Response Time";
                    }
                    action("Pricing Profitability")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Pricing Profitability';
                        RunObject = report "Serv. Pricing Profitability";
                    }
                    action("Service Items Out of Warranty1")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Items Out of Warranty';
                        RunObject = report "Service Items Out of Warranty";
                    }
                    action("Service Item Line Labels1")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Item Line Labels';
                        RunObject = report "Service Item Line Labels";
                    }
                    action("Profit (Service Items)")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Profit (Service Items)';
                        RunObject = report "Service Profit (Service Items)";
                    }
                    action("Service Item - Resource Usage")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Item - Resource Usage';
                        RunObject = report "Service Item - Resource Usage";
                    }
                    action("Service Item Worksheet")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Item Worksheet';
                        RunObject = report "Service Item Worksheet";
                    }
                }
            }
            group("Group10")
            {
                Caption = 'Setup';
                action("Service Setup")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Setup';
                    RunObject = page "Service Mgt. Setup";
                }
                action("Skill Codes")
                {
                    ApplicationArea = Service;
                    Caption = 'Skill Codes';
                    RunObject = page "Skill Codes";
                }
                action("Fault Reason Codes")
                {
                    ApplicationArea = Service;
                    Caption = 'Fault Reason Codes';
                    RunObject = page "Fault Reason Codes";
                }
                action("Service Costs")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Costs';
                    RunObject = page "Service Costs";
                }
                action("Service Zones")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Zones';
                    RunObject = page "Service Zones";
                }
                action("Service Order Types")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Order Types';
                    RunObject = page "Service Order Types";
                }
                action("Service Item Groups")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Item Groups';
                    RunObject = page "Service Item Groups";
                }
                action("Shelves")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Shelves';
                    RunObject = page "Service Shelves";
                }
                action("Standard Service Codes")
                {
                    ApplicationArea = Service;
                    Caption = 'Standard Service Codes';
                    RunObject = page "Standard Service Codes";
                }
                action("Report Selections")
                {
                    ApplicationArea = Service;
                    Caption = 'Report Selection - Service';
                    RunObject = page "Report Selection - Service";
                }
                group("Group11")
                {
                    Caption = 'Service Operations';
                    action("Default Service Hours")
                    {
                        ApplicationArea = Service;
                        Caption = 'Default Service Hours';
                        RunObject = page "Default Service Hours";
                    }
                    action("Work-Hour Templates")
                    {
                        ApplicationArea = Jobs, Service;
                        Caption = 'Work-Hour Templates';
                        RunObject = page "Work-Hour Templates";
                    }
                    action("Resource Service Zones")
                    {
                        ApplicationArea = Service;
                        Caption = 'Resource Service Zones';
                        RunObject = page "Resource Service Zones";
                    }
                    action("Troubleshooting")
                    {
                        ApplicationArea = Service;
                        Caption = 'Troubleshooting';
                        RunObject = page "Troubleshooting List";
                    }
                }
                group("Group12")
                {
                    Caption = 'Status';
                    action("Order Status Setup")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Order Status Setup';
                        RunObject = page "Service Order Status Setup";
                    }
                    action("Repair Status Setup")
                    {
                        ApplicationArea = Service;
                        Caption = 'Repair Status Setup';
                        RunObject = page "Repair Status Setup";
                    }
                }
                group("Group13")
                {
                    Caption = 'Pricing';
                    action("Price Adjustment Groups")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Price Adjustment Groups';
                        RunObject = page "Serv. Price Adjmt. Group";
                    }
                    action("Price Groups")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Price Groups';
                        RunObject = page "Service Price Groups";
                    }
                }
                group("Group14")
                {
                    Caption = 'Fault Reporting';
                    action("Resolution Codes")
                    {
                        ApplicationArea = Service;
                        Caption = 'Resolution Codes';
                        RunObject = page "Resolution Codes";
                    }
                    action("Fault Areas")
                    {
                        ApplicationArea = Service;
                        Caption = 'Fault Areas';
                        RunObject = page "Fault Areas";
                    }
                    action("Symptom Codes")
                    {
                        ApplicationArea = Service;
                        Caption = 'Symptom Codes';
                        RunObject = page "Symptom Codes";
                    }
                    action("Fault Codes")
                    {
                        ApplicationArea = Service;
                        Caption = 'Fault Codes';
                        RunObject = page "Fault Codes";
                    }
                    action("Fault/Resol. Codes Relationshi")
                    {
                        ApplicationArea = Service;
                        Caption = 'Fault/Resol. Codes Relationships';
                        RunObject = page "Fault/Resol. Cod. Relationship";
                    }
                    action("Imp. IRIS to Area/Symptom Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Imp. IRIS to Area/Symptom Code';
                        RunObject = XMLport "Imp. IRIS to Area/Symptom Code";
                    }
                    action("Import IRIS to Fault Codes")
                    {
                        ApplicationArea = Service;
                        Caption = 'Import IRIS to Fault Codes';
                        RunObject = XMLport "Import IRIS to Fault Codes";
                    }
                    action("Import IRIS to Resol. Codes")
                    {
                        ApplicationArea = Service;
                        Caption = 'Import IRIS to Resol. Codes';
                        RunObject = XMLport "Import IRIS to Resol. Codes";
                    }
                }
                group("Group15")
                {
                    Caption = 'Contracts';
                    action("Account Groups")
                    {
                        ApplicationArea = Service;
                        Caption = 'Serv. Contract Account Groups';
                        RunObject = page "Serv. Contract Account Groups";
                    }
                    action("Templates")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Contract Templates';
                        RunObject = page "Service Contract Template List";
                    }
                    action("Groups")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Contract Groups';
                        RunObject = page "Service Contract Groups";
                    }
                    action("Service Item Groups1")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Item Groups';
                        RunObject = page "Service Item Groups";
                    }
                }
            }
#if not CLEAN25
            group("Group16")
            {
                Caption = 'Dynamics 365 Field Service';
                Visible = false;
                ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                ObsoleteState = Pending;
                ObsoleteTag = '25.0';

                action("Bookable Resources - Dynamics 365 Field Service")
                {
                    ApplicationArea = Suite;
                    Caption = 'Bookable Resources - Dynamics 365 Field Service';
                    RunObject = page "FS Bookable Resource List";
                    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '25.0';
                }
                action("Customer Assets - Dynamics 365 Field Service")
                {
                    ApplicationArea = Suite;
                    Caption = 'Customer Assets - Dynamics 365 Field Service';
                    RunObject = page "FS Customer Asset List";
                    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '25.0';
                }
                action("Records Skipped For Synchronization")
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled Data Synchronization Errors';
                    RunObject = page "CRM Skipped Records";
                    AccessByPermission = TableData "CRM Integration Record" = R;
                    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '25.0';
                }
            }
#endif
        }
    }
}
