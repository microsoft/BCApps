// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Recording;

using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Counting.Comment;

page 5879 "Phys. Inventory Recording"
{
    Caption = 'Phys. Inventory Recording';
    PageType = Document;
    SourceTable = "Phys. Invt. Record Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the physical inventory order number that is linked to the physical inventory recording.';
                }
                field("Recording No."; Rec."Recording No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a number that is assigned to the physical inventory recording, when you link a physical inventory recording to a physical inventory order.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the inventory recording.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the location where the items must be counted.';
                }
                field("Person Responsible"; Rec."Person Responsible")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the person responsible for performing this physical inventory recording.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the physical inventory recording is open or finished.';
                }
                field("Person Recorded"; Rec."Person Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the user ID of the person who performed the physical inventory.';
                }
                field("Date Recorded"; Rec."Date Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the physical inventory was taken.';
                }
                field("Time Recorded"; Rec."Time Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the time when the physical inventory was taken.';
                }
                field("Allow Recording Without Order"; Rec."Allow Recording Without Order")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that recording lines are automatically created for items that do not exist on the physical inventory order. This can only happen if none of the values in these four fields exist for an item on the order: Item No., Variant Code, Location Code, and Bin Code.';
                }
            }
            part(Lines; "Phys. Invt. Recording Subform")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "Order No." = field("Order No."),
                              "Recording No." = field("Recording No.");
                SubPageView = sorting("Order No.", "Recording No.", "Line No.");
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Recording")
            {
                Caption = '&Recording';
                Image = Document;
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Phys. Inventory Comment Sheet";
                    RunPageLink = "Document Type" = const(Recording),
                                  "Order No." = field("Order No."),
                                  "Recording No." = field("Recording No.");
                    ToolTip = 'View or add comments for the recording.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("E&xport Recording Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'E&xport Recording Lines';
                    Ellipsis = true;
                    Image = Export;
                    ToolTip = 'Send the list of counted inventory items to a file.';

                    trigger OnAction()
                    var
                        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
                        ExportPhysInvtRecording: XMLport "Export Phys. Invt. Recording";
                    begin
                        PhysInvtRecordHeader.Copy(Rec);

                        ExportPhysInvtRecording.Set(PhysInvtRecordHeader);
                        ExportPhysInvtRecording.TextEncoding(TextEncoding::UTF8);
                        ExportPhysInvtRecording.Run();
                        Clear(ExportPhysInvtRecording);
                    end;
                }
                action("I&mport Recording Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'I&mport Recording Lines';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Import a list of counted inventory items from a file.';

                    trigger OnAction()
                    var
                        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
                        ImportPhysInvtRecording: XMLport "Import Phys. Invt. Recording";
                    begin
                        PhysInvtRecordHeader.Copy(Rec);

                        ImportPhysInvtRecording.Set(PhysInvtRecordHeader);
                        ImportPhysInvtRecording.TextEncoding(TextEncoding::UTF8);
                        ImportPhysInvtRecording.Run();
                        Clear(ImportPhysInvtRecording);
                    end;
                }
                action("Fi&nish")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Fi&nish';
                    Ellipsis = true;
                    Image = Approve;
                    RunObject = Codeunit "Phys. Invt. Rec.-Finish (Y/N)";
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Indicate that counting is finished. After this, you can no longer change the physical inventory order. When finishing the physical inventory order, the expected quantity and the recorded quantities are compared and the differences calculated.';
                }
                action("Reo&pen")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Reo&pen';
                    Ellipsis = true;
                    Image = ReOpen;
                    RunObject = Codeunit "Phys. Invt. Rec.-Reopen (Y/N)";
                    ToolTip = 'Reopen the recording. This also reopens the related physical inventory order.';
                }
            }
            action(Print)
            {
                ApplicationArea = Warehouse;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Print the recording document. The printed document has an empty column in which to write the counted quantities.';

                trigger OnAction()
                begin
                    DocPrint.PrintInvtRecording(Rec, true);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Print_Promoted; Print)
                {
                }
                actionref("I&mport Recording Lines_Promoted"; "I&mport Recording Lines")
                {
                }
                actionref("E&xport Recording Lines_Promoted"; "E&xport Recording Lines")
                {
                }
                actionref("Fi&nish_Promoted"; "Fi&nish")
                {
                }
                actionref("Reo&pen_Promoted"; "Reo&pen")
                {
                }
            }
        }
    }

    var
        DocPrint: Codeunit "Document-Print";
}

