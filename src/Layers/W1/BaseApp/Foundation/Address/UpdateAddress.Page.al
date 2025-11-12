// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

page 1330 "Update Address"
{
    Caption = 'Do you want to update the address?';
    Editable = false;
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            field("<Name>"; Name)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Name';
                Editable = false;
                MultiLine = false;
                ToolTip = 'Specifies the name of the customer or vendor.';
            }
            field("<AddressBlock>"; AddressBlock)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Existing Address';
                Editable = false;
                MultiLine = true;
                ToolTip = 'Specifies the existing full address of the customer or vendor.';
            }
            field("<AddressBlock2>"; AddressBlock2)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Entered Address';
                Editable = false;
                MultiLine = true;
                Style = Strong;
                StyleExpr = true;
                ToolTip = 'Specifies the entered full address of the customer or vendor.';
            }
        }
    }

    actions
    {
    }

    var
        Name: Text;
        AddressBlock: Text;
        AddressBlock2: Text;

    procedure SetName(NameAdd: Text)
    begin
        Name := NameAdd;
    end;

    procedure SetExistingAddress(Address: Text)
    begin
        AddressBlock := Address;
    end;

    procedure SetUpdatedAddress(Address: Text)
    begin
        AddressBlock2 := Address;
    end;
}

