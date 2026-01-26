// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Setup;

page 11614 "BAS - XML Field IDs Setup"
{
    Caption = 'BAS - XML Field IDs Setup';
    PageType = Worksheet;
    SourceTable = "BAS XML Field ID Setup";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(CurrentBASSetupNameCtrl; CurrentBASSetupName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Setup Name';
                    Lookup = true;
                    ToolTip = 'Specifies the BAS setup name that you want to use.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        if CurrentBASSetupNameCtrlEditabl then begin
                            CurrPage.SaveRecord();
                            BASMngmt.LookupBASXMLSetupName(CurrentBASSetupName, Rec);
                            CurrPage.Update(false);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        BASMngmt.CheckBASXMLSetupName(CurrentBASSetupName);
                        CurrentBASSetupNameOnAfterVali();
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("XML Field ID"; Rec."XML Field ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the extensible markup language (XML) field ID for the business activity statement (BAS).';
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
                    ToolTip = 'Specifies the replicated XML file that is received from the Australian Taxation Office (ATO).';
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
            action("Update XML Field IDs")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Update XML Field IDs';
                Image = SetupList;
                ToolTip = 'Start the process of updating the information.';

                trigger OnAction()
                begin
                    BASImportExport.SetCurrentBASSetupName(CurrentBASSetupName);
                    BASImportExport.SetDirection(2);
                    BASImportExport.RunModal();
                    Clear(BASImportExport);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Update XML Field IDs_Promoted"; "Update XML Field IDs")
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
        BASImportExport: Report "BAS - Import/Export Setup";
        BASMngmt: Codeunit "BAS Management";
        CurrentBASSetupName: Code[20];
        CurrentBASSetupNameCtrlEditabl: Boolean;

    local procedure CurrentBASSetupNameOnAfterVali()
    begin
        CurrPage.SaveRecord();
        BASMngmt.SetBASXMLSetupName(CurrentBASSetupName, Rec);
        CurrPage.Update(false);
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        CurrentBASSetupName := Rec."Setup Name";
    end;
}

