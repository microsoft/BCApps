// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 105 "New Account Schedule Name"
{
    Caption = 'New Row Definition';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(AccountSheduleGroup)
            {
                Caption = 'Row definition';
                field(SourceAccountScheduleName; OldName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Row Definition';
                    Enabled = false;
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the existing row definition in the package.';
                }
                field(NewAccountScheduleName; NewName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New Row Definition';
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the new row definition after importing.';
                    trigger OnValidate()
                    begin
                        CheckAccScheduleAlreadyExists();
                        CurrPage.Update();
                    end;
                }
                field(AlreadyExistsText; AlreadyExistsTxt)
                {
                    ShowCaption = false;
                    Editable = false;
                    Style = Unfavorable;
                }
            }
        }
    }

    var
        OldName: Code[10];
        NewName: Code[10];
        AlreadyExistsTxt: Text;
        AlreadyExistsErr: Label 'Row definition %1 will be overwritten.', Comment = '%1 - name of the row definition.';

    procedure Set(Name: Code[10])
    begin
        OldName := Name;
        NewName := Name;
        CheckAlreadyExists();
    end;

    procedure GetName(): Code[10]
    begin
        exit(NewName);
    end;

    local procedure CheckAlreadyExists()
    begin
        CheckAccScheduleAlreadyExists();
    end;

    local procedure CheckAccScheduleAlreadyExists()
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AlreadyExistsTxt := '';
        if AccScheduleName.Get(NewName) then
            AlreadyExistsTxt := StrSubstNo(AlreadyExistsErr, NewName);
    end;

}
