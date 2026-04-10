// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Text;

codeunit 9150 "My Records Filter Sub."
{

    trigger OnRun()
    begin
    end;

    var
        MyCustomersTxt: Label 'MYCUSTOMERS', Comment = 'Must be uppercase';
        MyItemsTxt: Label 'MYITEMS', Comment = 'Must be uppercase';
        MyVendorsTxt: Label 'MYVENDORS', Comment = 'Must be uppercase';
        OverflowMsg: Label 'The filter contains more than 2000 numbers and has been truncated.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Filter Tokens", 'OnResolveTextFilterToken', '', false, false)]
    local procedure DoOnResolveTextFilterToken(TextToken: Text; var TextFilter: Text; var Handled: Boolean)
    begin
        case TextToken of
            CopyStr('MYCUSTOMERS', 1, StrLen(TextToken)), CopyStr(MyCustomersTxt, 1, StrLen(TextToken)):
                begin
                    GetMyFilterText(TextFilter, DATABASE::"My Customer");
                    Handled := true;
                end;
            CopyStr('MYITEMS', 1, StrLen(TextToken)), CopyStr(MyItemsTxt, 1, StrLen(TextToken)):
                begin
                    GetMyFilterText(TextFilter, DATABASE::"My Item");
                    Handled := true;
                end;
            CopyStr('MYVENDORS', 1, StrLen(TextToken)), CopyStr(MyVendorsTxt, 1, StrLen(TextToken)):
                begin
                    GetMyFilterText(TextFilter, DATABASE::"My Vendor");
                    Handled := true;
                end;
        end;
    end;

    procedure GetMyFilterText(var TextFilterText: Text; MyTableNo: Integer)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        NoOfValues: Integer;
        IsHandled: Boolean;
        IsMyTable: Boolean;
    begin
        IsHandled := false;
        IsMyTable := MyTableNo in [DATABASE::"My Customer", DATABASE::"My Vendor", DATABASE::"My Item"];
        OnBeforeGetMyFilterText(TextFilterText, MyTableNo, IsMyTable, IsHandled);
        if IsHandled then
            exit;

        if not IsMyTable then
            exit;

        TextFilterText := '';
        NoOfValues := 0;
        RecRef.Open(MyTableNo);
        FieldRef := RecRef.Field(1);
        FieldRef.SetRange(UserId);
        if RecRef.Find('-') then
            repeat
                FieldRef := RecRef.Field(2);
                AddToFilter(TextFilterText, Format(FieldRef.Value));
                NoOfValues += 1;
            until (RecRef.Next() = 0) or (NoOfValues > 2000);
        RecRef.Close();

        if NoOfValues > 2000 then
            Message(OverflowMsg);
    end;

    local procedure AddToFilter(var FilterString: Text; MyNo: Code[20])
    begin
        if FilterString = '' then
            FilterString := MyNo
        else
            FilterString += '|' + MyNo;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetMyFilterText(var TextFilterText: Text; MyTableNo: Integer; var IsMyTable: Boolean; var IsHandled: Boolean)
    begin
    end;
}

