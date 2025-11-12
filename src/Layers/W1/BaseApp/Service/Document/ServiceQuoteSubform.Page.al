// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Service.Comment;
using Microsoft.Service.Item;
using Microsoft.Service.Loaner;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Resources;
using Microsoft.Service.Setup;

page 5965 "Service Quote Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Service Item Line";
    SourceTableView = where("Document Type" = const(Quote));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the line.';
                    Visible = false;
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service item number registered in the Service Item table.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ServOrderMgt: Codeunit ServOrderManagement;
                    begin
                        ServOrderMgt.LookupServItemNo(Rec);
                        if xRec.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.") then;
                    end;
                }
                field("Service Item Group Code"; Rec."Service Item Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the service item group for this item.';
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the item number linked to this service item.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of this item.';

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditSerialNo();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of this service item.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies an additional description of this item.';
                    Visible = false;
                }
                field("Repair Status Code"; Rec."Repair Status Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the repair status of this service item.';
                }
                field("Service Shelf No."; Rec."Service Shelf No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service shelf this item is stored on.';
                    Visible = false;
                }
                field(Warranty; Rec.Warranty)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that warranty on either parts or labor exists for this item.';
                }
                field("Warranty Starting Date (Parts)"; Rec."Warranty Starting Date (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the spare parts warranty for this item.';
                    Visible = false;
                }
                field("Warranty Ending Date (Parts)"; Rec."Warranty Ending Date (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ending date of the spare parts warranty for this item.';
                    Visible = false;
                }
                field("Warranty % (Parts)"; Rec."Warranty % (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the percentage of spare parts costs covered by the warranty for this item.';
                    Visible = false;
                }
                field("Warranty % (Labor)"; Rec."Warranty % (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the percentage of labor costs covered by the warranty for this item.';
                    Visible = false;
                }
                field("Warranty Starting Date (Labor)"; Rec."Warranty Starting Date (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the labor warranty for this item.';
                    Visible = false;
                }
                field("Warranty Ending Date (Labor)"; Rec."Warranty Ending Date (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ending date of the labor warranty for this item.';
                    Visible = false;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the service contract associated with the item or service on the line.';
                }
                field("Fault Reason Code"; Rec."Fault Reason Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the fault reason code for the item.';
                    Visible = false;
                }
                field("Service Price Group Code"; Rec."Service Price Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the service price group associated with the item.';
                    Visible = false;
                }
                field("Adjustment Type"; Rec."Adjustment Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the adjustment type for the line.';
                    Visible = false;
                }
                field("Base Amount to Adjust"; Rec."Base Amount to Adjust")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the amount that the service line, linked to this service item line, will be adjusted to.';
                    Visible = false;
                }
                field("Fault Area Code"; Rec."Fault Area Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the fault area code for this item.';
                    Visible = false;
                }
                field("Symptom Code"; Rec."Symptom Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the symptom code for this item.';
                    Visible = false;
                }
                field("Fault Code"; Rec."Fault Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the fault code for this item.';
                    Visible = false;
                }
                field("Resolution Code"; Rec."Resolution Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the resolution code for this item.';
                    Visible = false;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service priority for this item.';
                }
                field("Response Time (Hours)"; Rec."Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated hours from order creation, to the time when the repair status of the item line changes from Initial, to In Process.';
                }
                field("Response Date"; Rec."Response Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated date when service should start on this service item line.';
                }
                field("Response Time"; Rec."Response Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated time when service should start on this service item.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the vendor of this item.';
                    Visible = false;
                }
                field("Vendor Item No."; Rec."Vendor Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number that the vendor uses for this item.';
                    Visible = false;
                }
                field("Loaner No."; Rec."Loaner No.")
                {
                    ApplicationArea = Service;
                    LookupPageID = "Available Loaners";
                    ToolTip = 'Specifies the number of the loaner that has been lent to the customer in the service order to replace this item.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when service on this item began and when the repair status changed to In process.';
                    Visible = false;
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the time when service on this item began and when the repair status changed to In process.';
                    Visible = false;
                }
                field("Finishing Date"; Rec."Finishing Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the finishing date of the service and when the repair status of this item changes to Finished.';
                    Visible = false;
                }
                field("Finishing Time"; Rec."Finishing Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the finishing time of the service and when the repair status of this item changes to Finished.';
                    Visible = false;
                }
                field("No. of Previous Services"; Rec."No. of Previous Services")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of services performed on service items with the same item and serial number as this service item.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Resource &Allocations")
                {
                    ApplicationArea = Service;
                    Caption = 'Resource &Allocations';
                    Image = ResourcePlanning;
                    ToolTip = 'View or allocate resources, such as technicians or resource groups to service items. The allocation can be made by resource number or resource group number, allocation date and allocated hours. You can also reallocate and cancel allocations. You can only have one active allocation per service item.';

                    trigger OnAction()
                    begin
                        AllocateResource();
                    end;
                }
                action("Service &Item Worksheet")
                {
                    ApplicationArea = Service;
                    Caption = 'Service &Item Worksheet';
                    Image = ServiceItemWorksheet;
                    ToolTip = 'View or edit information about service items, such as repair status, fault comments and codes, and cost. In this window, you can update information on the items such as repair status and fault and resolution codes. You can also enter new service lines for resource hours, for the use of spare parts and for specific service costs.';

                    trigger OnAction()
                    begin
                        ShowServOrderWorksheet();
                    end;
                }
                action(Troubleshooting)
                {
                    ApplicationArea = Service;
                    Caption = 'Troubleshooting';
                    Image = Troubleshoot;
                    ToolTip = 'View or edit information about technical problems with a service item.';

                    trigger OnAction()
                    begin
                        ShowChecklist();
                    end;
                }
                action("&Fault/Resol. Codes Relations")
                {
                    ApplicationArea = Service;
                    Caption = '&Fault/Resol. Codes Relations';
                    ToolTip = 'View or edit the relationships between fault codes, including the fault, fault area, and symptom codes, as well as resolution codes and service item groups. It displays the existing combinations of these codes for the service item group of the service item from which you accessed the window and the number of occurrences for each one.';

                    trigger OnAction()
                    begin
                        ShowFaultResolutionRelation();
                    end;
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                group("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    action(Faults)
                    {
                        ApplicationArea = Service;
                        Caption = 'Faults';
                        Image = Error;
                        ToolTip = 'View or edit the different fault codes that you can assign to service items. You can use fault codes to identify the different service item faults or the actions taken on service items for each combination of fault area and symptom codes.';

                        trigger OnAction()
                        begin
                            Rec.ShowComments("Service Comment Line Type"::Fault);
                        end;
                    }
                    action(Resolutions)
                    {
                        ApplicationArea = Service;
                        Caption = 'Resolutions';
                        Image = Completed;
                        ToolTip = 'View or edit the different resolution codes that you can assign to service items. You can use resolution codes to identify methods used to solve typical service problems.';

                        trigger OnAction()
                        begin
                            Rec.ShowComments("Service Comment Line Type"::Resolution);
                        end;
                    }
                    action(Internal)
                    {
                        ApplicationArea = Service;
                        Caption = 'Internal';
                        Image = Comment;
                        ToolTip = 'View or reregister internal comments for the service item. Internal comments are for internal use only and are not printed on reports.';

                        trigger OnAction()
                        begin
                            Rec.ShowComments("Service Comment Line Type"::Internal);
                        end;
                    }
                    action(Accessories)
                    {
                        ApplicationArea = Service;
                        Caption = 'Accessories';
                        Image = ServiceAccessories;
                        ToolTip = 'View or register comments for the accessories to the service item.';

                        trigger OnAction()
                        begin
                            Rec.ShowComments("Service Comment Line Type"::Accessory);
                        end;
                    }
                    action("Lent Loaners")
                    {
                        ApplicationArea = Service;
                        Caption = 'Lent Loaners';
                        ToolTip = 'View the loaners that have been lend out temporarily to replace the service item.';

                        trigger OnAction()
                        begin
                            Rec.ShowComments("Service Comment Line Type"::"Service Item Loaner");
                        end;
                    }
                }
                action("Service Item &Log")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Item &Log';
                    Image = Log;
                    ToolTip = 'View a list of the service item changes that have been logged, for example, when the warranty has changed or a component has been added. This window displays the field that was changed, the old value and the new value, and the date and time that the field was changed.';

                    trigger OnAction()
                    begin
                        ShowServItemEventLog();
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Receive Loaner")
                {
                    ApplicationArea = Service;
                    Caption = '&Receive Loaner';
                    Image = ReceiveLoaner;
                    ToolTip = 'Record that the loaner is received at your company.';

                    trigger OnAction()
                    begin
                        ReceiveLoaner();
                    end;
                }
                action("Create Service &Item")
                {
                    ApplicationArea = Service;
                    Caption = 'Create Service &Item';
                    ToolTip = 'Create a new service item card for the item on the document.';

                    trigger OnAction()
                    begin
                        CreateServItemOnServItemLine();
                    end;
                }
                action("Get St&d. Service Codes")
                {
                    ApplicationArea = Service;
                    Caption = 'Get St&d. Service Codes';
                    Ellipsis = true;
                    Image = ServiceCode;
                    ToolTip = 'Insert service order lines that you have set up for recurring services. ';

                    trigger OnAction()
                    var
                        StdServItemGrCode: Record "Standard Service Item Gr. Code";
                    begin
                        StdServItemGrCode.InsertServiceLines(Rec);
                    end;
                }
            }
            group("&Quote")
            {
                Caption = '&Quote';
                Image = Quote;
                action(ServiceLines)
                {
                    ApplicationArea = Service;
                    Caption = 'Service Lin&es';
                    Image = ServiceLines;
                    ShortCutKey = 'Ctrl+Alt+Q';
                    ToolTip = 'View or edit the related service lines.';

                    trigger OnAction()
                    begin
                        RegisterServInvLines();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if Rec."Serial No." = '' then
            Rec."No. of Previous Services" := 0;
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec."Serial No." = '' then
            Rec."No. of Previous Services" := 0;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine();
    end;

    var
        ServLoanerMgt: Codeunit ServLoanerManagement;
#pragma warning disable AA0470
        CannotOpenWindowErr: Label 'You cannot open the window because %1 is %2 in the %3 table.';
#pragma warning restore AA0470

    local procedure RegisterServInvLines()
    var
        ServInvLine: Record "Service Line";
        ServInvLines: Page "Service Quote Lines";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRegisterServInvLines(Rec, IsHandled);
        if IsHandled then
            exit;

        Rec.TestField("Document No.");
        Rec.TestField("Line No.");
        Clear(ServInvLine);
        ServInvLine.SetRange("Document Type", Rec."Document Type");
        ServInvLine.SetRange("Document No.", Rec."Document No.");
        ServInvLine.FilterGroup(2);
        Clear(ServInvLines);
        ServInvLines.Initialize(Rec."Line No.");
        ServInvLines.SetTableView(ServInvLine);
        ServInvLines.RunModal();
        ServInvLine.FilterGroup(0);
    end;

    local procedure ShowServOrderWorksheet()
    var
        ServItemLine: Record "Service Item Line";
    begin
        Rec.TestField("Document No.");
        Rec.TestField("Line No.");

        Clear(ServItemLine);
        ServItemLine.SetRange("Document Type", Rec."Document Type");
        ServItemLine.SetRange("Document No.", Rec."Document No.");
        ServItemLine.FilterGroup(2);
        ServItemLine.SetRange("Line No.", Rec."Line No.");
        PAGE.RunModal(PAGE::"Service Item Worksheet", ServItemLine);
        ServItemLine.FilterGroup(0);
    end;

    local procedure AllocateResource()
    var
        ServOrderAlloc: Record "Service Order Allocation";
        ResAlloc: Page "Resource Allocations";
    begin
        Rec.TestField("Document No.");
        Rec.TestField("Line No.");
        ServOrderAlloc.Reset();
        ServOrderAlloc.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
        ServOrderAlloc.FilterGroup(2);
        ServOrderAlloc.SetFilter(Status, '<>%1', ServOrderAlloc.Status::Canceled);
        ServOrderAlloc.SetRange("Document Type", Rec."Document Type");
        ServOrderAlloc.SetRange("Document No.", Rec."Document No.");
        ServOrderAlloc.FilterGroup(0);
        ServOrderAlloc.SetRange("Service Item Line No.", Rec."Line No.");
        if ServOrderAlloc.FindFirst() then;
        ServOrderAlloc.SetRange("Service Item Line No.");
        Clear(ResAlloc);
        ResAlloc.SetRecord(ServOrderAlloc);
        ResAlloc.SetTableView(ServOrderAlloc);
        ResAlloc.SetRecord(ServOrderAlloc);
        ResAlloc.Run();
    end;

    local procedure ReceiveLoaner()
    begin
        ServLoanerMgt.ReceiveLoaner(Rec);
    end;

    local procedure ShowServItemEventLog()
    var
        ServItemLog: Record "Service Item Log";
    begin
        Rec.TestField("Service Item No.");
        Clear(ServItemLog);
        ServItemLog.SetRange("Service Item No.", Rec."Service Item No.");
        PAGE.RunModal(PAGE::"Service Item Log", ServItemLog);
    end;

    local procedure ShowChecklist()
    var
        TblshtgHeader: Record "Troubleshooting Header";
    begin
        TblshtgHeader.ShowForServItemLine(Rec);
    end;

    local procedure ShowFaultResolutionRelation()
    var
        ServMgtSetup: Record "Service Mgt. Setup";
        FaultResolutionRelation: Page "Fault/Resol. Cod. Relationship";
    begin
        ServMgtSetup.Get();
        case ServMgtSetup."Fault Reporting Level" of
            ServMgtSetup."Fault Reporting Level"::None:
                Error(
                  CannotOpenWindowErr,
                  ServMgtSetup.FieldCaption("Fault Reporting Level"),
                  ServMgtSetup."Fault Reporting Level",
                  ServMgtSetup.TableCaption());
        end;
        Clear(FaultResolutionRelation);
        FaultResolutionRelation.SetDocument(
          DATABASE::"Service Item Line", Rec."Document Type".AsInteger(), Rec."Document No.", Rec."Line No.");
        FaultResolutionRelation.SetFilters(Rec."Symptom Code", Rec."Fault Code", Rec."Fault Area Code", Rec."Service Item Group Code");
        FaultResolutionRelation.RunModal();
    end;

    local procedure CreateServItemOnServItemLine()
    var
        ServItemMgt: Codeunit ServItemManagement;
    begin
        ServItemMgt.CreateServItemOnServItemLine(Rec);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeRegisterServInvLines(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean);
    begin
    end;
}

