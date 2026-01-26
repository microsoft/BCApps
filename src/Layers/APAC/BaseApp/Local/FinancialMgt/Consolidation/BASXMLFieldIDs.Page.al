// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Setup;

page 11611 "BAS - XML Field IDs"
{
    ApplicationArea = Basic, Suite;
    Caption = 'BAS - XML Field IDs';
    PageType = List;
    SourceTable = "BAS XML Field ID";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("XML Field ID"; Rec."XML Field ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name with which it is referred in the xml file generated from ECI software from the ATO.';
                }
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "BAS Calc. Schedule Fields";
                    ToolTip = 'Specifies the internal program number that corresponds with the Field Label No., contained within the XML file received from the ATO.';
                }
                field("Field Label No."; Rec."Field Label No.")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies that this field is replicated from the xml file received from the ATO.';
                }
                field("Field Description"; Rec."Field Description")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies a description of the Field Label No. as it would be referred to in the relevant section of the BAS instructions.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Update Using XML File")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Using XML File';
                    Image = UpdateXML;
                    ToolTip = 'Start the process of updating the information based on an XML file.';

                    trigger OnAction()
                    begin
                        BASImportExport.SetDirection(2);
                        BASImportExport.RunModal();
                        Clear(BASImportExport);
                    end;
                }
                action("Copy from Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy from Setup';
                    ToolTip = 'Specifies if you want to copy the value from the BAS XML Field ID Setup window.';

                    trigger OnAction()
                    begin
                        if PAGE.RunModal(0, BASSetupName) = ACTION::LookupOK then begin
                            BasXMLFieldIDSetup.SetRange("Setup Name", BASSetupName.Name);
                            if BasXMLFieldIDSetup.Find('-') then begin
                                BasXMLFieldID.DeleteAll();
                                repeat
                                    BasXMLFieldID.Init();
                                    BasXMLFieldID.TransferFields(BasXMLFieldIDSetup);
                                    BasXMLFieldID.Insert();
                                until BasXMLFieldIDSetup.Next() = 0;
                            end;
                        end;
                    end;
                }
                action("Copy to Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy to Setup';
                    ToolTip = 'Specifies if you want to copy the value to the BAS XML Field ID Setup window.';

                    trigger OnAction()
                    begin
                        if PAGE.RunModal(0, BASSetupName) = ACTION::LookupOK then begin
                            BasXMLFieldIDSetup.SetRange("Setup Name", BASSetupName.Name);
                            if BasXMLFieldID.Find('-') and BasXMLFieldIDSetup.Find('-') then
                                BasXMLFieldIDSetup.DeleteAll();
                            repeat
                                if LineNo = 0 then
                                    LineNo := 10000;
                                BasXMLFieldIDSetup.Init();
                                BasXMLFieldIDSetup.TransferFields(BasXMLFieldID);
                                BasXMLFieldIDSetup."Setup Name" := BASSetupName.Name;
                                BasXMLFieldIDSetup."Line No." := LineNo;
                                BasXMLFieldIDSetup.Insert();
                                LineNo := LineNo + 10000;
                            until BasXMLFieldID.Next() = 0;
                        end;
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Update Using XML File_Promoted"; "Update Using XML File")
                {
                }
                actionref("Copy from Setup_Promoted"; "Copy from Setup")
                {
                }
                actionref("Copy to Setup_Promoted"; "Copy to Setup")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        AfterGetCurrentRecord();
    end;

    trigger OnInit()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.TestField("Enable GST (Australia)", true);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        AfterGetCurrentRecord();
    end;

    var
        CurrentBASSetupName: Code[20];
        BASSetupName: Record "BAS XML Field Setup Name";
        BasXMLFieldID: Record "BAS XML Field ID";
        BasXMLFieldIDSetup: Record "BAS XML Field ID Setup";
        LineNo: Integer;
        BASImportExport: Report "BAS - Import/Export";

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        CurrentBASSetupName := Rec."Setup Name";
    end;
}

