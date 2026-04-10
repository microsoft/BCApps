namespace System.Utilities;

page 709 "Error Message Register"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Error Message Register';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Error Message Register";
    SourceTableView = sorting("Created On")
                      order(descending);
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Created On"; Rec."Created On")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec."Message")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Errors; Rec.Errors)
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnDrillDown()
                    begin
                        DrillDownErrors(MessageType::Error);
                    end;
                }
                field(Warnings; Rec.Warnings)
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnDrillDown()
                    begin
                        DrillDownErrors(MessageType::Warning);
                    end;
                }
                field(Information; Rec.Information)
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnDrillDown()
                    begin
                        DrillDownErrors(MessageType::Information);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Show)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show';
                Image = ShowList;
                ToolTip = 'Open the list of all error messages related to the current register record.';

                trigger OnAction()
                begin
                    DrillDownErrors(MessageType::All);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref(Show_Promoted; Show)
                {
                }
            }
        }
    }

    var
        MessageType: Option Error,Warning,Information,All;

    local procedure DrillDownErrors(Type: Option)
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessages: Page "Error Messages";
    begin
        ErrorMessage.SetRange("Register ID", Rec.ID);
        if Type <> MessageType::All then
            ErrorMessage.SetRange("Message Type", Type);
        ErrorMessage.CopyToTemp(TempErrorMessage);
        ErrorMessages.SetRecords(TempErrorMessage);
        ErrorMessages.RunModal();
    end;
}

