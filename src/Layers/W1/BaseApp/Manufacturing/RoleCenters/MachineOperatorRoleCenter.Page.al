// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.RoleCenters;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Journal;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Warehouse.Activity;
using Microsoft.Foundation.Task;
using System.Threading;

page 9013 "Machine Operator Role Center"
{
    Caption = 'Machine Operator - Manufacturing Comprehensive';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(Control1900316508; "Machine Operator Activities")
            {
                ApplicationArea = Manufacturing;
            }
            part("User Tasks Activities"; "User Tasks Activities")
            {
                ApplicationArea = Suite;
            }
            part("Job Queue Tasks Activities"; "Job Queue Tasks Activities")
            {
                ApplicationArea = Suite;
            }
            part(Control3; "My Job Queue")
            {
                ApplicationArea = Manufacturing;
                Visible = false;
            }
            part(Control1905989608; "My Items")
            {
                ApplicationArea = Manufacturing;
            }
            part(Control5; "Report Inbox Part")
            {
                ApplicationArea = Manufacturing;
                Visible = false;
            }
            systempart(Control1901377608; MyNotes)
            {
                ApplicationArea = Manufacturing;
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action("&Capacity Task List")
            {
                ApplicationArea = Manufacturing;
                Caption = '&Capacity Task List';
                Image = "Report";
                RunObject = Report "Capacity Task List";
                ToolTip = 'View the production orders that are waiting to be processed at the work centers and machine centers. Printouts are made for the capacity of the work center or machine center). The report includes information such as starting and ending time, date per production order and input quantity.';
            }
            action("Prod. Order - &Job Card")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Prod. Order - &Job Card';
                Image = "Report";
                RunObject = Report "Prod. Order - Job Card";
                ToolTip = 'View a list of the work in progress of a production order. Output, Scrapped Quantity and Production Lead Time are shown or printed depending on the operation.';
            }
        }
        area(embedding)
        {
            action("Released Production Orders")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Released Production Orders';
                RunObject = Page "Released Production Orders";
                ToolTip = 'View the list of released production order that are ready for warehouse activities.';
            }
            action("Finished Production Orders")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Finished Production Orders';
                RunObject = Page "Finished Production Orders";
                ToolTip = 'View completed production orders. ';
            }
            action(Items)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Items';
                Image = Item;
                RunObject = Page "Item List";
                ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
            }
            action(ItemsProduced)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Produced';
                RunObject = Page "Item List";
                RunPageView = where("Replenishment System" = const("Prod. Order"));
                ToolTip = 'View the list of production items.';
            }
            action(ItemsRawMaterials)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Raw Materials';
                RunObject = Page "Item List";
                RunPageView = where("Low-Level Code" = filter(> 0),
                                    "Replenishment System" = const(Purchase),
                                    "Production BOM No." = filter(= ''));
                ToolTip = 'View the list of items that are not bills of material.';
            }
            action("Stockkeeping Units")
            {
                ApplicationArea = Warehouse;
                Caption = 'Stockkeeping Units';
                Image = SKU;
                RunObject = Page "Stockkeeping Unit List";
                ToolTip = 'Open the list of item SKUs to view or edit instances of item at different locations or with different variants. ';
            }
            action("Capacity Ledger Entries")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Capacity Ledger Entries';
                Image = CapacityLedger;
                RunObject = Page "Capacity Ledger Entries";
                ToolTip = 'View the capacity ledger entries of the involved production order. Capacity is recorded either as time (run time, stop time, or setup time) or as quantity (scrap quantity or output quantity).';
            }
            action("Inventory Put-aways")
            {
                ApplicationArea = Warehouse;
                Caption = 'Inventory Put-aways';
                RunObject = Page "Inventory Put-aways";
                ToolTip = 'View ongoing put-aways of items to bins according to a basic warehouse configuration. ';
            }
            action("Inventory Picks")
            {
                ApplicationArea = Warehouse;
                Caption = 'Inventory Picks';
                RunObject = Page "Inventory Picks";
                ToolTip = 'View ongoing picks of items from bins according to a basic warehouse configuration. ';
            }
            action(ConsumptionJournals)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Consumption Journals';
                RunObject = Page "Item Journal Batches";
                RunPageView = where("Template Type" = const(Consumption),
                                    Recurring = const(false));
                ToolTip = 'Post the consumption of material as operations are performed.';
            }
            action(OutputJournals)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Output Journals';
                RunObject = Page "Item Journal Batches";
                RunPageView = where("Template Type" = const(Output),
                                    Recurring = const(false));
                ToolTip = 'Post finished end items and time spent in production. ';
            }
            action(CapacityJournals)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Capacity Journals';
                RunObject = Page "Item Journal Batches";
                RunPageView = where("Template Type" = const(Capacity),
                                    Recurring = const(false));
                ToolTip = 'Post consumed capacities that are not assigned to the production order. For example, maintenance work must be assigned to capacity, but not to a production order.';
            }
            action(RecurringCapacityJournals)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Recurring Capacity Journals';
                RunObject = Page "Item Journal Batches";
                RunPageView = where("Template Type" = const(Capacity),
                                    Recurring = const(true));
                ToolTip = 'Post consumed capacities that are not posted as part of production order output, such as maintenance work.';
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
        area(sections)
        {
        }
        area(creation)
        {
            action("Inventory P&ick")
            {
                ApplicationArea = Warehouse;
                Caption = 'Inventory P&ick';
                Image = CreateInventoryPickup;
                RunObject = Page "Inventory Pick";
                RunPageMode = Create;
                ToolTip = 'Create a pick according to a basic warehouse configuration, for example to pick components for a production order. ';
            }
            action("Inventory Put-&away")
            {
                ApplicationArea = Warehouse;
                Caption = 'Inventory Put-&away';
                Image = CreatePutAway;
                RunObject = Page "Inventory Put-away";
                RunPageMode = Create;
                ToolTip = 'View ongoing put-aways of items to bins according to a basic warehouse configuration. ';
            }
        }
        area(processing)
        {
            separator(Tasks)
            {
                Caption = 'Tasks';
                IsHeader = true;
            }
            action("Consumptio&n Journal")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Consumptio&n Journal';
                Image = ConsumptionJournal;
                RunObject = Page "Consumption Journal";
                ToolTip = 'Post the consumption of material as operations are performed.';
            }
            action("Output &Journal")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Output &Journal';
                Image = OutputJournal;
                RunObject = Page "Output Journal";
                ToolTip = 'Post finished end items and time spent in production. ';
            }
            action("&Capacity Journal")
            {
                ApplicationArea = Manufacturing;
                Caption = '&Capacity Journal';
                Image = CapacityJournal;
                RunObject = Page "Capacity Journal";
                ToolTip = 'Post consumed capacities that are not posted as part of production order output, such as maintenance work.';
            }
            separator(Action6)
            {
            }
            action("Register Absence - &Machine Center")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Register Absence - &Machine Center';
                Image = CalendarMachine;
                RunObject = Report "Reg. Abs. (from Machine Ctr.)";
                ToolTip = 'Register planned absences at a machine center. The planned absence can be registered for both human and machine resources. You can register changes in the available resources in the Registered Absence table. When the batch job has been completed, you can see the result in the Registered Absences window.';
            }
            action("Register Absence - &Work Center")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Register Absence - &Work Center';
                Image = CalendarWorkcenter;
                RunObject = Report "Reg. Abs. (from Work Center)";
                ToolTip = 'Register planned absences at a machine center. The planned absence can be registered for both human and machine resources. You can register changes in the available resources in the Registered Absence table. When the batch job has been completed, you can see the result in the Registered Absences window.';
            }
        }
    }
}
