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
                }
                field("Normal Ending Time"; Rec."Normal Ending Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Preset Output Quantity"; Rec."Preset Output Quantity")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Default Consum. Calc. Based on"; Rec."Default Consum. Calc. Based on")
                {
                    ApplicationArea = Manufacturing, Planning;
                }
                field("Show Capacity In"; Rec."Show Capacity In")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Planning Warning"; Rec."Planning Warning")
                {
                    ApplicationArea = Planning;
                }
                field("Doc. No. Is Prod. Order No."; Rec."Doc. No. Is Prod. Order No.")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Dynamic Low-Level Code"; Rec."Dynamic Low-Level Code")
                {
                    ApplicationArea = Planning;
                }
                field("Cost Incl. Setup"; Rec."Cost Incl. Setup")
                {
                    ApplicationArea = Manufacturing;
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
                }
                field("Planned Order Nos."; Rec."Planned Order Nos.")
                {
                    ApplicationArea = Manufacturing, Planning;
                }
                field("Firm Planned Order Nos."; Rec."Firm Planned Order Nos.")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Released Order Nos."; Rec."Released Order Nos.")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Work Center Nos."; Rec."Work Center Nos.")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Machine Center Nos."; Rec."Machine Center Nos.")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Production BOM Nos."; Rec."Production BOM Nos.")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Routing Nos."; Rec."Routing Nos.")
                {
                    ApplicationArea = Manufacturing;
                }
            }
            group(Planning)
            {
                Caption = 'Planning';
#if not CLEAN27
                field("Current Production Forecast"; Rec."Current Production Forecast")
                {
                    ApplicationArea = Planning;
                    ObsoleteReason = 'Moved to page Inventory Setup';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                    Editable = false;
                    Visible = false;
                }
                field("Use Forecast on Locations"; Rec."Use Forecast on Locations")
                {
                    ApplicationArea = Planning;
                    ObsoleteReason = 'Moved to page Inventory Setup';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                    Editable = false;
                    Visible = false;
                }
                field("Use Forecast on Variants"; Rec."Use Forecast on Variants")
                {
                    ApplicationArea = Planning;
                    ObsoleteReason = 'Moved to page Inventory Setup';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                    Editable = false;
                    Visible = false;
                }
                field("Default Safety Lead Time"; Rec."Default Safety Lead Time")
                {
                    ApplicationArea = Manufacturing, Planning;
                    ObsoleteReason = 'Moved to page Inventory Setup';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                    Editable = false;
                    Visible = false;
                }
                field("Blank Overflow Level"; Rec."Blank Overflow Level")
                {
                    ApplicationArea = Planning;
                    ObsoleteReason = 'Moved to page Inventory Setup';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                    Editable = false;
                    Visible = false;
                }
                field("Combined MPS/MRP Calculation"; Rec."Combined MPS/MRP Calculation")
                {
                    ApplicationArea = Planning;
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
                }
#if not CLEAN27
                field("Default Dampener Period"; Rec."Default Dampener Period")
                {
                    ApplicationArea = Planning;
                    ObsoleteReason = 'Moved to page Inventory Setup';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                    Editable = false;
                    Visible = false;
                }
                field("Default Dampener %"; Rec."Default Dampener %")
                {
                    ApplicationArea = Planning;
                    AutoFormatType = 0;
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

