// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Setup;
using System.DataAdministration;

page 99000768 "Manufacturing Setup"
{
    ApplicationArea = Manufacturing, Planning;
    Caption = 'Manufacturing Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Manufacturing Setup";
    UsageCategory = Administration;
    AdditionalSearchTerms = 'Planning Setup';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Normal Starting Time"; Rec."Normal Starting Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the normal starting time of the workday.';
                }
                field("Normal Ending Time"; Rec."Normal Ending Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the normal ending time of a workday.';
                }
                field("Preset Output Quantity"; Rec."Preset Output Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies what to show in the Output Quantity field of a production journal when it is first opened.';
                }
                field("Default Consum. Calc. Based on"; Rec."Default Consum. Calc. Based on")
                {
                    ApplicationArea = Manufacturing, Planning;
                }
                field("Show Capacity In"; Rec."Show Capacity In")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies which capacity unit of measure to use by default to record and track capacity.';
                }
                field("Planning Warning"; Rec."Planning Warning")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether to run the MRP engine to detect if planned shipment dates cannot be met.';
                }
                field("Doc. No. Is Prod. Order No."; Rec."Doc. No. Is Prod. Order No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies that the production order number is also the document number in the ledger entries posted for the production order.';
                }
                field("Dynamic Low-Level Code"; Rec."Dynamic Low-Level Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies low-level codes are dynamically assigned to each component in a product structure. Note that this may affect performance. The top final assembly level is denoted as level 0, the end item. The higher the low-level code number, the lower the item is in the hierarchy. The codes are used in the planning of component parts. When you calculate a plan, the BOM is exploded in the planning worksheet, and the gross requirements for level 0 are passed down the planning levels as gross requirements for the next planning level.';
                }
                field("Cost Incl. Setup"; Rec."Cost Incl. Setup")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies whether the setup times are to be included in the cost calculation of the Standard Cost field.';
                }
                field("Inc. Non. Inv. Cost To Prod"; Rec."Inc. Non. Inv. Cost To Prod")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Load SKU Cost on Manufacturing"; Rec."Load SKU Cost on Manufacturing")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Finish Order without Output"; Rec."Finish Order without Output")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies that status of orders with no output can be changed to finished and the WIP will be written off to Inventory Adjustment Account.';
                }
                field("Default Gen. Bus. Post. Group"; Rec."Default Gen. Bus. Post. Group")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Default Flushing Method"; Rec."Default Flushing Method")
                {
                    ApplicationArea = Manufacturing;
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Simulated Order Nos."; Rec."Simulated Order Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to a simulated production order.';
                }
                field("Planned Order Nos."; Rec."Planned Order Nos.")
                {
                    ApplicationArea = Manufacturing, Planning;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to a planned production order.';
                }
                field("Firm Planned Order Nos."; Rec."Firm Planned Order Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to firm planned production orders.';
                }
                field("Released Order Nos."; Rec."Released Order Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to a released production order.';
                }
                field("Work Center Nos."; Rec."Work Center Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to work centers.';
                }
                field("Machine Center Nos."; Rec."Machine Center Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to machine centers.';
                }
                field("Production BOM Nos."; Rec."Production BOM Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to production BOMs.';
                }
                field("Routing Nos."; Rec."Routing Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number series code to use when assigning numbers to routings.';
                }
            }
            group(Planning)
            {
                Caption = 'Planning';
#if not CLEAN27
                field("Current Production Forecast"; Rec."Current Production Forecast")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the name of the relevant demand forecast to use to calculate a plan. Use Inventory Setup page to change this field.';
                    ObsoleteReason = 'Moved to page Inventory Setup';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                    Editable = false;
                    Visible = false;
                }
                field("Use Forecast on Locations"; Rec."Use Forecast on Locations")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies that actual demand for the selected demand forecast is nettet for the specified location only. If you leave the check box empty, the program regards the demand forecast as valid for all locations. Use Inventory Setup page to change this field.';
                    ObsoleteReason = 'Moved to page Inventory Setup';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                    Editable = false;
                    Visible = false;
                }
                field("Use Forecast on Variants"; Rec."Use Forecast on Variants")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies that actual demand for the selected demand forecast is nettet for the specified item variant. If you leave the check box empty, the program regards the demand forecast as valid for all variants. Use Inventory Setup page to change this field.';
                    ObsoleteReason = 'Moved to page Inventory Setup';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                    Editable = false;
                    Visible = false;
                }
                field("Default Safety Lead Time"; Rec."Default Safety Lead Time")
                {
                    ApplicationArea = Manufacturing, Planning;
                    ToolTip = 'Specifies a time period that is added to the lead time of all items that do not have another value specified in the Safety Lead Time field. Use Inventory Setup page to change this field.';
                    ObsoleteReason = 'Moved to page Inventory Setup';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                    Editable = false;
                    Visible = false;
                }
                field("Blank Overflow Level"; Rec."Blank Overflow Level")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how the planning system should react if the Overflow Level field on the item or SKU card is empty. Use Inventory Setup page to change this field.';
                    ObsoleteReason = 'Moved to page Inventory Setup';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                    Editable = false;
                    Visible = false;
                }
                field("Combined MPS/MRP Calculation"; Rec."Combined MPS/MRP Calculation")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies if both master production schedule and material requirements plan are run when you choose the Calc. Regenerative Plan action in the planning worksheet. Use Inventory Setup page to change this field.';
                    ObsoleteReason = 'Moved to page Inventory Setup';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                    Editable = false;
                    Visible = false;
                }
#endif
                field("Components at Location"; Rec."Components at Location")
                {
                    ApplicationArea = Manufacturing, Planning;
                    ToolTip = 'Specifies the inventory location from where the production order components are to be taken.';
                }
#if not CLEAN27
                field("Default Dampener Period"; Rec."Default Dampener Period")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a period of time during which you do not want the planning system to propose to reschedule existing supply order''s forward. This value in this field applies to all items except for items that have a different value in the Dampener Period field on the item card. When a dampener time is set, an order is only rescheduled when the defined dampener time has passed since the order s original due date. Note: The dampener time that is applied to an item can never be higher than the value in the item''s Lot Accumulation Period field. This is because the inventory build-up time that occurs during a dampener period would conflict with the build-up period defined by the item''s lot accumulation period. Accordingly, the default dampener period generally applies to all items. However, if an item''s lot accumulation period is shorter than the default dampener period, then the item''s dampener time equals its lot accumulation period. Use Inventory Setup page to change this field.';
                    ObsoleteReason = 'Moved to page Inventory Setup';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                    Editable = false;
                    Visible = false;
                }
                field("Default Dampener %"; Rec."Default Dampener %")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a percentage of an item''s lot size by which an existing supply must change before a planning suggestion is made. Use Inventory Setup page to change this field.';
                    ObsoleteReason = 'Moved to page Inventory Setup';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                    Editable = false;
                    Visible = false;
                }
#endif
                field("Manual Scheduling"; Rec."Manual Scheduling")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Safety Lead Time for Man. Sch."; Rec."Safety Lead Time for Man. Sch.")
                {
                    ApplicationArea = Manufacturing;
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
        ManufacturingSetupNotif: Codeunit "Manufacturing Setup Notif.";
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        ManufacturingSetupNotif.ShowPlanningFieldsMoveNotification();
    end;

}

