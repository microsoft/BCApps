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
                field("Copy Loc. to Cap. Val. Entries"; Rec."Copy Loc. to Cap. Val. Entries")
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
#if not CLEAN27
            group(Subcontracting)
            {
                ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                ObsoleteState = Pending;
                ObsoleteTag = '27.0';
                Caption = 'Subcontracting';
                field("Subcontr. Ship. Reason Code"; Rec."Subcontr. Ship. Reason Code")
                {
                    ApplicationArea = LegacySubcontracting;
                    ToolTip = 'Specifies the reason code for the subcontracting shipment.';
                    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
                field("Subcontr. Return Reason Code"; Rec."Subcontr. Return Reason Code")
                {
                    ApplicationArea = LegacySubcontracting;
                    ToolTip = 'Specifies the reason code for the subcontracting return.';
                    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
                field("Legacy Subcontracting"; Rec."Legacy Subcontracting")
                {
                    ApplicationArea = LegacySubcontracting;
                    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                    ObsoleteState = Pending;
                    ObsoleteTag = '28.0';
                }
            }
#endif
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
#if not CLEAN28
    actions
    {
        area(processing)
        {
            group(LegacySubcontracting)
            {
                Caption = 'Legacy Subcontracting';
                ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                ObsoleteState = Pending;
                ObsoleteTag = '28.0';

                action("Activate Legacy Subcontracting")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Activate Legacy Subcontracting';
                    ToolTip = 'Activates the Legacy Subcontracting application area so that the legacy subcontracting functionality becomes available. A session restart is required for the change to take effect.';
                    Image = Change;
                    Visible = not Rec."Legacy Subcontracting";
                    ObsoleteReason = 'Legacy Subcontracting will be discontinued, environments should move to the Subcontracting App.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '29.0';

                    trigger OnAction()
                    var
                        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
                        ActivateLegacySubcontractingQst: Label 'Legacy subcontracting features are scheduled for removal in a future release. We recommend installing and using the Subcontracting app instead. Do you want to activate legacy subcontracting anyway?';
                    begin
                        LegacySubcFeatureHandler.CheckCanEnableLegacySubcontracting();
                        if not Confirm(ActivateLegacySubcontractingQst, false) then
                            exit;

                        LegacySubcFeatureHandler.SetLegacySubcontracting(Rec, true);
                    end;
                }
                action("Disable Legacy Subcontracting")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Disable Legacy Subcontracting';
                    ToolTip = 'Disables the Legacy Subcontracting application area and enables the Subcontracting application area. A session restart is required for the change to take effect.';
                    Image = Change;
                    Visible = Rec."Legacy Subcontracting";
                    ObsoleteReason = 'Legacy Subcontracting will be discontinued, environments should move to the Subcontracting App.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '28.0';

                    trigger OnAction()
                    var
                        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
                    begin
                        LegacySubcFeatureHandler.SetLegacySubcontracting(Rec, false);
                    end;
                }
                action("Pre Check Disable Legacy Subcontracting")
                {
                    ApplicationArea = LegacySubcontracting;
                    Caption = 'Pre-Check Disable Legacy Subcontracting';
                    ToolTip = 'Performs a pre-check to ensure that the legacy subcontracting feature can be safely disabled. This action does not actually disable the feature or trigger migration.';
                    Image = CheckList;
                    ObsoleteReason = 'Subcontracting app will be enabled by default, so this pre-check is no longer necessary';
                    ObsoleteState = Pending;
                    ObsoleteTag = '28.0';

                    trigger OnAction()
                    var
                        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
                        PreChecksPassedMsg: Label 'Pre-checks passed. You can now disable Legacy Subcontracting using the action "Disable Legacy Subcontracting".';
                    begin
                        LegacySubcFeatureHandler.CheckCanDisableLegacySubcontracting();
                        Message(PreChecksPassedMsg);
                    end;
                }
            }
        }
    }
#endif

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
